---
name: "Generated docs/tests/ catalog + freshness primitive"
type: user-story
id: "S000114"
status: active
created: "2026-06-28"
updated: "2026-06-28"
parent: "F000069"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/amazing-nightingale-7ffdd3"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "a731e295a51705e3501796ce3bcb8ca29f3fdf87"
    completed_at: "2026-06-29T04:05:43Z"
    test_rows_run: 9
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-smoke-summary] green 5/5", "[qa-e2e] E1-E4 green", "[qa-e2e-summary] green", "[qa-audit] AUDITS=deferred", "[qa-pass] green smoke + green E2E"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Story 1 of the F000069 epic. Buildable + fully-specified this pass.
     Design context: F000069_DESIGN.md + the parent's /office-hours design doc
     (~/.gstack/projects/jcl2018-claude-skills-templates/audit-tightening-design-20260628-200601.md, Part 1 / U1). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/gen_tests_catalog_freshness` (shipping in the F000069 branch / PR)
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

- [ ] `scripts/test-spec.sh --render-docs` renders one `docs/tests/<family>.md` per unit family (validate, test, ci, hook, windows-smoke, test-deploy, eval) + `docs/test-catalog.md` (index grouped by family with counts), from the MERGED test-spec registry's rendered fields only.
- [ ] Output is deterministic (stable sort, fixed headers) and work-item-ID-free.
- [ ] `scripts/test-spec.sh --render-docs --check` renders to a temp dir, diffs vs on-disk, exits non-zero on any mismatch/missing file and 0 when fresh.
- [ ] The generated `docs/tests/*.md` + `docs/test-catalog.md` are committed.
- [ ] `scripts/validate.sh` Check 26 (freshness) regenerates to a temp + diffs vs on-disk; any mismatch is a hard ERROR.
- [ ] `scripts/test.sh` has the matching integration-fixture assertion for Check 26 (same story).
- [ ] `spec/doc-spec-custom.md` declares `docs/test-catalog.md` + the `docs/tests/*.md` set as generated human-docs (no work-item IDs).
- [ ] `spec/test-spec-custom.md` has units rows for the new test(s) so Check 24 reverse-sweep resolves them.
- [ ] `skills/CJ_test_audit/SKILL.md` Stage 1 runs `--render-docs --check`; Stage 3 recognizes `docs/tests/` as a generated surface (no false orphan/uncontemplated finding).
- [ ] `tests/test-spec-render.test.sh` asserts `--render-docs` is stable, ID-free, and `--check` passes on fresh / fails on a hand-edited catalog.

## Todos

- [x] Add `--render-docs` (+ `--render-docs --check`) to `scripts/test-spec.sh`.
- [x] Generate `docs/test-catalog.md` and `docs/tests/<family>.md` (committed by the orchestrator).
- [x] Add `validate.sh` Check 26 + the parallel `scripts/test.sh` integration fixture.
- [x] Declare the generated docs in `spec/doc-spec-custom.md`; add new units rows in `spec/test-spec-custom.md`.
- [x] Wire `/CJ_test_audit` Stage 1 freshness + Stage 3 generated-surface recognition.
- [x] Author `tests/test-spec-render.test.sh`.

## Log

- 2026-06-28: Created. Generated docs/tests/ catalog (rendered from the merged test-spec registry) + the reusable freshness primitive (Check 26 + audit Stage-1 enforcement).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Implement. -->

- `scripts/test-spec.sh` — new `--render-docs` / `--render-docs --check` subcommand (renderer + freshness primitive; ID-masking of anchors)
- `scripts/validate.sh` — new Check 26 (mirror of Check 25) + the `docs/tests` orphan-doc-dir skip
- `scripts/test.sh` — Check 26 integration fixture (positive + negative drift), the new test runner block, and the docs/test-catalog.md backup in the EXIT trap
- `docs/test-catalog.md`, `docs/tests/*.md` — NEW generated surfaces (7 family pages + index)
- `spec/doc-spec-custom.md` — declared the 8 generated docs as human-docs
- `spec/test-spec-custom.md` — `validate-check-26` + `test-test-spec-render` units rows
- `skills/CJ_test_audit/SKILL.md` + `USAGE.md` — Stage 1 render-freshness + Stage 3 generated-surface recognition; frontmatter description updated
- `skills-catalog.json` — CJ_test_audit description synced to the new frontmatter
- `README.md` — regenerated (catalog-derived)
- `tests/test-spec-render.test.sh` — NEW hermetic test

## Insights

- The generated docs satisfy Check 19 (no work-item IDs in human-docs) BY CONSTRUCTION because the renderer emits only rendered fields, which the existing rendered-field lint already keeps ID-free. The `anchor` must be shown as a code reference (path:line), never as a rendered claim.
- The freshness diff must be byte-stable: a stable sort + fixed headers + a single deterministic emit order. Any non-determinism (hash-ordered map iteration, locale-dependent sort) would make Check 26 flap.

## Journal

- [decision] 2026-06-28 — Render ONLY rendered fields; show the anchor as a code reference. Summary: rendered fields are already ID-free by the existing lint, so the human-docs pass Check 19 by construction; rendering the anchor as a claim would risk leaking work-item IDs and is semantically a source pointer, not a human claim.
- [decision] 2026-06-28 — `--render-docs --check` is the freshness primitive both Check 26 AND `/CJ_test_audit` Stage 1 invoke. Summary: one engine entry point owns the regenerate→diff logic, so the workbench check and the portable standalone audit agree by construction (no second copy of the diff logic).
- [impl-decision] 2026-06-28 — Mask work-item IDs in the rendered anchor. Summary: the SPEC promised "ID-free by construction" via the rendered-field lint, but that lint only covers label/purpose; many anchors are inline test-banner strings that embed `[FSTD]NNNNNN` (e.g. `=== F000026: ... ===`). Check 19 greps the WHOLE human-doc (inline code included), so an unmasked anchor would hard-fail it. Resolution: the anchor is a source POINTER, not a human claim — `_mask_ids` replaces each ID token with `[id]` in the rendered ref, keeping the catalog ID-free by construction (Check 19 green: 19 human-docs scanned, 0 hits) while still pointing the reader at the right source line.
- [impl-decision] 2026-06-28 — Determinism via fixed sort + `TESTDOC_OUT` override. Summary: families emit in `LC_ALL=C sort -u` order; rows sort by unit id; fixed headers, generated banner, no timestamps — a render→render diff is byte-stable (verified by tests/test-spec-render.test.sh T1). `--check` renders into a temp dir via `TESTDOC_OUT` and diffs vs on-disk (forward: missing/stale; reverse: orphan family page), so it never mutates the committed tree.
- [impl] 2026-06-28 — Closed the recurring blind spot (F000032/34/35): the new validate.sh Check 26 got its PARALLEL `scripts/test.sh` integration fixture in the SAME pass (Step 3e: positive PASS detection + negative drift-fires-ERROR + regenerate-green), plus the new `tests/test-spec-render.test.sh` wired into the hand-wired runner and registered as a `units:` row so Check 24's reverse sweep resolves it.
- [impl-pass] 2026-06-28 — Self-verification green: `test-spec.sh --render-docs --check` exit 0; `--validate` exit 0; `validate.sh` 0 errors / 0 warnings (Checks 19/24/25/26 all PASS); `tests/test-spec-render.test.sh` RESULT: PASS; the Check-26 fixture in `scripts/test.sh` passes positive + negative + regenerate.
- 2026-06-28 [qa-smoke] S1 (AC-1): green — `--render-docs` wrote 7 family pages + docs/test-catalog.md; render is idempotent (empty git diff).
- 2026-06-28 [qa-smoke] S2 (AC-2): green — tests/test-spec-render.test.sh RESULT: PASS (deterministic byte-identical render + ID-free + check pass/fail asserts).
- 2026-06-28 [qa-smoke] S3 (AC-3): green — `--render-docs --check` exit 0 (generated catalog in sync with the registry, findings=0).
- 2026-06-28 [qa-smoke] S4 (AC-4): green — validate.sh Check 26 PASS (0 errors/0 warnings); scripts/test.sh carries the parallel Check-26 fixture (positive + negative drift + regenerate, lines 611-646).
- 2026-06-28 [qa-smoke] S5 (AC-5,AC-6): green — doc-spec.sh --check-on-disk 5/5 PASS (generated docs declared, no orphans, ID-free); test-spec.sh --validate + --check-coverage 0 findings (units rows resolve).
- 2026-06-28 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-28 [qa-e2e-run-start] RUN_ID=20260628-205454-19459 commit=a731e29
- 2026-06-28 [qa-e2e] E1 (AC-1,AC-2): green — `--render-docs` wrote docs/test-catalog.md (index lists all 7 families w/ counts + links) + docs/tests/<family>.md pages (label/purpose/layer/disposition/trigger + source·anchor code ref); ID-free (no [FSTD]NNNNNN matches) and a second render is a byte-identical no-op diff.
- 2026-06-28 [qa-e2e] E2 (AC-3,AC-4): green — hand-edited docs/test-catalog.md (hook count 2→999): `--render-docs --check` exit 1 + validate.sh Check 26 ERROR, both naming docs/test-catalog.md (see scripts/validate.sh Check 26 output line "the generated test catalog is stale"); after regenerate both pass (check exit 0, Check 26 PASS). Tree restored clean (matches original render).
- 2026-06-28 [qa-e2e] E3 (AC-6): green — Stage-1 freshness engine (`test-spec.sh --render-docs --check`) catches drift (E2) + clean-when-fresh (exit 0); skills/CJ_test_audit/SKILL.md:203-222 wires it into Stage 1 and SKILL.md:351-358 instructs Stage 3 to NOT flag docs/tests/ as orphan/uncontemplated (generated surface). doc-spec.sh --check-on-disk exit 0, orphans check PASS, FINDINGS=0 — docs/tests not flagged. Executed Stage-1 inline per constraint (no subagent dispatch).
- 2026-06-28 [qa-e2e] E4 (AC-7): green — `scripts/test.sh` RESULT: PASS (Failures: 0), incl. tests/test-spec-render.test.sh (stability/ID-free/--check pass-on-fresh+fail-on-edit, all OK) + the parallel Check-26 fixture (positive PASS + negative drift ERROR + regenerate-green, see /tmp test_full.out lines 1185-1187,1380).
- 2026-06-28 [qa-e2e-summary] green (subagent: 4 rows E1-E4; 0 rows parent-inline; 0 deferred): All 4 E2E criteria green; live tree left clean (Check 26 green).
- 2026-06-28 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom changed (units: validate-check-26, test-test-spec-render),doc-spec-custom changed (8 generated docs: docs/test-catalog.md + docs/tests/*.md) (Step 8.6a/8.6b ran inline — overlays already current for this story; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-28 [qa-pass] S000114 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
- 2026-06-28 [qa-e2e-summary] green: 4/4 E2E rows green (E1,E2,E3,E4); live docs/ tree clean + Check 26 green at finish.
