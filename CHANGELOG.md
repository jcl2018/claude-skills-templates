# Changelog

All notable changes to this collection will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).




## [1.7.0] - 2026-05-08

New `/scaffold-work-item` skill — first of three pipeline skills automating the gap between `/office-hours` and `/ship` in the personal-workflow lifecycle. Takes a design-doc path, produces a compliant work-item directory tree per WORKFLOW.md scaffolding rules. Reads templates + manifest + WORKFLOW.md as runtime sources of truth; runs `/personal-workflow check` at boundaries; idempotent (re-run on same input is NO-OP). Bootstrap-validated by re-scaffolding F000010 itself via the new skill — proof revealed and fixed a real bug in the user-story DESIGN.md section instructions before shipping.

### Added

- **`/scaffold-work-item`** — new LLM-driven skill that scaffolds a personal-workflow work item from an `/office-hours` design doc. Status: `experimental`. Depends on `personal-workflow` (templates + manifest + WORKFLOW.md). Three files: `skills/scaffold-work-item/SKILL.md` (entry point: preamble, path resolution, usage, error handling) + `skills/scaffold-work-item/scaffold.md` (13-step logic: input validation, design-doc parsing, type detection from branch with AskUserQuestion fallback, ID generation, slug derivation, component grouping, multi-story decomposition with AskUserQuestion confirmation, idempotency check, write tree, boundary check at end, optional SCAFFOLDED footer append) + `skills/scaffold-work-item/fixtures/README.md` (F000010 as canonical fixture; manual snapshot-diff workflow).
- **`work-items/features/personal-workflow/F000010_pipeline_skills/`** — feature work item for the three-skill pipeline (scaffold + implement + qa). Hand-scaffolded as the bootstrap, then validated by re-scaffolding via the new skill itself. Contains feature-level TRACKER + DESIGN + ROADMAP, plus 3 user-story children (S000017 scaffold-work-item, S000018 implement-from-spec, S000019 qa-work-item) each with TRACKER + DESIGN + SPEC + TEST-SPEC. S000017 is Phase 2 complete (this PR); S000018 + S000019 remain Phase 1 for follow-up.

### Changed

- **`TODOS.md`** — added P3/M deferred entry: `/personal-pipeline` orchestrator wrapping the three pipeline skills (Approach B from office-hours). Decision deferred until S000017+S000018+S000019 ship and have been used on real work items for 2+ weeks.

### Notes

- The Phase 1 design (`~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`) was produced via `/office-hours` and refined via `/plan-eng-review`. Eng review surfaced 4 substantive issues, all addressed before scaffolding: idempotency premise (1.1A), work-item granularity (1.2A — scaffold full tree; implement/QA at user-story level only), boundary validation premise (1.3A — every skill calls `/personal-workflow check` at start AND end), and one golden fixture per skill (3.1A).
- Bootstrap proof was non-trivial: a fresh-context Agent subagent acted as `/scaffold-work-item` against F000010's design doc; the diff against the hand-scaffolded baseline revealed 3 user-story DESIGN.md files producing 3 sections instead of the 7 required by `doc-DESIGN.md`. Root cause: `scaffold.md` Step 10 "brief stub" instruction was too permissive. Fixed in this PR: instruction now explicitly requires all 7 sections (content can be brief, structure cannot be omitted). Logged as the `brief-stub-ambiguity` pitfall learning (confidence 9/10).
- v1 ships with manual fixture-based testing per Step 0A choice during eng review. Behavioral eval harness (TODOS.md P1) deferred until after the three skills ship and the per-skill pattern is stable.

## [1.6.1] - 2026-05-08

Documentation hygiene: removed the dormant top-level `TODO.md` (last touched 2026-04-10 in v1.4.x era, 37 lines, all items already DONE-marked). The active list lives in `TODOS.md` — having both files alongside each other was confusing for anyone navigating the repo. The DONE history is preserved in git log.

### Removed

- **`TODO.md`** — legacy file consolidated. `TODOS.md` is the single source of truth for open and completed work. No content was lost; all items in `TODO.md` were already DONE-marked when retired.

### Notes

- No code, manifest, or skill changes. Pure repo cleanup.
- No references to `TODO.md` anywhere in the repo (verified by grep) — removing it doesn't break any docs or scripts.

## [1.6.0] - 2026-05-08

Update-nudge mechanism so consumers on other machines learn when a new collection version ships. Models gstack's pattern: each instrumented skill's preamble runs a check; if `origin/main` has a newer `VERSION` than what's installed, the user sees a `SKILLS_UPGRADE_AVAILABLE 1.5.3 → 1.6.0` banner and is prompted to Upgrade now / Snooze 24h / Skip this version. Upgrade runs `git pull --ff-only && skills-deploy install --from-upgrade <old>` from the user's clone, then the next skill invocation prints `SKILLS_JUST_UPGRADED 1.5.3 → 1.6.0` once. Closes the gap where users only learned about new versions by happening to `git pull`.

### Added

- **`scripts/skills-update-check`** — new ~280 LOC bash script. Default action emits banners; subcommands `--snooze [hours]`, `--skip <version>`, `--prompted <session>`, `--should-prompt <session>` let skill bodies update cache state without writing JSON themselves. Reads installed version from `manifest.collection_version` (catches "pulled but didn't reinstall"); reads remote from `git show origin/main:VERSION` after a 24h-cached `git fetch`. Reuses `version_gte` from `scripts/lib.sh` for semver compare; atomic cache writes via `mktemp` + `mv`; defensive numeric guards on every cache field consumed in arithmetic so a corrupted cache can't crash the silent preamble.
- **`scripts/skills-deploy install --from-upgrade <version>`** flag — when set, writes `~/.claude/.skills-templates-just-upgraded` after a successful install. The next `skills-update-check` invocation reads, unlinks, and emits the `SKILLS_JUST_UPGRADED` line once.
- **`skills-deploy doctor`** — surfaces `Update check:` section: last-check timestamp (portable BSD/GNU date), cached local/remote versions, snooze-until time, skipped versions. Also flags a missing `manifest.source` path (e.g., user deleted their clone) as FAIL with recovery hint.
- **`skills/personal-workflow/SKILL.md`** — `AskUserQuestion` added to `allowed-tools`; preamble snippet runs the check; `## Update Nudge Handling` section instructs how to react to banners (parse, debounce via `--should-prompt`, branch-state precondition, three-option AskUserQuestion, call `--snooze`/`--skip`/`--prompted`).
- **`skills/system-health/SKILL.md`** — same preamble snippet + `## Update Nudge Handling` block. `AskUserQuestion` was already in its allowed-tools.
- **`scripts/test-deploy.sh`** — 28 new tests (U1–U28): subcommand semantics, atomic-write debris check, marker round-trip, E2E with a temp git fixture verifying banner emission / cache TTL / snooze / skip / source-deleted silent / marker emit-and-unlink. Plus the `--from-upgrade` flag's three branches (missing value rejected, non-semver rejected, marker written) and doctor's cache surface (populated + never-run).

### Changed

- **`.github/workflows/validate.yml`** — `shellcheck` step now covers `scripts/skills-deploy` and `scripts/skills-update-check` (the existing `scripts/*.sh` glob misses them — both lack the `.sh` extension). Closes a CI gap that pre-dated this PR.
- **`scripts/test-deploy.sh`** — `SKILL_COUNT` now excludes `status: deprecated` catalog entries to mirror what `skills-deploy install` actually deploys (was over-counting, hid pre-existing test failures). Tests that intentionally install `company-workflow` now pass `--include-deprecated` explicitly. Pre-existing template-ownership tests (T2/T4–T7) are still failing — they reference a flat `doc-RCA.md` that no longer exists at the top level (subfoldered to `company-workflow/doc-RCA.md` in v1.3.x). Out of scope for this PR; tracked for follow-up.
- **`CLAUDE.md`** — `## Scripts reference` table gains a row for `skills-update-check`; new `## Update-check mechanism (F000009)` section documents the state files (`.skills-templates.json`, `.skills-templates-update.json`, `.skills-templates-just-upgraded`), the manual-override path (`rm` the cache), and the in-snippet path-resolution shape.

### Notes

- **Not in scope:** Copilot-bundle (`work-copilot/`) consumers — they have no preamble surface; defer until there's a real signal anyone wants it. Fork-aware detection (fall back to `upstream/main` when `origin/main` is missing) — tracked as a follow-up.
- **Acknowledged limitation:** preamble auto-runs `$source/scripts/skills-update-check` based on `manifest.source`. A user who can write to `~/.claude/.skills-templates.json` can redirect every skill invocation to attacker-controlled code. Same trust boundary already applies to all installed skills (deployed via skills-deploy from this manifest); the update check doesn't enlarge the attack surface beyond what's already there. Pinning the `origin` URL would tighten the upgrade path; deferred.
- **Pre-existing template-ownership tests** in `scripts/test-deploy.sh` (T2/T4–T7) still fail. They were already broken on `main` (the SKILL_COUNT fix made them visible by un-masking the run path). Tracked as a follow-up.

## [1.5.3] - 2026-05-07

Documentation hygiene: the Scripts table in `README.md` and the matching reference in `CLAUDE.md` had drifted from the actual contents of `scripts/`. Five entries described scripts that no longer exist (`skill-design.sh`, `create-skill.sh`, `skill-check.sh`, `skill-version.sh`, `skill-ship.sh`) and five real scripts were missing (`skills-deploy`, `setup.sh`, `test-deploy.sh`, `collection-version.sh`, `copilot-deploy.py` in README; `skills-deploy`, `setup.sh`, `test-deploy.sh` in CLAUDE.md). The README's Quick Start block also pointed at the phantom `create-skill.sh`. The drift had survived multiple ships because the stale content lived inside `scripts/generate-readme.sh`'s hardcoded heredoc, so re-running the generator just re-emitted the same wrong table.

### Changed

- **`README.md`** and **`scripts/generate-readme.sh`** — Scripts table reflects actual repo contents (was: 5 phantom scripts, missing 5 real ones). Quick Start block drops the phantom `./scripts/create-skill.sh my-new-skill` line; new-skill creation is manual per CLAUDE.md.
- **`CLAUDE.md`** — Scripts reference table adds `setup.sh`, `skills-deploy`, and `test-deploy.sh` (was missing the workhorse installer plus its bootstrap and test driver).

### Notes

- No skill, manifest, or behavioral changes — pure documentation sync. `skills-catalog.json`, all SKILL.md versions, and per-skill manifests are untouched.
- No tracker work item filed; the change is a single-PR doc reconciliation that doesn't merit a TRACKER + RCA + test-plan triple.
- The drift *mechanism* (hardcoded heredoc) remains. This PR fixes the current snapshot, not the structural cause — the next script add/rename/delete can re-introduce the same drift. A follow-up to derive the table from `ls scripts/` (or to add a `validate.sh` check that asserts the heredoc table covers every executable in `scripts/`) is the right next step; out of scope here.

## [1.5.2] - 2026-05-07

