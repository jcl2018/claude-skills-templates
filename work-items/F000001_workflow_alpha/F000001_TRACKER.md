---
name: "workflow-alpha"
type: feature
id: "F000001_workflow_alpha"
status: closed
created: "2026-04-11"
updated: "2026-04-13"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/{slug}`
3. Scaffold work item directory and TRACKER.md
4. Extract from design doc into doc triplet: requirements → `PRD.md`, architecture decisions → `ARCHITECTURE.md`, test scenarios → `TEST-SPEC.md`
   (use templates from `templates/doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`)
5. Decompose into child user-stories and/or tasks

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Broken down into child tasks/stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Files section with top-level changed files

**Gates:**
- [x] All child stories/tasks have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Review

1. Run `/docs check` — verify full hierarchy passes all badges
2. Run `/docs tree` — verify structural completeness (all children present)
3. Verify all child stories/tasks have passed their own Phase 3
4. Run `/review` for feature-level code review

**Gates:**
- [x] `/docs check` — all children pass validation
- [x] `/docs tree` — structure complete
- [x] All children have passed Phase 3: Review

### Phase 4: Ship

1. Ensure all child stories/tasks are shipped first
2. Run `/ship` — creates feature PR (if not already created by children)
3. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [x] All children shipped
- [x] `/ship` — PR created (#22, #24)
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] 4-phase lifecycle encoded in tracker templates (Track → Implement → Review → Ship)
- [x] Type-specific artifact sets via artifact-manifests.json
- [x] Solo-dev tracker templates (no multi-person ceremony)
- [x] Structural completeness validation in /docs check (Steps 15-17)
- [x] Tree report and graph artifact (/docs tree, work-item-graph.json)
- [x] Final E2E test: create a work item using the workflow itself (this test)

## Todos

### User Stories
- [x] [S000001_workflow_implementation](S000001_workflow_implementation/S000001_TRACKER.md) — Full workflow implementation (1 task) — CLOSED

### Remaining
- [x] Complete E2E test (creating this work item is the test)
- [x] Run `./scripts/test.sh` for full validation (PASS, 0 failures)
- [x] Run `/docs check` on the doc triplet

## Log

- 2026-04-11: Created. v1 documentation for workflow skill — the 4-phase router with track, implement, review, ship.
- 2026-04-11: Doc triplet populated. PRD covers 11 user stories, ARCHITECTURE maps the router + 4 subcommands, TEST-SPEC has 8 test cases + 5 smoke tests + 4 E2E scenarios.
- 2026-04-11: Template consolidation implemented -- new solo-dev gates, removed review type, removed scrum, structured IDs.
- 2026-04-13: Consolidated 3 user stories (S000001, S000002, S000003) into S000001_workflow_implementation. 4 tasks merged into T000001_implement_workflow.
- 2026-04-13: S000001 closed. All TODOs complete, doc triplet expanded, GENERATION-GUIDE cleanup done, tracker templates updated.
- 2026-04-13: F000001 closed. Consistency verified across 12 docs (structure, logic, cross-refs). Fixed: architecture diagram aligned with manifest (feature requires tracker only), milestones marked Done, test-plan updated from Draft to Done, stale HANDOFF removed.

## PRs

## Files

- templates/tracker-feature.md
- templates/tracker-defect.md
- templates/tracker-task.md
- templates/tracker-user-story.md
- skills/docs/check.md
- skills/docs/tree.md
- skills/docs/SKILL.md
- artifact-manifests.json
- skills-catalog.json

## Insights

- The /workflow router skill was built then removed in v0.2.2. Its track phase was replaced by CLAUDE.md rules; implement/review/ship were redundant with gstack skills.
- The 4-phase lifecycle pattern persists in tracker templates, which is simpler and more portable than a dedicated skill.
- Type-specific artifact sets via artifact-manifests.json are the lasting design win.

## Journal

### 2026-04-11 -- finding
E2E test of work item creation: scaffolded workflow-alpha with TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones. All templates resolved from repo-local templates/ directory. Manifest found at ~/.claude/artifact-manifests.json.

### 2026-04-11 -- decision
Template consolidation for solo-dev: removed review work item type, removed scrum, simplified Review phase to doc review/generation, simplified Ship phase to /ship + /land-and-deploy, added structured IDs (F/S/D/T prefix).

<!-- CLOSED: 2026-04-13 — all phases complete, children shipped -->
