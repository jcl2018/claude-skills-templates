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

### ~~Skill authoring harness skill (P1, M)~~ DONE
Shipped as `skills/skill-author/SKILL.md` v0.1.0. 5-stage pipeline (intake, scaffold,
author, check, ship). Invoke via `/skill-author <name>`.

### Skill authoring enhancements (P3, S)
Potential enhancements to `/skill-author` after manual usage proves the need:
- Auto-fill from /office-hours design docs (AI extraction, not string matching)
- Checkpoint JSON for formal multi-session resume
- Verify stage (invoke new skill on canned prompt)
**When:** After 3+ skills have been authored using the harness and friction points are known.
**Depends on:** skill-author

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

### Behavioral eval harness (P1, M) — PRIORITY
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.
Both CEO and Eng review voices (Codex + Claude subagent) independently flagged this
as the highest-priority next step: "faster authoring without quality signal is faster
error production."
**When:** Next priority after skill-author ships.
**Depends on:** skill-check.sh

### Batch version mode for multi-skill commits (P3, S)
When a change touches multiple skills, allow bumping all at once.
**When:** When cross-cutting refactors become frequent.
**Depends on:** skill-version.sh, deps.sh
