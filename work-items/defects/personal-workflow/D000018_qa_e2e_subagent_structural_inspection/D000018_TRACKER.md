---
name: "/CJ_qa-work-item E2E subagent does structural inspection instead of real verification"
type: defect
id: "D000018"
status: active
created: "2026-05-11"
updated: "2026-05-11"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/admiring-kowalevski-0ec061"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/qa_e2e_subagent_structural_inspection`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-admiring-kowalevski-0ec061-qa-e2e-design-20260511-151535.md`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. Take any user-story with TEST-SPEC E2E rows that describe user-facing flows (not just code structure verification).
2. Run `/CJ_qa-work-item <work-item-dir>`.
3. Observe in tracker journal:
   - `[qa-e2e] E# (...): ambiguous — <structural inspection of source>`
   - `[qa-e2e-summary] ambiguous` (or `mixed`)
4. Phase 2 qa-owned gates remain unchecked.

**Environment:** Claude Code 2.1.91; reproduces deterministically.

## Todos

- [x] Edit `skills/CJ_qa-work-item/qa.md` Step 7 prompt to add `Skill` to the subagent's tool list (lines ~299-301)
- [x] Add Step 4.5 (or inline in Step 4): per-row tool-need classifier with four categories — `read-only`, `skill-invoking`, `interactive`, `recursive`
- [x] Add Step 7.5: parent-inline execution for `interactive` and `recursive` rows (full toolbelt available)
- [x] Update Step 8 verdict aggregator to merge `[qa-e2e]` entries from both sources (subagent + parent-inline) keyed by row number
- [x] Update `skills/CJ_qa-work-item/SKILL.md` Overview + per-type table to mention the classifier and parent-inline path
- [x] Append a 2026-05-11 re-probe note to `tests/spike/subagent-capabilities/findings.md` documenting `SKILL=yes` for both subagent types
- [ ] Verify `scripts/validate.sh` and `scripts/test.sh` exit 0
- [ ] Bootstrap dogfood: re-run `/CJ_qa-work-item` on `work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item` and confirm it still passes
- [x] Cap parent-inline rows to 5 per run (R3 mitigation); surplus rows mark ambiguous with "deferred to manual"
- [x] Document the row-classifier heuristic and provide an explicit `Tag: e2e-parent` override marker for TEST-SPEC rows (R2 mitigation)

## Log

- 2026-05-11: Created. /CJ_qa-work-item E2E subagent silently degrades to structural source inspection when E2E rows require Skill invocation, AskUserQuestion, or recursive Agent dispatch. Root cause: Step 7 prompt's tool-list omission (Skill missing) + AUQ/Agent absent from subagent context. Scaffolded from design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-admiring-kowalevski-0ec061-qa-e2e-design-20260511-151535.md`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_qa-work-item/qa.md`
- `skills/CJ_qa-work-item/SKILL.md`
- `tests/spike/subagent-capabilities/findings.md`

## Insights

- The recurring "ambiguous via structural inspection" pattern across S000027, S000028, S000022, S000020, S000030 was masked as a known subagent limitation; the actual cause is a prompt blind spot — the subagent DOES have the Skill tool (re-probed 2026-05-11), but the Step 7 prompt explicitly lists only Read/Bash/Grep/Glob, so the subagent obediently never uses Skill.
- The 2026-05-09 spike (S000026 findings.md) correctly identified AUQ + Agent absence in subagent context. It did NOT audit the qa.md Step 7 prompt text, which is where the largest blind spot lived.
- Subagent type swap (`claude` vs `general-purpose`) doesn't help — both have identical tool surfaces today (re-probed 2026-05-11).
- The "orchestrator pre-collects" pattern from S000026 generalizes: orchestrator runs the rows the subagent can't (interactive, recursive), subagent runs what it can. Approach B in the design doc applies this pattern to E2E classification.

## Journal

