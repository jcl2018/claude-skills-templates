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

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

## The index

| Workflow | Kind | Detail |
|----------|------|--------|
| `CJ_goal_feature` | orchestrator | [workflows/CJ_goal_feature.md](workflows/CJ_goal_feature.md) |
| `CJ_goal_task` | orchestrator | [workflows/CJ_goal_task.md](workflows/CJ_goal_task.md) |
| `CJ_goal_defect` | orchestrator | [workflows/CJ_goal_defect.md](workflows/CJ_goal_defect.md) |
| `CJ_goal_todo_fix` | orchestrator | [workflows/CJ_goal_todo_fix.md](workflows/CJ_goal_todo_fix.md) |
| `utilities-and-phase-steps` | roster | [workflows/utilities-and-phase-steps.md](workflows/utilities-and-phase-steps.md) |
| `utility-audits` | roster | [workflows/utility-audits.md](workflows/utility-audits.md) |
