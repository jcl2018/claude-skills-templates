---
type: test-plan
parent: T000039
title: "Wire Step 4.6 registered-doc-verdict surfacing into /CJ_goal_defect + /CJ_goal_todo_fix (Job-2.1 parity) — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — the Job-2.1 parity wire-up of the registered-doc verdict
     SURFACING into /CJ_goal_defect + /CJ_goal_todo_fix. The deterministic guarantee
     is surfacing WIRING (T1, T2) — the verdict CONTENT is agent-judged
     (non-deterministic), so the live dogfood (T7) is best-effort, not a gate. -->

## Scope

The change mirrors the proven, shipped `/CJ_goal_feature` Step 4.6 registered-doc verdict
SURFACING (read the gitignored scratch file `.cj-goal-feature/registered-doc-verdicts.md` →
idempotent replace-if-present splice of `### Registered-doc requirements` under the PR body
`## Documentation` → `gh pr edit`; best-effort, NEVER halts) into the other two cj_goal
orchestrators, so all three surface the verdict in front of a reviewer. The shared PRODUCER
(Step 6.7 in the `/CJ_document-release` wrapper) already runs for all three. Files modified:

- `skills/CJ_goal_defect/pipeline.md` — §1: new **Step 9.5** between Step 9 (`/ship`, captures
  `$PR_URL`) and Step 10 (`/land-and-deploy`); mirror of Step 4.6 with `s/$PR_NUMBER/$PR_URL/g`
  (defect has no `$PR_NUMBER`; gh pr view/edit accept a URL).
- `skills/CJ_goal_todo_fix/pipeline.md` — §2: new **Step 5.6** surfacing section (pipeline.md
  currently ENDS at Step 5.5); uses `$PR_URL` from `/ship`'s output; one site covers single-TODO
  + drain.
- `skills/CJ_goal_todo_fix/SKILL.md` — §2: one-line Routing pointer; §5: Overview-chain node.
- `skills/CJ_goal_defect/SKILL.md` — §5: Overview-chain node.
- `skills/CJ_goal_feature/pipeline.md` + `CLAUDE.md` + `doc/ARCHITECTURE.md` + `CHANGELOG.md` —
  §3: the "v1 wires /CJ_goal_feature only" deferral note updated to "all three" in ALL FOUR.
- `doc/WORKFLOWS.md` — §4: Step 4.6 node added to the CJ_goal_defect + CJ_goal_todo_fix charts.
- `skills/CJ_goal_defect/USAGE.md` + `skills/CJ_goal_todo_fix/USAGE.md` — §5: `last-updated` bumped.
- `scripts/test.sh` — §6: two deterministic smoke checks (defect + todo_fix pipeline.md each).

