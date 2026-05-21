---
type: test-spec
parent: S000059
feature: F000027
title: "/cj_goal_feature skill — office-hours-inline -> silent build -> PR-stop, strengthened resume — Test Specification"
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
| S1 | core | AC-1 | `skills/cj_goal_feature/SKILL.md` exists with valid frontmatter + a catalog `experimental` entry whose dir exists | Skill installable, catalog ↔ filesystem consistent | `bash scripts/validate.sh` |
| S2 | core | AC-3 | SKILL.md contains no autoplan invocation and no auto-merge/`gh pr merge` on the path | Auto-deploy excluded; PR-stop end state | `grep -LiE 'autoplan|gh pr merge|--auto-merge' skills/cj_goal_feature/SKILL.md` |
| S3 | usability | AC-2 | SKILL.md suppresses `/ship`'s diff-review AUQ and STOPs after PR | Zero AUQ between approval and PR | `grep -iE 'suppress.*diff-review|STOP at PR' skills/cj_goal_feature/SKILL.md` |
| S4 | resilience | AC-4, AC-5 | SKILL.md/pipeline doc defines the resume state (`last_completed_phase` + HEAD SHA + PR#) with validate-before-skip + recorded-path office-hours recovery | Strengthened resume contract present | `grep -iE 'last_completed_phase|ancestor|Status: APPROVED' skills/cj_goal_feature/*.md` |
| S5 | observability | AC-6 | A run appends one JSONL line to `~/.gstack/analytics/CJ_goal_feature.jsonl` | Telemetry schema mirrors the family | `bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3 | Author builds a feature from a one-line topic | Run `/cj_goal_feature "<a small topic>"` from clean `main`, approve at the office-hours Approve gate, then do nothing | Worktree → office-hours → APPROVED → silent scaffold/impl/qa → `/ship` opens a PR → STOP, with zero AUQ after approval and no auto-merge | PASS if a PR is opened and the run stops with no AUQ between approval and PR; FAIL on any mid-flight AUQ or any auto-merge/deploy |
| E2 | resilience | AC-4 | Resume after a halt with a moved tree | Halt a run mid-build, force-push / amend so the recorded SHA is no longer an ancestor of HEAD, then re-invoke `/cj_goal_feature` | The affected phase restarts instead of skipping ahead on the stale flag | PASS if the phase restarts when SHA/PR validation fails; FAIL if it trusts the flag and skips |
| E3 | resilience | AC-5 | Resume at office-hours on an unchanged APPROVED doc | With `last_completed_phase=office-hours` and an unchanged APPROVED doc at the recorded path, re-invoke `/cj_goal_feature` | It re-locates the doc by recorded path, re-confirms APPROVED, and proceeds to scaffold without re-running office-hours | PASS if office-hours is not re-run and the build proceeds; FAIL if it re-runs office-hours or newest-globs |

<!-- E2E test skill: none for this story. The S000057 early feature smoke harness
     validates the path shape before this skill lands. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Auto-merge override path (Open Question 1) | Dropped from scope; only built if the author re-opens it | If re-opened later, it needs its own gate-profile tests |
| Deep office-hours interactive correctness | Owned by the upstream `/office-hours` skill | A bad design-doc is an office-hours issue, not a `cj_goal_feature` issue |
| Live `/land-and-deploy` | Out of scope — `feature` STOPs at the PR; deploy is a separate human step | No deploy risk introduced by this story |
