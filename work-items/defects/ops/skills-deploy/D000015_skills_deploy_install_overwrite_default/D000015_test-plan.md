---
type: test-plan
parent: D000015
title: "skills-deploy: make `--overwrite` the default behavior for install — Test Plan"
date: 2026-05-07
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect D000015). Cases below are regression scenarios for
     the specific bug (default install does not update drifted templates) plus
     the design-decision branches captured in the RCA. -->

## Scope

Changes the default behavior of `scripts/skills-deploy install` from "skip on checksum drift" to "overwrite on checksum drift." Touches:

- `scripts/skills-deploy` lines 149, 153, 379-395, 405-425, 664, 881
- `CLAUDE.md` "Template deployment" section
- `scripts/test.sh` (new D000015 regression block; possible audit of D000013 block)
- Possibly `scripts/setup-hooks.sh` (audit redundant `--overwrite` flag in post-merge hook)

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Default install replaces drifted templates | (a) `skills-deploy install` to populate `~/.claude/`. (b) Edit a deployed template directly. (c) Run `skills-deploy install` (no flag). | Deployed template now matches workbench source. Pre-fix: WARN, no change. | Pending |
| 2 | Default install replaces drifted rules | Same as #1 but for a file under `rules/`. | Deployed rule matches workbench source. | Pending |
| 3 | Fresh install (no existing files) | `rm -rf ~/.claude/templates/personal-workflow ~/.claude/skills/personal-workflow`. Run `skills-deploy install`. | All files deployed cleanly. No errors. | Pending |
| 4 | No-op install (no drift) | Run `skills-deploy install` twice in a row. | Second run is silent / reports zero changes. No spurious overwrites. | Pending |
| 5 | Escape hatch (if option 1A from RCA — `--no-overwrite`) | After deployed-file edit, run `skills-deploy install --no-overwrite`. | Edit preserved; WARN logged; exit 0. | Pending — depends on design decision |
| 6 | Backwards-tolerated flag (if option 1B from RCA — drop `--overwrite` but tolerate it) | `skills-deploy install --overwrite`. | Deploys normally. May log a "deprecated flag" warning for one release. | Pending — depends on design decision |
| 7 | doctor reset hint | Trigger the `skills-deploy doctor` drift path (line 664). | Hint message no longer references `--overwrite`. | Pending |
| 8 | help text | `skills-deploy install --help` (or `skills-deploy --help`). | Reflects new default. `--overwrite` either omitted or marked deprecated. | Pending |
| 9 | D000013 post-merge hook still works end-to-end | (a) `setup-hooks.sh`. (b) Edit workbench template, commit, merge to main, pull from a second clone. | Hook fires, deploy succeeds, deployed templates match (whether or not the hook still passes `--overwrite`). | Pending |
| 10 | D000012 drift regression check still passes | Run `scripts/test.sh`. | All checks pass; D000012 block still catches drift if any exists. | Pending |

## Verification Steps

- [ ] Local build succeeds (macOS — primary dev env)
- [ ] `scripts/test.sh` passes (full suite, including D000012 + D000013 regression blocks)
- [ ] `scripts/validate.sh` passes (catalog ↔ filesystem consistency)
- [ ] Manual reproduction of original bug: edit deployed template, run `skills-deploy install`, confirm overwrite (test case #1 above)
- [ ] D000013 post-merge hook still triggers an automatic sync end-to-end on a fresh clone

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.3.0 (Darwin), zsh | `main` post-D000015 | Pending |
