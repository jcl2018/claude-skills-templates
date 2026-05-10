---
type: test-spec
parent: S000027
feature: F000014
title: "Personal-pipeline skill implementation — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke = automated regression in CI (validate.sh + fixture-based checks).
     E2E = manual user-scenario verification before /ship.
     Soft cap of 5 rows per tier; this story has 4 smoke + 4 E2E. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `validate.sh` exits 0 after personal-pipeline is in the catalog | Frontmatter, catalog entry, file presence all valid | `./scripts/validate.sh` |
| S2 | core | AC-1 | `skills-deploy install` deploys to `~/.claude/skills/personal-pipeline/` | Deploy plumbing handles the new skill | `./scripts/skills-deploy install && ls ~/.claude/skills/personal-pipeline/SKILL.md` |
| S3 | core | AC-3 | Total skill markdown ≤ 800 lines | Skill stays compact per design constraint | `wc -l skills/personal-pipeline/SKILL.md skills/personal-pipeline/pipeline.md \| tail -1` |
| S4 | observability | AC-7 | pipeline.md instructs halt cases to write `[gate-red]` to tracker journal | Skill source-of-truth declares the durable-halt-reason behavior; runtime verification (a tracker actually receiving the entry) is E2E-tier and runs from the regression-broken-validate fixture | `grep -q '\[gate-red\]' skills/personal-pipeline/pipeline.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2, AC-6 | Happy-path full pipeline run on a small TODO entry | Pick "Fork-aware update detection" P3 entry from TODOS.md. Run `/office-hours` (or hand-write a stub design doc) to produce a design under `~/.gstack/projects/`. Run `/personal-pipeline <design-doc-path>`. Watch all 9 steps execute. AskUserQuestion to approve scaffold shape, then sit through implement + qa. | Final summary prints WORK_ITEM_DIR; tracker has Phase 2 gates green; `/ship` suggested; one telemetry line in `~/.gstack/analytics/personal-pipeline.jsonl` with `end_state=green`. | Pass = single keystroke produced a green work-item; user only AUQ'd at scaffold approval. Fail = subagent loop, multiple manual interventions, or any context-bloat into orchestrator |
| E2 | core | AC-3 | Pre-scaffold idempotency on F000010's already-scaffolded design | Run `/personal-pipeline ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`. F000010's design doc has a Status: SCAFFOLDED footer. | Step 2 takes branch (a); orchestrator skips Phase 1; uses existing F000010 dir for Phase 2/3. End-state telemetry: `green` (Phase 1 properly skipped, not crashed). | Pass = no duplicate F000011 dir created; orchestrator detected the footer correctly. Fail = scaffold subagent dispatched and produced a duplicate |
| E3 | core | AC-4 | Partial-write halt regression | Set up a partial scaffold dir (e.g., F000010 with `F000010_DESIGN.md` deleted) on a design doc whose footer is also removed. Run `/personal-pipeline` on that design doc. | Step 2 takes branch (c); orchestrator detects the partial dir via tracker grep; halts with manual-cleanup AUQ; no Phase 1 dispatch | Pass = halt with clear remediation message. Fail = orchestrator dispatched scaffold and produced a duplicate, or silently overwrote |
| E4 | core | AC-5 | Post-implement gate halts on broken validate.sh | Run pipeline on a design that, when implemented, deliberately produces a catalog entry with missing required fields. | Step 6 (post-implement gate) catches the validate.sh failure; AUQ surfaces with abort/fix/override options; on abort, telemetry end_state=halted_at_gate; tracker journal has `[gate-red]` entry | Pass = halt before Phase 3 dispatch; user can pick abort. Fail = orchestrator continued to Phase 3 despite validate.sh failure |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent pipeline runs | Documented accepted risk in F000014_DESIGN; v1 single-user workbench | If a real collision happens, surfaces as duplicate work-item dir; user resolves manually |
| Multi-story feature decomposition (post-scaffold loop) | Out of v1 scope per F000014 Open Q2 | First multi-story feature post-v1 will exercise the halt-after-scaffold message; if the manual per-child invocation feels wrong, file follow-up |
| Subagent crash mid-write (e.g., network interruption during Phase 2) | Hard to inject deterministically; relies on idempotency contract from S000018 | Re-running orchestrator should resume from first incomplete phase; verified by general re-run pattern, not a dedicated test |
| 5-run sunset AUQ on 6th invocation | Requires 6 real runs to exercise; defer to first encounter post-ship | If the AUQ is confusing, reword on encounter; not a release blocker |
| `RESULT: AUQ_NEEDED=...` propagation when AUQ doesn't bubble (S000026 leg-a fail case) | Conditional — only tested if S000026 finds AUQ doesn't bubble | If S000026 finds AUQ does bubble, this code path doesn't exist in pipeline.md; if not, regression test added at implement time |
