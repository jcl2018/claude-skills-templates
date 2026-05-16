---
type: roadmap
parent: F000024
title: "/CJ_goal_investigate — defect-aware bugfix pipeline orchestrator — Roadmap"
date: 2026-05-15
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

`/CJ_goal_investigate` ships a defect-aware bugfix pipeline orchestrator — a sibling to `/CJ_goal_run` (user-story / feature lifecycle) and `/CJ_goal_todo_fix` (TODOs.md drain) that closes the gap from defect work-item to deployed fix. v1.0 covers the single-defect path end-to-end: resolve defect by D-ID or fragment, dispatch `/investigate` with machine-readable JSON handoff, post-process RCA + test-plan, chain to `/CJ_qa-work-item` → `/ship` → `/land-and-deploy`. Halt-on-red default, idempotent re-entry, autonomy ceiling preserved (`/ship` Gate #2 fires per defect).

## Non-Goals

- Drain mode and `--quiet` flag — v1.1 prerequisite work; v1 requires explicit D-ID or fragment input.
- Family-drain cross-skill lock — v1.1 design problem; fresh thought when drain mode lands.
- Sunset criterion at 6th invocation — v1.1; no end-state taxonomy data at v1.
- Freestanding defect dir convention (`D<NNN>_bug-report.md`) — v1.1 via single helper swap.
- Ad-hoc bugs without a scaffolded defect dir — v2.0 speculative.
- Upstream `/investigate` schema changes — convention-based handoff only in v1; gstack feature request deferred.

## Success Criteria

- [ ] `/CJ_goal_investigate D000NNN` against a scaffolded defect produces a shipped + deployed PR with a populated RCA matching the template, with no operator intervention except `/ship` Gate #2.
- [ ] `/CJ_goal_investigate --dry-run D000NNN` prints the chain plan + idempotency state + expected RCA / test-plan writes WITHOUT modifying any file.
- [ ] Re-running `/CJ_goal_investigate D000NNN` after green is a one-line summary, no /investigate dispatch.
- [ ] Re-running after `/ship` declined resumes at `/ship`.
- [ ] `[investigate-unverified]` halts pre-ship and writes a transcript path the operator can `cat` to investigate.
- [ ] Tracker journal of every dispatched defect contains exactly one `[investigate-*]` line (terminal end-state).
- [ ] CHANGELOG / README / skill-routing rules updated.
- [ ] The `/investigate` subagent's sentinel-wrapped JSON output validates against the orchestrator's parser on a real defect (Phase 7 dogfood).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000049](S000049_phase1_single_defect_mode/S000049_TRACKER.md) | Phase1: v1.0 single-defect mode — skill scaffold, /investigate dispatch with sentinel-wrapped JSON, RCA + test-plan artifact writes, halt taxonomy, idempotency, /CJ_qa-work-item + /ship + /land-and-deploy chain, dogfood validation | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000049 — v1.0 single-defect mode | 2026-05-15 | Not Started | chjiang | Skill scaffold + /investigate dispatch + JSON parser + artifact writes + halt taxonomy + chain + dogfood | — |
| 2 | End-to-end pipeline run — dogfood against existing defect (e.g. D000019) | 2026-05-15 | Not Started | chjiang | Phase 7 of S000049; surfaces v1.0.1 follow-ups | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- {YYYY-MM-DD}: {PR# or version} — {brief description}

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000049 v1.0 single-defect mode --> #2 End-to-end dogfood run against real defect
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Does `/investigate` honor the sentinel-wrapped JSON instruction reliably? | Phase 1 of S000049 impl: dispatch against scratch bug; fall back to free-text-regex parser if not. |
| Should the FIX_PLAN preamble (blast-radius detection) be a separate halt or fold into the existing halt taxonomy? | Resolved in S000049 SPEC: separate halt `[investigate-blast-radius]` per design doc's Halt-on-Red taxonomy. |
