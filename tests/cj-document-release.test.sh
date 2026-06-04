#!/usr/bin/env bash
# tests/cj-document-release.test.sh
#
# Unit-shape regression test for the CJ_document-release skill (F000036).
# Pattern: file content greps + frontmatter parsing.
#
# Asserts (≥10):
#   1. SKILL.md exists
#   2. USAGE.md exists
#   3. SKILL.md YAML frontmatter has name=CJ_document-release
#   4. SKILL.md frontmatter mentions --docs flag in description
#   5. SKILL.md frontmatter has version: 0.1.0
#   6. SKILL.md frontmatter allowed-tools includes Bash, Read, Glob, Grep, Skill
#   7. USAGE.md has all 5 required H2 sections (When to use / When NOT to use /
#      Mental model / Common pitfalls / Related skills)
#   8. skills-catalog.json contains CJ_document-release entry with
#      status=experimental + portability=workbench
#   9. doc/ARCHITECTURE.md component roster has the **CJ_document-release** entry
#      (T000037: the skill moved from the retired per-skill catalog doc's
#      phase-step section to the ARCHITECTURE non-workflow roster — only
#      CJ_goal_* orchestrators get a doc/WORKFLOWS.md section now)
#  10. `[doc-sync-red]` halt-marker grep returns ≥1 in SKILL.md
#  11. `[doc-sync-non-doc-write]` halt-marker grep returns ≥1 in SKILL.md
#  12. Branch refusal prose grep returns ≥1 in SKILL.md
#  13. Clean-tree refusal prose grep returns ≥1 in SKILL.md
#  14. --docs arg parse prose mentioned (grep ≥1) in SKILL.md
#  15. --docs README example prose mentioned in SKILL.md (Usage block)
#  16. --docs all token mentioned in SKILL.md

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

SKILL_MD="$REPO_ROOT/skills/CJ_document-release/SKILL.md"
USAGE_MD="$REPO_ROOT/skills/CJ_document-release/USAGE.md"
CATALOG="$REPO_ROOT/skills-catalog.json"
ARCHITECTURE_DOC="$REPO_ROOT/doc/ARCHITECTURE.md"

echo "=== cj-document-release: skill structure + body assertions ==="

# 1. SKILL.md exists
if [ -f "$SKILL_MD" ]; then
  ok "skills/CJ_document-release/SKILL.md exists"
else
  fail_test "skills/CJ_document-release/SKILL.md is missing"
fi

# 2. USAGE.md exists
if [ -f "$USAGE_MD" ]; then
  ok "skills/CJ_document-release/USAGE.md exists"
else
  fail_test "skills/CJ_document-release/USAGE.md is missing"
fi

# 3. SKILL.md frontmatter has name
if grep -qE '^name: CJ_document-release$' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md frontmatter: name = CJ_document-release"
else
  fail_test "SKILL.md frontmatter: name field missing or wrong"
fi

# 4. Description mentions --docs flag
if grep -q '\-\-docs' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md mentions --docs flag"
else
  fail_test "SKILL.md does not mention --docs flag"
fi

# 5. Version frontmatter
if grep -qE '^version: 0\.1\.0$' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md frontmatter: version = 0.1.0"
else
  fail_test "SKILL.md frontmatter: version != 0.1.0"
fi

# 6. allowed-tools includes the 5 expected
FM=$(sed -n '/^---$/,/^---$/p' "$SKILL_MD" 2>/dev/null)
MISSING_TOOLS=""
for tool in Bash Read Glob Grep Skill; do
  if ! echo "$FM" | grep -qE "^  - $tool$"; then
    MISSING_TOOLS="$MISSING_TOOLS $tool"
  fi
done
if [ -z "$MISSING_TOOLS" ]; then
  ok "SKILL.md frontmatter: allowed-tools includes Bash, Read, Glob, Grep, Skill"
else
  fail_test "SKILL.md frontmatter: allowed-tools missing:$MISSING_TOOLS"
fi

