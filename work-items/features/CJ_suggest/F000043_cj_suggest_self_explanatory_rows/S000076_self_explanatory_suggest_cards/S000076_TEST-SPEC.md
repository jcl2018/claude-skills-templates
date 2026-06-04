---
type: test-spec
parent: S000076
feature: F000043
title: "Self-explanatory suggest cards — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | integration | AC-2 | Capture `--for-skill` output against a fixture TODOS.md; diff against the committed expected table | Consumer table is byte-stable so `/CJ_goal_todo_fix` keeps parsing | `bash skills/CJ_suggest/scripts/suggest.sh --for-skill cj-goal --limit 15 \| diff - tests/fixtures/suggest-consumer-table.expected` |
| S2 | usability | AC-1 | Run no-flag `suggest.sh` on a fixture; assert output contains `What:` and `Status:` card markers and a `· ` effort separator | Default path emits the card layout, not the table | `bash skills/CJ_suggest/scripts/suggest.sh \| grep -qE '^What:' && ... grep -qE '^Status:'` |
| S3 | usability | AC-3 | Fixture row with Size `S` (and `M`, `L`); assert the card shows `quick (<1h)` / `~half-day` / `large (1-2 days)` | Size letter expands to the effort label | `bash skills/CJ_suggest/scripts/suggest.sh \| grep -q 'quick (<1h)'` |
| S4 | resilience | AC-4 | Fixture row with an empty body; assert the card prints `What: (no description)` | Empty-body fallback renders, no blank card | `bash skills/CJ_suggest/scripts/suggest.sh \| grep -q 'What: (no description)'` |
| S5 | resilience | AC-4 | Run with no TODOS.md (expect exit 1) and with an actionable-empty TODOS.md (expect `No actionable items.` + exit 0) | Edge cases preserved across the render change | `rm TODOS.md; suggest.sh; [ $? -eq 1 ]` and `suggest.sh \| grep -q 'No actionable items.'` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1, AC-3 | Operator picks next work from cards | Run `/CJ_suggest` (no flags) against the real workbench TODOS.md | A scannable card list: each item shows ID (when present), title, `Pri · Effort` label, a `What:` line, and a `Status:` line | Pass if a reader can tell what each top item does and how big it is without opening TODOS.md |
| E2 | integration | AC-2 | Drain consumer still works | Run `/CJ_goal_todo_fix --dry-run` (or invoke the candidate-parse path) after the change | `/CJ_goal_todo_fix` parses the same candidates it did before — no parse error, identical selection | Pass if drain mode ranks/selects identically to pre-change behavior |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Quality of the `What:` line for arbitrary real TODOS bodies | It tracks TODOS.md authoring, not skill logic; no deterministic assertion possible | A low-signal first body line yields a low-signal card — fix is better authoring, not code |
| `--table` interactive override | Out of scope for v1 (deferred follow-up) | Operators have no interactive way to force the old table; accepted until asked for |
