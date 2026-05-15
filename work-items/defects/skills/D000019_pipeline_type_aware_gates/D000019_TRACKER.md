---
name: "Pipeline gate substrate fixes — Step 7 type-aware halt + sensitive-surface regex extend"
type: defect
id: "D000019"
status: active
created: "2026-05-14"
updated: "2026-05-14"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/{slug}`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

Two confirmed substrate bugs in `skills/CJ_personal-pipeline/pipeline.md`:

**Bug 1 (TODOS.md:94 — Step 7 strict halt-on-ambiguous blocks defects and tasks).**
1. Scaffold a `defect` or `task` work-item.
2. Run `/CJ_personal-pipeline` through to Phase 3 (QA).
3. `/CJ_qa-work-item` returns `RESULT: SMOKE=green; E2E=ambiguous; PHASE2_GATES=green` (structural — defect/task QA cannot emit `E2E=green` because the inner E2E subagent only dispatches for user-stories).
4. **Observe:** Step 7 strict halt rule treats `E2E=ambiguous` as `User Challenge — Halt-at-Gate`. Pipeline ends `halted_at_gate`.

Verified repros: D000017 (PR #84) — orchestrator logged a Taste decision treating ambiguous as green (workaround, not fix); T000020 (pipeline run 20260511-150733-27826) — orchestrator halted strictly even though tracker-side `[qa-pass]` and `[qa-smoke-summary] green` were already written.

**Bug 2 (TODOS.md:91 — sensitive-surface regex misses `skills/*/scripts/`).**
1. Scaffold a work-item whose implementation adds a new file under `skills/{name}/scripts/`.
2. Run `/CJ_personal-pipeline` Phase 2 implement subagent.
3. **Observe:** Step 5.1's sensitive-surface pre-scan regex does NOT flag the new script path. The implement subagent ships the new file auto-approved (no user_challenge_approved surfacing at Step 5.2 / Step 8.5).

Verified repro: D000017 (PR #84) — codex adversarial review at /ship Step 11 caught the new `skills/CJ_suggest/scripts/suggest.sh` invocation as a trust-boundary hole. The pipeline should have surfaced it.

## Todos

- [ ] Edit #0: Load `TRACKER` + `WORK_ITEM_TYPE` from tracker frontmatter at consuming bash blocks (Step 4 sub-step 2 trailer; reused at Steps 5.1, 7, 8).
- [ ] Edit #1: Step 7 type-aware halt branch — `if [ "$WORK_ITEM_TYPE" = "defect" ] || [ "$WORK_ITEM_TYPE" = "task" ]` AND `SMOKE=green` AND `PHASE2_GATES=green` AND `E2E=ambiguous`, treat as green silently.
- [ ] Edit #2a: Broaden Step 5.1 regex to match `skills/[^/]+/scripts/[^/]+` (any file under skills scripts/).
- [ ] Edit #2b: Type-aware input selection at Step 5.1 — defects scan RCA + test-plan; tasks scan TRACKER + test-plan; user-stories scan SPEC (current behavior).
- [ ] Edit #3: Step 7 dispatch prompt — documentation only, tighten RETURN CONTRACT to say "for type=defect|task, emit `E2E=ambiguous` (smoke is the verification layer; ambiguous means N/A for this type)". Does NOT rewrite ambiguous as green.
- [ ] Edit #4: Sensitive-Surface Pre-Scan Reference table — add row for `Skill scripts` matching `skills/*/scripts/*` (any file under a skill's scripts/ dir).
- [ ] Regression test execution per test-plan.md (6 grep-on-source rows + 1 behavior-fixture row).

## Log

- 2026-05-14: Created. Bundled D-defect for both pipeline.md gate-substrate bugs (Bug 1: Step 7 strict halt-on-ambiguous blocks defects/tasks; Bug 2: sensitive-surface regex misses skills/*/scripts/). Scaffolded from design doc `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-184452.md` (Status: APPROVED post-/CJ_run autoplan v2, 5 patches applied).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- skills/CJ_personal-pipeline/pipeline.md — 5 surgical edits (Edit #0 prerequisite, Edit #1 Step 7 type-aware branch, Edit #2a Step 5.1 regex broaden, Edit #2b Step 5.1 type-aware input selection, Edit #3 Step 7 dispatch prompt, Edit #4 reference table row).

## Insights

**Shared root cause:** Pipeline gate semantics are not type-aware, and the trust-boundary scan substrate is incomplete. Both bugs trace to the same architectural premise — Step 5.1's pre-scan and Step 7's halt rule were both designed for user-stories (the original primary work-item type) and were never generalized when defect/task types were added in F000012/v1.11.0.

**Why bundled:** Single RCA articulates the shared root cause; one PR; both fixes diff cleanly in one file (`pipeline.md`). Approach A (bundled D-defect) chosen over Approach B (two T-task split) per Phase 4 AUQ on 2026-05-14.

**Deferred reframe:** CEO Theme D ("fix at emission, not consumption") suggested moving the type-check into `/CJ_qa-work-item` so it emits `E2E=green` directly for defect/task. That's an architectural reframe (changes the RESULT contract upstream) and deferred to its own /office-hours; the current fix patches consumption while preserving the qa.md contract.

## Journal

- [decision] 2026-05-14: Bundled D-defect (Approach A) chosen over two T-task split (Approach B). Rationale: shared root cause makes one RCA more honest than two task closures; reversible single-PR fix; both diffs in same file.
- [decision] 2026-05-14: Edit #2 expanded post-autoplan into 2a (regex broaden) + 2b (type-aware input selection). Without 2b, Bug 2's verified failure mode (D000017's path lived in `D000017_test-plan.md`, not SPEC) doesn't trigger the regex at all — input selection must be type-aware.
- [decision] 2026-05-14: Edit #3 reframed post-autoplan. Original wording rewrote `ambiguous`→`green` semantics, violating qa.md line 179 contract. Corrected to preserve `ambiguous` as the canonical N/A-for-type marker; Edit #1 carries the orchestrator-side interpretation.
- [decision] 2026-05-14: Step 7/Step 8 two-source-of-truth architectural reframe deferred (Codex CEO CRITICAL + Codex Eng #4). Current fix preserves both gates; redesign would change Step 8 to sole authority and reduce Step 7 to crash/timeout — bigger scope, separate work-item.
- [finding] 2026-05-14: D000019 test-plan row 7 fixture walkthrough executed. WORK_ITEM_DIR=work-items/defects/skills/D000019_pipeline_type_aware_gates; Edit #0 awk against D000019_TRACKER.md resolved WORK_ITEM_TYPE=defect (literal). Edit #1 branch fires on RESULT shape {SMOKE=green; E2E=ambiguous; PHASE2_GATES=green}. Pipeline continues silently to Step 8 (green path); end_state=green reachable. Test-plan rows 1-6 grep-on-source all returned expected matches against post-fix pipeline.md.
- [qa-smoke-summary] green — 6 grep-on-source rows + 1 behavior-fixture row all pass. scripts/validate.sh exits 0. No structural drift in TRACKER/RCA/test-plan vs templates.
- [qa-pass] D000019 smoke verification complete. Defect-type smoke-only QA per S000021 (qa.md line 643). No live pipeline run required for v1 — inspection-based verification covers the gate-logic surgical edits.
- [auto-final-gate-suppressed] 1 mechanical, 0 taste, 1 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260514-201314-57312). Suppression flag --suppress-final-gate set by wrapper (/CJ_run); wrapper consumes the decision log itself and will surface the user_challenge_approved entry at /ship's diff review.
