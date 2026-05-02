---
name: "deprecated-skill-status"
type: feature
id: "F000005_deprecated_skill_status"
status: active
created: "2026-05-02"
updated: "2026-05-02"
repo: "claude-skills-templates"
branch: "feat/deprecated-skill-status"
blocked_by: ""
---

<!-- Implementation status: All 8 acceptance criteria verified locally
     (validate.sh + test.sh + manual install/doctor on fresh target). Phase 3
     ship gates pending /ship + /land-and-deploy invocation. -->

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/deprecated-skill-status`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `feature-summary.md` (roll-up identity: scope, success criteria, constituent stories, non-goals) — from `templates/doc-feature-summary.md`
5. Scaffold `DESIGN.md` (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
6. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
7. Define acceptance criteria (what "done" looks like for the whole feature)
8. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] feature-summary + DESIGN + milestones scaffolded
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Ensure all child stories have shipped
3. Run `/ship` — creates feature PR, includes pre-landing code review
4. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [x] `/personal-workflow check` — all children pass validation
- [x] All children shipped (locally — `/ship` step pending)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [x] `skills-catalog.json` schema documents `deprecated` as a valid `status` value alongside `active` / `experimental` (via `validate.sh` enum check + CLAUDE.md note)
- [x] `scripts/skills-deploy install` skips skills with `status: deprecated` by default and prints a one-line warning per skipped skill
- [x] `scripts/skills-deploy install --include-deprecated` installs deprecated skills (escape hatch, for users who still need them)
- [x] `scripts/skills-deploy doctor` reports deprecated skills as INFO (not WARN), with a "deprecated — not installed by default" annotation
- [x] `scripts/validate.sh` accepts `deprecated` as a valid `status` value (no false-positive errors); rejects typos like `depricated`
- [x] `scripts/generate-readme.sh` renders deprecated skills under a separate "Deprecated" section
- [x] `company-workflow` flipped to `status: deprecated` in `skills-catalog.json`; install on a clean target skips it; `--include-deprecated` still installs it
- [x] `./scripts/test.sh` passes end-to-end on the feature branch

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] [S000012_deprecated_status_semantics](S000012_deprecated_status_semantics/S000012_TRACKER.md) — define `deprecated` semantics in catalog + install/doctor/readme honoring it
- [x] [T000013_migrate_company_workflow](S000012_deprecated_status_semantics/T000013_migrate_company_workflow/T000013_TRACKER.md) — flip company-workflow to deprecated; verify install skips it

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-02: Created. Add a `deprecated` status value to the skill catalog so retired skills (e.g., `company-workflow`, superseded by the `work-copilot` Copilot bundle) can stay in the repo for reference but are skipped by `skills-deploy install` by default. Default behavior: warn-but-skip; opt-in via `--include-deprecated`.
- 2026-05-02: Implemented. Edits across `scripts/skills-deploy` (install filter + `--include-deprecated` flag, doctor INFO labels in both installed/not-installed states, templates loop also gated), `scripts/validate.sh` (Error check 9b: closed status enum), `scripts/generate-readme.sh` (separate "Deprecated" section gated on count > 0), `skills-catalog.json` (company-workflow → `status: deprecated`), `README.md` regenerated, `CLAUDE.md` (catalog format note). Verified end-to-end on a fresh `SKILLS_DEPLOY_TARGET`: install skips company-workflow with WARN, `--include-deprecated` installs it, doctor INFO in both states, validate fails on `depricated` typo, idempotency preserves pre-existing install. `./scripts/test.sh` PASS (Failures: 0).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills-catalog.json                          # add status="deprecated" semantics; flip company-workflow
- scripts/skills-deploy                        # filter deprecated on install; --include-deprecated escape hatch; doctor INFO label
- scripts/validate.sh                          # accept "deprecated" in status enum check (if any)
- scripts/generate-readme.sh                   # render deprecated section
- README.md                                    # regenerated artifact
- work-items/features/F000005_deprecated_skill_status/  # this work item

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Today the `status` field in `skills-catalog.json` is read only by `generate-readme.sh` (display); `skills-deploy` ignores it entirely. So this feature is mostly about *giving the field teeth* — not adding a brand-new field.
- Existing values in the catalog: `"active"` (4×). The DESIGN docs and `skills-catalog.json` schema mention `experimental` as a third value but no skill currently uses it. Adding `deprecated` is consistent with that prior intent.
- `company-workflow` is the canonical first deprecated skill: superseded by the GitHub Copilot bundle (`work-copilot/`, F000004) on the user's Windows work machine, but the source skill stays in the repo as upstream truth for the byte-mirrored bundle (`validate.sh` Error check 10 enforces the mirror).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-05-02 — decision

Default install behavior is **warn-but-skip** for `status: deprecated`. Rejected silent-skip (too easy to miss a deprecation when reinstalling on a new machine) and warn-and-install (defeats the purpose of marking deprecated). The escape hatch is `--include-deprecated`, which both installs the skill and acknowledges the user explicitly wants the deprecated version.

### 2026-05-02 — decision

Single user-story decomposition (S000012) instead of splitting "schema/catalog change" from "tooling change." All edits land in the same files (`skills-catalog.json`, `scripts/skills-deploy`, `scripts/generate-readme.sh`) and ship in one PR, so two stories would create artificial seams. The migration of `company-workflow` is the verification gate, scoped as a child task (T000013) under S000012.
