# gate-spec.md — what stops a broken cj_goal change from landing

This file is the single answer to one question: **what stops a broken cj_goal
change from landing, and at which layer?** It is both the human-readable map (the
prose, the table, and the ASCII diagram below) and the machine source of truth
(the fenced `yaml` registry at the end, parsed by `scripts/gate-spec.sh`). One
file, no second list to keep in sync.

It is the third member of the `spec/doc-spec.md` → `spec/permission-policy.md` →
`spec/gate-spec.md` family: the same proven shape (a `spec/` registry doc + a
`scripts/` reader + an advisory `scripts/validate.sh` check) applied to a new
concern. Anyone who already understands `spec/doc-spec.md` understands this file
on sight.

## The four verification layers

A cj_goal change passes through four independent verification layers between an
edit and a landed PR. Each layer runs at a different moment and owns a different
kind of guarantee:

| Layer | When it runs | What it owns | Disposition |
|-------|--------------|--------------|-------------|
| **local-hook** | at `git commit` (pre-commit hook) | the commit is structurally valid before it ever leaves your machine | hard-fail (blocks the commit) |
| **ci** | on every PR (GitHub Actions) | the whole tree is structurally + behaviorally sound on a clean runner | hard-fail (gates the PR) |
| **pipeline-gate** | during a cj_goal run | this run did the right thing — isolated, designed, tested, documented, honest — before it reached the PR | mixed (most halt; some advise) |
| **ratchet** | inside ci / the orchestrator | a monotonic property never regresses (VERSION, the portability baseline, doc freshness) | advisory or hard-fail |

The word **"gate"** is reserved here for a single thing: an **inline
orchestrator halt** (a `pipeline-gate` row below). `validate.sh`-as-a-whole is
the **ci** layer (a set of numbered *checks*), not "the gate." A monotonic guard
is a **ratchet**. Three words, three referents, no overload.

## How the layers fit together

```
                         gate-spec.md (this file)
                    ┌──────────────────────────────────┐
                    │ four-layer map + division-of-     │
                    │ labor + a fenced `yaml` registry  │
                    │   layers[]: local-hook | ci |     │
                    │             pipeline-gate|ratchet │
                    │   gates[]: per-mode `markers` map │
                    │            ({enforced_by} escape) │
                    └─────────────────┬─────────────────┘
                                      │ parsed by scripts/gate-spec.sh
                                      │  (--validate / --list-layers / --list-gates)
        ┌─────────────────────────────┼─────────────────────────────┐
        │ references                  │ references                  │ cross-checks
        ▼                             ▼                             ▼
  the four CJ_goal_* pipelines   the human docs            validate.sh Check 22
  (one-line canonical-gate-      (architecture.md /        (advisory: registry parses
   sequence reference line)       philosophy.md §4 /        + per-mode marker drift
                                  doc-spec.md registry /     guard across the four
                                  CLAUDE.md pointer)         pipelines; exit 0)

  edit ──▶ [local-hook] ──▶ [pipeline-gate]* ──▶ [ci] ──▶ PR (human review) ──▶ land
            commit            during the run        on the PR
            (validate.sh)     (isolation→design→    (validate.sh +
                               qa→doc-sync→          test.sh + shellcheck +
                               portability→ship)     windows smoke)
            with [ratchet] properties checked inside ci and the orchestrator
            (* a cj_goal run; a plain commit skips the pipeline-gate layer)
```

## Division of labor — one owning layer per guarantee

Each guarantee is owned by exactly **one** layer. This is the de-duplication: a
guarantee is not re-checked at three layers with three vocabularies.

