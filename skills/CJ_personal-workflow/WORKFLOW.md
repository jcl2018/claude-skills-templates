---
name: CJ_personal-workflow-guide
description: "Doc-driven development workflow, scaffolding conventions, and installation guide for the CJ_personal-workflow skill."
type: workflow
version: 1.0.0
---

## Doc-Driven Development Workflow

This skill enables a 3-step doc-driven development approach. Documents are
first-class artifacts, not afterthoughts. The `check` command enforces structural
compliance at every step.

### Step 1: Generate Initial Docs

The engineer gives the AI the big picture. The AI generates work item documents
using templates from `templates/CJ_personal-workflow/`.

For each work item type, the AI reads the template for structure:

- Feature: tracker + DESIGN + ROADMAP (3 artifacts)
- User-story: tracker + DESIGN + SPEC + TEST-SPEC (4 artifacts)
- Task: tracker + test-plan (2 artifacts)
- Defect: tracker + RCA + test-plan (3 artifacts)

The full type-to-artifact mapping is in `personal-artifact-manifests.json`.

After generation, run `/CJ_personal-workflow check` to ensure the docs meet the
structural rules. The validator derives those rules from the templates at
runtime (required fields, section order, lifecycle phases, minimum checkbox
count). Templates are the single source of truth.

### Step 2: Align the Big Picture

The engineer works on the docs to align the big picture with reality:

- Refine acceptance criteria in trackers
- Flesh out SPEC requirements and acceptance criteria
- Make architecture decisions and record tradeoffs in SPEC
- Map test cases to requirements in TEST-SPEC
- Adjust ROADMAP delivery timeline and decomposition

Run `/CJ_personal-workflow check` iteratively during this step.

### Step 3: Implement and Iterate

Implementation follows the aligned docs. For each task:

1. Read the parent user story's SPEC for context
2. Implement according to the architecture decisions
3. Run `/CJ_personal-workflow check` on modified docs after updates
4. Update tracker: move through lifecycle phases, add journal entries
5. Verify against TEST-SPEC criteria

## Scaffolding Conventions

### Type-to-Artifact Mapping

Each work item type requires specific artifacts. See `personal-artifact-manifests.json`
for the canonical mapping. Summary:

| Type | Artifacts | Count |
|------|-----------|-------|
| feature | TRACKER, DESIGN, ROADMAP | 3 |
| user-story | TRACKER, DESIGN, SPEC, TEST-SPEC | 4 |
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

### Hierarchy & Placement

When scaffolding a work item, the generating AI must also scaffold its required
children in the same operation. Structural completeness is enforced at scaffolding
time by the AI reading this spec, not by a separate validator or scaffolder script.
This matches the D000007 philosophy: templates + WORKFLOW.md are the source of
truth; the AI reads them and follows them.

**Required children (scaffold these alongside the parent):**

- **feature** -> at least 1 user-story child
- **user-story** -> tasks are OPTIONAL; scaffold only when scope warrants further decomposition (e.g., parallel sub-units, multiple distinct file groups, or work spanning > ~5 components). A simple user-story whose work is one cohesive change can ship without any task children — record the choice with a checked Phase 1 gate `[x] Tasks broken down (N/A — atomic story)`.
- **task, defect** -> no required children

**Placement rules:**

| Type | Location |
|------|----------|
| feature | `work-items/features/{ID}_{slug}/` |
| defect | `work-items/defects/{ID}_{slug}/` |
| user-story | nested under a feature: `work-items/features/{feature-ID}_{slug}/{ID}_{slug}/` |
| task | nested under a user-story |

**Directory naming rule:** every work-item directory must be `{ID}_{slug}/` where:
- `{ID}` matches the type prefix (F/S/T/D) + 6 digits (e.g., `F000003`)
- `{slug}` matches `[a-z0-9_-]+` (lowercase, no spaces or capitals)
- The `{ID}` inside the directory name must match the `id` field in the TRACKER
  frontmatter

**Common mistakes to avoid:**

- Creating `work-items/features/F000003_my-feature/` with no child user-story directory
- Creating a user-story at `work-items/user-stories/` (they always nest under a feature)
- Using bare slugs like `work-items/features/my-feature/` without the ID prefix
- Mismatching the ID in the directory name vs. the ID in the TRACKER frontmatter

**Legacy directories:** if you encounter an existing bare-slug directory (e.g.,
`work-items/features/my-feature/` without an ID prefix), treat it as legacy. Don't
auto-rename. Flag it to the user and let them decide whether to migrate.

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

The CJ_personal-workflow spec uses a 3-phase lifecycle:

1. **Track** -- scope the work, scaffold docs, define acceptance criteria
2. **Implement** -- write code, update trackers, commit changes
3. **Ship** -- create PR, run `/CJ_personal-workflow check`, merge, deploy

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
- For user-stories: SPEC requirements have corresponding TEST-SPEC entries

Warn on missing sections. Never auto-fix without asking.

## Using check

```
/CJ_personal-workflow check                    # full work-items/ scan
/CJ_personal-workflow check work-items/features/F000001/F000001_TRACKER.md   # single file
/CJ_personal-workflow check work-items/features/F000001/                     # single directory
```

## Installation

Install the complete skill package on any machine:

```bash
# From the workbench repo (recommended):
scripts/skills-deploy install

# Or copy manually:
cp -r skills/CJ_personal-workflow/ ~/.claude/skills/CJ_personal-workflow/
cp -r templates/CJ_personal-workflow/ ~/.claude/templates/CJ_personal-workflow/
```

### What Gets Deployed

```
~/.claude/skills/CJ_personal-workflow/
    SKILL.md                          # check command
    WORKFLOW.md                       # this file (scaffolding + workflow)
    personal-artifact-manifests.json  # type-to-artifact mapping
    check.md                          # full validation logic (template-derived rules)
    fixtures/                         # test fixtures

~/.claude/templates/CJ_personal-workflow/
    tracker-*.md                      # 4 tracker templates
    doc-*.md                          # 6 doc templates
```

### Path Resolution

2-level fallback chain. Works in the workbench repo and on deployed machines:

```
Level 1: $REPO_ROOT/skills/CJ_personal-workflow/     (workbench)
Level 2: ~/.claude/skills/CJ_personal-workflow/       (deployed)
```

Templates resolve the same way: `$REPO_ROOT/templates/CJ_personal-workflow/` then
`~/.claude/templates/CJ_personal-workflow/`.

Note: The previous 3-level chain with `~/.claude/spec/templates/` is no longer
supported. Templates at that path will not be found.
