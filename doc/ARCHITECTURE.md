# Architecture

Mechanism reference for the workbench's load-bearing layers. Pair with [PHILOSOPHY.md](PHILOSOPHY.md) — that doc explains *why* this workbench exists and which CJ_ skill to call; this doc explains *how* the mechanisms underneath those skills work. Most layers below are Claude-side; the final section documents the parallel **GitHub Copilot** delivery surface (`work-copilot/`).

## The shared cj-goal-common.sh helper (S000057)

`scripts/cj-goal-common.sh` is the deterministic helper consumed by the two intent-named front doors (`/CJ_goal_feature` and `/CJ_goal_defect`). It absorbs the phases that don't need per-skill prose: worktree management, PR-check polling, and telemetry writes.

**Phases it owns:**

- **worktree** — auto-creates `.claude/worktrees/cj-{feat|defect}-<ts>-<pid>/` when invoked from `main` with arguments, no-ops inside an existing Conductor-managed worktree, and exposes `--assert-isolated` so each orchestrator's Step 1.9 isolation gate can refuse to proceed on a dirty working tree.
- **pr-check** — polls `gh pr view` for the merge state of an open PR, captures the PR URL into the per-branch state file, and produces a deterministic `next_action=` / `resume_cmd=` / `pr_url=` line that the orchestrator can drop directly into its journal entry.
- **telemetry** — appends a single JSONL line per run to `~/.gstack/analytics/<skill>.jsonl` (one file per front door: `CJ_goal_feature.jsonl`, `CJ_goal_defect.jsonl`).

**Modes it dispatches on:**

- **feature** — paired with `/CJ_goal_feature` (build a feature: topic → reviewable PR). Stops at the PR; deploy is a separate human step.
- **defect** — paired with `/CJ_goal_defect` (fix a bug: description → shipped fix). Runs `/investigate` as a depth-≤2 leaf subagent and only mints a D-ID after the Iron-Law gate passes.

**Consumers:**

- `/CJ_goal_feature` (mode=feature) — primary consumer; pulls every phase from the helper.
- `/CJ_goal_defect` (mode=defect) — primary consumer; same phase surface.

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

## F000036 inline doc-sync wrapper (`/CJ_document-release` Step 5.5)

F000036 closes the orchestrator-driven half of the doc-sync loop. F000028+F000029 surface doc-sync as a marker-AUQ on the NEXT session after main moves, which is correct for non-orchestrator paths (raw `git push`, manual `/ship`) but leaves a one-PR drift window for the cj_goal pipelines: by the time the marker fires, the code PR has already opened with stale docs. F000036 folds the doc update into the same PR by invoking the wrapper inline at a new pipeline Step 5.5, between the QA pass and `/ship`.

**The wrapper, not the upstream skill.** `/CJ_document-release` is a workbench skill that wraps upstream gstack `/document-release` (invoked via the Skill tool). It adds three workbench-specific behaviors that aren't expressible in the upstream skill or in F000029's detection-only script:

- **`--docs <comma-list>` subset filter** — per-invocation doc subset selection (e.g. `--docs README,CHANGELOG`), best-effort via a project-context block. The genuinely new capability that earns the catalog cost.
- **Halt-on-red contract** — upstream non-green result emits `[doc-sync-red]` to the orchestrator's halt taxonomy, so the orchestrator can stop the pipeline instead of barreling into `/ship` with broken docs.
- **Doc-only auto-commit whitelist** — gated by the conservative regex `README|CHANGELOG|CLAUDE|ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`. Non-whitelist writes HALT with `[doc-sync-non-doc-write]` — the wrapper refuses to absorb code edits into a "docs" commit.

**Pipeline insertion point.** Each of the three cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) has a Step 5.5 between the QA-pass gate and `/ship`. The wrapper runs inline, the halt classes feed into the orchestrator's existing halt taxonomy, and the auto-commit lands as a separate `docs:` commit ahead of the code PR push. F000029's marker-AUQ stays as fallback for non-orchestrator paths — when a code PR ships without going through the cj_goal pipeline, the marker still fires on the next session.

