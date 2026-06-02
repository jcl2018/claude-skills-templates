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

# Catalog-driven path helpers (F000006). Skills can live anywhere the catalog
# points (skills/, deprecated/, etc.) — these helpers honor files[] and an
# optional templates_source override instead of hardcoding skills/{name}/ or
# templates/{name}/. Mirror the helpers in scripts/skills-deploy.

# Repo-relative path of a skill's SKILL.md (from catalog files[0]).
skill_md_path() {
  jq -r --arg n "$1" '.[] | select(.name == $n) | (.files // []) | .[0] // ""' "$CATALOG" 2>/dev/null || true
}
# Absolute path of a skill's SKILL.md.
skill_md_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    echo "$REPO_ROOT/$f0"
  fi
}
# Absolute source directory (dirname of files[0]).
skill_source_dir_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    echo "$REPO_ROOT/$(dirname "$f0")"
  fi
}
# Absolute on-disk path for a (skill, templates[] entry) pair, honoring the
# optional templates_source override. Default: $TEMPLATES_DIR/$tpl. Override:
# $REPO_ROOT/$templates_source/$(basename $tpl) — the {skill}/ prefix in the
# entry is the DST organizing subfolder (preserved by skills-deploy at install
# time), not part of the SRC path under the override.
template_src_path() {
  local name="$1" tpl="$2"
  local s
  s=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .templates_source // "templates"' "$CATALOG" 2>/dev/null || echo "templates")
  s="${s:-templates}"
  if [ "$s" = "templates" ]; then
    echo "$REPO_ROOT/templates/$tpl"
  else
    echo "$REPO_ROOT/$s/$(basename "$tpl")"
  fi
}

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
  skill_md=$(skill_md_path "$name")
  if [ -n "$skill_md" ] && [ -f "$REPO_ROOT/$skill_md" ]; then
    pass "$name has SKILL.md at $skill_md"
  else
    fail "$name is in catalog but its SKILL.md ($skill_md) does not exist on disk"
  fi
done

# Error check 2: Every SKILL.md has required frontmatter
echo ""
echo "Checking SKILL.md frontmatter..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file=$(skill_md_abs "$name")
  if [ -z "$skill_file" ] || [ ! -f "$skill_file" ]; then
    continue
  fi
  if sed -n '/^---$/,/^---$/p' "$skill_file" | grep -q 'name:' &&
     sed -n '/^---$/,/^---$/p' "$skill_file" | grep -q 'description:'; then
    pass "$name has name and description frontmatter"
  else
    fail "$name SKILL.md is missing required frontmatter (name, description)"
  fi
done

# Error check 3: Every skill's templates list has those files on disk
# (resolved via templates_source override when present, default templates/).
echo ""
echo "Checking template references..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  templates=$(jq -r --arg name "$name" '.[] | select(.name == $name) | .templates[]' "$CATALOG" 2>/dev/null)
  for tmpl in $templates; do
    tmpl_path=$(template_src_path "$name" "$tmpl")
    if [ -f "$tmpl_path" ]; then
      pass "$name template $tmpl exists at ${tmpl_path#"$REPO_ROOT"/}"
    else
      fail "$name references template $tmpl but ${tmpl_path#"$REPO_ROOT"/} does not exist"
    fi
  done
done

