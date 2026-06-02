#!/usr/bin/env bash
# tests/cj-document-release-config.test.sh
#
# Unit-shape regression test for the workbench's own cj-document-release.json
# (F000037). Validates the JSON file itself — schema_version, whitelist_patterns
# shape, categories shape, identifier-shape category names, and F000036-compat
# category presence (readme, changelog, claude, architecture, philosophy,
# skill-catalog).
#
# Asserts (≥6):
#   1. cj-document-release.json is valid JSON (`jq empty` passes)
#   2. .schema_version == 1
#   3. .whitelist_patterns is a non-empty array of strings
#   4. .categories is a non-empty object
#   5. Every .categories[*] value is a non-empty array of strings
#   6. Every category name matches identifier regex ^[a-z][a-z0-9-]*$
#   7. All 6 F000036-compat categories present (readme, changelog, claude,
#      architecture, philosophy, skill-catalog)

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CONFIG="$REPO_ROOT/cj-document-release.json"

echo "=== cj-document-release-config.json: JSON file assertions ==="

# 1. JSON exists + is valid
if [ ! -f "$CONFIG" ]; then
  fail_test "cj-document-release.json missing at repo root: $CONFIG"
  echo "FAIL: cj-document-release-config ($ERRORS error(s))"
  exit 1
fi
if jq empty "$CONFIG" 2>/dev/null; then
  ok "cj-document-release.json is valid JSON"
else
  fail_test "cj-document-release.json is not valid JSON"
fi

# 2. schema_version
SV=$(jq -r '.schema_version // empty' "$CONFIG")
if [ "$SV" = "1" ]; then
  ok ".schema_version == 1"
else
  fail_test ".schema_version != 1 (got '$SV')"
fi

# 3. whitelist_patterns shape
if jq -e '.whitelist_patterns | type == "array" and length > 0' "$CONFIG" >/dev/null 2>&1; then
  ok ".whitelist_patterns is a non-empty array"
else
  fail_test ".whitelist_patterns is missing or not a non-empty array"
fi
if jq -e '[.whitelist_patterns[] | type == "string"] | all' "$CONFIG" >/dev/null 2>&1; then
  ok ".whitelist_patterns contains only strings"
else
  fail_test ".whitelist_patterns contains non-string entries"
fi

# 4. categories shape (object, non-empty)
if jq -e '.categories | type == "object" and (length > 0)' "$CONFIG" >/dev/null 2>&1; then
  ok ".categories is a non-empty object"
else
  fail_test ".categories is missing or empty or not an object"
fi

# 5. Every category value is a non-empty array of strings
if jq -e '[.categories | to_entries[] | .value | type == "array" and length > 0] | all' "$CONFIG" >/dev/null 2>&1; then
  ok "every category value is a non-empty array"
else
  fail_test "at least one category value is missing, empty, or non-array"
fi
if jq -e '[.categories | to_entries[] | .value[] | type == "string"] | all' "$CONFIG" >/dev/null 2>&1; then
  ok "every category entry is a string"
else
  fail_test "at least one category entry is non-string"
fi

# 6. Category name identifier shape: ^[a-z][a-z0-9-]*$
BAD_NAMES=$(jq -r '.categories | keys[] | select(test("^[a-z][a-z0-9-]*$") | not)' "$CONFIG")
if [ -z "$BAD_NAMES" ]; then
  ok "all category names match identifier shape ^[a-z][a-z0-9-]*$"
else
  fail_test "category names violating identifier shape: $BAD_NAMES"
fi

# 7. F000036-compat: 6 named categories present
F36_COMPAT="readme changelog claude architecture philosophy skill-catalog"
MISSING=""
for cat in $F36_COMPAT; do
  if ! jq -e --arg c "$cat" '.categories | has($c)' "$CONFIG" >/dev/null 2>&1; then
    MISSING="$MISSING $cat"
  fi
done
if [ -z "$MISSING" ]; then
  ok "all 6 F000036-compat categories present (readme, changelog, claude, architecture, philosophy, skill-catalog)"
else
  fail_test "F000036-compat categories missing:$MISSING"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-document-release-config"
  exit 0
else
  echo "FAIL: cj-document-release-config ($ERRORS error(s))"
  exit 1
fi
