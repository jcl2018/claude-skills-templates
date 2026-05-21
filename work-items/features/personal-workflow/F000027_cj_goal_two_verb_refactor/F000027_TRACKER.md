---
name: "CJ_goal family — two-verb refactor (feature / defect) over leaf skills"
type: feature
id: "F000027"
status: active
created: "2026-05-21"
updated: "2026-05-21"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-hermann-c2b955"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cj_goal_two_verb_refactor`
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

- [ ] `/cj_goal_feature "<topic>"` from clean `main`: worktree → office-hours → APPROVED doc → silent scaffold/impl/qa → `/ship` opens a PR → STOP, with zero AUQ between the office-hours approval gate and the PR.
- [ ] Re-invoking `feature` after a halt resumes at `last_completed_phase`, validating the recorded SHA/PR against current HEAD; never re-runs office-hours on an unchanged APPROVED doc and never skips a phase on stale state.
- [ ] `/cj_goal_defect "<bug>"` with no pre-existing defect dir scaffolds a bug report, root-causes via `/investigate` (Iron-Law), passes the human `/ship` gate, and deploys.
- [ ] Nesting depth ≤ 2; no subagent-spawns-subagent path anywhere in either pipeline.
- [ ] Deprecated `run`/`auto` print a one-line banner and route to `feature`; `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` + `/schedule` + `/loop` still work.
- [ ] `validate.sh` + `test.sh` green; `cj-worktree-init.sh` accepts the new `feature`/`defect` callers; the early feature smoke harness passes.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000057 — Extend `cj-worktree-init.sh` `--caller` validator + prefix map; add `cj-goal-common.sh`; add early feature smoke harness.
- [ ] S000058 — `/cj_goal_defect` (reshape of investigate v1.1 + no-doc bug-report scaffolding).
- [ ] S000059 — `/cj_goal_feature` (office-hours-inline → silent build → PR-stop) with strengthened resume.
- [ ] S000060 — Deprecate `/CJ_goal_run` + `/CJ_goal_auto` with alias shims + sunset; update routing + catalog.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-21: Created. Collapse the CJ_goal front door to two verbs — `/cj_goal_feature` and `/cj_goal_defect` — on a flat, leaf-subagent architecture; deprecate `/CJ_goal_run` + `/CJ_goal_auto`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-worktree-init.sh` (S000057 — `--caller` validator + prefix map)
- `scripts/cj-goal-common.sh` (S000057 — new deterministic helper)
- `skills/cj_goal_defect/SKILL.md` (S000058 — new)
- `skills/cj_goal_feature/SKILL.md` (S000059 — new)
- `skills/CJ_goal_run/`, `skills/CJ_goal_auto/` (S000060 — alias shims + deprecation)
- `skills-catalog.json`, `rules/skill-routing.md`, `CLAUDE.md` (S000060 — routing + catalog)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Auto-deploy of skill-work is unsafe-by-construction in this repo: `cj-handoff-gate.sh`'s denylist blocks `skills-catalog.json`, `tests/`, `validate.sh`, `test.sh`, and skill dirs on purpose — but those are exactly the surfaces every skill-feature here touches. So the auto-mergeable subset is "the set of features that change nothing important." PR-stop is the correct end state for `feature`, not a v1 shortcut.
- The "shared tail" simplification was a fake one: feature PR-stops while defect human-ships-then-deploys, so the tails genuinely differ. Forcing one shared doc just recreates the mode-flag orchestrator the refactor exists to remove. Common, deterministic bits (worktree, telemetry, PR checks) move to a bash helper instead.
- A defect-first build never exercises the feature tail, so an early feature smoke harness (right after the `--caller` change) is needed to avoid leaving the riskier skill wholly unvalidated until PR #2.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-21: `feature` terminates at a PR for human review; auto-merge+deploy dropped (Revision 2, GATE #1). Summary: auto-deploy of skill-work is unsafe-by-construction here because the handoff-gate denylist blocks exactly the skill surfaces every feature touches. PR-stop is correct, not a compromise.
- [decision] 2026-05-21: No autoplan in `feature` (Revision 2, GATE #1). Summary: Rev 1's "autoplan only on the auto-deploy branch" was logically incoherent (the branch is known only after `/ship`, but autoplan runs before the build). With auto-deploy gone, every run PR-stops and gets a human PR review — which is the architecture gate.
- [decision] 2026-05-21: Approach A — two independent verb skills + a deterministic `cj-goal-common.sh` helper (Open Question 3 RESOLVED). Summary: rejected Approach B's shared LLM-followed `tail.md` because the differing tails turn it into a mode-flag orchestrator; the common bits are deterministic bash, not LLM-followed prose.
- [decision] 2026-05-21: Resume model strengthened to `last_completed_phase` + per-phase HEAD SHA + PR number, validated against current HEAD (GATE #1). Summary: the A/S/P/M flag model was too lossy and could skip into a later phase on stale state.
