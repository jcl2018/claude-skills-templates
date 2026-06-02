#!/usr/bin/env bash
# cj-document-release-config.sh — parse + validate cj-document-release.json;
# expand globs against the working tree; return one of {parsed JSON shape |
# [doc-sync-no-config] halt verdict}. F000037 strict-required posture: file
# missing OR invalid JSON OR schema_version unsupported OR required fields
# missing → HALT with `[doc-sync-no-config] <reason>` on stdout + exit 1.
#
# Mirrors scripts/skills-doc-sync-check (F000029) shape: one bash file owns the
# parse/match logic; the SKILL.md prose captures helper output and acts on it.
#
# Subcommands:
#   --parse              echo the parsed JSON (pretty-printed via `jq '.'`)
#   --expand-whitelist   echo the expanded whitelist file list (globs resolved
#                        against working tree; sorted, unique)
#   --resolve <token>    echo file list for one category token; exit 1 +
#                        halt-emit if token not declared in `categories`
#   --validate           exit 0 + print `OK schema_version=<n>` if JSON is valid
#                        + schema_version supported; exit 1 + halt-emit otherwise
#
# Globs use bash-globstar semantics (`**` for any-depth recursion). Helper
# enables `shopt -s globstar nullglob` so unmatched patterns return empty.
#
# Schema v1 shape:
#   {
#     "schema_version": 1,
#     "whitelist_patterns": ["glob", ...],
#     "categories": { "name": ["glob", ...], ... }
#   }

set -eu

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
# Mirrors scripts/skills-doc-sync-check defense.
jq() { command jq "$@" | tr -d '\r'; }

# Resolve repo root (allows REPO_ROOT override for tests).
REPO_ROOT_RESOLVED="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "")}"
JSON_PATH="${REPO_ROOT_RESOLVED}/cj-document-release.json"
SUPPORTED_SCHEMA_VERSIONS=(1)

emit_halt() {
  echo "[doc-sync-no-config] $1"
  exit 1
}

# Expand a single glob pattern against the working tree. Handles both `**`
# recursive globs (via `find`) AND simple shell globs (via shell expansion).
# Portable across bash 3.2 (macOS default) and bash 4+ — does NOT require
# `shopt -s globstar`, which is bash 4+ only.
#
# Args: $1 = pattern (e.g. `README.md`, `doc/**/*.md`, `templates/doc-*.md`)
# Writes matched file paths to stdout, one per line. No output if no match.
expand_pattern() {
  local pattern="$1"
  if [[ "$pattern" == *"**"* ]]; then
    # Recursive: split on `**` once; treat as `<prefix>**<suffix>`. Anchor at
    # repo root via find; filter by suffix glob.
    local prefix="${pattern%%\*\**}"
    local suffix="${pattern##*\*\*}"
    # Strip trailing slash from prefix; strip leading slash from suffix.
    prefix="${prefix%/}"
    suffix="${suffix#/}"
    local search_root="${prefix:-.}"
    if [ -d "$search_root" ]; then
      # find prints all files under search_root; name filter applies to the
      # basename of the suffix (the leaf glob).
      local name_filter="${suffix##*/}"
      if [ -n "$name_filter" ]; then
        find "$search_root" -type f -name "$name_filter" 2>/dev/null || true
      else
        find "$search_root" -type f 2>/dev/null || true
      fi
    fi
  else
    # Simple shell glob; let the shell expand it. nullglob behavior is faked
    # by checking `-f` per result (an unmatched literal pattern stays the
    # literal string, which `-f` rejects).
    local f
    # shellcheck disable=SC2086  # intentional word-splitting for glob expansion
    for f in $pattern; do
      if [ -f "$f" ]; then
        echo "$f"
      fi
    done
  fi
  # Always exit 0 — patterns that match nothing are not an error (nullglob
  # semantics). Without this, set -e in the caller terminates the while loop
  # when [ -f ] returns false on a non-matching pattern.
  return 0
}

# ---- Validation gates (always run before subcommand dispatch) ----

[ -f "$JSON_PATH" ] || emit_halt "cj-document-release.json missing at repo root: $JSON_PATH"
command jq empty "$JSON_PATH" 2>/dev/null || emit_halt "cj-document-release.json is not valid JSON: $JSON_PATH"

SCHEMA_VERSION=$(jq -r '.schema_version // empty' "$JSON_PATH")
[ -n "$SCHEMA_VERSION" ] || emit_halt "schema_version field missing in $JSON_PATH"

# Check schema_version against supported list.
SCHEMA_OK=0
for v in "${SUPPORTED_SCHEMA_VERSIONS[@]}"; do
  if [ "$SCHEMA_VERSION" = "$v" ]; then
    SCHEMA_OK=1
    break
  fi
done
[ "$SCHEMA_OK" -eq 1 ] || emit_halt "schema_version=${SCHEMA_VERSION} unsupported (this helper supports ${SUPPORTED_SCHEMA_VERSIONS[*]})"

# Required fields.
jq -e '.whitelist_patterns | type == "array"' "$JSON_PATH" >/dev/null \
  || emit_halt "whitelist_patterns missing or not an array in $JSON_PATH"
jq -e '.categories | type == "object"' "$JSON_PATH" >/dev/null \
  || emit_halt "categories missing or not an object in $JSON_PATH"

# ---- Subcommand dispatch ----

case "${1:-}" in
  --parse)
    jq '.' "$JSON_PATH"
    ;;
  --expand-whitelist)
    cd "$REPO_ROOT_RESOLVED"
    {
      while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        expand_pattern "$pattern"
      done < <(jq -r '.whitelist_patterns[]' "$JSON_PATH")
    } | sort -u
    ;;
  --resolve)
    TOKEN="${2:-}"
    [ -n "$TOKEN" ] || emit_halt "--resolve requires a category token"
    HAS=$(jq -r --arg t "$TOKEN" '.categories | has($t)' "$JSON_PATH")
    [ "$HAS" = "true" ] || emit_halt "category '$TOKEN' not declared in cj-document-release.json"
    cd "$REPO_ROOT_RESOLVED"
    {
      while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        expand_pattern "$pattern"
      done < <(jq -r --arg t "$TOKEN" '.categories[$t][]' "$JSON_PATH")
    } | sort -u
    ;;
  --validate)
    echo "OK schema_version=$SCHEMA_VERSION"
    ;;
  --help|-h)
    cat <<'USAGE'
cj-document-release-config.sh — parse + validate cj-document-release.json.

Usage:
  cj-document-release-config.sh --parse              # pretty-print JSON
  cj-document-release-config.sh --expand-whitelist   # expanded whitelist files
  cj-document-release-config.sh --resolve <token>    # files for one category
  cj-document-release-config.sh --validate           # exit 0 if schema ok
USAGE
    exit 0
    ;;
  "")
    echo "Usage: $0 {--parse|--expand-whitelist|--resolve <token>|--validate}" >&2
    exit 2
    ;;
  *)
    echo "cj-document-release-config.sh: unknown subcommand '$1'" >&2
    echo "  see --help" >&2
    exit 2
    ;;
esac
