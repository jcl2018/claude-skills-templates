---
type: roadmap
parent: F000074
title: "Category-based test contract — /CJ_test_audit + /CJ_test_run V1 foundation — Roadmap"
date: 2026-07-02
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals, decomposition, delivery timeline. -->

## Scope

Deliver the FOUNDATION increment of the category-based test contract: add a NEW,
backward-compatible category axis (`workflow` + `CI`) to the two-tier test contract
and re-point the two experimental skills at it. `/CJ_test_audit` gains the five
structural checks (a–e) with report + idempotent doc-stub seeding (never moving
scripts); `/CJ_test_run` gains `--category` + single-test-name selection reusing the
`docs/tests/` name. Both skills' `SKILL.md` + `USAGE.md` are rewritten around the
category model and CLAUDE.md is updated to match. The category contract is carried
portably via `test-spec.sh --seed`. The whole increment is ADDITIVE so the repo stays
green: the existing units/behaviors/runners grammar, the `docs/tests/<family>.md`
render, and `validate.sh` Checks 24/26/28 are left intact this PR.

## Non-Goals

- Physically moving the `*.test.sh` scripts into `tests/workflow/` + `tests/CI/` — deferred follow-up run.
- Removing the existing `units:` / `behaviors:` / `runners:` grammar — deferred (coexists this PR).
- Re-expressing `validate.sh` Checks 24 / 26 / 28 against the category contract — deferred (they keep validating the existing grammar to stay green).
- Migrating flat `docs/tests/<family>.md` into category subdirs — deferred (this PR only ADDS category docs where declared).

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] `/CJ_test_audit` standalone reports the five checks (a–e); seeds missing doc stubs idempotently; never moves scripts.
- [ ] `/CJ_test_run --category workflow`, `--category CI`, and `<single-test-name>` each select + run the right tests; the default run touches no paid model.
- [ ] `test-spec.sh --seed` emits the portable category contract; the new category subcommands work while the pre-existing subcommands stay green on the current overlay.
- [ ] Both skills' SKILL.md + USAGE.md + CLAUDE.md describe the category model.
- [ ] `scripts/validate.sh` + the full `scripts/test.sh` suite + the post-doc-sync doc/test audit all pass; the change is verified ADDITIVE.

## Decomposition

<!-- The user-stories that decompose this feature. Status: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000124](S000124_category_axis_foundation/S000124_TRACKER.md) | Category-axis foundation (backward-compatible contract + engines + skills + docs + tests) | Open |

## Delivery Timeline

<!-- Owner = primary person responsible. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000124 (category-axis foundation) | — | Not Started | chang | Additive foundation — contract + engines + skills + docs + tests | — |
| 2 | End-to-end pipeline run (green validate + test + audit) | — | Not Started | chang | Verify the additive change stays green and touches no paid model | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-07-02: Scaffolded F000074 (foundation increment of the category-based test contract).

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000124 (category-axis foundation) --> #2 End-to-end green pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does the additive overlay section risk perturbing the existing test-spec.sh subcommands? | New tests assert both the new category subcommands and the unchanged pre-existing subcommands during QA. |
| Is the V1 category taxonomy `{workflow, CI}` sufficient for the workbench's own tests? | Confirmed at office-hours: every `*.test.sh` suite is `CI`; `tests/eval/` + `e2e-local` are `workflow`. Deferred categories stay out of V1. |
