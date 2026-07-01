---
type: design
parent: F000071
title: "cj_goal local happy-path E2E harness — Feature Design"
version: 1
status: Draft
date: 2026-06-30
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

F000070 proved each `CJ_goal_*` workflow's entry + one gate (real eval,
gstack-independent). The behavioral upgrade — proving the autonomous BUILD runs
end to end — is blocked in CI four ways and, two adversarial reviews confirmed,
by the **AUQ wall** even locally: a headless run blocks at the first human-gate
AskUserQuestion (the autonomy ceiling). The honest path is a LOCAL real run with
the cj_goal *build* gates auto-answered under a hard guard, NEVER the
ship/merge/deploy gates, stopping at the `/ship` boundary in a sandbox.

Two operator additions shape the feature beyond a bare pass/fail: it must be
documented as discoverable workbench machinery (in the workflow docs, not buried
in test files), and it must emit a materialized run report — not a terminal
checkmark, but a written report showing which parts are DETERMINISTIC vs which
ran via `claude --print`, the task tested, and what each layer covered.

## Shape of the solution

The feature is three parts with a clean CI-green / CI-skip split. **THIS
feature's first shipped story (S000120) is Part A ONLY** — the dormant, CI-green
build-gate auto-answer seam + its non-activation proof. Parts B and C are tracked
follow-on (captured here, not built in S000120).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Part A — build-gate auto-answer seam (deterministic, CI-green): the `cj-e2e-gate.sh` verdict helper + uniform seam prose in the 4 pipelines + marker gitignore + validate marker-absence check + the deterministic verdict-matrix test | S000120 | [S000120_build_gate_auto_answer_seam/S000120_TRACKER.md](S000120_build_gate_auto_answer_seam/S000120_TRACKER.md) |
| Part B — the local-E2E harness (`scripts/e2e-local.sh`) + sandbox + the real `/CJ_goal_task` run + the materialized run report (md + json) — TRACKED FOLLOW-ON | (follow-on) | (not yet scaffolded) |
| Part C — workflow-docs roster entry (extend `docs/workflows/utilities-and-phase-steps.md`) + `docs/tests/test-hierarchy.md` update — TRACKED FOLLOW-ON | (follow-on) | (not yet scaffolded) |

Part A's seam is a pure deterministic verdict helper plus agent-prose in each
pipeline.md AUQ step. The helper (`scripts/cj-e2e-gate.sh --gate
<design-gate|qa-audit> [--digest <...>]`) prints exactly
`AUTO=continue|halt|inactive` from guard + allowlist + green-digest logic. The
agent-prose runs the helper first: `continue` → skip the AUQ + print the
`[E2E-AUTO]` banner + proceed; `halt` → `[qa-audit-declined]`; `inactive` → fire
the AUQ unchanged.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Ship Part A (dormant seam) as the first standalone story (S000120); defer Parts B/C as tracked follow-on | Part A is fully unit-tested (no Claude), changes no real run's behavior (guard off by default), and lands as one low-risk mergeable PR — and it is the prerequisite the real-run harness (Part B) needs. Operator-decided split. |
| 2 | Verdict helper + agent-prose mechanism, NOT a pure shell suppressor | The gates are agent-emitted `AskUserQuestion` calls (prose in pipeline.md); a shell helper cannot suppress them. So a pure deterministic verdict function does the logic (unit-testable) and the pipeline prose branches on it. |
| 3 | Generalize `todo_fix --quiet`'s green-only continue predicate rather than inventing a new one | One auto-continue path, two triggers: fire on `QUIET=1 OR (CJ_GOAL_E2E_AUTO=1 AND marker)`; continue ONLY on `doc:ok,test:ok`, HALT on findings, NEVER auto-waive. Reuse keeps the autonomy ceiling intact. |
| 4 | Double hard guard + loud banner; marker gitignored + validate-checked-absent | The seam is active ONLY when BOTH `CJ_GOAL_E2E_AUTO=1` AND `.cj-e2e-sandbox` exists at repo root; a `[E2E-AUTO]` banner prints when on. The marker is `.gitignore`d AND a `validate.sh` check HARD-fails if it is in the tracked tree — it can never ship into a real repo. |
| 5 | Standalone `cj-e2e-gate.sh` helper home (not a `cj-goal-common.sh` phase) | Simplest to unit-test as a pure deterministic verdict function. (Open Question 3 resolved.) |
| 6 | design-gate is feature-only; the qa-audit seam is the one shared across four orchestrators | Only `CJ_goal_feature` has Step 2.7 (the design gate); qa-audit is the post-sync audit checkpoint shared by all four cj_goal verbs. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seam accidentally widens to auto-answer a gstack ship/merge/deploy gate | S000120 TEST-SPEC asserts the allowlist returns `inactive` for any non-`{design-gate, qa-audit}` id; the no-remote sandbox is the sole auto-ship backstop (Part B). |
| Marker file leaks into a tracked tree of a real repo | S000120: marker `.gitignore`d AND a `validate.sh` marker-absence check that hard-fails if `.cj-e2e-sandbox` is tracked; the new check gets a parallel `zzz-test-scaffold` fixture row in `scripts/test.sh` (the recurring implement blind spot). |
| Part B real run halts before `/ship` on a sensitive-surface topic (`[impl-red]`) | Part B follow-on: the case topic must be a plain non-sensitive, non-doc edit; the boundary assertion accepts a RANGE ("reached at least qa-audit; ideally `/ship`"). |
| Editing 4 sensitive pipeline files risks behavior drift in a normal run | S000120 TEST-SPEC asserts a normal run (no guard) is behavior-unchanged: the helper returns `inactive` and the AUQ fires unchanged. |

## Definition of done

- [ ] **S000120 (Part A):** `cj-e2e-gate.sh` verdict matrix asserted by `tests/cj-e2e-gate.test.sh` (no Claude); the 4 pipelines branch on it; a normal run is behavior-unchanged; `.cj-e2e-sandbox` is gitignored + validate-checked-absent; CI-green.
- [ ] The seam NEVER touches ship/merge/deploy gates.
- [ ] `validate.sh` 0 errors; `test.sh` green.
- [ ] Parts B and C are recorded as tracked follow-on (this DESIGN + ROADMAP), not silently dropped.

## Not in scope

- Part B (the local-E2E harness `scripts/e2e-local.sh` + sandbox + the real `/CJ_goal_task` run + the materialized run report) — TRACKED FOLLOW-ON, not built in S000120.
- Part C (the workflow-docs roster entry + the `docs/tests/test-hierarchy.md` update) — TRACKED FOLLOW-ON, not built in S000120.
- Auto-answer of ANY gstack ship / merge / `/land` / deploy gate — EXPLICITLY NEVER built by the seam (the autonomy ceiling).
- The other cj_goal verbs as Part-B harness cases (feature needs office-hours handling), the `real-pr` depth (scratch GitHub repo), and the CI-automated epic (gstack-in-CI + eval allowedTools + budget) — deferred follow-on beyond this feature.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000071_TRACKER.md](F000071_TRACKER.md)
- Roadmap: [F000071_ROADMAP.md](F000071_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-happy-e2e-design-20260630-153711.md`
- Builds on F000070 (workflow entry + gate eval), F000013 (eval harness).
