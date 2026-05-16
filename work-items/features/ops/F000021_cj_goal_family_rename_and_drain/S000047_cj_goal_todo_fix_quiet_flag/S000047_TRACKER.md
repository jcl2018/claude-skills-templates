---
name: "Schedule-friendly --quiet flag + cron-pattern doc in /CJ_goal_todo_fix"
type: user-story
id: "S000047"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000021"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: "S000046"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_todo_fix_quiet_flag`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` (brief stub — references parent F000021)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture)
6. Scaffold `TEST-SPEC.md` (smoke + E2E)
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (parent F000021 design)
- [ ] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Add `--quiet` flag to /CJ_goal_todo_fix (suppress count-summary AUQ; log to journal instead)
3. Add schedule-run attribution field to telemetry (e.g., `scheduled_run: bool`)
4. Add cron-pattern example to CLAUDE.md and SKILL.md
5. Run smoke tests
6. Run `/CJ_personal-workflow check`
7. Update tracker journal entries
8. Update Files section

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Verify smoke tests pass in CI
3. Walk E2E manually (e.g., test `/schedule create` invocation with `--quiet`)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version (4.2.0 → 4.3.0), updates changelog
6. Run `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `--quiet` flag suppresses the summary AUQ at the end of Phase 3; logs the summary as a journal entry instead.
- [ ] Telemetry includes `scheduled_run: true|false` field (true when `--quiet` is set; false otherwise).
- [ ] CLAUDE.md (workbench) has an example `/schedule create` invocation: `/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am`.
- [ ] SKILL.md documents `--quiet` behavior + cron-pattern example.
- [ ] `--quiet` mode preserves halt-on-red; halt journal entries still get written (just no interactive AUQs).
- [ ] /ship Gate #2 is NOT suppressed by `--quiet` (per F000021 constraint — autonomy ceiling).
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (no `--auto`).

## Todos

- [ ] Add `--quiet` flag parsing to `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`.
- [ ] Modify Phase 3 (summary output) to check `$QUIET`: if set, write summary as `[scheduled-drain-summary]` journal entry; else AUQ as today.
- [ ] Add `scheduled_run` field to telemetry write.
- [ ] Document `--quiet` in SKILL.md (allowed-tools + behavior section).
- [ ] Add cron-pattern example to CLAUDE.md (workbench).
- [ ] Add cron-pattern example to SKILL.md.
- [ ] Update CHANGELOG.md v4.3.0 entry.
- [ ] Add eval case `tests/eval/CJ_goal_todo_fix/quiet-flag/` (verify no AUQ + journal entry written).

## Log

- 2026-05-15: Created. Schedule-friendly `--quiet` flag for /CJ_goal_todo_fix: suppresses summary AUQ noise (cron-eligible) without affecting /ship Gate #2. Plus cron-pattern documentation.

## PRs

## Files

- skills/CJ_goal_todo_fix/scripts/todo_fix.sh (--quiet flag handling)
- skills/CJ_goal_todo_fix/SKILL.md (documents --quiet + cron pattern)
- CLAUDE.md (workbench — example /schedule invocation)
- VERSION (4.2.0 → 4.3.0)
- CHANGELOG.md (v4.3.0 entry)
- tests/eval/CJ_goal_todo_fix/quiet-flag/ (NEW)

## Insights

- `--quiet` ≠ `--no-prompts`. The /ship Gate #2 AUQ (diff-review) remains — `--quiet` only suppresses the Phase 3 summary AUQ. Per F000021 constraint: "schedule-friendly means PRs surface at scheduled cadence and queue for human review; does NOT mean autonomous merge."
- `[scheduled-drain-summary]` journal entry replaces the AUQ output. Schedule-run attribution lets retro tooling distinguish operator-driven vs cron-driven drain.
- Cron-pattern example assumes `/schedule` skill exists (it's in the user's stack — doc-only integration, no schema-binding).

## Journal

- [decision] 2026-05-15: `--quiet` does NOT suppress /ship Gate #2 (per F000021 constraint). Only the Phase 3 summary AUQ. Maintains the autonomy ceiling.
- [decision] 2026-05-15: Schedule-run attribution via `scheduled_run: true` telemetry field (set when `--quiet`). Retro tooling distinguishes cron drain from operator drain.
- [decision] 2026-05-15: Cron-pattern documentation is doc-only — no /schedule schema-binding in v4. /schedule integration is a separate concern; documenting the pattern is sufficient for v4.x.
