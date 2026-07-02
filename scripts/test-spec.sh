#!/usr/bin/env bash
# test-spec.sh — parse + validate the two-tier test-spec registry (the general
# test-spec.md rules + layers + the optional test-spec-custom.md units + gates
# overlay); run the coverage cross-check; emit the portable general seed for
# self-bootstrap.
#
# test-spec.md is the GENERAL tier of the verification contract: the portable
# rules every adopting repo holds its verification surface to
# (tests-discoverable, suite-green, new-code-tested, units-anchored,
# single-owner) PLUS the four-layer map (local-hook / ci / pipeline-gate /
# ratchet — the layers[] registry, folded in from the retired gate-spec.md) —
# delivered verbatim by --seed and never edited in place. The repo-specific
# unit-level enumeration (one row per validate check / test sub-suite / inline
# family / standalone suite / CI workflow / git hook) lives in an optional
# test-spec-custom.md OVERLAY next to it (units: rows), alongside the per-mode
# pipeline-gate rows (a SEPARATE top-level gates: array — the units: `layer`
# enum {local-hook, ci} cannot hold `pipeline-gate`). This helper merges
# everything internally, so every consumer (scripts/validate.sh Check 24, the
# /CJ_test_audit skill, scripts/test.sh) sees ONE registry. awk only — no
# python/yaml dependency, portable to bash 3.2; mirrors scripts/doc-spec.sh.
#
# Absent-vs-invalid split (the lesson from the predecessor engine's ambiguous
# exit-1): when NEITHER spec/test-spec.md NOR a root test-spec.md exists, every
# registry-reading subcommand prints `REGISTRY=absent` and exits 0 — a distinct,
# machine-classifiable skip, never a halt. A PRESENT-but-invalid registry
# (either file) HALTs with `[test-spec-no-config] <reason>` on stdout + exit 1.
#
# Subcommands (all registry-reading subcommands operate on the MERGE):
#   --validate         `REGISTRY=absent` + exit 0 when the general file is
#                      absent; exit 0 + `OK schema_version=<n>` when the merged
#                      registry is valid; exit 1 + halt-emit otherwise. Includes
#                      the rendered-field work-item-ID lint (label + purpose).
#   --list-rules       echo every declared rule id (registry order).
#   --list-units       echo every declared unit id (registry order; empty when
#                      no overlay declares units).
#   --list-layers      echo every declared layer id (general layers[]; sorted).
#   --list-gates       echo every declared gate id (overlay gates[]; sorted;
#                      empty when no overlay declares gates).
#   --list-behaviors   echo every declared behavior id (overlay behaviors[];
#                      registry order; empty when no overlay declares behaviors).
#   --list-behavior-coverage  echo every behavior_coverage row's `behavior` key
#                      (registry order; empty when no overlay declares any).
#   --check-coverage   the Check 24 engine. Forward: every unit's `anchor`
#                      must match LIVE in its declared `source` file. Reverse:
#                      every live `=== Check N:` banner / `# Error check N:` /
#                      `# Warning check` comment in scripts/validate.sh, every
#                      tests/*.test.sh on disk, every .github/workflows/*.yml,
#                      and every `install_hook <name>` invocation in
#                      scripts/setup-hooks.sh must resolve to exactly one
#                      registry row in its namespace. Floor: reverse extraction
#                      must yield >= TEST_SPEC_REVERSE_FLOOR (default 20)
#                      tokens. The reverse sweep + floor apply ONLY when units:
#                      rows exist — a rules-only registry (the seeded consumer
#                      default) prints a named "coverage cross-check inactive"
#                      note + exits 0 instead of inventing extraction findings.
#                      Also runs the behavior-coverage conformance (F000066)
#                      when behaviors: rows exist (gated INDEPENDENT of units:):
#                      every behavior_coverage.behavior resolves to one
#                      behaviors row; every .unit resolves to one test-bearing
#                      units row (family in {test, test-deploy, eval,
#                      windows-smoke}); .source exists + .anchor greps LIVE
#                      (fixed-string grep -F); every behaviors row has >=1
#                      coverage row. No behaviors: => "behavior coverage
#                      inactive" + exit 0 (behaviors do NOT participate in the
#                      reverse floor). Findings print as `FINDING: ...` lines;
#                      exit 1 on any.
#   --check-workflow-coverage  (F000070) the workflow-coverage gate. FORWARD:
#                      every declared CJ_goal_* orchestrator (sourced from
#                      workflow-spec.sh --list-orchestrators, repo-local→_cj-shared)
#                      has >=1 level:workflow behavior whose `workflow:` field
#                      equals it. REVERSE: every level:workflow behavior's
#                      `workflow:` resolves to a declared orchestrator. Registry-
#                      gated skip (mirror of Check 24/26/27): an absent test-spec
#                      registry OR an absent/non-canonical workflow registry =>
#                      `workflow coverage inactive` + exit 0 (a consumer with no
#                      orchestrators passes vacuously). HARD (exit 1) on any
#                      forward/reverse finding. Surfaced by validate.sh Check 28
#                      + /CJ_test_audit Stage 1.
#   --classify         (F000065) READ-ONLY generation detector, symmetric with
#                      doc-spec.sh --classify. Emits GENERATION=<canonical|
#                      absent|malformed>, POSITIONS=, DUPLICATE=<0|1>,
#                      CANONICAL_PATH=spec/test-spec.md. Never emits `legacy`:
#                      test-spec's fenced-yaml format never diverged (confirmed
#                      from git history), so there is no old on-disk format to
#                      detect. A no-registry no-format file is `malformed`.
#   --reconcile        (F000065) Opt-in; for test-spec this is a dedup / no-op
#                      (canonical => clean no-op; duplicate => report the
#                      redundant copy, no auto-delete; malformed => the
#                      [test-spec-no-config] halt; absent => "run the audit to
#                      seed"). There is NO legacy-format migration for test-spec.
#   --seed             echo a COMPLETE, minimal, VALID general test-spec.md for
#                      self-bootstrap of a MISSING test-spec.md. Does NOT
#                      require the registry to exist; emits ONLY seed content.
#   --help|-h
#
# family closed enum:      validate | test | test-deploy | eval | windows-smoke | ci | hook.
# unit layer closed enum:  local-hook | ci.
# unit disposition enum:   hard-fail | advisory.
# trigger token enum:      pre-commit | post-merge | pr-ci | push-main | nightly | manual.
# layer id closed enum:    local-hook | ci | pipeline-gate | ratchet.
# layer disposition enum:  hard-fail | advisory | mixed.
# gate layer:              pipeline-gate (the only value).
# gate disposition enum:   hard-fail | advisory | mixed | halt.
# gate marker mode enum:   feature | defect | task | todo.
# gate marker value:       a "[...]" literal OR { enforced_by: subagent | auq }.
# schema_version supported: 1.

set -eu

# Strip CRLF from any command output on Windows. No-op on Unix.
_strip_cr() { tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests / temp-dir drills).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: TEST_SPEC_PATH env override (outermost) ->
# spec/test-spec.md (this repo) -> root test-spec.md (root-only consumers).
# Same spec/-then-root idiom as the sibling helpers.
TEST_SPEC_PATH="${TEST_SPEC_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/test-spec.md" ] && echo "$REPO_ROOT_RESOLVED/spec/test-spec.md" || echo "$REPO_ROOT_RESOLVED/test-spec.md" )}"
# The optional units overlay ALWAYS lives next to the resolved general file
# (spec/test-spec-custom.md here; root test-spec-custom.md in a root-style
# consumer; sibling of any TEST_SPEC_PATH override in temp-dir drills — which
# keeps overridden parses hermetic). TEST_SPEC_CUSTOM_PATH overrides outermost.
TEST_SPEC_CUSTOM_PATH="${TEST_SPEC_CUSTOM_PATH:-$(dirname "$TEST_SPEC_PATH")/test-spec-custom.md}"
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[test-spec-no-config] $1"
  exit 1
}

# The distinct registry-absent path: NEITHER the resolved general file NOR a
# root fallback exists. Callers (validate.sh Check 24, the audit skills)
# classify skip-vs-findings on this literal without parsing halt prose.
_emit_absent_and_exit() {
  echo "REGISTRY=absent"
  exit 0
}

# ---- Cross-script resolution to workflow-spec.sh (F000070) -------------------
# The workflow-coverage gate + the --validate workflow: enum-check both need the
# set of declared CJ_goal_* orchestrators, which is sourced from the workflow
# registry via `workflow-spec.sh --list-orchestrators`. Resolve that engine
# repo-local FIRST (sibling of this script, then $REPO_ROOT/scripts/), then the
# deployed shared home — the same repo-local→_cj-shared idiom /CJ_test_audit
# uses for its own engine. Emits the engine path on stdout, or nothing when the
# engine is unreachable (callers treat absence as the registry-gated skip).
_resolve_workflow_spec() {
  _ws_self_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd 2>/dev/null || echo "")
  for _ws_cand in \
    "$_ws_self_dir/workflow-spec.sh" \
    "$REPO_ROOT_RESOLVED/scripts/workflow-spec.sh" \
    "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/workflow-spec.sh"; do
    [ -n "$_ws_cand" ] || continue
    if [ -x "$_ws_cand" ] || [ -f "$_ws_cand" ]; then
      echo "$_ws_cand"
      return 0
    fi
  done
  return 0
}

# Emit the declared orchestrator names (one per line) from the resolved workflow
# registry, or NOTHING when the engine is unreachable / the registry is absent /
# not canonical (the registry-gated skip — callers must treat empty output as
# "no orchestrators to enforce", never as a finding).
_list_orchestrators() {
  _lo_engine=$(_resolve_workflow_spec)
  [ -n "$_lo_engine" ] || return 0
  # Only a canonical registry yields orchestrators; an absent/malformed one is a
  # clean skip (mirror of validate.sh Check 27's --classify gate).
  _lo_gen=$(bash "$_lo_engine" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $2}')
  [ "$_lo_gen" = "canonical" ] || return 0
  bash "$_lo_engine" --list-orchestrators 2>/dev/null || true
}

# Extract the single fenced ```yaml ... ``` block from one registry file ($1).
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
  echo "$TEST_SPEC_PATH"
  [ -f "$TEST_SPEC_CUSTOM_PATH" ] && echo "$TEST_SPEC_CUSTOM_PATH"
  return 0
}

_schema_version_file() {
  _extract_yaml_file "$1" | awk '/^schema_version:/ { print $2; exit }'
}

# Parse one file's rules[] block into TSV rows (4 columns):
#   id, statement, scope, enforced_by
# Flag-based, key-anchored — the same shape as the units parser below.
# statement/scope/enforced_by are quoted single-line values, extracted by
# stripping the `key: "…"` wrapper. EMPTY fields are emitted as a literal `-`
# placeholder (tab-IFS reads collapse consecutive tabs); readers normalize.
_parse_rules_file() {
  _extract_yaml_file "$1" | awk '
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)
      sub(/"[[:space:]]*$/, "", v)
      return v
    }
    function nz(v) { return (v == "" ? "-" : v) }
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\n", nz(cur_id), nz(cur_stmt), nz(cur_scope), nz(cur_enf)
      }
      cur_id=""; cur_stmt=""; cur_scope=""; cur_enf=""
    }
    /^rules:/                  { in_rules=1; next }
    /^(units|layers|gates|behaviors|behavior_coverage):/   { flush(); in_rules=0; next }
    !in_rules          { next }
    /^[[:space:]]*#/   { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*statement:/    { cur_stmt=strip($0); next }
    /^[[:space:]]*scope:/        { cur_scope=strip($0); next }
    /^[[:space:]]*enforced_by:/  { cur_enf=strip($0); next }
    END { flush() }
  '
}

