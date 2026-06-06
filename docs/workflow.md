# Workflows

This doc catalogs every routable skill in the repo — the `cj_goal`
**orchestrator chains** that take a one-line intent (a feature topic, a bug
description, a TODO row) all the way to a reviewable or shipped PR, AND the
component skills those chains dispatch / the operator runs directly (the
phase-step skills, the validator, the standalone utilities). The two live in two
sections: `## Orchestrators` (the end-to-end chains, full detail) and
`## Utilities & phase-step skills` (the single-step building blocks, a lighter
shape). Each **orchestrator** section gives status, source paths, an "Invoke
when" trigger, a fenced ASCII workflow chart, and a **Touches** block so a reader
can see the shape of every workflow — and its blast radius — at a glance; each
**utility / phase-step** entry uses the lighter shape described in that section
(status + source + invoke-when + a compact Touches, no workflow chart or 4-bullet
Touches — single-step skills dispatch nothing and run no pipeline).

**Granular-enumeration rule.** The **Touches** block carries FOUR canonical
bullets — **Skills dispatched** / **Steps · phases** / **Scripts · tools ·
shell** / **Docs touched** — and each **orchestrator** section MUST enumerate ALL
of them at the *granular helper + named-step* level. "Granular" means the
load-bearing, easy-to-forget pieces are named, not just the top-level skills: the
worktree lifecycle (init via `cj-worktree-init.sh`, teardown via
`cj-worktree-cleanup.sh` / `--phase cleanup`), the pre-build skills-sync
(`cj-goal-common.sh --phase sync`) and base-freshness fast-forward, the isolation
gate, `check-version-queue.sh`, and the verdict-surfacing producer steps.
**Granularity ceiling:** stop at NAMED workbench helpers + pipeline steps — do
NOT enumerate every raw `git`/`gh` call, and do NOT list `post-land-sync.sh` (it
is NOT an orchestrator step — it is the internal core `--phase sync` reuses + a
manual operator step). The four anchored bullets are STRUCTURALLY enforced by
`scripts/validate.sh` Check 15b (each `## Orchestrators` section's body must match
`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`); completeness
*within* each bullet stays agent-judged. The 4-bullet mandate applies to the
`## Orchestrators` sections ONLY — the `## Utilities & phase-step skills` entries
deliberately use the lighter shape.

For **routing** (which skill to pick for a given intent), see
[philosophy.md](philosophy.md) `## Decision tree`. For the workbench's
**mechanism reference** (auto-worktree, doc-sync wrapper, update-check, the
`work-copilot` bundle), see [architecture.md](architecture.md). For per-skill
operator + agent best-practice, see each skill's `USAGE.md`.

