---
name: "Add /qa discoverability pointer to /CJ_personal-pipeline final summary"
type: task
id: "T000020"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/epic-williams-a2c0c2"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_qa_pointer_to_pipeline_summary`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed) — N/A, no parent; design doc reviewed
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-epic-williams-a2c0c2-design-20260511-145646.md`
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
     the actual things to build, fix, or investigate.

     Acceptance criteria (from design doc Success Criteria) are folded into the
     verification checklist at the bottom — every "verify ..." todo is a binding
     gate for ship-readiness. -->

Implementation:

- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 9.3 (`### 9.3 Print summary`) — add `/qa` as an unconditional entry inside the existing `Next:` block, on its own line after `/ship`. Preserve the two-space indent + column alignment of the existing `/ship` row. Exact line: `  /qa                                  # if work-item touched a web app — visual / E2E polish`
- [ ] Run `./scripts/check-version-queue.sh` pre-ship to confirm next free VERSION slot (likely v2.0.10)
- [x] Run `./scripts/validate.sh` locally — confirm exits 0 with no new violations
- [x] Run `./scripts/test.sh` locally — confirm full suite still green
- [ ] Bump VERSION + add CHANGELOG entry (handled by `/ship`)

Verification (acceptance criteria from design):

- [x] One-line edit lands in `skills/CJ_personal-pipeline/pipeline.md` Step 9.3 adding `/qa` as an unconditional entry under the existing `Next:` block (conditional phrased in comment: `# if work-item touched a web app — visual / E2E polish`)
- [x] `scripts/validate.sh` passes unchanged (no new tests required)
- [x] `scripts/test.sh` passes unchanged
- [ ] Next `/CJ_personal-pipeline` invocation includes the `/qa` line in its end-of-run `Next:` block (verified post-deploy, on the first real pipeline run)
- [x] No drift to `/CJ_personal-pipeline`'s contract: still web-app-agnostic by default; the line is a discoverability pointer, not a workflow change

