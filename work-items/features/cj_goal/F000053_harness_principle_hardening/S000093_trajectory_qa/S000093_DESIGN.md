---
type: design
parent: F000053
title: "Trajectory QA — QA that cannot lie about correctness — Story Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

GAP A (P4) of F000053: cj_goal verification can lie about correctness on the user-story/feature path. Two distinct resume mechanisms skip a genuine QA re-run — `qa.md` Step 3's NO-OP short-circuit (the date-only `[qa-pass]` branch) and `CJ_goal_feature/pipeline.md`'s phase-granular resume that skips the whole QA phase when `LAST_PHASE ∈ {qa, ship}` on a still-valid SHA. A same-SHA resume where untracked/generated/fixture/environment state changed can therefore report ready without re-verifying. See parent F000053_DESIGN.md for the feature-level context (the five harness-engineering principles).

## Shape of the solution

This story is the first child of F000053 (correctness-first). On resume, QA re-validates (re-runs smoke + checks an execution receipt) and re-runs the expensive E2E subagent ONLY when the receipt is missing/incomplete/stale-SHA; QA emits a structured execution receipt (work-copilot `receipts.qa` schema) and fails closed when it is missing/incomplete. See parent F000053_DESIGN.md for how the three stories decompose.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Trajectory QA — re-verify on resume, execution receipt, fail closed (P4 / GAP A) | S000093 | S000093_TRACKER.md |

## Big decisions

See parent F000053_DESIGN.md for the feature-level decisions (correctness-first sequence, the Codex reframe).

| # | Decision | Why |
|---|----------|-----|
| 1 | Adopt work-copilot's `receipts.qa` schema verbatim rather than inventing a receipt shape | Premise 4 "do not reinvent"; it is a near-exact prototype and Story 3 reuses the same schema (one schema, not two). |
| 2 | Fix BOTH skip paths (`qa.md` marker AND `pipeline.md` phase-skip) as two named changes | They are independent holes in two files; closing only one leaves the other open. |
| 3 | Gate the ~5-min E2E re-run on a missing/incomplete/stale receipt rather than re-running unconditionally | Cost-curation (P1) — receipt-validate is cheap, E2E is the expensive path. |

## Risks & open questions

See parent F000053_DESIGN.md `## Open Questions` for the S1/S3 receipt-home question (generalize `.cj-goal-feature/${branch}.state` vs sibling file).

| Risk / Question | Next check |
|-----------------|-----------|
| Re-execution could thrash Phase-2 gate transitions / journal entries | Resolved by AC5 — reuse the `qa.md` Step 6.5 run-start marker for write-idempotency; verified by the second-run-no-duplicate smoke test. |
| Receipt home: generalize `.cj-goal-feature/${branch}.state` or add a sibling receipt file | Leaning generalize-in-place; S1 sets the shared schema (whichever of S1/S3 ships first). Resolve in implement. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] AC1–AC5 (SPEC `## Acceptance Criteria`) verified met
- [ ] Smoke + E2E rows (TEST-SPEC) pass; every AC mapped to a passing row
- [ ] Green on `scripts/validate.sh` + `scripts/test.sh` + the windows-latest Git-Bash job
- [ ] PR-stopped for human review (no auto-deploy of the QA/orchestrator surface)

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Defect/task QA re-run behavior — already re-runs unconditionally (`CJ_goal_defect/pipeline.md:857`); this gap is the user-story/feature path only.
- Story 2 (permission policy) and Story 3 (within-phase receipts) — separate child PRs of F000053.
- P2 (state) and P3 (handoff) — already strong; not touched.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000053_TRACKER.md](../F000053_TRACKER.md)
- Parent design: [F000053_DESIGN.md](../F000053_DESIGN.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-tender-elion-267bd0-design-20260606-204310.md` (Story 1)
- Receipt schema prototype: `work-copilot/prompts/qa.prompt.md:222-285` (`receipts.qa`)