# Error check 4: No orphan skill directories. Walk both skills/ (active) and
# deprecated/ (lifecycle-relocated). For every directory containing a SKILL.md,
# require a catalog entry whose files[0] resolves to that path. Avoids `declare
# -A` (bash 4+) for portability with macOS bash 3.2.
echo ""
echo "Checking for orphan skill directories..."
_claimed_skill_dirs=$(
  for n in $(jq -r '.[].name' "$CATALOG"); do
    d=$(skill_source_dir_abs "$n")
    if [ -n "$d" ]; then
      printf '%s\t%s\n' "$d" "$n"
    fi
  done
)
for parent in "$SKILLS_DIR" "$REPO_ROOT/deprecated"; do
  [ -d "$parent" ] || continue
  for dir in "$parent"/*/; do
    [ -d "$dir" ] || continue
    dir_abs="${dir%/}"
    rel="${dir_abs#"$REPO_ROOT"/}"
    # Under deprecated/, only check dirs that look like skill sources (contain SKILL.md
    # or are claimed by a catalog entry). deprecated/ is allowed to host non-skill
    # subtrees like work-items/. Under skills/, every dir must be catalog-claimed
    # — that's how the zzz-test-orphan regression test flags accidental dirs.
    if [ "$parent" = "$REPO_ROOT/deprecated" ] && [ ! -f "$dir_abs/SKILL.md" ]; then
      continue
    fi
    matched=$(printf '%s\n' "$_claimed_skill_dirs" | awk -F'\t' -v d="$dir_abs" '$1==d {print $2; exit}')
    if [ -n "$matched" ]; then
      pass "$rel is claimed by catalog entry '$matched'"
    else
      fail "$rel exists but no catalog entry claims it (orphan)"
    fi
  done
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

# Error check 9b: Catalog status field is one of {active, experimental}
# Closed enum so typos (e.g. "actiev") fail the build instead of silently
# behaving like a missing status. Status is required on every entry.
echo ""
echo "Checking catalog status values..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  status_val=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .status // ""' "$CATALOG")
  case "$status_val" in
    active|experimental)
      pass "$name has valid status: $status_val"
      ;;
    "")
      fail "$name has no 'status' field (must be one of: active, experimental)"
      ;;
    *)
      fail "$name has invalid status: '$status_val' (must be one of: active, experimental)"
      ;;
  esac
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

# Error check 10: work-copilot bundle existence check (S000052: F000023)
#
# History: Error check 10 was previously a byte-mirror enforcement between
# deprecated/CJ_company-workflow/ (upstream truth) and work-copilot/ (consumer).
# F000023/S000052 inverted that relationship: work-copilot/ is now the canonical
# source. The MIRROR_SPECS + shape handlers + orphan reporter (~190 lines) are
# deleted. What remains is a single existence-check sweep over every file the
# bundle is required to ship.
#
# To extend: append one line per new bundle file. No shape distinction needed —
# the bundle is byte-canonical on disk now; copilot-deploy.py reads it directly.
EXPECTED_BUNDLE_FILES=(
  # WORKFLOW + manifest (top-level)
  "work-copilot/WORKFLOW.md"
  "work-copilot/copilot-artifact-manifests.json"
  # F000015 prompts + domain templates (bundle-only, no upstream counterpart)
  "work-copilot/prompts/validate.prompt.md"
  "work-copilot/prompts/qa.prompt.md"
  "work-copilot/prompts/implement.prompt.md"
  "work-copilot/prompts/scaffold.prompt.md"
  "work-copilot/prompts/investigate.prompt.md"
  "work-copilot/prompts/ship.prompt.md"
  "work-copilot/prompts/pipeline.prompt.md"
  "work-copilot/domain/domain-knowledge.template.md"
  "work-copilot/domain/coding-conventions.template.md"
  "work-copilot/domain/architecture-overview.template.md"
  # Templates (17 — were templates/ via MIRROR_SPECS flat shape)
  "work-copilot/templates/doc-ARCHITECTURE.md"
  "work-copilot/templates/doc-DESIGN.md"
  "work-copilot/templates/doc-feature-summary.md"
  "work-copilot/templates/doc-milestones.md"
  "work-copilot/templates/doc-pr-description-defect.md"
  "work-copilot/templates/doc-pr-description-task.md"
  "work-copilot/templates/doc-PRD.md"
  "work-copilot/templates/doc-RCA.md"
  "work-copilot/templates/doc-review-notes.md"
  "work-copilot/templates/doc-scrum.md"
  "work-copilot/templates/doc-test-plan.md"
  "work-copilot/templates/doc-TEST-SPEC.md"
  "work-copilot/templates/tracker-defect.md"
  "work-copilot/templates/tracker-feature.md"
  "work-copilot/templates/tracker-review.md"
  "work-copilot/templates/tracker-task.md"
  "work-copilot/templates/tracker-user-story.md"
  # Reference guides (7 — were reference/ via MIRROR_SPECS flat shape)
  "work-copilot/reference/guide-architecture.md"
  "work-copilot/reference/guide-general.md"
  "work-copilot/reference/guide-prd.md"
  "work-copilot/reference/guide-rca.md"
  "work-copilot/reference/guide-review-notes.md"
  "work-copilot/reference/guide-task.md"
  "work-copilot/reference/guide-test-spec.md"
  # Philosophy (3 — were philosophy/ via MIRROR_SPECS flat shape)
  "work-copilot/philosophy/rationale-ARCHITECTURE.md"
  "work-copilot/philosophy/rationale-PRD.md"
  "work-copilot/philosophy/rationale-TEST-SPEC.md"
  # Examples (14 — were examples/ via MIRROR_SPECS flat shape)
  "work-copilot/examples/example-doc-ARCHITECTURE.md"
  "work-copilot/examples/example-doc-feature-summary.md"
  "work-copilot/examples/example-doc-milestones.md"
  "work-copilot/examples/example-doc-PRD.md"
  "work-copilot/examples/example-doc-RCA.md"
  "work-copilot/examples/example-doc-review-notes.md"
  "work-copilot/examples/example-doc-scrum.md"
  "work-copilot/examples/example-doc-test-plan.md"
  "work-copilot/examples/example-doc-TEST-SPEC.md"
  "work-copilot/examples/example-tracker-defect.md"
  "work-copilot/examples/example-tracker-feature.md"
  "work-copilot/examples/example-tracker-review.md"
  "work-copilot/examples/example-tracker-task.md"
  "work-copilot/examples/example-tracker-user-story.md"
  # Fixtures (8 — were fixtures/ via MIRROR_SPECS recursive shape)
  "work-copilot/fixtures/invalid-bad-frontmatter.md"
  "work-copilot/fixtures/invalid-missing-artifact-dir/TRACKER.md"
  "work-copilot/fixtures/invalid-missing-lifecycle.md"
  "work-copilot/fixtures/invalid-wrong-order.md"
  "work-copilot/fixtures/valid-feature-dir/DESIGN.md"
  "work-copilot/fixtures/valid-feature-dir/feature-summary.md"
  "work-copilot/fixtures/valid-feature-dir/milestones.md"
  "work-copilot/fixtures/valid-feature-dir/TRACKER.md"
)
echo ""
echo "Checking work-copilot bundle existence (${#EXPECTED_BUNDLE_FILES[@]} expected files)..."
for _path in "${EXPECTED_BUNDLE_FILES[@]}"; do
  if [ -f "$REPO_ROOT/$_path" ]; then
    pass "$_path is present (work-copilot/-only bundle file)"
  else
    fail "$_path is required but not present (work-copilot/-only bundle file; restore via copilot-deploy or re-run the owning child story)"
  fi
done

# Error check 11: Manifest reconciliation — work-items + fixtures vs manifests
# Catches the drift case where the manifest declares a required artifact but
# real work-item directories or "valid-*" fixtures don't have it. The skills'
# /CJ_personal-workflow check and /CJ_company-workflow validate commands are
# LLM-driven; bash CI cannot invoke them end-to-end, so this is the only
# gate that catches manifest-vs-filesystem drift on every CI run.
echo ""
echo "Checking manifest reconciliation (work-items + fixtures)..."

PERSONAL_MANIFEST="$REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json"
COMPANY_MANIFEST="$REPO_ROOT/deprecated/CJ_company-workflow/company-artifact-manifests.json"

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

  # Normalize: CJ_company-workflow accepts userstory as alias for user-story.
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
# repo are CJ_personal-workflow (templates were scaffolded from CJ_personal-workflow).
echo ""
echo "  Reconciling work-items/ against CJ_personal-workflow manifest..."
while IFS= read -r tracker; do
  d=$(dirname "$tracker")
  check_work_item_dir "$d" "$PERSONAL_MANIFEST" "work-item"
done < <(find "$REPO_ROOT/work-items" -type f \( -name '*_TRACKER.md' -o -name 'TRACKER.md' \) 2>/dev/null | LC_ALL=C sort)

# Walk CJ_personal-workflow fixtures.
echo ""
echo "  Reconciling CJ_personal-workflow fixtures..."
while IFS= read -r d; do
  check_work_item_dir "$d" "$PERSONAL_MANIFEST" "personal-fixture"
done < <(find "$REPO_ROOT/skills/CJ_personal-workflow/fixtures" -maxdepth 1 -type d -name 'valid-*' 2>/dev/null | LC_ALL=C sort)

# Walk CJ_company-workflow fixtures.
echo ""
echo "  Reconciling CJ_company-workflow fixtures..."
while IFS= read -r d; do
  check_work_item_dir "$d" "$COMPANY_MANIFEST" "company-fixture"
done < <(find "$REPO_ROOT/deprecated/CJ_company-workflow/fixtures" -maxdepth 1 -type d -name 'valid-*' 2>/dev/null | LC_ALL=C sort)

# Warning check 3: Orphan template files (walks subdirectories).
# Walks the default templates/ dir AND any override base from a catalog
# entry's templates_source field. The lookup key for a file shape
# (override_base/foo.md) is "{skill}/foo.md" — the catalog key always carries
# the {skill}/ DST organizing prefix even when the SRC is overridden.
echo ""
echo "Checking for orphan template files..."

_check_orphan_template() {
  local file="$1" key="$2"
  if jq -e --arg tmpl "$key" '[.[].templates[]] | index($tmpl)' "$CATALOG" >/dev/null 2>&1; then
    pass "${file#"$REPO_ROOT"/} is referenced by a catalog entry (key=$key)"
  else
    warn "${file#"$REPO_ROOT"/} is not referenced by any catalog entry (key=$key)"
  fi
}

# Default templates/ — key = path relative to templates/ (e.g. CJ_personal-workflow/foo.md).
find "$TEMPLATES_DIR" -name "*.md" -type f 2>/dev/null | while read -r tmpl_file; do
  tmpl_rel="${tmpl_file#"$TEMPLATES_DIR"/}"
  _check_orphan_template "$tmpl_file" "$tmpl_rel"
done

# Each override base — key = "{skill}/{basename}".
while IFS=$'\t' read -r ts_name ts_path; do
  if [ -z "$ts_name" ] || [ -z "$ts_path" ]; then
    continue
  fi
  ts_dir="$REPO_ROOT/$ts_path"
  [ -d "$ts_dir" ] || continue
  find "$ts_dir" -name "*.md" -type f 2>/dev/null | while read -r tmpl_file; do
    base=$(basename "$tmpl_file")
    _check_orphan_template "$tmpl_file" "$ts_name/$base"
  done
done < <(jq -r '.[] | select(.templates_source) | "\(.name)\t\(.templates_source)"' "$CATALOG")

# Check 11: rules/ deploy health (each *.md in rules/ must be deployed to ~/.claude/rules/).
# Skipped when deploy target doesn't exist (e.g. CI fresh checkout, new machines pre-install).
echo ""
echo "=== Check 11: rules/ deploy health ==="
RULES_SRC_DIR="$REPO_ROOT/rules"
RULES_DEPLOY_DIR="${SKILLS_DEPLOY_RULES_TARGET:-$HOME/.claude/rules}"
if [ ! -d "$RULES_SRC_DIR" ]; then
  pass "rules/ directory does not exist (no rules to deploy)"
elif [ ! -d "$RULES_DEPLOY_DIR" ]; then
  warn "rules/ deploy target $RULES_DEPLOY_DIR does not exist — run './scripts/skills-deploy install'"
else
  found_rules=0
  for rule_file in "$RULES_SRC_DIR"/*.md; do
    [ -f "$rule_file" ] || continue
    found_rules=$((found_rules + 1))
    rule_name=$(basename "$rule_file")
    rule_dst="$RULES_DEPLOY_DIR/$rule_name"
    if [ ! -f "$rule_dst" ]; then
      fail "rules/$rule_name not deployed at $rule_dst — run './scripts/skills-deploy install'"
    else
      pass "rules/$rule_name deployed at $rule_dst"
    fi
  done
  [ "$found_rules" -eq 0 ] && pass "rules/ directory is empty (no rules to deploy)"
fi

# Error check 12: pipeline.md Step 6 guard present
# T000029: enforces the workbench-coupling boundary at pipeline.md:528.
# If a future skill-author deletes the guard, CI fails — preventing silent
# regression of T000028 / Approach D's downstream-portability fix.
echo ""
echo "=== Check 12: pipeline.md Step 6 guard present ==="
PIPELINE_MD="skills/CJ_personal-pipeline/pipeline.md"
if [ -f "$PIPELINE_MD" ]; then
  if grep -qF '[ -x ./scripts/validate.sh ]' "$PIPELINE_MD"; then
    echo "  PASS: pipeline.md contains the validate.sh presence guard"
  else
    echo "  FAIL: pipeline.md missing '[ -x ./scripts/validate.sh ]' guard token"
    echo "        This guard is the workbench-coupling boundary (T000028, Approach D)."
    echo "        Deleting it would regress downstream /CJ_goal_todo_fix portability."
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  WARN: pipeline.md not found at $PIPELINE_MD (skipping check)"
fi

# Check 13: USAGE.md present + has required H2 sections (every routable non-deprecated skill)
# F000032/S000065: per-skill USAGE.md is the operator + agent best-practice surface.
# Predicate intentionally diverges from Check 11 / F000030's new-skills check:
# F000030 uses `status == "active"` (gates decision-tree placement, ship-stable only);
# Check 13 uses `status != "deprecated"` (operators route to experimental skills today,
# so USAGE.md must cover them). The 5 deprecated shims + tooling-only `templates` entry
# (files: []) are excluded automatically.
echo ""
echo "=== Check 13: per-skill USAGE.md present + required sections ==="
REQUIRED_H2=("## When to use" "## When NOT to use" "## Mental model" "## Common pitfalls" "## Related skills")
while IFS= read -r SKILL_NAME; do
  USAGE_PATH="skills/$SKILL_NAME/USAGE.md"
  if [ ! -f "$USAGE_PATH" ]; then
    echo "  ERROR: $USAGE_PATH missing"
    ERRORS=$((ERRORS+1))
    continue
  fi
  MISSING=0
  for H2 in "${REQUIRED_H2[@]}"; do
    # Line-anchored heading match — reject substring matches inside code fences.
    if ! grep -qE "^${H2}[[:space:]]*\$" "$USAGE_PATH"; then
      echo "  ERROR: $USAGE_PATH missing section heading: $H2"
      ERRORS=$((ERRORS+1))
      MISSING=$((MISSING+1))
    fi
  done
  [ "$MISSING" -eq 0 ] && echo "  PASS: $USAGE_PATH has all required sections"
done < <(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json)

# Check 14: USAGE.md content freshness (git-log %ct comparison)
# F000033/S000066: USAGE.md must be at least as recent as its sibling SKILL.md,
# measured by committer Unix timestamp from `git log -1 --format=%ct`. Drift
# means SKILL.md changed in a more recent commit than USAGE.md — the audit
# flags USAGE.md as stale. Same predicate as Check 13 (status != "deprecated"
# + non-empty files). When SKILL.md changed cosmetically and USAGE.md is still
# accurate, the operator bumps USAGE.md's `last-updated:` frontmatter field
# (real content change, so %ct advances) — see CLAUDE.md "USAGE.md drift
# detection" for the override command.
echo ""
echo "=== Check 14: USAGE.md content freshness ==="
while IFS= read -r SKILL_NAME; do
  SKILL_PATH="skills/$SKILL_NAME/SKILL.md"
  USAGE_PATH="skills/$SKILL_NAME/USAGE.md"
  if [ ! -f "$SKILL_PATH" ] || [ ! -f "$USAGE_PATH" ]; then
    # Check 13 already errored on missing USAGE.md; SKILL.md missing is a different bug.
    continue
  fi
  SKILL_CT=$(git log -1 --format=%ct -- "$SKILL_PATH" 2>/dev/null)
  USAGE_CT=$(git log -1 --format=%ct -- "$USAGE_PATH" 2>/dev/null)
  # Pre-commit-hook escape: if USAGE.md is staged (in the about-to-land diff),
  # treat it as current. Otherwise the documented override commit gets blocked
  # by the same Check 14 that the override is trying to silence (chicken-and-egg).
  # The staged change IS the operator's confirmation that USAGE.md is up-to-date.
  if git diff --cached --name-only 2>/dev/null | grep -qx "$USAGE_PATH"; then
    USAGE_CT=$(date +%s)
  fi
  if [ -z "$SKILL_CT" ] || [ -z "$USAGE_CT" ]; then
    # Untracked-or-staged-only: git log returns empty. Skip drift check (Check 13 covers presence).
    echo "  SKIP: $USAGE_PATH (file untracked or staged-only; drift check requires committed history)"
    continue
  fi
  if [ "$SKILL_CT" -gt "$USAGE_CT" ]; then
    SKILL_SHA=$(git log -1 --format=%h -- "$SKILL_PATH")
    USAGE_SHA=$(git log -1 --format=%h -- "$USAGE_PATH")
    echo "  ERROR: $USAGE_PATH is stale (SKILL.md last updated at $SKILL_SHA, USAGE.md last updated at $USAGE_SHA)."
    echo "         If USAGE.md is still accurate, bump its last-updated frontmatter field and commit:"
    echo "           sed -i.bak 's/^last-updated:.*/last-updated: \"'\"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\"'\"/' $USAGE_PATH && rm ${USAGE_PATH}.bak"
    echo "           git add $USAGE_PATH && git commit -m \"docs: verify USAGE.md current for $SKILL_NAME\""
    echo "         (ISO-8601 second-resolution timestamp ensures the value changes even if the override runs twice on the same day.)"
    ERRORS=$((ERRORS+1))
  else
    echo "  PASS: $USAGE_PATH is current (SKILL.md $SKILL_CT <= USAGE.md $USAGE_CT)"
  fi
