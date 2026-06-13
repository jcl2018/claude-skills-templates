---
name: "--check-on-disk Stage-1 engine + three-stage restructure of both audit skills + fresh-context dispatch + per-stage reports"
type: user-story
id: "S000103"
status: active
created: "2026-06-12"
updated: "2026-06-12"
parent: "F000061"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "ce7af57cda52e72bae772626f85d0601eeca44bb"
    completed_at: "2026-06-12T18:35:00Z"
    test_rows_run: 10
    ac_ids_covered: [AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-smoke-summary] green 5/5", "[qa-e2e-run-start] RUN_ID=20260612-182809-qa", "[qa-e2e] E1-E5 green [parent-inline]", "[qa-e2e-summary] green", "[qa-audit] doc:findings:1,test:ok", "[qa-pass] S000103"]
    ready_for_ship: true
    next_legal: [ship]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/check_on_disk_engine_and_staged_audits` (or use parent's branch if shipping in same PR)
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

<!-- What "done" looks like for this story. Expanded, testable form of the
     parent's Definition of done; SPEC.md carries the Given/When/Then blocks. -->

- [ ] `scripts/doc-spec.sh --check-on-disk` exists and runs the six deterministic checks (declared-exists, orphans, root-declared, human-doc-ids, front-table, views-render) against the MERGED registry, emitting one line per check (`check: <id> — PASS` | `FINDING: stage1/<id> — <detail>`, one FINDING line per violation) + `CHECKS_RUN=`/`FINDINGS=` tail; exit 0 clean / exit 1 findings; clean workbench ⇒ all PASS, `FINDINGS=0`, exit 0
- [ ] `--check-on-disk` probes registry-file existence ITSELF, before the parse gates: absent ⇒ `REGISTRY=absent` + exit 0; present-but-invalid ⇒ `[doc-sync-no-config]` + exit 1; the `orphans` check counts a non-self-declaring overlay file as an orphan; all engine loops are `while IFS= read -r`; env overrides (`DOC_SPEC_PATH`, `REPO_ROOT`-equivalent) honored for hermetic temp-dir tests
- [ ] `/CJ_doc_audit` Stage 1 is ONE engine call printed verbatim (zero executor-authored loops remain in the skill); Stage 2 quotes each declared doc's `requirement:`, decomposes it into clauses, and emits evidence-cited verdicts in the grammar `<path>: satisfies` | `<path>: missing-requirement (soft — no requirement: declared)` | `<path>: n/a — <why>` | `FINDING: stage2/<path> — clause '<clause>' not met: <evidence>` (only FINDING lines count; `up-to-date`/`stale:` RETIRED); Stage 3 enumerates ground truth first, cross-walks per the doc-type playbook, and emits `<path>: no-drift` | `FINDING: stage3/<path> — <named delta>` (catalog-dependent cross-walks skip with a note in a no-catalog consumer repo)
- [ ] Standalone runs dispatch Stages 2+3 to ONE fresh-context general-purpose subagent (REQUIRED) whose prompt carries ONLY repo root + engine path + Stage-1 report + the stage protocols; both skills' `allowed-tools` + catalog `depends.tools` gain `Agent`; the in-QA inline degradation (Step 8.6c/d — nested-subagent wall) is documented in both SKILL.mds
- [ ] The per-stage report contract holds: `DOC_AUDIT: <ok|findings>`, `FINDINGS=` (total), `STAGE1_FINDINGS=`/`STAGE2_FINDINGS=`/`STAGE3_FINDINGS=`, `DOCS_AUDITED=`, `seeded:`, + three `--- stage N ---` sections; pre-stage findings (engine-unreachable / seed-failure / registry-invalid) count as STAGE1 with `stage1/engine`/`stage1/seed`/`stage1/registry` prefixes; skipped stages print their header + one `skipped: <reason>` line + `STAGE*_FINDINGS=0`; `DOC_AUDIT: ok` requires all three counts = 0
- [ ] `/CJ_test_audit` gets the symmetric three-stage shape: Stage 1 = `test-spec.sh --validate` + `--check-coverage` unchanged mechanics with `stage1/` prefixes; Stage 2 judges each general RULE's `statement` with cited evidence AND each overlay UNIT's `purpose`/`label` truthfulness (the anchor-greps-while-description-rots catch); Stage 3 enumerates live verification surfaces and judges coverage-in-substance; same dispatch rule (one subagent MAY judge both audits when run together); per-stage report with `UNITS_AUDITED=`
- [ ] qa.md's Step 8.6 AUDIT_FINDINGS block template adopts the per-stage shape (each audit contributes its `STAGE*_FINDINGS=` trio + three stage sections); the four cj_goal pipelines need ZERO edits — verified by grep (they print the block verbatim)
- [ ] Docs sweep complete: both catalog descriptions + `doc_requirement` strings name the three-stage contract; both USAGE.mds current (Check 14 normal path); `docs/workflow.md` utility entries + CLAUDE.md audit-internals mentions refreshed; `docs/architecture.md`'s stale "future `--check-on-disk` … deferred" passage (~L285–296) rewritten to describe the shipped subcommand; TODOS row added for validate.sh Checks 15/17/19/20 convergence (Approach B, deferred)
- [ ] Tests: `tests/doc-spec-overlay.test.sh` extended with the `--check-on-disk` battery (clean fixture ⇒ exit 0/`FINDINGS=0`; seven seeded violations — missing declared doc, orphan in docs/, orphan in spec/, undeclared root `*.md`, work-item ID in a human-doc, missing front table, view-table drift — each flipping exactly its own `FINDING: stage1/<id>` + exit 1; registry-absent ⇒ `REGISTRY=absent` exit 0; invalid ⇒ `[doc-sync-no-config]` exit 1); `tests/cj-audit-skills.test.sh` extended with per-stage report-shape assertions + the planted-drift stage3 drill; the two suites' purpose text updated in `spec/test-spec-custom.md` (anchors unchanged); NO new suites; `./scripts/validate.sh` + `./scripts/test.sh` green

## Todos

<!-- Actionable items for this story. -->

- [x] Implement `doc-spec.sh --check-on-disk` (6 checks + output contract + registry-absent probe carve-out + env overrides; `while IFS= read -r` everywhere)
- [x] Restructure `skills/CJ_doc_audit/SKILL.md` into the three named stages (Stage 1 engine call; Stage 2 clause/evidence protocol + verdict grammar; Stage 3 ground-truth enumeration + cross-walk playbook; fresh-context dispatch section; per-stage report; pre-stage/skipped-stage error grammar restated in stage terms)
- [x] Restructure `skills/CJ_test_audit/SKILL.md` symmetrically (engine-call Stage 1 unchanged mechanics; Stage 2 rules+units judgment; Stage 3 live-surface drift; shared-dispatch note; `UNITS_AUDITED=` report)
- [x] Add `Agent` to both skills' `allowed-tools` frontmatter + catalog `depends.tools`; update both catalog `description` + `doc_requirement` strings; regenerate README
- [x] Update qa.md Step 8.6 AUDIT_FINDINGS block template to the per-stage shape; grep-verify the four pipelines need zero edits
- [x] Docs sweep: workflow.md utility entries, CLAUDE.md mentions, architecture.md ~L285–296 rewrite, both USAGE.mds; TODOS convergence row
- [x] Extend the two test suites + update their purpose text in `spec/test-spec-custom.md`; run validate.sh + test.sh green

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Atomic story carrying the full F000061 build: the NEW `doc-spec.sh --check-on-disk` Stage-1 engine, the three-stage restructure of both audit skills (evidence-forced Stage 2, drift-hunting Stage 3), the REQUIRED fresh-context subagent dispatch standalone, the per-stage findings report contract, qa.md's AUDIT_FINDINGS template refinement (pipelines untouched), the docs/catalog sweep, and the two extended test suites.
- 2026-06-12: Implementation complete (/CJ_implement-from-spec). All 7 Todos closed; 15 files written/modified; validate.sh PASS; both extended suites green standalone; zero edits to the four pipelines / validate.sh / test.sh / test-spec.sh / the seeds (D11 + constraints honored). Awaiting /CJ_qa-work-item.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- scripts/doc-spec.sh (modified — NEW `--check-on-disk` subcommand)
- skills/CJ_doc_audit/SKILL.md + USAGE.md (modified — three-stage restructure)
- skills/CJ_test_audit/SKILL.md + USAGE.md (modified — symmetric restructure)
- skills-catalog.json (modified — descriptions, doc_requirement, depends.tools + Agent), README.md (regenerated)
- skills/CJ_qa-work-item/qa.md (modified — AUDIT_FINDINGS per-stage template)
- docs/workflow.md, docs/architecture.md, CLAUDE.md, TODOS.md (modified — sweep + convergence row)
- spec/test-spec-custom.md (modified — two suites' purpose text)
- tests/doc-spec-overlay.test.sh, tests/cj-audit-skills.test.sh (extended)

## Insights

<!-- Non-obvious findings worth remembering. -->

- See the parent [../F000061_TRACKER.md](../F000061_TRACKER.md) `## Insights` — the word-split defect class, the resident-context rubber-stamp bias, the pre-stage-findings-are-STAGE1 error grammar, the table-block (not whole-file) `views-render` comparison, and the orphan-overlay honesty decision all live there.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] Story scope locked to the parent's D10.1/D10.2/D10.3/D11 decisions (engine subcommand; REQUIRED fresh-context dispatch standalone with honest in-QA inline degradation; both audits symmetrically; validate.sh untouched). Single atomic story — no task children.
- 2026-06-12 [impl-decision] `--check-on-disk` always runs all 6 check ids (`CHECKS_RUN=6` on every full run; `views-render` with no view files on disk trivially passes) — locks Open Question 3's "one count per check id" reading into the engine + test battery. The registry-absent probe is a one-line `[ -f "$DOC_SPEC_PATH" ]` in the dispatch arm BEFORE `_run_registry_gates` (the subcommand-local carve-out), so present-but-invalid inherits the `[doc-sync-no-config]` halt unchanged.
- 2026-06-12 [impl-decision] Orphan-in-spec/ test case built as the NON-self-declaring overlay (declares `EXTRA.md`, creates it, regenerates the custom view against the merged registry) so the overlay file itself is the LONE finding — proving both the orphan-overlay design decision AND single-finding isolation in one fixture.
- 2026-06-12 [impl-decision] The planted-drift stage3 drill asserts the two halves a test CAN assert (agent stages cannot execute in a suite): the documented cross-walk is mechanically computable on a fixture (jq catalog ground truth vs workflow-doc grep names `CJ_omitted`), and the SKILL.md documents the playbook + `FINDING: stage3/` grammar.
- 2026-06-12 [impl-finding] The cj-audit-skills suite's old 3a drills hand-rolled the root-declared + ID-lint loops — exactly the executor-authored-loop class this story kills. Rewrote them to ONE `--check-on-disk` engine call asserting `stage1/`-prefixed findings (the test now exercises the engine, not a re-derivation).
- 2026-06-12 [impl] Wrote/modified 15 files: scripts/doc-spec.sh (NEW --check-on-disk + header/usage), both audit SKILL.mds (three-stage restructure, Agent tool, v0.2.0), both USAGE.mds (real content), skills-catalog.json (descriptions + doc_requirement + depends.tools Agent), README.md (regenerated), skills/CJ_qa-work-item/qa.md (per-stage AUDIT_FINDINGS template + 8.6c/d capture text), docs/workflow.md + docs/architecture.md + CLAUDE.md (audit-internals refresh; stale "deferred" passage rewritten), TODOS.md (validate.sh-convergence row), spec/test-spec-custom.md (two purpose strings, anchors unchanged), tests/doc-spec-overlay.test.sh (+10-case --check-on-disk battery), tests/cj-audit-skills.test.sh (per-stage shape + engine drills + stage3 drill). Four pipelines + validate.sh + test.sh + test-spec.sh + seeds: ZERO edits (verified by git diff).
- 2026-06-12 [impl] Verified: bash -n clean; clean workbench `--check-on-disk` all 6 PASS / FINDINGS=0 / exit 0; seed 3-way byte-identity holds; both extended suites pass standalone (doc-spec-overlay 26 OK incl. 7-violation isolation; cj-audit-skills 50 OK); shellcheck --norc clean on doc-spec.sh; validate.sh PASS 0 errors / 0 warnings (Check 23 + 24 green with updated purpose text).
- 2026-06-12 [impl-pass] S000103: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-12 [qa-smoke] S1 (AC-1, AC-2): green — `bash tests/doc-spec-overlay.test.sh` exit 0 (26 OK): --check-on-disk clean fixture 6 PASS + CHECKS_RUN=6 + FINDINGS=0; seven seeded violations each isolated to exactly their own `FINDING: stage1/<id>` + exit 1 (incl. non-self-declaring overlay named as orphan); registry-absent ⇒ REGISTRY=absent exit 0; invalid ⇒ [doc-sync-no-config] exit 1
- 2026-06-12 [qa-smoke] S2 (AC-4, AC-7, AC-8): green — `bash tests/cj-audit-skills.test.sh` exit 0 (50 OK): STAGE1/2/3_FINDINGS= trio + three stage-section delimiters + stage1/ prefixes asserted; Stage-2 grammar tokens present and up-to-date/stale: absent; skipped-stage grammar on registry-invalid path; symmetric TEST_AUDIT shape with UNITS_AUDITED=
- 2026-06-12 [qa-smoke] S3 (AC-5): green — planted-drift stage3 drill (same suite): documented cross-walk mechanically NAMES the omitted skill (CJ_omitted) from catalog ground truth; SKILL.md documents the playbook + FINDING: stage3/ grammar
- 2026-06-12 [qa-smoke] S4 (AC-3, AC-6): green — CJ_doc_audit Stage 1 is the one `--check-on-disk` engine call (grep count 5, all in Stage-1/seed/dispatch prose — zero executor-authored conformance loops); `Agent` present in BOTH skills' allowed-tools frontmatter AND catalog depends.tools; dual standalone-dispatch/in-QA-inline posture documented in both SKILL.mds (nested-subagent wall)
- 2026-06-12 [qa-smoke] S5 (AC-9, AC-10): green — ./scripts/validate.sh PASS (0 errors / 0 warnings; Check 23 + Check 24 green: coverage rows=69 reverse_tokens=49 findings=0); ./scripts/test.sh PASS (Failures: 0); zero edits to the four pipeline files (working-tree diff AND main... diff both empty); qa.md AUDIT_FINDINGS template carries the STAGE*_FINDINGS= trio (11 matches)
- 2026-06-12 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-12 [qa-e2e-run-start] RUN_ID=20260612-182809-qa commit=ce7af57
- 2026-06-12 [qa-e2e] E1 (AC-3, AC-4, AC-6, AC-7): green — doc audit executed inline per the new SKILL.md: Stage 1 was the ONE `--check-on-disk` engine call printed verbatim (6 PASS, CHECKS_RUN=6, FINDINGS=0); Stage 2 quoted all 16 declared docs' requirements clause-by-clause with cited evidence; Stage 3 opened with the ground-truth enumeration line; per-stage report with STAGE1/2/3_FINDINGS= emitted. Fresh-context dispatch verified STRUCTURALLY (SKILL.md REQUIRED-dispatch section; Agent in allowed-tools + depends.tools) — live top-level dispatch is the documented in-QA coverage gap (TEST-SPEC Coverage Gaps row 2; nested-subagent wall), stage headers labeled (agent-judged, inline) per the SKILL.md posture rule [parent-inline]
- 2026-06-12 [qa-e2e] E2 (AC-8): green — test audit symmetric: Stage 1 = `test-spec.sh --validate` (OK schema_version=1) + `--check-coverage` (OK coverage rows=69 reverse_tokens=49 findings=0) with stage1/ prefix rule; Stage 2 quoted all 5 rule statements with cited evidence (suite-green cites THIS run's `./scripts/test.sh` PASS) AND judged touched units' purpose/label truthfulness; Stage 3 enumerated live surfaces (17 test files, 13+14 validate banners/comments, 3 workflows, 2 hooks); UNITS_AUDITED=69; one inline judge handled both audits (the shared-dispatch option) [parent-inline]
- 2026-06-12 [qa-e2e] E3 (AC-5): green — planted one-line drift drill run live against a temp COPY of docs/workflow.md (CJ_suggest mentions removed): the Stage-3 cross-walk emitted `FINDING: stage3/docs/workflow.md — routable skill CJ_suggest absent from the workflow list` naming exactly the planted-missing skill; Stages 1+2 unaffected; live tree untouched; corroborated by the suite's fixture drill (names CJ_omitted) [parent-inline]
- 2026-06-12 [qa-e2e] E4 (AC-9): green — qa.md AUDIT_FINDINGS template carries the STAGE*_FINDINGS= trio + three stage sections (11 grep matches); zero edits to the four pipeline files (working-tree AND main... diffs both empty); all four pipelines carry the literal [qa-audit-declined] checkpoint marker (suite-asserted); THIS run's own AUDIT_FINDINGS block is emitted in the per-stage shape and rides the RESULT to the checkpoint verbatim [parent-inline]
- 2026-06-12 [qa-e2e] E5 (AC-10): green — docs/architecture.md L275-305 now describes the SHIPPED --check-on-disk subcommand (six checks, output contract, registry probe, consumer-CI yaml example) + the deliberate parallel-implementation note pointing at the TODOS convergence row (TODOS.md:5); both catalog descriptions + doc_requirement strings name the three-stage contract; both USAGE.mds updated this change with validate.sh Check 14 green (normal path, no override); validate.sh + test.sh PASS on this tree; self-application: Stage 2/3 judged the swept docs — zero stale flags on the feature's own surfaces (one pre-existing minor stage3 finding on README's generator-emitted layout tree, not a swept surface) [parent-inline]
- 2026-06-12 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): all 5 E2E rows green parent-inline — no subagent-eligible rows (every row recursive/interactive per the Step 4.5 classifier; nested-subagent wall)
- 2026-06-12 [qa-audit] AUDITS=doc:findings:1,test:ok,spec_updates:none(both overlays verified current — the two suites' purpose rows were updated by the implement phase; no new test surfaces, no new docs) (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). The one doc finding: FINDING: stage3/README.md — Repository-layout tree omits real top-level dirs tests/ and deprecated/ (block emitted by scripts/generate-readme.sh:22-33; pre-existing, not introduced by this change)
- 2026-06-12 [qa-pass] S000103 (user-story): green smoke + green E2E. Phase 2 gates transitioned. Fail-closed verdict GREEN (SMOKE=green, E2E=green, all 10 ACs covered, receipts.qa written for commit ce7af57); execution receipt at frontmatter receipts.qa.
- 2026-06-13 [qa-audit-fixed] stage3/README.md finding (layout tree omitted tests/ + deprecated/) FIXED INLINE at the operator checkpoint (D14): scripts/generate-readme.sh heredoc + README regen; --check-on-disk re-verified FINDINGS=0; no waiver needed.
