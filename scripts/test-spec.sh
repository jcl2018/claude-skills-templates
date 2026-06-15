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
#                      Findings print as `FINDING: ...` lines; exit 1 on any.
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
    /^(units|layers|gates):/   { flush(); in_rules=0; next }
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
    /^(rules|layers|gates):/   { flush(); in_units=0; next }
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
    /^(rules|units|gates):/    { flush(); in_layers=0; next }
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
# either a bracket literal (e.g. [portability-red]) or `enforced_by:<kind>`.
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
    /^(rules|units|layers):/   { flush(); in_gates=0; next }
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

# ---- Coverage cross-check (the Check 24 engine, ported) ----
# Forward + reverse + floor. Findings print as `FINDING: ...`; the summary line
# is the last line either way. Exit 1 on any finding. The reverse sweep + floor
# apply ONLY when units: rows exist (the units-gated contract): a rules-only
# registry — the seeded consumer default — prints a named inactive note + exits
# 0 instead of misleading extraction-grammar findings.
_run_coverage() {
  if [ -z "$_UNITS" ]; then
    echo "no units declared — coverage cross-check inactive; declare units in spec/test-spec-custom.md to activate"
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
  # grammar-rot signal ONLY when that namespace's surface EXISTS on disk. A
  # consumer repo that adopts the contract against its own surface (vitest
  # *.test.ts + a workflow, with NO scripts/validate.sh / tests/*.test.sh /
  # scripts/setup-hooks.sh) legitimately yields zero tokens in the absent
  # namespaces — that is N/A, not rot. The global floor is calibrated to the
  # FULL workbench shape, so it applies only when ALL FOUR surfaces are present;
  # a partial/consumer surface set legitimately yields few tokens and relies on
  # the surface-gated per-namespace floors instead. (Same `for ...; do [ -e
  # "$x" ] && { ...; break; }; done` existence idiom the reverse sweep uses.)
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
  _SURFACES_PRESENT=$(( _SURF_VALIDATE + _SURF_TESTS + _SURF_WF + _SURF_HOOKS ))

  _FLOOR="${TEST_SPEC_REVERSE_FLOOR:-20}"
  # Global floor: fires only when the full workbench surface set is present (the
  # floor value is calibrated to that shape; a partial set legitimately yields
  # few tokens, so a flat global floor would false-fire there).
  if [ "$_SURFACES_PRESENT" -eq 4 ] && [ "$_TOKENS" -lt "$_FLOOR" ]; then
    echo "FINDING: floor — reverse extraction yielded only $_TOKENS live token(s) (< $_FLOOR); the extraction grammar no longer matches the live surface"
    _FINDINGS=$((_FINDINGS + 1))
  fi
  # Per-namespace floors: fire on a PRESENT-but-zero-token namespace (genuine
  # grammar rot); skip an ABSENT-surface namespace (consumer repo — N/A).
  for _ns in "validate:$_NS_VALIDATE:$_SURF_VALIDATE" \
             "test-files:$_NS_TESTS:$_SURF_TESTS" \
             "workflows:$_NS_WF:$_SURF_WF" \
             "hooks:$_NS_HOOKS:$_SURF_HOOKS"; do
    _ns_name="${_ns%%:*}"; _ns_rest="${_ns#*:}"
    _ns_count="${_ns_rest%%:*}"; _ns_surf="${_ns_rest#*:}"
    if [ "$_ns_surf" -eq 1 ] && [ "$_ns_count" -eq 0 ]; then
      echo "FINDING: floor — reverse extraction yielded ZERO live tokens in the '$_ns_name' namespace; that namespace's extraction grammar no longer matches the live surface"
      _FINDINGS=$((_FINDINGS + 1))
    fi
  done

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
  --check-coverage)
    _run_registry_gates
    _run_coverage
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
  test-spec.sh --check-coverage  # forward anchors + reverse sweep + floor (units-gated)
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
    echo "Usage: $0 {--validate|--list-rules|--list-units|--list-layers|--list-gates|--check-coverage|--classify|--reconcile|--seed}" >&2
    exit 2
    ;;
  *)
    echo "test-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
