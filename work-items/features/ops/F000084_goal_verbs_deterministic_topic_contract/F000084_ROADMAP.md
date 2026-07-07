---
type: roadmap
parent: F000084
title: "Backfill the three-layer topic contract for the three cj_goal verbs (deterministic-only enrollment) — Roadmap"
date: 2026-07-06
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Give the three primary cj_goal verbs — `/CJ_goal_feature`, `/CJ_goal_task`,
`/CJ_goal_defect` — hard, layered, can't-rot verification as three SEPARATE
enrolled test topics (`goal-feature` / `goal-task` / `goal-defect`), each held to
CI-push + CI-nightly + local-hook deterministic coverage with full Check-31 doc
legibility (dream doc + topic subdir + front-door docs). Because the operator
plans to remove the agentic tests later, the contract engine itself gains a
**deterministic-only enrollment flavor** (`topic_contracts_deterministic:` — three
required points, agentic tolerated but never required), with union iteration in
both engine runners so the new list activates Checks 30/31 non-vacuously. The
CI-nightly layer is real new coverage: per-verb chain drills driving each verb's
deterministic helper chain end to end in a throwaway sandbox, registered under
the `TEST_FAST=1` guard so the per-PR gate never runs them.

## Non-Goals

- Any NEW agentic test/row — defect's on-disk eval case stays undeclared; the two existing eval rows are re-topic'd only, required by nothing.
- The agentic-test removal itself — a future TODOS row; this feature clears Check 30 only (Check 28/24 + portability's both-modes enrollment remain enumerated blockers).
- Enrolling `/CJ_goal_todo_fix` or other labeled topics — follow-up TODOS row, same deterministic-only pattern.
- Testing the agent-executed `pipeline.md` prose — deterministic drills reach helper scripts only (accepted helpers-only ceiling).
- Touching `portability`'s enrollment or the `topic_contracts:` four-point rule — unchanged.
- CI workflow-file changes — `nightly.yml` already runs the full `test.sh`.

## Success Criteria

- [ ] `bash scripts/test-spec.sh --check-topic-contract` reports the three required points present for `goal-feature` / `goal-task` / `goal-defect` (det-only arm) and `portability` unchanged (four-point arm); `validate.sh` Checks 30 + 31 green.
- [ ] Deleting an agentic eval row in a scratch copy does NOT red `--check-topic-contract` for the three new topics (negative-drill arm 2).
- [ ] `bash scripts/test-spec.sh --check-structure` green (folders + docs + INDEX + front-door sections for every new row).
- [ ] The 4 new test scripts pass locally; `TEST_FAST=1 bash scripts/test.sh` SKIPs the 3 chain drills; a full `test.sh` runs them.
- [ ] Seed-identity test green (spec prose ↔ `_emit_seed` byte-identical).
- [ ] `validate.sh` fully green (incl. Check 24 with the new units rows).
- [ ] The `cj-goal-eval` topic label no longer appears in the registry.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000133](S000133_det_only_enrollment_goal_verb_topics/S000133_TRACKER.md) | Deterministic-only enrollment seam + per-verb goal topics (chain drills + docs + enrollment) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Contract-engine seam: `topic_contracts_deterministic:` parser + cross-list guard + det-only Check-30 arm + union iteration in `_run_topic_contract`/`_run_topic_docs` + seed dual-write + 3-arm negative drill | — | Not Started | chang | Unblocks enrollment; grep/summary contracts preserved | — |
| 2 | 4 new test scripts (defect smoke first, then 3 chain drills) + `scripts/test.sh` registration (chains under `TEST_FAST=1`) | — | Not Started | chang | Chain steps per design Part 3; assertion granularity settled at SPEC/TEST-SPEC | #1 |
| 3 | 11 `categories:` rows (9 new + 2 re-topic'd) + `units:` rows + 9 front-door docs | — | Not Started | chang | `cj-goal-eval` label retired; `--check-structure` green | #2 |
| 4 | 3 dream docs + 3 topic subdirs; declare all new docs in `spec/doc-spec-custom.md` | — | Not Started | chang | Check-31 surfaces; human-docs, no work-item IDs | #3 |
| 5 | Prose sweeps (TEST_FAST guard/overlay/test-deploy purpose; `topic_contracts:` header; Check 30/31 self-describing surfaces) + CLAUDE.md line | — | Not Started | chang | Keeps Stage-2 audit truthfulness | #3 |
| 6 | Enroll `topic_contracts_deterministic: [goal-feature, goal-task, goal-defect]`; regenerate catalogs; run engines + validate | — | Not Started | chang | Enrollment is LAST; README regen if counts change | #4, #5 |
| 7 | TODOS hygiene (PARTIAL mark + todo_fix follow-up + agentic-removal blockers row) + ship S000133 end-to-end | — | Not Started | chang | End-to-end pipeline run | #6 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-07-06: Feature scaffolded (F000084 + child S000133) from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. Arrow = "blocks". Keep in sync
     with the Blocked By column. -->

```
#1 engine seam (det-only key + union iteration + seed dual-write + 3-arm drill)
   --> #2 4 new test scripts + TEST_FAST-gated registration
          --> #3 11 categories rows + units rows + 9 front-door docs
                 --> #4 dream docs + topic subdirs + doc-spec declarations --+
                 --> #5 prose sweeps + CLAUDE.md line -----------------------+--> #6 enrollment LAST + regen + validate
                                                                                    --> #7 TODOS hygiene + ship
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Exact assertion granularity inside each chain drill (chain step lists are the contract) | S000133 SPEC/TEST-SPEC + implementation |
| Do the 2 re-topic'd eval front-door docs need any prose edit (docs may never name the retired `cj-goal-eval` label)? | Verify at build time (milestone #3) |
| Does the later agentic-removal also retire `scripts/eval.sh` / `e2e-local.sh` harness code (affects the two local-det fills)? | Out of scope; documented fallback = re-declare the verb's chain drill at `local-hook`; TODOS removal row |
