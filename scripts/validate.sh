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
  # Skip templates-only entries (empty files array, no SKILL.md expected)
  files_count=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .files | length' "$CATALOG")
  if [ "$files_count" -eq 0 ]; then
    pass "$name is a templates-only entry (no SKILL.md expected)"
    continue
  fi
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

# Error check 7: VERSION file exists and contains valid semver
echo ""
echo "Checking VERSION file..."
COLLECTION_VER=""
if [ -f "$VERSION_FILE" ]; then
  COLLECTION_VER=$(read_version 2>/dev/null)
  if [ -n "$COLLECTION_VER" ] && validate_version_string "$COLLECTION_VER" 2>/dev/null; then
    pass "VERSION file contains valid semver: $COLLECTION_VER"
  else
    fail "VERSION file exists but contains invalid semver: '$(cat "$VERSION_FILE" 2>/dev/null)'"
  fi
else
  fail "VERSION file not found at $VERSION_FILE"
fi

# Error check 8: VERSION >= latest collection v-tag (no regression)
echo ""
echo "Checking VERSION against git tags..."
LATEST_VTAG=$(git tag -l 'v[0-9]*' --sort=-v:refname 2>/dev/null | head -1)
if [ -n "$LATEST_VTAG" ] && [ -n "$COLLECTION_VER" ]; then
  TAG_VER="${LATEST_VTAG#v}"
  if ! validate_version_string "$TAG_VER" 2>/dev/null; then
    warn "Latest v-tag '$LATEST_VTAG' is not valid semver (skipping regression check)"
  elif version_gte "$COLLECTION_VER" "$TAG_VER"; then
    pass "VERSION $COLLECTION_VER >= latest tag $LATEST_VTAG"
  else
    fail "VERSION $COLLECTION_VER is behind latest tag $LATEST_VTAG (version regression)"
  fi
else
  pass "No collection v-tags found yet (skipping regression check)"
fi

# Error check 9: All skill versions in catalog are valid semver
echo ""
echo "Checking catalog skill versions..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_ver=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .version' "$CATALOG")
  if validate_version_string "$skill_ver" 2>/dev/null; then
    pass "$name version $skill_ver is valid semver"
  else
    fail "$name has invalid version in catalog: '$skill_ver'"
  fi
done

# Warning check: Orphan doc directories
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