# Merged rules TSV across general + overlay (general first).
_parse_rules() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_rules_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# Parse one file's units[] block into TSV rows (11 columns):
#   id, family, label, anchor, source, layer, disposition,
#   skips_when_absent, ratchet, trigger, purpose
# Flag-based, key-anchored — ported intact from the predecessor engine so the
# extraction grammar and reverse-sweep id conventions survive the migration.
# label/anchor/trigger/purpose are quoted single-line values; they are
# extracted by stripping the `key: "…"` wrapper (so they may contain spaces
# and most punctuation, but no double quotes and no tabs — a documented
# parser constraint in the registry prose). Full-line comments inside the
# block (`  # ---- … ----`) are skipped.
#
# EMPTY fields (the optional skips_when_absent/ratchet, or a missing required
# key) are emitted as a literal `-` placeholder: a bash `read` with IFS=<tab>
# COLLAPSES consecutive tabs (tab is IFS whitespace), so empty TSV fields would
# silently shift every later column left. Readers normalize `-` back to "".
_parse_units_file() {
  _extract_yaml_file "$1" | awk '
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)   # drop `  key: "`
      sub(/"[[:space:]]*$/, "", v)                          # drop trailing `"`
      return v
    }
    function nz(v) { return (v == "" ? "-" : v) }
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
          nz(cur_id), nz(cur_family), nz(cur_label), nz(cur_anchor), nz(cur_source), nz(cur_layer), \
          nz(cur_disp), nz(cur_skips), nz(cur_ratchet), nz(cur_trigger), nz(cur_purpose)
      }
      cur_id=""; cur_family=""; cur_label=""; cur_anchor=""; cur_source=""
      cur_layer=""; cur_disp=""; cur_skips=""; cur_ratchet=""; cur_trigger=""
      cur_purpose=""
    }
    /^units:/                  { in_units=1; next }
    /^(rules|layers|gates|behaviors|behavior_coverage):/   { flush(); in_units=0; next }
    !in_units          { next }
    /^[[:space:]]*#/   { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*family:/            { cur_family=$2; next }
    /^[[:space:]]*label:/             { cur_label=strip($0); next }
    /^[[:space:]]*anchor:/            { cur_anchor=strip($0); next }
    /^[[:space:]]*source:/            { cur_source=$2; next }
    /^[[:space:]]*layer:/             { cur_layer=$2; next }
    /^[[:space:]]*disposition:/       { cur_disp=$2; next }
    /^[[:space:]]*skips_when_absent:/ { cur_skips=$2; next }
    /^[[:space:]]*ratchet:/           { cur_ratchet=$2; next }
    /^[[:space:]]*trigger:/           { cur_trigger=strip($0); next }
    /^[[:space:]]*purpose:/           { cur_purpose=strip($0); next }
    END { flush() }
  '
}

# Merged units TSV across general + overlay (general first; the general seed
# carries no units, so in practice these are the overlay's rows).
_parse_units() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_units_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# Parse one file's layers[] block into TSV rows: id<TAB>name<TAB>disposition.
# Flag-based, key-anchored — scoped within the top-level `layers:` block
# (stops at the next top-level key: rules:/units:/gates:). The layers[] registry
# lives in the GENERAL file (the four-layer map, folded in from gate-spec.md).
_parse_layers_file() {
  _extract_yaml_file "$1" | awk '
    function flush() {
      if (cur_id != "") { printf "%s\t%s\t%s\n", cur_id, cur_name, cur_disp }
      cur_id=""; cur_name=""; cur_disp=""
    }
    /^layers:/                 { in_layers=1; next }
    /^(rules|units|gates|behaviors|behavior_coverage):/    { flush(); in_layers=0; next }
    !in_layers                 { next }
    /^[[:space:]]*#/           { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*name:/        { cur_name=$2; next }
    /^[[:space:]]*disposition:/ { cur_disp=$2; next }
    END { if (in_layers) flush() }
  '
}

# Merged layers TSV across general + overlay (in practice only the general
# carries layers).
_parse_layers() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_layers_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# Parse one file's gates[] block into TSV rows:
#   id<TAB>layer<TAB>order<TAB>disposition<TAB>backing_present<TAB>markers_blob
# markers_blob is a space-separated list of `mode=value` tokens, where value is
# either a bracket literal (e.g. [doc-sync-red]) or `enforced_by:<kind>`.
# Ported intact from the retired scripts/gate-spec.sh _parse_gates. Scoped
# within the top-level `gates:` block. backing_present is 1 when a `backing:`
# key was seen (its value can be free text, so only presence is recorded).
_parse_gates_file() {
  _extract_yaml_file "$1" | awk '
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", cur_id, cur_layer, cur_order, cur_disp, cur_backing, cur_markers
      }
      cur_id=""; cur_layer=""; cur_order=""; cur_disp=""; cur_backing="0"; cur_markers=""; in_markers=0
    }
    /^gates:/                  { in_gates=1; next }
    /^(rules|units|layers|behaviors|behavior_coverage):/   { flush(); in_gates=0; next }
    !in_gates                  { next }
    # A new gate entry.
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; cur_backing="0"; in_markers=0; next }
    # Gate-level keys (also close any open markers map).
    /^[[:space:]]*layer:/       { in_markers=0; cur_layer=$2; next }
    /^[[:space:]]*order:/        { in_markers=0; cur_order=$2; next }
    /^[[:space:]]*disposition:/  { in_markers=0; cur_disp=$2;  next }
    /^[[:space:]]*backing:/      { in_markers=0; cur_backing="1"; next }
    /^[[:space:]]*checks:/       { in_markers=0; next }
    # Open the per-mode markers map.
    /^[[:space:]]*markers:/      { in_markers=1; next }
    # Inside the markers map: `mode: value` lines (a bracket literal or an
    # {enforced_by: kind} inline map). Comment-only lines (full-line `#`) are
    # skipped — they document an omitted mode.
    in_markers && /^[[:space:]]*[a-z]+:[[:space:]]*/ {
      mode=$1; sub(/:$/, "", mode); sub(/:.*/, "", mode)
      val=$0
      sub(/^[[:space:]]*[a-z]+:[[:space:]]*/, "", val)
      sub(/[[:space:]]+#.*$/, "", val)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      if (val ~ /^\{[[:space:]]*enforced_by:/) {
        kind=val
        sub(/^\{[[:space:]]*enforced_by:[[:space:]]*/, "", kind)
        sub(/[[:space:]]*\}.*$/, "", kind)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", kind)
        tok=mode "=enforced_by:" kind
      } else {
        gsub(/^"|"$/, "", val)
        tok=mode "=" val
      }
      cur_markers = (cur_markers=="" ? tok : cur_markers " " tok)
      next
    }
    END { if (in_gates) flush() }
  '
}

# Merged gates TSV across general + overlay (in practice only the overlay
# carries gates).
_parse_gates() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_gates_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# Parse one file's behaviors[] block into TSV rows (6 columns):
#   id, statement, level, area, purpose, workflow
# Flag-based, key-anchored — keys on `- id:` like rules/units (a behavior HAS
# an id). statement/purpose are quoted single-line values stripped of the
# `key: "…"` wrapper; level/area/workflow are bare tokens. The optional
# area/purpose/workflow use the same nz()/`-` empty-field placeholder discipline
# as the units parser (tab-IFS collapses empty fields and shifts columns
# otherwise). The 6th `workflow` column (F000070) is the forward-link: on a
# `level: workflow` row it names the CJ_goal_* orchestrator the behavior proves
# (enum-checked in --validate); empty (`-`) on every other level.
_parse_behaviors_file() {
  _extract_yaml_file "$1" | awk '
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)
      sub(/"[[:space:]]*$/, "", v)
      return v
    }
    function nz(v) { return (v == "" ? "-" : v) }
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", nz(cur_id), nz(cur_stmt), nz(cur_level), nz(cur_area), nz(cur_purpose), nz(cur_workflow)
      }
      cur_id=""; cur_stmt=""; cur_level=""; cur_area=""; cur_purpose=""; cur_workflow=""
    }
    /^behaviors:/                                                { in_b=1; next }
    /^(rules|units|layers|gates|behavior_coverage):/             { flush(); in_b=0; next }
    !in_b              { next }
    /^[[:space:]]*#/   { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*statement:/ { cur_stmt=strip($0); next }
    /^[[:space:]]*level:/     { cur_level=$2; next }
    /^[[:space:]]*area:/      { cur_area=strip($0); next }
    /^[[:space:]]*purpose:/   { cur_purpose=strip($0); next }
    /^[[:space:]]*workflow:/  { cur_workflow=$2; next }
    END { if (in_b) flush() }
  '
}

# Merged behaviors TSV across general + overlay (in practice only the overlay
# carries behaviors — the general seed is rules: + layers: only).
_parse_behaviors() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_behaviors_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# Parse one file's behavior_coverage[] block into TSV rows (4 columns):
#   behavior, unit, source, anchor
# Flag-based, key-anchored — UNLIKE every other block, behavior_coverage rows
# carry NO id; the per-row flush keys on the FIRST field, `- behavior:`
# (mirroring how rules/units key on `- id:`). anchor is a quoted single-line
# value stripped of the wrapper; behavior/unit/source are bare tokens.
_parse_behavior_coverage_file() {
  _extract_yaml_file "$1" | awk '
    function strip(line,   v) {
      v=line
      sub(/^[[:space:]]*[a-z_]+:[[:space:]]*"?/, "", v)
      sub(/"[[:space:]]*$/, "", v)
      return v
    }
    function nz(v) { return (v == "" ? "-" : v) }
    function flush() {
      if (cur_b != "") {
        printf "%s\t%s\t%s\t%s\n", nz(cur_b), nz(cur_unit), nz(cur_src), nz(cur_anchor)
      }
      cur_b=""; cur_unit=""; cur_src=""; cur_anchor=""
    }
    /^behavior_coverage:/                              { in_bc=1; next }
    /^(rules|units|layers|gates|behaviors):/           { flush(); in_bc=0; next }
    !in_bc             { next }
    /^[[:space:]]*#/   { next }
    /^[[:space:]]*-[[:space:]]*behavior:/ { flush(); cur_b=$3; next }
    /^[[:space:]]*unit:/   { cur_unit=$2; next }
    /^[[:space:]]*source:/ { cur_src=$2; next }
    /^[[:space:]]*anchor:/ { cur_anchor=strip($0); next }
    END { if (in_bc) flush() }
  '
}

# Merged behavior_coverage TSV across general + overlay (overlay-only in
# practice).
_parse_behavior_coverage() {
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    _parse_behavior_coverage_file "$_rf"
  done <<EOF
$(_registry_files)
EOF
  true
}

# ---- Validation gates (run for every registry-reading subcommand) ----
_run_registry_gates() {
  [ -f "$TEST_SPEC_PATH" ] || _emit_absent_and_exit

  # Per-file structural gates (general, then the overlay when present).
  while IFS= read -r _rf; do
    [ -n "$_rf" ] || continue
    case "$_rf" in
      "$TEST_SPEC_PATH") _disp="test-spec.md" ;;
      *)                 _disp="test-spec-custom.md (overlay)" ;;
    esac
    _FENCES=$(grep -cE '^```yaml' "$_rf" || true)
    [ "${_FENCES:-0}" -eq 1 ] || emit_halt "$_disp must carry exactly ONE fenced \`\`\`yaml registry block (found ${_FENCES:-0})"
    _YAML_BODY=$(_extract_yaml_file "$_rf")
    [ -n "$_YAML_BODY" ] || emit_halt "$_disp has no fenced \`\`\`yaml registry block"
    _SV=$(_schema_version_file "$_rf")
    [ -n "$_SV" ] || emit_halt "schema_version field missing in the $_disp registry"
    _SV_OK=0
    for v in $SUPPORTED_SCHEMA_VERSIONS; do
      [ "$_SV" = "$v" ] && { _SV_OK=1; break; }
    done
    [ "$_SV_OK" -eq 1 ] || emit_halt "$_disp schema_version=${_SV} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"
  done <<EOF
$(_registry_files)
EOF
  SCHEMA_VERSION=$(_schema_version_file "$TEST_SPEC_PATH")

  _RULES=$(_parse_rules)
  _UNITS=$(_parse_units)
  _LAYERS=$(_parse_layers)
  _GATES=$(_parse_gates)
  _BEHAVIORS=$(_parse_behaviors)
  _BEHAVIOR_COVERAGE=$(_parse_behavior_coverage)
  [ -n "$_RULES" ] || emit_halt "the test-spec registry declares no rules (empty rules[] list — the general contract must carry the portable rules)"

  # Duplicate-id guards (per namespace, across the merged registry).
  _N_R=$(printf '%s\n' "$_RULES" | awk -F'\t' '{print $1}' | grep -c . || true)
  _N_RU=$(printf '%s\n' "$_RULES" | awk -F'\t' '{print $1}' | sort -u | grep -c . || true)
  [ "$_N_R" -eq "$_N_RU" ] || emit_halt "duplicate rule id(s): $(printf '%s\n' "$_RULES" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')"
  if [ -n "$_UNITS" ]; then
    _N_IDS=$(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | grep -c . || true)
    _N_UNIQ=$(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | sort -u | grep -c . || true)
    [ "$_N_IDS" -eq "$_N_UNIQ" ] || emit_halt "duplicate unit id(s): $(printf '%s\n' "$_UNITS" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')"
  fi
  if [ -n "$_GATES" ]; then
    _N_G=$(printf '%s\n' "$_GATES" | awk -F'\t' '{print $1}' | grep -c . || true)
    _N_GU=$(printf '%s\n' "$_GATES" | awk -F'\t' '{print $1}' | sort -u | grep -c . || true)
    [ "$_N_G" -eq "$_N_GU" ] || emit_halt "duplicate gate id(s): $(printf '%s\n' "$_GATES" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')"
  fi
  if [ -n "$_BEHAVIORS" ]; then
    _N_B=$(printf '%s\n' "$_BEHAVIORS" | awk -F'\t' '{print $1}' | grep -c . || true)
    _N_BU=$(printf '%s\n' "$_BEHAVIORS" | awk -F'\t' '{print $1}' | sort -u | grep -c . || true)
    [ "$_N_B" -eq "$_N_BU" ] || emit_halt "duplicate behavior id(s): $(printf '%s\n' "$_BEHAVIORS" | awk -F'\t' '{print $1}' | sort | uniq -d | tr '\n' ' ')"
  fi

  # Per-rule required keys.
  while IFS="$(printf '\t')" read -r _rid _rstmt _rscope _renf; do
    [ -n "$_rid" ] || continue
    [ "$_rstmt" = "-" ] && _rstmt=""
    [ "$_rscope" = "-" ] && _rscope=""
    [ "$_renf" = "-" ] && _renf=""
    case "$_rid" in
      *[!a-z0-9-]*) emit_halt "rule id '$_rid' is not a slug ([a-z0-9-]+ only)" ;;
    esac
    [ -n "$_rstmt" ]  || emit_halt "rule '$_rid' is missing 'statement'"
    [ -n "$_rscope" ] || emit_halt "rule '$_rid' is missing 'scope'"
    [ -n "$_renf" ]   || emit_halt "rule '$_rid' is missing 'enforced_by'"
  done <<EOF
