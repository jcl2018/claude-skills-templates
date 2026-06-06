---
type: test-spec
parent: S000086
feature: F000049
title: "Single-bundle layout + git-checkout install (skills-deploy install --bundle) — Test Specification"
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
| S1 | core | AC-1 | After a hermetic `--bundle` install, the bundle path is a git checkout (`.git` present) | install == clone: the install dir IS a git checkout | `scripts/test.sh` (S000086 block: assertion 1) |
| S2 | core | AC-2 | Flat `~/.claude/skills/CJ_goal_feature/SKILL.md` is a symlink whose target is `<bundle>/skills/CJ_goal_feature/SKILL.md` | the flat skills resolve INTO the bundle | `scripts/test.sh` (S000086 block: assertion 2) |
| S3 | core | AC-3 | Manifest records `install_mode=bundle` + `bundle_path` + `source` = the bundle | the install==clone receipt is recorded | `scripts/test.sh` (S000086 block: assertion 3) |
| S4 | integration | AC-4 | A DEFAULT install (no `--bundle`) symlinks to a dev-clone source and writes no bundle marker | the legacy install is untouched (additive) | `scripts/test.sh` (S000086 block: assertion 4) |
| S5 | resilience | AC-5 | The whole S000086 block bootstraps the bundle from a LOCAL clone source (`SKILLS_DEPLOY_BUNDLE_SOURCE=$REPO_ROOT`), no network | install==clone works offline | `scripts/test.sh` (S000086 block runs with a local source) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | An operator opts into the bundle install on their machine | Run `skills-deploy install --bundle`; then invoke a `/CJ_*` skill and inspect `~/.claude/skills/CJ_goal_feature/SKILL.md` | A managed checkout exists at `~/.claude/skills/cj-workbench`; `/CJ_*` are discoverable and resolve INTO the bundle; the legacy install is unaffected | PASS if the bundle is a git checkout AND `/CJ_*` resolve from it AND a subsequent default `install` reverts to the dev-clone symlinks |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The flip-to-default + develop-in-place + retiring the external clone | Out of scope for S2 — those are S3/S4 | S2 leaves the legacy install as the default; the bundle is opt-in |
| Windows/Git-Bash copy-mode of the bundle clone | Deferred to the S5 parity story | A Git-Bash bundle install would copy rather than symlink; S2 degrades to copy-mode like the legacy install but the parity audit is S5 |
| Network clone from `upstream_url` | The hermetic test clones from a LOCAL source (no network in CI) | The network-clone path is exercised only on a real first install; the local-clone path is the tested mechanism |
