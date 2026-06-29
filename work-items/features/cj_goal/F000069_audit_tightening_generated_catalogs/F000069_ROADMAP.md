---
type: roadmap
parent: F000069
title: "Tighten doc/test audits — generated human catalogs, forced seeding, consumer enforcement — Roadmap"
date: 2026-06-28
author: chjiang
status: Draft
---

## Scope

Apply a unified "generated human catalog, freshness-gated, audit-owned" model to
the test surface and the workflow surface, add proactive seeding of the doc/test/
workflow contracts at adoption, and ship a deterministic Stage-1 enforcement gate
installable in any consumer repo. The `spec/` registries stay the single source
of truth; the `docs/` surfaces become generated views the audits keep fresh. The
feature is an EPIC delivered in four phased, independently-shippable user-stories;
this pass delivers Story 1 (the generated `docs/tests/` catalog + the reusable
generator/freshness/audit primitive).

## Non-Goals

- Modifying upstream gstack skills — enforcement lives in this repo's `validate.sh` + audits; never edit `/ship` / `/document-release` / `/land-and-deploy`.
- Changing the `spec/` registry grammar — Story 1 reads the existing merged test-spec rendered fields; it adds a renderer, not a new registry axis.
- Delivering all four stories in one build — the epic is phased; Stories 2–4 ship in subsequent passes.

## Success Criteria

- [ ] **(Story 1)** A human-browsable, GENERATED test catalog (`docs/test-catalog.md` index + `docs/tests/<family>.md`) exists, is committed, and stays byte-fresh against `spec/test-spec*.md` via a hard `validate.sh` Check 26.
- [ ] **(Story 1)** The generator (`test-spec.sh --render-docs`) is deterministic, work-item-ID-free, and self-checking (`--render-docs --check` exits non-zero on drift); `tests/test-spec-render.test.sh` proves it.
- [ ] **(Story 1)** `/CJ_test_audit` enforces catalog freshness in Stage 1 standalone (any repo) and treats `docs/tests/` as a generated surface in Stage 3 (no false orphan).
- [ ] **(Deferred)** Workflows surface fully generated + freshness-gated (Story 2); contracts force-seeded at adoption + stale-engine shadow fixed (Story 3); a portable consumer Stage-1 gate installable as a pre-commit hook (Story 4).

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000114](S000114_gen_tests_catalog_freshness/S000114_TRACKER.md) | Generated docs/tests/ catalog + freshness primitive (P1) | In Progress |
| (deferred) | Workflows full symmetric generation (P2) | Open |
| (deferred) | Forced seeding + stale-engine fix (P3) | Open |
| (deferred) | Consumer Stage-1 enforcement gate (P4) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000114 (generated docs/tests/ catalog + Check 26 + freshness primitive) | — | In Progress | chjiang | This build pass — scaffold → implement → qa → doc-sync → audit → PR | — |
| 2 | Ship Story 2 (workflows full symmetric generation, Check 27, fold 15b/15c) | — | Not Started | chjiang | Reuses S000114's primitive; heaviest (ASCII-chart migration) | #1 |
| 3 | Ship Story 3 (forced seeding `--seed-contracts` + stale-engine capability probe) | — | Not Started | chjiang | Adoption path | #1, #2 |
| 4 | Ship Story 4 (consumer `cj-contract-gate.sh` + hook/CI install) | — | Not Started | chjiang | Cross-machine; verify via temp-dir adopt drill | #1, #2, #3 |
| 5 | End-to-end epic pipeline run (all surfaces generated, seeded, enforced) | — | Not Started | chjiang | Epic closure | #1, #2, #3, #4 |

### Delivery History

- 2026-06-28: F000069 scaffolded (epic) — Story 1 (S000114) fully specified for this build pass; Stories 2–4 tracked as deferred follow-ups.

## Dependency Graph

```
#1 S000114 (docs/tests catalog + freshness primitive)
      |
      v
#2 Story 2 (workflows generation — reuses primitive)
      |
      v
#3 Story 3 (forced seeding + stale-engine fix)
      |
      v
#4 Story 4 (consumer Stage-1 gate)
      |
      v
#5 End-to-end epic pipeline run
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Will byte-faithful ASCII-chart rendering (Story 2) prove brittle? | Story 2 design: byte-diff acceptance test; an explicitly-approved normalized rendering is the documented fallback. |
| Is the consumer gate (Story 4) verifiable inside the workbench? | Story 4: temp-dir adopt drill — cross-machine behavior not fully E2E from inside the workbench. |
