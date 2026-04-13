# TODOS

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

### ~~Add `/docs check` and `/docs tree` to Phase 3 review gates (P2, S)~~ DONE
Already present in all 4 tracker templates. Phase 3 gates include `/docs check` and
`/docs tree` (feature/user-story) or `/docs check` (task/defect).

### Stale example output in check.md and tree.md (P2, S)
check.md (lines 352-363, 399, 438-442) and tree.md (lines 73-84) reference
deleted work items S000002, S000003, T000002, T000003 and show "3 user-story children"
instead of 1. These are illustrative examples in skill instructions that may mislead
Claude when formatting output.
**Found by:** Claude adversarial review, 2026-04-13 (chore/close-f000001)

### Sync global rules with repo-local rules (P2, S)
`~/.claude/rules/work-items.md` still says features get full doc triplet and uses
2-level fallback chain. Repo-local `rules/work-items.md` was updated (feature = tracker only,
3-level fallback). Run `skills-deploy install` or manually sync.
**Found by:** Claude adversarial review, 2026-04-13

### Template fallback chain inconsistency (P3, S)
Three different descriptions exist: CLAUDE.md and rules say 3-level
(`templates/` > `~/.claude/spec/templates/` > `~/.claude/templates/`),
but PHILOSOPHY.md, check.md, and docs CHANGELOG say 2-level (missing spec dir).
The check.md implementation uses 2 levels, so `~/.claude/spec/templates/` is silently
ignored during validation while being used during scaffolding.
**Found by:** Claude adversarial review, 2026-04-13

### validate.sh structural check via graph JSON (P2, M)
Add structural completeness check to validate.sh by reading `work-item-graph.json`
badges instead of doing its own YAML parsing. Catches structural violations in
pre-commit, not just when someone runs `/docs check`.
**When:** After graph artifact schema (v1.0.0) is proven stable.
**Depends on:** `.docs/work-item-graph.json` emitted by `/docs check` Steps 15-17.

### Behavioral eval harness (P1, M) — PRIORITY
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.
**When:** Next priority.
**Depends on:** validate.sh

### ~~Batch version mode for multi-skill commits (P3, S)~~ SIMPLIFIED
Simplified by collection versioning. Use `collection-version.sh bump patch`.
**Depends on:** collection-version.sh
