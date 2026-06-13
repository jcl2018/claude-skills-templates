#!/usr/bin/env bash
# doc-spec.sh — parse + validate the two-tier doc-spec registry (the general
# doc-spec.md + the optional doc-spec-custom.md overlay); derive the doc-only
# auto-commit whitelist; emit the portable general seed for self-bootstrap.
#
# doc-spec.md is the GENERAL tier of the doc contract ("what docs does this
# repo carry and what is each for") — delivered verbatim by --seed and never
# edited in place. Repo-specific docs live in an optional doc-spec-custom.md
# OVERLAY next to it (same fenced ```yaml grammar, section: custom entries).
# This helper merges the two internally, so every consumer (scripts/validate.sh
# Checks 15-23, the /CJ_document-release skill, generate-doc-views.sh) sees ONE
# registry. No python/yaml dependency — awk only, portable to bash 3.2.
#
# Strict posture (registry-reading subcommands only): general doc-spec.md
# missing OR no yaml registry OR schema_version unsupported OR an entry missing
# path/section/audit_class OR an audit_class outside the closed enum OR a
# present-but-invalid overlay OR a path duplicated across the two files  ->
# HALT with `[doc-sync-no-config] <reason>` on stdout + exit 1. These gates run
# via _run_registry_gates() ONLY for --validate/--list-declared/
# --list-human-docs/--list-front-table-docs/--render/--expand-whitelist.
# --seed and --help do NOT inherit them (see --seed).
#
# Subcommands (all list subcommands + --validate operate on the MERGE):
#   --validate          exit 0 + print `OK schema_version=<n>` if the merged
#                       registry is valid; exit 1 + halt-emit otherwise.
#   --check-on-disk     the deterministic conformance set (the audit Stage-1
#                       engine): six checks of the MERGED registry against the
#                       disk state under REPO_ROOT — declared-exists, orphans
#                       (docs/*.md maxdepth 1 + spec/*.md, each dir only when
#                       present; an undeclared overlay file IS an orphan),
#                       root-declared, human-doc-ids, front-table,
#                       views-render (table-block vs fresh --render). One
#                       `check: <id> — PASS` line per clean check, one
#                       `FINDING: stage1/<id> — <detail>` line per violation,
#                       then `CHECKS_RUN=<n>` + `FINDINGS=<n>`. Exit 0 clean /
#                       1 findings. Probes registry existence ITSELF before
#                       the parse gates: absent => `REGISTRY=absent` + exit 0
#                       (the caller's seed-delivery step owns that case);
#                       present-but-invalid => the [doc-sync-no-config] halt.
#   --list-declared     echo every declared `path` (general + overlay; sorted,
#                       unique).
#   --list-human-docs   echo only the `audit_class: human-doc` paths (merged).
#   --list-front-table-docs
#                       echo only the paths whose `front_table` is `required`
#                       (merged; consumed by validate.sh Check 20). Separate
#                       awk pass; the shared 3-column TSV is unchanged.
#   --render general|custom
#                       Markdown table (Doc | Purpose | Requirement) of the
#                       merged registry's section: common / section: custom
#                       rows. `--render custom` therefore reads the overlay —
#                       and, back-compat, any legacy in-file section: custom
#                       rows still render (general-file rows order first).
#   --expand-whitelist  echo the doc-only auto-commit whitelist: every declared
#                       `path` (merged) + the contract files + every
#                       docs/**/*.md on disk (sorted, unique).
#   --seed              echo a COMPLETE, minimal, VALID general doc-spec.md for
#                       self-bootstrap of a MISSING doc-spec.md.
#                       Does NOT require doc-spec.md to exist (that is the whole
#                       point). Source: repo-local templates/doc-spec-common.md
#                       if present, else the embedded heredoc below (so a consumer
#                       repo with only the deployed doc-spec.sh can bootstrap).
#                       Emits ONLY seed content to stdout; exit 0.
#
# audit_class closed enum: human-doc | operational.
# schema_version supported: 1.

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
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[doc-sync-no-config] $1"
  exit 1
}

# Extract the single fenced ```yaml ... ``` block from one registry file ($1).
# Prints the block body (between the fences), CRLF-stripped.
_extract_yaml_file() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$1" | _strip_cr
}

