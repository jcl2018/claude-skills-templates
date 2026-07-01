---
type: design
parent: F000071
title: "Build-gate auto-answer seam (dormant, CI-green) — Feature Design"
version: 1
status: Draft
date: 2026-06-30
author: chjiang
reviewers: []
---

<!-- Atomic-story design. This is a brief stub: the full cross-story design
     context lives on the parent feature F000071_DESIGN.md. -->

## Problem

A headless cj_goal run blocks at the first human-gate `AskUserQuestion` (the
autonomy ceiling), so the autonomous BUILD cannot be proven end to end even
locally. This story builds the prerequisite SEAM the real-run harness needs: a
dormant, CI-green way to auto-answer ONLY the cj_goal *build* gates (design-gate,
qa-audit) under a hard guard — never the ship/merge/deploy gates. See the parent
F000071_DESIGN.md for the full problem framing.

## Shape of the solution

A pure deterministic verdict helper plus uniform agent-prose in the four cj_goal
pipelines. The mechanism is split because the gates are agent-emitted AUQ calls,
not shell.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The verdict helper + the seam prose + the marker guard + the deterministic test | S000120 | [S000120_SPEC.md](S000120_SPEC.md) |

- **(a) verdict helper** `scripts/cj-e2e-gate.sh --gate <design-gate|qa-audit> [--digest <...>]` → prints exactly `AUTO=continue|halt|inactive` (guard + allowlist + green-digest logic). Pure, deterministic, unit-testable.
- **(b) agent-prose** in each pipeline.md AUQ step: run the helper first; `continue` → skip the AUQ + print the `[E2E-AUTO]` banner + proceed; `halt` → `[qa-audit-declined]`; `inactive` → fire the AUQ unchanged.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Scope = Part A ONLY (the dormant seam + its non-activation proof) | Fully unit-tested (no Claude), changes no real run's behavior, lands as one low-risk mergeable PR, and is the prerequisite Part B needs. Parts B/C are tracked follow-on on F000071. |
| 2 | Verdict helper + agent-prose, NOT a shell suppressor | The gates are agent-emitted AUQ calls; a shell helper cannot suppress them. A pure verdict function does the logic (unit-testable); the pipeline prose branches on it. |
| 3 | Generalize `todo_fix --quiet`'s green-only continue predicate | One auto-continue path, two triggers: `QUIET=1 OR (CJ_GOAL_E2E_AUTO=1 AND marker)`; continue ONLY on `doc:ok,test:ok`, HALT on findings, NEVER auto-waive. |
| 4 | Double hard guard + banner + marker gitignore + validate marker-absence check | Active ONLY when BOTH `CJ_GOAL_E2E_AUTO=1` AND `.cj-e2e-sandbox` present; a loud `[E2E-AUTO]` banner; the marker is gitignored AND a `validate.sh` check hard-fails if it is tracked. |
| 5 | Standalone `cj-e2e-gate.sh` helper home | Simplest to unit-test as a pure deterministic verdict function (Open Question 3, resolved). |
| 6 | design-gate is feature-only; the qa-audit seam is shared across four | Only `CJ_goal_feature` has Step 2.7 (design gate); qa-audit is the post-sync audit checkpoint shared by all four verbs. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Seam widens to auto-answer a ship/merge/deploy gate | TEST-SPEC asserts a non-allowlisted gate id → `inactive` (the allowlist is `{design-gate, qa-audit}` only). |
| Marker leaks into a real repo's tracked tree | The marker is gitignored AND a `validate.sh` marker-absence check hard-fails if tracked; covered by a `zzz-test-scaffold` fixture row in `scripts/test.sh`. |
| Editing 4 sensitive pipeline files drifts a normal run's behavior | TEST-SPEC asserts a normal run (no guard) is behavior-unchanged: the helper returns `inactive`, the AUQ fires unchanged. |

## Definition of done

- [ ] `cj-e2e-gate.sh` verdict matrix asserted by `tests/cj-e2e-gate.test.sh` (no Claude).
- [ ] The 4 pipelines branch on the helper at the qa-audit step (+ design-gate in `CJ_goal_feature`).
- [ ] A normal run is behavior-unchanged.
- [ ] `.cj-e2e-sandbox` is gitignored + validate-checked-absent.
- [ ] CI-green: `validate.sh` 0 errors; `test.sh` green.

## Not in scope

- Part B (the local-E2E harness + sandbox + the real `/CJ_goal_task` run + the materialized report) — tracked follow-on on F000071.
- Part C (the workflow-docs roster entry + the `docs/tests/test-hierarchy.md` placement work beyond the single seam note) — tracked follow-on on F000071.
- Auto-answer of ANY gstack ship / merge / `/land` / deploy gate — EXPLICITLY NEVER built.

## Pointers

<!-- Cross-links to related artifacts. Use relative paths from the story directory. -->

- Parent tracker: [../F000071_TRACKER.md](../F000071_TRACKER.md)
- Parent design: [../F000071_DESIGN.md](../F000071_DESIGN.md)
- This story's SPEC: [S000120_SPEC.md](S000120_SPEC.md)
- This story's TEST-SPEC: [S000120_TEST-SPEC.md](S000120_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-happy-e2e-design-20260630-153711.md`
