---
type: roadmap
parent: F000053
title: "cj_goal harness-principle hardening — Roadmap"
date: 2026-06-06
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

This feature closes the three remaining agent-harness gaps in the `cj_goal`
orchestrator framework (CJ_goal_feature / CJ_goal_defect / CJ_goal_todo_fix) so a
resumed run is as trustworthy as a fresh one — replay-safe, review-safe, and
permission-legible. It hardens the affordable P4/P5/P1 tail (verification cannot
lie about correctness; one declared allow/ask/deny permission contract; within-phase
context curation after the long inline office-hours phase) while leaving the already-strong
P2 (externalized state) and P3 (stateless handoff) habits untouched. Three
independently shippable child user-stories deliver the work, built correctness-first.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- **S4 (cross-branch state index + per-phase telemetry + crash checkpointing)** — refinements, not gaps; deferred to TODOS.md rows, built only after S000093/S000094/S000095 land (else it risks formalizing the wrong execution model).
- **P2 / P3 changes** — already strong; deliberately out of scope.
- **A generic "compact everything" within-phase framework** — S000095 is scoped to the known long inline phases (office-hours) only.
- **Downstream-consumer / cross-repo scope** — workbench-only (this repo, macOS + Git-Bash).
- **A live re-activation of `cj-handoff-gate.sh`** — S000094 only makes its dormant denylist DERIVE from the policy (forward-looking correctness, not a live-enforcement claim).

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] A resumed user-story/feature run re-verifies (re-validates the receipt; re-runs E2E on a missing/stale receipt) rather than trusting a date-keyed marker or a phase-skip; an artifacts-only or stale-state work-item cannot read green (S000093 ACs).
- [ ] One declared allow/ask/deny policy exists; the live enforcement points reference it and an advisory check flags drift; risky verbs (git push to main, gh pr merge, rm, network) are explicit deny/ask (S000094 ACs).
- [ ] The office-hours inline phase writes a receipt the orchestrator continues from rather than the raw transcript (S000095 ACs).
- [ ] Each story lands as its own PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review. No regression to P2 / P3.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000093](S000093-trajectory_qa/S000093_TRACKER.md) | Trajectory QA: QA that cannot lie about correctness (P4) | Open |
| [S000094](S000094-permission_policy/S000094_TRACKER.md) | Permission policy: one declared allow/ask/deny contract (P5) | Open |
| [S000095](S000095-within_phase_receipts/S000095_TRACKER.md) | Within-phase receipts: continue from receipts, not transcript (P1) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000093 (Trajectory QA, P4) | — | Not Started | chjiang | Build first (correctness-first). Closes both GAP A skip paths; QA emits an execution receipt + fails closed. Sets the shared receipt schema. | — |
| 2 | Ship S000094 (Permission policy, P5) | — | Not Started | chjiang | Build second. One declared allow/ask/deny artifact + parser; advisory `validate.sh` drift check (+ parallel `test.sh` fixture). "The tell." | — |
| 3 | Ship S000095 (Within-phase receipts, P1) | — | Not Started | chjiang | Build third. Office-hours boundary writes a receipt; orchestrator continues from `$RECEIPT_PATH`. Reuses S000093's receipt schema. | — |
| 4 | End-to-end: all three landed, resumed runs trustworthy | — | Not Started | chjiang | Each story PR-stopped + green on validate/test/windows; no P2/P3 regression. A resumed cj_goal run is as trustworthy as a fresh one. | 1, 2, 3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-06-06: Feature scaffolded — TRACKER + DESIGN + ROADMAP + three child user-stories (S000093, S000094, S000095).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
The three stories are INDEPENDENT (value/risk build order, not a hard chain).
Each can land alone; the order below is correctness-first sequencing.

F000053 (cj_goal harness-principle hardening)
   |
   +--> S000093  Trajectory QA (P4)            [ship #1 — correctness-first]
   |
   +--> S000094  Permission policy (P5)        [ship #2 — "the tell"]
   |
   +--> S000095  Within-phase receipts (P1)    [ship #3 — reuses S000093 schema]
   |
   +--> #4 End-to-end: all three landed, resumed runs trustworthy
              ^ blocked by S000093 + S000094 + S000095
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| S000093/S000095 receipt home — generalize `.cj-goal-feature/${branch}.state` into the receipt chain (one surface), or add a sibling per-phase receipt file? Leaning generalize-in-place. | Resolved by whichever of S000093/S000095 ships first; it sets the one shared receipt schema. |
| Advisory→strict ratchet timing for S000094's `validate.sh` drift check. | Land advisory first (portability Check 18 precedent); a follow-up PR flips it strict once the policy is reconciled. |
