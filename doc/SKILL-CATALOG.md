# Skill Catalog

Consolidated index of every routable non-deprecated skill in this workbench, plus the non-skill companion surfaces (the Copilot bundle) that the operator manages alongside skills. Each section gives status, source paths, an "Invoke when" trigger, and either a fenced ASCII workflow chart (orchestrators + phase-step chain) or a tag line (single-step skills + companion surfaces) — a companion surface with a real multi-step workflow (e.g. work-copilot) carries both a chart and its tag — so a reader can see the shape of every surface at a glance without opening its SKILL.md (or README.md, for companion surfaces). Sections are hand-written and audited by `scripts/validate.sh` Check 15 — every routable non-deprecated skill in `skills-catalog.json` must have a section, and every section must have either a chart or a closed-enum tag (no silent omission). Companion-surface sections are NOT enforced by Check 15 (the check is one-way: catalog → catalog file), so they are conventionally — but not mechanically — kept in sync. For the routing decision tree (which skill to pick for a given intent), see [`doc/PHILOSOPHY.md`](PHILOSOPHY.md). For per-skill operator + agent best-practice, see each skill's `USAGE.md`.

## Orchestrators

The four orchestrators chain multiple skills end-to-end. Each has a mandatory ASCII workflow chart.

### CJ_goal_feature

**Status:** experimental (the F000027 `feature` verb; production front door for "build a feature end-to-end" but the chain is still being tuned)
**Source:** `skills/CJ_goal_feature/SKILL.md` · `skills/CJ_goal_feature/USAGE.md`

**Invoke when:** the operator has a one-line feature topic and wants a reviewable PR. Common phrasings: "build a feature", "one-line idea to a reviewable PR", "topic to PR". Stops at the PR — `/land-and-deploy` is a separate human step.

**Workflow:**

```
"<topic>"
   │  cj-goal-common.sh --phase worktree --mode feature  (auto cj-feat-* worktree)
   ▼
/office-hours   [INLINE — interactive; emits APPROVED design doc]
   │   ↳ not APPROVED / abandoned → HALT (halted_at_officehours)
   ▼
capture doc path → resume state file (last_completed_phase + HEAD SHA + PR#)
   │
   ▼
design-summary approval gate   [INLINE AUQ — go/no-go]
   │   ↳ Abort → HALT (halted_at_design_gate)
   ▼  Approve & build →  SILENT depth-≤2 leaf Agent subagents
/CJ_scaffold-work-item → /CJ_implement-from-spec → /CJ_qa-work-item
   │
   ▼
/CJ_document-release   [INLINE Step 5.5 — doc-sync folds doc edits into the PR; halt-on-red]
   │
   ▼
/ship   [INLINE — diff-review AUQ suppressed; opens PR]
   │
   ▼
STOP at PR   (human reviews + merges; /land-and-deploy is SEPARATE)
   │
   ▼
telemetry → ~/.gstack/analytics/CJ_goal_feature.jsonl
```

### CJ_goal_defect

**Status:** experimental (the F000027 `defect` verb; ~80% reshape of /CJ_goal_investigate v1.1, still being hardened)
**Source:** `skills/CJ_goal_defect/SKILL.md` · `skills/CJ_goal_defect/USAGE.md`

**Invoke when:** the operator has a plain bug description with no pre-existing defect dir and wants a deployed fix. Common phrasings: "fix this bug end-to-end", "bug report to deployed fix", "root-cause and ship a fix". Differs from `/CJ_goal_feature` in that it auto-deploys after `/ship` — defects are time-sensitive.

**Workflow:**

