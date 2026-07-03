---
name: "Remove the inline audit + checkpoint from the cj_goal paths and relocate it to a CI-nightly job"
type: user-story
id: "S000126"
status: active
created: "2026-07-03"
updated: "2026-07-03"
parent: "F000076"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/wonderful-burnell-e85b3a"
branch: "claude/wonderful-burnell-e85b3a"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/qa_gate_slim_audit_to_nightly` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
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
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
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

- [ ] The inline post-sync audit (Step 5.6) + the QA-audit checkpoint (Step 3.4/4.5/8.5) are removed from all four `CJ_goal_*` orchestrators (feature, task, defect, todo_fix): no post-sync `/CJ_doc_audit`+`/CJ_test_audit` subagent step, no checkpoint AUQ, no `halted_at_qa_audit` halt-taxonomy row, no `[qa-audit-declined]` / `[qa-audit-waived]` markers, and no audit node in the overview chains; the `todo_fix` `--quiet` green-continue logic that depended on the checkpoint is dropped.
- [ ] `DEFER_AUDIT: true` STAYS in the QA dispatch; `skills/CJ_qa-work-item/qa.md` keeps its `DEFER_AUDIT` detection + the 8.6c/8.6d skip and the `AUDITS=deferred` RESULT shape, with only the deferred-path RESULT prose reworded ("orchestrator runs post-sync audit at Step 5.6" → "nightly CI covers the audit; orchestrator does not re-run inline").
- [ ] `.github/workflows/audit-nightly.yml` exists — modeled on `eval-nightly.yml`: `schedule` cron (~`37 9 * * *`) + `workflow_dispatch`; `permissions: contents:read, issues:write`; a `concurrency` group; `defaults: shell: bash`; `ANTHROPIC_API_KEY` from secrets; installs jq + `@anthropic-ai/claude-code`; a secret pre-check; runs `scripts/audit-nightly.sh`; writes a job summary.
- [ ] `scripts/audit-nightly.sh` exists and is gated like `eval.sh`: no `ANTHROPIC_API_KEY` ⇒ `SKIP` (exit 0); a budget cap (per-run + aggregate); `claude --print` invoking `/CJ_doc_audit` then `/CJ_test_audit` standalone over the repo; parse the two `FINDINGS=` lines into `doc:<n>,test:<n>`; create-or-update ONE `audit-drift`-labelled GitHub issue when `n>0` (comment/close when clean); emit a machine-parseable job-summary line.
- [ ] `tests/audit-nightly.test.sh` exists (deterministic half only — the SKIP-without-key path, arg parsing, and the findings-parse → issue-decision logic with stubbed `claude`/`gh`), is registered in `scripts/test.sh`, and is declared in the `spec/test-spec-custom.md` overlay (a `units:` ci row + a `categories:` CI-nightly row + a `docs/tests/` doc).
- [ ] `spec/test-spec-custom.md` has the `qa-audit` gate row (order 50) + its markers removed and dropped from the grouped-by-layer table, the `doc-sync` (order 45) prose updated; `spec/test-spec.md` qa-audit-gate canonical-sequence prose scrubbed; the generated `docs/test-catalog.md` + `docs/tests/*.md` regenerated (Check 26).
- [ ] `spec/workflow-spec.md` has the DEFER_AUDIT / Step 5.6 / checkpoint wording removed from all four orchestrator Touches/flow blocks; `docs/workflow.md` + `docs/workflows/*.md` regenerated and fresh (Check 27); `docs/workflows/utility-audits.md` checkpoint references updated.
- [ ] `tests/cj-audit-skills.test.sh` drops the orchestrator-marker grep assertions (keeps the standalone assertions); `tests/cj-goal-doc-sync-wiring.test.sh` has the checkpoint-ordering assertions refactored out; `tests/e2e-local.sh` + `tests/e2e-local/lib/report.sh` + `tests/e2e-local/reports/EXAMPLE.md` drop the `halted_at_qa_audit` / "qa-audit checkpoint" report rows.
- [ ] `CLAUDE.md` ("Doc-sync coverage", "Verification contract", orchestrator descriptions), `docs/architecture.md`, `README.md`, `skills-catalog.json` (4 orchestrator descriptions), the 4 orchestrator `USAGE.md` + `CJ_qa-work-item/USAGE.md` updated to match the removal.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both pass; `shellcheck scripts/audit-nightly.sh` clean; `bash scripts/audit-nightly.sh` with no key prints `SKIP` + exits 0.

## Todos

<!-- Actionable items for this story. -->

- [ ] Edit the four orchestrators' `pipeline.md`: delete Step 5.6 (post-sync audit) + the checkpoint (feature 3.4 / task 4.5 / defect 8.5 / todo_fix 5.5b+5.6); keep the `DEFER_AUDIT: true` directive in the QA dispatch but drop its "defer-to-orchestrator" explanation; delete the `halted_at_qa_audit` halt-taxonomy rows + the cj-e2e-gate qa-audit seam block; drop the `todo_fix` `--quiet` green-continue logic.
- [ ] Edit the four orchestrators' `SKILL.md` (description strings + overview chains + halt-taxonomy rows) + `USAGE.md`.
- [ ] Light-touch `skills/CJ_qa-work-item/qa.md`: keep `DEFER_AUDIT` detection + the 8.6c/8.6d skip; reword the deferred-path RESULT prose only. Update `CJ_qa-work-item/USAGE.md` if it references the orchestrator post-sync re-run.
- [ ] Add `.github/workflows/audit-nightly.yml` (cron `~37 9 * * *` + `workflow_dispatch`; `permissions: contents:read, issues:write`; concurrency; `defaults: shell: bash`; secret pre-check; install jq + claude-code; run `scripts/audit-nightly.sh`; job summary).
- [ ] Add `scripts/audit-nightly.sh` (SKIP-without-key + exit 0; budget cap; `claude --print` of `/CJ_doc_audit` + `/CJ_test_audit`; parse `FINDINGS=` → `doc:<n>,test:<n>`; create/update/close ONE `audit-drift` GitHub issue; machine-parseable summary line).
- [ ] Add `tests/audit-nightly.test.sh` (deterministic: SKIP-without-key, arg parsing, findings-parse → issue-decision with stubbed `claude`/`gh`); register it in `scripts/test.sh`; declare it in `spec/test-spec-custom.md` (`units:` ci row + `categories:` CI-nightly row) + seed the `docs/tests/` doc.
- [ ] Edit `spec/test-spec-custom.md` (remove the `qa-audit` gate row order 50 + markers; drop from grouped-by-layer; update `doc-sync` order 45 prose) + `spec/test-spec.md` (scrub qa-audit-gate canonical-sequence prose); regenerate `docs/test-catalog.md` + `docs/tests/*.md` via `test-spec.sh --render-docs`.
- [ ] Edit `spec/workflow-spec.md` (remove DEFER_AUDIT / Step 5.6 / checkpoint from the four orchestrator Touches/flow) → `workflow-spec.sh --render-docs`; update `docs/workflows/utility-audits.md`.
- [ ] Edit tests: `tests/cj-audit-skills.test.sh` (drop orchestrator-marker greps), `tests/cj-goal-doc-sync-wiring.test.sh` (checkpoint-ordering assertions gone), `tests/e2e-local.sh` + `tests/e2e-local/lib/report.sh` + `tests/e2e-local/reports/EXAMPLE.md` (drop qa-audit report rows).
- [ ] Edit prose: `CLAUDE.md`, `docs/architecture.md`, `README.md`, `skills-catalog.json` (4 orchestrator descriptions).
- [ ] Run `./scripts/validate.sh` + `./scripts/test.sh` + `shellcheck scripts/audit-nightly.sh` + `bash scripts/audit-nightly.sh` (no key ⇒ SKIP); confirm acceptance criteria.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Single atomic user-story carrying the full QA-tail slimming — remove the inline post-sync audit + checkpoint from all four cj_goal orchestrators and relocate the audit to a new CI-nightly Claude job.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_feature/{pipeline.md,SKILL.md,USAGE.md}` (modified — remove Step 5.6 + Step 3.4 checkpoint)
- `skills/CJ_goal_task/{pipeline.md,SKILL.md,USAGE.md}` (modified — remove Step 5.6 + Step 4.5 checkpoint)
- `skills/CJ_goal_defect/{pipeline.md,SKILL.md,USAGE.md}` (modified — remove Step 5.6 + Step 8.5 checkpoint)
- `skills/CJ_goal_todo_fix/{pipeline.md,SKILL.md,USAGE.md}` (modified — remove Step 5.5b post-sync + Step 5.6 checkpoint + `--quiet` green-continue)
- `skills/CJ_qa-work-item/qa.md` (modified — light: deferred-path RESULT prose reword; KEEP DEFER_AUDIT detection + 8.6c/8.6d skip) + `skills/CJ_qa-work-item/USAGE.md`
- `.github/workflows/audit-nightly.yml` (new), `scripts/audit-nightly.sh` (new), `tests/audit-nightly.test.sh` (new)
- `spec/test-spec-custom.md` (modified — remove qa-audit gate row + markers; update doc-sync prose; add audit-nightly `units:`/`categories:` rows), `spec/test-spec.md` (modified — scrub qa-audit-gate prose)
- `spec/workflow-spec.md` (modified) + `docs/workflow.md`, `docs/workflows/*.md` (regenerated via `workflow-spec.sh --render-docs`), `docs/workflows/utility-audits.md`
- `docs/test-catalog.md`, `docs/tests/*.md` (regenerated via `test-spec.sh --render-docs`)
- `scripts/test.sh` (modified — register `tests/audit-nightly.test.sh`), `tests/cj-audit-skills.test.sh`, `tests/cj-goal-doc-sync-wiring.test.sh`
- `tests/e2e-local.sh`, `tests/e2e-local/lib/report.sh`, `tests/e2e-local/reports/EXAMPLE.md` (modified — drop qa-audit report rows)
- `CLAUDE.md`, `docs/architecture.md`, `README.md`, `skills-catalog.json` (modified — de-checkpoint prose + 4 orchestrator descriptions)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The file inventory must land as ONE atomic change: an intermediate state (checkpoint removed but the `qa-audit` gate row still declared in `spec/test-spec-custom.md`, or the marker dropped from a pipeline but still referenced by `tests/cj-audit-skills.test.sh`) would fail the pre-commit `validate.sh` / CI `test.sh`. Hence single-story, not multi-story.
- `DEFER_AUDIT: true` is a load-bearing keeper: it already makes QA skip its inline 8.6c/8.6d audit and emit `AUDITS=deferred`. Repurposing it (rather than removing it and re-enabling QA's inline audit) is what keeps the ~5-8 min OFF the build entirely instead of just relocating it within the run.
- `eval-nightly.yml` is the template to copy for `audit-nightly.yml` — same `claude --print`-in-CI-nightly shape with a budget cap + secret pre-check + `SKIP`-without-key, so the "no surprise model spend on a normal `test.sh` / a secret-less fork" guarantee is inherited, not re-invented.
- The four TEST-SPEC verification rows are deliberately smoke/command rows runnable in bash CI (grep-empty, `validate.sh`, `test.sh`, `shellcheck`, `audit-nightly.sh` SKIP), NOT interactive happy-path-to-PR E2E — the workbench defers full live cj_goal E2E on the gstack-in-CI blocker (`level: workflow` evals target dry-run/halt paths).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Atomic single-story decomposition. Summary: the reshape spans the four orchestrators (pipeline.md + SKILL.md + USAGE.md each), a light `qa.md` reword, three new files (workflow + runner + test), the test-spec + workflow-spec registries (+ regenerated docs), three test files, and the prose set — but it is one cohesive concern (move the audit off the hot path) and must land together to keep the pre-commit + CI gates green; no task children (atomic story).
- [decision] Keep `DEFER_AUDIT: true` and repurpose it as the skip-inline switch, rather than removing it and re-enabling QA's inline 8.6c/8.6d for orchestrator runs. Summary: the goal is to REMOVE ~5-8 min from the orchestrated build; re-enabling QA's inline audit would move the cost, not remove it. `qa.md` keeps its detection + skip + `AUDITS=deferred` RESULT shape; only the deferred-path prose is reworded.
