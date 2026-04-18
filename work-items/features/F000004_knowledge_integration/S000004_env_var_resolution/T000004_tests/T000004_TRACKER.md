---
name: "tests"
type: task
id: "T000004"
status: active
created: "2026-04-16"
updated: "2026-04-17"
parent: "S000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "T000003"
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

- [ ] Implement S000004 TEST-SPEC Tier 1 checks S1–S6 as shell assertions in `scripts/test.sh`
- [ ] Implement S000004 TEST-SPEC Tier 2 scenarios E1–E4 (env unset / set-valid / set-invalid-path / set-file)
- [ ] Add regression diff: run validate on `fixtures/valid-feature-dir/` with env unset vs. set, assert empty diff
- [ ] Capture warning text in a variable so both impl and tests reference the same string (avoid future drift)
- [ ] Wire new tests into `./scripts/test.sh` so CI runs them
- [ ] Document how to run the E2E tests locally in WORKFLOW.md Testing section (if one exists) or in a README comment

## Log

- 2026-04-16: Created. Adds Tier 1 smoke + Tier 2 E2E + regression check for S000004.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).
- 2026-04-18: /plan-eng-review added 3 test cases to test-plan.md (empty-string parity, stdout-empty assertion, set -e safety). Coverage for S000004's Knowledge Resolution block now 100% across code paths, structural, regression, and safety dimensions.
- 2026-04-18: Codex outside-voice (via /plan-eng-review) caught 3 gaps. Applied: (a) rewrote Tier 2 E1–E5+E1b as extract-and-exec of the SKILL.md bash block instead of "invoke /company-workflow validate" (not possible from bash CI per D000004 RCA); (b) added case 13 (hostile input) to lock in the SKILL.md sanitization patch; (c) clarified scope note at top of test-plan. Coverage model is now honest about what bash CI can enforce vs. what is manual-verification-only.

## PRs

## Files

- scripts/test.sh (modified)
- skills/company-workflow/fixtures/... (possibly added — if a knowledge-dir fixture is needed; otherwise in-test `mktemp -d`)

## Insights

## Journal
