---
name: "Tighten the doc-spec & test-spec contract format (table-as-source + gate-spec merge)"
type: feature
id: "F000063"
status: active
created: "2026-06-12"
updated: "2026-06-12"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/upbeat-williams-043b2a"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/tighten_doc_test_spec_contract`
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

- [ ] `spec/doc-spec.md` is a 3-column markdown table parsed directly; no YAML block, no `section`/`audit_class`/`front_table`; byte-identical to `doc-spec.sh --seed` AND `templates/doc-spec-common.md` (3-way identity).
- [ ] `spec/doc-spec-custom.md` uses the same table shape and only extends.
- [ ] `docs/doc-general.md`, `docs/doc-custom.md`, `scripts/generate-doc-views.sh`, `scripts/gate-spec.sh`, `spec/gate-spec.md` are all deleted; no live reference to any of them remains (grep-clean across scripts/skills/docs/tests).
- [ ] `doc-spec.sh --check-on-disk` runs 4 checks (`CHECKS_RUN=4`), human-doc-ids still works via the path-derived `audit_class`; `--render` / `--list-front-table-docs` removed.
- [ ] `spec/test-spec.md` answers kinds/what/when in the four-layer framing (carries the `layers[]` registry); `spec/test-spec-custom.md` holds the `units:` rows + a new top-level `gates:` array (per-mode pipeline-gate rows) that `test-spec.sh --validate` accepts.
- [ ] Check 19 (no work-item IDs in human-docs) still passes via the path heuristic; Checks 20 + 23 are gone; Check 22 folded into Check 24 with its marker-drift portion STILL ADVISORY (no silent promotion to hard-fail).
- [ ] All four cj_goal pipelines cite `test-spec.md` as the canonical gate sequence.
- [ ] `CJ_doc_audit` re-enumerates the 4 checks; both audit skills still seed + run clean in a bare repo AND in this workbench.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` are green.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Phase 1 (S000105): doc-spec table-ification — rewrite `spec/doc-spec.md` + `spec/doc-spec-custom.md` to 3-column table; rewrite `scripts/doc-spec.sh` parser + `_check_on_disk` engine (6→4 checks); maintain 3-way seed identity; delete generated views + `generate-doc-views.sh`; re-point validate.sh Checks 15/15a/16/17/19, delete 20 + 23; update `CJ_doc_audit`/`CJ_document-release` skills + six-checks prose; verify suite green.
- [ ] Phase 2 (S000105): test-spec/gate-spec full merge — fold gate-spec `layers[]` into general `test-spec.md`, `gates[]` into `test-spec-custom.md` as a new top-level `gates:` array; absorb `gate-spec.sh` into `test-spec.sh` then delete it; delete `spec/gate-spec.md`; fold Check 22 into Check 24 (keep marker-drift advisory); re-point all four cj_goal pipelines + gate-spec prose (grep-driven); verify suite green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Tighten the doc-spec & test-spec contract format to table-as-source, and merge gate-spec into the test-spec family. Single feature, two internal phases (Approach B), one PR.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/doc-spec.md`, `spec/doc-spec-custom.md`, `spec/test-spec.md`, `spec/test-spec-custom.md`, `spec/gate-spec.md` (DELETE)
- `scripts/doc-spec.sh`, `scripts/test-spec.sh`, `scripts/gate-spec.sh` (DELETE), `scripts/generate-doc-views.sh` (DELETE), `scripts/generate-readme.sh`, `scripts/validate.sh`, `scripts/test.sh`
- `templates/doc-spec-common.md`
- `docs/doc-general.md` (DELETE), `docs/doc-custom.md` (DELETE), `docs/architecture.md`, `docs/philosophy.md`
- `skills/CJ_doc_audit/SKILL.md`, `skills/CJ_document-release/SKILL.md`, `skills/CJ_test_audit/SKILL.md`, all four cj_goal `{pipeline,SKILL}.md`
- `CLAUDE.md`, `README.md`, `CHANGELOG.md`
- `tests/doc-spec-overlay.test.sh`, `tests/cj-document-release-config.test.sh`, `tests/test-spec.test.sh`, `tests/cj-audit-skills.test.sh`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The spec file stops being "prose + a YAML registry + a generated view of the registry" (three representations of one list) and becomes one markdown table that IS the source of truth — a human reads it, the parser reads it, there is no second copy to drift.
- The verification story collapses from two files (test-spec = abstract rules, gate-spec = layers/when) into one test-spec family that answers the real operator question end to end. The operator trusted the representation that already worked (gate-spec's four-layer map) over the abstract-rules one — reversing a recent deliberate F000060 split.
- The operator picked the maximal-simplification option on both forks (full merge + minimal 3-column) without hedging: the spec files are "the clean interface", optimized for the seed-into-an-arbitrary-repo case, not just this workbench's convenience.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-12 — Consolidation scope: FULL MERGE, retire gate-spec (D1). gate-spec.md's four-layer map folds into general `test-spec.md`; per-mode pipeline-gate `gates[]` fold into `test-spec-custom.md`; `gate-spec.sh` folds into `test-spec.sh`; Check 22 merges into Check 24; all four cj_goal pipelines re-point. The `test-spec` name is KEPT (renaming would roughly double blast radius); broadened meaning stated in prose. Summary: chose the unified "verification contract" framing over test-vs-process-gate purity.
- [decision] 2026-06-12 — doc-spec format: TABLE-AS-SOURCE, 3 columns (D2). The markdown table `| Doc | Purpose | Requirement |` becomes the parsed source of truth; fenced-YAML block + generated views deleted; `doc-spec-custom.md` uses the identical table shape. Summary: one artifact, not three.
- [decision] 2026-06-12 — Dropped structured fields, derived consequences (D3). `section` dropped (file declares the tier); `audit_class` dropped from the table BUT Check 19 survives by deriving "human-doc" from path convention (under `docs/` or root `README.md`); `front_table` dropped and Check 20 retired (most cosmetic / workbench-specific lint, no clean 3-column home).
- [decision] 2026-06-12 — Sequencing: ONE PR, internally sequenced (D4 / Approach B). doc-spec table-ification verified green first, then the test-spec/gate-spec merge verified green, same work-item/PR. De-risks the table-parser rewrite + Check 22→24 merge + four pipeline re-points landing together.
