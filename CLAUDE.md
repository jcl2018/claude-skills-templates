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

The CJ_ skill family in this workbench is fronted by two intent-named verbs:
`/CJ_goal_feature` (build a feature: topic → reviewable PR) and `/CJ_goal_defect`
(fix a bug: description → shipped fix). Supporting skills: `/CJ_personal-pipeline`
(internal scaffold→impl→qa engine), workflow validator (/CJ_personal-workflow),
per-phase skills (/CJ_scaffold-work-item, /CJ_implement-from-spec,
/CJ_qa-work-item), and standalone utilities (/CJ_system-health, /CJ_suggest,
/CJ_goal_todo_fix). /CJ_goal_todo_fix bridges TODOS.md rows to the shipping
pipeline in one keystroke — see `skills/CJ_goal_todo_fix/SKILL.md`.

`/CJ_goal_run` + `/CJ_goal_auto` are **DEPRECATED** alias shims (F000027 two-verb
refactor; sunset v6.0.0) that print a banner then route to `/CJ_goal_feature`.
`/cj_goal_feature` + `/cj_goal_defect` are also **DEPRECATED** alias shims
(F000031 casing-fix follow-up; sunset v6.0.0) that print a banner then route to
the uppercase canonicals `/CJ_goal_feature` + `/CJ_goal_defect` for family-name
consistency. `/CJ_goal_investigate` is a **DEPRECATED** alias shim (F000027
closure, sunset v6.0.0) routing non-D-id args to `/CJ_goal_defect` and rejecting
bare D-id args (`^D[0-9]{6}$`). Do not use any of these five for new work; they
stay installable via `skills-deploy install --include-deprecated` so in-flight
pipelines finish.

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
- ~~`/CJ_goal_investigate <D-id|fragment>` → `cj-inv-*` (`cj-worktree-init.sh --caller investigate`)~~ **DEPRECATED** (F000027 closure, sunset v6.0.0; investigate is now a thin alias shim routing to `/CJ_goal_defect`; the `cj-inv-*` prefix remains reachable only via `skills-deploy install --include-deprecated`).

Conductor-managed sessions (already inside a worktree) detect + no-op. Opt out with `--no-worktree`. Drain mode (`/CJ_goal_todo_fix --max-drain N`) creates one worktree per drained TODO inside `scripts/drain-one-todo.sh`. Helper: `scripts/cj-worktree-init.sh`; tests: `tests/cj-worktree-init.test.sh`.

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
  USAGE.md          # required, has When-to-use / When-NOT / Mental model / Pitfalls / Related skills
  *.md              # optional supporting files