$_RULES
EOF

  # Per-layer required keys + closed enums (the general four-layer map).
  if [ -n "$_LAYERS" ]; then
    while IFS="$(printf '\t')" read -r _lid _lname _ldisp; do
      [ -n "$_lid" ] || continue
      [ -n "$_lname" ] || emit_halt "layer '$_lid' is missing 'name'"
      [ -n "$_ldisp" ] || emit_halt "layer '$_lid' is missing 'disposition'"
      case "$_lid" in
        local-hook|ci|pipeline-gate|ratchet) : ;;
        *) emit_halt "layer id '$_lid' is outside the closed enum {local-hook, ci, pipeline-gate, ratchet}" ;;
      esac
      case "$_ldisp" in
        hard-fail|advisory|mixed) : ;;
        *) emit_halt "layer '$_lid' has disposition '$_ldisp' outside the closed enum {hard-fail, advisory, mixed}" ;;
      esac
    done <<EOF
$_LAYERS
EOF
  fi

  # Per-gate required keys + closed enums + per-mode marker grammar (the overlay
  # pipeline-gate rows folded in from gate-spec.md).
  if [ -n "$_GATES" ]; then
    while IFS="$(printf '\t')" read -r _gid _glayer _gorder _gdisp _gback _gmarkers; do
      [ -n "$_gid" ] || continue
      case "$_gid" in
        *[!a-z0-9-]*) emit_halt "gate id '$_gid' is not a slug ([a-z0-9-]+ only)" ;;
      esac
      [ -n "$_glayer" ] || emit_halt "gate '$_gid' is missing 'layer'"
      [ -n "$_gorder" ] || emit_halt "gate '$_gid' is missing 'order'"
      [ -n "$_gdisp" ] || emit_halt "gate '$_gid' is missing 'disposition'"
      [ "$_gback" = "1" ] || emit_halt "gate '$_gid' is missing 'backing'"
      [ -n "$_gmarkers" ] || emit_halt "gate '$_gid' has an empty 'markers' map (a gate runs in >=1 mode)"
      [ "$_glayer" = "pipeline-gate" ] || emit_halt "gate '$_gid' has layer '$_glayer' (gates: rows are always layer: pipeline-gate)"
      case "$_gdisp" in
        hard-fail|advisory|mixed|halt) : ;;
        *) emit_halt "gate '$_gid' has disposition '$_gdisp' outside the closed enum {hard-fail, advisory, mixed, halt}" ;;
      esac
      # Each marker token is mode=value; value is a "[...]" literal or enforced_by:<kind>.
      for _tok in $_gmarkers; do
        _mode=${_tok%%=*}
        _val=${_tok#*=}
        case "$_mode" in
          feature|defect|task|todo) : ;;
          *) emit_halt "gate '$_gid' markers map has mode '$_mode' outside {feature, defect, task, todo}" ;;
        esac
        case "$_val" in
          \[*\]) : ;;                                  # a bracket literal marker
          enforced_by:subagent|enforced_by:auq) : ;;   # the escape hatch
          *) emit_halt "gate '$_gid' mode '$_mode' has marker value '$_val' that is neither a \"[...]\" literal nor {enforced_by: subagent|auq}" ;;
        esac
      done
    done <<EOF
$_GATES
EOF
  fi

  # Per-behavior required keys + the closed level enum + the rendered-field
  # work-item-ID lint (behaviors[] Checks 1-2; in the SHARED gate so a malformed
  # behaviors block halts --validate / --list-* / --check-coverage alike). Runs
  # INDEPENDENT of the units: gate — a repo may declare behaviors with no units.
  if [ -n "$_BEHAVIORS" ]; then
    # Orchestrator enum for the workflow: field (F000070). Sourced from the
    # workflow registry (repo-local→_cj-shared); empty when the engine/registry
    # is unreachable — in which case an unknown workflow: value is reported as
    # "unresolvable" rather than enum-rejected (a present workflow: with no way
    # to resolve the orchestrator set is a halt, but only because the field was
    # declared; absent fields never touch this path).
    _ORCH_ENUM=$(_list_orchestrators)
    while IFS="$(printf '\t')" read -r _bid _bstmt _blevel _barea _bpurpose _bworkflow; do
      [ -n "$_bid" ] || continue
      # Normalize the `-` empty-field placeholders back to "".
      [ "$_bstmt" = "-" ] && _bstmt=""
      [ "$_blevel" = "-" ] && _blevel=""
      [ "$_barea" = "-" ] && _barea=""
      [ "$_bpurpose" = "-" ] && _bpurpose=""
      [ "$_bworkflow" = "-" ] && _bworkflow=""
      case "$_bid" in
        *[!a-z0-9-]*) emit_halt "behavior id '$_bid' is not a slug ([a-z0-9-]+ only)" ;;
      esac
      [ -n "$_bstmt" ]  || emit_halt "behavior '$_bid' is missing 'statement'"
      [ -n "$_blevel" ] || emit_halt "behavior '$_bid' is missing 'level'"
      case "$_blevel" in
        unit|integration|contract|workflow|property) : ;;
        *) emit_halt "behavior '$_bid' has level '$_blevel' outside the closed enum {unit, integration, contract, workflow, property}" ;;
      esac
      # Rendered-field work-item-ID lint: statement + purpose are the rendered
      # fields (like a unit's label/purpose); they must be ID-free.
      if printf '%s %s' "$_bstmt" "$_bpurpose" | grep -qE '[FSTD][0-9]{6}'; then
        emit_halt "behavior '$_bid' carries a work-item ID in a rendered field (statement/purpose must be ID-free)"
      fi
      # The 6th `workflow:` forward-link (F000070): optional, but allowed ONLY on
      # a `level: workflow` row, and — WHEN the orchestrator set is resolvable —
      # its value MUST be a declared orchestrator. The level-placement check is
      # unconditional (a structural rule). The enum-check is GRACEFUL when the
      # orchestrator set is unresolvable (workflow-spec.sh / spec/workflow-spec.md
      # absent or not canonical): it SKIPS rather than halts, so test-spec
      # --validate never depends on the workflow registry being present (a temp-dir
      # drill copying only test-spec-custom.md, or a consumer repo with no workflow
      # registry, still validates). The dedicated --check-workflow-coverage gate +
      # validate.sh Check 28 own the orchestrator-set enforcement where the registry
      # IS resolvable, so a genuine orphan link is still caught there.
      if [ -n "$_bworkflow" ]; then
        [ "$_blevel" = "workflow" ] || emit_halt "behavior '$_bid' declares 'workflow: $_bworkflow' but is level '$_blevel' — the workflow: forward-link is allowed ONLY on level: workflow rows"
        if [ -n "$_ORCH_ENUM" ] && ! printf '%s\n' "$_ORCH_ENUM" | grep -qxF "$_bworkflow"; then
          emit_halt "behavior '$_bid' declares 'workflow: $_bworkflow' which is not a declared orchestrator (workflow-spec.sh --list-orchestrators: $(printf '%s' "$_ORCH_ENUM" | tr '\n' ' '))"
        fi
      fi
    done <<EOF
