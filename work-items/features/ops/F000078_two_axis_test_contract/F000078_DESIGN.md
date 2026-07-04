---
type: design
parent: F000078
title: "Two-axis test contract — category × verification-layer — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The repo's test contract (`spec/test-spec.md` general + `spec/test-spec-custom.md`
overlay, driven by `scripts/test-spec.sh` + `scripts/test-run.sh`, surfaced through
`/CJ_test_audit` + `/CJ_test_run`) classifies tests on **one muddled axis**. Today's
`categories:` taxonomy V2 is `{workflow, CI-push, CI-nightly}` — which **conflates a
semantic kind (`workflow`) with a run cadence (`CI-push`/`CI-nightly`)**. Separately the
general `layers[]` map is `{local-hook, ci, pipeline-gate, ratchet}`, where `ci` is one
undifferentiated blob and `ratchet` is a monotonic-guard *property* dressed up as a
*location*.

The single-axis muddle already produced a half-built artifact: `tests/{workflow, CI-push,
CI-nightly}/` folders exist on disk carrying only `.gitkeep` — the F000074/F000075 category
foundation created category folders and **never migrated a single test into them**. All 29
`tests/*.test.sh` files sit flat in `tests/`. The taxonomy was the wrong cut, so nobody
could finish it. This feature replaces the wrong cut with two clean orthogonal axes plus a
per-test mode attribute, so every test has a precise, self-describing home.

## Shape of the solution

Split the one muddled axis into **two clean orthogonal axes plus one attribute**:

- **category** = the *kind* of test: `workflow | regression | infra`
  - `workflow` — proves a whole user-facing workflow runs end to end (features earn these)
  - `regression` — proves a specific past defect stays fixed (defects earn these)
  - `infra` — the standing verification surface itself (the validator, the full suite, the deploy harness)
- **layer** = *where/when* it runs: `CI-push | CI-nightly | pipeline-gate | local-hook`
  - `CI-push` — every push/PR (the old `ci` blob, cadence-split); `CI-nightly` — nightly schedule; `pipeline-gate` — inline orchestrator halts (unchanged); `local-hook` — on your machine
- **mode** = a per-test attribute: `deterministic | agentic` (agentic spends model tokens)

`ratchet` stops being a layer and becomes a `ratchet: true` **flag**, so the layer set is
exactly the four above. Physical home: `tests/<category>/<layer>/<name>.test.sh` (or a
`command`-only category row for script invocations). Docs mirror to
`docs/tests/<category>/<layer>/<name>.md` (front-door: `## What it is` / `## How to run` /
`## Explanation`), indexed by `docs/tests/index.md`.

