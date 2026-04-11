# claude-skills-templates

Custom skills and development tooling for Claude Code. Work lifecycle pipeline, doc contract enforcement, system health monitoring, and a skill authoring pipeline.

## Install

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git ~/.claude/skills-templates
~/.claude/skills-templates/scripts/setup.sh
```

This symlinks all skills into `~/.claude/skills/` so Claude Code discovers them automatically. Updates are just `cd ~/.claude/skills-templates && git pull`.

```bash
# Manage installed skills
./scripts/skills-deploy install              # Install all skills
./scripts/skills-deploy install skill-author # Install one (resolves deps)
./scripts/skills-deploy remove skill-author  # Remove a skill
./scripts/skills-deploy doctor               # Check health
```

## Skills

### Work Lifecycle Pipeline

Structured feature development in 4 phases: track, implement, review, ship.

| Skill | What it does |
|-------|-------------|
| `/work` | Router. Detects your branch, shows where you are, suggests the next phase. |
| `/work-track` | Create and manage work items. Scaffolds PRD + ARCHITECTURE + TEST-SPEC doc triplets. |
| `/work-implement` | Structured implementation. Build-forward for features, debug-backward for defects. |
| `/work-review` | Code review wrapper. Loads work item context, delegates to gstack `/review`. |
| `/work-ship` | Ship wrapper. Validates TEST-SPEC acceptance criteria, delegates to gstack `/ship`. |

### Doc Contract Enforcement

| Skill | What it does |
|-------|-------------|
| `/align-feature-contract` | Validates PRD + ARCHITECTURE + TEST-SPEC against templates. Checks cross-doc traceability. |
| `/test-align-contract` | Test harness for the contract enforcer. Tier 1 smoke + Tier 2 end-to-end. |

### Tooling

| Skill | What it does |
|-------|-------------|
| `/system-health` | Scans `~/.claude/` for broken symlinks, orphan skills, dependency graph issues. |
| `/skill-author` | Guided pipeline to create a new skill: intake, scaffold, author, validate, ship. |

## Creating a New Skill

```
/skill-author my-new-skill
```

Walks you through 5 stages:

1. **Intake** -- validate name, check for conflicts
2. **Scaffold** -- create DESIGN.md, SKILL.md, CHANGELOG.md, catalog entry
3. **Author** -- write the skill content (the creative part)
4. **Check** -- validate frontmatter, lint content, run tests
5. **Ship** -- version bump, hand off to `/ship` for commit + PR

Or do it manually:

```bash
./scripts/skill-design.sh my-skill       # Create DESIGN.md
./scripts/create-skill.sh my-skill       # Scaffold SKILL.md + catalog entry
# ... write the skill ...
./scripts/skill-check.sh my-skill        # Validate
./scripts/skill-version.sh my-skill patch  # Bump version
./scripts/skill-ship.sh my-skill         # Commit + tag
```

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Bootstrap installer (clone + deploy symlinks) |
| `skills-deploy` | Manage installed skills (install/remove/relink/doctor) |
| `validate.sh` | Catalog-to-filesystem validation |
| `test.sh` | Full test suite |
| `test-deploy.sh` | Deploy pipeline tests |
| `create-skill.sh` | Scaffold a new skill |
| `skill-design.sh` | Scaffold DESIGN.md |
| `skill-check.sh` | Per-skill validation |
| `skill-version.sh` | Bump version (major/minor/patch) |
| `skill-ship.sh` | Commit, tag, release |
| `doctor.sh` | Skill health diagnostics |
| `lint-skill.sh` | Content-level linting |
| `deps.sh` | Dependency graph |
| `generate-readme.sh` | Auto-generate skills table |
