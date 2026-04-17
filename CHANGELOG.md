# Changelog

All notable changes to this collection will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).


## [0.7.3] - 2026-04-16

### Fixed
- **personal-workflow scaffolder no longer skips required hierarchy levels** (D000007). Root cause: `WORKFLOW.md` Step 1 was silent on recursive generation, so AIs producing trees from the spec stopped at the parent level — leaving e.g. user-stories without the task children declared as `min: 1` in `personal-artifact-manifests.json hierarchy`. Fix: added an explicit "Recursive scaffolding (required)" paragraph to Step 1 mandating that scaffolding a parent type must also scaffold at least `min` children of each `required_child` declared in the manifest, recursing until a type has no `required_child`.
- **personal-workflow Directory Layout convention is now uniform across files and directories** (D000007). The file-prefix rule (`{ID}_TRACKER.md`, `{ID}_{artifact}.md`) was applied at the file level only; containing directories were left as bare slugs (`accounts/` instead of `S000001_accounts/`). Fix: `WORKFLOW.md § Directory Layout` now requires every work-item directory to be named `{ID}_{slug}/`, with the embedded ID matching the directory's TRACKER frontmatter `id`. Updated the layout example to show three nested levels with prefixed dirs.

### Added
- **`check.md` Step 19f — new `[MISFORMATTED]` rule** under the `structure` badge category (D000007). Walks every work-item directory in the Tier 2 hierarchy walk and validates: (1) directory name matches `^[FSTD]\d{6}_[a-z0-9_-]+$`, (2) the ID prefix letter (F/S/T/D) maps to the expected work-item type, (3) the embedded ID equals the TRACKER frontmatter `id`. Top severity in the structure badge — promoted above `INCOMPLETE` and `MISPLACED`. Step 20 (Badge Taxonomy) and Step 23 (Human-Readable Report) updated to surface MISFORMATTED in the Critical findings section and Structural Summary.
- **3 personal-workflow fixtures** under `skills/personal-workflow/fixtures/`: `valid-nested-feature/` (positive control with full feature → user-story → task hierarchy, all dirs ID-prefixed), `invalid-unprefixed-subdir/` (parent feature with bare-slug child to demonstrate `[MISFORMATTED]`), `invalid-missing-required-child/` (user-story with zero task children to demonstrate `[INCOMPLETE]`). New `fixtures/README.md` documents each scenario and how to test Tier 2 rules.
- **New `{SLUG}` placeholder** in `WORKFLOW.md § Placeholder Replacement` table, plus a clarifying line that work-item directories are named `{ITEM_ID}_{SLUG}/`.

### Migration note
After this version, existing personal-workflow consumers with bare-slug work-item directories will fail `[MISFORMATTED]` checks during Tier 2 walks. Backfill: rename each work-item subdirectory to `{ID}_{slug}/` matching its TRACKER's `id` field. Cross-repo example: in the `portfolio` repo, the 5 user-story dirs under `work-items/features/discord-v1/` (`accounts/`, `market-regime/`, `portfolio/`, `reference/`, `trading-desk/`) need backfill to `S00000X_accounts/` etc., plus the parent `discord-v1/` itself to `F000001_discord_v1/`. The consumer-side defect record for that backfill lives at `portfolio/work-items/defects/D000001_scaffold-prefix-hierarchy/`.

The deployed personal-workflow skill at `~/.claude/skills/personal-workflow/` is symlinked to the active development worktree, so changes propagate automatically once this branch merges to `claude/nostalgic-volhard`. No `skills-deploy install --overwrite` is needed unless the deployment is filename-based on a given machine.

## [0.7.2] - 2026-04-16

