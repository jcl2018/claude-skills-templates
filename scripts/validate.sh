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
# Closed enum so typos (e.g. "depricated") fail the build instead of silently
# behaving like a missing status. Status is required on every entry.
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

# Error check 10: work-copilot bundle mirrors selected upstream content
#
# MIRROR_SPECS entries are pipe-delimited 4-tuples: src|dst|shape|orphan_policy
#   shape          = single | flat | recursive | manifest
#   orphan_policy  = fail | warn   (fail = stale bundle file fails CI; warn = log only)
#
# Shapes:
#   single     — exact file pair (src + dst are file paths)
#   flat       — directory of *.md files (one level)
#   recursive  — directory tree of *.md files; uses find -print0 (POSIX-portable;
#                bash 3.2 on macOS lacks shopt -s globstar)
#   manifest   — JSON pair compared with `description` field stripped via jq
#                (description is human prose, no programmatic consumer)
#
# Filenames filter to *.md only — keeps OS junk out (.DS_Store, Thumbs.db, .gitkeep,
# .gitattributes, .editorconfig). Binary cmp -s preserves D000005 CRLF safety.
#
# To add a new mirror dir: append one line to MIRROR_SPECS.

MIRROR_SPECS=(
  "deprecated/CJ_company-workflow/templates|work-copilot/templates|flat|warn"
  "deprecated/CJ_company-workflow/WORKFLOW.md|work-copilot/WORKFLOW.md|single|fail"
  "deprecated/CJ_company-workflow/reference|work-copilot/reference|flat|fail"
  "deprecated/CJ_company-workflow/philosophy|work-copilot/philosophy|flat|fail"
  "deprecated/CJ_company-workflow/examples|work-copilot/examples|flat|fail"
  "deprecated/CJ_company-workflow/fixtures|work-copilot/fixtures|recursive|fail"
  "deprecated/CJ_company-workflow/company-artifact-manifests.json|work-copilot/copilot-artifact-manifests.json|manifest|fail"
)

# Orphan reporter — emits FAIL or WARN based on policy. Used by all shapes.
_mirror_orphan() {
  local path="$1" policy="$2" upstream="$3"
  if [ "$policy" = "fail" ]; then
    fail "$path has no counterpart in $upstream (stale bundle file — delete or restore upstream)"
  else
    warn "$path has no counterpart in $upstream"
  fi
}

# Single-file shape: compare two exact file paths.
_mirror_check_single() {
  local src="$1" dst="$2" policy="$3"
  if [ ! -f "$src" ]; then
    fail "$src missing (mirror source absent — sync spec is broken)"
    return
  fi
  if [ ! -f "$dst" ]; then
    fail "$dst missing (must mirror $src)"
  elif ! cmp -s "$src" "$dst"; then
    fail "$dst differs from $src"
  else
    pass "$dst in sync"
  fi
}

