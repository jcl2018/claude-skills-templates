---
name: "Four-Phase Workflow Pipeline"
type: user-story
id: "S000001_four_phase"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000001_workflow_alpha"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria defined
- [x] Working branch created
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Milestones created
- [x] Tasks broken down (if needed)

### Phase 2: Implement
- [x] Build-forward mode (from doc triplet + acceptance criteria)
- [x] Implementation committed
- [x] Acceptance criteria verified met

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Doc triplet alignment check (TEST-SPEC)

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] Branch-aware router detects feat/*, fix/*, task/*, story/* and resolves work items
- [x] Track phase: manifest-driven scaffolding for 4 types, evidence synthesis, journal/milestones/list/close/child-items
- [x] Implement phase: build-forward for features, debug-backward with 3-hypothesis testing for defects
- [x] Review phase: /contracts check as quality gate, then delegates to gstack /review
- [x] Ship phase: /ship + /land-and-deploy
- [x] Status menu shows phase progress when invoked without subcommand
- [x] Handoff blocks written after each phase transition

## Todos

- [x] [T000001_router_implementation](T000001_router_implementation/T000001_TRACKER.md) — SKILL.md router + 4 subcommand files

## Log

- 2026-04-11: Created. Four-phase workflow pipeline user story.

## PRs

## Files

- skills/workflow/SKILL.md
- skills/workflow/track.md
- skills/workflow/implement.md
- skills/workflow/review.md
- skills/workflow/ship.md

## Insights

- Consolidating 5 separate skills into one router with shared context was the key design win.

## Journal
