---
type: test-spec
parent: S000044
feature: F000021
title: "Batched rename CJ_run → CJ_goal_run + CJ_goal → CJ_goal_todo_fix — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Repository structure post-rename | Both new skill dirs exist; both old slash names are thin aliases | `test -d skills/CJ_goal_run && test -d skills/CJ_goal_todo_fix && test -f skills/CJ_run/SKILL.md && test -f skills/CJ_goal/SKILL.md` |
| S2 | integration | AC-1, AC-2 | Validator regression-free | `./scripts/validate.sh` passes after rename | `./scripts/validate.sh` |
| S3 | integration | AC-1, AC-2, AC-6 | Catalog + manifest consistency | `skills-catalog.json` entries match disk layout; `skills-deploy doctor` reports clean | `./scripts/skills-deploy doctor` |
| S4 | core | AC-3, AC-4 | Alias delegation grep | Both alias SKILL.md files contain `renamed to` deprecation phrase | `grep -l 'renamed to /CJ_goal_run' skills/CJ_run/SKILL.md && grep -l 'renamed to /CJ_goal_todo_fix' skills/CJ_goal/SKILL.md` |
| S5 | observability | AC-5, AC-7 | VERSION bump + CHANGELOG entry | VERSION = 4.0.0 and CHANGELOG.md has v4.0.0 entry documenting rename | `grep -q '^4.0.0$' VERSION && grep -q '## \[4.0.0\]' CHANGELOG.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Fresh-clone install round-trip | 1. Clone repo at PR HEAD. 2. Run `./scripts/setup.sh`. 3. Run `./scripts/skills-deploy install`. 4. Verify `~/.claude/skills/CJ_goal_run/SKILL.md` exists. 5. Verify `~/.claude/skills/CJ_run/SKILL.md` exists (alias). | Both new and alias SKILL.md files deploy without errors. | PASS if both files exist + skills-deploy doctor shows clean. |
| E2 | usability | AC-3 | Alias muscle-memory test in Claude Code | 1. Open Claude Code with the new skills installed. 2. Type `/CJ_run --help` or invoke with a test design doc. | Skill prints deprecation banner ("renamed to /CJ_goal_run; will be removed in v5.0.0") then delegates and produces the same output as direct `/CJ_goal_run` invocation. | PASS if banner appears AND downstream behavior matches the canonical skill. |
| E3 | usability | AC-4 | Alias muscle-memory test for /CJ_goal | 1. Type `/CJ_goal --help` or invoke with a test TODO ID. | Skill prints deprecation banner then delegates to /CJ_goal_todo_fix. | PASS if banner appears AND delegation works. |
| E4 | observability | AC-5 | Telemetry fallback-read smoke | 1. Write 3 fake entries to `~/.gstack/analytics/CJ_run.jsonl`. 2. Invoke `/CJ_goal_run <test-design-doc>`. 3. After completion, check skill's sunset-trip-wire output (or inspect read path manually). | Sunset trip-wire counts prior invocations from both old + new files. | PASS if trip-wire scan reports `INVOCATION_COUNT >= 4` (3 old + 1 new). |
| E5 | integration post-ship | AC-6, AC-7 | Downstream consumer pickup | 1. After PR merges. 2. In a downstream repo (e.g., jcl2018-portfolio), run `git pull` on the workbench remote + `skills-deploy install`. 3. Verify both new + alias skills deploy. | Downstream repo picks up rename via normal sync flow; no manual intervention required. | PASS if downstream `skills-deploy doctor` clean post-pull. (post-ship — verify after merge.) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior of stale `/CJ_run` calls AFTER v5.0.0 alias removal | This story (S000044) ships the aliases. Removal is v5.0.0 (separate ship). | LOW: v5.0.0 will have its own test plan for the alias-removal error message. |
| `~/.claude/CLAUDE.md` (global) update — whether it auto-updates via skills-deploy or requires manual hand-edit | Out of scope for this rename PR (deploy-script behavior, not rename behavior). | LOW: If skills-deploy doesn't touch it, document the manual step in CHANGELOG.md v4.0.0 entry. |
| Concurrent rename + active pipeline run (operator runs `/CJ_run` mid-PR-merge) | Race window is minutes; aliases prevent breakage. | LOW: alias delegation covers the window. |
| Performance impact of alias delegation (extra dispatch hop) | Single dispatch hop; negligible vs. pipeline cost (~5+ min). | NIL: cost is microseconds. |