**Why a new skill, not just upstream skill prose.** F000029 BD#1 considered exactly this question and rejected it ("new /CJ_doc_sync skill in catalog" was rejected) on the grounds that the F000029 marker-AUQ flow covered all real needs. F000036 reopened that decision and superseded it: the `--docs` parameterization, the halt-on-red contract, and the auto-commit whitelist are all wrapper behaviors that the upstream skill doesn't own and the detection-only script can't carry. Supersession is annotated in-place in `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` so future readers see why the reversal happened.

**Idempotent re-run with `/ship` Step 18.** `/ship`'s existing Step 18 also dispatches `/document-release` post-push. Under squash-merges, the Step 5.5 inline call and the Step 18 post-push call are partially redundant for the auto-trigger use case (Step 18 has nothing fresh to do after Step 5.5 already absorbed doc updates), but the re-run is idempotent and harmless. The operator-callable `/-command` surface (`/CJ_document-release --docs <subset>`) is what F000036 is really for — point-in-time doc audits on a feature branch outside the cj_goal pipeline.

## F000037 strict-required `cj-document-release.json` per-repo config

F000037 externalizes the F000036 hardcoded doc whitelist + `--docs <token>` map to a per-repo JSON file at the repo root, with a strict-required posture: the wrapper HALTs before any audit runs when the config is missing or invalid. F000036's hardcoded list is now seed-only — every adopting repo declares its own doc surface.

**Config file (`cj-document-release.json` at repo root):**

- `schema_version` — integer, currently `1`. Future v2 bumps add migration steps; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported).
- `whitelist_patterns` — array of globs (e.g. `["README.md", "doc/**/*.md", "templates/doc-*.md"]`). Used by Step 2 (clean-tree gate) and Step 6 (auto-commit gate). `**` recursion is bash-globstar via `find` (macOS bash 3.2 lacks `shopt -s globstar`); the helper isolates the quirks.
- `categories` — map of `{token: [glob, ...]}`. The `--docs <token>` flag resolves against this map, NOT against a hardcoded list. A Rails app can map `--docs models` → `app/models/**/*.rb`; a Python lib can map `--docs sphinx` → `docs/source/**/*.rst`. This is the genuinely new capability F000037 adds over F000036.

**Helper script (`scripts/cj-document-release-config.sh`):** Mirrors F000029's `skills-doc-sync-check` shape (one bash file, subcommands, isolated test surface). Subcommands:

- `--parse` — pretty-print the JSON for debug/inspection.
- `--validate` — exit 0 if schema is OK; exit 1 + emit `[doc-sync-no-config] <reason>` otherwise. The `/CJ_document-release` skill calls this at Step 0.5.
- `--expand-whitelist` — emit the expanded file list (globs resolved against the working tree; sorted, unique). Step 2 (clean-tree gate) and Step 6 (auto-commit gate) both consume this.
- `--resolve <token>` — emit the file list for one `--docs` category. Unknown tokens exit 1 with `[doc-sync-no-config]`; the wrapper passes that through (no warn-and-skip fallback for unknown tokens).

