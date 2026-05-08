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

# Generate skills table from catalog (active + experimental — non-deprecated)
echo "| Name | Description | Status | Portability | Version |"
echo "|------|-------------|--------|-------------|---------|"
jq -r '.[] | select((.status // "active") != "deprecated") | "| \(.name) | \(.description) | \(.status) | \(.portability) | \(.version) |"' "$CATALOG"

# Append a "Deprecated" section iff at least one entry has status=deprecated.
# Skills here stay in the repo (e.g. as upstream truth for byte-mirrored bundles)
# but are skipped by `skills-deploy install` unless --include-deprecated is set.
DEPRECATED_COUNT=$(jq -r '[.[] | select((.status // "active") == "deprecated")] | length' "$CATALOG")
if [ "$DEPRECATED_COUNT" -gt 0 ]; then
  echo ""
  echo "### Deprecated"
  echo ""
  echo "Skills below remain in the repo for reference but are skipped by \`skills-deploy install\` by default. Use \`skills-deploy install --include-deprecated\` to install them anyway."
  echo ""
  echo "| Name | Description | Portability | Version |"
  echo "|------|-------------|-------------|---------|"
  jq -r '.[] | select((.status // "active") == "deprecated") | "| \(.name) | \(.description) | \(.portability) | \(.version) |"' "$CATALOG"
fi

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

## Scripts

| Script | Purpose | Exit code |
|--------|---------|-----------|
| `setup.sh` | Bootstrap: clone-or-update repo and deploy all skills | 1 on error |
| `skills-deploy` | Install/remove/relink/doctor skills from this repo into `~/.claude/` | 1 on error |
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
| `copilot-deploy.py` | Install/doctor/remove the Copilot bundle in a target repo | 1 on error |
| `skills-update-check` | Passive update detector — emits `SKILLS_UPGRADE_AVAILABLE` banner when origin/main has a newer collection version. Auto-invoked from instrumented skill preambles. | 0 (advisory) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
BODY
