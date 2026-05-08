---
name: "relocate-deprecated-skills"
type: feature
id: "F000006_relocate_deprecated_skills"
status: active
created: "2026-05-02"
updated: "2026-05-02"
repo: "claude-skills-templates"
branch: "feat/relocate-deprecated-skills"
blocked_by: ""
---

<!-- Follow-up to F000005 (v1.2.0). The deprecation work shipped a "skip on
     install" semantic but kept the source files at `skills/company-workflow/`
     and `templates/company-workflow/` because work-copilot/ byte-mirrors them.
     This feature relocates the source out of `skills/` into a new top-level
     `deprecated/` directory so `skills/` contains only deployable skills, and
     refactors `skills-deploy` + `validate.sh` to derive paths from the catalog
     instead of hardcoding `skills/{name}/`. The work-copilot mirror invariant
     is preserved — only source paths change. -->

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/relocate-deprecated-skills`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
5. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
6. Define acceptance criteria (what "done" looks like for the whole feature)
7. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
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
- [ ] `/personal-workflow check` — all children pass validation
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [x] `skills/` contains exactly: `personal-workflow/`, `system-health/` (no `company-workflow/`)
- [x] `templates/` contains exactly: `personal-workflow/`, `doc-SKILL-DESIGN.md` (no `company-workflow/`)
- [x] `deprecated/company-workflow/` contains the full skill source incl. `templates/` subdir
- [x] `deprecated/README.md` exists explaining the dir's purpose (5-line note)
- [x] `./scripts/validate.sh` passes — Error check 10 (MIRROR_SPECS) verifies byte-identity at the new source paths
- [x] `./scripts/test.sh` passes
- [x] `scripts/skills-deploy install` on a clean target skips `company-workflow` (deprecated, expected)
- [x] `scripts/skills-deploy install --include-deprecated` installs `company-workflow` from `deprecated/company-workflow/`
- [x] `scripts/skills-deploy doctor` reports `company-workflow` under INFO (not WARN), with a "deprecated — not installed by default" annotation
- [x] `skills-catalog.json` `files[]` and `templates[]` for `company-workflow` reference `deprecated/company-workflow/...`
- [x] `scripts/skills-deploy` derives paths from catalog `files[]` via `skill_md_path` / `skill_source_dir` helpers (no hardcoded `skills/{name}/`)
- [x] `scripts/validate.sh` catalog walker + orphan check honor catalog paths; orphan check extended to walk `deprecated/` too
- [x] `scripts/test.sh` introduces `COMPANY_PATH` / `COMPANY_TPL` constants; hardcoded `$REPO_ROOT/skills/company-workflow` and `$REPO_ROOT/templates/company-workflow` refs replaced (test fixture destination paths intentionally retained)
- [x] `CLAUDE.md` references `deprecated/company-workflow/...` consistently; new `deprecated/` convention section documented
- [x] `README.md` regenerated reflects the new paths

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] [S000013_relocate_with_catalog_driven_paths](S000013_relocate_with_catalog_driven_paths/S000013_TRACKER.md) — relocate skills/company-workflow/ + templates/company-workflow/ to deprecated/; refactor skills-deploy + validate.sh to derive paths from catalog
- [x] [T000014_migrate_company_workflow_paths](S000013_relocate_with_catalog_driven_paths/T000014_migrate_company_workflow_paths/T000014_TRACKER.md) — verification gate: clean install + mirror invariant + doctor INFO at new path

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-02: Created. Follow-up to F000005 (v1.2.0). Move company-workflow source out of `skills/` into a new top-level `deprecated/company-workflow/` so `skills/` contains only deployable skills, and refactor consumer scripts to derive paths from the catalog instead of hardcoding `skills/{name}/`. Office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260502-015311.md` (Status: APPROVED).
- 2026-05-02: Implemented. File moves via `git mv` (53 + 14 files). Catalog updated with `templates_source: "deprecated/company-workflow/templates"`. Catalog-driven helpers (`skill_md_path`, `skill_source_dir`, `skill_templates_source`) added to `scripts/skills-deploy`, `scripts/validate.sh`, and `scripts/test.sh`. `discover_skills()` migrated from filesystem walk to catalog iteration. `MIRROR_SPECS` retargeted; `validate.sh` orphan check extended to walk both `skills/` and `deprecated/`; `test.sh` introduces `COMPANY_PATH`/`COMPANY_TPL` constants. `CLAUDE.md` documents the `deprecated/` convention. `deprecated/README.md` added. README regenerated. Verified: `./scripts/validate.sh` PASS (0 errors / 0 warnings; Error check 10 byte-identity verified for all 7 mirror entries); `./scripts/test.sh` PASS (Failures: 0); T000014 6 regression cases all PASS on a fresh `SKILLS_DEPLOY_TARGET` (default install skips with 1 WARN; `--include-deprecated` installs from new path with manifest path field reflecting `deprecated/company-workflow/SKILL.md`; doctor reports INFO; idempotent re-install no-op).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/company-workflow/                       # MOVED to deprecated/company-workflow/ (53 files)
- templates/company-workflow/                    # MOVED to deprecated/company-workflow/templates/ (14 templates)
- deprecated/                                    # NEW top-level directory
- deprecated/README.md                           # NEW (5-line purpose note)
- skills-catalog.json                            # update files[] + templates[] for company-workflow
- scripts/skills-deploy                          # line 260 + line 278: derive paths from catalog
- scripts/validate.sh                            # MIRROR_SPECS retarget; catalog walker + orphan check honor catalog paths
- scripts/test.sh                                # introduce COMPANY_PATH / COMPANY_TPL constants; ~40 path replacements
- CLAUDE.md                                      # 3 path refs updated; new `deprecated/` convention line
- README.md                                      # regenerated artifact

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- F000005's "Out-of-Scope" listed *deletion* of `skills/company-workflow/` as out-of-scope, but did not consider *relocation*. F000006 occupies that gap — same byte-mirror invariant, different folder shape.
- The work-copilot byte-mirror is the load-bearing constraint. `validate.sh` Error check 10's `MIRROR_SPECS` array (7 entries) is the canonical check. Post-move, all 7 source paths point at `deprecated/company-workflow/...`; the destination paths under `work-copilot/` do not change.
- `scripts/generate-readme.sh` and `scripts/copilot-deploy.py` showed zero hardcoded `skills/company-workflow` or `templates/company-workflow` references in the preliminary grep — both are catalog-driven. The work concentrates in `skills-deploy`, `validate.sh`, and `test.sh`.
- `skills-catalog.json` `templates[]` entries are shaped like `"company-workflow/tracker-feature.md"` — verify during implementation whether these are filesystem-relative paths under `templates/` or catalog keys. The resolver behavior in `skills-deploy` decides which one needs adjusting.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-05-02 — decision

