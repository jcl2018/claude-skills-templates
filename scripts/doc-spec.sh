#!/usr/bin/env bash
# doc-spec.sh — parse + validate the doc-spec.md registry; derive the doc-only
# auto-commit whitelist; emit the portable Common seed for self-bootstrap.
#
# doc-spec.md is the single source of truth for "what docs does this repo carry
# and what is each for." It carries a portable Common section, a repo Custom
# section, and ONE fenced ```yaml machine registry. This helper parses that
# registry (no python/yaml dependency — awk only, portable to bash 3.2) and is
# consumed by scripts/validate.sh + the /CJ_document-release skill.
#
# Strict posture (registry-reading subcommands only): doc-spec.md missing OR no
# yaml registry OR schema_version unsupported OR an entry missing
# path/section/audit_class OR an audit_class outside the closed enum  ->  HALT
# with `[doc-sync-no-config] <reason>` on stdout + exit 1. These gates run via
# _run_registry_gates() ONLY for --validate/--list-declared/--list-human-docs/
# --expand-whitelist. --seed and --help do NOT inherit them (see --seed).
#
# Subcommands:
#   --validate          exit 0 + print `OK schema_version=<n>` if the registry is
#                       valid; exit 1 + halt-emit otherwise.
#   --list-declared     echo every declared `path` (sorted, unique).
#   --list-human-docs   echo only the `audit_class: human-doc` paths.
#   --list-front-table-docs
#                       echo only the paths whose `front_table` is `required`
#                       (the workbench-local registry field consumed by
#                       validate.sh Check 20). Separate awk pass; the shared
#                       3-column TSV is unchanged.
#   --expand-whitelist  echo the doc-only auto-commit whitelist: every declared
#                       `path` + doc-spec.md + every docs/**/*.md on disk
#                       (sorted, unique).
#   --seed              echo a COMPLETE, minimal, VALID doc-spec.md (Common +
#                       Custom placeholder + a yaml registry of the four common
#                       human-docs) for self-bootstrap of a MISSING doc-spec.md.
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
# adopters / the portable seed convention). POSIX/bash-3.2 idiom.
DOC_SPEC_PATH="${DOC_SPEC_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/doc-spec.md" ] && echo "$REPO_ROOT_RESOLVED/spec/doc-spec.md" || echo "$REPO_ROOT_RESOLVED/doc-spec.md" )}"
SEED_TEMPLATE="${REPO_ROOT_RESOLVED}/templates/doc-spec-common.md"
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[doc-sync-no-config] $1"
  exit 1
}

# Extract the single fenced ```yaml ... ``` block from doc-spec.md.
# Prints the block body (between the fences), CRLF-stripped.
_extract_yaml() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$DOC_SPEC_PATH" | _strip_cr
}

