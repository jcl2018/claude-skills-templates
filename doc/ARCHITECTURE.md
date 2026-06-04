# Architecture

Mechanism reference for the workbench's load-bearing layers. Pair with [PHILOSOPHY.md](PHILOSOPHY.md) — that doc explains *why* this workbench exists and which CJ_ skill to call; this doc explains *how* the mechanisms underneath those skills work. Most layers below are Claude-side; the final section documents the parallel **GitHub Copilot** delivery surface (`work-copilot/`).

## The shared cj-goal-common.sh helper (S000057)

`scripts/cj-goal-common.sh` is the deterministic helper consumed by the two intent-named front doors (`/CJ_goal_feature` and `/CJ_goal_defect`). It absorbs the phases that don't need per-skill prose: worktree management, PR-check polling, telemetry writes, and post-run worktree cleanup.

**Phases it owns:**

- **worktree** — auto-creates `.claude/worktrees/cj-{feat|defect}-<ts>-<pid>/` when invoked from `main` with arguments, no-ops inside an existing Conductor-managed worktree, and exposes `--assert-isolated` so each orchestrator's Step 1.9 isolation gate can refuse to proceed on a dirty working tree. **Base-freshness (F000045 / Fork 1):** inside `cj-worktree-init.sh`, just before `git worktree add`, when on `main`/`master` with an existing `origin/<branch>` ref, the helper fail-soft fetches + fast-forwards local `main` to the origin tip so the new worktree branches off current trunk. Outcome rides the `note` field of the `created` emit (`ff'd N commits` / `local main diverged from origin; building on local main` / `freshness skipped (offline)`); never halts; skipped under `--dry-run`.
- **sync** — pre-build skills-sync (F000045 / Fork 2). Delegates to `post-land-sync.sh`'s guarded pull+install-from-`.source` core so installed skills match trunk at build start (without the worktree-invoked-install foreign-owned-skill skip). The orchestrator runs `--phase sync` BEFORE the worktree block. Fail-soft exactly like `pr-check`: a guard refusal (`.source` off-main / dirty tracked tree) or an offline pull emits `PHASE_RESULT=skipped` (exit 0), never failed. `--no-sync` short-circuits to `skipped` before any install (Fork-1's ff still runs); `--dry-run` forwards to `post-land-sync.sh --dry-run`.
- **pr-check** — polls `gh pr view` for the merge state of an open PR, captures the PR URL into the per-branch state file, and produces a deterministic `next_action=` / `resume_cmd=` / `pr_url=` line that the orchestrator can drop directly into its journal entry.
- **telemetry** — appends a single JSONL line per run to `~/.gstack/analytics/<skill>.jsonl` (one file per front door: `CJ_goal_feature.jsonl`, `CJ_goal_defect.jsonl`).
- **cleanup** (T000036) — at each orchestrator's post-land terminal, sweeps *landed* `cj-(feat|def|todo)-*` worktrees (removed only when their PR reads MERGED/CLOSED via the `pr-check` phase — not by branch ancestry, which a squash merge breaks), runs `git worktree prune`, and switches the root checkout back to `main` and pulls it. Strictly best-effort — it never halts the run. Delegates to the teardown-mirror helper `scripts/cj-worktree-cleanup.sh`; `/CJ_goal_todo_fix` calls that helper directly rather than through this phase.

**Modes it dispatches on:**

- **feature** — paired with `/CJ_goal_feature` (build a feature: topic → reviewable PR). Stops at the PR; deploy is a separate human step.
- **defect** — paired with `/CJ_goal_defect` (fix a bug: description → shipped fix). Runs `/investigate` as a depth-≤2 leaf subagent and only mints a D-ID after the Iron-Law gate passes.

**Consumers:**

- `/CJ_goal_feature` (mode=feature) — primary consumer; pulls every phase from the helper.
- `/CJ_goal_defect` (mode=defect) — primary consumer; same phase surface.

The helper is deliberately one shell file, not a directory or a skill. Each phase is a function the orchestrator sources and calls — there is no second layer of orchestration. Treat it as plumbing for the two front doors.

## Doc-sync (F000036 inline Step 5.5 + `/ship` Step 18)

F000028 (post-merge/post-rewrite git hooks that dropped a per-repo doc-sync marker JSON under `~/.gstack/`) and F000029 (a detection script + a marker-pickup AskUserQuestion in the `cj_goal` orchestrator preambles that consumed the marker on the next session) were **retired by F000040** once F000036 made doc-sync run inline. They are gone from the codebase; this section documents only the surviving inline mechanism. For the operator-facing accepted-gap note, see CLAUDE.md `## Doc-sync coverage`.

