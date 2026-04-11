#!/usr/bin/env bash
# Validate skills-catalog.json against the filesystem.
# Exit 0 = all error checks pass. Exit 1 = one or more failures.

. "$(dirname "$0")/lib.sh"
init

ERRORS=0
WARNINGS=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "  WARNING: $1"; WARNINGS=$((WARNINGS + 1)); }

echo "=== Validating skills-catalog.json ==="

# Error check 1: Every catalog entry has a SKILL.md on disk
echo ""
echo "Checking catalog entries have SKILL.md files..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  if [ -f "$SKILLS_DIR/$name/SKILL.md" ]; then
    pass "$name has SKILL.md"
  else
    fail "$name is in catalog but skills/$name/SKILL.md does not exist"
  fi
done

# Error check 2: Every SKILL.md has required frontmatter
echo ""
echo "Checking SKILL.md frontmatter..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  [ -f "$skill_file" ] || continue
  if sed -n '/^---$/,/^---$/p' "$skill_file" | grep -q 'name:' &&
     sed -n '/^---$/,/^---$/p' "$skill_file" | grep -q 'description:'; then
    pass "$name has name and description frontmatter"
  else
    fail "$name SKILL.md is missing required frontmatter (name, description)"
  fi
done

# Error check 3: Every skill's templates list has those files in templates/
echo ""
echo "Checking template references..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  templates=$(jq -r --arg name "$name" '.[] | select(.name == $name) | .templates[]' "$CATALOG" 2>/dev/null)
  for tmpl in $templates; do
    if [ -f "$TEMPLATES_DIR/$tmpl" ]; then
      pass "$name template $tmpl exists"
    else
      fail "$name references template $tmpl but templates/$tmpl does not exist"
    fi
  done
done

# Error check 4: No orphan skill directories
echo ""
echo "Checking for orphan skill directories..."
for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  dir_name=$(basename "$dir")
  if jq -e --arg name "$dir_name" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
    pass "$dir_name has catalog entry"
  else
    fail "skills/$dir_name exists but has no catalog entry (orphan)"
  fi
done

# Error check 5: Doc triplets have all three files and type frontmatter
echo ""
echo "Checking doc triplets..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  doc_dir="$DOCS_DIR/$name"
  [ -d "$doc_dir" ] || continue
  for doc in PRD.md ARCHITECTURE.md TEST-SPEC.md; do
    if [ -f "$doc_dir/$doc" ]; then
      if sed -n '/^---$/,/^---$/p' "$doc_dir/$doc" | grep -q 'type:'; then
        pass "$name doc $doc has type frontmatter"
      else
        fail "$name doc $doc is missing type frontmatter"
      fi
    else
      fail "$name is missing docs/$name/$doc"
    fi
  done
done

# Error check 6: All depends.skills entries exist in catalog
echo ""
echo "Checking skill dependencies..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  deps=$(jq -r --arg name "$name" '.[] | select(.name == $name) | .depends.skills[]' "$CATALOG" 2>/dev/null)
  for dep in $deps; do
    if jq -e --arg dep "$dep" '.[] | select(.name == $dep)' "$CATALOG" >/dev/null 2>&1; then
      pass "$name dependency '$dep' exists in catalog"
    else
      fail "$name depends on '$dep' which is not in the catalog"
    fi
  done
done

# Warning check 1: Template sync drift (align-feature-contract only)
echo ""
echo "Checking template sync (align-feature-contract)..."
for pair in "PRD-TEMPLATE.md:doc-PRD.md" "ARCHITECTURE-TEMPLATE.md:doc-ARCHITECTURE.md" "TEST-SPEC-TEMPLATE.md:doc-TEST-SPEC.md"; do
  skill_tmpl="${pair%%:*}"
  canon_tmpl="${pair##*:}"
  skill_file="$SKILLS_DIR/align-feature-contract/$skill_tmpl"
  canon_file="$TEMPLATES_DIR/$canon_tmpl"
  if [ -f "$skill_file" ] && [ -f "$canon_file" ]; then
    skill_hash=$(shasum -a 256 "$skill_file" | awk '{print $1}')
    canon_hash=$(shasum -a 256 "$canon_file" | awk '{print $1}')
    if [ "$skill_hash" = "$canon_hash" ]; then
      pass "align-feature-contract/$skill_tmpl matches templates/$canon_tmpl"
    else
      warn "align-feature-contract/$skill_tmpl differs from templates/$canon_tmpl (template drift)"
    fi
  fi
done

# Warning check 2: Orphan doc directories
echo ""
echo "Checking for orphan doc directories..."
for dir in "$DOCS_DIR"/*/; do
  [ -d "$dir" ] || continue
  dir_name=$(basename "$dir")
  if jq -e --arg name "$dir_name" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
    pass "docs/$dir_name has matching catalog entry"
  else
    warn "docs/$dir_name has no matching skill in catalog (orphan doc directory)"
  fi
done

# Warning check 3: Orphan template files
echo ""
echo "Checking for orphan template files..."
for tmpl_file in "$TEMPLATES_DIR"/*.md; do
  [ -f "$tmpl_file" ] || continue
  tmpl_name=$(basename "$tmpl_file")
  if jq -e --arg tmpl "$tmpl_name" '[.[].templates[]] | index($tmpl)' "$CATALOG" >/dev/null 2>&1; then
    pass "templates/$tmpl_name is referenced by a catalog entry"
  else
    warn "templates/$tmpl_name is not referenced by any catalog entry"
  fi
done

# Summary
echo ""
echo "=== Validation Summary ==="
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
