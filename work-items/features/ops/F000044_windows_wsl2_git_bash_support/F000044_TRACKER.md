---
name: "Windows (WSL2 + Git Bash) support for the skills workbench"
type: feature
id: "F000044"
status: active
created: "2026-06-03"
updated: "2026-06-03"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-234927-99694"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/windows_wsl2_git_bash_support`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `./scripts/test.sh` stays green on macOS (unchanged) AND passes on Git Bash via a `windows-latest` CI job, plus new Darwin-gated-path tests pass on the existing `ubuntu-latest` CI
- [ ] A fresh clone on Windows (Git-for-Windows, `core.autocrlf=true`) checks out every `*.sh` with LF endings — no `#!/usr/bin/env bash\r` shebang breakage
- [ ] `skills-deploy install` + `skills-deploy doctor` succeed on Git Bash (copy-mode) and on WSL2 (symlink-mode)
- [ ] `CJ_suggest` + `CJ_improve-queue` run (do not refuse) on WSL2 + Git Bash, with correct date math

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000077 — CRLF safety (`.gitattributes`)
- [ ] S000078 — portable POSIX runtime (inline `date_to_epoch` + widen the two `uname` Darwin gates) — "runs on WSL2"
- [ ] S000079 — symlink-free copy-mode install in `skills-deploy` + new manifest `install_kind`/`source_checksum` (the L-effort risk item) — "runs on Git Bash"
- [ ] S000080 — `windows-latest` CI job + docs

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Windows (WSL2 + Git Bash) support, Approach B (POSIX-clean), scaffolded from office-hours design doc `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260603-233220.md`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `.gitattributes` (new — S000077)
- `skills/CJ_suggest/scripts/suggest.sh` (portable date + gate — S000078)
- `skills/CJ_improve-queue/scripts/improve_queue.sh` (portable date + gate — S000078)
- `scripts/skills-deploy` (copy-mode install + manifest schema + doctor/remove/relink branching — S000079)
- `scripts/test-deploy.sh`, `scripts/test.sh` (both-mode coverage — S000079; repo blind-spot: edit in parallel)
- `.github/workflows/` (windows-latest job — S000080)
- `README.md`, `CLAUDE.md` (Running on Windows docs — S000080)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- "Native Windows" is illusory for a Claude Code skills repo: Claude Code runs skill bash preambles through Git Bash/WSL, so the only real Windows targets are POSIX layers. WSL2 sidesteps the symlink-install rewrite (real symlinks); Git Bash forces it.
- The runtime manifest (`~/.claude/.skills-templates.json`) stores NO per-skill-file checksum — skill records are `{path, installed_at}` only; `source_checksum` exists for templates/rules only. Copy-mode `doctor` therefore needs a new manifest schema. This is why S000079 is L-effort.
- Partial Windows hardening already exists (`scripts/lib.sh` `jq()` CRLF shim, MINGW handling in several scripts). Build on it; do not duplicate.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- **[decision]** 2026-06-03 — Summary: Rejected native cmd/PowerShell. It would require a parallel reimplementation of all 42 bash scripts and still would not satisfy the skills' bash preambles; the `work-copilot/` Python bundle already serves non-bash Windows consumers. Chose Approach B (WSL2 + Git Bash POSIX support).
- **[decision]** 2026-06-03 — Summary: bash stays the implementation language. Portability comes from portable date math + a widened OS gate + a capability-probed install, not a language rewrite.
