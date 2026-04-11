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

### GitHub Actions CI for skill lifecycle (P3, S)
Run `skill-check.sh` on PRs for remote enforcement. Pre-commit hooks are local-only.
**When:** Add when collaborators join or CI enforcement is needed.
**Depends on:** skill-check.sh

### skill-status.sh dashboard (P3, S)
Show all skills with version, last modified, lifecycle gate status.
**When:** When navigating 15+ skills becomes cumbersome.
**Depends on:** skill-check.sh, skills-catalog.json

### skill-diff.sh version comparison (P3, S)
Show what changed in a skill between git tags using `git diff {name}-v{old}..{name}-v{new}`.
**When:** When version history is deep enough to need comparison.
**Depends on:** skill-ship.sh (creates tags)

### Behavioral eval harness (P2, M)
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.
**When:** When skill quality matters more than skill quantity.
**Depends on:** skill-check.sh

### Batch version mode for multi-skill commits (P3, S)
When a change touches multiple skills, allow bumping all at once.
**When:** When cross-cutting refactors become frequent.
**Depends on:** skill-version.sh, deps.sh