| Guarantee | Owning layer | How |
|-----------|--------------|-----|
| The catalog ⇔ filesystem ⇔ doc-spec registry is internally consistent | **ci** | `validate.sh` checks (run by the local-hook too, authoritative in CI) |
| The full test suite + shellcheck + Windows Git-Bash smoke pass | **ci** | `test.sh` / `shellcheck` / `windows.yml` on the PR |
| This run built in a clean, isolated worktree (no in-place source write) | **pipeline-gate** | the isolation gate (`[feature-not-isolated]` / `[investigate-not-isolated]` / `[task-not-isolated]`) |
| A feature's design was approved before the autonomous budget was spent | **pipeline-gate** | the design-summary gate (`[design-gate-declined]`, feature only) |
| A defect actually found a root cause before anything shipped | **pipeline-gate** | the investigate Iron-Law gate (`[investigate-no-root-cause]`, defect only) |
| A "task" is genuinely small (not disguised design/bug work) | **pipeline-gate** | the hard complexity gate (`[task-too-complex]`, task only) |
| The work-item's tests pass | **pipeline-gate** | the QA gate (`[qa-red]`; todo enforces via a subagent, no bracket marker) |
| Doc drift is folded into the same PR | **pipeline-gate** | the doc-sync gate (`[doc-sync-red]`, universal) |
| No touched skill declares a portability tier it does not honor | **pipeline-gate** | the portability gate (`[portability-red]`, universal) |
| The change reaches a human before it merges | **pipeline-gate** | the ship gate (`[ship-declined]`; PR-stop + human merge) |
| VERSION never regresses | **ratchet** | `validate.sh` Check 8 |
| The portability baseline stays clean (FINDINGS=0) | **ratchet** | the portability `FINDINGS=0` baseline (Check 18 / the strict orchestrator gate) |
| USAGE.md stays fresh against its SKILL.md | **ratchet** | `validate.sh` Check 14 |

## The plain answer

**What stops a broken cj_goal change from landing, and at which layer?**

- A **structurally broken** change (bad catalog wiring, a missing doc, a failing
  test) is stopped by **ci** — the `validate.sh` / `test.sh` checks, hard-fail,
  on the PR (and locally at the commit via the pre-commit hook).
- A **process-broken** change (built in-place, never designed, never tested,
  undocumented, portability-dishonest, or trying to self-merge) is stopped by a
  **pipeline-gate** — the inline halt inside the cj_goal run, before a PR even
  opens.
- A **regression** of a monotonic property (VERSION going backwards, a new
  portability finding, a stale USAGE.md) is stopped by a **ratchet**.
- And every change reaches a **human** at the **ship** pipeline-gate: the
  orchestrators STOP at a reviewable PR; the merge is the human's, not the
  orchestrator's.

## The registry (machine source of truth)

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file. `scripts/gate-spec.sh` parses it; `scripts/validate.sh` Check 22
cross-checks each declared literal marker against the live pipelines.

Schema:

- **`layers[]`** — `id` (closed enum `local-hook | ci | pipeline-gate |
  ratchet`), `name`, `trigger`, `disposition` (closed enum `hard-fail | advisory
  | mixed | halt`), `owns`.
- **`gates[]`** — `id`, `layer`, `order` (the canonical run order; a mode runs
  its subset in this order), `markers` (a **per-mode map** keyed by
  `feature|defect|task|todo`), `disposition`, `backing`, `checks`.
- **`markers`** is a per-mode map. A mode **absent** from the map does not run
  that gate. A map value is either a literal `"[marker]"` (Check 22 greps for it
  in that mode's files) OR `{ enforced_by: subagent | auq }` (the gate runs but
  emits no bracket marker, so Check 22 records it without grepping — the escape
  hatch that keeps the baseline honestly clean).

