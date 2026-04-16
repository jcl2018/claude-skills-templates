# /personal-workflow tree — Work Item Hierarchy View

Quick tree view of the work item hierarchy with structural completeness badges.
Runs only structural checks (no template, lifecycle, or traceability checks).

## Step 1: Locate Work Items

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
WORK_ITEMS_DIR="$REPO_ROOT/work-items"
[ -d "$WORK_ITEMS_DIR" ] && echo "FOUND: $WORK_ITEMS_DIR" || echo "NO_WORK_ITEMS"
```

**If NO_WORK_ITEMS:** Print "No work-items/ directory found." and stop.

## Step 2: Load Manifest + Hierarchy

```bash
cat "$_SKILL_DIR/personal-artifact-manifests.json"
```

**If missing or malformed:** Print "Warning: personal-artifact-manifests.json not found. Showing tree without structural checks." and continue to Step 3 (tree renders but structure badge shows "—").

Extract the `hierarchy` field.

**If `hierarchy` missing or malformed:** Print "Warning: no hierarchy rules found. Showing tree without structural checks." and continue (structure badge shows "—").

Also read the `placement` field if present. If missing, use defaults:
```
feature: features, defect: defects, user-story: feature, task: user-story
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
   - All unchecked = Open
   - Mix of checked and unchecked = In Progress
   - All checked = Closed

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
=== /personal-workflow tree ===

WORK ITEM TREE:
  features/
    F000001_workflow_alpha (feature) [Closed]  completeness: 1/1 user-story
      template: —  lifecycle: —  traceability: —  structure: PASS
      S000001_workflow_implementation (user-story) [Closed]  completeness: 1/1 task
        template: —  lifecycle: —  traceability: —  structure: PASS
        T000001_implement_workflow (task) [Closed]
          template: —  lifecycle: —  traceability: —  structure: PASS

  F000002_system_health_v1 (feature) [Closed]  completeness: 0/1 user-story
    template: —  lifecycle: —  traceability: —  structure: INCOMPLETE (0 user-story children)

TREE SUMMARY: {N} items, {N} incomplete, {N} misplaced
```

Non-structural badges (template, lifecycle, traceability) always show "—" in `/personal-workflow tree`.
For full badges, run `/personal-workflow check`.

## Step 6: Lightweight Report

After rendering the tree, write a lightweight report to `.docs/work-item-tree.md`.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
mkdir -p "$REPO_ROOT/.docs"
```

Write `.docs/work-item-tree.md` with this structure:

````markdown
# Work Item Tree

Generated: {ISO-8601 timestamp}
Commit: {short SHA or "unknown"}

```
{exact same tree visualization from Step 5}
```

## Summary

- **Items:** {N} total ({N} features, {N} user-stories, {N} tasks, {N} defects)
- **Incomplete:** {N}
- **Misplaced:** {N}
````

This is the structural-only view. No badge summary table, no findings grouping.
For the full report with all badges and findings, run `/personal-workflow check`.

If `.docs/` write fails: print `[WARN] Could not write tree report` and continue.

Print: "Tree report written to .docs/work-item-tree.md"