```
"<bug description>"
   │  cj-goal-common.sh --phase worktree --mode defect  (auto cj-def-* worktree)
   ▼
scaffold .inbox/<slug>/DRAFT.md   (no D-ID yet; idempotent)
   │
   ▼  Agent: /investigate dispatch (sentinel-wrapped JSON)
   │        Iron-Law gate: no root cause ⇒ HALT, nothing promoted
   │
   ▼  parse FIX_PLAN (halt if >5 files) + DEBUG_REPORT (halt taxonomy)
   │
   ▼  PROMOTE: .inbox/<slug>/ → work-items/defects/uncategorized/D000NNN_<slug>/
   │        (D-ID minted ONLY after Iron-Law passes)
   │
   ▼  write RCA.md + test-plan.md → /CJ_qa-work-item (leaf subagent)
   │
   ▼  /CJ_document-release                   (Step 5.5 doc-sync; halt-on-red)
   │
   ▼  /ship                                  (Gate #2 fires; halt on [ship-declined])
   │
   ▼  /land-and-deploy --suppress-readiness-gate
   │
   ▼  telemetry → ~/.gstack/analytics/CJ_goal_defect.jsonl
```

### CJ_goal_todo_fix

**Status:** active (the TODO drainer; production front door for "fix this TODO" and the cron-eligible `--quiet` mode powers /schedule integrations)
**Source:** `skills/CJ_goal_todo_fix/SKILL.md` · `skills/CJ_goal_todo_fix/USAGE.md`

**Invoke when:** the operator wants to drain TODOS.md backlog rows into PRs. Default no-args drains up to 10 easy-fix TODOs; single-TODO mode (T-ID or fragment) fixes exactly one. Common phrasings: "fix this TODO", "clear the TODO backlog", "drain TODOs", "auto-resolve TODOs". `/ship` Gate #2 still fires per drained TODO (the autonomy ceiling).

**Workflow:**

```
TODOS.md row → /CJ_goal_todo_fix preflight
   │  (drain mode: enumerate via /CJ_suggest --for-skill cj-goal --limit 2*max)
   │  (single mode: exact T-ID or fragment match)
   ▼
T-task scaffold (TRACKER + test-plan)
   │
   ▼
/CJ_personal-pipeline
   │  scaffold → implement → qa (depth-≤2 leaf subagents)
   ▼
/CJ_document-release   (Step 5.5 doc-sync; halt-on-red)
   │
   ▼
/ship   (Gate #2 fires per drained TODO — human approves diff)
   │
   ▼
/land-and-deploy   (auto-merge + verify production)
   │
   ▼
TODOS.md DONE-mark (hash-verified row update)
   │
   ▼
telemetry → ~/.gstack/analytics/CJ_goal_todo_fix.jsonl
```

### CJ_personal-pipeline

**Status:** active (internal scaffold→impl→qa engine; depended on by /CJ_goal_todo_fix + /CJ_goal_feature)
**Source:** `skills/CJ_personal-pipeline/SKILL.md` · `skills/CJ_personal-pipeline/USAGE.md`

**Invoke when:** an orchestrator (`/CJ_goal_todo_fix` or another) needs to drive scaffold → implement → QA on a design doc or already-scaffolded work-item dir. NOT typically called directly by the operator — it's the internal phase-2-to-4 loop engine. Common phrasings (from inside orchestrators): "run the pipeline", "drive scaffold/impl/qa".

**Workflow:**

```
<design-doc-path>  OR  --work-item-dir <path>
   │
   ▼
Pre-scaffold idempotency check (footer routing: 4 branches)
   │
   ▼  Phase 1 — Agent subagent: /CJ_scaffold-work-item
   │        Returns: RESULT: WORK_ITEM_DIR=<path>
   │
   ▼  Post-scaffold gate: /CJ_personal-workflow check + AUQ confirm shape
   │
   ▼  Phase 2 — Agent subagent: /CJ_implement-from-spec
   │        (pre-collected AUQs threaded in; subagent auto-equivalent)
   │        Returns: RESULT: STATUS=...; FILES_CHANGED=<n>
   │
   ▼  Post-implement gate: /CJ_personal-workflow check + validate.sh
   │
   ▼  Phase 3 — Agent subagent: /CJ_qa-work-item
   │        Returns: RESULT: SMOKE=...; E2E=...; PHASE2_GATES=...
   │
   ▼  Post-QA gate: parse tracker journal for [smoke-pass]/[qa-pass]; halt on red
   │
   ▼  telemetry → ~/.gstack/analytics/CJ_CJ_personal-pipeline.jsonl
```

