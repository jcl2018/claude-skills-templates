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

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Extract from design doc into doc triplet: requirements → `PRD.md`, architecture decisions → `ARCHITECTURE.md`, test scenarios → `TEST-SPEC.md`
   (use templates from `templates/doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`)
6. Create milestones from PRD acceptance criteria
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Milestones created
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Work from doc triplet + acceptance criteria (build-forward mode)
2. Commit changes incrementally with descriptive messages
3. Update Todos section — remove completed items, add new discoveries
4. Update Files section with all changed file paths

**Gates:**
- [x] Implementation committed (>=1 commit SHA in Log)
- [x] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` — verify hierarchy and structural completeness
3. Run tests: `./scripts/test.sh`
4. Review TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
5. Run `/review` for code review (if PR exists)

❌ If `/docs check` finds issues: fix findings, re-run until clean

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] `/docs tree` — structure verified
- [ ] Test verification passed
- [ ] Doc triplet alignment verified (TEST-SPEC covers P0 stories)

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
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
