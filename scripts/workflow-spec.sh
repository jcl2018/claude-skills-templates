#!/usr/bin/env bash
# workflow-spec.sh — parse + validate the workflow-docs registry (spec/workflow-spec.md)
# and RENDER the entire workflow documentation surface from it.
#
# spec/workflow-spec.md is the single source of truth for the workbench's workflow
# documentation: the docs/workflow.md index plus the six docs/workflows/*.md files
# (the four CJ_goal_* orchestrator pages + the two prose rosters
# utilities-and-phase-steps.md and utility-audits.md). This engine is the THIRD
# instance of the proven README ↔ generate-readme.sh ↔ Check 25 + test-catalog ↔
# test-spec.sh --render-docs ↔ Check 26 generate→freshness→audit primitive, applied
# to the workflow surface. The renderer is PURE: registry in → deterministic docs
# out; `--render-docs --check` is the single freshness owner (validate.sh Check 27
# AND /CJ_doc_audit Stage 1 both call it). awk only — no python/yaml dependency;
# mirrors scripts/doc-spec.sh + scripts/test-spec.sh.
#
# The registry has TWO entry shapes (one `## <name>` section each):
#   orchestrator (the 4 CJ_goal_*): kind: orchestrator + single-line status/
#       category/source/invoke_when fields + five four-backtick fenced blocks
#       (chart, summary, touches-skills, touches-steps, touches-scripts,
#       touches-docs) — wait, six blocks: chart + summary + the four touches axes.
#   roster (the 2 prose docs): kind: roster + one four-backtick fenced `body` block.
# PLUS a header block (<!-- WORKFLOW-SPEC-HEADER:BEGIN/END -->, a four-backtick
# fenced `header` block) holding the docs/workflow.md index prose preamble.
#
# Four-backtick fences (````) wrap the registry's verbatim blocks because the
# migrated content itself contains three-backtick (```) fences (the charts + the
# utility-audits roster's own workflow chart). Extraction is unambiguous: a line of
# exactly four backticks followed by the block name opens; a line of exactly four
# backticks closes.
#
# Absent-vs-invalid split (the doc-spec.sh / test-spec.sh lesson): when
# spec/workflow-spec.md (resolved spec/-then-root) does not exist, every
# registry-reading subcommand prints `REGISTRY=absent` and exits 0 — a distinct,
# machine-classifiable skip, never a halt. A PRESENT-but-invalid registry HALTs
# with `[workflow-spec-no-config] <reason>` on stdout + exit 1.
#
# Subcommands:
#   --validate         REGISTRY=absent + exit 0 when absent; exit 0 + `OK ...`
#                      when valid; exit 1 + halt-emit otherwise. Enforces per-kind
#                      required fields, the closed `kind` enum, AND
#                      registry-completeness: every routable CJ_goal_* skill
#                      (jq skills-catalog.json, status != deprecated, non-empty
#                      files) has an orchestrator entry — the no-vanish guarantee
#                      (the replacement for retired validate.sh Check 15c).
#   --list-workflows   echo every declared workflow name (registry order).
#   --render-docs      render docs/workflow.md + docs/workflows/<name>.md (×N)
#                      from the registry to a NORMALIZED deterministic template
#                      (stable order, fixed headers, no timestamps, ID-free).
#   --render-docs --check  render to a temp dir, diff vs on-disk, exit 0 if fresh,
#                      1 + a finding list on any mismatch/missing/orphan file.
#   --classify         READ-ONLY generation detector, symmetric with the other
#                      engines: GENERATION=<absent|canonical|malformed>,
#                      POSITIONS=, DUPLICATE=<0|1>, CANONICAL_PATH=spec/workflow-spec.md.
#   --seed             echo a minimal valid skeleton registry (header + contract
#                      prose, ZERO workflow sections) so a consumer repo with no
#                      orchestrators is vacuously registry-complete. Does NOT
#                      require the registry to exist.
#   --help|-h
#
# kind closed enum: orchestrator | roster.

set -eu

