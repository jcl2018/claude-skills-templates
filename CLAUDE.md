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
GNU-only `date -d`. The `windows-latest` Git Bash CI job
(`.github/workflows/windows.yml`) gates every PR; run the same checks locally
with `bash scripts/windows-smoke.sh`. Full feature:
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
/CJ_doc_audit, /CJ_test_audit). /CJ_goal_todo_fix bridges
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
checkpoint AUQ every cj_goal pipeline surfaces before doc-sync.
/CJ_document-release is the inline doc-sync wrapper invoked at
Step 5.5 of every cj_goal orchestrator (between the QA pass + checkpoint and
`/ship`) — folds
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

Conductor-managed sessions (already inside a worktree) detect + no-op. Opt out of the worktree with `--no-worktree`; opt out of the pre-build skills-sync (below) with `--no-sync`. Drain mode (`/CJ_goal_todo_fix --max-drain N`) creates one worktree per drained TODO inside `scripts/drain-one-todo.sh`. Helper: `scripts/cj-worktree-init.sh`; tests: `tests/cj-worktree-init.test.sh`.

**Pre-build base-freshness + skills-sync (F000045):** before a build starts, two fail-soft forks make sure it runs against current trunk + current skills. Neither ever halts the orchestrator — a guard refusal, a divergence, or an offline network all degrade to "proceed on what we have."

- **Fork 1 — base-freshness (in the worktree phase).** Inside `cj-worktree-init.sh`, just before `git worktree add`, when on `main`/`master` with an existing `origin/<branch>` ref, the helper fail-soft fetches and fast-forwards local `main` to the origin tip so the new worktree branches off current trunk. The outcome rides the `note` field of the `created` JSON emit: `ff'd N commits` (was behind), `local main diverged from origin; building on local main` (diverged — no ff, no halt, local commits never dropped), or `freshness skipped (offline)` (fetch failed / no origin ref). Skipped under `--dry-run`. Runs even under `--no-sync` (it is independent of Fork 2). Tests: `tests/cj-worktree-init.test.sh`.
- **Fork 2 — pre-build skills-sync (a `cj-goal-common.sh --phase sync` step the orchestrator runs BEFORE the worktree block).** Delegates to `post-land-sync.sh`'s guarded pull+install-from-`.source` core so installed skills match trunk at build start (without the worktree-invoked-install foreign-owned-skill skip). Fail-soft exactly like `pr-check`: a guard refusal (`.source` missing / not a git repo / off-main / dirty tracked tree) or an offline pull emits `PHASE_RESULT=skipped` (exit 0), never failed. `--no-sync` short-circuits to `skipped` BEFORE any install (the operator's opt-out for the heavy global-state install + latency); `--dry-run` forwards to `post-land-sync.sh --dry-run`. Stdout fields: `SYNC_RAN`, `VERSION_BEFORE`, `VERSION_AFTER`, `PHASE_RESULT`. Tests: `tests/cj-goal-common-sync.test.sh`.

