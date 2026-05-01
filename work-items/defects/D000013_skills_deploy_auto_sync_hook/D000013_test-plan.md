---
type: test-plan
parent: D000013
title: "skills-deploy: post-merge hook auto-syncs ~/.claude on workbench pull — Test Plan"
date: 2026-05-01
author: chjiang
status: Verified
---

<!-- Scope: regression coverage for the auto-sync hook. The fix has two parts:
     (1) extending scripts/setup-hooks.sh to write a post-merge hook, and
     (2) installing the hook on the maintainer's machine via re-running setup-hooks.sh. -->

## Scope

The fix touches:
- `scripts/setup-hooks.sh` — adds a second `cat > $HOOK_DIR/post-merge << 'HOOK' ... HOOK` block matching the existing pre-commit pattern. Embedded hook detects deploy-relevant changes between `ORIG_HEAD` and `HEAD` and runs `scripts/skills-deploy install --overwrite`.
- `scripts/test.sh` — new D000013 regression block verifying `setup-hooks.sh` writes a `post-merge` hook that calls `skills-deploy install --overwrite`. Source-level grep, no actual hook firing (avoids touching `.git/hooks/` in CI).
- `.git/hooks/post-merge` (per-machine, untracked) — installed by re-running `setup-hooks.sh` after the source change lands.

No source code change to the validator, the deploy mechanism, or any other skill. The fix is at the hook-installer + onboarding-bootstrap layer.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `setup-hooks.sh` declares a post-merge hook | `grep -q "post-merge" scripts/setup-hooks.sh` | Match found | **PASS** — D000013 block in test.sh asserts this |
| 2 | Embedded post-merge hook calls `skills-deploy install --overwrite` | `grep -qE 'skills-deploy.*install.*--overwrite' scripts/setup-hooks.sh` (within the post-merge heredoc region) | Match found | **PASS** — D000013 block asserts this |
| 3 | Embedded post-merge hook filters on deploy-relevant paths | `grep -qE '\(templates/\|skills/\|skills-catalog\.json\|rules/\)' scripts/setup-hooks.sh` | Match found | **PASS** — D000013 block asserts this |
| 4 | Running `./scripts/setup-hooks.sh` writes both hooks to `.git/hooks/` | `./scripts/setup-hooks.sh && [ -x .git/hooks/pre-commit ] && [ -x .git/hooks/post-merge ]` | Both hooks present and executable | **PASS** — verified manually after re-running setup-hooks.sh |
| 5 | Post-merge hook is silent on no-op pull (no deploy-relevant changes) | Trigger a `git merge` that only touches `README.md` (or any non-filtered path) | Hook exits silently, `skills-deploy install` does NOT run | Pending — manual verification next pull |
| 6 | Post-merge hook fires on template-touching pull | Edit a template on a side branch, merge into `main` locally, observe hook output | Hook prints "[skills-deploy] templates/skills/catalog/rules changed — re-deploying..." and runs the install | Pending — manual verification next time a real template change lands |
| 7 | Post-merge hook leaves `~/.claude/templates/` byte-current after firing | After test #6, run D000012 drift block | 0 failures (hook synced everything before the test ran) | Pending — D000012 block + this hook compose into end-to-end coverage |
| 8 | D000012 drift block still passes | `./scripts/test.sh` | 0 failures including both D000012 and D000013 blocks | **PASS** — full test.sh run after this PR's changes |

## Verification Steps

- [x] `./scripts/validate.sh` — passes (no skill catalog regressions)
- [x] `./scripts/test.sh` — passes (0 failures) including the new D000013 block
- [x] `./scripts/setup-hooks.sh` re-run on this machine; `.git/hooks/post-merge` written and executable
- [x] `cat .git/hooks/post-merge` matches the heredoc body in `scripts/setup-hooks.sh` (sanity check that the source change propagated to disk)
- [ ] Next workbench pull that includes a template change auto-deploys without manual `skills-deploy install` (deferred — first opportunity is the next PR after this one lands)
- [x] Manual: re-read D000012's RCA "Option C" — sub-path C2 is shipped; sub-path C1 (symlink templates) was the alternative and remains unimplemented (separate design call if/when needed)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 (workbench, maintainer) | `fix/skills-deploy-auto-sync-hook` (off `main` @ 5b421a4 / v1.1.1) | **PASS** — `./scripts/test.sh` 0 failures including D000013 block; `.git/hooks/post-merge` installed and matches source |
| Other machines | varies | Pending — each clone needs `./scripts/setup-hooks.sh` re-run after pulling this PR. Same one-time bootstrap as the existing pre-commit hook. |