# Strip CRLF from any command output on Windows. No-op on Unix.
_strip_cr() { tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests / temp-dir drills).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: WORKFLOW_SPEC_PATH env override (outermost) ->
# spec/workflow-spec.md (this repo) -> root workflow-spec.md (root-only consumers).
# Same spec/-then-root idiom as the sibling helpers.
WORKFLOW_SPEC_PATH="${WORKFLOW_SPEC_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/workflow-spec.md" ] && echo "$REPO_ROOT_RESOLVED/spec/workflow-spec.md" || echo "$REPO_ROOT_RESOLVED/workflow-spec.md" )}"
# The docs output root (default $REPO_ROOT/docs) is overridable via WORKFLOWDOC_OUT
# so --check can render into a temp dir and diff vs on-disk without touching the
# committed tree.

emit_halt() {
  echo "[workflow-spec-no-config] $1"
  exit 1
}

# The distinct registry-absent path. Callers classify skip-vs-findings on this
# literal without parsing halt prose.
_emit_absent_and_exit() {
  echo "REGISTRY=absent"
  exit 0
}

# ---- Parsing primitives ----

# Echo every `## <name>` workflow-section name in registry (declaration) order. A
# section header is a line `## <name>` at column 0. Only `## ` headings that sit
# (1) AFTER the WORKFLOW-SPEC-HEADER:END marker (so the leading contract prose's
# own `## Grammar` / `## Rendered output` headings are skipped) and (2) OUTSIDE any
# four-backtick fenced block (a roster body may carry its own `## ` Markdown
# headings — those must not be mistaken for section headers) are counted.
_list_sections() {
  awk '
    /^<!-- WORKFLOW-SPEC-HEADER:END/ { past_header=1; next }
    !past_header { next }
    /^````/ { infence = !infence; next }
    infence { next }
    /^## /  { name=$0; sub(/^## /, "", name); print name }
  ' "$WORKFLOW_SPEC_PATH" | _strip_cr
}

# Extract a single four-backtick fenced block by name from the WHOLE registry.
# $1 = block name (e.g. "header"). Emits the block body verbatim (between the
# opening ```` <name> line and the next bare ```` line). The FIRST matching block
# wins. Used for the global header block.
_extract_named_block() {
  awk -v want="$1" '
    !inblock && $0 == "````" want { inblock=1; next }
    inblock && /^````$/ { exit }
    inblock { print }
  ' "$WORKFLOW_SPEC_PATH" | _strip_cr
}

# Extract a single four-backtick fenced block by name WITHIN a given section.
# $1 = section name, $2 = block name. Emits the block body verbatim. Scoped: only
# blocks appearing AFTER the section's `## <name>` header and BEFORE the next
# `## <other>` header (at column 0, outside any fence) are considered.
_extract_section_block() {
  awk -v sec="$1" -v want="$2" '
    # Section boundary tracking (only honor `## ` headers outside a fence).
    !inblock && /^## / {
      cur=$0; sub(/^## /, "", cur)
      insec = (cur == sec) ? 1 : 0
      next
    }
    # Block open/close (four-backtick fences).
    insec && !inblock && $0 == "````" want { inblock=1; next }
    inblock && /^````$/ { inblock=0; done=1; exit }
    inblock { print }
  ' "$WORKFLOW_SPEC_PATH" | _strip_cr
}

# Extract a single-line `key: value` field WITHIN a given section. $1 = section
# name, $2 = key. Emits the value (everything after `key: `). Only the field lines
# that sit between the section header and its first fenced block (outside any
# fence) are honored.
_extract_section_field() {
  awk -v sec="$1" -v key="$2" '
    /^````/ { infence = !infence; next }
    infence { next }
    /^## / { cur=$0; sub(/^## /, "", cur); insec = (cur == sec) ? 1 : 0; next }
    insec && $0 ~ "^" key ":" {
      v=$0; sub("^" key ":[[:space:]]*", "", v); print v; exit
    }
  ' "$WORKFLOW_SPEC_PATH" | _strip_cr
}

# The `kind` field of a section. Empty when the section declares none.
_section_kind() {
  _extract_section_field "$1" "kind"
}

# ---- Validation ----