# Error check 10: work-copilot bundle mirrors company-workflow templates
echo ""
echo "Checking work-copilot/templates sync with templates/company-workflow..."
if [ -d "work-copilot/templates" ]; then
  for src in templates/company-workflow/*.md; do
    [ -f "$src" ] || continue
    base=$(basename "$src")
    dst="work-copilot/templates/$base"
    if [ ! -f "$dst" ]; then
      fail "work-copilot/templates/$base missing (must mirror templates/company-workflow/)"
    elif ! cmp -s "$src" "$dst"; then
      fail "work-copilot/templates/$base differs from templates/company-workflow/$base"
    else
      pass "work-copilot/templates/$base in sync"
    fi
  done
  for dst in work-copilot/templates/*.md; do
    [ -f "$dst" ] || continue
    base=$(basename "$dst")
    if [ ! -f "templates/company-workflow/$base" ]; then
      warn "work-copilot/templates/$base has no counterpart in templates/company-workflow/"
    fi
  done
else
  pass "no work-copilot/templates/ directory (sync check skipped)"
fi

# Error check 11: Manifest reconciliation — work-items + fixtures vs manifests
# Catches the drift case where the manifest declares a required artifact but
# real work-item directories or "valid-*" fixtures don't have it. The skills'
# /personal-workflow check and /company-workflow validate commands are
# LLM-driven; bash CI cannot invoke them end-to-end, so this is the only
# gate that catches manifest-vs-filesystem drift on every CI run.
echo ""
echo "Checking manifest reconciliation (work-items + fixtures)..."

PERSONAL_MANIFEST="$REPO_ROOT/skills/personal-workflow/personal-artifact-manifests.json"
COMPANY_MANIFEST="$REPO_ROOT/skills/company-workflow/company-artifact-manifests.json"

# Strip ID prefix (^[A-Z][0-9]+_) — same rule used by the LLM-driven validator.
strip_id_prefix() {
  local name="$1"
  if [[ "$name" =~ ^[A-Z][0-9]+_(.*)$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf '%s' "$name"
  fi
}

# Validate one work-item directory against a manifest.
# Args: <dir> <manifest-path> <label>
check_work_item_dir() {
  local dir="$1"
  local manifest="$2"
  local label="$3"

  # Find a TRACKER (with or without ID prefix); alphabetical first if multiple.
  local tracker
  tracker=$(find "$dir" -maxdepth 1 -type f \( -name '*_TRACKER.md' -o -name 'TRACKER.md' \) 2>/dev/null | LC_ALL=C sort | head -1 || true)
  [ -n "$tracker" ] || return 0

  # Extract `type:` from frontmatter (between the first --- pair). Tolerates
  # quoted/unquoted, leading whitespace, trailing whitespace.
  local type
  type=$(awk '
    /^---$/ { f++; next }
    f == 1 && /^type:/ {
      sub(/^type:[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$tracker")

  # Normalize: company-workflow accepts userstory as alias for user-story.
  [ "$type" = "userstory" ] && type="user-story"

  # Skip if type isn't declared in this manifest (silent — same as the validator).
  jq -e --arg t "$type" '.types[$t]' "$manifest" >/dev/null 2>&1 || return 0

  # Build a set of canonical filenames present in the dir.
  local -a present=()
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    present+=("$(strip_id_prefix "$(basename "$f")")")
  done < <(find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null)

  # For each required filename, check presence.
  local req found p
  while IFS= read -r req; do
    [ -n "$req" ] || continue
    found=0
    if [ "${#present[@]}" -gt 0 ]; then
      for p in "${present[@]}"; do
        if [ "$p" = "$req" ]; then
          found=1
          break
        fi
      done
    fi
    if [ "$found" = "1" ]; then
      pass "$label ${dir#"$REPO_ROOT"/} has $req (type=$type)"
    else
      fail "$label ${dir#"$REPO_ROOT"/} missing $req (required for type=$type per $(basename "$manifest"))"
    fi
  done < <(jq -r --arg t "$type" '.types[$t].required[].filename' "$manifest")
}

# Walk every dir under work-items/ that has a TRACKER. All work-items in this
# repo are personal-workflow (templates were scaffolded from personal-workflow).
echo ""
echo "  Reconciling work-items/ against personal-workflow manifest..."
while IFS= read -r tracker; do
  d=$(dirname "$tracker")
  check_work_item_dir "$d" "$PERSONAL_MANIFEST" "work-item"
done < <(find "$REPO_ROOT/work-items" -type f \( -name '*_TRACKER.md' -o -name 'TRACKER.md' \) 2>/dev/null | LC_ALL=C sort)

# Walk personal-workflow fixtures.
echo ""
echo "  Reconciling personal-workflow fixtures..."
while IFS= read -r d; do
  check_work_item_dir "$d" "$PERSONAL_MANIFEST" "personal-fixture"
done < <(find "$REPO_ROOT/skills/personal-workflow/fixtures" -maxdepth 1 -type d -name 'valid-*' 2>/dev/null | LC_ALL=C sort)

# Walk company-workflow fixtures.
echo ""
echo "  Reconciling company-workflow fixtures..."
while IFS= read -r d; do
  check_work_item_dir "$d" "$COMPANY_MANIFEST" "company-fixture"
done < <(find "$REPO_ROOT/skills/company-workflow/fixtures" -maxdepth 1 -type d -name 'valid-*' 2>/dev/null | LC_ALL=C sort)

# Warning check 3: Orphan template files (walks subdirectories)
echo ""
echo "Checking for orphan template files..."
find "$TEMPLATES_DIR" -name "*.md" -type f 2>/dev/null | while read -r tmpl_file; do
  # Get path relative to TEMPLATES_DIR (e.g., "personal-workflow/tracker-feature.md" or "doc-SKILL-DESIGN.md")
  tmpl_rel="${tmpl_file#"$TEMPLATES_DIR"/}"
  if jq -e --arg tmpl "$tmpl_rel" '[.[].templates[]] | index($tmpl)' "$CATALOG" >/dev/null 2>&1; then
    pass "templates/$tmpl_rel is referenced by a catalog entry"
  else
    warn "templates/$tmpl_rel is not referenced by any catalog entry"
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
