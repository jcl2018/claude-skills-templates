---
name: "Structural Completeness + Tree Report"
type: user-story
id: "S000003_structural_completeness"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "F000001_workflow_alpha"
repo: "claude-skills-templates"
branch: "feat/structural-completeness"
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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` — verify hierarchy and structural completeness
3. Run tests: `./scripts/test.sh`
4. Review TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
5. Run `/review` for code review (if PR exists)

❌ If `/docs check` finds issues: fix findings, re-run until clean

**Gates:**
- [x] `/docs check` — validation passed
- [x] `/docs tree` — structure verified
- [ ] Test verification passed
- [ ] Doc triplet alignment verified (TEST-SPEC covers P0 stories)

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/ship` — PR created (#22)
- [x] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `/docs check` flags F000002_system_health_v1 as INCOMPLETE (0 user-story children)
- [x] `/docs check` flags S000002_template_consolidation as INCOMPLETE (0 task children)
- [x] Tree report renders hierarchy with per-node badges (template, lifecycle, traceability, structure)
- [x] `work-item-graph.json` emitted to `.docs/` with correct schema (nodes, edges, structural_rules, completeness)
- [x] Hierarchy rules read from `artifact-manifests.json` `hierarchy` field (required, no fallback)
- [ ] Orphan/misplaced detection: task under feature flagged as MISPLACED
- [x] Placement rules enforced: feature/defect root-level, story inside feature, task inside story
- [x] Badge taxonomy maps all existing check statuses to 4 badge categories with severity ordering
- [x] Claims.json gate separated: Steps 1-5 skip if missing, Steps 6+ run regardless
- [x] Lifecycle cross-reference: "broken down" checked + 0 children = LIFECYCLE_INCONSISTENT
- [x] `/docs tree` subcommand renders tree with structural badges only (other badges show "—")
- [x] Repos without `work-items/` gracefully skip structural checks and tree report
- [x] Existing checks (1-3) continue to work unchanged

## Todos

- [x] Add `hierarchy` field to artifact-manifests.json
- [x] Separate claims.json gate in check.md (Steps 1-5 vs 6+)
- [x] Add Steps 15-17 to check.md (structural check + orphan detection, tree report, graph artifact)
- [x] Add badge taxonomy mapping to check.md
- [x] Add lifecycle cross-reference for "broken down" checkbox
- [x] Create tree.md for `/docs tree` subcommand
- [x] Update SKILL.md with `/docs tree` routing
- [x] Update skills-catalog.json (version bump, add tree.md)
- [x] Run `/docs check` to verify F000002 flagged
- [x] Run `./scripts/validate.sh` to confirm no regressions

## Log

- 2026-04-11: Created. Structural completeness enforcement for work item hierarchy.
- 2026-04-11: Design doc produced via /office-hours (9/10 after adversarial review).
- 2026-04-11: CEO review completed (SCOPE EXPANSION, 5 expansions accepted, 1 deferred).

## PRs

## Files

- skills/docs/check.md
- skills/docs/tree.md (new)
- skills/docs/SKILL.md
- artifact-manifests.json
- skills-catalog.json

## Insights

- Claims.json gate blocks ALL downstream checks including work items (Codex found this).
- Badge taxonomy must map all existing statuses to 4 categories with explicit severity ordering.
- F000002's TRACKER has "broken down" checked but 0 children — lifecycle/structural contradiction.

## Journal

### 2026-04-11 -- decision
Absolute rule: feature must have >= 1 user-story, user-story must have >= 1 task. No escape hatch. If something doesn't decompose, it's the wrong type.

### 2026-04-11 -- decision
Hierarchy rules stored in artifact-manifests.json, not hard-coded. Required field, no fallback. Forces repos to be explicit.

### 2026-04-11 -- decision
/docs tree shows structural badges only. Template/lifecycle/traceability badges show "—". Speed over completeness for the quick view.
