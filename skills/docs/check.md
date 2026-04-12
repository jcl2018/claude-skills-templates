# /docs check — Staleness Detection + Coherence

Detect stale doc sections via the claims sidecar, and run mechanical coherence checks.

## Step 1: Locate Claims Sidecar

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CLAIMS="$REPO_ROOT/.docs/claims.json"
[ -f "$CLAIMS" ] && echo "FOUND: $CLAIMS" || echo "MISSING"
```

**If MISSING:** Print:
"No .docs/claims.json found. Skipping staleness check (Steps 2-5). Run `/docs init` to generate documentation and the claims sidecar."
Skip to Step 6 (work item validation runs independently of staleness checks).

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

## Step 15: Check 4 — Structural Completeness + Orphan Detection

### 15a: Load Hierarchy Rules

Read the `hierarchy` field from artifact-manifests.json (already loaded in Step 7).

**If `hierarchy` field is missing:** Print "Warning: artifact-manifests.json has no `hierarchy` field. Skipping structural completeness checks." and skip to Step 16 (tree report still renders, structure badge shows "—" for all nodes).

**If `hierarchy` field is malformed** (not a valid JSON object, or entries lack `required_child`/`min`): Print "Warning: artifact-manifests.json `hierarchy` field is malformed. Skipping structural completeness checks." and skip to Step 16.

Also read the `placement` field if present. If missing, use defaults:
```
feature: root, defect: root, user-story: feature, task: user-story
```

### 15b: Structural Completeness Check

For each work item in the Actual Model:
1. Look up its normalized type in the hierarchy rules
2. If the type has a `required_child`:
   - Count children whose normalized type matches `required_child`
   - If count == 0: flag `[INCOMPLETE] {slug} — {type} has 0 {required_child} children (minimum: {min})`
   - If 0 < count < min: flag `[INCOMPLETE] {slug} — {type} has {count} {required_child} child(ren) (minimum: {min})`
   - If count >= min: `[PASS] {slug} — {count} {required_child} child(ren)`
   - Use "child" when count == 1, "children" when count > 1
   - Always use the singular form of the type name (e.g., "2 user-story children")
3. If the type has no required_child entry in hierarchy: `[PASS] {slug} — no structural requirements`

### 15c: Placement Check

For each work item in the Actual Model:
1. Look up its normalized type in the placement rules
2. If placement is `root`: the item must be a direct child of `work-items/` (depth 1 from work-items root). If nested deeper, flag `[MISPLACED] {slug} — {type} must be at root level of work-items/, found inside {parent_slug}`
3. If placement names a parent type (e.g., `user-story` requires parent type `feature`): check the directory parent's type. If parent type does not match, flag `[MISPLACED] {slug} — {type} must be inside a {expected_parent_type}, found inside {actual_parent_type}`
4. Items at the correct placement: no output (implicit pass)

### 15d: Stray Directory Detection

Walk `work-items/` for directories that contain `.md` files but no file matching `TRACKER.md` (with or without ID prefix):

Flag: `[STRAY] {directory_name} — contains .md files but no TRACKER.md (not a work item)`

### 15e: Lifecycle Cross-Reference

For each work item in the Actual Model that has a structural requirement (per 15b):

1. Read the TRACKER.md lifecycle section
2. Search for a checkbox line containing "broken down" or "tasks broken down" (case-insensitive)
3. If such a checkbox is checked (`- [x]`) AND the structural check from 15b found 0 children of the required type:
   - Flag `[LIFECYCLE_INCONSISTENT] {slug} — "broken down" is checked but has 0 {required_child} children`

This flag appears in the lifecycle badge category, not the structure badge category.

## Step 16: Badge Taxonomy + Tree Report

### 16a: Badge Taxonomy Mapping

Map all check statuses to 4 badge categories with severity ordering.

**Badge categories and their status values (lowest to highest severity):**

| Badge | Statuses (severity order) | Source checks |
|-------|--------------------------|---------------|
| template | PASS < WARN (EXTRA sections) < DRIFT (missing field/section) < MISSING (required artifact absent) | Check 1 (Step 11) |
| lifecycle | PASS < WARN (child closed, parent open) < LIFECYCLE_INCONSISTENT (parent closed + child open, or broken-down cross-ref) | Check 2 (Step 12) + Step 15e |
| traceability | PASS < INFO (P1/P2 untested) < UNTESTED (P0 untested) | Check 3 (Step 13) |
| structure | PASS < INCOMPLETE (missing required children) < MISPLACED (wrong hierarchy level) | Check 4 (Step 15b/15c) |

Each badge for a node shows the **worst** (highest severity) status from its category.

For work item types that don't participate in a check (e.g., tasks have no traceability check because they lack PRD/TEST-SPEC): show "—" for that badge.

### 16b: Tree Report

After all checks complete, emit a unified tree view. Walk `work-items/` depth-first, sorting siblings alphabetically by slug at each level.

```
WORK ITEM TREE:
  F000001_workflow_alpha (feature) [In Progress]  completeness: 3/1 user-story
    template: PASS  lifecycle: PASS  traceability: PASS  structure: PASS
    S000001_four_phase (user-story) [In Progress]  completeness: 1/1 task
      template: PASS  lifecycle: PASS  traceability: PASS  structure: PASS
      T000001_router_implementation (task) [Open]
        template: PASS  lifecycle: PASS  structure: PASS  traceability: —
    S000002_template_consolidation (user-story) [In Progress]  completeness: 0/1 task
      template: PASS  lifecycle: PASS  traceability: PASS  structure: INCOMPLETE (0 task children)
    S000003_structural_completeness (user-story) [In Progress]  completeness: 1/1 task
      template: PASS  lifecycle: PASS  traceability: PASS  structure: PASS
      T000002_implement_structural_check (task) [Open]
        template: PASS  lifecycle: PASS  structure: PASS  traceability: —

  F000002_system_health_v1 (feature) [Open]  completeness: 0/1 user-story
    template: PASS  lifecycle: LIFECYCLE_INCONSISTENT  traceability: PASS  structure: INCOMPLETE (0 user-story children)
