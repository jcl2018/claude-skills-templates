---
type: design
parent: F000006_relocate_deprecated_skills
title: "relocate-deprecated-skills — Feature Design"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (PRD/ARCHITECTURE/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. Source: office-hours design doc at
     `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260502-015311.md`. -->

## Problem

F000005 (v1.2.0, shipped 2026-05-02) made `skills-deploy install` skip `company-workflow` on clean machines, but kept all source files at `skills/company-workflow/` and `templates/company-workflow/`. The reason: `work-copilot/` byte-mirrors 7 things from those paths via `validate.sh` Error check 10's `MIRROR_SPECS` array, and deletion would break the bundle.

End state today: `skills/` contains `company-workflow/` (deprecated), `personal-workflow/` (active), `system-health/` (active). The deprecated entry is visually indistinguishable from the active ones — `status: deprecated` lives only in the catalog JSON. Opening the folder reads as "deployable skills + one deprecated holdout" instead of "deployable skills only." User reaction on revisiting: "I still see company-workflow related skill/doc/templates in this folder."

The fix: relocate the source out of `skills/` into a new top-level `deprecated/` directory. The path itself names the lifecycle state. `skills/` becomes a curated catalog of deployable skills only. The work-copilot byte-mirror invariant continues to hold — only source paths change.

## Shape of the solution

Two artifacts ship in one PR. The bulk of the work is the user-story (S000013); the task (T000014) is the end-to-end verification gate.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| File moves (skills + templates), catalog updates, skills-deploy + validate.sh + test.sh refactor, CLAUDE.md, deprecated/README.md, README regen | S000013 | [S000013_relocate_with_catalog_driven_paths/S000013_TRACKER.md](S000013_relocate_with_catalog_driven_paths/S000013_TRACKER.md) |
| Verify clean-target install with and without `--include-deprecated`, mirror invariant byte-check, doctor INFO at new path | T000014 | [S000013_relocate_with_catalog_driven_paths/T000014_migrate_company_workflow_paths/T000014_TRACKER.md](S000013_relocate_with_catalog_driven_paths/T000014_migrate_company_workflow_paths/T000014_TRACKER.md) |

Same shape as F000005 (one user-story + one verification task). All edits land in the same files; two stories would create artificial seams.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | New top-level dir is named **`deprecated/`** (not `bundle-sources/`, not `skills/_deprecated/`) | `deprecated/` names the lifecycle state, which scales if more skills get deprecated later. `bundle-sources/` named the function (mirror source) but reads against the lifecycle — confusing if a deprecated skill ever stops being a bundle source. `skills/_deprecated/` keeps the entry under skills/, which doesn't solve the stated complaint. |
| 2 | Templates move **WITH the skill** as `deprecated/company-workflow/templates/` (not retained at `templates/company-workflow/`) | The whole company-workflow concept lives in one self-contained directory. `templates/` top-level stays clean (only `personal-workflow/` and `doc-SKILL-DESIGN.md`). Mirror destination paths under `work-copilot/templates/` are unchanged — only the source path retargets. |
| 3 | Refactor `skills-deploy` (line 260, line 278) and `validate.sh` (line 30 catalog walker, line 71 orphan check) to derive paths from catalog `files[]` / `templates[]` (not special-case deprecated lookup) | Catalog already has `files[]` / `templates[]` arrays. Making consumer scripts respect them removes a hardcoded `skills/{name}/` assumption that creates a maintenance trap the next time a skill needs to move. Special-casing deprecated paths trades short-term diff size for long-term debt. |
| 4 | `test.sh` introduces a `COMPANY_PATH` constant near the top; replace ~40 hardcoded `skills/company-workflow` / `templates/company-workflow` refs | One-time pain to introduce the constants makes the next move (if any) trivial. Same principle as decision #3 applied to the test suite. |
| 5 | Add a 5-line `deprecated/README.md` explaining the directory's purpose | Without it, a future contributor opening the dir wonders why source files live outside `skills/`. The note: "contents are upstream-truth sources for byte-mirrored bundles, not deployable skills." |
| 6 | `validate.sh` orphan check (line 71) is extended to walk `deprecated/` with the same orphan rule (deprecated dir without a corresponding deprecated catalog entry → orphan) | Keeps the check symmetric. Catches the case where someone moves a directory under `deprecated/` but forgets to update the catalog. |
| 7 | Pure relocation — no SKILL.md content changes, no behavioral changes outside path resolution | Smaller blast radius, easier to verify. Frontmatter banners, archived tiers, and bundle-vending refactors are deferred per Out-of-Scope. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Are `skills-catalog.json` `templates[]` entries filesystem-relative paths under `templates/` or catalog keys? Resolver behavior in `skills-deploy` decides which one needs adjusting. | Resolved during S000013 ARCHITECTURE phase: trace skills-deploy's templates-resolution logic from line ~278 onward. If the resolver hardcodes `templates/{name}/`, either change it to read from a per-skill source field on the catalog entry or update entries to be filesystem-relative paths. |
| `scripts/skills-deploy` line 260 stores the manifest path as `skills/$name/SKILL.md` — for catalog-driven refactor we need to compute the source root from `files[0]` (assuming it's the SKILL.md) OR introduce a `source_dir` catalog field. Trade-off: implicit-by-convention vs. explicit-by-schema. | Resolved during S000013 ARCHITECTURE phase: pick one. Recommended: derive from `files[0]` since SKILL.md is by convention always the first entry, and a `source_dir` field would duplicate information already encoded in `files[0]`. |
| `validate.sh` line 30 hardcodes `fail "$name is in catalog but skills/$name/SKILL.md does not exist"` — replace with a check against the catalog's resolved SKILL.md path. | Resolved during S000013 ARCHITECTURE phase. |
| Some downstream consumer (a script, a doc) might `grep` for `"skills/company-workflow"` in `skills-catalog.json` or in test fixtures and break post-move. | T000014 verification: `./scripts/test.sh` end-to-end on the feature branch is the canary. Initial grep showed `scripts/skills-deploy` and `scripts/generate-readme.sh` are catalog-driven (no hardcoded refs). |
| Mirror invariant byte-check could regress silently if `MIRROR_SPECS` retargeting has a typo. Validate Error check 10 explicitly with byte-identity verification before merge. | T000014 test-plan includes a step: `./scripts/validate.sh` must report Error check 10 PASS with all 7 mirror entries verified. |
| Pre-existing installs of `company-workflow` (from `--include-deprecated` runs before this feature) will still be at `~/.claude/skills/company-workflow/`. The new install path is unchanged (still `~/.claude/skills/company-workflow/`); only the source path on disk changes. Confirm idempotency. | T000014 test-plan: install once with `--include-deprecated`; run again; verify no-op (already installed). |

## Definition of done

- [ ] `skills/` and `templates/` no longer contain `company-workflow/`
- [ ] `deprecated/company-workflow/` contains the full skill source incl. `templates/` subdir; `deprecated/README.md` exists
- [ ] `skills-catalog.json` `files[]` and `templates[]` for `company-workflow` reference `deprecated/company-workflow/...`
- [ ] `scripts/skills-deploy` line 260 + 278 derive paths from catalog (no hardcoded `skills/{name}/`)
- [ ] `scripts/validate.sh` MIRROR_SPECS retargeted; catalog walker + orphan check honor catalog paths
- [ ] `scripts/test.sh` uses `COMPANY_PATH` / `COMPANY_TPL` constants; ~40 path replacements applied
- [ ] `CLAUDE.md` references updated (3 lines); new `deprecated/` convention documented
- [ ] `README.md` regenerated
- [ ] `./scripts/validate.sh` PASS (Error check 10 byte-identity verified)
- [ ] `./scripts/test.sh` PASS (Failures: 0)
- [ ] `scripts/skills-deploy install` clean-target verification: skips `company-workflow` (1 WARN line); `--include-deprecated` installs from new path; `doctor` reports INFO
- [ ] PR shipped via `/ship` + `/land-and-deploy`

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Removing `skills/company-workflow/` from the repo entirely — moving, not deleting.
- Refactoring `personal-workflow/` or `system-health/` to use catalog-driven path lookup — both active, live at the conventional `skills/{name}/`. The catalog-driven refactor benefits any future move but only company-workflow exercises the new behavior today.
- Eliminating the `templates/` top-level directory — `personal-workflow/` templates and `doc-SKILL-DESIGN.md` still live there.
- Changing SKILL.md frontmatter of company-workflow — same stance as F000005's out-of-scope.
- Auto-uninstalling a previously-installed company-workflow on the next `install` run — users own removal via `skills-deploy remove`.
- Eliminating the work-copilot byte-mirror entirely (e.g., reference-at-deploy instead of duplicate files) — bigger architectural change, separate feature if/when needed.
- Adding an `archived` tier beyond `deprecated` — premature.

## Pointers

- Parent tracker: [F000006_TRACKER.md](F000006_TRACKER.md)
- Roadmap: [F000006_ROADMAP.md](F000006_ROADMAP.md)
- Source design (office-hours): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260502-015311.md` (Status: APPROVED)
- Predecessor feature: [F000005_deprecated_skill_status](../F000005_deprecated_skill_status/F000005_TRACKER.md) — shipped the deprecation lifecycle in v1.2.0; this feature is the directory-shape follow-up F000005 explicitly deferred via Out-of-Scope.
- Sibling feature whose mirror invariant constrains this work: [F000004_work_copilot](../F000004_work_copilot/F000004_TRACKER.md) — `validate.sh` Error check 10's `MIRROR_SPECS` array enforces byte-identity sync; this feature retargets all 7 source paths.
- Relevant scripts: `scripts/skills-deploy`, `scripts/validate.sh`, `scripts/test.sh`, `scripts/generate-readme.sh`, `scripts/copilot-deploy.py`
- Relevant catalog: `skills-catalog.json`
