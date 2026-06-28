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
#                       engine): FIVE checks of the MERGED registry against the
#                       disk state under REPO_ROOT — declared-exists, orphans
#                       (docs/**/*.md RECURSIVE — incl. docs/workflows/ — +
#                       spec/*.md maxdepth 1, each dir only when present; an
#                       undeclared overlay file IS an orphan), workflows-subfolder
#                       (registry-gated: docs/workflows/ exists + non-empty),
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
#   --classify          (F000065) READ-ONLY generation detector. Emits
#                       GENERATION=<canonical|legacy|absent|malformed>,
#                       POSITIONS=<comma-list of on-disk positions>,
#                       DUPLICATE=<0|1> (both spec/ + root present),
#                       CANONICAL_PATH=spec/doc-spec.md. `legacy` is reported
#                       ONLY when the active file has NO canonical table AND
#                       matches the old-generation signature (fenced ```yaml +
#                       schema_version: + docs:); a no-table no-signature file
#                       is `malformed` (the caller keeps the halt semantics).
#                       Never writes; no registry gates (works on legacy/absent).
#   --reconcile         (F000065) The ONLY new WRITE path; opt-in. canonical =>
#                       clean no-op (RECONCILE: already canonical). legacy =>
#                       migrate the active file legacy yaml -> canonical 3-col
#                       Markdown table PRESERVING every declared row (path->Doc,
#                       purpose->Purpose, requirement->Requirement; drop
#                       section/audit_class/front_table), written atomically
#                       (temp -> --validate-clean -> mv) with a <path>.bak + a
#                       migration report + the audit_class asymmetry guard
#                       (RECONCILE-WARN). malformed => the [doc-sync-no-config]
#                       halt (a hand-broken canonical file is never clobbered).
#                       duplicate => reconcile the canonical copy + report the
#                       redundant one (no auto-delete; OQ1 deferred).
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
# FIVE checks of the MERGED registry against the disk state under REPO_ROOT.
# Called AFTER _run_registry_gates (the dispatch arm runs the registry-absent
# probe itself, BEFORE the gates — a subcommand-local carve-out, since the
# parse gates halt on a missing registry, which is wrong for this caller).
# Output contract: one `check: <id> — PASS` line per clean check, one
# `FINDING: stage1/<id> — <detail>` line PER VIOLATION (a multi-violation
# check emits one line each, no PASS line), then the machine tail
# `CHECKS_RUN=<n>` (check ids run — 5 on a full run) + `FINDINGS=<n>`
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

  # orphans — every docs/**/*.md (RECURSIVE — so a per-workflow file under
  # docs/workflows/ must be declared too) and spec/*.md (maxdepth 1) on disk is
  # declared; each dir checked only when it exists. The docs scan is recursive
  # (F000067 docs/workflows/ subfolder); spec stays maxdepth 1 (the flat
  # spec-registry family). A non-self-declaring overlay file COUNTS as an orphan
  # by design — an overlay MUST self-declare (this workbench's does); the finding
  # is honest guidance for a consumer repo.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  for _dir in docs spec; do
    [ -d "$REPO_ROOT_RESOLVED/$_dir" ] || continue
    # docs recurses (no -maxdepth); spec stays flat (-maxdepth 1). Two explicit
    # find invocations rather than an unquoted flag variable (shellcheck SC2086).
    if [ "$_dir" = "docs" ]; then
      _COD_ORPHAN_FILES=$(cd "$REPO_ROOT_RESOLVED" && find "$_dir" -type f -name '*.md' 2>/dev/null | sort)
    else
      _COD_ORPHAN_FILES=$(cd "$REPO_ROOT_RESOLVED" && find "$_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
    fi
    while IFS= read -r _f; do
      [ -n "$_f" ] || continue
      if ! printf '%s\n' "$_COD_DECLARED" | grep -qFx "$_f"; then
        echo "FINDING: stage1/orphans — undeclared $_dir *.md on disk (orphan): $_f"
        _c=$((_c + 1))
      fi
    done <<EOF
$_COD_ORPHAN_FILES
EOF
  done
  if [ "$_c" -eq 0 ]; then echo "check: orphans — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  # workflows-subfolder (F000067) — when the registry is PRESENT, docs/workflows/
  # MUST exist and contain at least one *.md (the two-level docs structure is a
  # mandated part of the portable contract). This check only runs from
  # _check_on_disk, which the --check-on-disk dispatch arm calls AFTER the
  # registry-absent probe returns early — so REGISTRY=absent never reaches here,
  # i.e. the mandate is registry-gated and never fires on a non-adopting repo.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  _WF_DIR="$REPO_ROOT_RESOLVED/docs/workflows"
  if [ ! -d "$_WF_DIR" ]; then
    echo "FINDING: stage1/workflows-subfolder — docs/workflows/ is required but missing (the contract mandates a per-workflow subfolder)"
    _c=1
  elif [ -z "$(find "$_WF_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)" ]; then
    echo "FINDING: stage1/workflows-subfolder — docs/workflows/ exists but contains no *.md (the contract mandates a non-empty per-workflow subfolder)"
    _c=1
  fi
  if [ "$_c" -eq 0 ]; then echo "check: workflows-subfolder — PASS"; fi
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

# ---- --classify / --reconcile: contract-file generation detection + migration ----
# (F000065/S000109) The audits own the canonical contract-file format (the
# 3-column Markdown table) + position (spec/, root accepted). --classify is a
# READ-ONLY machine block telling a caller whether the registry is canonical,
# legacy (an OLD-generation on-disk format), duplicated across both positions,
# or absent. --reconcile is the ONLY new WRITE path (opt-in): it migrates a
# legacy file -> canonical preserving every declared row, atomically, with a
# .bak and a migration report. Idempotent (canonical => clean no-op).
#
# OLD-generation signature (doc-spec legacy): a fenced ```yaml block carrying
# `schema_version:` + `docs:` (the pre-F000063 generated-registry format —
# recoverable from git: `git show 716a537:doc-spec.md`). `legacy` is reported
# ONLY when (a) the CURRENT parser finds NO canonical Markdown registry table
# AND (b) this signature matches. A no-table no-signature file is NOT legacy —
# it stays the [doc-sync-no-config] halt (a hand-broken canonical file must
# never be clobbered).

# Does file $1 carry a parseable canonical Markdown registry table?
# (exit 0 = yes). Uses the same extractor the rest of the script trusts.
_has_canonical_table() {
  [ -f "$1" ] || return 1
  _ct=$(_extract_table_file "$1")
  [ -n "$_ct" ]
}

# Does file $1 match the OLD-generation doc-spec signature? (exit 0 = yes)
# A single fenced ```yaml block containing both `schema_version:` and a
# top-level `docs:` key.
_has_legacy_doc_signature() {
  [ -f "$1" ] || return 1
  _ly=$(awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$1")
  [ -n "$_ly" ] || return 1
  printf '%s\n' "$_ly" | grep -qE '^schema_version:' || return 1
  printf '%s\n' "$_ly" | grep -qE '^docs:' || return 1
  return 0
}

# Classify the generation of the doc-spec contract file(s) without writing.
# Emits four machine lines:
#   GENERATION=<canonical|legacy|absent>
#   POSITIONS=<comma-list of on-disk contract positions: spec/doc-spec.md, doc-spec.md>
#   DUPLICATE=<0|1>   (1 when BOTH spec/ and root copies exist)
#   CANONICAL_PATH=<the spec/-position canonical target path>
# Resolution mirrors the rest of the script (spec/-then-root); a genuinely
# malformed canonical file (no table, no legacy signature) classifies as
# GENERATION=malformed so the caller keeps the [doc-sync-no-config] halt
# semantics rather than treating it as legacy.
_classify() {
  _CL_SPEC="$REPO_ROOT_RESOLVED/spec/doc-spec.md"
  _CL_ROOT="$REPO_ROOT_RESOLVED/doc-spec.md"
  _CL_POSITIONS=""
  [ -f "$_CL_SPEC" ] && _CL_POSITIONS="spec/doc-spec.md"
  if [ -f "$_CL_ROOT" ]; then
    [ -n "$_CL_POSITIONS" ] && _CL_POSITIONS="$_CL_POSITIONS,doc-spec.md" || _CL_POSITIONS="doc-spec.md"
  fi
  _CL_DUP=0
  [ -f "$_CL_SPEC" ] && [ -f "$_CL_ROOT" ] && _CL_DUP=1

  # The canonical target is always the spec/ position.
  echo "CANONICAL_PATH=spec/doc-spec.md"

  if [ -z "$_CL_POSITIONS" ]; then
    echo "GENERATION=absent"
    echo "POSITIONS="
    echo "DUPLICATE=0"
    return 0
  fi

  # The active file (the one the rest of the script resolves) drives the
  # generation verdict. DOC_SPEC_PATH already resolved spec/-then-root.
  _CL_ACTIVE="$DOC_SPEC_PATH"
  if _has_canonical_table "$_CL_ACTIVE"; then
    echo "GENERATION=canonical"
  elif _has_legacy_doc_signature "$_CL_ACTIVE"; then
    echo "GENERATION=legacy"
  else
    # No canonical table AND no legacy signature: a genuinely malformed
    # canonical file. NOT legacy — preserve the halt semantics.
    echo "GENERATION=malformed"
  fi
  echo "POSITIONS=$_CL_POSITIONS"
  echo "DUPLICATE=$_CL_DUP"
  return 0
}

# Parse the OLD-generation doc-spec yaml `docs:` list into TSV rows:
#   path<TAB>purpose<TAB>requirement
# Drops the old section/audit_class/front_table fields (audit_class is
# re-derived from the path in the canonical model). awk only — the same
# fenced-yaml extraction the legacy generation used.
_parse_legacy_doc_entries() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    !f         { next }
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)
      sub(/"[[:space:]]*$/, "", v)
      return v
    }
    # strip a `  - key: "value"` list-item line (the leading `- ` dash + key).
    function strip_listkey(line,   v) {
      v=line
      sub(/^[[:space:]]*-[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)
      sub(/"[[:space:]]*$/, "", v)
      return v
    }
    function flush() {
      if (cur_path != "") {
        printf "%s\t%s\t%s\n", cur_path, cur_purpose, cur_req
      }
      cur_path=""; cur_purpose=""; cur_req=""
    }
    /^[[:space:]]*-[[:space:]]*path:/ { flush(); cur_path=strip_listkey($0); next }
    /^[[:space:]]*purpose:/           { cur_purpose=strip($0); next }
    /^[[:space:]]*requirement:/       { cur_req=strip($0); next }
    END { flush() }
  ' "$1"
}

# Reconcile the doc-spec contract file. The ONLY new write path; opt-in.
#   - canonical  => clean no-op (RECONCILE: already canonical), exit 0.
#   - legacy     => migrate the active file legacy->canonical preserving every
#                   declared row (path->Doc, purpose->Purpose,
#                   requirement->Requirement; drop section/audit_class/
#                   front_table), written atomically (temp -> --validate-clean
#                   -> mv) with a <path>.bak, a migration report, and a
#                   RECONCILE-WARN audit_class asymmetry guard line for any old
#                   row declared audit_class: operational whose path derives
#                   human-doc.
#   - duplicate  => reconcile the canonical (spec/) position + report the
#                   redundant root copy (do NOT auto-delete; OQ1 deferred).
#   - malformed  => the [doc-sync-no-config] halt (never clobbered).
#   - absent     => nothing to reconcile (RECONCILE: absent — run the audit to
#                   seed), exit 0.
_reconcile() {
  _RC_GEN=$(_classify | awk -F= '/^GENERATION=/{print $2}')
  _RC_DUP=$(_classify | awk -F= '/^DUPLICATE=/{print $2}')
  _RC_SPEC="$REPO_ROOT_RESOLVED/spec/doc-spec.md"
  _RC_ROOT="$REPO_ROOT_RESOLVED/doc-spec.md"

  case "$_RC_GEN" in
    absent)
      echo "RECONCILE: absent — no contract file to reconcile (run /CJ_doc_audit to seed the canonical contract)"
      return 0
      ;;
    malformed)
      emit_halt "doc-spec.md is present but has neither a canonical registry table nor a recognized legacy signature — refusing to reconcile a possibly hand-broken canonical file (fix the table by hand): $DOC_SPEC_PATH"
      ;;
    canonical)
      echo "RECONCILE: already canonical — no migration needed ($DOC_SPEC_PATH)"
      if [ "$_RC_DUP" = "1" ]; then
        echo "RECONCILE-WARN: a redundant doc-spec copy exists at the root position (doc-spec.md) alongside the canonical spec/doc-spec.md — remove it by hand (auto-delete is deferred, OQ1)"
      fi
      return 0
      ;;
    legacy)
      : # fall through to migrate
      ;;
    *)
      emit_halt "internal: unexpected GENERATION='$_RC_GEN' from _classify"
      ;;
  esac

  # Migrate the ACTIVE file (DOC_SPEC_PATH resolved spec/-then-root). Always
  # write the canonical output to the SAME position as the active legacy file
  # so a root-only legacy file reconciles in place (root is an accepted
  # position; relocation to spec/ is OQ2, deferred).
  _RC_TARGET="$DOC_SPEC_PATH"

  _RC_ENTRIES=$(_parse_legacy_doc_entries "$_RC_TARGET")
  if [ -z "$_RC_ENTRIES" ]; then
    emit_halt "doc-spec.md matched the legacy signature but its docs: list parsed to zero rows (cannot migrate): $_RC_TARGET"
  fi
  _RC_NROWS=$(printf '%s\n' "$_RC_ENTRIES" | grep -c . || true)

  # Build the canonical Markdown table file in a temp, then validate, then mv.
  _RC_TMP=$(mktemp -d -t doc-spec-reconcile.XXXXXX)
  _RC_OUT="$_RC_TMP/doc-spec.md"
  {
    echo "<!-- DOC-SPEC-COMMON:BEGIN (portable — keep byte-identical across adopting repos) -->"
    echo "# doc-spec.md — what docs this repo carries"
    echo ""
    echo "This file is the doc contract: **what documents does this repo carry, and"
    echo "what is each one for?** The Markdown table at the end IS the machine source"
    echo "of truth — \`scripts/doc-spec.sh\` parses it directly. (Migrated from the"
    echo "legacy yaml generation by \`doc-spec.sh --reconcile\`.)"
    echo ""
    echo "## The registry (machine source of truth)"
    echo ""
    echo "Three columns — **Doc** (the repo-relative path), **Purpose** (what the doc"
    echo "is for), and **Requirement** (what makes the doc current). A path under"
    echo "\`docs/\` or the root \`README.md\` is a human-doc (no work-item IDs);"
    echo "everything else is operational. Cells may not contain a literal \`|\`."
    echo ""
    echo "| Doc | Purpose | Requirement |"
    echo "|-----|---------|-------------|"
    printf '%s\n' "$_RC_ENTRIES" | while IFS="$(printf '\t')" read -r _p _pu _rq; do
      [ -n "$_p" ] || continue
      echo "| \`$_p\` | $_pu | $_rq |"
    done
    echo "<!-- DOC-SPEC-COMMON:END -->"
  } > "$_RC_OUT"

  # Atomic guard: the migrated file must parse clean before it replaces the
  # original. A failed validate leaves the legacy file untouched.
  if ! DOC_SPEC_PATH="$_RC_OUT" DOC_SPEC_CUSTOM_PATH="$_RC_TMP/nonexistent-custom.md" bash "$0" --validate >/dev/null 2>&1; then
    rm -rf "$_RC_TMP"
    emit_halt "the migrated doc-spec.md did not validate clean — leaving the legacy file untouched ($_RC_TARGET)"
  fi

  cp "$_RC_TARGET" "$_RC_TARGET.bak"
  mv "$_RC_OUT" "$_RC_TARGET"
  rm -rf "$_RC_TMP"

  echo "RECONCILE: migrated $_RC_NROWS rows (legacy yaml -> canonical Markdown table) at $_RC_TARGET"
  echo "RECONCILE: backup written: $_RC_TARGET.bak"
  echo "RECONCILE: dropped fields: section, audit_class, front_table (audit_class is now path-derived)"

  # audit_class asymmetry guard: an OLD row declared audit_class: operational
  # whose path derives human-doc would silently change class in the canonical
  # model. Re-scan the ORIGINAL (now .bak) for `audit_class: operational` rows
  # whose path derives human-doc and warn (the operator verifies no work-item
  # IDs before the next hard Check 19).
  _scan_asymmetry "$_RC_TARGET.bak"

  if [ "$_RC_DUP" = "1" ]; then
    echo "RECONCILE-WARN: a redundant doc-spec copy exists at the other position alongside $_RC_TARGET — remove it by hand (auto-delete is deferred, OQ1)"
  fi
  return 0
}

