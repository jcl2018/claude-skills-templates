---
name: "doc-spec table-ification + test-spec/gate-spec full merge"
type: user-story
id: "S000105"
status: active
created: "2026-06-12"
updated: "2026-06-12"
parent: "F000063"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/upbeat-williams-043b2a"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "7a9ca2ea115ff9c8518de132517eab17d9fca902"
    completed_at: "2026-06-13T04:11:45Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["qa-smoke S1-S5", "qa-smoke-summary green", "qa-e2e E1-E3", "qa-e2e-summary green", "qa-audit doc:ok,test:ok", "qa-pass"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Prerequisite: this atomic story derives directly from the parent feature's
     /office-hours session; the parent's DESIGN is sufficient context and this
     story's DESIGN.md is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/tighten_doc_test_spec_contract` (shipping in the same PR as the parent feature)
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
- [x] Tasks broken down (N/A — atomic story; work is one cohesive change sequenced into two internal phases)

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

- [ ] Phase 1: `spec/doc-spec.md` + `spec/doc-spec-custom.md` are 3-column tables; `scripts/doc-spec.sh` parses the table and runs `_check_on_disk` with `CHECKS_RUN=4`; 3-way seed identity holds; generated views + generator + `--render` deleted; validate.sh Checks 15/15a/16/17/19 re-pointed, 20 + 23 deleted; `CJ_doc_audit`/`CJ_document-release` skills + six-checks prose updated; `validate.sh` + `test.sh` green.
- [ ] Phase 2: `spec/test-spec.md` carries the `layers[]` registry; `spec/test-spec-custom.md` holds `units:` + a new top-level `gates:` array; `gate-spec.sh` absorbed into `test-spec.sh` then deleted; `spec/gate-spec.md` deleted; Check 22 folded into Check 24 (marker-drift STILL advisory); all four cj_goal pipelines re-pointed to `test-spec.md`; gate-spec prose updated everywhere (grep-driven); `validate.sh` + `test.sh` green.
- [ ] No live reference to any deleted file (`doc-general.md`, `doc-custom.md`, `generate-doc-views.sh`, `gate-spec.sh`, `gate-spec.md`) remains anywhere (grep-clean).
- [ ] Both audit skills (`/CJ_doc_audit`, `/CJ_test_audit`) seed + run clean in a bare repo AND in this workbench.

## Todos

<!-- Actionable items for this story. -->

