#!/usr/bin/env bash
# doc-spec.sh — parse + validate the two-tier doc-spec registry (the general
# doc-spec.md + the optional doc-spec-custom.md overlay); derive the doc-only
# auto-commit whitelist; emit the portable general seed for self-bootstrap.
#
# doc-spec.md is the GENERAL tier of the doc contract ("what docs does this
# repo carry and what is each for") — delivered verbatim by --seed and never
# edited in place. Its source of truth is a 3-column Markdown table
# (`| Doc | Purpose | Requirement |`) parsed directly — the table IS the
# registry, no second copy to drift. Repo-specific docs live in an optional
# doc-spec-custom.md OVERLAY next to it (the same 3-column table grammar). This
# helper merges the two internally, so every consumer (scripts/validate.sh
# Checks 15-19/24, the /CJ_document-release skill) sees ONE registry. No
# python/yaml dependency — awk only, portable to bash 3.2.
#
# Table cell grammar (pinned): the registry is the LAST Markdown table in the
# file (`| Doc | Purpose | Requirement |`). The header row and the `|---|`
# delimiter row are skipped; each data row is split on `|`, each cell is
# whitespace-trimmed, and surrounding backticks are stripped from the Doc (path)
# cell. A literal `|` inside a cell is rejected (Markdown tables cannot carry
# one). `audit_class` is no longer a declared field: it is DERIVED from the path
# — a path under `docs/` OR the root `README.md` is a `human-doc`, every other
# declared path is `operational`.
#
# Strict posture (registry-reading subcommands only): general doc-spec.md
# missing OR no registry table OR a row with the wrong column count OR a literal
# `|` inside a cell OR a present-but-invalid overlay OR a path duplicated across
# the two files  ->  HALT with `[doc-sync-no-config] <reason>` on stdout +
# exit 1. These gates run via _run_registry_gates() ONLY for --validate/
# --list-declared/--list-human-docs/--expand-whitelist. --seed and --help do
# NOT inherit them (see --seed).
#
# Subcommands (all list subcommands + --validate operate on the MERGE):
#   --validate          exit 0 + print `OK schema_version=<n>` if the merged
#                       registry is valid; exit 1 + halt-emit otherwise.
#   --check-on-disk     the deterministic conformance set (the audit Stage-1
#                       engine): FOUR checks of the MERGED registry against the
#                       disk state under REPO_ROOT — declared-exists, orphans
#                       (docs/*.md maxdepth 1 + spec/*.md, each dir only when
#                       present; an undeclared overlay file IS an orphan),
#                       root-declared, human-doc-ids. One `check: <id> — PASS`
#                       line per clean check, one `FINDING: stage1/<id> —
#                       <detail>` line per violation, then `CHECKS_RUN=<n>` +
#                       `FINDINGS=<n>`. Exit 0 clean / 1 findings. Probes
#                       registry existence ITSELF before the parse gates: absent
#                       => `REGISTRY=absent` + exit 0 (the caller's seed-delivery
#                       step owns that case); present-but-invalid => the
#                       [doc-sync-no-config] halt.
#   --list-declared     echo every declared `Doc` path (general + overlay;
#                       sorted, unique).
#   --list-human-docs   echo only the path-derived human-doc paths (merged).
#   --expand-whitelist  echo the doc-only auto-commit whitelist: every declared
#                       path (merged) + the contract files + every
#                       docs/**/*.md on disk (sorted, unique).
#   --seed              echo a COMPLETE, minimal, VALID general doc-spec.md for
#                       self-bootstrap of a MISSING doc-spec.md.
#                       Does NOT require doc-spec.md to exist (that is the whole
#                       point). Source: repo-local templates/doc-spec-common.md
#                       if present, else the embedded heredoc below (so a consumer
#                       repo with only the deployed doc-spec.sh can bootstrap).
#                       Emits ONLY seed content to stdout; exit 0.
#
# audit_class (path-derived, not declared): human-doc | operational.
# schema_version (conceptual): 1.

set -eu

