---
name: "complete Phase 2 test coverage: cj_test self-test infra rows plus D000019 QA-gate shape-guard drill"
type: task
id: "T000058"
status: active
created: "2026-07-07"
updated: "2026-07-07"
parent: ""
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-mcclintock-e72fcb"
branch: "claude/phase2-coverage-gaps"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/complete_phase_2_test_coverage_cj_test`
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
   → design doc at `~/.gstack/projects/complete_phase_2_test_coverage_cj_test/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log) — deferred: builder run stops before commit (operator commits via /ship)
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
- [x] Test-plan verified (all scenarios passing) — all targeted engines green + the D000019 drill's 3 grep needles confirmed LIVE + fails-on-mutation
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] GAP 2: promote the 3 cj_test self-test suites to first-class `categories: infra` CI-push rows (`test-run-self`, `test-spec-self`, `cj-audit-self`) + 3 front-door docs + doc-spec declarations + index rows
- [x] GAP 3: author the D000019 type-aware QA-gate shape-guard drill in `scripts/test.sh` + flip its `defect_coverage:` ledger row to `covered-by-anchor`
- [x] Regenerate catalogs (`test-spec.sh` + `workflow-spec.sh --render-docs`) + run all targeted engine self-checks green

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-07-07: Created. Auto-scaffolded by /CJ_goal_task from topic: complete Phase 2 test coverage: cj_test self-test infra rows plus D000019 QA-gate shape-guard drill
- 2026-07-07: GAP 2 — added 3 `categories: infra` CI-push rows (test-run-self / test-spec-self / cj-audit-self) to `spec/test-spec-custom.md`, created their 3 front-door docs under `docs/tests/infra/CI-push/`, declared them in `spec/doc-spec-custom.md`, and added their `docs/tests/index.md` rows. `--check-structure` checks (d)+(f) PASS for all three; zero new structural findings vs baseline (13 pre-existing structure/e findings on unrelated tests, unchanged).
- 2026-07-07: GAP 3 — added the `Regression test (D000019): QA gates stay type-aware` shape-guard block to `scripts/test.sh` (grep-pins the qa.md per-type dispatch table rows + the defect/task E2E-always-empty ambiguous-is-N/A clause + the todo_fix.sh `skills/*/scripts/` trust-boundary surface), and flipped the D000019 `defect_coverage:` ledger row from `waived` to `covered-by-anchor` → `scripts/test.sh`. Check 32 now `dirs=38 rows=38 findings=0`.
- 2026-07-07: Regenerated catalogs; all targeted engine self-checks green (see Journal). No commit (builder stops before /ship).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec-custom.md` — +3 `categories: infra` CI-push rows; D000019 `defect_coverage:` row flipped waived → covered-by-anchor
- `spec/doc-spec-custom.md` — +3 declared per-test doc rows
- `docs/tests/infra/CI-push/test-run-self.md` — NEW front-door doc
- `docs/tests/infra/CI-push/test-spec-self.md` — NEW front-door doc
- `docs/tests/infra/CI-push/cj-audit-self.md` — NEW front-door doc
- `docs/tests/index.md` — +3 INDEX rows (satisfies `--check-structure` (e))
- `docs/testing.md` — regenerated (category-test index now carries the 3 rows)
- `scripts/test.sh` — NEW `Regression test (D000019)` shape-guard block
- `work-items/tasks/ops/T000058_.../` — this tracker + test-plan

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): complete Phase 2 test coverage: cj_test self-test infra rows plus D000019 QA-gate shape-guard drill

- The D000019 RCA points at `skills/CJ_personal-pipeline/pipeline.md`, which was reshaped away. The type-aware halt / ambiguous-is-N/A semantics now live in `skills/CJ_qa-work-item/qa.md` (per-type dispatch table + `E2E_ROWS = []` for defect/task), while the `skills/*/scripts/` pre-scan trust boundary migrated to the `todo_fix.sh` sensitive-surface scan (`skills/[^/]+/scripts/`). The drill anchors those live surfaces, not the retired file.
- The 3 self-test rows are deliberately UN-topic'd: they are not enrolled in the three-layer topic contract (Check 30 unaffected, enrolled=6). `--seed-docs` would overwrite `docs/tests/index.md` (dropping its hand-maintained Topic column + prose), so the index was hand-edited instead — `--check-structure` (e) only requires the name/path be referenced, and `--render-docs --check` does NOT diff `index.md` (it diffs `docs/testing.md` + the family docs + catalog).
- The em-dash (—) in the qa.md grep anchors trips shellcheck's Windows-console output writer (`commitBuffer: cannot encode '\8212'`) but not the lint itself; `shellcheck -f gcc` to a file confirms 0 findings. The 3 SC2016 notes (backticks/`$` in single-quoted grep needles) were suppressed with `# shellcheck disable=SC2016` comments, matching the existing D000025/setup-hook blocks.

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-07-07 [decision] GAP 2 self-test rows kept UN-topic'd (not enrolled in the three-layer topic contract) — they are standing CI-push infra, not a whole-topic concern; hand-edited `docs/tests/index.md` rather than `--seed-docs` (which would nuke the hand-maintained Topic column).
- 2026-07-07 [finding] D000019's guarded surfaces migrated off the RCA's `skills/CJ_personal-pipeline/pipeline.md` (retired) onto `skills/CJ_qa-work-item/qa.md` + `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`; the drill anchors the LIVE surfaces. Negative test confirmed: removing the `E2E always empty` clause makes the drill FAIL loudly.
- 2026-07-07 [finding] Self-checks all green: `test-spec.sh --validate` OK; `--check-coverage` rows=97 findings=0; `--render-docs --check` in sync findings=0; `--check-topic-contract` enrolled=6 findings=0; `--check-defect-coverage` dirs=38 rows=38 findings=0; `--check-structure` +0 new findings vs baseline (13 pre-existing, unrelated); `doc-spec.sh --validate`+`--check-on-disk` FINDINGS=0; seed identity IDENTICAL; `shellcheck scripts/test.sh` 0 findings.

<!-- Source: /CJ_goal_task: complete Phase 2 test coverage: cj_test self-test infra rows plus D000019 QA-gate shape-guard drill -->

- 2026-07-07 [qa-pass] T000058 QA GREEN (verified independently by the orchestrator). GAP 2: `--check-coverage` rows=97 findings=0 (3 new infra rows resolve), `doc-spec --check-on-disk` FINDINGS=0 (3 front-door docs declared/present/ID-free, each 3/3 F000077 sections), `--check-structure` +0 new findings, the 3 rows flow into the generated `docs/testing.md` category index (+3). GAP 3: `--check-defect-coverage` dirs=38 rows=38 findings=0 with D000019 `covered-by-anchor` → the `scripts/test.sh` drill; the drill's 3 grep needles confirmed LIVE in `skills/CJ_qa-work-item/qa.md` (defect/task dispatch rows + the E2E-always-empty clause) + `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (`skills/[^/]+/scripts/` trust boundary), passes on the current tree + fails-on-mutation. `--render-docs --check` findings=0 (Check 26 — docs/testing.md fresh); seed byte-identity IDENTICAL; shellcheck clean. Ready for /ship.