# Parse the registry block into TSV rows: path<TAB>section<TAB>audit_class.
# One row per `- path:` entry. Uses the same flag-based, key-anchored shape as
# the workbench's other YAML-ish parsers — no real YAML engine required.
_parse_registry() {
  _extract_yaml | awk '
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

_schema_version() {
  _extract_yaml | awk '/^schema_version:/ { print $2; exit }'
}

# List the registry paths whose `front_table` is `required`. A SEPARATE awk pass
# over the extracted yaml (mirrors how --list-human-docs filters) so the shared
# _parse_registry 3-column TSV — read with a 3-var `read` in _run_registry_gates
# — stays unchanged; a 4th TSV column would mis-bind onto audit_class and break
# the closed-enum gate. Flag-based per-entry shape: capture path at `- path:`,
# capture front_table within the entry, emit the path at the NEXT `- path:`
# (flush) or END when front_table == required.
_list_front_table_docs() {
  _extract_yaml | awk '
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
  ' | sort -u
}

# Render the registry entries of one section (common | custom) as a Markdown
# table: `| Doc | Purpose | Requirement |`. A SEPARATE awk pass over the
# extracted yaml (mirrors _list_front_table_docs) so the shared _parse_registry
# 3-column TSV stays unchanged — a 4th TSV column would mis-bind onto audit_class
# and break the closed-enum gate. purpose/requirement are quoted, multi-word,
# free-form values (unlike path/section/audit_class), so they are extracted by
# stripping the `key: "…"` wrapper from the rest-of-line and pipe-escaping each
# cell (Markdown-table safe). Values are single-line (no YAML folding). Flag-based
# per-entry shape: capture path at `- path:`, capture section/purpose/requirement
# within the entry, emit the row at the NEXT `- path:` (flush) or END when the
# entry's section matches the requested one. Deterministic; no timestamps.
_render_section() {
  _want_section="$1"
  {
    echo "| Doc | Purpose | Requirement |"
    echo "|-----|---------|-------------|"
    _extract_yaml | awk -v want="$_want_section" '
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
  }
}

# ---- Validation gates (run ONLY for registry-reading subcommands) ----
# NOTE: --seed and --help must NOT inherit these gates. --seed exists precisely
# to bootstrap a MISSING doc-spec.md; the original bug ran these gates before
# dispatch, so --seed inherited the "doc-spec.md must exist" gate and emitted a
# `[doc-sync-no-config]` halt string that callers redirected into the new file —
# corrupting it. Gates therefore run per-subcommand below, not at top level.
_run_registry_gates() {
  [ -f "$DOC_SPEC_PATH" ] || emit_halt "doc-spec.md missing (resolved spec/-then-root): $DOC_SPEC_PATH"

  _YAML_BODY=$(_extract_yaml)
  [ -n "$_YAML_BODY" ] || emit_halt "doc-spec.md has no fenced \`\`\`yaml registry block"

  SCHEMA_VERSION=$(_schema_version)
  [ -n "$SCHEMA_VERSION" ] || emit_halt "schema_version field missing in doc-spec.md registry"

  SCHEMA_OK=0
  for v in $SUPPORTED_SCHEMA_VERSIONS; do
    [ "$SCHEMA_VERSION" = "$v" ] && { SCHEMA_OK=1; break; }
  done
  [ "$SCHEMA_OK" -eq 1 ] || emit_halt "schema_version=${SCHEMA_VERSION} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"

  _ROWS=$(_parse_registry)
  [ -n "$_ROWS" ] || emit_halt "doc-spec.md registry declares no docs (empty docs[] list)"

  # Every entry must have path + section + audit_class; audit_class in the enum.
  while IFS="$(printf '\t')" read -r _p _s _c; do
    [ -n "$_p" ] || emit_halt "a registry entry is missing 'path'"
    [ -n "$_s" ] || emit_halt "registry entry '$_p' is missing 'section'"
    [ -n "$_c" ] || emit_halt "registry entry '$_p' is missing 'audit_class'"
    case "$_c" in
      human-doc|operational) : ;;
      *) emit_halt "registry entry '$_p' has audit_class '$_c' outside the closed enum {human-doc, operational}" ;;
    esac
  done <<EOF
$_ROWS
EOF
}

# ---- Portable seed (a COMPLETE, minimal, VALID doc-spec.md) ----
# Source order: the repo-local published artifact templates/doc-spec-common.md
# (the maintained copy a human can read/copy), else the embedded heredoc below.
# The heredoc makes --seed self-contained so a CONSUMER repo — where only the
# deployed scripts/doc-spec.sh is present and templates/ is absent — can still
# self-bootstrap. The two are kept byte-identical by a no-drift test in
# tests/cj-document-release-config.test.sh.
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

A repo adopts this contract by dropping in this file: copy the **Common**
section verbatim, then fill the **Custom** section with whatever else the repo
carries. Nothing about the repo's other tooling has to change.

## The doc contract

Every repo that adopts this contract carries four **human docs** — the docs a
person (not just an agent) reads to understand the project:

| Doc | What it is for |
|-----|----------------|
| `docs/philosophy.md` | The major design logic — one `## Principle N` section per idea. States the repo's first principle(s). |
| `docs/workflow.md` | The major workflows from a human's point of view; names the major entry points. ASCII flowcharts preferred. |
| `docs/architecture.md` | The meaningful machinery under the hood — deeper than `workflow.md`. ASCII diagrams preferred. |
| `README.md` | The landing page: folder structure + how to get started. |

Two rules make these docs trustworthy:

- **Human docs carry no work-item IDs.** A reference of the shape
  `<F|S|T|D>` followed by six digits is internal-tracker noise; it does not
  belong in a doc a newcomer reads. This is enforced (a hard CI lint), not a
  guideline.
