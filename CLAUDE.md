# CLAUDE.md

## What this repo is

A skill development workbench for Claude Code. Contains 3 custom skills (CJ_personal-workflow, CJ_company-workflow, CJ_system-health), a template library for doc-first development, a standalone GitHub Copilot bundle (`work-copilot/`) mirroring CJ_company-workflow validation for non-Claude machines, and tooling to validate, test, and distribute skills.

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

The CJ_ skill family in this workbench includes top-level pipelines (/CJ_run,
/CJ_personal-pipeline), workflow validators (/CJ_personal-workflow,
/CJ_company-workflow), per-phase skills (/CJ_scaffold-work-item,
/CJ_implement-from-spec, /CJ_qa-work-item), and standalone utilities
(/CJ_system-health, /CJ_suggest, /CJ_goal). /CJ_goal bridges TODOS.md rows to
the shipping pipeline in one keystroke — see `skills/CJ_goal/SKILL.md`.

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
- **CJ_company-workflow** (deprecated, source-of-truth for `work-copilot/`): `deprecated/CJ_company-workflow/templates/` + `deprecated/CJ_company-workflow/company-artifact-manifests.json`

Scaffolding conventions live in each skill's WORKFLOW.md. Invoke the skill to access them.

## Conventions

### Skill directory structure
```
skills/{skill-name}/
  SKILL.md          # required, has name + description frontmatter
  *.md              # optional supporting files
```

### Template naming
Templates live in `templates/` (active skills) and `deprecated/{name}/templates/` (deprecated skills):
- `templates/CJ_personal-workflow/` — personal-dev work item templates (tracker-*.md, doc-*.md)
- `deprecated/CJ_company-workflow/templates/` — company work item templates (tracker-*.md, doc-*.md). Deprecated skill; source-of-truth for the `work-copilot/` byte-mirror, kept in-tree but skipped by `skills-deploy install` unless `--include-deprecated` is passed.
- `templates/doc-SKILL-DESIGN.md` — skill authoring template (not tied to a workflow skill)
- `work-copilot/` — GitHub Copilot bundle byte-mirrored from upstream. Templates (`work-copilot/templates/*.md`) mirror `deprecated/CJ_company-workflow/templates/*.md`; `WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, `fixtures/` mirror their `deprecated/CJ_company-workflow/` counterparts. `validate.sh` Error check 10 (`MIRROR_SPECS` array) enforces byte-identity sync across all 7 mirror entries. Adding a new mirror dir is one new line in the `MIRROR_SPECS` array. Bundle-only files with no upstream counterpart (e.g. F000015 pipeline prompts like `prompts/qa.prompt.md`) are covered by `validate.sh` Error check 10b (`EXPECTED_BUNDLE_FILES` array) — distinct from 10 because it catches "file deleted / never shipped" drift, not byte-identity drift. Extend the array by one line as each F000015 child story ships.

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
| `setup-hooks.sh` | Installs pre-commit hook | Once per clone |
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
