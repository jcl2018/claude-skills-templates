---
name: "fork-aware-update-detection"
type: task
id: "T000015"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/personal-pipeline"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed — N/A standalone task; design doc reviewed instead)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [x] `/ship` — PR created
- [x] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Read `scripts/skills-update-check` to locate the `git fetch origin main` block.
- [x] Add a 4-6 line fallback: detect whether `origin/main` exists as a tracking ref; if not, try `upstream/main` instead.
- [x] Apply the same logic to the `git show {remote}/main:VERSION` step that reads the remote's collection version.
- [x] Ensure both remotes absent silently no-ops (no stderr spam) per design AC.
- [x] Smoke: run `validate.sh` PASS post-change.
- [x] Smoke: simulate fork checkout (`origin/main` removed, `upstream/main` added) and confirm banner emits.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-09: Created. Scaffolded from /office-hours design doc `chjiang-feat-personal-pipeline-design-bootstrap-1778371110.md` — bootstrap run for /personal-pipeline orchestrator. Adds `upstream/main` fallback to `scripts/skills-update-check` so fork users see the upgrade banner.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #73: v1.13.0 feat: F000014 /personal-pipeline orchestrator + T000015 fork-aware update detection](https://github.com/jcl2018/claude-skills-templates/pull/73) — MERGED

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/skills-update-check` — add `upstream/main` fallback before fetch + show steps.

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- Captured originally as TODOS.md:8 (P3, S). The original F000009 update-check infrastructure called fork-aware detection "out of scope for v1" (see CLAUDE.md F000009 section). This task closes that gap.
- The fallback must be silent when both remotes are absent: don't spam errors, just skip the check. The existing `2>/dev/null || true` pattern in the preamble snippet is the contract this needs to honour.
- Bootstrap context: this is also the first real /personal-pipeline run — small, well-scoped, and exercises the scaffold → implement → qa loop end-to-end without taking on real architectural risk.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-09 [impl-decision] Used `git config --get remote.<name>.url` to detect remote configuration rather than `git rev-parse --verify <remote>/main` — config check works pre-fetch (no tracking ref required yet on a fresh fork clone) and is the lightest-weight existence check. Origin preferred, upstream as fallback, neither → silent exit 0.
- 2026-05-09 [impl-finding] The 4-6 line fallback fits cleanly inside the existing `if [ "$need_fetch" = "1" ]` block before the fetch invocation, keeping the change surgical (single Edit, 12 lines added including comment) and preserving the cache-fallback path on the outside.
- 2026-05-09 [impl] Modified 1 file (scripts/skills-update-check); inserted fork-aware remote resolution before the fetch step. Smoke tests verified all 4 test-plan rows: origin-only banner emits, upstream-only fork banner emits, both-remotes-absent silent no-op, both-remotes-present origin wins. validate.sh PASS, test.sh PASS.
- 2026-05-09 [impl-pass] T000015: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files).
- 2026-05-09 [qa-smoke] 1 (test-plan row 1): green — origin/main only, banner emits `SKILLS_UPGRADE_AVAILABLE 1.0.0 99.0.0` (isolated temp-repo simulation; exit 0).
- 2026-05-09 [qa-smoke] 2 (test-plan row 2): green — upstream/main only (fork), banner emits via upstream fallback `SKILLS_UPGRADE_AVAILABLE 1.0.0 99.0.0` (origin remote absent, only upstream configured; exit 0).
- 2026-05-09 [qa-smoke] 3 (test-plan row 3): green — both remotes absent, no banner, no stderr (0 lines output, exit 0). Silent no-op contract honored.
- 2026-05-09 [qa-smoke] 4 (test-plan row 4): green — both remotes present (origin VERSION=99.0.0, upstream VERSION=50.0.0), banner emits using origin/main — `SKILLS_UPGRADE_AVAILABLE 1.0.0 99.0.0`. Origin preferred over upstream as designed.
- 2026-05-09 [qa-smoke-summary] green: 4/4 non-manual rows green (0 manual rows pending). Verification Steps row 1 (`./scripts/validate.sh`) PASS post-change.
- 2026-05-09 [qa-pass] T000015 (task): green smoke from test-plan rows (4 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-09 [gates-update] Phase 3: /ship — PR #73,/land-and-deploy — PR merged,PRs section: linked PR #73 (MERGED).
