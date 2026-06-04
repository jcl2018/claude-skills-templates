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

## Skill routing

Routing rules are deployed globally to `~/.claude/rules/skill-routing.md` by
`./scripts/skills-deploy install`. Source of truth: [`rules/skill-routing.md`](rules/skill-routing.md).

The CJ_ skill family in this workbench is fronted by two intent-named verbs:
`/CJ_goal_feature` (build a feature: topic → reviewable PR) and `/CJ_goal_defect`
(fix a bug: description → shipped fix). Supporting skills: workflow validator
(/CJ_personal-workflow), per-phase skills (/CJ_scaffold-work-item,
/CJ_implement-from-spec, /CJ_qa-work-item, /CJ_document-release) that the
orchestrators dispatch as leaf subagents, and standalone utilities
(/CJ_system-health, /CJ_suggest, /CJ_goal_todo_fix, /CJ_repo-init). /CJ_goal_todo_fix bridges
TODOS.md rows to the shipping pipeline in one keystroke — see
`skills/CJ_goal_todo_fix/SKILL.md`.
/CJ_repo-init verifies/scaffolds the per-repo prerequisites (cj-document-release.json,
CJ-DOC-RELEASE.md, TODOS.md, work-items/) that the CJ_ family needs to run in a given repo.
/CJ_document-release (F000036) is the inline doc-sync wrapper invoked at
Step 5.5 of every cj_goal orchestrator (between QA pass and `/ship`) — folds
doc updates into the same code PR rather than chasing them post-merge.

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

**Auto-worktree on main (F000025 + F000027):** the three current CJ_goal_* orchestrators auto-create a `.claude/worktrees/cj-{prefix}-{ts}-{pid}/` worktree when invoked from `main` with arguments — main checkout stays clean and parallel sessions don't collide. The three orchestrators and their prefixes:

- `/CJ_goal_feature "<topic>"` → `cj-feat-*` (worktree phase: `cj-goal-common.sh --mode feature` → `cj-worktree-init.sh --caller feature`)
- `/CJ_goal_defect "<bug description>"` → `cj-def-*` (`cj-goal-common.sh --mode defect` → `cj-worktree-init.sh --caller defect`)
- `/CJ_goal_todo_fix [<T-ID> | "<fragment>"]` (single-TODO mode) → `cj-todo-*` (`cj-worktree-init.sh --caller todo`)

Conductor-managed sessions (already inside a worktree) detect + no-op. Opt out of the worktree with `--no-worktree`; opt out of the pre-build skills-sync (below) with `--no-sync`. Drain mode (`/CJ_goal_todo_fix --max-drain N`) creates one worktree per drained TODO inside `scripts/drain-one-todo.sh`. Helper: `scripts/cj-worktree-init.sh`; tests: `tests/cj-worktree-init.test.sh`.

**Pre-build base-freshness + skills-sync (F000045):** before a build starts, two fail-soft forks make sure it runs against current trunk + current skills. Neither ever halts the orchestrator — a guard refusal, a divergence, or an offline network all degrade to "proceed on what we have."

- **Fork 1 — base-freshness (in the worktree phase).** Inside `cj-worktree-init.sh`, just before `git worktree add`, when on `main`/`master` with an existing `origin/<branch>` ref, the helper fail-soft fetches and fast-forwards local `main` to the origin tip so the new worktree branches off current trunk. The outcome rides the `note` field of the `created` JSON emit: `ff'd N commits` (was behind), `local main diverged from origin; building on local main` (diverged — no ff, no halt, local commits never dropped), or `freshness skipped (offline)` (fetch failed / no origin ref). Skipped under `--dry-run`. Runs even under `--no-sync` (it is independent of Fork 2). Tests: `tests/cj-worktree-init.test.sh`.
- **Fork 2 — pre-build skills-sync (a `cj-goal-common.sh --phase sync` step the orchestrator runs BEFORE the worktree block).** Delegates to `post-land-sync.sh`'s guarded pull+install-from-`.source` core so installed skills match trunk at build start (without the worktree-invoked-install foreign-owned-skill skip). Fail-soft exactly like `pr-check`: a guard refusal (`.source` missing / not a git repo / off-main / dirty tracked tree) or an offline pull emits `PHASE_RESULT=skipped` (exit 0), never failed. `--no-sync` short-circuits to `skipped` BEFORE any install (the operator's opt-out for the heavy global-state install + latency); `--dry-run` forwards to `post-land-sync.sh --dry-run`. Stdout fields: `SYNC_RAN`, `VERSION_BEFORE`, `VERSION_AFTER`, `PHASE_RESULT`. Tests: `tests/cj-goal-common-sync.test.sh`.

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

