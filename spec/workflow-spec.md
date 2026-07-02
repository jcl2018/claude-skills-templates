<!-- WORKFLOW-SPEC:BEGIN (parsed by scripts/workflow-spec.sh) -->
# workflow-spec.md — the workflow-docs registry

This file is the **single source of truth** for the workbench's workflow
documentation: the `docs/workflow.md` index plus the six `docs/workflows/*.md`
files (the four `CJ_goal_*` orchestrator pages + the two prose rosters
`utilities-and-phase-steps.md` and `utility-audits.md`). `scripts/workflow-spec.sh`
parses this registry and RENDERS that entire surface (`--render-docs`); a
`validate.sh` Check 27 freshness gate regenerates→diffs so a hand-edit to a
generated doc cannot pass validation, and `/CJ_doc_audit` Stage 1 runs the same
freshness check standalone in any repo.

This is the THIRD instance of the proven generate→freshness→audit primitive
(after `README.md` ↔ `generate-readme.sh` ↔ Check 25 and the test catalog
`spec/test-spec.md` ↔ `test-spec.sh --render-docs` ↔ Check 26). The no-vanish
guarantee that retired Checks 15b/15c provided now lives in this engine's
`--validate` registry-completeness: every routable `CJ_goal_*` skill
(`skills-catalog.json`, `status != deprecated`, non-empty `files`) MUST have an
`## <name>` orchestrator entry here.

## Grammar (how the engine parses this file)

- The leading `<!-- WORKFLOW-SPEC:BEGIN -->` … `<!-- WORKFLOW-SPEC:END -->`
  markers bracket the registry. The HEADER block below
  (`<!-- WORKFLOW-SPEC-HEADER:BEGIN/END -->`, a four-backtick fenced block) holds
  the `docs/workflow.md` index prose preamble, reproduced verbatim on render.
- Each workflow is one `## <name>` section. The first key in every section is
  `kind:` (closed enum `{orchestrator, roster}`).
- **orchestrator** sections (the 4 `CJ_goal_*`) carry single-line key:value
  fields `status:` / `category:` / `source:` / `invoke_when:`, then five
  four-backtick fenced blocks — `chart` (the ASCII workflow chart, verbatim),
  `summary` (the "In words" prose, verbatim), and the four Touches axes
  `touches-skills` / `touches-steps` / `touches-scripts` / `touches-docs`
  (each the verbatim bullet prose for that axis).
- **roster** sections (the 2 prose docs) carry one four-backtick fenced `body`
  block holding the entire doc body verbatim (it may itself contain three-backtick
  fences — that is why the registry blocks use four backticks).
- A four-backtick fenced block is opened by a line of exactly four backticks
  followed by the block name (e.g. ````` ````chart `````) and closed by a line of
  exactly four backticks. Content between is emitted verbatim.

## Rendered output (deterministic)

`--render-docs` writes `docs/workflow.md` (the header preamble + an index table
over all entries in registry order) and one `docs/workflows/<name>.md` per entry,
to a NORMALIZED template (fixed headers, registry declaration order, no
timestamps). Charts, roster bodies, and the index preamble are reproduced
verbatim; only structural bits may reformat. The rendered output is work-item-ID
free (`[FSTD][0-9]{6}` masked) so the human-docs pass Check 19. A second render is
byte-identical.

<!-- WORKFLOW-SPEC-HEADER:BEGIN -->
````header
# Workflows

This doc is the **index/overview** of every routable skill in the repo — the
`cj_goal` **orchestrator chains** that take a one-line intent (a feature topic, a
bug description, a TODO row) all the way to a reviewable or shipped PR, AND the
component skills those chains dispatch / the operator runs directly (the
phase-step skills, the validator, the standalone utilities). It names + links
every workflow; the **deep per-workflow detail** (ASCII workflow charts, the
4-bullet **Touches** blocks, the machinery glossary, the audit specs) lives one
level down, under [`docs/workflows/`](workflows/) — one file per workflow.

This split keeps the overview short and readable while the dense reference detail
is isolated per workflow. It is part of the portable doc contract
([`spec/doc-spec.md`](../spec/doc-spec.md)): an adopting repo carries a non-empty
`docs/workflows/` subfolder, and every `docs/workflows/*.md` is a declared
human-doc (no work-item IDs). The whole workflow surface (this index + the six
per-workflow files) is GENERATED from [`spec/workflow-spec.md`](../spec/workflow-spec.md)
by `scripts/workflow-spec.sh --render-docs`; the overview names every workflow — a
no-vanish guarantee enforced by `workflow-spec.sh --validate` (registry
completeness: every `CJ_goal_*` orchestrator has an entry) and kept fresh by
`scripts/validate.sh` Check 27 (regenerate→diff).

For **routing** (which skill to pick for a given intent), see
[philosophy.md](philosophy.md) `## Decision tree`. For the workbench's
**mechanism reference** (auto-worktree, doc-sync wrapper, update-check, the
`work-copilot` bundle), see [architecture.md](architecture.md). For per-skill
operator + agent best-practice, see each skill's `USAGE.md`.

For the **deep per-workflow detail**, see the per-workflow files under
[`docs/workflows/`](workflows/): the four `cj_goal` orchestrators each get a file
with a mandatory ASCII workflow chart and a four-bullet **Touches** block
(**Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** /
**Docs touched**), so a reader can see the shape of every workflow — and its
blast radius — at a glance. The component skills (phase-steps, the validator, the
standalone utilities) use a lighter shape in
[workflows/utilities-and-phase-steps.md](workflows/utilities-and-phase-steps.md)
(status + source + invoke-when + a compact Touches; no chart, no 4-bullet
Touches — single-step skills dispatch nothing and run no pipeline).

## See also

- [philosophy.md](philosophy.md) — workbench-level overview + the routing
  **decision tree** (which skill to pick for a given intent). Read this when you
  know what you want to do but aren't sure which skill to invoke; read this index
  (and the linked `docs/workflows/*.md`) when you want to understand the shape and
  blast radius of a `cj_goal` workflow end-to-end.
- [architecture.md](architecture.md) — mechanism reference (auto-worktree,
  doc-sync wrapper, update-check, the `work-copilot` bundle, etc.) — *how* the
  layers underneath these skills work. Deliberately does NOT duplicate the
  routing decision tree; the per-skill component roster lives in
  [workflows/utilities-and-phase-steps.md](workflows/utilities-and-phase-steps.md).
