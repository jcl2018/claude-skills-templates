---
name: "Branch(g) full PR-state detection for `/CJ_run` (P2, M)"
type: task
id: "T000026"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "fix/branch-g-pr-state-T000026"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/branch_g_full_pr_state_detection_for_cj`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/branch_g_full_pr_state_detection_for_cj/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [x] `/ship` — PR created
- [x] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: Branch(g) full PR-state detection for `/CJ_run` (P2, M)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-14: Created. Auto-scaffolded by /CJ_goal from TODOS.md ### Branch(g) full PR-state detection for `/CJ_run` (P2, M)

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #113: v3.5.3 fix: T000026 /CJ_run Branch(g) full PR-state dedup (TODOS:123) [via /CJ_goal]](https://github.com/jcl2018/claude-skills-templates/pull/113) — MERGED

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- modified: `templates/CJ_personal-workflow/tracker-user-story.md` — added optional `pr:` frontmatter field (commented placeholder; backwards-compatible additive change)
- modified: `skills/CJ_run/run.md` — extended Branch(g) candidate filter with PR-state dedup (gh pr view + per-invocation cache, default-permissive on lookup failure)

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal -->

Branch(g)'s current candidate filter uses TRACKER Phase 1/2/3 gate states to determine "in-progress" — it doesn't call `gh pr view` because the user-story TRACKER template has no `pr:` frontmatter field (PR links live in a Markdown `## PRs` section). This works correctly for the common case (gates accurately reflect ship state), but a tracker with `[x]` gates that was force-merged or manually edited could slip past. **Fix sketch:** (a) extend `tracker-user-story.md` with an optional `pr:` frontmatter field plus a section parser that recognizes both styles; (b) call `gh pr view "$PR_URL" --json state` with a cache to avoid N round-trips per candidate; (c) gate Branch(g) on `MERGED` state for explicit deduplication. **When:** when a false positive surfaces in real use; for now the gate-state filter catches all known shipped work-items. **Reference:** pre-landing review on F000017 S000038 (2026-05-13).


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### Branch(g) full PR-state detection for `/CJ_run` (P2, M) -->

- 2026-05-15T06:46:05Z [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/ops/T000026_branch_g_full_pr_state_detection_for_cj; scaffold skipped.
- 2026-05-15 [impl-decision] Reused Branch(f)'s dual-convention PR URL extraction (frontmatter `pr:` + ## PRs section regex) verbatim — taste decision per duplication-over-abstraction for ~6 lines.
- 2026-05-15 [impl-decision] Cache is a parallel-array memo (Bash 3.2 compat — no associative arrays). N round-trip avoidance is the value; ordering doesn't matter.
- 2026-05-15 [impl-decision] Default-permissive on `gh pr view` failure (offline / unauthenticated / unknown state → include candidate). Operator chooses at multi-candidate AUQ rather than getting silent exclusion.
- 2026-05-15 [impl-finding] Added optional `pr:` frontmatter field as a *commented* line in the template (with usage hint). Active opt-in keeps the template uncluttered for the common case while making the field discoverable.
- 2026-05-15 [impl] Modified 2 files (templates/CJ_personal-workflow/tracker-user-story.md, skills/CJ_run/run.md). validate.sh: 0 errors / 0 warnings. bash -n on modified Step 1.0.g block: OK.
- 2026-05-15 [impl-auto] Auto-mode run; --auto allowed (2 files, sensitive surface=template change — propose-mode auto-demote rule did NOT fire because /CJ_personal-pipeline's pre-collected AUQ already approved the sensitive-surface change at Step 5.2.
- 2026-05-15 [impl-pass] T000026: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-05-15T06:51:21Z [qa-smoke-manual] 1 (T000026): pending human verification — Manual verification: Branch(g) full PR-state detection for /CJ_run (P2, M); inspect modified Step 1.0.g block + tracker-user-story.md frontmatter addition
- 2026-05-15T06:51:21Z [qa-smoke-summary] green: 0/0 non-manual rows green (1 manual row pending)
- 2026-05-15T06:51:21Z [qa-pass] T000026: smoke verdict green (0 non-manual rows; 1 manual row pending operator verification). validate.sh clean (0 errors / 0 warnings). bash -n on modified Step 1.0.g block: OK. Implementation matches TODO body (3-part fix sketch: a/b/c).
- 2026-05-15T06:51:48Z [auto-final-gate-suppressed] 0 mechanical, 0 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
- 2026-05-14 [gates-update] Phase 3: /ship — PR #113,/land-and-deploy — PR merged,PRs section: linked PR #113 (MERGED).