_run_registry_gates() {
  [ -f "$WORKFLOW_SPEC_PATH" ] || _emit_absent_and_exit

  # The registry markers must bracket the file.
  grep -q '^<!-- WORKFLOW-SPEC:BEGIN' "$WORKFLOW_SPEC_PATH" || emit_halt "spec/workflow-spec.md is missing the <!-- WORKFLOW-SPEC:BEGIN --> marker"
  grep -q '^<!-- WORKFLOW-SPEC:END' "$WORKFLOW_SPEC_PATH"   || emit_halt "spec/workflow-spec.md is missing the <!-- WORKFLOW-SPEC:END --> marker"

  # The header block must exist (it holds the index preamble; rendering needs it).
  _HEADER=$(_extract_named_block "header")
  [ -n "$_HEADER" ] || emit_halt "spec/workflow-spec.md has no fenced \`\`\`\`header block (the docs/workflow.md index preamble)"

  _SECTIONS=$(_list_sections)

  # Duplicate section-name guard.
  _N_S=$(printf '%s\n' "$_SECTIONS" | grep -c . || true)
  _N_SU=$(printf '%s\n' "$_SECTIONS" | sort -u | grep -c . || true)
  [ "$_N_S" -eq "$_N_SU" ] || emit_halt "duplicate workflow section name(s): $(printf '%s\n' "$_SECTIONS" | sort | uniq -d | tr '\n' ' ')"

  # Per-section required fields + closed kind enum.
  while IFS= read -r _name; do
    [ -n "$_name" ] || continue
    _kind=$(_section_kind "$_name")
    [ -n "$_kind" ] || emit_halt "workflow '$_name' is missing the 'kind:' field"
    case "$_kind" in
      orchestrator)
        for _f in status category source invoke_when; do
          _v=$(_extract_section_field "$_name" "$_f")
          [ -n "$_v" ] || emit_halt "orchestrator '$_name' is missing the '$_f:' field"
        done
        for _b in chart summary touches-skills touches-steps touches-scripts touches-docs; do
          _bv=$(_extract_section_block "$_name" "$_b")
          [ -n "$_bv" ] || emit_halt "orchestrator '$_name' is missing the \`\`\`\`$_b block"
        done
        ;;
      roster)
        _bv=$(_extract_section_block "$_name" "body")
        [ -n "$_bv" ] || emit_halt "roster '$_name' is missing the \`\`\`\`body block"
        ;;
      *)
        emit_halt "workflow '$_name' has kind '$_kind' outside the closed enum {orchestrator, roster}"
        ;;
    esac
  done <<EOF
$_SECTIONS
EOF

  # Registry-completeness — the no-vanish guarantee (replaces retired Check 15c).
  # Every routable CJ_goal_* skill MUST have an orchestrator entry. Enumerated
  # dynamically from skills-catalog.json (status != deprecated, non-empty files,
  # name startswith CJ_goal_); GUARDED — a consumer repo with no catalog is
  # vacuously complete (no CJ_goal_* skills to vanish).
  _CATALOG="$REPO_ROOT_RESOLVED/skills-catalog.json"
  if [ -f "$_CATALOG" ] && command -v jq >/dev/null 2>&1; then
    while IFS= read -r _gskill; do
      [ -n "$_gskill" ] || continue
      _ek=$(_section_kind "$_gskill")
      if [ -z "$_ek" ]; then
        emit_halt "registry-completeness (no-vanish): routable CJ_goal_* skill '$_gskill' has NO entry in spec/workflow-spec.md — every CJ_goal_* orchestrator must have a '## $_gskill' orchestrator section"
      fi
      [ "$_ek" = "orchestrator" ] || emit_halt "registry-completeness (no-vanish): routable CJ_goal_* skill '$_gskill' has kind '$_ek' in spec/workflow-spec.md — a CJ_goal_* entry must be kind: orchestrator"
    done <<EOF
$(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | select(.name | startswith("CJ_goal_")) | .name' "$_CATALOG" 2>/dev/null)
EOF
  fi
}

# ---- Render ----

# The generated-file banner (mirrors generate-readme.sh / test-spec.sh intent).
# $1 = the regenerate command shown to the reader.
_render_banner() {
  echo "<!-- GENERATED FILE — do not edit by hand."
  echo "     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:"
  echo "     $1"
  echo "     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->"
}

# Work-item-ID masker (load-bearing for Check 19). The rendered human-docs must be
# ID-free; mask each `[FSTD]NNNNNN` token with a neutral `[id]` so a stray ID in
# the registry prose never leaks into a generated human-doc.
_mask_ids() {
  sed -E 's/[FSTD][0-9]{6}/[id]/g'
}

