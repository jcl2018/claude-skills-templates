---
name: "Branch(f) work-item-dir input mode + phase-detection dispatch"
type: user-story
id: "S000039"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000017"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/awesome-pasteur-36565c"
blocked_by: "F000016"
---

<!-- Blocks on F000016 (specifically S000036's --work-item-dir flag for the
     impl_qa_ship dispatch). Other dispatch modes (qa_ship, ship, open_pr,
     already_shipped) do not require F000016 but are grouped here for
     coherence of the Branch(f) implementation. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_run_branch_f` (or use parent's branch)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the parent F000017_DESIGN.md and source design doc
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Break into child tasks if scope warrants decomposition — N/A (atomic story)

**Gates:**
- [x] /office-hours design referenced (parent's F000017_DESIGN.md and source design)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped — N/A
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `skills/CJ_run/run.md` Step 1 detects work-item-dir input (arg is a directory with `*_TRACKER.md`)
- [ ] Phase-detection logic reads TRACKER gate strings and `pr:` field to determine MODE
- [ ] MODE values cover: `impl_qa_ship`, `qa_ship`, `ship`, `open_pr`, `already_shipped`, `pr_unknown_state`
- [ ] `impl_qa_ship` dispatches `CJ_personal-pipeline --work-item-dir "$WORK_ITEM_DIR"` (requires F000016/S000036)
- [ ] `qa_ship` dispatches `/CJ_qa-work-item "$WORK_ITEM_DIR"` then `/ship` + `/land-and-deploy`
- [ ] `ship` dispatches `/ship` + `/land-and-deploy`
- [ ] `open_pr` prints "PR already open at $PR_URL. Run /land-and-deploy to merge." and exits 0
- [ ] `already_shipped` prints "Already shipped. Nothing to do." and exits 0
- [ ] `pr_unknown_state` AUQs the user with the unexpected state and confirms next action
- [ ] PR-state check uses `gh pr view $PR_URL --json state -q .state` with graceful UNKNOWN fallback when gh is offline
- [ ] Branch(f) integrates with Branch(g) — Branch(g) selecting a candidate dispatches into Branch(f) for phase detection

## Todos

- [ ] Add Branch(f) detection at Step 1 of `run.md` (after Branch(g), before existing branches)
- [ ] Implement phase-state read (IMPL_GATE, QA_GATE, PR_URL extraction)
- [ ] Implement PR-state check with `gh pr view`
- [ ] Implement MODE dispatch table (5 modes + 1 unknown-state AUQ)
- [ ] Wire Branch(g) dispatch to call Branch(f) phase detection (single entry point)
- [ ] Smoke test each MODE with a fixture work-item in the test corpus
- [ ] Document the gate strings (canonical from `tracker-user-story.md`) in run.md comments

## Log

- 2026-05-13: Created. Atomic story for Branch(f) work-item-dir input mode + phase-detection dispatch table.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_run/run.md` (Branch(f) logic at Step 1; integrates with Branch(g) from S000038)

## Insights

- Phase detection uses verbatim gate strings from `tracker-user-story.md` Phase 2 Gates section. If those strings change, Branch(f) breaks silently. Add a comment pointing to the canonical template.
- PR state check via `gh` is best-effort: when gh is offline/unauthenticated, fall back to "treat as not-merged" (avoid blocking the dispatch).
- This story blocks on F000016 because `impl_qa_ship` dispatches to `CJ_personal-pipeline --work-item-dir`, which is the flag added by S000036.

## Journal

- 2026-05-13 [decision] Group all Branch(f) modes (impl_qa_ship, qa_ship, ship, open_pr, already_shipped, pr_unknown_state) into one story rather than split. Rationale: all six modes share the same gate-detection scaffolding; splitting would duplicate the code.
- 2026-05-13 [decision] `blocked_by: "F000016"` — strictly only impl_qa_ship mode depends on F000016, but the story ships as a unit. If F000016 is delayed, S000039 could partial-ship with impl_qa_ship marked as error; documented as a fallback in DESIGN.
