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
  # Read the frontmatter block ONCE, then match it with `case` globs — NOT a
  # `sed | grep -q` pipe. `grep -q` early-exits on the match, which SIGPIPEs `sed`
  # while it is still writing a very long `description:` line; under
  # `set -o pipefail` that non-zero pipe status flips the check to a FALSE FAIL.
  # It is timing-flaky (passes on a fast host, fails on a slower CI runner) and
  # only bites skills with a huge single-line description (hit live on
  # CJ_test_audit, whose description is a ~5000-char line). `case` avoids the pipe.
  _fm=$(sed -n '/^---$/,/^---$/p' "$skill_file")
  case "$_fm" in *name:*) _fm_name=1 ;; *) _fm_name=0 ;; esac
  case "$_fm" in *description:*) _fm_desc=1 ;; *) _fm_desc=0 ;; esac
  if [ "$_fm_name" = 1 ] && [ "$_fm_desc" = 1 ]; then
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
# Check 4 is satisfied) while every `!= deprecated` selector — Check 13/14,
# workflow-spec.sh --validate registry-completeness, the portability audit, the
# registered-doc audit — correctly excludes it.
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
  # `workflows/` is the GENERATED per-workflow subfolder (F000067 mandate; F000069
  # generation), NOT a per-skill doc directory — its files are declared human-docs
  # in the doc-spec registry (Check 15a enforces declared <=> on-disk), rendered
  # from spec/workflow-spec.md by workflow-spec.sh --render-docs, and kept fresh by
  # Check 27. Skip it here.
  if [ "$dir_name" = "workflows" ]; then
    pass "docs/workflows is the generated per-workflow subfolder (declared in the doc-spec registry; rendered by workflow-spec.sh --render-docs)"
    continue
  fi
  # `tests/` is the GENERATED test-catalog subfolder (F000069) — one
  # docs/tests/<family>.md per unit family, rendered by test-spec.sh
  # --render-docs, declared as human-docs in the doc-spec registry (Check 15a)
  # and kept fresh by Check 26. NOT a per-skill doc dir — skip it here.
  if [ "$dir_name" = "tests" ]; then
    pass "docs/tests is the generated test-catalog subfolder (declared in the doc-spec registry; rendered by test-spec.sh --render-docs)"
    continue
  fi
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
# The doc contract lives in the spec/doc-spec.md registry (a 3-column Markdown
# table parsed by scripts/doc-spec.sh). Check 15a asserts declared <=> on-disk:
# every declared doc exists AND every docs/**/*.md on disk (recursive, incl.
# docs/workflows/) is declared (no orphans).
#
# Checks 15b + 15c are RETIRED (F000069/S000115): the entire workflow surface
# (docs/workflow.md + docs/workflows/*.md) is now GENERATED from
# spec/workflow-spec.md by scripts/workflow-spec.sh --render-docs. The shape-only
# guarantees those checks gave (15b: each orchestrator doc has a chart + the four
# anchored Touches bullets; 15c: the index links each orchestrator) are replaced
# by truth/freshness enforcement: the no-vanish guarantee now lives in
# `workflow-spec.sh --validate` (registry-completeness — every routable CJ_goal_*
# skill has an orchestrator entry, a STRONGER guarantee than 15c's index-link
# grep), and freshness is Check 27 below (regenerate→diff; a stale chart/Touches
# can no longer pass). See Check 27 + scripts/workflow-spec.sh.
echo ""
echo "=== Check 15: doc-spec.md registry (declared <=> on-disk) + workflows completeness ==="

# 15a: parse the doc-spec.md registry via the helper (--list-declared) and check
# declared <=> on-disk. The helper enforces schema validity itself (Check 16);
# here we only need the declared path list. If the helper is missing/unparseable
# the declared set is empty and 15a-orphan flags every docs/*.md loudly.
DOC_SPEC_HELPER="$REPO_ROOT/scripts/doc-spec.sh"
DECLARED_PATHS=""
if [ -x "$DOC_SPEC_HELPER" ]; then
  DECLARED_PATHS=$(bash "$DOC_SPEC_HELPER" --list-declared 2>/dev/null || true)
fi

