---
name: "deprecated-status-semantics"
type: user-story
id: "S000012_deprecated_status_semantics"
status: active
created: "2026-05-02"
updated: "2026-05-02"
parent: "F000005_deprecated_skill_status"
repo: "claude-skills-templates"
branch: "feat/deprecated-skill-status"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/deprecated-skill-status`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [x] Acceptance criteria verified met
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
3. Ensure all child tasks have shipped
4. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
5. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] TEST-SPEC covers all P0 acceptance criteria
- [x] All children shipped (locally)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] AC1: `skills-catalog.json` is documented to accept `status: deprecated` (alongside `active` / `experimental`)
- [x] AC2: `scripts/skills-deploy install` filters out catalog entries with `status: deprecated` and prints exactly one `WARN: skipping deprecated skill: <name> (use --include-deprecated to install)` line per skipped skill
- [x] AC3: `scripts/skills-deploy install --include-deprecated` installs deprecated skills with no behavioral difference vs. an active skill (full file + template deployment)
- [x] AC4: `scripts/skills-deploy doctor` lists deprecated skills under an INFO line (not WARN) — both deprecated-and-not-installed and deprecated-and-installed states are non-warnings
- [x] AC5: `scripts/skills-deploy remove` removes a previously-installed deprecated skill the same way it removes an active one (no special-casing)
- [x] AC6: `scripts/validate.sh` accepts `deprecated` as a valid `status` value; rejects typos like `depricated` (closed enum)
- [x] AC7: `scripts/generate-readme.sh` renders deprecated entries under a separate "Deprecated" section in the generated README
- [x] AC8: All existing tests in `./scripts/test.sh` continue to pass

## Todos

<!-- Actionable items for this story. -->

- [x] Read current `scripts/skills-deploy` flag-parsing — uses ad-hoc `case` in `do_install` arg loop; mirrored that pattern for `--include-deprecated`
- [x] Read current `scripts/validate.sh` — no pre-existing status check; added new check (Error check 9b) after the existing version check
- [x] Read current `scripts/generate-readme.sh` — single `jq` pass over catalog; split into two passes (active table + Deprecated section, gated on count > 0)
- [x] Implement install filter + `--include-deprecated` flag (AC2, AC3) — gate added at top of skill loop AND template loop (templates are part of skill surface area)
- [x] Implement doctor INFO labeling (AC4) — both installed (`INFO: ... — deprecated, installed (--include-deprecated)`) and not-installed (`INFO: ... — deprecated, not installed by default`) cases
- [x] Update validate.sh status enum (AC6) — closed enum {active, experimental, deprecated}; missing/typo'd values fail
- [x] Update generate-readme.sh (AC7)
- [x] Document `deprecated` in CLAUDE.md / catalog schema commentary (AC1)
- [x] [T000013_migrate_company_workflow](T000013_migrate_company_workflow/T000013_TRACKER.md) — verification gate (AC2, AC3 end-to-end)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-02: Created. Add `deprecated` semantics to the skill catalog and teach `skills-deploy` (install/doctor) and `generate-readme.sh` to honor it. Default install: warn-but-skip; opt-in via `--include-deprecated`.
- 2026-05-02: Implemented all 8 ACs. Files touched: `scripts/skills-deploy`, `scripts/validate.sh`, `scripts/generate-readme.sh`, `skills-catalog.json`, `README.md`, `CLAUDE.md`. End-to-end verified: install on fresh `SKILLS_DEPLOY_TARGET` skips company-workflow and its templates with one WARN line; `--include-deprecated` installs both; doctor INFO in both states; remove works unchanged; idempotency holds (pre-existing install survives a no-flag re-run); typo'd status fails validate; full `./scripts/test.sh` PASS.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills-catalog.json
- scripts/skills-deploy
- scripts/validate.sh
- scripts/generate-readme.sh
- README.md  # regenerated
- CLAUDE.md  # status enum commentary, if any

## Insights

<!-- Non-obvious findings worth remembering. -->

- (TBD during Implement) — record any non-obvious discoveries about flag parsing, manifest schema, or README diff churn here.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-05-02 — decision

Single-story scope (this story) instead of splitting "schema" from "tooling." All edits land in 3 closely-related files in one PR; two stories would create artificial seams across the same diff.