# Strip CRLF from any command output on Windows. No-op on Unix.
_strip_cr() { tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: DOC_SPEC_PATH env override (outermost) -> spec/doc-spec.md
# (this repo, post-relocation) -> root doc-spec.md (root-only consumers / fresh
# adopters). POSIX/bash-3.2 idiom.
DOC_SPEC_PATH="${DOC_SPEC_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/doc-spec.md" ] && echo "$REPO_ROOT_RESOLVED/spec/doc-spec.md" || echo "$REPO_ROOT_RESOLVED/doc-spec.md" )}"
# The optional custom overlay ALWAYS lives next to the resolved general file
# (spec/doc-spec-custom.md here; root doc-spec-custom.md in a root-style
# consumer; sibling of any DOC_SPEC_PATH override in temp-dir drills — which
# keeps overridden parses hermetic). DOC_SPEC_CUSTOM_PATH overrides outermost.
DOC_SPEC_CUSTOM_PATH="${DOC_SPEC_CUSTOM_PATH:-$(dirname "$DOC_SPEC_PATH")/doc-spec-custom.md}"
SEED_TEMPLATE="${REPO_ROOT_RESOLVED}/templates/doc-spec-common.md"
SCHEMA_VERSION="1"

emit_halt() {
  echo "[doc-sync-no-config] $1"
  exit 1
}

# Emit the registry files in merge order: the general file, then the overlay
# when present. Every merged read iterates this list.
_registry_files() {
  echo "$DOC_SPEC_PATH"
  [ -f "$DOC_SPEC_CUSTOM_PATH" ] && echo "$DOC_SPEC_CUSTOM_PATH"
  return 0
}

# Parse one file's registry TABLE into rows. The registry is the LAST Markdown
# table in the file whose header is `| Doc | Purpose | Requirement |`. Emits one
# line per data row, raw (pipe-delimited cells, untrimmed) for the callers to
# split — a sentinel `__BADROW__<n>` line marks a data row with the wrong column
# count so the validate gate can name it. awk only.
#
# Recognition: a line is a TABLE row when it starts (after optional whitespace)
# with `|`. The header is the row whose trimmed cells are exactly Doc/Purpose/
# Requirement; the very next `|`-row is the `|---|` delimiter (skipped). Every
# subsequent `|`-row until a blank/non-table line is a data row.
_extract_table_file() {
  awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    {
      line=$0
      # Is this a Markdown table row? (starts with optional ws then |)
      if (line ~ /^[[:space:]]*\|/) {
        # Header detection: split and check the three trimmed cells.
        n=split(line, c, "|")
        # c[1] is empty (before the leading |); cells are c[2..n-1].
        h1=trim(c[2]); h2=trim(c[3]); h3=trim(c[4])
        if (!in_table) {
          if (h1=="Doc" && h2=="Purpose" && h3=="Requirement") {
            in_table=1; saw_delim=0
          }
          next
        }
        # In table.
        if (!saw_delim) {
          # The first row after the header is the |---| delimiter — skip it.
          saw_delim=1
          next
        }
        # A data row. Emit raw (callers trim + split).
        print line
        next
      } else {
        # Non-table line: a blank line or prose ends the current table.
        in_table=0; saw_delim=0
      }
    }
  ' "$1" | _strip_cr
}

