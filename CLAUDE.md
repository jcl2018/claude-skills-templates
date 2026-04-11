# CLAUDE.md

## What this repo is

A skill development workbench for Claude Code. Contains 8 custom skills (work lifecycle pipeline, doc contract enforcement, system health), 15+ templates, and the tooling to author, validate, test, and distribute skills like real software.

## Quick start

```bash
git clone https://github.com/jcl2018/claude-skills-templates.git
cd claude-skills-templates
./scripts/validate.sh          # check repo health
./scripts/create-skill.sh my-skill  # scaffold a new skill
./scripts/test.sh              # run full test suite
```

## Skill routing

When the user's request matches an available skill, invoke it:

- "scaffold a work item", "create a feature" -> /workflow track create
- "implement this", "build this feature" -> /workflow implement
- "review this code" -> /workflow review
- "ship this", "create a PR" -> /workflow ship
- "check doc quality", "align contracts" -> /contracts check
- "test the contracts" -> /contracts test
- "health check", "system status" -> /system-health
- "what phase am I in" -> /workflow

## Conventions

### Skill directory structure
```
skills/{skill-name}/
  SKILL.md          # required, has name + description frontmatter
  *.md              # optional supporting files
```

### Template naming
Templates live in `templates/` with prefixes:
- `doc-*.md` for scaffolding templates (used by /workflow track to create new docs)
- `contract-*.md` for enforcement templates (used by /contracts to validate existing docs)
- `tracker-*.md` for work item templates (feature, defect, task, etc.)
- `*-GENERATION-GUIDE.md` for doc generation instructions
- `GENERATION-GUIDE.md` and `TRACKER-TEMPLATE.md` are meta-templates

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

## Scripts reference

| Script | What it does | When to run |
|--------|-------------|-------------|
| `validate.sh` | Checks catalog against filesystem | Before every commit |
| `test.sh` | Full test suite (superset of validate) | Before pushing |
| `skill-design.sh` | Scaffolds DESIGN.md for a new skill | First step of new skill |
| `create-skill.sh` | Scaffolds SKILL.md + CHANGELOG.md | After DESIGN.md exists |
| `skill-check.sh` | Validates skill lifecycle compliance | Before version bump or ship |
| `skill-version.sh` | Bumps skill version (major/minor/patch) | When ready to version |
| `skill-ship.sh` | Commits and tags a skill release | When ready to ship |
| `skill-migrate.sh` | Migrates existing skills to lifecycle format | One-time migration |
| `doctor.sh` | Diagnoses skill health issues | Periodic checkup |
| `lint-skill.sh` | Checks SKILL.md content quality | After writing a skill |
| `deps.sh` | Shows dependency graph | When changing deps |
| `generate-readme.sh` | Regenerates README.md from catalog | After catalog changes |
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs pre-commit hook | Once per clone |