The whole reframe (the general-tier model, the two engine changes, the overlay re-map, the
populated workflow category, the doc updates, and the two skill-MD updates) lands as one
cohesive change — one user-story, since the build order is sequential and the enum change is
atomic (see Big decisions #2). The deferred backfill is a separate tracked increment.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The two-axis model + engines + populated workflow category (the whole atomic change) | S000128 | [S000128_two_axis_model_and_engines/S000128_TRACKER.md](S000128_two_axis_model_and_engines/S000128_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Two clean axes (category × layer) + a `deterministic\|agentic` mode replace the single conflated `categories:` axis (Premise 1). | The old `{workflow, CI-push, CI-nightly}` conflated a semantic kind (`workflow`) with a run cadence (`CI-push`/`CI-nightly`). Orthogonal axes give every test a self-describing `tests/<cat>/<layer>/` home. |
| 2 | The layer + category enum change is ATOMIC — lands in ONE change (Premise 6, "full re-map now"). | `test-spec.sh --validate` enum-checks BOTH `categories:` AND `units:`/`layers:` rows and is called by HARD `validate.sh` Check 24. Staging the flip would red CI mid-PR and force carrying two layer vocabularies; the operator chose one bigger coherent diff. |
| 3 | Categories are the closed set `{workflow, regression, infra}` (Premise 2). | Operator added `infra` as an honest third bucket for the validator/suite/deploy self-checks rather than overloading `regression`. |
| 4 | Layers are exactly `{CI-push, CI-nightly, pipeline-gate, local-hook}`; `ratchet` demotes to a `ratchet: true` flag (Premise 3). | `ratchet` is a monotonic-guard property, never a location. It already exists as a flag; demoting it leaves the layer set clean at four. |
| 5 | Main logic lives in the GENERAL portable tier (Premise 4). | The two-axis model, category definitions, and four layers land in `docs/philosophy.md` + `spec/test-spec.md` prose + `layers[]` — the tier byte-identical to `--seed`, inherited by every consumer repo. The change bumps the seed. |
| 6 | Ship the workflow category POPULATED (chose Approach A; rejected B). | Approach B ships the workflow category empty — repeats exactly the half-built-scaffold mistake that motivated the feature. A creates the 4 concrete workflow tests with front-door docs. |
| 7 | Defer the 29-flat-test migration + the mapping-enforcement gate (rejected Approach C). | C compounds the migration into the 83-row re-map = one unreviewable XL/High-risk diff. The repo's own "land additively" philosophy makes the flat-test migration its own backfill increment. |
| 8 | `category=workflow` is NOT behavior `level: workflow`; category↔behavior stays convention-only this increment (review fix #5). | Check 28 enforces orchestrator↔`level:workflow`, not category↔behavior. Only `goal-feature-eval` is `level:workflow` (Check 28 stays green); portability + doc-sync are `category=workflow` backing non-workflow-level behaviors. A `level:workflow` behavior for a non-orchestrator would FAIL Check 28's reverse arm. |
| 9 | On a `categories:` row `layer` is DESCRIPTIVE metadata — it does NOT drive CI scheduling (review fix #9). | The real cron/trigger stays in `.github/workflows/*.yml`; the two are kept consistent by hand — a documented drift risk, not an enforced binding. |
| 10 | `mode` is required on every `categories:` row (no default); `--validate` cross-checks `agentic ⇒ tier ∈ {paid, local-only}` (review fix #6/#7). | Agentic tests spend model tokens, so `agentic` can never be `free`. Making `mode` explicit + required removes the mode/tier overlap ambiguity. |
| 11 | `--check-structure` check (b) requires a `tests/<cat>/<layer>/` folder only for (category,layer) pairs with ≥1 FILE-backed test — committed, not deferred (review fix #8). | Command-only rows (validate/suite/test-deploy) are script invocations, not `tests/*.test.sh` files; they must never force an empty `tests/infra/…` folder. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| A large mechanical diff (83 units rows + 3-way seed lockstep + every rendered family doc) risks a mid-PR CI red if the flip is not fully lockstep. | Staged greening during implement: `validate.sh` (24/26/27/28) → `test.sh` (seed-identity + render-freshness) → shellcheck, in build order. |
| Line numbers in the design (`~127-133`, `~744-746`, `~979-981`, `~932/933`, `~2205/2210-2221`, `~224/225`) may drift from the live source. | Implement re-greps `grep -n "CI-push\|CI-nightly" scripts/test-spec.sh scripts/test-run.sh` and updates every hit — do NOT trust line numbers. |
| Re-categorizing rows MOVES their generated doc paths — old `docs/tests/CI-push/…` become orphans (review fix #4). | Enumerate existing `docs/tests/**/*.md`, DELETE moved-category docs, add new `docs/tests/<cat>/<layer>/…` to `spec/doc-spec-custom.md`, regenerate via `--render-docs` + `--seed-docs`, re-run `doc-spec.sh --check-on-disk` (Check 15/15a) + Check 26 BEFORE greening. |
| Check 28 must stay green — the reused `workflow-cj-goal-feature-runs` behavior must keep resolving to a declared orchestrator. | Verify Check 28 (`test-spec.sh --check-workflow-coverage`) after the overlay rewrite; do not add a `level:workflow` behavior for a non-orchestrator. |
| doc-sync workflow test backing undecided: a new `tests/eval/CJ_doc_audit/` agentic case (via `suite-eval`) vs the existing deterministic `cj-audit-skills` unit. | Settle the exact backing in scaffold/implement. Default: an eval-style agentic case at CI-nightly (the "entire cj_doc_audit logic" per the request). |
| `docs/tests/<family>.md` flat family docs (GENERATED per `units:` family) could collide with the per-test-doc mirror rule. | Confirmed no collision — flat family docs stay flat, orthogonal to category/layer; they are the linked drill-down behind the per-test front-door doc. |
| Windows/POSIX portability of every script edit. | LF everywhere; `jq()` CR-strip wrapper for any NEW jq call; portable `date` idiom; run `scripts/windows-smoke.sh` as part of greening. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `test-spec.sh --validate` passes with the 3-category / 4-layer enums + the `agentic⇒¬free` cross-check; `--list-categories` emits the extended TSV; `--check-structure` validates the 2-deep structure (command-only infra rows exempt from check (b)) and reports the 29 un-migrated flat tests as advisory backfill findings (not errors).
- [ ] The general `spec/test-spec.md` stays byte-identical to `test-spec.sh --seed` (3-way-lockstep test passes); no `units:` row references a layer absent from `layers[]`; all 83 `layer: ci` rows re-mapped by trigger.
- [ ] `test-run.sh --category workflow` / `--layer CI-nightly` select correctly; a default run stays free-tier (never spends model tokens).
- [ ] The 4 workflow tests exist under `tests/workflow/<layer>/` (or as command rows) with front-door docs; `docs/tests/index.md` lists them; no orphaned old-path docs remain.
- [ ] `validate.sh` green (Checks 24/26/27/28), `test.sh` green (incl. seed-identity + render-freshness suites), shellcheck clean.
- [ ] The follow-on TODOS row is filed (backfill migration + enforcement gate + category↔behavior cross-check).

## Not in scope

<!-- Explicit non-goals. -->

- Migrating the 29 flat `tests/*.test.sh` files into `tests/regression/<layer>/` — deferred as a tracked backfill increment (Approach C rejected as one unreviewable diff).
- The "every feature has a workflow test / every defect has a regression test" enforcement gate — deferred; convention-only this increment.
- Wiring the category↔behavior cross-check as a checked invariant — deferred; convention-only this increment.
- Any new user-facing artifact or distribution channel — the model ships to consumers through the existing `test-spec.sh --seed` / `skills-deploy seed-contracts` adoption path.
- Changing the physical test-script *move* for the re-categorized command rows — those 7 rows are script invocations pointing at existing paths; no test-script move is required for them.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000078_TRACKER.md](F000078_TRACKER.md)
- Roadmap: [F000078_ROADMAP.md](F000078_ROADMAP.md)
- Child user-story: [S000128_two_axis_model_and_engines/S000128_TRACKER.md](S000128_two_axis_model_and_engines/S000128_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-kind-goldberg-4747aa-design-20260703-153124.md`
- Lineage: F000074 (category test contract V1), F000075 (CI-push/CI-nightly cadence split), F000076 (QA-audit → nightly CI), F000077 (per-test-doc front door)
