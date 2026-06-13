---
skill-name: "CJ_goal_todo_fix"
version: 2.2.0
status: active
created: "2026-06-01"
last-updated: "2026-06-13T04:02:12Z"
---

# Skill Usage: CJ_goal_todo_fix

## When to use

- "fix this TODO", "clear the TODO backlog", "auto-resolve TODOs", "drain TODOs"
- Default no-args mode drains up to 10 easy-fix TODOs end-to-end
- Single-TODO mode: `/CJ_goal_todo_fix T000NNN` or `/CJ_goal_todo_fix "<fragment>"`
- Cron/schedule cadence: pair `--quiet` with `/schedule` to drain at a fixed time
- `--max-drain N` caps the batch; `--dry-run` previews without mutation; `/loop`
  wrapper for continuous drain
- `--no-sync` skips the pre-build skills-sync (F000045) for a faster start; the
  single-TODO worktree's local-main fast-forward still runs

## When NOT to use

- The work is a new feature topic, not an existing TODO row — use `/CJ_goal_feature`
- The work is a bug-from-description — use `/CJ_goal_defect`
- The TODO row is multi-item or non-trivial — drain mode skips hard rows by design;
  scaffold the work as a proper feature/defect instead
- You want autonomous merge — `/ship` Gate #2 still fires per drained PR (the
  workbench's autonomy ceiling per F000021)

## Mental model

A TODOS.md backlog drainer. Each invocation's preamble first runs a pre-build
skills-sync (`cj-goal-common.sh --phase sync` → `post-land-sync.sh`'s guarded
pull + `skills-deploy install` from `.source`, fail-soft) — so the drain runs
against current skills — plus the `skills-update-check` advisory it newly gained
(F000045). It then chains `/CJ_suggest` (rank) → bash T-task scaffold →
`/CJ_implement-from-spec` → `/CJ_qa-work-item` (impl→qa leaf Agent subagents,
halt-on-red between; QA runs the doc/test audits inline at its Step 8.6) → the
QA-audit checkpoint (interactive runs: AUQ ALWAYS on the AUDIT_FINDINGS digest,
Continue past findings journals `[qa-audit-waived]`; `--quiet` runs:
auto-continue on doc:ok,test:ok, halt `[qa-audit-declined]` /
`halted_at_qa_audit` on any findings) → `/CJ_document-release` (Step 5.5
doc-sync) → a pre-ship
portability gate (Step 5.7, `cj-goal-common.sh --phase portability-audit --mode
feature`, run STRICT; HALTs on a dishonest skill portability declaration before
the PR) → `/ship` (open PR) → `/land-and-deploy` (merge + verify) per drained
row. Drain mode
creates one worktree per TODO inside `scripts/drain-one-todo.sh`; single mode
creates one `cj-todo-*` worktree on `main` (whose local main is fast-forwarded
to trunk first, Fork 1). The pre-build sync is mode-independent (runs for both
drain and single-TODO modes); `--no-sync` opts out of the heavy install only.
Halt-on-red stops the loop and writes the finding to the tracker journal.

## Common pitfalls

- Forgetting that `/ship` Gate #2 is human — drain mode prepares PRs at your cadence,
  it does not auto-merge them
- TODOS hygiene debt: a row whose work shipped but wasn't strikethrough'd will keep
  ranking active and burn `/loop` iterations on idempotent skips (see CLAUDE.md
  "TODOS.md hygiene conventions")
- Treating PARTIAL closes the same as full closes — partial fixes need an explicit
  `~~strikethrough~~ PARTIAL —` annotation or `/CJ_suggest` will re-pick the row
- Running drain in a session that's already inside a worktree — drain creates
  per-TODO worktrees and parent-session collisions are confusing
- A touched skill that declares a portability tier it does not honor — the
  Step 5.7 portability gate HALTs (`halted_at_portability`) before the PR; relabel
  the skill's `portability` (or add the dep to `portability_requires`) in
  skills-catalog.json and re-run
- Expecting `--no-sync` to also skip the base fast-forward — it does not; `--no-sync`
  only suppresses the heavy `skills-deploy install`, Fork-1's local-main ff still runs
  (single-TODO mode); the pre-build sync is fail-soft and never blocks the drain

## Related skills

- `/CJ_suggest` — ranks TODOS.md rows; drain mode calls it with `--for-skill cj-goal`
- `/CJ_implement-from-spec` — dispatched per drained TODO (leaf Agent subagent) to write the code
- `/CJ_qa-work-item` — dispatched after impl (leaf Agent subagent) to verify; halt-on-red between; its Step 8.6 runs `/CJ_doc_audit` + `/CJ_test_audit` inline and feeds the QA-audit checkpoint
- `/ship` (upstream gstack) — opens PR with Gate #2 diff-review AUQ
- `/land-and-deploy` (upstream gstack) — merges and verifies deploy
- `/schedule` (upstream gstack) — pair with `--quiet` for cron-style drains
