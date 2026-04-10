---
name: work
description: "Work item router: auto-detect from branch, show menu, suggest phase skill. No mutations."
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# /work — Work Item Router

Thin router that detects the current work item from the branch name and offers the
right phase skill. This skill never mutates state. All mutations happen in phase skills.

## Branch Detection

Detect the current branch and extract a work item slug:

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $BRANCH"
```

Match against these patterns (personal-native, no PRODUCT patterns):
- `feature-*` or `feat-*` or `feat/*` → type=feature, slug=remainder
- `defect-*` or `fix-*` or `fix/*` or `bugfix-*` → type=defect, slug=remainder
- `review-*` → type=review, slug=remainder
- `task-*` or `chore-*` or `chore/*` → type=task, slug=remainder
- `story-*` → type=user-story, slug=remainder

If no pattern matches, tell the user: "Branch `{BRANCH}` doesn't match a work item
pattern. Create a work item with `/work-track create` or switch to a matching branch."

## Work Item Resolution

Once a slug is extracted, look for an existing work item:

```bash
WORK_DIR=$(git rev-parse --show-toplevel 2>/dev/null)/work-items
[ -d "$WORK_DIR" ] && echo "WORK_DIR: $WORK_DIR" || echo "NO_WORK_DIR"
```

If WORK_DIR exists, search for a matching tracker:
```bash
find "$WORK_DIR" -name "TRACKER.md" -path "*${SLUG}*" 2>/dev/null | head -5
```

If found, read the tracker's frontmatter to get: name, type, status, phase progress.

If not found, offer to create one:
"No work item found for `{SLUG}`. Create one with `/work-track create --type {detected_type} --slug {SLUG}`"

## Phase Detection

Read the tracker's Lifecycle section. Check which phases have all checkboxes checked:
- Phase 1 (Track): all `- [x]` → Track complete
- Phase 2 (Implement): all `- [x]` → Implement complete
- Phase 3 (Review): all `- [x]` → Review complete
- Phase 4 (Ship): all `- [x]` → Ship complete

**Backward compatibility:** Treat `- [x] Investigate` the same as `- [x] Implement`.

Determine the current phase (first incomplete phase) and suggest the right skill.

## Menu Display

Present the work item status and available actions via AskUserQuestion:

```
Work Item: {name}
Type: {type} | Status: {status} | Branch: {BRANCH}
Phase: {current_phase} of 4

Lifecycle:
  ✅ Track    — {complete/incomplete}
  {▶️/✅} Implement — {complete/incomplete}
  {⬜/✅} Review   — {complete/incomplete}
  {⬜/✅} Ship     — {complete/incomplete}
```

Options based on current phase:
- If Track incomplete → "A) /work-track — scaffold artifacts and track progress"
- If Implement is next → "A) /work-implement — build or debug"
- If Review is next → "A) /work-review — code review"
- If Ship is next → "A) /work-ship — ship it"
- Always include: "B) /work-track — update journal, milestones, or close"
- Always include: "C) /system-health --scope — check doc quality"

When the user selects an option, invoke the corresponding skill using the Skill tool.

## No Work Items Directory

If `./work-items/` doesn't exist, this is a project that hasn't used the work pipeline yet.

Tell the user:
"This project doesn't have a work-items/ directory yet. To start using the work pipeline:
1. Run `/work-track create --type feature --slug {SLUG}` to create your first work item
2. The work-items/ directory will be created automatically"

## Rules

- **Never mutate state.** This skill reads only. All writes happen in phase skills.
- **One question at a time.** Present the menu, wait for selection, then invoke.
- **Branch is the key.** The branch name determines which work item is active.
