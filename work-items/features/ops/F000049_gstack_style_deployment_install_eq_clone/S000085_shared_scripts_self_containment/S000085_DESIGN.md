---
type: design
parent: S000085
title: "Shared scripts travel with the install (runtime de-coupling foundation) — Story Design"
version: 1
status: Draft
date: 2026-06-05
author: chjiang
reviewers: []
---

<!-- Atomic story: this design is a brief stub. The full target architecture,
     the S1–S5 decomposition, the big decisions, and the open questions live in
     the parent feature design — see Pointers. This doc captures only what is
     story-local to S000085. -->

## Problem

The 4 orchestrator-family skills (`CJ_goal_feature`, `CJ_goal_defect`,
`CJ_goal_todo_fix`, `CJ_document-release`) reach a separate source clone via
`.source` (in `~/.claude/.skills-templates.json`) to EXECUTE shared root
`scripts/*.sh`, which are not deployed. That reach-back is what makes those skills
`workbench`-tier — they cannot run on a machine/repo that lacks the source clone.
This is the runtime coupling the gstack migration must remove first. (12 skills
reach `.source`, but only these 4 execute shared scripts; the other 8 reach
`.source` only for the passive `skills-update-check` nudge — see the SPEC
reconciliation note.)

## Shape of the solution

Deposit the shared `scripts/*.sh` set into a deployed location that travels with
the install, and rewire the 4 orchestrator-family skills to resolve them
**bundle-first** with `.source` kept only as a legacy fallback. Non-breaking and
additive; it does not yet make the install a checkout (that is S2). One story, no
child tasks.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Shared scripts deployed + 3-tier resolution + tier re-classification | S000085 | S000085_SPEC.md / S000085_TEST-SPEC.md |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Keep the `.source` tier as a 3rd fallback (do NOT remove it in S1) | Non-breaking + reversible; the live install stays working. `.source` removal is S4. |
| 2 | One shared resolution idiom reused across the 4 skills (8 blocks), not divergent copies | Single source of truth for the 3-tier chain; cheaper to retarget in S2/S4 |
| 3 | Re-tier to `local-only`, not `standalone` | The skills still depend on a deployed shared location outside their own dir until the single-bundle layout (S2) |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| O2: the deployed shared-scripts home — a `_cj-shared/scripts/` skill dir vs a `cj-workbench/` proto-bundle | Resolved during S1 implementation |
| `skills-deploy install` from a worktree skips foreign-owned skills — the deposit step must not silently no-op | S1 implementation + the consumer-sim test |
| Windows/Git-Bash copy-mode must deposit the shared scripts too | Deferred to S5 parity; S1 keeps POSIX + LF + `date_to_epoch` idioms |

## Definition of done

- [x] `skills-deploy install` deposits the shared scripts at the deployed `_cj-shared/scripts/` home
- [x] The 4 orchestrator-family skills resolve shared scripts repo-local → deployed → `.source`
- [x] A skill resolves + runs a shared script with `.source` absent (S000085 consumer-sim green)
- [x] The 4 orchestrator-family skills read `local-only` in the catalog + the audit (`FINDINGS=0`)
- [x] `validate.sh` + `scripts/test.sh` green

## Not in scope

- Making the install a git checkout (install == clone) — S2
- Removing `.source` / the manifest `source` field — S4
- Retiring the `cj-feat-*` worktree / `post-land-sync` / `--phase sync` dev flow — S3
- Claude Code skill discovery changes (O1) — S2

## Pointers

- Parent feature design: [../F000049_DESIGN.md](../F000049_DESIGN.md)
- Parent roadmap: [../F000049_ROADMAP.md](../F000049_ROADMAP.md)
- /office-hours design (full target architecture + S1–S5): `.gstack/gstack-style-deployment-design-20260605.md`
- Precedent technique: D000032 (bundled `CJ_repo-init` engine — the bundle-own-script carve-out this generalizes), D000030 (the `.source` reach-back pattern this preamble mirrors)
