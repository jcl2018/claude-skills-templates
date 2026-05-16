---
type: design
parent: F000025
title: "Default worktree for /CJ_goal_run + /CJ_goal_todo_fix — Feature Design"
version: 1
status: Approved
date: 2026-05-16
author: chjiang
reviewers: ["plan-ceo-review", "plan-eng-review (Claude+Codex)", "plan-devex-review"]
---

<!-- Distilled from /office-hours design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-default-worktree-design-20260516-121928.md
     The full design doc — including original 3-approach trade-off table, /autoplan
     dual-voice Eng review with 12 mechanical fixes, and CEO/DX scorecards — is
     the canonical source-of-truth. This file is the feature-level distillation. -->

## Problem

The three top-level CJ_goal_* orchestrators (`/CJ_goal_run`, `/CJ_goal_investigate`,
`/CJ_goal_todo_fix`) assume current-branch execution. Invoked from the main checkout
on `main`, they create a feature branch on top of `main` directly and run the whole
pipeline there — polluting the main checkout, blocking parallel sessions, and
contradicting CLAUDE.md's documented convention that "day-to-day work happens inside
a git worktree under `.claude/worktrees/{name}/`."

The user already runs 17+ active worktrees under `.claude/worktrees/` (mostly
Conductor-managed). The CJ_goal_* family is the one entry point that doesn't honor
that pattern. The fix is "default to a worktree": each orchestrator detects whether
it is already inside a worktree (Conductor case) and, if not, creates one before any
code-changing phase fires.

## Shape of the solution

One shared bash helper (`scripts/cj-worktree-init.sh`) + per-skill preamble integration.
Approach B from the design doc — chosen over duplicate-per-skill preambles (Approach A)
and a new wrapper skill (Approach C, over-build).

**Scope cut (Open Q5):** `/CJ_goal_investigate` source-of-truth lives on an unmerged
worktree (`immutable-watching-sparrow`, branch `add-fid-collision-detection-todo`).
Workbench main has no `skills/CJ_goal_investigate/` dir. Scoped OUT of this PR;
deferred TODOS.md row added for the followup once the parent worktree lands.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Shared bash helper + caller integrations (CJ_goal_run + CJ_goal_todo_fix) + 5-case helper test + test.sh regression assertion + TODOS deferred row + CLAUDE.md note | S000054 | [S000054_default_worktree_helper_and_callers/S000054_TRACKER.md](S000054_default_worktree_helper_and_callers/S000054_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Shared bash helper (Approach B) over per-skill duplicate preambles (Approach A) | Three callers means the duplication tax is real; helper is the cheapest abstraction that pays for itself by the second caller. Mirrors existing extraction patterns (scripts/todo_fix.sh, drain-one-todo.sh, skills-update-check). |
| 2 | JSON output, parsed with `jq -r '.field'` — NOT `KEY=VALUE` + eval | Both Eng reviewers (Claude + Codex) independently flagged eval-injection via WORKTREE_NOTE. JSON encoding + jq parsing keeps stdout strictly a string value; zero shell-injection surface. |
| 3 | Helper invocation goes BEFORE the existing `_REPO_ROOT` Path Resolution block | `cd` after `git worktree add` invalidates pre-cd `_REPO_ROOT` / `_SKILL_DIR`; running helper first means paths resolve against the post-cd worktree. |
| 4 | Branch/path name: `cj-{run|inv|todo}-{YYYYMMDD-HHMMSS}-{PID}` | PID suffix prevents same-second collision in drain mode (consensus from both Eng reviewers). Matches existing `RUN_ID` convention. |
| 5 | Helper checks `git diff --quiet && git diff --cached --quiet`; halts on dirty main | Silent abandonment of uncommitted edits violates the feature's isolation purpose. Interactive: halt with clear message. `--quiet`: STATE=skipped, run in-place. |
| 6 | Helper invocation conditional on `[ $# -gt 0 ]` | `/CJ_goal_run` no-arg Branch (g) auto-resume must run on current branch; wrapping it silently breaks resume semantics. Detected by Claude subagent in Eng review. |
| 7 | `--force-create` flag bypasses in-worktree detection | Drain-loop from `drain-one-todo.sh` runs from inside a Conductor parent worktree but each drained TODO needs its own worktree+branch+PR. Without --force-create every drained TODO no-ops into the same parent. |
| 8 | Worktree path uses `git rev-parse --show-toplevel` (not cwd-relative) | Cwd-relative `.claude/worktrees/${name}` breaks when caller invoked from a subdirectory. |
| 9 | Visible WARN (not silent no-op) when helper unreachable on main | Silent no-op defeats feature purpose; user needs to know the helper didn't fire. Emits `[worktree] WARN: helper unreachable; running on current branch`. |
| 10 | Explicit caller→prefix map (run→cj-run, investigate→cj-inv, todo→cj-todo) | Naming inconsistency surfaced by Codex; `inv` over `investigate` for branch-name compactness. |
| 11 | `[worktree] <note>` echo gated on `${QUIET:-0} != 1` | Today's design violates the `--quiet` success criterion; gating fixes it. |
| 12 | `drain-one-todo.sh` resolves helper via BASH_SOURCE relative path (not manifest read) | Avoids duplicate workbench-source resolution; the script already lives inside the workbench tree. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Helper unreachable on a consumer repo without `.skills-templates.json` | Mitigated by the visible-WARN path; graceful no-op preserves today's behavior |
| `git worktree add` fails on first attempt (transient collision) | Helper retries once with `-$$-$RANDOM` suffix before declaring STATE=failed |
| `--worktree-name <name>` override flag in v1 or defer? | Deferred — `cj-{type}-{ts}` default is fine for v1; followup if asked |
| Auto-cleanup after `/land-and-deploy` success? | Deferred to followup TODO; CLAUDE.md cleanup convention is already documented |

## Definition of done

- [ ] `scripts/cj-worktree-init.sh` ships at the workbench root, executable, emits valid JSON
- [ ] Both `/CJ_goal_run` SKILL.md and `/CJ_goal_todo_fix` SKILL.md preambles source the helper BEFORE Path Resolution
- [ ] `scripts/drain-one-todo.sh` calls helper with `--force-create --quiet` per iteration
- [ ] `scripts/test.sh` regression assertion + 5-case helper test pass
- [ ] TODOS.md deferred row added for `/CJ_goal_investigate` worktree wiring
- [ ] CLAUDE.md updated with the auto-worktree note
- [ ] `scripts/validate.sh` clean

## Not in scope

- `/CJ_goal_investigate` SKILL.md preamble — source-of-truth on unmerged worktree; deferred TODOS row instead
- Auto-cleanup after `/land-and-deploy` — existing `gh api -X DELETE` workflow stays manual
- `--worktree-name <name>` override flag — `cj-{type}-{ts}` default suffices for v1
- Fixing the `skills-deploy` manifest-pinning bug (TODOS.md:110 — already closed by T000025/v3.5.2 per Codex review note in design doc; stale reference removed)

## Pointers

- Parent tracker: [F000025_TRACKER.md](F000025_TRACKER.md)
- Roadmap: [F000025_ROADMAP.md](F000025_ROADMAP.md)
- /office-hours design doc: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-default-worktree-design-20260516-121928.md