### Changed
- **company-workflow Phase 2 trackers now gate on test verification** (D000006). All 4 tracker templates (defect, task, user-story, feature) gained a Phase 2 gate that requires the linked test-doc to be marked Pass before advancing to Review/Ship. Closes the loop where a tracker could ship with a half-empty `test-plan.md` that nobody ran. Defect: `Regression test added AND all cases in test-plan.md marked Pass`. Task: `All test cases in test-plan.md marked Pass`. User-story: `All P0 cases in TEST-SPEC.md marked Pass; remaining cases marked Pending/Skip with reason`. Feature: roll-up over child user-stories' TEST-SPECs.
- **test-plan vs TEST-SPEC scope contract is now explicit** (D000006). Top-of-file scope comments added to `templates/{company,personal}-workflow/doc-test-plan.md` ("ONE fix or ONE task; cases concrete and reproducible") and `doc-TEST-SPEC.md` ("ENTIRE user story; every PRD acceptance criterion across happy/edge/error paths"). New `### test-plan vs TEST-SPEC` subsection added to `skills/company-workflow/WORKFLOW.md` codifying the concrete-vs-broader split so authors pick by parent type, not preference.
- **`templates/{company,personal}-workflow/doc-test-plan.md` placeholders generalized** so the same template renders cleanly for both defects and tasks: `parent: {DEFECT_ID}` → `parent: {ITEM_ID}`, `title: "{Defect Name} — Regression Test Plan"` → `title: "{ITEM_NAME} — Test Plan"`. Both placeholders match the canonical UPPER_SNAKE form in WORKFLOW.md and are detectable by the directory-mode validator's `\{[A-Za-z_]+\}` placeholder regex.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000006)" — 10 checks) that guard the new Phase 2 gates, scope comments, title generalization, and WORKFLOW.md subsection against silent removal. Greps anchor on `^- [ ]` checkbox prefix + key tokens so a future minor reword (`marked Pass` → `is Pass`) still trips the gate detection.

## [0.7.1] - 2026-04-16

### Fixed
- **`skills-deploy` now works on Windows** (D000005). Root cause: `jq.exe` on Windows writes output with CRLF line endings, which broke two things in `scripts/skills-deploy` — template-name validation (trailing `\r` failed `\.md$` regex checks) and integer comparisons (`files | length` returning `0\r` caused `[: : integer expression expected`). Fix: a single-line `jq()` shell-function wrapper that pipes `command jq` output through `tr -d '\r'`. No-op on Unix (no `\r` to strip); fixes every existing call site on Windows without per-call edits.
- The wrapper lives in three places for full coverage: `scripts/lib.sh` (picked up by the 8 scripts that source it — validate.sh, test.sh, doctor.sh, lint-skill.sh, deps.sh, generate-readme.sh, sync-upstream.sh, collection-version.sh), `scripts/skills-deploy` (standalone, does not source lib.sh), and `scripts/test-deploy.sh` (standalone).

### Added
- Regression tests in `scripts/test.sh` (5 checks under "Regression test (D000005)") that guard the `jq()` wrapper against silent removal and verify it strips CR while correctly propagating `jq -e` exit status through the `tr` pipe (requires `pipefail`, which all relevant scripts already set).

## [0.7.0] - 2026-04-16

### Added
- `templates/company-workflow/doc-feature-summary.md` — new feature-level roll-up template (Scope, Success Criteria, Constituent User-Stories, Out-of-Scope). Replaces the duplicated PRD/ARCHITECTURE/TEST-SPEC at feature scope.
- `feature-summary` artifact entry in `skills/company-workflow/company-artifact-manifests.json` (feature now requires tracker + feature-summary + milestones, 3 artifacts).
- D000003 defect spun into two: `D000003_company_workflow_feature_artifact_duplication` (this fix) and `D000004_company_workflow_contract_template_drift` (Issues 1 + 3, blocked on architectural rethink — see D000004 tracker).

### Changed
- **company-workflow feature artifact set narrows from 5 to 3.** Feature now requires `tracker + feature-summary + milestones`; user-story unchanged at 5 (`tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones`). The change eliminates duplicated PRD/ARCH/TEST-SPEC content between parent feature dirs and nested user-story dirs (verified concretely in ai-content `F973012/` containing `S1441024-hfss-integration/`).
- `templates/company-workflow/tracker-feature.md`: lifecycle gate "Doc triplet created (PRD + ARCHITECTURE + TEST-SPEC)" replaced with "Feature summary + milestones created"; review-phase "Doc triplet passes doc alignment check" replaced with "Feature summary + milestones pass alignment check".
- `skills/company-workflow/WORKFLOW.md`: Step 1 list and type-to-artifact summary table updated to reflect the 3-artifact feature set; rationale paragraph added pointing to D000003.
- `skills-catalog.json`: company-workflow templates list adds `company-workflow/doc-feature-summary.md` (13 templates → 14).

