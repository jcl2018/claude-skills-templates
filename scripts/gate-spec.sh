#!/usr/bin/env bash
# gate-spec.sh — parse + validate the gate-spec.md registry: the single declared
# answer to "what stops a broken cj_goal change from landing, and at which layer?"
#
# gate-spec.md is the third member of the doc-spec -> permission-policy ->
# gate-spec family: ONE file that is simultaneously the human-readable
# verification map (prose + a four-layer summary table + an ASCII diagram +
# a division-of-labor) AND the machine source of truth (the fenced ```yaml
# registry of layers[] + gates[]). This helper parses that registry (awk only —
# no python/yaml dependency, portable to bash 3.2) and mirrors scripts/doc-spec.sh
# + scripts/permission-policy.sh. It is consumed by scripts/validate.sh (Check 22,
# advisory) and scripts/test.sh.
#
# Strict posture (registry-reading subcommands): gate-spec.md missing OR no yaml
# registry OR schema_version unsupported OR a gate missing id/layer/order/markers/
# disposition/backing OR a layer/disposition outside its closed enum OR a markers
# value that is neither a "[...]" literal nor an {enforced_by: subagent|auq}
# escape  ->  HALT with `[gate-spec-no-config] <reason>` on stdout + exit 1.
#
# Subcommands:
#   --validate      exit 0 + print `OK schema_version=<n>` if the registry is
#                   valid; exit 1 + halt-emit otherwise.
#   --list-layers   echo every declared layer id (sorted, unique).
#   --list-gates    echo every declared gate id (sorted, unique).
#   --help|-h
#
# Deferred (no v1 consumer): --list-for <mode> (an ordered per-mode view) and
# --seed (self-bootstrap parity). The Check-22 conformance guard computes the
# per-mode subset internally and does not need --list-for; no skill recreates a
# missing gate-spec.md, so --seed has no caller. Add either when one appears.
#
# layer closed enum:       local-hook | ci | pipeline-gate | ratchet.
# disposition closed enum: hard-fail | advisory | mixed | halt.
# markers value:           a "[...]" literal OR {enforced_by: subagent|auq}.
# schema_version supported: 1.

set -eu

# Strip CRLF from any command output on Windows. No-op on Unix.
_strip_cr() { tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: GATE_SPEC_PATH env override (outermost) -> spec/gate-spec.md
# (this repo, post-relocation) -> root gate-spec.md (root-only consumers).
GATE_SPEC_PATH="${GATE_SPEC_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/gate-spec.md" ] && echo "$REPO_ROOT_RESOLVED/spec/gate-spec.md" || echo "$REPO_ROOT_RESOLVED/gate-spec.md" )}"
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[gate-spec-no-config] $1"
  exit 1
}

# Extract the single fenced ```yaml ... ``` block from gate-spec.md.
_extract_yaml() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$GATE_SPEC_PATH" | _strip_cr
}

_schema_version() {
  _extract_yaml | awk '/^schema_version:/ { print $2; exit }'
}

# Parse the layers[] block into TSV rows: id<TAB>name<TAB>disposition.
# Flag-based, key-anchored — the same shape as doc-spec.sh / permission-policy.sh.
# Only scans within the top-level `layers:` block (stops at `gates:`).
_parse_layers() {
  _extract_yaml | awk '
    function flush() {
      if (cur_id != "") { printf "%s\t%s\t%s\n", cur_id, cur_name, cur_disp }
      cur_id=""; cur_name=""; cur_disp=""
    }
    /^layers:/ { in_layers=1; next }
    /^gates:/  { flush(); in_layers=0; next }
    !in_layers { next }
    /^[[:space:]]*-[[:space:]]*id:/ { flush(); cur_id=$3; next }
    /^[[:space:]]*name:/ { cur_name=$2; next }
    /^[[:space:]]*disposition:/ { cur_disp=$2; next }
    END { if (in_layers) flush() }
  '
}

# Parse the gates[] block into TSV rows:
#   id<TAB>layer<TAB>order<TAB>disposition<TAB>backing_present<TAB>markers_blob
# markers_blob is a space-separated list of `mode=value` tokens, where value is
# either a bracket literal (e.g. [portability-red]) or `enforced_by:<kind>`.
# Flag-based: a `- id:` opens a gate, a `markers:` opens the per-mode map (each
# `mode: value` line under it is a marker), the next `- id:` (or `keyN:` at the
# gate-key indent) closes the map. backing_present is 1 when a `backing:` key was
# seen for the gate (its value can be free text, so we only record presence).
_parse_gates() {
  _extract_yaml | awk '
    function flush() {
      if (cur_id != "") {
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", cur_id, cur_layer, cur_order, cur_disp, cur_backing, cur_markers
      }
      cur_id=""; cur_layer=""; cur_order=""; cur_disp=""; cur_backing="0"; cur_markers=""; in_markers=0
    }
    /^gates:/ { in_gates=1; next }
    !in_gates { next }
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
      # Strip a trailing inline comment.
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
    END { flush() }
  '
}

