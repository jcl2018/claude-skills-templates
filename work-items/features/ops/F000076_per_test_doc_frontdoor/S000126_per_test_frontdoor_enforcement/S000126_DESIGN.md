---
type: design
parent: S000126
title: "Per-test doc front-door enforcement — Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

<!-- This is an atomic user-story deriving from the parent feature's /office-hours
     session. Sections are kept complete but brief; the parent F000076_DESIGN.md
     carries the full cross-story rationale. -->

## Problem

The category-test docs (`docs/tests/<category>/<name>.md`) are the right per-test
surface but are thin, seeded stubs and are unenforced — no rule requires a test's
doc to say what it is, how to run it, and why. This story makes each such doc the
authoritative What/How/Why front door via a GENERAL portable rule, while keeping
the generated family docs as linked units-detail. See parent
[F000076_DESIGN.md](../F000076_DESIGN.md) for the full problem framing.

## Shape of the solution

Eight tightly-coupled changes, all in this one story: (1) EDIT the existing
category-axis section in `spec/test-spec.md` + the `scripts/test-spec.sh --seed`
heredoc in lockstep to state the what/how/why requirement; (2) enrich the
`--seed-docs` stub template to the three-section shape; (3) one-time fill of the 7
existing category docs with family-doc cross-links; (4) add a `--check-structure`
content check gated on the `categories:` axis; (5) wire it into `/CJ_test_audit`
Stage 1 + a Stage-2 truthfulness judgment; (6) surface the doc's How-to-run in
`/CJ_test_run <name>`; (7) update `spec/doc-spec-custom.md` category-doc row
requirements; (8) update both cj_test skills' docs + catalog + tests.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | General portable rule via an EDIT (not an append) to the shared category-axis section. | Preserves the `cmp -s` byte-identity between `spec/test-spec.md` and the `--seed` heredoc that `tests/test-spec.test.sh` asserts. |
| 2 | One-time authored fill of the 7 docs; template updated for future tests. | `--seed-docs` is idempotent (present ⇒ skip) and will not upgrade existing stubs. |
| 3 | Keep the family render; doc-spec category rows get requirement-cell updates only. | No row churn → Checks 15/15a stay green; avoids Approach A's join-key/orphan dealbreakers. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Exact section headings (the content check is heading-anchored). | Lock in SPEC `## Open Questions` at start of implement. |
| Seed byte-identity drift across the two files. | `tests/test-spec.test.sh` `cmp -s` case in QA; edit both in one commit. |
| The 7 docs' exact category subdirs after F000075. | Enumerate via `test-spec.sh --list-categories` before authoring. |

## Definition of done

- [ ] General rule in `spec/test-spec.md` + `--seed` heredoc (`cmp -s` green).
- [ ] 7 category docs filled with What/How/Why + family-doc link.
- [ ] `--check-structure` content check green + inactive without a categories axis.
- [ ] `/CJ_test_audit` Stage 1 + Stage 2 green; `/CJ_test_run <name>` surfaces How-to-run.
- [ ] doc-spec category-doc requirements updated; family rows unchanged.
- [ ] cj_test skills' docs + catalog updated; `validate.sh` + full `test.sh` + shellcheck green.

## Not in scope

- The family render (`--render-docs`) + its Check 26 gate — kept unchanged.
- Any join key or schema change — deliberately avoided.
- Re-categorizing or moving any test — nothing moves.

## Pointers

- Parent tracker: [S000126_TRACKER.md](S000126_TRACKER.md)
- Spec: [S000126_SPEC.md](S000126_SPEC.md)
- Test spec: [S000126_TEST-SPEC.md](S000126_TEST-SPEC.md)
- Parent feature design: [../F000076_DESIGN.md](../F000076_DESIGN.md)
