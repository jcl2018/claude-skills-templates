### CJ_goal_task

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

**Status:** experimental (the `task` verb; the lightweight sibling of `/CJ_goal_feature` for small ad-hoc work)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers + its own `cj-task-scaffold.sh`; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_task/SKILL.md` · `skills/CJ_goal_task/USAGE.md`

**Invoke when:** the operator has a small, mechanical, ad-hoc task (refine a doc, add a file, clean up files, a one-line fix) that does NOT need design or investigation and is NOT already a `TODOS.md` row. Common phrasings: "do this small task end-to-end", "small cleanup to a PR". Stops at the PR.

**Workflow:**

```
"<small task>"
   |  cj-goal-common.sh --phase sync --mode task   (pre-build skills-sync; fail-soft -> skipped)
   v
cj-goal-common.sh --phase worktree --mode task   (auto cj-task-* worktree)
   |   `- cj-worktree-init.sh --caller task: base-freshness (ff local main to origin tip; fail-soft)
   v
isolation gate   (cj-worktree-init.sh --caller task --assert-isolated)
   |   `- not clean+isolated -> HALT (halted_at_not_isolated)
   v
HARD complexity gate + scaffold   [INLINE - scripts/cj-task-scaffold.sh --topic "<task>"]
   |   `- design-rework signal  -> HALT (halted_at_too_complex; suggest /CJ_goal_feature)
   |   `- bug/investigation     -> HALT (halted_at_too_complex; suggest /CJ_goal_defect)
   |   `- explicit-large-scope  -> HALT (halted_at_too_complex; suggest /CJ_goal_feature)
   |   on PASS -> bash-scaffold a `type: task` work-item (T-ID) from the topic
   v  record scaffold boundary -> resume state file (last_completed_phase + HEAD SHA + work-item dir)
   v  SILENT depth-<=2 leaf Agent subagents (no AUQ past the complexity gate)
/CJ_implement-from-spec -> /CJ_qa-work-item [DEFER_AUDIT: true - QA skips the inline audit; nightly CI covers it]
   |
   v
pre-doc-sync commit   [INLINE Step 4.4 - NEW; idempotent: commit QA-green code + 8.6a/8.6b overlays, skip on clean tree]
   |
   v
/CJ_document-release   [INLINE Step 5.5 - doc-sync folds doc edits into the PR; halt-on-red]
   |   (the agent-judged doc/test audit runs nightly in CI - audit-nightly.yml - not inline)
   v
/ship   [INLINE - diff-review AUQ suppressed; opens PR; check-version-queue.sh preflight]
   |
   v
registered-doc verdicts -> PR body   [post-/ship gh pr edit; best-effort]
   |
   v
at-PR recap   [cj-goal-common.sh --phase recap --when after --mode task; 3-part Delivered/E2E/Next; advisory, never halts]
   |
   v
STOP at PR   (human reviews + merges; /land-and-deploy is SEPARATE)
   |
   v
cj-goal-common.sh --phase cleanup --mode task   (worktree janitor; sweeps OTHER landed cj-* worktrees; best-effort)
   |
   v
telemetry -> ~/.gstack/analytics/CJ_goal_task.jsonl
```

**In words:** the `task` verb is `/CJ_goal_feature` with the design phase swapped
for an automatic gate. After the same deterministic setup (`--phase sync` +
`--phase worktree --mode task` + the `--assert-isolated` gate), there is NO
interactive phase: `scripts/cj-task-scaffold.sh` runs a **hard complexity gate**
that REFUSES topics needing design / investigation / large scope (routing each to
the right verb) and otherwise bash-scaffolds a `type: task` work-item directly
from the topic. The build is then fully silent — the implement -> QA leaf
subagents (QA skips its inline three-stage audit via `DEFER_AUDIT: true` — the
agent-judged audit runs nightly in CI), then a
pre-doc-sync commit (Step 4.4), `/CJ_document-release` folds doc edits into the
same PR at Step 5.5, and `/ship` opens the PR. It STOPs at the open PR
(PR-stop only; the same `unsafe-by-construction` reasoning as `/CJ_goal_feature`),
and the resume state file lets a re-invocation pick up mid-chain.

**Touches:**

- **Skills dispatched:** `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (silent depth-<=2 leaf subagents; QA skips its inline three-stage audit via `DEFER_AUDIT: true` — the agent-judged `/CJ_doc_audit` + `/CJ_test_audit` run nightly in CI via `audit-nightly.yml`), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check. No `/office-hours`, no `/CJ_scaffold-work-item` (the scaffold is bash, not the skill).
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> hard complexity gate + bash scaffold (`cj-task-scaffold.sh`; halt-on `too-complex` routing to the right verb) -> implement/qa (`DEFER_AUDIT: true` — QA skips the inline audit; the agent-judged audit runs nightly in CI) -> pre-doc-sync commit (Step 4.4) -> doc-sync (Step 5.5) -> `/ship` -> registered-doc verdicts -> PR body -> at-PR recap (`--phase recap --when after`; 3-part, advisory) -> STOP at PR -> worktree-cleanup (`--phase cleanup`) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `recap`, `--mode task`), `skills/CJ_goal_task/scripts/cj-task-scaffold.sh` (the complexity gate + topic-driven `type: task` scaffold), `scripts/cj-worktree-init.sh` (`--caller task`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same code PR.