**Pre-ship portability gate (F000051 / S000091):** a 6th `cj-goal-common.sh`
phase — `--phase portability-audit` — that the three CJ_goal_* orchestrators run
**after the Step 5.5 doc-sync handler and immediately before `/ship`** (feature
`pipeline.md` / defect `pipeline.md` Step 5.7; todo `SKILL.md` Step 5.7, called
with `--mode feature` like its `--phase sync`). It resolves the engine via
`resolve_portability_engine()` (sibling-in-scriptdir → manifest `.source`, the
same idiom as `resolve_worktree_helper` — NOT the `_cj-shared` idiom; the engine
finds its own catalog via `git rev-parse`), runs `scripts/cj-portability-audit.sh`
under `PORTABILITY_STRICT=1`, parses `FINDINGS=` (skills-with-findings) +
`SKILLS_AUDITED=` (total), and emits `PHASE`/`MODE`/`FINDINGS`/`SKILLS_AUDITED`/
`VERDICT_LINE`/`PHASE_RESULT`. **Unlike Fork 1/2 it is NOT fully fail-soft: a real
finding HALTS.** `PHASE_RESULT=findings` (non-zero exit) ⇒ the orchestrator HALTs
with `[portability-red]` / end_state `halted_at_portability` BEFORE any PR is
created (the verdict + first finding land in the halt journal with `next_action=`
/ `resume_cmd=` / `pr_url=N/A` / `raw_output_path=`); `PHASE_RESULT=ok` ⇒ the
clean `VERDICT_LINE` is written to `.cj-goal-feature/portability-verdict.md` and
spliced into the PR body's `## Documentation` section (a `### Portability` line
alongside the registered-doc verdicts) by the existing Step 4.6 / 9.5 / 5.6
surfacing; `PHASE_RESULT=skipped` (engine absent — a broken install, NOT a
finding) ⇒ a visible note + continue (fail-soft, mirroring `validate.sh` Check
18's "SKIP: engine absent"). `--dry-run` emits the schema and runs nothing. The
catalog baseline is clean (`FINDINGS=0`), so the strict gate is green today AND a
free regression ratchet (any finding is by definition new). This is cj_goal-scoped
enforcement; `validate.sh` Check 18 stays advisory globally (a separate decision).
`scripts/drain-one-todo.sh` is NOT modified — the gate is orchestrator-layer.
Tests: `tests/cj-goal-common-portability.test.sh` + the `--phase portability-audit`
integration block in `scripts/test.sh`.

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

Additionally, every active routable skill must be documented in `docs/workflow.md`:
a **`CJ_goal_*` workflow orchestrator** gets a section under
`## Orchestrators` with an ASCII workflow chart + a granular 4-bullet **Touches**
block (both enforced by `scripts/validate.sh` Check 15b); every **other**
routable skill (phase-steps, validators, utilities) gets an entry under
`docs/workflow.md` `## Utilities & phase-step skills` (the lighter per-skill shape —
status + source + invoke-when + a compact Touches; not Check-enforced).
Either way it must also appear in `docs/philosophy.md`'s decision tree (the
New-skills check is the no-vanish safety net that guarantees no routable
skill becomes undocumented).

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
- `skills-deploy doctor` reports template health (missing, drifted, orphaned)
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
6. Document the new skill in the right place: if it is a `CJ_goal_*` **workflow orchestrator**, add a section under `docs/workflow.md` `## Orchestrators` with a fenced ASCII workflow chart + a `**Touches:**` block (use `templates/doc-WORKFLOWS-section.md` as a starting point). The Touches block MUST carry all four canonical bullets — **Skills dispatched** / **Steps · phases** / **Scripts · tools · shell** / **Docs touched** — each enumerated at the granular named-helper + named-step level; Check 15b will ERROR if a `CJ_goal_*` skill's section is missing, lacks a chart, or is missing any of the four anchored Touches bullets. Otherwise (phase-step, validator, or utility) add an entry under `docs/workflow.md` `## Utilities & phase-step skills` (the lighter per-skill shape — `### <skill>` heading + **Status** + **Source** + **Invoke when** + a compact **Touches**; no chart, no 4-bullet Touches, not Check-enforced). EITHER WAY, also add the skill to `docs/philosophy.md`'s `## Decision tree` (the New-skills check enforces this — it is the no-vanish safety net).
7. Run `./scripts/validate.sh` to verify everything is consistent
8. Use `/ship` to commit and create a PR

## Scripts reference