## Phase-step skills

Called transitively by orchestrators (depth-2 leaf subagents). Their "chart" is one rectangle, so they tag instead.

### CJ_scaffold-work-item

**Status:** active (phase-1 building block; called by /CJ_personal-pipeline and /CJ_goal_feature)
**Source:** `skills/CJ_scaffold-work-item/SKILL.md` · `skills/CJ_scaffold-work-item/USAGE.md`

**Invoke when:** an /office-hours design doc exists and needs to be distilled into a `work-items/` directory tree (TRACKER + SPEC + TEST-SPEC + lifecycle gates). Usually dispatched by an orchestrator; can also be called directly when the operator has a doc but wants to stop at scaffolding.

`(phase-step in /CJ_goal_feature chain)` — Reads an APPROVED /office-hours design doc + per-type template + manifest, then writes a compliant work-item directory tree. Runs `/CJ_personal-workflow check` at the boundaries. Idempotent: re-running on the same input is a no-op.

### CJ_implement-from-spec

**Status:** active (phase-2 building block; called by /CJ_personal-pipeline and /CJ_goal_feature)
**Source:** `skills/CJ_implement-from-spec/SKILL.md` · `skills/CJ_implement-from-spec/USAGE.md`

**Invoke when:** a scaffolded work-item exists with its per-type spec on disk (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks) and code needs to be written against it. Sensitive-surface AUQ for catalog/manifest/validator edits; `--auto` for trivial ≤2-file changes.

`(phase-step in /CJ_goal_feature chain)` — Reads the per-type spec + Components Affected / Data Flow, writes code via Read/Edit/Write. Propose-and-confirm by default; sensitive surfaces trigger AUQs. Idempotent (re-running on a fully implemented work-item is a no-op).

### CJ_qa-work-item

**Status:** active (phase-3 building block; called by /CJ_personal-pipeline, /CJ_goal_feature, and /CJ_goal_defect)
**Source:** `skills/CJ_qa-work-item/SKILL.md` · `skills/CJ_qa-work-item/USAGE.md`

**Invoke when:** a scaffolded + implemented work-item is in Phase 2 and needs its test-plan rows run. User-stories get smoke tests + a fresh-context E2E subagent per TEST-SPEC; defects and tasks run their test-plan rows as smoke-equivalent.

`(phase-step in /CJ_goal_feature chain)` — Runs every test-plan row in the work-item, writes findings to the tracker journal, transitions Phase 2 QA-owned gates. Refuses on incomplete Phase 2. Idempotent.

### CJ_document-release

**Status:** experimental (F000036 inline doc-sync wrapper for the cj_goal orchestrator family; F000037 strict-required per-repo config)
**Source:** `skills/CJ_document-release/SKILL.md` · `skills/CJ_document-release/USAGE.md`

**Invoke when:** auto-invoked by all 3 cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) at Step 5.5 — between QA pass and `/ship` — so doc updates fold into the same code PR. Manual invocation: `/CJ_document-release [--docs <subset>]` on a feature branch when README/CHANGELOG/CLAUDE.md drift after a code change needs to be folded into the next commit. Common phrasings: "sync docs inline", "fold doc updates into this PR". For non-orchestrator paths (raw `git push`, manual `/ship` outside the cj_goal pipeline), F000029's marker-AUQ on next-session is the right surface instead.