# Scan a legacy doc-spec file ($1) for the audit_class asymmetry: a `path:`
# whose declared `audit_class: operational` conflicts with the path-derived
# class (human-doc). awk pairs each path with its following audit_class.
_scan_asymmetry() {
  [ -f "$1" ] || return 0
  _AS_PAIRS=$(awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    !f         { next }
    function strip(line,   v) {
      v=line; sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v); sub(/"[[:space:]]*$/, "", v); return v
    }
    function strip_listkey(line,   v) {
      v=line; sub(/^[[:space:]]*-[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v); sub(/"[[:space:]]*$/, "", v); return v
    }
    function flush() { if (cur_path != "") printf "%s\t%s\n", cur_path, cur_ac; cur_path=""; cur_ac="" }
    /^[[:space:]]*-[[:space:]]*path:/ { flush(); cur_path=strip_listkey($0); next }
    /^[[:space:]]*audit_class:/       { cur_ac=strip($0); next }
    END { flush() }
  ' "$1")
  printf '%s\n' "$_AS_PAIRS" | while IFS="$(printf '\t')" read -r _p _ac; do
    [ -n "$_p" ] || continue
    [ "$_ac" = "operational" ] || continue
    _derived=$(_audit_class_for "$_p")
    if [ "$_derived" = "human-doc" ]; then
      echo "RECONCILE-WARN: $_p audit_class was 'operational' but path derives 'human-doc' — verify no work-item IDs before the next hard Check 19"
    fi
  done
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
`README.md`, plus every per-workflow file under `docs/workflows/`. A declared
doc whose path is under `docs/`, or the root `README.md`, is treated as a
**human doc**: it must exist and must carry **no work-item IDs** (a reference of
the shape `<F|S|T|D>` followed by six digits is internal-tracker noise; this is
a hard CI lint, not a guideline).

`docs/workflow.md` is an **overview/index**: it names + links every major
workflow, and the deep per-workflow detail (flowcharts, touches, steps) lives
one level down under `docs/workflows/<name>.md`. In an adopting repo
`docs/workflows/` is **required and non-empty**, and every `docs/workflows/*.md`
is a human doc that must be declared in the (merged) registry.

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
  disk under `docs/` (recursively — including `docs/workflows/`) and `spec/` is
  declared (no orphans), that `docs/workflows/` exists and is non-empty, that
  every root `*.md` is declared, and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `Requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + the contract files + `docs/**/*.md`).

## The canonical contract-file template

The audit verbs (`/CJ_doc_audit`, `/CJ_test_audit`) own this contract's
canonical shape — what files are required, where they live, and their format:

- **Required** — the general file of each pair: `spec/doc-spec.md` (this file)
  and `spec/test-spec.md`. Each is delivered verbatim by its engine's `--seed`
  and must exist in an adopting repo (the audit seed-delivers a missing one).
- **Optional** — the `*-custom.md` overlay next to each general file
  (`spec/doc-spec-custom.md`, `spec/test-spec-custom.md`): the repo's chosen
  additions, merged in by the parser. A repo without an overlay carries the
  general contract alone.
- **Position** — `spec/` is canonical; the repo root is an accepted fallback
  (`doc-spec.md` / `test-spec.md`) for root-style consumers. The engine
  resolves `spec/`-then-root.
- **Format** — a 3-column Markdown table (`| Doc | Purpose | Requirement |`)
  for doc-spec; a single fenced `yaml` registry for test-spec. The table /
  block IS the source of truth, parsed directly.

`doc-spec.sh --classify` reports a file's generation (canonical / legacy /
absent / duplicated); `doc-spec.sh --reconcile` migrates a legacy file to this
canonical shape preserving every declared row.

## The registry (machine source of truth)

The table below is the source of truth. It has three columns —
**Doc** (the repo-relative path), **Purpose** (what the doc is for), and
**Requirement** (what makes the doc current). Add a doc by adding a row; a
path under `docs/` or the root `README.md` is a human-doc (no work-item IDs),
everything else is operational. Cells may not contain a literal `|`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| `docs/philosophy.md` | Major design logic, one '## Principle N' section each. | Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs. |
| `docs/workflow.md` | Overview/index that names + links every major workflow; per-workflow detail lives under docs/workflows/. | Overview/index that names + links every major workflow a human would invoke; per-workflow detail (flowcharts, touches, steps) lives under docs/workflows/<name>.md; no work-item IDs. |
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
  --classify)
    # READ-ONLY. No registry gates (classification works on absent/legacy/
    # malformed files too — the whole point is to tell the caller which it is).
    _classify
    ;;
  --reconcile)
    # The ONLY new WRITE path (opt-in). Migrates legacy->canonical preserving
    # every declared row; clean no-op on a canonical file; halts on a
    # malformed (non-signature, no-table) file rather than clobbering it.
    _reconcile
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
  doc-spec.sh --classify          # READ-ONLY generation detector: emits
                                  #   GENERATION=<canonical|legacy|absent|malformed>
                                  #   POSITIONS=<comma-list>/DUPLICATE=<0|1>/CANONICAL_PATH=
  doc-spec.sh --reconcile         # opt-in WRITE: migrate a legacy yaml doc-spec.md ->
                                  #   canonical 3-col Markdown table preserving every row
                                  #   (atomic + .bak + report); clean no-op on canonical
  doc-spec.sh --seed              # complete minimal valid general doc-spec.md (self-bootstrap)
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--check-on-disk|--list-declared|--list-human-docs|--expand-whitelist|--classify|--reconcile|--seed}" >&2
    exit 2
    ;;
  *)
    echo "doc-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