```

For each node:
- Line 1: `{indent}{slug} ({type}) [{state}]  completeness: {count}/{min} {required_child}` (omit completeness for types with no structural requirement)
- Line 2: `{indent}  template: {badge}  lifecycle: {badge}  traceability: {badge}  structure: {badge}`

Indent is 2 spaces per nesting level from work-items root.

## Step 17: Graph Artifact

After the tree report, emit `work-item-graph.json` to the `.docs/` directory.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
mkdir -p "$REPO_ROOT/.docs"
```

Write `.docs/work-item-graph.json` with this schema (v1.0.0):

```json
{
  "version": "1.0.0",
  "generated_at": "ISO-8601-TIMESTAMP",
  "generated_commit": "SHORT-SHA-or-unknown",
  "nodes": [
    {
      "id": "F000001",
      "slug": "F000001_workflow_alpha",
      "type": "feature",
      "state": "In Progress",
      "path": "work-items/F000001_workflow_alpha",
      "parent": null,
      "children": ["S000001", "S000002", "S000003"],
      "badges": {
        "template": "PASS",
        "lifecycle": "PASS",
        "traceability": "PASS",
        "structure": "PASS"
      },
      "completeness": {"count": 3, "min": 1, "required_child": "user-story"}
    }
  ],
  "edges": [],
  "structural_rules": {}
}
```

**Node fields:**
- `id`: work item ID extracted from slug (e.g., "F000001" from "F000001_workflow_alpha")
- `slug`: directory name
- `type`: normalized type (hyphenated form: "user-story")
- `state`: "Open" / "In Progress" / "Closed"
- `path`: relative path from repo root
- `parent`: parent ID or null (for root items)
- `children`: array of child IDs
- `badges`: per-check badge (worst severity per category). Use "—" for non-applicable badges.
- `completeness`: `{"count": N, "min": M, "required_child": "type"}` or null for types with no structural requirement

**Top-level fields:**
- `structural_rules`: copy the `hierarchy` object from artifact-manifests.json verbatim
- `edges`: empty array (reserved for dependency graph v2)
- `generated_commit`: output of `git rev-parse --short HEAD 2>/dev/null` or "unknown"

Print: "Graph artifact written to .docs/work-item-graph.json"

## Step 18: Structural Completeness Output

Append to the report after the WORK ITEM VALIDATION section:

```
STRUCTURAL COMPLETENESS:
  [INCOMPLETE] F000002_system_health_v1 — feature has 0 user-story children (minimum: 1)
  [INCOMPLETE] S000002_template_consolidation — user-story has 0 task children (minimum: 1)
  [PASS] F000001_workflow_alpha — 3 user-story children
  [PASS] S000001_four_phase — 1 task child
  [PASS] S000003_structural_completeness — 1 task child
  [LIFECYCLE_INCONSISTENT] F000002_system_health_v1 — "broken down" is checked but has 0 user-story children

WORK ITEM TREE:
  [... tree visualization from Step 16b ...]

Graph artifact written to .docs/work-item-graph.json

STRUCTURAL SUMMARY: {N} items, {N} incomplete, {N} misplaced, {N} stray, {N} lifecycle cross-ref issues
```

## Step 19: Human-Readable Report

After all checks complete, write a human-readable markdown report to `.docs/work-item-report.md`. This report consumes all data from Steps 1-18.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
mkdir -p "$REPO_ROOT/.docs"
```

Write `.docs/work-item-report.md` with this structure:

````markdown
# Work Item Health Report

Generated: {ISO-8601 timestamp}
Commit: {short SHA from git rev-parse --short HEAD, or "unknown"}
Repo: {repo name from basename of REPO_ROOT}

## Tree

```
{exact same tree visualization from Step 16b}
```

## Badge Summary

| Item | Type | State | Template | Lifecycle | Traceability | Structure |
|------|------|-------|----------|-----------|--------------|-----------|
| {slug} | {type} | {state} | {badge} | {badge} | {badge} | {badge} |
````

One row per work item, in tree order (depth-first, alphabetical siblings). The tree shows hierarchy with inline badges; the table provides a flat, sortable view for quick scanning.

```markdown
## Findings

### Critical
{list all INCOMPLETE (root items), LIFECYCLE_INCONSISTENT, MISPLACED, MISSING findings}

### Warnings
{list all INCOMPLETE (non-root), DRIFT, UNTESTED, STRAY findings}

### Advisory
{list all INFO, EXTRA, WARN findings}
```

"Root items" = work items whose placement rule is `root` (features and defects by default, per artifact-manifests.json placement rules).

If no findings exist in a severity category, omit that subsection. If no findings at all, write: "No issues found."

```markdown
## Structural Summary

- **Items:** {N} total ({N} features, {N} user-stories, {N} tasks, {N} defects)
- **Incomplete:** {N}
- **Misplaced:** {N}
- **Lifecycle issues:** {N}
- **Stray directories:** {N}
```

Include staleness and coherence results from Steps 3-5 if they ran (claims.json was present):

```markdown
## Staleness

- **Stale sections:** {N}
- **Fresh sections:** {N}
- **Unverifiable sections:** {N}

## Coherence

- **Broken links:** {N}
- **Version conflicts:** {N}
- **Dead references:** {N}
```

If staleness checks were skipped (no claims.json), omit the Staleness and Coherence sections entirely.

Print: "Report written to .docs/work-item-report.md"

## Error Messages

- **Not a git repo:** "Error: /docs requires a git repository."
- **No claims.json:** "No .docs/claims.json found. Skipping staleness check. Run /docs init to generate."
- **Malformed claims.json:** "Error: .docs/claims.json is not valid JSON or has an invalid schema. Cause: merge conflict, manual edit, or corruption. Fix: run /docs init to regenerate."
- **Unreachable commit:** "{section}: stored commit {sha} not in history. Likely cause: rebase or force-push. Fix: run /docs init to rebuild baseline."
- **No work-items/:** "No work-items/ directory found. Skipping work item validation."
- **No manifest:** "Warning: artifact-manifests.json not found. Skipping work item validation."
- **Malformed manifest:** "Warning: artifact-manifests.json is not valid JSON. Skipping work item validation."
- **Template not found:** "Warning: template {filename} not found. Skipping validation for this artifact."
- **Unparseable frontmatter:** "Warning: could not parse frontmatter in {path}. Skipping."
- **No hierarchy field:** "Warning: artifact-manifests.json has no `hierarchy` field. Skipping structural completeness checks."
- **Malformed hierarchy:** "Warning: artifact-manifests.json `hierarchy` field is malformed. Skipping structural completeness checks."