`(phase-step in /CJ_goal_feature chain)` — Workbench wrapper around upstream `/document-release`. Adds a `--docs <comma-list>` filter (best-effort via project-context block) that resolves tokens against the per-repo `cj-document-release.json`'s `categories` map (F000037 strict-required — unknown tokens HALT with `[doc-sync-no-config]`, not warn-and-skip), halt-on-red contract (`[doc-sync-red]` on upstream failure), and doc-only auto-commit gated by the JSON's `whitelist_patterns` globs; non-whitelist writes HALT with `[doc-sync-non-doc-write]`. Config missing/invalid/schema-unsupported HALTs with `[doc-sync-no-config]` BEFORE any audit runs. No upstream modification.

## Validators / utilities

Single-step skills with no chain. Validator or single-step-utility tag.

### CJ_personal-workflow

**Status:** active (workflow validator; depended on by every CJ_* phase-step + orchestrator)
**Source:** `skills/CJ_personal-workflow/SKILL.md` · `skills/CJ_personal-workflow/USAGE.md`

**Invoke when:** the operator wants to validate a work-item directory or TRACKER.md file against the personal templates and `personal-artifact-manifests.json`. Also runs as a pre/post-phase gate inside the orchestrators (you rarely call it directly; the orchestrators call it transitively).

`(validator)` — Validates tracker files and work-item directories against the personal templates + manifest. Templates + WORKFLOW.md are the single source of truth for structural rules; this skill enforces them.

### CJ_system-health

**Status:** active (read-only utility for ~/.claude/ inspection)
**Source:** `skills/CJ_system-health/SKILL.md` · `skills/CJ_system-health/USAGE.md`

**Invoke when:** the operator wants a scored snapshot of `~/.claude/` — dependency graph, filesystem health, usage analytics. Common phrasings: "check installed skills", "skill system health", "skills status".

`(single-step utility)` — Scans installed skills, builds a dependency graph, checks filesystem health, surfaces usage analytics with behavioral-topology overlay, and optionally invokes waza for config hygiene. Produces a scored report with trend tracking. Read-only; no mutations.

### CJ_suggest

**Status:** active (ranking utility for /CJ_goal_todo_fix + operator backlog browsing)
**Source:** `skills/CJ_suggest/SKILL.md` · `skills/CJ_suggest/USAGE.md`

**Invoke when:** the operator is unsure what to work on next, or `/CJ_goal_todo_fix` needs an enumeration of easy-fix TODOs (`--for-skill cj-goal --limit N`). Common phrasings: "what's next", "what should I work on", "suggest next work item", "top 5 work items".

`(single-step utility)` — Prints a ranked top-5 (or `--limit N`) of next-up work items from TODOS.md and tracker frontmatter. Internal phase-step skill rows are filtered by default; `--include-internal` surfaces them. `--for-skill` and `--limit` flags pre-filter for downstream callers.

### CJ_improve-queue

**Status:** experimental (URL-evaluation + offline-audit + research utility; deployed but still being tuned)
**Source:** `skills/CJ_improve-queue/SKILL.md` · `skills/CJ_improve-queue/USAGE.md`

**Invoke when:** the operator wants to evaluate a Claude best-practices URL against existing workbench skills, run an offline audit of stale skills + missing frontmatter, or research a topic with WebSearch + per-result evaluation. Common phrasings: "evaluate this URL", "is this a good Claude pattern", "should we adopt this", "audit the workbench skills".

`(single-step utility)` — Three modes: `evaluate <url>` (fetch + classify + draft TODOS.md row if novel), `audit` (offline repo self-scan), `research <topic>` (WebSearch + per-result evaluate with privacy gate). All TODOS rows land with `<!--impr-draft-->` markers; promotion is operator-gated.

### CJ_repo-init

**Status:** experimental (per-repo prerequisite verifier/scaffolder for the CJ_ skill family)
**Source:** `skills/CJ_repo-init/SKILL.md` · `skills/CJ_repo-init/USAGE.md`

**Invoke when:** the operator deployed the CJ_ skill family into a fresh clone or a new target repo and wants the per-repo config files (`cj-document-release.json`, `TODOS.md`, `work-items/` tree) verified and scaffolded before running an orchestrator. Common phrasings: "set up this repo for the CJ skills", "init repo prerequisites", "make this repo ready for CJ_", "bootstrap repo config", "verify repo prerequisites".