### Migration note
Existing company-workflow consumers (e.g., the ai-content repo) may have feature directories carrying legacy `PRD.md`, `ARCHITECTURE.md`, and `TEST-SPEC.md` files at feature scope. The validator no longer **requires** these files at feature scope. Note: the validator currently iterates only the manifest's required-artifact list and does not scan for unexpected files, so legacy files happen to be ignored — but this is implementation behavior, not a guaranteed contract. Recommended migration: keep one canonical copy of PRD/ARCHITECTURE/TEST-SPEC at the user-story level (the nested `S*-*/` directory); clean up the feature-scope copies when convenient. New features scaffolded after this version use only `feature-summary.md` + `milestones.md` at the feature level.

### Out of scope (deferred to D000004)
Two related drift defects originally bundled with this work — `workflow_type` frontmatter contract/template drift and `Acceptance Criteria` / `Reproduction Steps` section-order drift — were spun out to D000004 because they hit a separate architectural blocker (the validators are LLM-driven SKILL.md, not executable scripts; the originally-planned bash round-trip runner is unimplementable as designed). See `work-items/defects/D000004_company_workflow_contract_template_drift/` for the rethink. This release ships Issue 2 (artifact duplication) cleanly without that question resolved.

## [0.6.0] - 2026-04-15

### Added
- New `/personal-workflow` skill: self-contained work item validation with check + tree subcommands
- `skills/personal-workflow/SKILL.md`: thin router with 2-level path resolution and stale rules detection
- `skills/personal-workflow/check.md`: Tier 1 (contract.json foundation) + Tier 2 (hierarchy, cross-refs, graph, report)
- `skills/personal-workflow/tree.md`: quick hierarchy view with structural badges
- `skills/personal-workflow/WORKFLOW.md`: scaffolding conventions, 3-phase lifecycle, branch naming rules
- `skills/personal-workflow/contract.json`: 3-phase lifecycle structural validation rules
- `skills/personal-workflow/personal-artifact-manifests.json`: type-to-artifact mapping with hierarchy enforcement
- 7 test fixtures (5 file-mode, 2 directory-mode) for personal-workflow validation
- Personal-workflow templates at `templates/personal-workflow/` (10 templates: 4 trackers + 6 docs)
- Portability, catalog, and stale-reference tests for personal-workflow in test.sh

### Changed
- Templates moved from flat `templates/` to `templates/personal-workflow/` (mirrors company-workflow pattern)
- Template fallback chain simplified from 3-level to 2-level (dropped `~/.claude/spec/templates/`)
- CLAUDE.md updated: 3 skills listed, routing includes /personal-workflow, template docs reflect named sets
- template-registry.json: "workbench" set replaced with "personal-workflow" set
- skills-catalog.json: "docs" entry replaced with "personal-workflow", "templates" entry reduced to doc-SKILL-DESIGN.md only
- validate.sh orphan template detection now walks subdirectories recursively
- test.sh template content tests updated from root paths to `templates/personal-workflow/`
- test-deploy.sh multi-file skill test updated from docs to personal-workflow
- Tracker templates reference `/personal-workflow check` and `/personal-workflow tree` (was `/docs check` and `/docs tree`)

### Removed
- `/docs` skill (skills/docs/) including init.md, check.md, tree.md, DESIGN.md, CHANGELOG.md
- Narrative doc generation (PHILOSOPHY.md/OVERVIEW.md) and claims sidecar staleness detection
- `artifact-manifests.json` at repo root (moved into skill as personal-artifact-manifests.json)
- `rules/work-items.md` global rules file (replaced by WORKFLOW.md inside the skill)
- 10 flat templates at `templates/` root (moved to `templates/personal-workflow/`)

## [0.5.0] - 2026-04-15

### Added
- WORKFLOW.md: doc-driven development guide with scaffolding conventions, ID generation, directory layout, and 4-phase lifecycle
- 13 example files (1 per template) for AI-assisted doc generation, themed around API rate limiting
- `skills-deploy` now symlinks skill subdirectories (examples/, reference/, philosophy/, fixtures/)
- `skills-deploy remove` cleans up subdirectory symlinks
- `skills-deploy relink` recreates subdirectory symlinks
- `skills-deploy doctor` checks subdirectory symlink health (missing + broken)
- Migration guard: diff-then-replace for manual-to-symlink subdirectory migration
- 7 new automated tests for subdirectory lifecycle (Tests 13-19)
- PRD Step 3 (Implement and Iterate) fleshed out with validate-as-continuous-gate workflow

### Changed
- SKILL.md now references WORKFLOW.md via Getting Started section
- skills-catalog.json includes WORKFLOW.md in company-workflow files array
- S000003 work items closed (all children shipped)

