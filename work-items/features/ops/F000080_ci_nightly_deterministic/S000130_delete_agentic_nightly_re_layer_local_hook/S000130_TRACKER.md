---
name: "Delete agentic cron wrappers + re-layer the 3 tests to local-hook + prose sweep"
type: user-story
id: "S000130"
status: active
created: "2026-07-03"
updated: "2026-07-03"
parent: "F000080"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-volhard-9dcadc"
branch: "claude/vigorous-volhard-9dcadc"
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
2. Create working branch: `git checkout -b feat/ci_nightly_deterministic` (or use parent's branch if shipping in same PR)
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

- [x] Both cron wrappers deleted: `.github/workflows/eval-nightly.yml` and `audit-nightly.yml` are gone; the only scheduled workflow left is `windows-nightly.yml`.
- [x] `spec/test-spec-custom.md`: the 3 `categories:` rows (`goal-task-eval`, `goal-feature-eval`, `doc-sync`) read `layer: local-hook` with `doc:` paths under `docs/tests/workflow/local-hook/`; `mode: agentic` + `tier: paid` retained; the `ci-eval-nightly` and `ci-audit-nightly` `units:` rows are removed. (Also repointed the `suite-eval` unit off the deleted `eval-nightly.yml` onto `scripts/eval.sh` — see Journal.)
- [x] The 3 front-door docs are `git mv`'d to `docs/tests/workflow/local-hook/`, each with its `## How to run` reframed to on-demand/local (no "runs nightly in CI"); `docs/tests/index.md` moves the 3 rows to the `local-hook` column with fixed link paths. (The co-located deterministic guard `tests/workflow/CI-nightly/doc-sync.test.sh` moved too.)
- [x] `spec/doc-spec-custom.md`'s 3 declaration rows point at the `local-hook/` paths (declared == on-disk).
- [x] Prose sweep done across `CLAUDE.md`, `docs/architecture.md`, `docs/reference.md`, `docs/philosophy.md`, `docs/tests/test-hierarchy.md`, `spec/workflow-spec.md` (+ regenerated `docs/workflows/*.md`), and the 4 `CJ_goal_*` + `CJ_qa-work-item` + `CJ_doc_audit` + `CJ_test_audit` SKILL/USAGE/pipeline files (+ `skills-catalog.json` → regenerated `README.md`): "nightly in CI via audit-nightly.yml" → on-demand/local.
- [x] `bash scripts/test-spec.sh --render-docs` + `bash scripts/workflow-spec.sh --render-docs` regenerated; `test-spec.sh --check-structure` findings=0; `./scripts/validate.sh` GREEN (rc=0; Checks 15/15a/16/24/26/27/28 all PASS + shellcheck clean). NOTE: local `./scripts/test.sh` is red ONLY from a pre-existing Windows Git Bash `grep -q` SIGABRT crash on very-long-line SKILL.md files (unchanged files; phrases present) — the authoritative Linux CI runs it green.

## Todos

<!-- Actionable items for this story. -->

- [x] Part 1 — `rm .github/workflows/eval-nightly.yml` and `rm .github/workflows/audit-nightly.yml`.
- [x] Part 2 — `spec/test-spec-custom.md`: re-layer 3 `categories:` rows to `local-hook` + update `doc:` paths; remove `ci-eval-nightly` + `ci-audit-nightly` units; soften line ~37 prose + the CI-nightly/local-hook subsections + the `doc-sync` behavior `statement` (kept the behavior + its `behavior_coverage`); **repointed `suite-eval` off the deleted workflow onto `scripts/eval.sh`**.
- [x] Part 3 — `git mv` the 3 front-door docs to `docs/tests/workflow/local-hook/`; reframed each `## How to run` to on-demand/local + the `/CJ_test_run --layer local-hook` invocation; moved the co-located `doc-sync.test.sh` guard too.
- [x] Part 4 — `docs/tests/index.md`: moved the 3 INDEX rows from `CI-nightly` to `local-hook`; fixed markdown link paths.
- [x] Part 5 — `spec/doc-spec-custom.md`: updated the 3 declaration rows to the `local-hook/` paths.
- [x] Part 6 — prose sweep across `CLAUDE.md`, `docs/architecture.md`, `docs/reference.md`, `docs/philosophy.md`, `docs/tests/test-hierarchy.md`, `spec/workflow-spec.md` (then `--render-docs`), the 4 `CJ_goal_*` SKILL/pipeline/USAGE + `CJ_qa-work-item`/`CJ_doc_audit`/`CJ_test_audit`, `skills-catalog.json` (→ regenerated `README.md`), and code comments (`scripts/{eval,audit-nightly,test}.sh`, 2 test files). CHANGELOG release entry via `/ship`.
- [x] Part 7 — regenerated (`test-spec.sh --render-docs` + `workflow-spec.sh --render-docs`), `test-spec.sh --check-structure` findings=0, `./scripts/validate.sh` GREEN (rc=0). Local `test.sh` red only from the pre-existing Windows grep-crash (Linux CI green).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Single atomic story delivering the 7-part file set that makes `CI-nightly` deterministic — deletes the two agentic cron wrappers, re-layers the 3 agentic tests to `local-hook`, and sweeps the prose to match.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `.github/workflows/eval-nightly.yml` (delete)
- `.github/workflows/audit-nightly.yml` (delete)
- `spec/test-spec-custom.md`
- `spec/doc-spec-custom.md`
- `docs/tests/workflow/CI-nightly/goal-task-eval.md` → `docs/tests/workflow/local-hook/goal-task-eval.md`
- `docs/tests/workflow/CI-nightly/goal-feature-eval.md` → `docs/tests/workflow/local-hook/goal-feature-eval.md`
- `docs/tests/workflow/CI-nightly/doc-sync.md` → `docs/tests/workflow/local-hook/doc-sync.md`
- `docs/tests/index.md`
- `spec/workflow-spec.md` (+ generated `docs/workflow.md`, `docs/workflows/*.md`)
- `CLAUDE.md`, `docs/architecture.md`, `docs/reference.md`
- `skills/CJ_goal_feature/*`, `skills/CJ_goal_task/*`, `skills/CJ_goal_defect/*`, `skills/CJ_goal_todo_fix/*`
- `skills/CJ_qa-work-item/*`, `skills/CJ_doc_audit/*`

## Insights

<!-- Non-obvious findings worth remembering. -->

- The deferred-audit BEHAVIOR (`DEFER_AUDIT: true`, orchestrators don't run the audit inline) is UNCHANGED — only the "where the deferred audit runs" clause changes from "nightly in CI via audit-nightly.yml" to "on-demand locally." This keeps the sweep a characterization swap, not a behavior change.
- The `doc-sync` behavior + its `behavior_coverage` (backed by `tests/cj-goal-doc-sync-wiring.test.sh`, deterministic) STAY — they are re-characterized, not deleted. Only the `ci-audit-nightly` / `ci-eval-nightly` `units:` rows (whose `source:` `.yml` files are deleted) are removed.
- Check 28 is verified UNAFFECTED (design Premise 5): workflow behaviors link via `workflow: CJ_goal_*` and `behavior_coverage` `source:` at `tests/eval/*/prompt.md`, NOT the `categories:` `layer` — re-layering category rows leaves the workflow-coverage gate untouched (orchestrators=4, behaviors=4).
- `local-hook` already has `docs/tests/workflow/local-hook/` (it holds `e2e-local.md`), so the `git mv` target folder exists — no new folder needed.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03: This feature is a single cohesive change (the 7-part file set is one coordinated edit that must land atomically for validate/test to stay green), so it is scaffolded as ONE atomic user-story with no task children (`[x] Tasks broken down (N/A — atomic story)`). Summary: single-story feature; no further decomposition warranted.
- [finding] 2026-07-03: The design's Premise 5 ("Check 28 unaffected") was correct but INCOMPLETE. Deleting `eval-nightly.yml` would ALSO have broken **Check 24** (not just 28): the `suite-eval` unit — which BACKS the four `level: workflow` behaviors — had `source: .github/workflows/eval-nightly.yml`, so its forward anchor-grep would fail once that file was gone. Fix: repointed `suite-eval` onto `source: scripts/eval.sh` with `anchor: "Behavioral eval harness"` (a live literal in eval.sh:2), `layer: local-hook`, `trigger: manual`. The validator's closed `trigger` enum (`{pre-commit, post-merge, pr-ci, push-main, nightly, manual}`) rejected an initial `local manual`, and the rendered-field work-item-ID lint rejected an `F0000NN` in the `test-audit-nightly` purpose — both caught by `test-spec.sh --validate` and fixed. Summary: repoint contract units whose `source:` is a deleted file, not just remove the directly-orphaned ones.
- [finding] 2026-07-03: `tests/workflow/CI-nightly/doc-sync.test.sh` (the deterministic sibling guard) exists on disk but is NOT registered in `units:` and NOT run by `test.sh` — the reverse sweep globs `tests/*.test.sh` NON-recursively (`test-spec.sh:1340`), so nested category-folder tests are invisible to it. Moved it to `tests/workflow/local-hook/` to keep it co-located with its (re-layered) test; `--check-structure` (b) derives file-backed pairs from actual `*.test.sh` presence, so the move kept findings=0. Summary: the category-folder test guards are convention-placed, not suite-wired.
- [finding] 2026-07-03: QA E1 (grep for live nightly-CI claims) caught a real stale reference the prose-sweep missed: `docs/tests/test-hierarchy.md` (lines 44 + 88) still said the eval cases run "nightly (eval-nightly.yml)" and the audit "moved to a nightly CI job" — it was excluded from the sweep because it lives under `docs/tests/`. Fixed both to on-demand. Summary: the QA E1 doc-truthfulness grep earned its place — the automated safety net we're removing would otherwise have caught this.
- [finding] 2026-07-03: Local `./scripts/test.sh` shows 4 FAILs in `cj-audit-skills.test.sh`, ALL a pre-existing Windows Git Bash environment bug: `grep -qiF <pat>` ABORTS (rc=134/SIGABRT) on the CJ_doc_audit/CJ_test_audit SKILL.md files (UTF-8 "very long lines, 2146 chars"). Verified NOT a regression: those SKILL.md files are byte-identical to HEAD (`git diff` empty), the grepped phrases still exist (`grep -c` finds them), and the authoritative Linux CI runs the same test green. Matches the documented Windows-local `test.sh` redness. Summary: distinguish Windows-grep-crash artifacts from real failures by checking the target file is unchanged + the phrase present.
- [qa-pass] 2026-07-03: QA GREEN. Smoke S1-S4 + E2E E1-E3 all pass; `./scripts/validate.sh` rc=0 (Checks 15/15a/16/24/26/27/28 + shellcheck all PASS); Check 28 = orchestrators=4/behaviors=4/findings=0 (workflow-coverage verified untouched). One doc-truthfulness finding (test-hierarchy.md) found + fixed inline. The only red is the pre-existing Windows grep-crash in `test.sh` (Linux CI green). Landable.
