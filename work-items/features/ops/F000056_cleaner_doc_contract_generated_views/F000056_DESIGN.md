---
type: design
parent: F000056
title: "Cleaner doc-contract: generated general/custom views + philosophy Doc-contract topic — Feature Design"
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
     not duplicate it here. -->

## Problem

The operator wants `doc-spec.md` cleaner along three axes: (1) readable general vs
custom doc lists, split into two files under `docs/`; (2) the doc-contract *logic*
lifted into a `philosophy.md` "Doc contract" section; (3) `doc-spec.md` itself made
tidier. The literal proposal — relocate `doc-spec.md` into `docs/` and split it into
two hand-maintained files — was reframed (and the reframe operator-approved) because
the literal form breaks the contract: `doc-spec.md` is config (it carries
`schema_version` + a machine schema and is read by ~13 hardcoded `./`-relative call
sites: 5 scripts, 6 `validate.sh` checks, 8+ skill files), not a doc.

Relocating it would break every pinned path and every consumer repo, collide machine
config with the `docs/ = human-doc` rule, and reintroduce a second list to keep in
sync — the exact thing the "one file" contract exists to prevent.

## Shape of the solution

Keep one root registry; make the readable views GENERATED, the same way `README.md`
is generated from `skills-catalog.json`. The machine registry stays one file at root
(`doc-spec.md`, zero path churn); two readable files (`docs/doc-general.md`,
`docs/doc-custom.md`) become generated views grouped by `section: common` vs
`section: custom`; a `validate.sh` check keeps the views in lockstep with the registry
(regenerate-to-temp + diff; drift fails). The contract's *why* moves into one obvious
place: a new `philosophy.md` `## Topic: Doc contract`. One source of truth, two
readable views, one logic home.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The full 8-delta implementation (render subcommand → generator → views → registry entries → slim Custom prose → philosophy topic → Check 23 + test.sh mirror → generate-readme blurb + README regen) | S000098 | [S000098_doc_contract_generated_views_topic/S000098_TRACKER.md](S000098_doc_contract_generated_views_topic/S000098_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Keep one root registry; generate the two views (Approach A) | Preserves single-source-of-truth; no second list to keep in sync; near-zero path churn (the ~13 pinned `./doc-spec.md` call sites are untouched) |
| 2 | Reject literal relocation to `docs/` + hand-maintained files (Approach B) | Breaks ~13 pinned paths + every consumer repo, collides machine config with the `docs/ = human-doc` rule, reintroduces a second list |
| 3 | Reject philosophy-topic-only (Approach C) | Leaves the hand-maintained duplicate table in `doc-spec.md` and does not deliver the readable general/custom split the operator asked for |
| 4 | Common/portable seed section of `doc-spec.md` is OUT OF SCOPE (untouched) | It is byte-identical to `templates/doc-spec-common.md`, enforced by `tests/cj-document-release-config.test.sh` test #13; touching it breaks the seed + drift test + every consumer repo for no gain |
| 5 | `--render` = a separate awk pass (NOT `_parse_registry`) with quote-strip + pipe-escape | `_parse_registry`'s 3-col TSV would mis-bind a 4th field onto `audit_class` and break the closed-enum gate; `purpose:`/`requirement:` are quoted, multi-word, free-form |
| 6 | Check 23 written from scratch, generator-based (header-safe); `test.sh` mirror is stdout/temp-only | No existing regenerate-and-diff idiom to mirror; the `test.sh` EXIT trap restores README/catalog/VERSION/CHANGELOG but NOT `docs/`, so the test must never write into `docs/` |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Render columns: Doc · Purpose · Requirement (recommended) vs. adding a "Present?" column | Recommend 3-column for determinism; "Present?" is a deferred follow-up — resolved at SPEC time (P0 = 3-column) |
| Generator wiring into `/ship` (auto-regen like README?) | v1: leave manual + gated by the validate check (drift fails CI, prompting a regen); auto-regen-on-ship is a small deferred follow-up |
| Registry entries + generated files must land in the SAME commit, else Check 15a fails declared-but-missing/orphan mid-build | QA verifies both land together; covered in TEST-SPEC |
| The registered-doc audit will emit 2 new (advisory, non-halt) verdict lines for the views | Expected; no action — advisory only |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `doc-spec.sh --render general` emits exactly the 4 `section: common` rows; `--render custom` emits exactly the 9 `section: custom` rows (7 root operational + 2 self-referencing views); cells quote-stripped + pipe-escaped.
- [ ] `scripts/generate-doc-views.sh --output-dir` writes the two views idempotently (twice → identical output).
- [ ] The two registry entries + the two generated files land in the SAME commit (Check 15a green mid-build).
- [ ] `validate.sh` Check 23 fails on drift, passes when in sync, skips cleanly if the generator is absent; `scripts/test.sh` mirrors it stdout/temp-only.
- [ ] `docs/philosophy.md` has `## Topic: Doc contract` (the two doc-contract principles + the model); front-table labels updated; Check 19/20 green; Decision tree stays last.
- [ ] `doc-spec.md` Custom prose slimmed to a pointer with the "Repo notes" rationale preserved; Common section byte-identical to the seed (test #13 green); registry `doc-spec.sh --validate` clean.
- [ ] `CLAUDE.md` Scripts table documents `generate-doc-views.sh`; `generate-readme.sh:23` blurb updated + `README.md` regenerated.
- [ ] `validate.sh` + `test.sh` green; portability gate green; PR opens and STOPS.

## Not in scope

- Extending the Common/portable seed so every adopting repo auto-generates views — explicitly deferred (the seed, the consumer-repo story, and test #13 stay untouched).
- Auto-regenerating the views on `/ship` — v1 leaves regen manual, gated by the validate drift check; a small follow-up.
- A "Present?" render column — the 3-column (Doc · Purpose · Requirement) form is shipped for determinism; a follow-up could add it.
- Any change to the Common section of `doc-spec.md` — out of scope by design (seed parity).

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000056_TRACKER.md](F000056_TRACKER.md)
- Roadmap: [F000056_ROADMAP.md](F000056_ROADMAP.md)
- Child story: [S000098_doc_contract_generated_views_topic/S000098_TRACKER.md](S000098_doc_contract_generated_views_topic/S000098_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-doc-contract.md`
