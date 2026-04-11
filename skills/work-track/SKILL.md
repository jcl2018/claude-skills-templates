---
name: work-track
description: "Context-aware work item management: evidence synthesis, CRUD, lifecycle, manifest-driven scaffolding."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /work-track — Work Item Management

Phase 1 skill. Owns all work item document operations: scaffolding, evidence synthesis,
CRUD (create/update/close), lifecycle management (journal, milestones, list, scrum).

## Subcommands

Detect the subcommand from the user's input:
- `/work-track create` — scaffold a new work item
- `/work-track` (no subcommand) — evidence synthesis for current work item
- `/work-track journal` — add a manual journal entry
- `/work-track milestones` — CRUD milestone entries
- `/work-track list` — list all work items with status and risk badges
- `/work-track close` — close a work item
- `/work-track scrum` — generate scrum notes from milestones + git + journal
- `/work-track child-items` — create sub-tasks under a feature (max depth 3)

## Create Subcommand

### Resolve paths

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
WORK_DIR="$REPO_ROOT/work-items"
BRANCH=$(git branch --show-current 2>/dev/null)
echo "REPO_ROOT: $REPO_ROOT"
echo "WORK_DIR: $WORK_DIR"
echo "BRANCH: $BRANCH"
```

### Parse arguments

Extract from user input:
- `--type` or `-t`: feature | defect | task | user-story | review (required)
- `--slug` or `-s`: work item slug (default: derived from branch name)
- `--parent`: parent work item ID (required for user-story and task types)

If type not provided, ask via AskUserQuestion.

### Read artifact manifest

```bash
MANIFEST=~/.claude/artifact-manifests.json
[ -f "$MANIFEST" ] && echo "MANIFEST_FOUND" || echo "NO_MANIFEST"
```

If manifest found, read it and extract the required/optional artifacts for the given type.
If manifest not found, fall back to hardcoded defaults:
- feature: TRACKER.md, PRD.md, ARCHITECTURE.md, TEST-SPEC.md, milestones.md
- defect: TRACKER.md, RCA.md, test-plan.md
- task: TRACKER.md, test-plan.md
- user-story: TRACKER.md, PRD.md, ARCHITECTURE.md, TEST-SPEC.md, milestones.md
- review: TRACKER.md, review-notes.md

### Validate templates exist

```bash
TEMPLATE_DIR=~/.claude/spec/templates
for t in tracker-feature.md tracker-defect.md tracker-task.md tracker-review.md tracker-user-story.md doc-PRD.md doc-ARCHITECTURE.md doc-TEST-SPEC.md doc-RCA.md doc-review-notes.md doc-milestones.md doc-test-plan.md; do
  [ -f "$TEMPLATE_DIR/$t" ] && echo "OK: $t" || echo "MISSING: $t"
done
```

If any required template is missing, report the error and stop. Do not scaffold with missing templates.

### Create work item directory

```bash
ITEM_DIR="$WORK_DIR/{slug}"
mkdir -p "$ITEM_DIR"
echo "Created: $ITEM_DIR"
```

### Scaffold artifacts

For each required artifact in the manifest:
1. Read the template from `$TEMPLATE_DIR/{template}`
2. Replace frontmatter placeholders:
   - `{ITEM_NAME}` → work item name (from user input or slug)
   - `{ITEM_ID}` → slug
   - `{PARENT_ID}` → parent ID (or empty for top-level)
   - `{FEATURE_ID}` → feature ID (slug for features, parent's ID for stories)
   - `{YYYY-MM-DD}` → today's date
   - `{BRANCH_NAME}` → current branch
   - `{author}` → output of `whoami`
3. Apply lifecycle overrides from manifest (replace Phase sub-gates if specified)
4. Write to `$ITEM_DIR/{filename}`
5. If generation guides exist at `~/.claude/spec/reference/guide-*.md`, read the relevant one
   for type-specific instructions and pre-populate content using the user's description
   (Problem Statement for PRD, etc.). Fall back to `~/.claude/templates/GENERATION-GUIDE.md` if present.

### Post-scaffold

After all artifacts are created:
- Add a Log entry: `- {date}: Created. {brief description}`
- Report what was created:
  ```
  Work item created: {slug}
  Type: {type}
  Directory: {ITEM_DIR}
  Artifacts: {list of files created}
  
  Next: Run /work-implement to start building.
  ```

## Evidence Synthesis (default subcommand)

When `/work-track` runs without a subcommand on a branch with an active work item:

1. Resolve the work item from the branch (same as /work router)
2. Get recent git history scoped to this branch:
   ```bash
   BASE=$(git merge-base main HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null)
   git log --oneline "$BASE"..HEAD 2>/dev/null
   ```
3. Group commits by type (decision, finding, implementation):
   - Commits mentioning "fix", "debug", "investigate" → finding
   - Commits mentioning "decide", "choose", "switch to" → decision  
   - All other commits → implementation
4. Propose journal entries (one per group) referencing actual commit SHAs
5. Present proposed entries via AskUserQuestion: "Add these journal entries?"
6. If approved, append to the Journal section of the tracker

## Journal Subcommand

Add a manual journal entry to the current work item's tracker.

Ask via AskUserQuestion:
- Type: decision | finding | blocker
- Summary: one-line description

Format and append:
```
### {date} — {type}
{summary}
```

## Milestones Subcommand

CRUD operations on milestone entries in the work item.
Read milestones.md if it exists, otherwise create it.

## List Subcommand

Scan `$WORK_DIR/` for all TRACKER.md files. For each:
- Read frontmatter: name, type, status, created, updated
- Calculate risk badges based on dates:
  - Past target date → OVERDUE
  - Within 3 days → URGENT  
  - Within 7 days → AT RISK

Display as a table:
```
| # | Name | Type | Status | Branch | Risk | Updated |
```

## Close Subcommand

1. Read the current work item's tracker
2. Set `status: done` in frontmatter
3. Add `closed: {date}` to frontmatter
4. Add Log entry: `- {date}: Closed.`
5. If `$WORK_DIR/INDEX.md` exists, regenerate it (remove from active list)

## Scrum Subcommand

Generate scrum meeting notes from:
- Milestones (progress + blockers)
- Git activity since last scrum (commits, files changed)
- Journal entries since last scrum

Write to `$ITEM_DIR/scrum-{date}.md`.

## Child Items Subcommand

Create sub-items under a feature work item:
- Maximum depth: 3 (feature → user-story → task)
- Child directory: `$ITEM_DIR/{child-slug}/`
- Child tracker references parent via `parent` frontmatter field
- Register child in parent tracker's Todos section

## Rules

- **Manifest-driven scaffolding.** Always read artifact-manifests.json first. Fall back to hardcoded defaults only if manifest is missing.
- **Template validation.** Check template files exist before scaffolding. Fail loudly if missing.
- **No code modification.** This skill manages work item documents only.
- **Evidence requires approval.** Never commit proposed journal entries without user confirmation.
- **Handoff block.** After completing any operation, write a handoff block to the tracker:
  ```
  <!-- HANDOFF: phase=track status=complete next=/work-implement -->
  ```
