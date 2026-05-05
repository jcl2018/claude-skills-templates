---
type: test-spec
parent: S000013_relocate_with_catalog_driven_paths
feature: F000006_relocate_deprecated_skills
title: "Relocate with catalog-driven paths — Test Specification"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
prd: S000013_PRD.md
architecture: S000013_ARCHITECTURE.md
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
| 1 | usability | `skills/` listing post-move | AC-1 | Feature applied | Run `ls skills/` | Output: `personal-workflow` and `system-health` only (no `company-workflow`) | P0 | Integration |
| 2 | usability | `templates/` listing post-move | AC-1 | Feature applied | Run `ls templates/` | Output: `personal-workflow` and `doc-SKILL-DESIGN.md` only (no `company-workflow`) | P0 | Integration |
| 3 | usability | `deprecated/company-workflow/` populated | AC-1 | Feature applied | Run `ls deprecated/company-workflow/` | Output includes: SKILL.md, WORKFLOW.md, bin, philosophy, examples, fixtures, reference, company-artifact-manifests.json, templates | P0 | Integration |
| 4 | core | Mirror invariant byte-identity | AC-2 | MIRROR_SPECS retargeted; work-copilot/ unchanged | Run `./scripts/validate.sh` | Error check 10 reports PASS for all 7 mirror entries; no FAIL or WARN line | P0 | Integration |
| 5 | core | Clean-target install (default) skips company-workflow | AC-3 | `SKILLS_DEPLOY_TARGET` is empty fresh dir | Run `scripts/skills-deploy install` | `~/.claude/skills/company-workflow/` NOT created; exactly 1 WARN line for company-workflow | P0 | E2E |
| 6 | core | Clean-target install with --include-deprecated | AC-3 | Empty target | Run `scripts/skills-deploy install --include-deprecated` | `~/.claude/skills/company-workflow/` created; manifest.skills["company-workflow"].path = `deprecated/company-workflow/SKILL.md` | P0 | E2E |
| 7 | core | doctor reports company-workflow as INFO | AC-3 | After install --include-deprecated runs OR not-installed state | Run `scripts/skills-deploy doctor` | company-workflow reported under INFO; no WARN line for it | P0 | E2E |
| 8 | core | catalog-driven paths in skills-deploy | AC-4 | Feature applied | Run `grep -c "skills/company-workflow" scripts/skills-deploy` | Output: 0 | P0 | Smoke |
| 9 | core | catalog-driven paths in validate.sh line 30 | AC-4 | Feature applied | Read `scripts/validate.sh` line 30 area | Hardcoded `skills/$name/SKILL.md` replaced with catalog-resolved path; error message includes the resolved path | P0 | Smoke |
| 10 | core | test.sh exits 0 | AC-5 | Feature applied | Run `./scripts/test.sh` | Exit code 0; "Failures: 0" | P0 | Integration |
| 11 | core | validate.sh exits 0 | AC-5 | Feature applied | Run `./scripts/validate.sh` | Exit code 0; no errors, no warnings | P0 | Integration |
| 12 | usability | deprecated/README.md exists | AC-6 | Feature applied | Read `deprecated/README.md` | File exists; ~5 lines; explains upstream-truth-for-bundles purpose; references validate.sh Error check 10 | P1 | Smoke |
| 13 | usability | CLAUDE.md documents deprecated/ | AC-7 | Feature applied | Read `CLAUDE.md` conventions section | New line documenting `deprecated/` convention; lines 57, 73, 75 (or post-shift equivalents) reference `deprecated/company-workflow/...` | P1 | Smoke |
| 14 | resilience | Idempotent install | AC-3 | After first --include-deprecated install | Run `scripts/skills-deploy install --include-deprecated` again | No-op (already installed); no error; exit 0 | P1 | E2E |
| 15 | resilience | Pre-existing install on real user machine | AC-3 | Mock: pre-existing `~/.claude/skills/company-workflow/` from a v1.2.0 install (path field still `skills/company-workflow/SKILL.md`) | Run `scripts/skills-deploy install --include-deprecated` | No-op; no error; manifest path may be stale but functional | P2 | E2E |
| 16 | core | scripts/test.sh COMPANY_PATH constants | AC-8 (Story #8) | Feature applied | Read `scripts/test.sh` first ~50 lines + run `grep -c "skills/company-workflow" scripts/test.sh` | `COMPANY_PATH` and `COMPANY_TPL` defined; hardcoded ref count = 0 (or only the constant definitions themselves) | P2 | Smoke |

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
| S1 | usability | skills/ contains only active skills | AC-1 | `test -d skills/company-workflow && echo FAIL` |
| S2 | usability | deprecated/company-workflow/ exists | AC-1 | `test -d deprecated/company-workflow/SKILL.md \|\| echo FAIL` |
| S3 | core | No hardcoded skills/company-workflow refs in skills-deploy | AC-4 | `grep -c 'skills/company-workflow' scripts/skills-deploy` should be 0 |
| S4 | core | No hardcoded skills/company-workflow refs in validate.sh outside MIRROR_SPECS comment | AC-4 | `grep -n 'skills/company-workflow' scripts/validate.sh` lines should match expected post-move list |
| S5 | core | catalog files[] points at deprecated/ | AC-4 | `jq -r '.[] | select(.name == "company-workflow") | .files | .[]' skills-catalog.json` returns `deprecated/company-workflow/...` paths |
| S6 | usability | deprecated/README.md exists | AC-6 | `test -f deprecated/README.md` |
| S7 | usability | CLAUDE.md mentions deprecated/ | AC-7 | `grep -q '^- \`deprecated/' CLAUDE.md` |

### Tier 2: E2E Tests (real end-to-end execution)

<!-- Full end-to-end execution: invoke the actual feature, observe output, verify behavior
     matches AC. Requires AI execution. Can be manual (rubric-scored by human) or automated
     via an E2E test skill that creates fixtures and invokes the skill under test. -->

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Clean-target install (default) | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install` 3. `ls $SKILLS_DEPLOY_TARGET/skills/` | personal-workflow and system-health installed; no company-workflow dir; output contains exactly 1 line `WARN: skipping deprecated skill: company-workflow (use --include-deprecated to install)` | Pass: WARN line count = 1, company-workflow absent. Fail: any other line count or company-workflow present. |
| E2 | core | Clean-target install with --include-deprecated | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install --include-deprecated` 3. `ls $SKILLS_DEPLOY_TARGET/skills/company-workflow/` 4. Read `$SKILLS_DEPLOY_TARGET/manifest.json` and inspect `skills["company-workflow"].path` | company-workflow dir exists; manifest path = `deprecated/company-workflow/SKILL.md` | Pass: dir present + manifest path is deprecated/. Fail: dir missing OR manifest path still references skills/. |
| E3 | core | doctor INFO state | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install` 3. `scripts/skills-deploy doctor` | company-workflow appears under INFO line(s); no WARN for it | Pass: INFO line for company-workflow exists; zero WARN for it. Fail: WARN appears or INFO missing. |
| E4 | core | Mirror byte-identity (full validate.sh run) | 1. `./scripts/validate.sh` 2. Inspect output for Error check 10 results | All 7 mirror entries report PASS; exit 0 | Pass: 7/7 PASS. Fail: any FAIL or any unexpected WARN. |
| E5 | core | Full test.sh run | 1. `./scripts/test.sh` 2. Inspect tail of output | "Failures: 0"; exit 0 | Pass. Fail: any failure count > 0. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Behavior on Windows (CRLF in catalog/file paths) | The repo ships on Mac/Linux primary; F000005 already verified D000005 jq CRLF safety in `validate.sh`. F000006 doesn't change that surface. | If a Windows user clones, runs install, and hits a path-separator issue, that's an isolated future fix, not a behavior change introduced by F000006. |
| Cross-machine sync of pre-existing manifest path field | Manifest path stale after upgrade is a known acceptable state — F000006 doesn't auto-rewrite manifests. Tested as P2 idempotency case (E2). | Stale path field with functional install is acceptable; user runs `skills-deploy remove && install --include-deprecated` to refresh if needed. |
| Performance regression on `validate.sh` after orphan-check extension to `deprecated/` | `validate.sh` runs in <2s today; adding one more directory walk adds negligible overhead. | If validate.sh runtime regresses noticeably (>10s), that's a separate optimization concern. |
| Concurrent install on the same target | F000005 didn't test it; F000006 doesn't change concurrency behavior. | No new race conditions introduced. |
| External downstream consumer with hardcoded `skills/company-workflow` paths | Out of scope (workbench-only scope per CLAUDE.md and user memory). | If a downstream user has a workflow grep-ing `skills/company-workflow/`, they get the same behavior as before for `~/.claude/skills/company-workflow/` (destination unchanged); only repo source path changed. |