## F000036 inline doc-sync wrapper (`/CJ_document-release` Step 5.5)

F000036 folds the doc update into the same PR as the code by invoking the `/CJ_document-release` wrapper inline at pipeline Step 5.5, between the QA pass and `/ship`. Earlier the only doc-sync surface was a post-merge marker picked up on the NEXT session, which left a one-PR drift window for the cj_goal pipelines: by the time the marker fired, the code PR had already opened with stale docs. Step 5.5 closes that window — the doc update ships in the same PR.

**The wrapper, not the upstream skill.** `/CJ_document-release` is a workbench skill that wraps upstream gstack `/document-release` (invoked via the Skill tool). It adds three workbench-specific behaviors that aren't expressible in the upstream skill:

- **`--docs <comma-list>` subset filter** — per-invocation doc subset selection (e.g. `--docs README,CHANGELOG`), best-effort via a project-context block. The genuinely new capability that earns the catalog cost.
- **Halt-on-red contract** — upstream non-green result emits `[doc-sync-red]` to the orchestrator's halt taxonomy, so the orchestrator can stop the pipeline instead of barreling into `/ship` with broken docs.
- **Doc-only auto-commit whitelist** — gated by the conservative regex `README|CHANGELOG|CLAUDE|ARCHITECTURE.md` + `doc/.+\.md` + `templates/doc-.*\.md`. Non-whitelist writes HALT with `[doc-sync-non-doc-write]` — the wrapper refuses to absorb code edits into a "docs" commit.

**Pipeline insertion point.** Each of the three cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) has a Step 5.5 between the QA-pass gate and `/ship`. The wrapper runs inline, the halt classes feed into the orchestrator's existing halt taxonomy, and the auto-commit lands as a separate `docs:` commit ahead of the code PR push. Non-orchestrator paths are covered by `/ship` Step 18 (which dispatches `/document-release` on every invocation); the only uncovered path is a main-move that bypasses both the orchestrators and `/ship`, recovered manually (see CLAUDE.md `## Doc-sync coverage`).

**Why a new skill, not just upstream skill prose.** The retired F000029 design (BD#1) considered exactly this question and rejected a new doc-sync skill on the grounds that its (now-retired) preamble flow covered all real needs. F000036 reopened that decision and superseded it: the `--docs` parameterization, the halt-on-red contract, and the auto-commit whitelist are all wrapper behaviors that the upstream skill doesn't own and a detection-only script can't carry. Supersession is annotated in-place in `work-items/features/ops/F000029_marker_pickup_auq/F000029_DESIGN.md` so future readers see why the reversal happened.

**Idempotent re-run with `/ship` Step 18.** `/ship`'s existing Step 18 also dispatches `/document-release` post-push. Under squash-merges, the Step 5.5 inline call and the Step 18 post-push call are partially redundant for the auto-trigger use case (Step 18 has nothing fresh to do after Step 5.5 already absorbed doc updates), but the re-run is idempotent and harmless. The operator-callable `/-command` surface (`/CJ_document-release --docs <subset>`) is what F000036 is really for — point-in-time doc audits on a feature branch outside the cj_goal pipeline.

## F000037 strict-required `cj-document-release.json` per-repo config

F000037 externalizes the F000036 hardcoded doc whitelist + `--docs <token>` map to a per-repo JSON file at the repo root, with a strict-required posture: the wrapper HALTs before any audit runs when the config is missing or invalid. F000036's hardcoded list is now seed-only — every adopting repo declares its own doc surface.

**Config file (`cj-document-release.json` at repo root):**

- `schema_version` — integer, currently `1`. Future v2 bumps add migration steps; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported).
- `whitelist_patterns` — array of globs (e.g. `["README.md", "doc/**/*.md", "templates/doc-*.md"]`). Used by Step 2 (clean-tree gate) and Step 6 (auto-commit gate). `**` recursion is bash-globstar via `find` (macOS bash 3.2 lacks `shopt -s globstar`); the helper isolates the quirks.
- `categories` — map of `{token: [glob, ...]}`. The `--docs <token>` flag resolves against this map, NOT against a hardcoded list. A Rails app can map `--docs models` → `app/models/**/*.rb`; a Python lib can map `--docs sphinx` → `docs/source/**/*.rst`. This is the genuinely new capability F000037 adds over F000036.

