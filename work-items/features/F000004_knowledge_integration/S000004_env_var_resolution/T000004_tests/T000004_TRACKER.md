---
name: "tests"
type: task
workflow_type: task
id: "T000004"
status: active
created: "2026-04-16"
updated: "2026-04-16"
url: ""
parent: "S000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000003"
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

- [ ] Implement S000004 TEST-SPEC Tier 1 checks S1–S6 as shell assertions in `scripts/test.sh`
- [ ] Implement S000004 TEST-SPEC Tier 2 scenarios E1–E4 (env unset / set-valid / set-invalid-path / set-file)
- [ ] Add regression diff: run validate on `fixtures/valid-feature-dir/` with env unset vs. set, assert empty diff
- [ ] Capture warning text in a variable so both impl and tests reference the same string (avoid future drift)
- [ ] Wire new tests into `./scripts/test.sh` so CI runs them
- [ ] Document how to run the E2E tests locally in WORKFLOW.md Testing section (if one exists) or in a README comment

## Log

- 2026-04-16: Created. Adds Tier 1 smoke + Tier 2 E2E + regression check for S000004.

## PRs

## Files

- scripts/test.sh (modified)
- skills/company-workflow/fixtures/... (possibly added — if a knowledge-dir fixture is needed; otherwise in-test `mktemp -d`)

## Insights

## Journal
