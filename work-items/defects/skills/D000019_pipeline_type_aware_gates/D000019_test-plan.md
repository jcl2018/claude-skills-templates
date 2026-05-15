---
type: test-plan
parent: D000019
title: "Pipeline gate substrate fixes — Step 7 type-aware halt + sensitive-surface regex extend — Test Plan"
date: 2026-05-14
author: chjiang
status: Draft
---

<!-- Scope: ONE bundled D-defect for both pipeline.md gate substrate bugs.
     6 grep-on-source regression rows + 1 behavior-fixture row. -->

## Scope

The fix is 5 surgical edits to one file: `skills/CJ_personal-pipeline/pipeline.md`.

- Edit #0: orchestrator prelude `TRACKER` + `WORK_ITEM_TYPE` load
- Edit #1: Step 7 type-aware halt branch
- Edit #2a: Step 5.1 regex broaden to `skills/[^/]+/scripts/[^/]+`
- Edit #2b: Step 5.1 type-aware input selection (`$SCAN_INPUTS` aggregator)
- Edit #3: Step 7 Phase 3 dispatch prompt documentation tightening
- Edit #4: Sensitive-Surface Pre-Scan Reference table — new "Skill scripts" row

Testing is inspection-based (grep-on-source + mental walkthrough on synthetic tracker fixtures). Per S000021 defect-type QA semantics (qa.md line 179, 643), smoke IS the verification layer for defects; no live pipeline run required for v1.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Edit #0 prerequisite — TRACKER + WORK_ITEM_TYPE load present at Step 4 trailer (or in each consuming block) | `grep -n 'TRACKER=.*find.*WORK_ITEM_DIR.*TRACKER\.md' skills/CJ_personal-pipeline/pipeline.md` AND `grep -n 'awk .*\\^---\\$.*n==1 .*type:' skills/CJ_personal-pipeline/pipeline.md` | Both greps return ≥1 match | Pending |
| 2 | Edit #1 — Step 7 type-aware halt branch present, fires before strict halt at line ~522 | `grep -n '"\$WORK_ITEM_TYPE" = "defect"' skills/CJ_personal-pipeline/pipeline.md` AND line-number must precede `'Any red/ambiguous'` halt block | Match returned; line precedes existing halt line | Pending |
| 3 | Edit #2a — Step 5.1 regex includes broadened `skills/[^/]+/scripts/[^/]+` pattern | `grep -n 'skills/\[\^/\]+/scripts/\[\^/\]+' skills/CJ_personal-pipeline/pipeline.md` | Match returned in Step 5.1 region (line ~410) | Pending |
| 4 | Edit #2b — Step 5.1 type-aware input selection block present (`$SCAN_INPUTS` aggregator); per-type cases for defect + task | `grep -n 'SCAN_INPUTS=' skills/CJ_personal-pipeline/pipeline.md` AND `grep -nE 'case "\$WORK_ITEM_TYPE".*(defect|task)' skills/CJ_personal-pipeline/pipeline.md` | Both match in Step 5.1 region | Pending |
| 5 | Edit #3 — Step 7 dispatch prompt mentions `E2E=ambiguous` for defect/task with N/A semantics (NOT rewritten as green) | `grep -nE 'E2E=ambiguous.*defect\|task\|N/A.*type' skills/CJ_personal-pipeline/pipeline.md` (case-insensitive); confirm NO occurrence of `for type=defect.*emit.*E2E=green` | Positive match present; rewrite-as-green absent | Pending |
| 6 | Edit #4 — Reference table includes "Skill scripts" row matching `skills/*/scripts/*` | `grep -nE '\\| Skill scripts.*\\| skills/\\*/scripts/\\*' skills/CJ_personal-pipeline/pipeline.md` | Match returned in "Sensitive-Surface Pre-Scan Reference" section (line ~811-825) | Pending |
| 7 | Behavior fixture — synthetic defect tracker mentally executes Edit #0 + Edit #1 correctly | Construct synthetic in-memory: `WORK_ITEM_DIR=work-items/defects/skills/D000019_*` (this very dir); mentally execute Edit #0 awk against `D000019_TRACKER.md`; verify `WORK_ITEM_TYPE` resolves to literal "defect" (frontmatter line `type: defect`); mentally walk Step 7 with `RESULT: SMOKE=green; E2E=ambiguous; PHASE2_GATES=green` — Edit #1's branch fires; pipeline continues silently to Step 8 | Synthetic walkthrough succeeds; `WORK_ITEM_TYPE=defect`; Edit #1 fires; end_state=green path reachable; trace documented in tracker journal as `[finding] 2026-05-14: D000019 fixture walkthrough — Edit #0 awk resolves WORK_ITEM_TYPE=defect; Edit #1 branch fires on ambiguous E2E; continues to Step 8.` | Pending |

## Verification Steps

- [ ] All 6 grep rows return expected matches against post-fix `skills/CJ_personal-pipeline/pipeline.md`.
- [ ] Row 7 behavior fixture documented in tracker journal as `[finding]` entry.
- [ ] `./scripts/validate.sh` exits 0 (no catalog drift, no template drift).
- [ ] `/CJ_personal-workflow check work-items/defects/skills/D000019_pipeline_type_aware_gates/` returns clean (no MISSING / DRIFT findings).
- [ ] No regression in user-story flow: row #2 verifies type-aware branch DOES NOT fire when `WORK_ITEM_TYPE=user-story` (existing strict halt path preserved).
- [ ] F000013 eval suite (`./scripts/eval.sh` or CI workflow) shows no regression in existing user-story eval cases. New defect/task positive-match cases deferred to follow-up.

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.3.0 (Darwin) | claude-skills-templates main @ post-D000019 | Pending |
