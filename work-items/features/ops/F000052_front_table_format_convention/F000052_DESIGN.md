---
type: design
parent: F000052
title: "Front-table format convention for philosophy.md & workflow.md (registry-driven, enforced) — Feature Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`docs/philosophy.md` (~149 lines: 3 `## Principle N` sections + a decision tree)
and `docs/workflow.md` (~636 lines: 3 orchestrators + machinery + utilities) are
long, section-structured human docs. A reader scanning for "which principle /
which workflow do I want" has to skim the whole file — there is no at-a-glance
index at the top of either doc.

The fix is a **format convention**: each of these two docs must open with a
summary table listing all of its items (every principle for philosophy.md; every
workflow / entry point for workflow.md). The convention is registered in the
`doc-spec.md` contract and **enforced as a hard `validate.sh` gate** (the operator
chose enforcement over advisory-only). The gate is **registry-driven** —
`validate.sh` learns which docs require a front table by reading a new registry
field, not by hardcoding filenames — so the workbench's own first principle
("the registry is the source of truth; tooling parses it, never a second
hardcoded list", Principle 3 in the very file being edited) is honored.

## Shape of the solution

A single self-contained tooling change, carried by one user-story child. The
change spans the doc registry, the registry parser, the validator, the test
suite, the two human docs themselves, and a small set of doc-touches that keep
the subcommand/check enumerations from going stale.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Registry field + subcommand + Check 20 + front tables + tests + doc-touches | S000092 | [S000092_front_table_format_convention/S000092_TRACKER.md](S000092_front_table_format_convention/S000092_TRACKER.md) |

The pieces fit together as a one-way data flow: `doc-spec.md` (new `front_table:
required` field) → `scripts/doc-spec.sh --list-front-table-docs` (new subcommand,
separate awk path) → `scripts/validate.sh` Check 20 (consumes the subcommand
output; asserts a leading table before the first `^## `) → CI/pre-commit. The two
human docs gain their leading tables in the same change so they satisfy the new
requirement immediately (no self-stale ship).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Enforced, registry-driven (Approach C) over advisory-only (A) | Operator escalated from advisory (recommended) to a hard CI gate, and chose the registry-driven gate source over hardcoding filenames in validate.sh. |
| 2 | Workbench-local registry extension (C2) over propagating via the `doc-spec.sh` seed heredoc (B) | Keep the `DOC-SPEC-COMMON:BEGIN/END` prose block + `_emit_seed` byte-identical so `doc-spec.md` still satisfies its own "Common section verbatim from the seed" requirement. The new field lives in the machine registry OUTSIDE the COMMON markers and is documented in the Custom prose section. |
| 3 | New `--list-front-table-docs` uses a SEPARATE awk path; `_parse_registry`'s 3-column TSV is NOT widened | Its consumer `_run_registry_gates` reads the TSV with a 3-variable `while IFS=... read -r _p _s _c`; adding a 4th column without widening that `read` would append `front_table` onto `_c` (`audit_class`) and break the closed-enum gate for every entry. A separate awk path sidesteps this entirely. |
| 4 | Check 20 stops at the FIRST `^## ` heading; emits `  ERROR:` inline (not `fail()`) | Both docs already contain tables LATER (philosophy.md:136 inside the decision tree, workflow.md:581) — a whole-file grep would yield a false PASS. The negative test greps a literal `  ERROR:` prefix, so the inline Check 15-19 style is required (the `fail()` helper prints `FAIL:`). |
| 5 | Only philosophy.md + workflow.md flagged; architecture.md left unflagged | Demonstrates the registry-driven scoping payoff — flagging architecture.md later is a one-line registry edit, no validator change. Deferred as out of scope. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Widening `_parse_registry`'s shared TSV would silently break the closed-enum gate for every registry entry | Implementation uses a separate awk path; verified by `doc-spec.sh --validate` still returning `OK schema_version=1` and the existing config unit tests staying green. |
| Check 20's awk reaching EOF / a later table and yielding a false PASS | Plant-and-restore negative test in `scripts/test.sh` strips the leading table from a flagged real doc and asserts a non-zero exit with the `  ERROR:` Check-20 prefix. |
| Adding `--list-front-table-docs` makes three existing subcommand enumerations stale (CLAUDE.md, architecture.md, CJ_document-release SKILL.md) | Doc-touches folded into the same PR; the SKILL.md edit pairs with a USAGE.md `last-updated` bump (Check-14 idempotent-override recipe) so it doesn't leave USAGE.md flagged. |
| Exact table columns (philosophy: `# \| Principle \| In one line`; workflow: `Entry point \| What it does`) | Left to implementation — the gate asserts a leading table, not specific columns. |
| Whether to flag `architecture.md` with a front table too | Deferred, out of scope; one-line registry edit later. |

## Definition of done

- [ ] `scripts/doc-spec.sh --list-front-table-docs` prints exactly `docs/philosophy.md` and `docs/workflow.md`.
- [ ] `scripts/doc-spec.sh --validate` still returns `OK schema_version=1`.
- [ ] `scripts/validate.sh` passes on the repo and fails with a `  ERROR:` Check-20 line when a flagged doc's leading table is removed.
- [ ] `scripts/test.sh` is green end-to-end, including the new plant-and-restore Check-20 integration test and the `--list-front-table-docs` unit assertions.
- [ ] `docs/philosophy.md` and `docs/workflow.md` each open with a summary table; both still pass Check 15/15a/15b and Check 19.
- [ ] No `doc-spec.sh` subcommand enumeration left stale (CLAUDE.md, architecture.md, CJ_document-release SKILL.md updated; USAGE.md `last-updated` bumped).

## Not in scope

- `scripts/doc-spec.sh` `_emit_seed` (the portable seed) — NOT touched.
- The `DOC-SPEC-COMMON` prose block in `doc-spec.md` — stays byte-identical.
- `_parse_registry`'s shared 3-column TSV (and its `read` consumer) — NOT widened.
- `architecture.md` / `README.md` as *flagged* docs — only philosophy + workflow are flagged this change.
- Portable propagation to adopting repos via the seed (Approach B) — deliberately kept workbench-local.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. -->

- Parent tracker: [F000052_TRACKER.md](F000052_TRACKER.md)
- Roadmap: [F000052_ROADMAP.md](F000052_ROADMAP.md)
- Child user-story: [S000092_front_table_format_convention/S000092_TRACKER.md](S000092_front_table_format_convention/S000092_TRACKER.md)
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260606-154639-66395-design-20260606-160250.md`
- Related lineage: F000037 (cj_document_release_config), F000046 (consolidate_doc_release_required_docs), F000050 (doc_spec_driven_dev).
