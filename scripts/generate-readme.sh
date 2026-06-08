#!/usr/bin/env bash
# Auto-generate README.md from skills-catalog.json.
# Idempotent — no timestamps, no run-specific metadata.

. "$(dirname "$0")/lib.sh"
init

cat << 'HEADER'
# claude-skills-templates

A doc-first development workbench: a work lifecycle pipeline, doc-contract enforcement, and authoring tooling. It ships from one source of truth to **two delivery surfaces** — Claude Code skills, and a self-contained GitHub Copilot bundle (`work-copilot/`) for machines without Claude. It is deliberately not Claude-skill-only.

## Delivery surfaces

- **`skills/`** — Claude Code skills (the `CJ_` workflow family + utilities), auto-discovered and listed below.
- **`work-copilot/`** — a self-contained **GitHub Copilot** bundle carrying the same work-item templates + `/validate` workflow to non-Claude machines. Deploy with `python3 scripts/copilot-deploy.py install <target>`; see [`work-copilot/README.md`](work-copilot/README.md).

## Repository layout

```
.
├── doc-spec.md          # the doc contract: what docs this repo carries + what each is for
├── docs/                # human docs (philosophy.md, workflow.md, architecture.md) + generated doc-spec views (doc-general.md, doc-custom.md)
├── skills/              # Claude Code skills (the CJ_ family + utilities)
├── templates/           # work-item + doc authoring templates
├── work-copilot/        # the GitHub Copilot delivery bundle (Python-CLI deployed)
├── scripts/             # validate / test / deploy / helper scripts
├── work-items/          # the structured per-feature work tree (features, defects, tasks)
├── rules/               # skill-routing rules deployed to ~/.claude/rules/
├── CLAUDE.md            # agent operating instructions (auto-loaded by Claude Code)
├── CONTRIBUTING.md      # contributor authoring guide
├── CHANGELOG.md         # release history
└── TODOS.md             # operational backlog
```

For the full doc map (and the machine registry the validator parses), see [`doc-spec.md`](doc-spec.md).

## Skills

HEADER

# Generate skills table from catalog (active + experimental)
echo "| Name | Description | Status | Portability | Version |"
echo "|------|-------------|--------|-------------|---------|"
jq -r '.[] | select((.status // "active") != "deprecated") | "| \(.name) | \(.description) | \(.status) | \(.portability) | \(.version) |"' "$CATALOG"

cat << 'BODY'

## Quick Start

```bash
# Clone the repo
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates

# Validate the repo
./scripts/validate.sh

# Run full test suite
./scripts/test.sh
```

## Getting started: the major workflows

Once the skills are installed (see Installation below), the workbench is driven by
a handful of `CJ_` front doors. Pick by what you have in hand:

| You have... | Run | What it does |
|-------------|-----|--------------|
| A one-line feature topic | `/CJ_goal_feature "<topic>"` | Designs, scaffolds, implements, QAs, and opens a reviewable PR — stops at the PR for human review. |
| A bug description | `/CJ_goal_defect "<bug>"` | Root-causes it, writes the fix + tests, and ships the deployed fix. |
| A `TODOS.md` backlog to drain | `/CJ_goal_todo_fix` | Drains shippable TODO rows into PRs (one, or up to N in drain mode). |
| "What should I work on?" | `/CJ_suggest` | Prints a ranked top-5 of next-up work items. |
| "Is my `~/.claude/` healthy?" | `/CJ_system-health` | A read-only health dashboard for the install. |

Every front door converges on the same `/ship` → `/land-and-deploy` tail. For the
full workflow charts see [`docs/workflow.md`](docs/workflow.md); for the routing
decision tree see [`docs/philosophy.md`](docs/philosophy.md).

## Installation

### As a Claude Code plugin

```bash
claude plugin install claude-skills-templates@your-marketplace
```

### Via git clone

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
claude --plugin-dir ./claude-skills-templates
```

## Running on Windows

The workbench is POSIX-shell software. On Windows it runs two ways:

- **WSL2 (recommended).** A real Linux environment — everything behaves exactly as on macOS/Linux, including symlink-based `skills-deploy install`.
- **Git Bash (supported).** The bash that ships with [Git for Windows](https://gitforwindows.org/) — the same shell Claude Code uses to run skill preambles on Windows. Real symlinks are unavailable there, so `skills-deploy install` automatically falls back to **copy-mode** (real files + checksum-tracked drift detection) instead of symlinks.

**Prerequisites** (both paths): `git`, `jq`, `gh`, and `python3` (the last only for the Copilot bundle / `copilot-deploy.py`). On Git Bash, `git` and `jq` come with Git for Windows; install `gh` from [cli.github.com](https://cli.github.com/).

Line endings are pinned to LF by `.gitattributes` (`* text=auto eol=lf`), so shell scripts stay runnable under bash even when `core.autocrlf` is on. A `windows-latest` CI job (`.github/workflows/windows.yml`) runs the Windows-relevant test subset under Git Bash on every PR, so Windows support is exercised continuously. Run the same checks locally with `bash scripts/windows-smoke.sh`.

## gstack plans live in this repo

Plans, designs, and reviews from gstack skills (`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/context-save`) land at `<repo>/.gstack/` and are committed to git, so PR reviewers see the design intent that produced the code and design history travels alongside code history. Machine-local gstack state (sessions, analytics, learnings) stays out of git via `.gitignore`.

After cloning, wire up the per-machine redirect:

```bash
cd <repo>
./scripts/setup-gstack-symlink.sh
```

This creates a symlink from `~/.gstack/projects/<slug>/` (where gstack writes by default) to `<main-repo>/.gstack/`. Run from the repo root; the script resolves the main checkout via `git rev-parse --git-common-dir` so it works from worktrees too. Reverse with `./scripts/teardown-gstack-symlink.sh`.

See `CLAUDE.md` for the `.gstack/` (lateral/exploratory) vs `work-items/` (structured per-feature) split convention.

## Scripts

| Script | Purpose | Exit code |
|--------|---------|-----------|
| `setup.sh` | Bootstrap: clone-or-update repo and deploy all skills | 1 on error |
| `skills-deploy` | Install/remove/relink/doctor skills from this repo into `~/.claude/` (also deploys `rules/*.md` → `~/.claude/rules/`) | 1 on error |
| `validate.sh` | Catalog-to-filesystem validation | 1 on error |
| `test.sh` | Smoke tests (superset of validate) | 1 on failure |
| `test-deploy.sh` | Automated tests for `skills-deploy` in isolated temp dirs | 1 on failure |
| `collection-version.sh` | Get/bump/manifest for collection version | 1 on error |
| `doctor.sh` | Skill health diagnostics | 0 (advisory) |
| `lint-skill.sh` | Content-level skill linting | 0 (advisory) |
| `deps.sh` | Dependency graph visualization | 0 (advisory) |
| `generate-readme.sh` | Auto-generate this README | 1 on write failure |
| `sync-upstream.sh` | Compare upstream gstack skills | 0 (local-only) |
| `setup-hooks.sh` | Install pre-commit hook | 0 |
| `setup-gstack-symlink.sh` | Per-machine: symlink `~/.gstack/projects/<slug>/` to `<main-repo>/.gstack/` so gstack output commits in git. Idempotent; `--force` to re-point or merge non-empty target. | 1 on error |
| `teardown-gstack-symlink.sh` | Reverse the gstack symlink: restore `~/.gstack/projects/<slug>/` to a real directory. Refuses if the symlink target doesn't match expected. | 1 on wrong target |
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle in a target repo | 1 on error |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Auto-invoked from instrumented skill preambles. | 0 (advisory) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
BODY
