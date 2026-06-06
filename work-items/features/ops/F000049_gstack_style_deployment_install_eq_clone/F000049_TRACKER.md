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

- [ ] The CJ_ family installs as ONE self-contained bundle whose install dir is itself the git checkout (install == clone)
- [ ] No skill performs a runtime `.source` reach-back to a separate source clone (`/CJ_portability-audit --no-adjudication` shows no `.source`-reach `workbench` findings)
- [ ] The workbench is developed by editing the installed checkout in place; the separate-clone + `cj-feat-*`/`cj-def-*` worktree machinery + `post-land-sync` + `--phase sync` are retired or re-pointed
- [ ] A consumer can install + run the family without a separate source clone present
- [ ] `validate.sh` + `scripts/test.sh` green under the new layout; Windows/Git-Bash copy-mode parity holds

## Todos

- [x] S000085 (S1): shared-scripts self-containment (the runtime de-coupling foundation) — BUILT (deposit + 3-tier preambles + 4-skill re-tier to local-only + audit precision; `validate.sh` + `test.sh` green, audit `FINDINGS=0`)
- [ ] S2: single-bundle layout + git-checkout install (resolve O1: Claude Code skill discovery from a bundle)
- [ ] S3: develop-in-place + retire the separate-clone machinery
- [ ] S4: drop `.source` + manifest `source`; finalize tier shift; docs
- [ ] S5: cleanup + parity (Windows copy-mode, CI, `skills-update-check` on the in-place checkout)

## Log

- 2026-06-05: Created. Epic to convert the CJ_ workbench deployment to the gstack model (install == clone), per an /office-hours design (operator chose the full-gstack target over the hybrid). Decomposed into S1–S5; S1 (S000085) scaffolded as the non-breaking foundation.
- 2026-06-05: S1 (S000085) BUILT (operator resumed the build on this branch after the design+scaffold checkpoint). Shared scripts travel via a `_cj-shared/scripts/` deposit; the 4 orchestrator-family skills re-tier `workbench → local-only`. Reconciled the design's "12 skills" estimate to the 4 that actually re-tier. `validate.sh` + `scripts/test.sh` green. S2–S5 remain.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `.gstack/gstack-style-deployment-design-20260605.md` — the /office-hours design doc (target architecture + S1–S5 decomposition + open questions)
- `work-items/features/ops/F000049_*` — this feature + the S000085 story
- S1 implementation (landed): `scripts/skills-deploy` (shared-scripts deposit), the 4 orchestrator-family skills' resolution preambles (3-tier), `skills-catalog.json` (4 re-tiers), `scripts/cj-portability-audit.sh` (deployed-home recognition + comment-line precision), `scripts/test.sh` + `tests/cj-document-release.test.sh` (S000085 test + guard updates)

## Insights

The workbench is ALREADY half-way to gstack: `skills-deploy` symlinks each skill's files from the clone into `~/.claude/skills/<name>/`, so skill *content* tracks the clone live. The only `.source` reach-back is for the 26 shared root `scripts/*.sh` (not under any skill dir). So the de-coupling work (S1) is narrow; the *development-flow* rewrite (install==clone, retire worktree/`.source`/`post-land-sync`) is the wide part (S2–S5). gstack's elegance (zero install-drift) depends on devs editing the global checkout — adopting it fully means changing how the workbench is developed, not just consumed.

## Journal

- 2026-06-05T16:00:00Z [decision] Operator chose the full-gstack target (install == clone, develop-in-place) over the hybrid (consumer bundle + keep dev clone), with eyes open on the dev-flow rewrite. Then chose to stop at the design + scaffold S1 rather than autonomously silent-build the foundation change. Design: `.gstack/gstack-style-deployment-design-20260605.md`.
