---
type: roadmap
parent: F000063
title: "Tighten the doc-spec & test-spec contract format (table-as-source + gate-spec merge) — Roadmap"
date: 2026-06-12
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each
     piece ships). -->

## Scope

Make the portable spec-contract files lightweight and table-shaped, and
consolidate the verification story into one place. `spec/doc-spec.md` becomes a
3-column markdown table (`Doc | Purpose | Requirement`) that is itself the parsed
source of truth — retiring the fenced-YAML registry, the two generated views
(`docs/doc-general.md`, `docs/doc-custom.md`), their generator, and the
`--render` surface. `spec/gate-spec.md` is fully merged into the test-spec
family: its four-layer `layers[]` map into the general `test-spec.md`, its
per-mode pipeline-gate `gates[]` into `test-spec-custom.md`, `gate-spec.sh` into
`test-spec.sh`, and `validate.sh` Check 22 into Check 24. Ships as one PR,
internally sequenced (doc-spec green first, then the merge green).

## Non-Goals

- Renaming `test-spec` to `verification-spec` — deferred; kept to bound blast radius (OQ2).
- A replacement for the retired front_table lint (Check 20) — if wanted later, returns as a tiny path-list (OQ1).
- Two-PR split (Approach C) — one review/ship chain only.
- Any external/runtime dependency change — parser stays POSIX-shell awk/bash.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `spec/doc-spec.md` parsed directly as a 3-column table; no YAML / `section` / `audit_class` / `front_table`; 3-way byte-identical with `doc-spec.sh --seed` and `templates/doc-spec-common.md`.
- [ ] `docs/doc-general.md`, `docs/doc-custom.md`, `scripts/generate-doc-views.sh`, `scripts/gate-spec.sh`, `spec/gate-spec.md` deleted; grep-clean of all live references across scripts/skills/docs/tests.
- [ ] `doc-spec.sh --check-on-disk` reports `CHECKS_RUN=4`; human-doc-ids still fires via path-derived `audit_class`; `--render` / `--list-front-table-docs` removed.
- [ ] `spec/test-spec.md` carries the `layers[]` registry; `spec/test-spec-custom.md` holds `units:` + a new top-level `gates:` array accepted by `test-spec.sh --validate`.
- [ ] Check 19 passes via the path heuristic; Checks 20 + 23 gone; Check 22 folded into Check 24, marker-drift portion STILL ADVISORY.
- [ ] All four cj_goal pipelines cite `test-spec.md` as the canonical gate sequence; `CJ_doc_audit` re-enumerates the 4 checks; both audit skills seed + run clean in a bare repo AND in this workbench.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` are green.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000105](S000105_doc_test_spec_table_and_gate_merge/S000105_TRACKER.md) | doc-spec table-ification + test-spec/gate-spec full merge | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Phase 1 — doc-spec table-ification; `validate.sh` + `test.sh` green | — | Not Started | chjiang | Table parser + `_check_on_disk` 6→4 rewrite, 3-way seed identity, delete generated views + generator + `--render` | — |
| 2 | Phase 2 — test-spec/gate-spec full merge; `validate.sh` + `test.sh` green | — | Not Started | chjiang | `layers[]` into general, `gates:` array into custom, absorb+delete `gate-spec.sh`, Check 22→24, re-point all four pipelines | #1 |
| 3 | QA → doc-sync → portability gate → /ship → PR (stop for human review) | — | Not Started | chjiang | One PR | #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-12: Scaffolded F000063 + child S000105 from the /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Phase 1: doc-spec table-ification (green)
      |
      v
#2 Phase 2: test-spec/gate-spec full merge (green)
      |
      v
#3 QA -> doc-sync -> portability -> /ship -> PR (human review)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| OQ1 — should a leading-summary-table lint return after Check 20 is retired? | Operator decision later; if yes, ships as a tiny path-list, not a per-row field. Flagged, not blocking. |
| OQ2 — does `test-spec` keep its name once it owns process gates too? | Name kept now to bound blast radius; a future rename to `verification-spec` is a separate, larger change. |
