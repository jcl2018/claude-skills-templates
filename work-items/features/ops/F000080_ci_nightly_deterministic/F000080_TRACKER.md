---
name: "Make CI-nightly deterministic — delete the agentic evals + doc-sync audit, re-layer to local-hook"
type: feature
id: "F000080"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-volhard-9dcadc"
branch: "claude/vigorous-volhard-9dcadc"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/ci_nightly_deterministic`
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

- [ ] `.github/workflows/eval-nightly.yml` and `.github/workflows/audit-nightly.yml` no longer exist; the only scheduled workflow is `windows-nightly.yml` (deterministic `portability-deploy`).
- [ ] `spec/test-spec-custom.md` declares `goal-task-eval` / `goal-feature-eval` / `doc-sync` at `layer: local-hook`; the `ci-eval-nightly` and `ci-audit-nightly` units are removed.
- [ ] The 3 front-door docs live under `docs/tests/workflow/local-hook/`; `docs/tests/index.md` + `spec/doc-spec-custom.md` agree with disk.
- [ ] No doc/spec/skill text claims a nightly-CI audit or eval that no longer runs (the "nightly in CI via audit-nightly.yml" prose is swept to "on-demand locally").
- [ ] `scripts/eval.sh` and `scripts/audit-nightly.sh` are KEPT (on-demand/local runners); the `test-audit-nightly` regression test stays.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` GREEN; `test-spec.sh --check-structure` findings=0; Check 28 still passes (orchestrators=4, behaviors=4).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Deliver the 7-part file set via child story S000130 (delete the two cron wrappers; re-layer the 3 category rows; move the front-door docs; fix the index + doc-spec declarations; prose sweep; regenerate + validate).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Make CI-nightly deterministic by deleting the two agentic cron wrappers (`eval-nightly.yml`, `audit-nightly.yml`) and re-layering the 3 agentic tests (`goal-task-eval`, `goal-feature-eval`, `doc-sync`) from `CI-nightly` to `local-hook`; keep the scripts as on-demand/local runners.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `.github/workflows/eval-nightly.yml` (delete)
- `.github/workflows/audit-nightly.yml` (delete)
- `spec/test-spec-custom.md` (re-layer 3 category rows; remove 2 units; soften prose)
- `spec/doc-spec-custom.md` (update 3 doc-declaration paths)
- `docs/tests/workflow/CI-nightly/{goal-task-eval,goal-feature-eval,doc-sync}.md` (git mv → local-hook/)
- `docs/tests/index.md` (move 3 INDEX rows CI-nightly → local-hook)
- `spec/workflow-spec.md` + generated `docs/workflows/*.md` (prose sweep + `--render-docs`)
- `CLAUDE.md`, `docs/architecture.md`, `docs/reference.md` (prose sweep)
- 4 `CJ_goal_*` SKILL.md/USAGE.md/pipeline.md + `CJ_qa-work-item`/`CJ_doc_audit` (prose sweep)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- One coherent move makes the CI cost profile honest: after this change nothing on a cron burns model tokens. The agentic proofs don't disappear — they move to `local-hook` (joining `e2e-local`, the already-established agentic local-hook workflow test) and run on-demand.
- Because this change removes the very nightly job that auto-catches semantic prose drift, the honest prose sweep must happen *in the same PR* so the docs never claim a nightly job that no longer exists — the same doc-truthfulness instinct the whole workbench is built on.
- Reversibility is preserved by git history: re-enabling an agentic (or split doc/test) nightly later = `git revert`.
- Check 28 is verified UNAFFECTED: the `level: workflow` behaviors link via `workflow: CJ_goal_*` and their `behavior_coverage` `source:` points at `tests/eval/*/prompt.md`, NOT the `categories:` axis `layer` — re-layering the category rows does not touch the workflow-coverage gate.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03: Chose Approach A (delete the two `.yml` cron wrappers outright + manual-local safety net) over Approach B (neuter: keep `workflow_dispatch`, drop `schedule:`) and Approach C (delete + add a deterministic model-free nightly heartbeat). Rationale: A is the most truthful end-state for a doc-truthfulness repo — a dormant-but-referenced workflow (B) is precisely the semantic half-truth this change removes the auto-catch for, and a deterministic nightly (C) is near-redundant with the per-PR gate. Summary: delete-and-manual-local wins on truthfulness; reversibility via git history.
- [decision] 2026-07-03: Keep `scripts/eval.sh` + `scripts/audit-nightly.sh` and the `test-audit-nightly` regression test (`tests/audit-nightly.test.sh`, anchored on the script not the workflow). Only the two `.github/workflows/*.yml` cron wrappers are deleted. Summary: scripts become on-demand/local runners; the interim safety net is a hand-run `bash scripts/audit-nightly.sh` (or `/CJ_doc_audit` + `/CJ_test_audit`).
