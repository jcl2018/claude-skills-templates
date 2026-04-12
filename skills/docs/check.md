# /docs check — Staleness Detection + Coherence

Detect stale doc sections via the claims sidecar, and run mechanical coherence checks.

## Step 1: Locate Claims Sidecar

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CLAIMS="$REPO_ROOT/.docs/claims.json"
[ -f "$CLAIMS" ] && echo "FOUND: $CLAIMS" || echo "MISSING"
```

**If MISSING:** Tell the user:
"No .docs/claims.json found. Run `/docs init` first to generate documentation and the claims sidecar."
Stop.

## Step 2: Validate Claims Schema

Read `.docs/claims.json` and validate its structure.

Required top-level fields:
- `version` (number)
- `generated_at` (string, ISO 8601)
- `generated_commit` (string, hex SHA, 7-40 chars)
- `docs` (object, at least one key)

Each doc entry must have `sections` (object). Each section must have:
- `evidence` (array of strings, each a relative file path)
- `commit` (string, hex SHA)

**If validation fails:** Tell the user:
"Error: .docs/claims.json is not valid JSON or has an invalid schema.
Cause: merge conflict, manual edit, or corruption.
Fix: run `/docs init` to regenerate the claims sidecar."
Stop.

## Step 3: Staleness Detection

For each doc in claims.json, for each section:

1. Verify the stored commit exists:
```bash
git cat-file -t STORED_SHA 2>/dev/null && echo "REACHABLE" || echo "UNREACHABLE"
```

2. If UNREACHABLE: flag section as:
```
  UNVERIFIABLE: "Section title" — stored commit not in history (rebase or force-push?)
  Fix: run /docs init to rebuild the baseline.
```
Skip to next section.

3. If REACHABLE: check each evidence file for changes:
```bash
git diff STORED_SHA..HEAD -- "evidence/file/path" 2>/dev/null
```

4. If any evidence file has changes: flag section as STALE.
5. If an evidence file no longer exists: flag as STALE + warn "evidence file deleted."
6. If no changes to any evidence file: section is FRESH.

## Step 4: Mechanical Coherence Checks

Scan all markdown files in the repo root for:

**4a. Broken internal links:**
Find all markdown links `[text](path)` where path is a relative file path.
Check if the target file exists. Flag missing targets.

**4b. Conflicting version numbers:**
If multiple docs reference a version number (e.g., in frontmatter `version:` fields),
check they agree. Flag conflicts.

**4c. References to deleted files/functions:**
If docs reference specific file paths (e.g., `skills/docs/SKILL.md`) or function
names, check they still exist via Glob/Grep. Flag references to missing targets.

## Step 5: Output Report

Format the report as a structured staleness check:

```
=== /docs check ===
Claims: .docs/claims.json (generated TIMESTAMP, commit SHA)

STALENESS CHECK:
  PHILOSOPHY.md:
    [FRESH]  Why this repo exists — no evidence changes
    [STALE]  Design principles — CLAUDE.md changed (3 lines added)
    [STALE]  Key patterns — skills/workflow/SKILL.md modified
    [FRESH]  How to extend — no evidence changes

  OVERVIEW.md:
    [FRESH]  What this project is — no evidence changes
    [UNVERIFIABLE] Architecture — stored commit abc1234 not in history

COHERENCE CHECK:
  [PASS] Internal links — 12 checked, 0 broken
  [WARN] Version conflict — SKILL.md says 0.1.0, catalog says 0.2.0
  [WARN] Dead reference — PHILOSOPHY.md references scripts/migrate.sh (deleted)

SUMMARY: 2 stale sections, 1 unverifiable, 2 coherence warnings
```

## Step 6: Locate Work Items

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
WORK_ITEMS_DIR="$REPO_ROOT/work-items"
[ -d "$WORK_ITEMS_DIR" ] && echo "FOUND: $WORK_ITEMS_DIR" || echo "NO_WORK_ITEMS"
```

**If NO_WORK_ITEMS:** Print "No work-items/ directory found. Skipping work item validation." and skip to the end (no work item validation output).

