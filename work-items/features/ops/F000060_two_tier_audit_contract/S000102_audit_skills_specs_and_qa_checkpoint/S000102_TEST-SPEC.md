---
type: test-spec
parent: S000102
feature: F000060
title: "Audit skills + two-tier spec files + QA checkpoint + test-pipeline demolition — Test Specification"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier; multi-AC cells carry
     the 11 P0s across the 10 rows. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | doc-spec overlay suite | Merge semantics (overlay present/absent), duplicate-path ⇒ validate error, merged list subcommands, seed == general-file BYTE identity, --render custom from the overlay | `bash tests/doc-spec-overlay.test.sh` |
| S2 | core | AC-3, AC-4 | test-spec parser suite | Merged schema validate, invalid ⇒ `[test-spec-no-config]` halt, absent ⇒ `REGISTRY=absent` exit 0, seed emission, forward/reverse/floor coverage drills in temp-dir fixtures (ported from the old suite), units-gated floor note on a rules-only registry | `bash tests/test-spec.test.sh` |
| S3 | core | AC-5, AC-6 | audit-skills engine suite | In a bare temp repo: first run seed-delivers `spec/` + both files (`seeded: yes`), second run idempotent (`seeded: no`), seeded violations produce findings, clean workbench run green (FINDINGS=0) | `bash tests/cj-audit-skills.test.sh` |
| S4 | resilience | AC-4, AC-9 | Coverage-parity drift drills | Deleting a unit row for an existing test (forward orphan) or adding an unregistered `tests/*.test.sh` (reverse, the silent-skip catch) flips Check 24 / `--check-coverage` red in a temp fixture — the ported checks are demonstrably alive | `bash tests/test-spec.test.sh` (drill cases) |
| S5 | integration | AC-7, AC-9, AC-11 | Full validate + QA fixtures | `validate.sh` green end-to-end: swapped Check 24 (HARD, skip-when-absent) + `test-spec.sh --validate` + Check 23 without the test-pipeline branch + Check 22 covering the `[qa-audit-declined]` markers + Check 15b orchestrator sections; QA fixture asserts Step 8.6 emits the extended RESULT + AUDIT_FINDINGS block; new suites registered in test.sh + enumerated as `units:` rows | `./scripts/validate.sh && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-5, AC-6 | Standalone audit verbs in a foreign repo | `mkdir /tmp/e2e && cd /tmp/e2e && git init`; invoke `/CJ_doc_audit`, then `/CJ_test_audit`; invoke BOTH a second time | First runs create `spec/doc-spec.md` / `spec/test-spec.md` from the seeds, report `seeded: yes` + a non-crashing verdict each; second runs report `seeded: no` (no re-seed, no false hard-halt) | PASS if both seeds land byte-equal to `--seed` output and second runs are idempotent; FAIL on crash, re-seed, or false hard-halt |
| E2 | usability | AC-7, AC-8 | The feature ships through its own gate (success criterion 6) | Let this feature's own cj_goal run reach QA; observe Step 8.6a–d execute (spec updates first, audits after); observe the run pause at the post-QA checkpoint | QA RESULT carries `AUDITS=doc:…,test:…,spec_updates:…` + the fenced AUDIT_FINDINGS block; the orchestrator surfaces the checkpoint AUQ with the four step outcomes BEFORE doc-sync; Continue proceeds; (verify gate-spec qa-audit row + `halted_at_qa_audit` taxonomy present in all four pipelines by inspection) | PASS if the run pauses with the findings digest and the operator decides; FAIL if QA flips red on findings or the run reaches doc-sync without prompting |
| E3 | core | AC-9 | Demolition completeness sweep | `ls` the four retired paths; `git grep -n "test-pipeline"` across the tree; run `./scripts/validate.sh` and read Check 24's banner | All four files gone; grep hits ONLY in CHANGELOG.md, work-items/ history, and TODOS.md (struck row 12 + the new deferred rows); Check 24 banner names test-spec and runs `test-spec.sh --check-coverage` green on the migrated registry | PASS if zero out-of-policy grep hits and Check 24 green; FAIL on any live reference (CLAUDE.md scripts table, architecture.md, document-release, generate-readme.sh heredoc, test.sh) |
| E4 | integration | AC-10 | Both seed-delivery paths converge | In a temp consumer repo (no catalog), trigger `/CJ_document-release`'s self-bootstrap; diff its seeded `spec/doc-spec.md` against a `/CJ_doc_audit`-seeded copy; delete `spec/test-spec.md`, let document-release stub-scaffold the declared row; inspect a stubbed front_table doc | Identical doc-spec file at the identical spec/-path from both paths; the test-spec stub is `test-spec.sh --seed` output (validates clean, `/CJ_test_audit` does not hard-halt); the front_table stub opens with a summary table | PASS if diff is empty and both stubs pass their checks; FAIL if paths differ (root vs spec/) or a stub hard-halts an audit |
| E5 | observability | AC-1, AC-2, AC-3, AC-11 | Workbench green + self-application | Run `./scripts/validate.sh` + `./scripts/test.sh`; run `/CJ_doc_audit` + `/CJ_test_audit` in the workbench; inspect the four orchestrators' SKILL.md/catalog wording, routing lines, workflow.md/philosophy.md entries, README | Both suites green; both audits FINDINGS=0 — including the registered-doc audit NOT flagging the orchestrators (wording sweep landed); portability audit FINDINGS=0; the two routing lines present; README regenerated | PASS if everything green with zero findings on the feature's own surfaces; FAIL if Step 8.6d self-application flags any orchestrator stale |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The post-land Assignment (running both skills in the real portfolio consumer repo via `_cj-shared` engine resolution) | Requires merge + `post-land-sync.sh` install; structurally post-ship | A consumer-only resolution bug surfaces at the assignment, not before; E1/E4 in temp repos are the proxy |
| `/CJ_goal_todo_fix --quiet` auto-continue/halt at the checkpoint under a real cron run | Exercised only by inspection/fixture, not a live scheduled drain | A --quiet-path regression surfaces on the next scheduled drain; the marker + taxonomy are Check-22-covered |
| Run-to-run stability of agent-judged verdicts (doc `requirement:` alignment, rules `suite-green`/`new-code-tested`) | Inherently non-deterministic; deliberately layered ABOVE the deterministic floor (D6) | A flaky agent verdict can noise a checkpoint digest; the deterministic findings beneath it stay stable |
| Cross-platform (Git Bash copy-mode) behavior of the new shell | Covered only by the generic windows-smoke job, not a dedicated drill | POSIX+LF + date_to_epoch idioms are followed by construction; a Windows-only break surfaces in the windows-latest CI gate |
