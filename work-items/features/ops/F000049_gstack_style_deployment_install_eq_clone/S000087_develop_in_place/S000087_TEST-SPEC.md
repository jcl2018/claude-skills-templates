---
type: test-spec
parent: S000087
feature: F000049
title: "Develop-in-place enablement (bundle-status + origin-repoint) — Test Specification"
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
| S1 | core | AC-1 | After a hermetic `--bundle` install (cloned from a LOCAL source) with `SKILLS_DEPLOY_BUNDLE_UPSTREAM` set, the bundle's `origin` URL equals the upstream | origin repointed to GitHub — push/PR works from the bundle | `scripts/test.sh` (S000087 block: assertion 1) |
| S2 | core | AC-2 | `skills-deploy bundle-status` prints `install_mode: bundle` + the bundle path + the origin | the dev checkout state is reported | `scripts/test.sh` (S000087 block: assertion 2) |
| S3 | resilience | AC-3 | `bundle-status` on a non-bundle manifest reports `install_mode: dev-clone` + "Not in bundle mode" | no false install==clone claim | `scripts/test.sh` (S000087 block: assertion 3) |
| S4 | integration | AC-4 | The default `skills-deploy install` (no `--bundle`) and the separate-clone machinery are unchanged | additive — no rip-out (the S000086 default-install-untouched assertion still holds) | `scripts/test.sh` (S000086 block: default-install assertion, still green) |
| S5 | usability | AC-5 | `skills-deploy` (bad/no command) usage lists `bundle-status` + `install --bundle` | develop-in-place is documented + discoverable | `scripts/skills-deploy 2>&1 \| grep -E 'bundle-status\|--bundle'` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | A maintainer develops in place + ships from the bundle | Run `skills-deploy install --bundle`; `cd ~/.claude/skills/cj-workbench`; `git checkout -b test-branch`; edit a file; `git push -u origin test-branch` | The push reaches GitHub (origin is the upstream); `skills-deploy bundle-status` shows the branch + clean→dirty transition | PASS if the branch pushes to GitHub from the bundle AND bundle-status reflects the checkout; no separate external clone needed |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Retiring `.source` / the worktree flow / `post-land-sync` | Out of scope for S3 — deferred to S4 (the dangerous subtractive half) | The separate-clone machinery stays; the migration is not "complete" until S4 |
| Network clone from `upstream_url` + a real push | The hermetic test clones from a LOCAL source + uses a fake upstream URL (no network in CI) | The real network push is exercised only by E1 on a real machine |
| Windows/Git-Bash copy-mode of the bundle | Deferred to the S5 parity story | A Git-Bash bundle would copy rather than symlink; the origin-repoint is platform-neutral but full parity is S5 |
