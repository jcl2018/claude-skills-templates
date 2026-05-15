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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] `skills/CJ_goal/SKILL.md` exists with valid YAML frontmatter (name, description, allowed-tools at minimum)
- [x] SKILL.md is a thin wrapper that dispatches to `scripts/goal.sh`
- [x] `skills/CJ_goal/scripts/goal.sh` exists with `#!/usr/bin/env bash` shebang and is executable
- [x] `scripts/goal.sh` implements: preamble (update-check, git-repo guard, path-resolution); TODOS.md parser; input parsing (no-args / T-ID / fragment); pre-flight gates (suffix-parse, priority/size, body-extract, sensitive-surface AUQ, design-needed keyword, idempotency); ID picker; domain inference; slug generation; scaffold writes (TRACKER + test-plan); boundary check; direct-dispatch chain (handoff-block protocol per impl-decision journal); PR_NUM parse (deferred to agent-layer handoff consumer); hash-verify TODOS.md DONE-mark write (deferred to agent-layer); telemetry (handoff_pending state on script exit; agent writes terminal state)
- [x] Per-session skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` per autoplan v4 patch
- [x] Catalog entry in `skills-catalog.json` with `status: experimental`, `portability: standalone`, `depends.skills: ["CJ_suggest", "CJ_personal-pipeline", "CJ_personal-workflow", "CJ_scaffold-work-item"]`
- [x] `rules/skill-routing.md` updated with TODO-bridging triggers
- [x] CLAUDE.md routing block updated to list /CJ_goal among available skills
- [x] Eval fixtures at `tests/eval/CJ_goal/halt-*/` covering 7 scenarios: P1 halt, size-L halt, sensitive-surface halt, design-keyword halt, body-too-vague halt, suffix-missing halt, /CJ_suggest-empty halt
- [x] `scripts/validate.sh` clean (0 errors, 0 warnings)

## Todos

- [x] Create SKILL.md thin wrapper
- [x] Implement scripts/goal.sh
- [x] Add catalog entry
- [x] Add routing rule
- [x] Add CLAUDE.md mention
- [x] Create eval fixtures (7 cases under tests/eval/CJ_goal/halt-*/)
- [x] Run /CJ_personal-workflow check (boundary green via scripts/validate.sh PASS)
- [x] Run scripts/validate.sh (PASS: 0 errors, 0 warnings)
- [ ] (Deferred to v1.1) Extract ID picker to scripts/cj-id-picker.sh (Open Q #1 in source design)
- [ ] (Deferred to v1.1) Domain inference AUQ fallback when ambiguous (Open Q #2)
- [ ] (Deferred to v1.1) Sunset trip-wire calibration after 8+ real invocations (Open Q #4)
- [ ] (Deferred — QA scope) Verify smoke + E2E per S000041_TEST-SPEC.md

## Log

- 2026-05-14: Created. Skill skeleton story scaffolded under F000019.

## PRs

## Files

- `skills/CJ_goal/SKILL.md` (new) — thin wrapper with YAML frontmatter (name, description, version 1.0.0, allowed-tools: Bash/Read/AskUserQuestion/Skill/Agent) + Overview + Routing block dispatching to `scripts/goal.sh`
- `skills/CJ_goal/scripts/goal.sh` (new, executable mode 755) — load-bearing script: preamble (update-check + git-repo guard + telemetry init + PRE_HASH capture); TODOS.md parser; input parsing (no-args / T-ID / fragment / --dry-run); 6 pre-flight gates; ID picker (verbatim copy from /CJ_scaffold-work-item Step 5); domain inference; slug generation; scaffold writes (TRACKER + test-plan from templates/CJ_personal-workflow/); boundary check via validate.sh; handoff-block emission for the agent-layer dispatch chain; telemetry writer with jq + fallback paths
- `skills-catalog.json` (modified) — new entry: name=CJ_goal, version=1.0.0, status=experimental, portability=standalone, depends.skills=[CJ_suggest, CJ_personal-pipeline, CJ_personal-workflow, CJ_scaffold-work-item], depends.tools=[bash, awk, find, grep, sed, jq, git, gh]
- `rules/skill-routing.md` (modified) — two new routing lines covering "fix this TODO" / "auto-resolve TODOs" / "clear the TODO backlog" / "ship the next TODO" / "close TODOs from TODOS.md" / "auto-ship TODOs" / "resolve a TODO end-to-end" → `/CJ_goal`, and "loop through TODOs" / "fix TODO backlog continuously" / "auto-clear TODOs" → `/loop /CJ_goal`
- `CLAUDE.md` (modified) — added CJ_ skill family rundown to the Skill routing section, listing /CJ_goal alongside the other CJ_ skills with a one-liner pointing at SKILL.md
- `tests/eval/CJ_goal/halt-p1-priority/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-size-large/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-sensitive-surface/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-design-keyword/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-body-too-vague/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-suffix-missing/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json
- `tests/eval/CJ_goal/halt-suggest-empty/` (new) — fixture/TODOS.md + prompt.md + expected.schema.json

