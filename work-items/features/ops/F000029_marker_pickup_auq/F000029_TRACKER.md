---
name: "Marker-pickup AUQ in cj_goal preambles (closes F000028 doc-sync loop)"
type: feature
id: "F000029"
status: active
created: "2026-05-30"
updated: "2026-05-30"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260530-222955-29095"
blocked_by: ""
---

> **RETIRED by F000039 (2026-06-03).** The `DOC_SYNC_PENDING` marker-pickup AUQ
> + `skills-doc-sync-check` reader shipped by this feature were removed once
> F000036's inline Step 5.5 doc-sync made them redundant. This tracker is kept
> as archival history only. See
> `work-items/features/ops/F000039_retire_doc_sync_marker_mechanism/`.

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/marker_pickup_auq`
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

- [ ] New file `scripts/skills-doc-sync-check` exists, is executable, and structurally mirrors `scripts/skills-update-check` (passes shellcheck).
- [ ] Each of the 3 cj_goal SKILL.md preambles (`cj_goal_feature`, `cj_goal_defect`, `CJ_goal_investigate`) contains a minimal sibling bash block (≤5 lines) that calls `skills-doc-sync-check`, plus the AUQ-instruction prose block. All three blocks are identical modulo skill-name.
- [ ] On a clean cache + present marker, `bash scripts/skills-doc-sync-check` prints `DOC_SYNC_PENDING <marker-path>` to stdout, exits 0.
- [ ] `--snooze 24` suppresses subsequent invocations for 24h; after expiry, AUQ fires again.
- [ ] `--skip <head_sha>` suppresses subsequent invocations for that marker `head_sha`; new marker (different `head_sha`) re-fires.
- [ ] `--resolved` deletes marker + clears snooze/skip cache; idempotent silent-success when marker is already absent.
- [ ] Stale `head_sha` (unreachable from HEAD) triggers silent delete + no AUQ.
- [ ] New flat-convention test file `tests/skills-doc-sync-check.test.sh` covers all 8 behaviors from the design's Success Criteria (a–h).
- [ ] `./scripts/validate.sh` passes with 0 errors, 0 warnings (new script passes shellcheck).
- [ ] `./scripts/test.sh` passes (new test file invoked).
- [ ] CLAUDE.md "Update-check mechanism (F000009)" section gains a sibling subsection "Doc-sync check mechanism (F000028 follow-up)" documenting the novel-pattern callout.
- [ ] Real `/cj_goal_feature` invocation against a repo with a present marker surfaces the AUQ correctly with all 3 marker fields (`head_sha`, `main_moved_at`, `changed_files`); no-marker case stays silent (no regression).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000062 (`marker_pickup_auq_impl`) — implementation user-story (script + 3 preamble edits + CLAUDE.md doc + tests)
- [ ] End-to-end pipeline run — `/cj_goal_feature` invocation with a planted marker surfaces the AUQ correctly

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-30: Created. Marker-pickup AUQ in cj_goal preambles — closes F000028's open follow-up #1 by wiring the dropped marker into the operator-facing AUQ in each cj_goal orchestrator preamble.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/skills-doc-sync-check` (NEW)
- `tests/skills-doc-sync-check.test.sh` (NEW)
- `skills/cj_goal_feature/SKILL.md` (MODIFIED — preamble + AUQ-instruction prose)
- `skills/cj_goal_defect/SKILL.md` (MODIFIED — preamble + AUQ-instruction prose)
- `skills/CJ_goal_investigate/SKILL.md` (MODIFIED — preamble + AUQ-instruction prose)
- `CLAUDE.md` (MODIFIED — "Doc-sync check mechanism (F000028 follow-up)" sibling subsection)
- `CHANGELOG.md` (MODIFIED — entry for F000029)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **Mirrors a proven workbench pattern.** F000009's `skills-update-check` has been live for months; the script-output-then-AUQ-from-SKILL.md shape is just one more consumer of the same convention. No new architecture; one script to evolve.
- **Novel pattern callout (reviewer-flagged).** F000009 emits a user-facing banner (`SKILLS_UPGRADE_AVAILABLE`) with no AUQ — operator dismisses it implicitly. Here the script output (`DOC_SYNC_PENDING`) drives an orchestrator AUQ. SKILL.md instruction must be explicit with a copy-paste AUQ template (the script can't AUQ itself).
- **Step 1.9 isolation-gate collision avoided by ordering.** Marker check + `/document-release` must run BEFORE worktree creation (at operator cwd on main); afterward auto-commit any doc-only changes via `git commit -m "docs: post-merge sync for <slug>"`. Skipping the commit would leave a dirty checkout and HALT Step 1.9 with `[feature-not-isolated]`.
- **Feature-branch / Conductor edge case.** When invoked from inside a worktree (non-main branch), running `/document-release` would produce wrong doc state. AUQ-instruction prose handles this: detect branch via `git symbolic-ref --short HEAD`, downgrade recommendation from "Run now" → "Snooze 1h".
- **No per-session PID dedup.** `$$` is unstable across SKILL.md bash fences (each fence is a fresh bash subprocess). Dedup happens via subcommands: `--resolved` deletes marker (next check silent), `--snooze` suppresses by clock, `--skip` suppresses by head_sha.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-30 [decision] Chose Approach C (new script + per-preamble call) over Approach A (per-skill preamble only) or Approach B (new `/CJ_doc_sync` skill). Summary: single evolution surface for detection logic, mirrors proven F000009 pattern, no new skill in the catalog, each preamble grows by 2–3 lines.
- 2026-05-30 [decision] Removed `prompted_session` field from cache. Summary: `$$` not stable across SKILL.md bash fences (reviewer-flagged P0); dedup achieved naturally via `--resolved`/`--snooze`/`--skip` subcommands instead.
- 2026-05-30 [decision] Run marker check BEFORE worktree creation, not after. Summary: avoids Step 1.9 isolation-gate `[feature-not-isolated]` HALT on dirty checkout; `/document-release` writes uncommitted doc changes that get auto-committed before yielding to worktree phase.
- 2026-05-30 [decision] Feature-branch detection lives in SKILL.md prose, not in the script. Summary: keeps script's single job ("is there a marker?") clean; branch-aware AUQ option ordering belongs in the orchestrator.