- `skills/{name}/USAGE.md` — per-skill operator + agent best-practice. Has five
  required H2 sections (When to use / When NOT to use / Mental model / Common
  pitfalls / Related skills). Always linked from the **Source:** line of each
  per-workflow file under `docs/workflows/`.
````
<!-- WORKFLOW-SPEC-HEADER:END -->

## CJ_goal_feature
kind: orchestrator
status: experimental (the `feature` verb; production front door for "build a feature end-to-end" but the chain is still being tuned)
category: workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers; matches `skills-catalog.json`)
source: `skills/CJ_goal_feature/SKILL.md` · `skills/CJ_goal_feature/USAGE.md`
invoke_when: the operator has a one-line feature topic and wants a reviewable PR. Common phrasings: "build a feature", "one-line idea to a reviewable PR", "topic to PR". Stops at the PR — `/land-and-deploy` is a separate human step.

````chart
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
/ship   [INLINE - diff-review AUQ suppressed; opens PR; check-version-queue.sh preflight]
   |
   v
registered-doc verdicts -> PR body   [post-/ship gh pr edit; best-effort]
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
````

````summary
the orchestrator first calls `cj-goal-common.sh` for the
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
````

````touches-skills
- **Skills dispatched:** `/office-hours` (inline design), `/CJ_scaffold-work-item` -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (silent depth-<=2 leaf subagents; QA defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.6), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check.
````

````touches-steps
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `/office-hours` -> write compact office-hours receipt (Step 2.6; the digest distilled once, atomic mktemp+mv) -> design-summary approval gate (digest sourced from the receipt, not the resident transcript) -> scaffold/implement/qa (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 3.5) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.6 — ONE combined read-only subagent) -> QA-audit checkpoint (Step 3.4 — AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest; Continue past findings journals `[qa-audit-waived]`, Halt = `[qa-audit-declined]` / halted_at_qa_audit) -> `/ship` -> registered-doc verdicts -> PR body -> at-PR recap (`--phase recap --when after`; 3-part, advisory) -> STOP at PR -> worktree-cleanup (`--phase cleanup`) -> telemetry.
````

````touches-scripts
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `recap`, `--mode feature`), `scripts/cj-worktree-init.sh` (`--caller feature`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
````

````touches-docs
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same code PR.
````

## CJ_goal_task
kind: orchestrator
status: experimental (the `task` verb; the lightweight sibling of `/CJ_goal_feature` for small ad-hoc work)
category: workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers + its own `cj-task-scaffold.sh`; matches `skills-catalog.json`)
source: `skills/CJ_goal_task/SKILL.md` · `skills/CJ_goal_task/USAGE.md`
invoke_when: the operator has a small, mechanical, ad-hoc task (refine a doc, add a file, clean up files, a one-line fix) that does NOT need design or investigation and is NOT already a `TODOS.md` row. Common phrasings: "do this small task end-to-end", "small cleanup to a PR". Stops at the PR.

````chart
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
   v  SILENT depth-<=2 leaf Agent subagents (one checkpoint AUQ below)
/CJ_implement-from-spec -> /CJ_qa-work-item [DEFER_AUDIT: true - audit deferred to post-sync]
   |
   v
pre-doc-sync commit   [INLINE Step 4.4 - NEW; idempotent: commit QA-green code + 8.6a/8.6b overlays, skip on clean tree]
   |
   v
/CJ_document-release   [INLINE Step 5.5 - doc-sync folds doc edits into the PR; halt-on-red]
   |
   v
post-sync audit   [INLINE Step 5.6 - NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit over the post-sync tree]
   |
   v
QA-audit checkpoint   [INLINE Step 4.5 - AUQ ALWAYS; consumes the POST-sync AUDIT_FINDINGS digest; Continue / Halt]
   |   `- Halt -> HALT (halted_at_qa_audit); Continue past findings journals [qa-audit-waived]
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
````

````summary
the `task` verb is `/CJ_goal_feature` with the design phase swapped
for an automatic gate. After the same deterministic setup (`--phase sync` +
`--phase worktree --mode task` + the `--assert-isolated` gate), there is NO
interactive phase: `scripts/cj-task-scaffold.sh` runs a **hard complexity gate**
that REFUSES topics needing design / investigation / large scope (routing each to
the right verb) and otherwise bash-scaffolds a `type: task` work-item directly
from the topic. The build is then fully silent — the implement -> QA leaf
subagents (QA defers its three-stage audit via `DEFER_AUDIT: true`), then a
pre-doc-sync commit (Step 4.4), `/CJ_document-release` folds doc edits into the
same PR at Step 5.5, the orchestrator runs ONE combined read-only post-sync
doc/test audit (Step 5.6), the QA-audit checkpoint decides on that POST-sync
report (Step 4.5), and `/ship` opens the PR. It STOPs at the open PR
(PR-stop only; the same `unsafe-by-construction` reasoning as `/CJ_goal_feature`),
and the resume state file lets a re-invocation pick up mid-chain.
````

````touches-skills
- **Skills dispatched:** `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (silent depth-<=2 leaf subagents; QA defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.6), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check. No `/office-hours`, no `/CJ_scaffold-work-item` (the scaffold is bash, not the skill).
````

````touches-steps
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> hard complexity gate + bash scaffold (`cj-task-scaffold.sh`; halt-on `too-complex` routing to the right verb) -> implement/qa (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 4.4) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.6 — ONE combined read-only subagent) -> QA-audit checkpoint (Step 4.5 — AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest; Continue past findings journals `[qa-audit-waived]`, Halt = `[qa-audit-declined]` / halted_at_qa_audit) -> `/ship` -> registered-doc verdicts -> PR body -> at-PR recap (`--phase recap --when after`; 3-part, advisory) -> STOP at PR -> worktree-cleanup (`--phase cleanup`) -> telemetry.
````

