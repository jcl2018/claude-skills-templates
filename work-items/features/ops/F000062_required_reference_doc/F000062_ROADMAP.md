---
type: roadmap
parent: F000062
title: "Required reference.md — a general-tier curated external-references doc — Roadmap"
date: 2026-06-12
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals, decomposition,
     and delivery timeline. -->

## Scope

Add a new REQUIRED general-tier doc, `docs/reference.md` — a curated shelf of
external references (repos / links / blogs / articles) relevant to building this
workbench, grouped by category, each entry with a one-line note on why it is
relevant. The doc is governed by the doc contract: declared `section: common` /
`audit_class: human-doc` (no `front_table`) byte-identically across all three
seed copies, with the general-doc count word swept `eleven`→`twelve` and the
generated `docs/doc-general.md` view regenerated. Reuses the F000058
general-docs-required row+count+view mechanics; `validate.sh` is untouched
because its registry-reading checks pick up the new declared doc automatically.

## Non-Goals

- A `reference-custom.md` overlay — not requested; the general doc + the existing custom-overlay mechanism already let a repo extend.
- Auto-validation that links resolve (HTTP-checking) — out of the contract's deterministic scope; agent-judged staleness covers it.
- Any `validate.sh` edit — the registry-reading checks cover the new doc automatically.
- Orchestrator / drain-layer changes — this is a pure doc-contract addition.

## Success Criteria

<!-- Bulleted, measurable outcomes, observable from the outside. -->

- [ ] `docs/reference.md` exists, declared `section: common`, curated with real grouped entries, no work-item IDs.
- [ ] Seed 3-way byte-identity holds after the row + table + count edits (`--seed | cmp -` clean against both copies).
- [ ] `eleven`→`twelve` swept everywhere it described the general-doc count (3 seed copies + `spec/doc-spec-custom.md` + the CLAUDE.md parenthetical).
- [ ] `docs/doc-general.md` regenerated to list 12 docs; Check 23 green.
- [ ] `scripts/validate.sh` PASS 0/0; `scripts/test.sh` PASS (config test 8b tolerates 12 / lists reference.md).
- [ ] QA's three-stage `/CJ_doc_audit` reports reference.md `satisfies` (Stage 2) + `no-drift` (Stage 3).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000104](S000104_curated_reference_doc_and_seed_row/S000104_TRACKER.md) | Curated reference.md + 3-way seed row/table/count + view regen + QA dogfood | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Owner = primary person responsible. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000104 (full build: file + seed edits + view regen + test verify) | — | Not Started | chjiang | Single-story feature | — |
| 2 | End-to-end pipeline run (scaffold → implement → QA → PR) | — | Not Started | chjiang | reference.md dogfoods the three-stage `/CJ_doc_audit` | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-12: Scaffolded (F000062 / S000104).

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000104 (reference.md + seed row/table/count + doc-general.md regen) --> #2 End-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Final editorial set of curated entries ("useful") | Operator prunes/extends `docs/reference.md` at the PR (The Assignment). |