# Flat shape: iterate *.md in src dir, check each in dst dir, then orphan-check dst.
_mirror_check_flat() {
  local src_dir="${1%/}" dst_dir="${2%/}" policy="$3"
  if [ ! -d "$src_dir" ]; then
    fail "$src_dir missing (mirror source absent — sync spec is broken)"
    return
  fi
  if [ ! -d "$dst_dir" ]; then
    if [ "$policy" = "fail" ]; then
      fail "$dst_dir missing (must mirror $src_dir)"
    else
      pass "no $dst_dir/ directory (sync check skipped — bundle dir absent)"
    fi
    return
  fi
  local src dst base count=0
  for src in "$src_dir"/*.md; do
    [ -f "$src" ] || continue
    base=$(basename "$src")
    dst="$dst_dir/$base"
    if [ ! -f "$dst" ]; then
      fail "$dst missing (must mirror $src)"
    elif ! cmp -s "$src" "$dst"; then
      fail "$dst differs from $src"
    else
      pass "$dst in sync"
    fi
    count=$((count + 1))
  done
  # Min-count assertion (autoplan G7): empty src dir = silent false-pass otherwise.
  if [ "$count" -eq 0 ]; then
    warn "$src_dir contains no *.md files (mirror spec may be misconfigured or upstream emptied)"
  fi
  # Flat-shape sanity: catch nested *.md the spec author forgot is there.
  # Use find with -mindepth 2 to detect any *.md beneath the first level.
  local nested
  nested=$(find "$src_dir" -mindepth 2 -name '*.md' -print -quit 2>/dev/null)
  if [ -n "$nested" ]; then
    warn "$src_dir contains nested *.md files (e.g., $nested) — flat shape only checks the top level. If nesting is intentional, change MIRROR_SPECS shape to 'recursive'."
  fi
  # Orphan check: bundle-side files with no upstream counterpart.
  for dst in "$dst_dir"/*.md; do
    [ -f "$dst" ] || continue
    base=$(basename "$dst")
    if [ ! -f "$src_dir/$base" ]; then
      _mirror_orphan "$dst" "$policy" "$src_dir/"
    fi
  done
}

# Recursive shape: find -name '*.md' -print0 (POSIX-portable, bash 3.2 safe).
_mirror_check_recursive() {
  local src_dir="${1%/}" dst_dir="${2%/}" policy="$3"
  if [ ! -d "$src_dir" ]; then
    fail "$src_dir missing (mirror source absent — sync spec is broken)"
    return
  fi
  if [ ! -d "$dst_dir" ]; then
    if [ "$policy" = "fail" ]; then
      fail "$dst_dir missing (must mirror $src_dir tree)"
    else
      pass "no $dst_dir/ directory (sync check skipped — bundle dir absent)"
    fi
    return
  fi
  local src rel dst count=0
  while IFS= read -r -d '' src; do
    rel="${src#"$src_dir"/}"
    dst="$dst_dir/$rel"
    if [ ! -f "$dst" ]; then
      fail "$dst missing (must mirror $src)"
    elif ! cmp -s "$src" "$dst"; then
      fail "$dst differs from $src"
    else
      pass "$dst in sync"
    fi
    count=$((count + 1))
  done < <(find "$src_dir" -type f -name '*.md' -print0)
  if [ "$count" -eq 0 ]; then
    warn "$src_dir contains no *.md files recursively (mirror spec may be misconfigured)"
  fi
  # Orphan check: bundle-side files (recursive) with no upstream counterpart.
  while IFS= read -r -d '' dst; do
    rel="${dst#"$dst_dir"/}"
    if [ ! -f "$src_dir/$rel" ]; then
      _mirror_orphan "$dst" "$policy" "$src_dir/"
    fi
  done < <(find "$dst_dir" -type f -name '*.md' -print0)
}

# Manifest shape: schema parity (description field stripped) via jq.
# Reason (autoplan D5): no code grep-consumes the description field; forcing
# byte-identity is test-driven coupling, not product value. The runtime contract
# is filenames + schema, not human prose.
_mirror_check_manifest() {
  local src="$1" dst="$2" policy="$3"
  if [ ! -f "$src" ]; then
    fail "$src missing (manifest source absent)"
    return
  fi
  if [ ! -f "$dst" ]; then
    fail "$dst missing (must mirror $src schema)"
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not installed — manifest schema-parity check skipped"
    return
  fi
  local src_norm dst_norm
  src_norm=$(jq -S 'del(.description)' "$src" 2>/dev/null) || {
    fail "$src is not valid JSON"
    return
  }
  dst_norm=$(jq -S 'del(.description)' "$dst" 2>/dev/null) || {
    fail "$dst is not valid JSON"
    return
  }
  if [ "$src_norm" = "$dst_norm" ]; then
    pass "$dst schema-parity with $src (description field exempt)"
  else
    fail "$dst schema differs from $src (excluding description field)"
  fi
}

echo ""
echo "Checking work-copilot bundle mirror sync (MIRROR_SPECS, ${#MIRROR_SPECS[@]} entries)..."
for spec in "${MIRROR_SPECS[@]}"; do
  IFS='|' read -r _src _dst _shape _policy <<< "$spec"
  case "$_shape" in
    single)    _mirror_check_single    "$_src" "$_dst" "$_policy" ;;
    flat)      _mirror_check_flat      "$_src" "$_dst" "$_policy" ;;
    recursive) _mirror_check_recursive "$_src" "$_dst" "$_policy" ;;
    manifest)  _mirror_check_manifest  "$_src" "$_dst" "$_policy" ;;
    *)         fail "unknown MIRROR_SPECS shape '$_shape' for $_src" ;;
  esac
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
