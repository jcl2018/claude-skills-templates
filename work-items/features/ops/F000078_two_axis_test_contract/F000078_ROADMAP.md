---
type: roadmap
parent: F000078
title: "Two-axis test contract — category × verification-layer — Roadmap"
date: 2026-07-03
author: Charlie Jiang
status: Draft
---

<!-- A feature's roll-up roadmap — captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Replace the test contract's single muddled classification axis with two clean orthogonal
axes plus a per-test attribute: **category** (`workflow | regression | infra` — the *kind*
of test), **layer** (`CI-push | CI-nightly | pipeline-gate | local-hook` — *where/when* it
runs), and **mode** (`deterministic | agentic` — whether it spends model tokens). `ratchet`
demotes from a layer to a `ratchet: true` flag. The two-axis model lands mainly in the
GENERAL portable tier (`spec/test-spec.md` + `docs/philosophy.md`), so consumer repos
inherit it through the seed. The change is atomic — the full layer re-map (general `layers[]`
flip + all 83 `units:` `layer: ci` rows re-mapped by trigger) lands in this PR alongside the
engine updates (`test-spec.sh` + `test-run.sh`), the overlay rewrite, the two skill-MD
updates, and — critically — a POPULATED workflow category (4 concrete workflow tests with
front-door docs), fixing the F000074/F000075 empty-scaffold mistake.

## Non-Goals

<!-- Explicit non-goals. -->

- Migrating the 29 flat `tests/*.test.sh` into `tests/regression/<layer>/` — deferred backfill increment (Approach C rejected as one unreviewable diff).
- The feature→workflow / defect→regression mapping-enforcement gate — deferred; convention-only this increment.
- Wiring the category↔behavior link as a checked invariant — deferred; convention-only.
- Any new user-facing artifact or distribution channel — the model ships via the existing `test-spec.sh --seed` adoption path.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `test-spec.sh --validate` passes with the 3-category / 4-layer enums + the `agentic⇒¬free` cross-check.
- [ ] `--list-categories` emits the extended TSV; `--check-structure` validates the 2-deep `tests/<category>/<layer>/` structure (command-only infra rows exempt from check (b)) and reports the 29 flat tests as advisory backfill findings.
- [ ] The general `spec/test-spec.md` stays byte-identical to `test-spec.sh --seed`; all 83 `layer: ci` rows re-mapped by trigger; no `units:` row references a layer absent from `layers[]`.
- [ ] `test-run.sh --category workflow` / `--layer CI-nightly` select correctly; default run stays free-tier.
- [ ] The 4 workflow tests exist under `tests/workflow/<layer>/` (or as command rows) with front-door docs; `docs/tests/index.md` lists them; no orphaned old-path docs remain.
- [ ] `validate.sh` green (Checks 24/26/27/28), `test.sh` green (incl. seed-identity + render-freshness), shellcheck clean.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000128](S000128_two_axis_model_and_engines/S000128_TRACKER.md) | Two-axis model + engines + populated workflow category | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | General tier: `spec/test-spec.md` (layers + categories + mode) + `docs/philosophy.md` + `docs/architecture.md` | — | Not Started | Charlie Jiang | The "main logic" — the portable seed | — |
| 2 | Engine: `test-spec.sh` enums/fields/`--check-structure`/`--seed-docs`/`--list-categories` + `test-run.sh` `--category`/`--layer` | — | Not Started | Charlie Jiang | Enums in lockstep; do not trust line numbers | 1 |
| 3 | Overlay: `spec/test-spec-custom.md` — 83-row re-map + re-categorize + new workflow rows + new behavior | — | Not Started | Charlie Jiang | Atomic with the enum change | 2 |
| 4 | Physical: create `tests/workflow/<layer>/` + doc-sync test; front-door docs; regenerate `docs/tests/` + index + reconcile doc-spec; remove stale `.gitkeep` scaffolds | — | Not Started | Charlie Jiang | Ships the workflow category populated | 3 |
| 5 | Skills: `/CJ_test_audit` + `/CJ_test_run` SKILL.md + USAGE freshness | — | Not Started | Charlie Jiang | Two-axis structure, 3 categories, 4 layers, `--layer` | 4 |
| 6 | Green the tree: `validate.sh` (24/26/27/28) → `test.sh` (seed-identity + render-freshness) → shellcheck | — | Not Started | Charlie Jiang | Staged greening to catch seed + Check-26 fallout | 5 |
| 7 | S000128 shipped end-to-end (PR opened) | — | Not Started | Charlie Jiang | The single user-story carries the whole change | 6 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-07-03: Scaffolded F000078 + child S000128 from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 general tier (test-spec.md + philosophy + architecture)
      --> #2 engines (test-spec.sh + test-run.sh)
            --> #3 overlay (test-spec-custom.md 83-row re-map + categories)
                  --> #4 physical (tests/workflow/<layer>/ + docs regenerate + reconcile)
                        --> #5 skills (CJ_test_audit + CJ_test_run MDs)
                              --> #6 green the tree (validate -> test.sh -> shellcheck)
                                    --> #7 ship S000128 (PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| doc-sync workflow test backing: a new `tests/eval/CJ_doc_audit/` agentic case (via `suite-eval`) vs the existing deterministic `cj-audit-skills` unit. | Settle in scaffold/implement. Default: an eval-style agentic case at CI-nightly. |
| Do the `docs/tests/<family>.md` flat family docs collide with the per-test-doc mirror rule? | Confirmed no collision — flat family docs stay flat (per `units:` family), orthogonal to category/layer. |