```yaml
# gate-spec registry (parsed by scripts/gate-spec.sh + scripts/validate.sh)
schema_version: 1
layers:
  - id: local-hook
    name: "Local pre-commit hook"
    trigger: "at git commit"
    disposition: hard-fail
    owns: "the commit is structurally valid before it leaves the machine"
  - id: ci
    name: "GitHub Actions CI"
    trigger: "on every PR"
    disposition: hard-fail
    owns: "the whole tree is structurally + behaviorally sound on a clean runner"
  - id: pipeline-gate
    name: "In-orchestrator gates"
    trigger: "during a cj_goal run"
    disposition: mixed
    owns: "this run did the right thing before it reached the PR"
  - id: ratchet
    name: "Regression ratchets"
    trigger: "inside ci / the orchestrator"
    disposition: advisory
    owns: "a monotonic property never regresses"
gates:
  # --- same concept, DIFFERENT marker per mode, absent in todo (todo runs inside the drain worktree) ---
  - id: isolation
    layer: pipeline-gate
    order: 10
    markers:
      feature: "[feature-not-isolated]"
      defect:  "[investigate-not-isolated]"
      task:    "[task-not-isolated]"
      # todo: omitted — todo runs inside the drain worktree, no isolation gate
    disposition: halt
    backing: "cj-worktree-init.sh isolation assertion"
    checks: "the build runs in a clean, isolated worktree (no in-place source write)"
  # --- feature-only: the design-summary approval gate ---
  - id: design-gate
    layer: pipeline-gate
    order: 20
    markers:
      feature: "[design-gate-declined]"
      # defect/task/todo: omitted — no /office-hours design phase
    disposition: halt
    backing: "design-summary approval AUQ (feature pipeline)"
    checks: "the APPROVED design is confirmed before the autonomous build budget is spent"
  # --- defect-only: the investigate Iron-Law gate ---
  - id: root-cause
    layer: pipeline-gate
    order: 25
    markers:
      defect: "[investigate-no-root-cause]"
      # feature/task/todo: omitted — only defect roots a fix in /investigate
    disposition: halt
    backing: "/investigate Iron-Law gate (defect pipeline)"
    checks: "a populated root cause exists before anything is promoted or shipped"
  # --- task-only: the hard complexity gate ---
  - id: complexity
    layer: pipeline-gate
    order: 30
    markers:
      task: "[task-too-complex]"
      # feature/defect/todo: omitted — only task gates on size
    disposition: halt
    backing: "cj-task-scaffold.sh hard complexity gate (task pipeline)"
    checks: "the task is genuinely small (not disguised design or bug work)"
  # --- a gate feature/defect/task run with a literal marker; todo enforces WITHOUT a marker ---
  - id: qa
    layer: pipeline-gate
    order: 40
    markers:
      feature: "[qa-red]"
      defect:  "[qa-red]"
      task:    "[qa-red]"
      todo:    { enforced_by: subagent }   # runs QA, emits no bracket marker
    disposition: halt
    backing: "/CJ_qa-work-item leaf subagent"
    checks: "the work-item's test rows pass"
  # --- universal, same marker in all four: the case enforced literally ---
  - id: doc-sync
    layer: pipeline-gate
    order: 50
    markers:
      feature: "[doc-sync-red]"
      defect:  "[doc-sync-red]"
      task:    "[doc-sync-red]"
      todo:    "[doc-sync-red]"
    disposition: halt
    backing: "/CJ_document-release (Step 5.5 doc-sync)"
    checks: "doc drift is folded into the same PR (registry parses; declared docs current)"
  # --- universal, same marker in all four ---
  - id: portability
    layer: pipeline-gate
    order: 60
    markers:
      feature: "[portability-red]"
      defect:  "[portability-red]"
      task:    "[portability-red]"
      todo:    "[portability-red]"
    disposition: halt
    backing: "cj-goal-common.sh --phase portability-audit (PORTABILITY_STRICT=1)"
    checks: "no touched skill declares a portability tier it does not honor"
  # --- feature/defect/task run a ship gate with a literal marker; todo ships via /land-and-deploy ---
  - id: ship
    layer: pipeline-gate
    order: 70
    markers:
      feature: "[ship-declined]"
      defect:  "[ship-declined]"
      task:    "[ship-declined]"
      todo:    { enforced_by: auq }   # /ship Gate #2 fires per drained TODO; no [ship-declined] bracket
    disposition: halt
    backing: "/ship Gate #2 (always human)"
    checks: "the change reaches a human before it merges (PR-stop + human merge)"
```
