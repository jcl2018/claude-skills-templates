---
type: roadmap
parent: F000085
title: "Defect-coverage ledger + regression-category materialization — Roadmap"
date: 2026-07-06
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Convert the unenforced "defects earn regression tests" promise into a closed,
machine-checked ledger: a new `defect_coverage:` overlay axis in
`spec/test-spec-custom.md` maps all 38 defect work-item dirs (keyed by full
path) to their live proof via three closed dispositions (`covered-by`,
`covered-by-anchor`, `waived`), enforced by a new deterministic engine check
(`test-spec.sh --check-defect-coverage`) wired as HARD `validate.sh` Check 32
with a hermetic negative test. In the same PR (ledger-first commits), migrate
the 4 pure dedicated defect drills into `tests/regression/CI-push/`, fix the
reverse-sweep token grammar so nested test files are visible, resolve the
doc-sync orphan, mint the first `regression` `categories:` rows (all
deterministic + free) with front-door docs, and rewrite the stale migration
prose.

## Non-Goals

- Splitting the 11 inline `scripts/test.sh` D-blocks into per-defect files — destabilizes a proven battery (Approach C, rejected)
- Moving shared suites or re-owning any test file — single-owner constraint; shared proof is referenced in place via `covered-by-anchor`
- Authoring the remaining waived-gap drills in this PR — filed as TODOS rows (except the ≤30-line shape-guard exception, capped at 3)
- The agentic-test purge + `portability` topic un-enrollment — tracked as a TODOS row, out of scope
- Editing the general `spec/test-spec.md` seed — overlay-only + engine feature (dual-write footgun)
- Adding anything heavy to CI-push — all migrated/new drills are fast deterministic scripts already on (or suitable for) the per-PR path

## Success Criteria

- [ ] `bash scripts/test-spec.sh --check-defect-coverage`: 38/38 dirs dispositioned, 0 findings; named vacuous SKIP in a bare consumer repo
- [ ] `validate.sh` green including new Check 32; the hermetic negative test proves the gate fires (plant → finding → restore → pass)
- [ ] `--list-categories --category regression` returns ≥4 rows, ALL `mode: deterministic` + `tier: free`; `/CJ_test_run --category regression` runs them green with zero model spend
- [ ] Check 24 green after the token-grammar change; the doc-sync orphan is wired (invoked by `scripts/test.sh` + owned by a `units:` row)
- [ ] Structure checks (a–f) green with `tests/regression/CI-push/` + `docs/tests/regression/CI-push/*.md` (three front-door sections, no D-IDs)
- [ ] Full `scripts/test.sh` + shellcheck green locally before push (the CI gate runs all three)
- [ ] An engine FINDING fires if any `covered-by` cites an agentic row (drilled in the negative test)

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000134](S000134_defect_ledger_gate_backfill_migration/S000134_TRACKER.md) | Defect-coverage ledger (axis + Check 32 + 38-dir backfill) + regression migration, ledger-first | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Commit 1 — grammar + parser: `defect_coverage:` axis, block-close regexes, `--list-defect-coverage`, `--validate` enums + duplicate-key guard | — | Not Started | chang | Stage 1 (ledger) | — |
| 2 | Commit 2 — engine check: `--check-defect-coverage` (forward/reverse + mode gate + vacuous skips + machine-classifiable output) | — | Not Started | chang | Stage 1 (ledger) | #1 |
| 3 | Commit 3 — gate wiring + negative test (two plants) + verified 38-row backfill + `/CJ_test_audit` Stage-1 wiring + TODOS rows; MIGRATE rows land as `covered-by-anchor` against current flat proof | — | Not Started | chang | Stage 1 complete — descope point | #2 |
| 4 | Commit 4 — sweep grammar: full relative-path tokens at both sites, recursed glob, doc-sync orphan wired + units row | — | Not Started | chang | Stage 2 (migration) | #3 |
| 5 | Commit 5 — moves: `git mv` 4 pure drills → `tests/regression/CI-push/`; same-commit invocation-line + units-row `anchor:` updates + ledger re-anchor | — | Not Started | chang | Stage 2 (migration) | #4 |
| 6 | Commit 6 — regression `categories:` rows + front-door docs + doc-spec declarations + stale-prose fix + catalog regen; flip MIGRATE rows to `covered-by` | — | Not Started | chang | Stage 2 complete | #5 |
| 7 | Ship S000134 (QA + doc-sync + /ship → PR) | — | Not Started | chang | user-story complete | #6 |
| 8 | End-to-end pipeline run: `/CJ_test_run --category regression` green on both machines post-land | — | Not Started | chang | The Assignment | #7 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. -->

- 2026-07-06: Scaffolded from the APPROVED /office-hours design. No code shipped yet.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 grammar+parser --> #2 engine check --> #3 gate+backfill (DESCOPE POINT)
                                              |
                                              v
                       #4 sweep grammar --> #5 moves --> #6 rows+docs+regen
                                                              |
                                                              v
                                            #7 ship S000134 --> #8 E2E both machines
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Exact final pure-drill migration list (a candidate proving shared/feature behavior stays put) | Implement-time re-verification at commit 5 |
| D000018: cheap deterministic shape-guard (grep qa.md for the E2E-subagent directive) or waiver | Implementer decides by cost at commit 3 (≤30-line cap) |
| Dispositions for the ~13 VERIFY-flagged provisional rows (incl. the two hallucinated proofs) | Verify-before-declare at commit 3; failures default to `waived: "gap — …"` + TODOS row |
