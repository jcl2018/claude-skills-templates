---
type: test-spec
parent: S000103
feature: F000061
title: "--check-on-disk Stage-1 engine + three-stage restructure of both audit skills + fresh-context dispatch + per-stage reports — Test Specification"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier; multi-AC cells carry
     the 10 P0s across the 10 rows. NO new test suites — both smoke suites
     below are EXTENSIONS of already-registered files (design constraint). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | doc-spec overlay suite — extended `--check-on-disk` battery | Clean fixture ⇒ all 6 check lines PASS + `CHECKS_RUN=6` + `FINDINGS=0` + exit 0; seven seeded violations (missing declared doc, orphan in docs/, orphan in spec/ incl. a non-self-declaring overlay, undeclared root *.md, work-item ID in a human-doc, missing front table, view-table drift) each flip EXACTLY their own `FINDING: stage1/<id>` + exit 1; registry-absent ⇒ `REGISTRY=absent` + exit 0 (probe before parse gates); invalid registry ⇒ `[doc-sync-no-config]` + exit 1; env overrides keep the drills hermetic | `bash tests/doc-spec-overlay.test.sh` |
| S2 | core | AC-4, AC-7, AC-8 | cj-audit-skills suite — per-stage report shape | Report carries `STAGE1_FINDINGS=`/`STAGE2_FINDINGS=`/`STAGE3_FINDINGS=` + the three `--- stage N ---` section delimiters + `stage1/` prefixes on seeded-violation findings; `FINDINGS` == stage sum; `DOC_AUDIT: ok` only when all three counts are 0; skipped-stage grammar (header + `skipped: <reason>` + `STAGE*_FINDINGS=0`) on the registry-invalid path; Stage-2 grammar tokens (`satisfies`, `missing-requirement (soft`, `n/a`, `FINDING: stage2/`) present and `up-to-date`/`stale:` absent; symmetric `TEST_AUDIT:` shape with `UNITS_AUDITED=` | `bash tests/cj-audit-skills.test.sh` |
| S3 | resilience | AC-5 | Planted-drift stage3 drill | A temp fixture repo whose workflow doc omits a catalog skill produces `FINDING: stage3/...` NAMING the missing skill, after a ground-truth enumeration line — the drift-hunting stage is demonstrably alive, not vacuous | `bash tests/cj-audit-skills.test.sh` (drill case) |
| S4 | core | AC-3, AC-6 | Structural greps on the skill surfaces | `skills/CJ_doc_audit/SKILL.md` Stage 1 is ONE `--check-on-disk` engine call with zero executor-authored conformance loops; BOTH skills' `allowed-tools` frontmatter AND their `skills-catalog.json` `depends.tools` carry `Agent`; both SKILL.mds document the standalone-dispatch / in-QA-inline dual posture | `grep -c 'check-on-disk' skills/CJ_doc_audit/SKILL.md; grep -A8 'allowed-tools' skills/CJ_doc_audit/SKILL.md skills/CJ_test_audit/SKILL.md \| grep Agent; jq '.[] \| select(.name=="CJ_doc_audit" or .name=="CJ_test_audit") \| .depends.tools' skills-catalog.json` |
| S5 | integration | AC-9, AC-10 | Full validate + test + zero-pipeline-edit proof | `validate.sh` green with validate.sh itself untouched (D11) — Check 24 green against the two suites' updated purpose text in `spec/test-spec-custom.md` (anchors unchanged); `test.sh` green with NO new runner blocks; `git diff --name-only` for the story shows zero edits to the four pipeline files; qa.md's AUDIT_FINDINGS template carries the `STAGE*_FINDINGS=` trio | `./scripts/validate.sh && ./scripts/test.sh && git diff --name-only main... -- skills/CJ_goal_feature/pipeline.md skills/cj_goal_defect/pipeline.md skills/CJ_goal_task/pipeline.md skills/CJ_goal_todo_fix/SKILL.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3, AC-4, AC-6, AC-7 | The dogfood re-run — `/CJ_doc_audit` standalone on the workbench | Invoke `/CJ_doc_audit` from a top-level session; watch the transcript: Stage 1 executes as a single engine call printed verbatim; ONE fresh-context subagent is dispatched for Stages 2+3; read the returned verdict lines and the final report | Stage-1 section is the `--check-on-disk` output verbatim (no agent-authored loops); the subagent prompt carries only repo root + engine path + Stage-1 report + protocols; every Stage-2 verdict quotes a clause + cites evidence (spot-check 3 docs); Stage 3 opens with the ground-truth enumeration line; report shows `STAGE1/2/3_FINDINGS=` + three sections; `DOC_AUDIT: ok` iff all counts 0 | PASS if all four observations hold and the run is green (or findings are honest and named); FAIL on any executor-authored Stage-1 loop, evidence-free verdict, missing dispatch, or flat report |
| E2 | core | AC-8 | Symmetric `/CJ_test_audit` standalone (optionally same dispatch as E1) | Invoke `/CJ_test_audit` (in the same session as E1 to exercise the shared single-dispatch option); inspect Stage 2's rule + unit verdicts and Stage 3's surface enumeration | Stage 1 = existing engine calls with `stage1/` prefixes; Stage 2 quotes each rule's `statement` with cited evidence (suite-green names the freshest run; new-code-tested names the diff-vs-units comparison) and judges unit `purpose`/`label` truthfulness; Stage 3 enumerates live surfaces and judges coverage-in-substance; report carries `TEST_AUDIT:` + `UNITS_AUDITED=` + the per-stage trio | PASS if the shape is symmetric with E1 and verdicts are evidence-cited; FAIL if the test audit keeps the flat F000060 report or judges without citations |
| E3 | resilience | AC-5 | Planted one-line drift (the Assignment drill, pre-land) | In a scratch worktree, remove one skill mention from `docs/workflow.md`; run `/CJ_doc_audit` there; restore | Stage 3 emits `FINDING: stage3/docs/workflow.md — <delta naming the missing skill>`; `STAGE3_FINDINGS=1`; `DOC_AUDIT: findings`; Stages 1+2 unaffected | PASS if the finding names the exact missing skill; FAIL if Stage 3 reports no-drift or names the wrong delta |
| E4 | usability | AC-9 | This run's own QA checkpoint shows the per-stage block | Let this story's own cj_goal run reach QA; observe Step 8.6c/d execute the audits INLINE (nested-subagent wall); read the checkpoint AUQ digest | The AUDIT_FINDINGS block carries each audit's `STAGE*_FINDINGS=` trio + three stage sections; the checkpoint AUQ prints it verbatim; `git diff` confirms zero edits to the four pipeline files | PASS if the per-stage shape arrives at the checkpoint with no pipeline change; FAIL if the block is flat or any pipeline needed an edit |
| E5 | observability | AC-10 | Docs sweep + self-application green | Read `docs/architecture.md` ~L285–296; read both catalog entries + USAGE.mds; scan TODOS.md; run `./scripts/validate.sh && ./scripts/test.sh`; let this run's own registered-doc audit (Step 8.6d self-application) judge the swept docs | The "future `--check-on-disk` … deferred" passage now describes the SHIPPED subcommand; both descriptions + `doc_requirement` strings name the three-stage contract; USAGE.mds current (no Check-14 override needed); the validate.sh-convergence TODOS row exists; both suites green; the self-application flags no swept doc stale | PASS if everything green and zero stale flags on the feature's own surfaces; FAIL if the architecture passage survives un-rewritten or any swept doc flags |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Run-to-run stability of Stage 2/3 agent verdicts | Inherently non-deterministic; deliberately layered ABOVE the deterministic Stage-1 floor; the evidence-citation protocol makes them spot-checkable, not reproducible | A flaky judged verdict can noise a checkpoint digest; the engine findings beneath it stay stable |
| Fresh-context dispatch inside QA | Structurally impossible — a QA subagent cannot spawn subagents (the nested-subagent wall); in-QA Stages 2+3 run inline by design and the degradation is documented, not hidden | In-QA verdicts carry more resident context than standalone ones; the standalone dogfood (E1) is the fresh-context proof |
| Consumer-repo engine resolution via `~/.claude/_cj-shared/scripts/` post-land | Requires merge + `post-land-sync.sh` install; structurally post-ship (the parent's Assignment + milestone 2) | A consumer-only resolution bug surfaces at the post-land assignment, not before; temp-repo drills with env overrides are the proxy |
| `/CJ_goal_todo_fix --quiet` auto-continue/halt reading the per-stage block under a real cron run | The checkpoint wiring is untouched by this story (pipelines: zero edits); exercised only by inspection | A --quiet-path regression would be a pre-existing F000060 behavior, not introduced here |
| Cross-platform (Git Bash copy-mode) behavior of the new engine loops | Covered only by the generic windows-smoke job, not a dedicated drill | POSIX+LF idioms followed by construction; a Windows-only break surfaces in the windows-latest CI gate |
