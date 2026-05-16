---
type: test-spec
parent: S000049
feature: F000024
title: "v1.0 single-defect mode — /CJ_goal_investigate skill + pipeline + chain — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | SKILL.md frontmatter validates | Skill is discoverable; catalog entry consistent | `./scripts/validate.sh` |
| S2 | core | AC-5 | RCA section-heading mapping unit test | Orchestrator writes ALL 7 RCA headings in correct order | `bash skills/CJ_goal_investigate/scripts/test-rca-mapping.sh` (new) |
| S3 | core | AC-7 | Idempotency resume-row classifier | 5-row table returns correct row per (RCA, fix, PR-open, PR-merged) combination | `bash skills/CJ_goal_investigate/scripts/test-resume-table.sh` (new) |
| S4 | core | AC-8 | --dry-run writes nothing | filesystem unchanged after dry-run completes | `bash skills/CJ_goal_investigate/scripts/test-dry-run.sh` (new) |
| S5 | resilience | AC-9 | Halt-on-red writes journal entries with required fields | each of 9 halt entries contains `next_action=`, `resume_cmd=`, `raw_output_path=` (where applicable) | `bash skills/CJ_goal_investigate/scripts/test-halt-journal.sh` (new) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3, AC-5, AC-6, AC-12 | Happy path: dispatch real defect end-to-end | 1. Pick an existing scaffolded defect with empty/light RCA. 2. Run `/CJ_goal_investigate <D-id>`. 3. Observe /investigate dispatch. 4. Verify RCA + test-plan written. 5. Approve /ship Gate #2. 6. Observe land-and-deploy. | RCA populated with all 7 headings; test-plan has regression row; PR shipped; `[investigate-shipped]` in journal | All steps complete without operator intervention except Gate #2 |
| E2 | core | AC-2 | Fragment fuzzy ambiguity halt | Run `/CJ_goal_investigate "common-fragment"` where 2+ defects match | Halt with ranked candidate list + copy-paste re-run command | Halt is clean; suggested re-run command resolves cleanly |
| E3 | core | AC-8, AC-15 | --dry-run preview | Run `/CJ_goal_investigate --dry-run <D-id>` | Plan + idempotency state + expected write paths printed; no files written; suggested resume command shown | `git status` shows no modifications |
| E4 | resilience | AC-10 | DONE_WITH_CONCERNS halt | Inject a scratch /investigate that returns JSON.status="DONE_WITH_CONCERNS" | Orchestrator halts pre-ship with `[investigate-unverified]`; does NOT advance to /ship | journal entry present; PR not created |
| E5 | integration post-ship | AC-12, AC-13 | /ship Gate #2 + /land-and-deploy chain | E1 happy path (post-merge verification) | After merge: tracker journal contains `[investigate-shipped] D000NNN vX.Y.Z PR #NNN` | PR merged via Gate #2; deploy verified by canary |

<!-- E5 is tagged post-ship because the journal entry `[investigate-shipped]` is only
     observable after /land-and-deploy completes; /CJ_qa-work-item Step 4 will defer
     this row out of the E2E subagent dispatch. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent runs on the same defect (race) | v1 scope: lock deferred to v1.1 (family-drain lock design). | Two concurrent runs may double-write artifacts; operator-visible (git conflicts). |
| `/investigate` returning sentinel-wrapped JSON every time without backslide | Phase 1 of impl validates against live /investigate; no automated guard for upstream changes. | If gstack changes /investigate behavior post-ship, our parser may fail; halts cleanly with `[investigate-no-sentinel]` rather than misbehaving. |
| Cross-skill drain interactions (e.g. /CJ_goal_todo_fix + /CJ_goal_investigate running together) | Drain mode is v1.1; v1 only supports explicit invocation. | Not relevant for v1. |
| Ad-hoc bugs without scaffolded defect dir | v2.0 scope. | Not applicable; v1 refuses on missing dir. |
| Hot-fix path with compressed gates | v2.0 scope. | Not applicable; v1 enforces full chain. |
