---
type: design
parent: F000073
title: "Remove the portability-audit gate from the cj_goal orchestrators — Feature Design"
version: 1
status: Draft
date: 2026-07-02
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. -->

## Problem

All four `CJ_goal_*` orchestrators (feature, task, defect, todo_fix) run a pre-ship
"portability gate" via `cj-goal-common.sh --phase portability-audit` (F000051 /
S000091). It runs `scripts/cj-portability-audit.sh` STRICT and HALTs the run
(`[portability-red]` / `halted_at_portability`) if a touched skill declares a
`portability` tier it does not honor. Portability is a **workbench-only** concern:
it audits `skills-catalog.json` declarations, which only exist in this repo.
Consumer repos that installed these skills have no portability engine and no
catalog to audit. The operator wants the portability check OUT of the cj_goal
build path and left as a SEPARATE test only.

The portable cj_goal orchestrators should stop carrying a workbench-specific gate.
The build pipeline loses a whole halt class and a redundant phase; portability
stays enforced by the one place that owns it (the strict global ratchet, Check 18)
plus the standalone `/CJ_portability-audit` skill.

## Shape of the solution

Approach A (Full extraction): delete the entire `--phase portability-audit`
mechanism from `cj-goal-common.sh`, remove the gate + halt class from all four
orchestrators, drop the gate-specific tests + contract rows, regenerate the
workflow docs, and update `CLAUDE.md`. The orchestrators end up with zero
portability logic and no dead code. This is a single atomic multi-file change —
all edits must land together so the pre-commit `validate.sh` + CI `test.sh` stay
green. The whole scope is one cohesive removal, so it decomposes into a single
user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Full extraction of the portability gate from the cj_goal build path (script + 4 orchestrators + test-spec + workflow-spec + tests + CLAUDE.md), keeping the standalone test intact | S000123 | [S000123_remove_portability_gate/S000123_TRACKER.md](S000123_remove_portability_gate/S000123_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (Full extraction) — delete the `--phase portability-audit` mechanism entirely | Approach B (Minimal unwire) leaves dead code + workbench-specific logic in `cj-goal-common.sh` and only half-honors "not inside that skill." Approach C (Soft-remove / advisory) still RUNS inside the orchestrators and adds behavior instead of removing it. A is the only option that leaves the orchestrators with zero portability logic. |
| 2 | Keep the standalone portability test intact — `validate.sh` Check 18 (strict global ratchet, T000054) + `/CJ_portability-audit` skill + `scripts/cj-portability-audit.sh` engine | Check 18 is strict-by-default globally: a portability finding hard-fails every commit + CI + manual `validate.sh`. A cj_goal build commits ≥ twice (pre-doc-sync + `/ship`), each firing the pre-commit hook → Check 18. So removing the dedicated gate creates NO portability hole — the guarantee is preserved by the one place that owns it. |
| 3 | Single-story decomposition (one atomic change), not multi-story | The file inventory must land together to keep the pre-commit + CI gates green; splitting it would produce intermediate red states. There is one cohesive concern (remove the gate), so one user-story carries it. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Self-modifying pipeline: this build edits the very orchestrator (`cj-goal-common.sh` + `CJ_goal_feature/pipeline.md`) that is executing it. Once implement removes the portability phase, the orchestrator's own later `--phase portability-audit` call no longer exists. | The run recognizes the gate is removed by this change (its explicit intent) and proceeds straight to `/ship`. No skill's `portability` tier is relabeled, so nothing would have failed the gate anyway. Resolved by QA success criterion 5 (dry-run shows no portability node). |
| Missing a wiring site (a stray `[portability-red]` / `halted_at_portability` / PR-body `### Portability` reference left behind) leaves dead references that fail Check 24 marker cross-check or the grep success criterion. | QA success criterion 1 (grep returns nothing) + criterion 2 (`validate.sh` passes, incl. Check 24). |
| `scripts/test.sh` `task`-enum probe currently reuses `--phase portability-audit --mode task --dry-run` as a mode-agnostic phase; deleting that phase would break the probe. | REPOINT the probe to a surviving mode-agnostic phase (`--phase recap --mode task` or `--phase sync --mode task --dry-run`) so enum coverage is preserved. QA criterion 3. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `grep -rn "phase portability-audit\|portability-red\|halted_at_portability"` over `scripts/cj-goal-common.sh` + the four `skills/CJ_goal_*/` dirs returns nothing.
- [ ] `./scripts/validate.sh` passes (Check 18 still strict; Check 24 marker cross-check consistent; Check 27 workflow docs fresh).
- [ ] `./scripts/test.sh` passes (no reference to the deleted test/integration block; the `task`-enum probe repointed and green).
- [ ] `/CJ_portability-audit` + `validate.sh` Check 18 still function unchanged (the separate test survives).
- [ ] A dry-run of a cj_goal orchestrator no longer lists a portability gate node.

## Not in scope

<!-- Explicit non-goals. -->

- `scripts/cj-portability-audit.sh` (the engine) — untouched; it is the separate test.
- `scripts/validate.sh` Check 18 (the strict global ratchet) — untouched; it is the separate test.
- `skills/CJ_portability-audit/` (SKILL.md + USAGE.md — the standalone skill) — untouched; it is the separate test.
- `spec/test-spec-custom.md` Check 18 unit rows + the engine unit row — KEPT; they back the separate test.
- The F000047/S000083 portability ENGINE fixture block in `test.sh` — KEPT; it tests the engine, not the gate.
- No skill's declared `portability` tier is relabeled — this feature removes the gate, not any portability declaration.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000073_TRACKER.md](F000073_TRACKER.md)
- Roadmap: [F000073_ROADMAP.md](F000073_ROADMAP.md)
- Source /office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-inspiring-torvalds-0e7e5d-design-20260701-235812.md`
- Origin of the gate being removed: F000051 / S000091 (pre-ship portability gate).
- Preserved separate test: `validate.sh` Check 18 (T000054 strict-by-default) + `/CJ_portability-audit`.
