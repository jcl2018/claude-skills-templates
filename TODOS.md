# TODOS

## Deferred work

### scripts/migrate-commands.sh (P3, S)
Convert `.claude/commands/*.md` files (old standalone format) into plugin `skills/` directories.
Reads command markdown, extracts frontmatter, creates `skills/name/SKILL.md`, adds catalog entry.
**When:** Add when a second repo wants to consume skills from this workbench.
**Depends on:** create-skill.sh

### Template version tracking (P3, S)
Add `version` field to template frontmatter and `template_version` to catalog entries.
`validate.sh` checks that a skill's template_version matches the current template version.
**When:** Add when templates start changing frequently (>6 templates, active iteration).
**Depends on:** validate.sh
