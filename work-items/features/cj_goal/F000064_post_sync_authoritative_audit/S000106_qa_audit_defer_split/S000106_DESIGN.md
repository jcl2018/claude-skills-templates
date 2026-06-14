---
type: design
parent: S000106
title: "qa.md Step 8.6 split + DEFER_AUDIT directive — Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- Atomic story — brief stub; see parent F000064_DESIGN.md for the full feature design. -->

## Problem

qa.md Step 8.6 runs the three-stage doc/test audit (8.6c/8.6d) inline inside the QA
subagent on every green path — pre-doc-sync in a cj_goal run. To make the audit run at the
authoritative post-sync point, QA must be able to DEFER 8.6c/8.6d when an orchestrator
drives it, while keeping the overlay writes (8.6a/8.6b) inline and keeping the full inline
audit for standalone runs.

## Shape of the solution

Split Step 8.6 in `skills/CJ_qa-work-item/qa.md`: 8.6a/8.6b (spec-overlay refresh writes)
always run inline on every green path. 8.6c/8.6d (the doc/test audits) become deferrable —
when the QA dispatch prompt contains the literal `DEFER_AUDIT: true` directive, QA skips
8.6c/8.6d and reports `AUDITS=deferred` in the RESULT, emitting no `AUDIT_FINDINGS` block
(the orchestrator's post-sync audit step emits it instead). Standalone QA (no directive)
runs 8.6c/8.6d inline exactly as today and emits `AUDIT_FINDINGS`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Defer signal = literal `DEFER_AUDIT: true` in the dispatch prompt | `/CJ_qa-work-item` is dispatched as a subagent prompt, not a CLI with argv; a literal string is greppable in the pipeline.md prompt templates. |
| 2 | Only 8.6c/8.6d defer; 8.6a/8.6b stay inline | Overlay writes belong pre-sync with the code; audits belong after the last doc-mutating step. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Standalone QA must keep its inline audit + `AUDIT_FINDINGS` emission | Verify with the no-directive smoke/E2E rows in TEST-SPEC. |

## Definition of done

- [ ] qa.md Step 8.6 split implemented; `DEFER_AUDIT: true` defers 8.6c/8.6d and sets `AUDITS=deferred`; standalone runs inline + emit `AUDIT_FINDINGS`.

## Not in scope

- The orchestrator-level post-sync audit step (S000107) — this story only makes QA deferrable.
- The test-spec gate-order swap + docs (S000108).

## Pointers

- Parent feature design: [../F000064_DESIGN.md](../F000064_DESIGN.md)
- Parent tracker: [../F000064_TRACKER.md](../F000064_TRACKER.md)
- Story tracker: [S000106_TRACKER.md](S000106_TRACKER.md)
