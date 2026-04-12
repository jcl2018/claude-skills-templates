# claude-skills-templates

Custom skills, templates, and development tooling for Claude Code. Doc-first development templates, doc intelligence, and system health monitoring.

## Install

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git ~/.claude/skills-templates
~/.claude/skills-templates/scripts/setup.sh
```

This symlinks all skills into `~/.claude/skills/` so Claude Code discovers them automatically. Updates are just `cd ~/.claude/skills-templates && git pull`.

```bash
# Manage installed skills
./scripts/skills-deploy install              # Install all skills + templates
./scripts/skills-deploy remove docs          # Remove a skill
./scripts/skills-deploy doctor               # Check health
```

## Templates

Doc-first development templates for structured work tracking. Create work items with type-aware artifact sets via CLAUDE.md rules (no skill needed).

| Type | Artifacts |
|------|-----------|
| Feature | TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones |
| Defect | TRACKER + RCA + test-plan |
| Task | TRACKER + test-plan |
| User Story | TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones |

See `artifact-manifests.json` for the canonical type-to-artifact mapping.

## Skills

| Skill | What it does |
|-------|-------------|
| `/docs` | Doc intelligence. Generates narrative docs (PHILOSOPHY.md, OVERVIEW.md) with claims sidecar for staleness detection. |
| `/system-health` | Scans `~/.claude/` for broken symlinks, orphan skills, dependency graph issues. |

## Creating a New Skill

Create the directory and files directly (see CLAUDE.md "Creating a new skill" section for the full guide):

1. Create `skills/{name}/SKILL.md` with YAML frontmatter (name, description, version, allowed-tools)
2. Add a catalog entry to `skills-catalog.json`
3. Run `./scripts/validate.sh` to verify
4. Use `/ship` to commit and create a PR

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Bootstrap installer (clone + deploy symlinks) |
| `skills-deploy` | Manage installed skills (install/remove/relink/doctor) |
| `validate.sh` | Catalog-to-filesystem validation |
| `test.sh` | Full test suite |
| `test-deploy.sh` | Deploy pipeline tests |
| `collection-version.sh` | Get/bump/manifest for collection version |
| `doctor.sh` | Skill health diagnostics |
| `lint-skill.sh` | Content-level linting |
| `deps.sh` | Dependency graph |
| `generate-readme.sh` | Auto-generate skills table |
