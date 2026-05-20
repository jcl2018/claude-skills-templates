---
type: test-plan
parent: T000034
title: "v5.0.0 alias removal — delete /CJ_run and /CJ_goal — Test Plan"
date: 2026-05-19
author: test
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Nine mechanical surfaces implementing Approach A (minimal cut) from the source
design doc — 6 deletions/migrations + 3 documentation bumps that together
remove the `/CJ_run` and `/CJ_goal` aliases and ship v5.0.0:

1. `skills/CJ_run/` — `git rm -r` (alias skill removed).
2. `skills/CJ_goal/` — `git rm -r` (alias skill removed).
3. `skills-catalog.json` — remove the two catalog entries via jq rewrite.
4. `rules/skill-routing.md` — drop the "Legacy aliases" block.
5. `README.md` — regenerate via `scripts/generate-readme.sh` (drops table rows).
6. `tests/eval/CJ_goal/` → `tests/eval/CJ_goal_todo_fix/` — `git mv` + content rewrite (~25 inline references).
7. `CLAUDE.md` — remove the legacy-aliases line.
8. `VERSION` — bump `4.6.15` → `5.0.0`.
9. `CHANGELOG.md` — prepend a `## v5.0.0` entry with breaking-change + canonical-name migration.

Plus one follow-up TODO row appended to `TODOS.md` (P3/S — post-v5.0.0
telemetry fallback-read cleanup) so the deferred cosmetic work isn't lost.

The deprecation contract is honored: operators who still type `/CJ_run` after
upgrade get a "command not found" error (or equivalent — the skill is gone
from `~/.claude/skills/` post-`skills-deploy install`).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Alias skill dirs deleted | After Edits 1+2: `ls skills/CJ_run skills/CJ_goal 2>&1` | Both paths return `No such file or directory`. | Pending |
| 2 | Catalog entries removed | After Edit 3: `jq '[.[] | select(.name == "CJ_run" or .name == "CJ_goal")] | length' skills-catalog.json` AND `jq 'length' skills-catalog.json` (compare to pre-edit length). | First returns `0`; second is exactly `pre-edit length - 2`. | Pending |
| 3 | Skill-routing rule block removed | After Edit 4: `grep -c 'Legacy aliases (v4.x grace window' rules/skill-routing.md` | Returns `0`. | Pending |
| 4 | README regenerated cleanly | After Edit 5 (`scripts/generate-readme.sh` re-run after Edit 3): `grep -E '^\| (CJ_run\|CJ_goal) \|' README.md` | Returns empty (no table rows for the deleted aliases). | Pending |
| 5 | Test fixture migration + content rewrite | After Edit 6: `[ -d tests/eval/CJ_goal_todo_fix ] && [ ! -d tests/eval/CJ_goal ]` AND `grep -r '/CJ_goal\b' tests/eval/CJ_goal_todo_fix/` | First check passes (dir renamed); second returns empty (all inline references rewritten to `/CJ_goal_todo_fix`). | Pending |
| 6 | CLAUDE.md legacy-aliases line removed | After Edit 7: `grep -c 'Legacy aliases /CJ_run and /CJ_goal' CLAUDE.md` | Returns `0`. | Pending |
| 7 | VERSION bumped to 5.0.0 | After Edit 8: `cat VERSION` | Outputs `5.0.0` (no trailing whitespace beyond a single newline). | Pending |
| 8 | CHANGELOG v5.0.0 entry prepended | After Edit 9: `head -20 CHANGELOG.md` | Begins with a `## v5.0.0` header explaining the breaking change, deprecation timeline (v4.0.0 → v4.6.15), and canonical-name migration (`/CJ_run` → `/CJ_goal_run`, `/CJ_goal` → `/CJ_goal_todo_fix`). | Pending |
| 9 | Follow-up TODO row appended | After Edit 10: `grep -i 'post-v5.0.0 telemetry fallback' TODOS.md` | Returns one row with a P3/S tag noting the ~20 LOC cleanup across the 4 referenced files. | Pending |
| 10 | `validate.sh` passes | After all edits: `./scripts/validate.sh` | Exit 0. Catalog/filesystem coherence preserved (skill dirs deleted AND catalog rows deleted in lockstep). No orphaned-skill or unbacked-catalog-entry findings. | Pending |
| 11 | `test.sh` passes | After all edits: `./scripts/test.sh` | Exit 0. Eval-fixture resolution still works after the `tests/eval/CJ_goal/` → `tests/eval/CJ_goal_todo_fix/` rename (`scripts/eval.sh` iterates `tests/eval/*/`, no hardcoded path). | Pending |
| 12 | Eval-nightly wiring unaffected | Inspect `.github/workflows/eval-nightly.yml` AND `scripts/eval.sh` for hardcoded `tests/eval/CJ_goal` references. | Neither file hardcodes the old path; both iterate `tests/eval/*/`. No CI workflow changes required by Edit 6. | Pending |
| 13 | `work-copilot/` bundle untouched | After all edits: `grep -rE 'CJ_(run\|goal)([^_]\|$)' work-copilot/` | Returns empty (bundle never referenced the aliases). | Pending |
| 14 | Post-deploy: `/CJ_run` errors on a fresh session | After `gh pr merge --squash --delete-branch` + `git pull` + `./scripts/skills-deploy install` on an operator machine: type `/CJ_run` in a fresh Claude Code session. | Errors with "command not found" (or equivalent — skill is gone from `~/.claude/skills/`). | Pending (manual, post-deploy) |
| 15 | Post-deploy: `/CJ_goal` errors on a fresh session | Same as #14 but type `/CJ_goal`. | Errors with "command not found" (or equivalent). | Pending (manual, post-deploy) |
| 16 | Post-deploy: `/CJ_goal_run` and `/CJ_goal_todo_fix` still work | After deploy: type `/CJ_goal_run --help` and `/CJ_goal_todo_fix --help` in a fresh session. | Both skills resolve and print their usage. Canonical-name path unaffected. | Pending (manual, post-deploy) |
| 17 | PR squash-merge succeeds | After `/ship` creates the PR: `gh pr merge <PR#> --squash --delete-branch` (no `--auto`) THEN `gh pr view <PR#> --json state -q .state` | Second command outputs `MERGED`. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` passes (catalog/filesystem coherence preserved).
- [ ] `./scripts/test.sh` passes (eval fixtures resolve after rename + content rewrite).
- [ ] Manual: `grep -rE 'CJ_(run|goal)([^_]|$)' .` from repo root returns ONLY (a) the rewritten test-fixture references in `tests/eval/CJ_goal_todo_fix/`, (b) historical-record entries in `T000026_TRACKER.md` + `T000027_TRACKER.md`, (c) the v5.0.0 CHANGELOG entry, and (d) telemetry fallback-read lines in `skills/CJ_goal_run/` + `skills/CJ_goal_todo_fix/` (explicitly deferred). No active routing surface remains.
- [ ] Manual: read the CHANGELOG v5.0.0 entry from an operator's perspective — one paragraph; clear breaking change; canonical-name migration without requiring deeper context.
- [ ] Manual: post-merge, on a fresh checkout (`git pull origin main`), run `./scripts/skills-deploy install` and confirm `ls ~/.claude/skills/CJ_run ~/.claude/skills/CJ_goal 2>&1` returns `No such file or directory` for both.

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS, workbench (claude-skills-templates main) | current branch | Pending |
| post-deploy operator (fresh Claude Code session after `git pull` + `skills-deploy install`) | v5.0.0 | Pending (manual) |
