---
type: roadmap
parent: F000019
title: "/CJ_goal — auto-resolve TODOs — Roadmap"
date: 2026-05-14
author: chjiang
status: Draft
---

## Scope

`/CJ_goal` is a single-keystroke bridge from a TODOS.md row to the
implement-QA-ship-deploy chain. It composes /CJ_suggest's ranking,
/CJ_personal-pipeline's task-type dispatch, /ship, and /land-and-deploy
(with `--suppress-readiness-gate`) to auto-walk the green path for small
TODOs. P1 or L/XL TODOs halt at preflight; sensitive-surface AUQs default
to halt. Composes with `/loop` for continuous mode.

## Non-Goals

- Generalizing TODO sources outside `claude-skills-templates/TODOS.md` — workbench-only scope per `[[feedback_workbench_scope]]`.
- Green-path eval coverage — defers to /CJ_personal-pipeline precedent (per-case $0.50 eval budget).
- Bypassing safety nets — sensitive-surface scan, /autoplan halts, /ship Gate #2, /land-and-deploy red signals all preserved.
- `--force-design-skip` flag — explicitly refused per design Constraint 6.

## Success Criteria

- [ ] Green path: `/CJ_goal` on a P3,S TODO with clear body produces a green merged PR. User interaction limited to /autoplan AUQs (during /CJ_personal-pipeline) + /ship Gate #2.
- [ ] Pre-flight halts are clean: P1, size L/XL, sensitive surface (declined), design-needed keyword, body too vague, missing suffix → exit non-zero, no work-items/ pollution.
- [ ] Idempotency: re-running on a TODO with existing T-tracker dispatches the existing work-item; re-running on a shipped TODO is a no-op via strikethrough detection.
- [ ] `/loop /CJ_goal` continues only on `end_state ∈ {green, idempotent_skip, halted_at_preflight}` (the last is skip-and-continue per Theme B fix).
- [ ] TODOS.md stays source-of-truth: no drift between DONE marks and shipped PRs; hash-verify protects concurrent edits.
- [ ] Telemetry populated at `~/.gstack/analytics/CJ_goal.jsonl` with `end_state` per invocation.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000041](S000041_skill_skeleton/S000041_TRACKER.md) | Skill skeleton + scripts/goal.sh + catalog + routing + eval | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000041 implement + QA + ship | 2026-05-14 | In Progress | chjiang | Single-story feature; all build work here | — |

### Delivery History

- 2026-05-14: F000019 scaffolded from /CJ_personal-pipeline on design doc 20260514-162927.

## Dependency Graph

```
#1 S000041 implement + QA + ship → (ship)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| ID picker extraction to shared helper (`scripts/cj-id-picker.sh`) | v1.1 — refactor work-item once /CJ_goal proves out |
| Domain inference AUQ when ambiguous | v1.1 — driven by real-world mis-routing signal from telemetry |
| Sunset trip-wire threshold | v1.1 — calibrate after 8+ real invocations |