| Script | What it does | When to run |
|--------|-------------|-------------|
| `setup.sh` | Bootstrap: clones-or-updates the repo and deploys all skills | First-time install on a new machine |
| `skills-deploy` | Install/remove/relink/doctor skills from this repo into `~/.claude/` (also deploys `rules/*.md` → `~/.claude/rules/`) | After pulling the workbench, or to sync drift |
| `validate.sh` | Checks catalog against filesystem | Before every commit |
| `test.sh` | Full test suite (superset of validate) | Before pushing |
| `test-deploy.sh` | Tests `skills-deploy` in isolated temp dirs | When changing `skills-deploy` |
| `eval.sh` | Behavioral eval harness (F000013 V1) — spawns `claude --print` against scratch worktrees per case in `tests/eval/<skill>/<case>/`, validates structured JSON output via `--json-schema`. Per-case `--max-budget-usd 0.50`, aggregate `EVAL_TOTAL_BUDGET_USD` (default $10). | Nightly CI (`.github/workflows/eval-nightly.yml`, 09:17 UTC daily + `workflow_dispatch`) or local manual run |
| `collection-version.sh` | Get/bump/manifest for collection version | Maintainer tool (internal) |
| `doctor.sh` | Diagnoses skill health issues | Periodic checkup |
| `lint-skill.sh` | Checks SKILL.md content quality | After writing a skill |
| `deps.sh` | Shows dependency graph | When changing deps |
| `generate-readme.sh` | Regenerates README.md from catalog | After catalog changes |
| `generate-doc-views.sh` | Regenerates the generated doc views: `docs/doc-general.md` + `docs/doc-custom.md` from the MERGED doc-spec registry (`spec/doc-spec.md` + the `spec/doc-spec-custom.md` overlay, via `doc-spec.sh --render general\|custom`). `--output-dir <dir>` (default `docs`). Idempotent (no timestamps). The views are generated, not hand-maintained — `validate.sh` Check 23 fails if either drifts from the registry. | After registry changes (add/edit a doc-spec general or overlay entry) |
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs git hooks (pre-commit validate + post-merge auto-sync) | Auto-run by `setup.sh`; run manually only after a direct `git clone` + `skills-deploy install` (that path does not install hooks) |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle (`work-copilot/`) into a target repo | When setting up a new target repo for Copilot |
| `post-land-sync.sh` | Post-land local sync: resolve `.source` from the manifest, guard (`.source` exists / on `main` / clean tracked tree), `git pull --ff-only` + `skills-deploy install` from `.source`, report `collection_version` before→after. `--dry-run` previews. Closes the gap where a remote `gh pr merge` bypasses the local post-merge auto-sync hook, leaving merged skills uninstalled + the manifest version lagging `.source`. | After `gh pr merge` + verify MERGED + branch cleanup (the merge convention's post-land step) |
| `cj-worktree-cleanup.sh` | Post-run worktree janitor (T000036): the teardown mirror of `cj-worktree-init.sh`. PR-state-gated sweep of landed `cj-(feat\|def\|todo\|task)-*` worktrees (REMOVE only on `PR_STATE ∈ {MERGED,CLOSED}` via `cj-goal-common.sh --phase pr-check` — NOT branch ancestry, this is a squash-merge repo), `git worktree prune`, an orphan-dir sweep (`rm -rf` leftover `cj-*` dirs git no longer tracks — basename-matched so it's symlink-robust, cj-* scoped, registered/current always skipped), + guarded root-`main` refresh. Skips current/locked/dirty/OPEN-PR/no-PR/non-cj. `--dry-run` previews (`WOULD-REMOVE`/`WOULD-SKIP`, mutates nothing); `--caller {feature\|defect\|todo\|task}`. Best-effort — always exits 0; never halts the calling run. | Invoked automatically at each `CJ_goal_*` orchestrator's post-land terminal (feature/defect via `cj-goal-common.sh --phase cleanup`; todo directly). Run `--dry-run` by hand to preview a sweep. |
| `cj-id-claim.sh` | Scaffold-time atomic work-item ID claim (F000048): the 4th ID source for `/CJ_scaffold-work-item` Step 5.1. Atomically claims the next `{F\|S\|T\|D}` ID via `mkdir "$(git rev-parse --git-common-dir)/cj-id-claims/<ID>"` (a compare-and-swap — git worktrees share one `.git`, so the claim is visible to sibling worktrees BEFORE any push), closing the pre-push collision race the 3-source check (local / open-PRs / origin) cannot see. Lazy reaping (TTL + already-on-origin); same-branch reuse keeps re-runs idempotent. Args: `--prefix <F\|S\|T\|D> --floor <N> [--ttl-hours 72] [--dry-run]`. Same-machine/same-clone scope; cross-machine stays covered post-push. | Called by `/CJ_scaffold-work-item` Step 5.1 (fail-soft — scaffold falls back to the 3-source `printf` if the helper is absent). |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Subcommands: `--snooze [hours]`, `--skip <ver>`, `--prompted <session>`, `--should-prompt <session>`. Called from each active skill's preamble. | Auto-invoked from skill preambles. Not a maintainer tool. |
| `doc-spec.sh` | Parse + validate the two-tier doc-spec registry (the doc contract): the GENERAL `spec/doc-spec.md` (byte-identical to `--seed`, never edited in place) merged with the optional `spec/doc-spec-custom.md` overlay (same fenced-yaml grammar, `section: custom` entries; the overlay always resolves next to the general file). All list subcommands + `--validate` operate on the MERGE; a path duplicated across the two files is a `--validate` error. Subcommands: `--validate` (exit 0 + `OK schema_version=<n>`, else `[doc-sync-no-config]` + exit 1 — incl. a present-but-invalid overlay), `--check-on-disk` (the audit Stage-1 engine: six deterministic conformance checks of the merged registry vs the disk — declared-exists, orphans incl. an undeclared overlay, root-declared, human-doc-ids, front-table, views-render table-block vs fresh `--render`; `check: <id> — PASS` / `FINDING: stage1/<id>` lines + `CHECKS_RUN=`/`FINDINGS=` tail; probes registry existence BEFORE the parse gates — absent ⇒ `REGISTRY=absent` + exit 0, present-but-invalid ⇒ the `[doc-sync-no-config]` halt), `--list-declared`, `--list-human-docs`, `--list-front-table-docs` (the `front_table: required` paths consumed by Check 20 — `front_table` is now a portable seed field), `--render general\|custom` (a Markdown table of the merged `section: common` / `section: custom` rows — `--render custom` therefore reads the overlay, plus any legacy in-file custom rows), `--expand-whitelist` (the doc-only auto-commit whitelist = merged declared paths + the contract files + `docs/**/*.md`), `--seed` (the portable general file, for self-bootstrap; 3-way byte-identical with `spec/doc-spec.md` + `templates/doc-spec-common.md`). Resolves the registry `spec/doc-spec.md`-then-root via `git rev-parse --show-toplevel`, so a `_cj-shared`-resolved copy parses the cwd repo's registry. Consumed by `validate.sh` Checks 15/16/17/19/20/23 + `/CJ_document-release` + `/CJ_doc_audit`. | Auto-invoked by `validate.sh` + `/CJ_document-release` + `/CJ_doc_audit`. |
| `test-spec.sh` | Parse + validate the two-tier test-spec registry (the test contract): the GENERAL `spec/test-spec.md` (the 5 portable rules — tests-discoverable, suite-green, new-code-tested, units-anchored, single-owner; byte-identical to `--seed`) merged with the optional `spec/test-spec-custom.md` units overlay (this repo's one-row-per-verification-unit enumeration: validate checks, test sub-suites, inline families, standalone suites, CI workflows, git hooks). Subcommands: `--validate` (merged schema + closed enums + duplicate-id guard + the test-row source pin + the rendered-field work-item-ID lint; `[test-spec-no-config]` + exit 1 when present-but-invalid), `--list-rules`, `--list-units`, `--check-coverage` (the Check 24 engine: forward anchor-grep into each declared source + reverse sweep of live validate banners/comments, `tests/*.test.sh` on disk, workflows, installed hooks + ≥20-token floor `TEST_SPEC_REVERSE_FLOOR` — reverse+floor apply ONLY when `units:` rows exist; a rules-only registry reports "coverage cross-check inactive"), `--seed`. An ABSENT registry (neither `spec/test-spec.md` nor root `test-spec.md`) is the distinct `REGISTRY=absent` + exit 0 path — a machine-classifiable skip, never a halt. `REPO_ROOT`/`TEST_SPEC_PATH`/`TEST_SPEC_CUSTOM_PATH` env overrides for temp-dir drills. Consumed by `validate.sh` Check 24 + `/CJ_test_audit` + `tests/test-spec.test.sh`. | Auto-invoked by `validate.sh` + `/CJ_test_audit`. |

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
  at **Step 5.5** (`/CJ_document-release`, between QA pass and `/ship`).
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

## Verification contract (gate-spec.md)

**What stops a broken cj_goal change from landing, and at which layer** lives in
ONE file, [`spec/gate-spec.md`](spec/gate-spec.md) — both the human-readable map
(prose + a four-layer summary table + an ASCII diagram + a division-of-labor) and
the machine source of truth (a fenced `yaml` registry of `layers[]` + `gates[]`,
parsed by `scripts/gate-spec.sh`). It is the third member of the `spec/doc-spec.md` →
`spec/permission-policy.md` → `spec/gate-spec.md` → `spec/test-spec.md` family
(the spec-registry files live under `spec/`; each helper resolves
`spec/`-then-root; the doc-spec + test-spec members are TWO-TIER — a portable
general seed plus an optional `spec/*-custom.md` overlay the parser merges in).
gate-spec owns the LAYER question; the CHECK-level enumeration (which
individual checks/tests/workflows/hooks exist, what each asserts, when each
runs) lives in the test-spec member's overlay, `spec/test-spec-custom.md`
(`units:` rows in the predecessor registry's row shape, kept verbatim), enforced by `validate.sh`
Check 24 (validate-the-merge + coverage cross-check: forward anchor-grep,
reverse live-surface sweep, ≥20-token floor — the check that makes an
unregistered `tests/*.test.sh` a hard failure instead of a silent skip; both
reverse + floor are units-gated so a rules-only consumer repo reports
"inactive", never findings). The four layers: **local-hook**
(pre-commit `validate.sh`), **ci** (GitHub Actions), **pipeline-gate** (the
inline orchestrator halts — isolation / design / QA / qa-audit / doc-sync /
portability / ship), and **ratchet** (VERSION / portability-baseline /
USAGE-freshness). "Gate"
means a `pipeline-gate` row; `validate.sh`-as-a-whole is the **ci** layer (a set
of *checks*), never "the gate." `validate.sh` Check 22 (advisory) cross-checks
every declared literal marker against the four `CJ_goal_*` pipelines (the
`qa-audit` row, order 45, declares the literal `[qa-audit-declined]` in ALL
FOUR modes — the post-QA audit-findings checkpoint). Each
pipeline's halt-taxonomy names `gate-spec.md` as the canonical gate sequence.

## Doc contract (doc-spec.md)

What docs the repo carries — and what each one is for — lives in a TWO-TIER
registry: the GENERAL [`spec/doc-spec.md`](spec/doc-spec.md) (byte-identical to
`doc-spec.sh --seed` — the portable contract, never edited in place) plus this
repo's [`spec/doc-spec-custom.md`](spec/doc-spec-custom.md) overlay (the
`section: custom` rows). `scripts/doc-spec.sh` merges the two internally —
every consumer sees ONE registry; a path duplicated across the two files is a
validate error. There is no second list: the merged registry is the source,
the prose explains it.

- **Human docs** (`audit_class: human-doc`) live under `docs/`
  (`docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`) plus the
  root `README.md`. They must exist
  and carry **no work-item IDs** (`[FSTD]NNNNNN`) — a hard `validate.sh` lint
  (Check 19).
- **Operational docs** (`audit_class: operational`) are the spec-registry family
  under `spec/` (general: `spec/doc-spec.md`, `spec/test-spec.md`; custom:
  `spec/gate-spec.md`, `spec/permission-policy.md`, `spec/doc-spec-custom.md`,
  `spec/test-spec-custom.md`) plus the root `*.md` set
  the repo pins for an external-tool reason: `CLAUDE.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md` (custom), `TODOS.md`. These may reference work items.
- **Config files** stay at root (`skills-catalog.json`, `template-registry.json`,
  `VERSION`) because tooling hardcodes `./` paths to them. Docs under `skills/`,
  `templates/`, `work-copilot/`, `work-items/`, and `tests/` follow their own
  conventions and are out of this contract's scope.

`validate.sh` enforces the contract against the merged registry:
- **Check 15/15a** — declared ⇔ on-disk: every declared doc exists AND every
  `docs/*.md` / `spec/*.md` on disk is declared (no orphans).
- **Check 15b** — `docs/workflow.md` has a section for every `CJ_goal_*`
  orchestrator (ASCII chart + a 4-bullet Touches block).
- **Check 16** — the merged doc-spec registry schema validates (`doc-spec.sh
  --validate` — general + overlay + the duplicate-path guard).
- **Check 17** — every root `*.md` on disk is a declared registry path.
- **Check 19** — no work-item IDs in any `human-doc`.
- **Check 20** — every `front_table: required` doc (today `docs/philosophy.md`,
  `docs/workflow.md` — the field is part of the portable seed schema, optional,
  enforced only where present) opens with a summary table BEFORE
  its first `## ` heading (registry-driven via `doc-spec.sh
  --list-front-table-docs`).
- **Check 23** — the generated views (`docs/doc-general.md`, `docs/doc-custom.md`)
  are regenerated from the merged registry into a temp dir and diffed; any drift
  is a hard error (run `scripts/generate-doc-views.sh`).
- **Check 24** — the test-spec coverage cross-check (HARD,
  SKIP-when-registry-absent): validates the merged test-spec registry
  (`test-spec.sh --validate`), then every `spec/test-spec-custom.md` unit anchor
  must match LIVE in its declared source (forward), every live validate
  banner/comment, `tests/*.test.sh`
  on disk, workflow and installed hook resolves to exactly one registry row
  (reverse), with a ≥20-token floor — reverse + floor units-gated.

Add a repo-specific doc by adding a registry entry to `spec/doc-spec-custom.md`
(and creating the file) — never by editing the general `spec/doc-spec.md` (it
must stay byte-identical to the seed). A new root `*.md` must be a declared
registry entry — `custom` (overlay) for repo-specific docs, `common` only if
the portable contract adopts it — or Check 17 flags it. Flag a doc to require
a leading summary table by adding `front_table: required` to its registry
entry — Check 20 then enforces it.

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
   (the `!= "deprecated"` predicate Check 14/15b use — deliberately BROADER than
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
