---
name: skill-author
description: "Guided skill authoring pipeline: scaffold, write, validate, version, and ship a new skill in one conversation."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - AskUserQuestion
---

# /skill-author

Chains the lifecycle scripts into one guided workflow. 6 stages: intake, scaffold,
author, check, ship, install. Invoke with `/skill-author <name>` or `/skill-author` to be prompted.

## Stage 1: Intake

1. If the user provided a skill name as an argument, use it. Otherwise, ask:
   "What should this skill be called? (kebab-case, e.g. `code-review`)"

2. Validate the skill name by running:
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   . "$REPO_ROOT/scripts/lib.sh"
   validate_skill_name "<name>"
   ```
   If validation fails, show the error and ask for a different name.

3. Check if a design doc exists for context:
   ```bash
   eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || true
   SLUG=${SLUG:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")}
   BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
   DESIGN_DOC=$(ls -t ~/.gstack/projects/$SLUG/*-$BRANCH-design-*.md 2>/dev/null | head -1)
   [ -z "$DESIGN_DOC" ] && DESIGN_DOC=$(ls -t ~/.gstack/projects/$SLUG/*-design-*.md 2>/dev/null | head -1)
   [ -n "$DESIGN_DOC" ] && echo "Design doc found: $DESIGN_DOC" || echo "No design doc found"
   ```
   If found, read it for context during the Author stage. If not found, proceed without it.

4. Print: "Starting /skill-author for `<name>`. Stages: intake, scaffold, author, check, ship, install."

## Stage 2: Scaffold

Check file existence before calling each script. This enables resume if interrupted.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
SKILL_DIR="$REPO_ROOT/skills/<name>"
```

1. **DESIGN.md:** If `$SKILL_DIR/DESIGN.md` does NOT exist, run:
   ```bash
   "$REPO_ROOT/scripts/skill-design.sh" <name>
   ```
   Then fill in the Purpose and Behavior sections based on context (design doc if
   available, or ask the user). Purpose and Behavior must be non-placeholder content
   or skill-check.sh will fail.

   If `DESIGN.md` already exists, print "DESIGN.md exists, skipping scaffold." and continue.

2. **SKILL.md + CHANGELOG.md:** If `$SKILL_DIR/SKILL.md` does NOT exist, run:
   ```bash
   "$REPO_ROOT/scripts/create-skill.sh" <name>
   ```
   This also creates CHANGELOG.md and adds a catalog entry.

   If `SKILL.md` already exists, print "SKILL.md exists, skipping scaffold." and continue.

## Stage 3: Author

This is the creative stage. Guide the user through writing the SKILL.md content.

1. Read the scaffolded SKILL.md. It has placeholder content ("TODO: describe what this
   skill does" and "TODO: Add skill instructions here.").

2. If a design doc was found in Stage 1, read it now for context about the skill's
   purpose, behavior, constraints, and dependencies.

3. Ask the user these questions (skip any that the design doc already answers clearly):

   a. "What triggers this skill? What would a user type or what situation would invoke it?"
      (Maps to: description frontmatter + routing rules)

   b. "What does the skill do step by step? Walk me through the behavior."
      (Maps to: SKILL.md body instructions)

   c. "What tools does this skill need?" Present the common set:
      Bash, Read, Glob, Grep, Write, Edit, AskUserQuestion, WebSearch, Agent.
      (Maps to: allowed-tools frontmatter)

   d. "What does the skill produce? What artifacts, files, or outputs?"
      (Maps to: output description in SKILL.md body)

4. Write the SKILL.md body using the answers. Structure:
   - Update the `description` frontmatter with a real description (replace TODO)
   - Update the `allowed-tools` list based on answer (c)
   - Write the skill body with clear sections for behavior, organized by step
   - Include error handling guidance where appropriate

5. Update the catalog entry to replace placeholder values:
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   jq --arg name "<name>" --arg desc "<real description>" \
     'map(if .name == $name then .description = $desc | .templates = [] else . end)' \
     "$REPO_ROOT/skills-catalog.json" > /tmp/catalog-update.json && \
     mv /tmp/catalog-update.json "$REPO_ROOT/skills-catalog.json"
   ```

6. Show the user the completed SKILL.md and ask: "Does this look right? Edit anything?"
   Apply any requested changes.

## Stage 4: Check

Run validation in a fix loop.

1. Run skill-check:
   ```bash
   "$REPO_ROOT/scripts/skill-check.sh" <name>
   ```

2. If it fails, read the output. For each error:
   - **Mechanical errors** (missing frontmatter field, version mismatch, missing changelog
     entry): fix automatically by editing the relevant file.
   - **Subjective errors** (lint warnings about content quality): show the warning to
     the user and ask how to address it.

3. Re-run skill-check.sh. Repeat up to 3 times total. If still failing after 3 attempts,
   show the remaining errors and ask the user for help.

4. Run lint as advisory:
   ```bash
   "$REPO_ROOT/scripts/lint-skill.sh" <name>
   ```
   Show any warnings but don't block on them.

5. Print: "All checks pass. Ready to ship."

## Stage 5: Ship

Version bump and release.

1. **Check for existing version bump.** Read the current version from SKILL.md frontmatter
   and check if a git tag already exists for it:
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   VERSION=$(sed -n '/^---$/,/^---$/p' "$REPO_ROOT/skills/<name>/SKILL.md" | grep '^version:' | head -1 | sed 's/^version:[[:space:]]*//')
   TAG="<name>-v$VERSION"
   git tag -l "$TAG" | grep -q "$TAG" && echo "TAG_EXISTS" || echo "NO_TAG"
   ```

2. **Version bump** (only if tag does NOT exist for a bumped version):
   - If this is the initial version (0.1.0) and no tag exists, ask: "Ready to ship
     `<name>` v0.1.0? This will commit and tag."
   - If a tag for 0.1.0 already exists (re-run scenario), skip the bump.
   - Otherwise, ask: "What kind of change? (patch / minor / major)" and run:
     ```bash
     "$REPO_ROOT/scripts/skill-version.sh" <name> <bump-type>
     ```

3. **Fill changelog.** After version bump, the CHANGELOG.md has a placeholder entry.
   Fill it with a real description of what was added/changed.

4. **Ship:**
   ```bash
   "$REPO_ROOT/scripts/skill-ship.sh" <name>
   ```
   This commits, tags, and regenerates README.md.

5. Print the result:
   ```
   Shipped <name> v<version>
   Commit: <short-hash>
   Tag: <name>-v<version>
   Don't forget: git push && git push --tags
   ```

## Stage 6: Install

Deploy the newly created skill to `~/.claude/skills/` so it's immediately usable.

1. **Re-derive REPO_ROOT** (Claude does not share shell state between tool calls):
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   ```

2. **Resume guard.** Check if already installed:
   ```bash
   if [ -L "$HOME/.claude/skills/<name>/SKILL.md" ]; then
     echo "Skill <name> already installed, skipping."
   fi
   ```
   If the symlink exists, print the step 4 success message and skip to end of stage.

3. **Run install:**
   ```bash
   "$REPO_ROOT/scripts/skills-deploy" install <name>
   ```

4. If install succeeds, print:
   ```
   Skill <name> installed to ~/.claude/skills/<name>/
   ```

5. If install fails (non-zero exit), print a warning but do NOT exit with error:
   ```
   WARNING: Auto-install failed. The skill is committed and shipped.
   Run manually: scripts/skills-deploy install <name>
   ```

## Error Handling

- If any script exits non-zero, capture stderr, show the error to the user, and do NOT
  proceed to the next stage. The user can fix the issue and re-invoke `/skill-author <name>`
  to resume from where they left off (file existence determines progress).
- If the user provides an invalid skill name, show the validation error and ask for
  a corrected name. Do not run any scripts until the name is valid.
- If skill-check.sh fails repeatedly (3 times), stop the fix loop and present the
  remaining errors to the user for manual resolution.

## Important Rules

- **Do NOT skip stages.** Each stage depends on the previous one's artifacts.
- **Check file existence before running scripts.** This is the resume mechanism.
  Scripts exit 1 if their output files already exist.
- **The Author stage is where the value is.** Spend time on good questions and
  good SKILL.md content. The other stages are mechanical.
- **Show, don't assume.** After writing SKILL.md, show it to the user before proceeding.
  After version bump, show the changelog entry. Before ship, show the diff.