### Fixed
- test-deploy.sh referenced deleted skill-author skill (replaced with system-health)
- shellcheck SC2088 warning in test.sh (tilde in quotes)

## [0.4.0] - 2026-04-15
### Changed
- Company-workflow skill (v2.0.0): unified validate command replaces 3 separate subcommands (validate/check/create)
- File mode validates single trackers against contract.json; directory mode validates entire work items against company-artifact-manifests.json
- Type spelling normalized from `userstory` to `user-story` across manifest, templates, and registry
- Tracker-review.md now uses phase headings (### Phase N:) matching all other tracker types
- Tracker-feature.md doc triplet is unconditionally required (removed "N/A for small features")
- Handoff section removed from contract.json and tracker-review.md (unused across all types)

### Added
- `company-artifact-manifests.json` declares type-to-artifact mapping for all 5 company types
- Directory-mode fixtures: `valid-feature-dir/` (5 artifacts) and `invalid-missing-artifact-dir/` (missing PRD)
- Placeholder detection in frontmatter values (regex `{[A-Za-z_]+}`)
- CLAUDE.md routing rule for `/company-workflow validate`
- `skills-deploy` now deploys JSON files alongside skill markdown
- `skills-deploy` now supports subfolder templates (e.g., `company-workflow/tracker-feature.md`)

### Fixed
- `skills-deploy` template name validation blocked subfolder paths (regex extended for one subfolder level)
- `skills-deploy` path traversal prevention (blocked `..` segments in template names)
- `skills-deploy relink` now creates parent directories for nested templates

### Removed
- T000005 (check subcommand) and T000006 (create subcommand) work items (never implemented, replaced by unified validate)

## [0.3.8] - 2026-04-13
### Fixed
- Work items now live in type subfolders: `work-items/features/` and `work-items/defects/`
- All artifact filenames consistently ID-prefixed (`D000001_TRACKER.md`, `F000001_milestones.md`)
- Defect template Phase 2 gate simplified to "Fix committed" (removed "with regression test")
- D000001 tracker and test-plan closed out (was left active after fix shipped in #28)
- `/docs check` placement validation updated for type subfolders (placement, stray detection, tree rendering, graph paths)

### Added
- D000002 work item scaffolded: work item format consistency defect with full artifact set

## [0.3.7] - 2026-04-13
### Fixed
- Milestones artifact moved from user-story to feature type in manifest and rules (milestones track feature delivery, not individual stories)
- Feature tracker template now scaffolds milestones.md at feature level
- User-story tracker template no longer references milestones scaffolding
- Template frontmatter parent placeholder updated from `{USER_STORY_ID}` to `{FEATURE_ID}`
- F000001 milestones.md relocated from story level (S000001) to feature level
- First defect work item (D000001) scaffolded with full defect artifact set

## [0.3.6] - 2026-04-13
### Changed
- Lifecycle simplified from 4 phases (Track/Implement/Review/Ship) to 3 phases (Track/Implement/Ship) across all 4 tracker templates
- `/review` gate removed from templates since `/ship` runs pre-landing review internally
- Doc checks (`/docs check`, `/docs tree`) moved into Ship phase as pre-flight steps
- Template fallback chain standardized to 3-level across all docs: `templates/` > `~/.claude/spec/templates/` > `~/.claude/templates/`
- Task tracker "Design doc approved" gate removed (parent story concern, not task concern)
- F000002 tracker status corrected from `active` to `closed` to match checkbox state
- Stale examples in check.md and tree.md updated to reflect current hierarchy (1 story, 1 task)
- PHILOSOPHY.md aligned: doc triplet now described as user-story-only, fallback chain updated to 3-level

### Removed
- 8 feature-level docs that violated manifest rules: PRD, ARCHITECTURE, TEST-SPEC, milestones from both F000001 and F000002 (features get tracker only per artifact-manifests.json)

## [0.3.5] - 2026-04-13
### Changed
- Closed F000001_workflow_alpha: verified consistency across 12 work item docs (structure, logic, cross-refs), fixed stale lifecycle gates, aligned architecture diagram with manifest
- Feature type now requires only TRACKER in manifest; doc triplet (PRD, ARCHITECTURE, TEST-SPEC, milestones) lives at user-story level
- Feature tracker template no longer suggests decomposing into tasks directly (hierarchy requires tasks under stories)

### Removed
- 7 dead templates: GENERATION-GUIDE (4 files), contract-ARCHITECTURE, contract-PRD, contract-TEST-SPEC

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
