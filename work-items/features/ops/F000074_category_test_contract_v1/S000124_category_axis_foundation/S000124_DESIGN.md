---
type: design
parent: S000124
title: "Category-axis foundation — Story Design"
version: 1
status: Draft
date: 2026-07-02
author: chang
reviewers: []
---

<!-- Atomic story deriving from the parent feature's /office-hours session.
     See F000074_DESIGN.md for the full cross-story context. -->

## Problem

The two experimental test-contract skills are built around a family/units/behaviors/
runners model that the operator wants finalized around a simpler category-based mental
model (`workflow` + `CI`). This story carries the whole V1 FOUNDATION increment: add
the category axis backward-compatibly and re-point both skills at it, without the
deferred physical reorganization — so the repo stays green.

## Shape of the solution

Add a NEW category axis to the test contract (a `--seed`-carried portable category
contract + new `test-spec.sh` category subcommands) that coexists with the existing
grammar. Give `/CJ_test_audit` the five structural checks (a–e) with report + idempotent
doc-stub seeding (never moving scripts). Give `/CJ_test_run` `--category` + single-test-name
selection reusing the `docs/tests/` name. Rewrite both skills' SKILL.md + USAGE.md and
CLAUDE.md around the category model. Keep everything ADDITIVE.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Additive-only this PR (no removal/reorganization) | Checks 24/26/28 still validate the existing grammar; the change must stay green. |
| 2 | Audit REPORTS + SEEDS docs, never moves scripts | "Runs standalone in ANY repo" is load-bearing — the audit must not mutate a foreign repo's test layout. |
| 3 | V1 taxonomy is the closed set `{workflow, CI}` | Makes category assignment mechanical: every `*.test.sh` is `CI`; `tests/eval/` + `e2e-local` are `workflow`. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| The new overlay section perturbs existing test-spec.sh subcommands | New tests assert both the new and the pre-existing subcommands during QA. |
| Scope creep into the deferred physical move | The SPEC "Not in scope" fences it; QA verifies no scripts moved and no family docs deleted. |

## Definition of done

- [ ] Category subcommands + `--seed` portable contract work; the pre-existing subcommands stay green.
- [ ] `/CJ_test_audit` reports the five checks + seeds doc stubs idempotently, never moving scripts.
- [ ] `/CJ_test_run` selects by `--category` + single name; default run touches no paid model.
- [ ] Both skills' SKILL.md + USAGE.md + CLAUDE.md updated; `validate.sh` + `test.sh` + doc/test audit green; change verified ADDITIVE.

## Not in scope

- Physically moving `*.test.sh` scripts + rewriting `test.sh` discovery + anchor paths — deferred follow-up.
- Removing the `units:` / `behaviors:` / `runners:` grammar — deferred (coexists this PR).
- Re-expressing `validate.sh` Checks 24 / 26 / 28 against the category contract — deferred.
- Migrating flat `docs/tests/<family>.md` into category subdirs — deferred.

## Pointers

- Parent feature design: [../F000074_DESIGN.md](../F000074_DESIGN.md)
- Parent feature tracker: [../F000074_TRACKER.md](../F000074_TRACKER.md)
- Story tracker: [S000124_TRACKER.md](S000124_TRACKER.md)
- Spec: [S000124_SPEC.md](S000124_SPEC.md)
- Test spec: [S000124_TEST-SPEC.md](S000124_TEST-SPEC.md)
