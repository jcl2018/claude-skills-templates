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

# Error check 9b: Catalog status field is one of {active, experimental, deprecated}
# Closed enum so typos (e.g. "actiev") fail the build instead of silently
# behaving like a missing status. Status is required on every entry. `deprecated`
# is the lifecycle-retired status (the F000031 relocation pattern): the skill
# source is relocated under deprecated/ and the entry stays catalog-claimed (so
# Check 4 is satisfied) while every `!= deprecated` selector — Check 13/14/15b,
# the portability audit, the registered-doc audit — correctly excludes it.
echo ""
echo "Checking catalog status values..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  status_val=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .status // ""' "$CATALOG")
  case "$status_val" in
    active|experimental|deprecated)
      pass "$name has valid status: $status_val"
      ;;
    "")
      fail "$name has no 'status' field (must be one of: active, experimental, deprecated)"
      ;;
    *)
      fail "$name has invalid status: '$status_val' (must be one of: active, experimental, deprecated)"
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

# (Check 12 retired by F000039: it enforced the workbench-coupling guard token
# in the now-deleted middle-layer pipeline skill's pipeline.md. That skill was
# flattened off /CJ_goal_todo_fix and deleted; the portability rationale the
# check protected died with it. The dispatched leaf phase skills
# (/CJ_implement-from-spec, /CJ_qa-work-item) run only the portable
# `/CJ_personal-workflow check` at their boundaries, so downstream portability
# no longer needs a static guard token.)

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

# Check 15: doc-spec.md registry (declared <=> on-disk) + workflow.md completeness
# The doc contract lives in the root doc-spec.md registry (a fenced ```yaml block
# parsed by scripts/doc-spec.sh). Check 15a asserts declared <=> on-disk: every
# declared doc exists AND every docs/*.md on disk is declared (no orphans). Check
# 15b asserts docs/workflow.md carries a section for every CJ_goal_* orchestrator
# (the component skills it dispatches live in the same doc's `## Utilities &
# phase-step skills` section, guaranteed visible by the docs/philosophy.md
# decision-tree New-skills check). No silent omission of a workflow.
echo ""
echo "=== Check 15: doc-spec.md registry (declared <=> on-disk) + workflow.md completeness ==="

# 15a: parse the doc-spec.md registry via the helper (--list-declared) and check
# declared <=> on-disk. The helper enforces schema validity itself (Check 16);
# here we only need the declared path list. If the helper is missing/unparseable
# the declared set is empty and 15a-orphan flags every docs/*.md loudly.
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
DECLARED_PATHS=""
if [ -x "$DOC_SPEC_HELPER" ]; then
  DECLARED_PATHS=$(bash "$DOC_SPEC_HELPER" --list-declared 2>/dev/null || true)
fi

