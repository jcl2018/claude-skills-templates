---
type: test-plan
parent: T000017
title: "suggest-skill — Test Plan"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Add a new single-file slash-command skill `/suggest` that prints a top-5 ranked next-up list from `TODOS.md` headings joined to work-items tracker frontmatter (status, blocked_by, updated). Read-only, stateless, this-repo-only.

Files modified:
- `skills/suggest/SKILL.md` — new. Frontmatter (`name: suggest`, `version: 0.1.0`, `allowed-tools: [Bash, Read]`) + bash body implementing the 6-step pipeline (band-pass, regex parse, tracker walk, score, sort, render markdown table).
- `skills-catalog.json` — modified. Add catalog entry per the design's literal shape (`status: experimental`, `portability: local-only`, single file, no templates, no skill deps).
- `README.md` — modified (regenerated via `scripts/generate-readme.sh`). Picks up the new Skills-table row.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Basic invocation produces a 5-row table | 1. Run `/suggest` from this repo's root. | Output is a markdown table with header row + up to 5 data rows. Columns: Rank, Title, Pri, Size, Status, Why. Runtime under 3 seconds. | Pending |
| 2 | Strikethrough/DONE/RETIRED entries are excluded | 1. Confirm TODOS.md has at least one `~~strikethrough~~` heading in `## Active work`. 2. Run `/suggest`. | The strikethrough heading does NOT appear in any of the 5 output rows. | Pending |
| 3 | Deferred section is excluded | 1. Confirm TODOS.md has entries under `## Deferred work`. 2. Run `/suggest`. | No row in the output table comes from a heading under `## Deferred work`. | Pending |
| 4 | P1 items surface when present | 1. Confirm at least one active P1 entry exists in TODOS.md. 2. Run `/suggest`. | At least one P1 row appears in the top 5. | Pending |
| 5 | Tracker join enriches Status column | 1. Pick a TODOS.md heading whose title starts with a known work-item ID (e.g., `### F000013 ... (P1, M)`). 2. Run `/suggest`. | The corresponding row's Status column reflects that tracker's `status` field (e.g., `active`, `done`). Why column omits `(orphan)` for that row. | Pending |
| 6 | Orphan rows are labeled | 1. Pick a TODOS.md heading with no leading `[FSTD][0-9]{6}` ID token. 2. Run `/suggest`. | If that row is in the top 5, its Why column contains `(orphan)`. | Pending |
| 7 | Blocked items show blocker | 1. Pick or temporarily edit a tracker so its `blocked_by` field is non-empty (e.g., `blocked_by: "F000020"`). 2. Re-run `/suggest`. | That row's Why column contains `blocked by F000020`; unblocked bonus (+2) is NOT applied to its score. (Restore the tracker after the test.) | Pending |
| 8 | Recency penalty applied to stale items | 1. Identify a tracker whose `updated` is >14 days old. 2. Run `/suggest`. | If that row appears, its Why column contains `stale Nd` where N matches `(today - updated) / 14 * 14` approximately. Score reflects the penalty. | Pending |
| 9 | Idempotent — re-runs produce identical output | 1. Run `/suggest` and capture output to `/tmp/run1.md`. 2. Immediately re-run and capture to `/tmp/run2.md`. 3. `diff /tmp/run1.md /tmp/run2.md`. | Diff is empty (byte-identical output). No state files written between runs. | Pending |
| 10 | Read-only — no mutations to TODOS.md or trackers | 1. `git status` baseline. 2. Run `/suggest`. 3. `git status`. | `git status` after run shows zero working-tree changes (no modifications to TODOS.md, work-items/, or any state file). | Pending |
| 11 | Missing TODOS.md → exit 1 with clear message | 1. Temporarily move TODOS.md aside (`mv TODOS.md TODOS.md.bak`). 2. Run `/suggest`. 3. Restore TODOS.md. | Skill exits non-zero with a clear stderr message naming TODOS.md as the missing file. | Pending |
| 12 | No matching active entries → graceful empty output | 1. Temporarily replace TODOS.md `## Active work` body with only strikethrough entries (or empty). 2. Run `/suggest`. 3. Restore TODOS.md. | Output is `No actionable items.` (or equivalent), exit 0, no traceback. | Pending |
| 13 | No trackers found → degrade to TODOS-only ranking | 1. Temporarily rename `work-items/` (`mv work-items work-items.bak`). 2. Run `/suggest`. 3. Restore. | Output still produces 5 rows; all rows have `(orphan)` Why; no recency penalty applied. Exit 0. | Pending |
| 14 | Defaults for missing `(Pn, X)` suffix | 1. Confirm at least one TODOS.md heading lacks the `(P{1-4}, {S\|M\|L})` suffix (or temporarily add one). 2. Run `/suggest`. | That row, if it appears, is treated as P4 priority and M size per design premise #3. Why column reflects the default. | Pending |
| 15 | YAML frontmatter parser fragility check passes | 1. Run `find work-items -name '*_TRACKER.md' -exec awk '/^---$/{f=!f;next} f && /^[a-z_]+:.*:/' {} +`. | Output is empty (no tracker frontmatter has a value containing `: `). If non-empty, the awk parser is unsafe and migration to `yq` is required before ship. | Pending |
| 16 | Ranking sanity-check (eyeball test) | 1. Run `/suggest` against current repo state. 2. Manually scan TODOS.md and pick what feels like the top 5. 3. Compare. | At least 3 of the 5 model picks match the human picks (rough qualitative agreement). If <3, tune scoring weights and re-iterate. | Pending |
| 17 | Tie-break is alphabetic ascending by title | 1. Construct two entries with identical computed scores (same Pri, Size, blocked status, recency). 2. Run `/suggest`. | The earlier-alphabetic title appears first in the table. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` passes post-change (catalog ↔ filesystem consistency for the new `suggest` entry).
- [ ] `./scripts/test.sh` passes post-change (full repo test suite).
- [ ] Running `/suggest` completes in under 3 seconds on the current TODOS.md + ~12 trackers (timed via `time /suggest` or manual stopwatch).
- [ ] Output table renders correctly in the Claude Code chat (markdown table parses; no broken pipe characters or column misalignment).
- [ ] Manual eyeball test: the user (chjiang) can scan the top 5 and pick a thing in under 30 seconds without referring back to TODOS.md.
- [ ] No new stderr noise during normal invocation (compare `2>/tmp/suggest.err` against an empty baseline).

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 / zsh / git 2.x | claude/quizzical-panini-a78b33 | Pending |
