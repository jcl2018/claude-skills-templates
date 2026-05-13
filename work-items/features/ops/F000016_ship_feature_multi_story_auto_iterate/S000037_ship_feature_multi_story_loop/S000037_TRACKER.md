---
name: "Rewrite ship-feature.md Branch (b) multi-story loop"
type: user-story
id: "S000037"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000016"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/awesome-pasteur-36565c"
branch: "claude/awesome-pasteur-36565c"
blocked_by: "S000036"
---

<!-- Prerequisite: S000036 must ship first. This story's impl depends on the
     --work-item-dir flag being available in pipeline.md. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
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
- [ ] Tasks broken down (or N/A — atomic story)

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

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `run.md` Branch (b) is rewritten: no longer halts with manual instructions; instead auto-iterates over children
- [ ] For each child: creates branch off `origin/main`, copies scaffold files from feature branch, spawns pipeline subagent with `--work-item-dir --suppress-final-gate`, invokes /ship, invokes /land-and-deploy
- [ ] Resume guard: already-merged child PRs are skipped on re-run (idempotency)
- [ ] On child pipeline failure: halts loop, reports failure, restores repo to feature branch, prints remaining children
- [ ] `write_state()` helper extended: CHILDREN_TOTAL, CHILDREN_DONE, CHILDREN_FAILED, CHILD_PR_URLS fields
- [ ] Step 6.1 telemetry: `multi_story_scaffold_only` replaced by `multi_story_mode` (boolean) + `multi_story_children_shipped` (count)
- [ ] Step 6.2 green summary: multi-story completion block printed when MULTI_STORY=1
- [ ] Ship-feature `CJ_ship-feature 0.1.0` → `0.2.0` in SKILL.md and skills-catalog.json
- [ ] `./scripts/validate.sh` passes after all changes

## Todos

- [ ] Edit `skills/CJ_run/run.md`: rewrite Branch (b) — preamble (CHILDREN enumeration, state vars), loop body (branch creation, scaffold copy, pipeline dispatch, /ship, /land-and-deploy, failure halt)
- [ ] Edit `skills/CJ_run/run.md`: extend `write_state()` helper with new fields
- [ ] Edit `skills/CJ_run/run.md`: Step 6.1 telemetry rename multi_story_scaffold_only → multi_story_mode + add multi_story_children_shipped
- [ ] Edit `skills/CJ_run/run.md`: Step 6.2 green summary multi-story block
- [ ] Edit `skills/CJ_run/run.md`: Decision Gates section update (2 for single-story / 1+N for multi-story)
- [ ] Edit `skills/CJ_ship-feature/SKILL.md`: version bump to 0.2.0
- [ ] Edit `skills-catalog.json`: bump CJ_ship-feature version to 0.2.0; update decision-gates description
- [ ] Run `./scripts/validate.sh` to verify

## Log

- 2026-05-13: Created. Rewrites ship-feature.md Branch (b) to auto-iterate over child user-stories. Blocked on S000036 (--work-item-dir flag) shipping first. Derived from F000016 /office-hours design, Approach B §"Change 3: ship-feature.md — Branch (b) rewrite".

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_run/run.md`
- `skills/CJ_ship-feature/SKILL.md`
- `skills-catalog.json`

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
