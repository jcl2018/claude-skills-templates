# Architecture

Mechanism reference for the workbench's load-bearing layers. Pair with [PHILOSOPHY.md](PHILOSOPHY.md) — that doc explains *why* this workbench exists and which CJ_ skill to call; this doc explains *how* the mechanisms underneath those skills work.

## The shared cj-goal-common.sh helper (S000057)

`scripts/cj-goal-common.sh` is the deterministic helper consumed by the two intent-named front doors (`/CJ_goal_feature` and `/CJ_goal_defect`). It absorbs the phases that don't need per-skill prose: worktree management, PR-check polling, and telemetry writes. (Historically a third mode existed for `/CJ_goal_investigate` ~~before that skill was DEPRECATED~~ at v5.0.15; the mode's invocation surface is no longer reachable from any live front door — see `## Deprecation tombstones` below.)

**Phases it owns:**

- **worktree** — auto-creates `.claude/worktrees/cj-{feat|defect}-<ts>-<pid>/` when invoked from `main` with arguments, no-ops inside an existing Conductor-managed worktree, and exposes `--assert-isolated` so each orchestrator's Step 1.9 isolation gate can refuse to proceed on a dirty working tree.
- **pr-check** — polls `gh pr view` for the merge state of an open PR, captures the PR URL into the per-branch state file, and produces a deterministic `next_action=` / `resume_cmd=` / `pr_url=` line that the orchestrator can drop directly into its journal entry.
- **telemetry** — appends a single JSONL line per run to `~/.gstack/analytics/<skill>.jsonl` (one file per front door: `CJ_goal_feature.jsonl`, `CJ_goal_defect.jsonl`). The historical ~~`CJ_goal_investigate.jsonl`~~ stream is DEPRECATED — investigate retired at v5.0.15; the file remains on operator machines as archived state and is not written by any live skill.

**Modes it dispatches on:**

- **feature** — paired with `/CJ_goal_feature` (build a feature: topic → reviewable PR). Stops at the PR; deploy is a separate human step.
- **defect** — paired with `/CJ_goal_defect` (fix a bug: description → shipped fix). Runs `/investigate` as a depth-≤2 leaf subagent and only mints a D-ID after the Iron-Law gate passes.
- ~~**investigate** — paired with `/CJ_goal_investigate` (ship a fix for an already-scaffolded D000NNN defect).~~ **DEPRECATED at v5.0.15** (sunset v6.0.0); investigate is now a thin alias shim under `deprecated/CJ_goal_investigate/` that routes non-D-id args to `/CJ_goal_defect` and rejects bare D-id args. Reachable only via `skills-deploy install --include-deprecated`.

**Consumers:**

