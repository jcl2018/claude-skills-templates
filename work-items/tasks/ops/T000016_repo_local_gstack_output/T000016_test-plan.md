---
type: test-plan
parent: T000016
title: "repo-local-gstack-output — Test Plan"
date: 2026-05-09
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Add two scripts and supporting docs that redirect `~/.gstack/projects/jcl2018-claude-skills-templates/` into `<main-repo>/.gstack/` via symlink, and configure `.gitignore` so design/plan/review artifacts commit while machine-local state (sessions/, analytics/, learnings.jsonl, .gbrain*, etc.) stays local.

Files modified:
- `scripts/setup-gstack-symlink.sh` — new. Idempotent setup; `--force` flag for re-pointing or merging non-empty targets.
- `scripts/teardown-gstack-symlink.sh` — new. Reversal; refuses to revert if symlink points elsewhere.
- `.gitignore` — add `.gstack/sessions/`, `.gstack/analytics/`, `.gstack/learnings.jsonl`, `.gstack/timeline.jsonl`, `.gstack/.gbrain*`, `.gstack/.brain-*`, `.gstack/.pending-*`, `.gstack/tmp/`.
- `README.md` — add per-machine onboarding section (`cd <repo> && ./scripts/setup-gstack-symlink.sh`).
- `CLAUDE.md` — document `.gstack/` (lateral/exploratory) vs `work-items/` (structured per-feature) split.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Fresh setup — real dir at SRC, no DEST | 1. Ensure `~/.gstack/projects/jcl2018-claude-skills-templates/` is a real dir with content. 2. Ensure `<main-repo>/.gstack/` does NOT exist. 3. `cd <main-repo> && ./scripts/setup-gstack-symlink.sh`. | Migrates contents into `<main-repo>/.gstack/`; backs up SRC to `$SRC.bak.<ts>`; creates symlink. `readlink ~/.gstack/projects/jcl2018-claude-skills-templates` returns `<main-repo>/.gstack`. | Pending |
| 2 | Idempotent re-run — symlink already correct | 1. After test #1 succeeds. 2. Re-run `./scripts/setup-gstack-symlink.sh`. | Detects existing correct symlink; prints "Symlink already correct"; exits 0; no filesystem changes. | Pending |
| 3 | Symlink points elsewhere — refuse without --force | 1. `ln -sf /tmp/somewhere ~/.gstack/projects/jcl2018-claude-skills-templates`. 2. Run setup without `--force`. | WARN about existing target; refuses; exits non-zero. SRC unchanged. | Pending |
| 4 | Symlink points elsewhere — re-point with --force | 1. Same setup as #3. 2. Run setup with `--force`. | Re-points symlink to `<main-repo>/.gstack/`; exits 0. | Pending |
| 5 | Non-empty DEST + content in SRC — refuse without --force | 1. `<main-repo>/.gstack/` has files. 2. SRC is a real dir with files. 3. Run setup without `--force`. | WARN listing existing DEST contents; refuses; exits non-zero. | Pending |
| 6 | Non-empty DEST + content in SRC — merge with --force | 1. Same setup as #5. 2. Run with `--force`. | rsync merges (SRC overwrites DEST on filename collisions); SRC backed up; symlink created. | Pending |
| 7 | Teardown — symlink points to expected DEST | 1. After successful setup. 2. `cd <main-repo> && ./scripts/teardown-gstack-symlink.sh`. | Removes symlink; rsyncs DEST contents back into SRC as a real dir. `<main-repo>/.gstack/` unchanged (separate cleanup if desired). | Pending |
| 8 | Teardown — symlink points to wrong target | 1. Manually point SRC to `/tmp/wrong`. 2. Run teardown. | ERR refusing to revert blindly; exits non-zero; symlink unchanged. | Pending |
| 9 | Write integration — gstack writes land in repo | 1. After setup. 2. Trigger a gstack skill that writes to project dir (e.g., `eval "$(~/.claude/skills/gstack/bin/gstack-slug)" && touch ~/.gstack/projects/$SLUG/integration-test.md`). 3. `cd <main-repo> && git status`. | `integration-test.md` appears as untracked file in `<main-repo>/.gstack/`. Cleanup: `rm <main-repo>/.gstack/integration-test.md`. | Pending |
| 10 | .gitignore correctness — designs track, machine-state ignored | 1. After setup, with migrated content. 2. `cd <main-repo> && git status -- .gstack/`. | Design docs (`*-design-*.md`), `ceo-plans/`, eng-review test plans show as untracked (will commit). `sessions/`, `analytics/`, `learnings.jsonl`, `.gbrain*` do NOT show (gitignored). | Pending |
| 11 | gstack-slug failure surfaces clearly | 1. Temporarily make `~/.claude/skills/gstack/bin/gstack-slug` non-executable. 2. Run setup. | gstack-slug stderr surfaces (no `2>/dev/null` swallow); script errors with `gstack-slug ran but emitted no SLUG`. | Pending |
| 12 | Run from worktree — resolves to main correctly | 1. From `<main-repo>/.claude/worktrees/relaxed-kowalevski-955b4b/`. 2. Run setup. | DEST resolves to `<main-repo>/.gstack/` (NOT the worktree's `.gstack/`); symlink at SRC points to main, not worktree. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` passes post-change.
- [ ] `./scripts/test.sh` passes post-change (full repo test suite — especially anything that walks `.` recursively or assumes file types vs symlinks).
- [ ] After setup, run any gstack skill (/office-hours short brainstorm, /context-save, /plan-ceo-review draft) and confirm output lands in `<main-repo>/.gstack/`, visible in `git -C <main-repo> status`.
- [ ] Run teardown, verify `~/.gstack/projects/jcl2018-claude-skills-templates/` returns to a real dir with the expected contents.
- [ ] Re-run setup post-teardown — verify clean migration loop.
- [ ] No new stderr noise during normal use (compare `wc -l` on stderr from a sample skill invocation against pre-change baseline).
- [ ] Re-run the gstack `! -L` audit grep documented in T000016_TRACKER.md Insights — confirms no new symlink-rejecting checks were introduced upstream that would break the symlink.

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 / zsh / git 2.x | claude/relaxed-kowalevski-955b4b | Pending |
