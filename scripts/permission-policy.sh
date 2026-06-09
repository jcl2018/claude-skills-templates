#!/usr/bin/env bash
# permission-policy.sh — parse + validate the permission-policy.md registry;
# resolve a verb to its mode; emit the surface globs the cj-handoff-gate
# denylist derives from.
#
# permission-policy.md is the single source of truth for "what is a cj_goal
# orchestrator allowed to do." It carries prose + ONE fenced ```yaml registry of
# {verb, kind, mode, scope} rows. This helper parses that registry (awk only —
# no python/yaml dependency, portable to bash 3.2) and is consumed by
# scripts/validate.sh (Check 21), scripts/cj-handoff-gate.sh (denylist
# derivation), and scripts/test.sh. Mirrors scripts/doc-spec.sh.
#
# An unenumerated verb resolves to `deny` (design permission before capability —
# fail closed).
#
# Subcommands:
#   --validate              exit 0 + print `OK schema_version=<n>` if the registry
#                           is valid; exit 1 + `[permission-policy-no-config]`
#                           otherwise.
#   --resolve <verb>        print the verb's mode (allow|ask|deny); an absent verb
#                           prints `deny` (fail closed). exit 0.
#   --surface-globs [mode]  print the `scope` of kind=surface rows, one per line
#                           (optionally filtered to a single mode allow|ask|deny).
#   --deny-verbs            print the `verb` of mode=deny rows, one per line.
#   --help|-h
#
# mode closed enum: allow | ask | deny.   kind closed enum: surface | op.
# schema_version supported: 1.

set -eu

_strip_cr() { tr -d '\r'; }

REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
# Resolution order: PERMISSION_POLICY_PATH env override (outermost) ->
# spec/permission-policy.md (this repo, post-relocation) -> root
# permission-policy.md (root-only consumers).
POLICY_PATH="${PERMISSION_POLICY_PATH:-$( [ -f "$REPO_ROOT_RESOLVED/spec/permission-policy.md" ] && echo "$REPO_ROOT_RESOLVED/spec/permission-policy.md" || echo "$REPO_ROOT_RESOLVED/permission-policy.md" )}"
SUPPORTED_SCHEMA_VERSIONS="1"

emit_halt() {
  echo "[permission-policy-no-config] $1"
  exit 1
}

# Extract the single fenced ```yaml ... ``` block from permission-policy.md.
_extract_yaml() {
  awk '
    /^```yaml/ { if (!seen) { f=1; seen=1; next } }
    /^```/     { if (f) { f=0 } }
    f          { print }
  ' "$POLICY_PATH" | _strip_cr
}

# Parse the registry block into TSV rows: verb<TAB>kind<TAB>mode<TAB>scope.
# Flag-based, key-anchored — the same shape as scripts/doc-spec.sh's parser.
_parse_policy() {
  _extract_yaml | awk '
    function flush() {
      if (cur_verb != "") {
        printf "%s\t%s\t%s\t%s\n", cur_verb, cur_kind, cur_mode, cur_scope
      }
      cur_verb=""; cur_kind=""; cur_mode=""; cur_scope=""
    }
    /^[[:space:]]*-[[:space:]]*verb:/ { flush(); cur_verb=$3; next }
    /^[[:space:]]*kind:/ { cur_kind=$2; next }
    /^[[:space:]]*mode:/ { cur_mode=$2; next }
    /^[[:space:]]*scope:/ {
      line=$0
      sub(/^[[:space:]]*scope:[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      cur_scope=line
      next
    }
    END { flush() }
  '
}

_schema_version() {
  _extract_yaml | awk '/^schema_version:/ { print $2; exit }'
}

# ---- Validation gates (run ONLY for registry-reading subcommands) ----
_run_registry_gates() {
  [ -f "$POLICY_PATH" ] || emit_halt "permission-policy.md missing at: $POLICY_PATH"

  _YAML_BODY=$(_extract_yaml)
  [ -n "$_YAML_BODY" ] || emit_halt "permission-policy.md has no fenced \`\`\`yaml registry block"

  SCHEMA_VERSION=$(_schema_version)
  [ -n "$SCHEMA_VERSION" ] || emit_halt "schema_version field missing in the policy registry"

  SCHEMA_OK=0
  for v in $SUPPORTED_SCHEMA_VERSIONS; do
    [ "$SCHEMA_VERSION" = "$v" ] && { SCHEMA_OK=1; break; }
  done
  [ "$SCHEMA_OK" -eq 1 ] || emit_halt "schema_version=${SCHEMA_VERSION} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS})"

  _ROWS=$(_parse_policy)
  [ -n "$_ROWS" ] || emit_halt "the policy registry declares no rows (empty policy[] list)"

  # Every row must have verb + kind + mode + scope; kind + mode in their enums.
  while IFS="$(printf '\t')" read -r _v _k _m _s; do
    [ -n "$_v" ] || emit_halt "a policy row is missing 'verb'"
    [ -n "$_k" ] || emit_halt "policy row '$_v' is missing 'kind'"
    [ -n "$_m" ] || emit_halt "policy row '$_v' is missing 'mode'"
    [ -n "$_s" ] || emit_halt "policy row '$_v' is missing 'scope'"
    case "$_k" in
      surface|op) : ;;
      *) emit_halt "policy row '$_v' has kind '$_k' outside the closed enum {surface, op}" ;;
    esac
    case "$_m" in
      allow|ask|deny) : ;;
      *) emit_halt "policy row '$_v' has mode '$_m' outside the closed enum {allow, ask, deny}" ;;
    esac
  done <<EOF
$_ROWS
EOF
}

# ---- Subcommand dispatch ----

case "${1:-}" in
  --validate)
    _run_registry_gates
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --resolve)
    _verb="${2:-}"
    [ -n "$_verb" ] || { echo "permission-policy.sh --resolve needs a <verb>" >&2; exit 2; }
    _run_registry_gates
    # Print the verb's mode; an UNENUMERATED verb fails closed to `deny`.
    _mode=$(printf '%s\n' "$_ROWS" | awk -F'\t' -v v="$_verb" '$1==v { print $3; found=1; exit } END { if (!found) print "deny" }')
    [ -n "$_mode" ] || _mode="deny"
    echo "$_mode"
    ;;
  --surface-globs)
    _filter="${2:-}"   # optional: allow | ask | deny
    _run_registry_gates
    printf '%s\n' "$_ROWS" | awk -F'\t' -v m="$_filter" '
      $2=="surface" && (m=="" || $3==m) { print $4 }
    ' | grep -v '^$' | sort -u || true
    ;;
  --deny-verbs)
    _run_registry_gates
    printf '%s\n' "$_ROWS" | awk -F'\t' '$3=="deny" { print $1 }' | sort -u || true
    ;;
  --help|-h)
    cat <<'USAGE'
permission-policy.sh — parse + validate the permission-policy.md registry.

Usage:
  permission-policy.sh --validate              # exit 0 if the registry schema is ok
  permission-policy.sh --resolve <verb>        # the verb's mode; absent verb -> deny
  permission-policy.sh --surface-globs [mode]  # kind=surface scopes (optionally by mode)
  permission-policy.sh --deny-verbs            # mode=deny verbs
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--validate|--resolve <verb>|--surface-globs [mode]|--deny-verbs}" >&2
    exit 2
    ;;
  *)
    echo "permission-policy.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