- **The registry is the source of truth.** The `yaml` block below declares every
  doc the repo carries. Tooling parses it; the prose explains it. Add a doc by
  adding a registry entry — never by editing a second list somewhere else.

## How the registry is used

Two consumers parse the `yaml` registry:

```
            doc-spec.md  (this file)
            ┌───────────────────────────┐
            │ Common prose + Custom prose│
            │ yaml machine registry      │
            │   schema_version: 1        │
            │   docs[]: path / section / │
            │     audit_class / purpose /│
            │     requirement            │
            └───────┬───────────────┬────┘
                    │ parses        │ parses
        ┌───────────▼──┐      ┌─────▼─────────────────┐
        │ a CI validator│      │ a doc-release skill   │
        │ declared ⇔    │      │ self-bootstrap missing│
        │  on-disk      │      │  doc-spec.md          │
        │ schema valid  │      │ stub missing docs     │
        │ no work-item  │      │ audit each vs its     │
        │  IDs in human │      │  requirement          │
        │  docs         │      │ derive doc whitelist  │
        └───────────────┘      └───────────────────────┘
```

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` is declared (no orphans), that the registry schema is valid,
  and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable Common seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + `doc-spec.md` + `docs/**/*.md`).

## audit_class (closed enum)

Each registry entry declares one `audit_class`:

- **`human-doc`** — human-facing. Must exist; must contain **no work-item IDs**
  (`[FSTD]NNNNNN`); ASCII flowcharts/diagrams preferred (advisory).
- **`operational`** — must exist; work-item references are allowed (these are
  agent/ops docs, e.g. a changelog or an agent-instructions file).

<!-- DOC-SPEC-COMMON:END -->

<!-- DOC-SPEC-CUSTOM:BEGIN (this repo only — edit freely) -->
## Custom: this repo's additional docs

A freshly bootstrapped repo carries no extra docs yet. Add any repo-specific
docs here in prose, and a matching entry (with `section: custom`) in the
registry below.

<!-- DOC-SPEC-CUSTOM:END -->

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file.

```yaml
# doc-spec registry (parsed by scripts/validate.sh + /CJ_document-release)
schema_version: 1
docs:
  - path: docs/philosophy.md
    section: common
    audit_class: human-doc
    purpose: "Major design logic, one '## Principle N' section each."
    requirement: "Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs."
  - path: docs/workflow.md
    section: common
    audit_class: human-doc
    purpose: "The major workflows from a human's perspective; names the major entry points."
    requirement: "Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs."
  - path: docs/architecture.md
    section: common
    audit_class: human-doc
    purpose: "Meaningful infra under the hood, deeper than workflow.md."
    requirement: "Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs."
  - path: README.md
    section: common
    audit_class: human-doc
    purpose: "Repo landing page: folder structure + how to get started."
    requirement: "Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs."
  - path: doc-spec.md
    section: custom
    audit_class: operational
    purpose: "The doc contract itself (this file)."
    requirement: "Present; Common section verbatim from the seed; registry parses with schema_version 1."
```
DOCSPEC_SEED
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
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
    _list_front_table_docs
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
      # Every declared path.
      printf '%s\n' "$_ROWS" | awk -F'\t' '{print $1}'
      # doc-spec.md itself (this repo: spec/doc-spec.md, post-relocation).
      echo "spec/doc-spec.md"
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
doc-spec.sh — parse + validate the doc-spec.md registry.

Usage:
  doc-spec.sh --validate          # exit 0 if registry schema ok
  doc-spec.sh --list-declared     # every declared path
  doc-spec.sh --list-human-docs   # only audit_class: human-doc paths
  doc-spec.sh --list-front-table-docs  # only paths with front_table: required
  doc-spec.sh --render general    # Markdown table of the section:common docs
  doc-spec.sh --render custom     # Markdown table of the section:custom docs
  doc-spec.sh --expand-whitelist  # doc-only auto-commit whitelist
  doc-spec.sh --seed              # complete minimal valid doc-spec.md (self-bootstrap)
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--list-declared|--list-human-docs|--list-front-table-docs|--render general|custom|--expand-whitelist|--seed}" >&2
    exit 2
    ;;
  *)
    echo "doc-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
