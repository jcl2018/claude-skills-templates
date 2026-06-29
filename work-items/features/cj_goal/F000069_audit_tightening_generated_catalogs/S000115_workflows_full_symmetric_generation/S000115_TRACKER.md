---
name: "Workflows full symmetric generation"
type: user-story
id: "S000115"
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
    commit: "4a8fa122bdd6b9b42c6ba6512f060615ee54a82d"
    completed_at: "2026-06-28T23:58:00Z"
    test_rows_run: 11
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6", "AC-7", "AC-8", "AC-9", "AC-10"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S6 green", "[qa-e2e] E1-E5 green", "[qa-e2e-summary] green", "[qa-audit] AUDITS=deferred", "[qa-pass]"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Story 2 of the F000069 epic. Buildable + fully-specified this pass.
     Design context: F000069_DESIGN.md + the parent's /office-hours design doc
     (Part 2) and the Story-2 design doc
     (~/.gstack/projects/jcl2018-claude-skills-templates/workflows-gen-design-20260628-225608.md).
     Third instance of Story 1's generate→freshness→audit primitive — applied
     to the workflow docs (docs/workflow.md index + docs/workflows/*.md). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/workflows_full_symmetric_generation` (shipping in the F000069 branch / PR)
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

- [x] NEW `spec/workflow-spec.md` — a bash-parseable structured-Markdown registry (one `## <name>` section per workflow) with two entry shapes: **orchestrator** (the 4 `CJ_goal_*`: feature, task, defect, todo_fix — key block + a verbatim fenced `chart` block + the four Touches axes [skills, steps, scripts, docs] + an "In words" summary block) and **roster** (the 2: utilities-and-phase-steps, utility-audits — `kind: roster` + a verbatim `body` block), plus a registry header block holding the `docs/workflow.md` index prose preamble. The 6 existing `docs/workflows/*.md` bodies + the `docs/workflow.md` intro are migrated INTO this registry.
- [x] NEW `scripts/workflow-spec.sh` engine (bash; mirrors `doc-spec.sh`/`test-spec.sh` engine-resolution + `git rev-parse --show-toplevel` registry resolve + `REPO_ROOT`/`WORKFLOW_SPEC_PATH` env overrides) with `--validate` (per-kind required fields + closed `kind` enum + registry-completeness: every routable `CJ_goal_*` skill has an orchestrator entry — the no-vanish guarantee; emits `[workflow-spec-no-config]` on present-but-invalid), `--list-workflows`, `--render-docs`, `--render-docs --check`, `--classify`, and `--seed`.
- [x] All 6 `docs/workflows/*.md` + `docs/workflow.md` are regenerated from the registry (one-time normalized reformat). Charts + roster bodies + the index preamble reproduced verbatim; only structural whitespace/ordering may shift. Output is work-item-ID-free (Check 19 green).
- [x] `scripts/validate.sh` Check 27: regenerate→diff freshness gate (`workflow-spec.sh --render-docs --check`); hard ERROR on mismatch; registry-gated (skip when no `spec/workflow-spec.md`); mirrors Check 26's structure/exit semantics. Checks 15b + 15c are RETIRED (their no-vanish intent folded into `--validate` registry-completeness + Check 27; a one-line pointer comment left at the old 15b/15c site).
- [x] `scripts/test.sh` has the PARALLEL Check-27 integration fixture (positive PASS + negative drift-fires-ERROR + regenerate-green), mirroring the Check-26 fixture — the recurring new-check-without-a-test.sh-fixture blind spot, closed in the SAME story.
- [x] `skills/CJ_doc_audit/SKILL.md`: Stage 1 also runs `workflow-spec.sh --render-docs --check`; Stage 3 recognizes `docs/workflow.md` + `docs/workflows/` as a GENERATED surface (sourced from `spec/workflow-spec.md`), never an orphan/drift.
- [x] `spec/doc-spec-custom.md` declares `spec/workflow-spec.md` (operational registry doc); `docs/workflow.md` + `docs/workflows/*.md` stay declared human-docs (now generated).
- [x] `spec/test-spec-custom.md` has units rows for the new test(s) (validate Check 27 + the workflow-spec-render test) so Check 24 reverse-sweep resolves them.
- [x] NEW `tests/workflow-spec-render.test.sh` (hermetic; mirrors `tests/test-spec-render.test.sh`): `--render-docs` deterministic + ID-free, `--check` pass-on-fresh / fail-on-edit / fail-on-missing, AND a remove-an-entry drill proving `--validate` registry-completeness fails closed (the no-vanish replacement for retired Check 15c).

## Todos

- [x] Author `spec/workflow-spec.md`: registry header (index preamble) + 4 orchestrator sections (verbatim charts + 4 Touches axes + "In words") + 2 roster sections (verbatim bodies); migrate the 6 doc bodies + the index intro.
- [x] Build `scripts/workflow-spec.sh` (`--validate` incl. registry-completeness, `--list-workflows`, `--render-docs`, `--render-docs --check`, `--classify`, `--seed`).
- [x] Regenerate all 6 `docs/workflows/*.md` + `docs/workflow.md` from the registry (one-time normalized reformat; charts/rosters/preamble verbatim; ID-free).
- [x] Add `validate.sh` Check 27 + RETIRE 15b/15c (leave a pointer comment) + the parallel `scripts/test.sh` Check-27 integration fixture.
- [x] Wire `/CJ_doc_audit` Stage 1 (workflow freshness) + Stage 3 (generated-surface recognition).
- [x] Declare `spec/workflow-spec.md` in `spec/doc-spec-custom.md`; add units rows in `spec/test-spec-custom.md`.
- [x] Author `tests/workflow-spec-render.test.sh` (determinism, ID-free, `--check` pass/fail-on-edit/fail-on-missing, remove-an-entry registry-completeness drill).

## Log

- 2026-06-28: Created. Workflows full symmetric generation — `spec/workflow-spec.md` registry + `scripts/workflow-spec.sh` engine + `validate.sh` Check 27 freshness gate (15b/15c retired, folded into `--validate` registry-completeness + Check 27) + `/CJ_doc_audit` Stage-1 freshness / Stage-3 generated-surface recognition. Third instance of Story 1's generate→freshness→audit primitive.
- 2026-06-28: [impl] Built the registry + engine + freshness gate + retirement, all in one pass. NEW `spec/workflow-spec.md` (header + 4 orchestrator + 2 roster sections; the 6 doc bodies + index intro migrated VERBATIM — charts byte-identical to originals, confirmed). NEW `scripts/workflow-spec.sh` (four-backtick-fence parser; `--validate`/`--list-workflows`/`--render-docs [--check]`/`--classify`/`--seed`; `git rev-parse` resolve + `REPO_ROOT`/`WORKFLOW_SPEC_PATH`/`WORKFLOWDOC_OUT` overrides; shellcheck-clean). Regenerated all 7 docs (one-time normalized reformat: added the do-not-edit banner + un-wrapped the single-line key fields; charts/rosters/preamble verbatim; ID-free). `validate.sh` Check 27 (regenerate→diff, registry-gated, mirror of Check 26); Checks 15b+15c RETIRED with a pointer comment; the stale 15a/15b/15c comment refs + the line-227 selector comment updated.
- 2026-06-28: [impl] Cross-cutting edits the 15b/15c retirement required: `scripts/test.sh` — removed the Check-15b 4-anchored-bullets structural fixture (now covered by the renderer + Check 27); `spec/test-spec-custom.md` — the validate-check-15 purpose + the row-granularity prose now describe ONLY 15a. NEW Check-27 test.sh fixture (Step 3f: positive PASS + negative drift-fires + regenerate-green) + the EXIT-trap backup of docs/workflow.md. NEW `tests/workflow-spec-render.test.sh` (hermetic; T1 determinism, T2 ID-free, T3/T4 --check pass/fail-on-edit/fail-on-missing, T5 live-tree freshness, T6 the no-vanish remove-an-entry drill — proves `--validate` fails closed), wired into test.sh. Units rows added: validate-check-27 + test-workflow-spec-render (Check 24 reverse-sweep resolves both). `spec/doc-spec-custom.md` declares `spec/workflow-spec.md` + the 6 workflow rows reframed as generated. `/CJ_doc_audit` SKILL.md (+USAGE.md, +catalog desc synced): Stage-1 Step 3b runs `workflow-spec.sh --render-docs --check`; Stage-3 recognizes the generated surface. README regenerated. Self-verify: validate.sh 0 errors; workflow-spec --validate + --render-docs --check exit 0; test-spec --validate + --check-coverage green; tests/workflow-spec-render.test.sh PASS (incl. the drill); doc-spec --check-on-disk 0 findings.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Implement. -->

- `spec/workflow-spec.md` — NEW registry (header + 4 orchestrator + 2 roster sections); the 6 `docs/workflows/*.md` bodies + the `docs/workflow.md` index preamble migrated in verbatim
- `scripts/workflow-spec.sh` — NEW engine (`--validate`/`--list-workflows`/`--classify`/`--seed`/`--render-docs` + `--render-docs --check`)
- `docs/workflows/*.md` (×6) + `docs/workflow.md` — regenerated from the registry (one-time normalized reformat, reviewed in the PR)
- `scripts/validate.sh` — NEW Check 27 (workflow-docs freshness); RETIRE Checks 15b/15c (pointer comment at the old site); updated the stale 15a/15b/15c + line-227 selector comments
- `scripts/test.sh` — NEW Check-27 integration fixture (positive + negative drift + regenerate-green, mirror of the Check-26 fixture) + the docs/workflow.md EXIT-trap backup; REMOVED the retired Check-15b 4-anchored-bullets structural fixture; wired the new test runner
- `tests/workflow-spec-render.test.sh` — NEW hermetic test (determinism, ID-free, `--check` pass/fail-on-edit/fail-on-missing, the no-vanish remove-an-entry `--validate` drill)
- `spec/doc-spec-custom.md` — declared `spec/workflow-spec.md` (operational); reframed the 6 workflow-doc rows as generated (Check 27)
- `spec/test-spec-custom.md` — NEW units rows validate-check-27 + test-workflow-spec-render; validate-check-15 purpose + the row-granularity prose now describe only 15a
- `skills/CJ_doc_audit/SKILL.md` (+ `USAGE.md`) — Stage-1 Step 3b workflow-render freshness check; Stage-3 generated-surface recognition; frontmatter description synced to `skills-catalog.json`
- `skills-catalog.json` — CJ_doc_audit description synced to the SKILL.md frontmatter
- `README.md` — regenerated from the catalog (`generate-readme.sh`)
- `skills/CJ_doc_audit/SKILL.md` (+ USAGE.md if drift) — Stage-1 workflow freshness + Stage-3 generated-surface recognition
- `spec/doc-spec-custom.md` — declare `spec/workflow-spec.md` (operational registry doc)
- `spec/test-spec-custom.md` — units rows for the new test(s) (Check 27 + workflow-spec-render)
- `tests/workflow-spec-render.test.sh` — NEW hermetic test
- `docs/architecture.md` / `CLAUDE.md` — document the workflow-spec registry + Check 27 + the 15b/15c retirement (doc-sync folds these)

## Insights

<!-- Non-obvious findings worth remembering. -->

- This is the THIRD instance of the generate→freshness→audit primitive (after `README.md` ↔ `generate-readme.sh` ↔ Check 25, and Story 1's test catalog ↔ `test-spec.sh --render-docs` ↔ Check 26). The shape is proven; the novel work is the TWO-entry-shape registry (orchestrator vs roster) and reproducing the verbatim ASCII charts + roster prose + index preamble through a normalized template.
- Retiring Checks 15b/15c does NOT weaken the no-vanish guarantee — it STRENGTHENS it. 15c was an index-link grep; the replacement (`workflow-spec.sh --validate` registry-completeness: every routable `CJ_goal_*` has an orchestrator entry) asserts presence in the source of truth, and Check 27 freshness means a generated doc can't be missing its chart/Touches and the generated index can't drop a link. The remove-an-entry drill in the hermetic test proves `--validate` fails closed.
- A new `validate.sh` check ALWAYS needs the parallel `scripts/test.sh` zzz-test-scaffold integration fixture — the recurring implement-subagent blind spot (F000032/F000034/F000035 all hit it; Story 1 pinned it for Check 26). This story pins it as a P0 requirement + a TEST-SPEC row for Check 27 so it isn't dropped.
- The one-time normalized regeneration WILL produce a non-trivial diff against the current hand-authored 6 docs + index — this is expected and reviewed in the PR, not a regression. The charts + roster prose + index preamble must be reproduced VERBATIM; only structural whitespace/ordering may shift.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-28 — All 6 docs + index, truly symmetric (operator chose). Summary: the registry carries TWO entry shapes — orchestrator (structured: chart + 4 Touches axes + summary) for the 4 `CJ_goal_*`, roster (free-form verbatim body) for the 2 prose docs — so generation owns the ENTIRE workflow surface, not just the orchestrator pages.
- [decision] 2026-06-28 — Normalized template, one-time reviewed reformat (operator chose). Summary: charts + roster bodies + the index preamble are stored + emitted verbatim, but structural bits (headers, Touches ordering, whitespace) may reformat; migrating the 6 docs + regenerating produces a ONE-TIME diff reviewed in this PR — NOT a strict byte round-trip.
- [decision] 2026-06-28 — Retire Checks 15b/15c; fold their no-vanish intent into `--validate` registry-completeness + Check 27 freshness. Summary: 15b/15c only assert SHAPE, not truth/freshness; the generated model makes the docs un-rottable and the completeness check is a stronger no-vanish guarantee than 15c's index-link grep. A remove-an-entry drill in the hermetic test proves `--validate` fails closed (the 15c replacement).
- [decision] 2026-06-28 — Store the `docs/workflow.md` prose preamble as a registry header block. Summary: the index file has a prose intro above the table; the generator must reproduce/own it so regeneration doesn't drop it (design risk: "prose preamble").
- 2026-06-28 [qa-smoke] S1 (AC-2,AC-3): green — workflow-spec.sh --validate exits 0 (OK workflows=6); --list-workflows lists all 6 (4 orchestrators + 2 rosters)
- 2026-06-28 [qa-smoke] S2 (AC-4): green — --render-docs writes docs/workflow.md + 6 docs/workflows/<name>.md; second render byte-identical; --render-docs --check confirms live tree in sync (findings=0)
- 2026-06-28 [qa-smoke] S3 (AC-6,AC-10): green — tests/workflow-spec-render.test.sh T1 (deterministic) + T2 (ID-free) PASS
- 2026-06-28 [qa-smoke] S4 (AC-5): green — --render-docs --check exits 0 on fresh render; T4a/T4b prove fail-on-edit + fail-on-missing name the file
- 2026-06-28 [qa-smoke] S5 (AC-7): green — validate.sh Check 27 PASS; test.sh carries the Check-27 fixture (Step 3f); Checks 15b/15c retired (0 non-comment refs in validate.sh; pointer comments present); Check 15a still present
- 2026-06-28 [qa-smoke] S6 (AC-9): green — doc-spec.sh --check-on-disk 0 findings (human-doc-ids PASS); test-spec.sh --validate OK + --check-coverage findings=0 (validate-check-27 + test-workflow-spec-render units resolve)
- 2026-06-28 [qa-smoke-summary] green: 6/6 non-manual rows green (0 manual rows pending)
- 2026-06-28 [qa-e2e-run-start] RUN_ID=20260628-235635-48774 commit=4a8fa12
- 2026-06-28 [qa-e2e] E1 (AC-1,AC-4,AC-6): green — surface regenerates faithfully: docs/workflow.md reproduces the header preamble verbatim + lists all 6 entries with links; each orchestrator page carries its verbatim chart + 4 Touches axes + "In words" (e.g. docs/workflows/CJ_goal_feature.md:16-91); two consecutive renders are byte-identical; surface is ID-free; diff-vs-HEAD is the expected one-time reformat migration
- 2026-06-28 [qa-e2e] E2 (AC-3): green — no-vanish fails closed: removing the `## CJ_goal_defect` section makes `workflow-spec.sh --validate` exit 1 naming the missing workflow ("registry-completeness (no-vanish): routable CJ_goal_* skill 'CJ_goal_defect' has NO entry"); restored copy passes (OK workflows=6); completeness logic at scripts/workflow-spec.sh
- 2026-06-28 [qa-e2e] E3 (AC-5,AC-7): green — freshness gate catches drift: a hand-edit to docs/workflow.md makes both `--render-docs --check` (exit 1, names docs/workflow.md) and validate.sh Check 27 (ERROR "the generated workflow surface is stale", validate exit 1) fail; both pass after regenerate; Checks 15b/15c retired (pointer comment scripts/validate.sh:624; no live checks)
- 2026-06-28 [qa-e2e] E4 (AC-8): green — doc audit owns workflow freshness standalone: ran /CJ_doc_audit; repo-local SKILL.md Step 3b (skills/CJ_doc_audit/SKILL.md:212-240) emits `stage1/workflow-render` PASS on the fresh surface + FINDING naming the stale surface; Stage 3 playbook row (skills/CJ_doc_audit/SKILL.md:318) recognizes docs/workflow.md + docs/workflows/ as a GENERATED surface (never orphan/drift); generated files carry the GENERATED marker + are declared human-docs. Note: deployed ~/.claude skill is v0.3.0 (pre-Step-3b); executed the repo-local protocol as the leaf node (no subagent dispatch allowed)
- 2026-06-28 [qa-e2e] E5 (AC-7,AC-10): green — engine + no-vanish drill proven: standalone `bash tests/workflow-spec-render.test.sh` is green (RESULT: PASS) incl. T1 determinism, T2 ID-free, T3/T4a/T4b --check pass/fail-on-edit/fail-on-missing, and T6a/T6b the remove-an-entry no-vanish drill; scripts/test.sh carries the Check-27 fixture (Step 3f, scripts/test.sh:652-687: positive + negative drift + regenerate-green) + the workflow-spec-render.test.sh wiring (scripts/test.sh:2076-2081); parent ran the full suite GREEN (Failures: 0, RESULT: PASS)
- 2026-06-28 [qa-e2e-summary] green: 5/5 E2E rows green (E1-E5)
- 2026-06-28 [qa-e2e-summary] green (0s subagent rows verified in one dispatch; 0 rows parent-inline; 0 deferred): all 5 E2E rows green (E1 faithful regen, E2 no-vanish fails closed, E3 freshness gate, E4 /CJ_doc_audit standalone, E5 suite+drill)
- 2026-06-28 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(already-landed:validate-check-27,test-workflow-spec-render),doc-spec-custom:none(already-landed:spec/workflow-spec.md+6-workflow-rows-reframed) (Step 8.6a/8.6b verified already-landed inline; 8.6c/8.6d DEFERRED via DEFER_AUDIT — orchestrator runs the post-sync audit)
- 2026-06-28 [qa-pass] S000115 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
