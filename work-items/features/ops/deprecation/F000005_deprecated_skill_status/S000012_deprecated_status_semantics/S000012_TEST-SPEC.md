---
type: test-spec
parent: S000012_deprecated_status_semantics
feature: F000005_deprecated_skill_status
title: "Deprecated Status Semantics — Test Specification"
version: 2
status: Draft
date: 2026-05-02
updated: 2026-05-05
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Migrated from Test Matrix + Test Tiers shape to Smoke + E2E on 2026-05-05.
     Original 12 Test Matrix rows + 5 smoke + 6 E2E consolidated. E2 (opt-in
     install) and E5 (remove) merged into one round-trip E2E since they share
     the same fixture chain. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | resilience | AC-6 | Catalog status enum: accepts known values, rejects typos | `active`, `experimental`, `deprecated` accepted; `depricated` (or any non-enum) rejected with the offending entry named and valid values listed | `./scripts/validate.sh` against fixture catalogs (one valid, one with `depricated`) |
| S2 | usability | AC-7 | generate-readme produces "Deprecated" section when at least one deprecated entry exists | Section header present; deprecated rows under it | `./scripts/generate-readme.sh` then `grep -E '^## Deprecated' README.md` |
| S3 | core | AC-2, AC-3 | skills-deploy install respects status flag | Install loop's filter logic returns "skip" for `deprecated` without `--include-deprecated`, "install" with the flag | `bash -c 'source scripts/skills-deploy; should_install_skill "deprecated" false'` (or equivalent) |
| S4 | observability | AC-2 | WARN line format matches spec (regex match) | `WARN: skipping deprecated skill: <name> \(use --include-deprecated to install\)` | grep over captured stdout/stderr in a fixture install run |
| S5 | resilience | AC-1, AC-6 | Catalog entry with no `status` field still validates (backward compat) | `validate.sh` decision pinned: either reject (require status field) or accept and treat missing as active | Add a fixture catalog with `status` omitted; run `validate.sh`; assert pinned behavior |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | Fresh-machine bootstrap with deprecated skill in catalog | `rm -rf ~/.claude/skills/company-workflow` (precondition); `scripts/skills-deploy install`; `ls ~/.claude/skills/` | `company-workflow` is NOT in the listing; other skills are; install printed exactly 1 WARN line for it | Pass = listing matches + WARN line present; Fail = company-workflow installed without flag, or WARN missing |
| E2 | core | AC-3, AC-5 | Opt-in install + remove round-trip | After E1: `scripts/skills-deploy install --include-deprecated`; check `ls ~/.claude/skills/` shows `company-workflow`; then `scripts/skills-deploy remove company-workflow`; re-check listing | After install: `company-workflow` present; no WARN line for it; other skills idempotent. After remove: `company-workflow` no longer present; no errors | Pass = listing transitions correctly through both phases |
| E3 | usability | AC-4 | Doctor under both deprecated states (not-installed and installed-via-flag) | `scripts/skills-deploy doctor` after E1 (deprecated NOT installed); `scripts/skills-deploy doctor` after E2's install phase (deprecated IS installed via flag) | Both runs: INFO line for `company-workflow` mentioning the deprecated state; no WARN; exit 0 | Pass = INFO label, exit 0 in both runs |
| E4 | core | AC-2 | Install does NOT remove an existing deprecated skill (idempotency for "no destructive changes") | Install `company-workflow` manually first (legacy state); run `scripts/skills-deploy install` (no flag) | WARN line emitted; existing `~/.claude/skills/company-workflow/` directory untouched | Pass = directory present after run + WARN emitted |
| E5 | resilience | AC-1, AC-6 | Full test suite passes on feature branch | `./scripts/test.sh` | Exit 0 | Pass = exit 0; Fail = any test failure |

(No dedicated E2E test skill — these E2E cases are run manually by the maintainer in T000013 verification, since the feature affects only `scripts/skills-deploy` and is small enough to verify by hand.)

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent invocation of `skills-deploy install` from multiple shells | Single-developer tooling; not a real scenario | Race conditions on `~/.claude/skills/` would be a separate hardening pass |
| Behavior on a catalog with multiple deprecated entries | Only `company-workflow` is being deprecated; loop logic is the same regardless of count | Future deprecations should add a fixture-based smoke test if count-handling needs proof |
| Per-platform install on Windows / Linux | This repo's skill-deploy tooling is Mac/zsh-targeted today; Copilot bundle is the Windows path | Documented in repo CLAUDE.md; not a regression of this feature |
| GitHub Actions / CI integration of the new flag | Not used in CI; install runs locally | If CI adopts `skills-deploy install`, that's a future feature |
| Migration of multiple skills at once | T000013 only flips `company-workflow` | Subsequent deprecations are separate tasks; loop logic already covered |
