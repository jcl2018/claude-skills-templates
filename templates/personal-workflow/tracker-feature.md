---
name: "{FEATURE_NAME}"
type: feature
id: "{FEATURE_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/{slug}`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `feature-summary.md` (roll-up identity: scope, success criteria, constituent stories, non-goals) — from `templates/doc-feature-summary.md`
5. Scaffold `DESIGN.md` (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
6. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
7. Define acceptance criteria (what "done" looks like for the whole feature)
8. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [ ] Acceptance criteria scoped
- [ ] Working branch created (`branch` field populated)
- [ ] feature-summary + DESIGN + milestones scaffolded
- [ ] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Ensure all child stories have shipped
3. Run `/ship` — creates feature PR, includes pre-landing code review
4. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] {criterion}

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief feature description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
