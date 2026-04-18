---
name: "tests"
type: task
workflow_type: task
id: "T000007"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000006"
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

- [ ] Implement S000005 TEST-SPEC Tier 1 checks S1–S7 as shell assertions in `scripts/test.sh`
- [ ] Implement S000005 TEST-SPEC Tier 2 scenarios E1–E4 (canary-based: always-on content reaches Claude; on-demand doesn't; malformed-yml resilience; env-unset silence)
- [ ] Add regression diff: validate output on `fixtures/valid-feature-dir/` with env=empty dir vs. env=`valid-knowledge-dir`, assert stdout byte-identical
- [ ] Extend E2E runner to inject canary strings and verify Claude's replies quote them
- [ ] Wire new tests into `./scripts/test.sh` so pre-commit + CI runs them

## Log

- 2026-04-16: Created. Tests for S000005 (always-on loading). Depends on T000006 (impl) and T000005 (fixtures).

## PRs

## Files

- scripts/test.sh (modified)

## Insights

## Journal
