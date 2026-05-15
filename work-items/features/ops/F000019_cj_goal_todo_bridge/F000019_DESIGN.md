---
type: design
parent: F000019
title: "/CJ_goal — auto-resolve TODOs that other tasks drop into TODOS.md — Feature Design"
version: 1
status: Draft
date: 2026-05-14
author: chjiang
reviewers: []
---

<!-- Distilled from /office-hours design doc chjiang-main-design-20260514-162927.md.
     For the full multi-iteration design (4 autoplan rounds, Themes A/B/C resolution),
     see ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-162927.md
     (canonical) or .gstack/chjiang-main-design-20260514-162927.md (symlink). -->

## Problem

TODOS.md is the catch-basin for "found during X" notes other skills emit
(post-ship audits, autoplan taste-decisions, codex carry-overs, /document-release
follow-ups). The active set skews small-and-low-priority — 27/40 entries are
size S, 19/40 are P3,S. Each currently demands either `/office-hours` →
`/CJ_run` (heavyweight overkill for a five-line fix) or hand-scaffolded T-task
work-item + `/CJ_run --work-item-dir` (tedious enough that the user routes
around it). Result: TODOs pile up, drift stale, get skipped when the user
picks the next ambitious feature. The skill that *consumes* TODOs is missing.

## Shape of the solution

`/CJ_goal` is the missing bridge from a TODOS.md row to the existing
implement-QA-ship-deploy chain. One keystroke turns "fix this TODO" into a
green PR by composing already-shipped pieces: /CJ_suggest ranks, /CJ_goal
scaffolds a T-task tracker, /CJ_personal-pipeline runs impl + QA via the
task-type dispatch (S000021/F000012/v1.11.0), /ship gates the diff,
/land-and-deploy runs quietly with the v3.4.0 `--suppress-readiness-gate` flag.

Net new code is the bridge logic + the direct dispatch chain. Everything else
is reuse.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Skill skeleton + dispatch + scaffold + chain + eval | S000041 | S000041_skill_skeleton/S000041_TRACKER.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A — new top-level skill | Most reversible; composes cleanly with `/loop`; separation of concerns vs extending /CJ_run's already-complex dispatch tree. |
| 2 | Bypass /CJ_run for hand-off | /CJ_run Branch(f) explicitly rejects `type: task` (run.md:214); /CJ_goal chains the sub-skills directly per /CJ_run's own error-message guidance. |
| 3 | Refuse `P1` OR size `L/XL` at preflight | Size is the load-bearing risk control, priority is the secondary cap. P2/P3 at size S/M proceed. Matches user's `[[feedback_skip_design_for_small_todos]]`. |
| 4 | Per-session skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` | Autoplan v4 caught the gap — without skip-list, `/loop /CJ_goal` would re-hit the same skipped lead row infinitely. Skip-list per-session; new /loop invocation retries previously-skipped TODOs. |
| 5 | Telemetry to `~/.gstack/analytics/CJ_goal.jsonl` | Mirrors /CJ_personal-pipeline's shape. Enables v1.1 sunset trip-wire calibration once 8+ invocations exist. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| ID picker drift between /CJ_scaffold-work-item and /CJ_goal (verbatim copy-paste in v1) | v1.1 — extract to `scripts/cj-id-picker.sh` as single source of truth |
| Domain inference silent-defaults to `ops` when no regex matches | v1.1 — add AUQ for top-2 candidates if telemetry shows mis-routing |
| Sunset trip-wire is gold-plate for v1 | v1.1 — calibrate threshold after 8+ real invocations |
| `feat/{slug}` vs `task/{slug}` branch convention inconsistency (predates this design) | Follow-up: align tracker-task.md template with /CJ_scaffold-work-item Step 3 regex |

## Definition of done

- [ ] `skills/CJ_goal/SKILL.md` deployed (thin wrapper to scripts/goal.sh)
- [ ] `skills/CJ_goal/scripts/goal.sh` with `#!/usr/bin/env bash` shebang
- [ ] Catalog entry in `skills-catalog.json` with `status: experimental`
- [ ] Routing rule added to `rules/skill-routing.md`
- [ ] CLAUDE.md routing block updated
- [ ] Eval case `tests/eval/CJ_goal/preflight-halts/` with preflight-halt fixtures
- [ ] `/CJ_personal-workflow check` clean on F000019 tree
- [ ] `scripts/validate.sh` clean

## Not in scope

- Green-path eval — running the full chain (~3-5 min, ~$0.10-$0.30 LLM cost) would blow `scripts/eval.sh`'s per-case $0.50 budget. v1 ships preflight-halt eval only. Same precedent /CJ_personal-pipeline set.
- Generalizing TODO source beyond `claude-skills-templates/TODOS.md` — v1 is workbench-only per `[[feedback_workbench_scope]]`.
- `--force-design-skip` flag — refused per design's Constraints item 6.
- Theme D emission-side reframe — deferred to its own design cycle once /CJ_goal v1 telemetry signals whether consumption-side approach is sufficient.

## Pointers

- Parent tracker: [F000019_TRACKER.md](F000019_TRACKER.md)
- Roadmap: [F000019_ROADMAP.md](F000019_ROADMAP.md)
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-162927.md`
- Child user-story: [S000041_skill_skeleton/S000041_TRACKER.md](S000041_skill_skeleton/S000041_TRACKER.md)
