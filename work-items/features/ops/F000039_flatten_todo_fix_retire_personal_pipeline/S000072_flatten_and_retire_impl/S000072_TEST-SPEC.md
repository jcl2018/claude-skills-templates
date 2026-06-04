---
type: test-spec
parent: S000072
feature: F000039
title: "Flatten todo_fix + retire /CJ_personal-pipeline (implementation) — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion (#1-#8). Soft cap is 5 rows/tier; this story is a
     multi-surface sweep + a deletion, so the smoke tier intentionally exceeds
     the cap to give the Check-12/test.sh blind spot and the final grep sweep
     their own dedicated regression rows. Justified per the template's
     "exceed only when justified" note. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-5 | `skills/CJ_personal-pipeline/` is gone | The skill directory was deleted | `test ! -e skills/CJ_personal-pipeline && echo PASS` |
| S2 | integration | AC-7, AC-8 | Live-surface grep sweep is clean | No live file (skills/, scripts/, doc/, rules/, CLAUDE.md, README.md) mentions the deleted skill | `! grep -rI "CJ_personal-pipeline" skills/ scripts/ doc/ rules/ CLAUDE.md README.md` |
| S3 | resilience | AC-6 | validate.sh stays green after Check 12 removal | validate.sh does not error on the deleted pipeline.md; Check 12 block is gone | `./scripts/validate.sh; echo "exit=$?"` (expect exit=0) AND `! grep -nF '[ -x ./scripts/validate.sh ]' scripts/validate.sh` (Check-12 guard token removed) |
| S4 | resilience | AC-6 | test.sh stays green + pipeline.md-guard reference reconciled | test.sh does not red on the deleted pipeline.md (the validate.sh↔test.sh blind-spot pairing) | `./scripts/test.sh; echo "exit=$?"` (expect exit=0) AND `! grep -nF 'CJ_personal-pipeline/pipeline.md' scripts/test.sh` |
| S5 | core | AC-3 | Catalog parses + depends.skills rewritten | skills-catalog.json is valid JSON, has no CJ_personal-pipeline object, and CJ_goal_todo_fix.depends.skills omits it | `jq -e 'any(.[]; .name=="CJ_personal-pipeline") \| not' skills-catalog.json && jq -e '.[] \| select(.name=="CJ_goal_todo_fix") \| (.depends.skills \| index("CJ_personal-pipeline")) == null' skills-catalog.json` |
| S6 | observability | AC-4 | Halt taxonomy renamed | Old halt strings gone, new ones present in todo_fix SKILL.md | `! grep -rE 'halted_at_pipeline_(implement\|qa)' skills/CJ_goal_todo_fix && grep -qE 'halted_at_(impl\|qa)' skills/CJ_goal_todo_fix/SKILL.md` |
| S7 | core | AC-2 | Drain isolation preserved | The `--force-create` worktree-init invocation in drain-one-todo.sh is intact | `grep -qF -- '--caller todo --force-create' skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Single-TODO dry-run shows the flattened chain | Run `/CJ_goal_todo_fix <T-ID> --dry-run` and read the DISPATCH_CHAIN preview | The preview names `/CJ_implement-from-spec` → `/CJ_qa-work-item` as the chain, with no `/CJ_personal-pipeline` and no `--suppress-final-gate` | PASS if the dry-run chain is the flattened impl→qa pair and mentions neither the deleted skill nor the dropped flag |
| E2 | resilience | AC-6, AC-8 | Full gate sweep is green together | From the repo root run `./scripts/validate.sh` then `./scripts/test.sh` then the live-surface `grep -rI` sweep, in one sitting | validate.sh exits 0, test.sh exits 0, grep returns nothing — all three in the same session (proves Check 12 + test.sh were reconciled together) | PASS only if all three pass with no manual edits between them; any red ⇒ the blind-spot pairing was missed |
| E3 | integration | AC-7 | README regenerated, not hand-edited | Run `./scripts/generate-readme.sh`, then `git diff --stat README.md` | README.md regenerates cleanly with no CJ_personal-pipeline entry; the diff is consistent with a generator run (not ad-hoc hand edits) | PASS if regeneration is idempotent (re-running produces no further diff) and README has no personal-pipeline mention |

<!-- post-ship rows: none — all checks are verifiable pre-merge on the worktree. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Live drain run that actually ships impl→qa PRs per TODO | A real drain mutates the repo + opens PRs (Gate #2 fires per PR); too heavyweight for this story's regression suite — covered by the existing drain integration paths | A latent dispatch-wiring bug in drain mode could slip past the static grep (S7) — mitigated by S7 asserting the unchanged isolation block + the prose rewrite review |
| Runtime behavior of the deleted `[qa-severity-scale-fictional]` learning's stale pointer | Informational learning, out of scope; staleness detection is a separate surface | A stale doc pointer to pipeline.md remains until a future learnings sweep — accepted, noted in SPEC Open Questions |
| `work-items/` history references to CJ_personal-pipeline | Explicitly out of scope — history is retained, only LIVE surfaces are swept | None — intended behavior; the S2/AC-8 grep deliberately excludes `work-items/` |