`(single-step utility)` — Detects which CJ_ skills are deployed (manifest → `~/.claude/skills/CJ_*` → repo-local `skills/`), maps each to its per-repo prerequisite, verifies the union (existence + `cj-document-release.json` schema validity, mirroring `validate.sh` Check 16), prints a `prereq | needed-by | status` health table + machine-readable `GAPS=<n>`, and on one confirm AUQ scaffolds the missing repo-level prereqs from generic portable seeds via `scripts/cj-repo-init.sh --fix`. Detection-in-script / AUQ-in-prose split (precedent: `skills-doc-sync-check`). In-place; no worktree/ship. Idempotent. Install-level gaps are reported only (owned by `skills-deploy install`).

## Companion surfaces (non-skill)

Workbench artifacts that aren't Claude skills (no SKILL.md, no entry in `skills-catalog.json`) but ARE operator-facing surfaces the workbench produces, distributes, or manages. Tagged `(non-skill bundle)` to visually distinguish from the Check-15-enforced closed-enum skill tags. These sections are NOT enforced by `scripts/validate.sh` Check 15 — they are by-hand entries that exist so the catalog reflects the full surface of the workbench, not just the slice of it that is Claude-skill-shaped.

### work-copilot

**Status:** active (self-contained GitHub Copilot bundle; deployed to non-Claude target repos to mirror the `CJ_personal-workflow` `/validate` workflow + ambient knowledge for Copilot users)
**Source:** `work-copilot/README.md` · `work-copilot/WORKFLOW.md` · `work-copilot/prompts/*.prompt.md` · `scripts/copilot-deploy.py`

**Invoke when:** *(workbench side)* the operator wants to install, update, doctor, or remove the Copilot bundle in a target repo (any repo whose contributors use GitHub Copilot instead of Claude Code). NOT a Claude skill — driven by the `scripts/copilot-deploy.py` CLI, not by `/`-invocation. Common phrasings: "set up Copilot in repo X", "install work-copilot", "deploy the Copilot bundle", "doctor the Copilot bundle". *(target-repo side)* once installed, a Copilot user drives the work-item lifecycle with the `/wc-*` slash commands below, from VS Code Copilot Chat.

**Workflow** *(the `/wc-*` pipeline, run in the target repo's Copilot Chat — it mirrors the Claude `CJ_*` chain, but Copilot can't push, so it stops at a clipboard-ready PR body):*

```
big-picture idea  (engineer, in VS Code Copilot Chat — target repo)
   │  python3 scripts/copilot-deploy.py install <target>   (one-time bundle install, workbench side)
   ▼
/wc-investigate   [scoping conversation → design doc]
   │   loads domain/*.md ambient context, greps the codebase, walks a 4-question scope
   │   → writes designs/<slug>-design-<ts>.md + receipts.investigate
   ▼
/wc-scaffold      [design doc → work-item directory tree]
   │   picks the next ID per type, writes the per-type artifact set, runs /validate
   │   → copies receipts.investigate into the tracker, writes receipts.scaffold, design status: SCAFFOLDED
   ▼
/wc-implement     [per-type code walkthrough — propose → confirm → edit, never auto]
   │   reads per-type spec (user-story: PRD+ARCHITECTURE+TEST-SPEC; defect: RCA+test-plan; task: TRACKER+test-plan)
   │   → writes code + receipts.implement
   ▼
/wc-qa            [test-row checklist + AC coverage + diff audit]
   │   runs test-plan / TEST-SPEC rows, enforces the Working-Tree Rule
   │   → writes receipts.qa  (the schema the other phases conform to)
   ▼
/wc-ship          [PR-description synthesis]
   │   runs /validate, builds a clipboard-ready PR body from receipts.* + journal + AC coverage
   │   → writes receipts.ship (pr_opened: false; user flips it true after opening the PR)
   ▼
open PR on GitHub  (manual — Copilot has no push / PR capability)

  /validate     ─ structural compliance gate (file or directory mode); callable standalone at any step
  /wc-pipeline  ─ read-only status overlay: reads receipts.* → 5 drift rules + Next Legal (zero writes)
```

