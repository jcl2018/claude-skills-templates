---
name: "Generate docs/testing.md — the test-suite front door (Testing roadmap Phase 1)"
type: feature
id: "F000088"
status: active
created: "2026-07-06"
updated: "2026-07-06"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-mcclintock-e72fcb"
branch: "claude/docs-testing-front-door"
blocked_by: ""
---

<!-- Source /office-hours design:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-docs-testing-front-door-design-20260706-211006.md -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/generate_docs_testing_frontdoor` (using existing `claude/docs-testing-front-door`)
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

- [ ] `docs/testing.md` is emitted by `test-spec.sh --render-docs` (fixed template prose + registry-derived indexes) — no hand-edited sections.
- [ ] `docs/testing.md` is declared in `spec/doc-spec-custom.md` as a generated human-doc (no work-item IDs — Check 19 green).
- [ ] `validate.sh` Check 26 (`--render-docs --check`) is GREEN on the new file, and catches a hand-edit.
- [ ] `doc-spec.sh --validate` + `--check-on-disk` are green (declared, present, no orphan).
- [ ] The behaviors + categories indexes in the rendered page match the live merged registry (17 behaviors + 28 categories today) and track adds/removes automatically.
- [ ] `spec/test-spec.md` seed byte-identity intact (no general-seed change).
- [ ] Full `scripts/test.sh` green, incl. the new `tests/test-spec.test.sh` render/freshness drill.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship child S000137 (add `_render_testing_md` to `scripts/test-spec.sh`; wire into `--render-docs` + `--render-docs --check`; declare in `spec/doc-spec-custom.md`; add the `tests/test-spec.test.sh` drill).
- [ ] End-to-end pipeline run: regenerate, confirm Check 26 + doc-spec engines + seed identity + `test-spec.test.sh` green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Generate a single generated `docs/testing.md` front door for the test suite (Testing roadmap Phase 1), rendered from the merged test-spec registry so it can't drift.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/test-spec.sh` (add `_render_testing_md`; wire into render + check paths)
- `spec/doc-spec-custom.md` (declare `docs/testing.md` generated human-doc row)
- `docs/testing.md` (new — generated)
- `tests/test-spec.test.sh` (add render/idempotency/freshness drill)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Emitting `docs/testing.md` from the SAME `--render-docs` (+ `--render-docs --check`) path means the existing `validate.sh` Check 26 covers it automatically — no new validate check is needed.
- `docs/testing.md` complements (does not replace) `docs/test-catalog.md`: the catalog is the detailed family index; `docs/testing.md` is the narrative top-level front door that links down to the catalog + `docs/goals/<topic>.md` dream docs + `docs/tests/topics/`.
- Approach A (hybrid: concise generated why + link to `docs/philosophy.md` §Verification) avoids duplicating the verification principle prose — the exact drift this roadmap fights.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Chose Approach A (hybrid: concise generated what/why + link to `philosophy.md`/`test-spec.md`) over B (fully self-contained, duplicates the verification principle) and C (thin index/hub). Summary: a real front door that reads as one coherent story without a second copy of the verification principle to keep in sync.
