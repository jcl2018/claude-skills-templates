---
type: design
parent: F000055
title: "Standalone /CJ_document-release + the general/custom doc-contract principle — Feature Design"
version: 1
status: Draft
date: 2026-06-08
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

The operator wants three things from `/CJ_document-release`: (1) a **principle**
that says docs get kept current and well-formatted for **any** repo, on demand;
(2) the skill to be a **single standalone skill triggerable in any repo** (today
it is framed as a workbench-internal wrapper); and (3) a **two-tier
doc-requirement model** — a *general* set every repo gets by default (e.g.
`philosophy.md`) and a *custom* set specific to a repo (e.g. `agents.md` in a
knowledge-base vault). The payoff is peace of mind that docs are current, then
later wiring the same machine-readable contract into CI as a gate.

Investigation found **two of the three asks already exist**: the two-tier
general/custom model (`doc-spec.md` `section: common` / `section: custom`, used by
the knowledge-base repo today with 4 common + 43 custom docs) and the single
canonical seed (`doc-spec.sh --seed` byte-identical to
`templates/doc-spec-common.md`, gated by `tests/cj-document-release-config.test.sh`
test #13). The self-heal + per-doc requirement audit also exists (Step 6.7). So
this feature is **small and additive** — name the principle, fix the one real
cold-run rough edge, and document the portable CI hook honestly.

## Shape of the solution

Approach A (minimal, additive). Five separable changes, all carried by a single
atomic user-story (S000097): the philosophy principle + front-table row; the one
real standalone-robustness fix (the Step 6.7.2 `skills-catalog.json` guard); the
gstack-hard-require message clarification at the Step 4→5 boundary; the honest
portability/USAGE bookkeeping; and the architecture.md portable-CI-hook recipe
plus a cold-repo smoke test. The existing Common/Custom model + seed dedup are
left untouched (already done).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| All five deltas (principle, catalog guard, gstack message, bookkeeping, CI recipe + smoke test) | S000097 | [S000097_cj_document_release_standalone_principle/S000097_TRACKER.md](S000097_cj_document_release_standalone_principle/S000097_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (robustness + principle + CI recipe, minimal additive) | Smallest diff delivering all three asks; the two-tier model + seed already exist, so a rebuild is mostly rework. |
| 2 | Reject Approach B (native rebuild dropping gstack) | The operator chose hard-require gstack; the skill already has a native registry audit + self-heal — B is rework with real regression risk for little new value. |
| 3 | Reject Approach C (principle doc only) | Leaves the `skills-catalog.json` rough edge in place (stderr noise + a silently skill-MD-less audit cold); the small guard is cheap and worth shipping with the principle. |
| 4 | gstack `/document-release` stays a HARD dependency | Operator decision. "Standalone" = decoupled from workbench-repo-local files (no `skills-catalog.json` dep), NOT "runs without gstack." |
| 5 | No programmatic gstack-presence probe; message-only at the Step 4→5 boundary | Avoids a new false-halt class (cf. the known `skills-catalog.json` false-halt in the portability gate, TODO #251). The boundary covers both resolution-failure AND non-green; a Step-5-only edit would miss the resolution-failure case. |
| 6 | New sibling principle under `## Topic: Deployment` (one extra front-table row) | The general/custom + portable-pass + CI framing is a distinct idea worth its own row, not an in-place expansion of `### The doc contract is one file`. |
| 7 | Portability stays `local-only`, NOT relabeled `workbench` | The guard removes one repo-local dependency, trending the skill MORE portable; it still hard-deps gstack + `_cj-shared` + `doc-spec.sh`. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The Step 6.7.2 guard could introduce a `set -e` abort the current code avoids. | Implement: preserve the `$(…)`-capture idiom (or `|| true`); the cold-repo smoke row in `tests/cj-document-release-config.test.sh` is the mechanical gate. |
| Over-claiming "general by default for any repo" — the philosophy PROSE and the declared⇔on-disk loop do NOT travel to consumer repos. | Implement: architecture.md recipe must state plainly that only `doc-spec.sh --validate` + the general doc SET travel; the prose + declared⇔on-disk loop + `front_table` are workbench-local. |
| New front-table row / sibling principle could trip the New-skills / decision-tree checks or Check 20. | QA: `validate.sh` Checks 19 + 20 green; no work-item IDs in the human-doc. |
| `doc-spec.sh --check-on-disk` (declared⇔on-disk subcommand) — should the portable helper carry the full CI gate? | Deferred to a TODOS follow-up; decide later. Not this PR. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `docs/philosophy.md` has a new sibling principle (general/custom two-tier + portable any-repo pass + wire-into-CI hook) with a front-table row, no work-item IDs; `validate.sh` Checks 19 + 20 green.
- [ ] `/CJ_document-release` Step 6.7.2, catalog absent, emits a clean one-line skip (no `jq` stderr noise), skips the skill-MD audit half AND the `.cj-goal-feature/` scratch write; the registry-doc audit (6.7.1/6.7.3) incl. the human-doc no-work-item-ID lint still runs.
- [ ] gstack-absent surfaces `[doc-sync-red]` at the Step 4→5 boundary naming "gstack `/document-release` not installed" as a possible cause.
- [ ] `CJ_document-release` portability stays `local-only`; Step 5.7 portability gate passes; USAGE.md Check-14 drift resolved.
- [ ] `docs/architecture.md` documents the portable CI hook scoped honestly; a new cold-repo smoke row in `tests/cj-document-release-config.test.sh` proves the guard path (no `jq` error, no stray `.cj-goal-feature/` artifact).
- [ ] `scripts/validate.sh` + `scripts/test.sh` green; PR opens and STOPS for review.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Native rebuild of the doc audit / dropping the gstack `/document-release` dependency — Approach B, rejected (operator chose hard-require gstack).
- A new CI workflow file — "wire into CI later" is documented (the portable hook), not built in this PR.
- `doc-spec.sh --check-on-disk` (declared⇔on-disk subcommand) — deferred to a TODOS follow-up.
- Broadcasting the philosophy PROSE into consumer repos — the seed carries `doc-spec.md` structure, not `philosophy.md` text; each repo writes its own.
- Re-designing the existing Common/Custom model or seed dedup — already implemented; left untouched.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000055_TRACKER.md](F000055_TRACKER.md)
- Roadmap: [F000055_ROADMAP.md](F000055_ROADMAP.md)
- Child story: [S000097_cj_document_release_standalone_principle/S000097_TRACKER.md](S000097_cj_document_release_standalone_principle/S000097_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-093825.md`
- Related: `work-items/features/ops/F000036_cj_document_release/`, `work-items/features/ops/F000037_cj_document_release_config/`, `work-items/features/ops/F000050_doc_spec_driven_dev/`
