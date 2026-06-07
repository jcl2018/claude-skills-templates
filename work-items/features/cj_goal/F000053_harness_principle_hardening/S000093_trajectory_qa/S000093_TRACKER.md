---
name: "Trajectory QA — QA that cannot lie about correctness"
type: user-story
id: "S000093"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000053"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/tender-elion-267bd0"
branch: "claude/tender-elion-267bd0"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
receipts:
  qa:
    phase: 3
    commit: "9491e0236f2c4d4fd9117e63c413cfa2ac473155"   # QA-time HEAD (working tree; impl committed in the same PR immediately after)
    completed_at: "2026-06-07T04:59:17Z"
    test_rows_run: 6
    ac_ids_covered: [AC1, AC2, AC3, AC4, AC5]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-e2e-summary] green (E1+E2 PASS, independent inspection)", "[qa-pass] S000093 green smoke + green E2E"]
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
2. Create working branch: `git checkout -b feat/trajectory_qa` (or use parent's branch if shipping in same PR)
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

- [x] AC1: On a same-SHA resume, QA re-validates (re-runs smoke + checks the execution receipt) and re-runs the expensive ~5-min E2E subagent ONLY when the receipt is missing, incomplete, or stale-SHA. A date-only `[qa-pass]` from an earlier commit no longer satisfies the `qa.md` Step 3 NO-OP short-circuit.
- [x] AC2: QA writes an execution receipt capturing {test commands run, timestamp, commit SHA, one pass/fail row per acceptance-criterion / test-row}, matching the `receipts.qa` schema (`completed_at`, `test_rows_run`, `ac_ids_covered`/`ac_ids_uncovered`, `diff_audit.changed_files_without_tests`, `ready_for_ship`).
- [x] AC3: QA fails closed — a missing or incomplete receipt ⇒ RED; every acceptance-criterion must have a passing row to read GREEN.
- [x] AC4: An "edited but never executed" work-item (artifacts present, no execution receipt) is flagged RED, not silently passed.
- [x] AC5: Re-execution is idempotent in its WRITES — no duplicate Phase-2 gate transitions and no journal thrash (reuse the `qa.md` Step 6.5 run-start marker).

## Todos

<!-- Actionable items for this story. -->

- [x] Close the `qa.md` Step 3 date-only NO-OP branch (the `[qa-pass]` dated-today short-circuit) so it requires a valid receipt
- [x] Add execution-receipt emission to `skills/CJ_qa-work-item/qa.md` (adopt the `receipts.qa` schema)
- [x] Add the fail-closed verdict (missing/incomplete/stale receipt ⇒ RED; every AC needs a passing row to read GREEN)
- [x] Change `skills/CJ_goal_feature/pipeline.md` resume so `LAST_PHASE ∈ {qa, ship}` on a still-valid SHA re-dispatches QA (or a cheap receipt re-validate) instead of phase-skipping
- [x] Reuse the `qa.md` Step 6.5 run-start marker for write-idempotency on re-execution
- [x] Add the execution-receipt block to the tracker template under `templates/CJ_personal-workflow/` (commented `# receipts:` ref — no-ripple home)
- [x] Add smoke + E2E test rows per TEST-SPEC; map each AC to a passing row (rows scaffolded in TEST-SPEC; AC-mapping verified at /CJ_qa-work-item)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Story 1 of F000053 — close the two GAP A skip paths so a resumed user-story/feature QA re-verifies (re-runs smoke + checks an execution receipt; re-runs E2E only on missing/incomplete/stale receipt) and fails closed instead of trusting a date-keyed `[qa-pass]` marker or an orchestrator phase-skip.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_qa-work-item/qa.md` — MODIFIED: Step 3 resume re-validation gate (date-only NO-OP dropped), Step 6.5 write-idempotency note, Step 7 E2E-revalidation guard, Step 9.0 receipt emission + fail-closed verdict
- `skills/CJ_goal_feature/pipeline.md` — MODIFIED: Step 3.3 always re-dispatch QA on resume (+ general-rule carve-out at the phase-skip statement)
- `templates/CJ_personal-workflow/tracker-user-story.md` — MODIFIED: commented `# receipts:` schema reference (no-ripple home; mirrors `# pr:`)
- `scripts/test.sh` — MODIFIED: added the "F000053/S000093 trajectory-QA regression guards" static-grep block (the 4 smoke rows' real CI assertions — date-only NO-OP gone + RECEIPT_VOUCHES_HEAD present, receipts.qa schema, fail-closed verdict, Step 6.5 idempotency anchor, pipeline.md re-dispatch). Added at the smoke-row review (the SPEC's test.sh row was conditional on a validate.sh check; the smoke rows needed real assertions regardless, else they were hollow).

## Insights

<!-- Non-obvious findings worth remembering. -->

- The dangerous skip is the date-only branch of `qa.md` Step 3's OR condition: a same-day earlier-commit `[qa-pass]` marker satisfies the NO-OP even when behavior changed. The HEAD-match branch is fine; the date-match branch is the hole.
- Defect/task QA already re-runs unconditionally (`CJ_goal_defect/pipeline.md:857`) and a stale SHA already demotes qa→impl — so this gap is the user-story/feature path specifically, not all three verbs. Defect/task QA is out of scope.
- The two skip paths are independent fixes in two files: the `qa.md` marker logic AND the `pipeline.md` phase-granular resume. Name and fix both; closing only one leaves the other hole open.
- Do not unconditionally re-pay the ~5-min E2E budget on every resume (`qa.md:539`) — receipt-validate is cheap, E2E re-run is the expensive path gated on missing/incomplete/stale receipt.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-06 (decision): Adopt work-copilot's `receipts.qa` frontmatter schema (`work-copilot/prompts/qa.prompt.md:222-285`) verbatim rather than inventing a new receipt shape — the design's Premise 4 "do not reinvent." Story 3 of F000053 will reuse this same schema (one schema, not two).
- 2026-06-06 [impl-decision] Receipt home = work-item tracker FRONTMATTER `receipts.qa` (runtime-written by qa.md Step 9), NOT a new template section/field — the validator (`check.md`) flags only MISSING template keys/sections, so a runtime extra key is tolerated while adding to the template would ripple `[MISSING]` onto every existing user-story tracker. The template documents it as a commented `# receipts:` ref mirroring `# pr:`.
- 2026-06-06 [impl-decision] Extended work-copilot's locked `receipts.qa` schema with a `commit` field (the SHA the receipt vouches for) — the schema contract permits adding fields; `commit` is exactly what Step 3's stale-SHA re-validation needs.
- 2026-06-06 [impl-decision] Honored AC1 literally: a resume with gates checked re-runs smoke (cheap) and gates only the ~5-min E2E re-run on the receipt vouching HEAD; no early-exit NO-OP remains (the date-only NO-OP was the GAP-A hole). Idempotency moved to the WRITES (Step 6.5 marker), per AC5.
- 2026-06-06 [impl] Edited 3 files: `skills/CJ_qa-work-item/qa.md` (Step 3 resume re-validation gate, Step 6.5 note, Step 7 E2E guard, Step 9.0 receipt + fail-closed verdict), `skills/CJ_goal_feature/pipeline.md` (Step 3.3 always re-dispatch QA on resume + the carve-out), `templates/CJ_personal-workflow/tracker-user-story.md` (commented `# receipts:`). propose-and-confirm mode; sensitive surfaces (qa.md/pipeline.md/template) approved via AUQ. No `validate.sh` check ⇒ no `test.sh` fixture.
- 2026-06-06 [impl-pass] S000093: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-215707-94208 commit=9491e02
- 2026-06-06 [qa-e2e] E1 PASS (independent inspection): date-only NO-OP removed (qa.md Step 3 "no date-keyed short-circuit"); gates-checked re-validates; missing receipt ⇒ fail-closed RED (Step 9.0). AC1+AC3.
- 2026-06-06 [qa-e2e] E2 PASS (independent inspection): RECEIPT_VOUCHES_HEAD (commit==HEAD + ready_for_ship + ac_ids_uncovered empty) ⇒ E2E_REVALIDATE=false; Step 7 guard skips the ~5-min E2E re-run; smoke still re-runs. AC1+AC2.
- 2026-06-06 [qa-e2e-summary] green (independent inspection subagent ~60s; 0 parent-inline; 0 deferred): both E2E scenarios PASS + orchestrator pipeline.md Step 3.3 re-dispatch confirmed.
- 2026-06-06 [qa-finding] test.sh WAS modified this story (the earlier [impl] entry predates it): added the "F000053/S000093 trajectory-QA regression guards" static-grep block at the operator's election — the smoke rows S1-S4 needed real CI assertions, not a hollow whole-suite run. Files section corrected.
- 2026-06-06 [qa-pass] S000093 (user-story): green smoke (bash scripts/test.sh, incl. the S000093 guards) + green E2E (E1+E2 independent inspection). receipts.qa written to frontmatter (commit=9491e02, the QA-time HEAD/working-tree; impl committed in the same PR immediately after — a future resume at the merged SHA will re-validate, which is correct). Phase 2 QA-owned gates transitioned.