# Render the docs/workflow.md index page to stdout. Preamble (the header block)
# verbatim, then a deterministic index table over all sections in registry order.
_render_index_page() {
  # Header preamble verbatim (ID-masked defensively).
  _extract_named_block "header" | _mask_ids
  echo ""
  _render_banner "scripts/workflow-spec.sh --render-docs"
  echo ""
  echo "## The index"
  echo ""
  echo "| Workflow | Kind | Detail |"
  echo "|----------|------|--------|"
  while IFS= read -r _name; do
    [ -n "$_name" ] || continue
    _k=$(_section_kind "$_name")
    # shellcheck disable=SC2016  # backticks are literal Markdown in the printf format, not command substitution
    printf '| `%s` | %s | [workflows/%s.md](workflows/%s.md) |\n' \
      "$_name" "$_k" "$_name" "$_name"
  done <<EOF
$(_list_sections)
EOF
}

# Render ONE orchestrator page to stdout. $1 = section name.
_render_orchestrator_page() {
  _op_name="$1"
  echo "### $_op_name"
  echo ""
  _render_banner "scripts/workflow-spec.sh --render-docs"
  echo ""
  echo "**Status:** $(_extract_section_field "$_op_name" status | _mask_ids)"
  echo "**Category:** $(_extract_section_field "$_op_name" category | _mask_ids)"
  echo "**Source:** $(_extract_section_field "$_op_name" source | _mask_ids)"
  echo ""
  echo "**Invoke when:** $(_extract_section_field "$_op_name" invoke_when | _mask_ids)"
  echo ""
  echo "**Workflow:**"
  echo ""
  echo '```'
  _extract_section_block "$_op_name" chart | _mask_ids
  echo '```'
  echo ""
  printf '**In words:** '
  _extract_section_block "$_op_name" summary | _mask_ids
  echo ""
  echo "**Touches:**"
  echo ""
  _extract_section_block "$_op_name" touches-skills | _mask_ids
  _extract_section_block "$_op_name" touches-steps | _mask_ids
  _extract_section_block "$_op_name" touches-scripts | _mask_ids
  _extract_section_block "$_op_name" touches-docs | _mask_ids
}

# Render ONE roster page to stdout. $1 = section name. The body block is emitted
# verbatim AFTER the generated-file banner.
_render_roster_page() {
  _rp_name="$1"
  _render_banner "scripts/workflow-spec.sh --render-docs"
  echo ""
  _extract_section_block "$_rp_name" body | _mask_ids
}

# Render ONE page (dispatch by kind) to stdout. $1 = section name.
_render_page() {
  _rpg_name="$1"
  _rpg_kind=$(_section_kind "$_rpg_name")
  case "$_rpg_kind" in
    orchestrator) _render_orchestrator_page "$_rpg_name" ;;
    roster)       _render_roster_page "$_rpg_name" ;;
  esac
}

# Render the full workflow surface into a target docs dir. $1 = docs root (created
# if absent). Writes docs/workflow.md + docs/workflows/<name>.md per section.
_render_into() {
  _ri_docs="$1"
  mkdir -p "$_ri_docs/workflows"
  _render_index_page > "$_ri_docs/workflow.md"
  while IFS= read -r _name; do
    [ -n "$_name" ] || continue
    _render_page "$_name" > "$_ri_docs/workflows/$_name.md"
  done <<EOF
$(_list_sections)
EOF
  return 0
}

