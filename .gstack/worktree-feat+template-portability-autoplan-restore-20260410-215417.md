# /autoplan Restore Point
Captured: 2026-04-11T04:54:25Z | Branch: worktree-feat+template-portability | Commit: 2dc99e8

## Re-run Instructions
1. Copy "Original Plan State" below back to your plan file
2. Invoke /autoplan

## Original Plan State
# Plan: Template Portability for skills-deploy

## Context

Templates in `templates/` are tied to this repo. When someone installs skills into another repo via `skills-deploy install`, only SKILL.md gets symlinked. The templates stay behind. Anyone using workflow or contracts in a different repo gets template-not-found errors. This plan extends `scripts/skills-deploy` to also deploy per-skill templates to `~/.claude/templates/` with SHA256 checksums, shared-ownership tracking, and doctor/relink support.

Design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260410-214430.md` (APPROVED)

## Implementation

### Files to modify

| File | Change |
|------|--------|
| `scripts/skills-deploy` | Add template helpers, extend install/remove/doctor/relink |
| `scripts/test.sh` | Add template deployment test cases |
| `CLAUDE.md` | Document template deployment in conventions |

### Step 1: Add helpers to `scripts/skills-deploy`

New constants after line 11:
```bash
TEMPLATES_SRC="$REPO_ROOT/templates"
TEMPLATES_TARGET="${HOME}/.claude/templates"
```

New helpers after `reverse_deps()`:
```bash
skill_templates() {
  local name="$1"
  [ -f "$CATALOG" ] || return 0
  jq -r --arg n "$name" '.[] | select(.name == $n) | .templates // [] | .[]' "$CATALOG" 2>/dev/null || true
}

file_checksum() {
  (shasum -a 256 "$1" 2>/dev/null || sha256sum "$1" 2>/dev/null) | awk '{print $1}'
}
```

### Step 2: Extend `do_install` (after skill symlink loop, before manifest write)

For each installed skill, deploy its templates:
- Read templates from catalog via `skill_templates()`
- For each template:
  - Source missing? WARN and skip
  - Target exists, checksum matches? Skip copy, but update owners
  - Target exists, checksum differs? WARN and skip (--force overrides)
  - Target doesn't exist? Copy and record
- Track in manifest `.templates` with `{owners, source_checksum, installed_at}`

### Step 3: Extend `do_remove` (after skill symlink removal)

For each removed skill's templates:
- Remove skill from template's `owners` array
- If owners empty: delete template file from `~/.claude/templates/`
- If other owners remain: leave file in place

### Step 4: Extend `do_doctor` (new Templates section)

Check each template in manifest:
- File exists? FAIL if not
- Checksum matches? WARN if drifted
- All owners still installed? WARN if orphaned
- Catalog templates not in manifest? WARN if not deployed

### Step 5: Extend `do_relink` (template repair)

For each manifest template where file missing or drifted:
- Source exists? Re-copy and update checksum
- Source missing? WARN and leave manifest intact

### Step 6: Add tests to `scripts/test.sh`

- Install skill, verify templates in `~/.claude/templates/`
- Shared ownership: install 2 skills, remove 1, verify template persists
- Full cleanup: remove all skills, verify templates removed
- Doctor: detect missing/drifted templates

### Step 7: Update CLAUDE.md

Document template deployment in conventions section.

## Verification

1. `./scripts/skills-deploy install workflow` deploys 8 templates to `~/.claude/templates/`
2. `./scripts/skills-deploy doctor` shows template health
3. `./scripts/skills-deploy remove workflow` cleans up templates not owned by other skills
4. `./scripts/test.sh` passes all existing + new tests
