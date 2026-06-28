---
type: design
parent: S000111
title: "docs/workflows/ subfolder — full split + contract/engine/validator/test/prose changes — Design"
version: 1
status: Draft
date: 2026-06-27
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Brief by design — the full cross-story context
     lives in the parent F000067_DESIGN.md. -->

## Problem

`docs/workflow.md` (863 lines / 56KB) mixes a human-readable overview with deep
per-workflow reference detail, and the doc contract knows only the single file.
This story carries the whole fix: split the deep detail into `docs/workflows/`,
reduce `workflow.md` to a pure index, and teach the doc contract the two-level
structure as a registry-gated portable mandate. See parent F000067_DESIGN.md for
full context.

## Shape of the solution

A verbatim content move (six sections → six `docs/workflows/*.md`) plus a
contract/engine/validator/test/prose teach. The engine (`doc-spec.sh`) gains the
`workflows-subfolder` mandate + a recursed orphan scan; `validate.sh` mirrors the
recursion, retargets Check 15b to the subfolder files, and adds a no-vanish
Check 15c; the portable seed is reworded 3-way byte-identically; the overlay
declares the 6 rows; tests + prose are synced.

## Big decisions

<!-- Inherited from the parent feature; story-level confirmations. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Single atomic story (no task children) | One cohesive reorganize + contract-teach change; decomposition would add ceremony without parallelism. |
| 2 | Engine-level mandate (not overlay-only) | Portability — every adopting repo inherits the mandate via the seeded engine check. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 3-way seed byte-identity could drift during the edit. | `tests/cj-document-release-config.test.sh` no-drift run during QA. |
| Check 15b retarget could silently drop a workflow from the overview. | New Check 15c (verified by a TEST-SPEC smoke row). |
| `--list-human-docs` may be maxdepth-limited and miss the subfolder files. | Verify + adjust during implementation; covered by a TEST-SPEC smoke row. |

## Definition of done

- [ ] Six subfolder files + index `workflow.md`; seed taught 3-way byte-identical; engine check + recursion added; overlay rows declared; Check 15a/15b/15c done; tests + prose synced; `validate.sh` + `test.sh` green; audits clean.

## Not in scope

- New prose depth — verbatim reorganize only.
- Splitting non-workflow docs.
- Changing the registry table grammar.

## Pointers

- Parent feature design: [../F000067_DESIGN.md](../F000067_DESIGN.md)
- Parent tracker: [../F000067_TRACKER.md](../F000067_TRACKER.md)
- This story's spec: [S000111_SPEC.md](S000111_SPEC.md)
- This story's test-spec: [S000111_TEST-SPEC.md](S000111_TEST-SPEC.md)