```

### USAGE.md drift detection

`scripts/validate.sh` Check 14 detects USAGE.md content drift: if SKILL.md has a more
recent commit than USAGE.md, the audit flags USAGE.md as stale. The check uses git
commit timestamps (`git log -1 --format=%ct`), not filesystem mtimes — deterministic
across worktrees, fresh clones, and CI runners.

When the drift signal is real, update USAGE.md to match the new SKILL.md behavior
(this is the normal path). When SKILL.md changed cosmetically (typo, version bump,
comment edit) and USAGE.md is still accurate, bump the `last-updated:` field in
USAGE.md's frontmatter and commit:

```bash
sed -i.bak 's/^last-updated:.*/last-updated: "'"$(date +%Y-%m-%d)"'"/' skills/{name}/USAGE.md && rm skills/{name}/USAGE.md.bak
git add skills/{name}/USAGE.md && git commit -m "docs: verify USAGE.md current for {name}"
```

This is a real content change (one frontmatter line bumped), so `git log -1` picks up
the new commit and USAGE.md's `%ct` advances past SKILL.md's. The `last-updated:` field
is the audit trail — it records when the operator confirmed USAGE.md was still current.
**Do NOT use `git commit --allow-empty`** — `git log -1 -- <path>` only returns commits
that touched the path, and empty commits touch no paths, so they don't advance `%ct`.

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
4. Optionally create `skills/{name}/DESIGN.md` for design rationale if the skill is complex enough to warrant a developer-facing doc (template: `templates/doc-SKILL-DESIGN.md`)
5. Create `skills/{name}/USAGE.md` using `templates/doc-SKILL-USAGE.md` and fill in all five required H2 sections (When to use / When NOT to use / Mental model / Common pitfalls / Related skills)
6. Run `./scripts/validate.sh` to verify everything is consistent
7. Use `/ship` to commit and create a PR

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
| `setup-hooks.sh` | Installs git hooks (pre-commit validate + post-merge auto-sync + post-merge/post-rewrite doc-sync trigger) | Auto-run by `setup.sh`; run manually only after a direct `git clone` + `skills-deploy install` (that path does not install hooks) |
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

## Doc-sync check mechanism (F000028 follow-up)

The two `cj_goal` orchestrator preambles (`/CJ_goal_feature` + `/CJ_goal_defect`)
emit a `DOC_SYNC_PENDING <marker-path>` line when F000028's
`post-merge` / `post-rewrite` git hook has dropped a doc-sync marker since the
operator's last pull. (`/CJ_goal_investigate`'s preamble is no longer in
the live trigger surface — the skill is now a DEPRECATED alias shim under
`deprecated/CJ_goal_investigate/` and only emits the line when installed via
`--include-deprecated`.) The orchestrator interprets the line and surfaces an AUQ
asking whether to run `/document-release` inline now, snooze, or skip — closing
the loop F000028 opened (the hook writes markers; this mechanism consumes them).

**Novel pattern callout.** F000009's `skills-update-check` prints
`SKILLS_UPGRADE_AVAILABLE` as a user-facing banner with no AUQ. F000029's
`skills-doc-sync-check` goes further: the script output (`DOC_SYNC_PENDING <path>`)
drives an orchestrator AUQ. The script's job is detection only ("is there a
marker, and if so, print its path"); the SKILL.md prose owns the AUQ template,
branch-aware option ordering (B on main, A on a feature branch — upstream
`/document-release` Step 1 hard-aborts on the base branch with "You're on the
base branch. Run from a feature branch.", so A on main would always abort;
a feature branch is exactly where `/document-release` is designed to run),
and per-option follow-through (especially A's auto-commit of touched doc
files, required to avoid the next-step Step 1.9 isolation gate halting on a
dirty checkout). Branch detection lives in the prose, NOT in the script.
Future skills wanting a similar detection-then-AUQ shape should mirror this
split.

State files (`~/.gstack/`):
- `doc-sync-pending/<repo-slug>.json` — marker. Written by F000028's hook on
  non-trivial main-moving merges. Fields: `repo`, `head_sha`, `main_moved_at`,
  `diff_base`, `changed_files`. Read by `skills-doc-sync-check`, deleted by
  `--resolved`.
- `doc-sync-cache.json` — cache: `snooze_until`, `skip_head_sha`. Atomic writes
  via `mktemp` + `mv`. NO `prompted_session` field (reviewer-flagged P0:
  `$$` is not stable across SKILL.md bash fences, so per-shell PID dedup is
  unreliable; natural dedup via `--resolved` / `--snooze` / `--skip` is used
  instead).

Subcommand surface (mirrors `skills-update-check`):
- `skills-doc-sync-check` — default check, emits `DOC_SYNC_PENDING <path>` on hit.
- `skills-doc-sync-check --snooze [hours]` — suppress for N hours (default 24).
- `skills-doc-sync-check --skip <head_sha>` — suppress this specific marker
  forever (different `head_sha` re-fires).
- `skills-doc-sync-check --resolved` — delete marker + clear snooze/skip cache;
  idempotent silent-success when marker already absent. Called after a
  successful `/document-release` on the A path.

Stale-marker self-clean: if the marker's `head_sha` is unreachable from current
HEAD (force-push wiped the commit, operator did `git reset --hard` past it, or
the marker JSON is corrupted and `head_sha` reads empty), the script silently
deletes the marker via `git cat-file -e` and exits 0 — no AUQ for a non-existent
state. Stale markers self-clean instead of accumulating.

The script lives in the user's clone at `$source/scripts/skills-doc-sync-check`
— same path-resolution shape as `skills-update-check`. The preamble snippet in
each instrumented SKILL.md does:

```bash
_DSC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
_DSC_OUT=$([ -n "$_DSC" ] && [ -x "$_DSC/scripts/skills-doc-sync-check" ] && "$_DSC/scripts/skills-doc-sync-check" 2>/dev/null || true)
[ -n "$_DSC_OUT" ] && echo "$_DSC_OUT"
```

Manual override: `rm ~/.gstack/doc-sync-cache.json` clears snooze/skip state;
`rm ~/.gstack/doc-sync-pending/<slug>.json` discards a pending marker without
running `/document-release`. The script does not surface either file via
`skills-deploy doctor` — operator inspection via `ls ~/.gstack/` is the
intended discovery path.

Out of scope for v1: `/CJ_goal_todo_fix` / `/CJ_suggest` / `/CJ_system-health`
preamble calls (separate follow-up — `/CJ_goal_todo_fix` is in the same family
but deferred to a follow-up PR; `/CJ_suggest` / `/CJ_system-health` are
informational utilities, not work-starters, so they're out of the trigger
surface entirely). Per-marker snooze (current design is global `snooze_until`).

## /document-release workbench audit conventions

This workbench keeps two NAMED audit surfaces under `doc/`: `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md`. They are not "any other `.md` files" — they are the explanation + mechanism-reference docs that the operator reads to understand the workbench, and `/document-release` MUST audit them for skill-routing drift on every run. The drift class is: (a) retired-skill references that leak outside the `## Retired skills` subsection of `doc/PHILOSOPHY.md`, and (b) active skills that ship without an entry in `doc/PHILOSOPHY.md ## Decision tree`.

