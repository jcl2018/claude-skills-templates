---
type: test-spec
parent: S000088
feature: F000049
title: "Retire the separate-clone legacy (drop runtime .source, declare install==clone-in-place) — Test Specification"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | After a hermetic default `skills-deploy install` (no `--bundle`, temp HOME), the manifest has `install_mode == "in-place"` AND `bundle_path == source` | the default install declares install==clone-in-place | `scripts/test.sh` (S000088 block: assertion 1) |
| S2 | core | AC-2 | None of the 4 orchestrator SKILL.md preambles contain a `.source`/`cj-goal-common.sh` resolution branch (`grep -L` the `_S` + `cj-goal-common.sh` elif) | shared-script execution has no runtime `.source` tier | `scripts/test.sh` (S000088 block: assertion 2) |
| S3 | core | AC-3 | None of the 10 `.source`-reaching skills still read `manifest.source` in the update-check snippet (`grep -c "jq -r '.source"` over the update-check block == 0) | no skill performs a runtime `.source` reach-back | `scripts/test.sh` (S000088 block: assertion 3) |
| S4 | integration | AC-4 | `skills-deploy bundle-status` on an `in-place` manifest reports `install_mode: in-place` (not a false `bundle`/`dev-clone`) | the in-place mode is visible + truthful | `scripts/test.sh` (S000088 block: assertion 4) |
| S5 | integration | AC-4 | `cj-portability-audit.sh` machine output over the 4 orchestrators yields `FINDINGS=0` and tier `local-only` with no `source-reachback` PREAMBLE row | the family is audit-clean after the drop | `scripts/test.sh` (S000088 block: assertion 5) |
| S6 | usability | AC-5 | The default `skills-deploy install` summary / usage still references the install model; `post-land-sync.sh --dry-run` still resolves + prints a pull plan (reframed, not deleted) | docs current + the sync helper still functions on the in-place checkout | `scripts/post-land-sync.sh --dry-run` (resolves; exits 0/2 by guard, never absent) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,AC-2,AC-3 | A maintainer runs an orchestrator from the in-place checkout with zero `.source` reach | `skills-deploy install` (default); `cd` into the workbench checkout; run `/CJ_goal_feature --dry-run "x"` | The worktree/sync phases resolve `cj-goal-common.sh` from repo-local (or `_cj-shared`), the update-check resolves from `_cj-shared`, and `manifest.source` is never read by a skill preamble; `bundle-status` shows `in-place` | PASS if the orchestrator runs with no `.source` reach AND the manifest declares in-place; FAIL if any preamble still reads `manifest.source` |
| E2 | resilience | AC-6 | The `.source`-tier drop is fail-soft when `_cj-shared` is absent | Temporarily hide `~/.claude/_cj-shared`; run `/CJ_goal_feature --dry-run "x"` from a non-workbench cwd | The orchestrator prints the existing "shared script unreachable → WARN + proceed" path (no hard fail); the update-check nudge silently no-ops | PASS if it degrades gracefully (visible WARN, no crash); FAIL if it hard-errors |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Deleting `post-land-sync` / `--phase sync` | DELIBERATELY not done — `gh pr merge` is remote, so the in-place checkout still needs a post-merge pull; they are reframed, not deleted | The "retire the sync machinery" roadmap verb is realized as a reframe; a future dir-symlink (S5) could make reinstall-free pull possible |
| Full reinstall-free pull (dir-level skill symlinks) | Out of scope — entangled with Windows copy-mode parity (S5); the current per-file-symlink layout still needs a reinstall for NEW files | A `git pull` makes EXISTING files live but a NEW skill file needs `skills-deploy install` until S5 |
| Windows/Git-Bash copy-mode of the in-place model | Deferred to S5 | The `_cj-shared` resolution + in-place stamp are platform-neutral; full Git-Bash parity is S5 |
| The other ~6 passive-nudge skills' internal behavior | The repoint is a uniform snippet swap; `skills-update-check` itself is unchanged | The script still reads `manifest.source` internally (= the in-place checkout) — correct, out of the "skill reach-back" AC scope |
| The ACTIVE Update Nudge Handling upgrade flow (`CJ_personal-workflow` / `CJ_system-health` `--should-prompt` / `--snooze` / `--skip`) | DELIBERATELY retains `$_S` (manifest `source`) — it `git pull`s + `skills-deploy install`s that checkout, which it genuinely needs the checkout path for | Under install==clone `source` IS the in-place checkout, so this is the maintainer upgrade ritual reaching the install itself, not a separate-clone reach-back; the AC scopes the PASSIVE per-invocation nudge only |
