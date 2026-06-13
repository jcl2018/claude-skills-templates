---
type: design
parent: S000107
title: "Four cj_goal pipelines reorder — Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- Atomic story — brief stub; see parent F000064_DESIGN.md for the full feature design. -->

## Problem

All four cj_goal orchestrators run QA → checkpoint → doc-sync, so the post-QA checkpoint
decides on pre-sync docs. They must be reordered to QA → pre-doc-sync commit → doc-sync →
post-sync audit → checkpoint, with the audit moved to the orchestrator level (depth ≤ 2)
and run once, read-only. Each pipeline has a different existing commit topology, so the new
pre-doc-sync commit must be placed per file.

## Shape of the solution

Per pipeline file (feature `pipeline.md`, defect `pipeline.md`, task `SKILL.md`, todo
`SKILL.md`): (1) embed `DEFER_AUDIT: true` in the QA dispatch prompt; (2) add an explicit
automated, idempotent pre-doc-sync commit (skip when the tree is clean at HEAD); (3) move
doc-sync ahead of the audit + checkpoint; (4) add a post-sync audit step that dispatches
`/CJ_doc_audit` + `/CJ_test_audit` as ONE combined depth-2 fresh-context subagent
(read-only); (5) re-point the existing QA-audit checkpoint to consume the post-sync report.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Enumerate commit topology per file; do not move symmetrically | defect commits the fix before QA + re-commits the tracker after QA; feature commits nothing; task/todo differ. |
| 2 | Pre-doc-sync commit is idempotent (skip on clean tree) | A resume after the commit must not double-commit; doc-sync/audit/checkpoint record no new phase boundary. |
| 3 | Post-sync audit = ONE combined read-only subagent | Two would double the cost C-i exists to avoid; read-only preserves the post-sync-clean PR invariant. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Per-file step numbering + halt-marker consistency | Apply per-file during implementation; keep numbering, commit points, and halt markers consistent. |
| Resume double-commit | Make the commit idempotent (clean-tree skip) and confirm against each pipeline's validate-before-skip logic. |

## Definition of done

- [ ] All four pipelines reordered (pre-doc-sync commit → doc-sync → post-sync read-only audit → checkpoint), `DEFER_AUDIT: true` embedded, checkpoint re-pointed, resume-safe.

## Not in scope

- The qa.md Step 8.6 split (S000106) — this story consumes its `DEFER_AUDIT: true` signal.
- The test-spec gate-order swap + docs + named tests (S000108).
- Any `/CJ_document-release` functional change.

## Pointers

- Parent feature design: [../F000064_DESIGN.md](../F000064_DESIGN.md)
- Parent tracker: [../F000064_TRACKER.md](../F000064_TRACKER.md)
- Story tracker: [S000107_TRACKER.md](S000107_TRACKER.md)
