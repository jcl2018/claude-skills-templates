---
name: "Retire the F000028/F000029 doc-sync marker + preamble-AUQ mechanism"
type: feature
id: "F000039"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-140631-39060"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/retire_doc_sync_marker_mechanism`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0 (no references to deleted test files; no orphaned assertions).
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` STILL passes (F000036 Step 5.5 survivor coverage intact).
- [ ] Completeness grep #1 (`skills-doc-sync-check|DOC_SYNC_PENDING|doc-sync-pending|doc-sync-cache`), excluding `work-items/`, `CHANGELOG.md`, `.gstack/` → ZERO live references.
- [ ] Completeness grep #2 (`marker-AUQ|F000029.*fallback|Coexistence with F000029|F000028.*F000029`) across `skills/ doc/ README.md CLAUDE.md skills-catalog.json` → ZERO live references describing it as current behavior.
- [ ] Both orchestrator preambles (`CJ_goal_feature`, `CJ_goal_defect`) no longer contain the doc-sync block.
- [ ] `setup-hooks.sh` still installs pre-commit validate + F000009 post-merge auto-sync (Sections 1+2); post-merge Section 3 + the post-rewrite hook are gone.
- [ ] `README.md` regenerated from the catalog (not hand-edited) and consistent with `skills-catalog.json`.
- [ ] Accepted-gap note exists in `CLAUDE.md`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000072 — execute the full retirement surface (delete files, edit preambles, strike fallback language, surgical hook + test edits, doc deletes, comment cleanup).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Retire the F000028/F000029 doc-sync marker + preamble-AUQ mechanism (redundant since F000036 made doc-sync run inline at Step 5.5); document the narrow non-/ship, non-orchestrator gap rather than leaving a dead writer/reader pair.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/skills-doc-sync-check` (DELETE)
- `tests/skills-doc-sync-check.test.sh` (DELETE)
- `tests/cj-goal-doc-sync-auq-recommendation.test.sh` (DELETE)
- `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md` (preamble block removal)
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_todo_fix/pipeline.md` (strike fallback parenthetical, keep Step 5.5)
- `skills/CJ_document-release/SKILL.md`, `skills/CJ_document-release/USAGE.md` (remove fallback language)
- `doc/SKILL-CATALOG.md`, `doc/ARCHITECTURE.md`, `doc/PHILOSOPHY.md` (remove F000028/F000029 sections + cross-refs)
- `skills-catalog.json` (CJ_document-release description: drop F000029-fallback clause; byte-match item 9 frontmatter)
- `README.md` (regenerate via `scripts/generate-readme.sh`)
- `scripts/setup-hooks.sh` (remove post-merge Section 3 + post-rewrite hook; keep pre-commit + Sections 1+2)
- `tests/setup-hooks.test.sh`, `scripts/test.sh` (surgical test edits)
- `CLAUDE.md` (delete doc-sync section; add accepted-gap note)
- `scripts/cj-document-release-config.sh` (comment cleanup; KEEP file)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- "doc-sync" names TWO mechanisms: the F000028/F000029 marker-AUQ (DIES) and the F000036 inline Step 5.5 (LIVES). An adversarial review caught a delete targeting the survivor. The retirement surface is split explicitly so the build doesn't repeat that.
- The TODO's stated risk ("a direct /ship outside any orchestrator moves main with no inline Step 5.5") was a false premise: `/ship` already dispatches `/document-release` on every invocation (ship/SKILL.md:2873), so docs land in the PR. The only genuinely uncovered path is a main-move that bypasses BOTH orchestrators AND /ship — rare and manually recoverable.
- The retired preamble AUQ block lives in exactly 2 SKILL.md files; the stale "F000029 stays as fallback" sentence is duplicated across ~9 live locations. Two completeness greps (4-token + fallback-language) are needed; the first misses the prose.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: Chose Approach A (full delete + document the narrow gap) over Approach B (lightweight post-merge reminder — keeps a hook alive for a rare path, easy to ignore) and Approach C (drop only the AUQ — leaves dead code + orphaned state-file writers). Summary: complete retirement, no dead code or orphaned state-file writers, kills the operator-flagged AUQ, matches real coverage; accepted con is a manual merge bypassing /ship won't be auto-flagged (manually recoverable).
- [decision] 2026-06-03: KEEP `scripts/cj-document-release-config.sh` (it is the F000037 cj-document-release.json parser); only fix its two stale "mirrors skills-doc-sync-check" comments that become dangling references to the deleted script.
- [decision] 2026-06-03: Add a one-line "RETIRED by F000039" note to the F000028/F000029 TRACKERs for archival traceability; preserve the work-item history dirs.
