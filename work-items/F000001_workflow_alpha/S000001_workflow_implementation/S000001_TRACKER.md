---
name: "Workflow Alpha Implementation"
type: user-story
id: "S000001_workflow_implementation"
status: active
created: "2026-04-11"
updated: "2026-04-13"
parent: "F000001_workflow_alpha"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   -> produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Extract from design doc into doc triplet: requirements -> `PRD.md`, architecture decisions -> `ARCHITECTURE.md`, test scenarios -> `TEST-SPEC.md`
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
3. Update Todos section -- remove completed items, add new discoveries
4. Update Files section with all changed file paths

**Gates:**
- [x] Implementation committed (>=1 commit SHA in Log)
- [x] Acceptance criteria verified met
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` -- verify all validation passes
   -> should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` -- verify hierarchy and structural completeness
3. Run tests: `./scripts/test.sh`
4. Review TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
5. Run `/review` for code review (if PR exists)

**Gates:**
- [ ] `/docs check` -- validation passed
- [ ] `/docs tree` -- structure verified
- [ ] Test verification passed
- [ ] Doc triplet alignment verified (TEST-SPEC covers P0 stories)

### Phase 4: Ship

1. Run `/ship` -- creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` -- merges PR and verifies deployment

**Gates:**
- [ ] `/ship` -- PR created
- [ ] `/land-and-deploy` -- merged and deployed

## Acceptance Criteria

### Four-Phase Workflow (from S000001)
- [x] Branch-aware router detects feat/*, fix/*, task/*, story/* and resolves work items
- [x] Track phase: manifest-driven scaffolding for 4 types, evidence synthesis, journal/milestones/list/close/child-items
- [x] Implement phase: build-forward for features, debug-backward with 3-hypothesis testing for defects
- [x] Review phase: `/docs check` as quality gate, then delegates to gstack /review
- [x] Ship phase: /ship + /land-and-deploy
- [x] Status menu shows phase progress when invoked without subcommand
- [x] Handoff blocks written after each phase transition

### Template Consolidation (from S000002)
- [x] Tracker templates reflect solo-dev workflow (no "reviewer noted", no "Linux branch build")
- [x] Lifecycle gates are meaningful for a single developer working with Claude Code
- [x] Redundant fields removed (JIRA/TFS URL, workflow_type)
- [x] Review phase gates: doc review + generation (feature), + test verification (task/defect), + triplet alignment (user-story)
- [x] Ship phase gates: `/ship` + `/land-and-deploy`
- [x] Task tracker is lightweight
- [x] All 4 tracker templates updated consistently (review type removed)
- [x] Structured IDs: F/S/D/T prefix with 6-digit number + keywords
- [x] Scrum removed (subcommand, template, notes generation)
- [x] Review work item type removed (tracker-review.md, doc-review-notes.md, review-* branch pattern)

### Structural Completeness (from S000003)
- [x] `/docs check` flags F000002_system_health_v1 as INCOMPLETE (0 user-story children)
- [x] Tree report renders hierarchy with per-node badges (template, lifecycle, traceability, structure)
- [x] `work-item-graph.json` emitted to `.docs/` with correct schema (nodes, edges, structural_rules, completeness)
- [x] Hierarchy rules read from `artifact-manifests.json` `hierarchy` field (required, no fallback)
- [x] Placement rules enforced: feature/defect root-level, story inside feature, task inside story
- [x] Badge taxonomy maps all existing check statuses to 4 badge categories with severity ordering
- [x] Claims.json gate separated: Steps 1-5 skip if missing, Steps 6+ run regardless
- [x] Lifecycle cross-reference: "broken down" checked + 0 children = LIFECYCLE_INCONSISTENT
- [x] `/docs tree` subcommand renders tree with structural badges only (other badges show "-")
- [x] Repos without `work-items/` gracefully skip structural checks and tree report
- [x] Existing checks (1-3) continue to work unchanged
- [x] Human-readable report written to `.docs/work-item-report.md`

## Todos

- [x] [T000001_implement_workflow](T000001_implement_workflow/T000001_TRACKER.md) -- Full workflow implementation

### Remaining
- [ ] Run `/docs check` -- verify consolidated hierarchy passes
- [ ] Run `./scripts/test.sh` for full validation

## Log

- 2026-04-11: Created as S000001_four_phase. Four-phase workflow pipeline user story.
- 2026-04-11: S000002 template consolidation implemented. Updated 4 tracker templates, removed 4 files.
- 2026-04-11: S000003 structural completeness designed via /office-hours (9/10 after adversarial review).
- 2026-04-12: S000003 structural check implemented (154a4b3), human-readable report shipped (#24).
- 2026-04-13: Consolidated S000001 + S000002 + S000003 into single story. Doc triplet from S000003 (most complete).

## PRs

- #22 -- feat: structural completeness check, tree report, and graph artifact
- #24 -- feat: human-readable report + runbook lifecycle phases

## Files

- skills/workflow/SKILL.md
- skills/workflow/track.md
- skills/workflow/implement.md
- skills/workflow/review.md
- skills/workflow/ship.md
- skills/docs/check.md
- skills/docs/tree.md
- skills/docs/SKILL.md
- artifact-manifests.json
- skills-catalog.json
- templates/tracker-feature.md
- templates/tracker-defect.md
- templates/tracker-task.md
- templates/tracker-user-story.md

## Insights

- Consolidating 5 separate skills into one router with shared context was the key design win.
- Phase detection counts checkboxes, not text -- changing gate wording is safe.
- Claims.json gate blocks ALL downstream checks including work items. Fix: separate Steps 1-5 from Steps 6+.
- Badge taxonomy must map ALL existing check statuses to 4 categories with explicit severity ordering.
- F000002's TRACKER has "broken down" checked but 0 children -- lifecycle/structural contradiction.

## Journal

### 2026-04-11 -- decision (from S000003)
Absolute rule: feature must have >= 1 user-story, user-story must have >= 1 task. No escape hatch. If something doesn't decompose, it's the wrong type.

### 2026-04-11 -- decision (from S000003)
Hierarchy rules stored in artifact-manifests.json, not hard-coded. Required field, no fallback.

### 2026-04-11 -- decision (from S000002)
Kept 4 phases for tasks (not 2) but with lighter gates. Consistent model; fewer gates achieves "lighter" without a structural change.

### 2026-04-13 -- decision
Consolidated 3 user stories (S000001, S000002, S000003) into 1. The decomposition was useful during development but became maintenance overhead once the work shipped.
