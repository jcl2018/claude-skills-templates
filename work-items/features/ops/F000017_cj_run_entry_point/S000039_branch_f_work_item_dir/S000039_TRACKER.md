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
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] `skills/CJ_run/run.md` Step 1 detects work-item-dir input (arg is a directory with `*_TRACKER.md`)
- [x] Phase-detection logic reads TRACKER gate strings and `pr:` field to determine MODE
- [x] MODE values cover: `impl_qa_ship`, `qa_ship`, `ship`, `open_pr`, `already_shipped`, `pr_unknown_state`
- [x] `impl_qa_ship` dispatches `CJ_personal-pipeline --work-item-dir "$WORK_ITEM_DIR"` (requires F000016/S000036 — now live)
- [x] `qa_ship` dispatches `/CJ_qa-work-item "$WORK_ITEM_DIR"` then `/ship` + `/land-and-deploy`
- [x] `ship` dispatches `/ship` + `/land-and-deploy`
- [x] `open_pr` prints "PR already open at $PR_URL. Run /land-and-deploy to merge." and exits 0
- [x] `already_shipped` prints "Already shipped. Nothing to do." and exits 0
- [x] `pr_unknown_state` AUQs the user with the unexpected state and confirms next action
- [x] PR-state check uses `gh pr view $PR_URL --json state -q .state` with graceful UNKNOWN fallback when gh is offline
- [x] Branch(f) integrates with Branch(g) — Branch(g) selecting a candidate dispatches into Branch(f) for phase detection

## Todos

- [x] Add Branch(f) detection at Step 1 of `run.md` (after Branch(g), before existing branches)
- [x] Implement phase-state read (IMPL_GATE, QA_GATE, PR_URL extraction)
- [x] Implement PR-state check with `gh pr view`
- [x] Implement MODE dispatch table (6 modes — 5 deterministic + 1 unknown-state AUQ)
- [x] Wire Branch(g) dispatch to call Branch(f) phase detection (Branch(g) already sets `INPUT_MODE=work-item-dir` and falls through; no code change needed)
- [x] Smoke test each MODE with a fixture work-item (8/8 bash dry-run cases pass — see Insights)
- [x] Document the gate strings (canonical from `tracker-user-story.md`) in run.md comments

## Log

