---
type: roadmap
parent: F000082
title: "Three-layer test contract per topic — Roadmap"
date: 2026-07-04
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Make every test *topic* provably covered at all three verification layers
(CI-push, CI-nightly, local-hook), with the local layer carrying BOTH a
deterministic and an agentic test — enforced by a hard, declaration-only Check in
the two `cj_test_` skills. Delivers a first-class `topic:` axis on `categories:`
rows, a per-topic `topic_contracts:` enrollment seam, the `--check-topic-contract`
engine + `validate.sh` Check, a reusable repo-neutral agentic-sandbox lib, and
portability enrolled with its agentic proof (`portability-version-agentic`) built
so it is green from birth. Every other topic is labeled + grandfathered.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why. -->

- Fixing the real release-tag inertness (upstream `v1.1.0` vs VERSION 6.0.116) — a separate defect; the agentic test is the CATCH mechanism, not the fix.
- Migrating the 11 non-portability topics into the contract — labeled + grandfathered with follow-up TODOs.
- Running any agentic test in CI — agentic is local-only by house rule (F000080); the hard Check proves declaration only, so CI stays fast + model-spend-free.
- Refactoring `e2e-local`'s `sandbox.sh` / migrating `eval.sh --portability` onto the new lib — noted fast-follows.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] `test-spec.sh --list-categories` shows a `topic` for all 12 rows; `--validate` passes with the 9th column (AC1).
- [ ] `topic_contracts: [portability]` parses and portability reads as enrolled (AC2).
- [ ] `test-spec.sh --check-topic-contract` HARD-fails on a planted missing-agentic-row fault and PASSES once restored; the `scripts/test.sh` negative test proves it via the targeted engine only (AC3).
- [ ] `validate.sh` is green on this repo with the new hard Check and spends zero model tokens in CI (AC4).
- [ ] `scripts/lib/agentic-sandbox.sh` exists and its deterministic helpers pass a no-model smoke (AC5).
- [ ] `tests/portability-version-agentic.test.sh` SKIPs clean in `test.sh`/CI, and locally produces a `{surfaced_nudge, evidence}` PASS (AC6).
- [ ] `/CJ_test_run portability-version-agentic --e2e` runs it; default `free` SKIPs it; `/CJ_test_audit` Stage 1 reports it wired (AC7).
- [ ] Docs green: front-door three-section doc + `docs/tests/index.md` + `spec/doc-spec-custom.md`; Checks 24/26/27/28 + `doc-spec --check-on-disk` pass (AC8).
- [ ] CLAUDE.md + `spec/test-spec.md`/`--seed` + overlay prose updated; grandfather TODOs filed (AC9).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000132](S000132_topic_contract_portability_proof/S000132_TRACKER.md) | Topic contract + portability agentic proof (AC1–AC9) | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Schema + parser: `topic:` (9th col) + `topic_contracts:` across the six consumer sites; backfill 12 rows | — | Not Started | chang | AC1, AC2 | — |
| 2 | Lib: `scripts/lib/agentic-sandbox.sh` (3 helpers) + deterministic-helper smoke | — | Not Started | chang | AC5 | #1 |
| 3 | Proof: `tests/portability-version-agentic.test.sh` + new `categories:` row + front-door doc + index + doc-spec | — | Not Started | chang | AC6, AC8 | #2 |
| 4 | Enroll `topic_contracts: [portability]` + wire `--check-topic-contract` into `validate.sh` + the targeted negative test (LAST — atomic) | — | Not Started | chang | AC3, AC4 | #3 |
| 5 | Wiring: `/CJ_test_run --topic` selector; confirm `/CJ_test_audit` surfaces the check | — | Not Started | chang | AC7 | #4 |
| 6 | Docs: general seed + overlay + CLAUDE.md; file grandfather follow-up TODOs | — | Not Started | chang | AC9 | #4 |
| 7 | Ship S000132 | — | Not Started | chang | user-story complete | #5, #6 |
| 8 | End-to-end pipeline run (QA + doc-sync + /ship → PR) | — | Not Started | chang | feature PR opens | #7 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-07-04: Scaffolded from /office-hours design (F000082). No code shipped yet.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N -> #M (arrow = "blocks"). -->

```
#1 schema + parser (topic:/topic_contracts:) --> #2 agentic-sandbox lib --> #3 portability agentic proof + doc
                                                                                   |
                                                                                   v
                                                        #4 enroll + wire hard Check + negative test (LAST/atomic)
                                                                                   |
                                                        +--------------------------+--------------------------+
                                                        v                                                     v
                                             #5 /CJ_test_run --topic wiring                          #6 docs + grandfather TODOs
                                                        \                                                     /
                                                         +----------------------> #7 ship S000132 <---------+
                                                                                          |
                                                                                          v
                                                                          #8 end-to-end pipeline run --> feature PR
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Is `goal-task-eval` + `goal-feature-eval` one topic or two? (unenrolled labeling only) | Settle at implement time; affects only the grandfather TODO count, not the portability proof. |
| Should portability also get a live `git ls-remote` smoke (catches the real v1.1.0 inertness)? | Follow-up / separate defect, tracked with the release-tag fix. |
