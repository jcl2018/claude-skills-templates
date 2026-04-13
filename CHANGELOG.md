# Changelog

All notable changes to this collection will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.3.4] - 2026-04-13
### Changed
- Consolidated F000001 work items: 3 user stories (S000001, S000002, S000003) merged into S000001_workflow_implementation, 4 tasks merged into T000001_implement_workflow
- Doc triplet from S000003 (most complete) preserved via git mv with rename history
- All acceptance criteria, insights, and journal entries merged with source attribution

### Removed
- S000002_template_consolidation directory and all artifacts
- S000003_structural_completeness directory and all child tasks (T000002, T000003, T000004)

## [0.3.3] - 2026-04-12
### Added
- `/docs check` now writes a human-readable health report to `.docs/work-item-report.md` (tree, badge summary table, findings by severity, structural summary)
- `/docs tree` now writes a lightweight tree report to `.docs/work-item-tree.md`
- Runbook-style lifecycle phases in all 4 tracker templates: numbered procedural steps with exact commands + checkbox completion gates
- Each work item type gets its own runbook (feature coordinates via children, user-story uses `/office-hours` + doc triplet, task is simpler, defect uses `/investigate`)

### Changed
- All 8 existing trackers migrated to runbook format with checkbox states preserved
- Feature Phase 2 shifts from hands-on implementation to child coordination
- `.docs/` directory now gitignored (generated artifacts, regenerated each run)
- `MISSING` and `STRAY` statuses now included in report severity mapping

## [0.3.2] - 2026-04-12
### Added
- `/docs check` now enforces structural completeness: features must have user stories, stories must have tasks
- `/docs tree` standalone subcommand for quick hierarchy view with structural badges
- Work item tree report with per-node badges (template, lifecycle, traceability, structure)
- Machine-readable `.docs/work-item-graph.json` artifact with nodes, badges, completeness, and structural rules
- Hierarchy and placement rules in `artifact-manifests.json` (configurable per-project)
- Orphan/misplaced item detection (tasks under features flagged as MISPLACED)
- Lifecycle cross-reference: "broken down" checked with 0 children flags LIFECYCLE_INCONSISTENT
- Badge taxonomy mapping all check statuses to 4 categories with severity ordering
- S000003 work item (structural completeness) with T000002 (implementation) and T000003 (human-readable report)

### Changed
- `/docs check` no longer stops when claims.json is missing; staleness checks skip, work item checks run independently
- docs skill bumped to v0.3.0

## [0.3.1] - 2026-04-11
### Added
- PHILOSOPHY.md with claims sidecar for staleness detection
- S000002 milestones and T000001 test-plan (scaffolded from templates)
- F000001 and S000002 TEST-SPEC traceability entries for untested P0 stories

### Fixed
- S000001 and S000002 tracker type spelling ("userstory" to "user-story")
- S000001 and S000002 missing parent field in tracker frontmatter
- S000002 TEST-SPEC stale references to deleted tracker-review.md
- VERSION format (4-digit to semver)

## [0.3.0] - 2026-04-11
### Added
- `/docs check` now validates work items against their templates: template compliance, lifecycle consistency, and PRD-to-TEST-SPEC traceability
- Normalization layer handles type spelling mismatches and ID-prefixed filenames automatically
- P0-only traceability enforcement (P1/P2 stories get advisory-level flags, not warnings)
- Defensive error handling for missing manifests, templates, and malformed frontmatter

### Fixed
- Removed stale review-type references from F000001 work items (leftover from /workflow deletion)

## [0.2.4] - 2026-04-11
### Added
- system-health V1: feature work item (F000002) with TRACKER, PRD, ARCHITECTURE, TEST-SPEC, and milestones
- system-health version bump to 1.0.0 (no functional changes from 0.3.0)
- Backfilled missing system-health [0.3.0] CHANGELOG entry (usage trends, anomaly detection)

