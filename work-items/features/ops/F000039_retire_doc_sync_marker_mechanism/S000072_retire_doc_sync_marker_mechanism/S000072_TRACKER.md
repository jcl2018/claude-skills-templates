---
name: "Retire the doc-sync marker + preamble-AUQ retirement surface"
type: user-story
id: "S000072"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: "F000039"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-140631-39060"
blocked_by: ""
---

<!-- Prerequisite: parent feature F000039's /office-hours design is the context
     for this atomic story. See F000039_DESIGN.md / S000072_DESIGN.md. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/retire_doc_sync_marker_mechanism` (shipping in parent's branch / same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; this is one cohesive de-referencing change)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any) (N/A — atomic story)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] All three DELETE-target files removed: `scripts/skills-doc-sync-check`, `tests/skills-doc-sync-check.test.sh`, `tests/cj-goal-doc-sync-auq-recommendation.test.sh`.
- [ ] The `DOC_SYNC_PENDING` preamble bash fence + AUQ prose removed from both `CJ_goal_feature/SKILL.md` and `CJ_goal_defect/SKILL.md`.
- [ ] The "F000029 stays as fallback" language struck from all ~9 locations (3 pipeline.md, CJ_document-release SKILL.md×2 + USAGE.md, SKILL-CATALOG.md, skills-catalog.json, README.md via regen).
- [ ] `setup-hooks.sh` post-merge Section 3 + the post-rewrite hook removed; pre-commit validate + post-merge Sections 1+2 untouched.
- [ ] `tests/setup-hooks.test.sh` + `scripts/test.sh` surgically updated (drop marker-write cases + the auq-recommendation runner; KEEP the wiring runner).
- [ ] `CLAUDE.md` doc-sync section deleted + accepted-gap note added; `doc/ARCHITECTURE.md` + `doc/PHILOSOPHY.md` F000028/F000029 content removed.
- [ ] `scripts/cj-document-release-config.sh` two stale comments fixed (file kept).
- [ ] Both completeness greps return ZERO live references; `validate.sh` + `test.sh` exit 0; `cj-goal-doc-sync-wiring.test.sh` still passes.

## Todos

<!-- Actionable items for this story. -->

- [x] DELETE the 3 files (detection script + its 2 tests).
- [x] Remove the preamble AUQ block from the 2 orchestrator SKILL.md files.
- [x] Strike the fallback parenthetical in the 3 pipeline.md files (keep Step 5.5).
- [x] Remove fallback language from CJ_document-release SKILL.md (frontmatter + bullet) and USAGE.md; keep frontmatter byte-identical to catalog.
- [x] Edit `doc/SKILL-CATALOG.md`, drop the F000029 "right surface instead" sentence.
- [x] Edit `skills-catalog.json` CJ_document-release description (byte-match the SKILL.md frontmatter).
- [x] Regenerate `README.md` via `scripts/generate-readme.sh` (do NOT hand-edit).
- [x] Surgical `setup-hooks.sh`: remove post-merge Section 3 + post-rewrite hook; keep pre-commit + Sections 1+2.
- [x] Surgical `tests/setup-hooks.test.sh` + `scripts/test.sh` edits.
- [x] `CLAUDE.md`: delete doc-sync section, add accepted-gap note.
- [x] `doc/ARCHITECTURE.md` + `doc/PHILOSOPHY.md`: delete F000028/F000029 sections + cross-refs.
- [x] Fix the 2 stale comments in `scripts/cj-document-release-config.sh`.
- [x] Add one-line "RETIRED by F000039" note to F000028/F000029 TRACKERs (archival).
- [x] Run both completeness greps + `validate.sh` + `test.sh`; confirm green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Atomic user-story carrying the full F000028/F000029 doc-sync marker-AUQ retirement surface for parent feature F000039.
- 2026-06-03: Implemented via /CJ_implement-from-spec (--auto). 19 files changed (3 deleted, 14 edited, 2 archival tracker notes). validate.sh PASS (0/0); test.sh PASS (0 failures); survivor wiring test PASS; both completeness greps empty.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

DELETED (3):
- `scripts/skills-doc-sync-check` — detection script (reader half).
- `tests/skills-doc-sync-check.test.sh` — tested the deleted script.
- `tests/cj-goal-doc-sync-auq-recommendation.test.sh` — tested the removed AUQ.

MODIFIED:
- `skills/CJ_goal_feature/SKILL.md` — removed doc-sync preamble fence + AUQ prose block.
- `skills/CJ_goal_defect/SKILL.md` — removed the same fence + prose.
- `skills/CJ_goal_feature/pipeline.md` — rewrote Step 5.5 rationale sentence (no fallback/marker-AUQ language; Step 5.5 preserved).
- `skills/CJ_goal_defect/pipeline.md` — same Step 5.5 sentence rewrite.
- `skills/CJ_goal_todo_fix/pipeline.md` — same Step 5.5 sentence rewrite.
- `skills/CJ_document-release/SKILL.md` — frontmatter description trailing clause + removed "Coexistence with F000029" bullet.
- `skills/CJ_document-release/USAGE.md` — replaced 2 fallback-language spots with the "run `/document-release` by hand" accepted-gap guidance.
- `doc/SKILL-CATALOG.md` — replaced the F000029 "right surface instead" sentence.
- `skills-catalog.json` — CJ_document-release description trailing clause (matches SKILL.md frontmatter trailing text).
- `README.md` — regenerated via `scripts/generate-readme.sh` (not hand-edited).
- `scripts/setup-hooks.sh` — removed post-merge Section 3 + the entire post-rewrite hook; kept pre-commit + post-merge Sections 1+2.
- `tests/setup-hooks.test.sh` — rewrote to assert the surviving surface (pre-commit + post-merge S1/S2, no doc-sync block, no post-rewrite); deleted marker-write cases (a)-(f).
- `scripts/test.sh` — removed the auq-recommendation runner block; kept the wiring runner.
- `CLAUDE.md` — replaced the "## Doc-sync check mechanism" section with a "## Doc-sync coverage" accepted-gap note.
- `doc/ARCHITECTURE.md` — deleted the F000028 + F000029 sections; rewrote the F000036 section to drop retired-mechanism/fallback framing; fixed the config-helper comment.
- `doc/PHILOSOPHY.md` — dropped the marker example (Filesystem-as-protocol), the cross-ref, the mechanism block (rewritten to F000036 inline), and the marker-accumulation pitfall.
- `scripts/cj-document-release-config.sh` — fixed 2 stale "mirrors skills-doc-sync-check" comments (file KEPT — F000037 parser).
- `work-items/.../F000028_TRACKER.md`, `F000029_TRACKER.md` — added one-line "RETIRED by F000039" archival notes.

PRESERVED (verified untouched):
- `tests/cj-goal-doc-sync-wiring.test.sh`, `cj-document-release.json`, the Step 5.5 prose + `[doc-sync-red]`/`[doc-sync-non-doc-write]` halt rows.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The biggest implementation trap is linguistic: "doc-sync" is one name for two mechanisms (F000028/F000029 marker-AUQ DIES; F000036 Step 5.5 LIVES). Every edit in the SPEC's Components Affected table states which one it touches; the PRESERVE list is explicit.
- Two completeness greps are required because the 4-token grep (`skills-doc-sync-check|DOC_SYNC_PENDING|doc-sync-pending|doc-sync-cache`) misses the prose "F000029 stays as fallback" sentences — those need the second fallback-language grep.
- Implement blind-spot (per project memory): every new/changed validate.sh check needs a parallel edit to `scripts/test.sh`'s zzz-test-scaffold integration block. Here the inverse applies — check the zzz-test-scaffold block for doc-sync marker assertions and remove only those (keep Step 5.5 ones).

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-06-03: This story is atomic (no task children). The retirement is one cohesive de-referencing change spanning many files but not independently parallelizable; recorded the Phase 1 gate as `Tasks broken down (N/A — atomic story)` per WORKFLOW.md.
- [impl-decision] 2026-06-03: Step 5.5 rationale sentences in the 3 pipeline.md files referenced the retired mechanism by name ("F000028+F000029 marker-AUQ drift window"), which would trip the completeness greps even after striking only the parenthetical. Rewrote each lead sentence to state the live behavior ("no post-merge doc-drift window for orchestrator-driven paths; the doc update ships in the same PR") instead of the design's narrower "strike only the parenthetical" — the Step 5.5 mechanism itself is fully preserved and the greps are clean.
- [impl-decision] 2026-06-03: The accepted-gap note (CLAUDE.md/SKILL-CATALOG/USAGE) routes non-orchestrator paths to `/ship` Step 18 (which already dispatches /document-release) and names the genuinely-uncovered path as a main-move bypassing BOTH orchestrators AND /ship — recovered by running /document-release by hand. This matches the design's CRITICAL FRAMING premise that /ship Step 18 shrank the original gap.
- [impl-finding] 2026-06-03: `scripts/generate-readme.sh` emits to STDOUT (does not write README.md in place); regenerated via `generate-readme.sh > README.md` (atomic temp+mv). README diff is the single CJ_document-release description line — confirms no hand-edit drift.
- [impl-finding] 2026-06-03: A stale workbench-owned doc-sync `post-rewrite` hook (+ doc-sync block in the live `post-merge`) was present in `.git/hooks/` from a prior setup-hooks.sh run. Removed the orphaned post-rewrite hook and re-ran setup-hooks.sh so the live environment matches the retired code; setup-hooks.test.sh then passes against the clean state.
- [impl-finding] 2026-06-03: Retirement-announcing prose (e.g., "F000028/F000029 ... retired by F000039") legitimately co-names the two feature IDs, so the SPEC AC#3 `F000028.*F000029` regex matches 4 archival lines. The two AUTHORITATIVE return-greps (#1 retired tokens, #2 fallback language) are BOTH empty; kept the retirement notes since removing the IDs would make the history ungreppable.
- [impl] 2026-06-03: Wrote/edited 16 repo files + 2 archival tracker notes; deleted 3 files via `git rm`. validate.sh PASS (0 errors/0 warnings, Checks 14/15/16/17 green), test.sh PASS (0 failures incl. survivor wiring runner + setup-hooks guards), standalone cj-goal-doc-sync-wiring.test.sh + setup-hooks.test.sh both PASS.
- [impl-auto] 2026-06-03: --auto run. Change spans a sensitive surface (skills-catalog.json, validators/tests, git-hook installer) and >2 files, so per the skill's safety override this is a propose-class change; the orchestrator pre-authorized the enumerated sensitive surface (design approval gate), so it proceeded without an AUQ (runner has no AskUserQuestion tool).
- [impl-pass] S000072: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-03 [qa-smoke] S1 (AC-8): green — ./scripts/validate.sh exit 0, RESULT: PASS, 0 errors / 0 warnings (Checks 14/15/16/17 all PASS).
- 2026-06-03 [qa-smoke] S2 (AC-8): green — ./scripts/test.sh exit 0, RESULT: PASS, 0 failures; no references to the 3 deleted files; survivor cj-goal-doc-sync-wiring runner ran + passed inside the suite.
- 2026-06-03 [qa-smoke] S3 (AC-5): green — bash tests/cj-goal-doc-sync-wiring.test.sh exit 0, PASS (Step 5.5 + [doc-sync-red]/[doc-sync-non-doc-write] halt rows present + correctly ordered in all 3 orchestrators).
- 2026-06-03 [qa-smoke] S4 (AC-1, AC-2): green — authoritative completeness grep #1 (skills/ doc/ scripts/ CLAUDE.md README.md skills-catalog.json) returned ZERO live references to retired tokens. TEST-SPEC's broader variant surfaces one pre-existing TODOS.md request row (out of de-referencing scope; not touched by this impl per git diff HEAD).
- 2026-06-03 [qa-smoke] S5 (AC-3): green — authoritative completeness grep #2 (marker-AUQ|Coexistence with F000029|stays as fallback) returned ZERO. TEST-SPEC's broader F000028.*F000029 variant matches only 4 retirement-announcing archival lines (documented [impl-finding]; IDs intentionally retained for greppable history).
- 2026-06-03 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-03 [qa-e2e-run-start] RUN_ID=20260603-150541-99768 commit=ff22704
- 2026-06-03 [qa-e2e] E1 (AC-1): green — `ls` of all 3 dead files reports "No such file or directory" (scripts/skills-doc-sync-check, tests/skills-doc-sync-check.test.sh, tests/cj-goal-doc-sync-auq-recommendation.test.sh).
- 2026-06-03 [qa-e2e] E2 (AC-2): green — zero hits for skills-doc-sync-check / DOC_SYNC_PENDING in both skills/CJ_goal_feature/SKILL.md and skills/CJ_goal_defect/SKILL.md (preamble fence + AUQ prose gone).
- 2026-06-03 [qa-e2e] E3 (AC-4): green — setup-hooks.sh in a scratch git checkout installs pre-commit + post-merge only; post-rewrite absent; post-merge has no doc-sync/Section-3 block (installer output names only Sections 1+2).
- 2026-06-03 [qa-e2e] E4 (AC-5): green — survivors present (cj-document-release.json, scripts/cj-document-release-config.sh, tests/cj-goal-doc-sync-wiring.test.sh); Step 5.5 prose + [doc-sync-red] rows intact in all 3 orchestrators; config-helper comments no longer name the deleted script.
- 2026-06-03 [qa-e2e] E5 (AC-6, AC-7): green — CLAUDE.md "## Doc-sync coverage" note covers Step 5.5 + /ship Step 18 + manual-by-hand recovery; generate-readme.sh produces zero diff vs on-disk README.md.
- 2026-06-03 [qa-e2e-summary] green (0s subagent; 0 rows parent-inline; 0 deferred): All 5 E2E criteria green (E1-E5). Executed leaf-inline by the QA runner (all rows read-only). Tracker journal updated.
- 2026-06-03 [qa-pass] S000072 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