Every step writes a `receipts.<phase>` block into the work-item tracker's YAML frontmatter; that receipts chain is how the otherwise-stateless Copilot prompts hand off to each other and how `/wc-pipeline` reconstructs progress without re-running anything. Underneath, the bundle follows `WORKFLOW.md`'s 3-step doc-driven method (generate docs → align the big picture → implement) across a 4-phase lifecycle (Track → Implement → Review → Ship).

**What each command does:**

| Command | Role in a work workflow | Writes |
|---------|-------------------------|--------|
| `/wc-investigate` | Scoping conversation → structured design doc. Loads `domain/*.md` ambient context, greps the codebase for entities in the prompt, walks a 4-question scope (problem / target user / narrowest wedge / key risks). | `designs/<slug>-design-<ts>.md` + `receipts.investigate` |
| `/wc-scaffold` | Design doc → work-item directory tree. Picks the next ID per type, writes the per-type artifact set, runs `/validate` as a structural gate, propagates `receipts.investigate` as lineage. | work-item dir + `receipts.scaffold` |
| `/wc-implement` | Per-type implementation walkthrough (propose → confirm → edit; never auto). Reads different input artifacts per tracker `type:` (user-story / defect / task / feature / review). | code + `receipts.implement` |
| `/wc-qa` | QA walkthrough — runs the test-row checklist, cross-references AC coverage, audits the diff since the last `[qa-*]` journal entry, enforces the Working-Tree Rule. Locks the `receipts` schema the other phases conform to. | `receipts.qa` |
| `/wc-ship` | PR-description synthesis. Runs `/validate`, then builds a clipboard-ready PR body from `receipts.*` + journal + AC coverage (Copilot can't open the PR itself). | `PR-DESCRIPTION.md` + `receipts.ship` |
| `/wc-pipeline` | Read-only status compiler — reads `receipts.*` across phases, computes 5 drift rules (Missing / Stale / Coverage holes / Diff audit / Ship-not-opened) + Next Legal. The read-only capstone over all phase receipts. | — *(read-only)* |
| `/validate` | Structural compliance gate, file or directory mode. Rules are derived at runtime from the matching template — templates are the single source of truth. Callable standalone at any step. | — *(read-only)* |

`(non-skill bundle)` — Self-contained Copilot bundle mirroring the personal-workflow `/validate` workflow + ambient knowledge for non-Claude machines. Beyond the `prompts/` table above, it carries its own templates (`work-copilot/templates/*.md`), `WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, `fixtures/`, `copilot-artifact-manifests.json`, `domain/` skeletons, and `instructions/copilot-instructions.md`. Deployed via `python3 scripts/copilot-deploy.py install <target>`; doctor + remove via the same CLI. Bundle integrity enforced by `scripts/validate.sh` Error check 10 (`EXPECTED_BUNDLE_FILES` array). Add a new bundle file by appending one entry to that array.

## See also

- [`doc/PHILOSOPHY.md`](PHILOSOPHY.md) — workbench-level overview + the routing **decision tree** (which skill to pick for a given intent). Read this when you know what you want to do but aren't sure which skill to invoke; read SKILL-CATALOG.md (this file) when you have a skill name and want to understand its shape.
- `skills/{name}/USAGE.md` — per-skill operator + agent best-practice. Has five required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills). Always linked from the **Source:** line of each section above.
- [`doc/ARCHITECTURE.md`](ARCHITECTURE.md) — mechanism reference (auto-worktree, doc-sync hook, update-check, etc.). Deliberately does NOT duplicate the routing decision tree.