# 15a-orphan: docs/*.md on disk that aren't declared in the registry.
DOCS_FILES_ON_DISK=$(find docs -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
for f in $DOCS_FILES_ON_DISK; do
  if ! printf '%s\n' "$DECLARED_PATHS" | grep -qFx "$f"; then
    echo "  ERROR: $f is in docs/ but not declared in the doc-spec.md registry"
    ERRORS=$((ERRORS+1))
  fi
done

# 15a-missing: declared docs that are missing from disk.
for p in $DECLARED_PATHS; do
  if [ ! -f "$REPO_ROOT/$p" ]; then
    echo "  ERROR: $p is declared in doc-spec.md but missing from disk"
    ERRORS=$((ERRORS+1))
  fi
done
[ -n "$DECLARED_PATHS" ] && echo "  PASS: doc-spec.md registry declared <=> on-disk ($(printf '%s\n' "$DECLARED_PATHS" | grep -c .) docs declared)"

# 15b: workflow.md per-workflow completeness (only if the doc exists).
# Enforce a section ONLY for the CJ_goal_* workflow orchestrators (today:
# CJ_goal_feature, CJ_goal_defect, CJ_goal_todo_fix). Component skills live in
# docs/workflow.md's `## Utilities & phase-step skills` section.
CATALOG_FILE="docs/workflow.md"
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
    # 15b-touches (T000040): the **Touches** block MUST carry all four canonical
    # bullets — Skills dispatched / Steps · phases / Scripts · tools · shell /
    # Docs touched — at the granular helper + named-step level. Patterns are
    # LINE-ANCHORED on the bullet shape (`^- \*\*<dim>`), NOT bare substrings:
    # SECTION above is the WHOLE section body (chart + prose + Touches), so a bare
    # `Steps` would false-match a chart node (`Step 5.5`) or an Invoke-when
    # sentence and pass a section with NO Touches bullet, defeating the check. The
    # anchored bullet line is the deterministic structural guarantee; completeness
    # WITHIN each bullet stays agent-judged (CJ_document-release Step 6.7 audit +
    # the docs/workflow.md `requirement:` in the doc-spec.md registry).
    if ! echo "$SECTION" | grep -qE '^- \*\*Skills'; then
      echo "  ERROR: $CATALOG_FILE section '$SKILL_NAME' Touches block missing the 'Skills dispatched' bullet (expected a line matching '^- **Skills')"
      ERRORS=$((ERRORS+1))
    fi
    if ! echo "$SECTION" | grep -qE '^- \*\*Steps'; then
      echo "  ERROR: $CATALOG_FILE section '$SKILL_NAME' Touches block missing the 'Steps · phases' bullet (expected a line matching '^- **Steps')"
      ERRORS=$((ERRORS+1))
    fi
    if ! echo "$SECTION" | grep -qE '^- \*\*Scripts'; then
      echo "  ERROR: $CATALOG_FILE section '$SKILL_NAME' Touches block missing the 'Scripts · tools · shell' bullet (expected a line matching '^- **Scripts')"
      ERRORS=$((ERRORS+1))
    fi
    if ! echo "$SECTION" | grep -qE '^- \*\*Docs'; then
      echo "  ERROR: $CATALOG_FILE section '$SKILL_NAME' Touches block missing the 'Docs touched' bullet (expected a line matching '^- **Docs')"
      ERRORS=$((ERRORS+1))
    fi
  done < <(jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | select(.name | startswith("CJ_goal_")) | .name' skills-catalog.json)
fi

# Check 16: doc-spec.md registry schema enforcement
# Skip silently when doc-spec.md is missing (non-adopting repos). When present,
# enforce the registry schema via scripts/doc-spec.sh --validate: a fenced ```yaml
# block, schema_version supported, every docs[] entry has path/section/audit_class,
# and every audit_class is in the closed enum {human-doc, operational}. The helper
# emits `[doc-sync-no-config] <reason>` + exits 1 on any violation; this check
# surfaces that as an ERROR.
echo ""
echo "=== Check 16: doc-spec.md registry schema ==="
DOC_SPEC_FILE="doc-spec.md"
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
if [ -f "$DOC_SPEC_FILE" ]; then
  if [ ! -x "$DOC_SPEC_HELPER" ]; then
    echo "  ERROR: doc-spec.md present but scripts/doc-spec.sh helper missing/not executable"
    ERRORS=$((ERRORS+1))
  else
    if HELPER_OUT=$(bash "$DOC_SPEC_HELPER" --validate 2>&1); then
      echo "  PASS: $DOC_SPEC_FILE registry ($HELPER_OUT)"
    else
      echo "  ERROR: $DOC_SPEC_FILE registry invalid: $HELPER_OUT"
      ERRORS=$((ERRORS+1))
    fi
  fi
else
  echo "  SKIP: $DOC_SPEC_FILE not present (non-adopting repo; check is conditional)"
fi

echo ""
echo "=== Check 17: root-doc placement allowlist (doc-spec.md registry) ==="
# The root-docs allowlist now lives in the doc-spec.md registry: every root *.md
# on disk MUST be a declared registry path (a non-docs/ declared entry). Parse the
# declared set via the helper (--list-declared), filter to the root-level entries
# (no `/`), and check both directions. If doc-spec.md/helper is absent the
# declared set is empty and every root *.md flags loudly as an orphan.
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
ALL_DECLARED=""
if [ -x "$DOC_SPEC_HELPER" ]; then
  ALL_DECLARED=$(bash "$DOC_SPEC_HELPER" --list-declared 2>/dev/null || true)
fi
# Root-level declared docs = declared paths with no slash.
ALLOWED_ROOT_MD=$(printf '%s\n' "$ALL_DECLARED" | grep -vE '/' || true)
ROOT_MD_ON_DISK=$(find . -maxdepth 1 -type f -name '*.md' 2>/dev/null | sed 's#^\./##' | sort)

# 17-orphan: root *.md on disk that isn't declared in doc-spec.md.
for f in $ROOT_MD_ON_DISK; do
  if ! printf '%s\n' "$ALLOWED_ROOT_MD" | grep -qFx "$f"; then
    echo "  ERROR: root doc $f is not declared in the doc-spec.md registry; move it to docs/ (and declare it) or add a registry entry (section: custom) with a purpose"
    ERRORS=$((ERRORS+1))
  fi
done
# 17-missing: declared root entry that points to a missing file.
for p in $ALLOWED_ROOT_MD; do
  if [ ! -f "$REPO_ROOT/$p" ]; then
    echo "  ERROR: $p is a declared root doc in doc-spec.md but missing from disk"
    ERRORS=$((ERRORS+1))
  fi
done
# Empty allowlist is not separately guarded: it surfaces as an orphan ERROR for
# every root *.md (acceptable — the registry is required and present; an absent
# doc-spec.md fails loudly via orphan errors, never silently passes). Count once
# into a var; `|| true` keeps it safe under set -euo pipefail.
N_ALLOW=$(printf '%s\n' "$ALLOWED_ROOT_MD" | grep -c . || true)
[ "$N_ALLOW" -gt 0 ] && echo "  PASS: root *.md allowlist parsed from doc-spec.md ($N_ALLOW entries)"

# Check 18: portability audit (F000047 / S000083) — ADVISORY.
# Runs the shared static-lint engine (scripts/cj-portability-audit.sh) over the
# catalog-derived skill set and prints its per-skill verdict table. The engine
# compares each skill's declared `portability` against its ACTUAL executed
# repo-local dependencies (strict tier ladder; EXECUTED-vs-documented precision;
# bundled-own + scoped self-resolution-preamble carve-outs; `portability_requires`
# adjudication). v1 posture is ADVISORY: findings print but do NOT fail validate
# (the workbench has real declared-vs-actual mismatches today, adjudicated green
# via pre-seeded `portability_requires`). Setting PORTABILITY_STRICT=1 flips it to
# a hard gate (findings -> ERROR) — the documented Story-2 follow-up once the
# declarations are fully reconciled. The engine itself always exits 0 in default
# mode; this check inspects its FINDINGS=<n> tail.
echo ""
echo "=== Check 18: skill portability audit (advisory) ==="
PA_ENGINE="$REPO_ROOT/scripts/cj-portability-audit.sh"
if [ ! -x "$PA_ENGINE" ] && [ ! -f "$PA_ENGINE" ]; then
  echo "  SKIP: scripts/cj-portability-audit.sh not found (engine absent)"
else
  PA_OUT=$(bash "$PA_ENGINE" 2>&1) || true
  # Echo the engine's table verbatim, indented, so findings are visible in the run.
  while IFS= read -r _pa_line; do
    echo "  $_pa_line"
  done <<PA_TABLE
$PA_OUT
PA_TABLE
  PA_FINDINGS=$(printf '%s\n' "$PA_OUT" | sed -n 's/^FINDINGS=\([0-9][0-9]*\)$/\1/p' | head -1)
  PA_FINDINGS=${PA_FINDINGS:-0}
  if [ "$PA_FINDINGS" -gt 0 ]; then
    if [ "${PORTABILITY_STRICT:-0}" = "1" ]; then
      echo "  ERROR: $PA_FINDINGS skill(s) have unresolved portability findings (PORTABILITY_STRICT=1)"
      ERRORS=$((ERRORS+1))
    else
      echo "  ADVISORY: $PA_FINDINGS skill(s) have portability findings (advisory in v1; set PORTABILITY_STRICT=1 to hard-fail). Resolve by relabeling the skill's portability or adding the dep to its portability_requires."
    fi
  else
    echo "  PASS: portability audit clean ($PA_FINDINGS findings after adjudication)"
  fi
fi

# Check 19: no work-item refs in human docs (hard lint)
# For every doc-spec.md registry entry with audit_class: human-doc, grep for a
# work-item ID of the shape [FSTD] followed by exactly six digits. Any hit is an
# ERROR — human docs must stay human-readable (no internal-tracker noise). The
# doc-spec migration scrubs these first, so this lands green. Skips silently when
# doc-spec.md / the helper is absent (non-adopting repo). Uses --list-human-docs
# (the registry-derived human-doc set) so adding a human doc to the registry
# automatically extends the lint with no second list to maintain.
echo ""
echo "=== Check 19: no work-item refs in human docs ==="
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
if [ -f "doc-spec.md" ] && [ -x "$DOC_SPEC_HELPER" ]; then
  HUMAN_DOCS=$(bash "$DOC_SPEC_HELPER" --list-human-docs 2>/dev/null || true)
  C19_HITS=0
  for d in $HUMAN_DOCS; do
    [ -f "$REPO_ROOT/$d" ] || continue
    # grep -E for [FSTD] + 6 digits; capture matching lines for the message.
    if MATCHES=$(grep -nE '[FSTD][0-9]{6}' "$REPO_ROOT/$d" 2>/dev/null); then
      C19_HITS=$((C19_HITS+1))
      echo "  ERROR: human-doc $d contains work-item ref(s) (audit_class: human-doc must carry none):"
      printf '%s\n' "$MATCHES" | head -5 | while IFS= read -r _ml; do echo "    $_ml"; done
      ERRORS=$((ERRORS+1))
    fi
  done
  if [ "$C19_HITS" -eq 0 ]; then
    echo "  PASS: no work-item refs in any human-doc ($(printf '%s\n' "$HUMAN_DOCS" | grep -c .) human-docs scanned)"
  fi
else
  echo "  SKIP: doc-spec.md / helper not present (non-adopting repo; check is conditional)"
fi

# Check 20: front-table-required docs open with a summary table (hard lint)
# For every doc-spec.md registry entry flagged `front_table: required` (enumerated
# via doc-spec.sh --list-front-table-docs — registry-driven, no hardcoded
# filenames), assert the doc OPENS with a Markdown table: a `^\|` row IMMEDIATELY
# followed by a delimiter row (`^\|[ :|+-]*-[ :|+-]*\|$`) appearing BEFORE the
# doc's first `^## ` heading. Stopping at the first `^## ` is essential — both
# flagged docs already contain tables LATER (in a decision tree / a utility
# section), so a whole-file grep would yield a false PASS. awk-only, bash-3.2-safe.
# On a miss emit `  ERROR:` inline (the Check 15-19 style; NOT the fail() helper,
# which prints `FAIL:` — the negative test greps a literal `  ERROR:` prefix).
# Skips silently when doc-spec.md / the helper is absent (non-adopting repo).
echo ""
echo "=== Check 20: front-table-required docs open with a summary table ==="
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
if [ -f "doc-spec.md" ] && [ -x "$DOC_SPEC_HELPER" ]; then
  FRONT_TABLE_DOCS=$(bash "$DOC_SPEC_HELPER" --list-front-table-docs 2>/dev/null || true)
  C20_CHECKED=0
  for d in $FRONT_TABLE_DOCS; do
    C20_CHECKED=$((C20_CHECKED+1))
    if [ ! -f "$REPO_ROOT/$d" ]; then
      # Missing-on-disk is already an ERROR in Check 15a; don't double-count. Skip.
      continue
    fi
    # awk: walk from the top; stop at the first `^## `. A table is found when the
    # current line is a delimiter row AND the immediately-preceding line was a
    # `^|` row. NOTE: a bare `exit 0` would jump to END and the END's `exit`
    # would clobber the code — so set found=1 + `exit` (no arg, preserves it) and
    # let `END { exit !found }` yield 0-on-hit / 1-on-miss.
    if awk '
      /^## / { exit }
      /^\|[ :|+-]*-[ :|+-]*\|$/ {
        if (prev ~ /^\|/) { found = 1; exit }
      }
      { prev = $0 }
      END { exit !found }
    ' "$REPO_ROOT/$d" >/dev/null 2>&1; then
      echo "  PASS: $d opens with a summary table (before its first '## ' heading)"
    else
      echo "  ERROR: front-table-required doc $d does not open with a summary table before its first '## ' heading (front_table: required in doc-spec.md — add a leading Markdown table, e.g. a '|'-row followed by a '|---|' delimiter row)"
      ERRORS=$((ERRORS+1))
    fi
  done
  [ "$C20_CHECKED" -eq 0 ] && echo "  SKIP: no front_table: required docs declared in the doc-spec.md registry"
else
  echo "  SKIP: doc-spec.md / helper not present (non-adopting repo; check is conditional)"
fi

# Check 21: cj_goal permission-policy <-> enforcement-point drift (F000053/S000094) — ADVISORY.
# permission-policy.md is the single declared allow/ask/deny contract; this check
# flags drift between it and the enforcement points (advisory — exit 0, like
# Check 18; a follow-up PR flips it strict once reconciled). Drift = the policy
# does not parse, the handoff-gate re-hardcoded its denylist instead of deriving
# from the policy, or a live orchestrator dropped its policy pointer. Skips
# silently when the policy / parser is absent (non-adopting repo).
echo ""
echo "=== Check 21: cj_goal permission-policy drift (advisory) ==="
PP_HELPER="$REPO_ROOT/scripts/permission-policy.sh"
PP_FILE="$REPO_ROOT/permission-policy.md"
if [ ! -f "$PP_FILE" ] || [ ! -x "$PP_HELPER" ]; then
  echo "  SKIP: permission-policy.md / scripts/permission-policy.sh absent (non-adopting repo)"
else
  PP_DRIFT=0
  if ! bash "$PP_HELPER" --validate >/dev/null 2>&1; then
    echo "  ADVISORY: permission-policy.md does not parse ($(bash "$PP_HELPER" --validate 2>&1 | head -1))"
    PP_DRIFT=$((PP_DRIFT+1))
  fi
  if [ -f "$REPO_ROOT/scripts/cj-handoff-gate.sh" ] && ! grep -q 'surface-globs' "$REPO_ROOT/scripts/cj-handoff-gate.sh"; then
    echo "  ADVISORY: scripts/cj-handoff-gate.sh no longer derives its denylist from the policy (re-hardcoded?)"
    PP_DRIFT=$((PP_DRIFT+1))
  fi
  for _orch in CJ_goal_feature CJ_goal_task CJ_goal_defect CJ_goal_todo_fix; do
    _md="$REPO_ROOT/skills/$_orch/SKILL.md"
    if [ -f "$_md" ] && ! grep -q 'permission-policy.md' "$_md"; then
      echo "  ADVISORY: skills/$_orch/SKILL.md does not reference permission-policy.md (policy pointer dropped?)"
      PP_DRIFT=$((PP_DRIFT+1))
    fi
  done
  if [ "$PP_DRIFT" -eq 0 ]; then
    echo "  PASS: permission policy + enforcement points in sync (parses; gate derives; 4 orchestrators reference it)"
  else
    echo "  ADVISORY: $PP_DRIFT permission-policy drift finding(s) (advisory in v1; a follow-up flips this strict once reconciled)"
  fi
fi

# Check 22: cj_goal gate-spec <-> pipeline marker drift (F000054/S000096) — ADVISORY.
# gate-spec.md is the single declared verification map (the doc-spec -> permission-
# policy -> gate-spec family's third member); this check flags drift between the
# registry and the four live CJ_goal_* pipelines (advisory — exit 0, like Check 21
# / Check 18; a follow-up PR flips it strict once it runs clean across a few real
# builds). Two asserts: (1) the registry parses; (2) per-mode marker drift — for
# every gate, for every mode key in its `markers` map, a literal "[marker]" must
# appear in at least one of that mode's files (skills/CJ_goal_<mode-dir>/pipeline.md
# OR SKILL.md); an {enforced_by: ...} value is skipped (the gate runs but emits no
# bracket marker). A missing literal marker => advisory finding (the pipeline
# drifted from the contract, or the registry is stale). Skips silently when the
# registry / parser is absent (non-adopting repo).
echo ""
echo "=== Check 22: cj_goal gate-spec marker drift (advisory) ==="
GS_HELPER="$REPO_ROOT/scripts/gate-spec.sh"
GS_FILE="$REPO_ROOT/gate-spec.md"
if [ ! -f "$GS_FILE" ] || [ ! -x "$GS_HELPER" ]; then
  echo "  SKIP: gate-spec.md / scripts/gate-spec.sh absent (non-adopting repo)"
else
  GS_DRIFT=0
  if ! bash "$GS_HELPER" --validate >/dev/null 2>&1; then
    echo "  ADVISORY: gate-spec.md does not parse ($(bash "$GS_HELPER" --validate 2>&1 | head -1))"
    GS_DRIFT=$((GS_DRIFT+1))
  else
    # Per-mode marker drift guard. Reuse the helper's own awk parse to extract
    # one `<gate-id> <mode> <value>` triple per declared marker, then grep each
    # literal in that mode's pipeline.md OR SKILL.md. mode-dir map: feature ->
    # CJ_goal_feature, defect -> CJ_goal_defect, task -> CJ_goal_task, todo ->
    # CJ_goal_todo_fix. An {enforced_by:...} value emits no triple (skipped).
    GS_TRIPLES=$(awk '
      /^```yaml/ { if (!seen) { f=1; seen=1; next } }
      /^```/     { if (f) { f=0 } }
      !f { next }
      /^gates:/ { in_gates=1; next }
      !in_gates { next }
      /^[[:space:]]*-[[:space:]]*id:/ { cur_id=$3; in_markers=0; next }
      /^[[:space:]]*layer:/ || /^[[:space:]]*order:/ || /^[[:space:]]*disposition:/ || /^[[:space:]]*backing:/ || /^[[:space:]]*checks:/ { in_markers=0; next }
      /^[[:space:]]*markers:/ { in_markers=1; next }
      in_markers && /^[[:space:]]*[a-z]+:[[:space:]]*/ {
        mode=$1; sub(/:.*/, "", mode)
        val=$0; sub(/^[[:space:]]*[a-z]+:[[:space:]]*/, "", val); sub(/[[:space:]]+#.*$/, "", val)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        if (val ~ /^\{/) { next }   # {enforced_by: ...} — skip (no literal to grep)
        gsub(/^"|"$/, "", val)
        print cur_id "\t" mode "\t" val
      }
    ' "$GS_FILE")
    while IFS="$(printf '\t')" read -r _gid _mode _marker; do
      [ -n "$_marker" ] || continue
      case "$_mode" in
        feature) _dir="CJ_goal_feature" ;;
        defect)  _dir="CJ_goal_defect" ;;
        task)    _dir="CJ_goal_task" ;;
        todo)    _dir="CJ_goal_todo_fix" ;;
        *)       _dir="" ;;
      esac
      [ -n "$_dir" ] || continue
      _pipe="$REPO_ROOT/skills/$_dir/pipeline.md"
      _skill="$REPO_ROOT/skills/$_dir/SKILL.md"
      _found=0
      [ -f "$_pipe" ] && grep -qF "$_marker" "$_pipe" && _found=1
      [ "$_found" -eq 0 ] && [ -f "$_skill" ] && grep -qF "$_marker" "$_skill" && _found=1
      if [ "$_found" -eq 0 ]; then
        echo "  ADVISORY: gate '$_gid' declares marker $_marker for mode '$_mode' but it is absent from skills/$_dir/{pipeline.md,SKILL.md}"
        GS_DRIFT=$((GS_DRIFT+1))
      fi
    done <<EOF
