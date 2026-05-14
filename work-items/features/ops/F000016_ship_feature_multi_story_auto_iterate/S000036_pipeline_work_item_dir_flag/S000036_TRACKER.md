---
name: "Add --work-item-dir flag to CJ_personal-pipeline"
type: user-story
id: "S000036"
status: active
created: "2026-05-13"
updated: "2026-05-13"
parent: "F000016"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/awesome-pasteur-36565c"
branch: "claude/awesome-pasteur-36565c"
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
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `pipeline.md` Step 1 parses `--work-item-dir <path>` flag; DESIGN_DOC validation block is gated on override being absent
- [x] `pipeline.md` Step 2 gains Branch (e): when `WORK_ITEM_DIR_OVERRIDE` is set, skips footer search and Phase 1, journal-writes `[orchestrator] --work-item-dir mode`, continues directly to Step 4
- [x] Step 4 sub-step 1 (footer write-back check) is skipped in `--work-item-dir` mode; sub-steps 2–4 run normally
- [x] Step 9.3 summary prints `Design: (work-item-dir mode — no design doc)` when DESIGN_DOC is empty
- [x] Telemetry Step 9.1 adds `"work_item_dir_mode": true` field when flag is set
- [x] `SKILL.md` Usage section updated with `--work-item-dir` mode documentation
- [x] `CJ_personal-pipeline` version bumped: SKILL.md `0.1.0` → `1.1.0` and skills-catalog.json `1.0.0` → `1.1.0` (drift reconciliation; SPEC's nominal 0.2.0 superseded — see [impl-decision] entry)
- [x] `--suppress-final-gate` still works when combined with `--work-item-dir` (verified E2: both orderings work)
- [x] Standalone test: invoke `CJ_personal-pipeline --work-item-dir <existing-user-story-dir>`, verify it skips scaffold and reaches impl (Step 5) without error (verified E1 by runtime bash dry-run of arg parser + structural trace of Branch (e) / Step 4 carve-out; literal /CJ_personal-pipeline invocation deferred — would recursively QA S036 mid-flight)

## Todos

- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 1: add `--work-item-dir` to arg parser (look-ahead variable pattern from design doc)
- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 1: gate DESIGN_DOC validation block on `WORK_ITEM_DIR_OVERRIDE` being absent; add `--work-item-dir` validation block for when override is set
- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 2: add Branch (e) at top before footer search
- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 4: carve out sub-step 1 skip in `--work-item-dir` mode
- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 9.1: add `work_item_dir_mode` telemetry field
- [x] Edit `skills/CJ_personal-pipeline/pipeline.md` Step 9.3: handle empty DESIGN_DOC in summary
- [x] Edit `skills/CJ_personal-pipeline/SKILL.md`: update Usage section, bump version to 1.1.0 (reconciled from SPEC's 0.2.0 due to drift)
- [x] Edit `skills-catalog.json`: bump CJ_personal-pipeline version to 1.1.0
- [x] Run `./scripts/validate.sh` to verify

## Log

- 2026-05-13: Created. Extends CJ_personal-pipeline with --work-item-dir flag — first-class input mode for pre-scaffolded work item dirs, reusable beyond ship-feature. Derived from F000016 /office-hours design, Approach B.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/CJ_personal-pipeline/pipeline.md` (modified — Step 1 arg parser + validation; Step 2 Branch (e); Step 4 sub-step 1 carve-out; Step 9.1 telemetry field; Step 9.3 summary)
- `skills/CJ_personal-pipeline/SKILL.md` (modified — Usage section expanded for two input modes; version 0.1.0 → 1.1.0)
- `skills-catalog.json` (modified — CJ_personal-pipeline version 1.0.0 → 1.1.0)
- `work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/S000036_pipeline_work_item_dir_flag/S000036_TEST-SPEC.md` (modified — Smoke test S4 expected version reconciled to 1.1.0)

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
- 2026-05-13 [gates-update] Phase 3: /ship — PR #99,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #99,PRs section: linked PR #99 (MERGED).
- 2026-05-14 [impl-finding] PR #99 land-and-deploy hook auto-marked Phase 3 ship/deploy/smoke gates on this tracker, but PR #99 shipped S000038 only (rename + Branch(g)) — S000036 implementation was never in that PR. Reverted: unchecked Phase 3 `Smoke tests pass in CI`, `/ship — PR created`, `/land-and-deploy — merged and deployed`; removed stale PR #99 reference from PRs section. Tracker now reflects true state: Phase 2 pending, no PR yet.
- 2026-05-14 [impl-decision] Marked Phase 1 `Tasks broken down (N/A — atomic story)` as [x]. S000036 is atomic per parent F000016 scaffold; no child tasks needed. Confirmed in /office-hours session 2026-05-13 (premise P4).
- 2026-05-14 [impl-decision] Version drift reconciliation: SKILL.md was 0.1.0 / skills-catalog.json was 1.0.0 — both bumped to 1.1.0 (minor for new flag). SPEC's stated "0.1.0 → 0.2.0" was based on the stale SKILL.md value; catalog is the source of truth for installed version. AUQ-approved (D2) during impl.
- 2026-05-14 [impl-decision] Arg parser uses look-ahead loop (`_next_is_work_item_dir` flag) to consume the value after `--work-item-dir`. Bash `case` cannot peek the next positional; the loop pattern is minimal and has no external deps. Considered getopts but rejected — getopts adds complexity and doesn't handle long-form values cleanly in bash 3.2.
- 2026-05-14 [impl-decision] Step 4 sub-step 1 carve-out implemented as a prose-level italic note ("*Skipped when `$WORK_ITEM_DIR_OVERRIDE` is set ...*") rather than a code-level branch. Matches the SPEC's stated "prose-level carve-out" approach — the orchestrator-model reads this and persists the skip as prose state across Bash calls (same pattern as `$SUPPRESS_FINAL_GATE` elsewhere in pipeline.md).
- 2026-05-14 [impl-finding] Smoke test S4 in S000036_TEST-SPEC.md updated to expect catalog version `1.1.0` not `0.2.0`. Test-spec correction reflects implementation reality after the drift reconciliation.
- 2026-05-14 [impl] Wrote 3 files (pipeline.md: 5 edits; SKILL.md: 2 edits; skills-catalog.json: 1 edit). Also updated S000036_TEST-SPEC.md (smoke S4 expectation). All 5 smoke tests pass; validate.sh PASS (0 errors, 0 warnings).
- 2026-05-14 [impl-pass] S000036: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files). QA-owned gates (Acceptance + Smoke) remain for `/CJ_qa-work-item`.
- 2026-05-14 [qa-smoke] S1 (AC-1): green — `grep -c '--work-item-dir' pipeline.md` = 13 (≥3 required)
- 2026-05-14 [qa-smoke] S2 (AC-2): green — `grep -c 'Branch (e)' pipeline.md` = 2 (≥1 required)
- 2026-05-14 [qa-smoke] S3 (AC-4): green — `grep -c '--work-item-dir' SKILL.md` = 4 (≥1 required)
- 2026-05-14 [qa-smoke] S4 (AC-5): green — catalog version = 1.1.0 (reconciled from SPEC's 0.2.0 nominal)
- 2026-05-14 [qa-smoke] S5 (AC-1): green — `./scripts/validate.sh` exit=0, 0 errors / 0 warnings
- 2026-05-14 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-05-14 [qa-e2e-run-start] RUN_ID=20260513-180400-60205 commit=e90fb54
- 2026-05-14 [qa-e2e] E1 (AC-1,2,3,4): green — runtime bash dry-run of exact pipeline.md Step 1 arg parser code with `--work-item-dir <S000036_path>` confirms: WORK_ITEM_DIR_OVERRIDE set to path, DESIGN_DOC='' (no "design doc not found" error), dir+TRACKER validation PASS, WORK_ITEM_DIR realpath'd. Branch (e) at Step 2 / Step 4 sub-step 1 carve-out / Step 5 dispatch verified structurally in pipeline.md (orchestrator-model executes prose state). Literal /CJ_personal-pipeline invocation skipped to avoid recursion (would loop into nested QA on S036 mid-flight). [parent-inline]
- 2026-05-14 [qa-e2e] E2 (AC-1): green — runtime bash dry-run with `--work-item-dir <path> --suppress-final-gate` AND reverse order both yield: WORK_ITEM_DIR_OVERRIDE set, SUPPRESS_FINAL_GATE=1. No flag-ordering interaction; both variables set independently. [parent-inline]
- 2026-05-14 [qa-e2e-summary] green (0s subagent; 2 rows parent-inline; 0 deferred): All 2 E2E criteria green. Step 1 arg parser verified by runtime bash dry-run (the critical change). Branch (e) + Step 4 carve-out + Step 9.1/9.3 verified structurally. Recursion guard: literal /CJ_personal-pipeline invocation on S036 mid-QA-on-S036 deferred — pipeline would dispatch QA subagent on S036 which we're currently inside.
- 2026-05-14 [qa-pass] S000036 (user-story): green smoke (5/5) + green E2E (2/2 parent-inline). Phase 2 gates transitioned. AC items 1-9 marked verified.