# Emit the registry files in merge order: the general file, then the overlay
# when present. Every merged read iterates this list.
_registry_files() {
  echo "$DOC_SPEC_PATH"
  [ -f "$DOC_SPEC_CUSTOM_PATH" ] && echo "$DOC_SPEC_CUSTOM_PATH"
  return 0
}

# Parse one file's registry block into TSV rows: path<TAB>section<TAB>audit_class.
# One row per `- path:` entry. Uses the same flag-based, key-anchored shape as
# the workbench's other YAML-ish parsers — no real YAML engine required.
_parse_registry_file() {
  _extract_yaml_file "$1" | awk '
    function flush() {
      if (cur_path != "") {
        printf "%s\t%s\t%s\n", cur_path, cur_section, cur_class
      }
      cur_path=""; cur_section=""; cur_class=""
    }
    /^[[:space:]]*-[[:space:]]*path:/ {
      flush()
      cur_path=$3
      next
    }
    /^[[:space:]]*section:/    { cur_section=$2; next }
    /^[[:space:]]*audit_class:/{ cur_class=$2;   next }
    END { flush() }
  '
}

# Merged TSV rows across general + overlay (general first).
_parse_registry() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_registry_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
}

_schema_version_file() {
  _extract_yaml_file "$1" | awk '/^schema_version:/ { print $2; exit }'
}

# List the merged registry paths whose `front_table` is `required`. A SEPARATE
# awk pass over each file's extracted yaml (mirrors how --list-human-docs
# filters) so the shared 3-column TSV — read with a 3-var `read` in
# _run_registry_gates — stays unchanged; a 4th TSV column would mis-bind onto
# audit_class and break the closed-enum gate. Flag-based per-entry shape:
# capture path at `- path:`, capture front_table within the entry, emit the
# path at the NEXT `- path:` (flush) or END when front_table == required.
_list_front_table_docs() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _extract_yaml_file "$_rf" | awk '
      function flush() {
        if (cur_path != "" && cur_ft == "required") { print cur_path }
        cur_path=""; cur_ft=""
      }
      /^[[:space:]]*-[[:space:]]*path:/ {
        flush()
        cur_path=$3
        next
      }
      /^[[:space:]]*front_table:/ { cur_ft=$2; next }
      END { flush() }
    '
  done <<EOF
$(_registry_files)
EOF
  true
}

