#!/usr/bin/env bash
# tests/cj-document-release.test.sh
#
# Regression test for the CJ_document-release skill (F000050 doc-spec.md rewrite).
# Pattern: file content greps + frontmatter parsing.
#
# Asserts:
#   1. SKILL.md exists
#   2. USAGE.md exists
#   3. SKILL.md frontmatter has name=CJ_document-release
#   4. SKILL.md mentions --docs flag
#   5. SKILL.md frontmatter has version: 0.1.0
#   6. allowed-tools includes Bash, Read, Glob, Grep, Skill
#   7. USAGE.md has all 5 required H2 sections
#   8. skills-catalog.json: CJ_document-release status=experimental + portability=local-only
#   9. docs/workflow.md `## Utilities & phase-step skills` has the CJ_document-release entry
#   9b. that entry names the Step 5.5 inline role
#  10. [doc-sync-red] halt marker present
#  11. [doc-sync-non-doc-write] halt marker present
#  12. base-branch refusal prose present
#  13. clean-tree refusal prose present
#  14. --docs case-insensitive parsing prose present
#  15. --docs README example present
#  16. --docs all token present
#  17. SKILL.md references doc-spec.md (the new contract)
#  18. SKILL.md documents self-bootstrap of a missing doc-spec.md
#  19. SKILL.md documents stub-scaffold of missing declared docs
#  20. SKILL.md documents the derived whitelist (--expand-whitelist)
#  21. SKILL.md has NO reference to the retired cj-document-release.json
#  22. SKILL.md has NO bare `bash scripts/doc-spec.sh` invocation (portability)
#  23. SKILL.md uses resolved `bash "$_DS_HELPER"` >=4x + resolves via _cj-shared,
#      no manifest .source / .skills-templates.json reach-back

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

SKILL_MD="$REPO_ROOT/skills/CJ_document-release/SKILL.md"
USAGE_MD="$REPO_ROOT/skills/CJ_document-release/USAGE.md"
CATALOG="$REPO_ROOT/skills-catalog.json"
WORKFLOWS_DOC="$REPO_ROOT/docs/workflow.md"

echo "=== cj-document-release: skill structure + body assertions (doc-spec.md) ==="

# 1. SKILL.md exists
[ -f "$SKILL_MD" ] && ok "skills/CJ_document-release/SKILL.md exists" || fail_test "SKILL.md is missing"

# 2. USAGE.md exists
[ -f "$USAGE_MD" ] && ok "skills/CJ_document-release/USAGE.md exists" || fail_test "USAGE.md is missing"

# 3. name
grep -qE '^name: CJ_document-release$' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md frontmatter: name = CJ_document-release" \
  || fail_test "SKILL.md frontmatter: name field missing or wrong"

# 4. --docs flag
grep -q '\-\-docs' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md mentions --docs flag" \
  || fail_test "SKILL.md does not mention --docs flag"

# 5. version
grep -qE '^version: 0\.1\.0$' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md frontmatter: version = 0.1.0" \
  || fail_test "SKILL.md frontmatter: version != 0.1.0"

# 6. allowed-tools
FM=$(sed -n '/^---$/,/^---$/p' "$SKILL_MD" 2>/dev/null)
MISSING_TOOLS=""
for tool in Bash Read Glob Grep Skill; do
  echo "$FM" | grep -qE "^  - $tool$" || MISSING_TOOLS="$MISSING_TOOLS $tool"
done
[ -z "$MISSING_TOOLS" ] \
  && ok "SKILL.md frontmatter: allowed-tools includes Bash, Read, Glob, Grep, Skill" \
  || fail_test "SKILL.md frontmatter: allowed-tools missing:$MISSING_TOOLS"

# 7. USAGE.md 5 H2 sections
USAGE_MISSING=""
for sec in "## When to use" "## When NOT to use" "## Mental model" "## Common pitfalls" "## Related skills"; do
  grep -qFx "$sec" "$USAGE_MD" 2>/dev/null || USAGE_MISSING="$USAGE_MISSING $sec;"
done
[ -z "$USAGE_MISSING" ] \
  && ok "USAGE.md has all 5 required H2 sections" \
  || fail_test "USAGE.md missing required section(s): $USAGE_MISSING"

# 8. Catalog entry status + portability
CATALOG_STATUS=$(jq -r '.[] | select(.name=="CJ_document-release") | .status' "$CATALOG" 2>/dev/null)
CATALOG_PORTABILITY=$(jq -r '.[] | select(.name=="CJ_document-release") | .portability' "$CATALOG" 2>/dev/null)
if [ "$CATALOG_STATUS" = "experimental" ] && [ "$CATALOG_PORTABILITY" = "local-only" ]; then
  ok "skills-catalog.json: CJ_document-release entry has status=experimental + portability=local-only"
else
  fail_test "skills-catalog.json: CJ_document-release entry wrong (status=$CATALOG_STATUS portability=$CATALOG_PORTABILITY)"
fi