# --render-docs: write the surface into the live docs/ tree (or WORKFLOWDOC_OUT).
# --render-docs --check: render into a temp dir, diff vs on-disk, exit 0 if
# identical, exit 1 + a finding list if any file is missing/differs/orphaned.
_render_docs() {
  _RD_DOCS="${WORKFLOWDOC_OUT:-$REPO_ROOT_RESOLVED/docs}"
  if [ "${1:-}" = "--check" ] || [ "${1:-}" = "--check-render" ]; then
    _RD_TMP=$(mktemp -d -t workflow-spec-render-XXXXXX)
    WORKFLOWDOC_OUT="$_RD_TMP/docs" _render_into "$_RD_TMP/docs" >/dev/null 2>&1 || _render_into "$_RD_TMP/docs"
    _RD_FINDINGS=0
    # Forward: every freshly-rendered file must exist + match on disk.
    while IFS= read -r _gen; do
      [ -n "$_gen" ] || continue
      _rel="${_gen#"$_RD_TMP/docs/"}"
      _live="$_RD_DOCS/$_rel"
      if [ ! -f "$_live" ]; then
        echo "FINDING: render — docs/$_rel is missing on disk (run: scripts/workflow-spec.sh --render-docs)"
        _RD_FINDINGS=$((_RD_FINDINGS + 1))
      elif ! diff -q "$_live" "$_gen" >/dev/null 2>&1; then
        echo "FINDING: render — docs/$_rel is stale vs the registry (run: scripts/workflow-spec.sh --render-docs)"
        _RD_FINDINGS=$((_RD_FINDINGS + 1))
      fi
    done <<EOF
$(find "$_RD_TMP/docs" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)
EOF
    # Reverse: an on-disk docs/workflows/*.md with NO freshly-rendered counterpart
    # is an orphan page (a workflow was removed from the registry but its page
    # lingers) — also a freshness finding.
    if [ -d "$_RD_DOCS/workflows" ]; then
      while IFS= read -r _disk; do
        [ -n "$_disk" ] || continue
        _rel="${_disk#"$_RD_DOCS/"}"
        if [ ! -f "$_RD_TMP/docs/$_rel" ]; then
          echo "FINDING: render — docs/$_rel exists on disk but no longer maps to a registry workflow (run: scripts/workflow-spec.sh --render-docs)"
          _RD_FINDINGS=$((_RD_FINDINGS + 1))
        fi
      done <<EOF
$(find "$_RD_DOCS/workflows" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)
EOF
    fi
    rm -rf "$_RD_TMP"
    if [ "$_RD_FINDINGS" -gt 0 ]; then
      echo "RENDER: findings=$_RD_FINDINGS (the generated workflow surface is stale — run: scripts/workflow-spec.sh --render-docs)"
      return 1
    fi
    echo "OK render — generated workflow surface in sync with the registry (findings=0)"
    return 0
  fi
  # Plain --render-docs: write into the live tree.
  _render_into "$_RD_DOCS"
  echo "OK render — wrote docs/workflow.md + $(_list_sections | grep -c . || true) docs/workflows/<name>.md page(s) to $_RD_DOCS"
  return 0
}

# ---- --classify ----
# READ-ONLY generation detector, symmetric with doc-spec.sh / test-spec.sh.
#   GENERATION=<canonical|absent|malformed>
#   POSITIONS=<comma-list: spec/workflow-spec.md, workflow-spec.md>
#   DUPLICATE=<0|1>
#   CANONICAL_PATH=spec/workflow-spec.md
# canonical = the resolved file carries the WORKFLOW-SPEC:BEGIN marker + >=1
# parseable `## <name>` section header (or, for an empty seed, the marker + a
# header block — a zero-section seed is still canonical/vacuously complete). A
# present file with no marker is malformed.
_has_canonical() {
  [ -f "$1" ] || return 1
  grep -q '^<!-- WORKFLOW-SPEC:BEGIN' "$1" || return 1
  return 0
}

_classify() {
  _CL_SPEC="$REPO_ROOT_RESOLVED/spec/workflow-spec.md"
  _CL_ROOT="$REPO_ROOT_RESOLVED/workflow-spec.md"
  _CL_POSITIONS=""
  [ -f "$_CL_SPEC" ] && _CL_POSITIONS="spec/workflow-spec.md"
  if [ -f "$_CL_ROOT" ]; then
    [ -n "$_CL_POSITIONS" ] && _CL_POSITIONS="$_CL_POSITIONS,workflow-spec.md" || _CL_POSITIONS="workflow-spec.md"
  fi
  _CL_DUP=0
  [ -f "$_CL_SPEC" ] && [ -f "$_CL_ROOT" ] && _CL_DUP=1

  echo "CANONICAL_PATH=spec/workflow-spec.md"

  if [ -z "$_CL_POSITIONS" ]; then
    echo "GENERATION=absent"
    echo "POSITIONS="
    echo "DUPLICATE=0"
    return 0
  fi

  if _has_canonical "$WORKFLOW_SPEC_PATH"; then
    echo "GENERATION=canonical"
  else
    echo "GENERATION=malformed"
  fi
  echo "POSITIONS=$_CL_POSITIONS"
  echo "DUPLICATE=$_CL_DUP"
  return 0
}

