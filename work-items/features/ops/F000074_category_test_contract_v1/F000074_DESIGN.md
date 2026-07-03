---
type: design
parent: F000074
title: "Category-based test contract — /CJ_test_audit + /CJ_test_run V1 foundation — Feature Design"
version: 1
status: Draft
date: 2026-07-02
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. -->

## Problem

The workbench ships two experimental utility skills — `/CJ_test_audit` (verify tests
are wired) and `/CJ_test_run` (execute them) — built today around a
family/units/behaviors/runners contract (`spec/test-spec.md` +
`spec/test-spec-custom.md`, engines `scripts/test-spec.sh` + `scripts/test-run.sh`,
flat `docs/tests/<family>.md` + `docs/test-catalog.md`). The operator wants these
finalized around a simpler, category-based mental model any repo can adopt: tests
organized by category (V1: `workflow` + `CI`), one doc per test, a test-list index,
and a runner that selects by category or by single test name.

One clean noun — the test category — should thread the whole system: the folder a
test lives in (`tests/<category>/`), the section of the contract that declares it,
the doc that describes it (`docs/tests/<category>/<test>.md`), the index row that
references it, and the argument you pass to run it (`/CJ_test_run --category workflow`
or `/CJ_test_run windows`). Audit and run share ONE vocabulary. A newcomer can look
at `tests/` and immediately see what kinds of tests exist and what each one is.

The full end-state (Approach B) is a REPLACE that physically reorganizes the repo's
tests into `tests/<category>/` and re-expresses the validate gates against the
category contract. At the design gate the operator chose to STAGE it foundation-first:
THIS feature ships the additive foundation only, and the physical reorganization +
grammar removal + validate re-expression are a deferred follow-up run.

## Shape of the solution

This feature adds the category axis to the test contract as a NEW, backward-compatible
capability and re-points the two skills at it — additively, so the repo stays green
because the existing `validate.sh` Checks 24/26/28 keep validating the existing
grammar. The single child user-story carries the whole foundation increment.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Category axis in the contract + engines (backward-compatible), the five audit checks, `--category`/name run, skill+doc rewrites, seed, tests | S000124 | [S000124_category_axis_foundation/S000124_TRACKER.md](S000124_category_axis_foundation/S000124_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Core model = REPLACE (end-state), but ship the ADDITIVE foundation first | The category model is the real V1 and supersedes family/units/behaviors, but staging it foundation-first keeps each PR reviewable and green; the removal + reorganization land in a follow-up. |
| 2 | Category axis is purely ADDITIVE this PR (coexists with units/behaviors/runners) | Checks 24/26/28 still validate the existing grammar this PR, so reshaping/removing the existing axes would turn the repo red. Additive-only is the hard constraint. |
| 3 | Audit posture = REPORT + SEED DOC STUBS ONLY | "Runs standalone in ANY repo" is load-bearing: the audit reports structural gaps and may seed `docs/tests/<category>/*.md` + the index idempotently, but NEVER moves or rewrites a foreign repo's test scripts. |
| 4 | V1 category taxonomy is the closed set `{workflow, CI}` | Keeps the first increment mechanical: every `*.test.sh` contract/unit suite (gated by `test.sh`) is `CI`; the `tests/eval/` cases + `e2e-local` are `workflow`. `unit`/`integration`/`eval`-paid/`property` are explicitly deferred; the axis stays open-world for future growth. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Staying green: the additive category axis must not perturb the existing `--validate` / `--check-coverage` / `--render-docs --check` / `--check-workflow-coverage` behavior | QA runs full `validate.sh` + `test.sh` + the doc/test audit; a red result forces a Halt-and-iterate before ship. |
| Backward-compatible overlay parsing: adding a new overlay section could break the existing test-spec.sh parser for older overlays | New tests assert both the new category subcommands AND that the pre-existing subcommands still pass on the current overlay. |
| Scope creep into the deferred physical move | The child SPEC's "Not in scope" fences the deferred work explicitly; QA checks no `*.test.sh` scripts were moved and the family docs were not deleted. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `test-spec.sh` exposes the new category surface (a `--seed`-carried portable category contract + category list/validate/structure/render subcommands) while the existing subcommands remain green on the current overlay.
- [ ] `/CJ_test_audit` reports the five structural checks (a–e) as findings-not-crashes and seeds missing `docs/tests/<category>/<name>.md` stubs + the index table idempotently; it never moves scripts.
- [ ] `/CJ_test_run` selects by `--category <workflow|CI>` and by single test name (reusing the `docs/tests/` name); the default run touches no paid model.
- [ ] Both skills' `SKILL.md` + `USAGE.md` are rewritten around the category model and CLAUDE.md's scripts-reference + contract prose match.
- [ ] `validate.sh` + `test.sh` + the post-doc-sync doc/test audit are green; new tests cover the category behavior; the change is verified ADDITIVE (no removal of the existing axes / family-doc render).

## Not in scope

<!-- Explicit non-goals. Deferred to a follow-up cj_goal run per the design's "Explicitly DEFERRED" list. -->

- Physically moving the ~30 `*.test.sh` scripts into `tests/workflow/` + `tests/CI/` and rewriting `test.sh` discovery + the anchor paths — deferred follow-up.
- REMOVING the existing `units:` / `behaviors:` / `runners:` grammar — deferred (the category axis coexists this PR).
- RE-EXPRESSING `validate.sh` Checks 24 / 26 / 28 against the category contract — deferred (they keep running over the existing grammar so the repo stays green).
- Migrating the existing flat `docs/tests/<family>.md` into category subdirs — deferred (this PR ADDS category docs where the contract declares category tests; it does not delete the family docs).

## Pointers

- Parent tracker: [F000074_TRACKER.md](F000074_TRACKER.md)
- Roadmap: [F000074_ROADMAP.md](F000074_ROADMAP.md)
- Child user-story: [S000124_category_axis_foundation/S000124_TRACKER.md](S000124_category_axis_foundation/S000124_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-charming-germain-70dd6e-design-20260702-134458.md`