`skills-deploy install` now overwrites drifted templates and rules by default — running it after a workbench pull just makes `~/.claude/` match source, no flag required. The previous safe-by-default behavior (skip on checksum mismatch, log a WARN) inverted the realistic mental model: every routine deploy hit the warning and had to be retried with `--overwrite`. The post-merge git hook from D000013 already passed `--overwrite` unconditionally, so the automation had quietly concluded the same thing. Closes D000015.

### Changed

- **`scripts/skills-deploy`** — default install now overwrites drifted templates and rules. Renamed log line `OVERWRITE: ... (--overwrite used)` → `UPDATE: ... (checksum differs)`. The old WARN-and-skip path is reachable via the new `--no-overwrite` flag, where it now logs `PRESERVE: ... (--no-overwrite, keeping deployed copy)`. The doctor reset hint and `install --help` text are updated to match.
- **`CLAUDE.md`** — "Template deployment" bullet rewritten to document the new default and the `--no-overwrite` opt-out.
- **`scripts/test-deploy.sh`** — Test T6 split into three sub-cases asserting the new default-overwrites behavior, the `--no-overwrite` opt-out, and the legacy `--overwrite` no-op compat.

### Added

- **`scripts/test.sh`** — D000015 regression block (6 grep checks): default value, `--no-overwrite` handler, legacy `--overwrite` tolerance, removal of stale WARN copy, help-text update, CLAUDE.md sync.
- **`work-items/defects/ops/skills-deploy/D000015_skills_deploy_install_overwrite_default/`** — defect work item (TRACKER + RCA + test-plan).

### Notes

- `--overwrite` is retained as a tolerated no-op so D000013's post-merge git hook (which still passes the flag unconditionally) continues to work without modification. The flag can be retired in a future cleanup; no urgency.
- Live smoke test: drift → default install → `UPDATE`; drift → `--no-overwrite` → `PRESERVE` (drift preserved); drift → legacy `--overwrite` → `UPDATE`. All three paths verified on `~/.claude/templates/personal-workflow/tracker-defect.md`.

## [1.5.1] - 2026-05-07

Adds a Phase 3 gate for `/document-release` to the feature tracker template — closes the loop on post-ship doc drift. The recent v1.5.0 ship surfaced one such drift (README skill table left at v2.0.0 after the manifest moved to v3.0.0); the new gate makes the post-merge audit an explicit checkbox instead of freelance hygiene. Feature trackers only — user-stories and tasks unchanged so atomic work doesn't pick up gate overhead.

### Changed

- **`templates/personal-workflow/tracker-feature.md`** — Phase 3 grows from 5 gates to 6: adds `[ ] /document-release — post-ship doc audit done; drifts fixed inline or spawned as D-tickets` and the matching numbered step.
- **`skills/personal-workflow/examples/example-tracker-feature.md`** — mirrors the new gate.
- **`skills/personal-workflow/fixtures/valid-feature-dir/F999999_TRACKER.md`** — mirrors the new gate so the fixture stays byte-aligned with the template.

### Notes

- No artifact set or manifest changes — purely additive content inside an existing tracker section. `personal-artifact-manifests.json`, `skills-catalog.json`, `template-registry.json`, and `SKILL.md` versions all stay at 3.0.0.
- Historical feature work items (F000001, F000002, F000004, F000005, F000006, F000008) are not retroactively migrated; they shipped under the 5-gate Phase 3 contract and remain valid as-is.

## [1.5.0] - 2026-05-07

Personal-workflow tracker re-cut. Replaces the old artifact set (feature-summary, PRD, ARCHITECTURE, milestones) with a workflow-mirrored set where every persistent doc maps 1:1 to a step the engineer actually runs: `DESIGN.md` from `/office-hours`, `SPEC.md` from the scaffolding step (was PRD + ARCHITECTURE merged), `ROADMAP.md` for feature-level scope and timeline (was feature-summary + milestones merged), `TEST-SPEC.md` for smoke + E2E. Tracker templates' Phase 3 surfaces smoke and E2E as separate gates instead of one collapsed "TEST-SPEC verified" check. WORKFLOW.md task-required rule relaxed: atomic user-stories may ship without task children. Single sweep PR migrates 13 historical work items + 1 fixture + all examples to the new shape.

### Added

- **`templates/personal-workflow/doc-SPEC.md`** *(new)* — user-story specification merging requirements (`### P0 (Must-Have)`, `### P1`, `### P2` sub-sections under `## Requirements`) with architecture decisions and tradeoffs. Replaces PRD + ARCHITECTURE.
- **`templates/personal-workflow/doc-ROADMAP.md`** *(new)* — feature roll-up: scope, non-goals, decomposition, delivery timeline (with `### Delivery History` sub-section to absorb shipped milestone history), dependency graph. Replaces feature-summary + milestones.
- **`work-items/features/personal-workflow/F000008_tracker_recut/`** — feature work item that drove the re-cut, decomposed into S000014 (templates + manifest + check.md), S000015 (historical migration), S000016 (examples + repo-level surfaces).

### Changed

- **`skills/personal-workflow/personal-artifact-manifests.json`** — bumped to `version: 3.0.0`. New artifact set: feature = TRACKER + DESIGN + ROADMAP (3); user-story = TRACKER + DESIGN + SPEC + TEST-SPEC (4); task and defect unchanged.
- **`skills/personal-workflow/SKILL.md`** — version bumped to 3.0.0.
- **`skills/personal-workflow/check.md`** — Step 18 cross-reference traceability rewritten: source filename `PRD.md` → `SPEC.md` (4 references at lines 303-329); 4 incidental `PRD`/`ARCHITECTURE` mentions updated for consistency (lines 84, 218, 220, 365); `## Test Matrix` legacy clause deleted (dead code post-v1.4.0 sweep). `### P0/P1/P2` sub-section parsing preserved — same logic, new source file.
- **`skills/personal-workflow/WORKFLOW.md`** — 8 surfaces updated: artifact-count list (lines 21-22), Step 2 narrative (lines 38, 41), Step 3 narrative (line 49), Type-to-Artifact Mapping table (lines 64-65), validation rule (line 190). Plus line 120: user-story task-required rule relaxed from "at least 1 task child" to optional with explicit atomic-story escape hatch (`[x] Tasks broken down (N/A — atomic story)`).
- **`templates/personal-workflow/tracker-feature.md`** + **`tracker-user-story.md`** — full rewrite. Adds `/office-hours` Prerequisite line above Phase 1; Phase 1 reordered to start from branch creation, then DESIGN distillation, then SPEC/ROADMAP scaffolding; Phase 3 expanded to 5 explicit gates (`/personal-workflow check`, smoke pass, E2E walked, `/ship`, `/land-and-deploy`).
- **`templates/personal-workflow/tracker-task.md`** — adds optional `/office-hours` Prerequisite block; no gate or section changes.
- **`templates/personal-workflow/doc-DESIGN.md`** — line 15 prose, line 71 cross-link comment, line 76 hard-coded `Milestones:` link rewritten to `Roadmap:`.
- **`templates/personal-workflow/doc-TEST-SPEC.md`** — frontmatter cross-references (`prd: PRD.md` + `architecture: ARCHITECTURE.md`) collapsed to single `spec: SPEC.md`; instructional comments updated PRD → SPEC throughout.
- **`skills-catalog.json`** — personal-workflow entry version 3.0.0; templates list drops 4 (doc-PRD, doc-ARCHITECTURE, doc-feature-summary, doc-milestones), adds 2 (doc-SPEC, doc-ROADMAP).
- **`template-registry.json`** — personal-workflow `doc_types` array updated; version bumped to 3.0.0.
- **`CONTRIBUTING.md`** lines 44-45 and **`PHILOSOPHY.md`** lines 25, 42, 43 — narrative references PRD/ARCHITECTURE/feature-summary/milestones swept to SPEC/ROADMAP/DESIGN where active.
- **`scripts/test.sh:594-606`** — D000012 deployed-template guard loop split per-workflow: personal-workflow iterates `[doc-DESIGN, doc-SPEC, doc-ROADMAP]`; company-workflow keeps `[doc-DESIGN, doc-feature-summary]` (deprecated, byte-mirror source). Plus template-count assertion at line 299 updated 12 → 10.
- **`scripts/test-deploy.sh`** — canary template name swapped from `doc-PRD.md` to `doc-RCA.md` (19 references); manual line-414 path correction adds `personal-workflow/` subdir.
- **5 historical features migrated** (F000001, F000002, F000004, F000005, F000006): feature-summary + milestones consolidated into ROADMAP per item; existing DESIGN cross-links rewritten; old files deleted. Each ROADMAP includes the canonical 7 v3 sections + `### Delivery History`.
- **8 historical user-stories migrated** (S000001, S000006, S000007–S000010, S000012, S000013): PRD + ARCHITECTURE consolidated into SPEC per item; new DESIGN.md stub written per item (predates the v3 convention); TEST-SPEC frontmatter migrated; old files deleted. SPEC files preserve PRD's `### P0/P1/P2` sub-sections inside `## Requirements`.
- **F000008's three child user-stories** (S000014, S000015, S000016) self-migrated as part of the sweep with the same per-item recipe.
- **Sibling tracker Phase 1 lifecycle text refreshed** (F000001/F000004/F000005/F000006/F000008) to reference v3 templates (DESIGN, SPEC, ROADMAP) instead of deleted v2 templates.
- **Examples**: `example-doc-SPEC.md` and `example-doc-ROADMAP.md` (new, Reading List CLI consistent); `example-tracker-feature.md` and `example-tracker-user-story.md` rewritten to mirror the new tracker shapes.
- **Fixtures**: `valid-feature-dir/` rewritten to match the v3 manifest (TRACKER + DESIGN + ROADMAP).

### Removed

- **`templates/personal-workflow/doc-PRD.md`**, **`doc-ARCHITECTURE.md`**, **`doc-feature-summary.md`**, **`doc-milestones.md`** — replaced by SPEC + ROADMAP.
- **`example-doc-PRD.md`**, **`example-doc-ARCHITECTURE.md`**, **`example-doc-feature-summary.md`**, **`example-doc-milestones.md`** — corresponding examples.

### Why workflow-mirrored

The old artifact set framed itself around document types as nouns (PRD, ARCHITECTURE, feature-summary, milestones). The new set frames artifacts around the workflow step that produces them: `/office-hours` produces DESIGN, scaffolding produces SPEC + ROADMAP, the engineer running smoke + E2E produces TEST-SPEC content. Reading the artifact list now answers "where does this come from?" without a separate map.

### Open questions deferred

- Sibling-tracker drift in pre-existing migrated content (S000010_SPEC.md inline references to deleted PRD/ARCHITECTURE filenames, F000004_DESIGN.md links to repo paths deleted by F000006 in v1.3.x). Both are documentation-quality issues in sealed historical content; the validator passes (Step 16 only checks section headers + frontmatter, not body prose). Better suited to a separate content-polish pass.
- Mirroring the v3 shape to `deprecated/company-workflow/templates/` and `work-copilot/` byte-mirror sources is intentionally deferred (deprecated, sealed).