Additionally, every active routable skill must be documented in one of two
places (T000037): a **`CJ_goal_*` workflow orchestrator** gets a section with an
ASCII workflow chart in `doc/WORKFLOWS.md` (enforced by `scripts/validate.sh`
Check 15b); every **other** routable skill (phase-steps, validators, utilities)
goes in the `doc/ARCHITECTURE.md` `## Component skills (non-workflow roster)`.
Either way it must also appear in `doc/PHILOSOPHY.md`'s decision tree (the
F000030 New-skills check is the no-vanish safety net that guarantees no routable
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
6. Document the new skill in the right place (T000037): if it is a `CJ_goal_*` **workflow orchestrator**, add a section with a fenced ASCII workflow chart + a `**Touches:**` block to `doc/WORKFLOWS.md` (use `templates/doc-WORKFLOWS-section.md` as a starting point) — Check 15b will ERROR if a `CJ_goal_*` skill's section is missing or lacks a chart. Otherwise (phase-step, validator, or utility) add a compact line to the `doc/ARCHITECTURE.md` `## Component skills (non-workflow roster)`. EITHER WAY, also add the skill to `doc/PHILOSOPHY.md`'s `## Decision tree` (the New-skills check enforces this — it is the no-vanish safety net).
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
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs git hooks (pre-commit validate + post-merge auto-sync) | Auto-run by `setup.sh`; run manually only after a direct `git clone` + `skills-deploy install` (that path does not install hooks) |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle (`work-copilot/`) into a target repo | When setting up a new target repo for Copilot |
| `post-land-sync.sh` | Post-land local sync: resolve `.source` from the manifest, guard (`.source` exists / on `main` / clean tracked tree), `git pull --ff-only` + `skills-deploy install` from `.source`, report `collection_version` before→after. `--dry-run` previews. Closes the gap where a remote `gh pr merge` bypasses the local post-merge auto-sync hook, leaving merged skills uninstalled + the manifest version lagging `.source`. | After `gh pr merge` + verify MERGED + branch cleanup (the merge convention's post-land step) |
| `cj-worktree-cleanup.sh` | Post-run worktree janitor (T000036): the teardown mirror of `cj-worktree-init.sh`. PR-state-gated sweep of landed `cj-(feat\|def\|todo)-*` worktrees (REMOVE only on `PR_STATE ∈ {MERGED,CLOSED}` via `cj-goal-common.sh --phase pr-check` — NOT branch ancestry, this is a squash-merge repo), `git worktree prune`, an orphan-dir sweep (`rm -rf` leftover `cj-*` dirs git no longer tracks — basename-matched so it's symlink-robust, cj-* scoped, registered/current always skipped), + guarded root-`main` refresh. Skips current/locked/dirty/OPEN-PR/no-PR/non-cj. `--dry-run` previews (`WOULD-REMOVE`/`WOULD-SKIP`, mutates nothing); `--caller {feature\|defect\|todo}`. Best-effort — always exits 0; never halts the calling run. | Invoked automatically at each `CJ_goal_*` orchestrator's post-land terminal (feature/defect via `cj-goal-common.sh --phase cleanup`; todo directly). Run `--dry-run` by hand to preview a sweep. |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Subcommands: `--snooze [hours]`, `--skip <ver>`, `--prompted <session>`, `--should-prompt <session>`. Called from each active skill's preamble. | Auto-invoked from skill preambles. Not a maintainer tool. |

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

The script lives in the user's clone at `$source/scripts/skills-update-check` —
no symlink, no copy, no `~/.claude/bin/`. `git pull` propagates updates
automatically. The preamble snippet in each instrumented SKILL.md does:

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

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

## Doc placement convention (root vs doc/)

Human-readable **explanation** docs live in `doc/` and are registered in the
tracked-doc/ manifest (enforced by `validate.sh` Check 15 — see the `### Tracked
doc/ files manifest` section below). Root-level `*.md` is limited to the allowlist
below: each entry is pinned at the repo root for an external-tool or operational
reason, not because it is "explanation" content. **Config files** stay at root
(`skills-catalog.json`, `cj-document-release.json`, `template-registry.json`,
`VERSION`) because tooling hardcodes `./` paths to them — the convention documents
that placement but adds no config-file enforcement in v1. Docs under `skills/`,
`templates/`, `work-copilot/`, `work-items/`, and `tests/` follow their own
conventions (per-skill USAGE.md, template naming, the work-item taxonomy) and are
out of this convention's scope.

This allowlist and F000034's tracked-doc/ manifest are symmetric — together they
partition the top-level doc surface: a new explanation doc goes to `doc/` + a
tracked-doc manifest entry (Check 15 catches an unregistered `doc/` file); a new
root `*.md` must be justified + added to the allowlist below with a `reason:`
(Check 17 catches an un-allowlisted root file). Drift on either side fails
`validate.sh`.

Two load-bearing constraints on the YAML block below (stated here in prose,
deliberately OUTSIDE the fence): (1) the block must contain **no `#`-leading
comment lines** — Check 17's parser disarms on any line starting with `#`, so a
mid-block comment would silently drop every entry below it; (2) the `### Tracked
root docs allowlist` heading text is **matched literally** by Check 17 — renaming
it parses to an empty allowlist, which cascades to an orphan ERROR for every root
`*.md` (it fails loudly, never silently passes, but the heading is load-bearing).

### Tracked root docs allowlist
- path: README.md
  reason: GitHub renders it as the repo landing page
- path: CLAUDE.md
  reason: Claude Code auto-loads ./CLAUDE.md; moving to doc/ breaks auto-load
- path: CHANGELOG.md
  reason: /ship + /document-release write ./CHANGELOG.md (keep-a-changelog convention)
- path: CONTRIBUTING.md
  reason: GitHub surfaces it from root / docs/ / .github/ (not doc/)
- path: TODOS.md
  reason: operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14
- path: CJ-DOC-RELEASE.md
  reason: canonical /CJ_document-release contract; sits beside its machine sidecar cj-document-release.json at root and is presence-checked by /CJ_repo-init

## /document-release workbench audit conventions

> Canonical contract: the full, reader-facing `/CJ_document-release` contract —
> wrapper flow, the doc-only auto-commit whitelist gate, the
> `cj-document-release.json` schema, the registered-doc audit, and a
> declaration-site index — lives in [`CJ-DOC-RELEASE.md`](CJ-DOC-RELEASE.md) at
> the repo root. The blocks below (`### Tracked doc/ files manifest` + its
> `requirement:` strings, `### Reporting`) are the runtime-parsed machine surface
> (read by `validate.sh` Check 15a and the `/CJ_document-release` Step 6.7 `awk`)
> and stay verbatim and in-place here; CJ-DOC-RELEASE.md documents + indexes them.

This workbench keeps two NAMED audit surfaces under `doc/`: `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md`. They are not "any other `.md` files" — they are the explanation + mechanism-reference docs that the operator reads to understand the workbench, and `/document-release` MUST audit them for skill-routing drift on every run. The drift class is active skills that ship without an entry in `doc/PHILOSOPHY.md ## Decision tree`.

`/document-release` reads this section as project context at Step 2. The audit rides that existing behavior; no upstream skill modification.

### New-skills check

Extract the set of currently-active **routable** skill names (entries with a non-empty `files` array — empty `files` indicates a tooling-only catalog entry like `templates` that owns templates but has no SKILL.md and isn't invocable as a skill):

```
jq -r '.[] | select(.status=="active") | select((.files | length) > 0) | .name' skills-catalog.json
```

For each name returned, grep `doc/PHILOSOPHY.md` for a case-sensitive literal match within the `## Decision tree` heading + its body up to the next `##` heading. Missing → drift finding (`active skill not in decision tree: <name>`). This check runs on `doc/PHILOSOPHY.md` only; `doc/ARCHITECTURE.md` deliberately does not duplicate the decision tree (see ARCHITECTURE's `## Decision tree mirror` section).

### Tracked doc/ files manifest

Every `*.md` file under `doc/` MUST be registered in this manifest with an `audit_class`. `validate.sh` Check 15 fires ERROR for any orphan file (in `doc/` but not in the manifest) and for any manifest entry pointing to a missing file. Adding a new doc/ file is intentional; declaring its audit class is the cost of admission.

```yaml
- path: doc/PHILOSOPHY.md
  audit_class: skill-routing-drift
  owner: F000030 — workbench-level overview + decision tree
  requirement: "`## Decision tree` lists every active routable skill (matches the New-skills check); the overview + design principles reflect the current CJ_ skill family and the two delivery surfaces."
- path: doc/ARCHITECTURE.md
  audit_class: skill-routing-drift
  owner: F000030 — mechanism reference
  requirement: "`## Component skills (non-workflow roster)` lists every non-workflow active routable skill; each mechanism section matches the current load-bearing scripts OR skill steps (cj-goal-common.sh phases, doc-sync, F000037 config, the registered-doc audit, work-copilot)."
- path: doc/WORKFLOWS.md
  audit_class: workflow-completeness
  owner: F000034 / T000037 — workflow-only doc (the cj_goal orchestrator chains) with ASCII charts + Touches blocks
  requirement: "Has a `### <name>` section for every `CJ_goal_*` orchestrator, each with an ASCII chart + a Touches block reflecting the current chain."
```

`audit_class` enum (closed):

- `skill-routing-drift` — F000030 retired-skill + new-skills check (already applied to PHILOSOPHY.md + ARCHITECTURE.md). Section above.
- `workflow-completeness` — every `CJ_goal_*` workflow orchestrator has a section in doc/WORKFLOWS.md with an ASCII chart. Check 15b enforces (re-scoped by T000037 to the `CJ_goal_*` prefix; component skills live in doc/ARCHITECTURE.md's roster, guarded by the PHILOSOPHY decision-tree New-skills check).
- `static-reference` — file is hand-written reference content; audit only checks the file exists (Check 15a's `missing-from-disk` half). Reserved for future docs whose drift criteria the author hasn't worked out yet.
- `auto-generated` — file is regenerated by a script; audit checks `script-output == on-disk content`. Reserved; v1 has no entries.

`/document-release` reads this manifest as project context (the existing F000030 pattern at Step 2) and surfaces drift findings in the PR body's `## Documentation` section under a new `### Doc/ manifest drift` subheading, alongside the existing `### Skill-routing drift` subheading.

### Reporting

Drift findings surface in the PR body's `## Documentation` section under a new `### Skill-routing drift` subheading. One finding per line. If no findings, emit a single positive line (`Skill-routing drift: none`) so reviewers can tell the audit ran cleanly versus skipped silently.

Doc/ manifest drift findings (Check 15) appear under a sibling `### Doc/ manifest drift` subheading, same one-per-line shape. Positive line: `Doc/ manifest drift: none`.

Registered-doc requirement verdicts appear under a third sibling subheading `### Registered-doc requirements` (one verdict line per registered doc; positive line `Registered-doc requirements: all current` when every verdict is up-to-date). See `## Registered-doc requirements audit` below for the verdict taxonomy and the producer. All three subheadings are emitted by the same producer — the `/CJ_document-release` wrapper's Step 6.7 (the first real producer for these PR-body subheadings; the `### Skill-routing drift` / `### Doc/ manifest drift` blocks were convention-only prose until Job 2 wired Step 6.7, and emitting those two there remains OPTIONAL in v1 — `### Registered-doc requirements` is the Job-2 deliverable).

## cj-document-release.json convention (F000037)

> The reader-facing schema reference + the wider doc-release contract live in
> [`CJ-DOC-RELEASE.md`](CJ-DOC-RELEASE.md). This section is retained as the
> SKILL.md prose anchor + the in-repo schema record; it is not the canonical
> read.

`/CJ_document-release` reads a strict-required per-repo config from
`cj-document-release.json` at repo root. The file declares which docs the
auto-commit whitelist gate honors AND which categories the `--docs <token>`
flag resolves against.

Schema (v1):

```json
{
  "schema_version": 1,
  "whitelist_patterns": ["glob", ...],
  "categories": { "name": ["glob", ...], ... }
}
```

Globs use `**` for any-depth recursion (`doc/**/*.md`). `validate.sh` Check 16
enforces schema when the file exists. CJ_document-release HALTs with
`[doc-sync-no-config]` when the file is missing/invalid/schema_version-unsupported.

The workbench's own JSON seeds with the F000036 hardcoded set + workbench-specific
paths (doc/**, templates/doc-*). Other repos adopting `/CJ_document-release`
declare their own.

Per-verb overrides (`categories_by_verb`), audit_class enum mirror from F000030's
tracked-doc/ manifest, --docs negation, and multi-repo federation are all
DEFERRED to future v2 schema bumps.

## Registered-doc requirements audit (Job 2 / T000038)

> The reader-facing summary of this audit (registered set, verdict taxonomy,
> surfacing, posture) is consolidated in [`CJ-DOC-RELEASE.md`](CJ-DOC-RELEASE.md).
> This section is retained as the SKILL.md prose anchor + the authoritative
> mechanism reference for the Step 6.7 producer.

This convention DOCUMENTS what the `/CJ_document-release` wrapper's **Step 6.7**
does — it is the operator-facing reference for that producer step, NOT a
directive to an unwired upstream. (Mechanism reality: upstream gstack
`/document-release` does not ingest CLAUDE.md `## …audit conventions` sections as
audit directives — its Step 2 is a fixed set of per-file heuristics. The audit
below is produced by the workbench-owned wrapper, which already reads
`cj-document-release.json` + builds a project-context block; Step 6.7 is the
natural extension point. No upstream gstack modification.)

The audit answers one general question the hard gates structurally can't: **is
THIS registered doc up to date against ITS declared requirement?** — covering
both the `doc/*.md` files AND the active routable skill `SKILL.md`s. It
generalizes the shape the workbench already had (Check 14 is literally "is
USAGE.md up to date vs its requirement, SKILL.md?" for one doc-pair).

### The registered set

1. **Tracked-doc/ files** — every entry in the `### Tracked doc/ files manifest`
   block above, each carrying a bespoke `requirement:` value (the Job-2 extension
   of the F000034 manifest). The doc's requirement is that `requirement:` string.
2. **Routable skill MDs (active OR experimental)** — every skill returned by
   `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json`
   (the `!= "deprecated"` predicate Check 14/15b use — deliberately BROADER than
   the F000030 New-skills check's active-only selector, so the audit covers the
   whole CJ_ family, not just the 3 active skills; no hardcoded skill count). Each
   skill's `SKILL.md` is a registered doc; its requirement is the skill's optional
   `doc_requirement` field in `skills-catalog.json`, else the shared default below.

### Shared default skill-MD requirement

When a skill has no `doc_requirement`, its requirement is:

> The SKILL.md frontmatter `description` and the documented behavior/steps match
> the skill's current implementation; the skill's USAGE.md is current.

### Optional `doc_requirement` catalog field

A skill MAY declare an optional `doc_requirement` string in its
`skills-catalog.json` entry to OVERRIDE the shared default with a bespoke
requirement; absent ⇒ the shared default applies. The field is tolerated by
`validate.sh` (there is no closed catalog schema — only `status` is a closed
enum; Check 1/2 only check SKILL.md presence + frontmatter). Authoring guidance:
do NOT enumerate step numbers in the string (a skill that gains a new step would
self-stale a "Step N–Step M" requirement). See the `### Catalog format` note and
the `CJ_document-release` exemplar entry.

### Verdict taxonomy

Per registered doc, one verdict:

- `up-to-date` — satisfies its requirement given what the run changed.
- `stale: <one-line why>` — no longer satisfies its requirement.
- `missing-requirement` — the registered doc has no declared requirement (a
  tracked-doc/ manifest entry lacking a `requirement:` child). SOFT — never a halt.
- `n/a` — registered but out of scope for this run's judgment.

### Surfacing

The Step 6.7 producer emits a `### Registered-doc requirements` block (one
verdict line per registered doc) to its RESULT AND writes it to the gitignored
scratch file `.cj-goal-feature/registered-doc-verdicts.md`. The positive line
`Registered-doc requirements: all current` is emitted ONLY when every verdict is
`up-to-date` (so reviewers can tell the audit ran cleanly vs skipped). The block
lands in the PR body's `## Documentation` section under `### Registered-doc
requirements` via a post-`/ship` `gh pr edit` step in all three cj_goal
orchestrators (`/CJ_goal_feature` **Step 4.6**, `/CJ_goal_defect` **Step 9.5**,
`/CJ_goal_todo_fix` **Step 5.6**; best-effort, never halts; the Step 6.7 producer
is shared by all three). The defect/todo surfacing was wired by T000039 (Job-2.1);
because they auto-land, the PR-body verdict has a short review window (the verdict
also lands in the run output + the scratch file + `/ship` Gate #2).

### Producer note

Step 6.7 is the producer. The existing F000030 `### Skill-routing drift` /
`### Doc/ manifest drift` PR-body subheadings had NO wired producer until Job 2 —
they were aspirational prose applied ad-hoc by a knowledgeable agent. The same
Step 6.7 is their natural home, but emitting those two there is OPTIONAL in v1;
`### Registered-doc requirements` is the Job-2 deliverable.

### Posture

ADVISORY, agent-judged, NEVER a hard gate. No upstream gstack modification; no
new hard `validate.sh` check in v1 (a registered doc lacking a requirement gets a
soft `missing-requirement` verdict, not a CI error — hardening requirement-presence
is a Job-2.1 follow-up). Scope: the 3 tracked-doc/ files + the active routable
skill MDs. Root convention docs (the README / CHANGELOG / CLAUDE.md category,
plus `CJ-DOC-RELEASE.md` — a root `.md` is in neither the catalog-skill set nor
the tracked-doc/ manifest) are out of scope for the registered-doc audit;
`CJ-DOC-RELEASE.md`'s enforcement is `/CJ_repo-init` presence. Upstream
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
