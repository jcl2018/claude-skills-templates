---
type: design
parent: F000083
title: "Materialize + enforce the portability test contract — Feature Design"
version: 1
status: Approved
date: 2026-07-05
author: Charlie Jiang
reviewers: []
---

## Problem

The `portability` topic is fully wired at all three verification layers (F000082),
but its DOCS are seeded stubs: every `docs/tests/infra/**/portability-*.md` still
carries the `<!-- SEEDED STUB — Fill each section -->` banner, and each
`## Explanation` is just the one-line `purpose` copied from the registry. There is
NO topic-level "end goal" doc. So from the docs alone a maintainer cannot learn (a)
what portability testing PROVES as a whole, or (b) what each subtest actually
asserts. The end goal — "another machine gets the same cj_skills as in this repo" —
is real and decomposes cleanly into three properties, but that decomposition lives
only in a code-review answer, not in the repo. Enforcement is also partial:
completeness + fidelity only gate nightly, and nothing stops the per-test docs
rotting back to stubs.

## Shape of the solution

A WHAT-vs-HOW split plus a structural enforcement check, all gated on the existing
`topic_contracts:` enrollment (so it is CI-safe and vacuous in a consumer repo).

| Concern | Where | Kind |
|---------|-------|------|
| WHAT — the end goal + 3 properties (the "dream") | `docs/goals/portability.md` | hand-authored |
| HOW — tests grouped by layer, "how to achieve" the dream | `docs/tests/topics/portability/{index,CI-push,CI-nightly,local-hook}.md` | hand-authored |
| Assertion detail (single source of truth) | `docs/tests/infra/**/portability-*.md` (enriched) | hand-editable front doors |
| Enforcement | `test-spec.sh --check-topic-docs` → `validate.sh` Check 31 + `test.sh` negative | deterministic engine |
| CI-push parity gate | `windows-smoke.sh` S5 (completeness) + S6 (fidelity) | fast per-PR |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Dream doc at `docs/goals/portability.md`, NOT `docs/workflows/` | `docs/workflows/` is GENERATED (`workflow-spec.sh --render-docs`) + orphan-swept; a hand doc there is reverted/flagged. `docs/goals/` is a new hand-authored "dream docs" home (room for more topics). |
| 2 | Promote completeness/fidelity to CI-push via fast `windows-smoke.sh` S5/S6, NOT by moving `test-deploy.sh` | `windows-smoke.sh` already runs on CI-push in seconds; adding two assertions keeps the per-PR gate fast while gating parity every merge. Moving the slow suite would violate the "CI-push stays fast" directive. |
| 3 | Detailed assertion tables live ONLY in the per-test front-door docs; topic/layer pages LINK them | Single source of truth → no drift. Respects the existing `--check-structure` (f) front-door contract. |
| 4 | Enforcement is structure/declaration-level (deterministic), gated on `topic_contracts:` | CI-safe, zero model spend; a consumer repo with no enrollment reports "inactive" and passes vacuously — mirrors Check 30. |
| 5 | Check 18 strict is NOT re-implemented | It is ALREADY strict-by-default at the validate gate (T000054, `PORTABILITY_STRICT:-1`). Only the engine header's stale "advisory by default" wording is corrected. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| A new `docs/**` file trips the recursive orphan sweep (Check 15a) | Declare all 5 new docs in `spec/doc-spec-custom.md`; run `doc-spec.sh --check-on-disk` (expect FINDINGS=0). |
| `windows-smoke.sh` S5/S6 must pass on BOTH Windows + ubuntu | Use the host-independent `SKILLS_DEPLOY_FORCE_COPY=1` pattern already used by S3/S4. |
| The negative test must invoke ONLY the engine (not full validate) | Mirror the Check 30 negative test: hermetic temp registry, plant→fail→restore→pass. |
| `--check-topic-docs` must not false-positive on a repo with no enrollment | Gate on `topic_contracts:` presence; emit "topic-docs contract inactive" + exit 0 when absent. |

## Definition of done

- [ ] `docs/goals/portability.md` states the end goal + the 3-property table + supporting guarantees.
- [ ] `docs/tests/topics/portability/` has index + a page per covered layer, each referencing the dream doc.
- [ ] All 5 per-test docs carry a `## What it proves` assertion→property table.
- [ ] `test-spec.sh --check-topic-docs` HARD-fails on a missing dream doc / per-layer page; wired into `validate.sh` Check 31 + surfaced in `/CJ_test_audit` Stage 1; a `test.sh` negative test proves it fires.
- [ ] `windows-smoke.sh` S5/S6 assert completeness + fidelity and pass on this host.
- [ ] `validate.sh` (targeted) + `doc-spec.sh --check-on-disk` + `test-spec.sh --check-structure/--check-topic-contract/--check-topic-docs` all green.

## Not in scope

- Moving the slow `test-deploy.sh` onto CI-push — replaced by the fast `windows-smoke.sh` S5/S6.
- Enrolling the other 11 labeled topics into `topic_contracts:` — each needs its own dream doc + subdir first (follow-up).
- Changing any test's runtime behavior (the agentic proof, the deploy harness) — this is a docs + enforcement + fast-assertion feature.

## Pointers

- Parent tracker: [F000083_TRACKER.md](F000083_TRACKER.md)
- Roadmap: [F000083_ROADMAP.md](F000083_ROADMAP.md)
- Precedent: F000082 (the three-layer topic contract this builds on), Check 30 (`test-spec.sh --check-topic-contract`).