$_BEHAVIORS
EOF
  fi

  # Per-unit required keys + closed enums + the rendered-field work-item-ID lint.
  [ -n "$_UNITS" ] || return 0
  while IFS="$(printf '\t')" read -r _id _family _label _anchor _source _layer _disp _skips _ratchet _trigger _purpose; do
    [ -n "$_id" ] || continue
    # Normalize the `-` empty-field placeholders back to "" (see _parse_units_file).
    [ "$_family" = "-" ] && _family=""
    [ "$_label" = "-" ] && _label=""
    [ "$_anchor" = "-" ] && _anchor=""
    [ "$_source" = "-" ] && _source=""
    [ "$_layer" = "-" ] && _layer=""
    [ "$_disp" = "-" ] && _disp=""
    [ "$_skips" = "-" ] && _skips=""
    [ "$_ratchet" = "-" ] && _ratchet=""
    [ "$_trigger" = "-" ] && _trigger=""
    [ "$_purpose" = "-" ] && _purpose=""
    case "$_id" in
      *[!a-z0-9-]*) emit_halt "unit id '$_id' is not a slug ([a-z0-9-]+ only)" ;;
    esac
    [ -n "$_family" ]  || emit_halt "unit '$_id' is missing 'family'"
    [ -n "$_label" ]   || emit_halt "unit '$_id' is missing 'label'"
    [ -n "$_anchor" ]  || emit_halt "unit '$_id' is missing 'anchor'"
    [ -n "$_source" ]  || emit_halt "unit '$_id' is missing 'source'"
    [ -n "$_layer" ]   || emit_halt "unit '$_id' is missing 'layer'"
    [ -n "$_disp" ]    || emit_halt "unit '$_id' is missing 'disposition'"
    [ -n "$_trigger" ] || emit_halt "unit '$_id' is missing 'trigger'"
    [ -n "$_purpose" ] || emit_halt "unit '$_id' is missing 'purpose'"
    case "$_family" in
      validate|test|test-deploy|eval|windows-smoke|ci|hook) : ;;
      *) emit_halt "unit '$_id' has family '$_family' outside the closed enum {validate, test, test-deploy, eval, windows-smoke, ci, hook}" ;;
    esac
    case "$_layer" in
      local-hook|ci) : ;;
      *) emit_halt "unit '$_id' has layer '$_layer' outside the closed enum {local-hook, ci}" ;;
    esac
    case "$_disp" in
      hard-fail|advisory) : ;;
      *) emit_halt "unit '$_id' has disposition '$_disp' outside the closed enum {hard-fail, advisory}" ;;
    esac
    case "$_skips" in
      ""|true|false) : ;;
      *) emit_halt "unit '$_id' has skips_when_absent '$_skips' (must be true or false when present)" ;;
    esac
    case "$_ratchet" in
      ""|true|false) : ;;
      *) emit_halt "unit '$_id' has ratchet '$_ratchet' (must be true or false when present)" ;;
    esac
    for _tok in $_trigger; do
      case "$_tok" in
        pre-commit|post-merge|pr-ci|push-main|nightly|manual) : ;;
        *) emit_halt "unit '$_id' has trigger token '$_tok' outside the closed enum {pre-commit, post-merge, pr-ci, push-main, nightly, manual}" ;;
      esac
    done
    # Source pin for test rows (the silent-skip catch's load-bearing rule):
    # a family:test row anchored on a tests/*.test.sh runner path MUST declare
    # source: scripts/test.sh — the forward grep proves the file is WIRED into
    # the suite. Pointing source at the test file itself self-satisfies the
    # grep (every test file names itself in its header) and silently disarms
    # the catch, so a wrong fill fails HERE with a named reason.
    if [ "$_family" = "test" ]; then
      case "$_anchor" in
        tests/*.test.sh)
          [ "$_source" = "scripts/test.sh" ] || emit_halt "unit '$_id' is a test-runner row (anchor '$_anchor') but declares source '$_source' — test rows MUST declare source: scripts/test.sh so the forward grep proves the file is wired into the suite"
          ;;
      esac
    fi
    # Rendered-field work-item-ID lint: label + purpose are the fields a
    # future generated view would render (and the audit skills quote);
    # anchors never render.
    if printf '%s %s' "$_label" "$_purpose" | grep -qE '[FSTD][0-9]{6}'; then
      emit_halt "unit '$_id' carries a work-item ID in a rendered field (label/purpose must be ID-free; literal ID-bearing strings belong in the non-rendered anchor)"
    fi
  done <<EOF
$_UNITS
EOF
}

# ---- Behavior coverage conformance (Checks 3-6; gated on behaviors: existing,
# INDEPENDENT of the units: gate). Behaviors declare WHAT the software must
# prove (open-world); behavior_coverage[] links each to a test-bearing unit +
# a semantic-evidence source/anchor. The four checks:
#   (3) every behavior_coverage.behavior resolves to EXACTLY ONE behaviors row;
#   (4) every behavior_coverage.unit resolves to one units row whose family is
#       test-bearing {test, test-deploy, eval, windows-smoke} (reject
#       validate|ci|hook — those are not behavior proofs);
#   (5) behavior_coverage.source exists AND anchor matches LIVE via FIXED-STRING
#       grep -F (behavior anchors are arbitrary semantic-evidence prose, NOT the
#       family-shaped `=== Check N` / runner-path shapes _fwd_match dispatches);
#   (6) every behaviors row has >=1 behavior_coverage row.
# Behaviors do NOT participate in the >=20-token reverse floor (no reverse
# sweep). Increments the shared _FINDINGS counter set by the caller.
_run_behavior_coverage() {
  # (3) + (4) + (5): per behavior_coverage row.
  while IFS="$(printf '\t')" read -r _cb _cunit _csrc _canchor; do
    [ -n "$_cb" ] || continue
    [ "$_csrc" = "-" ] && _csrc=""
    [ "$_canchor" = "-" ] && _canchor=""
    # (3) behavior resolves to exactly one behaviors row.
    _c=$(printf '%s\n' "$_BEHAVIORS" | awk -F'\t' -v want="$_cb" '$1 == want' | grep -c . || true)
    if [ "$_c" -ne 1 ]; then
      echo "FINDING: behavior-coverage — coverage row behavior '$_cb' resolves to $_c behaviors[] row(s); want exactly one (a dangling typo = 0, a duplicate = 2+)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
    # (4) unit resolves to exactly one units row in a test-bearing family.
    _uc=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_cunit" '$1 == want' | grep -c . || true)
    if [ "$_uc" -ne 1 ]; then
      echo "FINDING: behavior-coverage — behavior '$_cb' proof unit '$_cunit' resolves to $_uc units[] row(s); want exactly one"
      _FINDINGS=$((_FINDINGS + 1))
    else
      _ufam=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_cunit" '$1 == want {print $2; exit}')
      case "$_ufam" in
        test|test-deploy|eval|windows-smoke) : ;;
        *)
          echo "FINDING: behavior-coverage — behavior '$_cb' proof unit '$_cunit' has family '$_ufam' (not test-bearing); a behavior proof must point at a {test, test-deploy, eval, windows-smoke} unit, never validate|ci|hook"
          _FINDINGS=$((_FINDINGS + 1))
          ;;
      esac
    fi
    # (5) source exists AND anchor greps LIVE via fixed-string grep -F.
    _csrc_abs="$REPO_ROOT_RESOLVED/$_csrc"
    if [ -z "$_csrc" ] || [ ! -f "$_csrc_abs" ]; then
      echo "FINDING: behavior-coverage — behavior '$_cb' coverage source '$_csrc' does not exist"
      _FINDINGS=$((_FINDINGS + 1))
    elif ! grep -qF -- "$_canchor" "$_csrc_abs"; then
      echo "FINDING: behavior-coverage — behavior '$_cb' anchor not found LIVE (grep -F) in $_csrc (the behavior is not named in the test/spec text there): $_canchor"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done <<EOF
$_BEHAVIOR_COVERAGE
EOF

  # (6) every behaviors row has >=1 behavior_coverage row.
  while IFS="$(printf '\t')" read -r _bid _rest; do
    [ -n "$_bid" ] || continue
    _cc=$(printf '%s\n' "$_BEHAVIOR_COVERAGE" | awk -F'\t' -v want="$_bid" '$1 == want' | grep -c . || true)
    if [ "$_cc" -lt 1 ]; then
      echo "FINDING: behavior-coverage — behavior '$_bid' has no behavior_coverage row (a declared behavior with zero covering test is the open-world gap this axis exists to catch)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done <<EOF
$_BEHAVIORS
EOF
}

# ---- Workflow-coverage gate (F000070) ----
# A forward + reverse cross-check between the workflow registry (the declared
# CJ_goal_* orchestrators, via workflow-spec.sh --list-orchestrators) and the
# `level: workflow` behaviors in the test-spec registry's behaviors[] block:
#   FORWARD  — every declared orchestrator has >=1 level:workflow behavior whose
#              `workflow:` field equals it (a documented orchestrator with no
#              workflow test is the gap this gate makes structurally impossible);
#   REVERSE  — every level:workflow behavior's `workflow:` value resolves to a
#              declared orchestrator (an orphan workflow: link is a finding).
# Registry-gated skip (mirror of validate.sh Check 24/26/27): when the workflow
# registry is unreachable / not canonical (no orchestrators resolvable) OR the
# test-spec registry is absent, the gate prints an `inactive` note + exits 0 —
# a consumer repo with no orchestrators passes vacuously, never a false finding.
# Findings print as `FINDING: workflow-coverage — ...`; exit 1 on any finding.
_run_workflow_coverage() {
  # test-spec registry-absent → inactive skip (callers must not parse halt prose).
  if [ ! -f "$TEST_SPEC_PATH" ]; then
    echo "workflow coverage inactive — test-spec registry absent (no behaviors to cross-check)"
    return 0
  fi

  _ORCHS=$(_list_orchestrators)
  if [ -z "$_ORCHS" ]; then
    echo "workflow coverage inactive — no orchestrators resolvable (workflow-spec.sh / spec/workflow-spec.md absent or not canonical); nothing to enforce"
    return 0
  fi

  # The level:workflow behaviors: TSV is id<tab>statement<tab>level<tab>area<tab>
  # purpose<tab>workflow. Project to "id workflow" for the level:workflow rows.
  _WF_BEHAVIORS=$(printf '%s\n' "$_BEHAVIORS" | awk -F'\t' '$3 == "workflow" {wf=$6; if (wf=="-") wf=""; print $1 "\t" wf}')

  _WFC_FINDINGS=0

  # FORWARD: every declared orchestrator has >=1 level:workflow behavior naming it.
  while IFS= read -r _orch; do
    [ -n "$_orch" ] || continue
    _hits=$(printf '%s\n' "$_WF_BEHAVIORS" | awk -F'\t' -v want="$_orch" '$2 == want' | grep -c . || true)
    if [ "$_hits" -lt 1 ]; then
      echo "FINDING: workflow-coverage — orchestrator '$_orch' is declared in spec/workflow-spec.md but has NO level:workflow behavior whose 'workflow:' field equals it (a documented-but-untested workflow); declare one in spec/test-spec-custom.md behaviors[] linked to a real eval case"
      _WFC_FINDINGS=$((_WFC_FINDINGS + 1))
    fi
  done <<EOF
$_ORCHS
EOF

  # REVERSE: every level:workflow behavior's workflow: resolves to a declared orchestrator.
  while IFS="$(printf '\t')" read -r _wbid _wbwf; do
    [ -n "$_wbid" ] || continue
    if [ -z "$_wbwf" ]; then
      echo "FINDING: workflow-coverage — level:workflow behavior '$_wbid' has no 'workflow:' field (a level:workflow behavior MUST name the orchestrator it proves)"
      _WFC_FINDINGS=$((_WFC_FINDINGS + 1))
      continue
    fi
    if ! printf '%s\n' "$_ORCHS" | grep -qxF "$_wbwf"; then
      echo "FINDING: workflow-coverage — level:workflow behavior '$_wbid' names 'workflow: $_wbwf' which is not a declared orchestrator (orphan forward-link)"
      _WFC_FINDINGS=$((_WFC_FINDINGS + 1))
    fi
  done <<EOF
$_WF_BEHAVIORS
EOF

  _ORCH_N=$(printf '%s\n' "$_ORCHS" | grep -c . || true)
  _WFB_N=$(printf '%s\n' "$_WF_BEHAVIORS" | grep -c . || true)
  echo "workflow coverage: orchestrators=$_ORCH_N level:workflow behaviors=$_WFB_N findings=$_WFC_FINDINGS"
  [ "$_WFC_FINDINGS" -eq 0 ]
}

# ---- Coverage cross-check (the Check 24 engine, ported) ----
# Forward + reverse + floor. Findings print as `FINDING: ...`; the summary line
# is the last line either way. Exit 1 on any finding. The reverse sweep + floor
# apply ONLY when units: rows exist (the units-gated contract): a rules-only
# registry — the seeded consumer default — prints a named inactive note + exits
# 0 instead of misleading extraction-grammar findings. The behavior-coverage
# conformance (Checks 3-6) is gated on behaviors: existing, INDEPENDENT of the
# units: gate: a no-behaviors repo prints "behavior coverage inactive" + exit 0.
_run_coverage() {
  if [ -z "$_UNITS" ]; then
    echo "no units declared — coverage cross-check inactive; declare units in spec/test-spec-custom.md to activate"
    # The behavior axis is independent of units: a repo could declare behaviors
    # with no units overlay. Run the behavior conformance even on the no-units
    # path so a declared behavior is never silently unverified.
    if [ -n "$_BEHAVIORS" ]; then
      _FINDINGS=0
      _run_behavior_coverage
      if [ "$_FINDINGS" -gt 0 ]; then
        echo "BEHAVIOR-COVERAGE: findings=$_FINDINGS"
        return 1
      fi
      echo "OK behavior-coverage findings=0"
    else
      echo "no behaviors declared — behavior coverage inactive; declare behaviors in spec/test-spec-custom.md to activate"
    fi
    return 0
  fi

  _FINDINGS=0

  # Forward: every anchor must be found in its declared source file — and for
  # the grammar-bearing namespaces the match is EXECUTION-SHAPED, not a bare
  # substring. A bare `grep -F` is forgeable with dead text (a commented-out
  # `echo "=== Check N:"`, a runner invocation deleted but its log strings
  # left behind, a `# if install_hook ...` comment) — the adversarial bypass
  # class this engine exists to catch. Shapes:
  #   - validate banner anchors (`=== Check N:`)  -> `^echo "=== Check N:` (live echo)
  #   - validate comment anchors (`# Error/Warning check`) -> line-start match
  #   - test rows (anchor tests/*.test.sh)        -> `^[^#]*bash .*<path>` (live invocation)
  #   - hook rows (anchor `install_hook <name>`)  -> `^if install_hook <name>` (live call)
  #   - everything else                            -> fixed-string (filenames etc.)
  _fwd_match() {
    # $1=family $2=anchor $3=src-file ; exit 0 = the anchor matches a LIVE line
    case "$2" in
      "=== Check "*)
        # live = an actual echo emits the banner (a commented-out echo fails)
        grep -E '^echo "' "$3" | grep -qF -- "$2" ;;
      "# Error check "*|"# Warning check"*)
        # live = the comment sits at line start (mirrors the reverse grammar)
        awk -v a="$2" 'index($0, a) == 1 { f=1; exit } END { exit !f }' "$3" ;;
      tests/*.test.sh)
        if [ "$1" = "test" ]; then
          # live = an uncommented bash invocation of the file (log/echo strings
          # and comments do not count)
          grep -E '^[^#]*bash ' "$3" | grep -qF -- "$2"
        else
          grep -qF -- "$2" "$3"
        fi ;;
      "install_hook "*)
        # live = the actual `if install_hook <name>` call line
        grep -E '^if install_hook ' "$3" | grep -qF -- "$2" ;;
      scripts/*.sh)
        # rows anchored on a script path: the caller string alone is
        # forgeable by a leftover invocation of a deleted/renamed script —
        # the anchored script must also still EXIST on disk
        grep -qF -- "$2" "$3" && [ -f "$REPO_ROOT_RESOLVED/$2" ] ;;
      *)
        grep -qF -- "$2" "$3" ;;
    esac
  }
  _ROWCOUNT=0
  while IFS="$(printf '\t')" read -r _id _family _label _anchor _source _layer _disp _skips _ratchet _trigger _purpose; do
    [ -n "$_id" ] || continue
    _ROWCOUNT=$((_ROWCOUNT + 1))
    _src="$REPO_ROOT_RESOLVED/$_source"
    if [ ! -f "$_src" ]; then
      echo "FINDING: forward — unit '$_id' declares source '$_source' which does not exist"
      _FINDINGS=$((_FINDINGS + 1))
    elif ! _fwd_match "$_family" "$_anchor" "$_src"; then
      echo "FINDING: forward — unit '$_id' anchor not found LIVE in $_source (unit removed/renamed/commented out, or a test file no longer wired into the runner — dead-text mentions do not count): $_anchor"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done <<EOF
$_UNITS
EOF

  # Reverse: every live unit on the swept surface must resolve to exactly one
  # registry row in its namespace. _TOKENS counts every extracted live token
  # for the floor assert.
  _TOKENS=0
  _NS_VALIDATE=0; _NS_TESTS=0; _NS_WF=0; _NS_HOOKS=0

  # (1) validate.sh banners + comments.
  _VAL_SRC="$REPO_ROOT_RESOLVED/scripts/validate.sh"
  if [ -f "$_VAL_SRC" ]; then
    # 1a. `=== Check N:` echo banners -> row id validate-check-N.
    while IFS= read -r _n; do
      [ -n "$_n" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _NS_VALIDATE=$((_NS_VALIDATE + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="validate-check-$_n" '$1 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live banner 'Check $_n' in scripts/validate.sh resolves to $_c registry row(s); want exactly one (id: validate-check-$_n)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^echo "=== Check [0-9]+[a-z]?:' "$_VAL_SRC" | sed -E 's/^echo "=== Check ([0-9]+[a-z]?):.*/\1/')
