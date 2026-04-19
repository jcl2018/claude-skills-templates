---
name: "tests"
type: task
id: "T000010"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000006"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000009"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Implement S000006 TEST-SPEC Tier 1 checks S1–S8 as shell assertions
- [ ] Implement S000006 TEST-SPEC Tier 2 scenarios E1–E8: single-word / phrase / non-match / no-trigger / multi-match / case-variants / empty-triggers / match-log
- [ ] Add regression diff: validate stdout on existing fixture with and without on-demand categories, assert byte-identical
- [ ] Reuse canary infrastructure from T000007 E2E runner
- [ ] Wire new tests into `./scripts/test.sh`
- [ ] Document how to add a new E2E trigger scenario for future categories (lowers maintenance burden)

## Log

- 2026-04-16: Created. Tests for S000006 (on-demand matching). Depends on T000009 (impl), T000008 (refactor), T000005 (fixtures).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- scripts/test.sh (modified)

## Insights

## Journal