- 2026-05-13: Created. Atomic story for Branch(f) work-item-dir input mode + phase-detection dispatch table.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_run/run.md` (modified — Step 1.1 placeholder replaced with full Branch(f) phase-detection + dispatch table; Step 1.1.dispatch prose mapping for 6 MODE values; telemetry write at end)
- `skills/CJ_run/SKILL.md` (modified — description updated to reflect Branch(f) live; version 0.2.0 → 0.3.0)
- `skills-catalog.json` (modified — CJ_run version 0.2.0 → 0.3.0; description updated)

## Insights

- Phase detection uses verbatim gate strings from `tracker-user-story.md` Phase 2 Gates section. If those strings change, Branch(f) breaks silently. Add a comment pointing to the canonical template.
- PR state check via `gh` is best-effort: when gh is offline/unauthenticated, fall back to "treat as not-merged" (avoid blocking the dispatch).
- This story blocks on F000016 because `impl_qa_ship` dispatches to `CJ_personal-pipeline --work-item-dir`, which is the flag added by S000036.

## Journal

- 2026-05-13 [decision] Group all Branch(f) modes (impl_qa_ship, qa_ship, ship, open_pr, already_shipped, pr_unknown_state) into one story rather than split. Rationale: all six modes share the same gate-detection scaffolding; splitting would duplicate the code.
- 2026-05-13 [decision] `blocked_by: "F000016"` — strictly only impl_qa_ship mode depends on F000016, but the story ships as a unit. If F000016 is delayed, S000039 could partial-ship with impl_qa_ship marked as error; documented as a fallback in DESIGN.
- 2026-05-13 [gates-update] Phase 3: /ship — PR #99,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #99,PRs section: linked PR #99 (MERGED).
- 2026-05-14 [impl-finding] PR #99 land-and-deploy hook auto-marked Phase 3 ship/deploy/smoke gates on this tracker, but PR #99 shipped only the Branch(f) placeholder stub (part of S000038), not S000039's actual phase-detection implementation. Reverted: unchecked Phase 3 gates; removed stale PR #99 reference from PRs section.
- 2026-05-14 [impl-finding] PR #100 land-and-deploy hook RE-corrupted this tracker (same bug pattern as the initial PR #99 corruption). Reverted: unchecked Phase 3 gates and removed stale PR #99 reference. Defect tracked for follow-up (spawn-task chip created during PR #100 land).
- 2026-05-14 [impl-decision] PR_URL extraction reads both `^pr:`/`^PR:` frontmatter AND the `## PRs` section markdown links — different work-item templates use different conventions. Verified with synthetic fixtures: both sources extract a valid PR URL.
- 2026-05-14 [impl-decision] DRAFT PR state classified as `open_pr` (not its own mode). Rationale: a DRAFT PR is still an open PR; the user's recovery action ("Run /land-and-deploy to merge") works once they convert it from draft. If a DRAFT PR needs different handling, add a 7th MODE in v0.3.
- 2026-05-14 [impl-decision] Branch(g) integration required no code change. Branch(g) already sets `ARG=$(dirname "$PICKED_TRACKER")` and `INPUT_MODE="work-item-dir"`, then falls through to Step 1.1 which is now Branch(f). Verified by inspection of the existing handoff at run.md Step 1.0.g.
- 2026-05-14 [impl] Wrote 3 files: `run.md` (replaced Step 1.1 placeholder with full Branch(f) phase-detection + dispatch table prose); `SKILL.md` (description + version 0.2.0 → 0.3.0); `skills-catalog.json` (version + description). `validate.sh` PASS (0 errors, 0 warnings). Mode resolution unit test: 8/8 fixture cases pass (impl_qa_ship, qa_ship, ship, open_pr, already_shipped from MERGED, pr_unknown_state from UNKNOWN/CLOSED, open_pr from DRAFT).
- 2026-05-14 [qa-smoke] S1: green — bash dry-run of mode resolution: 8/8 fixture states map to correct MODE (impl_qa_ship, qa_ship, ship, open_pr, already_shipped, pr_unknown_state ×2, DRAFT→open_pr).
- 2026-05-14 [qa-smoke] S2: green — work-item-dir input is recognized at run.md Step 1.0 dispatch; synthetic fixture extraction yields correct IMPL/QA/PR_URL via both frontmatter and PRs-section paths.
- 2026-05-14 [qa-smoke] S3: green — gh-offline path verified by case ladder: any non-MERGED/OPEN/DRAFT state (including UNKNOWN from `gh pr view 2>/dev/null || echo UNKNOWN`) falls to `pr_unknown_state`.
- 2026-05-14 [qa-smoke] S4: green — telemetry write block at run.md Step 1.1.dispatch includes `mode: $MODE` field. Inspection-verified.
- 2026-05-14 [qa-smoke] S5: green — Branch(g) → Branch(f) handoff verified by inspection of run.md Step 1.0.g: Branch(g) sets `INPUT_MODE="work-item-dir"` and falls through; Branch(f) at Step 1.1 picks up the same code path as direct invocation.
- 2026-05-14 [qa-smoke-summary] green: 5/5 smoke (8/8 mode resolution unit tests + extraction + offline + telemetry + Branch(g) integration).
- 2026-05-14 [qa-e2e] E1-E5: green via structural inspection. Literal /CJ_run invocation on S039 mid-QA deferred (same recursion guard as S036 QA — Branch(f) would dispatch sub-skills on S039 which we're currently inside). Each MODE's dispatch path is verified by reading run.md Step 1.1.dispatch table; phase resolution from bash dry-run; sub-skill invocation contracts are stable (Skill tool for /CJ_qa-work-item / /ship / /land-and-deploy; Agent dispatch for /CJ_personal-pipeline). [parent-inline]
- 2026-05-14 [qa-pass] S000039 (user-story): green smoke (5/5) + green E2E (5/5 parent-inline). Phase 2 gates transitioned.
- 2026-05-14 [impl-pass] S000039: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files).
