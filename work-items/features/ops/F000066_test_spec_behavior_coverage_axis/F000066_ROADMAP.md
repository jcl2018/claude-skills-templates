---
type: roadmap
parent: F000066
title: "test-spec behavior-coverage axis — Roadmap"
date: 2026-06-16
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — captures scope/non-goals (the feature's
     identity), decomposition (which user-stories carry the work), and delivery
     timeline (when each piece ships). -->

## Scope

Add an open-world **behavior-coverage axis** to the two-tier `test-spec`
verification contract. Today the contract is closed-world over existing tests —
it can flag an orphaned or mis-anchored test, but a behavior that *should* have a
test and doesn't is invisible. This feature lets a repo *declare* the behaviors
its software must prove (`behaviors:`, each with a first-class `level`) and link
each to a test-bearing mechanism with semantic evidence (`behavior_coverage:`), so
a missing covering test becomes a detectable gap. The schema rides the existing
two-tier seed+overlay distribution: prose + the `level` enum in the byte-identical
general seed, the behavior rows per-repo in the overlay. A new agent-judged
`/CJ_test_audit` Stage-2 sub-check verifies behavior *substance*.

## Non-Goals

- Per-`area` pyramid expectations + level-distribution reporting — Approach B (deferred fast-follow).
- Diff-aware enforcement (flag a behavior-adding change with no new behavior row) — Approach B (deferred).
- Executable-spec behaviors (given/when/then files that *are* the test) — Approach C (rejected; fights portability).
- A deterministic `source != unit.source` semantic-evidence guard — P5 (agent-judged) owns that judgment in v1.
- A `--reconcile`-style migration nudge for already-adopted repos — opt-in is enough for v1.

## Success Criteria

- [ ] `test-spec.sh --check-coverage` FAILS when a declared behavior has no covering row, the anchor doesn't grep live, or it points at a non-test-bearing unit.
- [ ] A behavior pointing at a real, green, semantically-matching test PASSES.
- [ ] A repo with no `behaviors:` reports "behavior coverage inactive" and stays green (consumer parity preserved).
- [ ] `spec/test-spec.md` stays byte-identical to `test-spec.sh --seed`.
- [ ] `/CJ_test_audit` Stage-2 flags a vague / over-claimed / mis-leveled behavior row.
- [ ] The ~8 dogfood behavior rows for test-spec itself are green; `scripts/validate.sh` and `scripts/test.sh` both green.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000110](S000110_behaviors_and_coverage_in_test_spec/S000110_TRACKER.md) | Behaviors + coverage in the test-spec contract | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000110 (parser + 6 checks + seed prose + validate.sh Check 24 + `/CJ_test_audit` Stage-2 + ~8 dogfood rows) | — | Not Started | chjiang | The whole v1 in one cohesive change | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh green; dogfood rows green on the live tree) | — | Not Started | chjiang | The DoD gate | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-16: Scaffolded F000066 from the /office-hours APPROVED design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000110 (behavior axis) --> #2 End-to-end pipeline run (validate + test green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Migration for already-adopted repos — `--reconcile` nudge or opt-in? | Lean: opt-in for v1; revisit if adoption stalls. |
| `area` taxonomy — free-text vs per-repo declared enum? | Lean: free-text, reporting-only; revisit when level-distribution reporting lands (Approach B). |
