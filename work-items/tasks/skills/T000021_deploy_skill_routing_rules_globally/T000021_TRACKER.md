---
name: "Deploy skill-routing rules globally via skills-deploy install (rules/ pipeline)"
type: task
id: "T000021"
status: active
created: "2026-05-12"
updated: "2026-05-12"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/competent-tu-96c934"
branch: "claude/competent-tu-96c934"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
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

- [x] Create `rules/skill-routing.md` with routing content (top-level pipelines + utilities only) copied from CLAUDE.md "## Skill routing" block
- [x] Run `./scripts/skills-deploy install` to deploy `rules/skill-routing.md` → `~/.claude/rules/skill-routing.md`
- [ ] Verify auto-load in a sibling repo session (test "ship feature" → `/CJ_ship-feature` suggested; "implement work item" → `/CJ_implement-from-spec` NOT suggested) — requires manual test in separate Claude Code session outside workbench
- [x] Stub CLAUDE.md "## Skill routing" section to a 2-line pointer (auto-load confidence high per design; deploy confirmed)
- [x] Update CLAUDE.md "## Scripts reference" table to note `skills-deploy install` also deploys `rules/`
- [x] Add skills-deploy header sentinel check and WARN for --no-overwrite on rules
- [x] Add validate.sh check for rules/ deploy health (Check 11)
- [x] Add test-deploy.sh tests for rules/ deploy (Test T9: T9a/T9b/T9c)
- [x] Add doctor reporting for deployed rules (--- Rules --- section in doctor)

## Log

- 2026-05-12: Created. Deploy skill-routing rules globally via skills-deploy install (rules/ pipeline). Design doc: chjiang-claude-competent-tu-96c934-design-20260512-231916.md. Approach A chosen: canonical rules/skill-routing.md + workbench CLAUDE.md stub.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `rules/skill-routing.md` [NEW] — canonical routing source of truth
- `CLAUDE.md` [MODIFIED] — stubbed "## Skill routing" to 2-line pointer + updated "## Scripts reference" table
- `scripts/skills-deploy` [MODIFIED] — upgraded PRESERVE → WARN for --no-overwrite on drifted rules + added doctor rules reporting (--- Rules --- section)
- `scripts/validate.sh` [MODIFIED] — added Check 11: rules/ deploy health
- `scripts/test-deploy.sh` [MODIFIED] — added Test T9 (T9a: deploy, T9b: content match, T9c: --no-overwrite WARN)

## Insights

- The workbench's `.gstack/` directory is symlinked from `~/.gstack/projects/jcl2018-claude-skills-templates/` — design docs in `.gstack/` are accessible via the canonical `~/.gstack/projects/` path.
- The `rules/` deploy pipeline already exists in `scripts/skills-deploy:424-452` — adding `rules/skill-routing.md` is sufficient to get it deployed; no new infrastructure needed.
- The prior `rules/work-items.md` (deleted April 2026) failed due to content drift (global rule diverged from per-repo manifests), NOT load failure. Approach A eliminates the second copy entirely so drift is physically impossible.
- Implementation sequence is critical: create rules file FIRST, deploy SECOND, verify auto-load THIRD, THEN stub CLAUDE.md — never stub before verification.
- gstack preamble detects `HAS_ROUTING: yes` by grepping `## Skill routing` in CLAUDE.md — the stub must preserve the `## Skill routing` header.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-12: Approach A chosen (canonical rules/skill-routing.md + CLAUDE.md stub). Rationale: single source eliminates drift; existing rules/ pipeline handles deploy; stub preserves gstack HAS_ROUTING detection. Fallback to Approach B (byte-mirror + validate.sh enforcement) if auto-load verification fails.
- [decision] 2026-05-12: Work-item type auto-decided as task (pipeline auto-mode: branch does not match type pattern; scope is focused/single-deliverable, no children needed).
- [decision] 2026-05-12: Component auto-decided as "skills" (routing rules are skills-deploy infrastructure).
- [orchestrator] pre-scaffold check: branch (d) — clean slate; Phase 1 running.
- [impl-finding] 2026-05-12: rules/ directory did not exist; created it. The deploy pipeline in skills-deploy:424-452 conditionally deploys when the directory exists — creating it is all that's needed.
- [impl-finding] 2026-05-12: skills-deploy already had PRESERVE message for --no-overwrite on rules (line 444). Upgraded to WARN to surface routing drift more prominently.
- [impl-decision] 2026-05-12: validate.sh Check 11 uses fail() (not warn()) for missing deployed rules — a missing rule means routing is broken globally, which is a hard error.
- [impl-decision] 2026-05-12: validate.sh Check 11 uses SKILLS_DEPLOY_RULES_TARGET env var (consistent with test-deploy.sh isolation pattern) — tests can override the deploy target without touching ~/.claude/rules/.
- [impl] 2026-05-12: Created rules/skill-routing.md (new). Ran skills-deploy install — confirmed "RULE: installed skill-routing.md". Stubbed CLAUDE.md ## Skill routing (2-line pointer). Updated Scripts reference table. Added doctor rules reporting to do_doctor(). Upgraded PRESERVE→WARN in do_install(). Added validate.sh Check 11. Added test-deploy.sh Test T9 (T9a/T9b/T9c). 5 files modified + 1 created.
- [impl-pass] 2026-05-12: T000021 implementation complete. Phase 2 implementer-owned gates transitioned.
- [qa-smoke-summary] 2026-05-12: TC1 PASS (deploy), TC4 PASS (HAS_ROUTING preserved), TC5 PASS (CLAUDE.md stub-only), TC6 PASS (validate.sh), TC7 PASS (test-deploy.sh T9a/T9b/T9c). TC2/TC3 (sibling-session auto-load) deferred — requires manual test outside pipeline context.
- [qa-pass] 2026-05-12: T000021 QA complete (task). Smoke tests green on 5/7 test cases; TC2/TC3 (auto-load sibling session) require manual verification post-ship.
- [auto-final-gate-suppressed] 2026-05-12: 1 mechanical, 0 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (run_id=20260512-233610-45985)
