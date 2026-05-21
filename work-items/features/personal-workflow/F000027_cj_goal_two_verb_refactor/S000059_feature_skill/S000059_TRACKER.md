---
name: "/cj_goal_feature skill — office-hours-inline -> silent build -> PR-stop, strengthened resume"
type: user-story
id: "S000059"
status: active
created: "2026-05-21"
updated: "2026-05-21"
parent: "F000027"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-hermann-c2b955"
blocked_by: ""
# pr: ""
---

<!-- Prerequisite: derives directly from the parent feature's /office-hours
     session; the parent F000027_DESIGN.md is sufficient design context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_two_verb_refactor` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
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
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `/cj_goal_feature "<topic>"` from clean `main`: worktree → `/office-hours` (inline) → APPROVED doc → silent scaffold/impl/qa leaf subagents → `/ship` opens a PR → STOP, with zero AUQ between the office-hours approval gate and the PR.
- [ ] No autoplan and no auto-merge/deploy anywhere on the feature path (PR-stop is the end state; the PR review is the architecture gate).
- [ ] `/ship`'s diff-review AUQ is suppressed (the PR itself is the review).
- [ ] Resume tracks `last_completed_phase` ∈ {none, office-hours, scaffold, impl, qa, ship} + per-phase HEAD SHA + PR number; on re-invocation it validates the recorded SHA is an ancestor of (or equal to) current HEAD and any open PR resolves to OPEN, restarting the affected phase otherwise.
- [ ] office-hours resume re-locates the doc by the recorded path (not a blind newest-glob) and re-confirms `Status: APPROVED` before proceeding; never re-runs office-hours on an unchanged APPROVED doc.
- [ ] Nesting depth ≤ 2 (orchestrator → leaf subagent); office-hours + `/ship` run inline, leaves dispatched directly.

## Todos

<!-- Actionable items for this story. -->

- [ ] Author `skills/cj_goal_feature/SKILL.md`: worktree → office-hours inline → scaffold/impl/qa leaf subagents → `/ship` → STOP.
- [ ] Suppress `/ship`'s diff-review AUQ on this path.
- [ ] Implement the strengthened resume state file (`last_completed_phase` + per-phase HEAD SHA + PR number) with validate-before-skip.
- [ ] Implement office-hours doc-path recovery from the recorded path + `Status: APPROVED` re-confirm.
- [ ] Wire the feature halt taxonomy (`green_pr_opened`, `halted_at_*`, `already_shipped`) + telemetry (`~/.gstack/analytics/CJ_goal_feature.jsonl`).
- [ ] Add a catalog entry (`experimental`) + routing line.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. The `feature` verb — office-hours-inline → silent scaffold/impl/qa → `/ship` PR → STOP; no autoplan, no auto-merge/deploy; strengthened resume.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/cj_goal_feature/SKILL.md`
- `skills/cj_goal_feature/pipeline.md` (if the flow is kept separate from SKILL.md)
- `skills-catalog.json`
- `scripts/cj-goal-common.sh` (consumed; owned by S000057)

## Insights

<!-- Non-obvious findings worth remembering. -->

- PR-stop is the correct end state here, not a v1 shortcut: auto-deploy of skill-work is unsafe-by-construction because the handoff-gate denylist blocks exactly the skill surfaces every feature touches. So no autoplan and no auto-merge.
- "No AUQ" means no AUQ *between the office-hours approval gate and the PR* — office-hours itself is interactive (six forcing questions, premise gate, terminal Approve), and it runs inline at top level because subagents can't AUQ.
- The A/S/P/M resume flag model was too lossy; tracking `last_completed_phase` + per-phase HEAD SHA + PR number with validate-before-skip prevents resuming into a later phase on stale state.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: `feature` terminates at the PR; no auto-merge/deploy (D3 REVISED at GATE #1). Summary: the handoff-gate denylist blocks the catalog/tests/validator/skill surfaces every feature touches, so the auto-mergeable subset is "features that change nothing important." PR-stop is correct.
- [decision] 2026-05-21: No autoplan in `feature` (Open Question 2 RESOLVED). Summary: with auto-deploy gone, the human PR review is the architecture gate, making autoplan redundant and the prior "autoplan only on the auto-deploy branch" rule incoherent.
- [decision] 2026-05-21: Resume strengthened to `last_completed_phase` + per-phase HEAD SHA + PR number, validate-before-skip; office-hours resume uses the recorded path + APPROVED re-confirm, not a newest-glob (GATE #1). Summary: prevents skipping into a later phase on stale state and re-running office-hours on an unchanged APPROVED doc.
