---
type: test-spec
parent: S000113
feature: F000068
title: "Wire the recap into the 4 pipelines + reframe the CLAUDE.md convention — Test Specification"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

<!-- Automated regression. The wiring is prose-in-markdown, so the structural
     checks are grep-based confirmations + the existing suite staying green.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | The recap pointer is present at the terminal step in the two PR-stop pipelines | feature + task pipelines reference `--phase recap` at their STOP-at-PR block | `grep -l 'phase recap' skills/CJ_goal_feature/pipeline.md skills/CJ_goal_task/pipeline.md` |
| S2 | core | AC-2 | The recap pointer is present around the land step in the two landing pipelines | defect + todo_fix pipelines reference `--phase recap` (before + after) around their land | `grep -c 'phase recap' skills/CJ_goal_defect/pipeline.md skills/CJ_goal_todo_fix/pipeline.md` |
| S3 | usability | AC-3 | `CLAUDE.md` `## Post-land recap` names the helper and keeps the advisory framing | The reframed convention mentions `cj-goal-common.sh --phase recap` and "advisory" / "never blocks" | `grep -A40 '## Post-land recap' CLAUDE.md` |
| S4 | integration | AC-5 | No change to upstream `/land-and-deploy` | The diff touches only this repo's pipeline.md / CLAUDE.md / docs, not the upstream skill | `git diff --name-only` review |
| S5 | observability | AC-6 | The full suite stays green with the wiring | `validate.sh` (and `test.sh`) pass; no new check introduced | `bash scripts/validate.sh` |

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-4 | Read each pipeline's land/PR-stop step and confirm the recap reads correctly | Open each of the 4 pipeline.md files at its terminal/land step; read the recap call + its 3-part field content + the prose fallback note | feature/task each show one at-PR 3-part recap; defect/todo_fix each show a before+after pair around the land; every call site documents the prose fallback | PASS if all four pipelines present the recap at the right point with the right count and a documented prose fallback (AC-4) |
| E2 | usability | AC-3, AC-6 | Read the reframed CLAUDE.md convention and confirm doc-sync is clean | Read `CLAUDE.md` `## Post-land recap`; run `bash scripts/validate.sh` | The convention describes the 3-part before+after shape, names the helper, states the agent authors the content, keeps the advisory framing; validate green | PASS if the section reads as a coherent 3-part before+after convention and validate exits 0 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Automated assertion that each pipeline references the recap | Advisory posture — no `validate.sh` presence-check (parent decision); the grep confirmations are manual at QA, not gated | A pipeline could silently drop the pointer; accepted as the chosen posture. |
| Runtime behavior of the recap inside a live cj_goal land | The pipelines are prose instructions executed by the agent at runtime; a full live land is out of scope for this PR (the helper itself is unit-tested in S000112) | A wiring mistake (wrong `--when`, wrong field) would only surface on a live run; mitigated by the E2E read-through. |
