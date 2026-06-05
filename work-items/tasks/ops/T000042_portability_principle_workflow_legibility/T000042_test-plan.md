---
type: test-plan
parent: T000042
title: "Document the portability principle + workflow legibility + honest Category badges — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — a doc change (PHILOSOPHY + WORKFLOWS) plus a small
     skills-catalog.json relabel. Cases are concrete + reproducible: the test
     surface is validate.sh + test.sh staying green, /CJ_portability-audit green
     after the relabel, and a read-through of the new prose. -->

## Scope

Three doc/catalog parts (one coherent change):

1. `doc/PHILOSOPHY.md` — adds the portability principle (producer-vs-consumer; the
   strict `standalone < local-only < workbench` tier ladder; the
   honesty / verified-invariant framing; references `/CJ_portability-audit` +
   `/CJ_repo-init`; NOT added to `## Decision tree`).
2. `doc/WORKFLOWS.md` — adds a `**Category:**` (portability tier) badge beside the
   existing `**Status:**` on every `## Orchestrators` section AND every
   `## Utilities & phase-step skills` entry; adds a `## How the machinery works`
   glossary (cj-goal-common.sh phases, cj-worktree-init.sh, cj-worktree-cleanup.sh,
   the `/CJ_document-release` doc-sync wrapper, the resume state file); adds a short
   per-workflow narrative under each orchestrator chart.
3. `skills-catalog.json` — relabels `CJ_goal_feature`, `CJ_goal_defect`,
   `CJ_goal_todo_fix`, `CJ_personal-workflow` to `portability: workbench` and removes
   their `portability_requires`; `CJ_repo-init` is left unchanged.

No code/script changes. Files modified: `doc/PHILOSOPHY.md`, `doc/WORKFLOWS.md`,
`skills-catalog.json`, and `TODOS.md` (one appended follow-up row for the deferred
doc-vs-catalog Category drift check).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `validate.sh` stays green (incl. Check 15/15a/15b registered-doc + tracked-doc manifest, and Check 18 portability advisory) | `./scripts/validate.sh; echo "exit=$?"` | `exit=0`; no new ERROR; Check 15b still passes for the orchestrator sections; Check 18 advisory exit 0 | Pending |
| 2 | `test.sh` full suite stays green | `./scripts/test.sh; echo "exit=$?"` | `exit=0` (superset of validate; no regressions) | Pending |
| 3 | `/CJ_portability-audit` is green after the relabel (FINDINGS=0) | `./scripts/cj-portability-audit.sh; echo "exit=$?"` | `exit=0`; aggregate `FINDINGS=0`; every skill verdict is `portable` or `portable-with-notes` | Pending |
| 4 | `--no-adjudication` now surfaces ONLY `CJ_repo-init` | `./scripts/cj-portability-audit.sh --no-adjudication` | The only finding-bearing skill is `CJ_repo-init` (the relabeled 4 no longer appear; they are now within-tier `workbench`) | Pending |
| 5 | Catalog relabel applied correctly | `jq -r '.[] \| select(.name=="CJ_goal_feature" or .name=="CJ_goal_defect" or .name=="CJ_goal_todo_fix" or .name=="CJ_personal-workflow") \| "\(.name) \(.portability) requires=\(.portability_requires // "ABSENT")"' skills-catalog.json` | All four print `portability=workbench` and `requires=ABSENT` (field deleted) | Pending |
| 6 | `CJ_repo-init` left unchanged | `jq -r '.[] \| select(.name=="CJ_repo-init") \| "\(.portability) requires=\(.portability_requires // "ABSENT")"' skills-catalog.json` | Prints `standalone` with a non-ABSENT `portability_requires` (untouched) | Pending |
| 7 | PHILOSOPHY states the portability principle and does NOT pollute the decision tree | Read-through of `doc/PHILOSOPHY.md`: confirm the new principle covers producer-vs-consumer, the tier ladder, the honesty/verified-invariant framing, references `/CJ_portability-audit` + `/CJ_repo-init`; then confirm `## Decision tree` was NOT given a portability routing row | Principle present + complete; decision tree unchanged (New-skills check still green — no routable skill added/removed) | Pending |
| 8 | WORKFLOWS Category badges present + honest | Read-through of `doc/WORKFLOWS.md`: every `## Orchestrators` section and every `## Utilities & phase-step skills` entry has a `**Category:**` line; values match the honest post-relabel table (orchestrators + `CJ_personal-workflow` + `CJ_document-release` + `CJ_portability-audit` = workbench; `CJ_suggest` = local-only; the rest standalone; `CJ_repo-init` standalone w/ debt note) | All sections carry a `**Category:**` line beside `**Status:**`; values match the table; badges agree with the post-relabel `skills-catalog.json` | Pending |
| 9 | WORKFLOWS `## How the machinery works` glossary + per-workflow narratives present | Read-through: a `## How the machinery works` section exists after the orchestrator charts with per-helper explainers for `cj-goal-common.sh` (sync/worktree/pr-check/ship/cleanup/telemetry), `cj-worktree-init.sh`, `cj-worktree-cleanup.sh`, `/CJ_document-release`, and the resume state file; each orchestrator chart has a 2-3 sentence narrative referencing the glossary | Glossary present + accurate vs the current scripts/steps; each orchestrator has a narrative paragraph | Pending |
| 10 | Registered-doc audit clean (no doc self-staled by the change) | Confirm the `doc/WORKFLOWS.md` + `doc/PHILOSOPHY.md` `requirement:` strings in CLAUDE.md's tracked-doc manifest are still satisfied by the edited docs | Both verdicts `up-to-date`; no `stale:` finding introduced | Pending |
| 11 | Follow-up TODO filed, not built (Open Question 1) | `grep -n "Category" TODOS.md` (or scan for the doc-vs-catalog drift-check row) | One new row describing the deferred doc-vs-catalog `Category` drift check; NO new `validate.sh` check implemented in this PR | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exit 0 (Linux/macOS)
- [ ] `./scripts/test.sh` exit 0 (full suite)
- [ ] `./scripts/cj-portability-audit.sh` FINDINGS=0; `--no-adjudication` lists only `CJ_repo-init`
- [ ] `skills-catalog.json` relabel verified via `jq` (cases 5 & 6)
- [ ] Manual read-through of the new PHILOSOPHY principle + WORKFLOWS badges/glossary/narratives for accuracy against the current scripts and the post-relabel catalog values

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin) + bash | cj-feat-20260604-165723-57005 | Pending |
