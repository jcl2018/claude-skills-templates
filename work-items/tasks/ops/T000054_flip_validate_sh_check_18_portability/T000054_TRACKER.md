---
name: "Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding"
type: task
id: "T000054"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/nervous-tesla-46a57e"
branch: "cj-task-20260628-140758-portability-strict-default"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/flip_validate_sh_check_18_portability`
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
   → design doc at `~/.gstack/projects/flip_validate_sh_check_18_portability/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

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

- [ ] Implement: Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-28: Created. Auto-scaffolded by /CJ_goal_task from topic: Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/validate.sh` — Check 18: `${PORTABILITY_STRICT:-0}` → `:-1` (strict-by-default) + banner/message/comment prose + Check 21 stale cross-ref
- `spec/test-spec-custom.md` — validate-check-18 `disposition: advisory` → `hard-fail`
- `scripts/test.sh` — S000083g wording + new S000083g2 strict-default guard
- `CLAUDE.md`, `docs/architecture.md` — "stays advisory globally" → strict-by-default prose
- `skills-catalog.json` + `README.md` (regen) + `skills/CJ_portability-audit/{SKILL,USAGE}.md` — description/usage prose sync
- `TODOS.md` — row strike (DONE)
- `work-items/tasks/ops/T000054_*/` — this work item

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding -->

- 2026-06-28 [qa-smoke] 1 (Check 18 strict-default): green — `grep PORTABILITY_STRICT:-1 scripts/validate.sh` matches; banner reads "(strict)".
- 2026-06-28 [qa-smoke] 2 (validate green on clean catalog): green — `bash scripts/validate.sh` 0 errors / 0 warnings (strict Check 18 still PASSes; catalog FINDINGS=0).
- 2026-06-28 [qa-smoke] 3 (test-spec disposition): green — validate-check-18 `disposition: hard-fail`; `test-spec.sh --validate` OK schema_version=1; `--check-coverage` findings=0.
- 2026-06-28 [qa-smoke] 4 (parallel test.sh guard): green — full `scripts/test.sh` PASS (Failures: 0); S000083g2 fired live ("validate.sh Check 18 defaults PORTABILITY_STRICT to 1"); S000083g/h green; Check 25 README in sync; Check 14 SKIP (uncommitted).
- 2026-06-28 [qa-smoke] 5 (no work-item IDs in human-docs): green — Check 19 PASS (T000054 removed from README + docs/architecture.md; lives only in operational docs).
- 2026-06-28 [qa-smoke-summary] green: 5/5 rows green. Broader surface green: validate.sh (0/0) + full test.sh (PASS).
- 2026-06-28 [qa-audit] AUDITS=deferred (8.6a test-spec-custom disposition updated inline; 8.6b no new doc; 8.6c/8.6d deferred to the orchestrator post-sync audit).
- 2026-06-28 [qa-pass] T000054 (task): green smoke from test-plan rows (5 rows). No qa-owned Phase 2 gates per task template.

- 2026-06-28 [task-pr-opened] T000054 PR #287 (v6.0.89) — https://github.com/jcl2018/claude-skills-templates/pull/287
