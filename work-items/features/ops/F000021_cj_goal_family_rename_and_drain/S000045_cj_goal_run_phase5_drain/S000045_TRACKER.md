---
name: "Phase 5 drain logic in /CJ_goal_run"
type: user-story
id: "S000045"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000021"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "F000021_cj_goal_family_rename_and_drain--S000045_cj_goal_run_phase5_drain-20260515-180109"
blocked_by: "S000044"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_run_phase5_drain` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (parent F000021 design)
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
- [x] Todos section reflects remaining work
- [x] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version (4.0.0 → 4.1.0), updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `/CJ_goal_run <design-doc>` Phase 5 diffs `TODOS.md` additions in the merged PR (`git diff <parent>..HEAD -- TODOS.md`). [Step 5.5.1]
- [x] Phase 5 counts new `^### ` headings → N. [Step 5.5.1, `grep -cE '^\+### '`]
- [x] If N == 0: Phase 5 silently skips and emits `end_state=green` with `new_todos_count: 0` in telemetry. [Step 5.5.2 + Step 6.1]
- [x] If N > 0: AUQ surfaces "Drain N new TODOs? [yes/no/show-list]" (recommended: yes if N ≤ cap=5, no otherwise). [Step 5.5.3]
- [x] On yes: per-TODO drain loop (cap=5) reuses `/CJ_goal_todo_fix` invocation as a subroutine (preflight → scaffold T-task → /CJ_personal-pipeline → /ship Gate #2 [per child] → /land-and-deploy → TODOS.md DONE-mark). [Step 5.5.4]
- [x] On per-child halt-red: STOP the loop, emit `drained_partial` end_state with per-child PR URLs in telemetry. [Step 5.5.4 post-loop classifier + Step 5.5.5]
- [x] On cap reached: STOP cleanly, emit `drained_partial` with "K TODOs remain; run /CJ_goal_todo_fix to drain" message. [Step 6.2 drained_partial branch — "Remaining: N TODOs not drained" tail]
- [x] On all green: emit `drained_complete` end_state. [Step 5.5.4 classifier]
- [x] New `--no-drain` flag bypasses Phase 5 entirely (escape hatch). [Step 1.0 pre-pass + Step 5.5.0]
- [x] Telemetry line includes `new_todos_count`, `drained_count`, `drained_pr_urls` array. [Step 6.1 jq + bare-shell fallback]
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (no `--auto`). [pending /ship]

## Todos

- [x] Add Phase 5 section to `skills/CJ_goal_run/run.md` (was `CJ_run/run.md`).
- [x] Implement TODOS.md diff parser (`git diff <parent>..HEAD -- TODOS.md | grep -E '^\+### '`).
- [x] Implement N-count threshold logic (skip silently when N == 0; AUQ when N > 0).
- [x] Implement per-TODO drain loop calling `/CJ_goal_todo_fix <T-or-heading>` per child (cap=5).
- [x] Halt-on-red preserves existing halt classes from `/CJ_run` (no new halts in this story; new classes `drained_complete`/`drained_partial` defined in F000021).
- [x] Update `skills/CJ_goal_run/SKILL.md` to document Phase 5 and `--no-drain` flag.
- [x] Add `--no-drain` flag parsing to Step 1 of `run.md`.
- [x] Telemetry: extend `~/.gstack/analytics/CJ_goal_run.jsonl` schema with `new_todos_count`, `drained_count`, `drained_pr_urls`.
- [x] Update CHANGELOG.md v4.1.0 entry.
- [x] Add eval case `tests/eval/CJ_goal_run/phase5-drain-zero-todos/`.
- [x] Add eval case `tests/eval/CJ_goal_run/phase5-drain-three-todos/`.

## Log

- 2026-05-15: Created. Phase 5 drain logic adds ~200 LOC to /CJ_goal_run: diff TODOS.md additions in merged PR, AUQ if N > 0, per-child drain loop cap=5, halt-on-red.
- 2026-05-15: Implementation landed locally on branch `F000021_cj_goal_family_rename_and_drain--S000045_cj_goal_run_phase5_drain-20260515-180109`. Smoke tests S1-S5 from TEST-SPEC pass; `./scripts/validate.sh` and `./scripts/test.sh` both green.

## PRs

## Files

- skills/CJ_goal_run/run.md (Phase 5 section added — Step 5.5 with sub-steps 5.5.0 through 5.5.5; --no-drain pre-pass in Step 1.0; state file schema extended; Step 5 Branch (a) now flows into Phase 5; Step 6.1 telemetry write extended; Step 6.2 summary prints Phase 5 outcomes; Step 7.1 exit code maps drained_complete / drained_partial to 0)
- skills/CJ_goal_run/SKILL.md (documents Phase 5 + --no-drain flag; bumped to v1.1.0; extended error table with drained_complete / drained_partial / silent-skip / --no-drain rows; extended end_state enum)
- skills-catalog.json (CJ_goal_run entry bumped 1.0.0 → 1.1.0; description extended with Phase 5 summary)
- VERSION (4.0.0 → 4.1.0)
- CHANGELOG.md (v4.1.0 entry — Phase 5 added, --no-drain flag, new end_states, telemetry schema extension, migration notes)
- tests/eval/CJ_goal_run/phase5-drain-zero-todos/ (new — prompt.md + expected.schema.json + fixture/TODOS.md; verifies silent-skip path emits new_todos_count: 0 and end_state: green)
- tests/eval/CJ_goal_run/phase5-drain-three-todos/ (new — prompt.md + expected.schema.json + fixture/TODOS.md; verifies N=3 happy path emits drained_complete with drained_count=3 and 3 PR URLs)

## Insights

- TODOS.md diff parsing uses `git diff <parent>..HEAD -- TODOS.md`. `<parent>` = the PR's base SHA. `^+### ` grep catches new top-level TODO headings. Excludes contextual lines (`^+- `, `^+  `).
- Recommended Y/N decision: AUQ recommends "yes" iff N ≤ cap=5 (achievable in one pass). If N > 5, AUQ recommends "no" — partial drain isn't really completeness, and operator should choose deliberately.
- Halt-on-red preserves existing /CJ_run halt classes (no NEW halt classes are introduced in this story; the F000021-level new classes `drained_complete`/`drained_partial` map to existing halt mechanics).
- `--no-drain` escape hatch is critical: operators sometimes know the TODOs from this run are out-of-scope to drain right now (e.g., need different reviewers, different time window). Forcing drain would be wrong.

## Journal

- [decision] 2026-05-15: Cap=5 hardcoded for /CJ_goal_run Phase 5 (vs config). Greppable in SKILL.md; P5 explicit-over-clever. Smaller than /CJ_goal_todo_fix's cap=10 because Phase 5 scope is "this run's TODOs" (naturally smaller).
- [decision] 2026-05-15: Per-child /ship Gate #2 (sequential), not batched. Same pattern as /CJ_run Branch (b) multi-story today. Batching would create "review 5 diffs at once" UX which is worse than 5 sequential targeted reviews.
- [decision] 2026-05-15: Phase 5 emits `green` (not `drained_complete`) when `new_todos_count: 0` — drain didn't have to fire because no debt was created. Telemetry distinguishes via the `new_todos_count` field.
- [decision] 2026-05-15: Phase 5 fires only on Step 5 Branch (a) (green deploy). Skipped on `deploy_red` / `halted_at_deploy` — drain assumes the feature PR landed cleanly. Halt classes from Phases 1-4 short-circuit straight to Step 6 without touching Phase 5.
- [decision] 2026-05-15: `--no-drain` is a pre-pass flag (Step 1.0) stripped from args before input-shape detection. Reuses the existing `--auto` / `--manual` accepted-and-discarded pattern from `/CJ_personal-pipeline`. Position-independent (anywhere in arg list); 7-line implementation.
- [decision] 2026-05-15: `drained_complete` / `drained_partial` both exit 0 (Step 7.1). The feature already shipped green in Phase 4; Phase 5 is forward-iteration on new debt, not a halt path. Sunset trip-wire (Step 7's grep regex) excludes both — they're Phase 5 outcomes, not orchestration brittleness.
- [decision] 2026-05-15: v1 calls `/CJ_goal_todo_fix` as a subroutine via the Skill tool (per per-design v1 preference). S000046 will extract the inner loop into a shared `drain-one-todo.sh` helper so this Phase 5 loop and `/CJ_goal_todo_fix`'s own native-drain mode share a single code path. v1 keeps the Skill-tool invocation for simplicity.
- [smoke-pass] 2026-05-15: TEST-SPEC Smoke Tests S1-S5 all pass. S1 (diff parser correctness): `printf '+### new TODO\n+- not a heading\n' | grep -cE '^\+### '` → 1 (correct). S2 (N==0 silent-skip branch): grep finds `new_todos_count` + silent-skip language in run.md. S3 (--no-drain): grep finds `no-drain` in run.md. S4 (telemetry schema): grep finds `drained_count` in both SKILL.md + run.md. S5 (Phase 5 section structural): `awk '/^## Step 5\.5/,/^## Step 6/'` returns 245 lines (well > 20).
- [validate-pass] 2026-05-15: `./scripts/validate.sh` exits 0 (Errors: 0, Warnings: 0).
- [test-pass] 2026-05-15: `./scripts/test.sh` exits 0 (Failures: 0).
