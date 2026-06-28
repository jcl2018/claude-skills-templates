---
name: "docs/workflows/ subfolder — per-workflow files + workflow.md as a pure index"
type: feature
id: "F000067"
status: active
created: "2026-06-27"
updated: "2026-06-27"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/docs-workflows-subfolder-design-20260627-204444.md -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/docs_workflows_subfolder`
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

- [ ] `docs/workflow.md` is reduced to a pure index/overview (~80–120 lines): intro/preamble + a compact one-line-per-workflow index linking each `docs/workflows/*.md` + the `## See also` tail.
- [ ] Six new `docs/workflows/*.md` files exist, each carrying its moved-verbatim content (no prose lost): `CJ_goal_feature.md`, `CJ_goal_task.md`, `CJ_goal_defect.md`, `CJ_goal_todo_fix.md`, `utilities-and-phase-steps.md`, `utility-audits.md`.
- [ ] The portable doc-spec seed is taught the two-level structure as a **hard mandate**, edited 3-way byte-identical (`spec/doc-spec.md` + `templates/doc-spec-common.md` + the `doc-spec.sh --seed` heredoc); the no-drift test stays green.
- [ ] `scripts/doc-spec.sh --check-on-disk` adds a `workflows-subfolder` check (registry present ⇒ `docs/workflows/` must exist + contain ≥1 `*.md`) and recurses `docs/` for orphans so every `docs/workflows/*.md` must be declared.
- [ ] The mandate is registry-gated: a `REGISTRY=absent` repo still exits 0 (mandate never fires on an unrelated repo).
- [ ] `spec/doc-spec-custom.md` declares the 6 new `docs/workflows/*.md` overlay rows (human-docs; no work-item IDs).
- [ ] `scripts/validate.sh` Check 15a recurses `docs/`, Check 15b retargets per-`CJ_goal_*` enforcement to `docs/workflows/<name>.md`, and a NEW light Check 15c verifies `docs/workflow.md` links each orchestrator's subfolder file (no-vanish guarantee).
- [ ] `spec/test-spec-custom.md` declares `units:` rows for the new engine check, the recursed orphan scan, the retargeted Check 15b, and the new Check 15c.
- [ ] Tests updated: `tests/doc-spec-overlay.test.sh` covers the new engine check + recursion; `tests/cj-document-release-config.test.sh` seed no-drift still green; `scripts/test.sh` zzz-test-scaffold integration fixture updated for the new validate checks.
- [ ] `scripts/validate.sh` + `scripts/test.sh` green; `/CJ_doc_audit` + `/CJ_test_audit` clean post-sync.
- [ ] Contract-describing prose synced (`CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `templates/doc-WORKFLOWS-section.md`).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement S000111 (the single child story carrying the whole reorganize + contract-teach change).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-27: Created. Split deep per-workflow detail out of `docs/workflow.md` into a `docs/workflows/` subfolder, leave `workflow.md` as a pure index, and bake the two-level structure into the portable doc-spec seed as a hard mandate.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `docs/workflow.md` — reduce to index/overview
- `docs/workflows/{CJ_goal_feature,CJ_goal_task,CJ_goal_defect,CJ_goal_todo_fix,utilities-and-phase-steps,utility-audits}.md` — new
- `spec/doc-spec.md`, `templates/doc-spec-common.md`, `scripts/doc-spec.sh` (`--seed` heredoc) — 3-way byte-identical seed edit
- `scripts/doc-spec.sh` — `--check-on-disk` recursion + new `workflows-subfolder` check + `--list-human-docs`
- `spec/doc-spec-custom.md` — +6 overlay rows
- `scripts/validate.sh` — Check 15a recursion, Check 15b retarget, new Check 15c
- `spec/test-spec-custom.md` — +units rows
- `tests/doc-spec-overlay.test.sh`, `tests/cj-document-release-config.test.sh` — coverage
- `scripts/test.sh` — zzz-test-scaffold integration fixture
- `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `templates/doc-WORKFLOWS-section.md` — prose sync

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Approach C (chosen over the recommended overlay-only A): bake the two-level structure into the **portable** seed as a **hard mandate**, with a **full split** (workflow.md → pure index). Every adopting repo inherits the mandate.
- The mandate is **registry-gated** so it never fires on a repo that has not adopted the doc contract (`REGISTRY=absent` ⇒ skip).
- Reorganize, do NOT expand — existing content moves verbatim; "current depth is ok."
- 3-way byte-identity (seed) is fragile — edit `spec/doc-spec.md`, `templates/doc-spec-common.md`, and the `doc-spec.sh --seed` heredoc in lockstep; the no-drift test enforces it.
- Check 15b retarget must not lose the no-vanish guarantee → that is exactly what the new Check 15c protects.
- Every new `validate.sh` check needs the parallel `scripts/test.sh` zzz-test-scaffold fixture edit (the implement-subagent blind spot — F000032/F000034/F000035 all hit it).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-27 — **Approach C (portable seed + hard mandate + full split)** chosen over the recommended overlay-only A. Summary: the two-level docs structure becomes part of the general/portable doc contract, not a workbench-only overlay; the engine mandates the subfolder when the registry is present.
- [decision] 2026-06-27 — **Full split** chosen over orchestrators-only. Summary: all six dense sections (4 orchestrators + utilities-and-phase-steps + utility-audits) move out; `workflow.md` becomes a pure index.
- [decision] 2026-06-27 — **"Mandate"** chosen over "describe + permit". Summary: an adopting repo MUST have a non-empty `docs/workflows/`; a missing one is a `stage1/workflows-subfolder` FINDING.