### Migration notes

- The catalog version bump triggers a `skills-deploy install --overwrite` requirement on existing user installs. The /ship validator's D000012 guard catches drift but does not auto-fix.
- Validator ran `/personal-workflow check` against the migrated `work-items/` tree; structural compliance (Step 16) PASS for all 14 migrated items.

## [1.4.0] - 2026-05-05

Personal-workflow TEST-SPEC template restructure. Drops the redundant Test Matrix + Test Tiers shape and replaces it with two compact tables — Smoke Tests and E2E Tests — distinguished by who edits them and when they run. Smoke tests are automated regression that lives in CI; E2E tests are manual user-scenario verification done before /ship. Soft cap of 5 rows per tier acts as a forcing function to pick the tests that prove the story works rather than tests that demonstrate completeness. The validator (`/personal-workflow check`) gets stricter: Step 18 traceability scans the new tier tables for AC values with a placeholder-filter to prevent freshly-scaffolded files from silently passing, a new Step 18.5 emits an `[INFO]` cap-advisory when either tier exceeds 5 rows, and Step 20's template badge ladder picks up `INFO` between `PASS` and `WARN` so cap-advisory signals route to the right column.

### Changed

- **`templates/personal-workflow/doc-TEST-SPEC.md`** — three top-level sections only: `## Smoke Tests`, `## E2E Tests`, `## Coverage Gaps`. Both tier tables include an AC column for PRD↔test traceability. Soft 5-row cap stated in template comments.
- **`skills/personal-workflow/check.md` Step 18** — replaces the `## Test Matrix` AC scan with a unified scan over `## Smoke Tests` + `## E2E Tests` AC columns, filters out the literal `AC-{n}` template placeholder so unfilled scaffolded files correctly flag as `[UNTESTED]`, and runs P0 + P1/P2 loops over a single shared `ac_set`. No legacy fallback — files that still use `## Test Matrix` fail Step 16's section check at the source.
- **`skills/personal-workflow/check.md` Step 18.5** *(new)* — emits `[INFO]` cap-advisory when Smoke or E2E row count exceeds 5. Row counting uses regex `^\s*\|.*\|\s*$` between heading and next `## ` header, minus 2 for the markdown header + separator rows.
- **`skills/personal-workflow/check.md` Step 20** — extends the **template** badge severity ladder to `PASS < INFO (cap-advisory) < WARN (EXTRA sections) < DRIFT < MISSING`. Traceability ladder unchanged.
- **`scripts/test.sh:107-117`** — replaces the dormant `## Test Matrix` grep with a loop that requires both `## Smoke Tests` AND `## E2E Tests` for any `docs/<skill>/TEST-SPEC.md` file. Pattern matches the surrounding feature-summary.md check.
- **`skills/personal-workflow/examples/example-doc-TEST-SPEC.md`** — re-synced to the new template shape using the reading-list-CLI domain. 5 smoke + 5 E2E rows, AC-mapped.
- **`skills/personal-workflow/examples/example-doc-test-plan.md`** — re-synced to the (unchanged) existing test-plan template. Closes a long-standing example/template drift.
- **8 historical TEST-SPEC.md files swept** to the new shape: `S000001` (workflow_implementation), `S000006` (personal_workflow_port), `S000007`–`S000010` (work-copilot subfeatures), `S000012` (deprecated_status_semantics), `S000013` (relocate_with_catalog_driven_paths). Each file consolidated to ≤5 rows per tier where natural; AC values converted from `Story #N` / `Story N` formats to `AC-N` for validator traceability. S000001's pre-existing `## Coverage Notes` heading was renamed to `## Coverage Gaps` to match the (unchanged-named) template section.

### Why two tiers, distinguished by editor

The old tier model (Test Matrix + Tier 1 Smoke + Tier 2 E2E as h3 children of `## Test Tiers`) framed the split around static-vs-dynamic execution. The new model frames it around the engineer's relationship to the tests: smoke = automated regression you write once and never touch, E2E = manual user-scenario verification you sit down and run before ship. That cognitive split shows up in the file as separate top-level sections so it's visible at a glance, not buried in a `Type` column.

### Validator behavior on legacy files

The 2 deprecated test-specs at `deprecated/work-items/features/F000003_company_workflow/{S000003,S000004}/` are not walked by the validator (Step 14 walks `./work-items/` only, not `deprecated/`). They retain the old Test Matrix shape and stay as frozen historical artifacts.

### Open question deferred

Mirroring this restructure to `templates/company-workflow/doc-TEST-SPEC.md` (and the byte-mirrored copies under `work-copilot/`) is intentionally deferred to a follow-up F-level work item per the design doc default. Touching company-workflow means coordinating template + reference + philosophy + example + 4 byte-mirror sources.


## [1.3.3] - 2026-05-05

Refines v1.3.2's grouping into a two-axis split: **skills** (per-subfolder for actual deployable skills) vs **ops** (umbrella for everything else — deprecation lifecycle, deploy tooling, ship workflow, generic workflow defects). The directory now reads as a clean taxonomy: if it's a skill, find it under its own name; if it's not, find it under `ops/`.

### Changed
- **`work-items/features/deprecation/`** → **`work-items/features/ops/deprecation/`** (F000005 + F000006).
- **`work-items/defects/skills-deploy/`** → **`work-items/defects/ops/skills-deploy/`** (D000005, D000013).
- **`work-items/defects/ship/`** → **`work-items/defects/ops/ship/`** (D000008).
- **`work-items/defects/workflow/`** → **`work-items/defects/ops/workflow/`** (D000001, D000002, D000007, D000014).

Skill subfolders (`personal-workflow/`, `system-health/`, `work-copilot/`) are unchanged. Same `git mv` blame-preservation rule + same hands-off policy on cross-references in completed trackers.

### Final shape

```
work-items/
├── features/
│   ├── personal-workflow/F000001
│   ├── system-health/F000002
│   ├── work-copilot/F000004
│   └── ops/
│       └── deprecation/{F000005, F000006}
└── defects/
    ├── personal-workflow/{D000009, D000012}
    ├── work-copilot/{D000010, D000011}
    └── ops/
        ├── skills-deploy/{D000005, D000013}
        ├── ship/{D000008}
        └── workflow/{D000001, D000002, D000007, D000014}
```

### Notes for contributors
- Future per-skill work (a new defect for personal-workflow, a feature for system-health) lands under the skill's existing subfolder.
- Future ops work (a new tooling category, a new lifecycle arc beyond deprecation) lands under `ops/{new-category}/`.
- `validate.sh`'s manifest reconciliation walk uses `find -type f` recursively, so the new depth (`work-items/{features,defects}/ops/{category}/{F-or-D}/`) is handled without script changes.

## [1.3.2] - 2026-05-05

Pure tree reorganization. Active features and defects in `work-items/` are now grouped into subject-component subfolders so the directory tree scales as more work items land. No content changes; `git mv` preserved blame for all files.

### Changed
- **`work-items/features/`** — 5 features grouped into 4 subfolders:
  - `personal-workflow/F000001_personal_workflow`
  - `system-health/F000002_system_health`
  - `work-copilot/F000004_work_copilot`
  - `deprecation/F000005_deprecated_skill_status` + `deprecation/F000006_relocate_deprecated_skills` (cross-cutting deprecation lifecycle arc)
- **`work-items/defects/`** — 11 defects grouped into 5 subfolders:
  - `personal-workflow/` — D000009, D000012
  - `work-copilot/` — D000010, D000011
  - `skills-deploy/` — D000005, D000013
  - `ship/` — D000008
  - `workflow/` — D000001, D000002, D000007, D000014 (generic workflow lifecycle/template defects that span multiple skills)

### Notes for contributors
- `deprecated/work-items/` is intentionally left flat — all contents are about the one deprecated skill (`company-workflow`), so sub-grouping there is redundant. If a second skill ever gets deprecated, the same per-component subfolder pattern will apply there too.
- Cross-references in completed work-item trackers and historical CHANGELOG entries point at the OLD flat paths. Same rule as F000007: frozen historical prose isn't updated. Unique IDs (D-numbers, F-numbers) resolve cross-references via either path.
- `validate.sh`'s manifest reconciliation walk uses `find -type f` recursively, so the new depth isn't a problem — no script changes needed.
- The `ship/` subfolder is a singleton today (D000008 only) but will absorb future ship-related defects without re-organization, matching the F000006 principle: name the subject explicitly so future entries know where to land.

## [1.3.1] - 2026-05-05

F000007 finishes the deprecation lifecycle by relocating the work-item history for
the deprecated `company-workflow` skill. F000005 made the catalog skip-on-install,
F000006 moved the skill source out of `skills/`, and F000007 moves the four
work-item directories whose primary subject is `company-workflow` to a new
`deprecated/work-items/` parent. `work-items/` now contains only active feature
and defect history; chronological IDs are preserved so cross-references in
CHANGELOG and other historical artifacts remain readable.

### Changed
- **`work-items/features/F000003_company_workflow/`** → **`deprecated/work-items/features/F000003_company_workflow/`** (the company-workflow feature itself, with TRACKER + DESIGN + feature-summary + milestones + nested user-story).
- **`work-items/defects/D000003_company_workflow_feature_artifact_duplication/`** → `deprecated/work-items/defects/`.
- **`work-items/defects/D000004_company_workflow_contract_template_drift/`** → `deprecated/work-items/defects/`.
- **`work-items/defects/D000006_company_workflow_test_verification_gates/`** → `deprecated/work-items/defects/`.
- **`scripts/validate.sh` Error check 4 (orphan check):** `deprecated/` is now allowed to host non-skill subtrees. The check still flags any directory under `skills/` without a catalog entry (the zzz-test-orphan regression case still trips), but under `deprecated/` it only inspects dirs that contain a `SKILL.md` or are claimed by a catalog entry. `deprecated/work-items/` is a sibling concept to `deprecated/{name}/` skill sources, not an orphan.
- **`deprecated/README.md`:** documents the `deprecated/work-items/` convention alongside the existing skill-source-of-truth note. Includes the rule-of-thumb: when deprecating another skill, move its primary work-item directories (the feature itself + any defects whose primary subject is this skill) here too.

### Notes for contributors
- D000007 (`workflow_template_single_source_of_truth`) was deliberately NOT moved — it was generic single-source-of-truth principle work that landed alongside the company-workflow refactor and ALSO refactored personal-workflow templates. Moving it would imply the principle is deprecated, which it isn't. Same logic for D000005, D000008, D000010-D000014: each is generic-tooling work that happened to surface on company-workflow but isn't *about* it.
- F000004 (work-copilot) stays active. The Copilot bundle is the live consumer of `deprecated/company-workflow/` via byte-mirror; the feature itself is still in production.
- Cross-references in completed work-item trackers (D000007, D000009) and historical CHANGELOG entries point at the OLD `work-items/...` paths. These are not updated — they're frozen historical prose describing past work, and revising them would be revisionist editing of the record. The chronological IDs (F000003, D000003, D000004, D000006) stay unique across both `work-items/` and `deprecated/work-items/`, so future cross-references can use either path or just the ID.