**Helper script (`scripts/cj-document-release-config.sh`):** Follows the workbench's single-bash-file helper shape (one bash file, subcommands, isolated test surface — the same shape as `skills-update-check`). Subcommands:

- `--parse` — pretty-print the JSON for debug/inspection.
- `--validate` — exit 0 if schema is OK; exit 1 + emit `[doc-sync-no-config] <reason>` otherwise. The `/CJ_document-release` skill calls this at Step 0.5.
- `--expand-whitelist` — emit the expanded file list (globs resolved against the working tree; sorted, unique). Step 2 (clean-tree gate) and Step 6 (auto-commit gate) both consume this.
- `--resolve <token>` — emit the file list for one `--docs` category. Unknown tokens exit 1 with `[doc-sync-no-config]`; the wrapper passes that through (no warn-and-skip fallback for unknown tokens).

**Strict-required vs F000036 backward-compat fallback.** F000037 deliberately rejected the "fallback to F000036's hardcoded defaults when JSON is missing" option. The strict posture (Big Decision #2 in `F000037_DESIGN.md`) trades a one-time authoring cost on adoption for a compounding clarity win: every repo's doc surface is declared up front, not implicit. Bundled-in-same-PR with the workbench's own seed JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON.

**Validator (`validate.sh` Check 16):** Enforces the JSON schema when `cj-document-release.json` exists at repo root. PASS lines emit `cj-document-release.json schema_version=1`. The check is one-way: it does not require the file to exist (a repo that doesn't use `/CJ_document-release` won't ship the file), but if present the schema must validate.

**New halt class `[doc-sync-no-config]`.** Added to all 3 cj_goal SKILL.md halt-taxonomy tables (between F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]`). Three orthogonal failure modes now live on the doc-sync surface: config-missing/invalid (F000037), audit-failed (F000036), upstream-misbehaved (F000036) — each has its own halt class for diagnostic clarity in the journal.

**Separation from F000034's tracked-doc/ manifest.** F000034's manifest in CLAUDE.md declares `audit_class` per `doc/*.md` file (closed enum: `skill-routing-drift` / `workflow-completeness` / `static-reference` / `auto-generated`). F000037's JSON declares the doc-sync whitelist + categories (open set, machine-parseable, schema-versionable). Different concerns, separate surfaces — the design deliberately resisted "consolidate into one file" because the shapes don't align. The CLAUDE.md `## cj-document-release.json convention (F000037)` section is the operator-facing reference; this section is the mechanism-reference companion.

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

**Relationship to the Claude side.** Same doc-first *contract* (templates + validation + ambient conventions), different runtime. The `CJ_` orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, …) do NOT port — they are Claude-only. What ports is the structure a contributor scaffolds against and the `/validate` pass that checks it. See [PHILOSOPHY.md → Two delivery surfaces, one contract](PHILOSOPHY.md#two-delivery-surfaces-one-contract) for the why, and the [work-copilot Copilot bundle section above](#the-work-copilot-copilot-bundle-parallel-delivery-surface) for the deploy mechanism + bundle-integrity check.

## Component skills (non-workflow roster)

The three `cj_goal` workflows in [doc/WORKFLOWS.md](WORKFLOWS.md) dispatch a set of single-purpose **component skills** and lean on a few standalone validators/utilities. Those skills don't get their own workflow chart — they are the building blocks a workflow composes, or a one-shot tool the operator runs directly. This roster is the per-skill reference for them: name + one-line role + Source link. (Every skill below is also enforced in [PHILOSOPHY.md ## Decision tree](PHILOSOPHY.md#decision-tree) by the workbench's New-skills check, which is the no-vanish safety net — see `## Decision tree mirror` below. This roster is documentation, not Check-enforced.)

**Phase-step skills** (dispatched by the orchestrators as depth-≤2 leaf subagents):

- **CJ_scaffold-work-item** — distills an APPROVED `/office-hours` design doc into a compliant `work-items/<type>/<id>_<slug>/` tree (TRACKER + per-type artifacts + lifecycle gates); runs `/CJ_personal-workflow check` at the boundaries; idempotent. Source: `skills/CJ_scaffold-work-item/SKILL.md` · `skills/CJ_scaffold-work-item/USAGE.md`.
- **CJ_implement-from-spec** — reads the per-type spec (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks) and writes code via Read/Edit/Write; propose-and-confirm by default with a sensitive-surface AUQ, `--auto` for trivial ≤2-file changes; idempotent. Source: `skills/CJ_implement-from-spec/SKILL.md` · `skills/CJ_implement-from-spec/USAGE.md`.
- **CJ_qa-work-item** — runs every test-plan / TEST-SPEC row in the work-item (user-stories get smoke + a fresh-context E2E subagent per row; defects/tasks run rows smoke-equivalent), writes findings to the tracker journal, transitions Phase 2 QA-owned gates; refuses on incomplete Phase 2; idempotent. Source: `skills/CJ_qa-work-item/SKILL.md` · `skills/CJ_qa-work-item/USAGE.md`.
- **CJ_document-release** — workbench wrapper around upstream `/document-release`; adds a `--docs <subset>` filter, a halt-on-red contract (`[doc-sync-red]`), and a doc-only auto-commit gated by the per-repo `cj-document-release.json` whitelist; invoked inline at Step 5.5 of all three orchestrators. (Mechanism detail: `## F000036 inline doc-sync wrapper` + `## F000037 strict-required cj-document-release.json` above.) Source: `skills/CJ_document-release/SKILL.md` · `skills/CJ_document-release/USAGE.md`.

**Validator** (depended on by every phase-step + orchestrator, run transitively at boundaries):

- **CJ_personal-workflow** — validates work-item directories + tracker files against the personal templates and `personal-artifact-manifests.json`; templates + WORKFLOW.md are the single source of truth for structural rules. Source: `skills/CJ_personal-workflow/SKILL.md` · `skills/CJ_personal-workflow/USAGE.md`.

**Standalone utilities** (operator-invoked directly; not part of a chain):

- **CJ_system-health** — read-only `~/.claude/` health dashboard: scans installed skills, builds a dependency graph, checks filesystem health, surfaces usage analytics with a behavioral-topology overlay, optionally invokes waza; produces a scored report with trend tracking. Source: `skills/CJ_system-health/SKILL.md` · `skills/CJ_system-health/USAGE.md`.
- **CJ_suggest** — prints a ranked top-5 (or `--limit N`) of next-up work items from TODOS.md + tracker frontmatter; internal phase-step rows filtered by default (`--include-internal` surfaces them); `--for-skill` / `--limit` pre-filter for downstream callers like `/CJ_goal_todo_fix`. Source: `skills/CJ_suggest/SKILL.md` · `skills/CJ_suggest/USAGE.md`.
- **CJ_improve-queue** — workbench self-improvement skill with three modes: `evaluate <url>` (fetch + classify a Claude best-practice article → draft TODOS row if novel), `audit` (offline repo self-scan), `research <topic>` (WebSearch + per-result evaluate with a privacy gate); all rows land with `<!--impr-draft-->` markers. Source: `skills/CJ_improve-queue/SKILL.md` · `skills/CJ_improve-queue/USAGE.md`.
- **CJ_repo-init** — detects which CJ_ skills are deployed, verifies each one's per-repo prerequisites (`cj-document-release.json`, `TODOS.md`, `work-items/` tree), prints a health table, and on one confirm scaffolds the missing prerequisites from generic portable seeds; in-place, no worktree/ship; idempotent. Source: `skills/CJ_repo-init/SKILL.md` · `skills/CJ_repo-init/USAGE.md`.

(The `work-copilot/` Copilot bundle is NOT a Claude skill — it is the parallel delivery surface documented in `## The work-copilot Copilot bundle (parallel delivery surface)` above, not in this roster.)

## Decision tree mirror

The active-skill routing diagram lives in [PHILOSOPHY.md ## Decision tree](PHILOSOPHY.md#decision-tree) — that is the single source of truth. This document does not duplicate the diagram. If you landed on ARCHITECTURE.md first looking for "which CJ_ skill do I call?", follow the link to PHILOSOPHY's Decision tree section; the routing prose and the "Quick rule of thumb" table both live there.

The split is intentional: PHILOSOPHY answers *which skill to call*; ARCHITECTURE answers *how the mechanism underneath works*. The workbench audit (CLAUDE.md `## /document-release workbench audit conventions`) reads PHILOSOPHY only for its new-skills check — adding a skill here without adding it to PHILOSOPHY's Decision tree would still produce a drift finding.
