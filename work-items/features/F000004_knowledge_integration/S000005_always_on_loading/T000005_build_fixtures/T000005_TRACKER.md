---
name: "build-fixtures"
type: task
workflow_type: task
id: "T000005"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [ ] Scope understood from parent work item (parent tracker read)
- [ ] Working branch created (`branch` field populated)
- [ ] Files section has >=1 entry

### Phase 2: Implement
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] All test cases in test-plan.md marked Pass
- [ ] Files section updated with all changed files
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Todos

- [ ] Create `skills/company-workflow/fixtures/valid-knowledge-dir/` root
- [ ] Subdir `coding/` — `surface: always`, triggers: []; contains `style.md` (with canary) and `cpp/errors.md` (nested file with canary)
- [ ] Subdir `runbooks/` — `surface: on-demand`, triggers: [pricing, "pricing engine"]; contains `pricing.md` (with canary)
- [ ] Subdir `notes/` — NO `.knowledge.yml`; contains `draft.md` (used to verify missing-yml default behavior)
- [ ] Subdir `broken/` — malformed `.knowledge.yml` (e.g., invalid syntax or wrong keys); contains `any.md`
- [ ] Subdir `empty-triggers/` — `surface: on-demand`, triggers: []; contains `nevermatched.md`
- [ ] Document each canary string at the top of each md file for tests to match (stable identifiers)
- [ ] Add fixture README explaining the intent of each category (helps reviewers)

## Log

- 2026-04-16: Created. Builds `valid-knowledge-dir/` fixture with mixed categories. Used by T000006, T000007, and eventually T000009/T000010.

## PRs

## Files

- skills/company-workflow/fixtures/valid-knowledge-dir/ (new directory tree)

## Insights

## Journal
