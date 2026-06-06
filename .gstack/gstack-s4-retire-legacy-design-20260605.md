---
title: "F000049 S4 — retire the separate-clone legacy: drop .source, repoint sync, flip --bundle to default"
mode: startup
status: DRAFT
date: 2026-06-05
author: chjiang
parent: F000049
predecessors: [S000085 (S1), S000086 (S2), S000087 (S3)]
recommended-approach: "B-in-place + staged (scaffold the staged design, build the lowest-risk increment first)"
---

## Why this doc exists

S4 is the **subtractive** story of the F000049 epic — it retires the very
machinery that every `cj_goal` build run (including the four that landed S1–S3)
operates on: the `.source` reach-back, the manifest `source`-as-separate-clone
semantics, `post-land-sync.sh`, the `--phase sync` reinstall, and the legacy
(non-`--bundle`) default install. I flagged it as the one story in this epic I'd
refuse to cold-build, and recommended a real design pass first so the staging
never breaks the dev flow mid-migration. This is that pass.

## The de-risking finding (changes the whole shape of S4)

Live manifest (`~/.claude/.skills-templates.json`) on this machine, today:

- `install_mode: null` → the dev env is STILL legacy separate-clone; `--bundle`
  (S2/S3) is built + tested but was never made this env's default.
- `source` == `/Users/chjiang/Documents/projects/claude-skills-templates` → the
  `.source` "separate clone" **is the same directory I develop in**. For this
  workbench, *separate-clone* and *dev-checkout* are already one path.
- The 4 orchestrator skills install as realdirs (per-file symlinks back into the
  checkout); `_cj-shared/scripts/` (27 files, S1) is the live shared-script home.
- CI (`validate.yml`, `windows.yml`, `eval-nightly.yml`) references **none** of
  `.source` / `post-land-sync` / `cj-goal-common` / `--phase sync` — that surface
  is already decoupled from CI.

**Consequence:** install==clone does NOT require relocating the checkout into
`~/.claude/skills/cj-workbench`. It can be reached **in place** — point the install
dirs *at the checkout you already have* and drop the now-redundant `.source`
fallback. That converts S4 from a dangerous relocation into a staged cleanup whose
worst case is "a skill falls back to a path that resolves to the same directory."

## Target end-state (unchanged from the epic; reached a safer way)

- `~/.claude/skills/<name>` resolves skill content + shared scripts **from the
  checkout itself** (dir-level symlink into the checkout, or the bundle clone for
  a fresh consumer) — no `.source` reach-back tier.
- A `git pull` in the checkout makes new skill content live with **no reinstall**
  (dir-level symlink ⇒ new files appear automatically) — this is the real
  install==clone payoff and what makes `post-land-sync` / `--phase sync` reinstall
  redundant.
- `skills-deploy install` (no flag) == clone; `--bundle` becomes a back-compat
  no-op alias.
- `/CJ_portability-audit --no-adjudication` shows the family with **no `.source`-reach
  `workbench` findings**.

## Key decisions

### D1 — Bundle location: relocate vs in-place  → **recommend B (in-place)**
- **(A) gstack-canonical relocate.** Develop in `~/.claude/skills/cj-workbench`
  (the managed bundle S2 builds); retire `~/Documents/.../claude-skills-templates`.
  Truest to the literal gstack layout. Cost: active development moves *under*
  `~/.claude/`; muscle-memory + any external tooling pinned to the Documents path
  breaks; a real relocation step.
- **(B) in-place repoint.** Make the existing dev checkout itself the bundle
  (`bundle_path` = the checkout); install `~/.claude/skills/<name>` as a dir-level
  symlink INTO it. install==clone holds (the install symlinks into the clone; no
  `.source`, no separate sync). Develop exactly where you do today. A small, safe
  delta from the current realdir+file-symlink layout.
- Both satisfy every F000049 acceptance criterion. (B) reaches the same no-reach-back
  end-state with near-zero workflow disruption, which for a single-dev workbench is
  the dominant consideration. (A) remains available if "literal gstack layout" is a
  hard requirement — flag at the gate.

