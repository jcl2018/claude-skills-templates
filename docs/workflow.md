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
human-doc (no work-item IDs). The overview below must name every workflow — a
no-vanish guarantee enforced by `scripts/validate.sh` Check 15c (the index links
each `CJ_goal_*` orchestrator's `docs/workflows/<name>.md`) and Check 15b (each
of those orchestrator files carries its chart + the four anchored Touches
bullets).

For **routing** (which skill to pick for a given intent), see
[philosophy.md](philosophy.md) `## Decision tree`. For the workbench's
**mechanism reference** (auto-worktree, doc-sync wrapper, update-check, the
`work-copilot` bundle), see [architecture.md](architecture.md). For per-skill
operator + agent best-practice, see each skill's `USAGE.md`.

## The index

| Entry point | What it does | Detail |
|-------------|--------------|--------|
| `/CJ_goal_feature "<topic>"` | One-line feature topic → reviewable PR (design → scaffold → implement → QA → doc-sync → post-sync audit checkpoint → ship; stops at the PR). | [workflows/CJ_goal_feature.md](workflows/CJ_goal_feature.md) |
| `/CJ_goal_task "<small task>"` | Small ad-hoc task → reviewable PR (complexity gate → scaffold → implement → QA → doc-sync → post-sync audit checkpoint → ship; stops at the PR; no design, no investigation). | [workflows/CJ_goal_task.md](workflows/CJ_goal_task.md) |
| `/CJ_goal_defect "<bug>"` | Bug description → shipped fix (root-cause → RCA → implement → QA → doc-sync → post-sync audit checkpoint → ship → land). | [workflows/CJ_goal_defect.md](workflows/CJ_goal_defect.md) |
| `/CJ_goal_todo_fix [<id> \| "<frag>"]` | Drain shippable `TODOS.md` rows into PRs (single-TODO or `--max-drain N` batch). | [workflows/CJ_goal_todo_fix.md](workflows/CJ_goal_todo_fix.md) |
| Machinery + utilities & phase-step skills | The deterministic shared helpers the orchestrators call (worktree init/cleanup, pre-build skills-sync, version-queue preflight) + the single-step building blocks the chains dispatch / the operator runs directly (scaffold, implement, QA, doc-release, the validator, `/CJ_suggest`, `/CJ_system-health`, `/CJ_improve-queue`). | [workflows/utilities-and-phase-steps.md](workflows/utilities-and-phase-steps.md) |
| Utility audits | Standalone read-only audits — `/CJ_portability-audit`, `/CJ_doc_audit`, `/CJ_test_audit`. | [workflows/utility-audits.md](workflows/utility-audits.md) |

The four `cj_goal` orchestrators each get a per-workflow file under
`docs/workflows/` with a mandatory ASCII workflow chart and a four-bullet
**Touches** block (**Skills dispatched** / **Steps · phases** / **Scripts · tools
· shell** / **Docs touched**), so a reader can see the shape of every workflow —
and its blast radius — at a glance. The component skills (phase-steps, the
validator, the standalone utilities) use a lighter shape in
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
