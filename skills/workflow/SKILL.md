---
name: workflow
description: "Dev workflow pipeline: track, implement, review, ship. Branch-aware routing with doc contract quality gates."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
  - Skill
---

## Preamble

Log skill usage so `/system-health` can track which skills are actually used:

```bash
mkdir -p ~/.gstack/analytics
echo '{"skill":"workflow","ts":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","repo":"'"$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo unknown)"'"}' >> ~/.gstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

# /workflow — Dev Workflow Pipeline

Single entry point for the 4-phase dev workflow: track, implement, review, ship.
Branch-aware routing resolves the active work item and dispatches to the right phase.

## Subcommand Routing

Detect the subcommand from the user's input:

- `/workflow` (no subcommand) — show status menu with phase progress
- `/workflow track [sub]` — work item management (read track.md and follow it)
- `/workflow implement` — build or debug (read implement.md and follow it)
- `/workflow review` — code review with contract gate (read review.md and follow it)
- `/workflow ship` — ship with spec validation (read ship.md and follow it)

For each subcommand, read the corresponding .md file in this skill directory
and follow its instructions. The file path is relative to this SKILL.md:
- track.md for `/workflow track`
- implement.md for `/workflow implement`
- review.md for `/workflow review`
- ship.md for `/workflow ship`

### Two-Level Dispatch for Track

`/workflow track` supports sub-subcommands. Pass the full argument through:
- `/workflow track create` -> track.md, create subcommand
- `/workflow track journal` -> track.md, journal subcommand
- `/workflow track milestones` -> track.md, milestones subcommand
- `/workflow track list` -> track.md, list subcommand
- `/workflow track close` -> track.md, close subcommand
- `/workflow track scrum` -> track.md, scrum subcommand
- `/workflow track child-items` -> track.md, child-items subcommand
- `/workflow track` (no sub) -> track.md, evidence synthesis (default)

## Shared Context Resolution

All subcommands share this context. Resolve it once before dispatching.

### Branch Detection

```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $BRANCH"
```

Match against these patterns:
- `feature-*` or `feat-*` or `feat/*` -> type=feature, slug=remainder
- `defect-*` or `fix-*` or `fix/*` or `bugfix-*` -> type=defect, slug=remainder
- `task-*` or `chore-*` or `chore/*` -> type=task, slug=remainder
- `story-*` -> type=user-story, slug=remainder
- `review-*` -> type=review, slug=remainder

If no pattern matches and the user gave a subcommand, warn:
"Branch `{BRANCH}` doesn't match a work item pattern. Create one with
`/workflow track create` or switch to a matching branch."

### Work Item Resolution

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
WORK_DIR="$REPO_ROOT/work-items"
[ -d "$WORK_DIR" ] && echo "WORK_DIR: $WORK_DIR" || echo "NO_WORK_DIR"
```

If WORK_DIR exists, search for a matching tracker:
```bash
find "$WORK_DIR" -name "TRACKER.md" -path "*${SLUG}*" 2>/dev/null | head -5
```

If found, read the tracker frontmatter: name, type, status, phase progress.
If not found, offer: "No work item for `{SLUG}`. Create with `/workflow track create`."

### Phase Detection

Read the tracker's Lifecycle section. Check which phases have all checkboxes checked:
- Phase 1 (Track): all `- [x]` -> Track complete
- Phase 2 (Implement): all `- [x]` -> Implement complete
- Phase 3 (Review): all `- [x]` -> Review complete
- Phase 4 (Ship): all `- [x]` -> Ship complete

Backward compatibility: treat `- [x] Investigate` the same as `- [x] Implement`.

Current phase = first incomplete phase.

## Status Menu Display

When `/workflow` is invoked without a subcommand, show the status menu:

```
Work Item: {name}
Type: {type} | Status: {status} | Branch: {BRANCH}
Phase: {current_phase} of 4

Lifecycle:
  [done/todo] Track      — {complete/incomplete}
  [done/todo] Implement  — {complete/incomplete}
  [done/todo] Review     — {complete/incomplete}
  [done/todo] Ship       — {complete/incomplete}
```

Options based on current phase:
- If Track incomplete -> "A) /workflow track — scaffold artifacts and track progress"
- If Implement is next -> "A) /workflow implement — build or debug"
- If Review is next -> "A) /workflow review — code review"
- If Ship is next -> "A) /workflow ship — ship it"
- Always: "B) /workflow track — update journal, milestones, or close"

When the user selects, dispatch to the corresponding subcommand.

## Template Reference

All templates live in the repo root `templates/` directory:
- `tracker-*.md` for work item trackers (feature, defect, task, user-story, review)
- `doc-*.md` for doc artifacts (PRD, ARCHITECTURE, TEST-SPEC, RCA, etc.)
- `contract-*.md` for contract enforcement templates

Subcommands reference templates by name. Resolution order:
1. `$REPO_ROOT/templates/` (this repo)
2. `~/.claude/spec/templates/` (user spec system)
3. `~/.claude/templates/` (legacy fallback)

## No Work Items Directory

If `./work-items/` does not exist:
"This project has no work-items/ directory. Start with `/workflow track create`
to create your first work item. The directory will be created automatically."

## Rules

1. **Branch is the key.** The branch name determines which work item is active.
2. **Shared context once.** Resolve branch, work item, and phase before dispatching.
   Do not re-resolve in subcommand files.
3. **Handoff protocol.** Each phase writes a handoff block pointing to the next:
   `<!-- HANDOFF: phase={name} status={status} next=/workflow {next} -->`
4. **Journal everything.** Every phase transition, decision, and outcome gets a journal entry.
5. **One question at a time.** Present options, wait for selection, then act.
6. **Never mutate in router.** The status menu (no subcommand) is read-only. All writes happen in subcommands.
