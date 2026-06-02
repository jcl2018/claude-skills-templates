#!/usr/bin/env bash
# Auto-generate README.md from skills-catalog.json.
# Idempotent — no timestamps, no run-specific metadata.

. "$(dirname "$0")/lib.sh"
init

cat << 'HEADER'
# claude-skills-templates

Work lifecycle pipeline, doc contract enforcement, and skill authoring workbench for Claude Code.

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
