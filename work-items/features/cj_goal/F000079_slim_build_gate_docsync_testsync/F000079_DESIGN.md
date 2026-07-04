---
type: design
parent: F000079
title: "Slim the cj_goal build gate — take inline doc-sync + test-sync off the per-PR path (deterministic-agentic split) — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

## Problem

Every orchestrated `CJ_goal_*` build still pays for two SLOW agent-driven sync
steps INLINE on the per-PR critical path, even after F000076 moved the agent-judged
AUDIT off it:

1. **doc-sync — Step 5.5 `/CJ_document-release`** (gate `doc-sync`, order 45; all
   four orchestrators). Its slow payload is the upstream LLM pass that rewrites the
   human-doc prose (README / CHANGELOG / CLAUDE.md).
2. **test-sync — QA Step 8.6a/8.6b** (unconditional on every green QA path): the
   agent-judged refresh of the `spec/test-spec-custom.md` (`units:`) +
   `spec/doc-spec-custom.md` overlays.

The deterministic obligations are already enforced per-PR by `validate.sh` (Checks
15-19/24/26/27/28), and — crucially — `/CJ_document-release` does NOT regenerate
the catalogs (`--render-docs` is owned by the implement phase). So the SLOW part is
the AGENTIC part, and it is advisory: F000076 already stood up the nightly
`claude --print` sweep (`audit-nightly.sh` → the `audit-drift` issue) that catches
exactly this class of drift.

## Shape of the solution

Apply F000076's deterministic-agentic split to doc-sync + test-sync:

- **Keep the FAST deterministic sync inline.** Replace Step 5.5's slow
  `/CJ_document-release` LLM pass with an idempotent deterministic doc-regen
  (`test-spec.sh` + `workflow-spec.sh --render-docs`), so the per-PR gate stays
  green with no model spend. Keep the `Step 5.5: Doc-sync` heading + the
  `[doc-sync-red]` / `[doc-sync-non-doc-write]` halt markers (reframed to the
  deterministic engine) so the gate shape + guard stay stable.
- **Move the SLOW agentic work off the path** via a new `DEFER_SYNC: true` QA
  directive (sibling of `DEFER_AUDIT`): orchestrated QA runs only the DETERMINISTIC
  half of 8.6a/8.6b (a new `tests/*.test.sh` gets its required `units:` row) and
  skips the agent-judged amendment sweep. Standalone `/CJ_qa-work-item` keeps the
  full sweep. The EXISTING nightly audit is the safety net — no new nightly job.
- **Keep the deterministic per-PR gate UNCHANGED.**

Then enforce the slimmed shape through the two-axis test contract (category ×
layer): a `category: workflow, layer: CI-push, mode: deterministic` test
(`cj-goal-gate-shape`) backed by a `level: integration` behavior
(`build-gate-no-inline-slow-sync`), so `/CJ_test_audit` reports it wired and
`/CJ_test_run` runs it — and the existing `tests/cj-goal-doc-sync-wiring.test.sh`
guard gains checks asserting no inline `/CJ_document-release`, the deterministic
regen, and the `DEFER_SYNC` wiring.

Single atomic user-story (the guard asserts the slimmed shape, so it cannot land
before the shape changes).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Deterministic-agentic split, not a blanket removal | doc/test sync WRITES files the PR needs, and some writes are REQUIRED for `validate.sh`. Keeping the fast deterministic regen inline preserves the green gate + structural same-PR sync; only the slow AGENTIC work defers. The honest F000076 shape. |
| 2 | Reuse the EXISTING nightly audit; add no new job | `audit-nightly.yml` already catches the deferred prose/overlay drift and files the `audit-drift` issue. |
| 3 | New `DEFER_SYNC: true` directive, not overloading `DEFER_AUDIT` | Audit is an advisory READ; sync is a productive WRITE — a distinct, legible concern. |
| 4 | Enforce via the two-axis category contract, `level: integration` (not `level: workflow`) | The invariant spans the four orchestrators + qa.md, not one orchestrator's run — Check 28 reserves `level: workflow` for one-orchestrator coverage. Mirrors the sibling `workflow-doc-audit-runs`. |
| 5 | Single-story, one atomic PR | The inverted/extended guard asserts the slimmed shape; the gate row, pipelines, qa.md, and regenerated docs must be mutually consistent for `validate.sh` to pass. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Self-modifying pipeline (this build edits the orchestrators running it). | The run's own Step 5.5 executes with the pipeline text loaded at invocation; the EDIT affects only future runs. The guard test verifies the slimmed shape. |
| A build that changes CLAUDE.md-relevant behavior no longer refreshes prose in-PR (F000036's same-PR thesis narrows to STRUCTURE). | Accepted trade (operator chose the split). The nightly `/CJ_doc_audit` Stage 3 catches stale prose → `audit-drift` issue. THIS PR updates its own CLAUDE.md prose. |
| Removing slow doc-sync silently reddening Check 26/27. | The deterministic regen that REPLACES Step 5.5 runs `--render-docs` idempotently before `/ship`. Verified: Checks 26/27 green. |
| `DEFER_SYNC` handshake drift (orchestrator passes it but qa.md doesn't honor it). | The guard asserts all four QA dispatches pass `DEFER_SYNC: true` AND qa.md gates the sweep on it. |
| Rendered registry fields carrying work-item IDs (human-doc contract). | Behavior/category/coverage rendered fields kept ID-free; verified via `--render-docs` + `--validate`. |

## Definition of done

See the parent `F000079_TRACKER.md` Acceptance Criteria (mirrored there). In brief:
Step 5.5 deterministic regen across all four pipelines; `DEFER_SYNC` in qa.md +
the four dispatches; the gate reframe + behavior + coverage + category row; the
extended guard; the audit-nightly framing + CLAUDE.md prose; `validate.sh` +
`test.sh` + `shellcheck` green; standalone skills unchanged.

## Not in scope

- The deterministic per-PR gate (`validate.sh` / `validate.yml` / pre-commit) —
  untouched.
- Standalone `/CJ_qa-work-item` — full inline sweep KEPT; only the `DEFER_SYNC` path
  changes.
- `/CJ_document-release`, `/CJ_doc_audit`, `/CJ_test_audit` — the skills themselves
  unchanged.
- A new nightly job, or an automated nightly doc-sync PR that writes the deferred
  prose fix — the safety net is report-only (the `audit-drift` issue), matching
  F000076's posture.

## Pointers

- Precedent: F000076 (`work-items/features/cj_goal/F000076_qa_gate_slim_audit_to_nightly/`).
- Two-axis framework built on: F000078 (`work-items/features/ops/F000078_two_axis_test_contract/`).
- Origin of the same-PR doc-sync thesis being narrowed: F000036.
- Child story (authoritative file inventory): [S000129_deterministic_agentic_split/S000129_SPEC.md](S000129_deterministic_agentic_split/S000129_SPEC.md)
