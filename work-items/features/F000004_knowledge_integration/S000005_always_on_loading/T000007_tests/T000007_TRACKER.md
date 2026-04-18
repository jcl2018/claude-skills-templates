---
name: "tests"
type: task
id: "T000007"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000006"
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

- [ ] Implement S000005 TEST-SPEC Tier 1 checks S1–S7 as shell assertions in `scripts/test.sh`
- [ ] Implement S000005 TEST-SPEC Tier 2 scenarios E1–E4 (canary-based: always-on content reaches Claude; on-demand doesn't; malformed-yml resilience; env-unset silence)
- [ ] Add regression diff: validate output on `fixtures/valid-feature-dir/` with env=empty dir vs. env=`valid-knowledge-dir`, assert stdout byte-identical
- [ ] Extend E2E runner to inject canary strings and verify Claude's replies quote them
- [ ] Wire new tests into `./scripts/test.sh` so pre-commit + CI runs them

## Log

- 2026-04-16: Created. Tests for S000005 (always-on loading). Depends on T000006 (impl) and T000005 (fixtures).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).

## PRs

## Files

- scripts/test.sh (modified)

## Insights

## Journal
