---
type: test-spec
parent: S000012_deprecated_status_semantics
feature: F000005_deprecated_skill_status
title: "Deprecated Status Semantics — Test Specification"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Test Matrix must cover every PRD acceptance criterion
     across happy/edge/error paths. For a single fix or task, use test-plan.md instead. -->

## Test Matrix

<!-- Each row maps to a PRD acceptance criterion via the AC column.
     Every P0 criterion needs at least one test case.
     "Tag" = domain keyword matching the PRD story this test traces to
       (core, resilience, observability, usability, security, integration). -->

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Install with no flag skips deprecated skill | AC2 | Clean target dir; catalog has 1 deprecated + 3 active | Run `skills-deploy install`; check target dir | `~/.claude/skills/<deprecated>/` not present; active skills present | P0 | Integration |
| 2 | core | Install with `--include-deprecated` installs deprecated skill | AC3 | Same as #1 | Run `skills-deploy install --include-deprecated`; check target dir | `~/.claude/skills/<deprecated>/` present; active skills present | P0 | Integration |
| 3 | observability | Install emits exactly one WARN per deprecated skill | AC2 | Catalog has 1 deprecated entry | Run `skills-deploy install` (no flag); count `WARN: skipping deprecated skill:` lines | Exactly 1 line; format matches spec | P0 | Integration |
| 4 | observability | Install with `--include-deprecated` emits no skip warnings | AC3 | Same as #1 | Run with flag; count `WARN: skipping deprecated` lines | 0 lines | P0 | Integration |
| 5 | usability | Doctor reports deprecated-not-installed as INFO | AC4 | Deprecated catalog entry; not installed | Run `skills-deploy doctor`; inspect output | INFO line for deprecated skill; no WARN; exit code 0 | P0 | Integration |
| 6 | usability | Doctor reports deprecated-installed as INFO | AC4 | Deprecated catalog entry; installed via `--include-deprecated` | Run `skills-deploy doctor`; inspect output | INFO line; no WARN; exit code 0 | P0 | Integration |
| 7 | resilience | validate.sh accepts status=deprecated | AC6 | Catalog has `status: deprecated` entry | Run `scripts/validate.sh` | Exit 0; no errors mentioning status | P0 | Smoke |
| 8 | resilience | validate.sh rejects typo'd status (depricated) | AC6 | Catalog has `status: depricated` entry | Run `scripts/validate.sh` | Exit non-zero; error names the offending entry and lists valid values | P0 | Smoke |
| 9 | usability | generate-readme.sh produces "Deprecated" section | AC7 | Catalog has 1 deprecated + active entries | Run `scripts/generate-readme.sh`; inspect output | README has both an active table and a "Deprecated" section with the deprecated skill listed | P0 | Smoke |
| 10 | core | Remove works on a previously-installed deprecated skill | AC5 | Deprecated skill installed via `--include-deprecated` | Run `skills-deploy remove <name>` | Skill files removed from `~/.claude/skills/`; no special prompts | P0 | Integration |
| 11 | core | Existing `~/.claude/skills/<deprecated>/` is not removed by install | AC2 | Deprecated catalog entry; skill already installed (legacy) | Run `skills-deploy install` (no flag) | WARN line emitted; existing dir untouched (idempotency for "no destructive changes") | P0 | Integration |
| 12 | resilience | Catalog entry with no status field still validates (backward compat) | AC1, AC6 | Catalog entry with `status` omitted | Run `validate.sh` | Decision (TBD during Implement): either reject (require status field) or accept and treat missing as active. Test must pin behavior either way. | P0 | Smoke |

## Test Tiers

<!-- Every feature has two test tiers. Both are needed:
     - Tier 1 (smoke): Fast, deterministic, catches structural regressions without invoking AI
     - Tier 2 (E2E): Real execution, catches behavioral regressions in prompts and output
     Tier 1 alone can't test AI behavior. Tier 2 alone is slow and non-deterministic.
     Together they form a fast-then-thorough pipeline. -->

### Tier 1: Smoke Tests (automated, no live execution)

