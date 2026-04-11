---
skill-name: "skill-author"
version: 0.1.0
status: APPROVED
created: "2026-04-10"
last-updated: "2026-04-10"
---

# Skill Design: skill-author

## Purpose

Chains the 5 lifecycle scripts (skill-design.sh, create-skill.sh, skill-check.sh, skill-version.sh, skill-ship.sh) into one guided, interactive workflow. Invoked via `/skill-author <name>`. Reduces the gap between "I have a design idea" and "I have a shipped, versioned, tagged skill" from 6 manual steps to one conversation.

## Behavior

5-stage pipeline: intake, scaffold, author, check, ship.

1. **Intake:** Read skill name from args or prompt. Optionally read a design doc from `~/.gstack/projects/` for context. Validate the skill name.
2. **Scaffold:** Check file existence for resume. If no DESIGN.md, run `skill-design.sh`. If no SKILL.md, run `create-skill.sh`. Skip stages where files already exist.
3. **Author:** Guide the user through writing SKILL.md content with targeted questions: what triggers the skill, what it produces, what tools it needs, step-by-step behavior. Write the SKILL.md body. Update catalog entry with real metadata.
4. **Check:** Run `skill-check.sh` in a fix loop (max 3 iterations). Auto-fix mechanical errors (missing fields, bad YAML). Surface subjective issues to user. Run `lint-skill.sh` as advisory.
5. **Ship:** Check for version/tag existence to avoid double-bump. Run `skill-version.sh` then `skill-ship.sh`. Show diff summary and confirm with user.

Tools used: Bash (run scripts), Read/Glob/Grep (read files), Write/Edit (write SKILL.md), AskUserQuestion (guided authoring).

Inputs: skill name, optional design doc.
Outputs: DESIGN.md, SKILL.md, CHANGELOG.md, catalog entry, git commit + tag.

## Design Decisions

- **5 stages, not 7.** Auto-fill, checkpoint JSON, and verify stage cut after /autoplan review. Both CEO and Eng dual voices (Codex + Claude subagent) flagged them as over-engineered.
- **File existence as state.** No checkpoint JSON. DESIGN.md exists = design done. SKILL.md exists = scaffold done. Scripts already exit 1 on duplicate files, so the skill checks before calling.
- **Design doc is optional.** The skill works without a design doc. When present, it provides context for guided authoring but doesn't auto-fill fields.
- **Version idempotency.** Check if version was already bumped (tag exists) before calling skill-version.sh to prevent double-bump on retry.

## Dependencies

Scripts: skill-design.sh, create-skill.sh, skill-check.sh, skill-version.sh, skill-ship.sh, lint-skill.sh. All in `scripts/`.
Shared lib: `scripts/lib.sh` (validate_skill_name, extract_frontmatter_version).
Template: `templates/doc-SKILL-DESIGN.md`.
External tools: jq, git.

## Security Boundaries

Allowed tools: Bash, Read, Glob, Grep, Write, Edit, AskUserQuestion.
Restricted: No WebSearch, no WebFetch, no Agent. The skill runs local scripts and reads/writes local files only.

## Test Criteria

1. `./scripts/skill-check.sh skill-author` passes (structural validation).
2. `./scripts/validate.sh` passes (repo-level validation).
3. `./scripts/test.sh` passes (full test suite including version/ship tests).
4. Manual end-to-end: invoke `/skill-author test-skill`, verify all artifacts created, tag exists.
5. Resume: interrupt mid-pipeline, re-invoke, verify it skips completed stages.
