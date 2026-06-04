# Workflows

This doc catalogs every routable skill in the repo — the `cj_goal` **orchestrator chains** that take a one-line intent (a feature topic, a bug description, a TODO row) all the way to a reviewable or shipped PR, AND the component skills those chains dispatch / the operator runs directly (the phase-step skills, the validator, the standalone utilities). The two live in two sections: `## Orchestrators` (the end-to-end chains, full detail) and `## Utilities & phase-step skills` (the single-step building blocks, a lighter shape). Each **orchestrator** section gives status, source paths, an "Invoke when" trigger, a fenced ASCII workflow chart, and a **Touches** block so a reader can see the shape of every workflow — and its blast radius — at a glance; each **utility / phase-step** entry uses the lighter shape described in that section (status + source + invoke-when + a compact Touches, no workflow chart or 4-bullet Touches — single-step skills dispatch nothing and run no pipeline).

**Granular-enumeration rule.** The **Touches** block carries FOUR canonical bullets — **Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** / **Docs touched** — and each **orchestrator** section MUST enumerate ALL of them at the *granular helper + named-step* level. "Granular" means the load-bearing, easy-to-forget pieces are named, not just the top-level skills: the worktree lifecycle (init via `cj-worktree-init.sh`, teardown via `cj-worktree-cleanup.sh` / `--phase cleanup`), the pre-build skills-sync (`cj-goal-common.sh --phase sync`, F000045 Fork 2) and base-freshness (Fork 1), the isolation gate, `check-version-queue.sh`, and the verdict-surfacing producer steps (Step 4.6 / 5.6 / 9.5). **Granularity ceiling:** stop at NAMED workbench helpers + pipeline steps — do NOT enumerate every raw `git`/`gh` call, and do NOT list `post-land-sync.sh` (it is NOT an orchestrator step — it is the internal core `--phase sync` reuses + a manual operator step; listing it would be factually wrong). The four anchored bullets are STRUCTURALLY enforced by `scripts/validate.sh` Check 15b (each `## Orchestrators` section's body must match `^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`); completeness *within* each bullet stays agent-judged (the `/CJ_document-release` Step 6.7 registered-doc audit + the `doc/WORKFLOWS.md` `requirement:` in the CLAUDE.md tracked-doc manifest). The 4-bullet mandate applies to the `## Orchestrators` sections ONLY — the `## Utilities & phase-step skills` entries deliberately use the lighter shape.

For **routing** (which skill to pick for a given intent), see [`doc/PHILOSOPHY.md`](PHILOSOPHY.md) `## Decision tree`. For the workbench's **mechanism reference** (auto-worktree, doc-sync wrapper, update-check, the `work-copilot` bundle), see [`doc/ARCHITECTURE.md`](ARCHITECTURE.md). For per-skill operator + agent best-practice, see each skill's `USAGE.md`.

Sections are hand-written and audited by `scripts/validate.sh` Check 15b — every `CJ_goal_*`-prefixed routable non-deprecated skill in `skills-catalog.json` (today exactly `CJ_goal_feature`, `CJ_goal_defect`, `CJ_goal_todo_fix`) must have a `### <name>` section with an ASCII chart AND a **Touches** block carrying all four anchored bullets (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`). No silent omission.

## Orchestrators

The three `cj_goal` orchestrators chain multiple skills end-to-end. Each has a mandatory ASCII workflow chart and a Touches block.

### CJ_goal_feature

**Status:** experimental (the F000027 `feature` verb; production front door for "build a feature end-to-end" but the chain is still being tuned)
**Source:** `skills/CJ_goal_feature/SKILL.md` · `skills/CJ_goal_feature/USAGE.md`

**Invoke when:** the operator has a one-line feature topic and wants a reviewable PR. Common phrasings: "build a feature", "one-line idea to a reviewable PR", "topic to PR". Stops at the PR — `/land-and-deploy` is a separate human step.

**Workflow:**

```
"<topic>"
   │  cj-goal-common.sh --phase sync --mode feature   (pre-build skills-sync, F000045 Fork 2; fail-soft → skipped)
   ▼
cj-goal-common.sh --phase worktree --mode feature   (auto cj-feat-* worktree)
   │   ↳ cj-worktree-init.sh --caller feature: Fork-1 base-freshness (ff local main to origin tip; fail-soft)
   ▼
Step 1.9 — isolation gate   (cj-worktree-init.sh --assert-isolated)
   │
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
/ship   [INLINE — diff-review AUQ suppressed; opens PR; check-version-queue.sh preflight]
   │
   ▼
Step 4.6 — registered-doc verdicts → PR body   [post-/ship gh pr edit; best-effort; T000038]
   │
   ▼
STOP at PR   (human reviews + merges; /land-and-deploy is SEPARATE)
   │
   ▼
Step 6.5 — cj-goal-common.sh --phase cleanup   (worktree janitor; sweeps OTHER landed cj-* worktrees; best-effort)
   │
   ▼
telemetry → ~/.gstack/analytics/CJ_goal_feature.jsonl
```

**Touches:**

- **Skills dispatched:** `/office-hours` (inline design), `/CJ_scaffold-work-item` → `/CJ_implement-from-spec` → `/CJ_qa-work-item` (silent depth-≤2 leaf subagents), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) → worktree create (`--phase worktree`) + Fork-1 base-freshness (ff local main) → Step 1.9 isolation gate (`--assert-isolated`) → `/office-hours` → design-summary approval gate → scaffold/implement/qa → doc-sync (Step 5.5) → `/ship` → registered-doc verdicts → PR body (Step 4.6) → STOP at PR → worktree-cleanup (Step 6.5, `--phase cleanup`) → telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry`, `--mode feature`), `scripts/cj-worktree-init.sh` (`--caller feature`, Fork-1 base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `doc/**` / `templates/doc-*` per the `cj-document-release.json` whitelist, folded into the same code PR.

### CJ_goal_defect

**Status:** experimental (the F000027 `defect` verb; ~80% reshape of /CJ_goal_investigate v1.1, still being hardened)
**Source:** `skills/CJ_goal_defect/SKILL.md` · `skills/CJ_goal_defect/USAGE.md`

**Invoke when:** the operator has a plain bug description with no pre-existing defect dir and wants a deployed fix. Common phrasings: "fix this bug end-to-end", "bug report to deployed fix", "root-cause and ship a fix". Differs from `/CJ_goal_feature` in that it auto-deploys after `/ship` — defects are time-sensitive.

**Workflow:**

```
"<bug description>"
   │  cj-goal-common.sh --phase sync --mode defect   (pre-build skills-sync, F000045 Fork 2; fail-soft → skipped)
   ▼
cj-goal-common.sh --phase worktree --mode defect   (auto cj-def-* worktree)
   │   ↳ cj-worktree-init.sh --caller defect: Fork-1 base-freshness (ff local main to origin tip; fail-soft)
   ▼
Step 5.0 — isolation gate   (cj-worktree-init.sh --assert-isolated)
   │
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
   ▼  /ship                                  (Gate #2 fires; check-version-queue.sh preflight; halt on [ship-declined])
   │
   ▼  Step 9.5 — registered-doc verdicts → PR body   (post-/ship gh pr edit "$PR_URL"; best-effort; T000039)
   │
   ▼  /land-and-deploy --suppress-readiness-gate
   │
   ▼  telemetry → ~/.gstack/analytics/CJ_goal_defect.jsonl
```

**Touches:**

- **Skills dispatched:** `/investigate` (root-cause, Agent subagent; Iron-Law gate), `/CJ_qa-work-item` (leaf subagent), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 always human), `/land-and-deploy --suppress-readiness-gate` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) → worktree create (`--phase worktree`) + Fork-1 base-freshness (ff local main) → Step 5.0 isolation gate (`--assert-isolated`) → `.inbox` draft → `/investigate` (Iron-Law gate) → promote to `D000NNN_<slug>/` → RCA + test-plan → `/CJ_qa-work-item` → doc-sync (Step 5.5) → `/ship` → registered-doc verdicts → PR body (Step 9.5) → `/land-and-deploy` → cleanup (`--phase cleanup`) → telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry`, `--mode defect`), `scripts/cj-worktree-init.sh` (`--caller defect`, Fork-1 base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `doc/**` / `templates/doc-*` per the `cj-document-release.json` whitelist, folded into the same fix PR.

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
cj-goal-common.sh --phase sync   (pre-build skills-sync, F000045 Fork 2; fail-soft → skipped)
   ▼
cj-worktree-init.sh --caller todo   (auto cj-todo-* worktree; Fork-1 base-freshness ff local main; fail-soft)
   │   (drain mode: one worktree per TODO via scripts/drain-one-todo.sh)
   ▼
T-task scaffold (TRACKER + test-plan, pure bash)
   │
   ▼
/CJ_implement-from-spec   (leaf Agent subagent, halt-on-red → halted_at_impl)
   │
   ▼
/CJ_qa-work-item          (leaf Agent subagent, halt-on-red → halted_at_qa)
   │
   ▼
/CJ_document-release   (Step 5.5 doc-sync; halt-on-red)
   │
   ▼
/ship   (Gate #2 fires per drained TODO — human approves diff; check-version-queue.sh preflight)
   │
   ▼
Step 5.6 — registered-doc verdicts → PR body   (post-/ship gh pr edit "$PR_URL"; best-effort; T000039)
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

**Touches:**

- **Skills dispatched:** `/CJ_suggest` (drain-mode enumeration, `--for-skill cj-goal`), `/CJ_implement-from-spec` → `/CJ_qa-work-item` (leaf Agent subagents), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 fires per drained TODO), `/land-and-deploy` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** preflight (drain enumerate / single-match) → pre-build skills-sync (`--phase sync`) → worktree create + Fork-1 base-freshness (ff local main) → T-task scaffold → `/CJ_implement-from-spec` → `/CJ_qa-work-item` → doc-sync (Step 5.5) → `/ship` → registered-doc verdicts → PR body (Step 5.6) → `/land-and-deploy` → TODOS.md DONE-mark → cleanup (`cj-worktree-cleanup.sh`, called directly) → telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync`; pre-build skills-sync, F000045 Fork 2), `scripts/cj-worktree-init.sh` (`--caller todo`, Fork-1 base-freshness; drain mode creates one worktree per TODO via `scripts/drain-one-todo.sh`), `scripts/cj-worktree-cleanup.sh` (post-land janitor, called directly), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `doc/**` / `templates/doc-*` per the `cj-document-release.json` whitelist, folded into each drained TODO's PR. Also marks the closed row in TODOS.md (hash-verified).

## Utilities & phase-step skills

The `## Orchestrators` above chain multiple skills end-to-end. The skills here are the single-purpose **building blocks** those chains dispatch (the phase-step skills + the validator), plus the standalone **utilities** the operator runs directly. They don't get a workflow chart — a single-step skill dispatches no skills and runs no pipeline — so each entry uses a **lighter shape** than the orchestrator 4-bullet Touches: `### <skill>` + **Status** + **Source** + **Invoke when** (1 line) + a compact **Touches** (`Scripts · tools · shell:` what it runs + `Reads / writes:` files/state it touches). The **Skills dispatched** / **Steps · phases** bullets are intentionally omitted (empty for single-step skills). Every skill below is also in [PHILOSOPHY.md ## Decision tree](PHILOSOPHY.md#decision-tree) (the New-skills check, the no-vanish safety net).

### Phase-step skills

Dispatched by the orchestrators as depth-≤2 leaf subagents.

#### CJ_scaffold-work-item

**Status:** experimental
**Source:** `skills/CJ_scaffold-work-item/SKILL.md` · `skills/CJ_scaffold-work-item/USAGE.md`
**Invoke when:** distilling an APPROVED `/office-hours` design doc into a compliant `work-items/<type>/<id>_<slug>/` tree (TRACKER + per-type artifacts + lifecycle gates); idempotent (re-run on the same input is a NO-OP).
**Touches:**

- **Scripts · tools · shell:** Read / Write / Edit; runs `/CJ_personal-workflow check` at the scaffold boundaries (no standalone helper script).
- **Reads / writes:** reads the APPROVED `/office-hours` design doc + `templates/CJ_personal-workflow/*` + `personal-artifact-manifests.json`; writes the new `work-items/<type>/<id>_<slug>/` tree.

#### CJ_implement-from-spec

**Status:** experimental
**Source:** `skills/CJ_implement-from-spec/SKILL.md` · `skills/CJ_implement-from-spec/USAGE.md`
**Invoke when:** writing the code a tracked work-item describes — reads the per-type spec (SPEC+DESIGN for user-stories, RCA+test-plan for defects, TRACKER+test-plan for tasks) and writes via Read/Edit/Write; propose-and-confirm by default with a sensitive-surface AUQ, `--auto` for trivial ≤2-file changes; idempotent.
**Touches:**

- **Scripts · tools · shell:** Read / Edit / Write; `git rm` for removals; `chmod +x` for new shell scripts; runs `/CJ_personal-workflow check` at the start + end boundaries.
- **Reads / writes:** reads the work-item's per-type input artifacts (+ parent feature DESIGN.md); writes the code files named in Components Affected and updates the TRACKER (journal + Files + Phase 2 implementer-owned gates).

#### CJ_qa-work-item

**Status:** experimental
**Source:** `skills/CJ_qa-work-item/SKILL.md` · `skills/CJ_qa-work-item/USAGE.md`
**Invoke when:** verifying a work-item against its test rows — user-stories get smoke + a fresh-context E2E subagent per TEST-SPEC row; defects/tasks run their test-plan rows smoke-equivalent; refuses on incomplete Phase 2; idempotent.
**Touches:**

- **Scripts · tools · shell:** Bash (runs the work-item's test-plan / TEST-SPEC rows + repo `scripts/test.sh` / `scripts/validate.sh` where a row calls them); runs `/CJ_personal-workflow check` at boundaries.
- **Reads / writes:** reads the work-item's test-plan / TEST-SPEC rows; writes findings to the TRACKER journal and transitions Phase 2 QA-owned gates.

#### CJ_document-release

**Status:** experimental
**Source:** `skills/CJ_document-release/SKILL.md` · `skills/CJ_document-release/USAGE.md`
**Invoke when:** inline at **Step 5.5** of all three `cj_goal` orchestrators (between QA pass and `/ship`) to fold doc updates into the same code PR; also operator-callable for a point-in-time doc audit. Wraps upstream `/document-release`; adds a `--docs <subset>` filter, a halt-on-red contract (`[doc-sync-red]`), and a doc-only auto-commit gated by the per-repo `cj-document-release.json` whitelist. (Mechanism detail: ARCHITECTURE.md `## F000036 inline doc-sync wrapper` + `## F000037 strict-required cj-document-release.json`.)
**Touches:**

- **Scripts · tools · shell:** the `Skill` tool (dispatches upstream `/document-release`); `scripts/cj-document-release-config.sh` (`--validate` / `--expand-whitelist` / `--resolve`); `git add` + `git commit` for the doc-only auto-commit.
- **Reads / writes:** reads `cj-document-release.json` + the project docs; writes the whitelisted doc set (README.md, CHANGELOG.md, CLAUDE.md, `doc/**`, `templates/doc-*`) and a `### Registered-doc requirements` verdict block (Step 6.7) to the gitignored `.cj-goal-feature/registered-doc-verdicts.md` scratch file.

### Validators

Depended on by every phase-step + orchestrator; run transitively at boundaries.

#### CJ_personal-workflow

**Status:** active
**Source:** `skills/CJ_personal-workflow/SKILL.md` · `skills/CJ_personal-workflow/USAGE.md`
**Invoke when:** validating work-item directories + tracker files against the personal templates and `personal-artifact-manifests.json`; the phase-step skills call it at their boundaries. Templates + WORKFLOW.md are the single source of truth for structural rules.
**Touches:**

- **Scripts · tools · shell:** Read / Glob / Grep / Bash (prose-driven check per `check.md`; no standalone helper script).
- **Reads / writes:** reads `personal-artifact-manifests.json` + `templates/CJ_personal-workflow/*` + the work-item tree; read-only audit — emits a structured PASS / `[MISSING]` / `[DRIFT]` / `[EXTRA]` report, mutates nothing.

### Standalone utilities

Operator-invoked directly; not part of a chain.

#### CJ_system-health

**Status:** active
**Source:** `skills/CJ_system-health/SKILL.md` · `skills/CJ_system-health/USAGE.md`
**Invoke when:** you want a read-only `~/.claude/` health dashboard — scans installed skills, builds a dependency graph, checks filesystem health, surfaces usage analytics with a behavioral-topology overlay, optionally invokes waza; produces a scored report with trend tracking.
**Touches:**

- **Scripts · tools · shell:** Bash / Read / Glob / Grep; optionally invokes `waza` (config hygiene).
- **Reads / writes:** reads `~/.claude/` (installed skills, manifest, analytics JSONL); read-only dashboard plus a trend-history write.

#### CJ_suggest

**Status:** active
**Source:** `skills/CJ_suggest/SKILL.md` · `skills/CJ_suggest/USAGE.md`
**Invoke when:** you want a ranked top-5 (or `--limit N`) of next-up work items; internal phase-step rows are filtered by default (`--include-internal` surfaces them); `--for-skill` / `--limit` pre-filter for downstream callers like `/CJ_goal_todo_fix`.
**Touches:**

- **Scripts · tools · shell:** `scripts/suggest.sh` (the ranking helper); Read / Grep.
- **Reads / writes:** reads `TODOS.md` + each work-item TRACKER's frontmatter; read-only — prints the ranked list, mutates nothing.

#### CJ_improve-queue

**Status:** experimental
**Source:** `skills/CJ_improve-queue/SKILL.md` · `skills/CJ_improve-queue/USAGE.md`
**Invoke when:** workbench self-improvement — `evaluate <url>` (fetch + classify a Claude best-practice article → draft TODOS row if novel), `audit` (offline repo self-scan), `research <topic>` (WebSearch + per-result evaluate with a privacy gate); all rows land with `<!--impr-draft-->` markers.
**Touches:**

- **Scripts · tools · shell:** the `/browse` skill (URL fetch), WebSearch; an mkdir-based write lock + atomic `mv`; Read / Edit.
- **Reads / writes:** reads the fetched article + the repo (audit mode) + `skills-catalog.json`; appends `<!--impr-draft-->`-marked draft rows to `TODOS.md` (backup-rotated).

#### CJ_repo-init

**Status:** experimental
**Source:** `skills/CJ_repo-init/SKILL.md` · `skills/CJ_repo-init/USAGE.md`
**Invoke when:** preparing a repo for the CJ_ family — detects which CJ_ skills are deployed, verifies each one's per-repo prerequisites (`cj-document-release.json`, `CJ-DOC-RELEASE.md`, `TODOS.md`, `work-items/` tree), prints a health table, and on one confirm scaffolds the missing prerequisites from generic portable seeds; in-place, no worktree/ship; idempotent.
**Touches:**

- **Scripts · tools · shell:** Bash / Read / Write; AskUserQuestion (the one scaffold confirm).
- **Reads / writes:** reads the target repo root + `skills-catalog.json`; on confirm writes the missing per-repo prerequisites (`cj-document-release.json`, `CJ-DOC-RELEASE.md`, `TODOS.md`, `work-items/` tree) from portable seeds.

## See also

- [`doc/PHILOSOPHY.md`](PHILOSOPHY.md) — workbench-level overview + the routing **decision tree** (which skill to pick for a given intent). Read this when you know what you want to do but aren't sure which skill to invoke; read this file (WORKFLOWS.md) when you want to understand the shape and blast radius of a `cj_goal` workflow end-to-end.
- [`doc/ARCHITECTURE.md`](ARCHITECTURE.md) — mechanism reference (auto-worktree, doc-sync wrapper, update-check, the `work-copilot` bundle, etc.) — *how* the layers underneath these skills work. Deliberately does NOT duplicate the routing decision tree; the per-skill component roster lives in this doc's `## Utilities & phase-step skills` section above.
- `skills/{name}/USAGE.md` — per-skill operator + agent best-practice. Has five required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills). Always linked from the **Source:** line of each section above.
