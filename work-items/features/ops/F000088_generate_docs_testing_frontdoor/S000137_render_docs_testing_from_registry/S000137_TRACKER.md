---
name: "Render docs/testing.md from the merged test-spec registry"
type: user-story
id: "S000137"
status: active
created: "2026-07-06"
updated: "2026-07-06"
parent: "F000088"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/vigorous-mcclintock-e72fcb"
branch: "claude/docs-testing-front-door"
blocked_by: ""
---

<!-- Atomic story deriving from the parent feature's /office-hours session.
     See ../F000088_DESIGN.md for the cross-story context. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/generate_docs_testing_frontdoor` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

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

- [x] `test-spec.sh --render-docs` writes `docs/testing.md` with all nine sections (fixed template prose + registry-derived indexes), carrying the GENERATED-FILE / Check-26 header.
- [x] `test-spec.sh --render-docs --check` diffs `docs/testing.md` too, so `validate.sh` Check 26 catches a hand-edit.
- [x] Rendering is idempotent (re-render produces a byte-identical file) and honors the existing `TESTDOC_OUT`/docs-root override for temp-dir drills.
- [x] `docs/testing.md` is declared in `spec/doc-spec-custom.md` as a generated human-doc; `doc-spec.sh --validate` + `--check-on-disk` green (declared, present, no orphan, no work-item IDs).
- [x] The rendered behaviors + categories + enrolled-topics indexes match the live merged registry (17 behaviors + 28 categories today) and track adds/removes.
- [x] `spec/test-spec.md` general seed is unchanged (seed-identity test green); a new `tests/test-spec.test.sh` drill (section 11, D1–D5) covers the render/idempotency/freshness and is green (`PASS: test-spec`).

## Todos

<!-- Actionable items for this story. -->

- [x] Add a `_render_testing_page` function to `scripts/test-spec.sh` composing the nine sections from the merged registry (reuses the parsed `$_BEHAVIORS` / `$_CATEGORIES` + `_parse_topic_contracts`).
- [x] Wire the render into BOTH the `--render-docs` write path (via `_render_into`) AND the `--render-docs --check` diff path (the forward diff picks up `docs/testing.md` automatically); emits to `docs/testing.md`, honoring the `TESTDOC_OUT`/docs-root override.
- [x] Declare `docs/testing.md` as a generated human-doc row in `spec/doc-spec-custom.md`; catalogs regenerated.
- [x] Add a `tests/test-spec.test.sh` drill (section 11, D1–D5): `docs/testing.md` renders, is deterministic/idempotent, indexes match `--list-behaviors`/`--list-categories`, `--render-docs --check` catches a hand-edit, ID-free. No new test FILE added (the drill lives in the already-registered `tests/test-spec.test.sh`), so no new `units:` row is required.
- [x] Verify: Check 26 (`--render-docs --check` findings=0), `doc-spec.sh --validate` + `--check-on-disk` FINDINGS=0, `spec/test-spec.md` seed byte-identical, `--validate`/`--check-coverage`/`--check-workflow-coverage`/`--check-topic-contract` all green, shellcheck clean. NOTE: the full `scripts/test.sh` was NOT run end-to-end here — this box renders a single `--render-docs` in ~107s (known slow-suite/OOM-flaky issue per repo memory), so verification used the targeted engines; the deferred full-suite run is an orchestrator/CI step.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Render `docs/testing.md` (the test-suite front door) from the merged test-spec registry, wired into both `--render-docs` paths and declared as a generated human-doc.
- 2026-07-06: Implemented. Added `_render_testing_page` (+ 3 index helpers) to `scripts/test-spec.sh`, wired into `_render_into`; declared `docs/testing.md` in `spec/doc-spec-custom.md`; added the section-11 drill to `tests/test-spec.test.sh`; regenerated catalogs. All targeted engine self-checks green (Check 26 findings=0, doc-spec FINDINGS=0, seed byte-identical, coverage/workflow/topic checks green, shellcheck clean). Phase 2 implementer-owned gates transitioned.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/test-spec.sh` (modified — added `_render_testing_page` + `_render_testing_behaviors`/`_render_testing_categories`/`_render_testing_topics` helpers; wired the page into `_render_into` so it renders on `--render-docs` and is diffed by `--render-docs --check`)
- `spec/doc-spec-custom.md` (modified — declared `docs/testing.md` as a generated human-doc row above `docs/test-catalog.md`)
- `docs/testing.md` (new — generated front-door output; do-not-edit banner + 9 sections)
- `tests/test-spec.test.sh` (modified — added section 11 render/idempotency/freshness/index-count/ID-free drill D1–D5)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Emitting `docs/testing.md` from the SAME `--render-docs` (+ `--render-docs --check`) path is what lets the existing `validate.sh` Check 26 cover it — no new check.
- Reuse the existing `--list-behaviors` / `--list-categories` / `topic_contracts` parsers rather than re-parsing the overlay, so the indexes track the registry automatically.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Wire the new render into both the write path and the `--render-docs --check` diff path. Summary: reusing Check 26's existing render→diff freshness gate is what guarantees the front door can't drift, without adding a new validate check.
- 2026-07-06 [impl-decision] Wired the page into `_render_into` (the shared write helper) rather than adding a parallel write path. The existing `--render-docs --check` forward diff walks every `*.md` under the rendered temp docs root, so `docs/testing.md` is picked up by Check 26 automatically — no change to the `--check` logic was needed. The reverse orphan sweep only scans `docs/tests/`, so the docs-root-level `testing.md` is never mis-flagged as a stale family page.
- 2026-07-06 [impl-decision] Reused the already-parsed `$_BEHAVIORS` / `$_CATEGORIES` (populated by `_run_registry_gates`) + a fresh `_parse_topic_contracts` for the three indexes, instead of shelling out to the `--list-*` subcommands. Same source of truth, one parse, so the indexes track registry adds/removes for free (17 behaviors + 28 categories + 6 enrolled topics today).
- 2026-07-06 [impl-decision] Approach A (hybrid): fixed narrative prose that LINKS to `docs/philosophy.md` §"Verification is a continuous gate" + `spec/test-spec.md` rather than duplicating them — avoids the second-copy drift this roadmap fights (per the SPEC tradeoff table).
- 2026-07-06 [impl-finding] `tests/test-spec.test.sh` is already a registered swept surface (its anchor is present in the overlay), and the drill adds sections to it rather than a NEW test file — so no new `units:` row / F000077 per-test doc was required. Every emitted cell is defensively `_mask_ids`-masked for symmetry with the catalog renderer, keeping the human-doc ID-free by construction (Check 19).
- 2026-07-06 [impl-finding] This box renders a single `--render-docs` in ~107s (the known slow-suite / OOM-flaky condition in repo memory), so the full `scripts/test.sh` was not run end-to-end here; verification used the targeted engines (Check 26 diff, doc-spec, seed-identity, coverage/workflow/topic checks, shellcheck) — all green. The full-suite run defers to the orchestrator / CI per the operator's fast-CI directive.
- 2026-07-06 [impl] Modified 3 files (`scripts/test-spec.sh` +~230 lines of render helpers; `spec/doc-spec-custom.md` +1 declaration row; `tests/test-spec.test.sh` +1 drill section) and added 1 generated file (`docs/testing.md`). Regenerated the test catalog + workflow docs (both in sync, findings=0).
- 2026-07-06 [impl-pass] S000137: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-07-06 [qa-smoke] S1–S5 GREEN (targeted engines, verified directly by the orchestrator): --render-docs writes docs/testing.md (9 sections + GENERATED/Check-26 header, deterministic/idempotent — byte-identical across two renders); --render-docs --check findings=0 AND catches a hand-edit (Check 26 covers the new file via the forward diff); --validate OK, --check-coverage rows=97 findings=0, --check-workflow-coverage 4/4, --check-topic-contract enrolled=6 findings=0; doc-spec.sh --validate OK + --check-on-disk FINDINGS=0 (declared, present, no orphan); grep -E "[FSTD][0-9]{6}" docs/testing.md = NONE (Check 19); seed byte-identity IDENTICAL. Behaviors index = 17 rows, category-test index = 28 rows (matches --list-behaviors/--list-categories; correctly includes F000084's goal-verb rows + excludes F000087's removed eval rows), enrolled-topics = 6.
- 2026-07-06 [qa-smoke] tests/test-spec.test.sh ran to completion → PASS: test-spec (no real FAIL). New section 11 (D1–D5) all green: D1 deterministic render, D2 nine sections + header, D3 index counts match, D4 --render-docs --check catches a hand-edit, D5 ID-free. Full scripts/test.sh deferred to CI (validate.yml; ~11min + OOM-flaky locally).
- 2026-07-06 [qa-pass] S000137: QA GREEN. Phase 2 QA-owned gates (Acceptance criteria / Smoke tests) transitioned; all 6 acceptance criteria met. E2E rows are manual reader-scenarios (N/A in autonomous build). Ready for pre-doc-sync commit + /ship.
