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
| S1 | core | AC-1 | Skill registers `--update` flag in catalog/help | Catalog wiring correct | `./scripts/validate.sh && grep -q -- '--update' skills/personal-workflow/check.md` |
| S2 | core | AC-9, AC-10 | `scripts/post-merge-hook.sh` exists, executable, has shebang | Hook file is present and runnable | `test -x scripts/post-merge-hook.sh && head -1 scripts/post-merge-hook.sh \| grep -q '^#!'` |
| S3 | core | AC-12 | `scripts/setup-hooks.sh` installs the new hook | Wire-up of post-merge hook into install pass | manual: re-run `./scripts/setup-hooks.sh`, verify `.git/hooks/post-merge` exists and links/copies post-merge-hook.sh |
| S4 | resilience | AC-7 | Engine is idempotent: re-run = NO-OP | Idempotent contract holds | manual: run --update twice on same already-shipped work-item dir; second run prints "no changes" |
| S5 | resilience | AC-13 | Engine handles `gh` offline gracefully | Offline-fallback contract holds | manual: temporarily `unset GH_TOKEN` or block network, run --update, verify partial inference + warning + exit 0 |

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