## [0.2.3] - 2026-04-11
### Removed
- `/skill-author` skill: 6-stage guided pipeline replaced by CLAUDE.md "Creating a new skill" section + direct script usage
- 6 lifecycle scripts: `skill-design.sh`, `create-skill.sh`, `skill-check.sh`, `skill-version.sh`, `skill-ship.sh`, `skill-migrate.sh`

### Changed
- Moved skill-author's 5 templates (doc-SKILL-DESIGN.md, generation guides) to the `templates` catalog entry
- Rewrote test.sh integration tests to use manual skill creation instead of deleted scaffolding scripts
- Fixed lint-skill.sh exit code handling in test.sh (pre-existing issue, warnings are non-zero exit)
- Updated CLAUDE.md, README.md, CONTRIBUTING.md to reflect 2-skill repo

### Added
- CLAUDE.md "Creating a new skill" section with frontmatter schema, catalog JSON format, and validation instructions

## [0.2.2] - 2026-04-11
### Removed
- `/workflow` skill (7 files): implement, review, and ship phases were redundant with gstack; track phase replaced by CLAUDE.md rules
- `/contracts` skill (3 files): doc triplet enforcement replaced by CLAUDE.md validation rules
- Orphan doc directories for deleted skills (docs/workflow/, docs/contracts/)

### Added
- `## Work Item Templates` section in CLAUDE.md: type-aware scaffolding, 3-level template fallback, branch conventions, ID generation, git-journal synthesis, contract validation
- `templates` catalog entry: templates-only distribution vehicle (no SKILL.md, 13 templates)
- `artifact-manifests.json` at repo root: canonical type-to-artifact mapping (previously external-only)
- Templates-only support in skills-deploy: install, remove, and doctor handle catalog entries with no SKILL.md

### Changed
- skills-catalog.json: workflow and contracts entries replaced by templates entry
- test-deploy.sh: test fixtures rewritten from workflow/contracts to docs/templates
- README.md: updated to template library identity (3 skills + template library)
- skills/docs references to /contracts updated to reflect removal

## [0.2.1] - 2026-04-11
### Changed
- Tracker templates rewritten for solo-dev workflow: removed enterprise gates ("reviewer noted", "Linux branch build"), JIRA/TFS URLs, and redundant `workflow_type` field
- User-story template now includes `parent` field and normalized `type: user-story` (was `userstory`)
- Template validation in track.md is now type-aware: defect/task no longer require PRD/ARCHITECTURE/TEST-SPEC templates

### Removed
- Review work item type: deleted tracker-review.md, doc-review-notes.md, doc-scrum.md, and TRACKER-TEMPLATE.md
- Scrum subcommand and `review-*` branch pattern from workflow skill
- 4 orphaned template references from skills-catalog.json

### Added
- 6 template content smoke tests in test.sh (enterprise gate checks, JIRA/TFS detection, gate count validation, review type removal)

## [0.2.0] - 2026-04-11
### Added
- New `/docs` skill with two subcommands: `init` (generate PHILOSOPHY.md or OVERVIEW.md) and `check` (staleness detection + coherence)
- Claims sidecar (`.docs/claims.json`) maps doc sections to evidence files with commit SHAs for diff-based staleness detection
- Unreachable commit guard for rebase/force-push resilience in staleness checks
- Schema validation for claims.json on read with clear error messages
- Quick Start workflow example in SKILL.md

## [0.1.0] - 2026-04-11
### Added
- Collection versioning with VERSION file at repo root
- `collection-version.sh` script (get, bump, manifest subcommands)
- Auto-bump collection version on `skill-ship.sh`
- VERSION consistency checks in `validate.sh`
- Collection version tracking in `skills-deploy` manifest
- Drift detection via on-demand manifest regeneration in `skills-deploy doctor`
- Semver semantics defined (patch/minor/major for the collection)

### Changed
- `skill-ship.sh` now creates a single commit with both skill tag and collection v-tag
- `skills-deploy install` records `collection_version` and `collection_commit`
- `skills-deploy doctor` reports collection version status and template drift
- `lib.sh` gains `file_checksum()`, `read_version()`, and `version_gte()` helpers
