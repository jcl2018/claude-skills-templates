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

# Create a new skill
./scripts/create-skill.sh my-new-skill

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
| `validate.sh` | Catalog-to-filesystem validation | 1 on error |
| `test.sh` | Smoke tests (superset of validate) | 1 on failure |
| `skill-design.sh` | Scaffold DESIGN.md for a new skill | 1 on error |
| `create-skill.sh` | Scaffold SKILL.md + CHANGELOG.md + catalog entry | 1 on error |
| `skill-check.sh` | Per-skill lifecycle validation | 1 on error |
| `skill-version.sh` | Bump skill version (major/minor/patch) | 1 on error |
| `skill-ship.sh` | Commit, tag, and ship a skill release | 1 on error |
| `doctor.sh` | Skill health diagnostics | 0 (advisory) |
| `lint-skill.sh` | Content-level skill linting | 0 (advisory) |
| `deps.sh` | Dependency graph visualization | 0 (advisory) |
| `generate-readme.sh` | Auto-generate this README | 1 on write failure |
| `sync-upstream.sh` | Compare upstream gstack skills | 0 (local-only) |
| `setup-hooks.sh` | Install pre-commit hook | 0 |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
BODY