## [1.3.0] - 2026-05-05

F000006 finishes the deprecation lifecycle that F000005 started. Where F000005
made `skills-deploy install` skip deprecated skills, this release moves the
source files out of `skills/` entirely so the directory contains only deployable
skills. `company-workflow` now lives at `deprecated/company-workflow/` (with its
templates as a sub-directory) and consumer scripts derive paths from the catalog
instead of hardcoding `skills/{name}/`. Future relocations are a one-line catalog
change.

### Added
- **Top-level `deprecated/` directory.** Source-of-truth for skills marked
  `status: deprecated` in the catalog. Contents are NOT deployable skills —
  they stay in the repo because byte-mirrored bundles (e.g. `work-copilot/`)
  reference them as upstream truth, enforced by `validate.sh` Error check 10's
  `MIRROR_SPECS` array. `deprecated/README.md` explains the convention.
- **Optional `templates_source` catalog field** for skills whose templates live
  outside the default `templates/{name}/` shape. When set, `skills-deploy` and
  `validate.sh` resolve template SRC paths via `$REPO_ROOT/$templates_source/
  $(basename $tpl)`; DST paths under `~/.claude/templates/{skill}/` are
  unchanged, so user-visible install locations stay the same.
- **Catalog-driven path helpers** in three scripts. `scripts/skills-deploy`,
  `scripts/validate.sh`, and `scripts/test.sh` each gained `skill_md_path`,
  `skill_source_dir(_abs)`, and (where relevant) `skill_templates_source`
  helpers that read paths from the catalog's `files[]` and `templates_source`
  fields. The `SKILLS_SRC` constant is gone — skills can live anywhere the
  catalog points.

### Changed
- **`skills/company-workflow/` → `deprecated/company-workflow/`** (53 files).
  `git mv` preserved blame history. The skill is still installable via
  `skills-deploy install --include-deprecated`; the destination path under
  `~/.claude/skills/company-workflow/` is unchanged.
- **`templates/company-workflow/` → `deprecated/company-workflow/templates/`**
  (14 templates). Co-located with the skill; `templates/` top-level now contains
  only `personal-workflow/` and `doc-SKILL-DESIGN.md`.
- **`scripts/skills-deploy`:** `discover_skills()` iterates the catalog instead
  of walking `skills/*/`; `do_install`, `do_relink`, and `do_doctor` derive the
  source directory from `dirname(catalog files[0])` (relink + doctor read the
  manifest's `path` field, with a fallback to the legacy shape for older
  installs). The templates loop honors `templates_source` overrides.
- **`scripts/validate.sh`:** MIRROR_SPECS source paths retargeted to
  `deprecated/company-workflow/...`; orphan check (Error check 4) extended to
  walk both `skills/` and `deprecated/`; catalog walker (Error check 1/2) reads
  SKILL.md path from the catalog; orphan-template walker (Warning check 3)
  walks both default and override template directories. `declare -A` avoided
  for bash 3.2 portability on macOS.
- **`scripts/test.sh`:** introduces `COMPANY_PATH` and `COMPANY_TPL` constants
  near the top; ~40 hardcoded `skills/company-workflow` and `templates/
  company-workflow` references replaced. The next relocation, if any, is a
  one-line edit instead of a search-and-replace pass.
- **`scripts/doctor.sh`:** version-staleness check reads the SKILL.md path from
  catalog `files[0]` instead of hardcoding `skills/{name}/SKILL.md`. Was
  silently skipping the check for any catalog entry whose source had moved.
- **`template-registry.json`:** `company-workflow` paths point at
  `deprecated/company-workflow/...`. Currently no script consumes these fields
  at runtime, but the registry is documentation that should match reality.
- **`CLAUDE.md`:** path references updated; new "Deprecated skills convention"
  subsection documents the catalog-driven shape.
- **`README.md`:** regenerated; rendered output unchanged from v1.2.0 (the
  generator reads catalog metadata, not paths).

### Verified
- `./scripts/validate.sh` PASS (0 errors, 0 warnings); Error check 10 byte-
  identity verified for all 7 `MIRROR_SPECS` entries at the new source paths.
- `./scripts/test.sh` PASS (Failures: 0); the path-constants refactor surfaced
  19 latent failures that `test.sh` had been silently masking — all fixed.
- T000014's 6 regression cases on a fresh `SKILLS_DEPLOY_TARGET`: default
  install skips with 1 WARN, `--include-deprecated` installs from the new path
  (manifest path field reflects `deprecated/company-workflow/SKILL.md`),
  doctor reports INFO, idempotent re-install no-op, relink + doctor walk the
  new source dir cleanly with 16 OK lines for templates.

### Notes for contributors
- To deprecate another skill in the future: flip its catalog `status` to
  `deprecated`, `git mv skills/{name}/` → `deprecated/{name}/`, set
  `templates_source: "deprecated/{name}/templates"` if the skill has templates,
  and update any `MIRROR_SPECS` source paths. The consumer scripts honor the
  catalog automatically.
- Pre-existing `WARN: templates source missing at .../skills/templates` from
  `skills-deploy relink` is unchanged by this PR — `templates` is a templates-
  only catalog entry that has no skill directory; the WARN was there before
  F000006 and is out of scope.

## [1.2.0] - 2026-05-02

F000005 introduces a `deprecated` skill status so retired skills can stay in the
repo as upstream truth (e.g. for byte-mirrored bundles like `work-copilot/`)
without being pushed onto fresh machines. `skills-deploy install` skips them with
a single warning by default; `--include-deprecated` is the explicit opt-in. First
migration: `company-workflow`, superseded by the GitHub Copilot bundle (F000004)
on the Windows work machine.

### Added
- **`status: deprecated` semantics in `skills-catalog.json` (S000012).** The
  `status` field is now a closed enum `{active, experimental, deprecated}`
  enforced by `scripts/validate.sh` (Error check 9b). Typos like `depricated`
  fail the build instead of silently behaving like a missing status.
- **`scripts/skills-deploy install --include-deprecated` flag.** By default,
  install skips deprecated skills with one warning per skipped skill
  (`WARN: skipping deprecated skill: <name> (use --include-deprecated to
  install)`); the flag is the explicit opt-in. Filter applies to both the skill
  loop and the templates loop, so a deprecated skill's templates are also
  skipped when the skill is.
- **`scripts/skills-deploy doctor` deprecated-aware reporting.** Deprecated
  skills are reported as `INFO`, never `WARN` — both
  `INFO: <name> — deprecated, not installed by default` (the expected state)
  and `INFO: <name> — deprecated, installed (--include-deprecated)` (when the
  user opted in). Doctor exit code unchanged.
- **`scripts/generate-readme.sh` separate "Deprecated" section.** Active and
  experimental skills render in the main table; deprecated skills appear under
  a labeled `### Deprecated` section with a one-line explanation, gated on
  count > 0 so the section disappears when no deprecations exist.

### Changed
- **`company-workflow` flipped to `status: deprecated`** in
  `skills-catalog.json` (T000013). Source files at `skills/company-workflow/`
  remain in-repo (the `work-copilot/` byte-mirror invariant in `validate.sh`
  Error check 10 requires them); only install/visibility is affected.

### Notes
- 100% backwards-compatible for active and experimental skills — install,
  doctor, remove, and README rendering behave identically for non-deprecated
  entries. Existing pre-deprecation installations of `company-workflow` are
  preserved (install only skips, never removes).


## [1.1.3] - 2026-05-01

D000014 closes two co-located coverage gaps from prior manifest changes that
D000012 + D000013 didn't address: WORKFLOW.md type-to-artifact tables drifted
behind the manifest (4 entries across both workflows), and the D000012 drift
block only iterated workbench → deployed (deployed-extras slipped through).
The new regression checks force WORKFLOW.md and the deployed templates dir
into bidirectional sync with the manifest source-of-truth.

### Fixed
- `skills/personal-workflow/WORKFLOW.md` — feature row + prose updated from
  "TRACKER + milestones (2 artifacts)" to "TRACKER + feature-summary + DESIGN +
  milestones (4 artifacts)" to match the manifest. AI scaffolding now reads the
  correct count.
- `skills/company-workflow/WORKFLOW.md` — feature row + prose 3 → 4 (added
  DESIGN); defect 3 → 4 and task 2 → 3 (both added PR-DESCRIPTION). `work-copilot/WORKFLOW.md`
  is byte-mirrored in lockstep per `MIRROR_SPECS`.

### Added
- `scripts/test.sh` D000012 block extended with a reverse-direction loop:
  every file in `~/.claude/templates/{workflow}/` must also exist in the
  workbench source. Catches stale templates left after a workbench removal.
  Tagged with `D000014 guard` in failure messages.
- `scripts/test.sh` new D000014 block: parses every type's required-array
  length from each manifest and grep's the `| <type> |` row count column from
  WORKFLOW.md. Mismatch fails CI with the workflow, type, and both counts.
  Manifest is authoritative; future manifest changes will fail this check
  until WORKFLOW.md is updated.

### Notes
- D000012 TRACKER's deferred items "WORKFLOW.md type-to-artifact tables" and
  "Deployed-extra detection" are now closed and cross-link D000014.
- Skipped: `skills-deploy install --prune` for auto-cleanup of deployed-extras.
  Test.sh detection + manual `rm` is enough for now; revisit if extras become
  common.

## [1.1.2] - 2026-05-01

D000013 skills-deploy auto-sync hook — closes D000012's deferred Option C2.
After re-running `./scripts/setup-hooks.sh`, every workbench `git pull` that
touches `templates/`, `skills/`, `skills-catalog.json`, or `rules/` automatically
re-runs `scripts/skills-deploy install --overwrite`. `~/.claude/templates/` is
ready before the next skill invocation needs it. Drift detection (D000012
regression block) stays in place as the safety net.

### Added
- `scripts/setup-hooks.sh` now installs a `post-merge` hook alongside the existing
  pre-commit hook. Hook filters `git diff-tree ORIG_HEAD HEAD` for deploy-relevant
  paths and silently no-ops on unrelated pulls. Per-machine, untracked, idempotent
  (re-running `setup-hooks.sh` rewrites both hooks).
- `scripts/test.sh` D000013 regression block (3 grep-level checks): `setup-hooks.sh`
  emits a post-merge hook block, that hook calls `skills-deploy install --overwrite`,
  and it filters on `templates/|skills/|skills-catalog.json|rules/`. Source-level
  verification only — does not fire the hook itself, so CI on non-deployed hosts
  passes cleanly.

### Notes
- **Bootstrap step on each clone:** run `./scripts/setup-hooks.sh` once after
  cloning (or after upgrading past v1.1.2) to install both hooks. Existing pre-commit
  installations are rewritten in place; no manual cleanup needed.
- C1 (symlink the deployed templates dir into the workbench checkout) was the
  alternative considered in D000012's RCA. Not implemented — revisit only if the
  workbench-must-exist constraint becomes a real problem.

