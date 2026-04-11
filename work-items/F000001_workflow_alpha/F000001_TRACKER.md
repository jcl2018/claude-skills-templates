---
name: "workflow-alpha"
type: feature
id: "F000001_workflow_alpha"
status: active
created: "2026-04-11"
updated: "2026-04-11"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Acceptance criteria scoped
- [x] Working branch created
- [x] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Broken down into child tasks/stories

### Phase 2: Implement
- [x] Doc triplet read (build-forward mode)
- [x] Core implementation committed (>=1 commit SHA in Log)
- [x] Child tasks completed or deferred
- [x] Files section updated

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] 4-phase workflow router works (track → implement → review → ship)
- [x] Branch-aware work item resolution
- [x] Manifest-driven scaffolding for 4 work item types (feature, defect, task, user-story)
- [x] Contract quality gates at review and ship
- [x] Dual implement modes (build-forward vs debug-backward)
- [ ] Final E2E test: create a work item using the workflow itself (this test)

## Todos

### User Stories
- [x] [S000001_four_phase](S000001_four_phase/S000001_TRACKER.md) — Four-phase workflow pipeline (1 task)
- [ ] [S000002_template_consolidation](S000002_template_consolidation/S000002_TRACKER.md) — Fix tracker templates for solo-dev mode

### Remaining
- [ ] Complete E2E test (creating this work item is the test)
- [ ] Run `/contracts check` on the doc triplet
- [ ] Run `./scripts/test.sh` for full validation

## Log

- 2026-04-11: Created. v1 documentation for workflow skill — the 4-phase router with track, implement, review, ship.
- 2026-04-11: Doc triplet populated. PRD covers 11 user stories, ARCHITECTURE maps the router + 4 subcommands, TEST-SPEC has 8 test cases + 5 smoke tests + 4 E2E scenarios.
- 2026-04-11: Template consolidation implemented — new solo-dev gates, removed review type, removed scrum, structured IDs.

## PRs

## Files

- skills/workflow/SKILL.md
- skills/workflow/track.md
- skills/workflow/implement.md
- skills/workflow/review.md
- skills/workflow/ship.md
- skills/workflow/DESIGN.md
- skills/workflow/CHANGELOG.md
- templates/tracker-feature.md
- templates/tracker-defect.md
- templates/tracker-task.md
- templates/tracker-user-story.md

## Insights

- Consolidating 5 original skills into a single /workflow router was the key design decision — context resolved once, shared across phases.
- Branch-as-primary-key means zero config: just be on the right branch and /workflow knows what you're working on.
- Dual implement modes (build-forward vs debug-backward) exist because features and defects have fundamentally different workflows.

## Journal

### 2026-04-11 -- finding
E2E test of work item creation: scaffolded workflow-alpha with TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones. All templates resolved from repo-local templates/ directory. Manifest found at ~/.claude/artifact-manifests.json.

### 2026-04-11 -- decision
Template consolidation for solo-dev: removed review work item type, removed scrum, simplified Review phase to doc review/generation, simplified Ship phase to /ship + /land-and-deploy, added structured IDs (F/S/D/T prefix).

<!-- HANDOFF: phase=review status=in-progress next=/workflow review -->
