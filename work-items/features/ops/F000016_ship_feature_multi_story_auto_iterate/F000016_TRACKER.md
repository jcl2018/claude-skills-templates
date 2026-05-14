---
name: "/CJ_ship-feature multi-story auto-iterate (per-child branches)"
type: feature
id: "F000016"
status: active
created: "2026-05-13"
updated: "2026-05-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/awesome-pasteur-36565c"
branch: "claude/awesome-pasteur-36565c"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/{slug}`
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

- [ ] `/CJ_ship-feature <multi-story-feature-design-doc>` runs end-to-end without manual intervention for a 2-child feature on the happy path
- [ ] Each child story creates its own branch off main and its own PR
- [ ] Each child PR diff contains only that child's scaffold + impl+qa changes (not the sibling children)
- [ ] No AUQs fire between /autoplan completion and each child's /ship diff-review
- [ ] If child N fails (impl or QA red), the wrapper halts, reports the failure, and leaves the repo on the feature branch (recoverable state)
- [ ] `CJ_personal-pipeline --work-item-dir <dir>` works in standalone (non-wrapper) mode — not just when called from ship-feature

## Todos

- [ ] S000036: add `--work-item-dir` flag to `pipeline.md` (Step 1 arg parsing + Step 2 Branch e) and update `SKILL.md` usage docs
- [ ] S000037: rewrite Branch (b) in `run.md` to enumerate children, loop per-child branch creation + pipeline dispatch + /ship + /land-and-deploy
- [ ] Version bumps: `CJ_personal-pipeline` 0.1.0 → 0.2.0, `CJ_ship-feature` 0.1.0 → 0.2.0, `skills-catalog.json` both entries
- [ ] Run `./scripts/validate.sh` after implementation
- [ ] Run `./scripts/skills-deploy install` to sync deployed skills

## Log

- 2026-05-13: Created. Extends CJ_personal-pipeline with --work-item-dir flag and rewrites run.md Branch (b) to auto-iterate per child story. Design approved in /office-hours session (Approach B chosen).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_personal-pipeline/pipeline.md`
- `skills/CJ_personal-pipeline/SKILL.md`
- `skills/CJ_run/run.md`
- `skills-catalog.json`

## Insights

- Approach B (per-child branch loop + `--work-item-dir` extension) is the only approach that satisfies P2 (extends pipeline), P3 (per-child branches), P4 (suppressed AUQs). Approach A (run.md patch only) violates P3 and P4. Approach C (synthetic design docs) is slow and fragile.
- `--work-item-dir` flag makes the pipeline a first-class interface for pre-scaffolded work items, reusable beyond ship-feature. Design choice: extend at the interface level, not just the call site.
- Gate count in multi-story mode: Gate #1 = /autoplan final approval (once), Gate #2...N+1 = /ship diff-review per child (N gates). Update run.md Decision Gates section to reflect "2 for single-story / 1 + N for multi-story."
- Context size note: inline Skills for /ship + /land-and-deploy add ~4K tokens per child. v1 may limit to N ≤ 3 children; N > 3 dispatches as Agent subagents to prevent compaction.
- Parent TRACKER copy per child PR (reviewer convenience) is deferred to a follow-up.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
