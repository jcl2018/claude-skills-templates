---
skill-name: "CJ_repo-init"
version: 0.1.0
status: experimental
created: "2026-06-03"
last-updated: "2026-06-04T01:07:15Z"
---

# Skill Usage: CJ_repo-init

## When to use

- "set up this repo for the CJ skills", "init repo prerequisites", "make this
  repo ready for CJ_", "bootstrap repo config", "verify repo prerequisites"
- You just deployed the CJ_ skill family (`skills-deploy install`) into a fresh
  clone or a brand-new target repo and want to confirm the per-repo config files
  exist before running an orchestrator
- A `cj_goal` orchestrator HALTed with `[doc-sync-no-config]`, or `/CJ_suggest`
  exited 1 — both point at a missing per-repo prerequisite this skill creates
- You want a one-shot health table of which prereqs your deployed skills need
  and which are present

## When NOT to use

- You want to **install** skills/templates into `~/.claude/` — that's
  `setup.sh` / `skills-deploy install`. This skill reports install-level gaps
  but never installs.
- You want a `~/.claude/` install-health dashboard — that's `/CJ_system-health`
  / `skills-deploy doctor`.
- You want to start or ship work — this skill is in-place only (no worktree, no
  branch, no commit, no `/ship`).
- You want to set up one specific skill's prereqs on demand (`--add <skill>`) —
  deferred; v1 is whole-repo detect-and-fix.

## Mental model

Three phases, all in one testable bash engine (`scripts/cj-repo-init.sh`):
(1) **detect** which CJ_ skills are deployed (read
`~/.claude/.skills-templates.json`; fall back to `ls ~/.claude/skills/CJ_*`,
then repo-local `skills/` for self-dev); (2) **map** each detected skill to its
per-repo prerequisite(s) and **verify** the union (existence — plus, for
`cj-document-release.json`, parseable JSON with a supported `schema_version`,
mirroring `validate.sh` Check 16); (3) on `--fix`, **scaffold** the missing
repo-level prerequisites from inline generic portable seeds.

The SKILL.md prose wraps phases 1+2 (always) and gates phase 3 behind exactly
one confirm AskUserQuestion — the documented detection-in-script / AUQ-in-prose
split (precedent: `skills-doc-sync-check`). The script never prompts; the prose
never re-implements detection. Default and `--dry-run` write nothing; exit 0
when no repo-level gaps remain, 1 when they do (install-level gaps are reported
but do not fail the repo-level contract).

## Common pitfalls

- **Expecting it to install skills.** It only scaffolds repo-level config files.
  An `INSTALL_GAP` line means you still need `skills-deploy install` — the skill
  surfaces it as advisory and never auto-fixes it.
- **Expecting `--fix` to repair a broken config.** A present-but-invalid
  `cj-document-release.json` is reported as a gap but NOT overwritten — the
  engine prints a `NOTE:` telling you to fix it by hand (or remove + re-run).
  This avoids clobbering an intentional-but-malformed config.
- **Assuming the seeds carry workbench-specific paths.** They don't — the
  scaffolded `cj-document-release.json` uses a generic portable whitelist
  (README/CHANGELOG/CLAUDE.md/CONTRIBUTING.md + `doc/**/*.md`), so it's safe to
  adopt in any repo. The workbench's own richer config is hand-maintained, not
  produced by this skill.
- **Forgetting it doesn't commit.** Scaffolded files land uncommitted; commit
  them via `/ship` or `git` yourself.

## Related skills

- `/CJ_system-health` — sibling read-only utility; audits `~/.claude/` install
  health (this skill audits the *repo*, not the install).
- `/CJ_document-release` — the primary consumer of `cj-document-release.json`;
  HALTs `[doc-sync-no-config]` without it, which this skill prevents.
- `/CJ_suggest` / `/CJ_goal_todo_fix` / `/CJ_improve-queue` — consumers of
  `TODOS.md`, which this skill scaffolds.
- `/CJ_scaffold-work-item` — first consumer of the `work-items/` tree this skill
  pre-creates.
