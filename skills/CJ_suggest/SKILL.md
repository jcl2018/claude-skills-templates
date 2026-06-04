---
name: CJ_suggest
description: "Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter. Internal phase-step skill rows (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, *-workflow validators) are filtered by default; pass --include-internal to surface them. Optional --for-skill / --limit flags pre-filter and extend the candidate window for downstream callers like /CJ_goal_todo_fix."
version: 1.2.0
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

## Flags

`--include-internal` (v1.2.0): by default, rows whose heading or body mention
an internal phase-step skill are excluded from output so the top-5 surfaces
user-facing top-level work. The filter catches:

- `CJ_personal-workflow`, `CJ_company-workflow` (deprecated validator)
- `CJ_scaffold-work-item`, `CJ_implement-from-spec`, `CJ_qa-work-item`
- Pre-v4.0 unprefixed forms with leading slash (`/scaffold-work-item`,
  `/implement-from-spec`, etc.) for legacy TODOs that predate the rename.

Each excluded row emits one stderr line: `[CJ_suggest] excluded: <id-or-title>
reason=internal-skill (<matched-name>)`. Pass `--include-internal` to surface
these rows when you genuinely need to drill into a phase step.

Rationale: top-level pipelines (`/CJ_goal_run`, `/CJ_goal_todo_fix`,
`/CJ_goal_investigate`) and standalone utilities (`/CJ_system-health`,
`/CJ_improve-queue`) are the "what should I work on next" surface. Phase-step
work usually surfaces transitively when the orchestrator gets exercised.

## Flags (S000042 v1.1.0)

`/CJ_suggest` accepts two opt-in flags for downstream-skill integration:

- `--for-skill <name>` — apply a named skill's preflight predicate block at
  ranking time. Rows the named skill would pre-reject are excluded from
  output; one stderr log line per exclusion (`[CJ_suggest] excluded: <id-or-title> reason=<criterion>`).
  v1 supports `cj-goal` only. The cj-goal block mirrors `/CJ_goal_todo_fix`'s
  preflight gates 3-5 (priority P1, size L|XL, sensitive-surface regex on
  body, design-needed keyword on body) and adds three heading-level gates
  that catch rows drain mode would halt on at preflight: date-trigger H2
  section (e.g. `## Scheduled checkpoints`), `YYYY-MM-DD —` heading prefix,
  and terminal-marker literals in the title (`WON'T FIX`, `SUPERSEDED`,
  `SHIPPED`, `RESOLVED`). Gate 1's body-too-vague is omitted (vagueness is
  generic and already handled via the recency penalty), and gate 2's
  missing-suffix is already handled by suggest.sh's default-P4/M fallback.
  Future consumers add new named blocks.
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

- **Surface convention (S000076 render fork).** Output shape forks on
  `--for-skill`:
  - **Default (no `--for-skill`)** — a scannable **card list** for the
    interactive operator. One card per ranked item: a header line
    `N. [ID] Title   Pri · <effort-label>` (the `[ID]` segment is omitted when
    the row carries no `[FSTD]NNNNNN` id), a `What:` line (the first non-empty
    prose line of the TODO body, or `(no description)` when the body is empty),
    and a `Status:` line that folds the live tracker status together with the
    existing Why reasons. Effort label = the Size letter expanded: `S → quick
    (<1h)`, `M → ~half-day`, `L → large (1-2 days)`.
  - **`--for-skill <name>`** — the byte-stable markdown **table** (`Rank | Title
    | Pri | Size | Status | Why`) the machine consumers parse. `/CJ_goal_todo_fix`
    reads candidate titles from column 2 via `awk -F'|'`, so this path's output
    is held byte-identical; only the interactive default render changed in
    S000076. Scoring, candidate selection, ranking, and the Why reasons are
    identical across both paths — only the top-N rendering differs.
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
