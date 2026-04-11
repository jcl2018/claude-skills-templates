# Work item templates

When creating work items, use templates from the first directory found:
`templates/` (repo root) -> `~/.claude/spec/templates/` -> `~/.claude/templates/`

Type-aware scaffolding (each type gets a different set of artifacts):
- **feature**: tracker-feature.md + doc-PRD.md + doc-ARCHITECTURE.md + doc-TEST-SPEC.md + doc-milestones.md
- **defect**: tracker-defect.md + doc-RCA.md + doc-test-plan.md
- **task**: tracker-task.md + doc-test-plan.md
- **user-story**: tracker-user-story.md + doc-PRD.md + doc-ARCHITECTURE.md + doc-TEST-SPEC.md + doc-milestones.md

Branch naming determines work item type:
- `feature-*` or `feat-*` or `feat/*` -> feature
- `defect-*` or `fix-*` or `fix/*` or `bugfix-*` -> defect
- `task-*` or `chore-*` or `chore/*` -> task
- `story-*` -> user-story

Directory structure:
```
work-items/{slug}/
  TRACKER.md          (required, from tracker-{type}.md template)
  {artifact}.md       (per type, from doc-{name}.md templates)
  {child-slug}/       (nested for parent > child: feature > user-story > task, max depth 3)
```

When scaffolding, replace these placeholders in templates:
`{ITEM_NAME}`, `{ITEM_ID}`, `{PARENT_ID}`, `{FEATURE_ID}`, `{YYYY-MM-DD}`, `{BRANCH_NAME}`, `{author}`

ID generation: `{TYPE_PREFIX}{NNNNNN}` where prefix is F (feature), S (user-story),
T (task), D (defect). Number increments from the highest existing ID of that type
in `work-items/`. Example: if F000001 exists, next feature is F000002.

When updating a work item, check git log for commits since merge-base with main:
`git merge-base main HEAD` -> BASE, then `git log --oneline $BASE..HEAD`.
Group commits: fix/debug/investigate -> finding, decide/choose/switch -> decision, other -> implementation.
Propose journal entries with commit SHAs. Ask before adding.

When scaffolding or reviewing work items, validate:
- Each doc has YAML frontmatter with required fields per its template
- Required sections (`##` headers) from the template exist in the instance
- For features/user-stories: PRD user stories have corresponding TEST-SPEC entries
Warn on missing sections. Never auto-fix without asking.
