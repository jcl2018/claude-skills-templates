---
type: test-spec
parent: S000056
feature: F000026
title: "v1.0 full-handoff one-liner-to-deployed skill — Test Specification"
version: 1
status: Draft
date: 2026-05-19
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. The TEST-SPEC soft cap is 5 rows per tier; this
     story exceeds the cap deliberately — the design requires 10 deterministic
     + lint tests plus 1 classifier spot-check as a single load-bearing safety
     contract, and each row maps directly to a SPEC story. The exceeded rows
     are advisory [INFO] not violations. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Tests 1–11 live in scripts/test.sh; the helper unit tests feed crafted
     `git diff` fixtures to scripts/cj-handoff-gate.sh. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | security | AC-9, AC-10, AC-12 | Denylisted-path change → helper exits non-zero | A diff touching `skills/CJ_goal_run/SKILL.md` (or any denylisted glob) MUST NOT auto-merge | `scripts/test.sh` test 1 (fixture: minimal diff touching one denylisted path; expect non-zero exit) |
| S2 | security | AC-9 | Size cap → helper exits non-zero | >120 added lines OR >5 files MUST NOT auto-merge | `scripts/test.sh` test 2 (fixture: 121-line diff, single file; AND second fixture: 6 files, 10 lines each) |
| S3 | security | AC-12 | Rename of denylisted file → helper exits non-zero | A rename of `skills/CJ_personal-workflow/SKILL.md` → `skills/foo.md` MUST trip the denylist (via `--no-renames` surfacing the delete) | `scripts/test.sh` test 3 (fixture: rename of denylisted file to non-denylisted path) |
| S4 | security | AC-12 | New/changed symlink → helper exits non-zero | Any new symlink (mode 120000) anywhere MUST NOT auto-merge | `scripts/test.sh` test 4 (fixture: diff introducing a symlink) |
| S5 | security | AC-10 | Test-surface weakening → helper exits non-zero | A ≤120-line diff that weakens an assertion under `tests/**` OR `scripts/*test*.sh` MUST trip the denylist | `scripts/test.sh` test 5 (fixture: tests/foo.test.sh assertion change, no other denylist hit) |
| S6 | resilience | AC-11 | Base-ref drift regression → helper computes against frozen merge-base | If origin/main advances mid-run, the helper's computed counts are unchanged from the pinned BASE | `scripts/test.sh` test 6 (fixture: simulate origin/main advance via local-branch rebase scenarios; assert exit code + counts stable) |
| S7 | core | AC-9 | QA predicate → helper exits non-zero on any failed Phase-2 marker | `PIPELINE_END_STATE≠green` OR any `SMOKE/E2E/PHASE2_GATES` not pass MUST NOT auto-merge | `scripts/test.sh` test 7 (fixture: stub Phase-2 marker outputs; iterate each failure mode) |
| S8 | core | AC-19 | GATE #1 untouched: `--handoff` never suppresses autoplan's final-approval AUQ | Lint check: no code path in `auto.md` or `run.md` answers the autoplan final gate | `scripts/test.sh` test 8 (`grep -L`-style assert over `skills/CJ_goal_auto/auto.md` + `skills/CJ_goal_run/run.md`: no `auto-approve autoplan` markers) |
| S9 | core | AC-19 | Sentinel co-located with gate call within N lines in `run.md` | Proof-of-support and behavior drift together (Eng F3) | `scripts/test.sh` test 9 (extract sentinel line + gate-invocation line; assert line-distance ≤ N, default 20) |
| S10 | resilience | AC-7 | Stage 1.5 abort path: doc missing `Status: APPROVED` or empty required section → Stage 2 never invoked | The fail-closed gate is enforced by an early-return, not by a downstream check | `scripts/test.sh` test 10 (fixture: synthetic doc missing required section; assert orchestrator returns with abort marker AND no `/CJ_goal_run` invocation logged) |
| S11 | usability | AC-4 | Classifier spot-check: fixed one-liner set → expected verdicts | Bounded sanity check; explicitly NOT a false-negative proof (Eng F4) | `scripts/test.sh` test 11 (fixture: `tests/fixtures/cj_goal_auto/classifier_one_liners.tsv` of (one-liner, expected_verdict) tuples; assert majority match) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section below for
     semantics — applies to E2E rows only; smoke rows do not support post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     The operator drives the feature as a real user. Each row is one
     user-visible scenario. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-13, AC-17, AC-19, AC-20 | Dogfood: one real small idea end-to-end with auto-merge | 1. From `main`, run `/CJ_goal_auto --auto-merge-small-diffs "fix the typo in CJ_system-health's health-score header"`. 2. Observe Stage 0 echoes `mode=auto-merge-small handoff=1 max_files=5 max_lines=120` and creates a worktree. 3. Observe Stage 0.5 returns `small-unambiguous` and appends a line to `~/.gstack/analytics/cj-goal-auto-classifier.jsonl` (orchestrator-owned write — AC-5 verified by `tail -1` of the jsonl after the run). 4. Observe Stage 1 writes the design doc to `~/.gstack/projects/<slug>/`. 5. Observe Stage 1.5 passes. 6. Observe Stage 2 prints Problem Statement + Recommended Approach before the autoplan AUQ. 7. Approve the AUQ. 8. Observe scaffold/impl/qa run autonomously. 9. Observe `/ship` creates the PR. 10. Observe `scripts/cj-handoff-gate.sh` exits 0. 11. Observe `/land-and-deploy --suppress-readiness-gate` merges + deploys. 12. Observe per-run audit receipt written + summary printed. | Deployed change with exactly one human prompt (GATE #1). PR body contains `auto-merged under handoff: ...` + pinned BASE SHA. `~/.gstack/analytics/CJ_goal_auto.jsonl` has a new entry. | PASS if all 12 observable steps happen in order AND the receipt's `gate_result=auto-approved`. FAIL if any step missing/wrong. |
| E2 | usability | AC-16 | `--dry-run` preview is fully read-only | 1. Run `/CJ_goal_auto --dry-run "<idea>"`. 2. Capture all stdout + stderr. 3. Inspect filesystem: NO new files anywhere (especially under `~/.gstack/projects/` and `work-items/`). 4. Inspect git: NO new commits, branches, or worktrees beyond what existed before. | Classifier verdict + reason, would-create paths, sentinel presence, gate caps printed. Zero filesystem writes. | PASS if step 3 + 4 confirm zero writes AND verdict printed. FAIL if any write found. |
| E3 | security | AC-9, AC-10, AC-15 | Auto-merge demotes to human GATE #2 on denylist hit | 1. Run `/CJ_goal_auto --auto-merge-small-diffs "tweak the validate.sh script's INFO line"` (touches `scripts/validate.sh` — denylisted). 2. Observe the run proceeds through Stages 0–2 + scaffold/impl/qa + `/ship`. 3. Observe `scripts/cj-handoff-gate.sh` exits non-zero with the named tripped condition. 4. Observe the structured halt: stop block + `next_action=human-review-gate2` + `resume_cmd=gh pr view <N>` + `pr_url=...`. | The PR is created but NOT merged. Operator can inspect + merge manually. | PASS if halt is structured AND PR exists AND merge did not happen. FAIL if auto-merge proceeded OR halt unstructured. |
| E4 | usability | AC-14 | `--audit` mode prints last N receipts | 1. After E1, E2, E3 have run, run `/CJ_goal_auto --audit` (or `--list-handoffs`). 2. Observe the last 3 entries printed in human-readable form. | Entries include classifier verdict, gate result, PR URL (when present), pinned BASE SHA. | PASS if 3 most-recent entries surface with required fields. FAIL if order wrong / fields missing. |
| E5 post-ship | observability | AC-18 | Every-run retro AUQ fires for first 5 auto-merges | After 5 cumulative `--auto-merge-small-diffs` runs (across E1-style dogfood + 4 more small items shipped post-bootstrap-merge), observe an in-conversation AUQ after each of runs 1–5 listing the auto-merged diff and asking "confirm none needed review." Then observe runs 6–9 do NOT surface an AUQ, and run 10 does. | AUQs fire on runs 1, 2, 3, 4, 5, 10, 15, ... | PASS if cadence matches. FAIL if AUQ fires on wrong runs OR doesn't fire when expected. Tagged `post-ship` because requires the bootstrap PR + at least 5 dogfood ships on main; not verifiable on a pre-merge worktree. |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: none for v1; manual dogfood per design. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Classifier false-negative rate (does the classifier ever return `small-unambiguous` when it should have returned `needs-human-taste` or `too-big`?) | No automated oracle; ground truth requires human judgment per one-liner. Test S11 spot-check is a bounded sanity check, NOT a false-negative proof (Eng F4). | A classifier slip can let a semantically wrong but small change through. Bounded by size cap (≤120 lines, ≤5 files) + denylist (no shipping/test machinery) + every-5th retro AUQ. Detection signal for skill-md changes is "a later skill invocation behaves wrong," not real-time. |
| Concurrent `--auto-merge-small-diffs` runs (Eng F3) | `check-version-queue.sh` is advisory; two runs started seconds apart can both pass preflight and claim the same VERSION slot. | Accepted v1 limitation — single-developer personal tooling. Documented in README + `--dry-run` output. v2 prerequisite (atomic slot reservation) if Approach C scheduled drain lands. |
| Post-deploy detection that an auto-merged change broke a downstream skill | For skill-markdown changes, `/land-and-deploy`'s web canary/health checks are near-vacuous (built for a web app). Detection signal is "a later skill invocation behaves wrong" with no telemetry loop. | Accepted with eyes open (P5). Real mitigation is size cap (small blast radius) + denylist (shipping/test machinery protected) + per-invocation opt-in + audit log. "Revert is one command" but the expensive part is noticing. |
| Cross-machine portability of the workbench-owned generator | v1 is workbench-only (macOS, this repo). No Copilot-bundle / portability surface. | Accepted v1 scope constraint. No portability tests until / unless v2 adds it. |
| GATE #1 auto-approve | Not buildable in v1 — autoplan writes review-log artifacts only on-approval; no stable pre-gate machine-readable verdict at any path. | Cut from v1 by design. v2 prerequisite: autoplan must first emit a stable pre-gate verdict artifact. Documented in DESIGN.md "Not in scope." |
