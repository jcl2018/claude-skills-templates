---
type: test-plan
parent: T000035
title: "Retire /CJ_goal_investigate (F000031 relocation pattern) — Test Plan"
date: 2026-05-31
author: chjiang
status: Draft
---

<!-- Scope: ONE task — retire /CJ_goal_investigate via F000031 relocation
     pattern. Cases are regression cases for the shim's D-id rejection +
     non-D-id delegation contract, plus catalog/audit-surface drift checks. -->

## Scope

What this task changes:

- `skills/CJ_goal_investigate/` relocated to `deprecated/CJ_goal_investigate/` via `git mv` (pipeline.md + scripts/ preserved as archival reference).
- `deprecated/CJ_goal_investigate/SKILL.md` overwritten with the shim (deprecation banner + D-id rejection regex + routing to `/CJ_goal_defect` for non-D-id args).
- `skills-catalog.json` entry for `CJ_goal_investigate`: `status: deprecated`, `files: ["deprecated/CJ_goal_investigate/SKILL.md"]` (trimmed from 6 → 1), `description` refreshed to match run/auto deprecation banner pattern, `version` synced.
- Six doc/routing surfaces touched: `CLAUDE.md`, `rules/skill-routing.md`, `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `README.md` (regenerated), `TODOS.md` (rows 37/47/81/28-35/70-76).
- New regression test `tests/cj-goal-investigate-shim.test.sh` wired into `scripts/test.sh`.
- VERSION + CHANGELOG entry.

Files/components modified: see TRACKER ## Files section.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Catalog reflects retirement | `jq '.[] | select(.name == "CJ_goal_investigate")' skills-catalog.json` | Returns entry with `status: "deprecated"`, `files: ["deprecated/CJ_goal_investigate/SKILL.md"]` (length 1), `description` matches run/auto deprecation banner pattern (no stale "(v1.0 single-defect mode)" prefix), `version` synced to shipped VERSION | Pending |
| 2 | Source dir relocated | `ls skills/CJ_goal_investigate/ 2>&1` and `ls deprecated/CJ_goal_investigate/SKILL.md` | First command errors (no such dir); second prints the shim SKILL.md path | Pending |
| 3 | Archival pipeline preserved | `ls deprecated/CJ_goal_investigate/pipeline.md deprecated/CJ_goal_investigate/scripts/ 2>&1` | pipeline.md exists; scripts/ dir exists with original test scripts | Pending |
| 4 | Shim D-id rejection (uppercase) | Invoke shim routing with arg `D000019` | Prints rejection error matching `\[DEPRECATED\] /CJ_goal_investigate has been retired\. D-id args cannot be forwarded to /CJ_goal_defect`; does NOT invoke Skill tool / delegate to `/CJ_goal_defect`; exits without minting a new D-id | Pending |
| 5 | Shim D-id rejection (case-insensitive) | Invoke shim routing with arg `d000019` | Same rejection error as #4 (regex `^D[0-9]{6}$` is case-insensitive); does NOT delegate | Pending |
| 6 | Shim non-D-id delegation | Invoke shim routing with arg `"foo bar"` | Prints deprecation banner (mirrors `/CJ_goal_run` banner shape); delegates to `/CJ_goal_defect` with verbatim args via the Skill tool | Pending |
| 7 | Shim banner extraction | `bash` the routing-block extraction snippet from `deprecated/CJ_goal_investigate/SKILL.md` | Prints the deprecation banner (the [DEPRECATED] prefix line) | Pending |
| 8 | Audit-surface drift eliminated | `grep -rn "CJ_goal_investigate" CLAUDE.md README.md doc/ rules/` | Every mention is annotated: either inside `## Retired skills` subsection of `doc/PHILOSOPHY.md`, OR inside `~~strikethrough~~`, OR within 200 chars of `DEPRECATED`/`sunset`/`tombstone` keyword. ZERO un-annotated leaks | Pending |
| 9 | `doc/PHILOSOPHY.md` tombstone present | `grep -A 5 "## Retired skills" doc/PHILOSOPHY.md` | Contains a tombstone paragraph for `/CJ_goal_investigate` mirroring the `/CJ_goal_run` tombstone shape (history + sunset target + replacement + alias-status) | Pending |
| 10 | `doc/PHILOSOPHY.md` decision tree updated | `grep -n "CJ_goal_investigate" doc/PHILOSOPHY.md` outside `## Retired skills` | No occurrences in the active `## Decision tree` section; the "Existing scaffolded defect?" leaf is removed; the routing-table row at line 106 is dropped | Pending |
| 11 | `doc/ARCHITECTURE.md` references annotated/relocated | `grep -n "CJ_goal_investigate" doc/ARCHITECTURE.md` | All references either struck (`~~...~~`), within 200 chars of `DEPRECATED`/`sunset`/`tombstone`, or relocated to a new "Retired" subsection | Pending |
| 12 | `CLAUDE.md` Supporting-skills updated | `grep -n "CJ_goal_investigate" CLAUDE.md` | Line 23 no longer lists `/CJ_goal_investigate` as a Supporting skill; line 71 worktree-prefix row is struck or moved to a "Retired worktree prefixes" sublist; line 263 reads "two cj_goal orchestrator preambles" | Pending |
| 13 | `rules/skill-routing.md` routing row moved | `grep -n "CJ_goal_investigate" rules/skill-routing.md` | Investigate routing row moved to "Deprecated front doors" subsection or dropped entirely | Pending |
| 14 | `README.md` regenerated | Run `./scripts/generate-readme.sh`, then inspect the catalog table | `CJ_goal_investigate` row reflects the new `status: deprecated` + refreshed description | Pending |
| 15 | TODOS:37 marked DONE | `grep -E "^\s*-?\s*\[x\].*TODOS:37" TODOS.md` or the strikethrough pattern | Row marked DONE by /ship Step 14 auto-mark (commit message carries `[via /CJ_goal_feature]` + `Closes TODOS:37`) | Pending |
| 16 | TODOS:47 body updated | `grep -B 2 -A 10 "TODOS:47" TODOS.md` (or the row's heading) | Body reads "five `CJ_goal_*` deprecation shims" (was "four"); includes `deprecated/CJ_goal_investigate/` in the removal list | Pending |
| 17 | TODOS:81 closed | Inspect TODOS:81 row | Row strikethrough'd with OBSOLETE annotation (dogfood-validation row moot once investigate retired) | Pending |
| 18 | TODOS audit (28-35, 70-76) | Inspect TODOS:28-35 + TODOS:70-76 rows | Investigate references dropped OR annotated as post-retirement archival-only | Pending |
| 19 | New regression test in scripts/test.sh | `grep -n "cj-goal-investigate-shim" scripts/test.sh` | Test is wired in; runs as part of the suite | Pending |
| 20 | `./scripts/validate.sh` GREEN | Run `./scripts/validate.sh` | Exit 0; no errors; deprecated-source-resolution (`dirname(files[0])` → `deprecated/CJ_goal_investigate`) works | Pending |
| 21 | `./scripts/test.sh` GREEN | Run `./scripts/test.sh` | Exit 0; all tests including the new shim regression test pass | Pending |
| 22 | VERSION via check-version-queue.sh | Run `./scripts/check-version-queue.sh` | Prints the next free slot (likely v5.0.15 if no concurrent worktrees) | Pending |
| 23 | CHANGELOG entry present | `grep -A 3 "v5\." CHANGELOG.md` (top entry) | One-line summary of the retirement referencing this design doc + TODOS:37 + F000027 closure | Pending |

## Verification Steps

<!-- How was the change verified beyond the test cases above? -->

- [ ] Local `./scripts/validate.sh` exit 0
- [ ] Local `./scripts/test.sh` exit 0 (including new regression test)
- [ ] `jq '.[] | select(.name == "CJ_goal_investigate")' skills-catalog.json` shows deprecated + trimmed `files` + refreshed description
- [ ] `grep -rn "CJ_goal_investigate" CLAUDE.md README.md doc/ rules/` shows zero un-annotated leaks
- [ ] `./scripts/check-version-queue.sh` claims VERSION before `/ship` local bump
- [ ] Manual `bash` extraction of shim routing block confirms banner + D-id rejection + non-D-id delegate paths
- [ ] PR diff reviewed at /ship Gate #2 (human review of sensitive-surface change)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.5.0 (workbench) | branch `cj-todo-20260531-201705-71301` | Pending |