Top-level `deprecated/` directory chosen over `bundle-sources/` (function-named) and `skills/_deprecated/` (in-place rename). Rationale: `deprecated/` names the lifecycle state, scales naturally if more skills get deprecated later, and stays out of `skills/` so the main directory only contains deployable skills. `bundle-sources/` would have named the function but reads against the lifecycle, less obvious to a future reader. `skills/_deprecated/` doesn't actually solve the stated complaint (still under skills/).

### 2026-05-02 — decision

Catalog-driven path refactor (Approach A) chosen over special-case lookup (Approach B) and reactive fix-as-broken (Approach C). Rationale: the catalog already has `files[]` / `templates[]` arrays. Making `skills-deploy` line 260 + 278 and `validate.sh` line 30 honor the catalog removes a hardcoded `skills/{name}/` assumption that costs nothing today but creates a maintenance trap the next time a skill needs to move. B trades short-term diff size for long-term debt; C is too reactive for a refactor with mirror-invariant verification.

### 2026-05-02 — decision

Templates move WITH the skill (`deprecated/company-workflow/templates/`) instead of staying at `templates/company-workflow/`. Rationale: the whole "company-workflow as upstream truth" concept lives in one self-contained directory. `templates/` top-level is left clean (only `personal-workflow/` and `doc-SKILL-DESIGN.md`). The work-copilot mirror's templates entry retargets at the new path; byte-identity preserved.