EOF
    # 1b. `# Error check N:` comments -> row id validate-error-check-N.
    while IFS= read -r _n; do
      [ -n "$_n" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _NS_VALIDATE=$((_NS_VALIDATE + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="validate-error-check-$_n" '$1 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live comment 'Error check $_n' in scripts/validate.sh resolves to $_c registry row(s); want exactly one (id: validate-error-check-$_n)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^# Error check [0-9]+[a-z]?:' "$_VAL_SRC" | sed -E 's/^# Error check ([0-9]+[a-z]?):.*/\1/')
EOF
    # 1c. `# Warning check` comments -> exactly one validate row whose anchor
    # is a substring of the live line (the warning namespace has an unnumbered
    # member, so matching is anchor-containment, not ID-derived).
    while IFS= read -r _wline; do
      [ -n "$_wline" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _NS_VALIDATE=$((_NS_VALIDATE + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v line="$_wline" '$2 == "validate" && index(line, $4) > 0' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — live warning-check comment in scripts/validate.sh resolves to $_c registry row(s); want exactly one: $_wline"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^# Warning check' "$_VAL_SRC")
EOF
  fi

  # (2) tests/*.test.sh on disk -> exactly one family:test row whose anchor is
  # the literal runner path AND whose source is scripts/test.sh. This is the
  # silent-skip catch: the row's FORWARD anchor proves the file is wired into
  # scripts/test.sh; this REVERSE pass proves every file on disk has a row at
  # all. The source pin is load-bearing — a row pointing source at the test
  # file itself would self-satisfy the forward grep (the file names itself in
  # its header), turning the catch back into a convention.
  for _tf in "$REPO_ROOT_RESOLVED"/tests/*.test.sh; do
    [ -e "$_tf" ] || continue
    _tok="tests/$(basename "$_tf")"
    _TOKENS=$((_TOKENS + 1))
    _NS_TESTS=$((_NS_TESTS + 1))
    _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_tok" '$2 == "test" && $4 == want && $5 == "scripts/test.sh"' | grep -c . || true)
    if [ "$_c" -ne 1 ]; then
      echo "FINDING: reverse — test file $_tok on disk resolves to $_c registry row(s); want exactly one (family: test, anchor: $_tok, source: scripts/test.sh — the runner, NOT the test file: the forward grep must prove the file is wired in)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

  # (3) .github/workflows/*.yml on disk -> exactly one family:ci row declaring
  # that workflow file as its source.
  for _wf in "$REPO_ROOT_RESOLVED"/.github/workflows/*.yml "$REPO_ROOT_RESOLVED"/.github/workflows/*.yaml; do
    [ -e "$_wf" ] || continue
    _wsrc=".github/workflows/$(basename "$_wf")"
    _TOKENS=$((_TOKENS + 1))
    _NS_WF=$((_NS_WF + 1))
    _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="$_wsrc" '$2 == "ci" && $5 == want' | grep -c . || true)
    if [ "$_c" -ne 1 ]; then
      echo "FINDING: reverse — workflow $_wsrc on disk resolves to $_c registry row(s); want exactly one (family: ci, source: $_wsrc)"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

  # (4) install_hook invocations in scripts/setup-hooks.sh -> exactly one
  # family:hook row per installed hook name.
  _SH_SRC="$REPO_ROOT_RESOLVED/scripts/setup-hooks.sh"
  if [ -f "$_SH_SRC" ]; then
    while IFS= read -r _hname; do
      [ -n "$_hname" ] || continue
      _TOKENS=$((_TOKENS + 1))
      _NS_HOOKS=$((_NS_HOOKS + 1))
      _c=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v want="install_hook $_hname" '$2 == "hook" && $4 == want' | grep -c . || true)
      if [ "$_c" -ne 1 ]; then
        echo "FINDING: reverse — installed hook '$_hname' resolves to $_c registry row(s); want exactly one (family: hook, anchor: install_hook $_hname)"
        _FINDINGS=$((_FINDINGS + 1))
      fi
    done <<EOF
$(grep -E '^if install_hook [a-z][a-z-]*' "$_SH_SRC" | sed -E 's/^if install_hook ([a-z][a-z-]*).*/\1/')
EOF
  fi

  # Floor-asserts: the reverse extraction must keep finding a healthy number of
  # live tokens, so extraction-grammar rot can never make this check vacuously
  # pass. The global floor is workbench-calibrated (overridable for smaller
  # adopting repos via TEST_SPEC_REVERSE_FLOOR); the per-namespace floors
  # catch single-namespace rot the aggregate would mask (e.g. setup-hooks.sh
  # refactoring away the `if install_hook` shape loses only 2 of ~49 tokens).
  #
  # Surface-existence gating (D000035): a namespace's zero-token floor is a
  # grammar-rot signal ONLY when that namespace's surface is part of THIS repo's
  # verification contract. A consumer repo that adopts the contract against its
  # own surface (vitest *.test.ts + a workflow, with NO scripts/validate.sh /
  # tests/*.test.sh / scripts/setup-hooks.sh) legitimately yields zero tokens in
  # the namespaces it does not use — that is N/A, not rot.
  #
  # A namespace's surface counts as PRESENT for the floors only when BOTH hold:
  #   (1) the surface file/dir exists on disk at the workbench's reserved path
  #       (scripts/validate.sh / tests/*.test.sh / .github/workflows/ /
  #       scripts/setup-hooks.sh), AND
  #   (2) the merged registry declares >=1 unit row in that namespace's family
  #       (validate / test / ci / hook) — the rows are what make us EXPECT live
  #       tokens, so they are the direct signal that this repo contracts to
  #       verify the namespace.
  # Path-existence alone is too coarse: a non-workbench consumer that declares
  # units AND happens to have a file at a reserved path in a DIFFERENT grammar
  # (a husky-style scripts/setup-hooks.sh with no `if install_hook` lines, or its
  # own scripts/validate.sh with no `=== Check N:` banners) would otherwise
  # false-fire a zero-token floor it can only escape by renaming its file — the
  # exact "misfire in a consumer repo" class this defect closes. Composing
  # path-presence with family-row-presence closes that residual WITHOUT weakening
  # the workbench (which declares rows in all four families): a present-yet-empty
  # surface that the registry DOES claim (genuine grammar rot) still fires.
  #
  # The global <20-token floor is calibrated to the FULL workbench shape, so it
  # applies only when ALL FOUR namespaces are present (path + rows); a
  # partial/consumer set legitimately yields few tokens and relies on the
  # surface-gated per-namespace floors instead. (Same `for ...; do [ -e "$x" ] &&
  # { ...; break; }; done` existence idiom the reverse sweep uses; family-row
  # counts via the same `awk -F'\t' '$2==<family>'` shape as the reverse sweep.)
  _SURF_VALIDATE=0; [ -f "$REPO_ROOT_RESOLVED/scripts/validate.sh" ] && _SURF_VALIDATE=1
  _SURF_TESTS=0
  for _t in "$REPO_ROOT_RESOLVED"/tests/*.test.sh; do
    [ -e "$_t" ] && { _SURF_TESTS=1; break; }
  done
  _SURF_WF=0
  for _w in "$REPO_ROOT_RESOLVED"/.github/workflows/*.yml "$REPO_ROOT_RESOLVED"/.github/workflows/*.yaml; do
    [ -e "$_w" ] && { _SURF_WF=1; break; }
  done
  _SURF_HOOKS=0; [ -f "$REPO_ROOT_RESOLVED/scripts/setup-hooks.sh" ] && _SURF_HOOKS=1

  # Family-row counts: does the registry declare any unit in this namespace's family?
  _FAM_VALIDATE=$(printf '%s\n' "$_UNITS" | awk -F'\t' '$2=="validate"{n++} END{print n+0}')
  _FAM_TEST=$(printf '%s\n' "$_UNITS" | awk -F'\t' '$2=="test"{n++} END{print n+0}')
  _FAM_CI=$(printf '%s\n' "$_UNITS" | awk -F'\t' '$2=="ci"{n++} END{print n+0}')
  _FAM_HOOK=$(printf '%s\n' "$_UNITS" | awk -F'\t' '$2=="hook"{n++} END{print n+0}')

  # Effective presence = path present AND the contract claims the namespace (rows).
  _EFF_VALIDATE=0; [ "$_SURF_VALIDATE" -eq 1 ] && [ "$_FAM_VALIDATE" -ge 1 ] && _EFF_VALIDATE=1
  _EFF_TESTS=0;    [ "$_SURF_TESTS" -eq 1 ]    && [ "$_FAM_TEST" -ge 1 ]    && _EFF_TESTS=1
  _EFF_WF=0;       [ "$_SURF_WF" -eq 1 ]       && [ "$_FAM_CI" -ge 1 ]      && _EFF_WF=1
  _EFF_HOOKS=0;    [ "$_SURF_HOOKS" -eq 1 ]    && [ "$_FAM_HOOK" -ge 1 ]    && _EFF_HOOKS=1
  _SURFACES_PRESENT=$(( _EFF_VALIDATE + _EFF_TESTS + _EFF_WF + _EFF_HOOKS ))

  _FLOOR="${TEST_SPEC_REVERSE_FLOOR:-20}"
  # Global floor: fires only when the full workbench surface set is present (path
  # + rows for all four; the floor value is calibrated to that shape — a partial
  # set legitimately yields few tokens, so a flat global floor would false-fire).
  if [ "$_SURFACES_PRESENT" -eq 4 ] && [ "$_TOKENS" -lt "$_FLOOR" ]; then
    echo "FINDING: floor — reverse extraction yielded only $_TOKENS live token(s) (< $_FLOOR); the extraction grammar no longer matches the live surface"
    _FINDINGS=$((_FINDINGS + 1))
  fi
  # Per-namespace floors: fire on a PRESENT-but-zero-token namespace (genuine
  # grammar rot — path present AND the registry claims it); skip a namespace the
  # contract does not claim (surface absent, OR a reserved-path file the registry
  # declares no rows for — a consumer's own unrelated script; N/A, not rot).
  for _ns in "validate:$_NS_VALIDATE:$_EFF_VALIDATE" \
             "test-files:$_NS_TESTS:$_EFF_TESTS" \
             "workflows:$_NS_WF:$_EFF_WF" \
             "hooks:$_NS_HOOKS:$_EFF_HOOKS"; do
    _ns_name="${_ns%%:*}"; _ns_rest="${_ns#*:}"
    _ns_count="${_ns_rest%%:*}"; _ns_eff="${_ns_rest#*:}"
    if [ "$_ns_eff" -eq 1 ] && [ "$_ns_count" -eq 0 ]; then
      echo "FINDING: floor — reverse extraction yielded ZERO live tokens in the '$_ns_name' namespace; that namespace's extraction grammar no longer matches the live surface"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

  # Behavior coverage (Checks 3-6), gated on behaviors: existing. Runs in the
  # SAME hard loop — its findings add to _FINDINGS so a bad behavior link fails
  # the gate alongside a units coverage finding. A no-behaviors repo emits the
  # named inactive note (parity with the units-gated reverse-sweep inactivity).
  if [ -n "$_BEHAVIORS" ]; then
    _run_behavior_coverage
  else
    echo "no behaviors declared — behavior coverage inactive; declare behaviors in spec/test-spec-custom.md to activate"
  fi

  if [ "$_FINDINGS" -gt 0 ]; then
    echo "COVERAGE: findings=$_FINDINGS (rows=$_ROWCOUNT reverse_tokens=$_TOKENS)"
    return 1
  fi
  echo "OK coverage rows=$_ROWCOUNT reverse_tokens=$_TOKENS findings=0"
  return 0
}

# ---- --classify / --reconcile: contract-file generation detection + migration ----
# (F000065/S000109) The SYMMETRIC partner of doc-spec.sh's classify/reconcile.
#
# IMPORTANT — confirmed from git history: test-spec.md has ALWAYS been the
# fenced ```yaml format (introduced at ce7af57 under spec/test-spec.md, the same
# schema_version: + rules: shape this engine parses today). It NEVER had a
# divergent on-disk legacy format the way doc-spec did (doc-spec went from a
# generated yaml registry to a 3-column Markdown table; test-spec's canonical
# format was the yaml block from day one). So for test-spec there is no
# legacy-yaml-to-something migration to perform. --classify therefore reduces to
# {canonical, absent, duplicate, malformed} (no `legacy` branch will ever fire),
# and --reconcile is a dedup / no-op: a canonical file is a clean no-op, a
# duplicated file reports the redundant copy (no auto-delete; OQ1), an absent
# file says "run the audit to seed", a malformed file halts. The subcommands are
# implemented symmetrically with doc-spec.sh so both contracts present one
# self-healing surface; the reduced legacy branch is documented, not hidden.

# Does file $1 carry a parseable canonical test-spec yaml registry?
# (exit 0 = yes). Canonical = exactly one fenced ```yaml block carrying both
# schema_version: and a top-level rules: key.
_has_canonical_yaml() {
  [ -f "$1" ] || return 1
  _cy=$(_extract_yaml_file "$1")
  [ -n "$_cy" ] || return 1
  printf '%s\n' "$_cy" | grep -qE '^schema_version:' || return 1
  printf '%s\n' "$_cy" | grep -qE '^rules:' || return 1
  return 0
}

# Classify the generation of the test-spec contract file(s) without writing.
# Symmetric machine block with doc-spec.sh --classify:
#   GENERATION=<canonical|absent|malformed>   (never `legacy` — see the note above)
#   POSITIONS=<comma-list of on-disk positions: spec/test-spec.md, test-spec.md>
#   DUPLICATE=<0|1>
#   CANONICAL_PATH=spec/test-spec.md
_classify() {
  _CL_SPEC="$REPO_ROOT_RESOLVED/spec/test-spec.md"
  _CL_ROOT="$REPO_ROOT_RESOLVED/test-spec.md"
  _CL_POSITIONS=""
  [ -f "$_CL_SPEC" ] && _CL_POSITIONS="spec/test-spec.md"
  if [ -f "$_CL_ROOT" ]; then
    [ -n "$_CL_POSITIONS" ] && _CL_POSITIONS="$_CL_POSITIONS,test-spec.md" || _CL_POSITIONS="test-spec.md"
  fi
  _CL_DUP=0
  [ -f "$_CL_SPEC" ] && [ -f "$_CL_ROOT" ] && _CL_DUP=1

  echo "CANONICAL_PATH=spec/test-spec.md"

  if [ -z "$_CL_POSITIONS" ]; then
    echo "GENERATION=absent"
    echo "POSITIONS="
    echo "DUPLICATE=0"
    return 0
  fi

  _CL_ACTIVE="$TEST_SPEC_PATH"
  if _has_canonical_yaml "$_CL_ACTIVE"; then
    echo "GENERATION=canonical"
  else
    # No parseable canonical yaml registry, and (by construction) test-spec has
    # no recognized legacy on-disk format — so this is a malformed canonical
    # file. NOT legacy; preserve the [test-spec-no-config] halt semantics.
    echo "GENERATION=malformed"
  fi
  echo "POSITIONS=$_CL_POSITIONS"
  echo "DUPLICATE=$_CL_DUP"
  return 0
}

# Reconcile the test-spec contract file. Symmetric with doc-spec.sh --reconcile
# but with the reduced (no-legacy-migration) branch:
#   - canonical  => clean no-op (RECONCILE: already canonical). If duplicated,
#                   report the redundant copy.
#   - duplicate  => (a canonical-and-duplicate file) report the redundant copy;
#                   no auto-delete (OQ1).
#   - malformed  => the [test-spec-no-config] halt (never clobbered).
#   - absent     => RECONCILE: absent — run the audit to seed.
# There is NO legacy migration path for test-spec (the format never diverged).
_reconcile() {
  _RC_OUT=$(_classify)
  _RC_GEN=$(printf '%s\n' "$_RC_OUT" | awk -F= '/^GENERATION=/{print $2}')
  _RC_DUP=$(printf '%s\n' "$_RC_OUT" | awk -F= '/^DUPLICATE=/{print $2}')

  case "$_RC_GEN" in
    absent)
      echo "RECONCILE: absent — no contract file to reconcile (run /CJ_test_audit to seed the canonical contract)"
      return 0
      ;;
    malformed)
      emit_halt "test-spec.md is present but carries no parseable canonical yaml registry — refusing to reconcile a possibly hand-broken file (fix the registry by hand): $TEST_SPEC_PATH"
      ;;
    canonical)
      echo "RECONCILE: already canonical — no migration needed ($TEST_SPEC_PATH)"
      echo "RECONCILE: test-spec has no divergent legacy on-disk format (the yaml registry has been canonical from introduction) — reconcile is a dedup/no-op"
      if [ "$_RC_DUP" = "1" ]; then
        echo "RECONCILE-WARN: a redundant test-spec copy exists at the root position (test-spec.md) alongside the canonical spec/test-spec.md — remove it by hand (auto-delete is deferred, OQ1)"
      fi
      return 0
      ;;
    *)
      emit_halt "internal: unexpected GENERATION='$_RC_GEN' from _classify"
      ;;
  esac
}

# ---- --render-docs / --render-docs --check: generated human test catalog ----
# (F000069/S000114) The SECOND instance of the proven README ↔ generate-readme.sh
# ↔ validate.sh Check 25 primitive, applied to the test surface. The renderer is
# PURE: the merged registry in → deterministic human docs out. It emits
#   docs/tests/<family>.md  (one per unit `family` present in the registry), and
#   docs/test-catalog.md     (the index grouped by family with per-family counts).
# RENDERED FIELDS ONLY are emitted: label, purpose, layer, disposition, trigger,
# and the anchor shown as an inline `code` reference next to its source path
# (NEVER as a prose claim). label/purpose are already ID-free by the existing
# rendered-field lint, so the output satisfies Check 19 (no work-item IDs in
# human-docs) by construction.
#
# DETERMINISM (load-bearing — Check 26 diffs byte-for-byte): families are emitted
# in a FIXED sort order (sort -u over the families present); within a family,
# rows are sorted by unit id (LC_ALL=C). Fixed header strings, no timestamps, no
# run-specific metadata — a regenerate→diff is byte-stable. Mirrors
# generate-readme.sh's idempotence discipline.
#
# The DOCS_ROOT (default $REPO_ROOT_RESOLVED/docs) is overridable via TESTDOC_OUT
# so --check can render into a temp dir and diff vs on-disk without touching the
# committed tree. awk only — no python/yaml dependency.

# The generated-file banner (mirrors generate-readme.sh's "do not edit by hand"
# intent). Kept as a function so the index + every family page share one string.
_render_banner() {
  # $1 = the regenerate command shown to the reader.
  echo "<!-- GENERATED FILE — do not edit by hand."
  echo "     Rendered from the merged test-spec registry (spec/test-spec.md +"
  echo "     spec/test-spec-custom.md) by: $1"
  echo "     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->"
}

# Markdown-table-cell escaper: a literal pipe in a rendered field would break the
# table. Replace it with the HTML entity so the cell stays one column. (The
# rendered-field lint already forbids tabs/double-quotes; pipes are the only
# table-hostile char that can legitimately appear in prose.)
_md_cell() {
  printf '%s' "$1" | sed 's/|/\&#124;/g'
}

# Work-item-ID masker (load-bearing for Check 19). The rendered-field lint keeps
# label + purpose ID-free, but the `anchor` is NOT a rendered field — it is a
# grep token that can legitimately embed a work-item ID (a test banner like
# `=== F000026: ... ===`). The anchor is a SOURCE POINTER, not a human claim, so
# masking the ID token keeps the catalog ID-free BY CONSTRUCTION (the SPEC's
# guarantee — passes validate.sh Check 19) while still pointing the reader at the
# right source line. Replace each `[FSTD]NNNNNN` token with a neutral `[id]`.
_mask_ids() {
  printf '%s' "$1" | sed -E 's/[FSTD][0-9]{6}/[id]/g'
}

# The sorted, unique list of families present in the merged registry (one per
# line). Empty when no units are declared.
_render_families() {
  [ -n "$_UNITS" ] || return 0
  printf '%s\n' "$_UNITS" | awk -F'\t' 'NF {print $2}' | LC_ALL=C sort -u
}

# Render ONE family page to stdout. $1 = family name. Reads the merged $_UNITS.
_render_family_page() {
  _rf_fam="$1"
  echo "# Test catalog — \`$_rf_fam\` family"
  echo ""
  _render_banner "scripts/test-spec.sh --render-docs"
  echo ""
  echo "Verification units in the \`$_rf_fam\` family, rendered from the test-spec"
  echo "registry. Each row shows only registry-rendered fields; the \`anchor\` is a"
  echo "source reference, never a claim."
  echo ""
  echo "| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |"
  echo "|-------|-------|-------------|---------|-----------------|---------|"
  # Stable sort by unit id (column 1), restricted to this family (column 2).
  printf '%s\n' "$_UNITS" | awk -F'\t' -v fam="$_rf_fam" '$2 == fam' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 | \
  while IFS="$(printf '\t')" read -r _id _family _label _anchor _source _layer _disp _skips _ratchet _trigger _purpose; do
    [ -n "$_id" ] || continue
    [ "$_label" = "-" ] && _label=""
    [ "$_anchor" = "-" ] && _anchor=""
    [ "$_source" = "-" ] && _source=""
    [ "$_layer" = "-" ] && _layer=""
    [ "$_disp" = "-" ] && _disp=""
    [ "$_trigger" = "-" ] && _trigger=""
    [ "$_purpose" = "-" ] && _purpose=""
    # Anchor as an inline code reference next to its source path — never prose.
    # Mask any work-item ID in the anchor (a grep token, not a rendered field) so
    # the human-doc stays ID-free by construction (Check 19). Source is a file
    # path (never carries IDs) but mask defensively for symmetry.
    _ref="\`$(_mask_ids "$_source")\` · \`$(_mask_ids "$_anchor")\`"
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$(_md_cell "$_label")" "$(_md_cell "$_layer")" "$(_md_cell "$_disp")" \
      "$(_md_cell "$_trigger")" "$_ref" "$(_md_cell "$_purpose")"
  done
}

# Render the index page (docs/test-catalog.md) to stdout. Reads $_UNITS.
_render_index_page() {
  echo "# Test catalog"
  echo ""
  _render_banner "scripts/test-spec.sh --render-docs"
  echo ""
  echo "A human-browsable view of the workbench's verification surface, generated"
  echo "from the merged test-spec registry (\`spec/test-spec.md\` +"
  echo "\`spec/test-spec-custom.md\`). Each family links to its own page listing the"
  echo "units in that family. The registry is the single source of truth; this"
  echo "catalog is a rendered view kept fresh by \`validate.sh\` Check 26."
  echo ""
  echo "| Family | Units | Page |"
  echo "|--------|-------|------|"
  _render_families | while IFS= read -r _fam; do
    [ -n "$_fam" ] || continue
    _cnt=$(printf '%s\n' "$_UNITS" | awk -F'\t' -v fam="$_fam" '$2 == fam' | grep -c . || true)
    echo "| \`$_fam\` | $_cnt | [docs/tests/$_fam.md](tests/$_fam.md) |"
  done
}

# Render the full catalog into a target docs dir. $1 = docs root (created if
# absent). Writes docs/test-catalog.md + docs/tests/<family>.md per family.
# Pure-ish: it writes files only under the given root (overridable via the caller
# for --check's temp dir). Returns 0.
_render_into() {
  _ri_docs="$1"
  mkdir -p "$_ri_docs/tests"
  _render_index_page > "$_ri_docs/test-catalog.md"
  _render_families | while IFS= read -r _fam; do
    [ -n "$_fam" ] || continue
    _render_family_page "$_fam" > "$_ri_docs/tests/$_fam.md"
  done
  return 0
}

# --render-docs: write the catalog into the live docs/ tree (or TESTDOC_OUT).
# --render-docs --check: render into a temp dir, diff vs on-disk, exit 0 if
# identical, exit 1 + a finding list if any file is missing or differs.
_render_docs() {
  _RD_DOCS="${TESTDOC_OUT:-$REPO_ROOT_RESOLVED/docs}"
  if [ "${1:-}" = "--check" ] || [ "${1:-}" = "--check-render" ]; then
    _RD_TMP=$(mktemp -d -t test-spec-render-XXXXXX)
    # Render the fresh catalog into the temp dir's docs/ shape.
    TESTDOC_OUT="$_RD_TMP/docs" _render_into "$_RD_TMP/docs" >/dev/null 2>&1 || _render_into "$_RD_TMP/docs"
    _RD_FINDINGS=0
    # Compare every freshly-rendered file against the on-disk counterpart.
    # A missing on-disk file or a byte diff is a finding.
    while IFS= read -r _gen; do
      [ -n "$_gen" ] || continue
      _rel="${_gen#"$_RD_TMP/docs/"}"
      _live="$_RD_DOCS/$_rel"
      if [ ! -f "$_live" ]; then
        echo "FINDING: render — docs/$_rel is missing on disk (run: scripts/test-spec.sh --render-docs)"
        _RD_FINDINGS=$((_RD_FINDINGS + 1))
      elif ! diff -q "$_live" "$_gen" >/dev/null 2>&1; then
        echo "FINDING: render — docs/$_rel is stale vs the registry (run: scripts/test-spec.sh --render-docs)"
        _RD_FINDINGS=$((_RD_FINDINGS + 1))
      fi
    done <<EOF
$(find "$_RD_TMP/docs" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)
EOF
    # Reverse: an on-disk docs/tests/*.md with NO freshly-rendered counterpart is
    # an orphan family page (a family was removed from the registry but its page
    # lingers) — also a freshness finding.
    # Hand-authored explainer pages under docs/tests/ are editorial prose, NOT
    # generated from the registry (e.g. the test-hierarchy explainer) — exempt
    # them from the orphan sweep. Keep this list narrow + explicit (space-
    # separated, repo-relative under docs/).
    _HANDAUTHORED_TESTDOCS="tests/test-hierarchy.md"
    if [ -d "$_RD_DOCS/tests" ]; then
      while IFS= read -r _disk; do
        [ -n "$_disk" ] || continue
        _rel="${_disk#"$_RD_DOCS/"}"
        case " $_HANDAUTHORED_TESTDOCS " in
          *" $_rel "*) continue ;;  # hand-authored page, not registry-generated
        esac
        if [ ! -f "$_RD_TMP/docs/$_rel" ]; then
          echo "FINDING: render — docs/$_rel exists on disk but no longer maps to a registry family (run: scripts/test-spec.sh --render-docs)"
          _RD_FINDINGS=$((_RD_FINDINGS + 1))
        fi
      done <<EOF
$(find "$_RD_DOCS/tests" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)
EOF
    fi
    rm -rf "$_RD_TMP"
    if [ "$_RD_FINDINGS" -gt 0 ]; then
      echo "RENDER: findings=$_RD_FINDINGS (the generated test catalog is stale — run: scripts/test-spec.sh --render-docs)"
      return 1
    fi
    echo "OK render — generated test catalog in sync with the registry (findings=0)"
    return 0
  fi
  # Plain --render-docs: write into the live tree.
  _render_into "$_RD_DOCS"
  echo "OK render — wrote $(_render_families | grep -c . || true) family page(s) + docs/test-catalog.md to $_RD_DOCS"
  return 0
}

# ---- Portable seed (a COMPLETE, minimal, VALID general test-spec.md) ----
# The embedded heredoc makes --seed self-contained so a CONSUMER repo — where
# only the deployed scripts/test-spec.sh is present — can self-bootstrap. The
# heredoc and the workbench's spec/test-spec.md stay byte-identical, guarded by
# tests/test-spec.test.sh. NO registry gates here — --seed exists precisely to
# bootstrap a MISSING test-spec.md (the doc-spec.sh --seed lesson).
_emit_seed() {
  cat <<'TESTSPEC_SEED'
<!-- TEST-SPEC-GENERAL:BEGIN (portable — keep byte-identical across adopting repos) -->
# test-spec.md — the verification contract

This file is the single answer to one question: **what stops a broken change
from landing, what rules is the repo's verification surface held to, and at
which layer?** It is both the human-readable map (the prose + the four-layer
table below) and the machine source of truth (the fenced `yaml` registry at the
end), parsed by `test-spec.sh` (resolved `spec/test-spec.md` first, then a root
`test-spec.md` fallback).

This file is the **general tier** of a two-tier contract, delivered verbatim
(`test-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific test logic — the
unit-level enumeration of the verification surface (every validator check,
test sub-suite, CI workflow, git hook) AND the per-mode pipeline gates — lives
in an optional **`test-spec-custom.md` overlay** next to this file (`units:`
rows + a `gates:` array in the same fenced-yaml grammar). The parser merges the
two internally, so consumers see ONE registry. An overlay-absent repo carries
the rules + layers alone: the coverage cross-check stays **inactive** until
`units:` rows exist, and tooling reports that state by name instead of inventing
findings.

## The four verification layers

A change passes through up to four independent verification layers between an
edit and a landed PR. Each layer runs at a different moment and owns a different
kind of guarantee:

| Layer | When it runs | What it owns | Disposition |
|-------|--------------|--------------|-------------|
| **local-hook** | at `git commit` (pre-commit hook) | the commit is structurally valid before it ever leaves your machine | hard-fail (blocks the commit) |
| **ci** | on every PR (GitHub Actions) | the whole tree is structurally + behaviorally sound on a clean runner | hard-fail (gates the PR) |
| **pipeline-gate** | during an orchestrated run | this run did the right thing — isolated, designed, tested, documented, honest — before it reached the PR | mixed (most halt; some advise) |
| **ratchet** | inside ci / the orchestrator | a monotonic property never regresses (VERSION, the portability baseline, doc freshness) | advisory or hard-fail |

The word **"gate"** is reserved here for a single thing: an **inline
orchestrator halt** (a `pipeline-gate` row, declared per repo in the overlay's
`gates:` array). The CI validator-as-a-whole is the **ci** layer (a set of
numbered *checks*), not "the gate." A monotonic guard is a **ratchet**. Three
words, three referents, no overload.

## The five general rules

| Rule | What it asserts |
|------|-----------------|
| `tests-discoverable` | every test file under the repo's test dir(s) is wired into a runner declared by a `units:` row — no silent skips |
| `suite-green` | the declared full-suite runner passes before ship |
| `new-code-tested` | a change that adds behavior carries test rows covering it |
| `units-anchored` | every declared unit's anchor greps in its declared source (forward coverage) |
| `single-owner` | every live test surface resolves to exactly one declared unit (reverse coverage) |

Two enforcement layers stand behind the rules:

- **Deterministic** — `test-spec.sh --check-coverage` mechanizes
  `units-anchored` / `single-owner` / `tests-discoverable` wherever `units:`
  rows exist: forward, every unit's `anchor` must match LIVE in its declared
  `source`; reverse, every live test surface must resolve to exactly one unit;
  floor, the reverse extraction must keep yielding a healthy token count so
  grammar rot can never make the check vacuously pass.
- **Agent-judged** — `suite-green` and `new-code-tested` are judged against the
  repo's current state by the test audit (a red suite or behavior-adding code
  without covering test rows is a finding), layered ABOVE the deterministic
  floor, never replacing it.

## The behavior-coverage axis (optional, overlay-only)

The `rules:` + `layers:` + `units:` axes model the verification *plumbing*:
where verification fires, whether the test inventory is honest, and one row per
verification *mechanism*. None of them captures **what behavior the software
must be proven to do** — the contract is *closed-world over existing tests*, so
a behavior that *should* have a test but doesn't is structurally invisible.

An adopting repo MAY add a third, orthogonal axis in its
`test-spec-custom.md` overlay (these arrays are **optional-on-schema-1** and
live overlay-only — the machine block in this general file is unchanged):

- **`behaviors:`** — one row per *required behavior*: a stable `id`, a
  one-line `statement` (specific enough to fail), a first-class `level`, and an
  optional `area` / `purpose`. The `level` is the closed enum
  `unit | integration | contract | workflow | property` — it lives on the
  *obligation* (the behavior), NOT on a `units:` row, because one mechanism can
  legitimately prove several levels.
- **`behavior_coverage:`** — a many-to-many relation linking each behavior to a
  test-bearing `unit` (family `test | test-deploy | eval | windows-smoke` —
  never `validate | ci | hook`) plus a `source`/`anchor` pair pointing at the
  *semantic evidence* (the behavior named in the test/spec text, not merely the
  runner path).

`test-spec.sh --check-coverage` mechanizes the **structure** of this axis when
`behaviors:` rows exist (independent of the `units:` gate): every coverage link
resolves to exactly one behavior and one test-bearing unit, every `anchor`
greps live in its `source`, and every behavior has at least one covering row —
so a declared-but-uncovered behavior becomes a detectable gap instead of
silence. A repo with no `behaviors:` rows reports "behavior coverage inactive"
and stays green.

**Deterministic checks verify structure, not completeness.** The engine proves
the links resolve and the anchor greps live; it does NOT prove the linked test
*actually proves* the behavior (vs merely mentioning it), that the `level` is
correct, or that one broad test isn't over-claimed against many behaviors. That
substance judgment is the agent-judged test audit's job (`/CJ_test_audit`
Stage 2) — load-bearing, because the deterministic half alone merely relocates
the blind spot from untested code to vague behavior prose.

## The canonical contract-file template

The audit verbs (`/CJ_test_audit`, `/CJ_doc_audit`) own this contract's
canonical shape — what files are required, where they live, and their format:

- **Required** — the general file of each pair: `spec/test-spec.md` (this file)
  and `spec/doc-spec.md`. Each is delivered verbatim by its engine's `--seed`
  and must exist in an adopting repo (the audit seed-delivers a missing one).
- **Optional** — the `*-custom.md` overlay next to each general file
  (`spec/test-spec-custom.md`, `spec/doc-spec-custom.md`): the repo's chosen
  additions (here, the `units:` enumeration + the per-mode `gates:` array),
  merged in by the parser. A repo without an overlay carries the general
  contract alone.
- **Position** — `spec/` is canonical; the repo root is an accepted fallback
  (`test-spec.md` / `doc-spec.md`) for root-style consumers. The engine resolves
  `spec/`-then-root.
- **Format** — a single fenced `yaml` registry for test-spec; a 3-column
  Markdown table (`| Doc | Purpose | Requirement |`) for doc-spec. The block /
  table IS the source of truth, parsed directly.

`test-spec.sh --classify` reports a file's generation (canonical / absent /
duplicated). For test-spec, `--reconcile` is a dedup / no-op: the fenced-yaml
format has been canonical since introduction, so there is no legacy on-disk
format to migrate (unlike doc-spec, which migrates a legacy yaml registry to its
canonical Markdown table).

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file. It carries `rules[]` (the five portable rules) and `layers[]` (the
four-layer map). The repo-specific `units:` enumeration and the per-mode
`gates:` array live in the optional `test-spec-custom.md` overlay.

```yaml
# test-spec registry (parsed by test-spec.sh; merged with the optional
# test-spec-custom.md overlay; consumed by a CI validator + a test-audit skill)
schema_version: 1
rules:
  - id: tests-discoverable
    statement: "Every test file under the repo's test dir(s) (default tests/) is wired into a runner declared by a units: row — a test file on disk that no runner invokes silently never runs."
    scope: "every test file on disk"
    enforced_by: "test-spec.sh --check-coverage reverse sweep (active when units: rows exist)"
  - id: suite-green
    statement: "The declared full-suite runner passes before ship."
    scope: "the whole verification surface"
    enforced_by: "agent-judged by the test audit / QA (a red suite is a finding)"
  - id: new-code-tested
    statement: "A change that adds behavior carries test rows covering it."
    scope: "every behavior-adding change"
    enforced_by: "agent-judged by the test audit / QA (code-without-units drift is a finding)"
  - id: units-anchored
    statement: "Every declared unit's anchor matches LIVE in its declared source file (forward coverage — dead-text mentions do not count)."
    scope: "every units: row"
    enforced_by: "test-spec.sh --check-coverage forward anchor-grep"
  - id: single-owner
    statement: "Every live test surface resolves to exactly one declared unit (reverse coverage)."
    scope: "every live validator banner/comment, test file on disk, CI workflow, installed hook"
    enforced_by: "test-spec.sh --check-coverage reverse sweep + floor (active when units: rows exist)"
layers:
  - id: local-hook
    name: "Local pre-commit hook"
    trigger: "at git commit"
    disposition: hard-fail
    owns: "the commit is structurally valid before it leaves the machine"
  - id: ci
    name: "CI on every PR"
    trigger: "on every PR"
    disposition: hard-fail
    owns: "the whole tree is structurally + behaviorally sound on a clean runner"
  - id: pipeline-gate
    name: "In-orchestrator gates"
    trigger: "during an orchestrated run"
    disposition: mixed
    owns: "this run did the right thing before it reached the PR"
  - id: ratchet
    name: "Regression ratchets"
    trigger: "inside ci / the orchestrator"
    disposition: advisory
    owns: "a monotonic property never regresses"
```
<!-- TEST-SPEC-GENERAL:END -->
TESTSPEC_SEED
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --list-rules)
    _run_registry_gates
    printf '%s\n' "$_RULES" | awk -F'\t' 'NF {print $1}'
    ;;
  --list-units)
    _run_registry_gates
    [ -n "$_UNITS" ] && printf '%s\n' "$_UNITS" | awk -F'\t' 'NF {print $1}'
    exit 0
    ;;
  --list-layers)
    _run_registry_gates
    [ -n "$_LAYERS" ] && printf '%s\n' "$_LAYERS" | awk -F'\t' 'NF {print $1}' | sort -u
    exit 0
    ;;
  --list-gates)
    _run_registry_gates
    [ -n "$_GATES" ] && printf '%s\n' "$_GATES" | awk -F'\t' 'NF {print $1}' | sort -u
    exit 0
    ;;
  --list-behaviors)
    _run_registry_gates
    [ -n "$_BEHAVIORS" ] && printf '%s\n' "$_BEHAVIORS" | awk -F'\t' 'NF {print $1}'
    exit 0
    ;;
  --list-behavior-coverage)
    _run_registry_gates
    [ -n "$_BEHAVIOR_COVERAGE" ] && printf '%s\n' "$_BEHAVIOR_COVERAGE" | awk -F'\t' 'NF {print $1}'
    exit 0
    ;;
  --check-coverage)
    _run_registry_gates
    _run_coverage
    ;;
  --check-workflow-coverage)
    # The workflow-coverage gate (F000070): forward + reverse cross-check between
    # the declared CJ_goal_* orchestrators (workflow-spec.sh --list-orchestrators)
    # and the level:workflow behaviors. Registry-gated skip: an ABSENT test-spec
    # registry exits 0 via _run_registry_gates' REGISTRY=absent path; an absent /
    # non-canonical workflow registry prints the inactive note + exits 0 inside
    # _run_workflow_coverage. HARD (exit 1) only on a real forward/reverse finding.
    _run_registry_gates
    _run_workflow_coverage
    ;;
  --render-docs)
    # (F000069/S000114) Render the generated human test catalog from the merged
    # registry. `--render-docs` writes docs/tests/<family>.md + docs/test-catalog.md;
    # `--render-docs --check` (or --check-render) renders to a temp dir, diffs vs
    # on-disk, exits non-zero on any mismatch/missing/orphan file and 0 when fresh.
    _run_registry_gates
    _render_docs "${2:-}"
    ;;
  --classify)
    # READ-ONLY. No registry gates (classification works on absent/malformed
    # files too). Symmetric with doc-spec.sh --classify; never emits `legacy`
    # (test-spec's yaml format never diverged — see the _classify note).
    _classify
    ;;
  --reconcile)
    # Opt-in. For test-spec this is a dedup / no-op: a canonical file is a clean
    # no-op, a duplicate reports the redundant copy, a malformed file halts.
    # There is NO legacy migration (the format never diverged).
    _reconcile
    ;;
  --seed)
    # NO registry gates — --seed bootstraps a MISSING test-spec.md.
    _emit_seed
    ;;
  --help|-h)
    cat <<'USAGE'
test-spec.sh — parse + validate the two-tier test-spec registry (general rules
+ layers + optional test-spec-custom.md units + gates overlay; all reads
operate on the merge); run the coverage cross-check; emit the portable seed.

Usage:
  test-spec.sh --validate        # REGISTRY=absent/exit 0 when absent; exit 0 OK when valid; halt when invalid
  test-spec.sh --list-rules      # every declared rule id (registry order)
  test-spec.sh --list-units      # every declared unit id (registry order; empty without an overlay)
  test-spec.sh --list-layers     # every declared layer id (general layers[]; sorted)
  test-spec.sh --list-gates      # every declared gate id (overlay gates[]; sorted; empty without an overlay)
  test-spec.sh --list-behaviors  # every declared behavior id (overlay behaviors[]; registry order; empty without an overlay)
  test-spec.sh --list-behavior-coverage # every behavior_coverage row's behavior key (registry order; empty without an overlay)
  test-spec.sh --check-coverage  # forward anchors + reverse sweep + floor (units-gated) + behavior coverage (behaviors-gated)
  test-spec.sh --check-workflow-coverage # forward+reverse gate: every declared CJ_goal_* orchestrator has a level:workflow behavior + no orphan workflow: link (registry-gated skip)
  test-spec.sh --render-docs     # render the generated human test catalog (docs/tests/<family>.md + docs/test-catalog.md) from the merged registry
  test-spec.sh --render-docs --check  # render to a temp dir, diff vs on-disk; exit 0 if fresh, 1 + findings if stale/missing
  test-spec.sh --classify        # READ-ONLY generation detector: emits
                                 #   GENERATION=<canonical|absent|malformed> (never legacy —
                                 #   test-spec's yaml format never diverged)/POSITIONS=/
                                 #   DUPLICATE=<0|1>/CANONICAL_PATH=
  test-spec.sh --reconcile       # opt-in: dedup/no-op for test-spec (canonical => clean no-op;
                                 #   duplicate => report the redundant copy; no legacy migration)
  test-spec.sh --seed            # complete minimal valid general test-spec.md (self-bootstrap)
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--list-rules|--list-units|--list-layers|--list-gates|--list-behaviors|--list-behavior-coverage|--check-coverage|--check-workflow-coverage|--render-docs [--check]|--classify|--reconcile|--seed}" >&2
    exit 2
    ;;
  *)
    echo "test-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
