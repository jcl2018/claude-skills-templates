---
name: "/CJ_test_run — execute the test contract and report real pass/fail"
type: feature
id: "F000072"
status: active
created: "2026-07-01"
updated: "2026-07-01"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/dazzling-shirley-87c62e"
branch: "claude/dazzling-shirley-87c62e"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/{slug}`
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

- [ ] On this workbench: `bash scripts/test-run.sh --dry-run` prints an honest plan; a default run executes `test.sh` once and writes a green report + ledger whose aggregate matches the real rc.
- [ ] On a bare consumer repo (rules-only registry, no runners): honest `SKIP: no runners declared`, exit 0, no execution, no report, no ledger.
- [ ] On a fixture with a failing runner: aggregate FAIL, exit 1, verbatim FAIL lines in the report, ledger outcome `fail`.
- [ ] `--evals`/`--e2e` execute only when passed; a default run never touches a model (free tier only).
- [ ] Full `validate.sh` + `scripts/test.sh` green including the new units rows, catalog entry, roster entry, regenerated docs; `/CJ_test_run` invocable standalone.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] PREREQUISITE (separate /CJ_goal_defect run, not in this diff): land the jq-CRLF defect fix — workbench scripts consume `$(jq -r ...)` without stripping CR; on Windows jq builds this false-halts `workflow-spec.sh --list-orchestrators` and cascades into `test-spec.sh` + `validate.sh` Checks 24/26/27/28, blocking every commit on this machine.
- [ ] S000122: `runners:` grammar + `--validate` rules + `--list-runners` + `--list-units --with-family` in `test-spec.sh`, with parser fixtures.
- [ ] S000122: `test-run.sh --dry-run` (the plan) — verify it reads honestly on this repo AND a bare fixture repo.
- [ ] S000122: execution + report + `.json` run ledger (evidence-derived aggregate, closed skip-reason enums).
- [ ] S000122: workbench overlay `runners:` rows + `/CJ_test_run` wrapper skill + paperwork (catalog, routing, roster, philosophy, units rows, regenerated docs).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-01: Created. /CJ_test_run — execute the test contract and report real pass/fail: a `runners:` overlay axis in the test contract + a `scripts/test-run.sh` engine (plan / tiered execution / report + ledger) + the `/CJ_test_run` skill wrapper. Scaffolded from the approved /office-hours design (chang-claude-dazzling-shirley-87c62e-design-20260701-161358.md).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/test-spec.sh` — `runners:` axis grammar, `--validate` rules, `--list-runners`, `--list-units --with-family` (Modified)
- `scripts/test-run.sh` — the execution engine (New)
- `spec/test-spec-custom.md` — workbench `runners:` rows + new units rows (Modified)
- `skills/CJ_test_run/` — SKILL.md + USAGE.md wrapper (New)
- `tests/test-run.test.sh` — fixture-repo unit tests (New)
- `skills-catalog.json`, `rules/skill-routing.md`, `spec/workflow-spec.md`, `docs/philosophy.md`, regenerated `docs/` (Modified)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The contract becomes executable: the `runners:` axis makes the registry declare both what exists (units/behaviors) and HOW to run it — any adopting repo gets real execution from the same portable engine, not a hardcoded workbench table.
- The run ledger is the first citable evidence artifact for the contract's own `suite-green` rule — the staged handshake that later lets `/CJ_test_audit` Stage 1 check "a green ledger exists, newer than HEAD, covers the free tier" deterministically instead of judging from scrollback.
- Honest everywhere: runner-granularity verdicts, named SKIP reasons, aggregate derived from evidence — a skipped tier is never counted green (the `e2e-local.sh` report posture, generalized).
- The audit/run separation was operator-driven from the start: `/CJ_test_audit` answers "is it wired?", `/CJ_test_run` answers "does it pass?" — the audit stays READ-ONLY.
- Live proof of the gap this closes: the operator's Windows machine had `validate.sh` red (jq-CRLF defect) while every audit-of-record was green.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-01 — Summary: Chose Approach A (runners-axis core, one PR) over B (core + audit handshake + `--changed`; XL, three sensitive surfaces in one diff) and C (hardcoded family→command mapping table; contradicts the operator's D4 decision that the CONTRACT defines what runs). Defers the audit-side ledger check and `--changed` as explicit follow-ups.
- [decision] 2026-07-01 — Summary: Premise 4 was revised twice, operator-driven: the skill is a standalone any-repo utility and the contract defines what runs there — v1 ships the optional `runners:` overlay axis; a registry with no `runners:` rows yields an honest `SKIP: no runners declared`, never inference, never fake green.
- [decision] 2026-07-01 — Summary: One workbench runner row (`run-test-sh`) covers validate + test + test-deploy + windows-smoke — VERIFIED that test.sh drives all four; a separate windows-smoke row would double-execute on Windows and report `skipped(platform)` on POSIX while test.sh actually ran it.
- [blocker] 2026-07-01 — Summary: Build order step 1 is a prerequisite landed OUTSIDE this feature: the jq-CRLF defect fix (separate /CJ_goal_defect run). Until it lands, the red `validate.sh` on the operator's Windows machine blocks every commit, including this feature's build.
