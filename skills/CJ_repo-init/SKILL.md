---
name: CJ_repo-init
description: "Detect which CJ_ skills are deployed, verify each one's per-repo prerequisites (cj-document-release.json, CJ-DOC-RELEASE.md, TODOS.md, work-items/ tree), print a health table, and on one confirm scaffold the missing repo-level prerequisites from generic portable seeds. Standalone utility — in-place, no worktree/ship. Use when: 'set up this repo for the CJ skills', 'init repo prerequisites', 'make this repo ready for CJ_', 'bootstrap repo config', 'verify repo prerequisites'."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

## Overview

`/CJ_repo-init` is a standalone utility that closes the seam between "the CJ_
skills are installed under `~/.claude/`" and "the CJ_ skills actually work in
this repo." A repo can have every skill deployed and still fail at runtime
because a per-repo config file is missing:

- `/CJ_document-release` HALTs with `[doc-sync-no-config]` if
  `cj-document-release.json` is absent — and it runs at Step 5.5 of every
  `cj_goal` orchestrator, so a missing config breaks `/CJ_goal_feature`,
  `/CJ_goal_defect`, and `/CJ_goal_todo_fix`.
- `CJ-DOC-RELEASE.md` is the canonical prose contract for `/CJ_document-release`
  (the human/agent read that the machine config `cj-document-release.json`
  documents). It is checked for presence + a small required-headings set; needed
  by the same skills as `cj-document-release.json`.
- `/CJ_suggest`, `/CJ_goal_todo_fix`, and `/CJ_improve-queue` exit 1 if
  `TODOS.md` is missing.
- The scaffold → implement → qa pipeline expects a `work-items/` tree.

This skill detects which CJ_ skills are deployed, maps each to its per-repo
prerequisite(s), verifies the union, prints a health table, and (on one
confirm) scaffolds the missing **repo-level** prerequisites from generic
portable seeds. Idempotent: re-running on a healthy repo is a no-op that just
prints the health table. In-place only — **no worktree, no branch, no `/ship`.**

## Architecture (detection-in-script / AUQ-in-prose)

This skill follows the workbench's documented split (CLAUDE.md "Novel pattern
callout", precedent `scripts/skills-doc-sync-check`): the detection +
verification + scaffolding logic lives in a testable bash engine
(`scripts/cj-repo-init.sh`); this SKILL.md prose owns the single confirm
AskUserQuestion. The script never prompts; the skill never re-implements
detection.

## Steps

### Step 1: Resolve the engine path

The engine lives in the user's clone at `<source>/scripts/cj-repo-init.sh` (same
path-resolution shape as `skills-update-check` / `skills-doc-sync-check`). Prefer
the repo-local copy when running inside the workbench; otherwise resolve via the
deployed manifest's `.source` field:

```bash
_RI=""
if [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/scripts/cj-repo-init.sh" ]; then
  _RI="$(git rev-parse --show-toplevel)/scripts/cj-repo-init.sh"
else
  _SRC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  [ -n "$_SRC" ] && [ -x "$_SRC/scripts/cj-repo-init.sh" ] && _RI="$_SRC/scripts/cj-repo-init.sh"
fi
[ -z "$_RI" ] && { echo "Error: cj-repo-init.sh not found. Run skills-deploy install or run from the workbench."; exit 2; }
echo "ENGINE: $_RI"
```

If the engine is not found, tell the user to run `skills-deploy install` (or to
run from inside the workbench) and stop.

If the engine reports "not inside a git repository" (exit 2), surface that
message verbatim and stop — `/CJ_repo-init` operates on a repo's per-repo files.

### Step 2: Run detection (always)

Run the engine in default mode and capture stdout + exit code:

```bash
OUT=$(bash "$_RI"); RC=$?
echo "$OUT"
```

Print the health table to the operator exactly as the engine emitted it (the
`prereq | needed-by | status` table). Read the machine-readable tail:

- `GAPS=<n>` — number of **repo-level** gaps.
- `INSTALL_GAPS=<n>` — number of **install-level** gaps (reported, never
  auto-fixed by this skill).
- One `REPO_GAP <prereq> <detail>` line per repo-level gap.
- One `INSTALL_GAP <prereq> <detail>` line per install-level gap.

### Step 3: Branch on the gap count

**If `GAPS=0`:** the repo is healthy at the repo level. Print a one-line
confirmation ("Repo prerequisites: all present"). If `INSTALL_GAPS>0`, relay the
`INSTALL_GAP` line(s) verbatim as advisory follow-up (they require
`skills-deploy install`, which this skill never runs). Then stop — no AUQ, no
writes. This is the idempotent no-op path.

**If `GAPS>0`:** surface **exactly ONE** AskUserQuestion. Quote the `REPO_GAP`
lines so the operator sees precisely what will be created:

> This repo is missing {N} CJ_ prerequisite(s):
>   {one REPO_GAP line each}
>
> Scaffold them now from generic portable seeds (creates `cj-document-release.json`,
> `CJ-DOC-RELEASE.md`, `TODOS.md`, and/or the `work-items/` dirs — repo-level
> only; nothing under `~/.claude/` is touched)?
>
> Options:
> - Scaffold now (recommended) — runs `--fix` and re-prints the health table
> - Dry-run only — re-print the report; make no changes
> - Cancel — stop without changes

Install-level gaps (`INSTALL_GAP`) are NOT part of the scaffold offer — relay
them as advisory text alongside the AUQ; they require `skills-deploy install`.

### Step 4: Act on the choice

- **Scaffold now:** run `bash "$_RI" --fix`, print its full output (post-fix
  table + `Scaffolded:` list). The engine re-verifies internally, so the printed
  table is the authoritative post-fix state. Confirm to the operator which files
  were created. If any `cj-document-release.json` was present-but-invalid, the
  engine prints a `NOTE:` that it was NOT overwritten — relay that verbatim so
  the operator fixes it by hand.
- **Dry-run only:** run `bash "$_RI" --dry-run` and print its output. No writes.
- **Cancel:** print "Cancelled — no changes made." and stop.

### Step 5: Done

This skill makes no commits and creates no branch. If the operator wants the
scaffolded files committed, that is a separate `/ship` (or manual `git`) step
they drive themselves. Re-running `/CJ_repo-init` on the now-healthy repo is a
clean no-op (Step 3, `GAPS=0`).

## Usage

```
/CJ_repo-init
```

No arguments. The single confirm AUQ is the only interaction, and only when
repo-level gaps exist.

## Error handling

| Condition | Behavior |
|---|---|
| Engine not found | Print "Run skills-deploy install or run from the workbench." and stop (exit 2). |
| Not a git repo | Engine exits 2 with a clear message; relay verbatim and stop. |
| `GAPS=0` | No-op: print the health table + a one-line confirmation; no AUQ. |
| Present-but-invalid `cj-document-release.json` | Reported as a gap; `--fix` does NOT overwrite it — relays a `NOTE:` to fix by hand. |
| Present-but-invalid `CJ-DOC-RELEASE.md` (missing required headings) | Reported as a gap; `--fix` does NOT overwrite it — relays a `NOTE:` to fix by hand. |
| Install-level gap | Reported as advisory; never auto-fixed (owned by `skills-deploy install`). |