# 15a-orphan: docs/**/*.md on disk that aren't declared in the registry. The
# scan RECURSES (no -maxdepth) so a per-workflow file under docs/workflows/ must
# also be declared (F000067 docs/workflows/ subfolder); this mirrors the
# doc-spec.sh --check-on-disk recursed orphan scan so validate.sh and the engine
# agree on what counts as an orphan.
DOCS_FILES_ON_DISK=$(find docs -type f -name '*.md' 2>/dev/null | sort)
for f in $DOCS_FILES_ON_DISK; do
  if ! printf '%s\n' "$DECLARED_PATHS" | grep -qFx "$f"; then
    echo "  ERROR: $f is in docs/ but not declared in the doc-spec.md registry"
    ERRORS=$((ERRORS+1))
  fi
done

# 15a-orphan (spec/): spec/*.md on disk that aren't declared in the registry.
# The spec-registry family lives under spec/; hold it to the same declared <=>
# on-disk discipline as docs/ so a stray spec/*.md must be declared (or removed).
SPEC_FILES_ON_DISK=$(find spec -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
for f in $SPEC_FILES_ON_DISK; do
  if ! printf '%s\n' "$DECLARED_PATHS" | grep -qFx "$f"; then
    echo "  ERROR: $f is in spec/ but not declared in the doc-spec.md registry"
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

# Checks 15b + 15c RETIRED (F000069/S000115). The workflow surface is now
# GENERATED from spec/workflow-spec.md; the no-vanish guarantee lives in
# `workflow-spec.sh --validate` (registry-completeness) and freshness in Check 27.

# Check 16: doc-spec.md registry schema enforcement
# Skip silently when doc-spec.md is missing (non-adopting repos). When present,
# enforce the registry schema via scripts/doc-spec.sh --validate: a fenced ```yaml
# block, schema_version supported, every docs[] entry has path/section/audit_class,
# and every audit_class is in the closed enum {human-doc, operational}. The helper
# emits `[doc-sync-no-config] <reason>` + exits 1 on any violation; this check
# surfaces that as an ERROR.
echo ""
echo "=== Check 16: doc-spec.md registry schema ==="
# Resolve spec/-then-root (the family moved into spec/; root remains a fallback
# for root-only consumers). Probe the same order the doc-spec.sh helper uses so
# this check never silently SKIPs after the relocation.
DOC_SPEC_FILE="$REPO_ROOT/spec/doc-spec.md"
[ -f "$DOC_SPEC_FILE" ] || DOC_SPEC_FILE="$REPO_ROOT/doc-spec.md"
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

# Check 18: portability audit (F000047 / S000083; strict-by-default since T000054) — HARD.
# Runs the shared static-lint engine (scripts/cj-portability-audit.sh) over the
# catalog-derived skill set and prints its per-skill verdict table. The engine
# compares each skill's declared `portability` against its ACTUAL executed
# repo-local dependencies (strict tier ladder; EXECUTED-vs-documented precision;
# bundled-own + scoped self-resolution-preamble carve-outs; `portability_requires`
# adjudication). Posture is STRICT-BY-DEFAULT (T000054): findings -> ERROR on every
# commit (pre-commit hook), CI, and manual run — the whole repo is the portability
# ratchet, not just the cj_goal orchestrated path. The catalog is clean today
# (FINDINGS=0 after adjudication), so this is green now and any regression is by
# definition new. Escape hatch: PORTABILITY_STRICT=0 downgrades it to advisory for
# a deliberate WIP commit. The engine itself always exits 0 in default mode; this
# check inspects its FINDINGS=<n> tail and decides ERROR vs advisory.
echo ""
echo "=== Check 18: skill portability audit (strict) ==="
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
    if [ "${PORTABILITY_STRICT:-1}" = "1" ]; then
      echo "  ERROR: $PA_FINDINGS skill(s) have unresolved portability findings (strict-by-default; set PORTABILITY_STRICT=0 to downgrade to advisory). Resolve by relabeling the skill's portability or adding the dep to its portability_requires."
      ERRORS=$((ERRORS+1))
    else
      echo "  ADVISORY: $PA_FINDINGS skill(s) have portability findings (downgraded via PORTABILITY_STRICT=0; unset it to restore the strict-by-default hard-fail). Resolve by relabeling the skill's portability or adding the dep to its portability_requires."
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
# Resolve spec/-then-root so this HARD gate never silently SKIPs after the move.
_C19_DOC_SPEC="$REPO_ROOT/spec/doc-spec.md"
[ -f "$_C19_DOC_SPEC" ] || _C19_DOC_SPEC="$REPO_ROOT/doc-spec.md"
if [ -f "$_C19_DOC_SPEC" ] && [ -x "$DOC_SPEC_HELPER" ]; then
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

# Check 21: cj_goal permission-policy <-> enforcement-point drift (F000053/S000094) — ADVISORY.
# permission-policy.md is the single declared allow/ask/deny contract; this check
# flags drift between it and the enforcement points (advisory — exit 0; a
# follow-up PR flips it strict once reconciled, the same path Check 18 took in
# T000054). Drift = the policy
# does not parse, the handoff-gate re-hardcoded its denylist instead of deriving
# from the policy, or a live orchestrator dropped its policy pointer. Skips
# silently when the policy / parser is absent (non-adopting repo).
echo ""
echo "=== Check 21: cj_goal permission-policy drift (advisory) ==="
PP_HELPER="$REPO_ROOT/scripts/permission-policy.sh"
# Resolve spec/-then-root (the family moved into spec/; root remains a fallback).
PP_FILE="$REPO_ROOT/spec/permission-policy.md"
[ -f "$PP_FILE" ] || PP_FILE="$REPO_ROOT/permission-policy.md"
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

# Check 24: test-spec coverage cross-check + gate marker drift (F000060 + F000063).
# MIXED disposition: the coverage portion is HARD (exit 1), the per-mode gate
# marker-drift portion (absorbed from the retired Check 22) is ADVISORY (exit 0).
# SKIP-when-registry-absent.
#
# The two-tier test-spec registry (the spec/test-spec.md general rules + layers +
# the spec/test-spec-custom.md units + gates overlay) declares one units: row per
# verification unit (validate checks, test sub-suites + inline families,
# standalone suites, CI workflows, git hooks) AND a gates: array of per-mode
# pipeline-gate rows (the four-layer map's pipeline-gate layer, folded in from
# the retired gate-spec.md). The check first validates the merged registry
# (scripts/test-spec.sh --validate — the symmetric schema gate Check 16 runs for
# the doc-spec), then runs --check-coverage to prove the registry and the live
# surface still cover each other:
#   forward — every unit's anchor matches LIVE in its declared source (a
#             removed or renamed check orphans its row; a test file whose
#             runner block disappears from scripts/test.sh orphans that row —
#             the silent-skip catch);
#   reverse — every live validate banner/comment, tests/*.test.sh on disk,
#             workflow file, and installed hook resolves to exactly one row;
#   floor   — reverse extraction must yield >= 20 live tokens, so extraction-
#             grammar rot can never make the check vacuously pass. The reverse
#             sweep + floor are units-gated: a rules-only registry (a seeded
#             consumer repo with no overlay) reports "coverage cross-check
#             inactive" and passes — never a misleading finding;
#   behavior — (F000066) when the overlay declares behaviors:, every
#             behavior_coverage link resolves to one behavior + one test-bearing
#             unit, every anchor greps live (grep -F), and every behavior has
#             >= 1 covering row. Behaviors-gated INDEPENDENT of the units: gate;
#             a no-behaviors repo reports "behavior coverage inactive". A
#             behavior finding fails the SAME hard loop as a coverage finding.
# THEN the ADVISORY gate marker-drift cross-check (was Check 22): for every gate
# in the gates: array, for every mode key in its `markers` map, a literal
# "[marker]" must appear in at least one of that mode's files
# (skills/CJ_goal_<mode-dir>/{pipeline.md,SKILL.md}); an {enforced_by: ...} value
# is skipped. A missing literal marker => ADVISORY finding (exit 0 preserved —
# this portion NEVER hard-fails, deliberately; only the coverage portion errors).
# When the registry is absent (non-adopting repo) the check SKIPs — never an
# ERROR (the helper itself classifies that as REGISTRY=absent + exit 0). A
# present registry with a missing helper is a broken install and DOES error
# (Check 16's posture for the doc-spec helper).
echo ""
echo "=== Check 24: test-spec coverage cross-check + gate marker drift ==="
TS_HELPER="$REPO_ROOT/scripts/test-spec.sh"
TS_REGISTRY="$REPO_ROOT/spec/test-spec.md"
[ -f "$TS_REGISTRY" ] || TS_REGISTRY="$REPO_ROOT/test-spec.md"
# The gates: array lives in the overlay (next to the general file).
TS_OVERLAY="$(dirname "$TS_REGISTRY")/test-spec-custom.md"
if [ ! -f "$TS_REGISTRY" ]; then
  echo "  SKIP: test-spec.md registry not present (non-adopting repo; check is conditional)"
elif [ ! -f "$TS_HELPER" ]; then
  echo "  ERROR: test-spec.md registry present but scripts/test-spec.sh helper missing"
  ERRORS=$((ERRORS+1))
else
  if TS_VAL_OUT=$(bash "$TS_HELPER" --validate 2>&1); then
    echo "  PASS: test-spec registry valid ($(printf '%s\n' "$TS_VAL_OUT" | tail -1))"
  else
    echo "  ERROR: test-spec registry invalid: $TS_VAL_OUT"
    ERRORS=$((ERRORS+1))
  fi
  if TS_OUT=$(bash "$TS_HELPER" --check-coverage 2>&1); then
    echo "  PASS: test-spec coverage cross-check clean ($(printf '%s\n' "$TS_OUT" | tail -1))"
  else
    while IFS= read -r _ts_line; do
      echo "  $_ts_line"
    done <<TS_FINDINGS
$TS_OUT
TS_FINDINGS
    echo "  ERROR: test-spec coverage cross-check failed — add/fix the units row(s) in spec/test-spec-custom.md (or wire the orphaned unit)"
    ERRORS=$((ERRORS+1))
  fi

  # --- ADVISORY: per-mode gate marker drift (absorbed Check 22; exit 0) ---
  # Parse one `<gate-id> <mode> <literal>` triple per declared bracket marker
  # from the gates: array in the overlay, then grep each literal in that mode's
  # pipeline.md OR SKILL.md. An {enforced_by:...} value emits no triple (skipped).
  # A missing literal => ADVISORY finding only (never increments ERRORS).
  GS_DRIFT=0
  if [ -f "$TS_OVERLAY" ]; then
    GS_TRIPLES=$(awk '
      /^```yaml/ { if (!seen) { f=1; seen=1; next } }
      /^```/     { if (f) { f=0 } }
      !f { next }
      /^gates:/ { in_gates=1; next }
      /^(rules|units|layers):/ { in_gates=0; next }
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
    ' "$TS_OVERLAY")
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
    echo "  PASS: gate marker drift — the gates: array + the four CJ_goal_* pipelines in sync (every declared literal marker present in its mode's files)"
  else
    echo "  ADVISORY: $GS_DRIFT gate marker drift finding(s) (advisory — this portion never hard-fails; only the coverage cross-check above errors)"
  fi
fi

# Check 25: README.md is in sync with scripts/generate-readme.sh output (HARD).
# README.md is fully generated from skills-catalog.json by scripts/generate-readme.sh
# (it prints to stdout; the README is written via
# `bash scripts/generate-readme.sh > README.md`). Without this check a stale
# catalog-derived README — skill descriptions/versions/statuses lagging the
# catalog — passes validation silently. generate-readme.sh is idempotent (no
# timestamps, no run-specific metadata — see its header + the test.sh idempotency
# assertion), so a byte diff between its live stdout and README.md is a
# deterministic staleness signal. READ-ONLY: the generator writes only to stdout
# here; README.md is never modified by this check.
echo ""
echo "=== Check 25: README.md in sync with generate-readme.sh ==="
GENREADME="$REPO_ROOT/scripts/generate-readme.sh"
if [ ! -f "$GENREADME" ]; then
  echo "  SKIP: scripts/generate-readme.sh not present (non-adopting repo)"
elif [ ! -f "$REPO_ROOT/README.md" ]; then
  echo "  ERROR: README.md is missing — run: bash scripts/generate-readme.sh > README.md"
  ERRORS=$((ERRORS+1))
else
  README_DIFF=$(diff "$REPO_ROOT/README.md" <(bash "$GENREADME" 2>/dev/null) 2>/dev/null || true)
  if [ -z "$README_DIFF" ]; then
    pass "README.md matches generate-readme.sh output (catalog-derived README is current)"
  else
    echo "  ERROR: README.md is stale vs generate-readme.sh — run: bash scripts/generate-readme.sh > README.md"
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 26: docs/tests/ + docs/test-catalog.md are in sync with the test-spec
# registry (HARD). The generated test catalog (one docs/tests/<family>.md per
# unit family + the docs/test-catalog.md index) is rendered from the merged
# test-spec registry by `scripts/test-spec.sh --render-docs` — the SECOND
# instance of the README ↔ generate-readme.sh ↔ Check 25 primitive (F000069).
# Without this check a stale catalog — family pages lagging the registry's
# units, a removed family's page lingering — passes validation silently.
# `--render-docs --check` is the single freshness owner: it renders to a temp
# dir, diffs vs on-disk, exits non-zero on any mismatch/missing/orphan file.
# The renderer is deterministic (stable sort, fixed headers, no timestamps), so
# a byte diff is a deterministic staleness signal. READ-ONLY: --check renders
# only into a temp dir; the committed docs/ tree is never modified here.
echo ""
echo "=== Check 26: docs/tests/ catalog in sync with test-spec.sh --render-docs ==="
TESTSPEC="$REPO_ROOT/scripts/test-spec.sh"
if [ ! -f "$TESTSPEC" ]; then
  echo "  SKIP: scripts/test-spec.sh not present (non-adopting repo)"
elif [ "$(bash "$TESTSPEC" --list-units 2>/dev/null | grep -c . || true)" -eq 0 ]; then
  echo "  SKIP: no units declared in the test-spec registry (the catalog is units-gated; nothing to render)"
else
  C26_OUT=$(bash "$TESTSPEC" --render-docs --check 2>&1) && C26_RC=0 || C26_RC=$?
  if [ "$C26_RC" -eq 0 ]; then
    pass "docs/tests/ + docs/test-catalog.md match test-spec.sh --render-docs (generated test catalog is current)"
  else
    echo "  ERROR: the generated test catalog is stale vs the registry — run: bash scripts/test-spec.sh --render-docs"
    printf '%s\n' "$C26_OUT" | grep -E '^(FINDING|RENDER):' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 27: docs/workflow.md + docs/workflows/*.md are in sync with the workflow
# registry (HARD). The entire workflow surface (the docs/workflow.md index + the
# six docs/workflows/<name>.md per-workflow files) is rendered from
# spec/workflow-spec.md by `scripts/workflow-spec.sh --render-docs` — the THIRD
# instance of the README ↔ generate-readme.sh ↔ Check 25 + test-catalog ↔ Check 26
# primitive (F000069/S000115). Without this check a stale workflow doc — a chart
# or a Touches bullet lagging the registry, a removed workflow's page lingering —
# passes validation silently (the shape-only Checks 15b/15c it replaces could not
# see staleness at all). `--render-docs --check` is the single freshness owner: it
# renders to a temp dir, diffs vs on-disk, exits non-zero on any
# mismatch/missing/orphan file. The renderer is deterministic (registry order,
# fixed headers, no timestamps), so a byte diff is a deterministic staleness
# signal. READ-ONLY: --check renders only into a temp dir; the committed docs/ tree
# is never modified here. Registry-gated: skips when spec/workflow-spec.md is
# absent (mirror of Check 26's engine-absent skip).
echo ""
echo "=== Check 27: docs/workflow.md + docs/workflows/ in sync with workflow-spec.sh --render-docs ==="
WORKFLOWSPEC="$REPO_ROOT/scripts/workflow-spec.sh"
if [ ! -f "$WORKFLOWSPEC" ]; then
  echo "  SKIP: scripts/workflow-spec.sh not present (non-adopting repo)"
elif [ "$(bash "$WORKFLOWSPEC" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $2}')" != "canonical" ]; then
  echo "  SKIP: no spec/workflow-spec.md registry (the workflow surface is registry-gated; nothing to render)"
else
  C27_OUT=$(bash "$WORKFLOWSPEC" --render-docs --check 2>&1) && C27_RC=0 || C27_RC=$?
  if [ "$C27_RC" -eq 0 ]; then
    pass "docs/workflow.md + docs/workflows/ match workflow-spec.sh --render-docs (generated workflow surface is current)"
  else
    echo "  ERROR: the generated workflow surface is stale vs the registry — run: bash scripts/workflow-spec.sh --render-docs"
    printf '%s\n' "$C27_OUT" | grep -E '^(FINDING|RENDER):' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 28: every CJ_goal_* orchestrator has a level:workflow behavior + no
# orphan workflow: link (HARD, registry-gated). The workflow-coverage gate
# (F000070) is a forward + reverse cross-check between the declared CJ_goal_*
# orchestrators (spec/workflow-spec.md, via workflow-spec.sh --list-orchestrators)
# and the level:workflow behaviors in the test-spec registry: FORWARD — every
# orchestrator has >=1 level:workflow behavior whose `workflow:` equals it;
# REVERSE — every level:workflow behavior's `workflow:` resolves to a declared
# orchestrator. This makes "documented-but-untested workflow" structurally
# impossible: adding a 5th CJ_goal_* orchestrator HARD-fails CI until it has a
# level:workflow behavior linked to a real eval case. The gate runs in plain CI
# (registry-only, no API); the linked eval cases RUN nightly/local with the API
# key. Engine: scripts/test-spec.sh --check-workflow-coverage (which resolves
# workflow-spec.sh repo-local→_cj-shared and registry-gates itself). Registry-
# gated: skips when the test-spec engine is absent OR the gate reports inactive
# (no test-spec registry / no resolvable orchestrators — a consumer with no
# orchestrators passes vacuously). Mirror of Check 24/26/27's engine-absent skip.
echo ""
echo "=== Check 28: every CJ_goal_* orchestrator has a level:workflow behavior (workflow-coverage gate) ==="
TESTSPEC_WFC="$REPO_ROOT/scripts/test-spec.sh"
if [ ! -f "$TESTSPEC_WFC" ]; then
  echo "  SKIP: scripts/test-spec.sh not present (non-adopting repo)"
else
  C28_OUT=$(bash "$TESTSPEC_WFC" --check-workflow-coverage 2>&1) && C28_RC=0 || C28_RC=$?
  if printf '%s\n' "$C28_OUT" | grep -qE '^(REGISTRY=absent|workflow coverage inactive)'; then
    echo "  SKIP: workflow-coverage gate inactive (no test-spec registry or no resolvable orchestrators — registry-gated)"
  elif [ "$C28_RC" -eq 0 ]; then
    pass "every declared CJ_goal_* orchestrator has a level:workflow behavior; no orphan workflow: link ($(printf '%s\n' "$C28_OUT" | grep '^workflow coverage:' | head -1))"
  else
    echo "  ERROR: the workflow-coverage gate has findings — a documented-but-untested orchestrator, or an orphan workflow: link"
    printf '%s\n' "$C28_OUT" | grep -E '^FINDING:' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 29: the cj_goal local-E2E sandbox marker (.cj-e2e-sandbox) must NEVER be
# in the tracked tree (HARD). The marker is the second half of the build-gate
# auto-answer seam's double guard (F000071 Part A / S000120): the seam is active
# ONLY when CJ_GOAL_E2E_AUTO=1 AND .cj-e2e-sandbox exists at the repo root. The
# marker is .gitignore'd and only ever exists in a throwaway local-E2E sandbox
# checkout; if it were ever committed into a real repo, the seam could become
# live there with only an env flag — defeating the guard. This check makes that
# impossible by hard-failing whenever git tracks .cj-e2e-sandbox (anywhere in the
# tree). Engine: `git ls-files` (the committed/staged tree, not the working dir),
# so a gitignored-but-present marker in a sandbox passes cleanly.
echo ""
echo "=== Check 29: cj_goal E2E sandbox marker absent from the tracked tree ==="
C29_TRACKED=$(git -C "$REPO_ROOT" ls-files -- '.cj-e2e-sandbox' '**/.cj-e2e-sandbox' 2>/dev/null || true)
if [ -n "$C29_TRACKED" ]; then
  echo "  ERROR: .cj-e2e-sandbox is in the tracked tree — the cj_goal E2E seam marker must never be committed"
  printf '%s\n' "$C29_TRACKED" | while IFS= read -r _mk; do echo "    tracked: $_mk"; done
  echo "    Remove it: git rm --cached <path> (the marker belongs only in a throwaway local-E2E sandbox; it is .gitignore'd)"
  ERRORS=$((ERRORS+1))
else
  pass ".cj-e2e-sandbox is not tracked (the E2E build-gate seam guard marker cannot ship)"
fi

# Check 30: every ENROLLED test topic reaches all three verification layers
# deterministically (the three-layer topic contract, HARD, registry-gated).
# F000082 adds a first-class `topic:` axis to the categories: rows and an
# overlay-level `topic_contracts:` enrollment list; this Check calls test-spec.sh
# --check-topic-contract to assert that every enrolled topic (portability /
# validator / full-suite, today) carries >=1 CI-push + >=1 CI-nightly + >=1
# local-hook{deterministic} test, each with its front-door
# docs/tests/<cat>/<layer>/<name>.md. A missing local-hook{agentic} test is
# ADVISORY (F000086): the engine prints a per-topic `note:` line, never a finding
# — agentic proofs run on-demand, never a requirement, so enrollment is not gated
# on the hardest-to-build test mode. This makes a documented-but-under-covered
# topic structurally impossible for an enrolled topic, while unenrolled topics
# keep the advisory matrix (the grandfather seam). Declaration-only ⇒ CI-safe,
# ZERO model spend (an agentic BEHAVIOR, where declared, is proven local-only by
# /CJ_test_run --e2e; mode:agentic ⇒ tier≠free, so an agentic row is
# present-in-CI-but-never-executed). Engine: scripts/test-spec.sh
# --check-topic-contract (which registry-gates itself). Registry-gated: skips when
# the test-spec engine is absent OR the contract reports inactive (no test-spec
# registry / no categories: axis / no topic_contracts: enrollment — a consumer with
# no enrollment passes vacuously). Mirror of Check 24/26/27/28's engine-absent skip.
echo ""
echo "=== Check 30: every enrolled test topic reaches all three layers deterministically (topic contract; agentic advisory) ==="
TESTSPEC_TC="$REPO_ROOT/scripts/test-spec.sh"
if [ ! -f "$TESTSPEC_TC" ]; then
  echo "  SKIP: scripts/test-spec.sh not present (non-adopting repo)"
else
  C30_OUT=$(bash "$TESTSPEC_TC" --check-topic-contract 2>&1) && C30_RC=0 || C30_RC=$?
  if printf '%s\n' "$C30_OUT" | grep -qE '^(REGISTRY=absent|topic contract inactive)'; then
    echo "  SKIP: topic contract inactive (no test-spec registry, no categories: axis, or no topic_contracts: enrollment — registry-gated)"
  elif [ "$C30_RC" -eq 0 ]; then
    pass "every enrolled topic reaches CI-push + CI-nightly + local-hook{deterministic} with its front-door doc — a missing agentic test is advisory ($(printf '%s\n' "$C30_OUT" | grep '^topic contract:' | head -1))"
  else
    echo "  ERROR: the topic contract has findings — an enrolled topic is missing a required deterministic coverage point or its front-door doc"
    printf '%s\n' "$C30_OUT" | grep -E '^FINDING:' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 31: every ENROLLED test topic is DOCUMENTED end to end — a docs/goals/<topic>.md
# dream doc + a docs/tests/topics/<topic>/ subdir (index referencing the dream + a
# per-layer page for each layer it covers). F000083's doc-legibility companion to
# Check 30: Check 30 proves the enrolled topic's TESTS reach all layers; Check 31
# proves its testing is DOCUMENTED as a whole (the WHAT — a dream doc — plus the HOW —
# a topic-by-layer subdir), so a maintainer can learn from the docs what the topic
# proves and how, and the docs cannot rot back to one-line stubs. Declaration-only ⇒
# CI-safe. Engine: scripts/test-spec.sh --check-topic-docs (registry-gates itself).
# Registry-gated: skips when the engine is absent OR the contract reports inactive
# (no test-spec registry / no categories: axis / no topic_contracts: enrollment).
echo ""
echo "=== Check 31: every enrolled test topic is documented (dream doc + topic-by-layer subdir) ==="
TESTSPEC_TD="$REPO_ROOT/scripts/test-spec.sh"
if [ ! -f "$TESTSPEC_TD" ]; then
  echo "  SKIP: scripts/test-spec.sh not present (non-adopting repo)"
else
  C31_OUT=$(bash "$TESTSPEC_TD" --check-topic-docs 2>&1) && C31_RC=0 || C31_RC=$?
  if printf '%s\n' "$C31_OUT" | grep -qE '^(REGISTRY=absent|topic docs contract inactive)'; then
    echo "  SKIP: topic docs contract inactive (no test-spec registry, no categories: axis, or no topic_contracts: enrollment — registry-gated)"
  elif [ "$C31_RC" -eq 0 ]; then
    pass "every enrolled topic has its dream doc + topic-by-layer subdir ($(printf '%s\n' "$C31_OUT" | grep '^topic docs contract:' | head -1))"
  else
    echo "  ERROR: the topic docs contract has findings — an enrolled topic is missing its dream doc or a per-layer topic page"
    printf '%s\n' "$C31_OUT" | grep -E '^FINDING:' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
fi

# Check 32: every defect work-item dir maps to exactly one LIVE defect-coverage
# ledger row (the defect↔proof ledger, HARD, registry-gated). F000085 adds an
# overlay-level `defect_coverage:` axis to spec/test-spec-custom.md — one row per
# work-items/defects/** dir (keyed by the FULL path relative to
# work-items/defects/), each carrying one of three closed dispositions:
# covered-by (a named deterministic regression categories: row), covered-by-anchor
# (a shared-file proof: source + anchor, grep-live), or waived (a reason; gaps are
# `waived: "gap — …"` + a todo pointer). This Check calls test-spec.sh
# --check-defect-coverage: FORWARD, an unmapped (or duplicated) defect dir is an
# ERROR; REVERSE, a dangling row, a covered-by citing a nonexistent or
# NON-DETERMINISTIC categories row (the deterministic-only ledger rule — a future
# agentic-test purge must never orphan defect coverage), a dead anchor, or an
# empty waiver reason is an ERROR. So "is defect X still protected, and by what?"
# is machine-answerable and a hallucinated proof citation cannot ship.
# Registry-gated: skips when the test-spec engine is absent OR the check reports
# inactive (no test-spec registry / no defect_coverage: axis / no
# work-items/defects/ dir — a consumer repo passes vacuously). Mirror of Check
# 24/26/27/28/30/31's engine-absent skip.
echo ""
echo "=== Check 32: every defect dir maps to a live defect-coverage ledger row (defect coverage) ==="
TESTSPEC_DC="$REPO_ROOT/scripts/test-spec.sh"
if [ ! -f "$TESTSPEC_DC" ]; then
  echo "  SKIP: scripts/test-spec.sh not present (non-adopting repo)"
else
  C32_OUT=$(bash "$TESTSPEC_DC" --check-defect-coverage 2>&1) && C32_RC=0 || C32_RC=$?
  if printf '%s\n' "$C32_OUT" | grep -qE '^(REGISTRY=absent|defect coverage inactive)'; then
    echo "  SKIP: defect coverage inactive (no test-spec registry, no defect_coverage: axis, or no work-items/defects/ — registry-gated)"
  elif [ "$C32_RC" -eq 0 ]; then
    pass "every defect dir is dispositioned and every declared proof is live ($(printf '%s\n' "$C32_OUT" | grep '^defect coverage:' | head -1))"
  else
    echo "  ERROR: the defect-coverage ledger has findings — an unmapped defect dir, a dangling row, a dead proof, or a non-deterministic covered-by target"
    printf '%s\n' "$C32_OUT" | grep -E '^FINDING:' | head -10 | while IFS= read -r _cl; do echo "    $_cl"; done
    ERRORS=$((ERRORS+1))
  fi
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
