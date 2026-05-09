---
type: test-spec
parent: S000020
feature: F000011
title: "Phase 3 gate auto-update — engine + post-merge hook — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- v1 test plan: manual fixture-based testing per Step 0A choice. End-to-end
     verification is a real ship cycle (the success criterion from the design). -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Skill registers `--update` flag in check.md | Skill change wired | `grep -q -- '--update' skills/personal-workflow/check.md` |
| S2 | core | AC-9, AC-10 | `scripts/check-gates-update.sh` exists, executable, has shebang | Inference engine present and runnable | `test -x scripts/check-gates-update.sh && head -1 scripts/check-gates-update.sh \| grep -q '^#!'` |
| S2b | core | AC-12 | `scripts/setup-hooks.sh` installs the post-merge hook with the F000011 gates-update Section 2 | Hook contains the gates-update logic inline | `grep -q "F000011" scripts/setup-hooks.sh && grep -q "check-gates-update.sh" scripts/setup-hooks.sh` |
| S3 | core | AC-12 | After running setup-hooks.sh, the installed `.git/hooks/post-merge` calls check-gates-update.sh on touched trackers | Wire-up verified end-to-end | `./scripts/setup-hooks.sh > /dev/null && grep -q 'check-gates-update.sh' .git/hooks/post-merge` |
| S4 | resilience | AC-7 | Engine is idempotent: re-run = NO-OP (already-converged state) | Idempotent contract holds | `./scripts/check-gates-update.sh work-items/features/personal-workflow/F000010_pipeline_skills/S000017_scaffold_work_item 2>&1 \| grep -qE 'gates-update'` (first run + second run; second prints "no changes") |
| S5 | resilience | AC-13 | Engine handles missing-PR gracefully (no PR found for the dir) | Offline / missing-PR-fallback works | `./scripts/check-gates-update.sh work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/S000020_implement_engine_and_hook 2>&1 \| grep -qE 'INFO: no PR found\|gates-update'` (S000020 has no PR yet) |
| S6 | core | AC-1, AC-3 | validate.sh + test.sh both green post-implementation | No regression on existing test suite | `./scripts/validate.sh > /dev/null && ./scripts/test.sh > /dev/null` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3 | Auto-mark Phase 3 gates on shipped work-item | 1. After ship + merge of F000011 itself, `git pull main`. 2. Hook fires. 3. Inspect F000011_TRACKER.md and S000020_TRACKER.md. | Phase 3 gates `/ship — PR created`, `/land-and-deploy — merged and deployed`, `Smoke tests pass in CI`, `/personal-workflow check — validation passed` are all `[x]`. `E2E walked manually` is `[ ]`. `## PRs` has the merged PR link. `## Journal` has `[gates-update]` entry. | PASS if all inferable gates green AND E2E gate stays unchecked AND PR link present AND journal entry present; FAIL on any over-mark, under-mark, or duplicate write |
| E2 | core | AC-4 | `E2E walked manually` is never auto-marked | 1. Run --update on any shipped work-item where E2E gate starts `[ ]`. 2. Inspect tracker. | `E2E walked manually` remains `[ ]` | PASS if gate stays `[ ]`; FAIL if marked `[x]` |
| E3 | resilience | AC-7 | Manual override is preserved | 1. Manually mark `E2E walked manually` as `[x]` on a tracker. 2. Run --update. 3. Inspect tracker. | The manually-marked gate stays `[x]`; engine doesn't downgrade | PASS if `[x]` preserved; FAIL on any downgrade |
| E4 | core | AC-9, AC-10 | Hook fires on main, no-ops on feature branch | 1. On main, simulate a pull that brings new tracker-touching commits. Verify hook runs. 2. Switch to feature branch, simulate a pull. Verify hook does NOT run. | Hook runs once on main; silently no-ops on feature branch | PASS if behavior matches; FAIL on either false-fire or missed-fire |
| E5 | resilience | AC-11 | Hook failure doesn't block git | 1. Inject a bug into post-merge-hook.sh (e.g., `exit 1` after a print). 2. Run `git pull` on main. 3. Observe git completes successfully. | Git pull succeeds despite hook printing warning + exiting 1 | PASS if git completes; FAIL if git fails |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Multi-level child recursion | v1 scope: one level only. Multi-level features don't exist yet to test against | Low — feature gap, surfaced when needed |
| Cross-machine merge sync (web UI from another machine) | Out of scope; accepted as known limitation | Low — solo workflow rarely hits this |
| `/document-release` over-mark via coincidence | Heuristic-based; depends on commit timing. Real coincidence rare | Low — accepted; v2 can add explicit marker |
| Hook ordering with hypothetical other post-merge hooks | Only one repo-managed post-merge hook in v1 | Low — composition concern is theoretical |
| Concurrent runs (two `git pull`s racing) | Personal use, single user, single machine | Low — shouldn't occur |
| Engine behavior when work-item PR title doesn't include the work-item ID | Edge case; falls back to commit-message grep, then warning | Medium — could miss PR linking on weirdly-named PRs |
| Multi-PR work-items (e.g., a feature shipped across 2 PRs) | v1 assumes one PR per work-item; falls back to picking the first match | Medium — feature with multiple PRs would need v2 enhancement |
