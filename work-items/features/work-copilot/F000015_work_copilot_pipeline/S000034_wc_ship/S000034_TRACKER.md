---
name: "/wc-ship — PR description synthesis"
type: user-story
id: "S000034"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000033"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker
2. Create working branch: `git checkout -b feat/wc_ship`
3. Scaffold work item directory
4. Distill DESIGN.md
5. Scaffold SPEC.md
6. Scaffold TEST-SPEC.md
7. Break into child tasks if needed

**Gates:**
- [x] /office-hours design referenced
- [x] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A)

### Phase 2: Implement

1. Read DESIGN + SPEC
2. Implement
3. Smoke tests
4. `/CJ_personal-workflow check`
5. Update tracker + journal
6. Update Files

**Gates:**
- [ ] Acceptance criteria verified
- [ ] Smoke tests pass
- [ ] Todos current
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Smoke in CI
3. E2E manually
4. Children shipped
5. `/ship`
6. `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — pass
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship`
- [ ] `/land-and-deploy`

## Acceptance Criteria

- [ ] `work-copilot/prompts/ship.prompt.md` exists with `tools: [codebase, search, searchResults, editFiles]`.
- [ ] Prompt calls `/validate` first; aborts on DRIFT/MISSING.
- [ ] Prompt reads tracker + PRD/RCA + existing PR-DESCRIPTION.md template (defect/task only).
- [ ] Prompt synthesizes PR description from tracker journal, AC coverage from `receipts.qa`, commits from `receipts.implement.commits_since_scaffold`.
- [ ] Prompt prints PR description to chat for clipboard paste. Does NOT push, does NOT open PR.
- [ ] Optionally writes synthesized text to `PR-DESCRIPTION.md` in the work-item dir.
- [ ] Writes `receipts.ship` block with `pr_description_synthesized_from`, `pr_url: null`, `pr_opened: false`, `next_legal: [merge]`.
- [ ] Working-Tree Rule: warn-and-write (not hard-stop). PR description is useful even with unpushed tree; warning surfaces risk.
- [ ] Manual smoke pass: invoke `/wc-ship` against a fixture with complete `receipts.qa` and `receipts.implement`; verify PR description quality.

## Todos

- [ ] Author `work-copilot/prompts/ship.prompt.md` with frontmatter + 5 main steps.
- [ ] PR description synthesis logic (tracker journal + receipts.qa AC coverage + commits).
- [ ] Working-Tree Rule paste pattern (warn variant, not hard-stop).
- [ ] `receipts.ship` write with `pr_opened: false` default.
- [ ] Document the post-ship convention: user flips `pr_opened: true` and fills `pr_url` manually after opening on GitHub.
- [ ] Smoke + fixture exercise.

## Log

- 2026-05-11: Created. Build #5 of Approach C. Blocked by S000033 (full chain to /wc-implement → /wc-qa → /wc-ship requires all upstream prompts).

## PRs

## Files

- `work-copilot/prompts/ship.prompt.md` (new)

## Insights

- `/wc-ship` is the only receipt-writing prompt with a warn-and-write Working-Tree Rule (not hard-stop). Reason: the synthesized PR description is useful even if the working tree is unpushed; the warning surfaces the risk but lets the user have the description for clipboard paste anyway. This is also why `pr_opened: false` and `pr_url: null` are the defaults — the prompt doesn't pretend to know if a PR was opened. The user flips these manually after the fact, and /wc-pipeline's "ship printed but PR not opened" drift rule catches the case where the user forgets.

## Journal

- [decision] 2026-05-11: Working-Tree Rule UX for /wc-ship is warn-and-write, NOT hard-stop. Lets users get the PR description for clipboard paste even when their tree isn't yet pushed; the warning makes the risk explicit. Confirmed by parent feature's Open Question #6 resolution.
- [decision] 2026-05-11: `pr_opened` is the canonical truth (NOT `pr_url`). A user could paste a URL and forget to flip the flag; `pr_opened` makes the gate unambiguous. /wc-pipeline keys on `pr_opened`.
