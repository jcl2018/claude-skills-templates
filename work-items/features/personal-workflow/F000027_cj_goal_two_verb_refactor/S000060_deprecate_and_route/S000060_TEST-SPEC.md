---
type: test-spec
parent: S000060
feature: F000027
title: "Deprecate /CJ_goal_run + /CJ_goal_auto (alias + sunset) + routing + catalog — Test Specification"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | integration | AC-2 | Catalog has `cj_goal_feature` + `cj_goal_defect` as `experimental` and `CJ_goal_run` + `CJ_goal_auto` as `deprecated` | Catalog status enum correct | `bash scripts/validate.sh` |
| S2 | core | AC-1 | `CJ_goal_run`/`CJ_goal_auto` SKILL.md contains a one-line deprecation banner + a route to `/cj_goal_feature` + a sunset version | Alias shims wired with sunset | `grep -iE 'deprecat|/cj_goal_feature|v6\.0\.0' skills/CJ_goal_run/SKILL.md skills/CJ_goal_auto/SKILL.md` |
| S3 | usability | AC-3 | `rules/skill-routing.md` + `CLAUDE.md` route the new verbs and don't recommend `run`/`auto` as primary | Routing updated in both files | `grep -E '/cj_goal_feature|/cj_goal_defect' rules/skill-routing.md CLAUDE.md` |
| S4 | resilience | AC-4 | Catalog still lists `CJ_goal_todo_fix` + `CJ_personal-pipeline` as non-deprecated | Kept skills untouched | `bash scripts/validate.sh` |
| S5 | core | AC-5 | Full suite passes after catalog/routing/shim edits | Repo stays green | `bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Author invokes a deprecated verb | Run `/CJ_goal_run` (then `/CJ_goal_auto`) | A one-line deprecation banner prints (naming the sunset) and the invocation routes to `/cj_goal_feature` | PASS if the banner prints and routing reaches `/cj_goal_feature`; FAIL if it runs the old pipeline or errors |
| E2 | integration | AC-2 | Maintainer installs including deprecated skills | Run `scripts/skills-deploy install` then `scripts/skills-deploy install --include-deprecated` | Default install skips `run`/`auto` with a WARN; `--include-deprecated` installs them for in-flight use | PASS if default skips and `--include-deprecated` installs; FAIL if default installs them or `--include-deprecated` cannot |
| E3 | resilience | AC-4 | Author uses a kept skill after deprecation | Run `/CJ_goal_todo_fix` (and confirm `/schedule`/`/loop` wiring) | The drain utility behaves exactly as before; `/CJ_personal-pipeline` still serves as its engine | PASS if behavior is unchanged; FAIL on any regression in the kept skills |

<!-- E2E test skill: none for this story. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Full deprecated-skill source relocation under `deprecated/` | Open Question — may be a status-flip-only change this story | If relocated later, the catalog-path-derivation tests already cover consumer scripts |
| Actual sunset/removal at the next major | Out of scope — this story only adds the alias + sunset date, not the removal | Removal is a future story; the banner sets the expectation |
