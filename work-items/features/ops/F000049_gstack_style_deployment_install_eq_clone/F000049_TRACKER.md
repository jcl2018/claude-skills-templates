---
name: "gstack-style deployment for the CJ_ workbench (install == clone)"
type: feature
id: "F000049"
status: active
created: "2026-06-05"
updated: "2026-06-05"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260605-160453-69246"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Create working branch: `cj-feat-20260605-160453-69246`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (`.gstack/gstack-style-deployment-design-20260605.md`)
4. Scaffold `ROADMAP.md` (scope, non-goals, the S1–S5 decomposition, timeline)
5. Define acceptance criteria (what "done" looks like for the whole epic)
6. Decompose into child user-stories (S1 = S000085 scaffolded; S2–S5 are roadmap entries, not yet scaffolded)

**Gates:**
- [x] /office-hours design produced (`.gstack/gstack-style-deployment-design-20260605.md`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories (S1 scaffolded; S2–S5 in ROADMAP)

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos — check off completed children, add discoveries
4. Update Files with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Run `/ship` — creates feature PR
5. Run `/land-and-deploy`
6. Run `/document-release`

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done

## Acceptance Criteria

- [x] The CJ_ family installs as ONE self-contained bundle whose install dir is itself the git checkout (install == clone) — S4: default install stamps `install_mode: in-place`, `bundle_path == source` (the install IS the in-place checkout); `--bundle` for the relocated/fresh-consumer variant
- [x] No skill performs a runtime `.source` reach-back to a separate source clone — S4: 10 update-check snippets + the 4 orchestrators' resolution tiers de-sourced; `/CJ_portability-audit` shows the family `local-only | portable`, `FINDINGS=0`, no `.source` note
- [x] The workbench is developed by editing the installed checkout in place; the separate-clone machinery + `post-land-sync` + `--phase sync` are retired or re-pointed — S4: RE-POINTED to the one in-place checkout (kept, not deleted, because a remote `gh pr merge` still needs a post-merge pull); `cj-feat-*` worktrees kept (D2, isolation primitive)
- [x] A consumer can install + run the family without a separate source clone present — S2: `skills-deploy install --bundle` clones + installs from the bundle
- [x] `validate.sh` + `scripts/test.sh` green under the new layout; Windows/Git-Bash copy-mode parity holds — S5: de-risking proved the in-place model holds under copy-mode (platform-neutral); a `windows-smoke.sh` lock-in assertion guards it on both lanes

## Todos

- [x] S000085 (S1): shared-scripts self-containment (the runtime de-coupling foundation) — BUILT (deposit + 3-tier preambles + 4-skill re-tier to local-only + audit precision; `validate.sh` + `test.sh` green, audit `FINDINGS=0`)
- [x] S000086 (S2): single-bundle layout + git-checkout install — BUILT (`skills-deploy install --bundle`, additive/opt-in; O1 resolved via the gstack reference bundle; `validate.sh` + `test.sh` green, shellcheck clean)
- [x] S000087 (S3): develop-in-place enablement — BUILT (`--bundle` origin-repoint + `skills-deploy bundle-status`, additive; the `.source`/worktree RIP-OUT is scoped to S4, not done here). `validate.sh` + `test.sh` green, shellcheck clean
- [x] S000088 (S4): retire the separate-clone legacy — declare install==clone-in-place (`install_mode`) + drop runtime `.source` (4 orchestrators' resolution tiers + 10 update-check snippets) + reframe (not delete) the sync machinery + docs. LANDED v6.0.45 / PR #235. SCOPE HONESTY (operator chose "build full S4"): "flip `--bundle` default" = the default IS install==clone-in-place (D1-B, no relocation); "retire post-land-sync/`--phase sync`" = REFRAME (remote-merge still needs a pull); worktrees kept (D2)
- [x] S000089 (S5): lock in Windows copy-mode parity for the in-place model + close the epic — BUILT (this PR). De-risking proved S4's model ALREADY holds under copy-mode (platform-neutral); S5 = a `windows-smoke.sh` lock-in assertion (both lanes) + docs + epic close. Dir-symlink reinstall-free refinement DROPPED (POSIX-only asymmetry, non-criterion, drift-detection cost). **F000049 COMPLETE on this PR landing.**

## Log

- 2026-06-05: Created. Epic to convert the CJ_ workbench deployment to the gstack model (install == clone), per an /office-hours design (operator chose the full-gstack target over the hybrid). Decomposed into S1–S5; S1 (S000085) scaffolded as the non-breaking foundation.
- 2026-06-05: S1 (S000085) BUILT (operator resumed the build on this branch after the design+scaffold checkpoint). Shared scripts travel via a `_cj-shared/scripts/` deposit; the 4 orchestrator-family skills re-tier `workbench → local-only`. Reconciled the design's "12 skills" estimate to the 4 that actually re-tier. `validate.sh` + `scripts/test.sh` green. (Landed v6.0.42 / PR #232.)
- 2026-06-05: S2 (S000086) BUILT on a fresh worktree off the landed S1. O1 resolved empirically (gstack's flat-symlink-into-a-git-checkout bundle; CJ_ already ~90% there). Added `skills-deploy install --bundle` — additive, opt-in, legacy install untouched: ensure a managed checkout + delegate the install INTO it + stamp the manifest with the install==clone receipt. `validate.sh` + `scripts/test.sh` green; shellcheck clean. (Landed v6.0.43 / PR #233.)
- 2026-06-05: S3 (S000087) BUILT on a fresh worktree off the landed S2. SCOPED: surfaced that S3 (retire the separate-clone machinery) is subtractive + retires the running machinery; operator chose "build now"; I scoped the build to the SAFE develop-in-place half — `--bundle` repoints the bundle's `origin` to the GitHub upstream (so push/PR works from the bundle) + a `skills-deploy bundle-status` subcommand. The `.source`/worktree/post-land-sync rip-out is DEFERRED to S4 (additive, separate-clone machinery untouched). `validate.sh` + `scripts/test.sh` green; shellcheck clean. S4–S5 remain. (Landed v6.0.44 / PR #234.)
- 2026-06-05: S4 (S000088) scaffolded + built on a fresh worktree off the landed S3. A full /office-hours S4 design pass first (`.gstack/gstack-s4-retire-legacy-design-20260605.md`); operator chose "Build full S4 now" at the design-gate. The de-risking finding (manifest `source` already == the dev checkout; `install_mode: null`) makes install==clone reachable IN PLACE (D1-B). Declares the default install install==clone-in-place + drops the runtime `.source` reach-backs (4 orchestrators' cj-goal-common tier + 10 update-check snippets → `_cj-shared`) + reframes (does NOT delete) the sync helpers. SCOPE HONESTY stated in the SPEC Tradeoffs + PR: deletion of post-land-sync/`--phase sync` is unsafe under remote-merge in-place. Worktrees kept (D2). S5 remains. (Landed v6.0.45 / PR #235.)
- 2026-06-06: S5 (S000089) scaffolded + built on a fresh worktree off the landed S4. A /office-hours S5 design pass first (`.gstack/gstack-s5-windows-parity-design-20260606.md`); operator chose "Verify + close epic" at the design-gate. The de-risking finding: a hermetic `FORCE_COPY` default install proved S4's install==clone-in-place + `.source` de-coupling ALREADY hold under Windows copy-mode (the S4 changes were platform-neutral by construction) — so S5 is a `windows-smoke.sh` lock-in assertion (runs on BOTH lanes — windows.yml + test.sh:506) + a CLAUDE.md note + the epic close, NOT new parity code. The POSIX-only dir-symlink reinstall-free refinement was DROPPED (asymmetry + non-criterion + drift-detection cost), not deferred. **F000049 is functionally COMPLETE on this PR landing — all 5 acceptance criteria met. The CJ_ workbench now installs == clone (in place), with no runtime `.source` reach-back, developed in place, consumer-installable via `--bundle`, and Windows copy-mode parity locked in.**

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `.gstack/gstack-style-deployment-design-20260605.md` — the /office-hours design doc (target architecture + S1–S5 decomposition + open questions)
- `work-items/features/ops/F000049_*` — this feature + the S000085 story
- S1 implementation (landed): `scripts/skills-deploy` (shared-scripts deposit), the 4 orchestrator-family skills' resolution preambles (3-tier), `skills-catalog.json` (4 re-tiers), `scripts/cj-portability-audit.sh` (deployed-home recognition + comment-line precision), `scripts/test.sh` + `tests/cj-document-release.test.sh` (S000085 test + guard updates)
- S2 implementation: `scripts/skills-deploy` (`do_bundle_install` + `--bundle` flag), `scripts/test.sh` (S000086 bundle test), `.gstack/gstack-s2-bundle-install-design-20260605.md`, `work-items/features/ops/F000049_*/S000086_*`
- S3 implementation: `scripts/skills-deploy` (`do_bundle_install` origin-repoint + `do_bundle_status` + dispatcher/usage), `scripts/test.sh` (S000087 develop-in-place test), `.gstack/gstack-s3-develop-in-place-design-20260605.md`, `work-items/features/ops/F000049_*/S000087_*`
- S4 implementation: `scripts/skills-deploy` (default `do_install` in-place receipt + `do_bundle_status` in-place), the 4 orchestrator preambles (drop `.source` cj-goal-common tier), 10 skills' update-check repoint to `_cj-shared`, touched `skills/*/USAGE.md`, `scripts/cj-portability-audit.sh` + `scripts/post-land-sync.sh` + `scripts/cj-goal-common.sh` (reframe), `scripts/test.sh` (S000088 test), `doc/PHILOSOPHY.md` + `doc/ARCHITECTURE.md` + `doc/WORKFLOWS.md` + `CLAUDE.md`, `.gstack/gstack-s4-retire-legacy-design-20260605.md`, `work-items/features/ops/F000049_*/S000088_*`

## Insights

The workbench is ALREADY half-way to gstack: `skills-deploy` symlinks each skill's files from the clone into `~/.claude/skills/<name>/`, so skill *content* tracks the clone live. The only `.source` reach-back is for the 26 shared root `scripts/*.sh` (not under any skill dir). So the de-coupling work (S1) is narrow; the *development-flow* rewrite (install==clone, retire worktree/`.source`/`post-land-sync`) is the wide part (S2–S5). gstack's elegance (zero install-drift) depends on devs editing the global checkout — adopting it fully means changing how the workbench is developed, not just consumed.

## Journal

- 2026-06-05T16:00:00Z [decision] Operator chose the full-gstack target (install == clone, develop-in-place) over the hybrid (consumer bundle + keep dev clone), with eyes open on the dev-flow rewrite. Then chose to stop at the design + scaffold S1 rather than autonomously silent-build the foundation change. Design: `.gstack/gstack-style-deployment-design-20260605.md`.
