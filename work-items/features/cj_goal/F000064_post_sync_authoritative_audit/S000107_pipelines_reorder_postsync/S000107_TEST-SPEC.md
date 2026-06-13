---
type: test-spec
parent: S000107
feature: F000064
title: "Four cj_goal pipelines reorder — Test Specification"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Soft cap: 5 rows. AC column maps to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-5 | All four pipelines embed `DEFER_AUDIT: true` in their QA dispatch prompt | The defer signal is wired in every orchestrator | `for f in skills/cj_goal_feature/pipeline.md skills/cj_goal_defect/pipeline.md skills/CJ_goal_task/SKILL.md skills/CJ_goal_todo_fix/SKILL.md; do grep -q 'DEFER_AUDIT: true' "$f" || { echo "MISSING in $f"; exit 1; }; done` |
| S2 | core | AC-1 | Each pipeline has a pre-doc-sync commit step | The automated commit exists per file | `grep -rlE 'pre-doc-sync commit' skills/cj_goal_feature/pipeline.md skills/cj_goal_defect/pipeline.md skills/CJ_goal_task/SKILL.md skills/CJ_goal_todo_fix/SKILL.md` |
| S3 | core | AC-2,AC-3 | doc-sync precedes the post-sync audit which precedes the checkpoint | The ordering assertion holds in every pipeline | `./tests/cj-goal-doc-sync-wiring.test.sh` |
| S4 | resilience | AC-6 | The pre-doc-sync commit is idempotent (clean-tree skip) | A resume does not double-commit | `grep -qE 'git diff --quiet|already clean|clean at HEAD' skills/cj_goal_feature/pipeline.md` |
| S5 | integration | AC-2 | Full suite green after the reorder | The reorder does not break validate/test | `./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. One user-visible scenario per row. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,AC-2,AC-3,AC-4 | Feature pipeline post-sync checkpoint | Run `/CJ_goal_feature "<topic>"` through QA-green; observe the order of steps to the checkpoint | Sequence is QA(deferred) → pre-doc-sync commit → doc-sync → post-sync audit → checkpoint; the checkpoint AUQ surfaces the POST-sync audit report | PASS if doc-sync runs before the audit/checkpoint AND the checkpoint shows post-sync findings |
| E2 | core | AC-4 | Checkpoint journal lines unchanged | At the checkpoint, choose Continue-past-findings then (separately) Halt | `[qa-audit-waived]` on continue, `[qa-audit-declined]` + `halted_at_qa_audit` on halt — unchanged meaning, now on the post-sync audit | PASS if the journal lines + end-state match today's semantics |
| E3 | resilience | AC-6 | Resume after the pre-doc-sync commit | Interrupt a run after the commit; resume the same verb | Resume re-runs doc-sync → audit → checkpoint without skipping and without a second commit (clean-tree skip) | PASS if no double-commit and the checkpoint re-surfaces |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Defect/task/todo full E2E walks (only feature E1 is walked) | The four pipelines share the same reorder shape; S3's `cj-goal-doc-sync-wiring.test.sh` asserts ordering across ALL four deterministically | A per-pipeline numbering slip is caught by S3 even without four manual walks |
| The combined audit subagent actually being depth-2 (not spawning a sub-subagent) | Hard to assert statically; the skills' standalone contract enforces one combined subagent | A depth violation would surface as a runtime nested-subagent halt during E1 |
