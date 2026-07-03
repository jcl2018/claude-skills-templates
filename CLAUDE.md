# CLAUDE.md

## What this repo is

A doc-first development workbench. Its primary surface is **Claude Code skills** (the `CJ_` workflow family + utilities under `skills/`), but it is deliberately **not Claude-only**: it also ships a self-contained **GitHub Copilot** bundle (`work-copilot/`) that carries the same work-item templates + validation set to non-Claude machines, plus a template library for doc-first development and tooling to validate, test, and distribute everything.

## Quick start

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates
./scripts/validate.sh          # check repo health
./scripts/test.sh              # run full test suite
```

## Running on Windows

This workbench is POSIX-shell software and supports Windows two ways (F000044):
**WSL2** (recommended — behaves identically to macOS/Linux) and **Git Bash**
(the shell Claude Code uses to run skill preambles on Windows). On Git Bash real
symlinks are unavailable, so `skills-deploy install` auto-falls-back to
**copy-mode** (real files + checksum-tracked drift) — see `scripts/skills-deploy`
`_can_symlink` + the manifest `install_kind`. When editing scripts, keep them
POSIX + LF (`.gitattributes` pins `eol=lf`) and use the portable `date_to_epoch`
idiom (probe `date --version` → GNU `date -d`, else BSD `date -j -f`), never
GNU-only `date -d`. Strip CR from **jq** output too — a Windows jq build emits
CRLF, so any `$(jq -r ...)` fed into parsing must go through a CR-stripping
`jq()` wrapper (`scripts/lib.sh:24` and `scripts/workflow-spec.sh` — the only
standalone spec engine with jq call sites — each define one; a NEW jq call in
any other engine must add the same wrapper first; regression drill:
`tests/workflow-spec-render.test.sh` T7). Windows CI is split by cadence
(F000075): the fast `windows-latest` Git Bash smoke job
(`.github/workflows/windows.yml`, the `CI-push` category) gates every PR and runs
ONLY `scripts/windows-smoke.sh`; the slow full `skills-deploy` suite
(`scripts/test-deploy.sh` on `windows-latest`) runs nightly in
`.github/workflows/windows-nightly.yml` (the `CI-nightly` category
`windows-deploy`, cron `23 8 * * *` + `workflow_dispatch`), off the PR path. Run
the smoke locally with `bash scripts/windows-smoke.sh`. Full feature:
`work-items/features/ops/F000044_windows_wsl2_git_bash_support/`.

**Install == clone holds on Windows (F000049/S5 — S000089).** The in-place
install==clone model (S4: a default `skills-deploy install` stamps `install_mode:
in-place` + `bundle_path == source`; skills resolve shared scripts + the
update-check from the deployed `_cj-shared` home, with no runtime `.source`
reach-back) is platform-neutral by construction, so it holds unchanged under
Git-Bash copy-mode. `scripts/windows-smoke.sh` asserts it (the in-place stamp +
the `_cj-shared` update-check resolution under `FORCE_COPY`) on BOTH the
`windows-latest` job and the ubuntu CI (`scripts/test.sh:506`). The POSIX-only
"dir-level skill symlink" refinement (a `git pull` making a NEW skill file live
without a reinstall) was deliberately NOT adopted: real symlinks are unavailable
under copy-mode, so it would create a POSIX-reinstall-free /
Windows-still-reinstalls **asymmetry** — the opposite of parity. On every
platform a NEW skill file is picked up by the next `skills-deploy install` /
`post-land-sync`.

## Skill routing

Routing rules are deployed globally to `~/.claude/rules/skill-routing.md` by
`./scripts/skills-deploy install`. Source of truth: [`rules/skill-routing.md`](rules/skill-routing.md).

The CJ_ skill family in this workbench is fronted by two intent-named verbs:
`/CJ_goal_feature` (build a feature: topic → reviewable PR) and `/CJ_goal_defect`
(fix a bug: description → shipped fix). Supporting skills: workflow validator
(/CJ_personal-workflow), per-phase skills (/CJ_scaffold-work-item,
/CJ_implement-from-spec, /CJ_qa-work-item, /CJ_document-release) that the
orchestrators dispatch as leaf subagents, and standalone utilities
(/CJ_system-health, /CJ_suggest, /CJ_goal_todo_fix, /CJ_portability-audit,
/CJ_doc_audit, /CJ_test_audit, /CJ_test_run). /CJ_goal_todo_fix bridges
TODOS.md rows to the shipping pipeline in one keystroke — see
`skills/CJ_goal_todo_fix/SKILL.md`.
/CJ_portability-audit is the producer-side static lint that checks each catalog
skill's declared `portability` against its actual repo-local dependencies (wired
into `validate.sh` as an advisory check).
/CJ_doc_audit + /CJ_test_audit are the operator audit verbs — runnable
standalone in ANY repo, each a THREE-STAGE audit: they seed-deliver the
two-tier doc/test contracts (`spec/doc-spec.md` / `spec/test-spec.md` via
each engine's `--seed`) when missing, then run Stage 1 (deterministic —
engine: `doc-spec.sh --check-on-disk` for docs; `test-spec.sh --validate` +
`--check-coverage` for tests; output printed verbatim, no executor-authored
loops), Stage 2 (requirement compliance — agent-judged, evidence-forced:
each requirement/rule/unit-purpose quoted, clause-checked, evidence cited),
and Stage 3 (implementation drift — agent-judged: ground truth enumerated
from the live repo first, then each doc/surface cross-walked). Standalone,
Stages 2+3 are dispatched to ONE fresh-context subagent (the Agent tool);
inside `/CJ_qa-work-item` Step 8.6 they run INLINE (the nested-subagent
wall). Reports are per-stage (`DOC_AUDIT:` / `TEST_AUDIT:` + `FINDINGS=` +
`STAGE1/2/3_FINDINGS=` + `stageN/`-prefixed findings), feeding the post-QA
checkpoint AUQ every cj_goal pipeline surfaces. On orchestrator paths the
three-stage audit is DEFERRED inside QA (`DEFER_AUDIT: true`) and re-run ONCE by
the orchestrator AFTER doc-sync, so the checkpoint decides on the docs that will
actually ship (F000064 post-sync-authoritative-audit reorder; standalone
`/CJ_qa-work-item` keeps the audit inline).
/CJ_test_run is the EXECUTOR companion to /CJ_test_audit (F000072/S000122):
where the audit answers "are the declared tests WIRED?" (static), /CJ_test_run
answers "do they PASS?" — it runs the Stage-1 audit as a pre-step, then EXECUTES
the repo's runners declared in the `spec/test-spec-custom.md` `runners:` overlay
axis via `scripts/test-run.sh`, cost-tiered (default `free`; `--evals` for the
paid eval tier, `--e2e` for local-only, `--all` for everything — no surprise
model spend), and writes a per-run `.md` report + a `.json` ledger (`schema: 1`;
runner→rc→covered-families→HEAD-SHA) under `tests/test-run/reports/`. Verdicts
are runner-granularity and evidence-derived (aggregate `{pass, fail,
all-skipped}`; a skipped tier is never `pass`); registry-absent ⇒ SKIP,
present-invalid ⇒ the `[test-spec-no-config]` halt, declared-but-zero-runners ⇒
`SKIP: no runners declared`. Standalone/any-repo like the audit verbs. The
audit-side ledger-freshness handshake + diff-driven `--changed` selection are
deferred follow-ups.
The **category-based test contract** (F000074 foundation, taxonomy V2 by
F000075 — ADDITIVE) threads one noun — the test **category** — through five
surfaces: the folder a test lives in (`tests/<category>/`), the `categories:`
overlay axis that declares it, the `docs/tests/<category>/<name>.md` doc, the
`docs/tests/index.md` INDEX row, and the `/CJ_test_run` argument that runs it.
Taxonomy V2 is the closed set `{workflow, CI-push, CI-nightly}` (`workflow` =
deterministic end-to-end workflow tests; `CI-push` = what must be green per-PR to
ship; `CI-nightly` = the slower cadence deferred off the PR path to a nightly
schedule) — the `CI` bucket of the V1 foundation was split into the `CI-push` /
`CI-nightly` cadence pair. **The per-test doc is the authoritative What/How/Why
front door (F000076 — a GENERAL rule that now lives in `spec/test-spec.md`):**
each declared category test's `docs/tests/<category>/<name>.md` is the ONE place a
maintainer opens to understand and run that test, so it MUST carry three literal
sections — `## What it is` (what the test verifies), `## How to run` (the exact
command matching the category's `command` + the `/CJ_test_run <name>` /
`--category <cat>` invocation), and `## Explanation` (why it exists + a cross-link
to the flat `docs/tests/<family>.md` units-detail page). The flat family docs are
KEPT unchanged as that linked drill-down — the per-test doc is the front door, the
family doc is the detail behind it. `/CJ_test_audit` gains the six structural
checks (a–f) via `test-spec.sh --check-structure` + idempotent doc-stub seeding
(`--seed-docs`, which now seeds a stub already carrying the three front-door
sections), and `/CJ_test_run` gains
`--category <workflow|CI-push|CI-nightly>` + single-name selection — both reusing
the `docs/tests/` name. `--check-structure` requires one `tests/<category>/`
subfolder per DISTINCT declared category (derived from the overlay's
`categories:` rows, so a repo that declares no nightly test is never forced to
create an empty `tests/CI-nightly/`); the new check **(f)** enforces
deterministically that each per-test doc actually CONTAINS the three front-door
section headings, and `/CJ_test_audit` Stage 2 judges that content is TRUTHFUL
(the how-to-run matches the command; the what/why are accurate) — the doc-level
catch for the anchor-greps-while-the-doc-rots gap. It COEXISTS with the existing
`units:`/`behaviors:`/`runners:` axes and the `docs/tests/<family>.md` family
render (the physical test-script move into `tests/<category>/`, the grammar
removal, and the `validate.sh` Checks 24/26/28 re-expression are DEFERRED
follow-ups); the audit REPORTS structural gaps + seeds docs but NEVER moves test
scripts, so it stays standalone-safe on a repo it does not own.
/CJ_document-release is the inline doc-sync wrapper invoked at
Step 5.5 of every cj_goal orchestrator (between the QA pass and the post-sync
doc/test audit + the QA-audit checkpoint, all ahead of `/ship`) — folds
doc updates into the same code PR rather than chasing them post-merge. It is also
a keeper of the doc contract: it reads the merged doc-spec registry,
self-bootstraps a missing `spec/doc-spec.md` from the portable seed, and
stub-scaffolds any declared-but-missing doc (the duty that replaced the retired
`/CJ_repo-init`; `spec/test-spec.md` is stubbed via `test-spec.sh --seed` so the
stub is a valid registry). The non-doc per-repo prerequisites (TODOS.md,
work-items/) are
lazy-created by the skills that read them. See [`spec/doc-spec.md`](spec/doc-spec.md).

