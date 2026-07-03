---
name: "QA-gate slimming — relocate the agent-judged audit to CI-nightly"
type: feature
id: "F000076"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/wonderful-burnell-e85b3a"
branch: "claude/wonderful-burnell-e85b3a"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/qa_gate_slim_audit_to_nightly`
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

- [ ] The inline post-sync audit (Step 5.6) + the QA-audit checkpoint (Step 3.4/4.5/8.5) are removed from all four `CJ_goal_*` orchestrator paths; a `grep -rn "halted_at_qa_audit\|qa-audit-declined\|qa-audit-waived\|post-sync.*audit"` over the four `skills/CJ_goal_*/` dirs returns nothing.
- [ ] `DEFER_AUDIT: true` STAYS in the QA dispatch (it is now the skip-inline-audit switch, not the defer-to-orchestrator switch); `skills/CJ_qa-work-item/qa.md` keeps its `DEFER_AUDIT` detection + the 8.6c/8.6d skip, with only the deferred-path RESULT prose reworded.
- [ ] A new CI-nightly Claude job exists — `.github/workflows/audit-nightly.yml` + `scripts/audit-nightly.sh` — modeled on `eval-nightly.yml` (cron + `workflow_dispatch`, secret pre-check, budget cap, `SKIP` without `ANTHROPIC_API_KEY`), that runs `/CJ_doc_audit` + `/CJ_test_audit` over `main` and files findings to a GitHub issue.
- [ ] `bash scripts/audit-nightly.sh` with no `ANTHROPIC_API_KEY` prints `SKIP` and exits 0 (a normal `test.sh` / a secret-less fork never touches a model).
- [ ] `./scripts/validate.sh` passes (esp. Check 24 gate-marker drift clean, Check 26 test-catalog fresh, Check 27 workflow docs fresh, Check 28 workflow coverage).
- [ ] `./scripts/test.sh` full suite green, incl. the new `tests/audit-nightly.test.sh` + the updated `cj-audit-skills` / `cj-goal-doc-sync-wiring` tests.
- [ ] `shellcheck` clean on `scripts/audit-nightly.sh`.
- [ ] The deterministic per-PR gate (validate.sh / validate.yml / pre-commit) and standalone `/CJ_qa-work-item` + `/CJ_doc_audit` + `/CJ_test_audit` are unchanged.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Remove the inline audit machinery from the four orchestrator paths: `skills/CJ_goal_feature/pipeline.md` (Step 5.6 + Step 3.4), `skills/CJ_goal_task/pipeline.md` (Step 5.6 + Step 4.5), `skills/CJ_goal_defect/pipeline.md` (Step 5.6 + Step 8.5), `skills/CJ_goal_todo_fix/pipeline.md` (Step 5.5b post-sync + Step 5.6 checkpoint + the `--quiet` green-continue logic) — plus the four `SKILL.md` (description strings, overview chains, halt-taxonomy rows) and the four `USAGE.md`.
- [ ] Light-touch `skills/CJ_qa-work-item/qa.md`: KEEP `DEFER_AUDIT` detection + the 8.6c/8.6d skip; only reword the deferred-path RESULT prose ("orchestrator runs post-sync audit at Step 5.6" → "nightly CI covers the audit; orchestrator does not re-run inline").
- [ ] Registry/gate: delete the `qa-audit` gate row (order 50) + its markers from `spec/test-spec-custom.md`, drop it from the grouped-by-layer table, update the `doc-sync` (order 45) prose; scrub the qa-audit-gate prose from `spec/test-spec.md`. `scripts/validate.sh` needs no code change (Check 24 marker-drift is advisory; with the row + markers gone it stays clean) — verify green.
- [ ] Add the nightly job: `.github/workflows/audit-nightly.yml` (cron ~`37 9 * * *` + `workflow_dispatch`; `permissions: contents:read, issues:write`; concurrency; secret pre-check; install jq + claude-code; run `scripts/audit-nightly.sh`; job summary) + `scripts/audit-nightly.sh` (SKIP-without-key, budget cap, `claude --print` of `/CJ_doc_audit` + `/CJ_test_audit`, parse `FINDINGS=` → create/update/close one `audit-drift` GitHub issue) + `tests/audit-nightly.test.sh` (deterministic half; register in `scripts/test.sh`; declare in the test-spec overlay).
- [ ] Generated docs (edit source → regenerate): `spec/workflow-spec.md` orchestrator Touches/flow blocks → `workflow-spec.sh --render-docs`; `docs/tests/*` + `docs/test-catalog.md` via `test-spec.sh --render-docs` after the overlay edit.
- [ ] Prose: `CLAUDE.md` (orchestrator descriptions, "Doc-sync coverage", "Verification contract" passages), `docs/architecture.md`, `README.md`, `docs/workflows/utility-audits.md`, `skills-catalog.json` (4 orchestrator descriptions), the 4 orchestrator `USAGE.md` + `CJ_qa-work-item/USAGE.md`.
- [ ] Tests: refactor `tests/cj-audit-skills.test.sh` (drop orchestrator-marker grep assertions; keep standalone) + `tests/cj-goal-doc-sync-wiring.test.sh` (checkpoint-ordering assertions gone); drop the `halted_at_qa_audit` / "qa-audit checkpoint" report rows from `tests/e2e-local.sh` + `tests/e2e-local/lib/report.sh` + `tests/e2e-local/reports/EXAMPLE.md`.
- [ ] Run `./scripts/validate.sh` + `./scripts/test.sh` + `shellcheck scripts/audit-nightly.sh`; confirm all acceptance criteria.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Remove the inline agent-judged post-sync audit + the QA-audit checkpoint from all four cj_goal orchestrator paths and relocate the audit to a new CI-nightly Claude job; the deterministic per-PR gate + standalone audit verbs are untouched.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_feature/USAGE.md`
- `skills/CJ_goal_task/pipeline.md`, `skills/CJ_goal_task/SKILL.md`, `skills/CJ_goal_task/USAGE.md`
- `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_defect/USAGE.md`
- `skills/CJ_goal_todo_fix/pipeline.md`, `skills/CJ_goal_todo_fix/SKILL.md`, `skills/CJ_goal_todo_fix/USAGE.md`
- `skills/CJ_qa-work-item/qa.md`, `skills/CJ_qa-work-item/USAGE.md` (light — deferred-path prose reword only)
- `.github/workflows/audit-nightly.yml` (new), `scripts/audit-nightly.sh` (new), `tests/audit-nightly.test.sh` (new)
- `spec/test-spec-custom.md`, `spec/test-spec.md`
- `spec/workflow-spec.md`, `docs/workflow.md`, `docs/workflows/*.md` (regenerated)
- `docs/test-catalog.md`, `docs/tests/*.md` (regenerated)
- `scripts/test.sh` (register the new test), `tests/cj-audit-skills.test.sh`, `tests/cj-goal-doc-sync-wiring.test.sh`
- `tests/e2e-local.sh`, `tests/e2e-local/lib/report.sh`, `tests/e2e-local/reports/EXAMPLE.md`
- `CLAUDE.md`, `docs/architecture.md`, `README.md`, `skills-catalog.json`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The audit is already advisory, not a hard gate: Stage 2/3 (the ~5-8 min agent-judged part) never flips QA red — it surfaces findings at a checkpoint the operator can Continue past. So removing it from the hot path removes an advisory drift-catch, not a merge gate.
- The audit's Stage 1 is deterministic and already runs per-PR in CI: the engine calls (`doc-spec.sh --check-on-disk`, `test-spec.sh --validate/--check-coverage/--render-docs/--check-workflow-coverage/--check-structure`) ARE `validate.sh` Checks 15-19/24/26/27/28, which `validate.yml` runs on every PR and the pre-commit hook runs locally. Re-running Stage 1 inline is pure redundancy.
- `DEFER_AUDIT: true` STAYS but its meaning shifts — from "defer to the orchestrator's post-sync re-run" to "skip the inline audit; the nightly CI job covers it." This is the minimal-surface way to slim the tail without touching the QA↔orchestrator handshake.
- Precedent for the nightly job: `eval-nightly.yml` already runs `claude --print` in CI nightly with a budget cap + secret pre-check + `SKIP`-without-key. The new `audit-nightly.yml` is the same pattern, so the safety story (no surprise model spend on a secret-less fork / a normal `test.sh`) is already proven.
- Tradeoff accepted: a doc/test drift a PR introduces is caught by the next nightly run (within-24h), not at merge. The deterministic contract still gates every PR, so nothing structural slips — acceptable for this repo's single-maintainer, low-PR-volume cadence.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Relocate (CI-nightly), don't delete, the agent-judged audit. Summary: keep the deterministic hard gate per-PR unchanged and move the advisory Stage 2/3 audit to a nightly `claude --print` sweep of `main` that files findings to an `audit-drift` GitHub issue — the operator loses ~5-8 min per build off the critical path without losing the drift-catch. `DEFER_AUDIT: true` is repurposed as the skip-inline switch. Single-story decomposition (one atomic multi-file change).
