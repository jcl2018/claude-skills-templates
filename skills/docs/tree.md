# /docs tree — Work Item Hierarchy View

Quick tree view of the work item hierarchy with structural completeness badges.
Runs only structural checks (no staleness, coherence, template, lifecycle, or traceability checks).

## Step 1: Locate Work Items

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
WORK_ITEMS_DIR="$REPO_ROOT/work-items"
[ -d "$WORK_ITEMS_DIR" ] && echo "FOUND: $WORK_ITEMS_DIR" || echo "NO_WORK_ITEMS"
```

**If NO_WORK_ITEMS:** Print "No work-items/ directory found." and stop.

## Step 2: Load Manifest + Hierarchy

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
MANIFEST="$REPO_ROOT/artifact-manifests.json"
[ -f "$MANIFEST" ] && echo "FOUND: $MANIFEST" || echo "NO_MANIFEST"
```

**If NO_MANIFEST:** Print "Warning: artifact-manifests.json not found. Showing tree without structural checks." and continue to Step 3 (tree renders but structure badge shows "—").

Read artifact-manifests.json. Extract the `hierarchy` field.

**If `hierarchy` missing or malformed:** Print "Warning: no hierarchy rules found. Showing tree without structural checks." and continue (structure badge shows "—").

Also read the `placement` field if present. If missing, use defaults:
```
feature: root, defect: root, user-story: feature, task: user-story
```

## Step 3: Build Work Item Model

Walk `./work-items/` recursively (max depth 3 from work-items root).

For each directory containing a TRACKER.md file (with or without ID prefix):

1. Read the TRACKER.md file
2. If YAML frontmatter cannot be parsed: warn "Warning: could not parse frontmatter in {path}. Skipping this work item." and skip
3. Parse YAML frontmatter, extract `type` field
4. Normalize type spelling (remove hyphens for comparison, display hyphenated)
5. Determine parent (directory nesting) and children (subdirectories with TRACKER.md)
6. Determine state from lifecycle checkboxes:
   - All `- [ ]` = Open
   - Mix of `- [x]` and `- [ ]` = In Progress
   - All `- [x]` = Closed

## Step 4: Structural Check (if hierarchy available)

If hierarchy rules were loaded in Step 2:

For each work item:
1. Look up type in hierarchy rules
2. If type has `required_child`: count children of that type
   - If count == 0: structure badge = INCOMPLETE
   - If count >= min: structure badge = PASS
3. Check placement rules. If item is at wrong level: structure badge = MISPLACED (takes precedence over INCOMPLETE)
4. If type has no hierarchy entry: structure badge = PASS

If hierarchy rules were NOT loaded: structure badge = "—" for all nodes.

## Step 5: Render Tree

Walk depth-first, sorted alphabetically by slug at each level.

```
=== /docs tree ===

WORK ITEM TREE:
  F000001_workflow_alpha (feature) [In Progress]  completeness: 3/1 user-story
    template: —  lifecycle: —  traceability: —  structure: PASS
    S000001_four_phase (user-story) [In Progress]  completeness: 1/1 task
      template: —  lifecycle: —  traceability: —  structure: PASS
      T000001_router_implementation (task) [Open]
        template: —  lifecycle: —  traceability: —  structure: PASS
    S000002_template_consolidation (user-story) [In Progress]  completeness: 0/1 task
      template: —  lifecycle: —  traceability: —  structure: INCOMPLETE (0 task children)
    S000003_structural_completeness (user-story) [In Progress]  completeness: 1/1 task
      template: —  lifecycle: —  traceability: —  structure: PASS
      T000002_implement_structural_check (task) [Open]
        template: —  lifecycle: —  traceability: —  structure: PASS

  F000002_system_health_v1 (feature) [Open]  completeness: 0/1 user-story
    template: —  lifecycle: —  traceability: —  structure: INCOMPLETE (0 user-story children)

TREE SUMMARY: {N} items, {N} incomplete, {N} misplaced
```

Non-structural badges (template, lifecycle, traceability) always show "—" in `/docs tree`.
For full badges, run `/docs check`.