# Derive audit_class from a path: human-doc when under docs/ OR the root
# README.md; operational otherwise. (Re-derives the dropped declared field so
# --list-human-docs and the engine human-doc-ids check survive unchanged.)
_audit_class_for() {
  case "$1" in
    docs/*) echo "human-doc" ;;
    README.md) echo "human-doc" ;;
    *) echo "operational" ;;
  esac
}

# Parse one file's table into TSV rows: path<TAB>audit_class<TAB>ok
# where ok is 1 for a well-formed 3-cell row, 0 for a malformed one (the
# path field then carries a diagnostic blob). audit_class is path-derived.
_parse_registry_file() {
  _extract_table_file "$1" | awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    function strip_bt(s) { gsub(/^`+|`+$/, "", s); return s }
    {
      # A well-formed row is `| a | b | c |` -> split yields 5 fields:
      # "", a, b, c, "" (leading + trailing empties around the pipes).
      n=split($0, c, "|")
      # Count the actual cells (between the outer pipes). For `| a | b | c |`
      # n==5 and cells = c[2],c[3],c[4]. Reject any other shape.
      if (n != 5) {
        printf "MALFORMED: wrong column count in row: %s\t-\t0\n", $0
        next
      }
      path=strip_bt(trim(c[2]))
      printf "%s\t%s\t1\n", path, "" # audit_class filled by the caller (bash _audit_class_for)
    }
  '
}

# Merged rows across general + overlay (general first). Fills audit_class via
# the bash path-deriver (awk cannot call it). Emits path<TAB>audit_class<TAB>ok.
_parse_registry() {
  _raw=$(while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_registry_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  )
  printf '%s\n' "$_raw" | while IFS="$(printf '\t')" read -r _p _ac _ok; do
    [ -n "$_p" ] || continue
    if [ "$_ok" = "0" ]; then
      # Pass the malformed marker through untouched.
      printf '%s\t%s\t0\n' "$_p" "-"
      continue
    fi
    printf '%s\t%s\t1\n' "$_p" "$(_audit_class_for "$_p")"
  done
}

# ---- Validation gates (run ONLY for registry-reading subcommands) ----
# NOTE: --seed and --help must NOT inherit these gates. --seed exists precisely
# to bootstrap a MISSING doc-spec.md.
_validate_one_file() {
  # $1 = file path, $2 = display name for halt reasons
  _ROWS_F=$(_parse_registry_file "$1")
  [ -n "$_ROWS_F" ] || emit_halt "$2 has no registry table (a Markdown table headed | Doc | Purpose | Requirement |)"

  # Reject a literal `|` inside a cell (manifests as the MALFORMED marker — a
  # data row that split to the wrong column count) or any other malformed row.
  while IFS="$(printf '\t')" read -r _p _ac _ok; do
    [ -n "$_p" ] || continue
    case "$_p" in
      MALFORMED:*) emit_halt "$2 registry has a malformed table row (every row must be exactly | Doc | Purpose | Requirement | with no literal | inside a cell): ${_p#MALFORMED: }" ;;
    esac
    [ -n "$_p" ] || emit_halt "a $2 registry row is missing its Doc (path) cell"
  done <<EOF
$_ROWS_F
EOF
}

_run_registry_gates() {
  [ -f "$DOC_SPEC_PATH" ] || emit_halt "doc-spec.md missing (resolved spec/-then-root): $DOC_SPEC_PATH"

  _validate_one_file "$DOC_SPEC_PATH" "doc-spec.md"

  # A present-but-invalid overlay halts; an absent overlay is fine (nothing to
  # merge, no finding).
  if [ -f "$DOC_SPEC_CUSTOM_PATH" ]; then
    _validate_one_file "$DOC_SPEC_CUSTOM_PATH" "doc-spec-custom.md (overlay)"
  fi

  _ROWS=$(_parse_registry)
  # Strip any MALFORMED placeholder rows for the consumers below (the per-file
  # gate already halted on them).
  _ROWS=$(printf '%s\n' "$_ROWS" | awk -F'\t' '$3=="1"')
  [ -n "$_ROWS" ] || emit_halt "doc-spec.md registry declares no docs (empty table)"

  # Duplicate-path guard across the merged registry (general + overlay): the
  # same path declared twice — in either file or across the two — is an error.
  _DUP_PATHS=$(printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')
  [ -z "${_DUP_PATHS% }" ] || emit_halt "duplicate path(s) across the doc-spec registry (general + overlay): ${_DUP_PATHS% }"
}

# ---- --check-on-disk: the deterministic conformance set (audit Stage 1) ----
# FOUR checks of the MERGED registry against the disk state under REPO_ROOT.
# Called AFTER _run_registry_gates (the dispatch arm runs the registry-absent
# probe itself, BEFORE the gates — a subcommand-local carve-out, since the
# parse gates halt on a missing registry, which is wrong for this caller).
# Output contract: one `check: <id> — PASS` line per clean check, one
# `FINDING: stage1/<id> — <detail>` line PER VIOLATION (a multi-violation
# check emits one line each, no PASS line), then the machine tail
# `CHECKS_RUN=<n>` (check ids run — 4 on a full run) + `FINDINGS=<n>`
# (violation lines). When declared-exists finds missing docs, a trailing
# `REMEDIATION: stage1/declared-exists — …` advisory line (NOT a finding; does
# NOT change FINDINGS=) names /CJ_document-release as the scaffolder, so a
# standalone/consumer run is actionable rather than a dead-end list. Returns 0
# clean / 1 findings. Every loop is `while IFS= read -r` — the word-split
# defect class stays designed out.
_check_on_disk() {
  _COD_FINDINGS=0
  _COD_CHECKS=0
  _COD_MISSING=0
  _COD_DECLARED=$(printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}' | sort -u)

  # declared-exists — every declared path exists on disk.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    if [ ! -f "$REPO_ROOT_RESOLVED/$_p" ]; then
      echo "FINDING: stage1/declared-exists — declared doc missing on disk: $_p"
      _c=$((_c + 1))
    fi
  done <<EOF
$_COD_DECLARED
EOF
  if [ "$_c" -eq 0 ]; then echo "check: declared-exists — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))
  _COD_MISSING=$_c

  # orphans — every docs/*.md (maxdepth 1) and spec/*.md on disk is declared;
  # each dir checked only when it exists. A non-self-declaring overlay file
  # COUNTS as an orphan by design — an overlay MUST self-declare (this
  # workbench's does); the finding is honest guidance for a consumer repo.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  for _dir in docs spec; do
    [ -d "$REPO_ROOT_RESOLVED/$_dir" ] || continue
    while IFS= read -r _f; do
      [ -n "$_f" ] || continue
      if ! printf '%s\n' "$_COD_DECLARED" | grep -qFx "$_f"; then
        echo "FINDING: stage1/orphans — undeclared $_dir/*.md on disk (orphan): $_f"
        _c=$((_c + 1))
      fi
    done <<EOF
$(cd "$REPO_ROOT_RESOLVED" && find "$_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
EOF
  done
  if [ "$_c" -eq 0 ]; then echo "check: orphans — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  # root-declared — every root *.md on disk is a declared registry path.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  while IFS= read -r _f; do
    [ -n "$_f" ] || continue
    if ! printf '%s\n' "$_COD_DECLARED" | grep -qFx "$_f"; then
      echo "FINDING: stage1/root-declared — undeclared root *.md: $_f"
      _c=$((_c + 1))
    fi
  done <<EOF
$(cd "$REPO_ROOT_RESOLVED" && find . -maxdepth 1 -type f -name '*.md' 2>/dev/null | sed 's|^\./||' | sort)
EOF
  if [ "$_c" -eq 0 ]; then echo "check: root-declared — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  # human-doc-ids — no path-derived human-doc contains a work-item ID
  # ([FSTD][0-9]{6}). Absence on disk is declared-exists' finding, not this
  # check's — skip missing files here.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    [ -f "$REPO_ROOT_RESOLVED/$_p" ] || continue
    if grep -qE '[FSTD][0-9]{6}' "$REPO_ROOT_RESOLVED/$_p"; then
      echo "FINDING: stage1/human-doc-ids — work-item ID ([FSTD]NNNNNN) in human-doc: $_p"
      _c=$((_c + 1))
    fi
  done <<EOF
$(printf '%s\n' "$_ROWS" | awk -F'\t' '$2=="human-doc" {print $1}' | sort -u)
EOF
  if [ "$_c" -eq 0 ]; then echo "check: human-doc-ids — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  echo "CHECKS_RUN=$_COD_CHECKS"
  echo "FINDINGS=$_COD_FINDINGS"
  # Remediation pointer (advisory — NOT a finding; does NOT change FINDINGS=).
  # declared-exists reports docs the contract REQUIRES but that are absent on
  # disk; this audit is read-mostly and never scaffolds them. Without a pointer,
  # a standalone / consumer-repo run is a dead-end list ("workflow.md missing"
  # with no next step). Name the remedy: /CJ_document-release reads this SAME
  # merged registry and stub-scaffolds every declared-but-missing doc.
  if [ "${_COD_MISSING:-0}" -gt 0 ]; then
    echo "REMEDIATION: stage1/declared-exists — $_COD_MISSING required doc(s) declared but missing; run /CJ_document-release to stub-scaffold them (it reads this same doc-spec registry). This audit reports, it does not scaffold."
  fi
  [ "$_COD_FINDINGS" -eq 0 ]
}

# ---- Portable seed (a COMPLETE, minimal, VALID general doc-spec.md) ----
# Source order: the repo-local published artifact templates/doc-spec-common.md
# (the maintained copy a human can read/copy), else the embedded heredoc below.
# The heredoc makes --seed self-contained so a CONSUMER repo — where only the
# deployed scripts/doc-spec.sh is present and templates/ is absent — can still
# self-bootstrap. Three copies stay byte-identical (the general spec/doc-spec.md
# file, this heredoc, templates/doc-spec-common.md): tests/
# cj-document-release-config.test.sh guards heredoc == template, and
# tests/doc-spec-overlay.test.sh guards general-file == --seed output.
_emit_seed() {
  if [ -f "$SEED_TEMPLATE" ]; then
    cat "$SEED_TEMPLATE"
    return 0
  fi
  cat <<'DOCSPEC_SEED'
<!-- DOC-SPEC-COMMON:BEGIN (portable — keep byte-identical across adopting repos) -->
# doc-spec.md — what docs this repo carries

This file is the single answer to two questions: **what documents does this
repo carry, and what is each one for?** The Markdown table at the end IS the
machine source of truth — `scripts/doc-spec.sh` parses it directly. A human
reads the same table. One artifact, no second list to keep in sync.

This file is the **general tier** of a two-tier contract, delivered verbatim
(`doc-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific docs are declared
in an optional **`doc-spec-custom.md` overlay** next to this file (the same
3-column table grammar). The parser merges the two internally, so every
consumer sees ONE registry; a repo without an overlay simply carries the
general contract alone. Nothing about the repo's other tooling has to change.

## The doc contract

Every repo that adopts this contract carries the ten **general docs** listed
in the registry table below — sub-grouped here for the reader.

**Human docs** — what a person (not just an agent) reads to understand the
project: `docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`,
`README.md`. A declared doc whose path is under `docs/`, or the root
`README.md`, is treated as a **human doc**: it must exist and must carry **no
work-item IDs** (a reference of the shape `<F|S|T|D>` followed by six digits is
internal-tracker noise; this is a hard CI lint, not a guideline).

**Operational docs** — agent- and ops-facing, so they may reference work
items: `spec/doc-spec.md` (this file), `spec/test-spec.md`, `CLAUDE.md`,
`CHANGELOG.md`, `TODOS.md`. Every declared path that is NOT a human doc is
operational.

Two rules make these docs trustworthy:

- **General docs are required.** Every general doc must exist in an adopting
  repo; the doc-release skill stub-scaffolds any missing one. Overlay docs
  (declared in `doc-spec-custom.md`) are the repo's chosen additions.
- **The registry is the source of truth.** The table below — merged with the
  overlay's, when one exists — declares every doc the repo carries. Tooling
  parses it; the prose explains it. Add a doc by adding a table row — never by
  editing a second list somewhere else.

## How the registry is used

Two consumers parse the merged table (this file + the overlay):

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` (and `spec/`) is declared (no orphans), that every root
  `*.md` is declared, and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `Requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + the contract files + `docs/**/*.md`).

## The registry (machine source of truth)

The table below is the source of truth. It has three columns —
**Doc** (the repo-relative path), **Purpose** (what the doc is for), and
**Requirement** (what makes the doc current). Add a doc by adding a row; a
path under `docs/` or the root `README.md` is a human-doc (no work-item IDs),
everything else is operational. Cells may not contain a literal `|`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| `docs/philosophy.md` | Major design logic, one '## Principle N' section each. | Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs. |
| `docs/workflow.md` | The major workflows from a human's perspective; names the major entry points. | Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs. |
| `docs/architecture.md` | Meaningful infra under the hood, deeper than workflow.md. | Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs. |
| `README.md` | Repo landing page: folder structure + how to get started. | Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs. |
| `docs/reference.md` | Curated external references for building this workbench — repos, docs, blogs, articles — grouped by category. | Lists useful external references (repos / links / blogs / articles) relevant to building this workbench, grouped by category, each with a one-line note on why it is relevant; human-readable; no work-item IDs. |
| `spec/doc-spec.md` | The doc contract itself (this file — the general tier, delivered verbatim by doc-spec.sh --seed). | Present; byte-identical to the portable seed (doc-spec.sh --seed); the registry table parses; repo-specific docs live in the optional doc-spec-custom.md overlay, never in this file. |
| `spec/test-spec.md` | The general test contract — portable rules for the repo's verification surface (parsed by test-spec.sh). | Present; rules current against the live verification surface; registry parses with schema_version 1; repo-specific units live in the optional test-spec-custom.md overlay. |
| `CLAUDE.md` | Agent operating instructions (auto-loaded by Claude Code). | Present; work-item references allowed (operational doc). |
| `CHANGELOG.md` | Release history (keep-a-changelog). | Present; updated by /ship + /document-release. |
| `TODOS.md` | The operational backlog. | Present; work-item references allowed (operational doc). |
<!-- DOC-SPEC-COMMON:END -->
DOCSPEC_SEED
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --check-on-disk)
    # Registry-existence probe BEFORE the parse gates (subcommand-local
    # carve-out): an ABSENT registry is the caller's seed-delivery case —
    # `REGISTRY=absent` + exit 0, never a [doc-sync-no-config] halt. A
    # PRESENT-but-invalid registry inherits --validate's halt posture
    # (exit 1) via the shared gates below.
    if [ ! -f "$DOC_SPEC_PATH" ]; then
      echo "REGISTRY=absent"
      exit 0
    fi
    _run_registry_gates
    _check_on_disk
    ;;
  --list-declared)
    _run_registry_gates
    printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}' | sort -u
    ;;
  --list-human-docs)
    _run_registry_gates
    printf '%s\n' "$_ROWS" | awk -F'\t' '$2=="human-doc" {print $1}' | sort -u
    ;;
  --expand-whitelist)
    _run_registry_gates
    {
      # Every declared path (general + overlay).
      printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}'
      # The contract files themselves (this repo: under spec/, post-relocation).
      echo "spec/doc-spec.md"
      echo "spec/doc-spec-custom.md"
      # Every docs/**/*.md on disk (relative to repo root).
      if [ -d "$REPO_ROOT_RESOLVED/docs" ]; then
        ( cd "$REPO_ROOT_RESOLVED" && find docs -type f -name '*.md' 2>/dev/null )
      fi
    } | sort -u | grep -v '^$' || true
    ;;
  --seed)
    # NO registry gates — --seed bootstraps a MISSING doc-spec.md.
    _emit_seed
    ;;
  --help|-h)
    cat <<'USAGE'
doc-spec.sh — parse + validate the two-tier doc-spec registry (general +
optional doc-spec-custom.md overlay; all reads operate on the merge). The
registry is a 3-column Markdown table (| Doc | Purpose | Requirement |) parsed
directly; audit_class is derived from the path (docs/* or README.md => human-doc).

Usage:
  doc-spec.sh --validate          # exit 0 if the merged registry is ok
  doc-spec.sh --check-on-disk     # deterministic conformance set (Stage-1 engine):
                                  #   4 checks vs disk; FINDING: stage1/<id> lines +
                                  #   CHECKS_RUN=/FINDINGS= tail; registry-absent =>
                                  #   REGISTRY=absent + exit 0 (probe before gates)
  doc-spec.sh --list-declared     # every declared path (merged)
  doc-spec.sh --list-human-docs   # only path-derived human-doc paths (merged)
  doc-spec.sh --expand-whitelist  # doc-only auto-commit whitelist (merged)
  doc-spec.sh --seed              # complete minimal valid general doc-spec.md (self-bootstrap)
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--check-on-disk|--list-declared|--list-human-docs|--expand-whitelist|--seed}" >&2
    exit 2
    ;;
  *)
    echo "doc-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
