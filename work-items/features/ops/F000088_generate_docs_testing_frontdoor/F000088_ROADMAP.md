---
type: roadmap
parent: F000088
title: "Generate docs/testing.md — the test-suite front door (Testing roadmap Phase 1) — Roadmap"
date: 2026-07-06
author: chang
status: Draft
---

<!-- Feature roll-up roadmap: scope/non-goals, decomposition, delivery timeline. -->

## Scope

Deliver a single **generated** `docs/testing.md` — the top-level front door for the
test suite (Phase 1 of the Testing roadmap saga). Rendered by `test-spec.sh
--render-docs` from the merged test-spec registry, it consolidates the scattered
what/how/why into one page: a concise generated what/why (linking to
`docs/philosophy.md` §Verification + `spec/test-spec.md`), the how-to (RUN via
`/CJ_test_run`, AUDIT via `/CJ_test_audit`/`/CJ_doc_audit`, VERIFY in-session via
`tests/eval/`), and live registry-derived indexes (behaviors, categories, enrolled
topics). Because it is generated and covered by the existing `validate.sh` Check 26,
it stays current and cannot drift.

## Non-Goals

- Absorbing / replacing `docs/test-catalog.md` — `docs/testing.md` complements the family catalog; a possible later merge is a deferred follow-up.
- Propagating the generated front door to other repos (Phase 3 of the saga) — depends on this phase.
- Changing the general `spec/test-spec.md` seed — only the overlay + engine + the new generated doc are touched.

## Success Criteria

- [ ] `docs/testing.md` is emitted by `test-spec.sh --render-docs` and reads as the one place to understand + run + audit + verify the tests.
- [ ] `validate.sh` Check 26 (`--render-docs --check`) is GREEN and catches a hand-edit.
- [ ] `doc-spec.sh --validate` + `--check-on-disk` green: declared in `spec/doc-spec-custom.md`, present, no orphan, no work-item IDs.
- [ ] The behaviors + categories indexes match the live registry (17 + 28 today) and track adds/removes automatically.
- [ ] `spec/test-spec.md` seed byte-identity intact; full `scripts/test.sh` green incl. the new `tests/test-spec.test.sh` render drill.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000137](S000137_render_docs_testing_from_registry/S000137_TRACKER.md) | Render docs/testing.md from the merged test-spec registry | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000137 (renderer + wiring + doc-spec declaration + test drill) | — | Not Started | chang | The whole implementation in one coherent PR | — |
| 2 | End-to-end pipeline run (regenerate; Check 26 + doc-spec engines + seed identity + `test-spec.test.sh` green) | — | Not Started | chang | Verifies the generated front door is live and enforced | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-07-06: Scaffolded from the /office-hours design (F000088 + S000137).

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000137 (render docs/testing.md + wire + declare + test) --> #2 End-to-end pipeline run (Check 26 + engines + seed identity green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should `docs/testing.md` later absorb `docs/test-catalog.md` entirely? | Deferred — revisit if the two-doc split feels redundant. |
| Does the generated front door need to be repo-portable for Phase 3? | Phase 3 of the roadmap saga (out of scope here). |