## Step 7: Load Manifest

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
MANIFEST="$REPO_ROOT/artifact-manifests.json"
[ -f "$MANIFEST" ] && echo "FOUND: $MANIFEST" || echo "NO_MANIFEST"
```

**If NO_MANIFEST:** Print "Warning: artifact-manifests.json not found. Skipping work item validation." and skip to the end.

Read and parse artifact-manifests.json. If JSON is malformed, print "Warning: artifact-manifests.json is not valid JSON. Skipping work item validation." and skip.

Extract the `types` object. Each key is a work item type (feature, defect, task, user-story) with a `required` array of artifact definitions.

## Step 8: Normalization Rules

These rules apply throughout all work item checks. Define them here once; reference from checks below.

**Type spelling:** Normalize by removing hyphens for comparison.
- "user-story" and "userstory" both normalize to "userstory"
- Always display the hyphenated form ("user-story") in output messages

**Filename matching:** Strip `{ID}_` prefix when matching against manifest filenames.
- "S000002_PRD.md" matches manifest filename "PRD.md"
- Pattern: a file matches if its name equals `{expected}` or ends with `_{expected}`

**Parent/child relationships:** Directory nesting is canonical.
- A work item in `work-items/F000001/S000001/` has parent F000001
- Frontmatter `parent` field is checked for consistency with nesting but does not override it
- If `parent` field is present and differs from the directory parent, flag as DRIFT

**Work item state** (derived from lifecycle checkboxes in TRACKER.md):
- **Open** = zero checkboxes checked (all `- [ ]`)
- **In Progress** = some checked, some unchecked (mix of `- [x]` and `- [ ]`)
- **Closed** = all checkboxes checked (all `- [x]`)

**Template resolution:** 2-level fallback chain.
1. `$REPO_ROOT/templates/{template_filename}`
2. `~/.claude/templates/{template_filename}`

Use the first found. If neither exists, warn: "Warning: template {filename} not found. Skipping validation for this artifact." and skip that artifact.

## Step 9: Build Expected Model

For each type in artifact-manifests.json `types` object:

1. Read the `required` array to get the list of artifacts, each with `artifact`, `template`, and `filename` fields
2. For each artifact entry, resolve the template file using the 2-level fallback chain (Step 8)
3. If template found:
   - Parse its YAML frontmatter (between `---` markers) to extract required field names (the keys)
   - Scan for `##` and `###` section headers to extract required sections
4. If template not found: warn and skip this artifact
5. If YAML frontmatter cannot be parsed: warn "Warning: could not parse frontmatter in {template}. Skipping." and skip

Store the Expected Model: for each type, the list of required artifacts with their expected frontmatter fields and section headers.

## Step 10: Build Actual Model

Walk `./work-items/` recursively (max depth 3 from the work-items root):

For each directory that contains a file named `TRACKER.md` (with or without an ID prefix like `F000001_TRACKER.md`):

1. Read the TRACKER.md file
2. If YAML frontmatter cannot be parsed: warn "Warning: could not parse frontmatter in {path}. Skipping this work item." and skip
3. Extract the `type` field from frontmatter, normalize spelling per Step 8
4. List all `.md` files in the directory
5. For each `.md` file, match against expected artifact filenames using the filename normalization rule (strip ID prefix)
6. Determine the directory parent: if this directory is nested inside another directory that also has a TRACKER.md, the outer directory is the parent
7. Determine children: subdirectories that also contain a TRACKER.md
8. Determine state: count `- [x]` (checked) and `- [ ]` (unchecked) patterns in the Lifecycle section. Apply the state definitions from Step 8.

## Step 11: Check 1 — Template Compliance

For each work item in the Actual Model:

1. Look up its normalized type in the Expected Model
   - If type not found in manifest: flag `[WARN] {item} — type "{type}" not found in artifact-manifests.json`
2. For each required artifact in the Expected Model:
   - **If file not found:** flag `[MISSING] {artifact} — required artifact not found`
   - **If file found:** 
     - Parse YAML frontmatter. If parsing fails: flag `[WARN] {artifact} — could not parse frontmatter`
     - Compare frontmatter keys against template's required keys:
       - Missing key: flag `[DRIFT] {artifact} — missing required field "{field}"`
       - Extra key: no flag (acceptable, work items accumulate fields)
     - Compare `##` section headers against template's required `##` sections:
       - Missing section: flag `[DRIFT] {artifact} — missing section "{section}"`
       - Extra section: flag `[EXTRA] {artifact} — unexpected section "{section}"` (WARN level only, advisory)
3. Check the `type` field value against the expected type (normalized comparison):
   - Mismatch: flag `[DRIFT] TRACKER.md — type field says "{actual}", expected "{expected}"`
