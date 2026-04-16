# CLAUDE.md

## What this repo is

A skill development workbench for Claude Code. Contains 2 custom skills (doc intelligence, system health), a template library for doc-first development, and tooling to validate, test, and distribute skills.

## Quick start

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates
./scripts/validate.sh          # check repo health
./scripts/test.sh              # run full test suite
```

## Skill routing

When the user's request matches an available skill, invoke it:

- "health check", "system status" -> /system-health
- "validate company work item", "company workflow" -> /company-workflow

## Work item templates

Work item template rules are delivered globally via `skills-deploy install` to
`~/.claude/rules/work-items.md`. The source lives at `rules/work-items.md` in this repo.
See `artifact-manifests.json` for the canonical type-to-artifact mapping.

## Conventions

### Skill directory structure
```
skills/{skill-name}/
  SKILL.md          # required, has name + description frontmatter
  *.md              # optional supporting files
```

### Template naming
Templates live in `templates/` with prefixes:
- `doc-*.md` for scaffolding templates (used when creating new work item docs)
- `tracker-*.md` for work item templates (feature, defect, task, user-story)

### Template deployment
`skills-deploy install` copies per-skill templates to `~/.claude/templates/` (global).
Templates resolve via fallback chain: `$REPO_ROOT/templates/` -> `~/.claude/spec/templates/` -> `~/.claude/templates/`.
- Use `--overwrite` to force-replace templates with local modifications
- `skills-deploy doctor` reports template health (missing, drifted, orphaned)
- `skills-deploy remove` cleans up templates when no installed skill needs them
- Templates are tracked in the manifest with SHA256 checksums and per-skill ownership

### Catalog format
`skills-catalog.json` is a bare JSON array of skill objects. Each entry has:
name, version, description, source, depends, portability, files, templates, status.
The catalog is for validation only. The plugin system auto-discovers `skills/`.

### Frontmatter requirements
Every SKILL.md must have YAML frontmatter with at least `name` and `description`.
`allowed-tools` is recommended for security (restricts which tools the skill can use).

### Personal-native pattern
No $AI_CONTENT_DIR indirection. Work items live at `./work-items/` per repo.
Templates at `~/.claude/templates/`. Upstream skills sync via git pull.

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
| `validate.sh` | Checks catalog against filesystem | Before every commit |
| `test.sh` | Full test suite (superset of validate) | Before pushing |
| `collection-version.sh` | Get/bump/manifest for collection version | Maintainer tool (internal) |
| `doctor.sh` | Diagnoses skill health issues | Periodic checkup |
| `lint-skill.sh` | Checks SKILL.md content quality | After writing a skill |
| `deps.sh` | Shows dependency graph | When changing deps |
| `generate-readme.sh` | Regenerates README.md from catalog | After catalog changes |
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs pre-commit hook | Once per clone |
