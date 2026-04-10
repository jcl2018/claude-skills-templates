---
name: work-ship
description: "Phase 4: ship wrapper. Validates TEST-SPEC acceptance criteria, writes journal entry, delegates to gstack /ship."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# /work-ship — Phase 4: Ship

Thin wrapper around gstack `/ship`. Adds spec validation gates, journal tracking,
and work item status updates.

## Step 1: Load context

1. Resolve work item from branch (same as /work router)
2. Read the tracker: name, type, status, current phase
3. Read TEST-SPEC.md if it exists (for acceptance criteria validation)

## Step 2: Validate acceptance criteria

If TEST-SPEC.md exists:
- Read the Test Matrix section
- For each P0 test case, check if the expected result is achievable:
  - Run Tier 1 smoke test commands if specified
  - For Tier 2 (manual), list them for the user to confirm

If validation fails:
- Write to tracker Journal:
  ```
  ### {date} — ship-blocked
  Ship blocked. Failing criteria: {list of failing test cases}
  ```
- Update handoff: `<!-- HANDOFF: phase=ship status=blocked reason=spec-validation -->`
- Tell user: "Ship blocked by failing acceptance criteria. Fix these, then re-run /work-ship."
- **Stop.** Do not proceed to /ship.

If no TEST-SPEC.md exists:
- Warn: "No TEST-SPEC.md found. Shipping without spec validation."
- Proceed.

## Step 3: Check Ship sub-gates

Read the tracker's Phase 4 (Ship) lifecycle checkboxes. Warn about any unchecked items:
```
Advisory: These Ship sub-gates are not checked:
- [ ] Tests pass
- [ ] Code review completed
Continue anyway?
```

This is advisory only. The user can proceed.

## Step 4: Journal entry

Write to the tracker's Journal section:
```
### {date} — ship
Entering ship phase. Spec validation: {passed/skipped/N-A}.
```

## Step 5: Delegate to /ship

Invoke gstack `/ship` using the Skill tool:
```
Skill: ship
```

The upstream skill handles PR creation, VERSION bump, CHANGELOG update, commit,
push, and PR submission.

## Step 6: Capture outcome

After /ship completes:
- Write to tracker Journal:
  ```
  ### {date} — shipped
  PR created: {PR URL}. Status: {merged/open}.
  ```
- Update PRs section in tracker with the PR link
- Mark Phase 4 sub-gates as complete
- Update handoff: `<!-- HANDOFF: phase=ship status=complete -->`
- If the user wants to close the work item: suggest `/work-track close`

## Rules

- **Spec validation gates shipping.** If TEST-SPEC P0 tests fail, do not ship.
- **Always delegate to /ship.** The ship logic lives upstream.
- **Journal every ship attempt.** Pass or fail, the outcome goes in the tracker.
- **Advisory sub-gate warnings.** Unchecked lifecycle items warn but don't block.
