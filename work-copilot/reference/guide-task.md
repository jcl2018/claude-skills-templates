# Task Tracker Generation Guide

How to pre-populate a new task tracker from the template.

## When to generate

When a new task is created via `the work-track child-items command` under a feature or
user-story parent. Tasks are always children, never top-level work items.

## Sources (in priority order)

1. **Parent work item** — read the parent tracker for scope context, existing
   children, cross-cutting concerns, and timeline
2. **User-provided description** — from the create command's natural language input
3. **Ticket URL** — if a TFS/Jira URL is provided AND the network allows it,
   extract the ticket title and description. Do not depend on network access.
4. **Git state** — infer repo path and branch name from current git context

## Steps

### 1. Fill frontmatter

- `name`: from the user's description or ticket title
- `type`: always `task`
- `workflow_type`: always `task`
- `id`: from the user's input (e.g., T1286554) or generated slug
- `status`: `active`
- `created`: today
- `updated`: today
- `url`: from the user's input, or blank
- `parent`: the parent work item's ID (required, never blank)
- `repo`: from `git rev-parse --show-toplevel` or user input
- `branch`: from `git branch --show-current` or user input, or blank
- `blocked_by`: blank

### 2. Todos section

Populate with actionable items extracted from:
- Parent tracker's scope description for this task
- User's natural language input
- Known sub-tasks from the ticket URL (if available)

If no specific items are available, leave the placeholder.

### 3. Log section

Add a creation entry:
```
- {today}: Created. {brief scope summary from parent or user input}
```

### 4. Files section

If the parent tracker or user input mentions specific files or modules,
pre-populate. Otherwise leave empty (the Phase 1 exit criterion will prompt
the user to populate it).

### 5. Sections to leave blank

- **PRs** — populated when PRs are created
- **Insights** — populated during work
- **Journal** — populated by `the work-track journal command` or nudge triggers

### 6. Lifecycle

Do not modify the lifecycle section. It ships as-is from the template.
The exit criteria are fixed, not task-specific.

#### Ship Gates

Phase 5 includes four pre-submit quality gates before PR creation:

| Gate | What it checks | When to mark |
|------|---------------|-------------|
| Linux branch build passes | Code compiles on Linux | After successful build |
| Regression tests pass | Regression suite passes | After test run |
| Code review completed | Peer review done | After reviewer approval |
| PR description generated | PR description written | Before PR creation |

These gates are checked by /work-ship before proceeding to /ship. If gates
are unchecked, /work-ship warns and offers an override. Overrides are
recorded in the work item journal.

**Example, completed Phase 5:**

```markdown
### Phase 5: Ship
- [x] Linux branch build passes
- [x] Regression tests pass
- [x] Code review completed (reviewer noted in Journal)
- [x] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch
```

### 7. Validation

After generation, verify:
- [ ] `parent` field is populated (never blank for tasks)
- [ ] `name` field is populated (not a placeholder)
- [ ] Log has a creation entry with today's date
- [ ] No placeholder text like `{TASK_NAME}` remains in filled sections
- [ ] Lifecycle section has all 6 phases with exit criteria intact

## Offline requirement

All generation must work without network access. If a ticket URL is provided,
attempt to fetch it but do not fail if the network is unavailable. Note
"Ticket details not fetched (network unavailable)" and proceed.