- [decision] 2026-05-11: Selected Approach B (Approach A's prompt fix + parent-inline classifier for AUQ/recursion rows) over A (prompt fix only) and C (hoist all E2E to parent, no subagent dispatch). B addresses all three root-cause issues and preserves the fresh-context subagent for rows it can handle. Summary: A is fallback if scope pushback; C abandons design intent.
- [finding] 2026-05-11: Subagent has `Skill=yes` confirmed by re-probe of both `subagent_type: "claude"` and `"general-purpose"`. AUQ and Agent confirmed absent in both. Premise basis for Approach B classifier categories.
- 2026-05-11 [impl-decision] Applied Approach B (per RCA Fix Description and Phase 2 Step 1 design doc reference). Step 7 stable preamble now lists Skill alongside Read/Bash/Grep/Glob with an explicit instruction not to substitute structural source inspection for /skill invocation. Step 4.5 classifier partitions E2E rows into four tool-need categories; ambiguity defaults to parent-inline (safer fallback). Step 7.5 runs interactive/recursive rows in parent context using the full toolbelt; capped at 5 rows per run with a soft 5-min per-row wall-clock cap (R3 mitigation). Step 8 aggregates `[qa-e2e]` entries from both sources by row number using the trailing `[parent-inline]` source tag for audit (verdict math joins by E#).
- 2026-05-11 [impl-decision] Identical journal-entry shape across both execution paths (`- {date} [qa-e2e] {E#} ({AC}): {verdict} — {summary} [parent-inline]`); only the trailing source tag differs. Rationale: makes Step 8's aggregator a simple row-number join with verdict-word lookup; avoids two-shape parsing logic and matches the RCA Regression Risk mitigation for verdict-aggregation correctness.
- 2026-05-11 [impl-decision] Smoke-red short-circuit (Step 6) gates parent-inline execution: Step 7.5 sits after Step 6 in the document so the same skip/abort branches apply. Idempotency contract (Step 3) is preserved unchanged — Step 4.5 runs before any side effects, and a NO-OP run still short-circuits at Step 3 before touching the classifier.
- 2026-05-11 [impl-finding] Step 4.5 explicit-override mechanism uses the `Tag` column's `e2e-parent` token (R2 mitigation). TEST-SPEC authors can force parent-inline classification by adding the tag, which makes the deterministic escape hatch grep-discoverable (`grep -n 'e2e-parent' TEST-SPEC.md`) without needing to extend the doc-TEST-SPEC.md template's schema.
- 2026-05-11 [impl-finding] 2026-05-11 re-probe note appended to `tests/spike/subagent-capabilities/findings.md` corrects the implication-by-omission in the 2026-05-09 spike. The earlier spike's leg (a) and leg (b) results remain correct; the new note clarifies that Skill=yes for both subagent types and the Step 7 prompt-text was the actual blind spot, not subagent capability.
- 2026-05-11 [impl-finding] --auto demoted to propose semantically (3 files touched, ≥ the trivial threshold of 2). Pre-collected AUQ answers from orchestrator confirmed no sensitive-surface forks (none of the three components matches catalog/manifest/validator/template/git-hooks), so the safety override was satisfied; --auto run continued under propose-equivalent treatment with all writes journaled.
- 2026-05-11 [impl] Edited 3 files: `skills/CJ_qa-work-item/qa.md` (Step 4.5 added; Step 7 preamble + variable parts updated; Step 7.5 added; Step 8 rewritten as two-source aggregator; Subagent Contract + Parent-Inline E2E Contract + Spec Deviations updated), `skills/CJ_qa-work-item/SKILL.md` (Overview describes the classifier + parent-inline path; per-type table updated), `tests/spike/subagent-capabilities/findings.md` (appended 2026-05-11 re-probe note). 6 journal entries added before this one. Phase 2 implementer-owned gates (`RCA doc updated`, `Todos section reflects remaining work`) transitioned; `Fix committed` left for `/ship`.
- 2026-05-11 [impl-auto] Auto-mode run; --auto demoted to propose-equivalent per safety override (3 files > 2-file trivial cap). No sensitive surface (catalog/manifest/validator/template/git-hooks all untouched).
- 2026-05-11 [impl-pass] D000018: implementation complete. Phase 2 implementer-owned gates transitioned (`RCA doc updated`, `Todos section reflects remaining work`); `Fix committed` is user/`/ship`-owned and remains unchecked.
- 2026-05-11 [qa-smoke] 1 (test-plan row): green — `grep -n 'Skill' skills/CJ_qa-work-item/qa.md` exit 0; Step 7 preamble tool-list line at L357 grants `Read, Bash, Grep, Glob, AND Skill tools` (matches expected)
- 2026-05-11 [qa-smoke] 2 (test-plan row): green — classifier mapping found at qa.md:229-232 (`read-only` / `skill-invoking` / `interactive` / `recursive` four-category table); grep exit 0
- 2026-05-11 [qa-smoke] 3 (test-plan row): green — `## Step 7.5: Parent-Inline E2E (interactive / recursive rows)` present at qa.md:441; runs full toolbelt before subagent dispatch per Step 4.5 partition
- 2026-05-11 [qa-smoke] 4 (test-plan row): green — Step 8 region (qa.md:504-565) aggregates `[qa-e2e]` entries by row number from both sources (line 506: "Aggregate `[qa-e2e]` entries from both sources by row number"); grep exit 0
- 2026-05-11 [qa-smoke] 5 (test-plan row): green — `./scripts/validate.sh` exit 0; Errors=0, Warnings=0, RESULT: PASS
- 2026-05-11 [qa-smoke] 6 (test-plan row): green — `./scripts/test.sh` exit 0; Failures=0, RESULT: PASS (full suite including T000006, S000010, T000011, test-deploy, check-version-queue)
- 2026-05-11 [qa-smoke-manual] 7 (test-plan row): pending human verification — re-run `/CJ_qa-work-item work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item` and confirm smoke + E2E produce non-`ambiguous` verdicts. Recursive skill dispatch (spawns subagents); free-form prose Steps; deferred to manual.
- 2026-05-11 [qa-smoke-manual] 8 (test-plan row): pending human verification — re-run `/CJ_qa-work-item skills/CJ_qa-work-item/fixtures/example-user-story` and confirm S1+S2 smoke pass, E1 still red (planted bug intact). Recursive skill dispatch; deferred to manual.
- 2026-05-11 [qa-smoke-manual] 9 (test-plan row): pending human verification — after test #7 passes, re-run `/CJ_qa-work-item` on S000019 dir and confirm NO-OP per Step 3 idempotency. Sequential/conditional prose; deferred to manual.
- 2026-05-11 [qa-smoke] 10 (test-plan row): green — `grep -nE 'parent-inline|classifier' skills/CJ_qa-work-item/SKILL.md` matches at L87 (per-type table mentions classifier partition) and L93 (Overview describes parent-inline path); exit 0
- 2026-05-11 [qa-smoke] 11 (test-plan row): green — `grep -n '2026-05-11' tests/spike/subagent-capabilities/findings.md` matches at L70 (`## 2026-05-11 Re-probe: Skill tool surface (D000018)`) and L121; exit 0
- 2026-05-11 [qa-smoke-manual] 12 (test-plan row): pending human verification — construct a custom TEST-SPEC mixing read-only + interactive rows; run `/CJ_qa-work-item`; confirm aggregator produces single coherent verdict with no double-counted rows. Construction + recursive skill dispatch; deferred to manual.
- 2026-05-11 [qa-smoke-summary] green: 8/8 non-manual rows green (4 manual rows pending)
- 2026-05-11 [qa-pass] D000018 (defect): green smoke from test-plan rows (12 rows: 8 automated green, 4 manual_pending deferred to human). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
- 2026-05-11 [ship-review-finding] Adversarial review (Claude + Codex) during /ship Step 11 surfaced 3 silent-failure bugs in the new Step 8 aggregator that would activate on the next user-story QA: (a) no run-boundary scoping ("appended during this run" had no implementation — prior runs' entries could pollute the verdict), (b) row-number regex `E1` would match `E10`/`E11` on TEST-SPECs with ≥10 E2E rows, (c) pre-D000018 entries (no source tag) would be absorbed as subagent entries. All three are dormant on this defect's own QA (defect type, no aggregator path), but live on the next user-story QA. User chose to fix-before-ship.
- 2026-05-11 [impl-decision] D000018 follow-on edits to qa.md addressing the 3 ship-review findings: (1) added Step 6.5 "E2E Run Marker" — orchestrator writes `[qa-e2e-run-start] RUN_ID=... commit=...` to journal before any `[qa-e2e]` entry; (2) rewrote Step 8 Step-1 to scope aggregation to entries AFTER the latest marker line; (3) Step 8 Step-2 specifies anchored regex `\[qa-e2e\] (E[0-9]+) \(` with the trailing ` (` as anchor to prevent E1/E10 collision; (4) added `[parent-inline]` source tag to deferred-row journal entries (Step 7.5.1) for uniform source bookkeeping; (5) updated Subagent Contract + Parent-Inline E2E Contract + Spec Deviations to document the new format and run-marker semantics. All R5/R6 mitigations now in qa.md.
- 2026-05-11 [impl-pass] D000018 (post-review): qa.md updates landed; validate.sh clean (0 errors, 0 warnings); test.sh clean (full suite still PASS). 3 ship-review findings closed.
