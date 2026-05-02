# claude-skills-templates

Work lifecycle pipeline, doc contract enforcement, and skill authoring workbench for Claude Code.

## Skills

| Name | Description | Status | Portability | Version |
|------|-------------|--------|-------------|---------|
| system-health | ~/.claude/ health dashboard with dependency graph and usage trends. Scans installed skills, builds dependency graph, checks filesystem health, surfaces skill usage analytics with behavioral topology overlay, invokes waza for config hygiene. | active | standalone | 1.0.0 |
| templates | Skill authoring template for new skills. | active | standalone | 0.1.0 |
| personal-workflow | Personal work item validation. Validates tracker files and work item directories against personal templates and personal-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules. | active | standalone | 2.0.0 |

### Deprecated

Skills below remain in the repo for reference but are skipped by `skills-deploy install` by default. Use `skills-deploy install --include-deprecated` to install them anyway.

| Name | Description | Portability | Version |
|------|-------------|-------------|---------|
| company-workflow | Company work item specification. Validates tracker files and work item directories against company templates and company-artifact-manifests.json. Templates + WORKFLOW.md are the single source of truth for structural rules. | standalone | 4.0.0 |

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