Posture: ADVISORY / best-effort surfacing, NEVER halts; NO new hard validate.sh check;
NO upstream gstack `/document-release` or `/ship` modification (only workbench-owned pipelines + docs).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | §1 + §6 DEFECT surfacing wired in CJ_goal_defect/pipeline.md (DETERMINISTIC — primary proof) | `grep -F 'gh pr edit' skills/CJ_goal_defect/pipeline.md` (the Step 9.5 PR-body edit) AND `grep -F 'registered-doc-verdicts.md' skills/CJ_goal_defect/pipeline.md` (the LITERAL scratch read) AND confirm the block uses `$PR_URL` (not `$PR_NUMBER`) | Both grep hits present; the new Step 9.5 reads the literal `.cj-goal-feature/registered-doc-verdicts.md` and runs `gh pr edit "$PR_URL"`; no `$PR_NUMBER` reference (Review #3) | Pending |
| 2 | §2 + §6 TODO_FIX surfacing wired in CJ_goal_todo_fix/pipeline.md (DETERMINISTIC — primary proof) | `grep -F 'gh pr edit' skills/CJ_goal_todo_fix/pipeline.md` (the Step 5.6 PR-body edit) AND `grep -F 'registered-doc-verdicts.md' skills/CJ_goal_todo_fix/pipeline.md` (the LITERAL scratch read) | Both grep hits present: the new Step 5.6 section reads the literal scratch file and runs `gh pr edit "$PR_URL"`. Together T1+T2 are the two `scripts/test.sh` smoke checks (mirror T000038b) — they prove the surfacing is wired into BOTH remaining orchestrators | Pending |
| 3 | §2 SKILL.md Routing pointer in CJ_goal_todo_fix | Confirm `skills/CJ_goal_todo_fix/SKILL.md` Routing's `/ship` → `/land-and-deploy` sequence names the new Step 5.6 surfacing (so the agent runs it at the right moment — todo_fix's tail is agent-driven, no pipeline-step auto-invoke) | A one-line pointer to Step 5.6 is present in the SKILL.md Routing sequence between `/ship` and `/land-and-deploy` | Pending |
| 4 | §3 deferral notes updated to "all three" in ALL FOUR files (Review #1) | Confirm each of `skills/CJ_goal_feature/pipeline.md` (Step 4.6 prose), `CLAUDE.md` (`### Surfacing`), `doc/ARCHITECTURE.md` (~89 surfacing note), `CHANGELOG.md` (new `[6.0.NN]` entry superseding the [6.0.28] clause) now says the verdict is surfaced by all three orchestrators — NOT "/CJ_goal_feature only". Confirm ARCHITECTURE's SEPARATE requirement-presence-hardening deferral is UNCHANGED | All four updated to "all three"; the new CHANGELOG entry supersedes (does not duplicate) the [6.0.28] deferral clause; ARCHITECTURE's other deferral untouched | Pending |
| 5 | `grep -rn "wires \`/CJ_goal_feature\` only"` returns ZERO in source (the deferral-note completeness gate) | `grep -rn "wires \`/CJ_goal_feature\` only" skills/ doc/ CLAUDE.md CHANGELOG.md` (or repo-wide excluding work-items/) | Zero matches in source — every "v1 wires /CJ_goal_feature only" deferral string is rewritten to "all three" (T000039's own TRACKER/test-plan under work-items/ quote the OLD phrasing as history and are excluded from the source grep) | Pending |
| 6 | §4 doc/WORKFLOWS.md charts show the Step 4.6 node | In `doc/WORKFLOWS.md`, confirm the `### CJ_goal_defect` chart AND the `### CJ_goal_todo_fix` chart each show a `registered-doc verdicts → PR body` (Step 4.6/9.5/5.6) node placed after `/ship`, before `/land-and-deploy` | Both charts carry the surfacing node in the correct position | Pending |
| 7 | §5 SKILL.md Overview charts + USAGE.md bumps (Check 14) | Confirm `skills/CJ_goal_defect/SKILL.md` + `skills/CJ_goal_todo_fix/SKILL.md` Overview chains show the surfacing node; confirm each USAGE.md `last-updated` is bumped past its SKILL.md edit (so Check 14 does not flag USAGE.md stale) | Both Overview chains updated; both USAGE.md `last-updated` advanced | Pending |
| 8 | validate.sh GREEN | `./scripts/validate.sh; echo "exit=$?"` | `exit=0`, RESULT: PASS, 0 errors. Check 14 GREEN for both orchestrators' USAGE.md (bumped past SKILL.md); Check 15/15b GREEN (WORKFLOWS.md charts current); the registered-doc audit docs stay current (no orphan/FAIL) | Pending |
| 9 | test.sh GREEN incl. the two new §6 smoke checks | `./scripts/test.sh; echo "exit=$?"` | `exit=0`, RESULT: PASS, 0 failures. The two new §6 smoke checks (defect pipeline.md + todo_fix pipeline.md each contain `gh pr edit` + `registered-doc-verdicts.md`) pass; the zzz-test-scaffold integration fixture is UNAFFECTED (no validate.sh Check was added) — but explicitly VERIFY per `project_implement_subagent_blind_spot_test_sh` | Pending |
| 10 | Live dogfood — THIS PR's body carries the section, all current (BEST-EFFORT, not a pass/fail gate) | After `/ship` opens the PR, `gh pr view <PR#> --json body -q .body \| grep -F '### Registered-doc requirements'`; confirm the verdict lines (esp. for `doc/ARCHITECTURE.md`) read `up-to-date` / `all current` | The PR body's `## Documentation` section contains a real `### Registered-doc requirements` block; every verdict up-to-date (the §3 deferral-note + §4/§5 chart/SKILL edits keep every registered doc current, esp. ARCHITECTURE.md which must NOT read stale on its own surfacing note). NON-BLOCKING: a failed `gh pr edit` logs a note and does NOT fail the run (the deterministic proof is T1+T2) | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exits 0 (no new ERROR; Check 14 GREEN for both USAGE.md; Check 15/15b GREEN)
- [ ] `./scripts/test.sh` exits 0 (RESULT: PASS; the two new §6 smoke checks green; zzz-test-scaffold fixture unaffected — explicitly verified)
- [ ] T1 + T2 (the two DETERMINISTIC surfacing-wiring grep checks, one per remaining orchestrator) both green — the primary proof the surfacing is wired, not inert
- [ ] `grep -rn "wires \`/CJ_goal_feature\` only"` returns ZERO in source — all four deferral notes rewritten to "all three"
- [ ] LOAD-BEARING confirmed: the scratch path is the LITERAL `.cj-goal-feature/registered-doc-verdicts.md` in all three pipelines (NOT verb-renamed — only `.cj-goal-feature/` is gitignored)
- [ ] Best-effort / never-halt posture confirmed: each surfacing step guards on the PR identifier + scratch presence and logs-and-proceeds on failure; no `[doc-sync-*]` / halt path added
- [ ] No upstream modification: `git diff` touches only workbench-owned files (skills/CJ_goal_defect/, skills/CJ_goal_todo_fix/, skills/CJ_goal_feature/pipeline.md, CLAUDE.md, doc/ARCHITECTURE.md, doc/WORKFLOWS.md, CHANGELOG.md, scripts/test.sh) — no upstream gstack `/document-release` or `/ship` files
- [ ] Best-effort dogfood (T10): THIS PR's body carries a real `### Registered-doc requirements` section, all current (non-blocking)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | branch cj-feat-20260604-112942-86086 | Pending |
