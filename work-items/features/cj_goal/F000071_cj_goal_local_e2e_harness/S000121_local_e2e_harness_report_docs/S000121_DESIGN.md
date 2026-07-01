---
type: design
parent: S000121
feature: F000071
title: "Local-E2E harness + materialized report + workflow docs (Part B/C) — Design"
version: 1
status: Approved
date: 2026-06-30
author: chjiang
---

<!-- The atomic-story design. The full /office-hours design context is the
     parent feature's APPROVED doc (Part A already shipped as S000120); this
     story builds the tracked follow-on, Part B + Part C. -->

## Design context (parent)

The /office-hours session for the parent feature F000071 produced the APPROVED
design doc that scopes this whole workstream. Part A (the dormant, CI-green
build-gate auto-answer seam) shipped as S000120 (v6.0.99). **This story builds
the tracked follow-on the parent doc captured: Part B (the local-E2E harness +
its materialized report) and Part C (the workflow-docs entry + the
test-hierarchy update).**

The load-bearing finding the parent doc established: the automated real
happy-path E2E is blocked in CI four ways (gstack not installed; the eval
harness runs read-only tools; the per-case budget; the interactive AUQs) AND,
even locally, by the AUQ wall — a headless run blocks at the first human gate.
The honest path is a LOCAL real run that drives the cj_goal *build* gates via the
Part-A seam (NEVER the ship/merge/deploy gates), stopping at the `/ship` boundary
in a sandbox, and writing a legible coverage report.

## What this story builds

- **Part B — the local-E2E harness (`scripts/e2e-local.sh`) + its materialized
  report.** Provisions a sandbox (a `mktemp` clone + the `.cj-e2e-sandbox` marker
  + a LOCAL bare origin that accepts push but defeats `gh pr create`), runs a
  REAL `/CJ_goal_task` build unattended via the Part-A seam, stops at the `/ship`
  boundary, and writes a report distinguishing DETERMINISTIC checks from the
  `claude --print` parts — each row verified by real post-run grep evidence
  (a new `work-items/tasks/T*/` dir, a non-empty diff, the run's `end_state`).
- **Part C — documentation.** Extends the existing `utilities-and-phase-steps`
  roster in `spec/workflow-spec.md` with a `### scripts/e2e-local.sh` subsection
  (regenerated into `docs/workflows/`), and updates `docs/tests/test-hierarchy.md`
  so the "full happy-path E2E" layer reads "local-only, real run via the seam,
  emits a materialized report."

## The CI-green / CI-skip split

The whole harness is gated on `CJ_E2E_LOCAL=1`. With the flag unset (CI + a normal
`test.sh`), the harness SKIPs with one note and touches no model. The parts that
ARE deterministic — the sandbox provision/teardown and the report generator — are
unit-tested with synthetic evidence (no Claude) so the story has a real CI-green
smoke suite beyond the bare skip path. The one part that needs a real model run is
the `/CJ_goal_task` orchestration itself; that is a LOCAL manual verification
(needs gstack + `ANTHROPIC_API_KEY` + `gh` + budget), never a CI green.

## Safety (inherited from Part A)

The harness only ever activates the Part-A seam, whose allowlist is `{design-gate,
qa-audit}` — it can NEVER auto-answer a gstack ship/merge/deploy gate. The sandbox's
LOCAL bare origin is the sole backstop that stops `task`'s already-suppressed `/ship`
diff-review AUQ from reaching a real `gh pr create`; that no-remote stop is an
explicitly tested invariant. `.cj-e2e-sandbox` is gitignored + validate-checked
absent (Part A's Check 29), so the marker can never leak into a real tracked tree.

## Links

- Parent feature design (APPROVED /office-hours doc): the F000071 design in
  `~/.gstack/projects/` — the Part B/C scope + the three-review fixes.
- Part A story: `S000120_build_gate_auto_answer_seam/` (the seam this harness drives).
