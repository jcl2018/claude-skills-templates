---
name: "Pipeline parity: per-type implement/qa + Step 18 comma-split fix"
type: feature
id: "F000012"
status: active
created: "2026-05-08"
updated: "2026-05-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-parity"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-pipeline-parity-design-20260508-180219.md
     Closes two F000010 polish gaps (TODOS.md #5 and #6) as a single feature.
     Approach A (generalize per-type) chosen over B/C/D in scoping conversation. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/pipeline-parity`
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

1. Run `/personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `/implement-from-spec` accepts defect work-items and reads RCA + test-plan instead of hard-failing.
- [ ] `/qa-work-item` accepts defect work-items and reads test-plan instead of hard-failing.
- [ ] Both skills preserve existing user-story behavior identically (regression-free for the today-path).
- [ ] `/personal-workflow check` Step 18 prose explicitly handles comma-separated AC cells; running `check` on F000010 produces no false `[UNTESTED]` findings on multi-AC P0 stories.
- [ ] Test suite extended with: implement-on-defect happy path, qa-on-defect happy path, Step 18 multi-AC TEST-SPEC fixture.

## Todos

- [ ] S000021: per-type implement/qa pipeline branching (the bigger refactor; ship first)
- [ ] S000022: Step 18 traceability comma-split fix (rides through new defect path as integration test)
- [ ] Cross-story: extend test suite covering both new code paths

## Log

- 2026-05-08: Created. Closes F000010 polish gaps (#5 and #6 from TODOS.md) under one feature.

## PRs

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/implement-from-spec/SKILL.md` (per-type branching)
- `skills/implement-from-spec/implement.md` (per-type input artifact resolution)
- `skills/qa-work-item/SKILL.md` (per-type branching)
- `skills/qa-work-item/qa.md` (per-type input artifact resolution)
- `skills/personal-workflow/check.md` (Step 18 comma-split clarification)
- `TODOS.md` (mark #5 and #6 done after merge)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The two TODOs are naturally coupled: the small bug (#5) becomes the integration test for the medium refactor (#6) once defects can flow through the pipeline.
- Per-type branching plumbing already exists in `/scaffold-work-item` (it accepts all 4 types). The asymmetry (only `/scaffold-work-item` accepts all types) is the actual defect; `/implement-from-spec` and `/qa-work-item` were built user-story-first and never extended.
- Step 18 is a prose-spec bug, not a code bug — `check.md` is interpreted by the LLM running `/personal-workflow check`. Tightening the prose IS the fix.

## Journal

<!-- Structured entries from the work-track journal command. -->

- 2026-05-08 [decision] Bundled #5 and #6 into one feature (per user direction in scoping). Story 2 acts as integration test for Story 1's new defect path.
- 2026-05-08 [decision] Approach A (generalize per-type) over B (sibling skills) / C (dispatcher) / D (accept). Existing type-detection in `/scaffold-work-item` provides the model; pipeline uniformity is the long-term win.
