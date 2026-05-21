---
type: test-spec
parent: S000058
feature: F000027
title: "/cj_goal_defect skill — reshape of investigate v1.1 + no-doc bug-report scaffolding — Test Specification"
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
| S1 | core | AC-1 | `skills/cj_goal_defect/SKILL.md` exists with valid frontmatter (name + description) | Skill is installable and discoverable | `bash scripts/validate.sh` |
| S2 | core | AC-1 | `skills-catalog.json` has an `experimental` entry for `cj_goal_defect` whose `files[0]` dir exists | Catalog ↔ filesystem consistency | `bash scripts/validate.sh` |
| S3 | integration | AC-4 | SKILL.md tail references `/ship` Gate #2 then `/land-and-deploy --suppress-readiness-gate` | Human-gated deploy tail wired (matches investigate) | `grep -E 'land-and-deploy --suppress-readiness-gate' skills/cj_goal_defect/SKILL.md` |
| S4 | core | AC-2 | SKILL.md dispatches `/investigate` as an Agent subagent with the Iron-Law gate before promotion | Iron-Law enforced before any fix | `grep -iE 'Iron-Law|root cause' skills/cj_goal_defect/SKILL.md` |
| S5 | observability | AC-4 | A defect run appends one JSONL line to `~/.gstack/analytics/CJ_goal_defect.jsonl` | Telemetry schema mirrors the family | `bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3 | Author fixes a real bug from a plain description | Run `/cj_goal_defect "<a real bug description>"` from clean `main` | A worktree is created, `.inbox/<slug>/DRAFT.md` is scaffolded, then (after root cause) promoted to a `D000NNN_<slug>/` defect dir with RCA + test-plan | PASS if the draft scaffolds and promotes only after a root cause; FAIL if it promotes without one or skips scaffolding |
| E2 | core | AC-2 | Iron-Law blocks a fix with no root cause | Run `/cj_goal_defect` on a bug `/investigate` cannot root-cause (or returns DONE_WITH_CONCERNS) | The pipeline HALTS before promotion/ship and emits `next_action=`/`resume_cmd=` | PASS if nothing is promoted/shipped and a resume_cmd prints; FAIL if any fix proceeds |
| E3 | integration | AC-4, AC-5 | Human-gated deploy completes a fix | Continue a root-caused run through `/CJ_qa-work-item` → `/ship` Gate #2 (approve) → `/land-and-deploy` | The fix deploys after the human approves at Gate #2; tracker journal + telemetry are written | PASS if deploy happens only post-Gate-#2 and the journal/telemetry land; FAIL if it deploys without the human gate |

<!-- E2E test skill: none for this story. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Deep `/investigate` root-cause correctness | Owned by the upstream `/investigate` skill; this story reuses it | A bad root cause is an `/investigate` defect, not a `cj_goal_defect` defect |
| Live `/land-and-deploy` against production | Requires merge + deploy infra; covered by the human at Gate #2 + canary | Deploy regressions surface via canary, not this story's smoke suite |
