# Philosophy

## The first principle

This workbench has one first principle. Everything else in its deployment
design is a consequence of it, not a separate decision.

> **There is exactly one source of truth — this git checkout. Installing it
> does not copy it; it references it. Every repo on the machine, and the
> workbench itself, run that one install.**

It has two halves: the **install model** (what `skills-deploy install` actually
does to your machine) and the **reference model** (how every other repo uses the
result). They are the same idea seen from the producer side and the consumer
side.

## The install model: install == clone

You clone this repo and run `./scripts/skills-deploy install`. The install *is*
the clone. There is no second copy of the skills that can drift from the one you
edit.

- **Skills are symlinks into the checkout.** `~/.claude/skills/<skill>/<file>`
  points straight back at `skills/<skill>/<file>` in this checkout (macOS/Linux).
  Edit `skills/CJ_goal_feature/pipeline.md` here and the next `/CJ_goal_feature`
  invocation runs the edit — no reinstall, no build step.
- **Shared scripts are deposited copies.** `~/.claude/_cj-shared/scripts/*` are
  checksum-tracked copies of this repo's `scripts/*.sh`. They are the one
  deliberate exception to pure-symlink, so a consumer repo can resolve them
  without reaching into the checkout.
- **The manifest knows it is the clone.** `~/.claude/.skills-templates.json`
  records `install_mode: in-place` with `source == bundle_path`, both pointing
  at this checkout.

So `git pull` is the update mechanism: skills update the instant you pull (they
are symlinks); shared scripts refresh on the next `skills-deploy install`. And
there is **no runtime reach-back to a registered source path** — a skill
resolves its shared scripts repo-local-first (this checkout's own live
`scripts/`), then the `_cj-shared` copies. Nothing has to look up "where is the
real install," because the install you are looking at *is* the real install.

## The reference model: every repo references the one install

Other repos do not carry their own copy of the CJ_ skills. They **reference** the
single `~/.claude/` install.

- Invoke `/CJ_goal_feature` from any repo on the machine. Claude Code loads it
  from `~/.claude/skills/` — which is symlinks into this checkout. That repo is
  transitively running this workbench's live code.
- Behavior is therefore **identical across every repo and the workbench
  itself**, because they all resolve to the same one install. There is no
  per-repo skill copy to fall out of sync, and no "which version is this repo
  on" question to answer.

The single nuance: *inside* this checkout, a skill prefers its **own live
`scripts/`** (repo-local-first) so the workbench dogfoods its own uncommitted
edits before they are deposited; any other repo uses the `_cj-shared/` copies.
After an install those two are identical content — so the behavior matches, and
the workbench is simply the one place you can change a script and see the effect
before committing.

## Why this is the first principle

State "install == clone, reference one install" once and the rest of the design
follows as corollaries rather than choices:

- **One install, not N.** No per-skill bundles and no shared `~/.claude/cj-bin/`
  — there is a single checkout, and `~/.claude/` is a view onto it.
- **Develop in place.** The files you edit and the files that run are the same
  files. No copy-to-install step, no "did I reinstall?" doubt.
- **`git pull` is deploy.** Updating the checkout updates the machine, because
  the machine references the checkout.
- **Worktrees are isolated checkouts off the one source.** The orchestrators
  auto-create `cj-*` worktrees so parallel builds don't collide, then sweep them
  once their PR lands — each is a branch of the single source, not a rival copy.
- **post-land-sync exists only because GitHub merges are remote.** `gh pr merge`
  lands on GitHub without touching your local checkout, so afterward you `git
  pull` to bring the one source current. That is the *only* reason a post-merge
  sync step exists.

## Windows: the model holds, the mechanism changes

Git Bash on Windows cannot create real symlinks, so `skills-deploy install`
falls back to **copy-mode**: `~/.claude/skills/` gets real-file copies with
checksum drift tracking instead of symlinks. The *model* is unchanged — the
manifest still records `install_mode: in-place`, the reference model is the
same, behavior is the same. Only the link mechanism differs, and CI
(`windows.yml` + `scripts/windows-smoke.sh`) guards that the in-place contract
holds under copy-mode.

## Decision tree

The first principle above is about *deployment* — how the skills get onto your
machine. This is the routing map for *using* them. Every `CJ_` front door
converges on the same downstream chain (`/ship` → `/land-and-deploy`); pick by
what you have in hand.

| Your input | Front door |
|---|---|
| One-line feature topic → reviewable PR | `/CJ_goal_feature "<topic>"` |
| Bug description → shipped fix | `/CJ_goal_defect "<bug>"` |
| Drain shippable `TODOS.md` rows | `/CJ_goal_todo_fix [<T-id> \| "<frag>"]` |
| "What should I work on?" | `/CJ_suggest` |
| "Is my `~/.claude/` healthy?" | `/CJ_system-health` |
| "Set up / verify this repo for the CJ_ family" | `/CJ_repo-init` |
| "Are my skills' `portability` labels honest?" | `/CJ_portability-audit` |
| Triage a Claude best-practice URL | `/CJ_improve-queue evaluate <url>` |

Internal phase-step skills are dispatched transitively by the orchestrators — do
not route to them directly: `/CJ_scaffold-work-item`, `/CJ_implement-from-spec`,
`/CJ_qa-work-item`, `/CJ_document-release`, `/CJ_personal-workflow`. The full
per-skill roster + ASCII workflow charts live in
[doc/WORKFLOWS.md](WORKFLOWS.md).

---

*This principle was reached incrementally by F000049 (S000085–S000089,
v6.0.42–v6.0.46): deposit the shared scripts so they travel with the install,
add the bundle install, develop in place, drop the runtime `.source` reach-back,
and lock in Windows copy-mode parity. Full history:
`work-items/features/ops/F000049_gstack_style_deployment_install_eq_clone/`.*