$GS_TRIPLES
EOF
  fi
  if [ "$GS_DRIFT" -eq 0 ]; then
    echo "  PASS: gate-spec registry + the four CJ_goal_* pipelines in sync (parses; every declared literal marker present in its mode's files)"
  else
    echo "  ADVISORY: $GS_DRIFT gate-spec marker drift finding(s) (advisory in v1; a follow-up flips this strict once it runs clean across a few real builds)"
  fi
fi

# Check 23: doc-spec generated views in sync with the registry (F000056/S000098) — HARD.
# docs/doc-general.md + docs/doc-custom.md are GENERATED views of the doc-spec.md
# registry (like README.md is generated from the skill catalog). This check
# regenerates them into a temp dir via scripts/generate-doc-views.sh and diffs
# against the on-disk docs/ copies; any drift is an ERROR (run the generator).
# Using the generator (not bare --render) makes the diff header-safe — the
# generator owns the header on both sides. Skips cleanly if the generator or the
# doc-spec parser is absent (non-adopting / broken-install repo).
echo ""
echo "=== Check 23: doc-spec generated views in sync ==="
DV_GEN="$REPO_ROOT/scripts/generate-doc-views.sh"
DV_SPEC="$REPO_ROOT/scripts/doc-spec.sh"
if [ ! -f "$DV_GEN" ] || [ ! -f "$DV_SPEC" ]; then
  echo "  SKIP: scripts/generate-doc-views.sh / scripts/doc-spec.sh absent (non-adopting repo)"
elif [ ! -f "$REPO_ROOT/docs/doc-general.md" ] || [ ! -f "$REPO_ROOT/docs/doc-custom.md" ]; then
  echo "  SKIP: docs/doc-general.md / docs/doc-custom.md not present (views not adopted)"
else
  DV_TMP=$(mktemp -d)
  if bash "$DV_GEN" --output-dir "$DV_TMP" >/dev/null 2>&1 \
     && diff "$DV_TMP/doc-general.md" "$REPO_ROOT/docs/doc-general.md" >/dev/null 2>&1 \
     && diff "$DV_TMP/doc-custom.md" "$REPO_ROOT/docs/doc-custom.md" >/dev/null 2>&1; then
    echo "  PASS: docs/doc-general.md + docs/doc-custom.md match the registry"
  else
    echo "  ERROR: doc views drifted from the registry — run scripts/generate-doc-views.sh"
    ERRORS=$((ERRORS+1))
  fi
  rm -rf "$DV_TMP"
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
