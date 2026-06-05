---
type: roadmap
parent: F000048
title: "Scaffold-time atomic F-ID claim (close the pre-push collision race) — Roadmap"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Close the scaffold-before-push work-item-ID collision race for concurrent
same-machine cj_goal worktrees by adding a 4th ID source — an atomic
`mkdir`-CAS claim directory under the shared `.git` common-dir, made at scaffold
time before any commit/push/PR. Ships as a new `scripts/cj-id-claim.sh` helper
plus a fail-soft wiring into `CJ_scaffold-work-item` Step 5.1, unit-tested
(including a looped concurrent-race test) and registered in `scripts/test.sh`.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- Cross-machine pre-push pre-emption (two clones, neither pushed) — not regressed; stays covered post-push by Sources 2+3, just not pre-empted. Deferred.
- Aggressive liveness/PID reaping — unnecessary; ID gaps are harmless, so lazy TTL + on-origin reaping suffices.
- Proactive claim release in `/ship` / `post-land-sync.sh` — nice-to-have, deferred (next run's on-origin reap clears merged claims).
- VERSION-slot collision handling — already owned by `check-version-queue.sh`; this feature is the ID half only.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] Two concurrent `cj-id-claim.sh` invocations with the same floor return distinct IDs every round of a 20+ round loop.
- [ ] A claim whose ID is on origin/main, or older than the TTL, is reaped and not counted.
- [ ] Scaffold re-run on the same branch (pre-completion) keeps its ID (idempotent).
- [ ] Helper-absent fallback still mints an ID (scaffold never breaks).
- [ ] `tests/cj-id-claim.test.sh` registered in `scripts/test.sh` and observably executed; validate.sh + test.sh green.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000084](S000084_scaffold_time_atomic_id_claim/S000084_TRACKER.md) | Scaffold-time atomic ID claim — helper + Step 5.1 wiring + tests | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000084 (claim engine + Step 5.1 wiring + tests) | — | Not Started | chjiang | The whole feature is this one atomic story | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh green, race test looped) | — | Not Started | chjiang | Gate before /ship | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-06-04: Scaffolded from /office-hours design doc (Builder mode, APPROVED).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000084 (cj-id-claim.sh + Step 5.1 wiring + tests) --> #2 E2E pipeline run (validate + test green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| TTL value (72h proposed, tunable via `--ttl-hours`) | Confirm at QA |
| Proactive claim release in /ship or post-land-sync.sh | Deferred; revisit if stale claims accumulate |