````touches-scripts
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `recap`, `--mode task`), `skills/CJ_goal_task/scripts/cj-task-scaffold.sh` (the complexity gate + topic-driven `type: task` scaffold), `scripts/cj-worktree-init.sh` (`--caller task`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
````

````touches-docs
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same code PR.
````

## CJ_goal_defect
kind: orchestrator
status: experimental (the `defect` verb; still being hardened)
category: workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers; matches `skills-catalog.json`)
source: `skills/CJ_goal_defect/SKILL.md` · `skills/CJ_goal_defect/USAGE.md`
invoke_when: the operator has a plain bug description with no pre-existing defect dir and wants a deployed fix. Common phrasings: "fix this bug end-to-end", "bug report to deployed fix", "root-cause and ship a fix". Differs from `/CJ_goal_feature` in that it auto-deploys after `/ship` — defects are time-sensitive.

````chart
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
   v  write RCA.md + test-plan.md -> /CJ_qa-work-item (leaf subagent; DEFER_AUDIT: true - audit deferred to post-sync)
   |
   v  pre-doc-sync commit                    (Step 8.4 - NEW; idempotent: commit post-QA tracker update, skip on clean tree)
   |
   v  /CJ_document-release                   (Step 5.5 doc-sync; halt-on-red)
   |
   v  post-sync audit                        (Step 5.6 - NEW; ONE combined READ-ONLY subagent: /CJ_doc_audit + /CJ_test_audit)
   |
   v  QA-audit checkpoint                    (Step 8.5 - AUQ ALWAYS; consumes the POST-sync AUDIT_FINDINGS digest; Continue / Halt)
   |        Halt -> HALT (halted_at_qa_audit); Continue past findings journals [qa-audit-waived]
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
````

````summary
same deterministic spine as `/CJ_goal_feature` — `cj-goal-common.sh`
does the `--phase sync` + `--phase worktree` setup (a `cj-def-*` worktree with
base-freshness) and `cj-worktree-init.sh --assert-isolated` gates it (see
[How the machinery works](utilities-and-phase-steps.md#how-the-machinery-works)). The defining move is the
Iron-Law gate: `/investigate` must produce a root cause or the run HALTs with
nothing promoted — the defect ID is minted only after it passes, when the
`.inbox` draft is promoted to a canonical defect dir. After QA (which defers its
three-stage audit via `DEFER_AUDIT: true`) and a pre-doc-sync commit (Step 8.4),
`/CJ_document-release` folds doc edits into the same fix PR (Step 5.5), the
orchestrator runs ONE combined read-only post-sync doc/test audit (Step 5.6), the
QA-audit checkpoint decides on that POST-sync report (Step 8.5), and the
chain auto-lands via `/ship` -> `/land-and-deploy` (defects are time-sensitive),
with `cj-worktree-cleanup.sh` sweeping the now-landed worktree.
````

````touches-skills
- **Skills dispatched:** `/investigate` (root-cause, Agent subagent; Iron-Law gate), `/CJ_qa-work-item` (leaf subagent; defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.6), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 always human), `/land-and-deploy --suppress-readiness-gate` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
````

````touches-steps
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `.inbox` draft -> `/investigate` (Iron-Law gate) -> promote to a defect dir (a full `tracker-defect.md`-compliant tracker) -> RCA + test-plan -> commit fix + artifacts (before QA) -> `/CJ_qa-work-item` (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 8.4) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.6 — ONE combined read-only subagent) -> QA-audit checkpoint (Step 8.5 — AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest; Continue past findings journals `[qa-audit-waived]`, Halt = `[qa-audit-declined]` / halted_at_qa_audit) -> `/ship` -> registered-doc verdicts -> PR body -> before-land recap (`--phase recap --when before`; 3-part, advisory) -> `/land-and-deploy` -> after-land recap (`--phase recap --when after`; 3-part, advisory) -> cleanup (`--phase cleanup`) -> telemetry.
````

