# claude-skills-templates

Work lifecycle pipeline, doc contract enforcement, and skill authoring workbench for Claude Code.

## Skills

| Name | Description | Status | Portability | Version |
|------|-------------|--------|-------------|---------|
| work | Work item router: auto-detect from branch, show menu, suggest phase skill. No mutations. | active | pipeline | 0.1.0 |
| work-track | Context-aware work item management: evidence synthesis, CRUD, lifecycle, manifest-driven scaffolding. | active | pipeline | 0.1.0 |
| work-implement | Structured implementation with root-cause debugging. Dual-mode: build-forward or debug-backward. | active | pipeline | 0.1.0 |
| work-review | Phase 3: code review wrapper. Loads work item context, delegates to gstack /review. | active | pipeline | 0.1.0 |
| work-ship | Phase 4: ship wrapper. Validates TEST-SPEC acceptance criteria, delegates to gstack /ship. | active | pipeline | 0.1.0 |
| system-health | Unified health dashboard: config hygiene, governance checks, doc quality, deploy state. | active | standalone | 0.1.0 |
| align-feature-contract | Doc triplet contract enforcement: template alignment, cross-doc traceability, code verification. | active | standalone | 0.1.0 |
| test-align-contract | Unified test harness for /align-feature-contract: Tier 1 smoke tests + Tier 2 end-to-end execution. | active | standalone | 0.1.0 |

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
| `create-skill.sh` | Scaffold new skill + doc triplet | 1 on error |
| `doctor.sh` | Skill health diagnostics | 0 (advisory) |
| `lint-skill.sh` | Content-level skill linting | 0 (advisory) |
| `deps.sh` | Dependency graph visualization | 0 (advisory) |
| `generate-readme.sh` | Auto-generate this README | 1 on write failure |
| `sync-upstream.sh` | Compare upstream gstack skills | 0 (local-only) |
| `setup-hooks.sh` | Install pre-commit hook | 0 |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full authoring guide.
