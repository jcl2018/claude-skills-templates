### CJ_goal_feature

**Status:** experimental (the `feature` verb; production front door for "build a
feature end-to-end" but the chain is still being tuned)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh`
+ the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_feature/SKILL.md` · `skills/CJ_goal_feature/USAGE.md`

**Invoke when:** the operator has a one-line feature topic and wants a reviewable
PR. Common phrasings: "build a feature", "one-line idea to a reviewable PR",
"topic to PR". Stops at the PR — `/land-and-deploy` is a separate human step.

**Workflow:**

```
"<topic>"
   |  cj-goal-common.sh --phase sync --mode feature   (pre-build skills-sync; fail-soft -> skipped)
   v
cj-goal-common.sh --phase worktree --mode feature   (auto cj-feat-* worktree)
   |   `- cj-worktree-init.sh --caller feature: base-freshness (ff local main to origin tip; fail-soft)
   v
isolation gate   (cj-worktree-init.sh --assert-isolated)
   |
   v
/office-hours   [INLINE - interactive; emits APPROVED design doc]
   |   `- not APPROVED / abandoned -> HALT
   v
capture doc path -> resume state file (last_completed_phase + HEAD SHA + PR# + office_hours_receipt pointer)
   |   `- write compact office-hours receipt   [.cj-goal-feature/<branch>.office-hours.receipt; atomic mktemp+mv; reuses the QA receipt envelope]
   v
design-summary approval gate   [INLINE AUQ - go/no-go; digest SOURCED FROM the receipt, not the resident transcript]
   |   `- Abort -> HALT
   v  Approve & build ->  SILENT depth-<=2 leaf Agent subagents (one checkpoint AUQ below)
/CJ_scaffold-work-item -> /CJ_implement-from-spec -> /CJ_qa-work-item [DEFER_AUDIT: true - audit deferred to post-sync]
   |
   v
pre-doc-sync commit   [INLINE Step 3.5 - NEW; idempotent: commit QA-green code + 8.6a/8.6b overlays, skip on clean tree]
   |
   v
/CJ_document-release   [INLINE Step 5.5 - doc-sync folds doc edits into the PR; halt-on-red]
   |
   v
post-sync audit   [INLINE Step 5.6 - NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit over the post-sync tree]
   |
   v
QA-audit checkpoint   [INLINE Step 3.4 - AUQ ALWAYS; consumes the POST-sync AUDIT_FINDINGS digest; Continue / Halt]
   |   `- Halt -> HALT (halted_at_qa_audit); Continue past findings journals [qa-audit-waived]
   v
portability gate   [INLINE Step 5.7 - cj-goal-common.sh --phase portability-audit; halt-on-red BEFORE /ship]
   |   `- findings -> HALT (halted_at_portability; no PR)
   v
/ship   [INLINE - diff-review AUQ suppressed; opens PR; check-version-queue.sh preflight]
   |
   v
registered-doc + portability verdicts -> PR body   [post-/ship gh pr edit; best-effort]
   |
   v
at-PR recap   [cj-goal-common.sh --phase recap --when after; 3-part Delivered/E2E/Next; advisory, never halts]
   |
   v
STOP at PR   (human reviews + merges; /land-and-deploy is SEPARATE)
   |
   v
cj-goal-common.sh --phase cleanup   (worktree janitor; sweeps OTHER landed cj-* worktrees; best-effort)
   |
   v
telemetry -> ~/.gstack/analytics/CJ_goal_feature.jsonl
```

**In words:** the orchestrator first calls `cj-goal-common.sh` for the
deterministic setup — the `--phase sync` pre-build skills-sync and the `--phase
worktree` create of an isolated `cj-feat-*` worktree (with base-freshness), then
`cj-worktree-init.sh --assert-isolated` gates the build (see
[How the machinery works](utilities-and-phase-steps.md#how-the-machinery-works)). The one interactive phase
is `/office-hours` (inline), gated by a design-summary go/no-go; everything after
it is silent — the scaffold -> implement -> QA leaf subagents (QA defers its
three-stage audit via `DEFER_AUDIT: true`), then a pre-doc-sync commit (Step 3.5),
`/CJ_document-release` folds doc edits into the same PR at Step 5.5, the
orchestrator runs ONE combined read-only post-sync doc/test audit (Step 5.6), the
QA-audit checkpoint decides on that POST-sync report (Step 3.4), and `/ship`
opens it. It STOPs at the open PR (the human architecture gate; `/land-and-deploy`
is a separate step), and the resume state file lets a re-invocation pick up
mid-chain without redoing finished phases.

**Touches:**

- **Skills dispatched:** `/office-hours` (inline design), `/CJ_scaffold-work-item` -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (silent depth-<=2 leaf subagents; QA defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.6), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `/office-hours` -> write compact office-hours receipt (Step 2.6; the digest distilled once, atomic mktemp+mv) -> design-summary approval gate (digest sourced from the receipt, not the resident transcript) -> scaffold/implement/qa (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 3.5) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.6 — ONE combined read-only subagent) -> QA-audit checkpoint (Step 3.4 — AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest; Continue past findings journals `[qa-audit-waived]`, Halt = `[qa-audit-declined]` / halted_at_qa_audit) -> portability gate (Step 5.7, `--phase portability-audit`; halt-on-red before `/ship`) -> `/ship` -> registered-doc + portability verdicts -> PR body -> at-PR recap (`--phase recap --when after`; 3-part, advisory) -> STOP at PR -> worktree-cleanup (`--phase cleanup`) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `portability-audit` / `recap`, `--mode feature`), `scripts/cj-portability-audit.sh` (the portability engine, run STRICT via `--phase portability-audit`), `scripts/cj-worktree-init.sh` (`--caller feature`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same code PR.