**Strict-required vs F000036 backward-compat fallback.** F000037 deliberately rejected the "fallback to F000036's hardcoded defaults when JSON is missing" option. The strict posture (Big Decision #2 in `F000037_DESIGN.md`) trades a one-time authoring cost on adoption for a compounding clarity win: every repo's doc surface is declared up front, not implicit. Bundled-in-same-PR with the workbench's own seed JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON.

**Validator (`validate.sh` Check 16):** Enforces the JSON schema when `cj-document-release.json` exists at repo root. PASS lines emit `cj-document-release.json schema_version=1`. The check is one-way: it does not require the file to exist (a repo that doesn't use `/CJ_document-release` won't ship the file), but if present the schema must validate.

**New halt class `[doc-sync-no-config]`.** Added to all 3 cj_goal SKILL.md halt-taxonomy tables (between F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]`). Three orthogonal failure modes now live on the doc-sync surface: config-missing/invalid (F000037), audit-failed (F000036), upstream-misbehaved (F000036) — each has its own halt class for diagnostic clarity in the journal.

**Separation from F000034's tracked-doc/ manifest.** F000034's manifest in CLAUDE.md declares `audit_class` per `doc/*.md` file (closed enum: `skill-routing-drift` / `skill-catalog-completeness` / `static-reference` / `auto-generated`). F000037's JSON declares the doc-sync whitelist + categories (open set, machine-parseable, schema-versionable). Different concerns, separate surfaces — the design deliberately resisted "consolidate into one file" because the shapes don't align. The CLAUDE.md `## cj-document-release.json convention (F000037)` section is the operator-facing reference; this section is the mechanism-reference companion.

**Portability stays `workbench` in v1.** F000037 is the enabler for future portability (downstream repos can now declare their own doc surface), but the actual flip to `standalone` requires at least one downstream repo successfully consuming the JSON first.

## The work-copilot Copilot bundle (parallel delivery surface)

Everything above is Claude-side plumbing. `work-copilot/` is the workbench's *other* delivery surface: a self-contained **GitHub Copilot** bundle that carries the doc-first work-item contract to machines without Claude Code. It is NOT a Claude skill — no `SKILL.md`, no `USAGE.md`, no entry in `skills-catalog.json` — and it is not `/`-invoked. It is driven by a Python CLI and consumed by Copilot's own prompt surface.

**What it carries (canonical source, no upstream sync):**

- `work-copilot/templates/` — the work-item templates (`tracker-*`, `doc-*`), mirroring the `CJ_personal-workflow` set.
- `work-copilot/WORKFLOW.md` + `work-copilot/copilot-artifact-manifests.json` — the structural rules + artifact manifest (the Copilot-side analogue of `personal-artifact-manifests.json`).
- `work-copilot/prompts/` — the Copilot slash-command surface: `/wc-investigate`, `/wc-scaffold`, `/wc-implement`, `/wc-qa`, `/wc-ship`, `/wc-pipeline`, and `/validate`.
- `work-copilot/reference/`, `philosophy/`, `examples/`, `fixtures/`, `domain/` skeletons, and `instructions/copilot-instructions.md` — ambient guidance + worked examples + validation fixtures.

**Deploy mechanism — `scripts/copilot-deploy.py`:**

- `find_bundle_dir()` resolves the bundle at `<repo-root>/work-copilot/` (the script directory's parent), so the bundle lives at the repo root **by design** — not under `skills/`, which is reserved for Claude skills.
- `python3 scripts/copilot-deploy.py install <target>` copies the bundle into the target repo under `.github/` (e.g. `.github/work-copilot/`) and installs the Copilot instructions file; `doctor` and `remove` use the same CLI.
- It is one-way distribution: the workbench is the source of truth, target repos receive a copy.

**Bundle integrity — `scripts/validate.sh` Error check 10:**

- The `EXPECTED_BUNDLE_FILES` array (currently 61 entries) lists every required bundle file; the check ERRORs if any is missing. `scripts/test.sh` adds a size budget on `copilot-instructions.md` and an install round-trip test.
- **To add a bundle file:** create it under `work-copilot/<subdir>/` and append one entry to `EXPECTED_BUNDLE_FILES`. That single array is the registration point.

**Relationship to the Claude side.** Same doc-first *contract* (templates + validation + ambient conventions), different runtime. The `CJ_` orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, …) do NOT port — they are Claude-only. What ports is the structure a contributor scaffolds against and the `/validate` pass that checks it. See [PHILOSOPHY.md → Two delivery surfaces, one contract](PHILOSOPHY.md#two-delivery-surfaces-one-contract) for the why, and [doc/SKILL-CATALOG.md → work-copilot](SKILL-CATALOG.md#work-copilot) for the operator-facing catalog entry.

## Decision tree mirror

The active-skill routing diagram lives in [PHILOSOPHY.md ## Decision tree](PHILOSOPHY.md#decision-tree) — that is the single source of truth. This document does not duplicate the diagram. If you landed on ARCHITECTURE.md first looking for "which CJ_ skill do I call?", follow the link to PHILOSOPHY's Decision tree section; the routing prose and the "Quick rule of thumb" table both live there.

The split is intentional: PHILOSOPHY answers *which skill to call*; ARCHITECTURE answers *how the mechanism underneath works*. The workbench audit (CLAUDE.md `## /document-release workbench audit conventions`) reads PHILOSOPHY only for its new-skills check — adding a skill here without adding it to PHILOSOPHY's Decision tree would still produce a drift finding.