## Insights

## Journal

- 2026-05-14 23:02 [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/ops/F000019_cj_goal_todo_bridge/S000041_skill_skeleton; scaffold skipped. RUN_ID=20260514-230256-64524
- 2026-05-14 [impl-decision] Chose handoff-block stdout protocol for the dispatch chain (Step 4 in source design Approach A). Bash scripts launched from SKILL.md routing cannot synchronously invoke Skill or Agent tools — the wrapping Claude agent must parse stdout and dispatch /CJ_personal-pipeline + /ship + /land-and-deploy itself. The handoff block (CJ_GOAL_HANDOFF_BEGIN ... CJ_GOAL_HANDOFF_END) carries WORK_ITEM_DIR + T_ID + HEADING + IDEMPOTENT_SKIP + PRE_HASH so the agent has everything it needs. Matches the /CJ_run pattern (orchestration at agent layer, script emits directive).
- 2026-05-14 [impl-decision] ID picker pasted verbatim from skills/CJ_scaffold-work-item/scaffold.md Step 5 per source design Open Q #1. Drift risk flagged in SKILL.md Notes section + inline DRIFT NOTE comment in goal.sh; v1.1 extracts to scripts/cj-id-picker.sh.
- 2026-05-14 [impl-decision] Sensitive-surface gate defaults to halt (not AUQ) when triggered. Pure-stdin bash context cannot reach AskUserQuestion, and the source design specifies halt-as-default for the AUQ option. User can re-invoke via manual scaffold path if they want to proceed.
- 2026-05-14 [impl-decision] Test-plan generator extracts first-sentence-of-body as the Steps column and replaces both placeholder rows in templates/CJ_personal-workflow/doc-test-plan.md. Theme C resolution (T000023) refuses placeholder-only test plans at /CJ_qa-work-item, so /CJ_goal must produce at least one real row or refuse-to-scaffold. First-sentence is a pragmatic choice — not pretending to extract test design, but giving the QA gate something concrete to verify the implementation against.
- 2026-05-14 [impl-decision] Domain inference order: skills (skills/CJ_ or templates/CJ_personal-workflow/) → work-copilot → ops (default). Pure heuristic; v1.1 may add an AUQ for ambiguous cases per source design Open Q #2.
- 2026-05-14 [impl-decision] Telemetry writer uses jq when available, falls back to sanitized echo (strips backslashes + double-quotes). Mirrors /CJ_personal-pipeline's Step 9.1 telemetry contract.
- 2026-05-14 [impl-finding] /CJ_suggest's stdout is a markdown table — column 2 contains the title without the `(Pn, X)` suffix. /CJ_goal's no-args path uses `grep -F` against parse_active_headings() output to recover the full `### Heading (Pn, X)` line. Substring match is sufficient because suggest only shows top-5 and active set is small.
- 2026-05-14 [impl-finding] Per-session skip-list at /tmp/cj-goal-skip-${RUN_ID}.txt requires the halt() function to write the heading to the file BEFORE exit for halted_at_preflight. Implemented in halt() helper — file append happens unconditionally on this end_state.
- 2026-05-14 [impl-finding] Tracker template's `git checkout -b feat/{slug}` literal contains `{slug}` — substituted with generated SLUG so the branch suggestion in Phase 1 step 2 is useful. Predates this work-item; documented in source design Open Q #6.
- 2026-05-14 [impl] Wrote 2 files (SKILL.md, scripts/goal.sh) + 7 eval case dirs (each 3 files); modified 3 (skills-catalog.json, rules/skill-routing.md, CLAUDE.md). 11 journal entries added. validate.sh PASS post-write.
- 2026-05-14 [impl-pass] S000041: implementation complete. Phase 2 implementer-owned gates (Todos section reflects remaining work, Files section updated with changed files) transitioned. Acceptance criteria + Smoke tests gates remain unchecked — owned by /CJ_qa-work-item.
