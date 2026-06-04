---
name: "Post-run worktree-cleanup janitor for the three CJ_goal_* orchestrators"
type: task
id: "T000036"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-230308-47489"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/cj_worktree_cleanup_janitor`
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
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-230308-47489-design-20260603-231237.md`
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

- [x] **Item 1 — New `scripts/cj-worktree-cleanup.sh`** (teardown mirror of `cj-worktree-init.sh`). Interface: `cj-worktree-cleanup.sh [--dry-run] [--caller feature|defect|todo]`.
  - `_ROOT` / `_CURRENT` derive from the **invoking cwd's git context** (NOT the script's own location — the script may resolve from `<manifest .source>/scripts/` while cwd is the target repo, exactly like `cj-worktree-init.sh`):
    - `_ROOT` = main working tree = `dirname "$(git rev-parse --git-common-dir)"` (the common `.git` lives at `<root>/.git`).
    - `_CURRENT` = `git rev-parse --show-toplevel`.
    - If cwd is not a git repo → no-op cleanly: emit `RESULT=skipped` and exit 0.
  - Enumerate `git worktree list --porcelain`; parse `worktree <path>`, `branch refs/heads/<b>`, `locked`. Keep ONLY branches matching `^cj-(feat|def|todo)-`.
  - **Local-state rails** — SKIP (with logged reason) when any holds: (a) path == `_CURRENT`; (b) `locked`; (c) dirty tree (`git -C <path> status --porcelain` non-empty). Deliberately **NO "unpushed commits" rail** — after a squash-merge the upstream tracking branch is deleted, so `git rev-list @{u}..HEAD` errors and a *landed* branch would look "unpushed" forever; the PR-state gate is the sole authority on "landed", and dirty-tree is the only local guard needed.
  - **PR-state gate (decision table)** — run `cj-goal-common.sh --phase pr-check --branch <b>` and branch on BOTH `PR_CHECK` and `PR_STATE` (NOT `PR_STATE` alone). REMOVE only when `PR_CHECK=ok` AND `PR_EXISTS=1` AND `PR_STATE ∈ {MERGED, CLOSED}`. Every other combination SKIPs:
    - `ok` / `1` / MERGED|CLOSED → REMOVE
    - `ok` / `1` / OPEN → SKIP (still in review)
    - `ok` / `0` / (empty) → SKIP (no PR — e.g. in-flight drain sibling not yet pushed)
    - `skipped` / — / — → SKIP (gh offline/unauth, can't prove landed)
  - Confirm the EXACT field names `cj-goal-common.sh --phase pr-check` emits when implementing (reviewer observed `PR_CHECK` / `PR_EXISTS` / `PR_STATE`, with `PR_STATE` populated only when `PR_CHECK=ok`).
  - REMOVE survivors: `git worktree remove "<path>"` (clean trees remove without `--force`). On failure → log warning, continue.
  - `git worktree prune` (clears orphaned-dir metadata — the ~3 untracked dirs).
  - **Root main refresh, guarded:** if `git -C "$_ROOT" status --porcelain` is empty → `git -C "$_ROOT" checkout main` then `git -C "$_ROOT" pull --ff-only`; else skip with a note (never disturb a dirty root). Best-effort; log on failure.
  - Emit structured report: `REMOVED=<n>` + removed paths, `SKIPPED=<n>` + per-path reasons, `PRUNED=<ok|fail>`, `ROOT_REFRESH=<ok|skipped|fail>`, final `RESULT=ok` (best-effort: returns 0 even when removals skipped/failed; only a usage error is non-zero; `RESULT=skipped` when cwd is not a repo). Under `--dry-run`: print `WOULD-REMOVE` / `WOULD-SKIP`, mutate nothing (all read-only).
- [x] **Item 2 — `scripts/cj-goal-common.sh`: add `--phase cleanup`** (feature + defect only). Mirror the existing `--phase worktree` dispatch (which shells to `cj-worktree-init.sh`): resolve repo-local `scripts/cj-worktree-cleanup.sh`, shell out passing `--caller "$MODE"` (`$MODE` is `feature` or `defect` — both already-valid modes; **do NOT introduce `--mode todo`**, which the existing `--mode` validation `case` rejects at usage-check) and forwarding `--dry-run`. Echo `PHASE=cleanup`, pass through the helper's report, emit `PHASE_RESULT=ok` on success/skipped or `PHASE_RESULT=skipped` if the helper is unreachable (NEVER `failed` — cleanup must not give callers a reason to halt). Exit 0 for ok/skipped. Register `cleanup` in the `--phase` validation `case` AND the usage string.
- [x] **Item 3a — feature wiring:** `skills/CJ_goal_feature/pipeline.md` Step 6 (final journal/summary, the PR-stop) — add `cj-goal-common.sh --phase cleanup --mode feature`. The feature run's OWN worktree is never removed (current dir + still-OPEN PR); the sweep clears *other* landed cj-* worktrees and refreshes root main. Step 6's summary gains a one-line "Worktree cleanup: removed N, root main refreshed" note; preserve the existing "your session is still in <worktree>" framing.
- [x] **Item 3b — defect wiring:** `skills/CJ_goal_defect/pipeline.md` immediately AFTER Step 10's `/land-and-deploy --suppress-readiness-gate` — add `cj-goal-common.sh --phase cleanup --mode defect`.
- [x] **Item 3c — todo wiring (single-TODO mode):** todo does NOT route through `cj-goal-common.sh` — wire `cj-worktree-cleanup.sh --caller todo` **directly** (same as todo already calls `cj-worktree-init.sh` directly). Place it at the **agent-layer terminal** described in `skills/CJ_goal_todo_fix/SKILL.md`, AFTER the orchestrator completes `/land-and-deploy` + the TODOS DONE-mark. NOTE: `todo_fix.sh` does NOT itself run `/land-and-deploy` — it emits a handoff block and exits 0; the wrapping orchestrator runs `/ship` → `/land-and-deploy` → DONE-mark. So the cleanup call belongs at that orchestrator terminal (where land+DONE-mark lives), **NOT** inside `todo_fix.sh`'s pre-handoff body (land has not happened yet at that point in the script).
- [x] **Item 3d — todo wiring (drain mode):** `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh`, at the per-iteration in-script terminal (a real post-`/land-and-deploy` dispatch point) — add `cj-worktree-cleanup.sh --caller todo`. Idempotent. An in-flight sibling worktree the NEXT drain iteration just created is protected by the no-PR ⇒ SKIP rail (`PR_EXISTS=0`), so drain (highest-collision path) is safe.
- [x] **Item 4 — Tests: `tests/cj-worktree-cleanup.test.sh`** mirroring `tests/cj-worktree-init.test.sh`, with a fake `git`/`gh` or fixture worktrees. Cases: dry-run mutates nothing; `PR_STATE=MERGED` removed; `PR_STATE=CLOSED` removed; `PR_STATE=OPEN` skipped; `PR_EXISTS=0` skipped; `PR_CHECK=skipped` (gh offline) skipped; current worktree never removed; locked skipped; dirty skipped; non-cj worktree untouched; prune invoked; root-refresh guarded on dirty root; cwd-not-a-repo ⇒ `RESULT=skipped`. **REGISTER the new test in `scripts/test.sh` — discovery is NOT glob-based; every `tests/*.test.sh` has a hand-written runner block, so registration is mandatory.**
- [x] **Item 5a — SKILL.md doc touches (3×):** add the cleanup step to each orchestrator's chain diagram / overview (`skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md`). No new halt-taxonomy entry (cleanup never halts) — instead one line per skill noting "worktree cleanup is best-effort, post-land, never halts the run."
- [x] **Item 5b — CLAUDE.md doc touches:** add `cj-worktree-cleanup.sh` to the "Scripts reference" table AND a short note under the "Worktree cleanup" subsection of the CI/CD merge convention (the automated counterpart to the manual `gh api -X DELETE` remote-branch cleanup already documented there).
- [x] **Item 6 — Final gate:** run `scripts/validate.sh` (must stay green — NO new validate.sh check is added by this work, so the `zzz-test-scaffold` integration fixture needs NO edit; the usual "new check ⇒ test.sh scaffold edit" blind spot does not apply) and `scripts/test.sh` (the new `cj-worktree-cleanup.test.sh` must pass inside it). — validate.sh PASS (0 errors, 0 warnings); test.sh PASS (0 failures); new test registered + fired inside the suite.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-03: Created. Scaffolded by /CJ_scaffold-work-item (within /CJ_goal_feature) from design doc chjiang-cj-feat-20260603-230308-47489-design-20260603-231237.md (Approach A: minimal janitor — new `cj-worktree-cleanup.sh` + `cj-goal-common.sh --phase cleanup` + 3-orchestrator terminal wiring + mirror test + doc touches).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-worktree-cleanup.sh` — NEW. Teardown mirror of `cj-worktree-init.sh`. PR-state-gated sweep of `cj-(feat|def|todo)-*` worktrees + `--dry-run` + `git worktree prune` + guarded root-main refresh. Structured `REMOVED=/SKIPPED=/PRUNED=/ROOT_REFRESH=/RESULT=` report. Best-effort: exit 0 for ok/skipped, non-zero only on usage error.
- `scripts/cj-goal-common.sh` — MODIFIED. Add `--phase cleanup` dispatch (feature + defect only): shells to `scripts/cj-worktree-cleanup.sh --caller "$MODE"`, forwards `--dry-run`, echoes `PHASE=cleanup` + `PHASE_RESULT=ok|skipped` (never `failed`). Register `cleanup` in the `--phase` validation `case` + usage string.
- `skills/CJ_goal_feature/pipeline.md` — MODIFIED. Step 6 (PR-stop terminal): add `cj-goal-common.sh --phase cleanup --mode feature` + a one-line cleanup summary note; preserve the "session still in <worktree>" framing.
- `skills/CJ_goal_defect/pipeline.md` — MODIFIED. After Step 10's `/land-and-deploy --suppress-readiness-gate`: add `cj-goal-common.sh --phase cleanup --mode defect`.
- `skills/CJ_goal_todo_fix/SKILL.md` — MODIFIED. (a) Single-TODO mode: wire `cj-worktree-cleanup.sh --caller todo` directly at the agent-layer terminal AFTER `/land-and-deploy` + DONE-mark. (b) Add the best-effort/post-land/never-halts cleanup-step line to the chain diagram / overview.
- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` — MODIFIED. Drain mode: add `cj-worktree-cleanup.sh --caller todo` at the per-iteration in-script terminal (post-`/land-and-deploy`).
- `skills/CJ_goal_feature/SKILL.md` — MODIFIED. Chain-diagram / overview: add the post-land best-effort cleanup step + the never-halts line.
- `skills/CJ_goal_defect/SKILL.md` — MODIFIED. Chain-diagram / overview: add the post-land best-effort cleanup step + the never-halts line.
- `tests/cj-worktree-cleanup.test.sh` — NEW. Mirrors `tests/cj-worktree-init.test.sh`; fake `git`/`gh` + fixture worktrees; the 13 cases enumerated in Todos Item 4.
- `scripts/test.sh` — MODIFIED. Register a hand-written runner block for `tests/cj-worktree-cleanup.test.sh` (discovery is NOT glob-based).
- `CLAUDE.md` — MODIFIED. (a) "Scripts reference" table: add a `cj-worktree-cleanup.sh` row. (b) "Worktree cleanup" subsection of the CI/CD merge convention: short note on the automated post-land sweep (counterpart to the manual `gh api -X DELETE`).

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

**Source:** `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-230308-47489-design-20260603-231237.md` (Status: APPROVED, Mode: Builder; Approach A — Minimal janitor — CHOSEN).

**Why this exists.** Every `/CJ_goal_feature`, `/CJ_goal_defect`, and `/CJ_goal_todo_fix` run auto-creates a `.claude/worktrees/cj-{feat,def,todo}-{ts}-{pid}/` worktree (F000025/F000027) and never tears it down. The repo had **49 dirs under `.claude/worktrees/`** (46 git-registered, ~3 orphaned). This is the **teardown mirror** of the existing `cj-worktree-init.sh` create step.

**Self-healing janitor model.** Each run sweeps *all* landed cj-* worktrees (not just its own), so a `/CJ_goal_feature` worktree merged by hand later gets swept by the *next* cj_goal run of any kind. The backlog drains itself over normal use — no manual purge needed.

**"Landed" MUST be detected by PR state, never by local ancestry.** This is a squash-merge repo: `git merge-base --is-ancestor <branch> origin/main` is FALSE for squash-merged branches (proven: only 2 of 14 cj-* branches read as ancestors though far more shipped). REMOVE only on `PR_CHECK=ok AND PR_EXISTS=1 AND PR_STATE ∈ {MERGED,CLOSED}` via `cj-goal-common.sh --phase pr-check --branch <b>`. Branch on BOTH `PR_CHECK` and `PR_STATE` — `PR_STATE` is populated only when `PR_CHECK=ok`.

**No "unpushed commits" rail — by design.** After a squash-merge the upstream tracking branch is deleted, so `git rev-list @{u}..HEAD` errors and a *landed* branch would look "unpushed" forever, defeating the janitor. The PR-state gate is the sole authority on "landed"; the dirty-tree rail is the only local guard needed. Unpushed in-flight work is implicitly protected (no push ⇒ no PR ⇒ `PR_EXISTS=0` ⇒ SKIP).

**Three different wiring seams — NOT all via cj-goal-common.sh.** feature + defect reuse the `cj-goal-common.sh` phase-dispatch contract (`PHASE=`/`PHASE_RESULT=`) via `--phase cleanup`; **todo does NOT route through `cj-goal-common.sh`** (it already calls `cj-worktree-init.sh` directly), so todo calls the new `cj-worktree-cleanup.sh` directly — same as its create step. The REAL seams: feature → `pipeline.md` Step 6 (PR-stop); defect → `pipeline.md` after Step 10's land; todo single-mode → the **agent-layer orchestrator terminal** (where `/land-and-deploy`+DONE-mark live, per `CJ_goal_todo_fix/SKILL.md`), NOT inside `todo_fix.sh` (which only emits a handoff + exits 0 before land happens); todo drain → `drain-one-todo.sh` per-iteration terminal.

**`--mode todo` does NOT exist in `cj-goal-common.sh`.** The `--phase cleanup` dispatch passes `--caller "$MODE"` where `$MODE` is `feature` or `defect` only — both already-valid modes. Do NOT introduce `--mode todo`; the existing `--mode` validation `case` rejects it at usage-check. todo handles its own cleanup directly (see above).

**`_ROOT`/`_CURRENT` from the INVOKING cwd, not the script location.** The script may resolve from `<manifest .source>/scripts/` while cwd is the target repo (exactly like `cj-worktree-init.sh`). `_ROOT` = `dirname "$(git rev-parse --git-common-dir)"` (common `.git` lives at `<root>/.git`, verified correct from inside a linked worktree); `_CURRENT` = `git rev-parse --show-toplevel`.

**Never halts the run.** Cleanup is strictly best-effort: a failed removal logs a warning and the run still ends green. It runs only *after* the PR is safely landed (defect/todo) or opened (feature), so it can never endanger shipped work. `cj-goal-common.sh --phase cleanup` emits `PHASE_RESULT=ok` or `skipped` — NEVER `failed`.

**No validate.sh check added; no `zzz-test-scaffold` edit needed.** This work is a script + skill-prose wiring; validate.sh has no `scripts/` orphan check. So the usual "new check ⇒ scripts/test.sh scaffold-fixture edit" blind spot (D000032/F000034/F000035 lesson) does NOT apply here. BUT test discovery in `scripts/test.sh` is NOT glob-based — the new `cj-worktree-cleanup.test.sh` MUST be registered with a hand-written runner block.

**Deferred (NOT in this task):** standalone `/CJ_worktree-cleanup` routable skill (Approach B — manual on-demand sweeps + `--include-conductor` `claude/*` broom); `/schedule` cron janitor (Approach C — rejected, doesn't satisfy "a step *in* the three skills"); a "skip if modified in last N minutes" mtime rail for concurrently-active sibling sessions (deferred refinement). v1 treats CLOSED == MERGED (abandoned ⇒ stale ⇒ removable, gated by the clean-tree rail); revisit if an operator reopens closed PRs.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-230308-47489-design-20260603-231237.md -->

- 2026-06-03 [decision] Scaffolded as a single TASK (not a multi-story feature): the APPROVED design's Implementation plan is one directly-implementable unit (new script + phase + 4 wiring seams + mirror test + doc touches), and /CJ_goal_feature runs exactly one scaffold→implement→qa chain. Component = `ops` (matches F000025/F000027 worktree features + the T000028 cj_goal script task). T-ID T000036 minted as the next free ID (highest actual T-tracker on local AND origin/main = T000035; T000045/T000099 are cross-references in other SPEC bodies, not real work-items; no open PR claims a T-tracker).
- 2026-06-03 [decision] Approach A (Minimal janitor) chosen over B (+standalone /CJ_worktree-cleanup skill — deferred) and C (/schedule cron — rejected: doesn't satisfy "a step *in* the three skills"). Smallest correct diff that reuses the proven `cj-goal-common.sh` phase machinery + `cj-worktree-init.sh`+test pattern; safe blast radius (cj_goal family's own footprint only); `--dry-run` baked in so the first real sweep can't surprise the operator.
- 2026-06-03 [decision] "Landed" = PR state MERGED|CLOSED via `cj-goal-common.sh --phase pr-check`, NOT branch ancestry (squash merges make `--is-ancestor` FALSE for shipped branches). Branch on BOTH `PR_CHECK` and `PR_STATE`. Deliberately NO "unpushed commits" rail (squash-merge deletes the upstream tracking branch → landed branches look unpushed forever); dirty-tree is the only local guard.
- 2026-06-03 [finding] todo's land+DONE-mark seam is NOT in `pipeline.md` (which only documents impl→qa→doc-sync). The cleanup call for single-TODO mode belongs at the agent-layer orchestrator terminal (per `CJ_goal_todo_fix/SKILL.md`), NOT inside `todo_fix.sh` (which emits a handoff + exits 0 before land happens). Drain mode wires into `drain-one-todo.sh`'s per-iteration post-land terminal.
- 2026-06-03 [impl-finding] Confirmed the EXACT field names `cj-goal-common.sh --phase pr-check` emits before coding the decision table (per the work-item's explicit instruction): `PR_CHECK` / `PR_EXISTS` / `PR_NUMBER` / `PR_STATE` (cj-goal-common.sh lines 326-333), with `PR_STATE` populated only on `PR_CHECK=ok`. `gh pr list .state` returns UPPERCASE `MERGED`/`CLOSED`/`OPEN`, so the decision table branches on `MERGED|CLOSED` verbatim. The design's assumed names were correct.
- 2026-06-03 [impl-decision] PR-state gate in `cj-worktree-cleanup.sh` calls the SIBLING `cj-goal-common.sh --phase pr-check --mode feature --branch <b>` (2-level probe: sibling-in-scripts/ first, then manifest `.source`). `--mode feature` is an arbitrary already-valid mode required only to satisfy cj-goal-common.sh's usage check — the pr-check phase is mode-agnostic. This same sibling-resolution is what lets the test fake the PR-state gate deterministically (a fake `cj-goal-common.sh` in a temp scripts/ dir) with zero real `gh`/network dependency.
- 2026-06-03 [impl-decision] `_ROOT` derivation handles a RELATIVE `git-common-dir`: when run from the root itself `git rev-parse --git-common-dir` returns the literal `.git` (not absolute), so the script resolves it to absolute via `cd … && pwd` before `dirname`. From inside a linked worktree it is already absolute. Verified both paths on this machine (root → `.git`; worktree → full path).
- 2026-06-03 [impl-finding] Worktree-list porcelain parsing: `locked` appears as its own line (`locked` or `locked <reason>`); `branch` as `branch refs/heads/<name>`; records are blank-line-separated and the final record may NOT be blank-terminated — so the parser flushes the last record after the read loop. Confirmed against the live 46-worktree workbench (the real `agent-*` worktree carries a `locked claude agent … (pid …)` line).
- 2026-06-03 [impl] Wrote 2 NEW files (`scripts/cj-worktree-cleanup.sh`, `tests/cj-worktree-cleanup.test.sh`, both chmod +x) and modified 8 (`scripts/cj-goal-common.sh` `--phase cleanup` dispatch+usage+validation; `scripts/test.sh` runner block; `skills/CJ_goal_feature/pipeline.md` Step 6.5 + SKILL.md chain; `skills/CJ_goal_defect/pipeline.md` Step 10.5 + SKILL.md chain; `skills/CJ_goal_todo_fix/SKILL.md` agent-layer terminal + chain; `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` release-terminal cleanup; `CLAUDE.md` Scripts-reference row + merge-convention note). All four wiring seams in place; `--mode todo` deliberately NOT introduced.
- 2026-06-03 [impl] Verified: `bash -n` + `shellcheck` clean on all changed scripts; live `--dry-run` against the 46-worktree workbench lists 9 WOULD-REMOVE / 5 WOULD-SKIP (current/dirty/no-pr reasons) and mutates nothing (count 46→46); `tests/cj-worktree-cleanup.test.sh` 13 behavior cases + 4 wiring assertions all PASS standalone AND inside `scripts/test.sh`; `scripts/validate.sh` PASS (0/0); full `scripts/test.sh` PASS (0 failures).
- 2026-06-03 [impl-pass] T000036: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). The `Core changes committed` gate is user/`/ship`-owned and left unchecked (no commit yet; `/CJ_goal_feature` ships via `/ship`).
- 2026-06-03 [qa-smoke] rows 1-13 (behavior): green — all 13 regression cases run as smoke-equivalent via `tests/cj-worktree-cleanup.test.sh` (fake `git`/`gh` rules RULE_MERGED/CLOSED/OPEN/NOPR/OFFLINE + fixture worktrees). Decision-table verified: REMOVE only on PR_CHECK=ok+PR_EXISTS=1+PR_STATE∈{MERGED,CLOSED} (cases 2,3); SKIP on OPEN (4), no-PR (5), gh-offline (6). Skip rails verified: current (7), locked (8), dirty (9), non-cj/`claude/*` never-enumerated (10). PRUNED=ok on real sweep (11); ROOT_REFRESH=skipped on dirty root (12); RESULT=skipped + exit 0 on non-git cwd (13).
- 2026-06-03 [qa-smoke] rows 14-15 (`cj-goal-common.sh --phase cleanup`): green — PHASE_RESULT=ok/skipped never `failed`; `cleanup` registered in `--phase` validation case + usage string; `--mode todo` still rejected at usage-check (cleanup passes `--caller "$MODE"`, never `--mode todo`). Verified via the test file's wiring assertions + live `grep` of cj-goal-common.sh (lines 104, 222-229).
- 2026-06-03 [qa-smoke] rows 16-17 (static-grep wiring): green — all four terminal seams wired (feature → cj-goal-common.sh --phase cleanup --mode feature; defect → --mode defect; todo single + drain → cj-worktree-cleanup.sh --caller todo direct); new test registered in `scripts/test.sh` with a hand-written runner block (lines 1159-1164, discovery is NOT glob-based).
- 2026-06-03 [qa-smoke] live --dry-run (no-mutation, real workbench): green — `./scripts/cj-worktree-cleanup.sh --dry-run --caller feature` listed 9 WOULD-REMOVE / 6 WOULD-SKIP (current + 4×dirty + no-pr), PRUNED=skipped, ROOT_REFRESH=skipped, RESULT=ok, exit 0; `git worktree list | wc -l` 47→47 unchanged (mutated nothing). bash -n clean on both scripts; shellcheck clean on cj-worktree-cleanup.sh.
- 2026-06-03 [qa-smoke-summary] green: 17/17 test-plan rows green (smoke-equivalent via the registered behavior test + live read-only dry-run); 0 manual rows pending. validate.sh PASS (0 errors / 0 warnings); full test.sh PASS (0 failures, includes the cj-worktree-cleanup runner block).
- 2026-06-03 [qa-note] shellcheck on `tests/cj-worktree-cleanup.test.sh` emits one SC2329 *info* (unused `cleanup_all` helper) — info-level only, dead test-fixture code, not a behavior issue; non-blocking. Optional cleanup at /ship.
- 2026-06-03 [qa-pass] T000036 (task): green smoke from test-plan rows (17 rows: 13 behavior + 2 phase-dispatch + 2 wiring, all green via the registered test + live dry-run). No qa-owned Phase 2 gates per task template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. Phase-2 commit gate (`Core changes committed`) left for /ship (code present in working tree; /CJ_goal_feature commits at /ship, after QA).
