---
type: test-plan
parent: T000028
title: "/CJ_goal validate.sh hardcode breaks downstream /loop drain (Approach D) — Test Plan"
date: 2026-05-15
author: test
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Four mechanical edits implementing Approach D from the source design doc:

1. `scripts/goal.sh` lines ~523-528 — DELETE the post-scaffold `./scripts/validate.sh` if-block (validate is now duplicate work; pipeline Step 6 re-runs it).
2. `skills/CJ_personal-pipeline/pipeline.md` Step 6 item 2 — UPDATE description: `validate.sh` is "workbench-only — skipped silently when absent or non-executable".
3. `scripts/goal.sh` awk newline block — SURGICAL fix to the affected awk block only (do NOT globally mutate `RESOLVED_BODY` — it's used in 3 places including sensitive-surface scan at ~line 289-290).
4. `skills/CJ_goal/SKILL.md` Notes "Workbench-only scope" paragraph — UPDATE to reflect TODOS.md source convention; workbench is v1 dev/test location; validate.sh check runs when present.

Halt-on-red contract is preserved: workbench (validate.sh exists & executable) → pipeline Step 6 halts on red as today.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Workbench: validate.sh present → pipeline Step 6 still gates | After Edit 1 (goal.sh DELETE) and Edit 2 (pipeline.md guard update): in `claude-skills-templates` repo, run /CJ_personal-pipeline against a scaffolded work-item where validate.sh would fail (e.g., a deliberately broken catalog entry). | Pipeline Step 6 halts with `[gate-red]`. validate.sh runs as today (workbench behavior bit-identical). | Pending |
| 2 | Workbench: goal.sh no longer halts at scaffold step | After Edit 1: in `claude-skills-templates` repo, run /CJ_goal "<fragment>" against a TODO that passes preflight. | goal.sh proceeds past the (now-deleted) line ~526 validate call straight to the dispatch handoff. No `halted_at_scaffold` from validate.sh. | Pending |
| 3 | Downstream: portfolio /loop /CJ_goal drains | After all 4 edits: in `~/projects/portfolio` (downstream repo with no validate.sh), run /CJ_goal against a tagged TODO. | goal.sh scaffolds, dispatches; /CJ_personal-pipeline Step 6 silently skips validate.sh (per pipeline.md doc-as-code guard); pipeline completes preflight → scaffold → dispatch → Step 6 without `halt halted_at_scaffold` AND without `[gate-red]` from missing validate.sh. | Pending (manual verification against `~/projects/portfolio`) |
| 4 | Awk newline warning cleared | After Edit 3 (surgical awk fix): run /CJ_goal against a TODO whose body contains a newline (e.g., multi-line body). | No `awk: newline in string` warnings emitted; resulting test-plan.md has no body-fragment leak in adjacent table cells. | Pending |
| 5 | Sensitive-surface scan unchanged | After Edit 3: run /CJ_goal against a TODO whose body explicitly mentions a sensitive surface (e.g., `skills-catalog.json`). | Gate 4's sensitive-surface regex still trips on the body. `RESOLVED_BODY` content untouched at line ~289-290 (surgical fix did not regress Gate 4 behavior). | Pending |
| 6 | SKILL.md note reads coherent | After Edit 4: read `skills/CJ_goal/SKILL.md` Notes section. | "Workbench-only scope" paragraph no longer claims absolute restriction; reads as "TODOS.md source convention; workbench is where v1 was developed and tested; validate.sh check runs when present" or equivalent. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `scripts/validate.sh` passes in this workbench (no regression on the workbench harness itself).
- [ ] Manual reproduction in `~/projects/portfolio`: run `/loop /CJ_goal` against a tagged TODO; verify it drains at least one TODO end-to-end (preflight → scaffold → dispatch → /CJ_personal-pipeline) without `halted_at_scaffold` AND without `awk: newline in string`.
- [ ] Read the diff of `scripts/goal.sh` to confirm only the targeted awk block was modified — `RESOLVED_BODY` unchanged at the insights-injection site and the sensitive-surface-scan site (~line 289-290).
- [ ] pipeline.md Step 6 item 2 reads naturally — guard semantics clear to a future reader.

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS, workbench (claude-skills-templates main) | current branch | Pending |
| local macOS, downstream (~/projects/portfolio, no validate.sh) | as-of fix | Pending (manual) |
