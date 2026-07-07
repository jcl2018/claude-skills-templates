---
type: design
parent: S000137
title: "Render docs/testing.md from the merged test-spec registry — Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- Atomic user-story design. The cross-story context lives in the parent
     feature design: ../F000088_DESIGN.md. Brief per-section content is fine. -->

## Problem

The test suite's what/how/why is scattered across `spec/test-spec.md`,
`docs/philosophy.md`, `docs/test-catalog.md`, and the ~130KB
`spec/test-spec-custom.md`. There is no single front door for "read the test
logic." This story builds the generator that emits one — `docs/testing.md`.

## Shape of the solution

Add a `_render_testing_md` function to `scripts/test-spec.sh` that composes the
nine-section front-door page from the merged registry (reusing the existing
`--list-behaviors` / `--list-categories` / `topic_contracts` parsers), and wire it
into BOTH the `--render-docs` write path and the `--render-docs --check` diff path,
emitting to `docs/testing.md` (honoring the existing `TESTDOC_OUT`/docs-root
override). Then declare `docs/testing.md` in `spec/doc-spec-custom.md` as a
generated human-doc, and add a `tests/test-spec.test.sh` drill for
render/idempotency/freshness. See parent [../F000088_DESIGN.md](../F000088_DESIGN.md)
for the section list and Approach-A rationale.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Wire the render into both the write path AND `--render-docs --check` | Reusing Check 26's render→diff freshness gate is what makes the front door non-driftable — no new validate check needed. |
| 2 | Reuse the existing list-parsers for the behaviors/categories/topics indexes | The indexes then track the registry automatically (adds/removes) rather than a hand-maintained copy. |
| 3 | Declare in `spec/doc-spec-custom.md`, leave the general `spec/test-spec.md` seed untouched | Repo-specific generated docs belong in the overlay; the seed must stay byte-identical to `--seed` (avoids the dual-write footgun). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Accidentally changing the general `spec/test-spec.md` seed | Implement: confirm seed-identity test green; no `_emit_seed` heredoc edit. |
| The `--render-docs --check` path missing the new file (freshness gap) | Implement: the `tests/test-spec.test.sh` drill asserts a hand-edit is caught. |

## Definition of done

- [ ] `docs/testing.md` renders via `--render-docs`, is idempotent, and is diffed by `--render-docs --check` (Check 26 catches a hand-edit).
- [ ] Declared in `spec/doc-spec-custom.md`; `doc-spec.sh --validate` + `--check-on-disk` green (no orphan, no work-item IDs).
- [ ] Indexes match the live registry (17 behaviors + 28 categories today); seed identity intact; `tests/test-spec.test.sh` + full `scripts/test.sh` green.

## Not in scope

- Absorbing / replacing `docs/test-catalog.md` — deferred follow-up.
- Repo-portability of the generated front door (Phase 3 of the saga).

## Pointers

- Parent feature design: [../F000088_DESIGN.md](../F000088_DESIGN.md)
- This story's tracker: [S000137_TRACKER.md](S000137_TRACKER.md)
- Spec: [S000137_SPEC.md](S000137_SPEC.md)
- Test spec: [S000137_TEST-SPEC.md](S000137_TEST-SPEC.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-docs-testing-front-door-design-20260706-211006.md`
