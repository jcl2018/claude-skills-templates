---
name: CJ_suggest
description: "Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter. Optional --for-skill / --limit flags pre-filter and extend the candidate window for downstream callers like /CJ_goal_todo_fix."
version: 1.1.0
allowed-tools:
  - Bash
  - Read
---

## Overview

`/suggest` reads this repo's `TODOS.md` (the candidate set) and joins it
against `work-items/**/*_TRACKER.md` YAML frontmatter (the live `status`,
`blocked_by`, `updated` per work item), scores each row, and prints the
top 5 as a markdown table.

Read-only. Stateless. Portable across two TODOS.md conventions:

1. **CJ_personal-workflow shape** — single `## Active work` section gates
   the candidate set; `### Title (P1, S)` headings; joins against
   `work-items/**/*_TRACKER.md`. Full ranking signal (priority, size,
   blocked, recency).
2. **Domain-grouped shape** — work items live under domain-specific `## `
   sections (e.g. `## Dispatcher`, `## Alert Rules`) with no `## Active work`
   gate. Items without the `(Pn, X)` suffix default to P4/M. Sections named
   `## Completed`, `## Done`, `## Archive(d)`, `## Shipped`, or
   `## Deferred work` are excluded.

Detection: presence of `## Active work` switches modes. Tracker join still
works in both — repos without `work-items/` simply degrade to TODOS-only
ranking.

Scoring (locked in design premise #2):

```
score = pri_w + size_w + unblocked - recency_penalty
  pri_w        = P1=4, P2=3, P3=2, P4=1   (default 1)
  size_w       = S=3,  M=2,  L=1          (default 2)
  unblocked    = +2 if joined tracker has empty blocked_by, OR no tracker join
  recency      = age_days / 14            (integer division; 0 if no tracker)
```

Tie-break: alphabetic ascending by title.

Edge cases (design premise #8):
- Missing `TODOS.md` → exit 1 with a clear stderr message.
- No matching active entries → print `No actionable items.` and exit 0.
- No trackers found → degrade to TODOS-only ranking (no recency penalty;
  every row treated as unblocked).

## Flags (S000042 v1.1.0)

`/CJ_suggest` accepts two opt-in flags for downstream-skill integration:

- `--for-skill <name>` — apply a named skill's preflight predicate block at
  ranking time. Rows the named skill would pre-reject are excluded from
  output; one stderr log line per exclusion (`[CJ_suggest] excluded: <id-or-title> reason=<criterion>`).
  v1 supports `cj-goal` only. The cj-goal block mirrors `/CJ_goal_todo_fix`'s
  preflight gates 3-5 (priority P1, size L|XL, sensitive-surface regex on
  body, design-needed keyword on body); gate 1's body-too-vague is omitted
  (vagueness is generic and already handled via the recency penalty), and
  gate 2's missing-suffix is already handled by suggest.sh's default-P4/M
  fallback. Future consumers add new named blocks.
- `--limit N` — extend the top-N output cap beyond the default 5. Default
  preserves byte-identical output for un-flagged callers (interactive
  /suggest users); `/CJ_goal_todo_fix` opts in via `--limit 15`.

The two flags compose: `--for-skill cj-goal --limit 15` is the canonical
`/CJ_goal_todo_fix` invocation (filtered + extended candidate window so /loop /CJ_goal_todo_fix
sessions don't starve when the default top-5 is fully skip-listed).

## Routing

Run the bash script below from the repo root and print its stdout verbatim.
Do not paraphrase or summarize the table; the user wants the raw markdown
to scan. The script's `#!/usr/bin/env bash` shebang pins execution to bash
regardless of which shell the harness dispatches through (D000017 fix:
zsh treats `status`/`pipestatus`/`LINENO` as read-only, fatal when assigned
inside an eval'd bash-shaped block).

```bash
# Default — interactive top-5
bash "$HOME/.claude/skills/CJ_suggest/scripts/suggest.sh"

# Filtered + extended — for /CJ_goal_todo_fix callers
bash "$HOME/.claude/skills/CJ_suggest/scripts/suggest.sh" --for-skill cj-goal --limit 15
```

Resolution rationale: the script always runs from the deployed location at
`~/.claude/skills/CJ_suggest/scripts/suggest.sh` (skills-deploy install puts
it there). The script reads the *current* repo's `TODOS.md` and
`work-items/`, so this stays workbench-portable. Resolving via the workbench
source (`$(git rev-parse --show-toplevel)/skills/...`) was a trust-boundary
hole: any repo that happened to contain that path would have run as the
skill. Workbench developers iterating on the script must
`./scripts/skills-deploy install` to sync changes (the existing convention)
or invoke `bash skills/CJ_suggest/scripts/suggest.sh` directly while testing.

## Notes

- **Surface convention.** Output is markdown to stdout. Same shape as
  `landing-report` so the user can scan-and-pick in under 30 seconds.
- **Heading-only ID extraction.** TODOS body prose often references other
  work items (`Closed by F000014`, etc.). Extracting from the body would
  cause false-positive joins. The regex matches the FIRST
  `\b[FSTD][0-9]{6}\b` in the heading line ONLY.
- **YAML parser fragility.** See FRAGILITY NOTE in the bash body. Pre-ship
  check via test #15 in the test-plan.
- **macOS-compatible date math.** Uses `date -j -f "%Y-%m-%d"` (BSD form),
  not GNU `date -d`.
- **Script-extracted (D000017).** The bash body lives at
  `scripts/suggest.sh` with a `#!/usr/bin/env bash` shebang and
  `set -euo pipefail`. SKILL.md's Routing block invokes it as a one-liner.
  The shebang pins execution to bash regardless of harness shell, fixing
  the zsh `status=` read-only collision that crashed the original inline
  heredoc form.
