---
name: "Audit skills + two-tier spec files + QA checkpoint + test-pipeline demolition"
type: user-story
id: "S000102"
status: active
created: "2026-06-12"
updated: "2026-06-12"
parent: "F000060"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
# receipts:               # optional; WRITTEN AT RUNTIME by /CJ_qa-work-item Step 9 (F000053/S000093), not at scaffold.
#   qa:                   # The SHA-anchored execution receipt qa.md Step 3's resume re-validation gate checks.
#     phase: 3            # Schema = work-copilot receipts.qa (work-copilot/prompts/qa.prompt.md) + a `commit` field.
#     commit: "<sha>"     # The commit this receipt vouches for (stale-SHA detection).
#     completed_at: "<ISO-8601 UTC>"
#     test_rows_run: 0
#     ac_ids_covered: []
#     ac_ids_uncovered: []
#     diff_audit: { changed_files_without_tests: [] }
#     ready_for_ship: false
#     next_legal: []
receipts:
  qa:
    phase: 3
    commit: "6141be251668cd2b4073d6da8df65f053d952613"
    completed_at: "2026-06-12T23:03:59Z"
    test_rows_run: 10
    ac_ids_covered: [AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5", "[qa-smoke-summary] green 5/5", "[qa-e2e-run-start] RUN_ID=20260612-155820-91971", "[qa-e2e] E1-E5 green [parent-inline]", "[qa-e2e-summary] green", "[qa-audit] AUDITS=doc:ok,test:ok", "[qa-pass] S000102"]
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
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
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

- [ ] `spec/doc-spec.md` is the GENERAL contract only and equals `doc-spec.sh --seed` output byte-for-byte; `front_table` is promoted into the portable seed schema (optional, enforced only when present, documented in the seed's Common prose); `spec/doc-spec-custom.md` carries exactly 5 overlay entries (3 migrated: `spec/gate-spec.md`, `CONTRIBUTING.md`, `spec/permission-policy.md`; 2 new self-declared: `spec/doc-spec-custom.md`, `spec/test-spec-custom.md`), same fenced-yaml grammar
- [ ] `doc-spec.sh` list subcommands + `--validate` operate on the MERGE of general + overlay-if-present; duplicate path across the two files ⇒ `--validate` error; `--render custom` reads the overlay; call sites in validate.sh / document-release / generate-doc-views.sh need no edits for the merge itself
- [ ] `spec/test-spec.md` (NEW seed) carries the 5 portable rules (tests-discoverable, suite-green, new-code-tested, units-anchored, single-owner) as `{ id, statement, scope, enforced_by }`; `spec/test-spec-custom.md` (NEW overlay) carries the old registry's content migrated verbatim in the OLD row shape (minus self-referential retired rows, plus rows for the new test files + swapped Check 24 banner, plus an explicit portability-audit unit)
- [ ] `scripts/test-spec.sh` (NEW) provides `--validate` (merged schema + closed enums + duplicate-id guard; `[test-spec-no-config]` halt marker), `--list-rules`, `--list-units`, `--check-coverage` (ported forward anchor-grep + reverse sweep + ≥20-token floor applied ONLY when `units:` rows exist, named note otherwise, env-overridable floor), `--seed`; registry absent ⇒ distinct `REGISTRY=absent` + exit 0
- [ ] `/CJ_doc_audit` and `/CJ_test_audit` exist as catalog skills (SKILL.md + USAGE.md, `status: experimental`, honest portability tiers, `doc_requirement` strings, repo-local → `_cj-shared` engine resolution), seed-deliver into bare repos (`seeded: yes` / idempotent `seeded: no`), run deterministic conformance + agent-judged alignment, and emit `DOC_AUDIT:`/`TEST_AUDIT:` findings reports; both document the inline-in-subagent vs Skill-tool-standalone dual posture
- [ ] `/CJ_qa-work-item` qa.md gains Step 8.6a–d (update test-spec-custom, update doc-spec-custom, run doc audit inline, run test audit inline) between Steps 8 and 9; audit findings ride a GREEN RESULT's `AUDITS=doc:<ok|findings:n>,test:<ok|findings:n>,spec_updates:<summary>` field + a fenced AUDIT_FINDINGS block; `[qa-audit-waived]` / `[qa-audit-declined]` journal lines are written on Continue-past-findings / Halt
- [ ] All four cj_goal pipelines surface the post-QA checkpoint AUQ (ALWAYS, green or red), halt as `halted_at_qa_audit` with the literal `[qa-audit-declined]` marker; `--quiet` auto-continues on `doc:ok,test:ok` and halts on findings; gate-spec.md gains the `qa-audit` gates[] row (order 45, between qa 40 and doc-sync 50) + a division-of-labor row; Check 22 green
- [ ] DEMOLITION: `spec/test-pipeline.md`, `scripts/test-pipeline.sh`, `tests/test-pipeline-spec.test.sh`, `docs/test-pipeline.md` deleted; validate.sh Check 24 body swapped to `test-spec.sh --check-coverage` (same HARD, SKIP-when-registry-absent posture) + `test-spec.sh --validate` added + Check 23 test-pipeline branch removed; generate-doc-views.sh render branch removed; the ENUMERATED reference sweep complete (CLAUDE.md scripts table + sections, architecture.md section rewrite + spec-family list, document-release SKILL.md + USAGE.md, generate-readme.sh heredoc, test.sh three F000059 blocks, doc-spec registry rows, TODOS row 12 struck); no `test-pipeline` grep hit outside CHANGELOG, work-items history, TODOS.md
- [ ] `/CJ_document-release` seeding path standardizes on `spec/doc-spec.md` (self-bootstrap + Step 6.7.3b basename equivalence), its generic stub-scaffold special-cases `spec/test-spec.md` via `test-spec.sh --seed`, and the generic stub shape for `front_table: required` docs opens with a summary table
- [ ] The zero-AUQ contract wording sweep lands in the same PR: four orchestrators' SKILL.md prose + skills-catalog.json descriptions become "one checkpoint AUQ (the QA audit findings) past the gate", halt taxonomies + telemetry enums gain `halted_at_qa_audit`, USAGE.md files updated; `rules/skill-routing.md` gains the two audit routing lines; docs/workflow.md (utilities entries + four orchestrator charts/Touches) + docs/philosophy.md decision tree updated; README regenerated
- [ ] Three new test suites green and registered in `scripts/test.sh` (tests/doc-spec-overlay.test.sh, tests/test-spec.test.sh, tests/cj-audit-skills.test.sh) + QA-wiring fixture assertions; ALL new tests + the swapped Check 24 enumerated as `units:` rows in `spec/test-spec-custom.md` (self-verification); `./scripts/validate.sh` + `./scripts/test.sh` fully green; portability audit FINDINGS=0

## Todos

<!-- Actionable items for this story. -->

- [x] Split `spec/doc-spec.md`: rewrite as general-only (spec/-style self-declared paths, current workbench requirement wording, front_table flags, `spec/test-spec.md` row added, retired test-pipeline rows dropped); move Custom-section prose + 3 entries to `spec/doc-spec-custom.md` + add the 2 self-declared rows; update the seed lockstep copies (`scripts/doc-spec.sh` heredoc, `templates/doc-spec-common.md`) byte-identically; seed prose documents front_table + drops the copy-verbatim instruction in favor of the overlay-file model
- [x] `scripts/doc-spec.sh`: overlay merge for `--list-declared`/`--list-human-docs`/`--list-front-table-docs`/`--expand-whitelist`/`--validate`; duplicate-path error; `--render custom` from the overlay (back-compat: in-file `section: custom` rows still render)
- [x] Write `spec/test-spec.md` seed (5 rules) + `spec/test-spec-custom.md` overlay (verbatim row migration minus self-referential rows, plus new-test + swapped-banner + portability-audit units)
- [x] Port `scripts/test-pipeline.sh` → `scripts/test-spec.sh` (schema rename, two-file merge, absent/invalid split, units-gated floor, `--seed`, `--list-rules`)
- [x] Build `skills/CJ_doc_audit/` + `skills/CJ_test_audit/` (SKILL.md + USAGE.md + catalog entries + routing lines + workflow.md/philosophy.md documentation)
- [x] Wire QA Step 8.6a–d into `skills/CJ_qa-work-item/qa.md` + extend the RESULT line + AUDIT_FINDINGS block
- [x] Add the checkpoint AUQ to all four pipelines (feature/defect/task pipeline.md, todo SKILL.md) + `--quiet` behavior + gate-spec `qa-audit` row + division-of-labor row
- [x] Execute the demolition + the enumerated reference sweep (CLAUDE.md, architecture.md, document-release, generate-readme.sh, test.sh, doc-spec rows, TODOS row 12) + validate.sh Check 23/24 surgery
- [x] Update `/CJ_document-release` (spec/-path seeding, test-spec stub special-case, front_table stub shape, third-view render logic removal)
- [x] Zero-AUQ wording sweep (4 SKILL.md + catalog descriptions + USAGE.md + telemetry enums) — same-PR (Step 8.6d self-application)
- [x] Write + register the three new test suites; add test.sh integration blocks; self-register all new tests + swapped Check 24 as `units:` rows; regenerate views + README
- [x] Add the deferred TODOS rows (test-spec generated view; concern-taxonomy re-eval) + strike TODOS row 12 as obsolete

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Atomic story carrying the full F000060 build: two-tier doc/test spec files (general seeds + custom overlays), doc-spec.sh overlay merge, new test-spec.sh full-parity parser, /CJ_doc_audit + /CJ_test_audit skills, QA Steps 8.6a–d + the always-prompt findings checkpoint in all four pipelines, and the F000059 test-pipeline demolition with its enumerated reference sweep.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- spec/doc-spec.md, spec/doc-spec-custom.md, spec/test-spec.md, spec/test-spec-custom.md
- scripts/doc-spec.sh, scripts/test-spec.sh (new), templates/doc-spec-common.md
- spec/test-pipeline.md, scripts/test-pipeline.sh, tests/test-pipeline-spec.test.sh, docs/test-pipeline.md (DELETED)
- scripts/validate.sh, scripts/generate-doc-views.sh, scripts/generate-readme.sh, scripts/test.sh
- skills/CJ_doc_audit/ (new), skills/CJ_test_audit/ (new), skills/CJ_qa-work-item/qa.md
- skills/CJ_goal_feature/pipeline.md, skills/CJ_goal_defect/pipeline.md, skills/CJ_goal_task/pipeline.md, skills/CJ_goal_todo_fix/SKILL.md (+ their SKILL.md/USAGE.md wording sweep)
- skills/CJ_document-release/SKILL.md + USAGE.md, spec/gate-spec.md, rules/skill-routing.md
- skills-catalog.json, README.md, docs/workflow.md, docs/philosophy.md, docs/architecture.md, CLAUDE.md, TODOS.md
- tests/doc-spec-overlay.test.sh, tests/test-spec.test.sh, tests/cj-audit-skills.test.sh (new)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The migration keeps the OLD unit row shape verbatim so the 66-row copy needs no field mapping and the coverage engine's extraction grammar + reverse-sweep id conventions port intact — the format changes HOME (custom overlay), not SHAPE.
- The reverse-coverage floor is gated on `units:` rows existing: a seeded-general-only consumer repo gets a named "coverage cross-check inactive" note, never a misleading extraction-grammar finding — that single gate is what makes one parser serve both the workbench and a bare consumer repo.
- A generic title-plus-section stub for the new `spec/test-spec.md` registry row would create a present-but-invalid registry and hard-halt `/CJ_test_audit` in any consumer repo — document-release's stub-scaffold must special-case it via `test-spec.sh --seed` (mirroring the existing generated-views render-stub special case).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] Scaffolded as the single atomic story for F000060 (single-story scope per /CJ_goal_feature v1); IDs F000060/S000102 reclaimed from the aborted earlier scaffold via cj-id-claim.sh same-branch reuse.
- 2026-06-12 [impl-decision] Overlay resolution is SIBLING-of-the-general-file (`dirname($GENERAL)/​{doc,test}-spec-custom.md`, env-overridable): keeps every DOC_SPEC_PATH/TEST_SPEC_PATH temp-dir override hermetic (a temp parse can never accidentally merge the live repo's overlay) while giving spec/-homed and root-homed repos the same sibling convention. Verified by tests/doc-spec-overlay.test.sh case 7.
- 2026-06-12 [impl-decision] Seed requirement strings: kept the workbench's current wording verbatim except where byte-identity + portability forced one string to serve both postures — the doc-spec self-row (now states seed byte-identity + the overlay rule), the new spec/test-spec.md row (the design's wording), and the two generated-view rows (mechanism-neutral "kept matching the merged registry" instead of naming the workbench-only generator). Recorded per the design's seed/front_table resolution.
- 2026-06-12 [impl-decision] The explicit portability-audit unit row landed as family: validate (anchor scripts/cj-portability-audit.sh, source scripts/validate.sh, advisory + ratchet, trigger pre-commit pr-ci manual): the trigger enum has no pipeline-gate token (gate-spec owns that layer), so the row documents the ENGINE under its Check-18 surface and names the strict orchestrator gate in its purpose.
- 2026-06-12 [impl-decision] document-release 6.7.3b basename equivalence generalized to ALL spec/-prefixed seed paths (covers spec/doc-spec.md AND the new spec/test-spec.md for root-style consumers), scoped so docs/* entries never get basename equivalence.
- 2026-06-12 [impl-finding] The 66-row migration nets 69 overlay units: 66 - 2 self-referential retired rows (the old suite's runner row + the old inline-guards row) + 5 new (3 new test suites, the new F000060 inline-guards block, the explicit portability-audit unit). Reverse sweep extracts 49 live tokens (floor 20).
- 2026-06-12 [impl-finding] CI shellcheck (SC2016 class) flagged the F000060 test.sh fixture printf with backticks in single quotes — replaced with a quoted heredoc; new scripts/doc-spec.sh + scripts/test-spec.sh shellcheck clean (only the pre-existing lib.sh SC1091 baseline remains repo-wide).
- 2026-06-12 [impl] Full F000060 build: rewrote spec/doc-spec.md as the general seed (3-way byte-identical with the doc-spec.sh heredoc + templates/doc-spec-common.md); created spec/doc-spec-custom.md (5 overlay rows), spec/test-spec.md (5 portable rules; == test-spec.sh --seed), spec/test-spec-custom.md (69 verbatim-shape units); rewrote scripts/doc-spec.sh (overlay merge + duplicate-path guard); created scripts/test-spec.sh (full parser parity port: absent/invalid split, units-gated reverse floor, --list-rules, --seed); deleted spec/test-pipeline.md + scripts/test-pipeline.sh + tests/test-pipeline-spec.test.sh + docs/test-pipeline.md; swapped validate.sh Check 24 body (validate-first + coverage) + removed Check 23's third-view branch; swept generate-doc-views.sh / generate-readme.sh / scripts/test.sh (3 blocks); built skills/CJ_doc_audit + skills/CJ_test_audit (SKILL+USAGE+catalog+routing); wired qa.md Step 8.6a-d + extended RESULT/AUDIT_FINDINGS; added the always-fire QA-audit checkpoint to all four pipelines + gate-spec qa-audit row (order 45) + the zero-AUQ wording sweep (4 SKILL.md + catalog descriptions + USAGE.md + telemetry enums); updated CLAUDE.md / architecture.md / workflow.md / philosophy.md / document-release; struck TODOS row as OBSOLETE + 2 deferred rows; 3 new registered test suites + test.sh integration blocks; README + doc views regenerated.
- 2026-06-12 [impl] Verification: bash -n clean on all touched shell; tests/doc-spec-overlay.test.sh (16 OK) + tests/test-spec.test.sh (29 OK incl. ported drills a/b/d/f/f2/g/h/i + floor) + tests/cj-audit-skills.test.sh (31 OK incl. bare-repo seed delivery + idempotence + seeded violations) all PASS; validate.sh fully green (Checks 15-24 PASS; Check 18 FINDINGS=0; Check 22 green incl. the qa-audit markers; Check 24 rows=69 reverse_tokens=49 findings=0); git grep test-pipeline outside CHANGELOG/work-items/TODOS = 0 hits.
- 2026-06-12 [impl-pass] S000102: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-12 [qa-smoke] S1 (AC-1, AC-2): green — tests/doc-spec-overlay.test.sh PASS (16 OK: merge semantics, duplicate-path halt, 3-way seed byte-identity, --render custom, hermetic DOC_SPEC_PATH override)
- 2026-06-12 [qa-smoke] S2 (AC-3, AC-4): green — tests/test-spec.test.sh PASS (29 OK: merged --validate, [test-spec-no-config] fail-closed fixtures, REGISTRY=absent exit-0, seed emission + byte-identity, units-gated floor note)
- 2026-06-12 [qa-smoke] S3 (AC-5, AC-6): green — tests/cj-audit-skills.test.sh PASS (31 OK: bare-repo seed delivery seeded:yes, second-run idempotence seeded:no, seeded violations produce findings, workbench baseline clean)
- 2026-06-12 [qa-smoke] S4 (AC-4, AC-9): green — coverage-parity drill cases in tests/test-spec.test.sh all OK (drills a/b/d/f/f2/g/h/i/j: forward orphan, unregistered tests/*.test.sh reverse flag, source pin, execution-shaped forward, floor override — ported checks demonstrably alive)
- 2026-06-12 [qa-smoke] S5 (AC-7, AC-9, AC-11): green — ./scripts/validate.sh re-run this QA run: RESULT PASS (Errors 0, Warnings 0; Check 22 green incl. qa-audit markers; Check 23 two-view sync; Check 24 test-spec coverage rows=69 reverse_tokens=49 findings=0); ./scripts/test.sh cited green from the immediately-preceding full-suite run on this exact tree (0 failures, orchestrator-verified)
- 2026-06-12 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-06-12 [qa-e2e-run-start] RUN_ID=20260612-155820-91971 commit=6141be2
- 2026-06-12 [qa-e2e] E1 (AC-5, AC-6): green — bare temp repo (git init): inline audit-skill first runs seed-delivered spec/doc-spec.md + spec/test-spec.md (seeded: yes both, byte-equal to --seed output), non-crashing verdicts (doc --validate exit 0; test audit emitted the named inactive-coverage note), second runs idempotent (seeded: no, no re-seed); engine via the documented CJ_SHARED_SCRIPTS env hook pointed at this worktree's scripts/ (the post-land _cj-shared proxy — deployed copy is pre-land stale) [parent-inline]
- 2026-06-12 [qa-e2e] E2 (AC-7, AC-8): green — self-application: THIS QA run executed Steps 8.6a–d and returns the extended RESULT + fenced AUDIT_FINDINGS block (the orchestrator's Step 3.4 checkpoint fires on it next, BEFORE Step 5.5 doc-sync — ordering verified in the feature pipeline); by inspection: gate-spec qa-audit row order 45 (between qa 40 and doc-sync 50), literal [qa-audit-declined] + [qa-audit-waived] + halted_at_qa_audit present in all four pipelines (Check 22 green); the live checkpoint pause is observed by the calling orchestrator on this RESULT [parent-inline]
- 2026-06-12 [qa-e2e] E3 (AC-9): green — demolition complete: all four retired paths gone (spec/test-pipeline.md, scripts/test-pipeline.sh, tests/test-pipeline-spec.test.sh, docs/test-pipeline.md); git grep test-pipeline hits ONLY CHANGELOG.md, TODOS.md, work-items/ history (zero out-of-policy); Check 24 banner reads 'test-spec coverage cross-check' and runs test-spec.sh --check-coverage green (rows=69 reverse_tokens=49 findings=0) [parent-inline]
- 2026-06-12 [qa-e2e] E4 (AC-10): green — temp consumer repo (no catalog): document-release self-bootstrap path seeded spec/doc-spec.md byte-identical to the /CJ_doc_audit-seeded copy at the identical spec/ path (convergent); declared-but-missing spec/test-spec.md stub-delivered via test-spec.sh --seed validates clean (OK schema_version=1 — /CJ_test_audit would not hard-halt); front_table stub (docs/philosophy.md) opens with a summary table before any '## ' heading [parent-inline]
- 2026-06-12 [qa-e2e] E5 (AC-1, AC-2, AC-3, AC-11): green — workbench: validate.sh re-run RESULT PASS (0 errors, 0 warnings) + test.sh cited green (full suite, 0 failures, same tree); inline /CJ_doc_audit FINDINGS=0 DOCS_AUDITED=16 + /CJ_test_audit FINDINGS=0 UNITS_AUDITED=69; self-application clean: all four orchestrator catalog descriptions + SKILL.md carry the one-checkpoint-AUQ wording (no unqualified zero-AUQ left), both new skills in philosophy decision tree + workflow.md utilities entries + the two routing lines; portability audit FINDINGS=0 (Check 18) [parent-inline]
- 2026-06-12 [qa-e2e-summary] green (0s subagent; 5 rows parent-inline; 0 deferred): (no subagent-eligible rows — leaf-subagent posture, all rows ran parent-inline per qa.md Step 7.5)
- 2026-06-12 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:none(both-overlays-pre-registered+verified-complete) (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator). 8.6a: test-spec-custom verified complete (3 new suite rows + swapped validate-check-24 + testsh-test-spec-guards + portability-audit unit all present; reverse sweep green guarantees no unregistered test). 8.6b: doc-spec-custom verified complete (3 migrated + 2 self-declared rows; spec/test-spec.md correctly in the general seed). 8.6c: DOC_AUDIT ok FINDINGS=0 DOCS_AUDITED=16 seeded:no (deterministic conformance + views-in-sync clean; all 16 registered-doc verdicts up-to-date). 8.6d: TEST_AUDIT ok FINDINGS=0 UNITS_AUDITED=69 seeded:no (coverage rows=69 reverse_tokens=49 findings=0; suite-green green via this run's smoke + cited full test.sh; new-code-tested green via 3 new suites + 69 units rows).
- 2026-06-12 [qa-pass] S000102 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
