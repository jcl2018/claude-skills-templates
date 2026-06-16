---
name: "test-spec behavior-coverage axis"
type: feature
id: "F000066"
status: active
created: "2026-06-16"
updated: "2026-06-16"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/angry-wozniak-0b3ea3"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/test_spec_behavior_coverage_axis`
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

- [ ] A repo can declare a behavior with a `level` and a coverage link; `test-spec.sh --check-coverage` FAILS when a declared behavior has no covering row, when the anchor doesn't grep live, or when it points at a non-test-bearing unit.
- [ ] A behavior pointing at a real, green, semantically-matching test PASSES.
- [ ] A repo with no `behaviors:` reports "behavior coverage inactive" and stays green (no fabricated findings) — consumer parity preserved.
- [ ] The general `spec/test-spec.md` is byte-identical to `test-spec.sh --seed` (existing seed-identity test still green).
- [ ] `/CJ_test_audit` Stage-2 flags a vague / over-claimed / mis-leveled behavior row.
- [ ] The ~8 dogfood behavior rows for test-spec itself are green on the live tree.
- [ ] `scripts/validate.sh` and `scripts/test.sh` both green.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000110 — implement the behavior-coverage axis (parser + 6 checks + 2 plumbing items + seed prose + `/CJ_test_audit` Stage-2 sub-check + dogfood rows)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-16: Created. Add an open-world behavior-coverage axis (declared `behaviors:` + first-class test `level`) to the two-tier test-spec contract.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (seed prose + closed `level` enum; machine block UNCHANGED, schema_version stays 1)
- `spec/test-spec-custom.md` (the ~8 dogfood `behaviors:` + `behavior_coverage:` rows)
- `scripts/test-spec.sh` (parser for the two new blocks; 6 conformance checks; `--list-behaviors` / `--list-behavior-coverage`; `--validate` lint; embedded `--seed` heredoc in lockstep)
- `scripts/validate.sh` Check 24 (run the new behavior checks in the same hard loop)
- `scripts/test.sh` + `tests/test-spec.test.sh` (parser round-trip + new deterministic-check drills + the parallel integration-fixture edit)
- `skills/CJ_test_audit/SKILL.md` (the new Stage-2 behavior substance sub-check)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The reframe is open-world: you DECLARE the behaviors the software must prove, so the absence of a covering test becomes a detectable gap instead of silence. Starting from a missing behavior ("is adding a short put valid?") rather than a coverage metric is what made the open-world flip obvious.
- Test **level** (`unit | integration | contract | workflow | property`) is first-class and lives on the **behavior** (the obligation), NOT on `units[]` — one suite legitimately proves multiple levels, so leveling the mechanism is wrong; leveling the obligation is right.
- The deterministic check alone is NOT sufficient: without the agent-judged substance check (`/CJ_test_audit` Stage-2) the blind spot merely *relocates* from untested code to vague behavior prose (Codex risk #2). The agent-judged stage is load-bearing, not optional.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-16 — Keep `schema_version: 1` everywhere; the two new arrays are optional-on-schema-1 and overlay-only. The seed's machine block is unchanged (prose-only seed edit), so no version bump and no `SUPPORTED_SCHEMA_VERSIONS` change — preserves the byte-identical-seed test and the one-fenced-yaml-block invariant. Summary: resolves the reviewer's which-file-version contradiction.
- [decision] 2026-06-16 — `level` lives on the `behaviors[]` obligation, not on `units[]` (Codex P3, agreed-revised). Summary: a mechanism can legitimately prove multiple levels; the obligation is the right place to assert depth-of-pyramid.
- [decision] 2026-06-16 — Adopted P5 (the mandatory agent-judged stage) from Codex risk #2. Summary: a self-attested low-granularity behavior row can go green while the real behavior stays invisible; the `/CJ_test_audit` Stage-2 substance check is what prevents that false confidence.
- [decision] 2026-06-16 — Chose Approach A (minimal honest v1). Summary: closes the actual gap and defers pyramid quotas / diff-aware enforcement / executable-spec (Approaches B/C) as fast-follows.
