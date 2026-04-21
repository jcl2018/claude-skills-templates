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
./scripts/skills-deploy remove system-health # Remove a skill
./scripts/skills-deploy doctor               # Check health
```

## Templates

Doc-first development templates for structured work tracking. Two workflow skills each own their own template set and artifact manifest. Invoke the relevant skill to scaffold work items per the mapping below.

**Company-workflow** (formal 4-phase lifecycle, PR descriptions for TFS / external review):

| Type | Artifacts |
|------|-----------|
| Feature | TRACKER + feature-summary + milestones |
| User Story | TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones |
| Task | TRACKER + test-plan + PR-DESCRIPTION |
| Defect | TRACKER + RCA + test-plan + PR-DESCRIPTION |
| Review | TRACKER + review-notes |

**Personal-workflow** (lighter 3-phase lifecycle, no PR-description artifacts):

| Type | Artifacts |
|------|-----------|
| Feature | TRACKER + milestones |
| User Story | TRACKER + PRD + ARCHITECTURE + TEST-SPEC |
| Task | TRACKER + test-plan |
| Defect | TRACKER + RCA + test-plan |

Per-skill manifests are the canonical source of truth:
- `skills/company-workflow/company-artifact-manifests.json`
- `skills/personal-workflow/personal-artifact-manifests.json`

## Skills

| Skill | What it does |
|-------|-------------|
| `/company-workflow` | Validates company work items against templates. Structural rules (required frontmatter, section order, lifecycle phases, minimum checkbox count) derived from the matching template at runtime — no separate contract file to drift. Optional `AI_KNOWLEDGE_DIR` env var points at an external knowledge folder for coding guidance and domain knowledge; categories marked `surface: always` inject their `*.md` files into Claude's context on every invocation, and categories marked `surface: on-demand` with a `triggers: [...]` list load only when Claude matches a trigger against the user's message. Both require the repo to opt in via `.claude/knowledge-enabled`. Ships with a `knowledge-doctor` diagnostic subcommand for troubleshooting. |
| `/personal-workflow` | Validates personal-dev work items. Same template-derived rules, lighter 3-phase lifecycle (Track / Implement / Ship), simpler frontmatter (no `workflow_type`, no `url`). |
| `/system-health` | Scans `~/.claude/` for broken symlinks, orphan skills, dependency graph issues. Composite 0-10 health score with trend tracking. |

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
