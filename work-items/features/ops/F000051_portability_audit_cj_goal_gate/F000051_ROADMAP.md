---
type: roadmap
parent: F000051
title: "Enforce /CJ_portability-audit in the cj_goal orchestrators — Roadmap"
date: 2026-06-06
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Make `/CJ_portability-audit` an enforced halt-on-red gate in all three cj_goal
orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) and
surface its verdict in the PR body. The work adds a single shared phase
`cj-goal-common.sh --phase portability-audit` (run under `PORTABILITY_STRICT=1`,
emitting a structured `PHASE_RESULT` + `VERDICT_LINE`), wires each orchestrator to
call it post-doc-sync / pre-`/ship` and halt on findings, and extends the existing
registered-doc-verdicts surfacing step to splice a `### Portability` line into the
PR. The engine itself is unchanged; `validate.sh` Check 18 stays advisory.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why. -->

- Flipping `validate.sh` Check 18 to strict-by-default — would block manual commits repo-wide; a separate, broader decision deferred to a follow-up PR.
- Editing the `cj-portability-audit.sh` engine — it already supports `PORTABILITY_STRICT` + emits `FINDINGS=`.
- Modifying `scripts/drain-one-todo.sh` — gate is orchestrator-layer; that script only locks + hands off.
- Refreshing the stale "advisory because we have debt" prose in `skills/CJ_portability-audit/SKILL.md` — a follow-up, not this feature.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside — not internal code state. -->

- [ ] `cj-goal-common.sh --phase portability-audit --mode feature` exits 0 + `PHASE_RESULT=ok` on the current clean catalog; non-zero + `PHASE_RESULT=findings` on a dishonest-declaration fixture; 0 + `PHASE_RESULT=skipped` when the engine is absent.
- [ ] A cj_goal run that introduces a dishonest portability declaration HALTS at the gate with `[portability-red]` BEFORE `/ship`, with a journal entry carrying `next_action` / `resume_cmd`.
- [ ] A clean cj_goal run passes the gate (green); the PR body shows a `### Portability` verdict line alongside the registered-doc verdicts.
- [ ] All 3 orchestrators wired; resume/idempotency preserved (gate is a pure read).
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` pass (incl. Check 15b + the new cj-goal-common test).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000091](S000091_portability_phase_and_pr_surfacing/S000091_TRACKER.md) | Shared portability-audit phase + 3-orchestrator gate + PR surfacing | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000091 (shared phase + 3-orchestrator wiring + tests + docs) | — | Not Started | chjiang | The single implementable unit for this feature | — |
| 2 | End-to-end pipeline run (the Assignment) | — | Not Started | chjiang | Run one real `/CJ_goal_feature` whose change touches a skill's declared portability; confirm the gate halts on a deliberately dishonest declaration — proving the ratchet on the live pipeline, not just the fixture | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- (none yet)

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000091 (shared phase + wiring + tests + docs) --> #2 E2E live-pipeline ratchet proof
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does `scripts/test.sh` enumerate cj-goal-common phases (needing a parallel entry for the new phase)? | Implement phase — grep test.sh and extend if so |
| Should `validate.sh` Check 18 flip to strict-by-default now that FINDINGS=0? | Separate follow-up PR (out of scope here) |
