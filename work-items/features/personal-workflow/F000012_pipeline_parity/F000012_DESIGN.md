---
type: design
parent: F000012
title: "Pipeline parity: per-type implement/qa + Step 18 comma-split fix — Feature Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Distilled from source design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-pipeline-parity-design-20260508-180219.md
     Skip-/office-hours pattern (small, well-scoped P3 work bundled per user preference). -->

## Problem

The F000010 pipeline (`/scaffold-work-item` → `/implement-from-spec` → `/qa-work-item`) has two known gaps surfaced during the F000011 dogfood on 2026-05-08:

1. **Pipeline coverage is partial.** `/scaffold-work-item` handles all 4 work-item types (feature/user-story/task/defect), but `/implement-from-spec` (S000018 SPEC AC-7) and `/qa-work-item` (S000019 SPEC AC-7) explicitly reject anything that's not a user-story. A defect or task tracker that's been scaffolded cannot flow through the pipeline.
2. **`/personal-workflow check` Step 18 traceability parser misses multi-AC cells.** Step 18 prose at `skills/personal-workflow/check.md:339-371` says "extract all values from the AC column" without specifying comma-handling. Real TEST-SPEC files contain `AC-1, AC-2, AC-3` style cells (S000018:24, S000018:26, S000019:32). Field-by-field exact-match yields false `[UNTESTED]` findings on multi-AC P0 stories.

Both originally tracked as separate P3 TODOs (#5, #6) in `TODOS.md`. Bundled here as one feature since the small bug (#5) becomes the natural integration test for the medium refactor (#6) once defects can flow through the pipeline.

## Shape of the solution

Two user-stories under this feature, sequenced so story 1 unblocks story 2's verification path:

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Generalize `/implement-from-spec` and `/qa-work-item` to accept all 4 work-item types (read type-appropriate input artifacts per `personal-artifact-manifests.json`) | S000021 | [S000021_per_type_implement_qa/S000021_TRACKER.md](S000021_per_type_implement_qa/S000021_TRACKER.md) |
| Tighten Step 18 prose in `check.md` to explicitly comma-split AC cells before set-membership check; preserve existing placeholder filter | S000022 | [S000022_traceability_comma_split/S000022_TRACKER.md](S000022_traceability_comma_split/S000022_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (generalize per-type) over B (sibling skills) / C (dispatcher) / D (accept) | Existing type-detection plumbing in `/scaffold-work-item` provides the model. Pipeline uniformity beats skill explosion (B) or extra indirection (C). D loses the dogfood path for #5. |
| 2 | Bundle #5 and #6 into one feature with two user-stories instead of separate defects | Small bug (#5) acts as the integration test for the medium refactor (#6). Both ship in one PR and one verification cycle. |
| 3 | Treat `test-plan.md` as the de-facto SPEC for defect implement; RCA is read for context only | `test-plan.md` defines desired post-fix behavior; RCA is "what went wrong + history pointer" the implementer reads to understand what NOT to revert. |
| 4 | Defect QA: treat all `test-plan.md` rows as smoke-equivalent in v1; no E2E subagent dispatch | Defect test-plans don't have the smoke/E2E split that TEST-SPEC has. Splitting later is a v2 concern if defect QA needs deeper coverage. |
| 5 | Feature-level implement/qa: AskUserQuestion to pick a child user-story, not auto-pick | Explicit beats clever. User can ship one child at a time without surprise. |
| 6 | Step 18 fix is prose tightening (worked example + explicit comma-split rule), not a code change | `check.md` is interpreted by the LLM running `/personal-workflow check`. Prose IS the spec. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Per-type branching grows each skill ~30%; new code paths need their own tests | Resolved during S000021 implementation — extend test suite per the F000010 pattern (one fixture per type) |
| Tasks-through-pipeline shipped but no real task work-items exist yet to dogfood | First task work-item flowing through the pipeline post-merge is the verification |
| Defect QA without E2E split may miss user-visible regressions on bigger defects | If gap surfaces post-merge, file a follow-up story to split defect test-plan into smoke + E2E tiers |

## Definition of done

- [ ] `/implement-from-spec` accepts defect work-items and reads RCA + test-plan; existing user-story behavior identical to v1.10.0.
- [ ] `/qa-work-item` accepts defect work-items and reads test-plan; existing user-story behavior identical.
- [ ] `skills/personal-workflow/check.md` Step 18 prose explicitly handles comma-separated AC cells with worked example.
- [ ] Test suite covers: implement-on-defect happy path, qa-on-defect happy path, Step 18 multi-AC TEST-SPEC fixture.
- [ ] Re-running `/personal-workflow check` on F000010 produces no false `[UNTESTED]` findings on multi-AC P0 stories.

## Not in scope

- Tasks-through-pipeline real-world dogfooding — the code path ships in S000021 but verification waits for the first task work-item.
- Smarter feature-level implement/qa (auto-pick a child) — v1 uses AskUserQuestion.
- Defect QA smoke/E2E split — accepted gap; revisit if defect QA needs deeper coverage.
- Any work-item types beyond the 4 already in `personal-artifact-manifests.json`.

## Pointers

- Parent tracker: [F000012_TRACKER.md](F000012_TRACKER.md)
- Roadmap: [F000012_ROADMAP.md](F000012_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-pipeline-parity-design-20260508-180219.md`
- Related: F000010 (pipeline skills, the surface this feature polishes), F000011 (Phase 3 lifecycle-gate auto-update, dogfood that surfaced these gaps)