Sections are hand-written and audited by `scripts/validate.sh` Check 15b — every
`CJ_goal_*`-prefixed routable non-deprecated skill in `skills-catalog.json`
(today exactly `CJ_goal_feature`, `CJ_goal_defect`, `CJ_goal_todo_fix`) must have
a `### <name>` section with an ASCII chart AND a **Touches** block carrying all
four anchored bullets (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`,
`^- \*\*Docs`). No silent omission.

| Entry point | What it does |
|-------------|--------------|
| `/CJ_goal_feature "<topic>"` | One-line feature topic → reviewable PR (design → scaffold → implement → QA → doc-sync → ship; stops at the PR). |
| `/CJ_goal_defect "<bug>"` | Bug description → shipped fix (root-cause → RCA → implement → QA → doc-sync → ship → land). |
| `/CJ_goal_todo_fix [<id> \| "<frag>"]` | Drain shippable `TODOS.md` rows into PRs (single-TODO or `--max-drain N` batch). |
| Machinery | The deterministic shared helpers the orchestrators call — worktree init/cleanup, pre-build skills-sync, version-queue preflight (see the `## Machinery` section). |
| Utilities & phase-step skills | The single-step building blocks the chains dispatch / the operator runs directly — scaffold, implement, QA, doc-release, the validator, `/CJ_suggest`, `/CJ_system-health`. |
| Utility audits | Standalone read-only audits — `/CJ_portability-audit`, `/CJ_improve-queue`. |

## Orchestrators

The three `cj_goal` orchestrators chain multiple skills end-to-end. Each has a
mandatory ASCII workflow chart and a Touches block.

### CJ_goal_feature

**Status:** experimental (the `feature` verb; production front door for "build a
feature end-to-end" but the chain is still being tuned)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh`
+ the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_feature/SKILL.md` · `skills/CJ_goal_feature/USAGE.md`

**Invoke when:** the operator has a one-line feature topic and wants a reviewable
PR. Common phrasings: "build a feature", "one-line idea to a reviewable PR",
"topic to PR". Stops at the PR — `/land-and-deploy` is a separate human step.

**Workflow:**

```
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
capture doc path -> resume state file (last_completed_phase + HEAD SHA + PR#)
   |
   v
design-summary approval gate   [INLINE AUQ - go/no-go]
   |   `- Abort -> HALT
   v  Approve & build ->  SILENT depth-<=2 leaf Agent subagents
/CJ_scaffold-work-item -> /CJ_implement-from-spec -> /CJ_qa-work-item
   |
   v
/CJ_document-release   [INLINE Step 5.5 - doc-sync folds doc edits into the PR; halt-on-red]
   |
   v
portability gate   [INLINE Step 5.7 - cj-goal-common.sh --phase portability-audit; halt-on-red BEFORE /ship]
   |   `- findings -> HALT (halted_at_portability; no PR)
   v
/ship   [INLINE - diff-review AUQ suppressed; opens PR; check-version-queue.sh preflight]
   |
   v
registered-doc + portability verdicts -> PR body   [post-/ship gh pr edit; best-effort]
   |
   v
STOP at PR   (human reviews + merges; /land-and-deploy is SEPARATE)
   |
   v
cj-goal-common.sh --phase cleanup   (worktree janitor; sweeps OTHER landed cj-* worktrees; best-effort)
   |
   v
telemetry -> ~/.gstack/analytics/CJ_goal_feature.jsonl
```

**In words:** the orchestrator first calls `cj-goal-common.sh` for the
deterministic setup — the `--phase sync` pre-build skills-sync and the `--phase
worktree` create of an isolated `cj-feat-*` worktree (with base-freshness), then
`cj-worktree-init.sh --assert-isolated` gates the build (see
[How the machinery works](#how-the-machinery-works)). The one interactive phase
is `/office-hours` (inline), gated by a design-summary go/no-go; everything after
it is silent — the scaffold -> implement -> QA leaf subagents, then
`/CJ_document-release` folds doc edits into the same PR at Step 5.5, and `/ship`
opens it. It STOPs at the open PR (the human architecture gate; `/land-and-deploy`
is a separate step), and the resume state file lets a re-invocation pick up
mid-chain without redoing finished phases.

**Touches:**

- **Skills dispatched:** `/office-hours` (inline design), `/CJ_scaffold-work-item` -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (silent depth-<=2 leaf subagents), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (opens the PR). `/CJ_personal-workflow` runs transitively as each phase-step's boundary check.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `/office-hours` -> design-summary approval gate -> scaffold/implement/qa -> doc-sync (Step 5.5) -> portability gate (Step 5.7, `--phase portability-audit`; halt-on-red before `/ship`) -> `/ship` -> registered-doc + portability verdicts -> PR body -> STOP at PR -> worktree-cleanup (`--phase cleanup`) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `portability-audit`, `--mode feature`), `scripts/cj-portability-audit.sh` (the portability engine, run STRICT via `--phase portability-audit`), `scripts/cj-worktree-init.sh` (`--caller feature`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same code PR.

### CJ_goal_defect

**Status:** experimental (the `defect` verb; still being hardened)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh`
+ the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_defect/SKILL.md` · `skills/CJ_goal_defect/USAGE.md`

**Invoke when:** the operator has a plain bug description with no pre-existing
defect dir and wants a deployed fix. Common phrasings: "fix this bug
end-to-end", "bug report to deployed fix", "root-cause and ship a fix". Differs
from `/CJ_goal_feature` in that it auto-deploys after `/ship` — defects are
time-sensitive.

**Workflow:**

```
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
   v  write RCA.md + test-plan.md -> /CJ_qa-work-item (leaf subagent)
   |
   v  /CJ_document-release                   (Step 5.5 doc-sync; halt-on-red)
   |
   v  portability gate                       (Step 5.7 - cj-goal-common.sh --phase portability-audit; halt-on-red BEFORE /ship)
   |        findings -> HALT (halted_at_portability; no PR)
   |
   v  /ship                                  (Gate #2 fires; check-version-queue.sh preflight)
   |
   v  registered-doc + portability verdicts -> PR body   (post-/ship gh pr edit "$PR_URL"; best-effort)
   |
   v  /land-and-deploy --suppress-readiness-gate
   |
   v  telemetry -> ~/.gstack/analytics/CJ_goal_defect.jsonl
```

**In words:** same deterministic spine as `/CJ_goal_feature` — `cj-goal-common.sh`
does the `--phase sync` + `--phase worktree` setup (a `cj-def-*` worktree with
base-freshness) and `cj-worktree-init.sh --assert-isolated` gates it (see
[How the machinery works](#how-the-machinery-works)). The defining move is the
Iron-Law gate: `/investigate` must produce a root cause or the run HALTs with
nothing promoted — the defect ID is minted only after it passes, when the
`.inbox` draft is promoted to a canonical defect dir. After QA,
`/CJ_document-release` folds doc edits into the same fix PR (Step 5.5) and the
chain auto-lands via `/ship` -> `/land-and-deploy` (defects are time-sensitive),
with `cj-worktree-cleanup.sh` sweeping the now-landed worktree.

**Touches:**

- **Skills dispatched:** `/investigate` (root-cause, Agent subagent; Iron-Law gate), `/CJ_qa-work-item` (leaf subagent), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 always human), `/land-and-deploy --suppress-readiness-gate` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** pre-build skills-sync (`--phase sync`) -> worktree create (`--phase worktree`) + base-freshness (ff local main) -> isolation gate (`--assert-isolated`) -> `.inbox` draft -> `/investigate` (Iron-Law gate) -> promote to a defect dir (a full `tracker-defect.md`-compliant tracker) -> RCA + test-plan -> commit fix + artifacts (before QA) -> `/CJ_qa-work-item` -> doc-sync (Step 5.5) -> portability gate (Step 5.7, `--phase portability-audit`; halt-on-red before `/ship`) -> `/ship` -> registered-doc + portability verdicts -> PR body -> `/land-and-deploy` -> cleanup (`--phase cleanup`) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` / `worktree` / `pr-check` / `cleanup` / `telemetry` / `portability-audit`, `--mode defect`), `scripts/cj-portability-audit.sh` (the portability engine, run STRICT via `--phase portability-audit`), `scripts/cj-worktree-init.sh` (`--caller defect`, base-freshness + `--assert-isolated` isolation gate), `scripts/cj-worktree-cleanup.sh` (post-land janitor, via `--phase cleanup`), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into the same fix PR.

### CJ_goal_todo_fix

**Status:** active (the TODO drainer; production front door for "fix this TODO"
and the cron-eligible `--quiet` mode powers /schedule integrations)
**Category:** workbench (operates ON the workbench — executes `cj-goal-common.sh`
+ the worktree helpers; matches `skills-catalog.json`)
**Source:** `skills/CJ_goal_todo_fix/SKILL.md` · `skills/CJ_goal_todo_fix/USAGE.md`

**Invoke when:** the operator wants to drain TODOS.md backlog rows into PRs.
Default no-args drains up to 10 easy-fix TODOs; single-TODO mode (an ID or
fragment) fixes exactly one. Common phrasings: "fix this TODO", "clear the TODO
backlog", "drain TODOs", "auto-resolve TODOs". `/ship` Gate #2 still fires per
drained TODO (the autonomy ceiling).

**Workflow:**

```
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
/CJ_qa-work-item          (leaf Agent subagent, halt-on-red)
   |
   v
/CJ_document-release   (Step 5.5 doc-sync; halt-on-red)
   |
   v
portability gate   (Step 5.7 - cj-goal-common.sh --phase portability-audit --mode feature; halt-on-red BEFORE /ship)
   |   (findings -> HALT halted_at_portability; no PR)
   v
/ship   (Gate #2 fires per drained TODO - human approves diff; check-version-queue.sh preflight)
   |
   v
registered-doc + portability verdicts -> PR body   (post-/ship gh pr edit "$PR_URL"; best-effort)
   |
   v
/land-and-deploy   (auto-merge + verify production)
   |
   v
TODOS.md DONE-mark (hash-verified row update)
   |
   v
telemetry -> ~/.gstack/analytics/CJ_goal_todo_fix.jsonl
```

**In words:** the entry point is a `TODOS.md` row (one in single mode, up to N in
drain mode, enumerated via `/CJ_suggest`), and the same `cj-goal-common.sh
--phase sync` + `cj-worktree-init.sh` setup creates a `cj-todo-*` worktree with
base-freshness (drain mode makes one worktree per TODO via `drain-one-todo.sh`) —
see [How the machinery works](#how-the-machinery-works). The body is a pure-bash
T-task scaffold -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item`, then
`/CJ_document-release` folds doc edits into the row's PR at Step 5.5. `/ship`
Gate #2 still fires per drained TODO (the autonomy ceiling — a human approves
each diff); on land it hash-verified DONE-marks the row and
`cj-worktree-cleanup.sh` sweeps the landed worktree.

**Touches:**

- **Skills dispatched:** `/CJ_suggest` (drain-mode enumeration, `--for-skill cj-goal`), `/CJ_implement-from-spec` -> `/CJ_qa-work-item` (leaf Agent subagents), `/CJ_document-release` (Step 5.5 doc-sync), `/ship` (Gate #2 fires per drained TODO), `/land-and-deploy` (auto-merge + verify). `/CJ_personal-workflow` runs transitively at boundaries.
- **Steps · phases:** preflight (drain enumerate / single-match) -> pre-build skills-sync (`--phase sync`) -> worktree create + base-freshness (ff local main) -> T-task scaffold -> `/CJ_implement-from-spec` -> `/CJ_qa-work-item` -> doc-sync (Step 5.5) -> portability gate (Step 5.7, `--phase portability-audit --mode feature`; halt-on-red before `/ship`) -> `/ship` -> registered-doc + portability verdicts -> PR body -> `/land-and-deploy` -> TODOS.md DONE-mark -> cleanup (`cj-worktree-cleanup.sh`, called directly) -> telemetry.
- **Scripts · tools · shell:** `scripts/cj-goal-common.sh` (`--phase sync` pre-build skills-sync + `--phase portability-audit` the pre-ship portability gate), `scripts/cj-portability-audit.sh` (the portability engine, run STRICT via `--phase portability-audit`), `scripts/cj-worktree-init.sh` (`--caller todo`, base-freshness; drain mode creates one worktree per TODO via `scripts/drain-one-todo.sh`), `scripts/cj-worktree-cleanup.sh` (post-land janitor, called directly), `scripts/check-version-queue.sh` (optional `/ship` preflight).
- **Docs touched:** via Step 5.5 `/CJ_document-release` — README.md, CHANGELOG.md, CLAUDE.md, and `docs/**` per the doc-spec.md registry-derived whitelist, folded into each drained TODO's PR. Also marks the closed row in TODOS.md (hash-verified).

## How the machinery works

The three orchestrator charts above share the same load-bearing pieces. Rather
than re-explain them in each chart, this glossary says what each one DOES and WHY
it exists, so the per-workflow "In words" narratives can just name them. (For the
routing decision — *which* orchestrator to pick — see
[philosophy.md ## Decision tree](philosophy.md#decision-tree-which-cj_-skill-do-i-call);
for the lower-level mechanism reference see [architecture.md](architecture.md).)

### `scripts/cj-goal-common.sh` — the shared phase dispatcher

**What:** a single helper the three orchestrators call for their deterministic,
non-interactive steps, selected by a `--phase` flag. The phases are `worktree`
(create + assert the isolated worktree, delegating to `cj-worktree-init.sh`),
`sync` (the pre-build skills-sync — reuses `post-land-sync.sh`'s guarded pull +
install core so installed skills match trunk at build start), `pr-check` (resolve
a PR's live state for resume + cleanup gating), `cleanup` (the post-run worktree
janitor, delegating to `cj-worktree-cleanup.sh`), `portability-audit` (the
pre-ship portability gate — runs `cj-portability-audit.sh` STRICT and classifies
the result into `ok` / `findings` / `skipped`, so a dishonest skill portability
declaration HALTs the run before the PR), and `telemetry` (append one JSONL
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
[philosophy.md ## Decision tree](philosophy.md#decision-tree-which-cj_-skill-do-i-call)
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
- **Reads / writes:** reads `doc-spec.md` (the registry) + the declared docs; writes the whitelisted doc set (README.md, CHANGELOG.md, CLAUDE.md, `docs/**`), self-bootstraps a missing `doc-spec.md`, stub-scaffolds missing declared docs, and writes a `### Registered-doc requirements` verdict block to the gitignored `.cj-goal-feature/registered-doc-verdicts.md` scratch file.

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
`scripts/suggest.sh` — matches `skills-catalog.json`)
**Source:** `skills/CJ_suggest/SKILL.md` · `skills/CJ_suggest/USAGE.md`
**Invoke when:** you want a ranked top-5 (or `--limit N`) of next-up work items;
internal phase-step rows are filtered by default (`--include-internal` surfaces
them); `--for-skill` / `--limit` pre-filter for downstream callers like
`/CJ_goal_todo_fix`.
**Touches:**

- **Scripts · tools · shell:** `scripts/suggest.sh` (the ranking helper); Read / Grep.
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
advisory check). The full correct-behavior spec is in the `## Utility audits` ->
`### /CJ_portability-audit` section just below.
**Touches:**

- **Scripts · tools · shell:** `scripts/cj-portability-audit.sh` (the shared engine, resolved repo-local-first then via the deployed shared home); Bash / Read / Grep. Also invoked by `scripts/validate.sh`.
- **Reads / writes:** reads `skills-catalog.json` (+ optional `portability_requires`) + each audited skill's files; read-only — prints the per-skill verdict table, mutates nothing.

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
behavior verbatim, operator-requested; it is NOT a `CJ_goal_*` orchestrator, so
`validate.sh` Check 15b neither requires nor rejects it).

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
   `--  validate.sh advisory check           -> prints findings, EXITS 0 in v1
                                                (PORTABILITY_STRICT=1 -> hard-fail)
```

**Strict tier ladder (each tier's ALLOWED dependency set; the bar is "works in a
repo that has never seen this workbench"):**

| Tier | ALLOWED | A dep beyond this is a FINDING |
|---|---|---|
| `standalone` | own bundled scripts (`skills/<name>/scripts/`) + the doc-spec contract files (`doc-spec.md`, `docs/**`, `TODOS.md`, `work-items/`) | root `scripts/*.sh`, `CLAUDE.md` reads, root config, the GitHub slug |
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

## See also

- [philosophy.md](philosophy.md) — workbench-level overview + the routing
  **decision tree** (which skill to pick for a given intent). Read this when you
  know what you want to do but aren't sure which skill to invoke; read this file
  (workflow.md) when you want to understand the shape and blast radius of a
  `cj_goal` workflow end-to-end.
- [architecture.md](architecture.md) — mechanism reference (auto-worktree,
  doc-sync wrapper, update-check, the `work-copilot` bundle, etc.) — *how* the
  layers underneath these skills work. Deliberately does NOT duplicate the
  routing decision tree; the per-skill component roster lives in this doc's
  `## Utilities & phase-step skills` section above.
- `skills/{name}/USAGE.md` — per-skill operator + agent best-practice. Has five
  required H2 sections (When to use / When NOT to use / Mental model / Common
  pitfalls / Related skills). Always linked from the **Source:** line of each
  section above.
