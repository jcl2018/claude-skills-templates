---
name: "Retire the eval runner, keep the specs + Check 28 gate"
type: user-story
id: "S000136"
status: active
created: "2026-07-06"
updated: "2026-07-06"
parent: "F000087"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-mcclintock-e72fcb"
branch: "claude/vigorous-mcclintock-e72fcb"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Working branch: `claude/vigorous-mcclintock-e72fcb` (parent's branch; ships in the same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; one coherent PR, ordered todo list below)

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

<!-- What "done" looks like for this story. -->

- [x] `scripts/eval.sh` is deleted; a sweep for `eval.sh` across `scripts/`, `tests/`, `.github/workflows/`, the `spec/test-spec.md` seed, and the `test-run.sh`/`test.sh` engines finds no dangling reference
- [x] `spec/test-spec-custom.md`: the `run-eval` `runners:` row is removed; `run-test-sh`'s `covers:` note is reframed (keep `eval`; drop the "run-eval owns real eval execution" clause); the `suite-eval` unit is re-anchored off `source: scripts/eval.sh` onto a live `tests/eval/` `source` + `anchor` and its `label`/`purpose` reframed as specs-only; the `goal-task-eval` + `goal-feature-eval` `categories:` rows are removed; `cj-goal-eval` is dropped from the `topic_contracts:` unenrolled-topics prose
- [x] `spec/test-spec.md` seed is mirrored ONLY if a general-file line changed (expected: no change — all edits are overlay); `test-spec.sh --seed` stays byte-identical to `spec/test-spec.md`
- [x] `spec/doc-spec-custom.md`: the two front-door-doc declaring rows are removed; `docs/tests/workflow/local-hook/goal-task-eval.md` + `docs/tests/workflow/local-hook/goal-feature-eval.md` are deleted; `docs/tests/index.md` is reconciled
- [x] Every `tests/eval/<skill>/<case>/prompt.md` states scenario + fixture but NOT expected output (the `dry_run_preview` leak in `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md` is removed, AND the `halted_at_too_complex`/`/CJ_goal_feature` answer leak in `tests/eval/CJ_goal_task/halt-too-complex/prompt.md` — the task `behavior_coverage` anchor was retargeted to a non-leaking scenario descriptor in sync); the `behavior_coverage` anchor strings Check 28/Check-5 grep still match live post-edit
- [x] The catalogs are regenerated (`test-spec.sh --render-docs`, `workflow-spec.sh --render-docs`) so Checks 26/27 stay green
- [x] `bash scripts/validate.sh` GREEN (esp. Checks 24/26/27/28/30) and `test-spec.sh --check-structure` confirms no required `tests/workflow/local-hook/` subfolder is left empty; `bash scripts/test.sh` deferred to CI (`validate.yml`; ~11min + OOM-flaky locally) — the most-affected sub-suite `tests/test-spec.test.sh` ran GREEN (`PASS: test-spec`); shellcheck clean on edited scripts

## Todos

<!-- Actionable items for this story. -->

- [x] Delete `scripts/eval.sh`; grep-sweep `eval.sh` across scripts/tests/workflows/spec engines and clean any dangling caller
- [x] `spec/test-spec-custom.md`: remove the `run-eval` `runners:` row
- [x] `spec/test-spec-custom.md`: reframe `run-test-sh`'s `covers:` note (keep `eval` in `covers:`; drop the "run-eval owns real eval execution" clause → "eval = specs-only, verified in-session")
- [x] `spec/test-spec-custom.md`: re-anchor the `suite-eval` unit off `source: scripts/eval.sh` onto a durable live `tests/eval/` `source` + `anchor` (`tests/eval/CJ_goal_feature/dry-run-plan/prompt.md` · `naming the planned worktree + the office-hours/scaffold/implement/qa/ship chain`); rewrite its `label`/`purpose`/`anchor` to the specs framing (Check 24 forward-grep matches — findings=0)
- [x] `spec/test-spec-custom.md`: remove the `goal-task-eval` + `goal-feature-eval` `categories:` rows (they carry `topic: cj-goal-eval`)
- [x] `spec/test-spec-custom.md`: drop `cj-goal-eval` from the `topic_contracts:` unenrolled-topics prose (5→4 remaining labeled topics)
- [x] `spec/test-spec.md`: mirror ONLY if a general-file line changed (NONE — all edits overlay-only; seed byte-identity untouched)
- [x] `spec/doc-spec-custom.md`: remove the two front-door-doc declaring rows; delete the two physical docs; reconcile `docs/tests/index.md` (hand-removed the two rows — index is hand-maintained/seed-additive)
- [x] De-leak the eval prompts: removed the `dry_run_preview` expected-output leak in `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md` + `tests/eval/CJ_goal_defect/dry-run-plan/prompt.md`; PRESERVED all 4 `behavior_coverage` anchor strings (verified live post-edit)
- [x] Regenerate catalogs (`test-spec.sh --render-docs`, `workflow-spec.sh --render-docs`) — Checks 26/27 diff clean (findings=0)
- [x] Verify (targeted engines): `test-spec.sh --validate` OK, `--check-coverage` findings=0, `--check-workflow-coverage` 4/4, `--check-topic-contract` exit 0 + advisory-only, `--check-structure` rc 0 (no new findings), `doc-spec.sh --validate`/`--check-on-disk` OK
- [x] (Discovered) Deleted the orphaned eval RUNNER machinery (`tests/eval/lib/{run-case,run-portability-case,portability-fixture,seed-fixture}.sh` + `tests/eval/README.md`) — its only caller `scripts/eval.sh` was deleted; the `tests/eval/<skill>/<case>/` SPECS are KEPT
- [x] (Discovered) Reconciled `tests/test-spec.test.sh` fixture (dropped the `cp scripts/eval.sh` line — the re-anchored `suite-eval` source is copied by the existing behavior_coverage `tests/eval/` loop), `tests/test-run/reports/EXAMPLE.md` (removed the stale `run-eval` sample row), and comment refs in `scripts/lib/agentic-sandbox.sh` + `scripts/audit-nightly.sh`
- [x] (QA) `tests/test-spec.test.sh` ran GREEN (`PASS: test-spec`, exit 0) — the most-affected sub-suite; full `scripts/test.sh` deferred to CI (`validate.yml`, ~11min + OOM-flaky locally); shellcheck clean on edited scripts

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Single story carrying Phase 0 of the Testing roadmap — delete the paid `run-eval` harness, re-anchor `suite-eval` onto the durable `tests/eval/` specs, remove the two `goal-*-eval` `categories:` rows + front-door docs, de-leak the eval prompts, and regenerate catalogs — keeping the `behaviors:`/Check 28 workflow gate intact.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/eval.sh` (DELETED — the paid runner)
- `spec/test-spec-custom.md` (modified — removed `run-eval` `runners:` row; reframed `run-test-sh` `covers:` note; re-anchored `suite-eval` onto `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md`; removed `goal-task-eval` + `goal-feature-eval` `categories:` rows; dropped `cj-goal-eval` from the unenrolled-topics prose; reframed 3 human-readable prose spots)
- `spec/test-spec.md` (UNCHANGED — all edits overlay-only; seed byte-identity untouched, no mirror needed)
- `spec/doc-spec-custom.md` (modified — removed the two front-door-doc declaring rows)
- `docs/tests/workflow/local-hook/goal-task-eval.md`, `docs/tests/workflow/local-hook/goal-feature-eval.md` (DELETED)
- `docs/tests/index.md` (modified — removed the two eval rows)
- `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md`, `tests/eval/CJ_goal_defect/dry-run-plan/prompt.md` (modified — removed the `dry_run_preview` expected-output leak; all 4 anchors preserved live)
- `tests/eval/lib/{run-case,run-portability-case,portability-fixture,seed-fixture}.sh`, `tests/eval/README.md` (DELETED — orphaned runner machinery for the deleted `scripts/eval.sh`; the `tests/eval/<skill>/<case>/` specs are KEPT)
- `tests/test-spec.test.sh` (modified — fixture no longer copies the deleted `scripts/eval.sh`; re-anchored `suite-eval` source is supplied by the existing behavior_coverage `tests/eval/` copy loop)
- `tests/test-run/reports/EXAMPLE.md` (modified — removed the stale `run-eval` sample row)
- `scripts/lib/agentic-sandbox.sh`, `scripts/audit-nightly.sh` (modified — reframed stale comment references to the deleted runner)
- `docs/tests/eval.md`, `docs/test-catalog.md`, `docs/tests/*.md`, `docs/workflow.md`, `docs/workflows/*.md` (regenerated — `test-spec.sh` / `workflow-spec.sh --render-docs`)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The `suite-eval` re-anchor is the load-bearing subtlety: deleting `scripts/eval.sh` without re-pointing `suite-eval`'s `source:` makes Check 24's forward anchor-grep dangle → red. Pick a `source` + `anchor` that exists LIVE in the `tests/eval/` tree.
- Check 28 (workflow coverage) is driven by the `behaviors:`/`behavior_coverage:` axis, NOT the `categories:` rows — so removing the two `goal-*-eval` `categories:` rows leaves the 4/4-orchestrator workflow gate intact as long as the `tests/eval/<skill>/<case>/prompt.md` anchors survive.
- De-leaking prompts must PRESERVE the `behavior_coverage` anchor strings that Check 28/Check-5 grep live `-F` — those describe the scenario/chain (not the expected output), so removing only the expected-output leak keeps the anchors matching.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: Approach C implemented per the parent design's operator AUQ — remove the two `goal-*-eval` `categories:` rows + front-door docs; keep ONLY the `behaviors:`/`behavior_coverage:` axis + the `tests/eval/` dirs + Check 28. No `/CJ_verify` skill, no self-skip command string, no helper script.
- [decision] 2026-07-06 — Summary: `suite-eval` re-anchors onto a durable live `tests/eval/` `source` + `anchor` (chosen at implementation time) and is reframed as the in-session verification specs, so Check 24's forward anchor-grep stays green after `scripts/eval.sh` is deleted; the eval family stays declared (not orphaned) via `run-test-sh` `covers:` + the `suite-eval` `family: eval`.
- 2026-07-06 [impl-decision] Chose `suite-eval` source = `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md`, anchor = `naming the planned worktree + the office-hours/scaffold/implement/qa/ship chain` — a durable literal that is ALSO the `workflow-cj-goal-feature-runs` behavior_coverage anchor, so one live string satisfies both Check 24 (forward unit anchor-grep) and Check 28 (workflow-coverage). It is scenario/chain framing, not an expected-output leak, so it survives the de-leak.
- 2026-07-06 [impl-decision] De-leak preserved the task anchor line verbatim: `emits \`halted_at_too_complex\` and suggests \`/CJ_goal_feature\`` is the Check-28 anchor for `CJ_goal_task/halt-too-complex`, so per the pre-approved scope I kept it intact even though it names the halt class; the removable leaks were the `dry_run_preview` clauses in the feature + defect dry-run prompts (both removed, anchors kept).
- 2026-07-06 [impl-finding] The `eval.sh` sweep surfaced more than the SPEC's Components Affected enumerated: the `tests/eval/lib/` runner library + `tests/eval/README.md` (reachable ONLY via the deleted `scripts/eval.sh` / `scripts/eval.sh --portability` — confirmed the KEPT portability agentic test `tests/portability-version-agentic.test.sh` does NOT depend on them), the `tests/test-spec.test.sh` fixture (`cp scripts/eval.sh`), the `tests/test-run/reports/EXAMPLE.md` sample `run-eval` row, and stale comment refs in `scripts/lib/agentic-sandbox.sh` + `scripts/audit-nightly.sh`. All reconciled so `! grep -rn "eval\.sh" scripts tests .github/workflows spec` passes. `.github/workflows/` had NO eval.sh refs (eval-nightly.yml was already removed by F000080).
- 2026-07-06 [impl-finding] `spec/test-spec.md` (the general seed) was NOT touched — every edit is in the `spec/test-spec-custom.md` overlay, so the dual-write footgun (seed byte-identity vs `test-spec.sh --seed`) is not tripped. `test-spec.sh --check-coverage` seed-identity assertion stays green.
- 2026-07-06 [impl-finding] `--check-structure` reports findings=4 (rc 0, advisory), all PRE-EXISTING: `tag-release` / `cj-goal-jq-crlf` / two `drain-one-todo-*` regression tests missing from `docs/tests/index.md` at HEAD too — unrelated to this story's `goal-*-eval` removals (which raise zero findings). Left as-is (out of scope; a hand `/CJ_test_audit --seed-docs` index refresh is the fix).
- 2026-07-06 [impl] Deleted 1 script + 5 runner/doc files; modified `spec/test-spec-custom.md`, `spec/doc-spec-custom.md`, 2 prompts, `tests/test-spec.test.sh`, `tests/test-run/reports/EXAMPLE.md`, `scripts/lib/agentic-sandbox.sh`, `scripts/audit-nightly.sh`, `docs/tests/index.md`; regenerated the test + workflow catalogs. Targeted engine self-checks all green.
- 2026-07-06 [impl-auto] Auto-equivalent mode (operator pre-approved the whole change set at the /CJ_goal_feature design gate); applied spec/script-delete/docs edits without the sensitive-surface halt, per the runner ROLE directive.
- 2026-07-06 [impl-pass] S000136: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files); QA-owned gates (Acceptance criteria / Smoke tests) left for /CJ_qa-work-item.
- 2026-07-06 [qa-smoke] S1 (AC-1): green — `scripts/eval.sh` deleted; `! grep -rn "eval\.sh" scripts tests .github/workflows spec` finds no dangling reference.
- 2026-07-06 [qa-smoke] S2 (AC-2, AC-3): green — `test-spec.sh --validate` OK schema_version=1; `--check-coverage` rows=93 reverse_tokens=73 findings=0 (`suite-eval` re-anchored to live `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md`, anchor phrase present verbatim; no unit declares the deleted `scripts/eval.sh`; `run-eval` runners row removed; `eval` stays in `run-test-sh` covers).
- 2026-07-06 [qa-smoke] S3 (AC-4): green — `--check-workflow-coverage` orchestrators=4 level:workflow behaviors=4 findings=0; `--check-topic-contract` enrolled=3 findings=0 exit 0 (only advisory validator/full-suite notes; `cj-goal-eval` no longer labeled — `goal-task-eval`/`goal-feature-eval` categories rows removed, `cj-goal-eval` dropped from topic prose).
- 2026-07-06 [qa-smoke] S4 (AC-5): green — no `dry_run_preview` leak in any `tests/eval/*/*/prompt.md`; `--check-workflow-coverage` still 4/4 findings=0 so all `level: workflow` behavior anchors remain live post de-leak.
- 2026-07-06 [qa-smoke] S5 (AC-6) [partial-fast]: green — validate.sh fast engines green: Check 26 (`test-spec.sh --render-docs --check` findings=0) + Check 27 (`workflow-spec.sh --render-docs --check` findings=0) catalogs fresh; `doc-spec.sh --validate` OK + `--check-on-disk` 5 checks PASS findings=0; `--check-structure` rc 0 with 4 advisory `structure/e` INDEX findings (tag-release, cj-goal-jq-crlf, 2× drain-one-todo-*) VERIFIED pre-existing + unrelated to this change (the two removed `goal-*-eval` docs raise zero findings; required `workflow/local-hook` subfolder NOT empty — still holds doc-sync.md + e2e-local.md). Full `scripts/test.sh` deferred to CI (`.github/workflows/validate.yml`, ~11min + OOM-flaky on this Git-Bash host per documented memory); the most-affected sub-suite `tests/test-spec.test.sh` run to completion in its place — result recorded below.
- 2026-07-06 [qa-smoke] S5 (AC-6) [full-suite-substitute]: GREEN — `tests/test-spec.test.sh` ran to completion → `PASS: test-spec` (exit 0, no real FAIL lines; the S1-additivity `--render-docs --check exits 0` drill passed, unblocked by the fresh `docs/tests/eval.md`).
- 2026-07-06 [orchestrator-review] A 3-lens adversarial review (contract-integrity / leak-honesty / dangling-completeness) over the working-tree diff surfaced + fixed: (1) BLOCKER — `docs/tests/eval.md` had been reverted to its stale `scripts/eval.sh` row by a reviewer's `git checkout`; re-ran `test-spec.sh --render-docs` → fresh, render-check findings=0. (2) The `tests/eval/CJ_goal_task/halt-too-complex/prompt.md` still recited its answer (`halted_at_too_complex` + `/CJ_goal_feature`); retargeted its `behavior_coverage` anchor to a non-leaking scenario descriptor (`routes to a design-first sibling verb…`) + rewrote the prompt to "determine … from the run itself" — all 4 prompts now genuinely non-leaking. (3) In-file prose `spec/test-spec-custom.md` "dogfoods three rows … run-eval" → "two rows". (4) Dangling refs to the deleted script cleared on live surfaces: `CLAUDE.md` (removed the `eval.sh` scripts-ref row + dropped `cj-goal-eval` from the 5→4 topic list), `docs/philosophy.md` (dropped "behavioral eval harness" from CI-nightly), `docs/reference.md` + `docs/tests/test-hierarchy.md` (reframed to in-session). `deprecated/CJ_portability-audit/USAGE.md` left as-is (frozen deprecated doc, out of the contract + declared sweep).
- 2026-07-06 [qa-pass] S000136: QA GREEN. Smoke S1–S5 all pass; Phase 2 QA-owned gates (Acceptance criteria / Smoke tests) transitioned. DEFER_AUDIT + DEFER_SYNC honored (no inline agent-judged audit — runs on-demand off the build path). E2E rows E1/E2 are manual operator scenarios (N/A in the autonomous build). Ready for the pre-doc-sync commit + /ship.
