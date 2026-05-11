---
name: "/wc-qa — QA walkthrough + receipt-schema lock"
type: user-story
id: "S000030"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/wc_qa` (or use parent's branch if shipping in same PR)
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
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
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

- [ ] `work-copilot/prompts/qa.prompt.md` exists with `tools: [codebase, search, searchResults, findTestFiles, editFiles]` declared in frontmatter.
- [ ] Prompt instructs Copilot to (1) run `/validate` first, (2) print test-plan/TEST-SPEC checklist, (3) extract AC IDs and flag uncovered, (4) ask user for `git log --name-only` paste (with first-run fallback to `receipts.scaffold` SHA), (5) run Working-Tree Rule paste pattern, (6) walk checklist, (7) write `[smoke-pass]` / `[qa-fail]` journal entries, (8) write `receipts.qa` block, (9) print READY_FOR_SHIP gate.
- [ ] Receipt schema documented in prompt's output instructions (this story locks the schema: `phase`, `completed_at`, `test_rows_run`, `ac_ids_covered`, `ac_ids_uncovered`, `diff_audit.changed_files_without_tests`, `journal_entries`, `ready_for_ship`, `next_legal`).
- [ ] Existing fixture work-item at `work-copilot/fixtures/valid-feature-dir/` extended (or new fixture added) so `/wc-qa` can be exercised against a real day-1 target.
- [ ] Manual smoke pass: invoke `/wc-qa` against the fixture in Copilot Chat (or fixture-driven dry run), verify receipt block lands in tracker frontmatter.

## Todos

<!-- Actionable items for this story. -->

- [x] Author `work-copilot/prompts/qa.prompt.md` with `mode: agent` + `tools:` frontmatter.
- [x] Document receipt schema in the prompt's output instructions (locks the contract for downstream prompts).
- [x] Encode the Working-Tree Rule paste pattern (hard-stop for `/wc-qa`).
- [x] Encode the "read whole tracker, parse YAML, merge `receipts.qa`, write whole tracker" pattern.
- [x] Extend `work-copilot/fixtures/valid-feature-dir/` to include a TEST-SPEC with at least one AC that has no test row (so /wc-qa exercises the "uncovered AC" diagnostic).
- [x] Document the first-run fallback (use `receipts.scaffold` SHA when no `[qa-*]` journal entry exists).
- [ ] (Deferred to /CJ_qa-work-item) Verify against the fixture in Copilot Chat or via fixture-driven validation.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-11: Created. Build #1 of Approach C — schema-locking. Locks the receipt contract that S000031–S000035 conform to.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `work-copilot/prompts/qa.prompt.md` (new — 310 lines; 9-step prompt body + locked receipts.qa schema + output contract)
- `work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/TRACKER.fixture.md` (new — fixture tracker with AC-3 uncovered; .fixture.md suffix avoids the work-item walker)
- `work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/PRD.md` (new — declares AC-1, AC-2, AC-3 literals)
- `work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/ARCHITECTURE.md` (new — components affected for the fixture)
- `work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/TEST-SPEC.md` (new — rows for AC-1/AC-2 only; AC-3 intentionally uncovered)
- `work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/milestones.md` (new — fixture milestone stub)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Building /wc-qa first means downstream prompts (S000031–S000035) consume a real schema instead of a guessed one. Codex's "a printer with weak child prompts is theater" applies in reverse: a printer with strong child prompts produces useful drift math, but only if those child prompts agree on what receipts look like — which means /qa has to ship first.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-11: First-run fallback uses `receipts.scaffold` SHA when no `[qa-*]` journal entry exists, instead of `HEAD~N`. SHA-based makes the cross-reference deterministic and lets `/wc-pipeline` validate the timeline later.
- 2026-05-11 [impl-decision] Implemented all 10 SPEC AC stories (Story #1-#10) in `qa.prompt.md` via the 9-step prompt body documented in SPEC §Data Flow. Carried forward all four SPEC Tradeoff choices: receipts location = tracker YAML frontmatter; first-run baseline = `receipts.scaffold` SHA; YAML edit pattern = read-whole/parse/merge/write-whole; Working-Tree Rule severity = hard-stop.
- 2026-05-11 [impl-decision] Fixture extension landed as a new child directory `S999001_uncovered_ac/` under `work-copilot/fixtures/valid-feature-dir/` rather than mutating the existing parent fixture files. Rationale: keeps the day-1 user-story fixture scoped (PRD+ARCHITECTURE+TEST-SPEC+milestones+TRACKER), exercises the uncovered-AC diagnostic (AC-3 declared in PRD but no TEST-SPEC row), and leaves the parent feature fixture untouched for the existing /validate tests.
- 2026-05-11 [impl-finding] qa.prompt.md additionally documents the `[smoke-skip: <reason>]` journal tag (beyond SPEC AC-7's pass/fail pair) so the walk-checklist step can record user-chosen skips without breaking the receipt schema. Surfacing here so downstream prompts (/wc-pipeline) know to treat `[smoke-skip]` as a valid tag.
- 2026-05-11 [impl-finding] qa.prompt.md adds an explicit `feature` and `review` row to the per-type test-row source table (feature delegates to children, review skips test rows). SPEC Step 1 type table doesn't enumerate these but they're implied by the broader bundle scope; making them explicit avoids ambiguity at runtime.
- 2026-05-11 [impl] Wrote 6 new files (work-copilot/prompts/qa.prompt.md + 5 fixture files under work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/). Modified 1 file (this tracker). All 4 testable smoke checks (S1 tools array, S2 schema fields, S3 Working-Tree Rule language, S4 receipts.scaffold fallback) pass against the implemented file.
- 2026-05-11 [impl-auto] Auto-mode run; --auto allowed (2 files touched per Components Affected, no sensitive surface, no active tradeoff alternatives).
- 2026-05-11 [impl-pass] S000030: implementation complete. Phase 2 implementer-owned gates transitioned. QA-owned gates (Acceptance criteria verified met, Smoke tests pass) remain unchecked for /CJ_qa-work-item.
- 2026-05-11 [impl-finding] Post-implement gate caught a MIRROR_SPECS violation: original placement of fixture under `work-copilot/fixtures/valid-feature-dir/S999001_uncovered_ac/` triggered byte-mirror byte-identity FAIL (5 entries with no upstream counterpart in `deprecated/CJ_company-workflow/fixtures/`). Fix: moved fixtures to work-item-local path `fixtures/uncovered_ac/` and renamed `TRACKER.md` → `TRACKER.fixture.md` to dodge the work-items walker (`find -name TRACKER.md`). Re-validate: PASS. SPEC did not surface the MIRROR_SPECS invariant; lesson for downstream stories that touch `work-copilot/` paths: check Error check 10 before adding new bundle files.
- 2026-05-11 [qa-smoke] S1 (AC-1): green — qa.prompt.md exists with the required tools array.
- 2026-05-11 [qa-smoke] S2 (AC-8): green — 31 schema-field grep matches (≥7 required).
- 2026-05-11 [qa-smoke] S3 (AC-6): green — Working-Tree Rule language (`git status --porcelain` + "commit those files first") present.
- 2026-05-11 [qa-smoke] S4 (AC-5): green — `receipts.scaffold` fallback mentioned in prompt body.
- 2026-05-11 [qa-smoke] S5 (AC-1): red — exit code 0 when qa.prompt.md was removed; `./scripts/validate.sh` does NOT enforce existence of `work-copilot/prompts/qa.prompt.md` (parent milestone #2 existence check missing for this file). File was restored intact after the test.
- 2026-05-11 [qa-smoke-summary] red: 4/5 non-manual rows green (0 manual rows pending). S5 surfaced a real gap in validate.sh's existence-check coverage for the new prompt file.

- 2026-05-11 [gate-red] post-QA halt: smoke S5 (AC-1) red — scripts/validate.sh does not enforce existence of work-copilot/prompts/qa.prompt.md. Design Doc Next Steps #2 specifies an existence check but no child story owned it; the SPECs as scaffolded had this gap. Batch aborted at user's direction; S000031–S000035 not implemented. Resume path: revise SPECs to own infra changes OR scaffold T000019_validate_sh_existence_check + T000020_tracker_receipts_stub as separate tasks before re-running per-child /CJ_implement-from-spec.
- 2026-05-11 [qa-smoke] S1 (AC-1): green — qa.prompt.md exists with the required tools array. (re-run after T000019)
- 2026-05-11 [qa-smoke] S2 (AC-8): green — 31 schema-field grep matches (≥7 required). (re-run after T000019)
- 2026-05-11 [qa-smoke] S3 (AC-6): green — Working-Tree Rule language (`git status --porcelain` + "commit those files first") present. (re-run after T000019)
- 2026-05-11 [qa-smoke] S4 (AC-5): green — `receipts.scaffold` fallback mentioned in prompt body. (re-run after T000019)
- 2026-05-11 [qa-smoke] S5 (AC-1): green — `./scripts/validate.sh` exited 1 with FAIL on missing `work-copilot/prompts/qa.prompt.md` (T000019 Error check 10b enforces existence). File restored intact after the test.
- 2026-05-11 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending). T000019 existence-check fix verified — prior S5 red converted to green.
- 2026-05-11 [qa-e2e] E1 (AC-1,2,3,7,8,9): ambiguous — requires interactive Copilot Chat against a target test repo with bundle installed; not verifiable from automated context. Static inspection confirms `work-copilot/prompts/qa.prompt.md` implements the 9-step flow including /validate gate (§Step 1), test-row checklist print (§Step 2), AC extraction + uncovered surfacing (§Step 3), git log paste with receipts.scaffold fallback (§Step 4), Working-Tree Rule hard-stop (§Step 5), checklist walk (§Step 6), READY_FOR_SHIP line (§Step 9), `receipts.qa` write (§Step 8). All structural prerequisites met.
- 2026-05-11 [qa-e2e] E2 (AC-6): ambiguous — Working-Tree Rule hard-stop is encoded in qa.prompt.md §Step 5 ("Please commit those files first and re-invoke /wc-qa; I'll wait."); end-to-end behavioral verification requires interactive Copilot Chat with a dirty fixture. Smoke S3 confirms the language is present in the prompt body.
- 2026-05-11 [qa-e2e] E3 (AC-3,4): ambiguous — uncovered-AC fixture exists at `fixtures/uncovered_ac/` (PRD declares AC-1/2/3; TEST-SPEC only covers AC-1/2). Prompt §Step 3 builds `ac_ids_uncovered` and surfaces it; §Step 7 forces `ready_for_ship: false` when non-empty. Behavioral verification via Copilot Chat against the fixture not run in this re-run pass.
- 2026-05-11 [qa-e2e] E4 (AC-10): ambiguous — YAML parse-failure abort path is encoded in qa.prompt.md §Step 8 ("/wc-qa aborted: tracker frontmatter could not be parsed — fix manually before re-invoking."); behavioral verification requires interactive Copilot Chat against a corrupted fixture. Static inspection confirms the abort branch is present and pre-empts any tracker write.
- 2026-05-11 [qa-e2e-summary] ambiguous: all 4 E2E rows require interactive Copilot Chat with the bundle installed in a target repo; not automatable from the /CJ_qa-work-item context. Static inspection of qa.prompt.md confirms all referenced behaviors are implemented per SPEC. Subagent dispatch (Agent tool) was unavailable in this run.
- 2026-05-11 [qa-partial] Smoke green (5/5); E2E ambiguous (4/4 require interactive Copilot Chat). Per qa.md Step 9, Phase 2 qa-owned gates NOT transitioned (transitions require E2E green or empty). Gates remain: `Acceptance criteria verified met` = [ ], `Smoke tests pass` = [ ]. Re-run after T000019 successfully converted the prior S5 red to green; the E2E ambiguity is structural (no automated harness exists for Copilot Chat verification) and is the same state as if the original first-pass smoke had been green.
