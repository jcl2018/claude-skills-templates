<!-- GENERATED FILE — do not edit by hand.
     Rendered from the workflow-docs registry (spec/workflow-spec.md) by:
     scripts/workflow-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 27 enforces freshness. -->

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