### D2 — What "retire the worktree machinery" actually means → **retire sync, KEEP worktrees**
The roadmap phrase "retire the worktree/post-land-sync machinery" conflates two
things. Precisely:
- **Retire (redundant under install==clone):** `post-land-sync.sh` (pull+reinstall
  from `.source`), the `--phase sync` *reinstall* step, the `.source` legacy tier in
  the 4 skill preambles, manifest `source`-as-separate-clone semantics.
- **KEEP, re-pointed:** the `cj-feat-*`/`cj-def-*` **worktree** flow itself
  (`cj-worktree-init.sh` / `cj-worktree-cleanup.sh` / `cj-goal-common.sh` worktree
  phases). Worktrees are created *inside* the checkout's `.claude/worktrees/` and
  isolate parallel builds — install==clone doesn't remove that need. They get
  re-pointed (branch within the in-place checkout), not deleted. `--phase sync`
  collapses to a plain `git pull` (no reinstall) rather than vanishing.

This resolves epic Open Question O3: "edit the checkout + branch in place" IS the
replacement dev convenience; worktrees remain the isolation primitive.

### D3 — Staging granularity → **recommend a 2-increment split, lowest-risk first**
Surface area is large and load-bearing: ~98 `.source` refs across scripts + ~42 in
the 4 skill preambles + the `--bundle` default flip + ~15 manifest-`source`
consumers in `skills-deploy`. A single PR that flips the default AND drops the
fallback in one shot has no safe rollback point if the dev flow breaks. Proposed
order (each increment leaves a GREEN, working dev flow):

- **S4-i1 (low risk, additive-ish): in-place install + drop the `.source` *tier*.**
  Teach `skills-deploy install` to (a) record the checkout as `bundle_path` /
  `install_mode: in-place` and install dir-level symlinks into it, and (b) the 4
  skill preambles drop the `.source` fallback (repo-local + `_cj-shared` already
  cover every invocation path — repo-local when cwd is the checkout, `_cj-shared`
  cross-repo). Sync machinery still present but now a no-op on this env. Reversible.
- **S4-i2 (subtractive cutover): repoint sync + flip `--bundle` default + retire
  `post-land-sync`/`--phase sync` reinstall + manifest `source` semantics + docs.**
  Done only after i1 proves the in-place install resolves with zero `.source`
  reach-backs (audit `FINDINGS=0`).

If the operator prefers, S4 stays a single story built in this same internal order
with i1's green checkpoint as an intermediate commit — the ordering is what matters,
not the PR count.

## Risks & mitigations
- **R1 — break the running dev flow mid-migration.** Mitigation: in-place (D1-B)
  means the dropped `.source` tier falls back to a path equal to the repo-local tier;
  worst case is a redundant resolution, not a missing one. Stage i1 before i2.
- **R2 — a `git pull` no longer installs new skills.** Mitigation: dir-level symlinks
  make new files live without reinstall; verify with a "add a file → pull → it's
  discoverable" test before retiring the reinstall path.
- **R3 — Windows/Git-Bash has no symlinks.** Out of scope here — copy-mode parity is
  S5. i1 must keep the existing copy-mode path intact (gate on `_can_symlink`), not
  assume symlinks.
- **R4 — a fresh consumer (no checkout) must still install.** `--bundle`/default
  clones the bundle from `upstream_url`; the in-place path is the *developer*
  optimization, the clone path is the *consumer* path. Both must stay green.

## Recommended approach
**D1-B (in-place) + D2 (keep worktrees, retire sync) + D3 (2-increment, i1 first).**
For this turn: scaffold S4 as the staged design (capture i1/i2 in SPEC/TEST-SPEC),
open a design PR, and STOP before any subtractive code — OR build just i1 (the
low-risk increment) flagged + PR-stop. The full subtractive i2 is the one piece
that warrants its own deliberate, reviewed pass.

## Open questions
- O1 (D1): is the literal `~/.claude/skills/cj-workbench` layout a hard "full gstack"
  requirement, or is in-place install==clone acceptable? (Operator call at the gate.)
- O2: does the manifest keep `source` (repurposed to mean the bundle/checkout path)
  for `skills-update-check` to read, or migrate update-check to `bundle_path`?
- O3 (resolved): worktrees stay as the isolation primitive; "develop in place" is the
  replacement for the separate-clone reach-back, not for worktrees.
