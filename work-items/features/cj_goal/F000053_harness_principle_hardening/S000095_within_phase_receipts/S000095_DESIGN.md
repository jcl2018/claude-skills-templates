---
type: design
parent: F000053
title: "Within-phase receipts — continue from receipts, not transcript — Feature Design"
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

The cj_goal framework compacts BETWEEN phases (the silent build dispatches scaffold / implement / QA as depth-≤2 leaf subagents returning ≤200-token summaries) but never WITHIN a long inline phase. `/office-hours` runs inline (subagents have no AskUserQuestion tool), so its full transcript sits in the orchestrator window through the rest of the build — the GAP C / P1 hole. See parent `F000053_DESIGN.md` for the full five-principle framing.

## Shape of the solution

After the known long inline phases (office-hours first), write a compact phase receipt to `.cj-goal-feature/` and have the orchestrator's post-phase steps READ `$RECEIPT_PATH` rather than depend on the raw transcript. Generalize the existing resume state file into a per-phase receipt chain, reusing S000093's shared receipt schema.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Within-phase context curation at the office-hours boundary (P1) | S000095 | S000095_TRACKER.md |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Generalize the existing `.cj-goal-feature/${branch}.state` file into a receipt chain rather than add a sibling per-phase receipt file | Avoids a second state surface; preserves the proven atomic mktemp+mv write + the ancestor-SHA validate-before-skip contract |
| 2 | Scope to the known long inline phases (office-hours) only — no generic "compact everything" framework | Lowest marginal value + highest over-build risk; overlaps most with Claude Code's built-in auto-compaction, so sequenced last in F000053 |
| 3 | Reuse S000093's receipt schema (one schema, not two) | Whichever story ships first sets the schema; this story consumes it if S000093 lands first |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Receipt-home choice: generalize-in-place vs sibling per-phase file | Leaning generalize-in-place; resolved at SPEC lock (See parent F000053_DESIGN.md Open Questions) |
| Receipt schema is shared with S000093 — ordering decides who sets it | If S000093 ships first, this story consumes that schema; confirmed before implement |
| Over-build risk: drifting into a generic compaction framework | Implement review keeps scope to office-hours only |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] A compact phase receipt is written to `.cj-goal-feature/` at the office-hours boundary via atomic write (AC1).
- [ ] The post-office-hours steps read `$RECEIPT_PATH`; the design-summary digest is sourced from the receipt, not regenerated from context (AC2).
- [ ] Scope stays at the known long inline phases (office-hours); no generic compaction framework (AC3).
- [ ] The receipt reuses S000093's shared schema (AC4).

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- A generic "compact everything" framework — only the known long inline phases (office-hours) are in scope.
- Any change to P2 (state) or P3 (handoff) beyond generalizing the state file into a receipt chain — those habits are already strong (See parent F000053_DESIGN.md).
- A second receipt schema — S000093's schema is reused.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000053_TRACKER.md](../F000053_TRACKER.md)
- Parent design: [F000053_DESIGN.md](../F000053_DESIGN.md)
- Sibling (shared receipt schema): [S000093 Trajectory QA](../S000093_trajectory_qa/S000093_TRACKER.md)