<!-- Static/structural checks: file existence, schema validation, section headers,
     frontmatter fields. Can run in CI or via a shell script. Fast, deterministic. -->

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | resilience | Catalog status enum check passes for valid values | `active`, `experimental`, `deprecated` are accepted | `./scripts/validate.sh` |
| S2 | resilience | Catalog status enum check rejects typo | `depricated` (or any non-enum value) is rejected | Add a fixture catalog with bad status; run `validate.sh`; assert non-zero exit |
| S3 | usability | README rendering produces "Deprecated" section when at least one deprecated entry exists | Section header present, deprecated rows under it | `./scripts/generate-readme.sh` then `grep -E '^## Deprecated' README.md` |
| S4 | core | Install loop's filter logic is unit-callable (or at least introspectable) | Function under test returns "skip" / "install" given a status value | `bash -c 'source scripts/skills-deploy; should_install_skill "deprecated" false'` (or equivalent — exact form decided at Implement time) |
| S5 | observability | WARN line format matches spec (regex match) | `WARN: skipping deprecated skill: <name> \(use --include-deprecated to install\)` | grep over captured stdout/stderr in a fixture install run |

### Tier 2: E2E Tests (real end-to-end execution)

<!-- Full end-to-end execution: invoke the actual feature, observe output, verify behavior
     matches AC. Requires AI execution. Can be manual (rubric-scored by human) or automated
     via an E2E test skill that creates fixtures and invokes the skill under test. -->

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Fresh-machine bootstrap with deprecated skill in catalog | `rm -rf ~/.claude/skills/company-workflow` (precondition); `scripts/skills-deploy install`; `ls ~/.claude/skills/` | `company-workflow` is NOT in the listing; other skills are; install printed exactly 1 WARN line for it | Pass = listing matches; Fail = company-workflow present without flag |
| E2 | core | Opt-in install of deprecated skill | After E1: `scripts/skills-deploy install --include-deprecated`; `ls ~/.claude/skills/` | `company-workflow` IS now in the listing; no WARN line for it; other skills idempotent | Pass = listing includes; Fail = absent or any spurious WARN |
| E3 | usability | Doctor under deprecated state | `scripts/skills-deploy doctor` after E1 | Output line for `company-workflow` uses INFO, mentions "deprecated — not installed by default"; exit 0 | Pass = INFO label, exit 0; Fail = WARN, error, or no mention |
| E4 | usability | Doctor under deprecated-installed state | `scripts/skills-deploy doctor` after E2 | Output line uses INFO, mentions "deprecated — installed (--include-deprecated)"; exit 0 | Pass = INFO label; Fail = WARN |
| E5 | core | Remove on a previously-installed deprecated skill | After E2: `scripts/skills-deploy remove company-workflow`; `ls ~/.claude/skills/` | `company-workflow` no longer present; no errors | Pass = removed cleanly; Fail = remains or errors |
| E6 | resilience | Full test suite passes on feature branch | `./scripts/test.sh` | Exit 0 | Pass = exit 0; Fail = any test failure |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

(No dedicated E2E test skill — these E2E cases are run manually by the maintainer in T000013 verification, since the feature affects only `scripts/skills-deploy` and is small enough to verify by hand.)

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Concurrent invocation of `skills-deploy install` from multiple shells | Single-developer tooling; not a real scenario | Race conditions on `~/.claude/skills/` would be a separate hardening pass |
| Behavior on a catalog with multiple deprecated entries | Only `company-workflow` is being deprecated in this feature; loop logic is the same regardless of count, and S5/E1 assert the per-entry shape | Future deprecations should add a fixture-based tier-1 test if the count-handling needs proof |
| Per-platform install on Windows / Linux | This repo's skill-deploy tooling is Mac/zsh-targeted today; the Copilot bundle (`work-copilot/`) is the Windows path | Documented in repo CLAUDE.md; not a regression of this feature |
| GitHub Actions / CI integration of the new flag | Not used in CI; install runs locally | If CI adopts `skills-deploy install`, that's a future feature |
| Migration of multiple skills at once | T000013 only flips `company-workflow` | Subsequent deprecations are separate tasks; the loop logic is already covered |