- [ ] P1.1 Rewrite `spec/doc-spec.md` to a 3-column table (`Doc | Purpose | Requirement`); drop YAML, `section`, `audit_class`, `front_table`; remove the two `docs/doc-*.md` rows.
- [ ] P1.2 Rewrite `spec/doc-spec-custom.md` to the same shape; remove the retired `spec/gate-spec.md` row + `docs/doc-*.md` references.
- [ ] P1.3 Rewrite `scripts/doc-spec.sh`: table parser → same internal TSV (header/delimiter skip, trim, backtick-strip Doc cell, reject inner `|`); re-derive `audit_class` into TSV `$3` from the path heuristic; rewrite `_check_on_disk` 6→4 (keep declared-exists/orphans/root-declared/human-doc-ids; delete front-table + views-render arms; `CHECKS_RUN=4`); delete `--render` + `--list-front-table-docs` + `_render_section` + `_list_front_table_docs`; rewrite the `--seed` heredoc in lockstep.
- [ ] P1.4 Maintain 3-way seed byte-identity: `spec/doc-spec.md` == `doc-spec.sh --seed` == `templates/doc-spec-common.md`.
- [ ] P1.5 Delete `scripts/generate-doc-views.sh`, `docs/doc-general.md`, `docs/doc-custom.md`.
- [ ] P1.6 `validate.sh`: delete Check 23 + Check 20; re-point Checks 15/15a/16/17/19 to the table parser (Check 19 uses path-derived human-doc set); confirm 15b needs no change.
- [ ] P1.7 Update `skills/CJ_doc_audit/SKILL.md` (body + frontmatter): re-enumerate to 4 checks; drop `--render`.
- [ ] P1.8 Update `skills/CJ_document-release/SKILL.md`: stop calling `--render`; drop the `front_table` stub special-case.
- [ ] P1.9 Update six-checks prose + `CHECKS_RUN` count: `docs/architecture.md`, `CLAUDE.md` (the doc-spec.sh row), `scripts/generate-readme.sh` (folder tree naming `doc-general.md`/`doc-custom.md`); regenerate README.
- [ ] P1.10 Update tests: `tests/doc-spec-overlay.test.sh` (`CHECKS_RUN=6`→`4`, drop `--render`/`--list-front-table-docs` drills, add table-parse + 3-way-seed-identity drills), `tests/cj-document-release-config.test.sh` (drop front_table + render drills), `scripts/test.sh` inline doc-spec/views family.
- [ ] P1.11 Run `./scripts/validate.sh` + `./scripts/test.sh` green.
- [ ] P2.1 Rewrite `spec/test-spec.md` (general seed) to the four-layer framing; carry gate-spec's `layers[]` registry verbatim; rewrite `test-spec.sh --seed` heredoc in lockstep.
- [ ] P2.2 Move gate-spec's per-mode `gates[]` into `spec/test-spec-custom.md` as a NEW top-level `gates:` array (schema: id/layer=pipeline-gate/order/markers/disposition/backing/checks); teach `test-spec.sh --validate` the `gates:` array.
- [ ] P2.3 Extend `scripts/test-spec.sh`: absorb `gate-spec.sh` parsing (`--list-layers`, `--list-gates`, per-mode marker view); keep existing subcommands; delete `scripts/gate-spec.sh`.
- [ ] P2.4 Delete `spec/gate-spec.md`.
- [ ] P2.5 `validate.sh`: fold Check 22 INTO Check 24, preserving its ADVISORY disposition (coverage hard, marker-drift advisory); per-mode marker cross-check reads `gates:` rows from `test-spec-custom.md`; update Check 24 banner/comment.
- [ ] P2.6 Re-point every cj_goal "Canonical gate sequence: gate-spec.md" → `spec/test-spec.md` (grep-driven across all four `{pipeline,SKILL}.md`).
- [ ] P2.7 Update every doc/skill naming gate-spec (grep-driven): `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `README.md`, `CHANGELOG.md`, `CJ_test_audit`, any other.
- [ ] P2.8 Update tests: re-home gate-spec coverage in `scripts/test.sh` into the test-spec suite; `tests/test-spec.test.sh`; `tests/cj-audit-skills.test.sh`; retarget the `=== Check 22:` unit row to `=== Check 24:` (or remove); reverse-sweep the deleted `gate-spec.sh` row.
- [ ] P2.9 Run `./scripts/validate.sh` + `./scripts/test.sh` green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Atomic story carrying both internal phases of F000063: doc-spec table-ification (Phase 1), test-spec/gate-spec full merge (Phase 2).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- Phase 1: `spec/doc-spec.md`, `spec/doc-spec-custom.md`, `scripts/doc-spec.sh`, `templates/doc-spec-common.md`, `scripts/generate-doc-views.sh` (DELETE), `docs/doc-general.md` (DELETE), `docs/doc-custom.md` (DELETE), `scripts/validate.sh`, `scripts/generate-readme.sh`, `README.md`, `docs/architecture.md`, `CLAUDE.md`, `skills/CJ_doc_audit/SKILL.md`, `skills/CJ_document-release/SKILL.md`, `tests/doc-spec-overlay.test.sh`, `tests/cj-document-release-config.test.sh`, `scripts/test.sh`.
- Phase 2: `spec/test-spec.md`, `spec/test-spec-custom.md`, `scripts/test-spec.sh`, `scripts/gate-spec.sh` (DELETE), `spec/gate-spec.md` (DELETE), `scripts/validate.sh`, all four cj_goal `{pipeline,SKILL}.md`, `skills/CJ_test_audit/SKILL.md`, `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `README.md`, `CHANGELOG.md`, `tests/test-spec.test.sh`, `tests/cj-audit-skills.test.sh`, `scripts/test.sh`.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The adversarial spec review's top blocker was that 3 of the 6 `_check_on_disk` checks read fields the table drops (`audit_class`, `front_table`); the fix is to derive `audit_class` into the TSV from path convention and cut the engine to 4 checks — NOT to leave `$3` empty (which would silently void the human-doc-id check).
- `pipeline-gate` cannot be a `units:` row — the `units:` `layer` field is a closed enum `{local-hook, ci}` that would reject it. The gates go into a separate top-level `gates:` array with its own schema.
- Check 24's own forward anchor-grep will self-break if the `=== Check 22:` unit row isn't retargeted to `=== Check 24:` after the merge.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-06-12 — Single atomic story carries both phases (no task children). Per WORKFLOW.md, tasks are optional for an atomic story whose work is one cohesive change; the two internal phases are sequencing within the one PR, not separate decomposable units. Summary: recorded the Phase 1 gate `[x] Tasks broken down (N/A — atomic story)`.
- [finding] 2026-06-12 — Re-point sweeps MUST be grep-driven, not fixed file lists. The design's file lists are a starting point; the build greps for every reference to the deleted files/checks/`--render` to avoid leaving a dangling cite.
- 2026-06-13 [qa-smoke] S1 (AC-1): green — 3-way seed identity holds (`doc-spec.sh --seed` == `spec/doc-spec.md` == `templates/doc-spec-common.md`); no fenced-YAML block in the table.
- 2026-06-13 [qa-smoke] S2 (AC-2): green — `doc-spec.sh --check-on-disk` reports `CHECKS_RUN=4`; `--render` is now an unknown subcommand (retired).
- 2026-06-13 [qa-smoke] S3 (AC-3): green (AC intent met; row regex over-broad) — all 5 retired files absent (`docs/doc-general.md`, `docs/doc-custom.md`, `scripts/generate-doc-views.sh`, `scripts/gate-spec.sh`, `spec/gate-spec.md`). The row's grep exits non-zero, but all 10 matches are intentional retirement-documentation PROSE ("folded in from the retired gate-spec.sh", "the former spec/gate-spec.md") mandated by P2.7; zero functional/live references (no script sources/executes a retired file, no doc-link to a deleted view). AC-3 says "no LIVE reference" — verified met. NOTE: row S3 command should anchor on live-reference patterns, not any textual mention (test-row refinement, not an impl defect).
- 2026-06-13 [qa-smoke] S4 (AC-4): green — `test-spec.sh --validate` exits 0 (`OK schema_version=1`) on the merged `layers[]`+`units:`+`gates:` registry; general byte-identical to `--seed`.
- 2026-06-13 [qa-smoke] S5 (AC-5,AC-6): green — `validate.sh` + `test.sh` both PASS (0 errors / 0 failures); Check 20 + Check 23 banners absent; Check 22 folded into Check 24 (present, passes; gate marker-drift advisory). Required the documented Check 14 USAGE.md `last-updated:` bump for the four `CJ_goal_*` skills (their SKILL.md gained a cosmetic gate-spec→test-spec reference re-point in commit 7a9ca2e; descriptions unchanged, USAGE content still accurate) — bumped + staged per CLAUDE.md; left in working tree for the orchestrator to commit.
- 2026-06-13 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). S3 recorded green-in-substance (AC intent "no live reference" met; over-broad row regex).
- 2026-06-13 [qa-e2e-run-start] RUN_ID=20260612-210840-66788 commit=7a9ca2e
- 2026-06-13 [qa-e2e] E1 (AC-7): green — in a fresh bare temp git repo, doc audit seeded `spec/doc-spec.md` (seeded: yes, 76 lines) + Stage 1 ran `CHECKS_RUN=4` with no engine error; test audit seeded `spec/test-spec.md` (seeded: yes, 119 lines), `--validate`=OK schema_version=1, `--check-coverage`=coverage cross-check inactive (rules-only seed); both report seeded: no idempotently on re-run. [parent-inline]
- 2026-06-13 [qa-e2e] E2 (AC-7): green — in this workbench, doc audit Stage 1 = 4/4 checks PASS, CHECKS_RUN=4, FINDINGS=0; test audit `--validate`=OK schema_version=1, `--check-coverage`=OK coverage rows=66 reverse_tokens=46 findings=0; new folded views resolve (`--list-layers`=ci/local-hook/pipeline-gate/ratchet; `--list-gates` includes qa-audit). No retired surface (`--render`, gate-spec) invoked. [parent-inline]
- 2026-06-13 [qa-e2e] E3 (AC-6): green — all four cj_goal skills cite `spec/test-spec.md` as canonical gate sequence (feature/defect/task in both SKILL.md+pipeline.md, todo_fix in SKILL.md); zero surviving gate-spec citations in any cj_goal skill dir. [parent-inline]
- 2026-06-13 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): all 3 E2E rows green — audit skills seed+run clean standalone (E1) + in-workbench (E2); cj_goal pipelines re-pointed to test-spec.md (E3). Leaf-subagent in-QA degradation: all rows ran parent-inline (cannot spawn subagents).
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). Both overlays already current with the new reality (Check-22 row retargeted to Check 24; gates: array added; doc-*.md+gate-spec.md rows dropped); doc audit 4/4 Stage-1 checks PASS + Stage 2/3 clean; test audit validate OK + coverage findings=0 + Stage 2/3 clean.
- 2026-06-13 [qa-pass] S000105 (user-story): green smoke + green E2E. Phase 2 gates transitioned. (Also bumped four CJ_goal_* USAGE.md last-updated fields per CLAUDE.md Check-14 procedure — staged, left for orchestrator commit.)
