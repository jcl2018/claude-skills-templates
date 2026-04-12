# TODOS

## Active work

### T000003: skills-deploy subfolder template support (P1, M)
**What:** Patch `scripts/skills-deploy` to deploy templates from subdirectories (e.g., `templates/company-workflow/*.md` to `~/.claude/templates/company-workflow/`).
**Why:** Without this, `skills-deploy install company-workflow` installs the skill but not its templates. The skill is deployed but broken on company machines.
**Context:** `skills-deploy` line 91 has `validate_template_name()` with regex `^[a-zA-Z0-9_.-]+\.md$` that rejects paths containing `/`. The catalog `templates` array for company-workflow must remain `[]` until this is patched. The fix needs to either extend the regex to allow `subfolder/name.md` patterns, or add a separate subfolder-aware deploy path. The skill's `template-registry.json` declares the path (`templates/company-workflow/`) that deploy should read.
**Depends on:** S000003 complete (templates in place). Part of F000003.

## Deferred work

### ~~scripts/migrate-commands.sh (P3, S)~~ RETIRED
Depends on create-skill.sh which was removed. Skills are now created manually via CLAUDE.md guide.

### ~~Template version tracking (P3, S)~~ RETIRED
Superseded by collection versioning. Templates are covered by the collection version.

### ~~Skill authoring harness skill (P1, M)~~ RETIRED
Shipped as v0.1.0, then sunset in v0.2.3. Replaced by /office-hours + implement + /ship workflow.

### ~~Skill authoring enhancements (P3, S)~~ RETIRED
Depends on skill-author which was removed.

### ~~GitHub Actions CI for skill lifecycle (P3, S)~~ RETIRED
Depends on skill-check.sh which was removed. Validation now handled by validate.sh only.

### ~~skill-status.sh dashboard (P3, S)~~ RETIRED
Depends on skill-check.sh which was removed.

### ~~skill-diff.sh version comparison (P3, S)~~ RETIRED
Depends on skill-ship.sh which was removed.

### Behavioral eval harness (P1, M) — PRIORITY
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.
**When:** Next priority.
**Depends on:** validate.sh

### ~~Batch version mode for multi-skill commits (P3, S)~~ SIMPLIFIED
Simplified by collection versioning. Use `collection-version.sh bump patch`.
**Depends on:** collection-version.sh
