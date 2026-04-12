# Philosophy

## Why this repo exists

Claude Code follows structured instructions reliably. That means the hard part of doc-first development is not getting AI to follow a process, it's having good templates to follow. This repo exists because the templates and the `work-items/` directory pattern are the actual product. The skills that used to orchestrate them (/workflow, /contracts) turned out to be thin wrappers around what Claude Code does naturally when given clear CLAUDE.md rules.

The target user is a solo developer using Claude Code who wants lightweight lifecycle management without adopting a project management platform. Work items live in the repo. Templates live in `~/.claude/templates/`. No external service required.

## Design principles and tradeoffs

**1. Templates over orchestration.** The repo started with 7 skills orchestrating a 4-phase workflow pipeline. After real usage, 5 were deleted. The logic that survived moved to CLAUDE.md rules (`rules/work-items.md`) and `artifact-manifests.json`. The tradeoff: less guardrail enforcement in exchange for less code to maintain. Evidence: commits `8a03260` (delete /workflow and /contracts) and `38abd03` (deliver rules via skills-deploy).

**2. Absorb what you own, compose what you don't.** When the /docs skill needed template enforcement (formerly /contracts), it absorbed the logic directly rather than calling a sibling skill. But for post-ship doc updates, it composes with gstack's `/document-release` rather than reimplementing. The tradeoff: absorbing means you maintain it, composing means you depend on upstream. Evidence: `skills/docs/DESIGN.md` key decision #1.

**3. Filesystem as protocol.** Parent/child relationships are expressed by directory nesting (`work-items/F000001/S000001/T000001/`). Work item types are determined by branch naming conventions (`feat/*` = feature, `fix/*` = defect). Template resolution follows a 2-level fallback chain (`templates/` then `~/.claude/templates/`). The tradeoff: no database, no API, no sync, but the conventions must be documented and followed. Evidence: `rules/work-items.md`, `artifact-manifests.json`.

**4. Declare, don't hardcode.** `artifact-manifests.json` is the single source of truth for which artifacts each work item type requires. The manifest drives scaffolding, validation, and template resolution. Adding a new artifact type means adding one JSON entry, not editing 5 files. The tradeoff: one more file to keep in sync. Evidence: `artifact-manifests.json` v2.0.0.

**5. Flag, don't fix.** `/docs check` detects staleness and drift but never auto-regenerates content. Philosophy docs need the human's voice. Work item validation flags missing sections but doesn't auto-fix. The tradeoff: more manual work, but no surprise overwrites. Evidence: `skills/docs/DESIGN.md` key decision #3.

## What this intentionally does NOT optimize for

- **Teams or collaboration.** Work items have no assignee field. No locking, no merge conflict resolution for trackers. This is a solo dev tool.
- **Universal portability.** Templates assume CLAUDE.md conventions, gstack patterns, and the `work-items/` directory structure. They won't work in an arbitrary repo without adaptation.
- **Runtime enforcement.** CLAUDE.md rules are passive instructions. Nothing prevents a developer from scaffolding a feature without a PRD. `/docs check` catches drift after the fact, not before.
- **Scalability beyond ~50 work items.** The directory-nesting model with max depth 3 works for solo projects. It would not work for a 200-person engineering org.

## Key patterns and conventions

**Template naming prefixes** (`templates/`):
- `doc-*.md` for scaffolding templates (used when creating new docs)
- `contract-*.md` for enforcement reference templates (define what good docs look like)
- `tracker-*.md` for work item lifecycle trackers (one per type: feature, defect, task, user-story)
- `*-GENERATION-GUIDE.md` for doc generation instructions

**Skill directory structure** (`skills/{name}/`):
- `SKILL.md` required, with YAML frontmatter (`name`, `description`, `version`, `allowed-tools`)
- `CHANGELOG.md` for version history
- `DESIGN.md` for design decisions
- Supporting `*.md` files for subcommands (e.g., `init.md`, `check.md`)

