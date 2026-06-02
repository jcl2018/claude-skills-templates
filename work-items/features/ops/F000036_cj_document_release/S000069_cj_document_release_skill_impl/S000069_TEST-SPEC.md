---
type: test-spec
parent: S000069
feature: F000036
title: "CJ_document-release skill + cj_goal orchestrator inline wiring — Test Specification"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2, AC-3, AC-4, AC-5 | Skill files + catalog entry + SKILL-CATALOG.md section all present and well-formed | Stories #1-5 — skill is structurally complete | `bash tests/cj-document-release.test.sh` (asserts: SKILL.md + USAGE.md exist; frontmatter parses; USAGE.md has 5 H2 sections; catalog entry has correct fields; doc/SKILL-CATALOG.md has `### CJ_document-release` section with `(phase-step in /CJ_goal_feature chain)` tag) |
| S2 | core | AC-6, AC-7, AC-8, AC-9, AC-10, AC-11 | All 3 cj_goal orchestrators have Step 5.5 + 2 halt-taxonomy rows in correct positions | Stories #6-11 — orchestrator wiring is symmetric across feature/defect/todo_fix | `bash tests/cj-goal-doc-sync-wiring.test.sh` (asserts: `^### Step 5.5: Doc-sync` in all 3 pipeline.md; `[doc-sync-red]` row in all 3 SKILL.md halt-taxonomy; `[doc-sync-non-doc-write]` row in all 3; row ordering after qa-red, before ship-declined in all 3) |
| S3 | core | AC-12, AC-13, AC-14 | Both new test files wired into test.sh; halt-marker prose present in CJ_document-release SKILL.md | Stories #12-14 — tests fire in suite + skill documents both halt classes | `grep -q 'cj-document-release\.test\.sh' scripts/test.sh && grep -q 'cj-goal-doc-sync-wiring\.test\.sh' scripts/test.sh && grep -q '\[doc-sync-red\]' skills/CJ_document-release/SKILL.md && grep -q '\[doc-sync-non-doc-write\]' skills/CJ_document-release/SKILL.md` |
| S4 | resilience | AC-15, AC-16 | validate.sh + test.sh green on PR HEAD | Stories #15, #16 — no regressions; audit set grows 11→12 with CJ_document-release passing Check 13/14/15 | `./scripts/validate.sh && ./scripts/test.sh` |
| S5 | core | AC-17, AC-18, AC-19 | F000029 BD#1 supersession annotation in-place + VERSION = 6.0.1 + CHANGELOG [6.0.1] entry | Stories #17-19 — ancillary artifacts wired | `grep -q 'SUPERSEDED BY F000036' work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md && grep -q '^5\.0\.20' VERSION && grep -q '^## \[5\.0\.20\]' CHANGELOG.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section below).
-->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-2, AC-3 | Operator reads SKILL.md + USAGE.md and understands the wrapper shape | Open `skills/CJ_document-release/SKILL.md`. Read top-to-bottom. Open `USAGE.md`. Read the 5 sections. | A new operator who hasn't seen F000036 can answer: "What does `/CJ_document-release --docs README` do? When should I use it manually vs let the orchestrator invoke it? What halt classes can it emit?" | PASS if all three questions answered correctly from SKILL.md + USAGE.md alone (no need to read pipeline.md or this TEST-SPEC). FAIL if any answer requires reading other files. |
| E2 | core | AC-6, AC-7, AC-8, AC-9, AC-10, AC-11 | Diff review: 3-way symmetric edits across cj_goal_feature/defect/todo_fix | `git diff main...HEAD -- skills/CJ_goal_{feature,defect,todo_fix}/pipeline.md skills/CJ_goal_{feature,defect,todo_fix}/SKILL.md` | The Step 5.5 subsection is byte-for-byte identical across all 3 pipeline.md modulo `<verb>` in resume_cmd (verb = feature/defect/todo_fix). The halt-taxonomy 2 new rows are byte-for-byte identical across all 3 SKILL.md. | PASS if diff confirms symmetry with only the `<verb>` substitution differing. FAIL if any orchestrator has divergent Step 5.5 content (e.g., different halt-marker shape, different RESULT branch handling) that isn't justified. |
| E3 | resilience | AC-15, AC-16, AC-20 | Walk the full pipeline locally: run validate.sh + test.sh + dry-run /ship | `./scripts/validate.sh; ./scripts/test.sh; gh pr list --state open --base main` | Both scripts exit 0. validate.sh confirms audit set = 12 routable skills, Check 13/14/15 all PASS for CJ_document-release. test.sh confirms both new test files run and PASS. | PASS if validate.sh + test.sh both exit 0 and the output explicitly names CJ_document-release as PASS in Check 13/14/15. FAIL if any check fails or silently skips CJ_document-release. |
| E4 | core post-ship | AC-20 | Live dogfood A: `/CJ_document-release --docs README` from a feature branch with stale README | After this PR merges + next feature branch: `git checkout -b feat-test-docrelease`; touch a code file referenced in README; commit; `/CJ_document-release --docs README`; observe behavior. | Skill runs: (a) branch gate passes (not on main); (b) clean-tree gate passes (only doc files dirty after upstream runs); (c) `/document-release` invoked with `--docs README` context; (d) if README needs updating → auto-commit "docs: post-build sync via CJ_document-release"; (e) success summary printed. If no doc changes needed → green-noop. | PASS if the skill respects the `--docs README` filter best-effort + auto-commits doc-only changes + prints success summary. PASS even if `/document-release` audits other docs too (best-effort filter). FAIL if skill modifies non-doc files OR emits a halt marker without cause OR doesn't print success summary. |
| E5 | core post-ship | AC-20 | Live dogfood B: `/CJ_goal_defect "synthetic doc-drift bug"` end-to-end | After PR merges + a synthetic fixture: `/CJ_goal_defect "modify lib/foo.py docstring referenced in README"`. Watch Step 5.5 fire between QA pass and `/ship`. Read the resulting PR diff. | The PR diff contains BOTH the code fix (lib/foo.py) AND the README update in a SINGLE PR (possibly 2 commits, same branch). The Step 5.5 ran successfully (no halt journal entries). `/CJ_goal_defect` halted at PR per /CJ_goal_feature semantics. | PASS if the PR diff contains both code + doc updates in one PR. PASS even if doc update is a single-line CHANGELOG voice polish (best-effort filter). FAIL if doc updates landed in a separate PR (defeats the F000036 atomicity goal) OR if Step 5.5 halted on green-noop (false-positive halt). |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke + live dogfood post-merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether `/document-release` actually honors the `--docs` filter (filter is best-effort, not enforced) | We don't modify upstream `/document-release`; the project-context block is documentation-only, not programmatic | Mitigation = if upstream audits everything anyway, CJ_document-release still auto-commits whatever's produced. The filter is operator intent + best-effort communication, not gate. Live dogfood E4 + E5 surfaces actual filter behavior. |
| Real cron-mode `/CJ_goal_todo_fix --quiet` interaction with `[doc-sync-red]` halt | Manual smoke required (cron scheduling); not feasible in unit tests | Mitigation = SKILL.md prose explicitly documents the `--quiet` interaction (halt-on-red contracts NOT suppressed by --quiet). Operator inspects halt journal at convenience. |
| What happens when Step 5.5 runs but the working tree was already dirty with non-doc files (orchestrator implementation phase left uncommitted changes) | Pre-Step-5.5 orchestrator phases should commit cleanly; if they don't, the clean-tree gate refusal IS the test | Mitigation = clean-tree gate explicitly refuses; orchestrator HALTs with `[doc-sync-non-doc-write]` (technically `[doc-sync-pre-dirty]` could be a separate class but v1 conflates them under the same gate). |
| Race condition: two parallel cj_goal worktrees both running Step 5.5 | Out of scope for v1; per-worktree Step 5.5 is independent | Mitigation = each Step 5.5 operates on its own branch; no shared state. Cross-worktree coordination is /ship's queue-collision check, not Step 5.5's job. |
| Whether the halt-marker journal entries are machine-readable (telemetry consumers can parse them) | v1 emits the marker shape per parent design Step 6 (next_action / resume_cmd / pr_url / aux fields); JSON shape is not yet schematized | Mitigation = follow F000027's halt-marker shape; analytics layer reads the shape today via line-anchored parse. Schema can be tightened in a follow-up. |
| Whether the new halt classes show up in /CJ_goal_feature's overview-table summary | Out of scope — orchestrator SKILL.md halt-taxonomy table is the canonical home; overview-table is a separate doc generator | Mitigation = if overview table drifts, F000034's Check 15 won't catch it (Check 15 audits SKILL-CATALOG.md, not overview tables). Add a separate check if/when overview-table drift becomes common. |
| Behavior when `/document-release` enters an infinite loop or hangs | Out of scope for v1; Skill tool has its own timeout/budget semantics | Mitigation = if upstream hangs, the orchestrator's Agent budget catches it; CJ_document-release inherits the parent's timeout. No new timeout layer added. |
| The "synthetic doc-drift bug" fixture for E5 doesn't actually exist | E5 is live dogfood post-merge; the fixture is built when the operator runs the test | Mitigation = E5 explicitly says "synthetic fixture"; PASS rubric is best-effort. If no fixture is available, skip E5 and rely on E4. |
