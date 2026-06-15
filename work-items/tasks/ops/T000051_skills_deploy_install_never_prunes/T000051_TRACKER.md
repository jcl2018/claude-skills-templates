---
name: "`skills-deploy install` never prunes shared scripts deleted from source — orphaned `_cj-shared/scripts/*` accumulate (P3, S)"
type: task
id: "T000051"
status: active
created: "2026-06-15"
updated: "2026-06-15"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/dazzling-jemison-feb6e8"
branch: "claude/dazzling-jemison-feb6e8"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/skills_deploy_install_never_prunes`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/skills_deploy_install_never_prunes/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
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
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: `skills-deploy install` never prunes shared scripts deleted from source — orphaned `_cj-shared/scripts/*` accumulate (P3, S)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-15: Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### `skills-deploy install` never prunes shared scripts deleted from source — orphaned `_cj-shared/scripts/*` accumulate (P3, S)
- 2026-06-15: Implemented (commit `5348a5d`). `skills-deploy install` now prunes manifest-tracked `_cj-shared/scripts/*` orphans with no source counterpart (file + manifest), keyed off `.shared_scripts` keys so hand-placed untracked files are never touched; `doctor` gains a `--- Shared scripts ---` health section (ORPHAN/FAIL/WARN/OK). New regression case in `scripts/test-deploy.sh`. Verified: test-deploy + validate + full test.sh green, shellcheck clean. Orphans expected to clear on the next real install: `test-pipeline.sh`, `gate-spec.sh`, `generate-doc-views.sh`, `cj-document-release-config.sh`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/skills-deploy` — `do_install`: prune block (manifest-keyed orphan removal of `_cj-shared/scripts/*` with no source counterpart) + `shared_pruned` counter + summary line; `do_doctor`: new `--- Shared scripts ---` health section (ORPHAN/FAIL/WARN/OK).
- `scripts/test-deploy.sh` — new regression case `T000051: install prunes orphaned shared scripts (ownership-safe)` (isolated shared-scripts target; asserts manifest-tracked orphan pruned from file + manifest, hand-placed untracked file survives, real tracked script kept).
- `work-items/tasks/ops/T000051_skills_deploy_install_never_prunes/{T000051_TRACKER.md,test-plan.md}` — tracker + test-plan updates.

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal_todo_fix -->

`scripts/skills-deploy install` adds + updates shared scripts into `~/.claude/_cj-shared/scripts/` (and per-skill files), but never REMOVES a shared script that has since been deleted from the source `scripts/` set. A retired script therefore lingers in the install as dead weight: nothing references it, but it can mislead a reader into thinking the surface is still live, and `post-land-sync` reinstalls don't clear it. Observed: `test-pipeline.sh` (retired by F000060) and `gate-spec.sh` (retired by F000063/v6.0.68) both survived reinstalls in `~/.claude/_cj-shared/scripts/` — gate-spec.sh was swept by hand during the F000063 land, test-pipeline.sh is still orphaned. `skills-deploy remove`/`doctor` reconcile per-skill + template orphans, but not shared-script orphans.
**Proposal:** teach `skills-deploy install` (or `doctor`) to reconcile `~/.claude/_cj-shared/scripts/` against the shared-script set the source actually deploys — prune (install) or report (doctor) any deployed shared script with no source counterpart. Manifest-track shared scripts with checksum + ownership so the prune is safe, mirroring the existing template-orphan path.
**Route:** `/CJ_goal_task "prune orphaned _cj-shared shared scripts on skills-deploy install"` — touches `scripts/skills-deploy` (the shared-script install + doctor paths) + a `tests/test-deploy.sh` case; S-sized.
**Reference:** surfaced 2026-06-13 during the F000063 / PR #265 land (v6.0.68 — gate-spec.sh retirement); `scripts/skills-deploy` shared-scripts deploy path; orphans observed in `~/.claude/_cj-shared/scripts/` (`gate-spec.sh` swept, `test-pipeline.sh` remaining).


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### `skills-deploy install` never prunes shared scripts deleted from source — orphaned `_cj-shared/scripts/*` accumulate (P3, S) -->
- 2026-06-15 [qa-smoke] S1 (test-plan row 1): green — `scripts/test-deploy.sh` 86 OK / 0 FAIL; new case `T000051: install prunes orphaned shared scripts (ownership-safe)` passes (orphan pruned from file + manifest, hand-placed untracked file survived, real tracked script kept).
- 2026-06-15 [qa-smoke-summary] green: 1/1 non-manual rows green (0 manual rows pending)
- 2026-06-15 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom~suite-test-deploy purpose amended,doc-spec-custom:none (Step 8.6a/8.6b ran inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-15 [qa-pass] T000051 (task): green smoke from test-plan rows (1 row). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-06-15 [qa-audit-fix] post-sync audit raised stage2/suite-test-deploy (the 8.6a purpose claimed `doctor` shared-scripts coverage the T000051 case did not exercise). Resolved per operator (add-assertion, not waive): the T000051 case now runs `skills-deploy doctor` and asserts the `--- Shared scripts ---` section flags `ORPHAN: zzz-orphan.sh` before the prune + clears it (surviving script `OK:`) after. test-deploy green; the purpose claim is now backed by a live assertion.