**Work item hierarchy** (`work-items/{slug}/`):
- `TRACKER.md` at every level (feature > user-story > task, max depth 3)
- Doc triplet artifacts (PRD, ARCHITECTURE, TEST-SPEC) for features and user-stories
- ID-prefixed filenames (`F000001_PRD.md`) to avoid collisions
- ID format: `{TYPE_PREFIX}{NNNNNN}` where prefix is F/S/T/D

**Version management:**
- 4-digit `VERSION` file at repo root (`MAJOR.MINOR.PATCH.MICRO`)
- Per-skill versions in SKILL.md frontmatter (semver)
- `skills-catalog.json` tracks all skill versions and template ownership
- Collection version bumps on every ship

## How to extend without breaking its character

**Adding a new work item type:** Add an entry to `artifact-manifests.json` with its required artifacts and template filenames. Create the tracker template (`tracker-{type}.md`) and any doc templates. Add the branch naming pattern to `rules/work-items.md`. The validation in `/docs check` will pick it up automatically via the manifest.

**Adding a new skill:** Create `skills/{name}/SKILL.md` with frontmatter. Add a catalog entry to `skills-catalog.json`. Run `./scripts/validate.sh`. The skill is discovered automatically by Claude Code.

**Adding a new template:** Add the file to `templates/`. Register it in `skills-catalog.json` under the appropriate catalog entry's `templates` array. Run `./scripts/skills-deploy install` to deploy globally.

**Anti-patterns to avoid:**
- Don't create orchestration skills that wrap existing gstack skills (they'll end up deleted like /workflow)
- Don't hardcode template lists in skill logic (read `artifact-manifests.json` instead)
- Don't add $AI_CONTENT_DIR indirection (use `./work-items/` directly)
- Don't add team collaboration features (assignees, locking, notifications)

## Dependencies and assumptions

**Runtime:** Git (for history, branching, commit SHAs). Bash (for scripts). `jq` (recommended for JSON parsing in scripts, optional).

**Claude Code ecosystem:** Skills are discovered from `~/.claude/skills/`. Templates deploy to `~/.claude/templates/`. Rules deploy to `~/.claude/rules/`. The `skills-deploy` script manages symlinks and manifests at `~/.claude/.skills-templates.json`.

**gstack (optional):** `/docs` composes with gstack's `/document-release` for post-ship doc updates. `/system-health` optionally invokes waza for config hygiene. Neither is required for core functionality.

**Assumptions:** The developer uses branch naming conventions for work item type detection. Templates exist either in `templates/` (repo root) or `~/.claude/templates/` (deployed globally). `artifact-manifests.json` is at repo root and matches the templates on disk.

## Failure modes and maintenance risks

**Template drift.** If `artifact-manifests.json` is updated but templates are not (or vice versa), scaffolding produces wrong artifacts. `/docs check` catches this, but only if someone runs it. Mitigation: `./scripts/validate.sh` checks template references at commit time.

**Stale CLAUDE.md rules.** The rules in `rules/work-items.md` are deployed globally via `skills-deploy`. If the source rules change but `skills-deploy install` isn't re-run, deployed rules go stale. Mitigation: `skills-deploy doctor` detects drift via SHA256 checksums.

**ID collision.** Work item IDs are auto-incremented from the highest existing ID in `work-items/`. If two sessions scaffold simultaneously, they could generate the same ID. Low risk for solo dev. Mitigation: none (accepted limitation for solo use).

**claims.json desync.** The `.docs/claims.json` sidecar maps doc sections to evidence files by commit SHA. If history is rewritten (rebase, force-push), stored SHAs become unreachable and staleness detection breaks gracefully with UNVERIFIABLE flags. Mitigation: re-run `/docs init` to rebuild the baseline.

**Skill-catalog version drift.** If a skill's SKILL.md frontmatter version doesn't match its catalog entry, `validate.sh` catches it. But nothing prevents manual edits that create drift between ship cycles.
