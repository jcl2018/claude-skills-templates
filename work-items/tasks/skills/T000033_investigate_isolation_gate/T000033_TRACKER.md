---
name: "Isolation gate before /CJ_goal_investigate subagent dispatch"
type: task
id: "T000033"
status: active
created: "2026-05-19"
updated: "2026-05-19"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/unruffled-chaplygin-3af3c7"
blocked_by: ""
---

<!-- Scaffolded from /office-hours design doc:
     /Users/chjiang/Documents/projects/claude-skills-templates/.gstack/chjiang-claude-sad-aryabhata-82fbaf-design-20260519-082921.md
     Design context distilled into ## Insights below. No separate DESIGN.md per the
     skip-design-for-small-todos convention — this is a single-deliverable hardening
     task (one helper mode + one pipeline.md gate + tests). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed — N/A, standalone task scaffolded from design doc)
- [x] Working branch created (`branch` field populated — claude/unruffled-chaplygin-3af3c7)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
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

- [x] Add `--assert-isolated` verdict mode to `scripts/cj-worktree-init.sh`: single self-contained read-only ordered-ladder block inserted AFTER the `emit_json` definition (`:84`) and BEFORE the Step 1 `--no-worktree` block (`:86`), gated by `if [ "$ASSERT_ISOLATED" = "1" ]` and `exit`ing unconditionally. Must be after `:84` so `emit_json` is defined (else exit 127 under `set -euo pipefail`). No separate guard on `:88-91` (unreachable on this path).
- [x] Verdict ladder (first match wins, mirrors helper's existing detection order): (1) not a git repo → `not_a_repo`/≠0; (2) dirty tree → `dirty`/≠0 (checked BEFORE `--no-worktree` and branch rules); (3) in a linked worktree → `isolated`/0; (4) `--no-worktree` + clean → `isolated`/0 (override recorded in `note`); (5) non-main/master branch + clean → `isolated`/0; (6) main/master primary checkout OR detached HEAD on primary → `not_isolated`/≠0.
- [x] Reuse the existing `emit_json` helper (`:75-84`); mirror the exact `2>/dev/null` guards the existing dirty check uses (`:129`) to stay `set -euo pipefail`-safe (`:28`).
- [x] Add a helper-block comment stating the ladder deliberately has NO `--quiet` rule (a `--quiet`→`isolated` rule would reopen Problem-Statement gap #3 for `/CJ_goal_run` + `/CJ_goal_todo_fix`).
- [x] Extend `tests/cj-worktree-init.test.sh` with the 8 verdict cases: (a) in worktree → `isolated`/0; (b) clean main, no worktree → `not_isolated`/≠0; (c) dirty on a feature branch → `dirty`/≠0; (d) clean feature branch → `isolated`/0; (e1) `--no-worktree` + clean → `isolated`/0; (e2) `--no-worktree` + dirty → `dirty`/≠0; (f) not a repo → `not_a_repo`/≠0; (g) detached HEAD on primary checkout → `not_isolated`/≠0.
- [x] Add the Step 5 isolation gate to `skills/CJ_goal_investigate/pipeline.md` (first ```bash``` block of `## Step 5`, as new sub-step `### Step 5.0`, immediately BEFORE the `ROLE:` dispatch-prompt template). [The `ROLE:` template + prose moved to `### Step 5.1`.]
- [x] Step 5 gate: re-resolve the helper path inside the block (shell vars do NOT persist across bash tool calls) via the 2-level probe — (1) `$_REPO_ROOT/scripts/cj-worktree-init.sh` (workbench self-dev), (2) `$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json")/scripts/cj-worktree-init.sh` (deployed manifest); first `-x` wins; both absent → HALT.
- [x] Step 5 gate: exact invocation `"$_HELPER" --caller investigate --assert-isolated`, forwarding ONLY `--no-worktree` if the operator passed it. NEVER forward `--dry-run`/`--quiet`/`--force-create`.
- [x] Step 5 gate: helper-unreachable (after the 2-level probe) → HALT (scoped revision of F000025 Decision #11 at the source-writing-subagent dispatch boundary). [marker `[investigate-not-isolated]`, `end_state=halted_at_investigate_not_isolated`]
- [x] Step 5 gate: first line is a hard idempotency guard `[ "${RESUME_ROW:-1}" = "1" ]` — gate runs iff `RESUME_ROW == 1` (fresh). Defense-in-depth; Rows 2/3/4/5 own Step 4 jumps untouched.
- [x] On non-zero verdict: append a journal entry to `$TRACKER` with marker `[investigate-not-isolated]`, `next_action=`, draft-aware `resume_cmd=` (`/CJ_goal_investigate $DEFECT_ID` for canonical defect; `/CJ_goal_investigate "$DRAFT_FRAGMENT"` when `IS_DRAFT=1`), `raw_output_path=N/A`. Also emit the C7-style plain-English terminal block (`Why it stopped:` / `State preserved:` / `Next:`). `exit 1` → `end_state=halted_at_investigate_not_isolated`.
- [x] Add one `[investigate-not-isolated]` / `halted_at_investigate_not_isolated` row to BOTH halt-taxonomy tables (SKILL.md "Halt-on-Red Taxonomy" + pipeline.md). Did NOT invent a state count or touch any existing inconsistent count strings (Open Q #3). [Also added an Error Handling table row in SKILL.md for operator completeness.]
- [x] Add the pipeline.md-side `grep` regression assertion (placed in `tests/cj-worktree-init.test.sh`): asserts pipeline.md Step 5 contains the `--assert-isolated` gate + helper re-resolution + draft-aware `resume_cmd` (F000025 one-grep idiom, adapted to the multi-line re-resolved-`$_HELPER` shape via 3 fixed-string signals).
- [x] Add a `TODOS.md` follow-up row: wire `--assert-isolated` into `/CJ_goal_run` + `/CJ_goal_todo_fix` dispatch boundaries (deferred — family scope, Open Q #2).
- [x] Ran `./scripts/validate.sh` + `./scripts/test.sh` (both GREEN, 0 failures). `/ship` is the next phase (Phase 3 — user/ship-owned).

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-19: Created. Scaffolded from APPROVED /office-hours design doc — add a read-only `--assert-isolated` verdict mode to the shared `cj-worktree-init.sh` and wire it as an enforced isolation gate before `/CJ_goal_investigate`'s source-writing subagent dispatch.
- 2026-05-19: Implemented via /CJ_implement-from-spec (auto mode, sensitive-surface AUQ pre-approved). 6 files modified (helper verdict mode + Step 5.0 gate + tests + halt-taxonomy + TODOS follow-up). validate.sh + test.sh both GREEN; cj-worktree-init.test.sh 13/13. Awaiting commit (Phase 2 commit gate is user/ship-owned).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-worktree-init.sh` — MODIFIED: new `--assert-isolated` arg + read-only 6-rung verdict ladder inserted after `emit_json` (`:84`), before Step 1 (`:86`); existing 5 mutating states + exit codes byte-unchanged
- `tests/cj-worktree-init.test.sh` — MODIFIED: 8 new `--assert-isolated` verdict cases (a–g) + pipeline.md 3-signal grep regression assertion + header docstring (5-case → 13-case)
- `skills/CJ_goal_investigate/pipeline.md` — MODIFIED: new `### Step 5.0` isolation gate (RESUME_ROW hard guard, 2-level helper re-resolution, helper-unreachable→HALT, draft-aware resume_cmd, C7 terminal block) + `[investigate-not-isolated]` row & note in "Notes on end-state telemetry"; `ROLE:` template relocated to `### Step 5.1`
- `skills/CJ_goal_investigate/SKILL.md` — MODIFIED: `[investigate-not-isolated]` / `halted_at_investigate_not_isolated` row in the Halt-on-Red Taxonomy table + a matching Error Handling table row
- `scripts/test.sh` — MODIFIED: count-string sync only ("5-case"/"all 5 cases pass" → "13-case"/"all 13 cases pass" for the cj-worktree-init.test.sh runner block); the grep regression assertion lives in the test file, not here
- `TODOS.md` — MODIFIED: new active deferred follow-up row "Wire `--assert-isolated` into `/CJ_goal_run` + `/CJ_goal_todo_fix` dispatch boundaries (P3, S)"

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- **The core invariant is "clean + isolated", NOT "a new `git worktree add` happened"** (Premise 3 + Premise 5). A detected Conductor worktree or a clean feature-branch checkout are already safe — testing the property, not the mechanism. This explicitly contradicts the literal original ask ("launch a new worktree"); the user confirmed the reframe.
- **`/investigate` Phase 4 writes the fix directly to source** — there is no separate implement step (SKILL.md:140-144, SKILL.md:281-283; claim text is SKILL.md-only, not in pipeline.md). This is what makes the missing isolation gate dangerous, not hypothetical. D000024 ("drain-one-todo silent in-place scaffold when worktree helper unavailable") was this exact bug class.
- **Three by-design paths reach the Step 5 subagent dispatch with NO isolation:** (1) feature branch — `cj-worktree-init.sh:116-125` returns `skipped`, runs in place; (2) helper unreachable — `SKILL.md:75-76` WARNs and continues (F000025 Decision #11, deliberate); (3) dirty tree on main — halts interactively, but `--quiet` downgrades to `skipped`.
- **Why the shared-helper approach (Approach C) over inline assertion (Approach A):** the helper is shared by all three `CJ_goal_*` orchestrators, so one read-only verdict mode closes the identical silent-in-place class for `/CJ_goal_run` and `/CJ_goal_todo_fix` later with a ~3-line call each. Inline assertion (A) creates a second definition of "isolated" that drifts — the D000024/D000025 dual-source bug class, which F000025's own Decision (its line 127) rejects.
- **The escape hatch is NOT a bypass:** `--no-worktree` verdicts `isolated` ONLY if the tree is also clean (dirty is checked first in the ladder). `--no-worktree` on a dirty `main` is a strictly-easier reopening of Problem-Statement gap #3 than the gaps being closed.
- **Insertion-point trap (highest-risk impl step, per autoplan F2 / Reviewer NEW #2):** the verdict block calls `emit_json` (defined `cj-worktree-init.sh:75-84`), so it MUST be inserted after `:84`. Inserting earlier (e.g. after the `--caller` map at ~:60) calls an undefined function and exits 127 under `set -euo pipefail`. Implementer MUST re-grep `cj-worktree-init.sh` for the `emit_json` end + `--no-worktree` block before inserting — that file may shift before pickup (Reviewer Residual Risk).
- **`$_S` / shell vars do NOT persist across bash tool calls** (only cwd does — see CLAUDE.md). The Step 5 gate must re-resolve the helper path using the *Default-worktree manifest-`source` idiom* (SKILL.md:58-59), NOT the SKILL.md "Path Resolution" idiom (SKILL.md:85-94, which resolves skill assets and contains no `scripts/`).
- **Workbench self-development must not false-halt:** running `/CJ_goal_investigate` inside this repo may have no deployed `$HOME/.claude/.skills-templates.json`, but `scripts/cj-worktree-init.sh` is present repo-local. The Step 5 reachability probe MUST try repo-local FIRST before declaring the helper unreachable.
- **Idempotency guard is the correct shape, not a spurious wrapper:** Rows 2/3/4/5 jumps are orchestrator-model-followed prose, not a bash `case` dispatch. Relying on that prose to keep a resume from reaching the gate would reintroduce the exact model-discipline dependency this design eliminates (Premise 4). The hard `RESUME_ROW` guard makes the gate robust to prose-jump drift instead of inheriting it.
- **Forward-guard for the family:** the ladder deliberately has NO `--quiet` rule. A future implementer must NOT "helpfully" add a `--quiet`→`isolated` rule — it would reopen gap #3 for `/CJ_goal_run` + `/CJ_goal_todo_fix`. State this in the helper block's comment.
- **Behavioral-test limitation (autoplan F1, P3+P5):** pipeline.md gate control-flow (RESUME_ROW≠1 skip; helper-unreachable→HALT) is covered by static `grep` only, not behavioral — markdown-orchestration behavioral testing is not unit-testable; repo convention (F000025) is one-grep-per-SKILL.md. Accepted as a known limitation.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-19 [decision] Approach C (read-only `--assert-isolated` mode on the shared helper) chosen over Approach A (inline git-state assertion in pipeline.md — rejected: second definition of "isolated", D000024/D000025 dual-source class, contradicts F000025 line 127) and Approach B (thread JSON verdict via state file — rejected: `RUN_ID` generated after the SKILL.md block forces a clunky pre-RUN_ID handoff file = new stale/missing-file failure mode). Summary: helper owns both actor and checker; one definition of "isolated", no handoff artifact, no RUN_ID wrinkle, reusable across the CJ_goal_* family. Most consistent with Premises P2 + P3 and F000025's anti-duplication decision.
- 2026-05-19 [decision] `--no-worktree` semantics resolved in design: verdict `isolated` ONLY if the tree is also clean (dirty checked first in the ladder). Summary: preserves the escape hatch (run on a clean checkout without a worktree) without it becoming a one-flag bypass of Problem-Statement gap #3.
- 2026-05-19 [decision] Family scope: ship the helper mode + wire investigate ONLY; defer `/CJ_goal_run` + `/CJ_goal_todo_fix` wiring to a tracked TODOS.md follow-up. Summary: minimal scope — ship the mechanism + one consumer (Open Q #2).
- 2026-05-19 [decision] Halt-count strings deferred: this work adds one row to the two taxonomy tables and explicitly does NOT touch any of the multiple inconsistent count strings already in both files (pipeline.md:4 "9-state"; SKILL.md:122 "9-state"; SKILL.md:3 "13-state"; SKILL.md:217 "10+2"; SKILL.md:243/247 "14 named"/"13-total"). Summary: reconciling them all is pre-existing debt for a separate cleanup (Open Q #3).
- 2026-05-19 [decision] GATE #1 final approval — operator chose "Approve as-is"; continue to Phase 2 (autoplan Eng-scoped audit trail row #3). No User Challenges; architecture/edge-case/security: no findings.
- 2026-05-19 [finding] Reviewer residual risk: round-3 fixes (`:75-84`/`:86` line numbers) are text/line-number corrections verified against code directly, but no 4th independent reviewer re-confirmed the final text (3-dispatch review cap hit). Summary: implementer should sanity-check the three cited insertion line numbers against `scripts/cj-worktree-init.sh` at implementation time, since that file may shift before pickup.
- 2026-05-19 [impl-finding] Verified insertion point against live `scripts/cj-worktree-init.sh` before writing (per the Insight #6 / Reviewer-residual-risk instruction): `emit_json` definition closes at line 84 (`}`), the Step 1 `--no-worktree` block comment is at line 86, and the existing dirty check at line 129 uses the `! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null` guard pair. Inserted the `--assert-isolated` ladder block between line 84 and line 86 as the design specifies — after `emit_json` is defined (no exit-127 under `set -euo pipefail`), before the mutating Step 1-9 path (block `exit`s unconditionally so no guard needed on the later steps). Line numbers matched the design's round-3 corrections exactly; no drift.
- 2026-05-19 [impl-finding] pipeline.md regression-assertion grep idiom adapted: the F000025 one-grep-per-SKILL.md idiom (`grep -qE 'helper\.sh.*--caller X'`) assumes the helper is invoked by its literal path on one line. The Step 5.0 gate invokes via a re-resolved `$_HELPER` var (the manifest-`source` idiom — shell vars do not persist across bash tool calls per CLAUDE.md), so `--assert-isolated` and `scripts/cj-worktree-init.sh` land on different lines. Used three independent fixed-string `grep -qF` signals instead (gate invocation + helper re-resolution + draft-aware `resume_cmd`) — same regression-guard intent, correct for the multi-line re-resolved-var shape.
- 2026-05-19 [impl-decision] Placed the pipeline.md-side grep regression assertion in `tests/cj-worktree-init.test.sh` (the design explicitly allows `scripts/test.sh` OR `tests/cj-worktree-init.test.sh`) to minimize the validator-family surface touched (sensitive-surface AUQ scope). The only `scripts/test.sh` edit was a mechanical doc-string sync of the now-stale "5-case"/"all 5 cases pass" count strings to "13-case"/"all 13 cases pass" — additive/descriptive, keeps test.sh honest about the test it runs, within the pre-approved validator surface.
- 2026-05-19 [impl-decision] Halt-taxonomy rows added additively WITHOUT touching any pre-existing inconsistent count string ("9-state", "13-state", "10+2", "14 named", "13-total" in pipeline.md/SKILL.md) per the locked design decision (Open Q #3 — count reconciliation is separate pre-existing debt). Added one row to SKILL.md's "Halt-on-Red Taxonomy" table, one to SKILL.md's Error Handling table, and a new `[investigate-not-isolated]` row + clarifying note to pipeline.md's "Notes on end-state telemetry" section.
- 2026-05-19 [impl-finding] Sensitive surface: `scripts/test.sh` matched the validator-family pattern (Step 6.4) → `SENSITIVE=true`. `FILES_TOUCHED`=6 (>2) AND sensitive → not trivial; `--auto` would normally demote to `MODE=propose`. The sensitive-surface AUQ was pre-collected by the orchestrator with verdict APPROVE-and-continue (scoped: additive grep regression assertion may go in test.sh OR the test file; `scripts/validate.sh` is run-only — not edited). Proceeded in auto-equivalent mode on the pre-answered approval.
- 2026-05-19 [impl] Wrote 0 new files; modified 6: `scripts/cj-worktree-init.sh` (added `--assert-isolated` arg + read-only 6-rung verdict ladder, byte-unchanged existing 5 mutating states), `tests/cj-worktree-init.test.sh` (8 verdict cases a-g + pipeline.md grep regression assertion + header docstring), `skills/CJ_goal_investigate/pipeline.md` (Step 5.0 isolation gate: RESUME_ROW hard idempotency guard, 2-level helper re-resolution, helper-unreachable→HALT, draft-aware resume_cmd, C7 terminal block + halt-taxonomy note), `skills/CJ_goal_investigate/SKILL.md` (halt-taxonomy + Error Handling rows), `scripts/test.sh` (count-string sync), `TODOS.md` (deferred family-wiring follow-up row). Verification: `./scripts/validate.sh` GREEN (0 err/0 warn), `./scripts/test.sh` GREEN (0 failures), `tests/cj-worktree-init.test.sh` 13/13 pass, F000025 regression guards still pass.
- 2026-05-19 [impl-auto] Auto-mode run; the only blocking AUQ (validator-family sensitive surface) was pre-collected APPROVE by the orchestrator and threaded; no un-pre-answered sensitive-surface or taste-fork encountered.
- 2026-05-19 [impl-pass] T000033: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-05-19 [gate-red] /CJ_personal-pipeline Step 8 post-QA gate: Phase 3 QA REFUSED at its boundary check (`Core changes committed` gate unchecked). STRUCTURAL, not a quality failure — /CJ_implement-from-spec writes files but does not commit; pipeline commits at /ship (Phase 3), after the QA phase. Affects all task-type design-doc pipeline runs. Independent verification PASSED this run: tests/cj-worktree-init.test.sh 0 failures (8 verdict cases a–g + e1/e2 + pipeline.md Step 5.0 grep regression); scripts/validate.sh 0 err/0 warn; HARD insertion-point directive verified against the live file (emit_json closes :89; verdict block placed after it and before the --no-worktree block; gated by ASSERT_ISOLATED; exits unconditionally; runtime --assert-isolated returns valid JSON, no exit-127); scope fence respected (no /CJ_goal_run|/CJ_goal_todo_fix wiring; no halt-state-count-string edits; deferred family-wiring TODO added per design Open Q #2). end_state=halted_at_gate per strict contract; resolution = /ship (commits, runs pre-landing review, operator diff-review gate), after which /CJ_qa-work-item is satisfiable.
- 2026-05-19 [review-finding] /ship Step 9 pre-landing review (independent fresh-context subagent) found P1 (conf 9/10): pipeline.md Step 5.0 read `${NO_WORKTREE:-0}`, a var never set anywhere — the documented `--no-worktree`-on-clean-main escape hatch (SKILL.md:39/:214, pipeline.md next_action) was dead code that false-halted. Two linked defects: (1) pipeline.md Step 1 parser had no `--no-worktree` case so it polluted ARGS and tripped the "exactly one D-ID" guard; (2) Step 5.0 read a shell var that does not persist across bash tool calls — the exact persistence trap the design itself flagged. The 3 adversarial rounds + autoplan Eng all missed it (they reviewed the plan, not the wired pipeline↔helper code). Operator chose "fix properly now (marker-file)".
- 2026-05-19 [fix-decision] Marker-file fix, ENTIRELY in pipeline.md (does NOT touch the sensitive SKILL.md actor block; sidesteps the pre-RUN_ID handoff problem that rejected design Approach B): Step 1 now parses `--no-worktree)`→`NO_WORKTREE=1` and, in the SAME bash fence where NO_WORKTREE + RUN_ID are both live, writes a RUN_ID-scoped marker `$HOME/.gstack/analytics/CJ_goal_investigate-runs/$RUN_ID/.operator-no-worktree`. Step 5.0 re-reads that marker via the model-carried RUN_ID (same persistence pattern as TELEMETRY/RAW_DIR/$TRACKER). Added a 2nd pipeline.md static-grep regression (asserts parse+persist+re-read present AND the dead `${NO_WORKTREE:-0}` conditional absent) + synced the test-file header docstring (singular→two regression assertions). Re-verified: validate.sh 0/0, full test.sh 0 failures, cj-worktree-init.test.sh 13/13 + both pipeline.md regressions pass, F000025 family scope fence re-confirmed intact (no --assert-isolated in goal_run/goal_todo_fix).
