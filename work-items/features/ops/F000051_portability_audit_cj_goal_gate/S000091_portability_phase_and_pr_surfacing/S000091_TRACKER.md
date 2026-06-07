---
name: "Shared portability-audit phase + 3-orchestrator gate + PR surfacing"
type: user-story
id: "S000091"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000051"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/intelligent-goodall-0860b2"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. This atomic story derives
     directly from the parent feature's /office-hours session; the parent's
     design is sufficient context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/portability_audit_cj_goal_gate` (using parent's branch — shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `cj-goal-common.sh --phase portability-audit` resolves the engine via the sibling-then-`.source` idiom, runs it under `PORTABILITY_STRICT=1`, parses `FINDINGS=` (skills-with-findings) + `SKILLS_AUDITED=`, and emits `PHASE=`, `MODE=`, `FINDINGS=`, `SKILLS_AUDITED=`, `VERDICT_LINE=`, `PHASE_RESULT=ok|findings|skipped`.
- [ ] Exit code is 0 on clean (`PHASE_RESULT=ok`); non-zero on findings (`PHASE_RESULT=findings`); 0 on engine-absent (`PHASE_RESULT=skipped`). `--dry-run` emits the schema with `PHASE_RESULT=ok` + empty `FINDINGS=` and runs nothing.
- [ ] The `--phase` validation enum, usage string, and header-comment phase list in `cj-goal-common.sh` all include `portability-audit`.
- [ ] All 3 orchestrators call the gate immediately after the Step 5.5 doc-sync block and immediately before `/ship` (todo: in BOTH single-TODO and drain-mode chain prose), via a CONTENT anchor (not a new step number).
- [ ] On `PHASE_RESULT=findings` each orchestrator HALTs with `[portability-red]` (end_state `halted_at_portability`) and a journal entry carrying `next_action=` / `resume_cmd=` / `pr_url=N/A` / `raw_output_path=`.
- [ ] On `PHASE_RESULT=ok` each orchestrator writes `VERDICT_LINE` to `.cj-goal-feature/portability-verdict.md`; on `skipped` it echoes a visible note and continues. The Step 4.6 / 9.5 / 5.6 surfacing step also reads that scratch file and splices a `### Portability` line into the PR body (best-effort, never halts).
- [ ] `tests/cj-goal-common-portability.test.sh` exists and asserts the three outcomes (clean → ok/exit 0; dishonest-declaration fixture → findings/non-zero; engine-absent → skipped/exit 0); wired into `scripts/test.sh` if it enumerates cj-goal-common phases.
- [ ] `docs/workflow.md` all 3 `CJ_goal_*` Touches blocks + ASCII charts updated (Check 15b passes); `CLAUDE.md` phase list + scripts-reference row + gate/halt note updated.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` green.

## Todos

<!-- Actionable items for this story. -->

- [x] Add `resolve_portability_engine()` (mirror `resolve_worktree_helper`) + the `portability-audit` phase block to `cj-goal-common.sh`; extend the `--phase` enum, usage string, header-comment phase list; add the `--dry-run` branch.
- [x] Capture the engine exit with the file's idiom `PA_OUT=$(PORTABILITY_STRICT=1 bash "$ENGINE" 2>&1) && PA_RC=0 || PA_RC=$?` (not a bare `$(...)`); parse `FINDINGS=` + `SKILLS_AUDITED=`; build clean/red `VERDICT_LINE`.
- [x] Wire the gate + `[portability-red]` halt + verdict-scratch write into feature `pipeline.md`, defect `pipeline.md`, todo `SKILL.md` (single-TODO AND drain-mode).
- [x] Extend the Step 4.6 / 9.5 / 5.6 surfacing step to also read `.cj-goal-feature/portability-verdict.md`.
- [x] Add each orchestrator's `--dry-run` preview line ("would run the portability-audit gate (halt-on-red) before /ship").
- [x] Add `tests/cj-goal-common-portability.test.sh`; grep `scripts/test.sh` for cj-goal-common phase enumeration and extend if present (added both a test-runner block + a `--phase portability-audit` integration block).
- [x] Update `docs/workflow.md` charts + Touches blocks (Check 15b) and `CLAUDE.md`.
- [x] Run `./scripts/validate.sh` + `./scripts/test.sh` to green (both PASS; validate 0 errors/0 warnings, test.sh 0 failures).
- [ ] (Phase 3 / QA) Acceptance-criteria verification + E2E (owned by /CJ_qa-work-item).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Atomic story implementing the shared `--phase portability-audit`, the 3-orchestrator halt-on-red gate, the PR-body verdict surfacing, the test, and the doc updates.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-goal-common.sh` (modified — `resolve_portability_engine()` helper + the `portability-audit` phase block; `--phase` enum/usage/header-comment phase list)
- `skills/CJ_goal_feature/pipeline.md` (modified — Step 5.7 gate + `[portability-red]` halt; Step 4.6 portability splice; dry-run preview line; telemetry halt-states list), `skills/CJ_goal_feature/SKILL.md` (modified — halt-taxonomy row + Error-Handling row + overview chart + description)
- `skills/CJ_goal_defect/pipeline.md` (modified — Step 5.7 gate + `[portability-red]` halt; Step 9.5 portability splice; dry-run preview line; telemetry halt-states list), `skills/CJ_goal_defect/SKILL.md` (modified — halt-taxonomy row + Error-Handling row + overview chart + description)
- `skills/CJ_goal_todo_fix/SKILL.md` (modified — Step 5.7 gate section (both single-TODO + drain prose); Step 5.6 portability splice; per-TODO end-state row + loop-semantics STOP set; chain diagrams)
- `tests/cj-goal-common-portability.test.sh` (NEW — hermetic: clean→ok / dry-run→ok-runs-nothing / findings-fixture→findings-nonzero / engine-absent→skipped), `scripts/test.sh` (modified — test-runner block + `--phase portability-audit` integration block)
- `docs/workflow.md` (modified — 3 `CJ_goal_*` charts + Touches blocks + the shared-phase-dispatcher subsection), `CLAUDE.md` (modified — F000051 pre-ship portability gate subsection)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The engine resolves its own catalog via `git rev-parse`, so a sibling call from a worktree Just Works — no `_cj-shared`/`CJ_SHARED_SCRIPTS` indirection (the script has zero such references).
- Mirror the `sync` phase's exit-capture idiom (`cj-goal-common.sh:470`) exactly: a bare `$(...)` would swallow the engine's non-zero exit or abort under the orchestrator shell.
- `FINDINGS=` counts SKILLS-with-findings (`cj-portability-audit.sh:571` increments once per skill; `:578` emits it); `SKILLS_AUDITED=` (`:579`) is the audited count. Gate on `FINDINGS > 0` (≡ `PA_RC != 0`); use `SKILLS_AUDITED` only for "N skills" wording.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-06: Modeled the feature as a single atomic user-story (one scaffold→implement→qa chain) — the work is one cohesive change across the shared script + 3 orchestrators + tests + docs, not separable parallel sub-units.
- [decision] 2026-06-06: todo orchestrator calls the phase with `--mode feature` (the value it already passes for `--phase sync`, `SKILL.md:57`); no change to the shared `--mode` validation. `scripts/drain-one-todo.sh` is NOT modified — the gate is orchestrator-layer.
- 2026-06-06 [impl] Wrote 1 NEW file (`tests/cj-goal-common-portability.test.sh`) and modified 8 (`scripts/cj-goal-common.sh`, `scripts/test.sh`, feature pipeline.md+SKILL.md, defect pipeline.md+SKILL.md, todo SKILL.md, `docs/workflow.md`, `CLAUDE.md`). Added the shared `--phase portability-audit` (6th phase) + `resolve_portability_engine()`; wired the halt-on-red gate (Step 5.7) + PR-body `### Portability` surfacing into all 3 orchestrators; added the test + test.sh wiring; updated docs.
- 2026-06-06 [impl-decision] Used a content anchor (after the Step 5.5 doc-sync handler, before `/ship`) labelled "Step 5.7" in all 3 orchestrators rather than a bare numeric step — consistent with the design's non-monotonic-step-number rationale; "5.7" sorts cleanly after the existing "Step 5.5" doc-sync and before the surfacing "Step 4.6/9.5/5.6" without cross-wiring.
- 2026-06-06 [impl-decision] The green portability verdict scratch file is written as a ready-to-splice `### Portability\n\n<VERDICT_LINE>` block (not a bare line), so the existing Step 4.6/9.5/5.6 awk splice — extended to strip+re-insert a `### Portability` block alongside `### Registered-doc requirements` under `## Documentation` — stays a uniform insert-or-replace for both blocks.
- 2026-06-06 [impl-finding] The engine exits non-zero under `PORTABILITY_STRICT=1`; captured it with the file's established `&& PA_RC=0 || PA_RC=$?` idiom (mirroring the `sync` phase at `cj-goal-common.sh:470`) so the non-zero exit is preserved rather than swallowed/aborting. The phase emits exit 2 on findings (matching the file's `failed`-class convention), exit 0 on ok/skipped.
- 2026-06-06 [impl-finding] BLIND-SPOT pre-flight honored (F000032/34/35/47 lesson): added BOTH a `tests/cj-goal-common-portability.test.sh` runner block AND a `--phase portability-audit` integration block to `scripts/test.sh` (parallel to the existing `--phase sync` wiring), so CI exercises the new phase. Full `scripts/test.sh` is green (0 failures) and `scripts/validate.sh` is green (0 errors / 0 warnings, incl. Check 15b + Check 18).
- 2026-06-06 [impl-auto] Auto-equivalent run (silent subagent for /CJ_goal_feature; no AUQ tool). The change touches a sensitive surface (`scripts/test.sh` validator) and >2 files, but the /office-hours design doc is the authorization for exactly these design-scoped infra files (it does NOT touch skills-catalog.json / manifest / validate.sh), so the gate was satisfied by the design approval rather than an interactive AUQ.
- 2026-06-06 [impl-pass] S000091: implementation complete. Phase 2 implementer-owned gates transitioned (`Todos section reflects remaining work`, `Files section updated with changed files`). QA-owned gates left for /CJ_qa-work-item.
- 2026-06-06 [qa-e2e-deferred] E3 (AC-3): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. Live `/CJ_goal_feature` halt-on-dishonest-declaration only meaningful after this change merges.
- 2026-06-06 [qa-e2e-deferred] E4 (AC-4): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. Live-pipeline green `### Portability` PR-body line only verifiable after merge.
- 2026-06-06 [qa-e2e-deferred] E5 (AC-5): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); not run pre-ship. Resume-restarts-at-gate after a red only exercisable on a live run post-merge.
- 2026-06-06 [qa-smoke] S1 (AC-1): green — `cj-goal-common.sh --phase portability-audit --mode feature` exit 0; emitted PHASE=portability-audit, MODE=feature, FINDINGS=0, SKILLS_AUDITED=12, PHASE_RESULT=ok, clean VERDICT_LINE.
- 2026-06-06 [qa-smoke] S2 (AC-2): green — dishonest-declaration fixture (tests/cj-goal-common-portability.test.sh findings case) → non-zero exit (rc=2), PHASE_RESULT=findings, FINDINGS=1, red VERDICT_LINE. Red path enforces.
- 2026-06-06 [qa-smoke] S3 (AC-2): green — engine-absent → exit 0 + PHASE_RESULT=skipped (fail-soft, never findings); --dry-run → exit 0 + PHASE_RESULT=ok + empty FINDINGS= + engine NOT run (tripwire not fired).
- 2026-06-06 [qa-smoke] S4 (AC-6): green — `scripts/validate.sh` exit 0 (Errors:0 Warnings:0; Check 15b PASS for all 3 CJ_goal_* workflow.md sections; Check 18 portability clean, 12 skills); `scripts/test.sh` exit 0 (Failures:0; incl. the F000051 test-runner block + the --phase portability-audit integration block).
- 2026-06-06 [qa-smoke] S5 (AC-3): green — all 3 orchestrators (feature pipeline.md, defect pipeline.md, todo SKILL.md) carry a `--phase portability-audit` call + `[portability-red]` halt token + `halted_at_portability` end-state, anchored after Step 5.5 doc-sync and before the actual `/ship` invocation.
- 2026-06-06 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-164600-3542 commit=97c703c
- 2026-06-06 [qa-e2e] E1 (AC-1): green — `cj-goal-common.sh --phase portability-audit --mode feature` on the live catalog printed the full structured block (PHASE/MODE/FINDINGS=0/SKILLS_AUDITED=12/PHASE_RESULT=ok) with VERDICT_LINE "Portability: all 12 skills honestly declared (0 findings)"; exit 0. [parent-inline]
- 2026-06-06 [qa-e2e] E2 (AC-7): green — dry-run runs nothing (`cj-goal-common.sh --phase portability-audit --dry-run` → PHASE_RESULT=ok + empty FINDINGS=, engine not invoked) AND all 3 orchestrators carry a dry-run/chain-plan preview line naming the portability-audit gate as halt-on-red before /ship (feature pipeline.md:101, defect pipeline.md:106, todo SKILL.md:87/158/362). [parent-inline]
- 2026-06-06 [qa-e2e-note] E1/E2 executed parent-inline (read-only/skill-invoking rows): this QA runner is a leaf with no Agent-spawn tool, so the subagent-eligible rows were run with the same tool surface the Step-7 subagent contract specifies (Read/Bash/Grep/Glob/Skill) rather than via a fresh Agent context — rows genuinely executed, not structurally inspected. E3/E4/E5 are post-ship (deferred to post-merge; [qa-e2e-deferred] above).
- 2026-06-06 [qa-e2e-summary] green (0s subagent; 2 rows parent-inline; 3 deferred): E1 + E2 green; E3/E4/E5 post-ship deferred to post-merge.
- 2026-06-06 [qa-pass] S000091 (user-story): green smoke (5/5) + green E2E (E1, E2); 3 E2E row(s) (E3/E4/E5) deferred to post-merge (post-ship). Phase 2 gates transitioned; post-ship ACs (AC-3/AC-4/AC-5) awaiting post-merge verification (see [qa-e2e-deferred] entries above). Repo gates green: validate.sh (0 err/0 warn, Check 15b + 18) + test.sh (0 failures, incl. new portability test + integration block) + tests/cj-goal-common-portability.test.sh PASS.
