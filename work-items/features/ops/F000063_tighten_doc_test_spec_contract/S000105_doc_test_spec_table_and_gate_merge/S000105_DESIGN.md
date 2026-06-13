---
type: design
parent: S000105
title: "doc-spec table-ification + test-spec/gate-spec full merge — Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- This atomic story derives directly from the parent feature's /office-hours
     session. The parent feature DESIGN (F000063_DESIGN.md) holds the full
     cross-story design; this stub keeps the 7 sections present and links up. -->

## Problem

The portable spec-contract files are heavy and answer the wrong question:
`spec/doc-spec.md` is prose + a fenced-YAML registry + two generated views (three
copies of one list), and `spec/test-spec.md` states abstract rules rather than
the practical "what tests, what do they do, when do they trigger?" that
`spec/gate-spec.md` already answers in a separate file. See parent
[F000063_DESIGN.md](../F000063_DESIGN.md) `## Problem` for full context.

## Shape of the solution

One atomic story, two internal phases. Phase 1: make `spec/doc-spec.md` a
3-column markdown table that the parser reads directly, deleting the YAML block,
the generated views, their generator, and `--render`; the `_check_on_disk`
engine drops from 6 to 4 checks and re-derives `audit_class` from path
convention. Phase 2: fully merge `spec/gate-spec.md` into the test-spec family —
`layers[]` into the general `test-spec.md`, per-mode `gates[]` into
`test-spec-custom.md` as a new top-level `gates:` array, `gate-spec.sh` into
`test-spec.sh`, Check 22 into Check 24 (marker-drift kept advisory), all four
cj_goal pipelines re-pointed. See parent
[F000063_DESIGN.md](../F000063_DESIGN.md) `## Shape of the solution`. The
requirement-level detail lives in [S000105_SPEC.md](S000105_SPEC.md).

## Big decisions

The four settled decisions (D1 full-merge / D2 table-as-source / D3 dropped
fields with path-derived human-doc / D4 one PR internally sequenced) are recorded
in the parent feature design's `## Big decisions` table — see
[F000063_DESIGN.md](../F000063_DESIGN.md). Story-local: the work is one cohesive
change with no task children; the two phases are build sequencing inside one PR.

## Risks & open questions

The full risk table (engine rewrite, 3-way seed identity, `pipeline-gate`
enum collision, Check 22→24 advisory preservation, Check 24 anchor
self-reference, OQ1/OQ2) lives in the parent
[F000063_DESIGN.md](../F000063_DESIGN.md) `## Risks & open questions`. The
top blocker for this story is the `_check_on_disk` 6→4 engine rewrite, mitigated
by deriving `audit_class` into the parser TSV from the path heuristic.

## Definition of done

`validate.sh` + `test.sh` green after Phase 1, then green again after Phase 2;
3-way seed identity holds; all deleted files are grep-clean of live references;
both audit skills seed + run clean in a bare repo AND in this workbench. See the
full list in [S000105_TRACKER.md](S000105_TRACKER.md) `## Acceptance Criteria`
and parent [F000063_ROADMAP.md](../F000063_ROADMAP.md) `## Success Criteria`.

## Not in scope

`test-spec` → `verification-spec` rename (OQ2); a Check 20 replacement lint
(OQ1); a two-PR split (Approach C); any external/runtime dependency change. See
parent [F000063_DESIGN.md](../F000063_DESIGN.md) `## Not in scope`.

## Pointers

- Parent feature design: [../F000063_DESIGN.md](../F000063_DESIGN.md)
- Parent feature roadmap: [../F000063_ROADMAP.md](../F000063_ROADMAP.md)
- This story's spec: [S000105_SPEC.md](S000105_SPEC.md)
- This story's test-spec: [S000105_TEST-SPEC.md](S000105_TEST-SPEC.md)
- This story's tracker: [S000105_TRACKER.md](S000105_TRACKER.md)