# ---- --seed: a minimal valid skeleton registry ----
# Header + contract prose + ZERO workflow sections. A consumer repo with no
# CJ_goal_* orchestrators is vacuously registry-complete (the completeness check
# enumerates from skills-catalog.json — no CJ_goal_* rows ⇒ nothing to vanish).
# NO registry gates here — --seed bootstraps a MISSING workflow-spec.md.
_emit_seed() {
  cat <<'WORKFLOWSPEC_SEED'
<!-- WORKFLOW-SPEC:BEGIN (parsed by scripts/workflow-spec.sh) -->
# workflow-spec.md — the workflow-docs registry

This file is the single source of truth for the repo's workflow documentation:
the `docs/workflow.md` index plus the `docs/workflows/*.md` per-workflow files.
`scripts/workflow-spec.sh` parses this registry and RENDERS that surface
(`--render-docs`); a `validate.sh` Check 27 freshness gate regenerates→diffs, and
`/CJ_doc_audit` Stage 1 runs the same freshness check standalone in any repo.

This seed is a minimal valid skeleton: a header block + this contract prose and
ZERO workflow sections. A repo with no `CJ_goal_*` orchestrators is vacuously
registry-complete (the no-vanish completeness check enumerates orchestrators from
`skills-catalog.json` — no rows ⇒ nothing to vanish). Add one `## <name>` section
per workflow as the repo grows orchestrators / rosters.

## Grammar

- The `<!-- WORKFLOW-SPEC:BEGIN/END -->` markers bracket the registry; the HEADER
  block below (four-backtick fenced `header`) holds the index prose preamble.
- Each workflow is one `## <name>` section whose first key is `kind:`
  (`orchestrator` | `roster`). orchestrator sections carry single-line
  status/category/source/invoke_when fields + the `chart` / `summary` /
  `touches-skills` / `touches-steps` / `touches-scripts` / `touches-docs`
  four-backtick blocks; roster sections carry one `body` four-backtick block.

<!-- WORKFLOW-SPEC-HEADER:BEGIN -->
````header
# Workflows

This doc is the index/overview of every routable workflow in the repo. It names +
links every workflow; the deep per-workflow detail lives one level down, under
[`docs/workflows/`](workflows/) — one file per workflow.

This whole surface is GENERATED from
[`spec/workflow-spec.md`](../spec/workflow-spec.md) by
`scripts/workflow-spec.sh --render-docs`; the overview names every workflow — a
no-vanish guarantee enforced by `workflow-spec.sh --validate` (registry
completeness) and kept fresh by `scripts/validate.sh` Check 27.
````
<!-- WORKFLOW-SPEC-HEADER:END -->
<!-- WORKFLOW-SPEC:END -->
WORKFLOWSPEC_SEED
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK workflows=$(_list_sections | grep -c . || true)"
    ;;
  --list-workflows)
    _run_registry_gates
    _list_sections
    ;;
  --render-docs)
    _run_registry_gates
    _render_docs "${2:-}"
    ;;
  --classify)
    # READ-ONLY. No registry gates (classification works on absent/malformed too).
    _classify
    ;;
  --seed)
    # NO registry gates — --seed bootstraps a MISSING workflow-spec.md.
    _emit_seed
    ;;
  --help|-h)
    cat <<'USAGE'
workflow-spec.sh — parse + validate the workflow-docs registry (spec/workflow-spec.md)
and render the docs/workflow.md index + docs/workflows/*.md per-workflow files.

Usage:
  workflow-spec.sh --validate        # REGISTRY=absent/exit 0 when absent; OK + exit 0 when valid; halt when invalid (per-kind fields + closed kind enum + registry-completeness no-vanish)
  workflow-spec.sh --list-workflows  # every declared workflow name (registry order)
  workflow-spec.sh --render-docs     # render docs/workflow.md + docs/workflows/<name>.md from the registry
  workflow-spec.sh --render-docs --check  # render to a temp dir, diff vs on-disk; exit 0 if fresh, 1 + findings if stale/missing
  workflow-spec.sh --classify        # READ-ONLY: GENERATION=<canonical|absent|malformed>/POSITIONS=/DUPLICATE=<0|1>/CANONICAL_PATH=
  workflow-spec.sh --seed            # minimal valid skeleton registry (header + contract prose, zero workflow sections) for self-bootstrap
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--list-workflows|--render-docs [--check]|--classify|--seed}" >&2
    exit 2
    ;;
  *)
    echo "workflow-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
