---
type: design
parent: S000128
title: "Two-axis model + engines + populated workflow category — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours session.
     The parent F000078_DESIGN.md carries the full cross-story design; this is a brief
     stub linking to it. All 7 sections are present (structural completeness is enforced
     by /CJ_personal-workflow check even for atomic stories). -->

## Problem

The test contract classifies tests on one muddled axis — `categories: {workflow, CI-push,
CI-nightly}` conflates a semantic *kind* with a run *cadence*, and the general `layers[]`
lumps all CI into one `ci` blob while dressing the `ratchet` property up as a location. This
story does the whole reframe: two orthogonal axes (category × layer) + a `deterministic|
agentic` mode, the full layer re-map, both engine changes, the overlay rewrite, and a
POPULATED workflow category. See the parent [F000078_DESIGN.md](../F000078_DESIGN.md) for
the full problem framing.

## Shape of the solution

One cohesive, sequential change (six build steps) landing as a single user-story:

1. **General tier** (the "main logic") — `spec/test-spec.md` `layers[]` → the four + a general `categories` definition (3 kinds) + the `mode` attribute; `docs/philosophy.md` "Four verification layers"; `docs/architecture.md` test-spec contract.
2. **Engines** — `test-spec.sh` (enums in 3-way lockstep, `layer`+`mode` fields + the `agentic⇒¬free` cross-check, `--check-structure` re-expressed for 2-deep `tests/<category>/<layer>/` with the committed check-(b) command-only exemption, `--seed-docs` 2-deep, extended `--list-categories` TSV) + `test-run.sh` (`--category` enum + `--layer` selection + composition).
3. **Overlay** — `spec/test-spec-custom.md`: re-map all 83 `units:` `layer: ci` rows by trigger, rewrite the 7 `categories:` rows, add the new workflow rows + the `workflow-doc-audit-runs` behavior + its coverage link.
4. **Physical** — create `tests/workflow/{CI-push,CI-nightly,local-hook}/` + the doc-sync test; write front-door docs; regenerate `docs/tests/` + index; reconcile `spec/doc-spec-custom.md`; remove the stale empty `.gitkeep` scaffolds.
5. **Skills** — `/CJ_test_audit` + `/CJ_test_run` SKILL.md + USAGE freshness.
6. **Green** — `validate.sh` (24/26/27/28) → `test.sh` (seed-identity + render-freshness) → shellcheck.

No task children — the change is atomic and sequential (see Big decisions).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The whole two-axis reframe (atomic) | S000128 | [S000128_SPEC.md](S000128_SPEC.md) |

## Big decisions

<!-- Choices that shape this story; rationale lives in the parent DESIGN. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Land the whole reframe as ONE atomic user-story (no task children). | The enum flip is atomic (`--validate` checks categories + units + layers together, gated by HARD Check 24) and the build order is strictly sequential with no parallel sub-units. Fragmenting it would red CI mid-change. |
| 2 | Full layer re-map now (all 83 `layer: ci` rows), not staged. | Parent decision (Premise 6) — one coherent diff over two co-existing layer vocabularies. |
| 3 | `mode` required per `categories:` row + `agentic⇒tier≠free` cross-check. | Agentic tests spend model tokens; `free` is impossible for them (review fix #6/#7). |
| 4 | `--check-structure` check (b) requires a folder only for (category,layer) pairs with ≥1 file-backed test; command-only rows exempt. | Command-only rows are script invocations, not `tests/*.test.sh` — never force an empty `tests/infra/…` (review fix #8). |
| 5 | Only `goal-feature-eval` is `level:workflow`; category↔behavior stays convention-only. | Check 28 enforces orchestrator↔`level:workflow`, not category↔behavior; a `level:workflow` behavior for a non-orchestrator would fail Check 28's reverse arm (review fix #5). |

## Risks & open questions

<!-- Story-level risks; the parent DESIGN carries the full risk table. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The 83-row + 3-way-seed-lockstep + rendered-doc diff risks a mid-PR CI red if not fully lockstep. | Staged greening (validate → test.sh → shellcheck) in build order during implement. |
| Design line numbers may drift. | Re-grep every hardcoded enum site before editing — do not trust line numbers. |
| Re-categorizing rows orphans old-path generated docs (Check 15/15a). | Delete moved-category docs, declare new paths in `spec/doc-spec-custom.md`, regenerate, re-run `doc-spec.sh --check-on-disk` + Check 26 before greening. |
| doc-sync workflow test backing undecided. | Settle in implement — default an eval-style agentic `tests/eval/CJ_doc_audit/` case at CI-nightly. |

## Definition of done

<!-- Objective criteria; mirrors the story SPEC's acceptance criteria. -->

- [ ] `test-spec.sh --validate` green with 3-category/4-layer enums + `agentic⇒¬free`; `--list-categories` extended TSV; `--check-structure` 2-deep + command-only exemption + 29-flat-test advisory findings.
- [ ] `spec/test-spec.md` byte-identical to `--seed`; all 83 `layer: ci` rows re-mapped by trigger; no `units:` layer absent from `layers[]`.
- [ ] `test-run.sh --category`/`--layer`/composition + single-NAME select correctly; default run free-tier.
- [ ] 4 workflow tests under `tests/workflow/<layer>/` (or command rows) with front-door docs; `docs/tests/index.md` lists them; no orphaned old-path docs.
- [ ] Check 28 green (reused `workflow-cj-goal-feature-runs` behavior resolves); `validate.sh` (24/26/27/28) + `test.sh` (seed-identity + render-freshness) + shellcheck all green.

## Not in scope

<!-- Deferred to the tracked backfill increment. -->

- Migrating the 29 flat `tests/*.test.sh` into `tests/regression/<layer>/` — deferred backfill.
- The feature→workflow / defect→regression enforcement gate — deferred; convention-only.
- Wiring the category↔behavior link as a checked invariant — deferred; convention-only.
- Physically moving the 7 re-categorized command rows' scripts — they are invocations pointing at existing paths; no move required.

## Pointers

<!-- Cross-links to related artifacts. Relative paths from this story dir. -->

- Parent tracker: [../F000078_TRACKER.md](../F000078_TRACKER.md)
- Parent design: [../F000078_DESIGN.md](../F000078_DESIGN.md)
- Parent roadmap: [../F000078_ROADMAP.md](../F000078_ROADMAP.md)
- Story SPEC: [S000128_SPEC.md](S000128_SPEC.md)
- Story TEST-SPEC: [S000128_TEST-SPEC.md](S000128_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-kind-goldberg-4747aa-design-20260703-153124.md`
