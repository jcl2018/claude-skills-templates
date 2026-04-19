# /personal-workflow check — Work Item Validation

Validate work items against the templates in `templates/personal-workflow/` and
`personal-artifact-manifests.json`. **Templates are the single source of truth**
for structural rules — required frontmatter fields, required sections, section
order, lifecycle phases, and minimum checkbox counts are all derived from the
matching template at runtime. Edit a template, the validator's expectations
change automatically. There is no separate `contract.json`.

Two tiers: Tier 1 (single file or directory, matches company-workflow validate
approach) and Tier 2 (full hierarchy walk with cross-checks, graph artifact,
and report).

Invocation model:
- File path argument → Tier 1 File Mode only
- Directory path argument → Tier 1 Directory Mode + Tier 2
- No argument → Tier 1 + Tier 2 on full work-items/ directory
- No work-items/ directory → skip Tier 2 with INFO message

---

# TIER 1: Foundation
# Matches company-workflow validate approach: template + manifest-based checks.

## Normalization Rules

These rules apply throughout all checks. Define them here once; reference from all steps.

**Type spelling:** Normalize by removing hyphens for comparison.
- "user-story" and "userstory" both normalize to "userstory"
- Always display the hyphenated form ("user-story") in output messages

**Filename matching:** Strip `{ID}_` prefix when matching against manifest filenames.
- "S000001_PRD.md" matches manifest filename "PRD.md"
- Pattern: a file matches if its name equals `{expected}` or ends with `_{expected}`

**Parent/child relationships:** Directory nesting is canonical.
- A work item in `work-items/F000001/S000001/` has parent F000001
- Frontmatter `parent` field is checked for consistency with nesting but does not override it
- If `parent` field is present and differs from the directory parent, flag as DRIFT

**Work item state** (derived from lifecycle checkboxes in TRACKER.md):
- **Open** = zero checkboxes checked (all `- [ ]` or `- [X]` patterns, none checked)
- **In Progress** = some checked, some unchecked
- **Closed** = all checkboxes checked (all `- [x]` or `- [X]`)

**Template resolution:** 2-level fallback chain.
1. `$_TMPL_DIR/{template_filename}` (from SKILL.md path resolution)
2. `~/.claude/templates/personal-workflow/{template_filename}`

Use the first found. If none exists, warn: "Warning: template {filename} not found. Skipping validation for this artifact." and skip that artifact.

**Section order validation:** Derive `expected_order` from the template's `##`
header order at runtime. Filter `expected_order` to only sections actually
present in the instance file (sections in the template but missing from the
instance are already flagged as missing-section violations), then assert the
filtered list matches the instance's section order.

