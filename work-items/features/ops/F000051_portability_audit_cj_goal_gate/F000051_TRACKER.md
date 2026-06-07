---
name: "Enforce /CJ_portability-audit in the cj_goal orchestrators"
type: feature
id: "F000051"
status: active
created: "2026-06-06"
updated: "2026-06-06"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/intelligent-goodall-0860b2"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/portability_audit_cj_goal_gate`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] A new shared phase `cj-goal-common.sh --phase portability-audit` exists, runs the engine in `PORTABILITY_STRICT=1` mode, and emits `PHASE=`, `MODE=`, `FINDINGS=`, `SKILLS_AUDITED=`, `VERDICT_LINE=`, `PHASE_RESULT=` to stdout.
- [ ] The phase exits 0 + `PHASE_RESULT=ok` on the current clean catalog; non-zero + `PHASE_RESULT=findings` on a fixture catalog with a dishonest declaration; 0 + `PHASE_RESULT=skipped` when the engine is absent (fail-soft).
- [ ] All three orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) call the gate immediately after the Step 5.5 doc-sync block and immediately before `/ship`, halting on red with `[portability-red]` (end_state `halted_at_portability`).
- [ ] On green, each orchestrator writes `VERDICT_LINE` to `.cj-goal-feature/portability-verdict.md` and the existing Step 4.6 / 9.5 / 5.6 surfacing step splices a `### Portability` line into the PR body (best-effort, never halts).
- [ ] The gate is a pure read with no phase boundary — a resume after a `[portability-red]` halt restarts at the gate, not at `/ship`.
- [ ] `docs/workflow.md` Touches blocks + ASCII charts for all 3 `CJ_goal_*` sections are updated (Check 15b passes); `CLAUDE.md` phase list + scripts-reference row + gate note updated.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` pass, including the new `tests/cj-goal-common-portability.test.sh`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Add `--phase portability-audit` to `scripts/cj-goal-common.sh` (+ `--phase` enum, usage string, header-comment phase list, `resolve_portability_engine()`, dry-run branch).
- [ ] Add `tests/cj-goal-common-portability.test.sh` (clean → ok/exit 0; findings fixture → findings/non-zero; engine-absent → skipped/exit 0); wire into `scripts/test.sh` if it enumerates cj-goal-common phases.
- [ ] Wire the gate + `[portability-red]` halt handler + verdict-scratch write into the 3 orchestrators (feature `pipeline.md`, defect `pipeline.md`, todo `SKILL.md` — single-TODO AND drain-mode prose).
- [ ] Extend the Step 4.6 / 9.5 / 5.6 PR-surfacing step to also read `.cj-goal-feature/portability-verdict.md`.
- [ ] Update `docs/workflow.md` Touches blocks + charts (Check 15b) and `CLAUDE.md`.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Enforce /CJ_portability-audit as a halt-on-red gate in all three cj_goal orchestrators via a shared `cj-goal-common.sh --phase portability-audit`, with the verdict surfaced in the PR body.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-goal-common.sh` — host of the new `portability-audit` phase
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_feature/SKILL.md`
- `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_defect/SKILL.md`
- `skills/CJ_goal_todo_fix/SKILL.md`
- `tests/cj-goal-common-portability.test.sh`, `scripts/test.sh`
- `docs/workflow.md`, `CLAUDE.md`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The audit ALREADY runs on every cj_goal commit (pre-commit → `validate.sh` Check 18). "Enforce" ≠ "make it run" — the real gap is gating (advisory exit 0 never blocks) + visibility (verdict buried in validate.sh output).
- The catalog baseline is clean (`FINDINGS=0`, even raw via `--no-adjudication`). A strict halt-on-any-finding gate is green today AND is a regression ratchet for free — any finding is by definition new, so no baseline-diff machinery is needed.
- `FINDINGS=` is the count of SKILLS-WITH-findings, not total findings; `SKILLS_AUDITED=` is the audited count. Parse both; gate on `FINDINGS > 0` (≡ `PA_RC != 0`).
- The todo orchestrator has no `--mode todo`; it calls the phase with `--mode feature` (verbatim the value it already passes for `--phase sync`). No change to the shared `--mode` validation needed.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-06: Chose Approach B (shared `--phase portability-audit` in `cj-goal-common.sh`) over Approach A (inline per-orchestrator bash — triples drift surface + 3 halt-table edits) and Approach C (export `PORTABILITY_STRICT=1` into the pre-commit path — fragile env-var propagation across subagent commit shells; red surfaces as an opaque mid-subagent pre-commit failure, not a clean halt). The shared phase is the idiomatic home for every cross-cutting cj_goal concern (worktree / sync / pr-check / cleanup / telemetry).
- [decision] 2026-06-06: Gate decision at the premise gate = option C — gate (halt-on-red) AND surface the verdict in the PR body, not visibility-only.
- [decision] 2026-06-06: `validate.sh` Check 18 stays ADVISORY (global); the new gate is cj_goal-scoped enforcement. Flipping Check 18 to strict-by-default is a separate, broader decision deferred to a follow-up PR.
- [decision] 2026-06-06: Insertion is anchored by CONTENT (the Step 5.5 doc-sync handler block, before `/ship`), NOT by a new step number — the orchestrators' step numbers are already non-monotonic, so a new number would be jarring and an implementer grepping a number could cross-wire.