## CI/CD merge convention

This repo uses **squash merges**. When `/ship` or `/land-and-deploy` reaches the
merge step (`gh pr merge`), use this exact invocation:

```bash
gh pr merge <PR#> --squash --delete-branch
```

Do NOT add `--auto`. Auto-merge is disabled in this repo's settings, so
`gh pr merge --auto` exits 0 even when the actual merge fails (error goes to
stderr). The upstream gstack `/land-and-deploy` Step 4 documents a fallback path,
but the silent exit-0 makes it easy for agents/operators to miss the fallback
and treat a non-merge as success. Skipping `--auto` entirely sidesteps this.

**Verify before cleanup.** After ANY `gh pr merge` invocation, verify the merge
succeeded BEFORE running cleanup (especially the worktree-workaround
`gh api -X DELETE` below):

```bash
gh pr view <PR#> --json state -q .state  # must print MERGED
```

If state is OPEN, the merge silently failed. Do NOT delete the remote branch —
deleting the branch on an open PR auto-closes the PR (we burned ~5 min recovering
from this exact failure mode on PR #83 / v2.0.4).

**Auto-worktree on main (F000025 + F000027):** the four current CJ_goal_* orchestrators auto-create a `.claude/worktrees/cj-{prefix}-{ts}-{pid}/` worktree when invoked from `main` with arguments — main checkout stays clean and parallel sessions don't collide. The four orchestrators and their prefixes:

- `/CJ_goal_feature "<topic>"` → `cj-feat-*` (worktree phase: `cj-goal-common.sh --mode feature` → `cj-worktree-init.sh --caller feature`)
- `/CJ_goal_task "<small task>"` → `cj-task-*` (`cj-goal-common.sh --mode task` → `cj-worktree-init.sh --caller task`)
- `/CJ_goal_defect "<bug description>"` → `cj-def-*` (`cj-goal-common.sh --mode defect` → `cj-worktree-init.sh --caller defect`)
- `/CJ_goal_todo_fix [<T-ID> | "<fragment>"]` (single-TODO mode) → `cj-todo-*` (`cj-worktree-init.sh --caller todo`)

Conductor-managed sessions (already inside a worktree) detect + no-op. Opt out of the worktree with `--no-worktree`; opt out of the pre-build skills-sync (below) with `--no-sync`. Drain mode (`/CJ_goal_todo_fix --max-drain N`) creates one worktree per drained TODO inside `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh`. Helper: `scripts/cj-worktree-init.sh`; tests: `tests/cj-worktree-init.test.sh`.

**Pre-build base-freshness + skills-sync (F000045):** before a build starts, two fail-soft forks make sure it runs against current trunk + current skills. Neither ever halts the orchestrator — a guard refusal, a divergence, or an offline network all degrade to "proceed on what we have."

- **Fork 1 — base-freshness (in the worktree phase).** Inside `cj-worktree-init.sh`, just before `git worktree add`, when on `main`/`master` with an existing `origin/<branch>` ref, the helper fail-soft fetches and fast-forwards local `main` to the origin tip so the new worktree branches off current trunk. The outcome rides the `note` field of the `created` JSON emit: `ff'd N commits` (was behind), `local main diverged from origin; building on local main` (diverged — no ff, no halt, local commits never dropped), or `freshness skipped (offline)` (fetch failed / no origin ref). Skipped under `--dry-run`. Runs even under `--no-sync` (it is independent of Fork 2). Tests: `tests/cj-worktree-init.test.sh`.
- **Fork 2 — pre-build skills-sync (a `cj-goal-common.sh --phase sync` step the orchestrator runs BEFORE the worktree block).** Delegates to `post-land-sync.sh`'s guarded pull+install-from-`.source` core so installed skills match trunk at build start (without the worktree-invoked-install foreign-owned-skill skip). Fail-soft exactly like `pr-check`: a guard refusal (`.source` missing / not a git repo / off-main / dirty tracked tree) or an offline pull emits `PHASE_RESULT=skipped` (exit 0), never failed. `--no-sync` short-circuits to `skipped` BEFORE any install (the operator's opt-out for the heavy global-state install + latency); `--dry-run` forwards to `post-land-sync.sh --dry-run`. Stdout fields: `SYNC_RAN`, `VERSION_BEFORE`, `VERSION_AFTER`, `PHASE_RESULT`. Tests: `tests/cj-goal-common-sync.test.sh`.