# 7. USAGE.md has 5 required H2 sections
USAGE_MISSING=""
for sec in "## When to use" "## When NOT to use" "## Mental model" "## Common pitfalls" "## Related skills"; do
  if ! grep -qFx "$sec" "$USAGE_MD" 2>/dev/null; then
    USAGE_MISSING="$USAGE_MISSING $sec;"
  fi
done
if [ -z "$USAGE_MISSING" ]; then
  ok "USAGE.md has all 5 required H2 sections"
else
  fail_test "USAGE.md missing required section(s): $USAGE_MISSING"
fi

# 8. Catalog entry exists + correct status/portability
CATALOG_STATUS=$(jq -r '.[] | select(.name=="CJ_document-release") | .status' "$CATALOG" 2>/dev/null)
CATALOG_PORTABILITY=$(jq -r '.[] | select(.name=="CJ_document-release") | .portability' "$CATALOG" 2>/dev/null)
if [ "$CATALOG_STATUS" = "experimental" ] && [ "$CATALOG_PORTABILITY" = "workbench" ]; then
  ok "skills-catalog.json: CJ_document-release entry has status=experimental + portability=workbench"
else
  fail_test "skills-catalog.json: CJ_document-release entry wrong (status=$CATALOG_STATUS portability=$CATALOG_PORTABILITY)"
fi

# 9. doc/ARCHITECTURE.md component roster entry exists (T000037: moved here from
# the retired per-skill catalog doc's phase-step section)
if grep -qE '^- \*\*CJ_document-release\*\*' "$ARCHITECTURE_DOC" 2>/dev/null; then
  ok "doc/ARCHITECTURE.md component roster has the **CJ_document-release** entry"
else
  fail_test "doc/ARCHITECTURE.md component roster missing the **CJ_document-release** entry"
fi

# 9b. The roster entry names the Step 5.5 inline doc-sync role (the phase-step
# semantics, now carried in prose rather than a closed-enum tag)
if grep -qE '^- \*\*CJ_document-release\*\* .*Step 5\.5' "$ARCHITECTURE_DOC" 2>/dev/null; then
  ok "doc/ARCHITECTURE.md CJ_document-release roster entry names the Step 5.5 inline role"
else
  fail_test "doc/ARCHITECTURE.md CJ_document-release roster entry missing the Step 5.5 role description"
fi

# 10. [doc-sync-red] halt-marker grep
if grep -qF '[doc-sync-red]' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md contains [doc-sync-red] halt marker"
else
  fail_test "SKILL.md missing [doc-sync-red] halt marker"
fi

# 11. [doc-sync-non-doc-write] halt-marker grep
if grep -qF '[doc-sync-non-doc-write]' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md contains [doc-sync-non-doc-write] halt marker"
else
  fail_test "SKILL.md missing [doc-sync-non-doc-write] halt marker"
fi

# 12. Branch refusal prose grep
if grep -qE 'refuses on the base branch' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md documents base-branch refusal"
else
  fail_test "SKILL.md does not document base-branch refusal prose"
fi

# 13. Clean-tree refusal prose grep
if grep -qE 'Working tree has uncommitted non-doc changes' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md documents clean-tree refusal"
else
  fail_test "SKILL.md does not document clean-tree refusal prose"
fi

# 14. --docs arg-parsing prose grep (look for case-insensitive parsing note)
if grep -qE 'case-insensitive' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md documents --docs case-insensitive parsing"
else
  fail_test "SKILL.md does not document --docs parsing"
fi

# 15. --docs README example in Usage block
if grep -qE '\-\-docs README,CHANGELOG' "$SKILL_MD" 2>/dev/null \
   || grep -qE '\-\-docs README$' "$SKILL_MD" 2>/dev/null \
   || grep -qE '\-\-docs README ' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md has --docs README example"
else
  fail_test "SKILL.md missing --docs README example"
fi

# 16. --docs all explicit token
if grep -qE '\-\-docs all' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md documents --docs all explicit no-filter token"
else
  fail_test "SKILL.md missing --docs all explicit token documentation"