# Render the merged registry entries of one section (common | custom) as a
# Markdown table: `| Doc | Purpose | Requirement |`. A SEPARATE awk pass per
# registry file (general-file rows first, overlay rows second — deterministic
# merge order) so the shared 3-column TSV stays unchanged. purpose/requirement
# are quoted, multi-word, free-form values (unlike path/section/audit_class),
# so they are extracted by stripping the `key: "…"` wrapper from the
# rest-of-line and pipe-escaping each cell (Markdown-table safe). Values are
# single-line (no YAML folding). Deterministic; no timestamps.
_render_section() {
  _want_section="$1"
  echo "| Doc | Purpose | Requirement |"
  echo "|-----|---------|-------------|"
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _extract_yaml_file "$_rf" | awk -v want="$_want_section" '
      function flush() {
        if (cur_path != "" && cur_section == want) {
          printf "| %s | %s | %s |\n", cur_path, cur_purpose, cur_req
        }
        cur_path=""; cur_section=""; cur_purpose=""; cur_req=""
      }
      function strip(line,   v) {
        v=line
        sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)   # drop `  key: "`
        sub(/"[[:space:]]*$/, "", v)                          # drop trailing `"`
        gsub(/\|/, "\\|", v)                                  # escape pipes
        return v
      }
      /^[[:space:]]*-[[:space:]]*path:/ {
        flush()
        cur_path=$3
        next
      }
      /^[[:space:]]*section:/     { cur_section=$2; next }
      /^[[:space:]]*purpose:/     { cur_purpose=strip($0); next }
      /^[[:space:]]*requirement:/ { cur_req=strip($0); next }
      END { flush() }
    '
  done <<EOF
$(_registry_files)
EOF
  true
}

# ---- Validation gates (run ONLY for registry-reading subcommands) ----
# NOTE: --seed and --help must NOT inherit these gates. --seed exists precisely
# to bootstrap a MISSING doc-spec.md; the original bug ran these gates before
# dispatch, so --seed inherited the "doc-spec.md must exist" gate and emitted a
# `[doc-sync-no-config]` halt string that callers redirected into the new file —
# corrupting it. Gates therefore run per-subcommand below, not at top level.
_validate_one_file() {
  # $1 = file path, $2 = display name for halt reasons
  _YAML_BODY=$(_extract_yaml_file "$1")
  [ -n "$_YAML_BODY" ] || emit_halt "$2 has no fenced \`\`\`yaml registry block"

  _SV=$(_schema_version_file "$1")
  [ -n "$_SV" ] || emit_halt "schema_version field missing in $2 registry"

  _SV_OK=0
  for v in $SUPPORTED_SCHEMA_VERSIONS; do
    [ "$_SV" = "$v" ] && { _SV_OK=1; break; }
  done
  [ "$_SV_OK" -eq 1 ] || emit_halt "$2 schema_version=${_SV} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"

  _FROWS=$(_parse_registry_file "$1")
  [ -n "$_FROWS" ] || emit_halt "$2 registry declares no docs (empty docs[] list)"

  # Every entry must have path + section + audit_class; audit_class in the enum.
  while IFS="$(printf '\t')" read -r _p _s _c; do
    [ -n "$_p" ] || emit_halt "a $2 registry entry is missing 'path'"
    [ -n "$_s" ] || emit_halt "$2 registry entry '$_p' is missing 'section'"
    [ -n "$_c" ] || emit_halt "$2 registry entry '$_p' is missing 'audit_class'"
    case "$_c" in
      human-doc|operational) : ;;
      *) emit_halt "$2 registry entry '$_p' has audit_class '$_c' outside the closed enum {human-doc, operational}" ;;
    esac
  done <<EOF
$_FROWS
EOF
}

_run_registry_gates() {
  [ -f "$DOC_SPEC_PATH" ] || emit_halt "doc-spec.md missing (resolved spec/-then-root): $DOC_SPEC_PATH"

  _validate_one_file "$DOC_SPEC_PATH" "doc-spec.md"
  SCHEMA_VERSION=$(_schema_version_file "$DOC_SPEC_PATH")

  # A present-but-invalid overlay halts; an absent overlay is fine (nothing to
  # merge, no finding).
  if [ -f "$DOC_SPEC_CUSTOM_PATH" ]; then
    _validate_one_file "$DOC_SPEC_CUSTOM_PATH" "doc-spec-custom.md (overlay)"
  fi

  _ROWS=$(_parse_registry)
  [ -n "$_ROWS" ] || emit_halt "doc-spec.md registry declares no docs (empty docs[] list)"

  # Duplicate-path guard across the merged registry (general + overlay): the
  # same path declared twice — in either file or across the two — is an error.
  _DUP_PATHS=$(printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')
  [ -z "${_DUP_PATHS% }" ] || emit_halt "duplicate path(s) across the doc-spec registry (general + overlay): ${_DUP_PATHS% }"
}

# ---- --check-on-disk: the deterministic conformance set (audit Stage 1) ----
# Six checks of the MERGED registry against the disk state under REPO_ROOT.
# Called AFTER _run_registry_gates (the dispatch arm runs the registry-absent
# probe itself, BEFORE the gates — a subcommand-local carve-out, since the
# parse gates halt on a missing registry, which is wrong for this caller).
# Output contract: one `check: <id> — PASS` line per clean check, one
# `FINDING: stage1/<id> — <detail>` line PER VIOLATION (a multi-violation
# check emits one line each, no PASS line), then the machine tail
# `CHECKS_RUN=<n>` (check ids run — 6 on a full run) + `FINDINGS=<n>`
# (violation lines). Returns 0 clean / 1 findings. Every loop is
# `while IFS= read -r` — the word-split defect class stays designed out
# inside this ONE tested implementation (never re-derived by an executor).
# The views-render check compares each view's TABLE BLOCK (its `^|` lines)
# against fresh --render output — NOT whole-file: view headers legitimately
# differ between workbench (generator header) and consumer (portable stub);
# the whole-file regen-diff remains validate.sh Check 23 (workbench CI).
_check_on_disk() {
  _COD_FINDINGS=0
  _COD_CHECKS=0
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

  # human-doc-ids — no audit_class: human-doc path contains a work-item ID
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
$(printf '%s\n' "$_ROWS" | awk -F'\t' '$3=="human-doc" {print $1}' | sort -u)
EOF
  if [ "$_c" -eq 0 ]; then echo "check: human-doc-ids — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  # front-table — every front_table: required path opens with a Markdown
  # table (a `|` row immediately followed by a `|---|`-style delimiter row)
  # BEFORE its first `## ` heading (the validate.sh Check 20 awk idiom).
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    [ -f "$REPO_ROOT_RESOLVED/$_p" ] || continue
    if ! awk '
      /^## / { exit }
      /^\|[ :|+-]*-[ :|+-]*\|$/ {
        if (prev ~ /^\|/) { found = 1; exit }
      }
      { prev = $0 }
      END { exit !found }
    ' "$REPO_ROOT_RESOLVED/$_p" >/dev/null 2>&1; then
      echo "FINDING: stage1/front-table — no leading summary table before the first '## ' heading: $_p"
      _c=$((_c + 1))
    fi
  done <<EOF
$(_list_front_table_docs | sort -u)
EOF
  if [ "$_c" -eq 0 ]; then echo "check: front-table — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  # views-render — only where a generated view exists on disk: its TABLE
  # BLOCK (the `^|` lines) must match fresh --render output exactly.
  _COD_CHECKS=$((_COD_CHECKS + 1))
  _c=0
  for _vw in general custom; do
    _vf="$REPO_ROOT_RESOLVED/docs/doc-$_vw.md"
    [ -f "$_vf" ] || continue
    case "$_vw" in
      general) _cod_fresh=$(_render_section common) ;;
      custom)  _cod_fresh=$(_render_section custom) ;;
    esac
    _cod_have=$(grep '^|' "$_vf" || true)
    if [ "$_cod_have" != "$_cod_fresh" ]; then
      echo "FINDING: stage1/views-render — docs/doc-$_vw.md table block does not match fresh --render $_vw output (regenerate the views)"
      _c=$((_c + 1))
    fi
  done
  if [ "$_c" -eq 0 ]; then echo "check: views-render — PASS"; fi
  _COD_FINDINGS=$((_COD_FINDINGS + _c))

  echo "CHECKS_RUN=$_COD_CHECKS"
  echo "FINDINGS=$_COD_FINDINGS"
  [ "$_COD_FINDINGS" -eq 0 ]
}

