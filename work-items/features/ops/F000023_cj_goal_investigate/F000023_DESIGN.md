---
type: design
parent: F000023
title: "/CJ_goal_investigate — defect-aware bugfix pipeline orchestrator — Feature Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The workbench has two one-keystroke pipeline skills today: `/CJ_goal_run` (user-story / feature lifecycle: autoplan → scaffold → impl → qa → ship → deploy) and `/CJ_goal_todo_fix` (TODOs.md row → drain → ship → deploy). Bugs have no equivalent one-keystroke path. When a bug is filed as a defect work-item (`work-items/defects/<domain>/D000NNN_*/`), the current flow is operator-driven: run `/investigate` manually, hand-write the RCA, run `/CJ_implement-from-spec` against the defect dir, run `/ship` + `/land-and-deploy` separately.

Friction shows up at steps 1–2 (no orchestrator chaining `/investigate` into the defect's RCA artifact) and at the seam from RCA to ship. `/CJ_goal_investigate` closes that gap with a defect-aware bugfix pipeline sibling to `/CJ_goal_run` and `/CJ_goal_todo_fix`, preserving the workbench's family-pattern contract.

## Shape of the solution

v1.0 ships a single-defect path: orchestrator resolves a defect work-item by D-ID or fuzzy fragment, dispatches `/investigate` with an explicit prompt instructing it to emit a sentinel-wrapped JSON DEBUG REPORT (`DEBUG_REPORT_BEGIN_JSON ... DEBUG_REPORT_END_JSON`), post-processes the JSON into RCA + test-plan artifacts, runs `/CJ_qa-work-item`, then `/ship` + `/land-and-deploy`. Halt-on-red default with a 9-row end-state taxonomy. Idempotent re-entry via a 5-row resume state table.

v1.1 adds drain mode (no args), `--max-drain N`, `--quiet`, family-drain lock, sunset criterion at the 6th invocation, and freestanding defect dir convention support. v2.0 (speculative) adds ad-hoc bugs without a scaffolded defect dir and a hot-fix path with compressed gate semantics.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| v1.0 single-defect mode (skill + pipeline + chain) | S000049 | [S000049_phase1_single_defect_mode/S000049_TRACKER.md](S000049_phase1_single_defect_mode/S000049_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Scope-split: v1.0 single-defect ONLY; drain/quiet/lock/sunset deferred to v1.1 | Both reviewers (Claude + codex) independently flagged v0 as over-scoped. No end-state taxonomy data yet; ceremony, not leverage. |
| 2 | Machine-readable handoff: `/investigate` emits sentinel-wrapped JSON via dispatch-prompt convention | Free-text DEBUG REPORT parser is brittle (reviewer-flagged critical). Convention not upstream feature: works against current `/investigate`, no gstack change required. |
| 3 | `/CJ_implement-from-spec` NOT in chain | `/investigate` Phase 4 writes the fix directly; RCA + test-plan are post-investigate audit artifacts, not inputs to a separate impl step. |
| 4 | `[investigate-unverified]` is an Iron-Law-equivalent halt | `DONE_WITH_CONCERNS` previously slipped past the Iron-Law gate; now a distinct halt that does NOT auto-advance to `/ship`. |
| 5 | Legacy defect dir convention only in v1 (`work-items/defects/<domain>/D000NNN_<slug>/`) | All D000001–D000018 use this layout. Freestanding `D<NNN>_bug-report.md` deferred to v1.1 with a single helper swap. |
| 6 | Approach B (defect-work-item-aware, scoped to single-defect) over Approach A (lightweight standalone) or Approach C (extend `/CJ_goal_run` Branch(d)) | A duplicates plumbing with no audit trail; C bloats `/CJ_goal_run`'s state machine. Family-pattern parity argues for a sibling skill. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `/investigate` may not honor the sentinel-wrapped JSON instruction in 100% of cases | Phase 1 of impl: dispatch /investigate against a low-stakes scratch bug, confirm sentinel block returned. Fallback: regex-parse free-text DEBUG REPORT (brittleness accepted; v1.0.1 fix with upstream feature request). |
| Blast-radius detection BEFORE fix is written | Recommend (c) in v1.0: ask /investigate to emit `FIX_PLAN_BEGIN_JSON ... FIX_PLAN_END_JSON` BEFORE Phase 4 starts; orchestrator halts on >5-file blast radius pre-fix. Resolves in S000049 SPEC. |
| Concurrent runs on the same defect (lock not present in v1) | Documented as accepted risk in v1 (parallel to /CJ_goal_run v1). Family-drain lock is a v1.1 design problem. |
| Telemetry baseline missing | Sunset criterion deferred to v1.1; v1 runs accumulate telemetry that v1.1 inspects. |

## Definition of done

- [ ] `/CJ_goal_investigate D000NNN` against a scaffolded defect produces a shipped + deployed PR with a populated RCA matching the template, with no operator intervention except `/ship` Gate #2.
- [ ] `/CJ_goal_investigate --dry-run D000NNN` prints the chain plan + idempotency state + expected RCA / test-plan writes WITHOUT modifying any file.
- [ ] Re-running `/CJ_goal_investigate D000NNN` after green is a one-line summary, no /investigate dispatch.
- [ ] Re-running after `/ship` declined resumes at `/ship`.
- [ ] `[investigate-unverified]` halts pre-ship and writes a transcript path the operator can `cat` to investigate.
- [ ] Tracker journal of every dispatched defect contains exactly one `[investigate-*]` line (terminal end-state).
- [ ] CHANGELOG / README / skill-routing rules updated.
- [ ] The `/investigate` subagent's sentinel-wrapped JSON output validates against the orchestrator's parser on a real defect (Phase 7 dogfood).

## Not in scope

- Drain mode (`/CJ_goal_investigate` no args; scan defects) — deferred to v1.1; requires telemetry baseline + family-drain lock design.
- `--max-drain N`, `--quiet` flags — v1.1, drain-mode prerequisites.
- Family-drain lock (cross-skill mutex) — v1.1 design problem; needs fresh thought once drain mode lands.
- Sunset criterion at 6th invocation — v1.1; no end-state taxonomy data at v1.
- Freestanding defect convention (`D<NNN>_bug-report.md`) — v1.1 via single helper swap.
- Ad-hoc bugs without a scaffolded defect dir (`--scaffold-defect <fragment>`) — v2.0 speculative.
- Hot-fix path with compressed gate semantics — v2.0 speculative.

## Pointers

- Parent tracker: [F000023_TRACKER.md](F000023_TRACKER.md)
- Roadmap: [F000023_ROADMAP.md](F000023_ROADMAP.md)
- /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-worktree-immutable-watching-sparrow-design-20260515-193008.md`
- Sibling skills: `/CJ_goal_run`, `/CJ_goal_todo_fix`
- Upstream gstack: `/investigate`, `/ship`, `/land-and-deploy`
