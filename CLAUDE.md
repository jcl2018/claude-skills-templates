# CLAUDE.md

## What this repo is

A skill development workbench for Claude Code. Contains 2 custom skills (CJ_personal-workflow, CJ_system-health), a template library for doc-first development, a self-contained GitHub Copilot bundle (`work-copilot/`) carrying the work-item template + validation set for non-Claude machines, and tooling to validate, test, and distribute skills.

## Quick start

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates
./scripts/validate.sh          # check repo health
./scripts/test.sh              # run full test suite
```

## Skill routing

Routing rules are deployed globally to `~/.claude/rules/skill-routing.md` by
`./scripts/skills-deploy install`. Source of truth: [`rules/skill-routing.md`](rules/skill-routing.md).

The CJ_ skill family in this workbench includes top-level pipelines (/CJ_goal_run,
/CJ_personal-pipeline), workflow validator (/CJ_personal-workflow), per-phase
skills (/CJ_scaffold-work-item, /CJ_implement-from-spec, /CJ_qa-work-item), and
standalone utilities (/CJ_system-health, /CJ_suggest, /CJ_goal_todo_fix).
/CJ_goal_todo_fix bridges TODOS.md rows to the shipping pipeline in one
keystroke — see `skills/CJ_goal_todo_fix/SKILL.md`.
Legacy aliases /CJ_run and /CJ_goal remain through v4.x (deprecation banner + delegation;
removed in v5.0.0).

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

**Auto-worktree on main (F000025):** `/CJ_goal_run` and `/CJ_goal_todo_fix` (single-TODO mode) auto-create `.claude/worktrees/cj-{run|todo}-{ts}-{pid}/` when invoked from `main` with arguments — main checkout stays clean and parallel sessions don't collide. Conductor-managed sessions (already inside a worktree) detect + no-op. Opt out with `--no-worktree`. Drain mode (`/CJ_goal_todo_fix --max-drain N`) creates one worktree per drained TODO inside `scripts/drain-one-todo.sh`. Helper: `scripts/cj-worktree-init.sh`; tests: `tests/cj-worktree-init.test.sh`.

**Worktree cleanup:** This repo's day-to-day work happens inside a git worktree under
`.claude/worktrees/{name}/`, while the parent repo at the root has `main` checked out.
`gh pr merge --delete-branch` does a local `git checkout main` to clean up; in a worktree
that errors with `'main' is already checked out`. The remote merge succeeds anyway, but
the remote branch is NOT deleted. Workaround (only after verifying MERGED above):

```bash
gh api -X DELETE "repos/jcl2018/claude-skills-templates/git/refs/heads/<branch>"
```

Run this after the merge to actually delete the remote branch.

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
  *.md              # optional supporting files
```

### Template naming
Templates live in `templates/` (active skills) and `deprecated/{name}/templates/` (deprecated skills, when any exist):
- `templates/CJ_personal-workflow/` — personal-dev work item templates (tracker-*.md, doc-*.md)
- `templates/doc-SKILL-DESIGN.md` — skill authoring template (not tied to a workflow skill)
- `work-copilot/` — Self-contained GitHub Copilot bundle deployed via `scripts/copilot-deploy.py` to non-Claude target repos. Carries its own templates (`work-copilot/templates/*.md`), WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, copilot-artifact-manifests.json, prompts/, and domain/ — no upstream sync. `validate.sh` Error check 10 (`EXPECTED_BUNDLE_FILES` array, 61 entries) enforces every required bundle file is present. Add a new bundle file by appending one entry to that array.

### Deprecated skills convention
Skills with `status: deprecated` in `skills-catalog.json` live under `deprecated/{name}/` instead of `skills/{name}/`. The catalog is the source of truth for paths — consumer scripts (`skills-deploy`, `validate.sh`, `test.sh`) derive `dirname(files[0])` for the source root and an optional `templates_source` field for the templates source. Future relocations are a one-line catalog change. See `deprecated/README.md` for what belongs there and what doesn't.

### Template deployment
`skills-deploy install` copies per-skill templates to `~/.claude/templates/{skill-name}/` (global).
Templates resolve from the catalog: `$REPO_ROOT/templates/{skill-name}/` for active skills, or `$REPO_ROOT/{templates_source}/` when the catalog entry sets `templates_source` (e.g., `deprecated/{name}/templates/`). Then fall back to `~/.claude/templates/{skill-name}/`.
- Drifted templates and rules are overwritten by default (`skills-deploy install` is treated as a sync from workbench source → `~/.claude/`); pass `--no-overwrite` to preserve deployed copies that differ from source. `--overwrite` is accepted as a no-op for backwards compatibility with pre-v1.6 callers (D000013's post-merge hook, etc.).
- `skills-deploy doctor` reports template health (missing, drifted, orphaned)
- `skills-deploy remove` cleans up templates when no installed skill needs them
- Templates are tracked in the manifest with SHA256 checksums and per-skill ownership

### Catalog format
`skills-catalog.json` is a bare JSON array of skill objects. Each entry has:
name, version, description, source, depends, portability, files, templates, status.
The catalog is for validation only. The plugin system auto-discovers `skills/`.

`status` is a closed enum enforced by `validate.sh`: `active`, `experimental`, or `deprecated`.
Entries with `status: deprecated` stay in the repo (e.g. as upstream truth for byte-mirrored
bundles like `work-copilot/`) but are skipped by `scripts/skills-deploy install` with a
WARN line. Pass `--include-deprecated` to install them anyway. `skills-deploy doctor`
reports deprecated skills as INFO, not WARN.

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
4. Optionally create `skills/{name}/DESIGN.md` using `templates/doc-SKILL-DESIGN.md`
5. Run `./scripts/validate.sh` to verify everything is consistent
6. Use `/ship` to commit and create a PR

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

### Edge case 2: multi-PR bundles via `/CJ_goal_run` need a post-bundle cleanup PR

`/CJ_goal_run`'s Branch (b) auto-iterate ships per-child PRs against `origin/main`
without bundling them in a single `/ship` invocation. `/ship` Step 14 sees only
each child's narrow diff and has no cross-PR view of which TODOs the bundle as
a whole closes. Result: TODOS rows that the bundle addresses end up unmarked
even after every child has merged. Operator action after the last child PR
merges: ship a small `chore: TODOS.md post-bundle cleanup for F000NNN` PR that
hand-edits the addressed rows to add `~~strikethrough~~ DONE — closed by
S000NNN (vX.Y.Z, PR #NNN)` annotations. Example: PR #119 (v3.6.2) cleaned up
TODOS:142 + :167 after PR #117 + #118 shipped the F000020 polish bundle.

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
