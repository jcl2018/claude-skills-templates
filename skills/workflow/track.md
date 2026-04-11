# track — Phase 1: Work Item Management

Subcommand of /workflow. Handles all work item document operations: scaffolding,
evidence synthesis, CRUD, lifecycle management.

Shared context (branch, work item, phase) is already resolved by SKILL.md.
Do not re-resolve.

## Subcommands

Detect from user input after `/workflow track`:
- `create` — scaffold a new work item
- (no subcommand) — evidence synthesis for current work item
- `journal` — add a manual journal entry
- `milestones` — CRUD milestone entries
- `list` — list all work items with status and risk badges
- `close` — close a work item
- `scrum` — generate scrum notes
- `child-items` — create sub-tasks under a feature

## Create

### Parse arguments
- `--type` or `-t`: feature | defect | task | user-story | review (required, ask if missing)
- `--slug` or `-s`: work item slug (default: from branch name)
- `--parent`: parent work item ID (required for user-story and task)

### Read artifact manifest
```bash
MANIFEST="$REPO_ROOT/artifact-manifests.json"
[ -f "$MANIFEST" ] || MANIFEST=~/.claude/artifact-manifests.json
[ -f "$MANIFEST" ] && echo "MANIFEST: $MANIFEST" || echo "NO_MANIFEST"
```

If found, extract required/optional artifacts for the type. Fallback defaults:
- feature: TRACKER.md, PRD.md, ARCHITECTURE.md, TEST-SPEC.md, milestones.md
- defect: TRACKER.md, RCA.md, test-plan.md
- task: TRACKER.md, test-plan.md
- user-story: TRACKER.md, PRD.md, ARCHITECTURE.md, TEST-SPEC.md, milestones.md
- review: TRACKER.md, review-notes.md

### Validate templates
Check templates via 3-level fallback chain (matches contracts/SKILL.md pattern):
```bash
TEMPLATE_DIR=""
for dir in "$REPO_ROOT/templates" "$HOME/.claude/spec/templates" "$HOME/.claude/templates"; do
  [ -d "$dir" ] && TEMPLATE_DIR="$dir" && break
done
[ -n "$TEMPLATE_DIR" ] && echo "TEMPLATES: $TEMPLATE_DIR"
for t in tracker-{type}.md doc-PRD.md doc-ARCHITECTURE.md doc-TEST-SPEC.md; do
  [ -f "$TEMPLATE_DIR/$t" ] && echo "OK: $t" || echo "MISSING: $t"
done
```
If TEMPLATE_DIR is empty (no directory found), report:
"Templates not found in:
  - $REPO_ROOT/templates/ (repo-local)
  - ~/.claude/spec/templates/ (user spec)
  - ~/.claude/templates/ (skills-deploy)
Run `skills-deploy install` from your claude-skills-templates clone,
or copy the templates/ directory into your repo root."
Stop. Do not proceed without templates.

If TEMPLATE_DIR is found but required templates are missing, report which
templates are missing and stop.

### Scaffold
```bash
ITEM_DIR="$WORK_DIR/{slug}"
mkdir -p "$ITEM_DIR"
```

For each artifact: read template, replace placeholders ({ITEM_NAME}, {ITEM_ID},
{PARENT_ID}, {FEATURE_ID}, {YYYY-MM-DD}, {BRANCH_NAME}, {author}), write to ITEM_DIR.

If generation guides exist (guide-*.md in spec/reference/ or GENERATION-GUIDE.md),
read for type-specific instructions and pre-populate content.

### Post-scaffold
- Add Log entry: `- {date}: Created. {brief description}`
- Report: work item slug, type, directory, artifacts created
- Write handoff: `<!-- HANDOFF: phase=track status=complete next=/workflow implement -->`

## Evidence Synthesis (default)

When `/workflow track` runs without a subcommand on an active work item:
1. Get recent git history scoped to this branch:
   ```bash
   BASE=$(git merge-base main HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null)
   git log --oneline "$BASE"..HEAD 2>/dev/null
   ```
2. Group commits: "fix/debug/investigate" -> finding, "decide/choose/switch" -> decision, other -> implementation
3. Propose journal entries with commit SHAs
4. Ask user: "Add these journal entries?" via AskUserQuestion
5. If approved, append to Journal section

## Journal

Ask via AskUserQuestion:
- Type: decision | finding | blocker
- Summary: one-line description

Append to tracker: `### {date} -- {type}\n{summary}`

## Milestones

CRUD operations on milestones.md. Read if exists, create if not.

## List

Scan WORK_DIR for all TRACKER.md files. For each, read frontmatter and calculate risk:
- Past target date -> OVERDUE
- Within 3 days -> URGENT
- Within 7 days -> AT RISK

Display as table: `| # | Name | Type | Status | Branch | Risk | Updated |`

## Close

1. Set `status: done` and add `closed: {date}` in frontmatter
2. Add Log entry: `- {date}: Closed.`
3. Regenerate INDEX.md if it exists

## Scrum

Generate scrum notes from milestones + git activity + journal since last scrum.
Write to `$ITEM_DIR/scrum-{date}.md`.

## Child Items

Create sub-items under a feature (max depth 3: feature -> user-story -> task).
Child directory: `$ITEM_DIR/{child-slug}/`. Register in parent Todos section.

## Rules

- **Manifest-driven scaffolding.** Read artifact-manifests.json first. Hardcoded defaults are fallback only.
- **Template validation.** Check templates exist before scaffolding. Fail loudly if missing.
- **No code modification.** This subcommand manages work item documents only.
- **Evidence requires approval.** Never commit proposed journal entries without user confirmation.
- **Handoff block.** Write after completing any operation.
