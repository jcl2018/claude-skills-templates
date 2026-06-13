---
type: roadmap
parent: F000065
title: "Self-healing contract-file reconcile for the audit skills — Roadmap"
date: 2026-06-13
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each
     piece ships). -->

## Scope

Make `/CJ_doc_audit` and `/CJ_test_audit` idempotent across *generations* of the
contract file, not just present/absent. Each audit's engine (`scripts/doc-spec.sh`,
`scripts/test-spec.sh`) gains a read-only `--classify` (labels
absent / canonical / legacy / duplicate / wrong-position) and an opt-in
`--reconcile` (migrates a legacy YAML-generation file to the canonical 3-column
Markdown table, preserving every declared row, atomic + `.bak` + migration
report; idempotent no-op on canonical). The audit skills generalize their "seed
if missing" step into a reconcile step driven by `--classify`: absent → seed
(unchanged); non-canonical → an advisory `RECONCILE:` directive into the Stage-1
report; an opt-in audit `--reconcile` flag forwards to the engine (standalone
only). The canonical contract-file template (required/optional files, position,
format) is written down in each audit's USAGE.md + the spec prose. Ships as one
PR (Approach A), one atomic child story carrying both internal phases.

## Non-Goals

- Auto-deleting duplicate contract files — v1 reports + reconciles the canonical copy; `--prune-duplicates` deferred (OQ1).
- Relocating a root-only contract into `spec/` — root is accepted; root-only is advisory `wrong-position` (OQ2).
- Redefining the canonical format/position — the audits already own it; this reconciles existing files TO it.
- Auto-creating the docs/units a contract *declares* — already reported by Stage 1 (declared-exists).
- Any external/runtime dependency change — parser stays POSIX-shell awk/sed, no python/yaml dep.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `doc-spec.sh --classify` correctly labels `absent` / `canonical` / `legacy` / `duplicate` fixtures; `test-spec.sh --classify` likewise.
- [ ] `doc-spec.sh --reconcile` migrates a legacy YAML fixture (multi-row, incl. a 40+-row fixture) to canonical Markdown **with every declared row preserved**, `--validate`-clean, `.bak` written, idempotent on re-run.
- [ ] The `audit_class` asymmetry guard fires `RECONCILE-WARN` for a `docs/*` row that was `operational`.
- [ ] `/CJ_doc_audit` on a legacy fixture surfaces a `RECONCILE:` directive in the Stage-1 report; `/CJ_doc_audit --reconcile` performs the migration; a canonical repo emits zero reconcile lines.
- [ ] Symmetric coverage for `/CJ_test_audit`.
- [ ] The canonical contract-file template (required/optional/position/format) is documented in each audit's USAGE.md + the spec prose.
- [ ] `scripts/validate.sh` stays green (0/0); the live workbench classifies `canonical` with no reconcile noise. New `tests/*.test.sh` registered in `scripts/test.sh` AND `spec/test-spec-custom.md`.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000109](S000109_reconcile_engine_and_audit_wiring/S000109_TRACKER.md) | Reconcile engines (`--classify`/`--reconcile`) + audit-skill wiring | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Phase 1 — `doc-spec.sh` + `test-spec.sh` `--classify` + `--reconcile`; `validate.sh` + `test.sh` green | — | Not Started | chjiang | Recover legacy YAML grammar (git history `716a537`); migrate-preserving + atomic + `.bak` + `audit_class` asymmetry guard; confirm test-spec legacy signature | — |
| 2 | Phase 2 — audit-skill wiring (Step-2 directive + opt-in `--reconcile` flag), canonical-template docs, fixtures; `validate.sh` + `test.sh` green | — | Not Started | chjiang | Read-mostly default; advisory directive; both skills; register tests in `test.sh` + `spec/test-spec-custom.md`; workbench classifies `canonical` clean | #1 |
| 3 | QA → doc-sync → portability gate → /ship → PR (stop for human review) | — | Not Started | chjiang | One PR | #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-13: Scaffolded F000065 + child S000109 from the /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Phase 1: reconcile engines (--classify + --reconcile), suite green
      |
      v
#2 Phase 2: audit-skill wiring + canonical-template docs + fixtures, suite green
      |
      v
#3 QA -> doc-sync -> portability -> /ship -> PR (human review)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| OQ1 — auto-delete duplicates? | v1 reports + reconciles the canonical copy but does NOT delete the redundant file (safe default). A future `--reconcile --prune-duplicates` could remove it after the canonical write verifies. Deferred. |
| OQ2 — root→spec relocation? | Root is an accepted position, so v1 treats root-only as advisory `wrong-position` (reported, not moved). Relocation is opt-in future work. |
| OQ3 — test-spec legacy signature? | doc-spec's old YAML generation is well characterized (git history). The exact old test-spec on-disk signature must be confirmed during implementation; if test-spec never had a divergent legacy format, its `--classify` reduces to canonical/absent + duplicate and `--reconcile` is a dedup/no-op (still symmetric, less converter work). |
