### CJ_goal_todo_fix

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

**Status:** active (the TODO drainer; production front door for "fix this TODO" and the cron-eligible `--quiet` mode powers /schedule integrations)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_todo_fix/SKILL.md` · `skills/CJ_goal_todo_fix/USAGE.md`

**Invoke when:** the operator wants to drain TODOS.md backlog rows into PRs. Default no-args drains up to 10 easy-fix TODOs; single-TODO mode (an ID or fragment) fixes exactly one. Common phrasings: "fix this TODO", "clear the TODO backlog", "drain TODOs", "auto-resolve TODOs". `/ship` Gate #2 still fires per drained TODO (the autonomy ceiling).

**Workflow:**

```
TODOS.md row -> /CJ_goal_todo_fix preflight
   |  (drain mode: enumerate via /CJ_suggest --for-skill cj-goal --limit 2*max)
   |  (single mode: exact ID or fragment match)
   v
cj-goal-common.sh --phase sync   (pre-build skills-sync; fail-soft -> skipped)
   v
cj-worktree-init.sh --caller todo   (auto cj-todo-* worktree; base-freshness ff local main; fail-soft)
   |   (drain mode: one worktree per TODO via scripts/drain-one-todo.sh)
   v
T-task scaffold (TRACKER + test-plan, pure bash)
   |
   v
/CJ_implement-from-spec   (leaf Agent subagent, halt-on-red)
   |
   v
/CJ_qa-work-item          (leaf Agent subagent, halt-on-red; DEFER_AUDIT: true - audit deferred to post-sync)
   |
   v
pre-doc-sync commit   (Step 5.4 - NEW; idempotent: commit QA-green fix + 8.6a/8.6b overlays, skip on clean tree)
   |
   v
/CJ_document-release   (Step 5.5 doc-sync; halt-on-red)
   |
   v
post-sync audit   (Step 5.5b - NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit over the post-sync tree)
   |
   v
QA-audit checkpoint   (AUQ ALWAYS interactive on the POST-sync report; --quiet auto-continues on doc:ok,test:ok / halts on findings)
   |   (Halt -> HALT halted_at_qa_audit; Continue past findings journals [qa-audit-waived])
   v
/ship   (Gate #2 fires per drained TODO - human approves diff; check-version-queue.sh preflight)
   |
   v
registered-doc verdicts -> PR body   (post-/ship gh pr edit "$PR_URL"; best-effort)
   |
   v
before-land recap   (pipeline.md Step 5.6 - cj-goal-common.sh --phase recap --when before; 3-part; advisory; per drained TODO)
   |
   v
/land-and-deploy   (auto-merge + verify production)
   |
   v
TODOS.md DONE-mark (hash-verified row update)
   |
   v
after-land recap   (SKILL.md Agent-layer terminal - cj-goal-common.sh --phase recap --when after; 3-part; advisory; per drained TODO)
   |
   v
telemetry -> ~/.gstack/analytics/CJ_goal_todo_fix.jsonl
```

**In words:** the entry point is a `TODOS.md` row (one in single mode, up to N in
drain mode, enumerated via `/CJ_suggest`), and the same `cj-goal-common.sh
--phase sync` + `cj-worktree-init.sh` setup creates a `cj-todo-*` worktree with
base-freshness (drain mode makes one worktree per TODO via `drain-one-todo.sh`) —
see [How the machinery works](utilities-and-phase-steps.md#how-the-machinery-works). The body is a pure-bash
T-task scaffold -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (which defers
its three-stage audit via `DEFER_AUDIT: true`), then a pre-doc-sync commit (Step
5.4), `/CJ_document-release` folds doc edits into the row's PR at Step 5.5, the
orchestrator runs ONE combined read-only post-sync doc/test audit (Step 5.5b), and
the QA-audit checkpoint decides on that POST-sync report. `/ship`
Gate #2 still fires per drained TODO (the autonomy ceiling — a human approves
each diff); on land it hash-verified DONE-marks the row and
`cj-worktree-cleanup.sh` sweeps the landed worktree.

**Touches:**

- **Skills dispatched:** `/CJ_suggest` (drain-mode enumeration, `--for-skill cj-goal`), `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (leaf Agent subagents; QA defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.5b), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 fires per drained TODO), `/land-and-deploy` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** preflight (drain enumerate / single-match) -> pre-build skills-sync (`--phase sync`) -> worktree create + base-freshness (ff local main) -> T-task scaffold -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 5.4) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.5b — ONE combined read-only subagent) -> QA-audit checkpoint (interactive: AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest, Continue past findings journals `[qa-audit-waived]`; `--quiet`: auto-continue on doc:ok,test:ok, halt `[qa-audit-declined]` / halted_at_qa_audit on findings) -> `/ship` -> registered-doc verdicts -> PR body -> before-land recap (`--phase recap --when before`; 3-part, advisory, per drained TODO) -> `/land-and-deploy` -> TODOS.md DONE-mark -> after-land recap (`--phase recap --when after`; 3-part, advisory, per drained TODO) -> cleanup (`cj-worktree-cleanup.sh`, called directly) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` pre-build skills-sync + `--phase recap` the land/PR 3-part recap formatter), `scripts/cj-worktree-init.sh` (`--caller todo`, base-freshness; drain mode creates one worktree per TODO via `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh`), `scripts/cj-worktree-cleanup.sh` (post-land janitor, called directly), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into each drained TODO's PR. Also marks the closed row in TODOS.md (hash-verified).