Out of scope (per design's Success Criteria, deferred to a follow-up):

- [ ] *(Out of scope — deferred to a follow-up after observing the first real `/CJ_personal-pipeline` run with the new line, see Open Question 2 in design doc)* CLAUDE.md Skill-routing section adds one line for `/qa` as web-app follow-up

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-11: Created. Add /qa discoverability pointer to /CJ_personal-pipeline final summary (Approach B from design doc, APPROVED). One-line edit to `skills/CJ_personal-pipeline/pipeline.md` Step 9.3 to surface /qa as a follow-up at the right moment (post-pipeline, on web-app-shipping work-items) without taking on the costs of full integration (commit-owner conflict, gstack hard dependency, schema change). Scope-creep is text-only; no runtime coupling.
- 2026-05-11: Implemented via `/CJ_implement-from-spec --auto`. One line added to `skills/CJ_personal-pipeline/pipeline.md` line 652 (inside Step 9.3 `Next:` block). `validate.sh` and `test.sh` both PASS. Phase 2 implementer-owned gates transitioned green; commit gate remains user/`/ship`-owned. Ready for `/ship`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

Modified (this implementation pass):

- `skills/CJ_personal-pipeline/pipeline.md` — one line added inside Step 9.3 `Next:` block (line 652: `  /qa                                  # if work-item touched a web app — visual / E2E polish`)

Deferred to `/ship`:

- `VERSION` — bump (handled by `/ship`, likely v2.0.10)
- `CHANGELOG.md` — new entry (handled by `/ship`)
- `skills-catalog.json` — `CJ_personal-pipeline` version bump in catalog entry (handled by `/ship` if skill-version bumping convention applies; otherwise text-only repo-level VERSION bump suffices)

Out of scope (preserved per design constraints):

- No schema changes to TRACKER.md / SPEC.md / TEST-SPEC.md
- No new tests (existing `validate.sh` / `test.sh` continue to gate)
- No CLAUDE.md edits in this PR (deferred per Open Question 2)
- No changes to `/CJ_qa-work-item` contract or commit-ownership semantics

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The "whoa" of this design is the discipline of *not* integrating. The user asked "can I use /qa in /CJ_personal-pipeline?" — the premise check (gstack /qa is web-app-only via headless Chromium; subagents in Claude Code 2.1.91 can't call AskUserQuestion per S000026 spike; /qa runs its own bug-find-fix-and-commit loop; workbench portability requires no hard gstack dependency) collapsed the answer space to a 5-minute documentation edit. Resisting the urge to make it bigger was the right move.
- **/qa and /CJ_qa-work-item have orthogonal contracts.** /qa: autonomous, web-app-only, interactive tier picker (Quick/Standard/Exhaustive), commits its own fixes. /CJ_qa-work-item: contract-driven, verifies TEST-SPEC rows, writes to tracker journal, halt-on-red, no autonomous commits. Combining them produces competing commit owners. Recognizing this orthogonality is what made Approach D non-viable.
- **Workbench-portability constraint is load-bearing.** `skills-deploy install` must continue to work standalone without gstack present. Approach B (text-only doc edit naming /qa) is the cheapest correct answer that respects this — the workbench *names* /qa but doesn't introduce gstack as a runtime dependency.
- The CLAUDE.md routing line is intentionally deferred (Open Question 2 → two-step rollout) to first observe whether the pipeline.md line reads cleanly in real output before adding a second discoverability surface.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-11: [decision] Approach B chosen over A (do nothing), C (TEST-SPEC frontmatter flag + auto-suggestion in /CJ_qa-work-item), D (full pipeline integration). Summary: B captures ~80% of the value at ~5% of the implementation cost. A leaves the only real failure mode (discoverability at the right moment) unaddressed. C adds schema + detection code for marginal gain over B. D violates P2 (subagent-AUQ unreachability), P3 (commit-ownership conflict), P4 (hard gstack dependency on portable workbench) — doesn't survive premise check.
- 2026-05-11: [decision] Unconditional emit, comment phrases the condition. Resolution of Open Question 1: the `/qa` line always appears under `Next:`; the inline comment (`# if work-item touched a web app — visual / E2E polish`) tells the user when it applies. Self-filtering at read time, no heuristic branch logic in pipeline.md. Keeps the change a text-only one-liner.
- 2026-05-11: [decision] CLAUDE.md Skill-routing line deferred to a follow-up (Open Question 2). Two-step rollout: pipeline.md edit → ship → see how it reads → decide on CLAUDE.md. Avoids over-shooting on the first PR.
- 2026-05-11: [impl-decision] Used `Edit` (surgical anchor on the `Next:` + `/ship` line) rather than `Write` — preserves the surrounding fenced-code-block context and guarantees a one-line additive diff (test-plan row 7).
- 2026-05-11: [impl-finding] Column-alignment verified empirically: `/ship` line places `#` at column 40 (7 chars `  /ship` + 32 spaces). New `/qa` line uses 34 spaces after `  /qa` to align `#` at the same column 40. Em-dash (U+2014) used per orchestrator pre-spec + repo convention.
- 2026-05-11: [impl] Modified 1 file (`skills/CJ_personal-pipeline/pipeline.md`, +1/-0). Ran `./scripts/validate.sh` (PASS, 0 errors, 0 warnings) and `./scripts/test.sh` (PASS, 0 failures). Test-plan rows 1, 2, 3, 4, 5, 7, 10 verified locally; rows 6, 8, 9 deferred to Phase 3 post-deploy.
- 2026-05-11: [impl-auto] Auto-mode run; --auto honored (1 file touched, no sensitive surface, no Open Questions live in test-plan/TRACKER).
- 2026-05-11: [impl-pass] T000020: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). Commit gate `Core changes committed` remains user/`/ship`-owned.
- 2026-05-11: [qa-smoke] R1 (line present): green — `grep -n '^  /qa' skills/CJ_personal-pipeline/pipeline.md` returns exactly one match at line 652 with expected content.
- 2026-05-11: [qa-smoke] R2 (/ship unchanged): green — `grep -n '^  /ship'` returns one match at line 651; byte-identical to pre-change.
- 2026-05-11: [qa-smoke] R3 (/qa follows /ship): green — `awk` after `/ship` row prints the `/qa` row directly, no intervening content.
- 2026-05-11: [qa-smoke] R4 (validate.sh): green — exits 0, 0 errors, 0 warnings, RESULT: PASS.
- 2026-05-11: [qa-smoke] R5 (test.sh full suite): green — exits 0, 0 failures, RESULT: PASS (includes test-deploy.sh end-to-end + check-version-queue.sh smoke).
- 2026-05-11: [qa-smoke] R6 (skills-deploy install no gstack dep): deferred-to-post-deploy per orchestrator pre-spec (requires clean clone in /tmp; falls outside this QA phase).
- 2026-05-11: [qa-smoke] R7 (one-line edit, no scope creep): green — `git diff main` shows +1/-0 in pipeline.md; total `+` non-header lines = 1, 0 removed.
- 2026-05-11: [qa-smoke] R8 (next /CJ_personal-pipeline prints new line): deferred-to-post-deploy per orchestrator pre-spec (requires post-merge update-check propagation + real pipeline invocation).
- 2026-05-11: [qa-smoke] R9 (workbench-portability without gstack): deferred-to-post-deploy per orchestrator pre-spec (requires post-deploy machine without gstack installed).
- 2026-05-11: [qa-smoke] R10 (no drift in /CJ_personal-pipeline contract): green — `git diff main -- skills/CJ_personal-pipeline/pipeline.md` shows only the single `/qa` line; no other section, gate, AUQ block, or contract clause modified.
- 2026-05-11: [qa-smoke-summary] green: 7/7 runnable rows green (R1, R2, R3, R4, R5, R7, R10). 3 rows deferred-to-post-deploy (R6, R8, R9) per orchestrator pre-spec — recorded explicitly, not red.
- 2026-05-11: [qa-pass] T000020 (task): green smoke from test-plan rows (7 runnable green, 3 deferred-to-post-deploy). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. E2E phase N/A for task type (v1 per-type dispatch). Commit gate `Core changes committed` remains user/`/ship`-owned (commit not yet made — QA ran on uncommitted working tree per orchestrator direction).
- 2026-05-11: [gate-red] orchestrator Step 7 halt: Phase 3 subagent RESULT line emitted `E2E=ambiguous` per dispatch-prompt over-specification for task type. Tracker is authoritative-green ([qa-pass] + green smoke summary above); halt is a v1 spec edge case for task-type Phase 3 routing. end_state=halted_at_gate. Decision logged at $DECISION_LOG (run_id=20260511-150733-27826).
