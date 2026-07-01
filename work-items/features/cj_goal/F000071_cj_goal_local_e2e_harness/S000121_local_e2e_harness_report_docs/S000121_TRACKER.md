---
name: "Local-E2E harness + materialized report + workflow docs (Part B/C)"
type: user-story
id: "S000121"
status: active
created: "2026-06-30"
updated: "2026-06-30"
parent: "F000071"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-happy-e2e"
blocked_by: ""
---

<!-- Prerequisite: the parent feature F000071's /office-hours session is the
     design context for this atomic story; DESIGN.md links to the parent. Part A
     (the seam) shipped as S000120; this is Part B + Part C. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: use the parent's branch (ship Part B/C in one PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table) — LOCAL only
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually (LOCAL — needs gstack + key + gh)
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `scripts/e2e-local.sh` provisions a sandbox, runs `/CJ_goal_task` for real via the Part-A seam, and stops at the `/ship` boundary (LOCAL, gated on `CJ_E2E_LOCAL=1`).
- [ ] With `CJ_E2E_LOCAL` unset (CI / normal `test.sh`), the harness SKIPs with a one-line reason (exit 0) and never invokes `claude`.
- [ ] `tests/e2e-local/lib/sandbox.sh` makes a `mktemp` clone + a `.cj-e2e-sandbox` marker + a LOCAL bare origin (accepts push, defeats `gh pr create`); teardown removes the tmpdir.
- [ ] Every run writes `tests/e2e-local/reports/<verb>-<UTC-ts>.md` (+ a `.json` sibling) whose coverage rows are labelled DETERMINISTIC vs `claude --print` and verified by real post-run grep evidence (a new `work-items/tasks/T*/` dir, a non-empty diff, the run's `end_state`).
- [ ] `tests/e2e-local/reports/` is gitignored with an un-ignored `!EXAMPLE.md`; a committed `EXAMPLE.md` sample exists.
- [ ] `tests/e2e-local.test.sh` asserts (no Claude): the SKIP path + sandbox provision/teardown + the report generator on synthetic evidence + EXAMPLE-tracked/reports-ignored — wired as a `units:` row + a `scripts/test.sh` runner block.
- [ ] Part C: a `### scripts/e2e-local.sh` subsection is ADDED to the existing `utilities-and-phase-steps` roster in `spec/workflow-spec.md`, regenerated into `docs/workflows/utilities-and-phase-steps.md` (Check 27 green) — NOT a new roster section.
- [ ] Part C: `docs/tests/test-hierarchy.md`'s full-happy-path-E2E layer reads "local-only, real run via the seam, emits a materialized report (deterministic vs claude-print)."
- [ ] CI-green: `validate.sh` 0 errors; `test.sh` green (the e2e-local family SKIPs).

## Todos

<!-- Actionable items for this story. -->

- [x] Write `scripts/e2e-local.sh` (pre-flight gate + sandbox + real run + boundary assertion + report + teardown). shellcheck-clean.
- [x] Write `tests/e2e-local/lib/sandbox.sh` (clone + marker + bare origin + teardown).
- [x] Write `tests/e2e-local/lib/report.sh` (materialized report generator: md + json, DETERMINISTIC vs claude-print, grep-backed rows).
- [x] Write `tests/e2e-local/CJ_goal_task/happy-build/topic.txt` (the tiny non-sensitive non-doc topic + boundary expectation) + the seed `fixtures/scratch.txt`.
- [x] Write `tests/e2e-local/reports/EXAMPLE.md` (committed sample; faithful to the generator) + `.gitignore` posture (ignore `reports/` except `!EXAMPLE.md`).
- [x] Write `tests/e2e-local.test.sh` (deterministic smoke, 7/7 green) + wire a `units:` row (`spec/test-spec-custom.md`) + a `scripts/test.sh` runner block + regenerate the test catalog.
- [x] Part C: extend `spec/workflow-spec.md` `utilities-and-phase-steps` roster + `workflow-spec.sh --render-docs`.
- [x] Part C: update `docs/tests/test-hierarchy.md` full-happy-path-E2E layer.
- [x] Add a `CLAUDE.md` scripts-reference row for `scripts/e2e-local.sh`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-30: Created. Part B + Part C of F000071 — the local-E2E harness + its materialized report + the workflow-docs discoverability entry + the test-hierarchy update. Builds ON Part A (S000120, the seam this harness drives).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/e2e-local.sh` (new)
- `tests/e2e-local/lib/sandbox.sh` (new)
- `tests/e2e-local/lib/report.sh` (new)
- `tests/e2e-local/CJ_goal_task/happy-build/topic.txt` (new)
- `tests/e2e-local/reports/EXAMPLE.md` (new, committed sample)
- `tests/e2e-local.test.sh` (new)
- `.gitignore` (modified — ignore `tests/e2e-local/reports/` except `!EXAMPLE.md`)
- `scripts/test.sh` (modified — e2e-local family runner block)
- `spec/workflow-spec.md` (modified — `### scripts/e2e-local.sh` roster subsection)
- `docs/workflows/utilities-and-phase-steps.md` (modified — regenerated; Check 27)
- `docs/tests/test-hierarchy.md` (modified — real-run layer update; hand-authored)
- `spec/test-spec-custom.md` (modified — `units:` row for `tests/e2e-local.test.sh`)
- `docs/test-catalog.md` + `docs/tests/<family>.md` (modified — regenerated; Check 26)
- `CLAUDE.md` (modified — scripts-reference row for `scripts/e2e-local.sh`)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The real-run proof is LOCAL-only and manual (gstack + key + gh + budget); CI proves only the deterministic half (the SKIP path, the sandbox lib, and the report generator on synthetic evidence). This is honest, not a shortcut — the CI 4-blocker + AUQ wall make an automated real E2E impossible today.
- The report's rows must be GREP-BACKED (verified against the actual sandbox state) — a hand-assigned pass template proves nothing. Only rows whose evidence is found are "verified."
- Part C MUST extend the existing `utilities-and-phase-steps` roster body — a NEW roster section would orphan an undeclared `docs/workflows/*.md` (Check 15a ERROR) and break the "six docs/workflows" header prose.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Scope = Part B + Part C of F000071. Summary: the local-E2E harness + materialized report (Part B) and the workflow-docs entry + test-hierarchy update (Part C). Builds on Part A (S000120, the seam). One PR.
- [decision] The real-run happy path is a LOCAL manual E2E, not a CI gate. Summary: the CI 4-blocker (gstack absent, read-only eval tools, budget, AUQs) + the AUQ wall make an automated real E2E impossible; the deterministic half (SKIP path + sandbox lib + report generator) is the CI-green smoke, and the real run is the local E2E rows.
- [decision] Workflow-docs placement = extend the existing `utilities-and-phase-steps` roster body, NOT a new roster section. Summary: a new section orphans an undeclared `docs/workflows/*.md` (Check 15a) and breaks the "six docs/workflows" header prose.
- 2026-06-30 [impl] Wrote 6 files (`scripts/e2e-local.sh`, `tests/e2e-local/lib/{sandbox,report}.sh`, `tests/e2e-local/CJ_goal_task/happy-build/topic.txt`, `tests/e2e-local/fixtures/scratch.txt`, `tests/e2e-local/reports/EXAMPLE.md`, `tests/e2e-local.test.sh`); modified 8 (`.gitignore`, `scripts/test.sh`, `spec/workflow-spec.md`, `docs/workflows/utilities-and-phase-steps.md`, `docs/tests/test-hierarchy.md`, `spec/test-spec-custom.md`, `docs/test-catalog.md` + `docs/tests/test.md` regenerated, `CLAUDE.md`). `scripts/e2e-local.sh` shellcheck-clean (the CI-gated `scripts/*.sh` target).
- 2026-06-30 [impl-finding] The reverse test-coverage sweep globs `tests/*.test.sh` NON-recursively, so only the top-level `tests/e2e-local.test.sh` needs a `units:` row; the `tests/e2e-local/lib/*.sh` libs (subdir, not `.test.sh`) do not. CI shellchecks only `scripts/*.sh` + skills-deploy/update-check, so `scripts/e2e-local.sh` is the shellcheck-critical file (kept clean); the libs are cleaned anyway.
- 2026-06-30 [qa-smoke] S1 (AC-1): green — `bash tests/e2e-local.test.sh` C1/C2: `scripts/e2e-local.sh` SKIPs (exit 0) with the flag unset AND with the flag set but a prerequisite missing (never reaches claude). Part of the ALL-PASS run.
- 2026-06-30 [qa-smoke] S2 (AC-2): green — C3/C4: `lib/sandbox.sh` provisions a clone + `.cj-e2e-sandbox` marker + a LOCAL bare origin (origin repointed, no GitHub remote) and teardown removes the mktemp base.
- 2026-06-30 [qa-smoke] S3 (AC-3, AC-4): green — C5/C6: `lib/report.sh` renders DETERMINISTIC-vs-claude-print rows + a legend + a `.json` sibling; green evidence → all pass, MISSING evidence → `unverified` rows + INCONCLUSIVE result (never a false pass). EXAMPLE.md verified byte-faithful to the generator.
- 2026-06-30 [qa-smoke] S4 (AC-6): green — `bash scripts/validate.sh` Check 27 (workflow-docs freshness) PASS after the `### scripts/e2e-local.sh` roster entry + `--render-docs`.
- 2026-06-30 [qa-smoke] S5 (AC-8): green — `bash scripts/validate.sh` 0 errors / 0 warnings (Checks 24/26/27/28/29 all pass); `bash scripts/test.sh` RESULT: PASS, Failures: 0 (the e2e-local block green; the whole suite green).
- 2026-06-30 [qa-smoke-summary] green: 5/5 non-manual rows green.
- 2026-06-30 [qa-e2e] E1/E2/E3 (AC-1/AC-4/AC-3): DEFERRED — LOCAL-only manual E2E (needs gstack + ANTHROPIC_API_KEY + gh + budget). The real `/CJ_goal_task` sandbox run is not runnable in this CI-like context; its deterministic half is proven by S1-S3 and the boundary logic is unit-tested via the report generator's derive-from-evidence path.
- 2026-06-30 [qa-e2e-summary] deferred (0 rows run; 3 rows LOCAL-manual): the honest CI-provable surface (SKIP path, sandbox lib, report generator, doc freshness) is green; the real model run is the documented local E2E.
- 2026-06-30 [qa-pass] S000121 (user-story): green smoke (5/5) + E2E deferred-to-local. Phase 2 gates transitioned.
