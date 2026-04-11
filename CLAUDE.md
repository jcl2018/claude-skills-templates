# CLAUDE.md

## What this repo is

A skill development workbench for Claude Code. Contains 3 custom skills (doc intelligence, skill authoring, system health), a template library for doc-first development, and tooling to author, validate, test, and distribute skills.

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

- "health check", "system status" -> /system-health

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
- `contract-*.md` for enforcement reference templates (document what good docs look like)
- `tracker-*.md` for work item templates (feature, defect, task, user-story)
- `*-GENERATION-GUIDE.md` for doc generation instructions
- `GENERATION-GUIDE.md` is a meta-template for doc generation instructions

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
| `skill-ship.sh` | Commits, tags skill + bumps collection version | When ready to ship |
| `collection-version.sh` | Get/bump/manifest for collection version | Maintainer tool (internal) |
| `skill-migrate.sh` | Migrates existing skills to lifecycle format | One-time migration |
| `doctor.sh` | Diagnoses skill health issues | Periodic checkup |
| `lint-skill.sh` | Checks SKILL.md content quality | After writing a skill |
| `deps.sh` | Shows dependency graph | When changing deps |
| `generate-readme.sh` | Regenerates README.md from catalog | After catalog changes |
| `sync-upstream.sh` | Compares upstream gstack skills | When updating from gstack |
| `setup-hooks.sh` | Installs pre-commit hook | Once per clone |