- `/CJ_goal_feature` (mode=feature) — primary consumer; pulls every phase from the helper.
- `/CJ_goal_defect` (mode=defect) — primary consumer; same phase surface.
- ~~`/CJ_goal_investigate` (mode=investigate)~~ — **DEPRECATED at v5.0.15** (sunset v6.0.0). Historical adoption-cadence note retained for the post-mortem: investigate predated the helper and adopted phases incrementally (telemetry already routed through the shared schema; worktree adoption was in flight when the skill retired). See `## Deprecation tombstones` below + [PHILOSOPHY.md ## Retired skills](PHILOSOPHY.md#retired-skills) for the canonical tombstone.

The helper is deliberately one shell file, not a directory or a skill. Each phase is a function the orchestrator sources and calls — there is no second layer of orchestration. Treat it as plumbing for the two front doors.

## F000028 doc-sync hooks (post-merge + post-rewrite)

F000028 wired two git hooks that drop a marker file every time `main` advances by a non-trivial merge, so the next `cj_goal` orchestrator invocation can prompt the operator to run `/document-release`.

**Marker file:**

- Path schema: `~/.gstack/doc-sync-pending/<repo-slug>.json` (one marker per repo; new merges overwrite the previous marker atomically via `mktemp` + `mv`).
- Fields:
  - `repo` — repo slug for cross-checking.
  - `head_sha` — the SHA at which the hook fired; the marker self-cleans when this SHA is unreachable from current HEAD (force-push, `git reset --hard`).
  - `main_moved_at` — ISO timestamp.
  - `diff_base` — the SHA the doc-release auditor should diff against (typically the previous main tip).
  - `changed_files` — list of touched files at the merge boundary, used by `/document-release` Step 2 to scope its audit pass.

**Hooks that fire it:**

- **post-merge** — fires on every merge into the local checkout, including `git pull` fast-forwards. Skipped on trivial merges where the diff doesn't move the documentable surface (e.g., a merge that only touches `.gitignore` or a hidden cache file is not worth surfacing as doc-sync drift).
- **post-rewrite** — fires on rebase / amend operations that rewrite history, catching the case where `main` moves via rewrite rather than fast-forward.

**What they don't fire on:**

- Trivial main-moving merges (the changed-file filter drops zero-impact diffs before writing a marker).
- Branch-local commits that don't move `main`.
- Stash / cherry-pick operations that don't trigger either hook.

The hook layer is detection only — it writes the marker and exits. The pickup-and-AUQ layer lives in the orchestrator preambles (see next section).

## F000029 marker-pickup AUQ (cj_goal preambles)

F000029 added the consumer side of the F000028 marker layer: each `cj_goal` orchestrator preamble emits a `DOC_SYNC_PENDING <path>` line and prompts the operator to handle it via AskUserQuestion.

**Script-output-drives-AUQ split.** This is the novel architectural pattern (called out explicitly in CLAUDE.md). The script `scripts/skills-doc-sync-check` does *detection only* — it checks for the marker file, validates that the recorded `head_sha` is reachable from current HEAD (else stale-self-cleans), and prints exactly one line of output: `DOC_SYNC_PENDING <marker-path>`. The script does NOT own the AUQ template, the branch-aware option ordering, or any post-AUQ follow-through. Those live in the SKILL.md prose of each `cj_goal` orchestrator.

This split is load-bearing because the AUQ shape depends on context that the script can't observe cleanly: which branch the operator is on, whether the AUQ should run `/document-release` inline now, and what to do after the operator picks option A (auto-commit the touched doc files, required to keep the next-step Step 1.9 isolation gate from halting on a dirty working tree).

**Branch-aware A/B ordering:**

- **On `main`** — option A is "run `/document-release` inline now." Option A is correct because the operator's checkout is on main; `/document-release` runs against the right branch state.
- **On a feature branch** — option B is presented first (snooze / skip / defer). Option A on a feature branch would run `/document-release` against the wrong branch state, so the prose deliberately reorders.

The branch detection lives in the SKILL.md prose, not the script. Future skills that want a similar detection-then-AUQ shape mirror this split.

**Lifecycle subcommands** (mirror `skills-update-check`):

- `skills-doc-sync-check` (no subcommand) — default check; emits `DOC_SYNC_PENDING <path>` on hit, silent otherwise.
- `skills-doc-sync-check --snooze [hours]` — suppress for N hours (default 24); writes `snooze_until` into `~/.gstack/doc-sync-cache.json`.
- `skills-doc-sync-check --skip <head_sha>` — suppress this specific marker forever; a different `head_sha` re-fires the check.
- `skills-doc-sync-check --resolved` — delete the marker + clear snooze/skip cache; idempotent silent-success when the marker is already absent. Called by the orchestrator after a successful `/document-release` on the A path.

Together the F000028 hook layer and the F000029 pickup-AUQ layer close the doc-sync loop: hooks write markers when main advances; orchestrator preambles pick up markers and surface the AUQ; `/document-release` runs against the right state; `--resolved` cleans up the marker.

## Decision tree mirror

The active-skill routing diagram lives in [PHILOSOPHY.md ## Decision tree](PHILOSOPHY.md#decision-tree) — that is the single source of truth. This document does not duplicate the diagram. If you landed on ARCHITECTURE.md first looking for "which CJ_ skill do I call?", follow the link to PHILOSOPHY's Decision tree section; the routing prose and the "Quick rule of thumb" table both live there.

The split is intentional: PHILOSOPHY answers *which skill to call*; ARCHITECTURE answers *how the mechanism underneath works*. The workbench audit (CLAUDE.md `## /document-release workbench audit conventions`) reads PHILOSOPHY only for its new-skills check — adding a skill here without adding it to PHILOSOPHY's Decision tree would still produce a drift finding.

## Deprecation tombstones

The list of retired skills lives in [PHILOSOPHY.md ## Retired skills](PHILOSOPHY.md#retired-skills) — that is the canonical tombstone home (one paragraph per retired skill, naming what it was, when it retired, why, and what replaced it). This document does not duplicate that list; the workbench audit (CLAUDE.md `## /document-release workbench audit conventions`) reads PHILOSOPHY's `## Retired skills` subsection to suppress drift findings for legitimate post-mortem references.

**Three-shape deprecation pattern.** When a skill retires in this workbench, three paired layers move together:

1. **Catalog status** — `skills-catalog.json` flips the entry's `status` from `active` (or `experimental`) to `deprecated`. `validate.sh` enforces the closed enum (`active` / `experimental` / `deprecated`). `skills-deploy install` skips deprecated entries by default with a WARN line; `--include-deprecated` opts in for in-flight migration.

2. **Skill source relocation** — the skill's source moves from `skills/<name>/` to `deprecated/<name>/`. The catalog entry is the source of truth for the path: consumer scripts derive `dirname(files[0])` for the source root, and an optional `templates_source` field handles templates that relocate alongside. Functional alias shims (e.g., the F000027 `/CJ_goal_run` and `/CJ_goal_auto` shims) are a documented exception — they stay in `skills/` because they must remain invocable until the v6.0.0 removal.

3. **Work-item history relocation** — work items whose primary subject is the retired skill move from `work-items/<domain>/` to `deprecated/work-items/<domain>/`. Future archaeology stays discoverable but doesn't pollute the active work-item view.

**Original instances.** F000005 (PR #52, "deprecated skill status + company-workflow migration") introduced the catalog `status: deprecated` layer; F000006 (PR #53) relocated the skill source out of `skills/`; F000007 (PR #54) relocated the matching work-item history. Together they established the three-shape pattern as a coherent deprecation convention rather than three ad-hoc moves.

**Recent instance.** F000027/S000060 (PR #173 / v5.0.6) applied a *modified* form of the pattern to `/CJ_goal_run` and `/CJ_goal_auto`: catalog flipped to `deprecated`, but the skill source stayed in `skills/` (the functional-alias-shim exception above) so in-flight pipelines could finish under `--include-deprecated`. The sunset target is v6.0.0; at removal the source will relocate to `deprecated/` per the standard pattern.
