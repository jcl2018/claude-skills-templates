---
type: roadmap
parent: F000056
title: "Cleaner doc-contract: generated general/custom views + philosophy Doc-contract topic — Roadmap"
date: 2026-06-08
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline. -->

## Scope

Make the doc-contract cleaner without breaking the contract: keep the one root
`doc-spec.md` registry as the single source of truth, and generate two readable
`docs/` views (`doc-general.md` for `section: common` docs, `doc-custom.md` for
`section: custom` docs) the same way `README.md` is generated from
`skills-catalog.json`. A `validate.sh` check keeps the views in lockstep with the
registry. Lift the doc-contract *logic* into a new `docs/philosophy.md` `## Topic:
Doc contract`, and slim the `doc-spec.md` Custom prose to a pointer (preserving the
"Repo notes" rationale). The portable Common seed is untouched.

## Non-Goals

- Relocating `doc-spec.md` into `docs/` — excluded; it is config read by ~13
  hardcoded `./`-relative call sites, and the move breaks every pinned path + every
  consumer repo.
- Touching the Common/portable seed section of `doc-spec.md` — excluded; it is
  byte-identical to `templates/doc-spec-common.md` (test #13) and shared by consumer
  repos.
- Extending the seed so adopting repos auto-generate views — excluded; deferred
  clean follow-up.
- Auto-regenerating views on `/ship` — excluded; v1 leaves regen manual, gated by the
  drift check.
- A "Present?" render column — excluded; 3-column form shipped for determinism.

## Success Criteria

<!-- Measurable, externally observable outcomes. -->

- [ ] `doc-spec.sh --render general` emits exactly 4 rows; `--render custom` emits exactly 9 rows; cells quote-stripped + pipe-escaped.
- [ ] `scripts/generate-doc-views.sh --output-dir` writes `docs/doc-general.md` + `docs/doc-custom.md` idempotently.
- [ ] The two registry entries + the two generated files land in the SAME commit (Check 15a green).
- [ ] `validate.sh` Check 23 fails on drift, passes in sync, skips cleanly if the generator is absent; `test.sh` mirrors it stdout/temp-only.
- [ ] `docs/philosophy.md` `## Topic: Doc contract` carries the two principles + model; front-table labels updated; Check 19/20 green; Decision tree last.
- [ ] `doc-spec.md` Custom prose slimmed + rationale preserved; Common section byte-identical to the seed (test #13 green); registry validates clean.
- [ ] `CLAUDE.md` Scripts table documents `generate-doc-views.sh`; `generate-readme.sh:23` blurb updated + `README.md` regenerated.
- [ ] `validate.sh` + `test.sh` + portability gate green; PR opens and STOPS.

## Decomposition

<!-- The user-stories that decompose this feature. Status: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000098](S000098_doc_contract_generated_views_topic/S000098_TRACKER.md) | Generated general/custom doc views + philosophy Doc-contract topic | Open |

## Delivery Timeline

<!-- Owner = primary person responsible. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000098 (the 8 deltas) | — | Not Started | chjiang | Render subcommand → generator → views → registry → slim prose → philosophy topic → Check 23 + test.sh → generate-readme + README regen | — |
| 2 | End-to-end pipeline run (QA-green → doc-sync → portability → /ship → PR → STOP) | — | Not Started | chjiang | PR-stop; no auto-merge | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-06-08: Scaffolded from /office-hours design doc (chjiang-claude-sleepy-cerf-e8f24b-design-20260608-doc-contract.md).

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000098 (8 deltas) --> #2 End-to-end pipeline run (/ship → PR → STOP)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Render columns: 3-column (Doc · Purpose · Requirement) vs. adding "Present?" | Resolved at SPEC: 3-column for determinism; "Present?" deferred |
| Auto-regen views on `/ship`? | v1 manual + gated by Check 23; auto-regen is a deferred follow-up |
