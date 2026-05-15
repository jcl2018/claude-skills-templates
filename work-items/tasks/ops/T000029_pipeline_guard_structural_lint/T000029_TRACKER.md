---
name: "T000028 v2 follow-ups — retire original sketches + bulletproof the doc-as-code guard"
type: task
id: "T000029"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/T000029-pipeline-guard-structural-lint"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/T000029-pipeline-guard-structural-lint`
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
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-104017.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
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
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] **Edit A:** Append "Error check 12: pipeline.md Step 6 guard present" to `scripts/validate.sh` AFTER existing "Error check 11" (rules/ deploy health) and BEFORE the "Validation Summary" section. Uses the existing `ERRORS` counter. Greps `skills/CJ_personal-pipeline/pipeline.md` for the literal token `[ -x ./scripts/validate.sh ]`; FAIL increments `ERRORS`; missing pipeline.md emits WARN only.
- [x] **Edit B:** In `TODOS.md`, locate the two v2 entries added in PR #115:
      - `### v2: replace pipeline.md:528 validate.sh call with handoff to /CJ_personal-workflow check on the scaffolded dir (P3, S)`
      - `### v2: ship scripts/validate.sh (or a scaffold-only subset) via skills-deploy install for downstream repos (P3, S)`
      Strike through each heading with `~~ ... ~~` markers AND append a `**RETIRED:**` line per entry referencing T000029 / v3.5.6 with the closer-inspection rationale.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-14: Created. Scaffolded by /CJ_personal-pipeline from design doc chjiang-main-design-20260515-104017.md (Approach F+I: retire two v2 TODOs + ship structural lint in validate.sh).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/validate.sh` — ADD a new "Error check 12: pipeline.md Step 6 guard present" block AFTER existing Error check 11 (rules/ deploy health) and BEFORE the "Validation Summary" section. Greps `skills/CJ_personal-pipeline/pipeline.md` for the literal `[ -x ./scripts/validate.sh ]` guard token; FAIL increments the existing `ERRORS` counter; missing pipeline.md emits WARN only. Workbench-CI executable enforcement of the doc-as-code guard at pipeline.md:528 (the T000028 / Approach D boundary).
- `TODOS.md` — STRIKE through the two PR #115 v2 follow-up headings (`### v2: replace pipeline.md:528 validate.sh call ...` and `### v2: ship scripts/validate.sh ...`) with `~~ ... ~~` markers and APPEND a `**RETIRED:**` line per entry citing T000029 / v3.5.6 + the closer-inspection rationale. Reopen if downstream acquires per-repo catalog/manifest surfaces.

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

**Source:** `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-104017.md` (Approach F+I recommended by autoplan CEO review of Approach G; supersedes the original PR #115 sketches B and E after closer inspection).

**Why retire B and E.** Re-reading `scripts/validate.sh:59-664`, every "Error check N" is a workbench-wide invariant (no per-work-item checks). And `skills/CJ_personal-workflow/check.md` operates on a single work-item dir against templates+manifest. Approach B (handoff to check on the scaffolded dir) replaces a workbench-wide structural lint with a per-work-item structural validator — different scope, not an improvement. Approach E (ship validate.sh downstream) would require downstream to have a `skills-catalog.json`, per-skill templates, and `personal-artifact-manifests.json` — surfaces downstream doesn't have. Neither sketch is wrong; both are based on an optimistic read of what `validate.sh` does. The honest move is to retire them with a reopen clause keyed to a future "downstream acquires per-repo catalog/manifest" trigger.

**Why ship the structural lint anyway.** The Approach D guard at `pipeline.md:528` is prose ("workbench-only — skipped silently when absent or non-executable") and the `[ -x ./scripts/validate.sh ]` token is the load-bearing string the pipeline orchestrator-model reads at runtime. A future skill-author re-flowing Step 6 could trivially delete the parenthetical guard. Approach G (split into 2a/2b sub-step) was the CEO's first instinct but the autoplan CEO subagent correctly flagged it as "mostly aesthetic theater without enforcement." The contract-strict answer is an executable invariant: validate.sh greps pipeline.md for the literal token; CI fails if the token disappears. About 10 lines of bash, lives in the existing Error check N pattern, additive (downstream unaffected — downstream doesn't run validate.sh).

