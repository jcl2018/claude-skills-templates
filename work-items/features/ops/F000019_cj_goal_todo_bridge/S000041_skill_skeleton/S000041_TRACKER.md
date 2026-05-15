---
name: "Skill skeleton + scripts/goal.sh + catalog + routing + eval"
type: user-story
id: "S000041"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: "F000019"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Atomic single-story under F000019. All build work for /CJ_goal v1
     lives here. Parent F000019_DESIGN.md is sufficient context — this
     story's DESIGN.md is a brief stub linking to parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_skill_skeleton` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

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
   → should show PASS for template, lifecycle, traceability badges
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

- [ ] `skills/CJ_goal/SKILL.md` exists with valid YAML frontmatter (name, description, allowed-tools at minimum)
- [ ] SKILL.md is a thin wrapper that dispatches to `scripts/goal.sh`
- [ ] `skills/CJ_goal/scripts/goal.sh` exists with `#!/usr/bin/env bash` shebang and is executable
- [ ] `scripts/goal.sh` implements: preamble (update-check, git-repo guard, path-resolution); TODOS.md parser; input parsing (no-args / T-ID / fragment); pre-flight gates (suffix-parse, priority/size, body-extract, sensitive-surface AUQ, design-needed keyword, idempotency); ID picker; domain inference; slug generation; scaffold writes (TRACKER + test-plan); boundary check; direct-dispatch chain; PR_NUM parse; hash-verify TODOS.md DONE-mark write; telemetry
- [ ] Per-session skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` per autoplan v4 patch
- [ ] Catalog entry in `skills-catalog.json` with `status: experimental`, `portability: standalone`, `depends.skills: ["CJ_suggest", "CJ_personal-pipeline", "CJ_personal-workflow", "CJ_scaffold-work-item"]`
- [ ] `rules/skill-routing.md` updated with TODO-bridging triggers
- [ ] CLAUDE.md routing block updated to list /CJ_goal among available skills
- [ ] Eval fixtures at `tests/eval/CJ_goal/preflight-halts/` covering: P1 halt, size-L halt, sensitive-surface halt, design-keyword halt, body-too-short halt, suffix-missing halt, /CJ_suggest-empty halt
- [ ] `scripts/validate.sh` clean

## Todos

- [ ] Create SKILL.md thin wrapper
- [ ] Implement scripts/goal.sh
- [ ] Add catalog entry
- [ ] Add routing rule
- [ ] Add CLAUDE.md mention
- [ ] Create eval fixtures
- [ ] Run /CJ_personal-workflow check
- [ ] Run scripts/validate.sh

## Log

- 2026-05-14: Created. Skill skeleton story scaffolded under F000019.

## PRs

## Files

- `skills/CJ_goal/SKILL.md` (new)
- `skills/CJ_goal/scripts/goal.sh` (new)
- `skills-catalog.json` (modified)
- `rules/skill-routing.md` (modified)
- `CLAUDE.md` (modified)
- `tests/eval/CJ_goal/preflight-halts/*` (new)

## Insights

## Journal
