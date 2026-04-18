---
name: "tests"
type: task
workflow_type: task
id: "T000010"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000009"
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

- [ ] Implement S000006 TEST-SPEC Tier 1 checks S1–S8 as shell assertions
- [ ] Implement S000006 TEST-SPEC Tier 2 scenarios E1–E8: single-word / phrase / non-match / no-trigger / multi-match / case-variants / empty-triggers / match-log
- [ ] Add regression diff: validate stdout on existing fixture with and without on-demand categories, assert byte-identical
- [ ] Reuse canary infrastructure from T000007 E2E runner
- [ ] Wire new tests into `./scripts/test.sh`
- [ ] Document how to add a new E2E trigger scenario for future categories (lowers maintenance burden)

## Log

- 2026-04-16: Created. Tests for S000006 (on-demand matching). Depends on T000009 (impl), T000008 (refactor), T000005 (fixtures).

## PRs

## Files

- scripts/test.sh (modified)

## Insights

## Journal
