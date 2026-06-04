---
type: design
parent: F000044
title: "Portable POSIX runtime (date + OS gate) — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic story. This DESIGN.md is a brief stub; the full problem shape,
     big decisions, and rejected alternatives live in the parent feature's
     design. See parent F000044_DESIGN.md for context. -->

## Problem

`/CJ_suggest` and `/CJ_improve-queue` hard-refuse off macOS (`[ "$(uname -s)" !=
"Darwin" ]` at `skills/CJ_suggest/scripts/suggest.sh:7` and
`skills/CJ_improve-queue/scripts/improve_queue.sh:76`) and use BSD-only `date -j
-f` (`suggest.sh:284`, `improve_queue.sh:676`). On WSL2 (uname=Linux) they refuse
outright; even past the gate, GNU date has no `-j`. `/CJ_suggest`'s refusal
cascades into `/CJ_goal_todo_fix` ranking. See parent F000044_DESIGN.md for the
full problem statement.

## Shape of the solution

Two edits per script: (1) inline a feature-probe `date_to_epoch()` helper that
selects GNU `date -d` vs BSD `date -j -f` by probing `date --version`, replacing
the `date -j -f` calls; (2) widen the OS gate from a Darwin-only refuse to a
`case` allowlist (`Darwin|Linux|MINGW*|MSYS*`) that refuses only a truly-unknown
OS. The helper is inlined into BOTH scripts (not shared in `scripts/lib.sh`)
because deployed skill scripts under `~/.claude/skills/` cannot source the repo's
`scripts/`. See parent F000044_DESIGN.md `## Shape of the solution`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | OS detection by feature-probe (`date --version`) not a uname branch | Git Bash ships GNU coreutils, so the probe selects the GNU branch correctly where a uname=Darwin/Linux split would mis-route. See parent F000044_DESIGN.md. |
| 2 | Inline `date_to_epoch` per script, not shared in `scripts/lib.sh` | Deployed skill scripts under `~/.claude/skills/` can't source the repo's `scripts/` at runtime. See parent F000044_DESIGN.md. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Bare-date parse divergence (GNU fills local midnight, BSD current wall-clock) | Within a day — below the `age_days = epoch/86400` resolution; TEST-SPEC S1 asserts age within 1 day of macOS. |
| Drop the OS gate entirely and rely on `date_to_epoch` portability, or keep an allowlist? | Resolve during S000078 implement. See parent F000044_DESIGN.md for full risk table. |

## Definition of done

- [ ] Both scripts run (not refuse) with correct date math on Linux/WSL2; both gates allow Darwin|Linux|MINGW*|MSYS* and refuse unknown; ubuntu CI exercises a check_darwin-gated path. See parent F000044_DESIGN.md `## Definition of done`.

## Not in scope

- True WSL2 / native-Windows CI runners — ubuntu-latest is the Linux proxy. See parent F000044_DESIGN.md `## Not in scope` for the full boundary.

## Pointers

- Parent feature design: [../F000044_DESIGN.md](../F000044_DESIGN.md)
- Parent tracker: [../F000044_TRACKER.md](../F000044_TRACKER.md)
- Story tracker: [S000078_TRACKER.md](S000078_TRACKER.md)
- SPEC: [S000078_SPEC.md](S000078_SPEC.md)
- TEST-SPEC: [S000078_TEST-SPEC.md](S000078_TEST-SPEC.md)