`/document-release` reads this section as project context at Step 2. The audit rides that existing behavior; no upstream skill modification.

### Retired-skill drift check

Extract the set of currently-deprecated skill names:

```
jq -r '.[] | select(.status=="deprecated") | .name' skills-catalog.json
```

For each name returned, `grep -n` for the name in `doc/PHILOSOPHY.md` and `doc/ARCHITECTURE.md`. A mention is **annotated** (and skipped, not reported as drift) if ANY of these hold:

- The mention appears inside the `## Retired skills` subsection of `doc/PHILOSOPHY.md` (one paragraph per retired skill is the canonical tombstone home).
- The mention is inside a `~~strikethrough~~` span.
- The mention is within 200 characters (case-insensitive substring window) of the words `DEPRECATED`, `sunset`, or `tombstone`.

All other mentions are drift findings. Examples of legitimate annotated mentions: the `## Retired skills` subsection itself, the `### Deprecated` table in `README.md`, this very section's `DEPRECATED` keyword. Examples of drift: a routing example in `doc/PHILOSOPHY.md` body that still names a retired skill as a primary front door, a mechanism reference in `doc/ARCHITECTURE.md` that quotes a deprecated skill without the proximity escape hatch.

### New-skills check

Extract the set of currently-active **routable** skill names (entries with a non-empty `files` array — empty `files` indicates a tooling-only catalog entry like `templates` that owns templates but has no SKILL.md and isn't invocable as a skill):

```
jq -r '.[] | select(.status=="active") | select((.files | length) > 0) | .name' skills-catalog.json
```

For each name returned, grep `doc/PHILOSOPHY.md` for a case-sensitive literal match within the `## Decision tree` heading + its body up to the next `##` heading. Missing → drift finding (`active skill not in decision tree: <name>`). This check runs on `doc/PHILOSOPHY.md` only; `doc/ARCHITECTURE.md` deliberately does not duplicate the decision tree (see ARCHITECTURE's `## Decision tree mirror` section).

### Reporting

Drift findings surface in the PR body's `## Documentation` section under a new `### Skill-routing drift` subheading. One finding per line. If no findings, emit a single positive line (`Skill-routing drift: none`) so reviewers can tell the audit ran cleanly versus skipped silently.

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