# ---- Validation gates (run ONLY for registry-reading subcommands) ----
_run_registry_gates() {
  [ -f "$GATE_SPEC_PATH" ] || emit_halt "gate-spec.md missing (looked in spec/ then root): $GATE_SPEC_PATH"

  _YAML_BODY=$(_extract_yaml)
  [ -n "$_YAML_BODY" ] || emit_halt "gate-spec.md has no fenced \`\`\`yaml registry block"

  SCHEMA_VERSION=$(_schema_version)
  [ -n "$SCHEMA_VERSION" ] || emit_halt "schema_version field missing in the gate-spec registry"

  SCHEMA_OK=0
  for v in $SUPPORTED_SCHEMA_VERSIONS; do
    [ "$SCHEMA_VERSION" = "$v" ] && { SCHEMA_OK=1; break; }
  done
  [ "$SCHEMA_OK" -eq 1 ] || emit_halt "schema_version=${SCHEMA_VERSION} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"

  _LAYERS=$(_parse_layers)
  [ -n "$_LAYERS" ] || emit_halt "the gate-spec registry declares no layers (empty layers[] list)"

  # Every layer must have id + name + disposition; disposition in the enum.
  while IFS="$(printf '\t')" read -r _lid _lname _ldisp; do
    [ -n "$_lid" ] || emit_halt "a layer is missing 'id'"
    [ -n "$_lname" ] || emit_halt "layer '$_lid' is missing 'name'"
    [ -n "$_ldisp" ] || emit_halt "layer '$_lid' is missing 'disposition'"
    case "$_lid" in
      local-hook|ci|pipeline-gate|ratchet) : ;;
      *) emit_halt "layer id '$_lid' is outside the closed enum {local-hook, ci, pipeline-gate, ratchet}" ;;
    esac
    case "$_ldisp" in
      hard-fail|advisory|mixed|halt) : ;;
      *) emit_halt "layer '$_lid' has disposition '$_ldisp' outside the closed enum {hard-fail, advisory, mixed, halt}" ;;
    esac
  done <<EOF
$_LAYERS
EOF

  _GATES=$(_parse_gates)
  [ -n "$_GATES" ] || emit_halt "the gate-spec registry declares no gates (empty gates[] list)"

  # Every gate must have id + layer + order + disposition + backing + >=1 marker;
  # layer + disposition in their enums; every markers value a literal or an
  # enforced_by escape.
  while IFS="$(printf '\t')" read -r _gid _glayer _gorder _gdisp _gback _gmarkers; do
    [ -n "$_gid" ] || emit_halt "a gate is missing 'id'"
    [ -n "$_glayer" ] || emit_halt "gate '$_gid' is missing 'layer'"
    [ -n "$_gorder" ] || emit_halt "gate '$_gid' is missing 'order'"
    [ -n "$_gdisp" ] || emit_halt "gate '$_gid' is missing 'disposition'"
    [ "$_gback" = "1" ] || emit_halt "gate '$_gid' is missing 'backing'"
    [ -n "$_gmarkers" ] || emit_halt "gate '$_gid' has an empty 'markers' map (a gate runs in >=1 mode)"
    case "$_glayer" in
      local-hook|ci|pipeline-gate|ratchet) : ;;
      *) emit_halt "gate '$_gid' has layer '$_glayer' outside the closed enum {local-hook, ci, pipeline-gate, ratchet}" ;;
    esac
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
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --list-layers)
    _run_registry_gates
    printf '%s\n' "$_LAYERS" | awk -F'\t' '{print $1}' | sort -u
    ;;
  --list-gates)
    _run_registry_gates
    printf '%s\n' "$_GATES" | awk -F'\t' '{print $1}' | sort -u
    ;;
  --help|-h)
    cat <<'USAGE'
gate-spec.sh — parse + validate the gate-spec.md registry.

Usage:
  gate-spec.sh --validate      # exit 0 if the registry schema is ok
  gate-spec.sh --list-layers   # every declared layer id
  gate-spec.sh --list-gates    # every declared gate id

Deferred (no v1 consumer): --list-for <mode>, --seed.
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--list-layers|--list-gates}" >&2
    exit 2
    ;;
  *)
    echo "gate-spec.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
