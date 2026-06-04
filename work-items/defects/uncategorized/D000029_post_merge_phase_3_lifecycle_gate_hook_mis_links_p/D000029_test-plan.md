---
type: test-plan
parent: D000029
title: "F000011 post-merge Phase-3 hook disable — Test Plan"
date: 2026-06-04
author: chjiang
status: Final
---

## Scope

One fix: remove the post-merge Phase-3 lifecycle-gate auto-update (Section 2) from
`scripts/setup-hooks.sh` (Approach A — disable the auto-tick). Regression coverage in
`tests/setup-hooks.test.sh` (now registered in `scripts/test.sh`).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Generated post-merge hook has no Phase-3 auto-tick | Install via setup-hooks.sh into a temp repo; inspect `.git/hooks/post-merge` executable lines | No `check-gates-update` / `"$BRANCH"=main` / `work-items.*_TRACKER` invocation (Smoke 1) | Pass |
| 2 | Section 1 (D000013 redeploy) preserved | Same generated hook | `skills-deploy install` invocation present | Pass |
| 3 | Removal comment doesn't false-match | Run absence greps through `hook_code()` comment-stripper | Greps see only executable lines (Smoke 0 inverted) | Pass |
| 4 | Test actually runs in CI | `./scripts/test.sh` | The `tests/setup-hooks.test.sh` runner block fires (was previously unregistered) | Pass |

## Verification Steps

- [x] `bash -n` clean on setup-hooks.sh / check-gates-update.sh / setup-hooks.test.sh / test.sh; shellcheck clean
- [x] `bash tests/setup-hooks.test.sh` → 8 assertions, 0 failures
- [x] `./scripts/test.sh` → PASS (new runner block fires)
- [x] `./scripts/validate.sh` → 0 errors / 0 warnings, PASS
- [ ] Post-land: re-run `scripts/setup-hooks.sh` to refresh the LIVE `.git/hooks/post-merge` (the source fix updates the installer; the installed copy updates on re-install)
