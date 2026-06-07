---
type: roadmap
parent: F000052
title: "Front-table format convention for philosophy.md & workflow.md (registry-driven, enforced) — Roadmap"
date: 2026-06-06
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Add a registry-driven, hard-enforced format convention: `docs/philosophy.md` and
`docs/workflow.md` must each open with a summary table indexing their items. The
requirement is registered in `doc-spec.md` via a new workbench-local `front_table:
required` field, exposed by a new `scripts/doc-spec.sh --list-front-table-docs`
subcommand, and enforced by a hard `scripts/validate.sh` Check 20 that consumes
that subcommand. The two docs gain their leading tables in the same change, and
the affected subcommand/check enumerations across CLAUDE.md, architecture.md, and
the CJ_document-release skill are kept current.

## Non-Goals

- Touching the portable Common seed (`doc-spec.sh _emit_seed` / the
  `DOC-SPEC-COMMON` prose block) — kept byte-identical; this is a workbench-local
  registry extension.
- Widening `_parse_registry`'s shared 3-column TSV — the new subcommand uses a
  separate awk path to avoid breaking the closed-enum gate.
- Flagging `architecture.md` or `README.md` with a front table — only philosophy
  + workflow are flagged; architecture stays unflagged to demonstrate the
  registry-driven scoping.
- Any new distribution surface — the existing pre-commit `validate.sh` hook,
  `scripts/test.sh`, and the `windows-latest` Git Bash CI job carry the new check.

## Success Criteria

- [ ] `scripts/doc-spec.sh --list-front-table-docs` prints exactly `docs/philosophy.md` and `docs/workflow.md`.
- [ ] `scripts/doc-spec.sh --validate` still returns `OK schema_version=1`.
- [ ] `scripts/validate.sh` passes on the repo and fails with a `  ERROR:` Check-20 line when a flagged doc's leading table is removed.
- [ ] `scripts/test.sh` is green end-to-end, including the plant-and-restore Check-20 integration test and the `--list-front-table-docs` unit assertions.
- [ ] `docs/philosophy.md` and `docs/workflow.md` each open with a summary table; both still pass Check 15/15a/15b and Check 19.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000092](S000092_front_table_format_convention/S000092_TRACKER.md) | Front-table format convention (registry field + subcommand + Check 20 + tables + tests + doc-touches) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000092 — front-table convention end-to-end | — | Not Started | chjiang | Registry field + subcommand + Check 20 + tables + tests + doc-touches | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh green) | — | Not Started | chjiang | Repo passes Check 20; negative test + unit assertions green | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-06: Scaffolded F000052 + child S000092 from the /office-hours design.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000092 (registry field + subcommand + Check 20 + tables + tests + doc-touches)
   --> #2 End-to-end pipeline run (validate.sh + test.sh green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Exact table columns for each doc | Implementation — the gate asserts a leading table, not specific columns. |
| Whether to flag `architecture.md` with a front table too | Deferred / out of scope — one-line registry edit later. |
