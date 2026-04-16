---
name: personal-workflow-guide
description: "Doc-driven development workflow, scaffolding conventions, and installation guide for the personal-workflow skill."
type: workflow
version: 1.0.0
---

## Doc-Driven Development Workflow

This skill enables a 3-step doc-driven development approach. Documents are
first-class artifacts, not afterthoughts. The `check` command enforces structural
compliance at every step.

### Step 1: Generate Initial Docs

The engineer gives the AI the big picture. The AI generates work item documents
using templates from `templates/personal-workflow/`.

For each work item type, the AI reads the template for structure:

- Feature: tracker + milestones (2 artifacts)
- User-story: tracker + PRD + ARCHITECTURE + TEST-SPEC (4 artifacts)
- Task: tracker + test-plan (2 artifacts)
- Defect: tracker + RCA + test-plan (3 artifacts)

The full type-to-artifact mapping is in `personal-artifact-manifests.json`.

After generation, run `/personal-workflow check` to ensure the docs meet the
structural contract (required fields, section order, lifecycle phases).

### Step 2: Align the Big Picture

The engineer works on the docs to align the big picture with reality:

- Refine acceptance criteria in trackers
- Flesh out PRD user stories and acceptance criteria
- Make architecture decisions and record tradeoffs
- Map test cases to requirements in TEST-SPEC
- Adjust milestones and dependency graphs

Run `/personal-workflow check` iteratively during this step.

### Step 3: Implement and Iterate

Implementation follows the aligned docs. For each task:

1. Read the parent user story's PRD and ARCHITECTURE for context
2. Implement according to the architecture decisions
3. Run `/personal-workflow check` on modified docs after updates
4. Update tracker: move through lifecycle phases, add journal entries
5. Verify against TEST-SPEC criteria

## Scaffolding Conventions

### Type-to-Artifact Mapping

Each work item type requires specific artifacts. See `personal-artifact-manifests.json`
for the canonical mapping. Summary:

| Type | Artifacts | Count |
|------|-----------|-------|
| feature | TRACKER, milestones | 2 |
| user-story | TRACKER, PRD, ARCHITECTURE, TEST-SPEC | 4 |
| task | TRACKER, test-plan | 2 |
| defect | TRACKER, RCA, test-plan | 3 |

Note: `userstory` (no hyphen) is accepted as an alias for `user-story`.

### Branch Naming

Branch naming determines work item type:
- `feature-*` or `feat-*` or `feat/*` -> feature
- `defect-*` or `fix-*` or `fix/*` or `bugfix-*` -> defect
- `task-*` or `chore-*` or `chore/*` -> task
- `story-*` -> user-story

### ID Generation

IDs use the format `{TYPE_PREFIX}{NNNNNN}`:

| Type | Prefix | Example |
|------|--------|---------|
| feature | F | F000001 |
| user-story | S | S000001 |
| task | T | T000001 |
| defect | D | D000001 |

Increment from the highest existing ID of that type in `work-items/`.

### Directory Layout

```
work-items/
  features/{slug}/
    {ID}_TRACKER.md
    {ID}_{artifact}.md
    {child-slug}/              # nested: feature > user-story > task, max depth 3
      {ID}_TRACKER.md
      {ID}_{artifact}.md
  defects/{slug}/
    {ID}_TRACKER.md
    {ID}_{artifact}.md
```

All artifact filenames are prefixed with the item ID at scaffold time.

### Placeholder Replacement

When generating docs from templates, replace these placeholders:

| Placeholder | Value |
|-------------|-------|
| `{ITEM_NAME}` | Human-readable name of the work item |
| `{ITEM_ID}` | Generated ID (e.g., F000001) |
| `{PARENT_ID}` | Parent work item ID (for nested items) |
| `{FEATURE_ID}` | Top-level feature ID |
| `{YYYY-MM-DD}` | Current date |
| `{BRANCH_NAME}` | Current git branch |
| `{author}` | Current user (from `whoami` or git config) |

### Lifecycle

The personal-workflow spec uses a 3-phase lifecycle:

1. **Track** -- scope the work, scaffold docs, define acceptance criteria
2. **Implement** -- write code, update trackers, commit changes
3. **Ship** -- create PR, run `/personal-workflow check`, merge, deploy

Each tracker template has lifecycle gates (checkboxes) for each phase.

### Updating Work Items

When updating a work item, check git log for commits since merge-base with main:
`git merge-base main HEAD` -> BASE, then `git log --oneline $BASE..HEAD`.

Group commits into journal entry categories:
- fix/debug/investigate -> finding
- decide/choose/switch -> decision
- other -> implementation

Propose journal entries with commit SHAs. Ask before adding.

### Validation Rules

When scaffolding or reviewing work items, validate:
- Each doc has YAML frontmatter with required fields per its template
- Required sections (`##` headers) from the template exist in the instance
- For user-stories: PRD user stories have corresponding TEST-SPEC entries

Warn on missing sections. Never auto-fix without asking.

## Using check and tree

### check (full validation)

```
/personal-workflow check                    # full work-items/ scan
/personal-workflow check work-items/features/F000001/F000001_TRACKER.md   # single file
/personal-workflow check work-items/features/F000001/                     # single directory + hierarchy
```

### tree (quick hierarchy view)

```
/personal-workflow tree                     # structural view with badges
```

## Installation

Install the complete skill package on any machine:

```bash
# From the workbench repo (recommended):
scripts/skills-deploy install

# Or copy manually:
cp -r skills/personal-workflow/ ~/.claude/skills/personal-workflow/
cp -r templates/personal-workflow/ ~/.claude/templates/personal-workflow/
```

### What Gets Deployed

```
~/.claude/skills/personal-workflow/
    SKILL.md                          # check + tree commands
    WORKFLOW.md                       # this file (scaffolding + workflow)
    contract.json                     # structural validation rules
    personal-artifact-manifests.json  # type-to-artifact mapping
    check.md                          # full validation logic
    tree.md                           # hierarchy view
    fixtures/                         # test fixtures

~/.claude/templates/personal-workflow/
    tracker-*.md                      # 4 tracker templates
    doc-*.md                          # 6 doc templates
```

### Path Resolution

2-level fallback chain. Works in the workbench repo and on deployed machines:

```
Level 1: $REPO_ROOT/skills/personal-workflow/     (workbench)
Level 2: ~/.claude/skills/personal-workflow/       (deployed)
```

Templates resolve the same way: `$REPO_ROOT/templates/personal-workflow/` then
`~/.claude/templates/personal-workflow/`.

Note: The previous 3-level chain with `~/.claude/spec/templates/` is no longer
supported. Templates at that path will not be found.