**Trade-off accepted.** Token-grep is brittle: a future intentional change (e.g. switch to `command -v` instead of `[ -x ]`) needs to update validate.sh's check-12 grep too. Two-step ripple. Acceptable because the guard string is normative and stable — the cost of the ripple is much smaller than the cost of silently regressing T000028's portability fix.

**Out-of-scope (deferred to a separate design session).** CEO Finding #5 from PR #115 — "CEO-suggested follow-up TODOs should cite `surface: file:line` before being committed to TODOS.md" — is a process-design question about autoplan/CEO-review skill rules, not T000029's surface. Log a P3/S follow-up TODO; defer.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-104017.md -->

- 2026-05-14T11:05:32Z [orchestrator] /CJ_personal-pipeline Phase 1: scaffolded T000029_pipeline_guard_structural_lint from design doc chjiang-main-design-20260515-104017.md (Approach F+I, branch (d) clean slate).
- 2026-05-14T11:10:00Z [impl-decision] Edit A inserted between Check 11 ("rules/ deploy health" block ending at validate.sh:650) and the Summary block (validate.sh:652). Used the design's literal bash form (raw echo PASS/FAIL + `ERRORS=$((ERRORS + 1))` increment) rather than the local `pass()`/`fail()` helpers — the design block was autoplan-CEO-reviewed verbatim and preserving it keeps the audit trail clean. Both styles update the same `ERRORS` counter, so functionally equivalent.
- 2026-05-14T11:10:00Z [impl-decision] Edit B used the existing TODOS.md `~~heading~~ RETIRED` strikethrough convention (lines 184/187/190/193) instead of inline strikethrough only. Added a per-entry `**RETIRED:**` line below each retired heading with the rationale + reopen clause referencing T000029 / v3.5.6.
- 2026-05-14T11:10:00Z [impl] T000029 (task): Approach F+I implemented. 2 files changed: scripts/validate.sh (Edit A: append Error check 12 between check 11 and Validation Summary, ~17 lines), TODOS.md (Edit B: strike+RETIRED the two v2 entries with rationale). No pipeline.md change per design. Phase 2 implementer-owned gates [Todos / Files] transitioned to [x]; commit gate left to /ship.
- 2026-05-14T11:10:00Z [impl-pass] T000029: implementation complete. Phase 2 implementer-owned gates transitioned. Next: /CJ_qa-work-item.
- 2026-05-14 [qa-smoke] 1 (validate.sh exits 0 on T000029 branch with Check 12 PASS): green — `./scripts/validate.sh` exit 0; output contains `=== Check 12: pipeline.md Step 6 guard present ===` and `PASS: pipeline.md contains the validate.sh presence guard`; Validation Summary shows 0 errors / 0 warnings / RESULT: PASS
- 2026-05-14 [qa-smoke] 2 (Guard-removal regression trips check 12): green — temporarily replaced the literal `[ -x ./scripts/validate.sh ]` token in pipeline.md with `[ -x WIPED_FOR_TEST ]`; ran validate.sh; exit 1; output contains `FAIL: pipeline.md missing '[ -x ./scripts/validate.sh ]' guard token`; ERRORS=1; RESULT: FAIL. Restored token before commit (verified 1 occurrence in pipeline.md post-restore).
- 2026-05-14 [qa-smoke] 3 (Validation Summary clean with check 12 added): green — re-ran validate.sh on T000029 branch; Summary shows Errors=0, Warnings=0, RESULT: PASS — additive check did not regress the other 11 checks.
- 2026-05-14 [qa-smoke-summary] green: 3/3 smoke rows green (all automated; no manual_pending rows).
- 2026-05-14 [qa-pass] T000029 (task): green smoke from test-plan rows (3/3 automated green). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-14T11:15:00Z [auto-final-gate-suppressed] 1 mechanical, 0 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
