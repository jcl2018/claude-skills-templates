---
name: "setup.sh bootstrap never installs the post-merge auto-sync hook (D000013 wiring gap)"
type: defect
id: "D000021"
status: active
created: "2026-05-15"
updated: "2026-05-15"
repo: "jcl2018/claude-skills-templates"
branch: "claude/stoic-swartz-eb489a"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/setup_sh_missing_hook_wiring`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/CJ_personal-workflow/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/CJ_personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (setup.sh's final `exec skills-deploy install` never invokes the separate setup-hooks.sh; post-merge auto-sync hook from D000013 stays uninstalled on the documented bootstrap path)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-stoic-swartz-eb489a-design-20260515-231745.md`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

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

1. On a throwaway machine, `git clone https://github.com/jcl2018/claude-skills-templates.git /tmp/cst-test`.
2. Run only the documented first-time bootstrap: `/tmp/cst-test/scripts/setup.sh`.
3. **Pre-fix observation:** `ls -l /tmp/cst-test/.git/hooks/post-merge` → file is **absent**. `setup.sh`'s final line is `exec "$CLONE_DIR/scripts/skills-deploy" install` (setup.sh:33); hook installation lives in a *separate* script (`scripts/setup-hooks.sh`) documented in CLAUDE.md only as a manual "Once per clone" step. The D000013 post-merge auto-resync — the entire reason "git pull keeps my skills current" is true — is silently inert until the user happens to run a second script by hand.
4. **Post-fix expectation:** after `scripts/setup.sh`, `.git/hooks/post-merge` is present and executable; manual `setup-hooks.sh` is no longer required for the documented bootstrap path.

**Environment:** workbench at current `main` (D000013 closed; post-merge hook exists in `setup-hooks.sh` but is only installed by that separate script). `setup.sh` runs under `set -euo pipefail` (setup.sh:12); `setup-hooks.sh` can `exit 1` on `HOOK_DIR` resolution failure (setup-hooks.sh:18–21).

## Todos

**In scope (this PR — exactly two one-line changes):**

