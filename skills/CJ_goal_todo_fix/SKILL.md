---
name: CJ_goal_todo_fix
description: "Auto-resolve a TODO from TODOS.md into a shipped PR (formerly /CJ_goal; renamed v4.0.0). Bridges TODOS.md rows to the existing /CJ_personal-pipeline + /ship + /land-and-deploy chain via an auto-scaffolded T-task work-item. One keystroke turns 'fix this TODO' into a merged PR. Workbench-only; halt-on-red preserved end-to-end."
version: 2.0.0
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - Skill
  - Agent
---

## Overview

`/CJ_goal_todo_fix` takes a TODO (resolved by no-args /CJ_suggest top-1, T-ID, or
heading fragment) and produces a green PR via the existing pipeline:

```
TODOS.md row → /CJ_goal_todo_fix preflight → T-task scaffold → /CJ_personal-pipeline
   → /ship Gate #2 → /land-and-deploy → TODOS.md DONE-mark → telemetry line
```

Net new logic vs the upstream pipeline: pre-flight gate stack, TODOS.md parser
(handles both `## Active work` and domain-grouped shapes), T-task scaffold
writes (TRACKER + test-plan), direct-dispatch chain, per-session skip-list
mechanic, hash-verify TODOS.md DONE-mark, and telemetry. Everything else
is reuse.

**Input shapes:**
- `/CJ_goal_todo_fix` — no args; reads /CJ_suggest top-1; fixes it.
- `/CJ_goal_todo_fix T000022` — exact T-ID lookup; if tracker exists, dispatch existing
  work-item; otherwise halt.
- `/CJ_goal_todo_fix "fragment"` — fuzzy match against active TODOS.md headings; halt
  on multi-match with disambiguation AUQ.
- `/CJ_goal_todo_fix --dry-run` — show resolved TODO + planned T-ID + planned
  work-item-dir + planned dispatch, no writes.

**Pre-flight gates (halt the run; under `/loop /CJ_goal_todo_fix` skip-and-continue):**
- Body too vague (< 50 chars)
- Missing `(P[1-4], [SMLX]+)` suffix on heading
- Priority P1 OR size in {L, XL} (run /office-hours instead)
- Sensitive surface AUQ (catalog / manifest / validator / `skills/*/scripts/` / `skills/*/*.md` / git-hook / templates) — v1.2 (S000044) added markdown skill files (SKILL.md, pipeline.md, etc.) since editing them is just as load-bearing as editing scripts
- Design-needed keyword (`needs design` / `investigate` / `spike` / `redesign` / `re-do` / `re-ground` / `rewrite` / `rescope` / `/office-hours` / etc.) — v1.2 (S000044) added the re-design-rework signals after T000031 ("Re-do brief-mode for /CJ_personal-pipeline", body step 1: "/office-hours from a new worktree") slipped past the original `investigate|spike|...` regex
- Idempotency hit (T-tracker already exists for this heading)

**Loop semantics.** `/loop /CJ_goal_todo_fix` continues on `end_state ∈ {green,
idempotent_skip, halted_at_preflight, halted_at_sensitive_surface_auto_declined}`.
The sensitive-surface auto-default joins `halted_at_preflight` in the continue
set because under bash there is no AUQ tool — the gate fires regardless of
whether a human is present, so `/loop` should defer the row (skip-list) and
keep iterating. Substantive halts (`halted_at_pipeline_*`, `halted_at_ship`,
`halted_at_deploy`, `halted_at_sensitive_surface_user_declined` (reserved for
future interactive AUQ; not emitted in v1.1), `halted_at_resolve`,
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
bash "$HOME/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh" "$@"
```

Resolution rationale: the script always runs from the deployed location at
`~/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (`skills-deploy install` puts it
there). The script reads the current repo's `TODOS.md`, `work-items/`, and
writes to the same. Workbench developers iterating on the script must
`./scripts/skills-deploy install` to sync changes (the existing convention)
or invoke `bash skills/CJ_goal_todo_fix/scripts/todo_fix.sh` directly while testing.

## Halt classes

| Class | Meaning | Loop behavior |
|-------|---------|---------------|
| `green` | Full chain shipped; PR merged; TODOS.md marked DONE | continue |
| `idempotent_skip` | Tracker existed; dispatched chain | continue |
| `halted_at_preflight` | Benign per-TODO halt (suffix / size / body-too-short / design-keyword) | continue (skip-list) |
| `halted_at_resolve` | No actionable TODOs from /CJ_suggest, or T-ID/fragment didn't match | STOP |
| `halted_at_sensitive_surface_auto_declined` | Bash auto-default at sensitive-surface gate (no AUQ tool reachable; honest disposition name). Mirrors `halted_at_preflight` semantics for `/loop` continuity. | continue (skip-list) |
| `halted_at_sensitive_surface_user_declined` | (reserved for future interactive AUQ; not emitted in v1.1) Human at the AUQ explicitly declined the sensitive-surface gate. | STOP |
| `halted_at_scaffold` | /CJ_personal-workflow check refused the scaffolded dir | STOP |
| `halted_at_pipeline_implement` / `halted_at_pipeline_qa` | /CJ_personal-pipeline returned non-green | STOP |

| `halted_at_ship` | /ship Gate #2 declined or pre-landing review red | STOP |
| `halted_at_deploy` | /land-and-deploy red (CI / merge / canary / regression) | STOP |
| `halted_at_todos_md` | Post-ship hash collision; PR merged but TODOS.md write failed; manual reconcile | STOP |

## Telemetry

Each invocation appends one JSONL line to `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`:

```json
{"ts":"...","todo_heading":"...","t_id":"T000NNN","end_state":"green",
 "pr_url":"https://...","duration_s":123,"parent_skill":"CJ_goal_todo_fix"}
```

Used for v1.1 sunset trip-wire calibration (deferred until 8+ real invocations
exist; threshold TBD).

## Notes

- **Script-extracted (D000017 pattern).** All load-bearing logic lives in
  `scripts/todo_fix.sh` with a `#!/usr/bin/env bash` shebang. Inline bash blocks
  inside SKILL.md routing crash under zsh (`status=` is read-only).
- **/CJ_goal_run bypass.** /CJ_goal_run Branch(f) explicitly rejects `type: task`
  (run.md:214). /CJ_goal_todo_fix follows that guidance and chains /CJ_personal-pipeline
  + /ship + /land-and-deploy directly.
- **Workbench is the source-of-truth, but the skill is portable.** v1 was
  developed and tested in the `claude-skills-templates` workbench — `TODOS.md`
  source convention lives here and gets curated here. The skill itself works
  in any repo with a `TODOS.md` and a `work-items/` tree: the post-scaffold
  workbench-coupled `validate.sh` check was removed from `scripts/todo_fix.sh`
  (T000028 / Approach D), and `/CJ_personal-pipeline` Step 6 silently skips
  `validate.sh` when the file is absent or non-executable. Downstream
  `/loop /CJ_goal_todo_fix` drains are supported as of T000028.
- **ID-picker source-of-truth.** v1 copy-pastes /CJ_scaffold-work-item Step 5's
  two-source picker block into `scripts/todo_fix.sh`. v1.1 will extract to
  `scripts/cj-id-picker.sh` (Open Q #1 in source design).