fi

# --- F000037 extensions: cj-document-release.json + helper assertions ---

CONFIG_JSON="$REPO_ROOT/cj-document-release.json"
HELPER="$REPO_ROOT/scripts/cj-document-release-config.sh"

# 17. cj-document-release.json exists at repo root (F000037)
if [ -f "$CONFIG_JSON" ]; then
  ok "cj-document-release.json exists at repo root"
else
  fail_test "cj-document-release.json missing at repo root (F000037 strict-required)"
fi

# 18. Helper script exists + executable
if [ -x "$HELPER" ]; then
  ok "scripts/cj-document-release-config.sh exists and is executable"
else
  fail_test "scripts/cj-document-release-config.sh missing or not executable"
fi

# 19. Helper --validate exits 0
if [ -x "$HELPER" ] && bash "$HELPER" --validate >/dev/null 2>&1; then
  ok "helper --validate exits 0 against workbench JSON"
else
  fail_test "helper --validate did not exit 0"
fi

# 20. Helper --parse returns valid JSON with required keys
if [ -x "$HELPER" ]; then
  _PARSE_OUT=$(bash "$HELPER" --parse 2>/dev/null || echo "")
  if printf '%s' "$_PARSE_OUT" | jq -e '.schema_version == 1 and (.whitelist_patterns | type == "array") and (.categories | type == "object")' >/dev/null 2>&1; then
    ok "helper --parse returns valid JSON with schema_version/whitelist_patterns/categories"
  else
    fail_test "helper --parse output missing required keys or wrong shape"
  fi
else
  fail_test "helper --parse skipped (helper not executable)"
fi

# 21. Helper --expand-whitelist returns ≥6 lines (sanity check on seed values)
if [ -x "$HELPER" ]; then
  _COUNT=$(bash "$HELPER" --expand-whitelist 2>/dev/null | grep -c '.' || true)
  if [ "${_COUNT:-0}" -ge 6 ]; then
    ok "helper --expand-whitelist returns $_COUNT files (>=6 expected)"
  else
    fail_test "helper --expand-whitelist returned $_COUNT files (expected >=6)"
  fi
else
  fail_test "helper --expand-whitelist skipped (helper not executable)"
fi

# 22. Helper --resolve readme returns README.md
if [ -x "$HELPER" ]; then
  _README_OUT=$(bash "$HELPER" --resolve readme 2>/dev/null || echo "")
  if echo "$_README_OUT" | grep -qx 'README.md'; then
    ok "helper --resolve readme returns README.md"
  else
    fail_test "helper --resolve readme did not return README.md (got: $_README_OUT)"
  fi
else
  fail_test "helper --resolve skipped (helper not executable)"
fi

# 23. Helper --resolve nonexistent-category exits 1 with [doc-sync-no-config]
if [ -x "$HELPER" ]; then
  _BAD_OUT=$(bash "$HELPER" --resolve nonexistent-category-zzz 2>&1 || true)
  _BAD_RC=$(bash "$HELPER" --resolve nonexistent-category-zzz >/dev/null 2>&1; echo $?)
  if [ "$_BAD_RC" = "1" ] && echo "$_BAD_OUT" | grep -qF '[doc-sync-no-config]'; then
    ok "helper --resolve nonexistent-category exits 1 with [doc-sync-no-config]"
  else
    fail_test "helper --resolve nonexistent-category did not halt as expected (rc=$_BAD_RC out=$_BAD_OUT)"
  fi
else
  fail_test "helper --resolve nonexistent-category skipped (helper not executable)"
fi

# 24. SKILL.md mentions cj-document-release.json (post-rewrite check)
if grep -qF 'cj-document-release.json' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md references cj-document-release.json (F000037 rewrite)"
else
  fail_test "SKILL.md does not reference cj-document-release.json (F000037 rewrite missing)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-document-release"
  exit 0
else
  echo "FAIL: cj-document-release ($ERRORS error(s))"
  exit 1
fi