````touches-scripts
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `recap`, `--mode defect`), `scripts/cj-worktree-init.sh` (`--caller defect`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
````

````touches-docs
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same fix PR.
````

## CJ_goal_todo_fix
kind: orchestrator
status: active (the TODO drainer; production front door for "fix this TODO" and the cron-eligible `--quiet` mode powers /schedule integrations)
category: workbench (operates ON the workbench — executes `cj-goal-common.sh` + the worktree helpers; matches `skills-catalog.json`)
source: `skills/CJ_goal_todo_fix/SKILL.md` · `skills/CJ_goal_todo_fix/USAGE.md`
invoke_when: the operator wants to drain TODOS.md backlog rows into PRs. Default no-args drains up to 10 easy-fix TODOs; single-TODO mode (an ID or fragment) fixes exactly one. Common phrasings: "fix this TODO", "clear the TODO backlog", "drain TODOs", "auto-resolve TODOs". `/ship` Gate #2 still fires per drained TODO (the autonomy ceiling).

````chart
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
````

````summary
the entry point is a `TODOS.md` row (one in single mode, up to N in
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
````

````touches-skills
- **Skills dispatched:** `/CJ_suggest` (drain-mode enumeration, `--for-skill cj-goal`), `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (leaf Agent subagents; QA defers its three-stage audit via `DEFER_AUDIT: true`, so the orchestrator runs `/CJ_doc_audit` + `/CJ_test_audit` ONCE post-sync at Step 5.5b), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 fires per drained TODO), `/land-and-deploy` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
````

````touches-steps
- **Steps · phases:** preflight (drain enumerate / single-match) -> pre-build skills-sync (`--phase sync`) -> worktree create + base-freshness (ff local main) -> T-task scaffold -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (`DEFER_AUDIT: true`) -> pre-doc-sync commit (Step 5.4) -> doc-sync (Step 5.5) -> post-sync doc/test audit (Step 5.5b — ONE combined read-only subagent) -> QA-audit checkpoint (interactive: AUQ ALWAYS on the POST-sync AUDIT_FINDINGS digest, Continue past findings journals `[qa-audit-waived]`; `--quiet`: auto-continue on doc:ok,test:ok, halt `[qa-audit-declined]` / halted_at_qa_audit on findings) -> `/ship` -> registered-doc verdicts -> PR body -> before-land recap (`--phase recap --when before`; 3-part, advisory, per drained TODO) -> `/land-and-deploy` -> TODOS.md DONE-mark -> after-land recap (`--phase recap --when after`; 3-part, advisory, per drained TODO) -> cleanup (`cj-worktree-cleanup.sh`, called directly) -> telemetry.
````

````touches-scripts
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` pre-build skills-sync + `--phase recap` the land/PR 3-part recap formatter), `scripts/cj-worktree-init.sh` (`--caller todo`, base-freshness; drain mode creates one worktree per TODO via `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh`), `scripts/cj-worktree-cleanup.sh` (post-land janitor, called directly), `scripts/check-version-queue.sh` (optional `/ship` preflight).
````

````touches-docs
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into each drained TODO's PR. Also marks the closed row in TODOS.md (hash-verified).
````

## utilities-and-phase-steps
kind: roster

````body
## How the machinery works

The three orchestrator charts above share the same load-bearing pieces. Rather
than re-explain them in each chart, this glossary says what each one DOES and WHY
it exists, so the per-workflow "In words" narratives can just name them. (For the
routing decision — *which* orchestrator to pick — see
[philosophy.md ## Decision tree](../philosophy.md#decision-tree-which-cj_-skill-do-i-call);
for the lower-level mechanism reference see [architecture.md](../architecture.md).)

### `scripts/cj-goal-common.sh` — the shared phase dispatcher

**What:** a single helper the three orchestrators call for their deterministic,
non-interactive steps, selected by a `--phase` flag. The phases are `worktree`
(create + assert the isolated worktree, delegating to `cj-worktree-init.sh`),
`sync` (the pre-build skills-sync — reuses `post-land-sync.sh`'s guarded pull +
install core so installed skills match trunk at build start), `pr-check` (resolve
a PR's live state for resume + cleanup gating), `cleanup` (the post-run worktree
janitor, delegating to `cj-worktree-cleanup.sh`), and `telemetry` (append one JSONL
receipt to `~/.gstack/analytics/<verb>.jsonl`). **Why:** it factors the
deterministic machinery out of all three orchestrators so they share one tested
implementation instead of each re-deriving the worktree/sync/cleanup/telemetry
logic. The Skill-tool invocations (`/office-hours`, scaffold, implement, QA,
`/ship`) stay INLINE in each verb skill; only the mechanical phases are
dispatched here.

### `scripts/cj-worktree-init.sh` — worktree create-or-detect + isolation gate

**What:** creates the `cj-{feat,def,todo}-*` worktree (or detects an existing one
and no-ops, so a managed session already inside a worktree is left alone), runs
the **base-freshness** fast-forward (when on `main`/`master` with an
`origin/<branch>` ref, fail-soft fetches and fast-forwards local `main` to the
origin tip so the new worktree branches off current trunk — outcome rides the
`note` field of the emitted JSON), and exposes the `--assert-isolated` verdict
mode that the isolation gate uses to refuse an un-isolated build. **Why:** keeps
the `main` checkout clean and lets parallel sessions run without colliding; the
base-freshness fork means a build never silently starts off a stale trunk, and
the isolation assertion is the gate that enforces "do all work in the worktree."

### `scripts/cj-worktree-cleanup.sh` — the PR-state-gated janitor

**What:** the teardown mirror of `cj-worktree-init.sh`. It removes landed
(`MERGED`/`CLOSED`) `cj-*` worktrees — gated on the PR's live state via `--phase
pr-check`, NOT on branch ancestry (a squash merge breaks ancestry) — prunes the
worktree list, sweeps leftover orphan `cj-*` dirs git no longer tracks, and
refreshes the root checkout to a fresh `main`. It skips any worktree that is
current, locked, dirty, has an OPEN PR, or has no PR. **Why:** a remote `gh pr
merge` leaves the local worktree dir behind; this sweeps it automatically at each
orchestrator's post-land terminal. It is strictly best-effort — it always exits 0
and never halts the calling run. (A feature run does NOT sweep its own worktree —
its PR is still OPEN at the PR-stop — so the *next* `cj_goal` run clears it; the
sweep is self-healing across runs.)

### `scripts/e2e-local.sh` — the local happy-path E2E harness

**What:** a LOCAL-only harness (gated on `CJ_E2E_LOCAL=1` plus gstack + a usable
claude login — `ANTHROPIC_API_KEY`, or a `claude auth login` confirmed by a tiny
live probe — plus `claude` + `gh`; it SKIPs with a one-line reason otherwise,
so CI and a normal `test.sh` never touch a model) that runs a REAL `/CJ_goal_task`
build end to end in a throwaway sandbox — a `mktemp` clone + a `.cj-e2e-sandbox`
marker + a LOCAL bare origin (accepts push, defeats `gh pr create`) — driven
unattended through the build gates by the build-gate auto-answer seam
(`scripts/cj-e2e-gate.sh`), stopping at the `/ship` boundary. Every run writes a
**materialized report** (`tests/e2e-local/reports/<verb>-<UTC-ts>.md` + a `.json`
sibling) whose coverage rows are each labelled DETERMINISTIC (asserted in shell)
vs `claude --print` (the real model run) and whose Outcome is DERIVED from real
post-run evidence (a new `work-items/tasks/T*/` dir, a non-empty diff, the run's
`end_state`) — a row without evidence renders `unverified`, never a false pass.
Its deterministic half (the SKIP path, the sandbox lib, the report generator) is
unit-tested with no Claude by `tests/e2e-local.test.sh`. **Why:** the automated
happy-path E2E is blocked in CI four ways (gstack absent, the read-only eval tool
grant, the per-case budget, the interactive AUQs) and, even locally, by the AUQ
wall; a LOCAL real run with the *build* gates auto-answered under the Part-A seam
(NEVER the ship/merge/deploy gates — the seam's allowlist is `{design-gate,
qa-audit}`) is the honest proof, and the report makes its coverage legible instead
of a bare checkmark. It never auto-ships: the sandbox's no-remote bare origin is
the sole auto-ship backstop, and the seam can never answer a ship/merge/deploy gate.

### `/CJ_document-release` — the Step 5.5 doc-sync wrapper

**What:** the inline doc-sync step every orchestrator runs at **Step 5.5**,
between QA pass and `/ship`. It wraps upstream `/document-release`, adds a `--docs
<subset>` filter and a halt-on-red contract, and auto-commits ONLY the doc files
allowed by the doc-only whitelist DERIVED from the `doc-spec.md` registry (a
non-whitelist write HALTs). **Why:** it folds documentation updates into the SAME
code PR as the change that necessitated them, so there is no post-merge doc-drift
window to chase separately. (Its own registered-doc audit also produces the
verdicts the orchestrators surface to the PR body.)

### The resume state file — last_completed_phase + per-phase SHA + PR#, validate-before-skip

**What:** each orchestrator records its progress to a per-branch state file: the
`last_completed_phase`, the HEAD SHA at each completed phase, and the open PR
number. On a re-invocation (`resume`), it does NOT blindly skip to the recorded
phase — it **validates before skipping**: a recorded phase's SHA must be an
ancestor of (or equal to) current HEAD, AND any recorded PR must still read OPEN;
if either check fails, that phase restarts. **Why:** a long autonomous build can
be interrupted (a halt, a crash, an operator stop), and a naive "resume at phase
N" would skip real work if the tree moved underneath it. Validate-before-skip
means a resume re-enters exactly where the recorded state is still trustworthy
and redoes anything that isn't.

## Utilities & phase-step skills

The `## Orchestrators` above chain multiple skills end-to-end. The skills here
are the single-purpose **building blocks** those chains dispatch (the phase-step
skills + the validator), plus the standalone **utilities** the operator runs
directly. They don't get a workflow chart — a single-step skill dispatches no
skills and runs no pipeline — so each entry uses a **lighter shape** than the
orchestrator 4-bullet Touches: `### <skill>` + **Status** + **Source** +
**Invoke when** (1 line) + a compact **Touches** (`Scripts · tools · shell:` what
it runs + `Reads / writes:` files/state it touches). The **Skills dispatched** /
**Steps · phases** bullets are intentionally omitted (empty for single-step
skills). Every skill below is also in
[philosophy.md ## Decision tree](../philosophy.md#decision-tree-which-cj_-skill-do-i-call)
(the New-skills check, the no-vanish safety net).

### Phase-step skills

Dispatched by the orchestrators as depth-<=2 leaf subagents.

#### CJ_scaffold-work-item

**Status:** experimental
**Category:** standalone (writes a `work-items/` tree from templates; it
*optionally* executes `scripts/cj-id-claim.sh` for an atomic cross-worktree ID
claim, fail-soft to the 3-source check when the helper is absent — so no hard
workbench dependency)
**Source:** `skills/CJ_scaffold-work-item/SKILL.md` ·
`skills/CJ_scaffold-work-item/USAGE.md`
**Invoke when:** distilling an APPROVED `/office-hours` design doc into a
compliant `work-items/<type>/<id>_<slug>/` tree (TRACKER + per-type artifacts +
lifecycle gates); idempotent (re-run on the same input is a NO-OP).
**Touches:**

- **Scripts · tools · shell:** Read / Write / Edit; runs `/CJ_personal-workflow check` at the scaffold boundaries; ID-minting calls `scripts/cj-id-claim.sh` (atomic `mkdir`-CAS claim in the shared `.git` common-dir — the 4th ID source closing the pre-push race) with a fail-soft fallback to the 3-source `printf` when the helper is absent.
- **Reads / writes:** reads the APPROVED `/office-hours` design doc + `templates/CJ_personal-workflow/*` + `personal-artifact-manifests.json`; writes the new `work-items/<type>/<id>_<slug>/` tree.

#### CJ_implement-from-spec

**Status:** experimental
**Category:** standalone (writes code from a spec; cites validators only as
scanned-for path patterns, executes none)
**Source:** `skills/CJ_implement-from-spec/SKILL.md` ·
`skills/CJ_implement-from-spec/USAGE.md`
**Invoke when:** writing the code a tracked work-item describes — reads the
per-type spec (SPEC+DESIGN for user-stories, RCA+test-plan for defects,
TRACKER+test-plan for tasks) and writes via Read/Edit/Write; propose-and-confirm
by default with a sensitive-surface AUQ, `--auto` for trivial <=2-file changes;
idempotent.
**Touches:**

- **Scripts · tools · shell:** Read / Edit / Write; `git rm` for removals; `chmod +x` for new shell scripts; runs `/CJ_personal-workflow check` at the start + end boundaries.
- **Reads / writes:** reads the work-item's per-type input artifacts (+ parent feature DESIGN.md); writes the code files named in Components Affected and updates the TRACKER (journal + Files + Phase 2 implementer-owned gates).

#### CJ_qa-work-item

**Status:** experimental
**Category:** standalone (runs the work-item's own test-plan rows; the root
`scripts/test.sh` citation is prose, not an executed hardcode)
**Source:** `skills/CJ_qa-work-item/SKILL.md` · `skills/CJ_qa-work-item/USAGE.md`
**Invoke when:** verifying a work-item against its test rows — user-stories get
smoke + a fresh-context E2E subagent per TEST-SPEC row; defects/tasks run their
test-plan rows smoke-equivalent; refuses on incomplete Phase 2; idempotent.
**Touches:**

- **Scripts · tools · shell:** Bash (runs the work-item's test-plan / TEST-SPEC rows + repo `scripts/test.sh` / `scripts/validate.sh` where a row calls them); runs `/CJ_personal-workflow check` at boundaries.
- **Reads / writes:** reads the work-item's test-plan / TEST-SPEC rows; writes findings to the TRACKER journal and transitions Phase 2 QA-owned gates.

#### CJ_document-release

**Status:** experimental
**Category:** local-only (executes its config helper via repo-local -> the
deployed `_cj-shared` home; folds doc-sync into the workbench's own PR — matches
`skills-catalog.json`'s `local-only`)
**Source:** `skills/CJ_document-release/SKILL.md` ·
`skills/CJ_document-release/USAGE.md`
**Invoke when:** inline at **Step 5.5** of all three `cj_goal` orchestrators
(between QA pass and `/ship`) to fold doc updates into the same code PR; also
operator-callable for a point-in-time doc audit. Wraps upstream
`/document-release`; adds a `--docs <subset>` filter, a halt-on-red contract
(`[doc-sync-red]`), and a doc-only auto-commit gated by the doc-only whitelist
DERIVED from the `doc-spec.md` registry. It also self-bootstraps a missing
`doc-spec.md` from the portable Common seed and stub-scaffolds any missing
declared doc. (Mechanism detail: architecture.md `## The doc-spec.md contract +
/CJ_document-release`.)
**Touches:**

- **Scripts · tools · shell:** the `Skill` tool (dispatches upstream `/document-release`); `scripts/doc-spec.sh` (`--validate` / `--expand-whitelist` / `--list-declared` / `--seed`); `git add` + `git commit` for the doc-only auto-commit.
- **Reads / writes:** reads `spec/doc-spec.md` (the registry, resolved spec/-then-root) + the declared docs; writes the whitelisted doc set (README.md, CHANGELOG.md, CLAUDE.md, `docs/**`), self-bootstraps a missing `doc-spec.md`, stub-scaffolds missing declared docs, and writes a `### Registered-doc requirements` verdict block to the gitignored `.cj-goal-feature/registered-doc-verdicts.md` scratch file.

### Validators

Depended on by every phase-step + orchestrator; run transitively at boundaries.

#### CJ_personal-workflow

**Status:** active
**Category:** workbench (executes the root `scripts/check-gates-update.sh` helper
— matches `skills-catalog.json`)
**Source:** `skills/CJ_personal-workflow/SKILL.md` ·
`skills/CJ_personal-workflow/USAGE.md`
**Invoke when:** validating work-item directories + tracker files against the
personal templates and `personal-artifact-manifests.json`; the phase-step skills
call it at their boundaries. Templates + WORKFLOW.md are the single source of
truth for structural rules.
**Touches:**

- **Scripts · tools · shell:** Read / Glob / Grep / Bash (prose-driven check per `check.md`; no standalone helper script).
- **Reads / writes:** reads `personal-artifact-manifests.json` + `templates/CJ_personal-workflow/*` + the work-item tree; read-only audit — emits a structured PASS / `[MISSING]` / `[DRIFT]` / `[EXTRA]` report, mutates nothing.

### Standalone utilities

Operator-invoked directly; not part of a chain.

#### CJ_system-health

**Status:** active
**Category:** standalone (read-only `~/.claude/` dashboard; only the passive
update-nudge, no executed root `.sh`)
**Source:** `skills/CJ_system-health/SKILL.md` ·
`skills/CJ_system-health/USAGE.md`
**Invoke when:** you want a read-only `~/.claude/` health dashboard — scans
installed skills, builds a dependency graph, checks filesystem health, surfaces
usage analytics with a behavioral-topology overlay, optionally invokes waza;
produces a scored report with trend tracking.
**Touches:**

- **Scripts · tools · shell:** Bash / Read / Glob / Grep; optionally invokes `waza` (config hygiene).
- **Reads / writes:** reads `~/.claude/` (installed skills, manifest, analytics JSONL); read-only dashboard plus a trend-history write.

#### CJ_suggest

**Status:** active
**Category:** local-only (reaches deployed `~/.claude` state via its own bundled
`skills/CJ_suggest/scripts/suggest.sh` — matches `skills-catalog.json`)
**Source:** `skills/CJ_suggest/SKILL.md` · `skills/CJ_suggest/USAGE.md`
**Invoke when:** you want a ranked top-5 (or `--limit N`) of next-up work items;
internal phase-step rows are filtered by default (`--include-internal` surfaces
them); `--for-skill` / `--limit` pre-filter for downstream callers like
`/CJ_goal_todo_fix`.
**Touches:**

- **Scripts · tools · shell:** `skills/CJ_suggest/scripts/suggest.sh` (the ranking helper); Read / Grep.
- **Reads / writes:** reads `TODOS.md` + each work-item TRACKER's frontmatter; read-only — prints the ranked list, mutates nothing.

#### CJ_improve-queue

**Status:** experimental
**Category:** standalone (offline repo scan + URL triage; appends draft
`TODOS.md` rows, executes no root workbench helper)
**Source:** `skills/CJ_improve-queue/SKILL.md` ·
`skills/CJ_improve-queue/USAGE.md`
**Invoke when:** workbench self-improvement — `evaluate <url>` (fetch + classify
a Claude best-practice article -> draft TODOS row if novel), `audit` (offline
repo self-scan), `research <topic>` (WebSearch + per-result evaluate with a
privacy gate); all rows land with `<!--impr-draft-->` markers.
**Touches:**

- **Scripts · tools · shell:** the `/browse` skill (URL fetch), WebSearch; an mkdir-based write lock + atomic `mv`; Read / Edit.
- **Reads / writes:** reads the fetched article + the repo (audit mode) + `skills-catalog.json`; appends `<!--impr-draft-->`-marked draft rows to `TODOS.md` (backup-rotated).

#### CJ_portability-audit

**Status:** experimental
**Category:** workbench (operates ON the workbench — reaches its own root engine
via the deployed shared home; matches `skills-catalog.json`)
**Source:** `skills/CJ_portability-audit/SKILL.md` ·
`skills/CJ_portability-audit/USAGE.md` · engine
`scripts/cj-portability-audit.sh`
**Invoke when:** you want to verify the workbench's own skills HONESTLY declare
their `portability` — a static lint over the catalog that flags a skill declaring
`standalone` while it *executes* a repo-local workbench helper a fresh target
repo won't have; read-only and advisory (also wired into `validate.sh` as an
advisory check). The full correct-behavior spec is in
[utility-audits.md](utility-audits.md) `## Utility audits` ->
`### /CJ_portability-audit`.
**Touches:**

- **Scripts · tools · shell:** `scripts/cj-portability-audit.sh` (the shared engine, resolved repo-local-first then via the deployed shared home); Bash / Read / Grep. Also invoked by `scripts/validate.sh`.
- **Reads / writes:** reads `skills-catalog.json` (+ optional `portability_requires`) + each audited skill's files; read-only — prints the per-skill verdict table, mutates nothing.

#### CJ_test_run

**Status:** experimental
**Category:** local-only (runnable in ANY repo the skills are installed for;
resolves both engines repo-local-first then via the deployed shared home)
**Source:** `skills/CJ_test_run/SKILL.md` · `skills/CJ_test_run/USAGE.md` ·
engines `scripts/test-run.sh` + `scripts/test-spec.sh`
**Invoke when:** you want to actually RUN the repo's tests and get honest
evidence-derived pass/fail — the "does it pass?" companion to `/CJ_test_audit`'s
"is it wired?". It runs a deterministic Stage-1 audit pre-step (the four
`test-spec.sh` engine calls, invalid-halts / valid-with-findings-surfaces /
absent-skips), then `scripts/test-run.sh` (reads the `runners:` axis, runs the
selected tier ONCE — default `free`; `--evals`/`--e2e`/`--all` widen it, never a
surprise model spend), then narrates the `.md` report + `.json` ledger. Registry
edges are honest (absent → `REGISTRY=absent`; invalid → the passthrough halt;
zero runners → `SKIP: no runners declared`).
**Touches:**

- **Scripts · tools · shell:** `scripts/test-run.sh` (the execution engine) + `scripts/test-spec.sh` (`--validate` / `--check-coverage` / `--render-docs --check` / `--check-workflow-coverage` / `--list-runners` / `--list-units --with-family`), both resolved sibling → `$REPO_ROOT/scripts/` → `_cj-shared`; Bash / Read / Grep.
- **Reads / writes:** reads the merged test-spec registry (`spec/test-spec.md` + `spec/test-spec-custom.md`); executes the declared runners; writes a per-run `tests/test-run/reports/<UTC-ts>.md` + `.json` ledger (gitignored except the committed `EXAMPLE.md`).
````

## utility-audits
kind: roster

````body
## Utility audits

### /CJ_portability-audit

**Status:** experimental (the static-lint Layer 1)
**Category:** workbench (operates ON the workbench — reaches its own root engine
via the deployed shared home; matches `skills-catalog.json`)
**Source:** `skills/CJ_portability-audit/SKILL.md` ·
`skills/CJ_portability-audit/USAGE.md` · engine
`scripts/cj-portability-audit.sh`

**Invoke when:** you want to verify the workbench's own skills HONESTLY declare
their `portability` — i.e. whether a skill declared `standalone` quietly reaches
for repo-local artifacts a fresh target repo will not have. Not part of a
`cj_goal` chain — a single-step utility (this section documents its correct
behavior verbatim, operator-requested; it is NOT a `CJ_goal_*` orchestrator).

> This is the authoritative **correct-behavior spec** for the engine: the tier
> ladder, the EXECUTED-vs-documented rule, the carve-outs, and the
> expected-findings table. The operator reads this to confirm the implementation
> (`scripts/cj-portability-audit.sh`) matches the intended behavior. The same
> contract is mirrored in the skill's `SKILL.md`.

**Workflow:**

```
skills-catalog.json (+ optional portability_requires per entry)
   |  jq: status != "deprecated"  &&  (files | length) > 0   (runtime-derived; NO hardcoded count)
   v
for each audited skill:
   |   collect files = catalog files[] + skill-dir *.md + skill-dir scripts/*.sh
   v
classify each repo-local dependency reference:
   |   EXECUTED   = runnable position - bash "$X" / source "$X" / [ -f "$X" ] / [ -x "$X" ]
   |               inside a ```bash fence OR a .sh engine script
   |   DOCUMENTED = prose / table / comment mention
   |   (root scripts/*.sh helper set is GLOBBED at runtime - never hardcoded;
   |    only the root-config set + the GitHub slug are literals)
   v
apply carve-outs:
   |   bundled-own-script:        scripts/*.sh under skills/<name>/scripts/ -> OK (never a finding)
   |   self-resolution preamble:  root-script engine-locate reach-back ->
   |                              OK-with-note for workbench|local-only; FINDING for standalone
   |   portability_requires:      a listed (adjudicated) dep -> OK; a stale listed dep -> note
   v
classify each EXECUTED hit against the STRICT tier ladder:
   |   standalone  <  local-only  <  workbench
   |   dep within declared tier -> OK; dep exceeding it -> FINDING
   v
per-skill verdict:  portable  /  portable-with-notes  /  findings:<list>
   |   finding text: "<skill> declared <tier> but depends on <dep> (needs <higher-tier>)"
   v
two surfaces share the engine:
   |--  /CJ_portability-audit skill          -> rich per-skill verdict table
   `--  validate.sh Check 18                 -> strict-by-default: a finding hard-fails
                                                every commit / CI / manual run
                                                (PORTABILITY_STRICT=0 downgrades to advisory;
                                                catalog currently FINDINGS=0)
```

**Strict tier ladder (each tier's ALLOWED dependency set; the bar is "works in a
repo that has never seen this workbench"):**

| Tier | ALLOWED | A dep beyond this is a FINDING |
|---|---|---|
| `standalone` | own bundled scripts (`skills/<name>/scripts/`) + the doc-spec contract files (`spec/doc-spec.md`, `docs/**`, `TODOS.md`, `work-items/`) | root `scripts/*.sh`, `CLAUDE.md` reads, root config, the GitHub slug |
| `local-only` | standalone's set PLUS the user's `~/.claude` deployed state | root workbench helpers, root config |
| `workbench` | everything PLUS root `scripts/*.sh`, `CLAUDE.md` reads, root config | (nothing — this is the tier for skills that operate ON the workbench) |

An unknown `portability` value (not in the closed enum `{standalone, local-only,
workbench}`) is itself a finding.

**Correctly NOT flagged (the EXECUTED-vs-documented precision rule at work):**

| Skill | Declared | Why NOT a finding |
|---|---|---|
| `CJ_qa-work-item` | `standalone` | references `scripts/test.sh` ONLY as a prose citation; it executes the per-work-item test-plan `Script/Command` column, NOT a hardcoded root helper -> **DOCUMENTED**, not executed -> not a finding. |
| `CJ_implement-from-spec` | `standalone` | references `scripts/validate.sh`/`test.sh`/`test-deploy.sh` ONLY in its sensitive-surface PATH-PATTERN list (backticked prose it scans FOR) -> **DOCUMENTED**, not executed -> not a finding |
| `CJ_document-release` | `local-only` | reaches its config helper via the deployed shared home (within-tier) -> **OK** |
| `CJ_suggest` | `local-only` | `~/.claude` deployed state + own bundled `scripts/suggest.sh` -> **OK** |
| `CJ_system-health`, `CJ_scaffold-work-item`, `CJ_improve-queue` | `standalone` | only the passive update-nudge, no executed ROOT `.sh` -> **OK** (`portable`) |
| `CJ_portability-audit` | `workbench` | its own ROOT engine via the deployed shared home (within-tier) -> **OK** (`portable-with-notes`) |

The audit does NOT auto-fix. The operator resolves each finding either by an
**honest relabel** of the skill's `portability` (the candid fix for the
orchestrators — they genuinely need the workbench) OR by **adjudicating** the dep
via the optional `portability_requires` accepted-deps catalog field. The
orchestrators are relabeled `workbench`; `portability_requires` is available for
any remaining adjudication so the default run + the advisory check land
**green**, while `--no-adjudication` still shows the reasoning above (proving the
audit is non-no-op).

**Posture:** ADVISORY in v1 — the `validate.sh` advisory check prints findings
and **exits 0**; the engine itself exits 0 in default mode. `PORTABILITY_STRICT=1`
flips it (and the engine's exit code) to hard-fail — the documented follow-up
once the workbench's declarations are fully reconciled.

**Touches:**

- **Skills dispatched:** none (a single-step utility; no chain).
- **Scripts / tools:** `scripts/cj-portability-audit.sh` (the shared engine, resolved repo-local-first then via the deployed shared home), invoked by the skill AND by `scripts/validate.sh`.
- **Docs it updates:** none — read-only. (Resolving a finding is a separate operator edit to `skills-catalog.json`.)

### /CJ_doc_audit

**Status:** experimental
**Category:** local-only (runs in ANY repo; resolves its engine repo-local
`scripts/doc-spec.sh` then the deployed `_cj-shared` home; matches
`skills-catalog.json`)
**Source:** `skills/CJ_doc_audit/SKILL.md` · `skills/CJ_doc_audit/USAGE.md` ·
engine `scripts/doc-spec.sh`

**Invoke when:** you want one keystroke that answers "do this repo's docs follow
its doc contract?" — in the workbench or any consumer repo. First run in a fresh
repo seed-delivers the two-tier contract (`spec/doc-spec.md` from
`doc-spec.sh --seed`, `seeded: yes`; second run `seeded: no`). Three stages:
Stage 1 is ONE engine call (`doc-spec.sh --check-on-disk`, printed verbatim) plus
the workflow-docs freshness check (`workflow-spec.sh --render-docs --check` when
the engine is present); Stages 2 (requirement compliance — each `requirement:`
quoted, clause-checked, evidence cited) and 3 (implementation drift — ground
truth enumerated first, then each contract doc cross-walked; `docs/workflow.md` +
`docs/workflows/` are recognized as a GENERATED surface sourced from
`spec/workflow-spec.md`, never an orphan/drift) are agent-judged and, standalone,
REQUIRED to run in one fresh-context subagent. On cj_goal orchestrator paths QA
defers this audit (`DEFER_AUDIT: true`) and the orchestrator runs it ONCE post-sync
(after `/CJ_document-release`) as part of the combined read-only post-sync audit
subagent, feeding the post-QA checkpoint with the docs that will actually ship;
standalone `/CJ_qa-work-item` Step 8.6c still runs it INLINE (a subagent cannot
spawn subagents).

**Touches:**

- **Scripts · tools · shell:** `scripts/doc-spec.sh` (`--seed` / `--validate` /
  `--check-on-disk` — the Stage-1 engine — / the merged list subcommands),
  `scripts/workflow-spec.sh` (`--render-docs --check` — the workflow-docs
  freshness check folded into Stage 1), plus the Agent tool for the standalone
  fresh-context dispatch of Stages 2+3.
- **Reads / writes:** reads the merged registry (`spec/doc-spec.md` +
  `spec/doc-spec-custom.md`), every declared doc, and the live repo state
  (catalog skills, scripts, workflows, dirs — the Stage-3 ground truth); its
  ONLY write is the idempotent seed delivery of a missing `spec/doc-spec.md`.
  Findings ride the per-stage `DOC_AUDIT:` report (`STAGE1/2/3_FINDINGS=` +
  `stageN/` prefixes) — never a halt.

### /CJ_test_audit

**Status:** experimental
**Category:** local-only (runs in ANY repo; resolves its engine repo-local
`scripts/test-spec.sh` then the deployed `_cj-shared` home; matches
`skills-catalog.json`)
**Source:** `skills/CJ_test_audit/SKILL.md` · `skills/CJ_test_audit/USAGE.md` ·
engine `scripts/test-spec.sh`

**Invoke when:** you want one keystroke that answers "are this repo's tests
aligned with its test contract?". First run in a fresh repo seed-delivers the
general 5-rule contract (`spec/test-spec.md` from `test-spec.sh --seed`); the
coverage cross-check activates once the repo declares `units:` rows in
`spec/test-spec-custom.md` (a rules-only repo gets the named "coverage
cross-check inactive" note). Three stages, symmetric with `/CJ_doc_audit`:
Stage 1 is the existing engine calls (`test-spec.sh --validate` +
`--check-coverage`, `stage1/`-prefixed findings); Stage 2 judges each rule's
`statement` with cited evidence AND each unit's `purpose`/`label` truthfulness
against the source at its anchor; Stage 3 enumerates the live verification
surfaces and judges coverage-in-substance. Standalone, Stages 2+3 run in one
fresh-context subagent (shared with `/CJ_doc_audit` when both run). On cj_goal
orchestrator paths QA defers this audit (`DEFER_AUDIT: true`) and the orchestrator
runs it ONCE post-sync (after `/CJ_document-release`) as part of the same combined
read-only post-sync audit subagent, feeding the post-QA checkpoint; standalone
`/CJ_qa-work-item` Step 8.6d still runs it INLINE.

**Touches:**

- **Scripts · tools · shell:** `scripts/test-spec.sh` (`--seed` / `--validate` /
  `--list-rules` / `--list-units` / `--check-coverage` — the forward + reverse
  + floor engine), the repo's declared suite runner when judging `suite-green`
  standalone, plus the Agent tool for the standalone fresh-context dispatch of
  Stages 2+3.
- **Reads / writes:** reads the merged registry (`spec/test-spec.md` +
  `spec/test-spec-custom.md`) and the live verification surface
  (`scripts/validate.sh` banners, `tests/*.test.sh`, workflows, hooks — also
  the Stage-3 ground truth); its ONLY write is the idempotent seed delivery of
  a missing `spec/test-spec.md`. Findings ride the per-stage `TEST_AUDIT:`
  report (`STAGE1/2/3_FINDINGS=` + `stageN/` prefixes) — never a halt.
````
<!-- WORKFLOW-SPEC:END -->
