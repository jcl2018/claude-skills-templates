---
type: design
parent: F000088
title: "Generate docs/testing.md — the test-suite front door (Testing roadmap Phase 1) — Feature Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- Distilled from the /office-hours design:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-docs-testing-front-door-design-20260706-211006.md -->

## Problem

Phase 1 of the "Testing roadmap → dream test suite" saga (top of TODOS.md). Today
the what/how/why of the test suite is scattered across four surfaces:
`spec/test-spec.md` (contract prose), `docs/philosophy.md` (the verification
principle + the category×layer model), `docs/test-catalog.md` (a generated family
view), and the ~130KB `spec/test-spec-custom.md` (the item enumeration). Step 1 of
the dream — "read the test logic" — has no single front door.

This feature consolidates that into ONE **generated** `docs/testing.md` so "read
the test logic" becomes "open `docs/testing.md`, full stop." Because it is
generated (rendered from the merged registry, kept fresh like
`docs/test-catalog.md` and guarded by `validate.sh` Check 26), it cannot drift.

## Shape of the solution

A single generated page, `docs/testing.md`, emitted by `test-spec.sh --render-docs`
(fixed template prose + registry-derived indexes), following **Approach A**
(hybrid): a concise generated what/why that LINKS to `docs/philosophy.md`
§Verification + `spec/test-spec.md` for depth, plus the full how-to (run / audit /
verify) and the live `behaviors:` / `categories:` / `topic_contracts:` indexes.
Self-contained enough to be the one front door, with no duplicated prose to diverge.

The page has nine sections (fixed template prose except the registry-derived
indexes): (1) what testing here proves; (2) the model at a glance (category × layer
× mode + topic contract); (3) how to RUN (`/CJ_test_run` selectors + cost tiers);
(4) how to AUDIT (`/CJ_test_audit` + `/CJ_doc_audit`); (5) how to VERIFY (agentic,
$0 — drive `tests/eval/<skill>/<case>/` in-session); (6) the behaviors index
(from `--list-behaviors`); (7) the category-test index (from `--list-categories`);
(8) the enrolled topics (from `topic_contracts:`, each linking its
`docs/goals/<topic>.md` + `docs/tests/topics/<topic>/`); (9) drill-down links. It
carries the same "GENERATED FILE — do not edit by hand … Check 26 enforces
freshness" header as `docs/test-catalog.md`.

One user-story carries the whole implementation (one coherent PR): the
`_render_testing_md` renderer + its wiring into both render paths, the
`spec/doc-spec-custom.md` declaration, and the `tests/test-spec.test.sh` drill.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Add `_render_testing_md` to `test-spec.sh` (wire into `--render-docs` + `--render-docs --check`), declare `docs/testing.md` in `spec/doc-spec-custom.md`, add the render/idempotency/freshness drill to `tests/test-spec.test.sh` | S000137 | [S000137_render_docs_testing_from_registry/S000137_TRACKER.md](S000137_render_docs_testing_from_registry/S000137_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (hybrid: concise generated why + link) over B (fully self-contained) and C (thin index/hub) | A reads as one coherent front door without a second copy of `philosophy.md`'s verification principle — the exact drift this roadmap fights. B duplicates the principle (two things to sync); C is a hub, not a "single place to understand." |
| 2 | Fully **generated** by `test-spec.sh --render-docs` — no hand-edited sections | Generated = it can't drift; the existing `validate.sh` Check 26 keeps it fresh, so no new check is needed. Emitting from the SAME `--render-docs` (+ `--render-docs --check`) path means Check 26 covers it automatically. |
| 3 | `docs/testing.md` **complements** `docs/test-catalog.md`, does not replace it (for now) | The catalog is the detailed family index; `docs/testing.md` is the narrative top-level front door that links down. Whether it later absorbs the catalog is an out-of-scope follow-up. |
| 4 | Reflect current post-F000084/F000087 reality: the eval family is specs-only (in-session verify, no runner); the three cj_goal verbs are enrolled topics | The "verify" story is exactly the Phase 0 model — drive `tests/eval/<skill>/<case>/` in-session (ask Claude), no paid runner, no metered spend. |
| 5 | Declare `docs/testing.md` in the OVERLAY (`spec/doc-spec-custom.md`), not the general `spec/doc-spec.md` seed | The general seed must stay byte-identical to `doc-spec.sh --seed`; repo-specific generated docs are declared in the custom overlay. Avoids the dual-write footgun (no seed change expected). |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The dual-write footgun: any prose touched in `spec/test-spec.md` must be mirrored into the `_emit_seed` heredoc; this feature must NOT change the general seed. | Implementation (S000137): confirm `spec/test-spec.md` unchanged + seed-identity test green. |
| Should `docs/testing.md` later ALSO absorb `docs/test-catalog.md` (fully replace it)? | Deferred follow-up — revisit if the two-doc split feels redundant. |
| Phase 3 (propagate the front door to other repos) depends on this phase. | Out of scope here — tracked by the roadmap saga. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `docs/testing.md` is emitted by `test-spec.sh --render-docs`, declared in `spec/doc-spec-custom.md`, and reads as the one place to understand + run + audit + verify the tests.
- [ ] `validate.sh` Check 26 (`--render-docs --check`) is GREEN on it (a hand-edit is caught); `doc-spec.sh --validate` + `--check-on-disk` green (declared, no orphan, no work-item IDs).
- [ ] `spec/test-spec.md` seed byte-identity intact.
- [ ] The behaviors + categories indexes match the live registry (17 + 28 today) and track adds/removes automatically.
- [ ] Full `scripts/test.sh` green, incl. the new `tests/test-spec.test.sh` render drill.

## Not in scope

<!-- Explicit non-goals. -->

- Absorbing / replacing `docs/test-catalog.md` — for now `docs/testing.md` complements it; deferred follow-up.
- Propagating the generated front door to other repos (Phase 3 of the roadmap saga) — depends on this phase.
- Any change to the general `spec/test-spec.md` seed — this feature touches only the overlay + engine + the new generated doc.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000088_TRACKER.md](F000088_TRACKER.md)
- Roadmap: [F000088_ROADMAP.md](F000088_ROADMAP.md)
- Child story: [S000137_render_docs_testing_from_registry/S000137_TRACKER.md](S000137_render_docs_testing_from_registry/S000137_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-docs-testing-front-door-design-20260706-211006.md`