done < <(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json)

# Check 15: doc/ manifest + SKILL-CATALOG.md completeness
# F000034: every doc/*.md must be registered in the CLAUDE.md manifest; the
# SKILL-CATALOG.md entry must list every active routable skill with at least
# one of (a) a fenced ASCII workflow chart, or (b) an explicit tag line
# matching one of `(single-step utility)` / `(validator)` / `(phase-step in
# /CJ_goal_feature chain)`. No silent omission.
echo ""
echo "=== Check 15: doc/ manifest + SKILL-CATALOG.md completeness ==="

# 15a: enumerate manifest entries (parse the YAML block under
# `### Tracked doc/ files manifest` in CLAUDE.md).
# Flag-based, NOT awk's `/start/,/end/` range — same collapse-on-overlap reason
# as Check 15b's section parser (both start and end patterns match `^### `).
MANIFEST_PATHS=$(awk '
  /^### Tracked doc\/ files manifest$/ {flag=1; next}
  /^### / {flag=0}
  flag && /^- path:/ {print $3}
' CLAUDE.md)
DOC_FILES_ON_DISK=$(find doc -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)

# 15a-orphan: doc/ files on disk that aren't in the manifest
for f in $DOC_FILES_ON_DISK; do
  if ! echo "$MANIFEST_PATHS" | grep -qFx "$f"; then
    echo "  ERROR: $f is in doc/ but not registered in CLAUDE.md tracked-doc/ manifest"
    ERRORS=$((ERRORS+1))
  fi
done

# 15a-missing: manifest entries pointing to missing files
for p in $MANIFEST_PATHS; do
  if [ ! -f "$p" ]; then
    echo "  ERROR: $p is in CLAUDE.md manifest but missing from disk"
    ERRORS=$((ERRORS+1))
  fi
done

# 15b: SKILL-CATALOG.md per-skill completeness (only if catalog file exists)
CATALOG_FILE="doc/SKILL-CATALOG.md"
if [ -f "$CATALOG_FILE" ]; then
  # Tag regex: matches the tag anywhere in the line (markdown often wraps it in
  # backticks for inline-code styling: `(validator)`, `(single-step utility)`,
  # etc.). Anchored `^\(` would reject the backticked form. The closed enum on
  # the inner alternation makes anywhere-in-line matching safe against false
  # positives — the four exact phrases would rarely appear in prose.
  TAG_RE='\((single-step utility|validator|phase-step in /CJ_goal_feature chain)\)'
  while IFS= read -r SKILL_NAME; do
    # Section heading is `### <name>` line-anchored
    if ! grep -qE "^### ${SKILL_NAME}$" "$CATALOG_FILE"; then
      echo "  ERROR: $CATALOG_FILE missing section: ### $SKILL_NAME"
      ERRORS=$((ERRORS+1))
      continue
    fi
    # Extract the section body (between this ### and the next ###).
    # Flag-based, NOT awk's `/start/,/end/` range: the range collapses to a single
    # line when start and end patterns overlap (both match `^### `), so the body
    # comes out empty. Flag pattern reads: arm when we see the section heading
    # (and skip the heading line itself via `next`), disarm at the next `^### `,
    # print everything in between.
    SECTION=$(awk -v skill="$SKILL_NAME" '
      $0 == "### " skill {flag=1; next}
      /^### / {flag=0}
      flag {print}
    ' "$CATALOG_FILE")
    # Section must have EITHER a fenced ``` block (ASCII chart) OR a tag line
    HAS_CHART=$(echo "$SECTION" | grep -cE '^```' || true)
    HAS_TAG=$(echo "$SECTION"   | grep -cE "$TAG_RE" || true)
    if [ "$HAS_CHART" -lt 2 ] && [ "$HAS_TAG" -lt 1 ]; then
      echo "  ERROR: $CATALOG_FILE section '$SKILL_NAME' has neither ASCII chart (fenced block) nor a tag line; one is required"
      ERRORS=$((ERRORS+1))
    else
      echo "  PASS: $CATALOG_FILE has section for $SKILL_NAME"
    fi
  done < <(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json)
fi

# Check 16: cj-document-release.json schema enforcement (F000037)
# Skip silently when the file is missing (non-adopting repos). When present,
# enforce schema_version=1, whitelist_patterns non-empty array, categories
# non-empty object with array values per entry, and cross-check via the
# helper's --validate subcommand.
echo ""
echo "=== Check 16: cj-document-release.json schema ==="
CONFIG_JSON="cj-document-release.json"
if [ -f "$CONFIG_JSON" ]; then
  # JSON validity (block other checks if this fails to avoid cascade noise).
  if ! jq empty "$CONFIG_JSON" 2>/dev/null; then
    echo "  ERROR: $CONFIG_JSON is not valid JSON"
    ERRORS=$((ERRORS+1))
  else
    # schema_version must be exactly 1 (v1 reader)
    SV=$(jq -r '.schema_version // empty' "$CONFIG_JSON")
    if [ -z "$SV" ] || [ "$SV" != "1" ]; then
      echo "  ERROR: $CONFIG_JSON schema_version missing or unsupported (expected 1, got '$SV')"
      ERRORS=$((ERRORS+1))
    fi
    # whitelist_patterns must be a non-empty array
    if ! jq -e '.whitelist_patterns | type == "array" and length > 0' "$CONFIG_JSON" >/dev/null 2>&1; then
      echo "  ERROR: $CONFIG_JSON whitelist_patterns must be a non-empty array"
      ERRORS=$((ERRORS+1))
    fi
    # categories must be a non-empty object
    if ! jq -e '.categories | type == "object" and (length > 0)' "$CONFIG_JSON" >/dev/null 2>&1; then
      echo "  ERROR: $CONFIG_JSON categories must be a non-empty object"
      ERRORS=$((ERRORS+1))
    fi
    # Each category value must be a non-empty array of strings
    if ! jq -e '[.categories | to_entries[] | .value | type == "array" and length > 0] | all' "$CONFIG_JSON" >/dev/null 2>&1; then
      echo "  ERROR: $CONFIG_JSON each category value must be a non-empty array of glob patterns"
      ERRORS=$((ERRORS+1))
    fi
    # Final cross-check: helper --validate must exit 0.
    if [ -x "scripts/cj-document-release-config.sh" ]; then
      if ! HELPER_OUT=$(bash scripts/cj-document-release-config.sh --validate 2>&1); then
        echo "  ERROR: cj-document-release-config.sh --validate failed: $HELPER_OUT"
        ERRORS=$((ERRORS+1))
      fi
    fi
    echo "  PASS: $CONFIG_JSON schema_version=$SV"
  fi
else
  echo "  SKIP: $CONFIG_JSON not present (non-adopting repo; check is conditional)"
fi

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
