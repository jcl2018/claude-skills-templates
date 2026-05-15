---
name: CJ_goal
description: "Auto-resolve a TODO from TODOS.md into a shipped PR. Bridges TODOS.md rows to the existing /CJ_personal-pipeline + /ship + /land-and-deploy chain via an auto-scaffolded T-task work-item. One keystroke turns 'fix this TODO' into a merged PR. Workbench-only; halt-on-red preserved end-to-end."
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - Skill
  - Agent
---

## Overview

`/CJ_goal` takes a TODO (resolved by no-args /CJ_suggest top-1, T-ID, or
heading fragment) and produces a green PR via the existing pipeline:

```
TODOS.md row → /CJ_goal preflight → T-task scaffold → /CJ_personal-pipeline
   → /ship Gate #2 → /land-and-deploy → TODOS.md DONE-mark → telemetry line
```

Net new logic vs the upstream pipeline: pre-flight gate stack, TODOS.md parser
(handles both `## Active work` and domain-grouped shapes), T-task scaffold
writes (TRACKER + test-plan), direct-dispatch chain, per-session skip-list
mechanic, hash-verify TODOS.md DONE-mark, and telemetry. Everything else
is reuse.

**Input shapes:**
- `/CJ_goal` — no args; reads /CJ_suggest top-1; fixes it.
- `/CJ_goal T000022` — exact T-ID lookup; if tracker exists, dispatch existing
  work-item; otherwise halt.
- `/CJ_goal "fragment"` — fuzzy match against active TODOS.md headings; halt
  on multi-match with disambiguation AUQ.
- `/CJ_goal --dry-run` — show resolved TODO + planned T-ID + planned
  work-item-dir + planned dispatch, no writes.

**Pre-flight gates (halt the run; under `/loop /CJ_goal` skip-and-continue):**
- Body too vague (< 50 chars)
- Missing `(P[1-4], [SMLX]+)` suffix on heading
- Priority P1 OR size in {L, XL} (run /office-hours instead)
- Sensitive surface AUQ (catalog/manifest/validator/skill-script/git-hook/templates)
- Design-needed keyword (`needs design` / `investigate` / `spike` / etc.)
- Idempotency hit (T-tracker already exists for this heading)

**Loop semantics.** `/loop /CJ_goal` continues on `end_state ∈ {green,
idempotent_skip, halted_at_preflight}`. Substantive halts
(`halted_at_pipeline_*`, `halted_at_ship`, `halted_at_deploy`,
`halted_at_sensitive_surface_user_declined`, `halted_at_resolve`,
`halted_at_scaffold`, `halted_at_todos_md`) stop the loop. Per-session
skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` prevents re-hitting
already-skipped TODOs within a `/loop` session.

**Practical fit.** Best for 1-5 small TODOs per session, each with a quick
/ship Gate #2 diff review. Not for unattended overnight clearance — /ship's
diff-review fires per TODO that reaches it (upstream gstack constraint).

## Routing

Run the bash script below from the repo root and pass through the user's
positional argument verbatim. The shebang pins execution to bash regardless
of harness shell (per D000017's `/CJ_suggest` lesson: zsh treats `status` /
`pipestatus` / `LINENO` as read-only and chokes on inline bash blocks).

```bash
bash "$HOME/.claude/skills/CJ_goal/scripts/goal.sh" "$@"
```

Resolution rationale: the script always runs from the deployed location at
`~/.claude/skills/CJ_goal/scripts/goal.sh` (`skills-deploy install` puts it
there). The script reads the current repo's `TODOS.md`, `work-items/`, and
writes to the same. Workbench developers iterating on the script must
`./scripts/skills-deploy install` to sync changes (the existing convention)
or invoke `bash skills/CJ_goal/scripts/goal.sh` directly while testing.

## Halt classes

| Class | Meaning | Loop behavior |
|-------|---------|---------------|
| `green` | Full chain shipped; PR merged; TODOS.md marked DONE | continue |
| `idempotent_skip` | Tracker existed; dispatched chain | continue |
| `halted_at_preflight` | Benign per-TODO halt (suffix / size / body-too-short / design-keyword) | continue (skip-list) |
| `halted_at_resolve` | No actionable TODOs from /CJ_suggest, or T-ID/fragment didn't match | STOP |
| `halted_at_sensitive_surface_user_declined` | User chose "halt" at sensitive-surface AUQ | STOP |
| `halted_at_scaffold` | /CJ_personal-workflow check refused the scaffolded dir | STOP |
| `halted_at_pipeline_implement` / `halted_at_pipeline_qa` | /CJ_personal-pipeline returned non-green | STOP |
| `halted_at_ship` | /ship Gate #2 declined or pre-landing review red | STOP |
| `halted_at_deploy` | /land-and-deploy red (CI / merge / canary / regression) | STOP |
| `halted_at_todos_md` | Post-ship hash collision; PR merged but TODOS.md write failed; manual reconcile | STOP |

## Telemetry

Each invocation appends one JSONL line to `~/.gstack/analytics/CJ_goal.jsonl`:

```json
{"ts":"...","todo_heading":"...","t_id":"T000NNN","end_state":"green",
 "pr_url":"https://...","duration_s":123,"parent_skill":"CJ_goal"}
```

Used for v1.1 sunset trip-wire calibration (deferred until 8+ real invocations
exist; threshold TBD).

## Notes

- **Script-extracted (D000017 pattern).** All load-bearing logic lives in
  `scripts/goal.sh` with a `#!/usr/bin/env bash` shebang. Inline bash blocks
  inside SKILL.md routing crash under zsh (`status=` is read-only).
- **/CJ_run bypass.** /CJ_run Branch(f) explicitly rejects `type: task`
  (run.md:214). /CJ_goal follows that guidance and chains /CJ_personal-pipeline
  + /ship + /land-and-deploy directly.
- **Workbench-only scope.** Only the `claude-skills-templates` repo's
  `TODOS.md` is the source. Generalizing to downstream repos is a v2 question
  per `[[feedback_workbench_scope]]`.
- **ID-picker source-of-truth.** v1 copy-pastes /CJ_scaffold-work-item Step 5's
  two-source picker block into `scripts/goal.sh`. v1.1 will extract to
  `scripts/cj-id-picker.sh` (Open Q #1 in source design).