# ---- Portable seed (a COMPLETE, minimal, VALID general doc-spec.md) ----
# Source order: the repo-local published artifact templates/doc-spec-common.md
# (the maintained copy a human can read/copy), else the embedded heredoc below.
# The heredoc makes --seed self-contained so a CONSUMER repo — where only the
# deployed scripts/doc-spec.sh is present and templates/ is absent — can still
# self-bootstrap. Three copies stay byte-identical (the general spec/doc-spec.md
# file, this heredoc, templates/doc-spec-common.md): tests/
# cj-document-release-config.test.sh check 13 guards heredoc == template, and
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
repo carry, and what is each one for?** It is both the human-readable map (the
prose below) and the machine source of truth (the fenced `yaml` registry at the
end). One file, no second list to keep in sync.

This file is the **general tier** of a two-tier contract, delivered verbatim
(`doc-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific docs are declared
in an optional **`doc-spec-custom.md` overlay** next to this file (the same
fenced-yaml grammar, `section: custom` entries). The parser merges the two
internally, so every consumer sees ONE registry; a repo without an overlay
simply carries the general contract alone. Nothing about the repo's other
tooling has to change.

## The doc contract

Every repo that adopts this contract carries twelve **general docs** — the
`section: common` tier, sub-grouped below.

**Human docs** — what a person (not just an agent) reads to understand the
project:

| Doc | What it is for |
|-----|----------------|
| `docs/philosophy.md` | The major design logic — one `## Principle N` section per idea. States the repo's first principle(s). |
| `docs/workflow.md` | The major workflows from a human's point of view; names the major entry points. ASCII flowcharts preferred. |
| `docs/architecture.md` | The meaningful machinery under the hood — deeper than `workflow.md`. ASCII diagrams preferred. |
| `docs/reference.md` | Curated external references for building the workbench — repos, docs, blogs, articles, grouped by category. |
| `README.md` | The landing page: folder structure + how to get started. |

**Operational docs** — agent- and ops-facing, so they may reference work items:

| Doc | What it is for |
|-----|----------------|
| `spec/doc-spec.md` | The doc contract itself — this file (tooling resolves `spec/doc-spec.md` first, then a root `doc-spec.md` fallback). |
| `spec/test-spec.md` | The general test contract — the portable rules the repo's verification surface is held to (same two-tier shape: a `test-spec.sh --seed` general file + an optional `test-spec-custom.md` overlay). |
| `CLAUDE.md` | Agent operating instructions. |
| `CHANGELOG.md` | Release history, updated on every release. |
| `TODOS.md` | The operational backlog. |

**Generated views (human docs)** — readable lists derived from the registry, so
there is never a second list to hand-maintain:

| Doc | What it is for |
|-----|----------------|
| `docs/doc-general.md` | Readable list of the `section: common` (general) docs. |
| `docs/doc-custom.md` | Readable list of the `section: custom` docs. |

Three rules make these docs trustworthy:

- **General docs are required.** Every `section: common` doc must exist in an
  adopting repo; the doc-release skill stub-scaffolds any missing one.
  `section: custom` docs (declared in the overlay) are the repo's chosen
  additions.
- **Human docs carry no work-item IDs.** A reference of the shape
  `<F|S|T|D>` followed by six digits is internal-tracker noise; it does not
  belong in a doc a newcomer reads. This is enforced (a hard CI lint), not a
  guideline.
- **The registry is the source of truth.** The `yaml` block below — merged with
  the overlay's, when one exists — declares every doc the repo carries. Tooling
  parses it; the prose explains it. Add a doc by adding a registry entry —
  never by editing a second list somewhere else.

## How the registry is used

Two consumers parse the merged `yaml` registry (this file + the overlay):

```
  doc-spec.md (general — this file)   doc-spec-custom.md (optional overlay)
  ┌───────────────────────────┐       ┌──────────────────────────────┐
  │ Common prose               │       │ repo-specific prose          │
  │ yaml machine registry      │       │ yaml registry — section:     │
  │   schema_version: 1        │       │   custom entries in the      │
  │   docs[]: path / section / │       │   same grammar               │
  │     audit_class / purpose /│       └───────────────┬──────────────┘
  │     requirement /          │                       │
  │     front_table (optional) │                       │
  └───────────┬────────────────┘                       │
              └────────────────┬───────────────────────┘
                               │ merged by the parser (duplicate path ⇒ error)
                ┌──────────────┴───────────────┐
                │ parses                       │ parses
    ┌───────────▼──┐                     ┌─────▼─────────────────┐
    │ a CI validator│                     │ a doc-release skill   │
    │ declared ⇔    │                     │ self-bootstrap missing│
    │  on-disk      │                     │  doc-spec.md          │
    │ schema valid  │                     │ stub missing docs     │
    │ no work-item  │                     │ audit each vs its     │
    │  IDs in human │                     │  requirement          │
    │  docs         │                     │ derive doc whitelist  │
    └───────────────┘                     └───────────────────────┘
```

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` is declared (no orphans), that the merged registry schema
  is valid, and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + the contract files + `docs/**/*.md`).

## audit_class (closed enum)

Each registry entry declares one `audit_class`:

- **`human-doc`** — human-facing. Must exist; must contain **no work-item IDs**
  (`[FSTD]NNNNNN`); ASCII flowcharts/diagrams preferred (advisory).
- **`operational`** — must exist; work-item references are allowed (these are
  agent/ops docs, e.g. a changelog or an agent-instructions file).

## front_table (optional field)

A registry entry MAY carry `front_table: required` — enforced only where the
field is present. A flagged doc must **open with a summary table**: the first
Markdown table (a `|`-row immediately followed by a `|---|`-style delimiter
row) must appear **before the doc's first `## ` heading**, giving a reader an
at-a-glance index. The gate asserts a leading table only — it does not
prescribe the table's columns. The seed flags `docs/philosophy.md` (a row per
principle) and `docs/workflow.md` (a row per major workflow/entry point); a
stub-scaffolded copy of a flagged doc must therefore open with a summary
table. Flagging another doc later is a one-line registry edit — no validator
change.

