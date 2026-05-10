# /autoplan Restore Point
Captured: 2026-04-10T18:28:35Z | Branch: main | Commit: f6bb891

## Re-run Instructions
1. Copy "Original Plan State" below back to your plan file
2. Invoke /autoplan

## Original Plan State
# Implementation Plan: Skill Authoring Harness (`/skill-author`)

## Context

The claude-skills-templates repo has 5 lifecycle scripts (skill-design.sh, create-skill.sh, skill-check.sh, skill-version.sh, skill-ship.sh) that work individually but require manual orchestration. This plan implements a Claude Code skill (`/skill-author`) that chains them into one guided, interactive, resumable workflow with AI-powered auto-fill from /office-hours design docs.

Based on the APPROVED design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260410-181753.md`.

## Approach: Interactive Pipeline + Resume (Approach B)

7 stages: intake > design > scaffold > author > check > version+ship > verify

### Files to Create/Modify

1. `skills/skill-author/DESIGN.md` - Skill design doc
2. `skills/skill-author/SKILL.md` - The harness skill itself
3. `skills/skill-author/CHANGELOG.md` - Per-skill changelog
4. `skills-catalog.json` - Add skill-author entry
5. `TODOS.md` - Mark item as DONE
6. `README.md` - Regenerated

### Implementation Sequence (dogfooding)

1. skill-design.sh skill-author
2. Pre-fill DESIGN.md
3. create-skill.sh skill-author
4. Write SKILL.md body
5. Update catalog entry
6. skill-check.sh skill-author
7. skill-version.sh skill-author patch
8. skill-ship.sh skill-author