# 9. docs/workflow.md entry
grep -qE '^#### CJ_document-release$' "$WORKFLOWS_DOC" 2>/dev/null \
  && ok "docs/workflow.md '## Utilities & phase-step skills' has the CJ_document-release entry" \
  || fail_test "docs/workflow.md missing the CJ_document-release entry"

# 9b. entry names Step 5.5
if awk '/^#### CJ_document-release$/{f=1;next} /^#### /{f=0} f' "$WORKFLOWS_DOC" 2>/dev/null | grep -qE 'Step 5\.5'; then
  ok "docs/workflow.md CJ_document-release entry names the Step 5.5 inline role"
else
  fail_test "docs/workflow.md CJ_document-release entry missing the Step 5.5 role description"
fi

# 10. [doc-sync-red]
grep -qF '[doc-sync-red]' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md contains [doc-sync-red] halt marker" \
  || fail_test "SKILL.md missing [doc-sync-red] halt marker"

# 11. [doc-sync-non-doc-write]
grep -qF '[doc-sync-non-doc-write]' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md contains [doc-sync-non-doc-write] halt marker" \
  || fail_test "SKILL.md missing [doc-sync-non-doc-write] halt marker"

# 12. base-branch refusal prose
grep -qE 'refuses on the base branch' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents base-branch refusal" \
  || fail_test "SKILL.md does not document base-branch refusal prose"

# 13. clean-tree refusal prose
grep -qE 'Working tree has uncommitted non-doc changes' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents clean-tree refusal" \
  || fail_test "SKILL.md does not document clean-tree refusal prose"

# 14. --docs case-insensitive parsing
grep -qE 'case-insensitive' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents --docs case-insensitive parsing" \
  || fail_test "SKILL.md does not document --docs parsing"

# 15. --docs README example
if grep -qE '\-\-docs README,CHANGELOG' "$SKILL_MD" 2>/dev/null \
   || grep -qE '\-\-docs README$' "$SKILL_MD" 2>/dev/null \
   || grep -qE '\-\-docs README ' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md has --docs README example"
else
  fail_test "SKILL.md missing --docs README example"
fi

# 16. --docs all token
grep -qE '\-\-docs all' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents --docs all explicit no-filter token" \
  || fail_test "SKILL.md missing --docs all explicit token documentation"

# --- F000050 doc-spec.md rewrite assertions ---

# 17. references doc-spec.md
grep -qF 'doc-spec.md' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md references doc-spec.md (the new contract)" \
  || fail_test "SKILL.md does not reference doc-spec.md"

# 18. self-bootstrap
grep -qiE 'self-bootstrap' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents self-bootstrap of a missing doc-spec.md" \
  || fail_test "SKILL.md does not document self-bootstrap"

# 19. stub-scaffold
grep -qiE 'stub-scaffold' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents stub-scaffold of missing declared docs" \
  || fail_test "SKILL.md does not document stub-scaffold"

# 20. derived whitelist
grep -qF -- '--expand-whitelist' "$SKILL_MD" 2>/dev/null \
  && ok "SKILL.md documents the derived whitelist (--expand-whitelist)" \
  || fail_test "SKILL.md does not document the derived whitelist"

# 21. NO retired cj-document-release.json reference
_JSON_REFS=$(grep -cF 'cj-document-release.json' "$SKILL_MD" 2>/dev/null || true)
[ "${_JSON_REFS:-0}" -eq 0 ] \
  && ok "SKILL.md has NO reference to the retired cj-document-release.json" \
  || fail_test "SKILL.md still references cj-document-release.json ($_JSON_REFS time(s))"

# 22. NO bare `bash scripts/doc-spec.sh` invocation (cross-repo portability)
_BARE=$(grep -cF 'bash scripts/doc-spec.sh' "$SKILL_MD" 2>/dev/null || true)
[ "${_BARE:-0}" -eq 0 ] \
  && ok "SKILL.md has NO bare 'bash scripts/doc-spec.sh' invocation" \
  || fail_test "SKILL.md still has $_BARE bare 'bash scripts/doc-spec.sh' invocation(s) — non-portable"

# 23. resolved `bash "$_DS_HELPER"` >=4x + _cj-shared, no .skills-templates.json
_RESOLVED=$(grep -cF 'bash "$_DS_HELPER"' "$SKILL_MD" 2>/dev/null || true)
if [ "${_RESOLVED:-0}" -ge 4 ] \
   && grep -qF '_cj-shared' "$SKILL_MD" 2>/dev/null \
   && ! grep -qF '.skills-templates.json' "$SKILL_MD" 2>/dev/null \
   && grep -qF '_DS_HELPER' "$SKILL_MD" 2>/dev/null; then
  ok "SKILL.md uses 'bash \"\$_DS_HELPER\"' >=4x + resolves via _cj-shared, no .source reach-back (got $_RESOLVED)"
else
  fail_test "SKILL.md resolved-helper wiring incomplete (bash \"\$_DS_HELPER\" count=$_RESOLVED)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-document-release"
  exit 0
else
  echo "FAIL: cj-document-release ($ERRORS error(s))"
  exit 1
fi