<!-- DOC-SPEC-COMMON:END -->

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file.

```yaml
# doc-spec registry (parsed by scripts/doc-spec.sh; merged with the optional
# doc-spec-custom.md overlay; consumed by a CI validator + a doc-release skill)
schema_version: 1
docs:
  - path: docs/philosophy.md
    section: common
    audit_class: human-doc
    front_table: required
    purpose: "Major design logic, one '## Principle N' section each."
    requirement: "Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs; opens with a summary table at the top listing every principle."
  - path: docs/workflow.md
    section: common
    audit_class: human-doc
    front_table: required
    purpose: "The major workflows from a human's perspective; names the major entry points."
    requirement: "Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs; opens with a summary table at the top listing every major workflow/entry point."
  - path: docs/architecture.md
    section: common
    audit_class: human-doc
    purpose: "Meaningful infra under the hood, deeper than workflow.md."
    requirement: "Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs."
  - path: docs/reference.md
    section: common
    audit_class: human-doc
    purpose: "Curated external references for building this workbench — repos, docs, blogs, articles — grouped by category."
    requirement: "Lists useful external references (repos / links / blogs / articles) relevant to building this workbench, grouped by category, each with a one-line note on why it is relevant; human-readable; no work-item IDs."
  - path: README.md
    section: common
    audit_class: human-doc
    purpose: "Repo landing page: folder structure + how to get started."
    requirement: "Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs."
  - path: spec/doc-spec.md
    section: common
    audit_class: operational
    purpose: "The doc contract itself (this file — the general tier, delivered verbatim by doc-spec.sh --seed)."
    requirement: "Present; byte-identical to the portable seed (doc-spec.sh --seed); registry parses with schema_version 1; repo-specific docs live in the optional doc-spec-custom.md overlay, never in this file."
  - path: spec/test-spec.md
    section: common
    audit_class: operational
    purpose: "The general test contract — portable rules for the repo's verification surface (parsed by test-spec.sh)."
    requirement: "Present; the general test contract — rules current against the live verification surface; registry parses with schema_version 1; repo-specific units live in the optional test-spec-custom.md overlay."
  - path: CLAUDE.md
    section: common
    audit_class: operational
    purpose: "Agent operating instructions (auto-loaded by Claude Code)."
    requirement: "Present; work-item references allowed (operational doc)."
  - path: CHANGELOG.md
    section: common
    audit_class: operational
    purpose: "Release history (keep-a-changelog)."
    requirement: "Present; updated by /ship + /document-release."
  - path: TODOS.md
    section: common
    audit_class: operational
    purpose: "The operational backlog."
    requirement: "Present; work-item references allowed (operational doc)."
  - path: docs/doc-general.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: common (general) registry docs."
    requirement: "Generated from the doc-spec registry via doc-spec.sh --render general; kept matching the merged registry; do not hand-edit."
  - path: docs/doc-custom.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: custom registry docs."
    requirement: "Generated from the doc-spec registry via doc-spec.sh --render custom; kept matching the merged registry; do not hand-edit."
```
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
    printf '%s\n' "$_ROWS" | awk -F'\t' '$3=="human-doc" {print $1}' | sort -u
    ;;
  --list-front-table-docs)
    _run_registry_gates
    _list_front_table_docs | sort -u
    ;;
  --render)
    _run_registry_gates
    case "${2:-}" in
      general) _render_section common ;;
      custom)  _render_section custom ;;
      *) echo "doc-spec.sh --render: expected 'general' or 'custom'" >&2; exit 2 ;;
    esac
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
optional doc-spec-custom.md overlay; all reads operate on the merge).

Usage:
  doc-spec.sh --validate          # exit 0 if the merged registry is ok
  doc-spec.sh --check-on-disk     # deterministic conformance set (Stage-1 engine):
                                  #   6 checks vs disk; FINDING: stage1/<id> lines +
                                  #   CHECKS_RUN=/FINDINGS= tail; registry-absent =>
                                  #   REGISTRY=absent + exit 0 (probe before gates)
  doc-spec.sh --list-declared     # every declared path (merged)
  doc-spec.sh --list-human-docs   # only audit_class: human-doc paths (merged)
  doc-spec.sh --list-front-table-docs  # only paths with front_table: required (merged)
  doc-spec.sh --render general    # Markdown table of the section:common docs
  doc-spec.sh --render custom     # Markdown table of the section:custom docs (the overlay)
  doc-spec.sh --expand-whitelist  # doc-only auto-commit whitelist (merged)
  doc-spec.sh --seed              # complete minimal valid general doc-spec.md (self-bootstrap)
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--check-on-disk|--list-declared|--list-human-docs|--list-front-table-docs|--render general|custom|--expand-whitelist|--seed}" >&2
    exit 2
    ;;
  *)
    echo "doc-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
