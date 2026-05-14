---
name: "/CJ_run end-to-end — suppress /land-and-deploy readiness gate"
type: feature
id: "F000018"
status: active
created: "2026-05-13"
updated: "2026-05-13"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/modest-meitner-0c7600"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_run_suppress_readiness_gate`
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

- [ ] Running `/CJ_run <approved-design-doc>` end-to-end on an all-green pipeline produces zero `/land-and-deploy` readiness-gate AUQs; only two AUQs surface (autoplan final approval + /ship diff review).
- [ ] Running `/CJ_run <work-item-dir>` in Branch(f) `open_pr` mode auto-continues into `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` with the same PR-num parsing as Step 5.
- [ ] If free tests fail at /land-and-deploy time, /CJ_run halts cleanly with `END_STATE=halted_at_deploy`.
- [ ] Direct invocation of `/land-and-deploy` (without /CJ_run, no flag) preserves today's behavior bit-for-bit.
- [ ] Cross-version compatibility: new workbench + old gstack → flag ignored, no regression. New gstack + old workbench → flag default off, no regression.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000040 — workbench-side change (run.md Step 5 + Branch(f) open_pr + SKILL.md description + version bump + CHANGELOG)
- [ ] (Out of scope here, user owns by hand) gstack PR: add `--suppress-readiness-gate` flag to `/land-and-deploy`

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-13: Created. /CJ_run end-to-end — suppress /land-and-deploy readiness gate when running under the pipeline.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_run/run.md`
- `skills/CJ_run/SKILL.md`
- `CHANGELOG.md`
- `VERSION`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The /CJ_run chain into /land-and-deploy already exists; the friction is one specific AUQ (Step 3.5e), not the chain itself.
- Mirrors the proven `--suppress-final-gate` pattern from /CJ_personal-pipeline — same shape extends naturally.
- Opt-in semantics (flag must be passed) protect direct callers; rollback is clean (stop passing the flag).
- Cross-version compatibility is symmetric: order-of-operations between the gstack PR and the workbench PR doesn't matter; users see no regression in either order.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-13: Picked Approach A (upstream flag) over Approach B (global redesign). Blast radius matters; opt-in beats opt-out for behavior changes other people depend on.
- [decision] 2026-05-13: PR_NUM parsing path → inline duplicate preferred (from /autoplan Phase 1 taste decision).
- [decision] 2026-05-13: Flag name → `--suppress-readiness-gate` (from /autoplan Phase 1 taste decision).
- [decision] 2026-05-13: gstack PR is OUT OF SCOPE for this work-item; only workbench-side changes scaffolded here. User owns gstack PR by hand.