**Template-derived rules** (the validator's spec — derived per type at runtime):

| Rule | Derivation |
|---|---|
| Required frontmatter fields | All keys present in the template's YAML frontmatter |
| Required sections | All `## ` headers in the template, in document order |
| Expected section order | The template's `##` header order |
| Required lifecycle phases | All `### Phase N: {name}` headers in the template's `## Lifecycle` section |
| Minimum checkbox count | Count of `- [ ]` and `- [x]` patterns inside the template's `## Lifecycle` section |
| Optional sections (per type) | Inferred structurally — if the per-type template includes the section, it's required for that type; if absent, it's not allowed (extras flagged as advisory `[EXTRA]`) |
| Unresolved placeholder detection | Scan the instance's frontmatter values for `\{[A-Z_]+\}` patterns |

## Step 1: Determine Mode

Parse the user's input to determine the target path:
- If a file path is given and the file exists: **File Mode** (Steps 2-7)
- If a directory path is given and the directory exists: **Directory Mode** (Steps 8-13), then **Tier 2** (Steps 14-23)
- If no path is given: set target to `$REPO_ROOT/work-items` and run **Directory Mode** + **Tier 2**
- If the path does not exist: "Error: path not found: {path}" and stop

## Step 2: Read Target File

Read the target file and parse its YAML frontmatter (between `---` markers).

If the file does not contain a `## Lifecycle` section, warn:
"Warning: {path} does not look like a tracker file. File-mode validation only validates trackers — for doc artifacts (PRD, RCA, test-plan, etc.), use Directory Mode on the parent directory."
Then stop (do not produce false positives by validating a doc against a tracker template).

## Step 3: Resolve Template

Read the `type` field from the instance's frontmatter. Apply Type Spelling
normalization from Normalization Rules.

Verify the type is one of `feature`, `defect`, `task`, `user-story`. If not:
`VIOLATION: unknown type "{value}" in {path}` and stop.

Resolve the matching template file at `$_TMPL_DIR/tracker-{type}.md` via the
2-level Template Resolution fallback chain. If the template cannot be found:
`Error: template tracker-{type}.md not found at {_TMPL_DIR} or ~/.claude/templates/personal-workflow/. Run skills-deploy install.` and stop.

## Step 4: Parse Template (derive expectations)

Parse the template file:

- Frontmatter keys → `required_fields` (every key present in the template is required in the instance)
- `##` headers in document order → `expected_sections` (this list IS the required section list AND the expected order)
- `### Phase N:` headers in document order, found inside the template's `## Lifecycle` section → `required_phases`
- Count of lines matching `^\s*[-*+]\s+\[[ xX]\]` inside the template's Lifecycle section → `min_checkboxes`

## Step 5: Check Frontmatter

For each field in `required_fields`:
- If missing from instance frontmatter: `VIOLATION: missing required field "{field}" in {path}`

Scan each frontmatter value in the instance for placeholder patterns matching
`\{[A-Z_]+\}`:
- If found: `VIOLATION: unresolved placeholder "{placeholder}" in frontmatter of {path}`

## Step 6: Check Sections

Extract all `## ` headings from the instance, in document order → `present_sections`.

For each section in `expected_sections`:
- If missing from `present_sections`: `VIOLATION: missing section "{section}" in {path}`

For each section in `present_sections` not in `expected_sections`:
- `[EXTRA] unexpected section "{section}" in {path}` (advisory only, not a hard violation)

Check section order: filter `expected_sections` to only sections actually
present in the instance, then assert `present_sections` matches the filtered
list in order:
- If not: `VIOLATION: section order mismatch — "{section}" appears before "{other}" in {path}`

## Step 6.5: Check Lifecycle

Find the `## Lifecycle` section in the instance.

Count checkboxes: lines matching `^\s*[-*+]\s+\[[ xX]\]` inside the Lifecycle section → `present_checkbox_count`.

Find `### Phase N:` headers in the instance's Lifecycle section → `present_phases`.

Verify:
- For each phase in `required_phases`: if not in `present_phases` → `VIOLATION: missing phase "{phase}" in {path}`
- If `present_checkbox_count` < `min_checkboxes` → `VIOLATION: lifecycle has {N} checkboxes, minimum is {min} (per template) in {path}`

## Step 7: File Mode Report

- Exit 0: all checks pass. Print "VALID: {path}"
- Exit 1: one or more violations. Print each violation to stderr.

**File Mode ends here.** Do not proceed to Directory Mode or Tier 2.

---

## Step 8: Locate TRACKER.md (Directory Mode)

Find files matching `*_TRACKER.md` or `TRACKER.md` in the target directory.
If multiple matches, use the first one alphabetically.

If no TRACKER.md found: "Error: no TRACKER.md found in {directory}. Not a work item directory." and stop.

## Step 9: Read Type

Parse TRACKER.md frontmatter. Extract the `type` field.
Normalize spelling per Normalization Rules.

Verify type is one of the known types (feature, defect, task, user-story).
If unknown: `[WARN] — type "{value}" not recognized`

## Step 10: Load Manifest

```bash
cat "$_SKILL_DIR/personal-artifact-manifests.json"
```

If missing or malformed: "Error: personal-artifact-manifests.json not found or invalid." and stop.

Find the type entry in the `types` object.

## Step 11: Check Artifact Completeness

For each required artifact in the manifest:
- List all `.md` files in the directory
- Match files using the Filename Matching Rule (strip ID prefix)
- If missing: `[MISSING] {artifact} — required artifact not found`
- If found: validate frontmatter using Template Frontmatter Comparison below

**Template Frontmatter Comparison:**
1. Resolve the template file from `$_TMPL_DIR/{template}` (2-level fallback)
2. Parse the template's YAML frontmatter to extract key names
3. Parse the artifact's YAML frontmatter
4. For each key in the template's frontmatter: check it exists in the artifact
   - Missing key: `[DRIFT] {artifact} — missing required field "{field}"`
5. Check for unresolved placeholders: scan frontmatter values for `{...}` patterns
   (regex `\{[A-Za-z_]+\}`). If found: `[DRIFT] {artifact} — unresolved placeholder "{placeholder}" in frontmatter`

## Step 12: Check Lifecycle (Directory Mode tracker)

Apply the same template-derived structural checks to the TRACKER.md as File
Mode (Steps 3-6.5 above):

1. Resolve the matching template (`tracker-{type}.md` per the TRACKER's `type` field).
2. Derive `required_fields`, `expected_sections`, `required_phases`, `min_checkboxes` from the template.
3. Verify the TRACKER.md instance matches all four:
   - Required sections present and in expected order
   - All required phases present (Track, Implement, Ship for personal-workflow)
   - Checkbox count meets the template's minimum
   - No unresolved frontmatter placeholders

Same violation messages as File Mode, but emitted under the directory report's
LIFECYCLE block.

## Step 13: Directory Mode Report

```
PERSONAL-WORKFLOW CHECK: {directory}
  Type: {type}
  ARTIFACTS:
    [PASS]    TRACKER.md — all required fields present
    [PASS]    PRD.md — all required fields and sections present
    [MISSING] test-plan.md — required artifact not found
    [DRIFT]   ARCHITECTURE.md — missing required field "repo"
  LIFECYCLE:
    [PASS]    3 phases present, {N} checkboxes
  SUMMARY: {N} artifacts checked, {N} missing, {N} drift
```

**If invoked on a single directory (not the full work-items/ tree):** stop here.
**If invoked with no path or on the work-items/ root:** continue to Tier 2.

---

# TIER 2: Extensions (personal-workflow only)
# These steps have no equivalent in company-workflow. They require walking the
# entire work-items/ tree, not just validating one file or directory.

## Step 14: Build Actual Model

Walk `./work-items/` recursively (max depth 4 from the work-items root, accounting for type subfolders like `features/` and `defects/`):

For each directory that contains a file named `TRACKER.md` (with or without an ID prefix like `F000001_TRACKER.md`):

1. Read the TRACKER.md file
2. If YAML frontmatter cannot be parsed: warn "Warning: could not parse frontmatter in {path}. Skipping this work item." and skip
3. Extract the `type` field from frontmatter, normalize spelling per Normalization Rules
4. List all `.md` files in the directory
5. For each `.md` file, match against expected artifact filenames using the filename normalization rule (strip ID prefix)
6. Determine the directory parent: if this directory is nested inside another directory that also has a TRACKER.md, the outer directory is the parent
7. Determine children: subdirectories that also contain a TRACKER.md
8. Determine state: count checked and unchecked checkbox patterns in the Lifecycle section. Apply the state definitions from Normalization Rules.

## Step 15: Build Expected Model

For each type in personal-artifact-manifests.json `types` object:

1. Read the `required` array to get the list of artifacts, each with `artifact`, `template`, and `filename` fields
2. For each artifact entry, resolve the template file using the 2-level fallback chain
3. If template found:
   - Parse its YAML frontmatter (between `---` markers) to extract required field names (the keys)
   - Scan for `##` and `###` section headers to extract required sections
4. If template not found: warn and skip this artifact
5. If YAML frontmatter cannot be parsed: warn and skip

Store the Expected Model: for each type, the list of required artifacts with their expected frontmatter fields and section headers.

## Step 16: Check 1 — Template Compliance

For each work item in the Actual Model:

1. Look up its normalized type in the Expected Model
   - If type not found in manifest: flag `[WARN] {item} — type "{type}" not found in personal-artifact-manifests.json`
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

## Step 17: Check 2 — Lifecycle Consistency

For each work item that has children (per the Actual Model):

1. Determine the parent's state and each child's state (per Normalization Rules)
2. **Parent Closed, child not Closed:**
   - Flag `[LIFECYCLE_INCONSISTENT] {parent} is Closed but child {child} is {child_state}`
3. **Child Closed, parent Open:**
   - Flag `[WARN] Child {child} is Closed but parent {parent} is Open (may be intentional)`
4. **Nesting depth exceeds 3:**
   - Flag `[WARN] {item} — nesting depth {N} exceeds maximum of 3`
5. If all parent/child states are consistent: `[PASS] All children consistent with parent state`

For work items with no children: `[PASS] No children`

## Step 18: Check 3 — Cross-Reference Traceability

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

## Step 19: Check 4 — Stray Directory Detection

Walk `work-items/` for directories that contain `.md` files but no file matching
`TRACKER.md` (with or without ID prefix).

**Recognized type subfolders** (valid containers, not work items, don't flag):
`features/`, `defects/`, `reviews/`.

For all other directories without a TRACKER.md:
Flag: `[STRAY] {directory_name} — contains .md files but no TRACKER.md (not a work item)`

**Note on hierarchy:** This validator does NOT enforce parent-child hierarchy
(e.g., "feature must have ≥1 user-story") or placement rules (e.g., "user-story
must nest under a feature"). Those rules live in `WORKFLOW.md` as prose and are
followed by the generating AI at scaffolding time. Same trust model as D000007:
templates + WORKFLOW.md are the source of truth; the AI reads them and follows
them. If AI obedience proves unreliable in practice, add a validator later that
reads its rules from `WORKFLOW.md`.

## Step 20: Badge Taxonomy

Map all check statuses to 3 badge categories with severity ordering.

**Badge categories and their status values (lowest to highest severity):**

| Badge | Statuses (severity order) | Source checks |
|-------|--------------------------|---------------|
| template | PASS < WARN (EXTRA sections) < DRIFT (missing field/section) < MISSING (required artifact absent) | Check 1 (Step 16) |
| lifecycle | PASS < WARN (child closed, parent open) < LIFECYCLE_INCONSISTENT (parent closed + child open) | Check 2 (Step 17) |
| traceability | PASS < INFO (P1/P2 untested) < UNTESTED (P0 untested) | Check 3 (Step 18) |

Each badge for a node shows the **worst** (highest severity) status from its category.

For work item types that don't participate in a check (e.g., tasks have no traceability check because they lack PRD/TEST-SPEC): show "—" for that badge.

The `[STRAY]` flag from Check 4 (Step 19) is not a per-node badge; it appears in the Findings list only.

## Step 21: Tree Report

After all checks complete, emit a unified tree view. Walk `work-items/` depth-first, sorting siblings alphabetically by slug at each level.

```
WORK ITEM TREE:
  features/
    F000001_workflow_alpha (feature) [Closed]
      template: PASS  lifecycle: PASS  traceability: PASS
      S000001_workflow_implementation (user-story) [Closed]
        template: PASS  lifecycle: PASS  traceability: PASS
        T000001_implement_workflow (task) [Closed]
          template: PASS  lifecycle: PASS  traceability: —

    F000002_system_health_v1 (feature) [Closed]
      template: PASS  lifecycle: PASS  traceability: PASS

  defects/
    D000001_milestones_artifact_placement (defect) [Closed]
      template: PASS  lifecycle: PASS  traceability: —
```

Type subfolders (`features/`, `defects/`, `reviews/`) are rendered as grouping headers in the tree. They are not work items and have no badges.

For each node:
- Line 1: `{indent}{slug} ({type}) [{state}]`
- Line 2: `{indent}  template: {badge}  lifecycle: {badge}  traceability: {badge}`

Indent is 2 spaces per nesting level from work-items root.

## Step 22: Graph Artifact

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
      "state": "Closed",
      "path": "work-items/features/F000001_workflow_alpha",
      "parent": null,
      "children": ["S000001"],
      "badges": {
        "template": "PASS",
        "lifecycle": "PASS",
        "traceability": "PASS"
      }
    }
  ],
  "edges": []
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

**Top-level fields:**
- `edges`: empty array (reserved for dependency graph v2)
- `generated_commit`: output of `git rev-parse --short HEAD 2>/dev/null` or "unknown"

If `.docs/` write fails: print `[WARN] Could not write to .docs/: {error}` and continue.
Console output is always emitted regardless of file write success.

Print: "Graph artifact written to .docs/work-item-graph.json"

## Step 23: Human-Readable Report

After all checks complete, write a human-readable markdown report to `.docs/work-item-report.md`.

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
{exact same tree visualization from Step 21}
```

## Badge Summary

| Item | Type | State | Template | Lifecycle | Traceability |
|------|------|-------|----------|-----------|--------------|
| {slug} | {type} | {state} | {badge} | {badge} | {badge} |
````

One row per work item, in tree order (depth-first, alphabetical siblings).

```markdown
## Findings

### Critical
{list all LIFECYCLE_INCONSISTENT, MISSING findings}

### Warnings
{list all DRIFT, UNTESTED, STRAY findings}

### Advisory
{list all INFO, EXTRA, WARN findings}
```

If no findings exist in a severity category, omit that subsection. If no findings at all, write: "No issues found."

```markdown
## Structural Summary

- **Items:** {N} total ({N} features, {N} user-stories, {N} tasks, {N} defects)
- **Lifecycle issues:** {N}
- **Stray directories:** {N}
```

If `.docs/` write fails: print `[WARN] Could not write report to .docs/: {error}` and continue.

Print: "Report written to .docs/work-item-report.md"

## Error Messages

- **Not a git repo:** "Error: /personal-workflow requires a git repository."
- **Skill assets not found:** "Error: personal-workflow skill assets not found."
- **Target path not found:** "Error: path not found: {path}"
- **Not a tracker file:** "Warning: {path} does not look like a tracker file. Contract checks may produce false positives."
- **No work-items/:** "INFO: no work-items/ directory found. Skipping tree walk, graph artifact, and report generation."
- **No manifest:** "Error: personal-artifact-manifests.json not found or invalid."
- **Template not found (file mode):** "Error: template tracker-{type}.md not found at {_TMPL_DIR} or ~/.claude/templates/personal-workflow/. Run skills-deploy install."
- **Template not found (directory/tier-2 mode):** "Warning: template {filename} not found. Skipping validation for this artifact."
- **Unknown type:** "VIOLATION: unknown type \"{value}\" in {path}"
- **Unparseable frontmatter:** "Warning: could not parse frontmatter in {path}. Skipping."
- **Write failure:** "[WARN] Could not write to .docs/: {error}"
