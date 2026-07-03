### CJ_goal_defect

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

**Status:** experimental (the `defect` verb; still being hardened)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_defect/SKILL.md` · `skills/CJ_goal_defect/USAGE.md`

**Invoke when:** the operator has a plain bug description with no pre-existing defect dir and wants a deployed fix. Common phrasings: "fix this bug end-to-end", "bug report to deployed fix", "root-cause and ship a fix". Differs from `/CJ_goal_feature` in that it auto-deploys after `/ship` — defects are time-sensitive.

**Workflow:**

```
"<bug description>"
   |  cj-goal-common.sh --phase sync --mode defect   (pre-build skills-sync; fail-soft -> skipped)
   v
cj-goal-common.sh --phase worktree --mode defect   (auto cj-def-* worktree)
   |   `- cj-worktree-init.sh --caller defect: base-freshness (ff local main to origin tip; fail-soft)
   v
isolation gate   (cj-worktree-init.sh --assert-isolated)
   |
   v
scaffold .inbox/<slug>/DRAFT.md   (no defect ID yet; idempotent)
   |
   v  Agent: /investigate dispatch (sentinel-wrapped JSON)
   |        Iron-Law gate: no root cause => HALT, nothing promoted
   |
   v  parse FIX_PLAN (halt if >5 files) + DEBUG_REPORT (halt taxonomy)
   |
   v  PROMOTE: .inbox/<slug>/ -> work-items/defects/uncategorized/<defect-id>_<slug>/
   |        (defect ID minted ONLY after Iron-Law passes)
   |
   v  write RCA.md + test-plan.md -> /CJ_qa-work-item (leaf subagent; DEFER_AUDIT: true - QA skips the inline audit; nightly CI covers it)
   |
   v  pre-doc-sync commit                    (Step 8.4 - NEW; idempotent: commit post-QA tracker update, skip on clean tree)
   |
   v  /CJ_document-release                   (Step 5.5 doc-sync; halt-on-red)
   |        (the agent-judged doc/test audit runs nightly in CI - audit-nightly.yml - not inline)
   |
   v  /ship                                  (Gate #2 fires; check-version-queue.sh preflight)
   |
   v  registered-doc verdicts -> PR body   (post-/ship gh pr edit "$PR_URL"; best-effort)
   |
   v  before-land recap                      (Step 10 - cj-goal-common.sh --phase recap --when before; 3-part; advisory)
   |
   v  /land-and-deploy --suppress-readiness-gate
   |
   v  after-land recap                       (Step 12 - cj-goal-common.sh --phase recap --when after; 3-part; advisory)
   |
   v  telemetry -> ~/.gstack/analytics/CJ_goal_defect.jsonl
```

**In words:** same deterministic spine as `/CJ_goal_feature` — `cj-goal-common.sh`
does the `--phase sync` + `--phase worktree` setup (a `cj-def-*` worktree with
base-freshness) and `cj-worktree-init.sh --assert-isolated` gates it (see
[How the machinery works](utilities-and-phase-steps.md#how-the-machinery-works)). The defining move is the
Iron-Law gate: `/investigate` must produce a root cause or the run HALTs with
nothing promoted — the defect ID is minted only after it passes, when the
`.inbox` draft is promoted to a canonical defect dir. After QA (which skips its
inline three-stage audit via `DEFER_AUDIT: true` — the agent-judged audit runs
nightly in CI) and a pre-doc-sync commit (Step 8.4),
`/CJ_document-release` folds doc edits into the same fix PR (Step 5.5), and the
chain auto-lands via `/ship` -> `/land-and-deploy` (defects are time-sensitive),
with `cj-worktree-cleanup.sh` sweeping the now-landed worktree.

**Touches:**

- **Skills dispatched:** `/investigate` (root-cause, Agent subagent; Iron-Law gate), `/CJ_qa-work-item` (leaf subagent; skips its inline three-stage audit via `DEFER_AUDIT: true` — the agent-judged `/CJ_doc_audit` + `/CJ_test_audit` run nightly in CI via `audit-nightly.yml`), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 always human), `/land-and-deploy --suppress-readiness-gate` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `.inbox` draft -> `/investigate` (Iron-Law gate) -> promote to a defect dir (a full `tracker-defect.md`-compliant tracker) -> RCA + test-plan -> commit fix + artifacts (before QA) -> `/CJ_qa-work-item` (`DEFER_AUDIT: true` — QA skips the inline audit; the agent-judged audit runs nightly in CI) -> pre-doc-sync commit (Step 8.4) -> doc-sync (Step 5.5) -> `/ship` -> registered-doc verdicts -> PR body -> before-land recap (`--phase recap --when before`; 3-part, advisory) -> `/land-and-deploy` -> after-land recap (`--phase recap --when after`; 3-part, advisory) -> cleanup (`--phase cleanup`) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `recap`, `--mode defect`), `scripts/cj-worktree-init.sh` (`--caller defect`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same fix PR.