**Land/PR recap formatter (F000068 / S000112):** a `cj-goal-common.sh` phase —
`--phase recap` — a **pure formatter** that renders the standardized 3-part
land/PR recap block (see `## Post-land recap`). It takes `--when {before|after}`
(selects the header) and the content via the existing repeatable `--field`
parsing (`delivered=` / `e2e=` / `next=`), printed verbatim (no eval — reuses the
telemetry phase's split-on-first-`=` idiom). It computes NOTHING, mutates NOTHING,
writes NO telemetry; emits `PHASE=recap` + `PHASE_RESULT=ok` and exits 0. Fully
fail-soft / advisory — a missing field renders an empty section, it NEVER halts.
The four `CJ_goal_*` orchestrators call it at their land/PR-stop step (S000113;
before+after for the landing verbs defect/todo_fix, one at-PR recap for the
PR-stop verbs feature/task), with a documented prose fallback when the helper is
absent. There is NO `validate.sh` gate asserting the wiring (advisory posture).
Tests: `tests/cj-goal-common-recap.test.sh` + the `--phase recap` integration
block in `scripts/test.sh`.

**Worktree cleanup:** This repo's day-to-day work happens inside a git worktree under
`.claude/worktrees/{name}/`, while the parent repo at the root has `main` checked out.
`gh pr merge --delete-branch` does a local `git checkout main` to clean up; in a worktree
that errors with `'main' is already checked out`. The remote merge succeeds anyway, but
the remote branch is NOT deleted. Workaround (only after verifying MERGED above):

```bash
gh api -X DELETE "repos/jcl2018/claude-skills-templates/git/refs/heads/<branch>"
```

Run this after the merge to actually delete the remote branch.

*Automated local-worktree sweep (T000036).* The manual `gh api -X DELETE` above
deletes the **remote** branch; the **local** `.claude/worktrees/cj-*/` dir is swept
automatically by the post-run janitor `scripts/cj-worktree-cleanup.sh`. Each of the
three `CJ_goal_*` orchestrators runs it at its post-land terminal (feature: after
the PR opens; defect/todo: after `/land-and-deploy`), so **defect/todo remove their
own (now-landed) worktree**, while a **feature run does NOT remove its own** — its PR
is still OPEN at the PR-stop, so that worktree is swept by the *next* cj_goal run.
Either way, any *other* MERGED/CLOSED `cj-*` worktrees are removed and the root
checkout is switched to `main` and pulled, with no manual step. It is **PR-state-gated** (a
worktree is removed only when its PR reads MERGED/CLOSED — never by branch ancestry,
which a squash merge breaks) and **self-healing** (every cj_goal run sweeps *all*
landed cj-* worktrees, so a hand-merged worktree is cleared by the next run of any
kind). It is strictly best-effort — it never halts a run. To preview the current
sweep at any time without mutating anything: `./scripts/cj-worktree-cleanup.sh
--dry-run` (lists `WOULD-REMOVE` / `WOULD-SKIP`).

*Manual-path caveat.* The sweep is a **pipeline step the orchestrator runs**, not a
background git hook — it fires only when you invoke one of the three `CJ_goal_*`
skills. A fully manual land (a hand-rolled `/ship` + `gh pr merge` that bypasses the
orchestrator) does NOT trigger it; run `./scripts/cj-worktree-cleanup.sh` by hand
afterward (`--dry-run` first to preview).

**Post-land local sync (F000041).** After `gh pr merge` + verify MERGED + the
worktree branch cleanup above, run the helper to install the merged skills
locally and refresh `collection_version`:

```bash
./scripts/post-land-sync.sh            # guarded git pull --ff-only + skills-deploy install + version report
./scripts/post-land-sync.sh --dry-run  # preview only — resolve .source + print would-run commands; mutate nothing
```

The helper resolves `.source` from `~/.claude/.skills-templates.json`, guards it
(refuses with a named message + non-zero exit if `.source` is missing, not a git
repo, not on `main`, or has a dirty *tracked* tree — untracked files are OK),
then `git -C "$_SRC" pull --ff-only` and runs `skills-deploy install` **from
`.source`** (not from a worktree — a worktree-invoked install skips
foreign-owned skills). It prints `collection_version` before→after.

*Install == clone, in place (F000049/S4 — S000088).* The default `skills-deploy
install` declares the install **install == clone**: it stamps `install_mode:
in-place` + `bundle_path` = the checkout you ran it from (which already equals
manifest `source`), so the install IS the dev checkout — there is no separate
clone. S4 also dropped every runtime `.source` reach-back from the skill
preambles (they resolve shared scripts repo-local → `_cj-shared`; the
update-check nudge resolves from `_cj-shared`). `post-land-sync.sh` and the
`cj-goal-common.sh --phase sync` step are **reframed, not retired**: because
`gh pr merge` is a REMOTE merge, the in-place checkout still needs a post-merge
`git pull` + `skills-deploy install` to refresh per-file symlinks for any NEW
files — this helper IS that pull+install, now operating on the one in-place
checkout (`source` == `bundle_path`). The `cj-feat-*` worktree flow is KEPT (it
is the parallel-build isolation primitive, created INSIDE the checkout).
`--bundle` remains the managed-checkout / fresh-consumer bootstrap (relocate to
`~/.claude/skills/cj-workbench`); the in-place default is the developer path.

*Why this step is needed.* `gh pr merge` is a **remote** merge. The local
post-merge auto-sync hook (`setup-hooks.sh` → `skills-deploy install`) only fires
on a local `git pull`/`merge`, so a remote merge bypasses it entirely — the
just-merged skill lands on `main` but is NOT installed into `~/.claude/skills/`
(so it isn't invocable as a `/`-command) until you pull + install. This helper is
that pull + install in one correct command.

*Drift note.* The same install also reconciles `collection_version` drift between
the manifest (`~/.claude/.skills-templates.json`) and `.source/VERSION`: a series
of remote merges leaves the manifest version lagging `.source` (observed: manifest
6.0.8 vs `.source` 6.0.10), and `post-land-sync.sh` brings them back into sync.

**Queue-collision preflight.** When multiple worktrees may be active and you're
about to run `/ship`, optionally run:

```bash
./scripts/check-version-queue.sh
```

The script scans open PRs targeting main, extracts `v<X.Y.Z>` from title prefixes,
and prints the next free VERSION slot. Catches collisions BEFORE `/ship`'s
local-only bump (cheaper than `/land-and-deploy` Step 3.4 post-push drift
detection). Skips with a one-line note when `gh` is offline or unauthenticated.
Read-only; no mutations. This is a workbench-side fallback for when gstack's
own `bin/gstack-next-version` queue util is offline in this repo (the typical
state — gstack-next-version is an upstream feature not currently deployed here).

See `work-items/defects/D000008_*` for the full root cause and the planned upstream fix
to gstack.

## Post-land recap

Around **every** cj_goal land/PR-stop, surface a consistent **3-part** recap to
the operator so they are never left guessing what just shipped, how to confirm it,
or what to do next. The three parts are always the same labelled sections:

1. **Delivered** — 1–3 lines: the change in plain terms, the version it bumped to,
   and the PR number + squash-merge SHA (e.g. "v6.0.69 — added the layer-grouped
   verification-surface section to `spec/test-spec-custom.md`; PR #267, `cdc684c`").
2. **How to E2E-test it** — the concrete end-to-end commands or checks for *this*
   change, not a generic checklist (e.g. `scripts/test-spec.sh --check-coverage`,
   `git show origin/main:<file>`, or "open PR #N and read section X"). Name the one
   or two checks that actually prove the change is live and correct.
3. **Next step** — the concrete next action (review + merge the PR, run
   `/land-and-deploy`, drain the next TODO, confirm the deploy — whatever applies).

**Before + after (F000068).** The recap is emitted at two points around the
land/PR moment, keyed off `--when`:

- **before** (`=== About to land ===`) — a heads-up just ahead of the land/PR.
- **after** (`=== Landed / PR opened ===`) — the confirmation + verification once
  the merge/PR is in place.

The two **landing verbs** emit a true before+after pair around the land:
`CJ_goal_defect` (before ahead of `skills/CJ_goal_defect/pipeline.md` Step 10's
`/land-and-deploy`; after at Step 12) and `CJ_goal_todo_fix` (before in
`pipeline.md` Step 5.6, after in SKILL.md's Agent-layer terminal — per drained
TODO). The two **PR-stop verbs** emit ONE at-PR recap (the after form), since they
never land in-pipeline: `CJ_goal_feature` (Step 6.5) and `CJ_goal_task` (Step 7);
the operator's later manual `/land-and-deploy` is the existing direct-land path.

**The producer is `cj-goal-common.sh --phase recap`** (F000068 / S000112) — a
shared **pure formatter**: it renders the standardized 3-part block (header keyed
off `--when {before|after}`, then the three labelled sections sourced from
`--field delivered=` / `--field e2e=` / `--field next=`), and nothing else. It
computes no content, mutates nothing, and writes no telemetry. **The agent authors
the `delivered`/`e2e`/`next` content** for THIS change — the helper only formats
it uniformly. A missing field renders an empty section; if the helper is absent the
pipeline falls back to emitting the same 3-part block as prose. (`/land-and-deploy`
is an upstream gstack skill this workbench never edits — the same rule that makes
`/CJ_document-release` wrap `/document-release` — so the recap calls bracket the
land in this repo's `pipeline.md`, never inside the upstream skill.)

It is **advisory**: it never blocks, never changes the land/PR outcome, and adds no
gate — a courtesy recap so the operator can review or verify at a glance. Like the
other convention sections here, it is prose guidance; **there is no `validate.sh`
check that asserts it fired.**

## Work item templates

Each workflow skill owns its own templates and artifact manifest:
- **CJ_personal-workflow**: `templates/CJ_personal-workflow/` + `skills/CJ_personal-workflow/personal-artifact-manifests.json`
- **work-copilot/** (Copilot consumer bundle, not a Claude skill): `work-copilot/templates/` + `work-copilot/copilot-artifact-manifests.json` + `work-copilot/WORKFLOW.md` are the canonical source. Deployed to non-Claude target repos via `scripts/copilot-deploy.py`.

Scaffolding conventions live in each skill's WORKFLOW.md (or `work-copilot/WORKFLOW.md` for the Copilot bundle). Invoke the skill to access them.

## Conventions

### Skill directory structure
```
skills/{skill-name}/
  SKILL.md          # required, has name + description frontmatter
  USAGE.md          # required, has When-to-use / When-NOT / Mental model / Pitfalls / Related skills
  *.md              # optional supporting files
```

Additionally, every active routable skill must be documented under
`docs/workflow.md` + its `docs/workflows/` subfolder. `docs/workflow.md` is a
pure **overview/index** that names + links every workflow; the deep per-workflow
detail lives one level down under `docs/workflows/<name>.md` (one file per
workflow). **`docs/workflow.md` + every `docs/workflows/*.md` are GENERATED**
(F000069 Story 2) from the `spec/workflow-spec.md` registry by
`scripts/workflow-spec.sh --render-docs` — the same generate→freshness→audit
primitive README and the test catalog use. A **`CJ_goal_*` workflow
orchestrator** is an `orchestrator`-kind registry entry (ASCII chart + the
granular 4-bullet **Touches** block); every **other** routable skill
(phase-steps, validators, utilities) lives in a `roster`-kind entry rendered to
`docs/workflows/utilities-and-phase-steps.md` (the lighter per-skill shape —
status + source + invoke-when + a compact Touches). The docs are kept in sync by
`validate.sh` **Check 27** (regenerate→diff freshness) + `/CJ_doc_audit` Stage 1,
and the **no-vanish guarantee** (every `CJ_goal_*` orchestrator has an entry)
lives in `workflow-spec.sh --validate` registry-completeness — the replacement
for the retired Checks 15b/15c (a generated doc cannot be missing its
chart/Touches, and the generated index cannot drop a link). Edit the registry,
not the docs — a hand edit is reverted by the next regenerate / Check 27. The
`docs/workflows/` subfolder is part of the portable doc contract: it is required
+ non-empty in an adopting repo (`doc-spec.sh --check-on-disk`'s
`workflows-subfolder` check, registry-gated), and every `docs/workflows/*.md` is
a declared human-doc (no work-item IDs). Either way it must also appear in
`docs/philosophy.md`'s decision tree (the New-skills check is the no-vanish safety
net that guarantees no routable skill becomes undocumented).

### USAGE.md drift detection

`scripts/validate.sh` Check 14 detects USAGE.md content drift: if SKILL.md has a more
recent commit than USAGE.md, the audit flags USAGE.md as stale. The check uses git
commit timestamps (`git log -1 --format=%ct`), not filesystem mtimes — deterministic
across worktrees, fresh clones, and CI runners.

When the drift signal is real, update USAGE.md to match the new SKILL.md behavior
(this is the normal path). When SKILL.md changed cosmetically (typo, version bump,
comment edit) and USAGE.md is still accurate, bump the `last-updated:` field in
USAGE.md's frontmatter to an ISO-8601 second-resolution timestamp and commit:

```bash
sed -i.bak 's/^last-updated:.*/last-updated: "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"/' skills/{name}/USAGE.md && rm skills/{name}/USAGE.md.bak
git add skills/{name}/USAGE.md && git commit -m "docs: verify USAGE.md current for {name}"
```

The ISO-8601 second-resolution timestamp (`2026-06-01T16:25:32Z`) is mandatory, not
a stylistic choice: a date-only override (`2026-06-01`) is a no-op when the existing
`last-updated:` field already shows today's date, sed produces no change, git finds
nothing staged, the commit doesn't happen, drift stays flagged. Second-resolution
makes the override idempotent in the practical sense — two runs in the same second
are pathological and the operator just re-runs.

The real content change makes `git log -1` pick up the new commit so USAGE.md's `%ct`
advances past SKILL.md's. The `last-updated:` field is the audit trail. **Do NOT use
`git commit --allow-empty`** — `git log -1 -- <path>` only returns commits that
touched the path, and empty commits touch no paths.

The pre-commit hook runs validate.sh; Check 14 is **staged-aware**: when USAGE.md
appears in `git diff --cached --name-only` (which it does at the moment `git commit -a`
fires the hook), the check treats USAGE_CT as `date +%s`, so the override commit is
NOT blocked by the very check it is trying to silence. No `--no-verify` needed.

### Template naming
Templates live in `templates/`:
- `templates/CJ_personal-workflow/` — personal-dev work item templates (tracker-*.md, doc-*.md)
- `templates/doc-SKILL-DESIGN.md` — skill authoring template (not tied to a workflow skill)
- `work-copilot/` — Self-contained GitHub Copilot bundle deployed via `scripts/copilot-deploy.py` to non-Claude target repos. Carries its own templates (`work-copilot/templates/*.md`), WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, copilot-artifact-manifests.json, prompts/, and domain/ — no upstream sync. `validate.sh` Error check 10 (`EXPECTED_BUNDLE_FILES` array, 61 entries) enforces every required bundle file is present. Add a new bundle file by appending one entry to that array.

### Template deployment
`skills-deploy install` copies per-skill templates to `~/.claude/templates/{skill-name}/` (global).
Templates resolve from the catalog: `$REPO_ROOT/templates/{skill-name}/` for active skills, or `$REPO_ROOT/{templates_source}/` when the catalog entry sets `templates_source`. Then fall back to `~/.claude/templates/{skill-name}/`.
- Drifted templates and rules are overwritten by default (`skills-deploy install` is treated as a sync from workbench source → `~/.claude/`); pass `--no-overwrite` to preserve deployed copies that differ from source. `--overwrite` is accepted as a no-op for backwards compatibility with pre-v1.6 callers (D000013's post-merge hook, etc.).
- `skills-deploy doctor` reports template health (missing, drifted, orphaned) plus a `--- Shared scripts ---` section reporting deployed `_cj-shared/scripts/*` health (ORPHAN/FAIL/WARN/OK)
- `skills-deploy remove` cleans up templates when no installed skill needs them
- Templates are tracked in the manifest with SHA256 checksums and per-skill ownership

### Catalog format
`skills-catalog.json` is a bare JSON array of skill objects. Each entry has:
name, version, description, source, depends, portability, files, templates, status.
The catalog is for validation only. The plugin system auto-discovers `skills/`.

`status` is a closed enum enforced by `validate.sh`: `active` or `experimental`.

An entry MAY also carry an optional `doc_requirement` string (T000038) —
overrides the shared default skill-MD requirement in the registered-doc audit;
absent ⇒ shared default applies. Tolerated by `validate.sh` (no closed catalog
schema). See `## Registered-doc requirements audit`.

### Frontmatter requirements
Every SKILL.md must have YAML frontmatter with at least `name` and `description`.
`allowed-tools` is recommended for security (restricts which tools the skill can use).

### Personal-native pattern
No $AI_CONTENT_DIR indirection. Work items live at `./work-items/` per repo.
Templates at `~/.claude/templates/`. Upstream skills sync via git pull.

### `.gstack/` vs `work-items/` (parallel design surfaces)

This repo has **two design-intent homes**, in parallel:

- **`.gstack/`** — lateral / exploratory. gstack skills (`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/context-save`) write here. Design exploration, what-ifs, draft plans. Symlinked from `~/.gstack/projects/<slug>/` via `scripts/setup-gstack-symlink.sh` (per-machine setup); see "gstack plans live in this repo" in README.md.
- **`work-items/`** — structured per-feature. The `CJ_personal-workflow` taxonomy (features, defects, user-stories, tasks) with TRACKER + SPEC + TEST-SPEC + lifecycle gates. This is the implementation pipeline; design intent gets re-shaped into a tracked work item via `/CJ_scaffold-work-item`.

Different lifecycles, different surfaces. Don't try to merge them. A typical flow: `/office-hours` produces a design doc in `.gstack/`, then `/CJ_scaffold-work-item` distills it into a `work-items/` entry that drives `/CJ_implement-from-spec` and `/CJ_qa-work-item`.

Machine-local gstack state (sessions, analytics, learnings) is `.gitignore`d under `.gstack/`; everything else under `.gstack/` commits.

## Creating a new skill

To create a new skill, create the directory and files manually (no scaffolding scripts needed):

1. Create `skills/{name}/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: my-skill
   description: "One-line description of what this skill does."
   version: 0.1.0
   allowed-tools:
     - Bash
     - Read
     - Glob
     - Grep
     - AskUserQuestion
   ---
   ```
2. Write the skill instructions below the frontmatter
3. Add a catalog entry to `skills-catalog.json`:
   ```json
   {
     "name": "my-skill",
     "version": "0.1.0",
     "description": "Same as frontmatter description.",
     "source": "local",
     "depends": { "skills": [], "tools": [] },
     "portability": "standalone",
     "files": ["skills/my-skill/SKILL.md"],
     "templates": [],
     "status": "experimental"
   }
   ```
4. Optionally create `skills/{name}/DESIGN.md` for design rationale if the skill is complex enough to warrant a developer-facing doc (template: `templates/doc-SKILL-DESIGN.md`)
5. Create `skills/{name}/USAGE.md` using `templates/doc-SKILL-USAGE.md` and fill in all five required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills)
6. Document the new skill in the right place — `docs/workflow.md` + `docs/workflows/*.md` are GENERATED, so you edit the `spec/workflow-spec.md` registry, NOT the docs (F000069 Story 2). If it is a `CJ_goal_*` **workflow orchestrator**, add an `orchestrator`-kind section to `spec/workflow-spec.md` (the ASCII chart + the four canonical Touches bullets — **Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** / **Docs touched** — each enumerated at the granular named-helper + named-step level). Otherwise (phase-step, validator, or utility) add it to the relevant `roster`-kind section body (`utilities-and-phase-steps` or `utility-audits`). Then run `bash scripts/workflow-spec.sh --render-docs` to regenerate the docs + the index. `workflow-spec.sh --validate` will ERROR if a `CJ_goal_*` skill has no registry entry (the no-vanish guarantee), and `validate.sh` Check 27 will ERROR if the on-disk docs are stale vs the registry. EITHER WAY, also add the skill to `docs/philosophy.md`'s `## Decision tree` (the New-skills check enforces this — it is the no-vanish safety net).
7. Run `./scripts/validate.sh` to verify everything is consistent
8. Use `/ship` to commit and create a PR

## Scripts reference

| Script | What it does | When to run |
|--------|-------------|-------------|
| `scripts/setup.sh` | Bootstrap: clones-or-updates the repo and deploys all skills | First-time install on a new machine |
| `skills-deploy` | Install/remove/relink/doctor skills from this repo into `~/.claude/` (also deploys `rules/*.md` → `~/.claude/rules/`). On `install`, ownership-safely PRUNES orphaned `_cj-shared/scripts/*` shared scripts — manifest-keyed, so a deployed+tracked script whose source counterpart was deleted (e.g. `test-pipeline.sh`/`gate-spec.sh`) is removed + de-tracked, while a hand-placed untracked file is never touched; the summary reports `Pruned: N`. `doctor` surfaces the same orphans (T000051). **Contract seeding (F000069 Story 3):** the new `seed-contracts` subcommand force-generates the three per-repo contracts (`spec/doc-spec.md` + `spec/test-spec.md` + `spec/workflow-spec.md`) into the cwd repo (or `--repo <path>`) via each engine's `--seed`, corruption-guarded (temp→`--validate`→`mv`) + idempotent (present⇒skip); and `install` run from a **consumer** repo ALWAYS seeds it (forced, no flag, git-repo-guarded). The **workbench self-repo is skipped** (worktree-aware data-loss guard, since the workbench authors the real contracts): it matches the manifest `source`/`bundle_path` (the primary identity signal), OR it carries an authored custom overlay (`spec/doc-spec-custom.md` without the auto-marker, or `spec/test-spec-custom.md`) AND a root `skills-catalog.json` (D000036 — the catalog gate is the workbench marker a consumer never ships, so a consumer's hand-authored overlay alone no longer false-positives as the self-repo and skips its adoption). **Contract gate + turnkey adoption (F000069 Story 4 / S000117):** a consumer `install` (and the standalone `install-contract-gate [--remove]`) ALSO **completes adoption** then installs the deterministic **`cj-contract-gate.sh`** pre-commit hook. Adoption (`complete_consumer_adoption`, after seeding, before the hook) makes the repo contract-clean so the FULLY-HARD gate passes from the first commit: it refreshes the generated surfaces (`*-spec.sh --render-docs` → `docs/test-catalog.md` + `docs/workflow.md` + `docs/workflows/`) and auto-declares the seeded/generated docs into an auto-marked `spec/doc-spec-custom.md` overlay (orphans cleared; merged registry re-validated, rolled back if invalid). A **hand-authored** overlay (no auto-marker) is ALSO completed but **APPEND-ONLY** (D000037, via `complete_consumer_adoption_handauthored`): adoption refreshes the same surfaces and splices ONLY the new undeclared orphans as contiguous declaring rows appended under the curated table's `| Doc | Purpose | Requirement |` header — never wholesale-regenerated, so curated rows/prose are preserved and no auto-marker is added (the append is validated + rolled back if it would invalidate the merged registry), closing the gap where a curated-overlay consumer got the gate hook but not the surface render / orphan declaration and its next commit was gate-blocked. The gate is the engine-only Stage-1 subset of `validate.sh` (HARD except a soft `declared-exists` remediation pointing at `/CJ_document-release`; registry-absent ⇒ SKIP); the guarded hook install reuses the shared `cj-hook-lib.sh` `cj_install_hook` (sentinel-aware, back-up-non-workbench, SKIP custom `core.hooksPath`/husky + workbench-self). | After pulling the workbench, or to sync drift; `seed-contracts` to adopt the contracts in a consumer repo; `install-contract-gate` to (re)install/`--remove` the gate hook |
| `validate.sh` | Checks catalog against filesystem | Before every commit |
| `test.sh` | Full test suite (superset of validate) | Before pushing |
| `test-deploy.sh` | Tests `skills-deploy` in isolated temp dirs | When changing `skills-deploy` |
| `eval.sh` | Behavioral eval harness (F000013 V1) — spawns `claude --print` against scratch worktrees per case in `tests/eval/<skill>/<case>/`, validates structured JSON output via `--json-schema`. Per-case `--max-budget-usd 0.50`, aggregate `EVAL_TOTAL_BUDGET_USD` (default $10). | Nightly CI (`.github/workflows/eval-nightly.yml`, 09:17 UTC daily + `workflow_dispatch`) or local manual run |
| `collection-version.sh` | Get/bump/manifest for collection version | Maintainer tool (internal) |
| `doctor.sh` | Diagnoses skill health issues | Periodic checkup |
| `lint-skill.sh` | Checks SKILL.md content quality | After writing a skill |
| `deps.sh` | Shows dependency graph | When changing deps |
| `generate-readme.sh` | Regenerates README.md from catalog | After catalog changes |
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs git hooks (pre-commit validate + post-merge auto-sync) | Auto-run by `setup.sh`; run manually only after a direct `git clone` + `skills-deploy install` (that path does not install hooks) |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle (`work-copilot/`) into a target repo | When setting up a new target repo for Copilot |
| `post-land-sync.sh` | Post-land local sync: resolve `.source` from the manifest, guard (`.source` exists / on `main` / clean tracked tree), `git pull --ff-only` + `skills-deploy install` from `.source`, report `collection_version` before→after. `--dry-run` previews. Closes the gap where a remote `gh pr merge` bypasses the local post-merge auto-sync hook, leaving merged skills uninstalled + the manifest version lagging `.source`. | After `gh pr merge` + verify MERGED + branch cleanup (the merge convention's post-land step) |
| `cj-worktree-cleanup.sh` | Post-run worktree janitor (T000036): the teardown mirror of `cj-worktree-init.sh`. PR-state-gated sweep of landed `cj-(feat\|def\|todo\|task)-*` worktrees (REMOVE only on `PR_STATE ∈ {MERGED,CLOSED}` via `cj-goal-common.sh --phase pr-check` — NOT branch ancestry, this is a squash-merge repo), `git worktree prune`, an orphan-dir sweep (`rm -rf` leftover `cj-*` dirs git no longer tracks — basename-matched so it's symlink-robust, cj-* scoped, registered/current always skipped), + guarded root-`main` refresh. Skips current/locked/dirty/OPEN-PR/no-PR/non-cj. `--dry-run` previews (`WOULD-REMOVE`/`WOULD-SKIP`, mutates nothing); `--caller {feature\|defect\|todo\|task}`. Best-effort — always exits 0; never halts the calling run. | Invoked automatically at each `CJ_goal_*` orchestrator's post-land terminal (feature/defect via `cj-goal-common.sh --phase cleanup`; todo directly). Run `--dry-run` by hand to preview a sweep. |
| `cj-id-claim.sh` | Scaffold-time atomic work-item ID claim (F000048): the 4th ID source for `/CJ_scaffold-work-item` Step 5.1. Atomically claims the next `{F\|S\|T\|D}` ID via `mkdir "$(git rev-parse --git-common-dir)/cj-id-claims/<ID>"` (a compare-and-swap — git worktrees share one `.git`, so the claim is visible to sibling worktrees BEFORE any push), closing the pre-push collision race the 3-source check (local / open-PRs / origin) cannot see. Lazy reaping (TTL + already-on-origin); same-branch reuse keeps re-runs idempotent. Args: `--prefix <F\|S\|T\|D> --floor <N> [--ttl-hours 72] [--dry-run]`. Same-machine/same-clone scope; cross-machine stays covered post-push. | Called by `/CJ_scaffold-work-item` Step 5.1 (fail-soft — scaffold falls back to the 3-source `printf` if the helper is absent). |
| `cj-e2e-gate.sh` | Deterministic build-gate auto-answer VERDICT helper (F000071/S000120, Part A — the dormant foundation the local happy-path E2E harness (`e2e-local.sh`, Part B) drives). `--gate <design-gate\|qa-audit> [--digest <doc:..,test:..>]` → prints exactly one `AUTO=continue\|halt\|inactive`, exit 0. Returns `inactive` UNLESS BOTH `CJ_GOAL_E2E_AUTO=1` AND a `.cj-e2e-sandbox` marker at the repo root AND the gate is in the hardcoded allowlist `{design-gate, qa-audit}`; qa-audit `continue`s ONLY on a fully-green digest (`doc:ok` AND `test:ok`), else `halt`; design-gate `continue`s (feature-only). **Safety:** any non-allowlisted gate id (`ship`/merge/`land`/…) → `inactive` — the seam can NEVER auto-answer a gstack ship/merge/deploy gate. The four `CJ_goal_*` pipelines call it (agent-prose) before the qa-audit checkpoint (design-gate in feature only), generalizing `todo_fix --quiet`'s green-continue: a normal run (no flag/marker) is behavior-unchanged. `.cj-e2e-sandbox` is gitignored + `validate.sh` **Check 29** hard-fails if it is tracked. | Called by the 4 cj_goal pipelines at their build gates (dormant unless the double guard is set — i.e. only under the local-E2E harness). Unit-tested by `tests/cj-e2e-gate.test.sh`. |
| `e2e-local.sh` | Local happy-path E2E harness (F000071/S000121, Part B). Runs a REAL `/CJ_goal_task` build end to end in a throwaway sandbox (a `mktemp` clone + a `.cj-e2e-sandbox` marker + a LOCAL bare origin that accepts push but defeats `gh pr create`), driven unattended through the build gates by the Part-A seam (`cj-e2e-gate.sh`), stopping at the `/ship` boundary, and writes a **materialized report** (`tests/e2e-local/reports/<verb>-<UTC-ts>.md` + a `.json` sibling) whose coverage rows are labelled DETERMINISTIC vs `claude --print` and whose Outcome is DERIVED from real post-run evidence (a new `work-items/tasks/T*/` dir, a non-empty diff, the run's `end_state`) — a row without evidence renders `unverified`, never a false pass. **LOCAL-only:** gated on `CJ_E2E_LOCAL=1` plus gstack + a usable claude login (`ANTHROPIC_API_KEY`, or a `claude auth login` confirmed by a tiny live probe — a stored login is not trusted blindly, since some managed environments report logged-in yet a subprocess 401s) + `claude` + `gh`; with the flag unset or any prerequisite missing it SKIPs (exit 0) so CI + a normal `test.sh` never touch a model. **Safety:** activates only the Part-A seam (allowlist `{design-gate, qa-audit}` — NEVER ship/merge/deploy); the no-remote bare origin is the sole auto-ship backstop. Its deterministic half (SKIP path + `lib/sandbox.sh` + `lib/report.sh`) is unit-tested with no Claude by `tests/e2e-local.test.sh`; `tests/e2e-local/reports/` is gitignored except the committed `EXAMPLE.md`. | Run locally (`CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh`) to prove the whole cj_goal build works end to end; SKIPs cleanly everywhere else. |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Subcommands: `--snooze [hours]`, `--skip <ver>`, `--prompted <session>`, `--should-prompt <session>`. Called from each active skill's preamble. | Auto-invoked from skill preambles. Not a maintainer tool. |
| `doc-spec.sh` | Parse + validate the two-tier doc-spec registry (the doc contract): the GENERAL `spec/doc-spec.md` (byte-identical to `--seed`, never edited in place) merged with the optional `spec/doc-spec-custom.md` overlay (same 3-column Markdown-table grammar — `\| Doc \| Purpose \| Requirement \|`; the overlay always resolves next to the general file). The table IS the registry — `audit_class` is DERIVED from the path (a path under `docs/` or the root `README.md` is a human-doc, else operational), not a declared column; the tier is the file (general vs overlay), not a per-row field. All list subcommands + `--validate` operate on the MERGE; a path duplicated across the two files is a `--validate` error. Subcommands: `--validate` (exit 0 + `OK schema_version=<n>`, else `[doc-sync-no-config]` + exit 1 — incl. a present-but-invalid overlay or a malformed table row / literal `\|` in a cell), `--check-on-disk` (the audit Stage-1 engine: FOUR deterministic conformance checks of the merged registry vs the disk — declared-exists, orphans incl. an undeclared overlay, root-declared, human-doc-ids; `check: <id> — PASS` / `FINDING: stage1/<id>` lines + `CHECKS_RUN=`/`FINDINGS=` tail; probes registry existence BEFORE the parse gates — absent ⇒ `REGISTRY=absent` + exit 0, present-but-invalid ⇒ the `[doc-sync-no-config]` halt), `--list-declared`, `--list-human-docs` (the path-derived human-doc paths), `--expand-whitelist` (the doc-only auto-commit whitelist = merged declared paths + the contract files + `docs/**/*.md`), `--seed` (the portable general file, for self-bootstrap; 3-way byte-identical with `spec/doc-spec.md` + `templates/doc-spec-common.md`). Resolves the registry `spec/doc-spec.md`-then-root via `git rev-parse --show-toplevel`, so a `_cj-shared`-resolved copy parses the cwd repo's registry. Consumed by `validate.sh` Checks 15/16/17/19 + `/CJ_document-release` + `/CJ_doc_audit`. | Auto-invoked by `validate.sh` + `/CJ_document-release` + `/CJ_doc_audit`. |
| `test-spec.sh` | Parse + validate the two-tier test-spec registry (the test contract): the GENERAL `spec/test-spec.md` (the 5 portable rules — tests-discoverable, suite-green, new-code-tested, units-anchored, single-owner; byte-identical to `--seed`) merged with the optional `spec/test-spec-custom.md` units overlay (this repo's one-row-per-verification-unit enumeration: validate checks, test sub-suites, inline families, standalone suites, CI workflows, git hooks). Subcommands: `--validate` (merged schema + closed enums + duplicate-id guard + the test-row source pin + the rendered-field work-item-ID lint; `[test-spec-no-config]` + exit 1 when present-but-invalid), `--list-rules`, `--list-units`, `--list-behaviors`, `--list-behavior-coverage`, `--check-coverage` (the Check 24 engine: forward anchor-grep into each declared source + reverse sweep of live validate banners/comments, `tests/*.test.sh` on disk, workflows, installed hooks + ≥20-token floor `TEST_SPEC_REVERSE_FLOOR` — reverse+floor apply ONLY when `units:` rows exist; a rules-only registry reports "coverage cross-check inactive"; ALSO the behavior-coverage conformance — 6 deterministic checks gated on overlay `behaviors:` existing, INDEPENDENT of the `units:` gate), `--render-docs` (renders the generated human-readable test catalog — `docs/test-catalog.md` index + one `docs/tests/<family>.md` per unit family — deterministically from the merged registry's rendered fields, work-item-IDs masked in anchors; `--render-docs --check` renders to a temp dir + diffs vs on-disk for the freshness gate, the `validate.sh` Check 26 + `/CJ_test_audit` Stage-1 engine), `--check-workflow-coverage` (the Check 28 workflow-coverage gate: forward — every `CJ_goal_*` orchestrator from `workflow-spec.sh --list-orchestrators` has a `level: workflow` behavior whose `workflow:` field names it; reverse — every `level: workflow` behavior resolves to a declared orchestrator; registry-gated skip), `--list-categories` / `--check-structure` / `--seed-docs` (F000074 — the ADDITIVE category-based test contract, coexisting with `units:`/`behaviors:`/`runners:`: `--list-categories` echoes the parsed `categories:` rows [`name`/`category {workflow,CI-push,CI-nightly}`/`command`/`tier {free,paid,local-only}`/`doc`/`purpose`], `--names` for names only, `--category <c>` to filter; `--check-structure` runs the six structural checks a–f — (a) `tests/` folder, (b) one `tests/<category>/` subfolder per DISTINCT declared category (taxonomy V2 `{workflow, CI-push, CI-nightly}`, derived from the `categories:` rows), (c) categories declare their tests, (d) one `docs/tests/<category>/<name>.md` per test, (e) a `docs/tests/index.md` INDEX, (f) each per-test doc CONTAINS the three front-door section headings `## What it is` / `## How to run` / `## Explanation` (F000076 — the deterministic half of the GENERAL per-test-doc front-door rule that lives in `spec/test-spec.md`; Stage 2 judges the content is truthful) — findings-are-the-product, exit 0 always, "category contract not adopted / inactive" when no `categories:` axis; `--seed-docs` idempotently seeds a missing per-test doc stub already carrying the three front-door sections + the INDEX [present ⇒ skip], NEVER moving test scripts — standalone-safe), `--seed`. The overlay carries a third axis alongside `units:`/`gates:` — `behaviors:` (open-world statements of WHAT the software must prove, each with a first-class `level` from the closed enum `{unit, integration, contract, workflow, property}`, plus an optional `workflow:` field on `level: workflow` rows naming the covered `CJ_goal_*` orchestrator) plus `behavior_coverage:` (each behavior linked to a test-bearing `units:` row — e.g. `suite-eval` for a workflow behavior backed by a `tests/eval/` case — + a semantic-evidence source/anchor). A FOURTH axis (F000074) is `categories:` (overlay-only, optional — the PRIMARY axis of the category model: `category → tests`, one row per named test; taxonomy V2 is the closed set `{workflow, CI-push, CI-nightly}` per F000075). An ABSENT registry (neither `spec/test-spec.md` nor root `test-spec.md`) is the distinct `REGISTRY=absent` + exit 0 path — a machine-classifiable skip, never a halt. `REPO_ROOT`/`TEST_SPEC_PATH`/`TEST_SPEC_CUSTOM_PATH` env overrides for temp-dir drills. Consumed by `validate.sh` Check 24 + `/CJ_test_audit` + `tests/test-spec.test.sh`. | Auto-invoked by `validate.sh` + `/CJ_test_audit`. |
| `workflow-spec.sh` | Parse + render the workflow-doc registry (F000069 Story 2): `spec/workflow-spec.md` is the single source of truth for `docs/workflow.md` (the index) + the 6 `docs/workflows/*.md` — a structured-Markdown registry with two entry kinds (`orchestrator` = the 4 `CJ_goal_*`, carrying chart + the 4 Touches axes; `roster` = the 2 free-form roster docs). Subcommands: `--validate` (per-kind required fields + closed `kind` enum + **registry-completeness** — every routable `CJ_goal_*` skill has an `orchestrator` entry, the no-vanish guarantee replacing retired Checks 15b/15c; `[workflow-spec-no-config]` + exit 1 when present-but-invalid), `--list-workflows`, `--list-orchestrators` (orchestrator-kind names only — the registry-sourced list the Check 28 workflow-coverage gate iterates; distinct from `--list-workflows`, which also emits the `roster` entries), `--render-docs` (renders the index + all 6 per-workflow docs deterministically to a normalized template; charts + roster bodies + the index preamble verbatim, work-item-ID-free), `--render-docs --check` (render to a temp dir + diff vs on-disk — the `validate.sh` Check 27 + `/CJ_doc_audit` Stage-1 freshness engine), `--classify`, `--seed` (a minimal valid skeleton — header + contract prose, zero workflow sections, so a consumer repo is vacuously complete). `REPO_ROOT`/`WORKFLOW_SPEC_PATH` env overrides for temp-dir drills. Consumed by `validate.sh` Check 27 + the Check 28 workflow-coverage gate (`--list-orchestrators`) + `/CJ_doc_audit` + `tests/workflow-spec-render.test.sh`. | Auto-invoked by `validate.sh` + `/CJ_doc_audit`. |
| `test-run.sh` | Execute the test contract and report real pass/fail (F000072/S000122 — the executor half of the test contract, companion to the static `test-spec.sh`/`/CJ_test_audit`). Reads the `spec/test-spec-custom.md` `runners:` overlay axis (rows: `id` / `command` / `tier {free,paid,local-only}` / `covers` [runnable families or `all` = `{validate,test,test-deploy,eval,windows-smoke}`, `ci`/`hook` rejected] / optional `platform {any,windows,posix}` / `note`), resolving the registry `spec/`-then-root + `test-spec.sh` sibling→`$REPO_ROOT/scripts`→`_cj-shared`. `--dry-run` prints the run plan (per runner: resolved command, tier, platform guard, covered families + unit count via `test-spec.sh --list-units --with-family`, will-run/skip+reason from the closed skip enum `{tier-not-selected, platform, self-gated}` / family `{no-covering-runner}`); default execute runs only `tier: free` (`--evals` adds paid, `--e2e` adds local-only, `--all` everything), one run per runner, self-gate = rc 0 + first line `^SKIP:`. Writes `tests/test-run/reports/<UTC-ts>.md` + a `.json` ledger (`schema: 1`; per-runner id/command/tier/rc/outcome/covered-families/unit-count/duration + run-level HEAD-SHA/flags/aggregate; JSON via `jq -Rs` through a CR-stripping wrapper). Aggregate `{pass, fail, all-skipped}` derived from evidence (exit 1 on any runner fail; `all-skipped` never rendered `pass`); registry-absent ⇒ `REGISTRY=absent`/exit 0, present-invalid ⇒ `[test-spec-no-config]` passthrough/exit 1, zero-runners ⇒ `SKIP: no runners declared`/exit 0 (no report). `ci`/`hook` appear as family-level ledger rows (`ci-only` / `hook-check`), outside the skip enum. **Category mode (F000074, ADDITIVE; taxonomy V2 per F000075):** `--category <workflow\|CI-push\|CI-nightly>` runs every declared test in that category, and a bare positional NAME runs the single test of that name (reusing the `docs/tests/<category>/<name>.md` name) — selection maps `name → command` via the `categories:` axis, honoring the SAME cost tiers (default free; `paid`/`local-only` ⇒ `skip(tier-not-selected)` without `--evals`/`--e2e`/`--all`), writing a `mode: category` ledger; an unadopted repo reports `category contract not adopted / inactive`, an unknown name / bad category / `--category`+name together ⇒ exit 2. With no `--category` and no name the `runners:` flow runs unchanged. `REPO_ROOT`/`TEST_SPEC_PATH`/`TEST_SPEC_CUSTOM_PATH` overrides for fixture drills. Consumed by `/CJ_test_run`; unit-tested by `tests/test-run.test.sh` (fixture repos only, never the real `test.sh`). | Invoked by `/CJ_test_run`; run `--dry-run` by hand to preview the plan. |

## Update-check mechanism (F000009)

Active skills (`CJ_personal-workflow`, `CJ_system-health`) emit a banner when a newer
collection version is available on `origin/main`. The user is prompted with
Upgrade now / Snooze 24h / Skip this version, then either auto-upgrades via
`git pull --ff-only && skills-deploy install --from-upgrade <old>` or suppresses
the banner via `--snooze` / `--skip` cache state.

State files (`~/.claude/`):
- `.skills-templates.json` — manifest. Field `source` (already populated by every
  install) is read by the check script. No new field added.
- `.skills-templates-update.json` — cache: `checked_at`, `local_version`,
  `remote_version`, `snooze_until`, `skip_version`, `prompted_session`,
  `prompted_at`. Atomic writes via `mktemp` + `mv`.
- `.skills-templates-just-upgraded` — single-shot marker written by
  `skills-deploy install --from-upgrade <old>`. Read once, then unlinked, then
  emitted as `SKILLS_JUST_UPGRADED <old> <new>` by the next skill invocation.

Manual override: `rm ~/.claude/.skills-templates-update.json` forces a re-check
on the next skill invocation. `skills-deploy doctor` surfaces last-check time,
local/remote versions, snooze/skip state.

The script travels with the install: `skills-deploy install` deposits it into the
shared `_cj-shared/scripts/` home (F000049/S1), and a `git pull` of the in-place
checkout propagates updates automatically. **F000049/S4 (S000088)** repointed the
preamble snippet OFF the manifest `.source` read onto that deployed home — so no
skill performs a runtime `.source` reach-back. The snippet in each instrumented
SKILL.md now does:

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

(`skills-update-check` itself still reads the manifest `source` to find the
checkout whose `origin/main` to compare against — under install==clone that
`source` IS the in-place checkout, not a separate clone.)

Out of scope for v1: work-copilot/ Copilot consumers (no preamble surface),
fork-aware detection (`upstream/main` fallback when `origin/main` is missing).

## Doc-sync coverage (F000028/F000029 marker mechanism retired by F000040)

Doc-sync now runs INLINE on every common main-moving path:

- **Orchestrator paths** — each `cj_goal` orchestrator (`/CJ_goal_feature`,
  `/CJ_goal_defect`, `/CJ_goal_todo_fix`) folds doc updates into the same code PR
  at **Step 5.5** (`/CJ_document-release`, after an idempotent pre-doc-sync commit
  and BEFORE the post-sync doc/test audit + the QA-audit checkpoint, all ahead of
  `/ship`; F000064 reorder).
- **`/ship` paths** — `/ship` Step 18 dispatches `/document-release` on every
  invocation, after the push and before the PR exists, so a manual `/ship` still
  lands doc updates in the PR.

**Accepted gap (manually recovered).** The one path NOT auto-covered is a
main-move that bypasses BOTH the orchestrators AND `/ship` — a raw `git push` to
`main`, or a hand-rolled `gh pr create` + `gh pr merge`. This is rare in this
workbench and manually recoverable: run `/document-release` by hand from a
feature branch to fold the drift into a follow-up PR. We accept this gap rather
than keep a post-merge marker mechanism alive for it.

The retired F000028/F000029 mechanism (a `post-merge`/`post-rewrite` git hook
that dropped a per-repo marker JSON under `~/.gstack/`, the reader script that
consumed it, and the preamble AUQ in the orchestrators that surfaced it) was
removed by F000040 once F000036's inline Step 5.5 made it redundant — the marker
AUQ kept firing for drift already folded into the same PR. Operators with
leftover state can safely delete the orphaned marker + cache JSON files under
`~/.gstack/` (inspect via `ls ~/.gstack/`).

## Verification contract (test-spec.md)

**What stops a broken cj_goal change from landing, what rules the verification
surface is held to, and at which layer** lives in ONE two-tier contract: the
GENERAL [`spec/test-spec.md`](spec/test-spec.md) (the five portable `rules[]` +
the four-layer `layers[]` map — both the human-readable table and the machine
source of truth, byte-identical to `test-spec.sh --seed`) plus this repo's
[`spec/test-spec-custom.md`](spec/test-spec-custom.md) overlay (the CHECK-level
`units:` enumeration + the per-mode pipeline-gate `gates:` array). It is the
member of the `spec/doc-spec.md` → `spec/permission-policy.md` →
`spec/test-spec.md` family (the spec-registry files live under `spec/`; each
helper resolves `spec/`-then-root; the doc-spec + test-spec members are
TWO-TIER — a portable general seed plus an optional `spec/*-custom.md` overlay
the parser merges in). (The former `spec/gate-spec.md` member was folded into
this contract by F000063 — its `layers[]` into the general file, its `gates[]`
into the overlay, its `gate-spec.sh` parsing into `scripts/test-spec.sh`.) The
CHECK-level enumeration (which individual checks/tests/workflows/hooks exist,
what each asserts, when each runs) is the overlay's `units:` rows; the per-mode
pipeline-gate halts are its `gates:` array. A third overlay axis (F000066) adds
behavior coverage: `behaviors:` rows are open-world statements of WHAT the
software must prove — each carrying a first-class `level` from the closed enum
`{unit, integration, contract, workflow, property}` — and `behavior_coverage:`
rows link each behavior to a test-bearing `units:` row plus a semantic-evidence
source/anchor. The behavior-coverage conformance (6 deterministic checks in
`test-spec.sh`, surfaced by `--list-behaviors` / `--list-behavior-coverage` and a
`/CJ_test_audit` Stage-2 substance check) is gated on `behaviors:` existing,
INDEPENDENT of the `units:` gate. Both `units:` and `behaviors:` are enforced by `validate.sh`
Check 24 — a MIXED check: validate-the-merge + the HARD coverage cross-check
(forward anchor-grep, reverse live-surface sweep, ≥20-token floor — the check
that makes an unregistered `tests/*.test.sh` a hard failure instead of a silent
skip; both reverse + floor are units-gated so a rules-only consumer repo reports
"inactive", never findings) PLUS the ADVISORY per-mode gate marker-drift
cross-check (absorbed from the retired Check 22). The four layers: **local-hook**
(pre-commit `validate.sh`), **ci** (GitHub Actions), **pipeline-gate** (the
inline orchestrator halts — isolation / design / QA / doc-sync / qa-audit /
ship), and **ratchet** (VERSION / portability-baseline /
USAGE-freshness). "Gate"
means a `pipeline-gate` row; `validate.sh`-as-a-whole is the **ci** layer (a set
of *checks*), never "the gate." Check 24's advisory marker-drift portion
cross-checks every declared literal marker against the four `CJ_goal_*` pipelines
(the `qa-audit` row, order 50, declares the literal `[qa-audit-declined]` in ALL
FOUR modes — the post-sync audit-findings checkpoint, which runs AFTER the
`doc-sync` gate, order 45; F000064 reorder). Each
pipeline's halt-taxonomy names `spec/test-spec.md` as the canonical gate sequence.

## Doc contract (doc-spec.md)

What docs the repo carries — and what each one is for — lives in a TWO-TIER
registry: the GENERAL [`spec/doc-spec.md`](spec/doc-spec.md) (byte-identical to
`doc-spec.sh --seed` — the portable contract, never edited in place) plus this
repo's [`spec/doc-spec-custom.md`](spec/doc-spec-custom.md) overlay. Both tiers
are a 3-column Markdown table (`| Doc | Purpose | Requirement |`) parsed
directly — the table IS the registry. `scripts/doc-spec.sh` merges the two
internally — every consumer sees ONE registry; a path duplicated across the two
files is a validate error. There is no second list: the merged registry is the
source, the prose explains it.

- **Human docs** (path-derived `audit_class: human-doc` — a declared path under
  `docs/` or the root `README.md`) are `docs/philosophy.md`, `docs/workflow.md`
  (the overview/index), `docs/architecture.md`, `docs/reference.md`, the six
  per-workflow files under `docs/workflows/` (`CJ_goal_feature.md`,
  `CJ_goal_task.md`, `CJ_goal_defect.md`, `CJ_goal_todo_fix.md`,
  `utilities-and-phase-steps.md`, `utility-audits.md`), plus the root `README.md`.
  They must exist and carry **no work-item IDs** (`[FSTD]NNNNNN`) — a hard
  `validate.sh` lint (Check 19). The `docs/workflows/` subfolder is mandated +
  non-empty by the portable contract (`doc-spec.sh --check-on-disk`'s
  `workflows-subfolder` check, registry-gated).
- **Operational docs** (every other declared path) are the spec-registry family
  under `spec/` (general: `spec/doc-spec.md`, `spec/test-spec.md`; custom:
  `spec/permission-policy.md`, `spec/doc-spec-custom.md`,
  `spec/test-spec-custom.md`) plus the root `*.md` set
  the repo pins for an external-tool reason: `CLAUDE.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md` (custom), `TODOS.md`. These may reference work items.
- **Config files** stay at root (`skills-catalog.json`, `template-registry.json`,
  `VERSION`) because tooling hardcodes `./` paths to them. Docs under `skills/`,
  `templates/`, `work-copilot/`, `work-items/`, and `tests/` follow their own
  conventions and are out of this contract's scope.

`validate.sh` enforces the contract against the merged registry:
- **Check 15/15a** — declared ⇔ on-disk: every declared doc exists AND every
  `docs/**/*.md` (recursive — including `docs/workflows/`) / `spec/*.md` on disk
  is declared (no orphans).
- **Check 27** — the generated **workflow docs** (`docs/workflow.md` +
  `docs/workflows/*.md`) are in sync with the `spec/workflow-spec.md` registry
  (HARD, registry-gated): regenerate via `workflow-spec.sh --render-docs --check`
  + diff vs on-disk, ERROR on mismatch (mirror of Check 26). Replaces the retired
  shape-only Checks 15b/15c — the no-vanish guarantee (every `CJ_goal_*`
  orchestrator has a registry entry) now lives in `workflow-spec.sh --validate`
  registry-completeness, and the chart + 4-bullet Touches + index links are
  guaranteed by generation.
- **Check 16** — the merged doc-spec registry table validates (`doc-spec.sh
  --validate` — general + overlay + the duplicate-path guard).
- **Check 17** — every root `*.md` on disk is a declared registry path.
- **Check 19** — no work-item IDs in any `human-doc`.
- **Check 24** — the test-spec coverage cross-check (HARD,
  SKIP-when-registry-absent): validates the merged test-spec registry
  (`test-spec.sh --validate`), then every `spec/test-spec-custom.md` unit anchor
  must match LIVE in its declared source (forward), every live validate
  banner/comment, `tests/*.test.sh`
  on disk, workflow and installed hook resolves to exactly one registry row
  (reverse), with a ≥20-token floor — reverse + floor units-gated.
- **Check 26** — the generated **test catalog** is in sync with the registry
  (HARD, registry-gated): regenerates `docs/test-catalog.md` + `docs/tests/*.md`
  to a temp dir via `test-spec.sh --render-docs` and diffs against on-disk, ERROR
  on any mismatch/missing file. The structural mirror of Check 25 (README ↔
  `generate-readme.sh`): the catalog is a GENERATED human-readable view of the
  test registry, never hand-edited. The same freshness check runs as
  `/CJ_test_audit` Stage 1, so the catalog is enforced standalone in any repo.
- **Check 28** — the **workflow-coverage gate** (HARD, registry-gated): every
  declared `CJ_goal_*` orchestrator (`workflow-spec.sh --list-orchestrators`)
  MUST carry a `level: workflow` behavior in `spec/test-spec-custom.md` whose
  `workflow:` field names it (forward), and every `level: workflow` behavior must
  resolve to a declared orchestrator (reverse) — so a documented-but-untested
  workflow cannot ship. Engine: `test-spec.sh --check-workflow-coverage`; also
  surfaced in `/CJ_test_audit` Stage 1 (+ a Stage-2 substance judgment that the
  linked test is a real run, not a hollow prompt). SKIPs when
  `spec/workflow-spec.md` or the test-spec registry is absent; green from birth
  (orchestrators=4, behaviors=4). Each workflow behavior is backed by a real
  Claude-driven eval case (`tests/eval/CJ_goal_*/`) targeting a gstack-independent
  path (task → `halted_at_too_complex`; feature/defect → `dry_run_preview`) — the
  honest `level: workflow` proof; the full happy-path-to-PR E2E is deferred on the
  gstack-in-CI blocker.

Add a repo-specific doc by adding a table row to `spec/doc-spec-custom.md`
(and creating the file) — never by editing the general `spec/doc-spec.md` (it
must stay byte-identical to the seed). A new root `*.md` must be a declared
registry row — the overlay for repo-specific docs, the general file only if
the portable contract adopts it — or Check 17 flags it.

## /CJ_document-release doc audit conventions

`/CJ_document-release` (the inline Step 5.5 doc-sync wrapper) is the keeper of the
doc contract. On every run it reads `doc-spec.md`, self-bootstraps a missing
`doc-spec.md` from the portable Common seed (`doc-spec.sh --seed`), stub-scaffolds
any declared-but-missing doc, derives the doc-only auto-commit whitelist from the
registry, and runs the registered-doc audit (below). The full mechanism reference
lives in [`docs/architecture.md`](docs/architecture.md) `## The doc-spec.md
contract + /CJ_document-release`; the implementation is
`skills/CJ_document-release/SKILL.md`.

### New-skills check

Extract the set of currently-active **routable** skill names (entries with a non-empty `files` array — empty `files` indicates a tooling-only catalog entry like `templates` that owns templates but has no SKILL.md and isn't invocable as a skill):

```
jq -r '.[] | select(.status=="active") | select((.files | length) > 0) | .name' skills-catalog.json
```

For each name returned, grep `docs/philosophy.md` for a case-sensitive literal match within the `## Decision tree` heading + its body up to the next `##` heading. Missing → drift finding (`active skill not in decision tree: <name>`). This check runs on `docs/philosophy.md` only; `docs/architecture.md` deliberately does not duplicate the decision tree (see architecture's `## Decision tree mirror` section).

### Registered-doc requirements audit

The audit answers one general question the hard gates structurally can't: **is
THIS registered doc up to date against ITS declared requirement?** — covering both
the `doc-spec.md` registry docs AND the routable skill `SKILL.md`s. It generalizes
the shape the workbench already had (Check 14 is literally "is USAGE.md up to date
vs its requirement, SKILL.md?" for one doc-pair). The producer is
`/CJ_document-release` Step 6.7.

**The registered set** (both enumerated dynamically; no hardcoded counts):

1. **The registry docs** — every entry in the `doc-spec.md` registry, each
   carrying a `requirement:` value. The doc's requirement is that string. A
   `human-doc` entry also gets the no-work-item-ref check (any `[FSTD][0-9]{6}` →
   `stale: contains work-item refs`).
2. **Routable skill MDs (active OR experimental)** — every skill returned by
   `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json`
   (the `!= "deprecated"` predicate Check 14 + `workflow-spec.sh --validate` use — deliberately BROADER than
   the New-skills check's active-only selector, so the audit covers the whole CJ_
   family; no hardcoded skill count). Each skill's `SKILL.md` is a registered doc;
   its requirement is the skill's optional `doc_requirement` field in
   `skills-catalog.json`, else the shared default below. This group is the one
   workbench-specific half: it reads `skills-catalog.json`, which exists only in a
   repo that ships a skill catalog. It is **guarded** (Step 6.7.2) — in a consumer
   repo with no catalog the skill-MD enumeration skips cleanly (one note, no `jq`
   stderr noise) while group 1 — the registry docs, including the human-doc
   no-work-item-ref lint — still runs. This is the "general by default, custom per
   repo" two-tier contract in practice: the portable half audits any repo, the
   catalog half only kicks in where a catalog exists.

**Shared default skill-MD requirement** (when a skill has no `doc_requirement`):

> The SKILL.md frontmatter `description` and the documented behavior/steps match
> the skill's current implementation; the skill's USAGE.md is current.

A skill MAY declare an optional `doc_requirement` string in its
`skills-catalog.json` entry to OVERRIDE the shared default; absent ⇒ the shared
default applies. The field is tolerated by `validate.sh` (only `status` is a
closed catalog enum). Authoring guidance: do NOT enumerate step numbers in the
string (a skill that gains a step would self-stale a "Step N–Step M" requirement).

**Verdict taxonomy** (one per registered doc):

- `up-to-date` — satisfies its requirement given what the run changed.
- `stale: <one-line why>` — no longer satisfies its requirement.
- `missing-requirement` — the registered doc has no declared requirement. SOFT —
  never a halt.
- `n/a` — registered but out of scope for this run's judgment.

**Surfacing.** The Step 6.7 producer emits a `### Registered-doc requirements`
block (one verdict line per registered doc) to its RESULT AND, in workbench mode
(catalog present), writes it to the gitignored scratch file
`.cj-goal-feature/registered-doc-verdicts.md`. When the skill runs standalone in a
consumer repo with no catalog (`CATALOG_PRESENT=false`) the scratch write is
skipped — that scratch only feeds the cj_goal orchestrator's PR-body surfacing,
which doesn't exist standalone, and `.cj-goal-feature/` is not gitignored in a
consumer repo, so writing it would leave a stray untracked artifact. The
positive line `Registered-doc requirements: all current` is emitted ONLY when
every verdict is `up-to-date`. The block lands in the PR body's `## Documentation`
section via a post-`/ship` `gh pr edit` step in all three cj_goal orchestrators
(`/CJ_goal_feature` **Step 4.6**, `/CJ_goal_defect` **Step 9.5**,
`/CJ_goal_todo_fix` **Step 5.6**; best-effort, never halts; the Step 6.7 producer
is shared by all three).

**Posture.** ADVISORY, agent-judged, NEVER a hard gate. No upstream gstack
modification. The one HARD doc gate is `validate.sh` Check 19 (no work-item IDs in
human-docs); everything else here is advisory. Root convention docs are covered as
`operational` registry entries (the no-ref lint does not apply to them). Upstream
`/document-release` already audits the README/CHANGELOG/CLAUDE.md set per-file.

## TODOS.md hygiene conventions

`TODOS.md` is the workbench's active backlog. `/CJ_suggest` ranks rows from it for
`/CJ_goal_todo_fix` and `/loop /CJ_goal_todo_fix`. Two known auto-marking gaps require explicit
agent action — get either wrong and `/loop /CJ_goal_todo_fix` will keep re-picking
already-addressed rows, burning iterations on idempotent skips.

### When TODOS rows get auto-marked DONE

`/ship` Step 14 (TODOS.md auto-update) reads the diff + commit history of the
PR being shipped and marks completed rows automatically. Works correctly for the
common case: a `/CJ_goal_todo_fix`-shipped PR with `[via /CJ_goal_todo_fix]` (or the legacy `[via /CJ_goal]` marker for pre-v4.0.0 PRs) in the commit message
and `Closes TODOS:NNN` in the body. Self-marks the row in the same PR's diff.
Five recent PRs (#108, #111, #112, #113, #116) all auto-marked their TODOs
without operator intervention.

### Edge case 1: partial closes need explicit `PARTIAL` annotation

When a PR addresses only part of a multi-item TODO (commit message says
"(TODOS:NNN partial)"), `/ship` Step 14 conservatively skips the auto-mark
because its confidence threshold isn't met. This is correct behavior — a partial
fix shouldn't claim full closure. Operator action: hand-edit the row to add a
PARTIAL annotation matching the existing convention at TODOS.md line 73:

```markdown
### ~~Original heading (Pn, Sz)~~ PARTIAL — sub-item (X) closed by T000NNN (vX.Y.Z, PR #NNN): one-line description of what shipped. **Remaining:** sub-items (Y), (Z) — what still needs to ship.
```

The `~~strikethrough~~` is required so `/CJ_suggest` excludes the row. Without
it, `/loop /CJ_goal_todo_fix` will keep ranking the row as active and burning iterations
to discover the work is already partly done. Example: TODOS:108 (T000027 / PR
#114) — addressed sub-item (b) only; (a)/(c)/(d) deferred.

### When in doubt

Before invoking `/loop /CJ_goal_todo_fix`, scan `TODOS.md` for active-looking rows whose
T-IDs / PR numbers match recent merged commits. Any unstrikethrough'd row whose
work has already shipped is a hygiene debt that will steal a `/loop` iteration.
Cleanup PRs are cheap (single-file edit, no code, ~5 min through `/ship`).

## Schedule-friendly drain

`/CJ_goal_todo_fix --quiet` (v4.3.0+) is the cron-eligible mode. It suppresses
the Phase 3 summary AUQ + start-of-run banner and emits `scheduled_run: true`
into telemetry; cron output stays empty when there's nothing to report.
Pair with `/schedule` (upstream gstack) to drain the backlog at a fixed cadence:

```
/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am
```

At 9am every day, drains up to 3 easy-fix TODOs into PRs that queue for review.
**Caveat: /ship Gate #2 still fires per drained TODO** — schedule prepares PRs
for review at your cadence, not autonomous merge. Operator approves each child
PR via `gh pr list` + the diff-review AUQ at their own cadence (the autonomy
ceiling per F000021). Halt-on-red entries are still written to tracker journals;
the loop still STOPS on red regardless of `--quiet`. The /schedule integration
is doc-only — no schema-binding lock-in; the /schedule skill (upstream gstack)
remains independent and the cron-pattern above is just a copy-paste example.