4. If the template for this type has a `parent` field in its frontmatter:
   - If `parent` missing from actual frontmatter: flag `[DRIFT] TRACKER.md — missing required field "parent"`
   - If `parent` present but differs from directory parent: flag `[DRIFT] TRACKER.md — parent field says "{value}", directory parent is "{dir_parent}"`

## Step 12: Check 2 — Lifecycle Consistency

For each work item that has children (per the Actual Model):

1. Determine the parent's state and each child's state (per Step 8 definitions)
2. **Parent Closed, child not Closed:**
   - Flag `[LIFECYCLE_INCONSISTENT] {parent} is Closed but child {child} is {child_state}`
3. **Child Closed, parent Open:**
   - Flag `[WARN] Child {child} is Closed but parent {parent} is Open (may be intentional)`
4. **Nesting depth exceeds 3:**
   - Flag `[WARN] {item} — nesting depth {N} exceeds maximum of 3`
5. If all parent/child states are consistent: `[PASS] All children consistent with parent state`

For work items with no children: `[PASS] No children`

## Step 13: Check 3 — Cross-Reference Traceability

For features and user-stories that have BOTH a PRD.md and TEST-SPEC.md (matched via filename normalization):

1. **Parse PRD.md** for P0 user story entries:
   - Find the `### P0 (Must-Have)` section
   - Extract story numbers from the `#` column in the table rows
   - These are the P0 story numbers requiring test coverage
2. **Parse PRD.md** for P1/P2 story entries:
   - Find `### P1 (Important)` and `### P2 (Nice-to-Have)` sections
   - Extract story numbers from the `#` column
3. **Parse TEST-SPEC.md** test matrix:
   - Find the `## Test Matrix` table
   - Extract all `AC-{n}` values from the AC column
4. **For each P0 story number:**
   - If no TEST-SPEC row has `AC-{n}` matching this story number: flag `[UNTESTED] P0 story #{n} has no TEST-SPEC coverage`
5. **For each P1/P2 story number:**
   - If no TEST-SPEC row has a matching `AC-{n}`: flag `[INFO] P1/P2 story #{n} has no TEST-SPEC coverage (advisory)`
6. If all P0 stories have coverage: `[PASS] All P0 stories have TEST-SPEC coverage`

For work items missing PRD or TEST-SPEC: skip traceability (no output for this subsection).

## Step 14: Work Item Validation Output

Append to the existing report after the COHERENCE CHECK section:

```
WORK ITEM VALIDATION:
  {item_slug} ({type}):
    TEMPLATE:
      [PASS]  {artifact} — all required fields and sections present
      [DRIFT] {artifact} — {description}
      [MISSING] {artifact} — required artifact not found
      [EXTRA] {artifact} — unexpected section "{section}" (advisory)
    LIFECYCLE:
      [PASS]  All children consistent with parent state
      [LIFECYCLE_INCONSISTENT] {description}
      [WARN]  {description}
    TRACEABILITY:
      [PASS]  All P0 stories have TEST-SPEC coverage
      [UNTESTED] P0 story #{n} has no TEST-SPEC coverage
      [INFO]  P1/P2 story #{n} has no TEST-SPEC coverage (advisory)

  {next_item_slug} ({type}):
    ...

WORK ITEM SUMMARY: {N} items checked, {N} drift issues, {N} missing artifacts, {N} traceability warnings, {N} lifecycle issues
```

Items should be listed in tree order: parent first, then children (depth-first).

## Error Messages

- **Not a git repo:** "Error: /docs requires a git repository."
- **No claims.json:** "No .docs/claims.json found. Run /docs init first."
- **Malformed claims.json:** "Error: .docs/claims.json is not valid JSON or has an invalid schema. Cause: merge conflict, manual edit, or corruption. Fix: run /docs init to regenerate."
- **Unreachable commit:** "{section}: stored commit {sha} not in history. Likely cause: rebase or force-push. Fix: run /docs init to rebuild baseline."
- **No work-items/:** "No work-items/ directory found. Skipping work item validation."
- **No manifest:** "Warning: artifact-manifests.json not found. Skipping work item validation."
- **Malformed manifest:** "Warning: artifact-manifests.json is not valid JSON. Skipping work item validation."
- **Template not found:** "Warning: template {filename} not found. Skipping validation for this artifact."
- **Unparseable frontmatter:** "Warning: could not parse frontmatter in {path}. Skipping."