## [1.1.1] - 2026-05-01

D000012 personal-workflow + company-workflow deploy drift — restores
`~/.claude/templates/{personal,company}-workflow/` to byte-match the workbench
source and adds a generic `scripts/test.sh` regression block so future workbench
template edits can't silently fall behind the deployed copy.

### Fixed
- `~/.claude/templates/personal-workflow/` and `~/.claude/templates/company-workflow/`
  now match the workbench source after running `scripts/skills-deploy install --overwrite`.
  Previously, `doc-DESIGN.md` (added in v0.13.1) and `doc-feature-summary.md` (added in
  v0.14.2) were missing from the deployed copy, plus `tracker-feature.md`,
  `tracker-user-story.md` (personal), `tracker-feature.md`, and `doc-milestones.md`
  (company) had drifted from workbench edits. Repos using personal-workflow or
  company-workflow from a non-workbench checkout now resolve every template the
  manifest declares.

### Added
- `scripts/test.sh` D000012 regression block (~50 lines) covering both workflows.
  Verifies (a) `skills-catalog.json` declares `doc-DESIGN.md` and `doc-feature-summary.md`
  for both workflows and (b) when `~/.claude/templates/{workflow}/` exists, every
  workbench template is byte-identical in the deployed copy. Skips with an INFO line
  on hosts where `skills-deploy` hasn't run (e.g. CI). Future workbench template edits
  without a re-deploy fail this check with a pointer to `scripts/skills-deploy install --overwrite`.

## [1.1.0] - 2026-04-27

F000004 work-copilot v2 realignment — closes the artifact-completeness gap
between `work-copilot/` and `skills/company-workflow/`. Same templates and
validator that shipped in v0.14.0, plus full procedural backbone, how-to guides,
rationale notes, example artifacts, and complete fixtures — all byte-identically
mirrored from upstream and CI-enforced.

