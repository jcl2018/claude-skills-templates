---
type: design
parent: S000092
title: "Front-table format convention (registry field + subcommand + Check 20 + tables + tests + doc-touches) — Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Derives directly from the parent feature's
     /office-hours session; see F000052_DESIGN.md for the full cross-story
     context. Sections kept per template; content is brief where the parent
     carries the depth. -->

## Problem

`docs/philosophy.md` and `docs/workflow.md` are long, section-structured human
docs with no at-a-glance index at the top. A reader scanning for "which principle
/ which workflow do I want" must skim the whole file. This story adds a leading
summary table to each, registers the requirement in `doc-spec.md`, and enforces
it as a hard, registry-driven `validate.sh` gate. See parent
[F000052_DESIGN.md](../F000052_DESIGN.md) for the full problem framing.

## Shape of the solution

One-way data flow: a new workbench-local `front_table: required` field in
`doc-spec.md` → a new `scripts/doc-spec.sh --list-front-table-docs` subcommand
(separate awk path) → a hard `scripts/validate.sh` Check 20 that consumes it and
asserts a leading table before the first `^## ` heading. The two docs gain their
tables in the same change; the affected subcommand/check enumerations
(CLAUDE.md, architecture.md, CJ_document-release SKILL.md+USAGE.md) are kept
current. Implementation order is fixed: registry field → subcommand → tables →
Check 20 → tests → doc-touches.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Separate awk path for `--list-front-table-docs`; do NOT widen `_parse_registry`'s 3-column TSV | Its consumer reads with a 3-var `read`; a 4th column would append onto `audit_class` and break the closed-enum gate for every entry. |
| 2 | Check 20 stops at the first `^## `; emits `  ERROR:` inline (not `fail()`) | Both docs already have tables LATER; a whole-file grep would false-PASS. The negative test greps a literal `  ERROR:` prefix. |
| 3 | Workbench-local registry extension; `_emit_seed` + `DOC-SPEC-COMMON` block untouched | `doc-spec.md` keeps satisfying its "Common section verbatim from the seed" requirement. |

(Full rationale + the rejected Approaches A/B live in the parent
[F000052_DESIGN.md](../F000052_DESIGN.md).)

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| A 4th TSV column silently breaking the closed-enum gate | `doc-spec.sh --validate` still returns `OK schema_version=1`; existing config unit tests stay green. |
| Check 20 false-PASS via a later table / EOF | Plant-and-restore negative test asserts a non-zero exit + `  ERROR:` Check-20 prefix. |
| Exact table columns | Implementation — the gate asserts a leading table, not specific columns. |

## Definition of done

- [ ] `doc-spec.sh --list-front-table-docs` prints exactly the two flagged docs; `--validate` still `OK schema_version=1`.
- [ ] Check 20 passes on the repo and fails with a `  ERROR:` line when a flagged doc's leading table is removed.
- [ ] Both docs open with a leading table (no work-item IDs) and still pass Check 15/15a/15b + 19.
- [ ] `scripts/test.sh` green incl. the plant-and-restore negative test and the unit assertions.
- [ ] All doc-touches folded into the same PR (USAGE.md `last-updated` bumped).

## Not in scope

- The portable seed (`_emit_seed`) and the `DOC-SPEC-COMMON` prose block — unchanged.
- Widening `_parse_registry`'s shared 3-column TSV — avoided via the separate awk path.
- Flagging `architecture.md` / `README.md` as front-table docs — only philosophy + workflow this change.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent feature design: [../F000052_DESIGN.md](../F000052_DESIGN.md)
- Parent tracker: [../F000052_TRACKER.md](../F000052_TRACKER.md)
- This story's spec: [S000092_SPEC.md](S000092_SPEC.md)
- This story's test spec: [S000092_TEST-SPEC.md](S000092_TEST-SPEC.md)
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260606-154639-66395-design-20260606-160250.md`