- [x] `scripts/setup.sh` — inserted exactly one guarded line immediately *before* setup.sh's final `exec` (now at setup.sh:36, `exec` stays last at setup.sh:39, untouched): `"$CLONE_DIR/scripts/setup-hooks.sh" || echo "WARN: hook install failed (run scripts/setup-hooks.sh manually)" >&2`. The `|| echo ... >&2` guard is **mandatory and load-bearing** — under `set -euo pipefail` a bare call that exits non-zero would abort `setup.sh` before the deploy (a regression of the working install path). A 4-line explanatory comment precedes it (setup.sh:32–35) documenting why the guard is load-bearing.
- [x] `scripts/test.sh` — added ONE `if grep` assertion inside the existing D000013 regression block (after the path-filter guard, before the block's trailing blank line), matching that block's exact `if grep -q ... ; then ok "..." ; else fail_test "..." ; fi` idiom: asserts `grep -q 'setup-hooks.sh' "$REPO_ROOT/scripts/setup.sh"` → `ok` on present / `fail_test` on absent. Source-level static assertion only; no `git init`, no fixture, no `setup.sh` execution. A 4-line comment precedes it explaining the CI-safety rationale.
- [ ] **Required disclosure (MANDATORY, no code change — owned by `/ship`):** the `/ship` CHANGELOG entry and PR body MUST state that `setup.sh` now also installs a commit-blocking `pre-commit` hook (alongside the intended `post-merge` auto-sync hook). `setup.sh` takes its update branch on **every** re-invocation (it is the documented repeated "sync drift" step, not just first-run); `setup-hooks.sh` unconditionally rewrites **both** hooks, so this opts any prior `setup-hooks.sh` holdout into commit-blocking pre-commit validation on their next `setup.sh` run. Conscious distribution decision, not a silent surprise (autoplan Eng+DX SHIP-WITH-DISCLOSURE). [Carried forward to `/ship`; not closeable by /CJ_implement-from-spec.]
- [x] Negative test confirmed: temporarily reverting the setup.sh wiring line (tested against a temp copy — real file never destructively mutated) makes `scripts/test.sh` fail at the new assertion; positive case `ok`s. Confirmed during implementation.

**Out of scope (deliberately NOT taken — scope settled at autoplan GATE #1):**

- [ ] **`test-deploy.sh` hermetic fixture** — office-hours plan's original location; dual CEO voices (Claude + Codex) flagged it as over-build in the wrong file (`test-deploy.sh` is scoped to `skills-deploy`, not bootstrap wiring). User accepted the challenge 2026-05-15 → use the `test.sh` D000013-block grep instead.
- [ ] **Approach B** (hook install inside `skills-deploy install` + `--no-hooks` opt-out) — biggest blast radius on the central script the post-merge hook itself calls. Not taken.
- [ ] **Approach C** (doctor-only "make the gap loud") — detection ≠ fix; bootstrap stays technically wrong. Not taken.
- [ ] **Direct `git clone` + `skills-deploy install` path (no `setup.sh`)** still misses hooks — accepted limitation for v1; revisit only if that becomes a real second-machine bootstrap route (would reopen Approach B).
- [ ] **Release/tag automation, marketplace publish, GitHub Releases** — explicitly out of scope per held premises (no live external channel).
- [ ] Pre-existing low-severity note: `setup-hooks.sh` can exit 0 with a non-executable hook if `chmod` fails — out of this PR's 2-line scope.

## Log

- 2026-05-15: Created. Opening question was "do we need any deploy workflow for this repo?" — answer is **no** (skill workbench, no runtime). The session surfaced a real verified gap underneath: `scripts/setup.sh` (the documented first-time bootstrap) never installs the git hooks. Hook install lives in a separate `scripts/setup-hooks.sh`, documented only as a manual step. So on a fresh machine the D000013 post-merge auto-resync is silently inert until the user runs a second script by hand — the mechanism that keeps you synced is not bootstrapped by the thing that sets you up. Codex's cold read independently named "bootstrap/install integrity" as the most-likely failure mode, which promoted it from "likely" to "the finding." autoplan: APPROVED (SHIP-WITH-DISCLOSURE) — 2 one-liners + a mandatory CHANGELOG/PR disclosure of the pre-commit install delta. Scope held: no new deploy/release workflow.

## PRs

## Files

- `scripts/setup.sh` — **modified**: one guarded line inserted immediately before the final `exec` (now setup.sh:36; `exec` stays last at setup.sh:39): `"$CLONE_DIR/scripts/setup-hooks.sh" || echo "WARN: hook install failed (run scripts/setup-hooks.sh manually)" >&2`, preceded by a 4-line explanatory comment (setup.sh:32–35). `CLONE_DIR` is resolved at setup.sh:14–21 before the insertion point, so the line is correct in both documented invocation modes (run-from-inside-repo and clone-to-`~/.claude/skills-templates`). Net +5 lines (1 logic + 4 comment + 1 blank).
- `scripts/test.sh` — **modified**: one `if grep` assertion added inside the existing D000013 regression block (after the path-filter guard at the former line ~750, before the block's trailing blank line), matching the adjacent guard idiom; asserts `setup.sh` references `setup-hooks.sh`. Preceded by a 4-line CI-safety-rationale comment. No fixture, no network, no `setup.sh` execution.
- `.git/hooks/post-merge` + `.git/hooks/pre-commit` — **not modified by this PR**; installed per-machine when `setup.sh` now calls the already-existing `setup-hooks.sh` (untracked files). The pre-commit-install behavior delta MUST be disclosed in CHANGELOG/PR (owned by `/ship`).

## Insights

<!-- The payoff is the inversion: the question was "should we *add* deploy machinery?" and the finding is "your *existing* auto-deploy machinery has a silent off-switch at install time." The fix is ~2 lines plus one test, not a pipeline. The repo's own RETIRED TODOS (skill-lifecycle CI, downstream validate.sh) already encode the right instinct — don't build deploy infrastructure for a workbench — and this design stays inside that instinct, closing the one real seam. Sibling defect: D000013 (work-items/defects/ops/skills-deploy/D000013_skills_deploy_auto_sync_hook) added the post-merge hook to setup-hooks.sh; D000021 is its bootstrap-wiring follow-up — same hook, the setup.sh wiring gap. Disclosure subtlety (autoplan Eng+DX, file:line-confirmed): setup-hooks.sh rewrites BOTH hooks including a pre-commit that runs validate.sh and blocks the commit on failure, and setup.sh takes its update branch on every re-invocation — so wiring setup-hooks.sh into setup.sh opts prior holdouts into commit-blocking pre-commit on their next sync. SHIP-WITH-DISCLOSURE, not a code change. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15 — Scope settled at autoplan GATE #1 (User Challenge accepted by user): drop the office-hours plan's `test-deploy.sh` hermetic fixture; instead add one `if grep` assertion inside the existing D000013 block in `scripts/test.sh`. Rationale: dual CEO voices (Claude subagent + Codex, independently) flagged the fixture as over-build in the wrong file — `test-deploy.sh` is scoped to `skills-deploy`, a bespoke `git init` fixture is the exact "infra for a hypothetical audience" anti-pattern the repo's RETIRED TODOs reject. Net change: 2 one-liners.
- [decision] 2026-05-15 — Add pre-commit behavior-delta disclosure to the `/ship` CHANGELOG entry + PR body (Mechanical auto-decision, P1 completeness + P5 explicit). Both autoplan Eng voices (Claude + Codex) file:line-confirmed a real user-visible delta: `setup.sh` reruns + `setup-hooks.sh` unconditional rewrite ⇒ prior holdouts get commit-blocking pre-commit on next sync. Disclosure clearly-right, no code change. Verdict SHIP-WITH-DISCLOSURE.
- [finding] 2026-05-15 — Premises 1–4 confirmed (no new deploy workflow; "deploy" = local sync that already exists; the real surface is release+distribution not deploy; bootstrap gap is real and verified — `setup.sh` confirmed to not reference hooks at all). Codex's premise-3 marketplace-line attack noted but down-weighted: the live risk is internal (own mechanism not bootstrapped), not unpublished external consumers.
- 2026-05-16 [impl-decision] Placed the `setup-hooks.sh` call immediately before the final `exec` (setup.sh:36) with a 4-line explanatory comment (setup.sh:32–35). `exec` remains the last line (setup.sh:39), unchanged — preserves the documented best-effort install-then-deploy ordering. Kept the `|| echo "WARN: hook install failed (run scripts/setup-hooks.sh manually)" >&2` guard verbatim per RCA Fix Description: load-bearing under `set -euo pipefail` (a bare call exiting non-zero would abort the deploy). No reimplementation of `setup-hooks.sh` — it is already idempotent + worktree-safe (reuse, per Constraints).
- 2026-05-16 [impl-decision] Placed the new `test.sh` assertion after the third existing D000013 guard (post-merge path-filter), before the block's trailing blank line, exactly matching the adjacent `if grep -q ... ; then ok "..." ; else fail_test "..." ; fi` idiom. Used `grep -q 'setup-hooks.sh' "$REPO_ROOT/scripts/setup.sh"` (source-level static assertion). No `git init`, no fixture, no `setup.sh` execution — same CI-safety rationale the existing D000013 block documents (avoids touching `.git/hooks/` / network in CI). Scope settled at autoplan GATE #1 (test-deploy.sh fixture explicitly NOT taken).
- 2026-05-16 [impl-finding] Negative test verified during implementation against a `mktemp` copy of `setup.sh` with the wiring line stripped (the real file was never destructively mutated): the new assertion correctly emits `fail_test` when the wiring is absent and `ok` when present. Satisfies the design's "negative test confirmed" Success Criterion without risking the working tree.
- 2026-05-16 [impl-finding] The mandatory pre-commit-install disclosure (CHANGELOG + PR body) is NOT closeable by /CJ_implement-from-spec — it is a `/ship`-owned, no-code-change requirement. Captured in TRACKER Todos (left `[ ]`, annotated "carried forward to /ship"), RCA Fix Description, and a [decision] journal entry so it cannot be lost between phases. SHIP-WITH-DISCLOSURE per autoplan Eng+DX.
- 2026-05-16 [impl] Modified 2 files: `scripts/setup.sh` (+5 lines: 1 guarded call + 4-line comment + 1 blank), `scripts/test.sh` (+~10 lines: 1 `if grep` assertion + 4-line comment). Strictly the two one-line logic changes from the approved design's Recommended Approach; no scope expansion (no test-deploy.sh, no skills-deploy change, no doctor, no release/deploy pipeline). Both files retain their executable bit (Edit preserves mode; no new files written).
- 2026-05-16 [impl-auto] Pipeline-dispatched auto-equivalent run (orchestrator pre-collected the two sensitive-surface AUQs — validator `scripts/test.sh` + git-hook via `scripts/setup.sh` — both auto-approved with surfacing, logged to the decision log for /ship review). No interactive AUQ reachable in this dispatch context per the pipeline Step 5.3 contract.
- 2026-05-16 [impl-pass] D000021: implementation complete. Phase 2 implementer-owned gates transitioned (RCA doc updated + Todos section reflects remaining work → [x]; Fix committed left for /ship). Boundary check at end clean.
- 2026-05-16 [qa-finding] Pipeline-dispatched QA. qa.md Step 2 normally refuses defect QA when the user/`/ship`-owned `Fix committed` gate is unchecked; in the pipeline sequence (implement → QA → /ship) the commit lands at /ship DOWNSTREAM of this QA, so the gate is expectedly `[ ]` here. Proceeded with smoke verification (the substantive QA the pipeline's Step 7 expects a SMOKE verdict from); commit gate satisfied later by /ship. Structural boundary check at start: PASS (no [MISSING]/[DRIFT]).
- 2026-05-16 [qa-smoke] R1 (positive: test.sh asserts setup.sh wires setup-hooks.sh): green — `./scripts/test.sh` emits `OK: setup.sh bootstrap invokes setup-hooks.sh (post-merge hook auto-installed on fresh clone)` inside the D000013 block (after the 3 existing post-merge/skills-deploy/path-filter guards, before the block's trailing blank line).
- 2026-05-16 [qa-smoke] R2 (negative: revert wiring → test fails): green — verified during implementation against a mktemp copy of setup.sh with the wiring line stripped: the new assertion correctly emits `fail_test "setup.sh does not invoke setup-hooks.sh ..."` (test.sh would go RED); positive case `ok`s. Real working tree never destructively mutated.
- 2026-05-16 [qa-smoke] R6 (scope held — no out-of-scope diff): green — `git diff --stat` shows ONLY `scripts/setup.sh` (+6) and `scripts/test.sh` (+10). Zero changes to test-deploy.sh / skills-deploy / VERSION / skills-catalog.json / doctor / release pipeline. Scope ceiling held exactly per the approved design.
- 2026-05-16 [qa-smoke-manual] R3 (manual acceptance — fresh clone): pending human verification — `git clone <repo> /tmp/cst-test && /tmp/cst-test/scripts/setup.sh` then `ls -l /tmp/cst-test/.git/hooks/post-merge` (must be present + executable). Network-dependent throwaway-clone demonstration; not auto-runnable in QA.
- 2026-05-16 [qa-smoke-manual] R4 (set -euo pipefail regression guard): pending human verification — simulate `setup-hooks.sh` exiting non-zero; confirm `setup.sh` prints the `WARN: hook install failed` line on stderr but STILL reaches the final `exec skills-deploy install` (no `set -e` abort). Static reasoning confirms the `|| echo ... >&2` guard neutralizes `set -e` (RCA Regression Risk row); full runtime check is manual.
- 2026-05-16 [qa-smoke] R5 (validate.sh + test.sh overall green): green-for-D000021 — `./scripts/validate.sh` exits 0 (Errors: 0, Warnings: 0, RESULT: PASS); `./scripts/test.sh` D000021-relevant assertions all `OK`. The single `test.sh` non-zero exit is `test-deploy.sh` Test 8 ("Doctor did not report healthy"), a PRE-EXISTING environmental version-skew (deployed `~/.claude/.skills-templates.json` manifest at 4.6.0 vs repo VERSION 4.5.4 tripping the `Health: OK` doctor assertion). PROVEN unrelated to D000021: `git stash`'d the 2-line change → `test-deploy.sh` fails IDENTICALLY on the pristine tree (same `FAIL: Doctor did not report healthy`, `1 test(s) failed`). D000021's `git diff --stat` does not touch test-deploy.sh/skills-deploy/VERSION/catalog. Out of D000021's 2-line scope; not a regression introduced by this fix.
- 2026-05-16 [qa-smoke-summary] green: 4/4 D000021-relevant non-manual rows green (R1, R2, R5-for-D000021, R6); 2 manual rows pending (R3 fresh-clone, R4 set-e guard). The new D000021 regression assertion passes; negative test confirmed; scope held. `test.sh`'s aggregate non-zero exit is solely a pre-existing, D000021-independent `test-deploy.sh` version-skew failure (proven via pristine-tree stash repro) and is out of this defect's 2-line scope.
- 2026-05-16 [qa-pass] D000021 (defect): green smoke from test-plan rows (4 automated rows green: R1 positive assertion, R2 negative test, R5 validate.sh+test.sh-for-D000021, R6 scope-held; 2 manual rows R3/R4 pending human run — network/runtime, recorded as [qa-smoke-manual]). No qa-owned Phase 2 gates per defect template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. Pre-existing test-deploy.sh Test 8 version-skew failure (4.6.0 deployed vs 4.5.4 repo VERSION) proven unrelated to D000021 via pristine-tree stash repro — out of this 2-line defect's scope, not a regression. MANDATORY carry-forward to /ship: CHANGELOG entry + PR body MUST disclose that setup.sh now also installs the commit-blocking pre-commit hook (SHIP-WITH-DISCLOSURE; see TRACKER Todos + RCA + [decision] journal).
- 2026-05-16 [auto-final-gate-suppressed] 1 mechanical, 0 taste, 2 user-challenge-approved; decisions at ~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260515-235255-86260). /CJ_personal-pipeline ran with --suppress-final-gate (wrapper-invoked by /CJ_goal_run); Step 8.5 AUQ skipped per the suppression contract. The 2 user-challenge-approved decisions are the sensitive-surface auto-approvals — validator `scripts/test.sh` (change 2: one if-grep assertion in the D000013 block) and git-hook surface via `scripts/setup.sh` (change 1: guarded setup-hooks.sh wiring). Both auto-picked "approve" forward; the wrapper consumes the decision log and surfaces them at /ship diff review. End state: green.