### Added
- **Bundle artifact mirrors (S000010).** `work-copilot/` now ships `WORKFLOW.md`,
  `reference/guide-*.md` (7 files), `philosophy/rationale-*.md` (3 files),
  `examples/example-*.md` (14 files), and the previously-missing fixture entries
  (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`,
  `invalid-wrong-order.md`, `valid-feature-dir/DESIGN.md`) plus a refreshed
  `valid-feature-dir/TRACKER.md`. All byte-identical to upstream.
- **`scripts/validate.sh` Error check 10 generalized to `MIRROR_SPECS` array (T000011).**
  Single composite check enforcing byte-identity sync on 7 mirror entries
  (templates, WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, manifest pair).
  Uses `find -name '*.md' -print0` for the recursive shape — POSIX-portable, works on
  bash 3.2 (macOS default) without `shopt -s globstar`. Future mirror dirs add as one new line.
- **Mirror orphan policy split (autoplan D3).** New authoritative mirrors
  (`reference/`, `philosophy/`, `examples/`, `fixtures/`, `WORKFLOW.md`) FAIL on
  orphan — stale bundle copies served to Copilot are exactly the failure mode v2
  prevents. Templates retain v1 WARN-only behavior for backward compatibility.
- **Manifest pair sync via schema parity (autoplan D5).** Sync check parses both
  manifests and diffs with the `description` field stripped via `jq 'del(.description)'`.
  No code grep-consumes the description field, so byte-identity unification was
  test-driven coupling, not product value. Schema parity reflects the actual contract.
- **`scripts/copilot-deploy.py` defense-in-depth path-traversal check (autoplan G3 / D4).**
  `doctor` and `remove` resolve `install-manifest.json` `dest` entries and refuse
  any path that escapes the target directory. Exits 2 with a clear error.
  Closes a latent vulnerability that pre-dates v2 but was widened by the bundle expansion.
- **`scripts/copilot-deploy.py --dry-run` (DX3).** `install --dry-run` and
  `remove --dry-run` preview filesystem changes without writing or deleting.
  Output prefixed `(would write)` / `(would delete)` so it's diff-greppable.
- **`scripts/copilot-deploy.py` Python 3.8+ guard (DX1).** Pre-flight check at
  `main()` exits with a friendly upgrade hint when run on Python <3.8 instead of
  failing later with a confusing `argparse` traceback.
- **`scripts/copilot-deploy.py --help` enriched (DX4).** `RawDescriptionHelpFormatter`
  + `description=__doc__` surfaces the module docstring (subcommands, platform
  notes) in `--help` for free.
- **`work-copilot/README.md` quickstart (DX2).** Single human-facing entry point:
  prerequisites, install / use / upgrade / health-check / uninstall, and a
  troubleshooting table. New users / re-installers no longer have to navigate
  PRD/DESIGN docs to find the install command.
- **`work-copilot/instructions/copilot-instructions.md` Bundle layout + Troubleshooting
  sections (DX5 + DX6).** Adds a per-mirror-dir pointer table ("when to read each file")
  plus inline quoted anchors from `WORKFLOW.md` and `philosophy/` so canonical phrasing
  lands even if Copilot's path-following is unreliable. Troubleshooting table covers
  "/validate not recognized", "Copilot ignores the bundle", drift on prior-experiment
  files, and bundle-cite paths that don't exist. Total file size: 7821 bytes (≤8192 budget).
- **14 new test cases in `scripts/test.sh`** covering the v2 surface: 8 KB budget guard,
  bundle-layout pointer presence, install spot-checks for each new bundle dir,
  doctor DRIFT on nested fixture (the file that historically drifted),
  path-traversal defense, --dry-run filesystem-untouched assertion, T000011
  drift detection across single/flat/recursive shapes, orphan FAIL/WARN policy split,
  and manifest schema parity (rejects schema changes, allows description-only divergence).

### Fixed
- **`templates/company-workflow/doc-milestones.md` frontmatter aligned with actual
  feature-level milestone convention.** Dropped stale `parent: {USER_STORY_ID}`
  comment + `feature: {FEATURE_ID}` key. Every real milestones file in the
  workbench (F000001-F000004) uses `parent: {FEATURE_ID}` with no separate
  `feature` key — matches the personal-workflow template convention. The
  drift was harmless workbench-side (no real artifact had the `feature` key
  for the validator to demand) but surfaced on Windows when Copilot's
  validator self-test on `fixtures/valid-feature-dir/milestones.md` reported
  [DRIFT] for missing `feature` field. Bundle mirror updated in lockstep
  (sync check enforces it).

### Notes
- v2 plan packet was reviewed via `/autoplan` (CEO + Eng + DX dual voices). 4 taste
  decisions (D2 find-print0, D3 orphan FAIL/WARN split, D4 path-traversal defense,
  D5 manifest schema parity) and 1 user challenge (UC1: gate v2 on citation spike +
  S000009 Windows E2E) all resolved. Eng-review test-plan addendum identified 13
  test-coverage gaps; G3-G10 absorbed into this release, G11-G13 deferred. See
  `work-items/features/F000004_work_copilot/F000004_DESIGN.md` v2.1 for full audit.
- **UC1 citation spike PASSED** on Windows work box (2026-04-28): Copilot cited
  `.github/work-copilot/{WORKFLOW.md, examples/, philosophy/, reference/}` for
  all 4 procedural / how-to / rationale / example queries. The autoplan-mandated
  premise held. The DX5 inline-quoted-anchor hedge is still the right defense
  in depth, but path-following worked.
- The S000009 Windows-box live E2E acceptance criterion remains outstanding —
  expanded bundle does not prove v1 worked. Tracked separately under S000009.
- Knowledge integration (`$AI_KNOWLEDGE_DIR`, two-tier surfacing,
  `bin/knowledge-helpers.sh`) is **not** mirrored into the bundle. Copilot has no
  shell at prompt time and no env-var resolution; the helpers go away when a
  follow-up feature ships their Copilot-native redesign. `bin/` intentionally
  absent from `work-copilot/` per design Decision #10.
- Re-install on existing v0.14.0 targets picks up the new mirror artifacts
  automatically (`scripts/copilot-deploy.py rglob("*")` already routes everything
  not in `prompts/` or `instructions/` to `.github/work-copilot/<same>`). If a
  target has a manual `WORKFLOW.md` (or any other newly-mirrored file) from prior
  experiments, re-install reports `[DRIFT]` — use `--overwrite`.
- `./scripts/validate.sh` PASS (0 errors, 0 warnings, 33 mirror entries verified).
  `./scripts/test.sh` PASS (0 failures, 14 new v2 test cases green).
  `/personal-workflow check work-items/features/F000004_work_copilot/` PASS.

## [1.0.0] - 2026-04-25

First major release. The skill bundle (`personal-workflow`, `company-workflow`,
`system-health`, plus the `work-copilot/` Copilot port) is feature-complete for
the 1.x line; future work in this stream is bug fixes and incremental
enhancements rather than ground-up changes.

### Changed (BREAKING)
- **Knowledge integration: removed the per-repo `.claude/knowledge-enabled` opt-in marker.** Knowledge loading now activates whenever `$AI_KNOWLEDGE_DIR` resolves to a valid directory; the marker file is no longer consulted by `## Knowledge Loading`, `## On-Demand Matching`, or `## Diagnostic: knowledge-doctor` in `skills/company-workflow/SKILL.md`. **Cross-context isolation is now the user's responsibility** — scope `$AI_KNOWLEDGE_DIR` per shell (don't export globally if you work across multiple clients), or use `AI_KNOWLEDGE_DISABLE=1` for one-shot bypass. Rationale: F000003_DESIGN.md decision #4 and S000004_ARCHITECTURE.md already documented the marker as REJECTED ("redundant on top of two-tier surfacing + env-var control"); the v0.12.0 marker implementation never matched the v1.0 design intent. v0→1.0.0 is the right semver boundary for the breaking change.
  - **Migration:** if you previously relied on `.claude/knowledge-enabled` as a security gate, the file is now a no-op. Replace it with per-shell scoping of `AI_KNOWLEDGE_DIR`. The marker file itself can be safely deleted; nothing reads it.
- **`skills/company-workflow/SKILL.md` simplified:** preconditions list went from 5 → 4 entries, the helpful-diagnostic branch for "marker absent + has always-on" is gone, the `_marker_ok` variable is removed from `knowledge-doctor`, and the `marker:` line no longer appears in doctor output.
- **`skills/company-workflow/WORKFLOW.md` Security section rewritten** to put cross-context isolation guidance front and center (per-shell `AI_KNOWLEDGE_DIR` scoping + `AI_KNOWLEDGE_DISABLE=1` + per-category on-demand triggers). The marker-as-security-control framing is gone.

### Removed
- **7 marker-specific test cases** from `scripts/test.sh`: G1 marker-absent gates (cases 18, 19), the symlink/directory/nested-marker hardening trio (cases 22, 23, 24), `knowledge-doctor` marker-missing (case 31), and on-demand G2 marker-absent (c3 case 21). Cases 4 + 8 inverted to assert the marker string does NOT appear in `SKILL.md` / `WORKFLOW.md`. Case 20 simplified. Case 30 inverted to require no `marker:` line in `knowledge-doctor` output.

### Fixed
- **Tracker reconciliation across the `work-items/` tree.** Drift accumulated as work shipped without trackers being closed:
  - **F000003 (company-workflow):** journal entry added recording the v1.0.0 implementation realignment.
  - **F000004 (work-copilot):** S000007 + S000008 closed (status: shipped) — bundle, validator prompt, installer, doctor, smoke test all shipped in v0.14.0 (PR #43). S000009 + parent F000004 stay `active` because their last AC requires live E2E in Copilot chat on a Windows box, which is a user-side acceptance test, not a build artifact. Phase 2 + most Phase 3 gates updated to match the v0.14.0 ship state.
  - **D000007** (eliminate `contract.json`) and **D000009** (require DESIGN.md for personal-workflow features) closed. D000007's evidence: `find . -name contract.json` returns zero hits + F000003_DESIGN.md decision #2 codifies templates-as-SSoT. D000009's evidence: `jq '.types.feature.required'` on the personal manifest now includes `design`/`DESIGN.md` (shipped v0.13.1); v0.14.2 extended the same pattern to `feature-summary.md`.

### Added
- **`.context/` added to `.gitignore`.** Local retro / scratch directory was being shown as an untracked path on every `git status`; gitignored now.

### Notes
- Pure realignment + tracker hygiene + version semantics. No new features. The bundle that ships here is the same bundle that shipped in v0.14.3 minus the marker code path.
- `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures, all knowledge-loading + on-demand + doctor + copilot-deploy regression blocks green after the marker removal and test-case revisions).

## [0.14.3] - 2026-04-24

### Changed
- **Knowledge helpers extracted to `skills/company-workflow/bin/knowledge-helpers.sh` — one canonical implementation, sourced by every `## Knowledge ...` block in `SKILL.md`.** Replaces 4× inline duplication of `parse_knowledge_yml`, `parse_knowledge_triggers`, `list_categories`, `list_md_files` (Helpers, Loading, On-Demand Matching, Diagnostic blocks). Diagnostic block's `_parse` shim and inline trigger awk parser also replaced with calls to the canonical helpers.
- **`SKILL.md`: 1109 → 851 lines (~258 saved)** — duplicated awk parsers gone. Token cost on every `/company-workflow` invocation reduced commensurately.
- **Drift tripwires removed from `scripts/test.sh`** — impossible by construction now that there's only one definition. Replaced with structural greps verifying each Knowledge block sources `bin/knowledge-helpers.sh`. Test fixture repos now symlink the helpers in so the Loading / On-Demand / Doctor blocks resolve them via the workbench-relative fallback.

### Notes
- Pure refactor. `knowledge-doctor` smoke-test (unset env + tiny knowledge dir) produces identical output to v0.14.2. `./scripts/test.sh` PASS (0 failures).

## [0.14.2] - 2026-04-24

### Fixed
- **`feature-summary.md` is now required for personal-workflow features.** Adds the artifact to `personal-artifact-manifests.json`, copies the template + example from company-workflow, and backfills F000001-F000004 (and a `milestones.md` for F000002 which had been missing). Personal-workflow scaffolds and company-workflow scaffolds now produce the same 4-artifact set for `type: feature`.
- **F000003 + both `valid-feature-dir/` fixtures pass their own validators.** F000003 had been missing `feature-summary.md` since it was scaffolded with personal-workflow templates; the company-workflow fixture had been missing `DESIGN.md` since D000009 added it as a required artifact (v0.13.1) without updating the fixture. Both `tracker-feature.md` Phase 1 gates updated to mention DESIGN.
- **`F000003_DESIGN.md` big-decisions table populated** with 6 lifted journal entries (was a stub backfill from D000009).

### Added
- **`scripts/validate.sh` Error check 11 — pure-bash manifest reconciliation gate.** Enumerates every `*_TRACKER.md` directory under `work-items/` plus every `valid-*-dir/` fixture, strips the ID prefix, and compares against `required[].filename` in the matching manifest. Catches manifest-vs-filesystem drift that the LLM-driven `/personal-workflow check` and `/company-workflow validate` commands would otherwise miss in CI.

### Notes
- Pure compliance + tooling fix. No skill behavior change. `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures).

## [0.14.1] - 2026-04-24

### Changed
- **Work item consolidation: one feature per skill.** Each skill in the workbench (`personal-workflow`, `system-health`, `company-workflow`, `work-copilot`) now maps to exactly one canonical feature work item, so future work on a skill has an obvious home and the skill's full arc reads in one tracker. F000001 renamed `workflow_alpha` → `personal_workflow`. F000002 renamed `system_health_v1` → `system_health`. F000003 renamed `company_spec_system` → `company_workflow` and absorbed former F000004's shipped knowledge-integration stories (S000004 + S000005). F000004's deferred personal-workflow port (S000006) reparented to F000001. F000005 renumbered to F000004 (`work_copilot`) so feature IDs stay contiguous. Story and task IDs are unchanged — they are globally unique, not per-feature.
- **External references updated to point at the new IDs.** `skills/company-workflow/SKILL.md`, `skills/company-workflow/WORKFLOW.md`, `scripts/test-helpers/knowledge.sh`, `work-copilot/instructions/copilot-instructions.md`, `work-copilot/prompts/validate.prompt.md`, and the example tree output in `skills/personal-workflow/check.md` were updated. CHANGELOG and defect tracker references (D000009, D000010) intentionally left as historical records — they describe state at the time of writing.
- **Status fields aligned to actual delivery state.** F000001 / F000002 / F000003 flipped to `status: shipped` (previously a mix of `closed` and `active` that didn't reflect the merged shipped work). F000004 (work-copilot) stays `active` — three child stories still mid-flight.

### Notes
- Pure restructure of `work-items/` plus six small documentation pointers. No skill code, template, validator, or manifest changed. `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures).

## [0.14.0] - 2026-04-23

### Added
- **`work-copilot/` — a standalone GitHub Copilot bundle that ports the `/company-workflow` validation logic to VS Code Copilot Chat (F000005).** Installable into any repo with one command: `python3 scripts/copilot-deploy.py install <target>`. Produces `.github/copilot-instructions.md` (always-on context, 5 KB) + `.github/prompts/validate.prompt.md` (slash command, 7 KB) + `.github/work-copilot/` (templates, manifest, fixtures). Lets a Windows work machine get the same "scaffold + validate + ship" discipline Claude users have, without installing Claude.
- **`scripts/copilot-deploy.py` — Python 3 stdlib installer (no pip)** with three subcommands: `install` (SKIP/UPDATE/DRIFT/OVERWRITE/WRITE tri-state logic — skips user-edited files by default, replaces skill-upstream-updated files, respects `--overwrite` for forced replacement), `doctor` (PASS/MISSING/DRIFT/ORPHAN reporting against the install-manifest), and `remove` (cleans up only files the installer wrote). Text files (.md, .json, .yaml) are CRLF/CR → LF normalized before SHA256 hashing so hashes are stable across macOS and Windows regardless of git autocrlf settings.
- **`scripts/test.sh` — `copilot-deploy.py` installer smoke test** — install → doctor (expect all PASS) → CRLF-mutation → doctor (still PASS, guarding the CRLF normalization) → remove round-trip, executed against a tmp target. Closes the previous 0% automated coverage gap on the 264-LoC installer.
- **`work-copilot/instructions/copilot-instructions.md`** — 6 H2 sections (work-item conventions, IDs, hierarchy, lifecycle phases, validation, sources of truth). Every section ends with a `Source:` footer linking back to the template, manifest, or validator — single source of truth pattern.
- **`work-copilot/prompts/validate.prompt.md`** — ports the full `/company-workflow check` validator logic (File Mode + Directory Mode, PASS/MISSING/DRIFT/EXTRA/WARN/VALID/VIOLATION output contract) to a single Copilot `.prompt.md` file.
- **`work-copilot/fixtures/`** — one known-good fixture + one known-bad fixture for E2E self-test on any machine: `/validate work-copilot/fixtures/valid-feature-dir/` prints all `[PASS]`; the invalid fixture prints at least one `[MISSING]`.
- **`scripts/validate.sh` Error check 10** — enforces byte-for-byte sync between `templates/company-workflow/*.md` and `work-copilot/templates/*.md`, so the Copilot bundle can't silently drift from the Claude-side source of truth.

### Changed
- **`work-copilot/copilot-artifact-manifests.json`** mirrors `skills/company-workflow/company-artifact-manifests.json` with an annotation noting the mirror relationship. Includes the `design` artifact entry added by D000009.
- **`work-copilot/instructions/copilot-instructions.md` — lifecycle section corrected from 3 phases to 4 (Track, Implement, Review, Ship)** to match all five `tracker-*.md` templates. The previous "three phases" wording (copied from personal-workflow) would have made Copilot give wrong answers about Phase 3 being Ship, when Phase 3 is actually Review. Surfaced by Codex adversarial review during the /ship of F000005.

### Deferred
- **D000010 — copilot-deploy.py security hardening (path traversal + symlink escape).** Adversarial review (Claude + Codex) found the installer trusts `install-manifest.json` `dest` values verbatim (doctor/remove can read/unlink outside the target repo given a poisoned manifest) and follows symlinks in both source and destination trees. Both are latent in the current single-user self-install threat model. Tracker: `work-items/defects/D000010_copilot_deploy_security_hardening/`. Fix before recommending `copilot-deploy.py` to other users.

## [0.13.1] - 2026-04-22

### Added
- **`DESIGN.md` is now a required feature artifact for both personal-workflow and company-workflow (D000009).** Feature work items must now carry a cross-story engineering design doc — capturing the problem, solution shape, big decisions, risks, and ship criteria that don't fit in any single user-story's `ARCHITECTURE.md`. Two new templates (`templates/personal-workflow/doc-DESIGN.md` with 7 sections, `templates/company-workflow/doc-DESIGN.md` with 6 sections — company's drops "Not in scope" since `feature-summary.md` already owns Out-of-Scope). `feature.required` updated in both artifact manifests. Existing closed features (F000001–F000004) get a minimal `status: Backfill` DESIGN.md pointing at the original TRACKER/ARCHITECTURE for context.
- D000009 regression block in `scripts/test.sh` — 4 checks guarding against the DESIGN entry silently disappearing from either manifest or either template file vanishing.

### Changed
- Template count for personal-workflow bumps from 10 → 11 (new `doc-DESIGN.md`); `scripts/test.sh` count assertion updated to match.
- `skills-catalog.json` template lists for both personal-workflow and company-workflow now include `doc-DESIGN.md`.

## [0.13.0] - 2026-04-20

### Added
- **On-demand trigger matching for `/company-workflow` (F000004, S000005 c3).** Drop `.knowledge.yml { surface: on-demand, triggers: [pricing, "pricing engine"] }` next to a category directory. New `## On-Demand Matching` section in `skills/company-workflow/SKILL.md` enumerates on-demand categories with non-empty triggers and emits a `## On-Demand Knowledge Candidates` block listing each category, its triggers, and its files. Claude matches the latest user message against triggers (case-insensitive whole-word for single-word triggers, phrase match at token boundaries for quoted multi-word triggers), loads every matched category's files, and logs `[knowledge] matched: <cat> via <trigger>` for each hit. Categories with `surface: on-demand` but no triggers are documented as intentionally inert. Together with always-on loading (v0.12.0), this completes the knowledge-loading vertical slice.
- **`parse_knowledge_triggers` helper.** New bash function in `## Knowledge Helpers` that tolerates both YAML flow form (`triggers: [a, "b c", 'd']`) and block form (`triggers:` followed by `  - a`); strips single + double quotes; honors `#` comments, CRLF, and UTF-8 BOM — same grammar tolerance as `parse_knowledge_yml`. Defined in Knowledge Helpers and inlined byte-for-byte into the On-Demand Matching block; drift tripwire (c3 case 8) diffs the two copies on every test run.
- **`knowledge-doctor` distinguishes loadable vs inert on-demand categories.** Output now shows `runbooks surface=on-demand files=5 loads=on-match (triggers: pricing, "pricing engine")` for categories that will activate vs `staging surface=on-demand files=2 loads=no (empty triggers)` for inert ones. Same diagnostic covers both always-on (c2) and on-demand (c3) surfacing.
- **25 new c3 test assertions in `scripts/test.sh`.** Structural (section presence, matching-semantics spec, helper drift across blocks), unit tests for `parse_knowledge_triggers` (inline flow, block form, empty list, missing key, quote stripping), behavioral tests (always-on excluded from on-demand block, missing yml excluded, empty triggers excluded, single-trigger emission, quoted phrase emission, multi-category correctness), gate tests (marker absent, env unset, `AI_KNOWLEDGE_DISABLE=1` all suppress the block), and instruction-presence + doctor-output assertions.
- **WORKFLOW.md trigger authoring guidance.** New section covering single-word vs multi-word phrase semantics, why quoting matters, hygiene tips (keep triggers concrete, avoid single common verbs, quote multi-word phrases to scope them to contiguous token matches).

### Changed
- **`skills/company-workflow` bumped to v3.2.0.** Additive feature; no breaking changes. `## On-Demand Matching` inserted between `## Knowledge Loading` and `## Diagnostic: knowledge-doctor`. Always-on loading behavior unchanged; on-demand categories that previously parsed-and-discarded now enumerate + emit.
- **Removed "v1 deferred" language throughout `skills/company-workflow/WORKFLOW.md` and SKILL.md.** On-demand is no longer deferred; both surfacing modes ship in this release. The Loading block's `on-demand)` case now reads "handled by On-Demand Matching block; not emitted here" instead of "v1 deferred — forward-compat for c3 follow-up."
- **c2 test extraction bounds updated.** Tests that extract the Knowledge Loading bash block now bound at `## On-Demand Matching` (not `## Diagnostic: knowledge-doctor`) so the Loading extraction captures only the Loading block. Drift tripwire and A2-leak test now pass deterministically regardless of On-Demand Matching's presence.

### Skipped (explicit non-scope)
- **50KB on-demand soft threshold.** Dual-voice review flagged the proposed soft-cap-with-warning as theater: no real protection (still loads), no user action (just noise), and the existing hard 500-path / 100KB caps in Loading already protect always-on. Skipping reduces complexity without reducing safety. If on-demand bloat becomes a real incident, revisit with a concrete threshold tuned to observed pain.

### Rationale
Completes F000004 S000005. Knowledge integration now supports both loading modes: always-on (v0.12.0, ship with every invocation) and on-demand (this release, ship when Claude matches triggers in the user's message). The c1 + c2 + c3 split was deliberate — each slice shipped something usable on its own, and c3's scope was re-evaluated after c2 landed. One piece of c3's original scope (50KB soft threshold) was dropped at the gate rather than shipped reflexively. Boiling the lake means doing the complete thing, not every proposed thing.


## [0.12.0] - 2026-04-21

### Added
- **Always-on knowledge loading for `/company-workflow` (F000004, S000005).** Drop `.knowledge.yml { surface: always }` + `*.md` files under a category directory in `$AI_KNOWLEDGE_DIR`, touch `.claude/knowledge-enabled` in any repo where you want knowledge injected, and every `/company-workflow` invocation in that repo automatically includes your house-style guidance in Claude's context. No more copy-pasting a cpp style guide into every prompt. New `## Knowledge Helpers` + `## Knowledge Loading` sections in `skills/company-workflow/SKILL.md` do the discovery (category enumeration, `.knowledge.yml` parsing with tolerance for quoted values, inline comments, CRLF, and UTF-8 BOM), emit a `## Always-On Knowledge` block with absolute paths, and instruct Claude to Read them before answering.
- **Per-repo opt-in marker: `.claude/knowledge-enabled`.** Prevents cross-context contamination — a global `$AI_KNOWLEDGE_DIR` pointing at Company A's knowledge folder will NOT inject Company A guidance into Company B or OSS repos. Only loads when the current repo explicitly opts in. Marker hardening rejects symlinks, directories, and `repo/.claude -> /tmp/attacker` redirection.
- **`/company-workflow knowledge-doctor` diagnostic subcommand.** Prints the state of every precondition and every category (env var, repo root, marker presence, category surface modes, byte totals, cap status, final verdict). Debug setup issues in one shot instead of iterating with canary tests.
- **`AI_KNOWLEDGE_DISABLE=1` one-shot escape hatch.** Bypass loading for a single invocation without touching the committed marker. Useful when debugging a bad knowledge file. Accepts only explicit truthy values (`1`/`true`/`yes`/`on` and capitalized variants) — `AI_KNOWLEDGE_DISABLE=false` leaves loading enabled, matching user intuition.
- **Helpful missing-marker diagnostic.** When `$AI_KNOWLEDGE_DIR` is configured AND at least one category has `surface: always` AND the repo's marker is absent, emits exactly one stderr line naming the missing marker and the fix command. Problem + cause + fix in one line; silent fail used to train users to distrust the feature.
- **Forward compatibility for on-demand surfacing.** Categories authored today with `surface: on-demand` + `triggers: [...]` parse cleanly and are silently skipped in v1. When the on-demand follow-up ships, these files activate automatically — no re-authoring needed.
- **Shared fixture builder `scripts/test-helpers/knowledge.sh`.** `build_knowledge_fixture()` synthesizes knowledge dirs in `mktemp -d` per test case with canary strings (`CANARY_<cat>_TOP`, `CANARY_<cat>_NESTED`). No fixtures committed under `skills/` — the knowledge dir is user-owned and external by design.
- **35+ new test assertions across `scripts/test.sh`.** T000006 c1: 15 helper self-tests covering parser edge cases (quoted/comment/CRLF/BOM/malformed) + enumeration determinism + nonexistent-dir handling. T000006 c2: 20 behavioral tests covering always-on emission, on-demand forward-compat, marker hardening (symlink/directory/nested-subdir all fail closed), 500-path cap enforcement, yml edge cases, absolute-path-with-spaces, invalid-env pass-through, and knowledge-doctor state reporting. Drift tripwire does real byte-level diff of helper function bodies between `## Knowledge Helpers` and `## Knowledge Loading` blocks — prevents silent drift between the canonical definitions and their inlined copy.
- **WORKFLOW.md `## Knowledge Configuration` rewrite with Quick Start IA.** Copy-paste 5-line quick-start, troubleshooting table with problem+cause+fix for every common trap, documented escape hatches, explicit security callout covering prompt-injection risk + control-char rejection + hidden-dir skip + parent-symlink hardening.

### Changed
- **`skills/company-workflow` bumped to v3.1.0.** Additive feature; no breaking changes to existing `validate` command behavior. Zero regression assertion: `/company-workflow validate` output is byte-identical when `$AI_KNOWLEDGE_DIR` is unset and `.claude/knowledge-enabled` is absent.
- **F000004 scope restructure.** Collapsed former S000005 "always-on-loading" + S000006 "on-demand-matching" stories into single `S000005_knowledge_loading` (same PR, both surfacing modes' infrastructure shared one helper layer; slice boundary was bookkeeping). S000006 slot now holds `S000006_personal_workflow_port` (parity port of the knowledge feature to `/personal-workflow`), which was scaffolded, /autoplan-reviewed, and DEFERRED after dual-voice CEO review flagged it as symmetry work rather than product work for a single-user workbench. Unblock condition: a specific personal-repo user incident where missing knowledge-loading blocks work.

### Deferred
- **On-demand trigger matching (c3 follow-up).** Parsing infrastructure is in place (forward-compat parse-and-discard); matching logic + trigger DSL + match log + 50KB soft threshold will land in a follow-up story. Unblock condition: a specific user incident where always-on alone was insufficient and on-demand triggers would have saved context or time. Re-evaluated if Anthropic ships native Claude Code knowledge-base support first.

### Rationale
Ships the user-visible half of F000004. Knowledge moves from "the skill knows where your folder is" (v0.11.0) to "the skill reads from your folder and Claude acts on it" (this release). The half-deferred (on-demand matching) was explicitly evidence-gated after /autoplan CEO dual-voice review converged that v1 had 60% of the complexity for 30% of the value without documented user demand. Boiling the lake here means deciding what NOT to boil, not just what to boil.


## [0.11.0] - 2026-04-19

### Added
- **Knowledge integration scaffolding for company-workflow (F000004, S000004 slice).** Introduces the `AI_KNOWLEDGE_DIR` environment variable as the seam between the skill and an external knowledge folder for coding guidance and company-specific domain knowledge. When set to a valid directory, downstream features (always-on category loading in S000005, on-demand trigger matching in S000006 — both unshipped) will consume its contents. When unset or invalid, the skill still functions; only knowledge features are disabled. New `## Knowledge Resolution` section in `skills/company-workflow/SKILL.md` (bash block running after Path Resolution) resolves the env var, validates the path with `[-e]` and `[-d]` checks, sets skill-local `$_KNOWLEDGE_DIR`, and emits one of three distinct warnings on stderr (not-set / not-found / not-a-directory). Exit code stays 0. New `## Knowledge Configuration` section in `skills/company-workflow/WORKFLOW.md` documenting setup, the flexible top-level category layout (arbitrary subfolder names, nesting allowed), and the `.knowledge.yml` schema (`surface: always | on-demand` + `triggers: [...]`) that S000005/S000006 will consume.
- **Full work-item decomposition for F000004 knowledge integration.** 1 feature TRACKER + feature-level milestones, 3 user-stories (S000004 env-var-resolution, S000005 always-on-loading, S000006 on-demand-matching) each with TRACKER + PRD + ARCHITECTURE + TEST-SPEC, and 8 tasks (T000003..T000010) each with TRACKER + test-plan. Uses personal-workflow structure (3-phase lifecycle Track / Implement / Ship). 30 artifacts total. S000004 shipped complete in this PR; S000005 and S000006 are future slices that share `skills/company-workflow/SKILL.md` and must land sequentially.
- **T000004 test coverage for the Knowledge Resolution block.** New "Regression test (T000004)" section in `scripts/test.sh` with 11 scripted assertions covering every branch and edge case: Tier 1 structural greps (section present, variable references, WORKFLOW.md docs, no stdout leakage), Tier 2 extract-and-exec against mocked env states (unset, empty-string, nonexistent path, path-is-file, valid dir, hostile newline input, parent-shell `set -e` safety). Uses portable `mktemp` patterns (GNU + BSD), single tmpdir with final cleanup. Case 9 (end-to-end regression diff) documented as manual-only — `/company-workflow validate` is an LLM-driven SKILL.md and cannot be invoked from bash CI per D000004 RCA.

### Fixed
- **Warning output in the Knowledge Resolution block is now newline-safe and terminal-safe.** The three invalid-path warnings previously echoed `$AI_KNOWLEDGE_DIR` raw. A hostile env var (embedded newline or terminal escape sequences) could split the warning into multiple stderr lines, breaking the documented "exactly one warning line" contract, or emit ANSI escapes that polluted the user's terminal. Now strips control characters via `tr -d '[:cntrl:]'` and truncates display at 200 characters with `...` before rendering. The filesystem tests still use the raw value; only display output is sanitized. Caught by Codex outside-voice during /plan-eng-review; pinned by T000004 case 13.

### Rationale
Three vertical slices for F000004 (resolve → load always-on → match on-demand) keep each PR reviewable on its own. S000004 ships the smallest viable increment: the skill knows where knowledge lives but does not read any knowledge file yet. Users can `export AI_KNOWLEDGE_DIR="$HOME/knowledge"` today and get the warning-every-invocation nudge if unset. Content loading lands in S000005 / S000006. Personal-workflow port is captured as a follow-up TODO in F000004 TRACKER, blocked on S000006.

### Migration note
Existing users will see a new stderr warning on every `/company-workflow` invocation until they configure `AI_KNOWLEDGE_DIR`. Exit code is unchanged (still 0) — the warning is intentional, it's the nudge to configure, not an error. `/company-workflow validate` stdout is byte-identical to before. All automated consumers (CI, scripting) are unaffected. Deploy: run `skills-deploy install --overwrite` to refresh `~/.claude/skills/company-workflow/SKILL.md` and `WORKFLOW.md`.

## [0.10.0] - 2026-04-17

### Changed
- **Hierarchy & Placement rules moved from enforcement to spec.** Both `skills/personal-workflow/WORKFLOW.md` and `skills/company-workflow/WORKFLOW.md` gain a new `### Hierarchy & Placement` section under "Scaffolding Conventions" that documents parent-child requirements (feature requires ≥1 user-story child; user-story requires ≥1 task child; defects/reviews/standalone-tasks have no required children), placement rules (features go in `features/`, defects in `defects/`, reviews in `reviews/` for company; user-stories nest under features; tasks nest under user-stories), and directory naming regex (`{ID}_{slug}/` where ID matches the type prefix F/S/T/D/R and slug matches `[a-z0-9_-]+`). The generating AI reads this spec at scaffolding time and follows it. Same trust model as D000007 (v0.9.0): templates + WORKFLOW.md are the single source of truth.

### Removed
- **`hierarchy` and `placement` blocks from `skills/personal-workflow/personal-artifact-manifests.json`** — these were the data feed for the enforcement code removed below. Schema is smaller and more consistent with D000007's "no separate config as source of truth" philosophy.
- **Hierarchy / placement enforcement from `skills/personal-workflow/check.md`** — the `[INCOMPLETE]` and `[MISPLACED]` flags (old Steps 19a, 19b, 19c, 19e) are gone. Old Step 19 "Check 4 — Structural Completeness + Orphan Detection" collapses into a single "Check 4 — Stray Directory Detection" that flags `[STRAY]` for non-work-item directories containing `.md` files. The `structure` badge, `completeness` field in the graph artifact, and `structural_rules` top-level field are all removed. The Badge Summary and Structural Summary sections in the generated report drop the corresponding columns. The `company-workflow` validator was NEVER wired to enforce these rules, so no changes there.
- **`/personal-workflow tree` subcommand and `skills/personal-workflow/tree.md`** — the tree subcommand was explicitly a structural-only view (per its own `tree.md` lines 4, 85, 116: "Non-structural badges always show '—'"). With structural enforcement gone, the command had no remaining purpose — `/personal-workflow check` already renders a tree view with the remaining template/lifecycle/traceability badges. Removed the file, the `tree` entry from `SKILL.md` usage + subcommand routing, the `tree (quick hierarchy view)` section in `WORKFLOW.md`, the `tree.md` entry from `skills-catalog.json` `files[]`, and `/personal-workflow tree` lines from both tracker templates, fixtures, and examples. Also scrubbed "structural completeness checks" phrasing from SKILL.md frontmatter descriptions and both catalog entries, and the stray "and tree" reference in `personal-artifact-manifests.json`'s description.

### Rationale
Adding hierarchy enforcement via a new config field + validator logic would have recreated the exact drift mechanism D000007 (v0.9.0, merged yesterday) eliminated by deleting `contract.json`. Putting the rules in `WORKFLOW.md` as prose that the AI reads is consistent with the rest of the skill architecture. If AI obedience proves unreliable in practice, a future validator can read its rules from `WORKFLOW.md` (one place, same spec the AI follows) rather than a separate config field.

### Migration note
Existing `work-items/features/*/` directories that have no user-story children (e.g., `F000002_system_health_v1/`) no longer surface as `[INCOMPLETE]` in the `/personal-workflow check` output. Pure behavior change for that validator. If your team depended on `[INCOMPLETE]` as a signal, move the check into a PR review step or a pre-commit hook that greps `WORKFLOW.md`'s "Required children" section.

## [0.9.1] - 2026-04-17

### Fixed
- **`/ship` and `/land-and-deploy` no longer waste 30 seconds on a wrong-then-right merge command in this repo** (D000008). Two related operational defects, both observed twice in this session: (1) `gh pr merge --auto --delete-branch` (per the upstream gstack /ship and /land-and-deploy Step 4) silently fails because gh CLI requires an explicit merge method when `--auto` is set — gh prints help and exits 0, no merge gets queued, the LLM only notices on the next `gh pr view`. (2) The fall-back `--delete-branch` flag does a local `git checkout main` for cleanup, which fails inside a worktree where the parent repo has `main` checked out. Local fix in this repo: a `## CI/CD merge convention` section in `CLAUDE.md` directing the LLM to use `gh pr merge <PR#> --auto --squash --delete-branch` (combined flags) and to use `gh api -X DELETE refs/heads/<branch>` for worktree-aware remote-branch cleanup. The next `/ship` + `/land-and-deploy` cycle in this repo will use the correct invocation directly with no fallback.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000008)" — 3 checks) that prevent the `## CI/CD merge convention` section in CLAUDE.md from being silently dropped: section header presence, `gh pr merge ... --auto --squash` invocation present, `gh api -X DELETE git/refs/heads` workaround present.

### Migration note
Upstream gstack fix is filed as a separate follow-up (out of scope for this PR). The local guard in `CLAUDE.md` is defense-in-depth and works regardless of which gstack version is installed.

## [0.9.0] - 2026-04-17

### Changed
- **Templates are now the single source of truth for both workflow skills** (D000007, supersedes D000004). Both `skills/company-workflow/contract.json` and `skills/personal-workflow/contract.json` are deleted. The validator now derives every structural rule (required frontmatter, required sections, section order, lifecycle phases, minimum checkbox count) from the matching template at runtime: it parses `templates/{skill}/tracker-{type}.md`, extracts frontmatter keys + `##` headers + `### Phase N:` headers + `- [ ]` count from the Lifecycle section, and validates instances against THAT. Edit a template, the validator's expectations move with it. Single source. No more drift between contract and templates.
- Skill major versions bumped: `personal-workflow` 1.0.0 → 2.0.0, `company-workflow` 2.1.0 → 3.0.0. Reflects the breaking change to the validator's input contract (no more `contract.json`).
- **`frontmatter.recommended` distinction is gone.** `repo` and `branch` were "recommended but not enforced" under the old contract. Under template-derived rules they're required (templates emit them). No observable change for compliant trackers.
- **`type_specific_optional` is gone too.** Per-type optional sections (e.g., `Reproduction Steps` for defects) are now inferred structurally — if the per-type template includes the section, instances need it; if not, they don't. Less declarative metadata, less drift.
- **Stricter checkbox enforcement.** The minimum checkbox count is read from the template at runtime, not from a config field. Trackers authored against an older template version that pre-dates new gates will surface as out-of-date — strictly correct, called out by the validator instead of silently passing.

### Removed
- `skills/company-workflow/contract.json` and `skills/personal-workflow/contract.json` — both deleted. After upgrading, run `skills-deploy install --overwrite` to refresh deployed copies. Existing deployed `~/.claude/skills/{company,personal}-workflow/contract.json` symlinks may linger as broken until manually removed (`rm ~/.claude/skills/{company,personal}-workflow/contract.json`); follow-up planned for `skills-deploy` to auto-clean orphan symlinks.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000007)" — 6 checks) that prevent re-introduction of the two-source-of-truth pattern: contract.json absent in both skills, validator files don't load contract.json at runtime (cat/jq/Read pattern grep), skills-catalog.json no longer references contract.json.

## [0.8.0] - 2026-04-16

### Added
- **PR description templates for company-workflow `task` and `defect` work items.** Two new templates designed as self-contained PR bodies that fit TFS's 4,000-character limit (TFS reviewers cannot click links to local work-item files like `RCA.md` or `test-plan.md`, so the PR body must inline-summarize). Defect template (~1,331 chars scaffolding, verified ~2,224 chars when filled with a realistic example): `[ID] {Name} (P{N})` → Summary → Symptom → Root Cause + Location → Fix → Changes → Test Coverage table. Task template (~976 chars scaffolding): `[ID] {Name}` → Summary → Motivation → Changes → Affected Workflows → Test Plan table. Both include strip-before-pasting instructions in an HTML comment header (frontmatter and comment block are stripped before pasting; only the body goes to TFS).
- `pr-description` artifact entry in `skills/company-workflow/company-artifact-manifests.json` for both `task` (template: `doc-pr-description-task.md`) and `defect` (template: `doc-pr-description-defect.md`). Filename is `PR-DESCRIPTION.md` in both cases. Aligns with the Phase 4: Ship lifecycle gate "PR description generated" already present in `tracker-task.md` and `tracker-defect.md`.
- `skills-catalog.json`: company-workflow templates list adds the two new templates (14 → 16 templates).

### Migration note
Existing company-workflow consumers with active `task` or `defect` work item directories will now see `PR-DESCRIPTION.md` flagged as missing by the directory-mode validator. Recommended migration: scaffold `PR-DESCRIPTION.md` from the new template at PR creation time (Phase 4: Ship). Older completed work items can either be backfilled or excluded from validation.

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
