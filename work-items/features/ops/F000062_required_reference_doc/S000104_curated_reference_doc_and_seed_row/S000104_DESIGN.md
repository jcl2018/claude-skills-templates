---
type: design
parent: S000104
title: "Curated reference.md + 3-way seed row/table/count + view regen — Story Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- Atomic-story design. Derives directly from the parent feature's
     /office-hours session — see F000062_DESIGN.md for full context. Each
     section is brief by design. -->

## Problem

The workbench has no governed home for the external references that shaped it.
This story builds the required general-tier `docs/reference.md` and wires it into
the doc contract end to end. See [parent F000062_DESIGN.md](../F000062_DESIGN.md)
for the full problem framing.

## Shape of the solution

Six coupled, mechanical pieces shipped in one PR: (1) the curated
`docs/reference.md` file (grep-grounded, grouped, no work-item IDs); (2) the
registry row added byte-identically after `docs/architecture.md` to all 3 seed
copies (`scripts/doc-spec.sh` heredoc + `templates/doc-spec-common.md` +
`spec/doc-spec.md`); (3) the "Human docs" prose-table row in all 3; (4) the
`eleven`→`twelve` count sweep across the 3 seed copies + `spec/doc-spec-custom.md`
+ the CLAUDE.md parenthetical; (5) `scripts/generate-doc-views.sh` regenerating
`docs/doc-general.md`; (6) verification — 3-way `cmp`, the doc-spec subcommands,
Check 23, `validate.sh` 0/0, and config-test-8b growth-safe confirmation.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | General-seed tier (D15.1) | Required everywhere; pay the consumer-ripple cost for a rule that means the same in every repo. |
| 2 | Curated v1, grep-grounded (D15.2) | Real entries only; no invented influences; operator prunes at PR. |
| 3 | No `front_table`; requirement asserts shape not links | A link shelf, not an index — Check 20 N/A; the requirement can't self-stale on a single link change. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| A seed copy drifts | 3-way `cmp` smoke row catches it pre-commit; Check 16 fails a malformed registry. |
| A work-item ID slips into the human-doc | Check 19 (HARD) + the clean-grep smoke row. |
| Config test 8b breaks on count 12 | It is inclusion-based; verify it tolerates 12 + add a reference.md include-assertion. |

## Definition of done

- [ ] `docs/reference.md` exists, declared `section: common`, curated, no work-item IDs.
- [ ] Registry row + table row + `eleven`→`twelve` byte-identical in all 3 seed copies; count swept in `spec/doc-spec-custom.md` + CLAUDE.md.
- [ ] 3-way `cmp` clean; `docs/doc-general.md` regenerated (12 docs); Check 23 green.
- [ ] `validate.sh` PASS 0/0; `test.sh` PASS (8b tolerates 12 + lists reference.md).
- [ ] QA `/CJ_doc_audit`: reference.md `satisfies` + `no-drift`.

## Not in scope

- A `reference-custom.md` overlay — the general doc + existing overlay mechanism already allow extension.
- HTTP link-liveness checking — out of the contract's deterministic scope.
- Any `validate.sh` edit — registry-reading checks cover the new doc automatically.

## Pointers

- Parent design: [../F000062_DESIGN.md](../F000062_DESIGN.md)
- Parent tracker: [../F000062_TRACKER.md](../F000062_TRACKER.md)
- This story: [S000104_TRACKER.md](S000104_TRACKER.md) · [S000104_SPEC.md](S000104_SPEC.md) · [S000104_TEST-SPEC.md](S000104_TEST-SPEC.md)
- Precedent: F000058 (general-docs-required mechanics); F000060/F000061 (two-tier seed + three-stage audit).
