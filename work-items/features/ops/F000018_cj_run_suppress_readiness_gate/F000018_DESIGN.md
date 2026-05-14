---
type: design
parent: F000018
title: "/CJ_run end-to-end — suppress /land-and-deploy readiness gate — Feature Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_run` already chains into `/land-and-deploy` in Phase 4 (Step 5 of
`skills/CJ_run/run.md`); the chain itself is built. The friction is
`/land-and-deploy`'s Step 3.5 pre-merge readiness-gate AUQ ("Ready to merge PR
#N? All checks passed."), which fires on every invocation even when everything
is green. Under `/CJ_run` that AUQ is pure ceremony: `/autoplan` (Gate #1) and
`/ship` (Gate #2) just ran 30 seconds earlier and gated the same things (review
staleness, free tests, CHANGELOG, VERSION, PR body accuracy, scope drift).

User intent: "let it run to the end (calling land and deploy), only ask my
question when needed (like a merge conflict)." Translation: keep the chain, but
halt only on genuine red signals (merge conflict, CI failure, free-test
regression at /land-and-deploy time, deploy workflow failure, canary issues).
Drop the green-confirmation tax.

## Shape of the solution

The feature ships in two PRs (one in gstack, one in the workbench). This
work-item scaffolds and tracks ONLY the workbench-side change as a single
user-story child. The gstack PR is owned by the user by hand; it is out of
scope for /CJ_personal-pipeline. Forward-compat: gstack's loose arg parsing
ignores unknown flags, so the workbench PR is a safe no-op until the gstack
PR also lands.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Workbench-side change (run.md Step 5, Branch(f) open_pr, SKILL.md description + Phase 4 entry, version bump, CHANGELOG) | S000040 | [S000040_workbench_side/S000040_TRACKER.md](S000040_workbench_side/S000040_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A (upstream flag `--suppress-readiness-gate`) over Approach B (global redesign of Step 3.5) | Blast radius matters; opt-in beats opt-out. Mirrors a proven pattern (CJ_personal-pipeline `--suppress-final-gate`); reviewers immediately understand the shape; clean rollback. |
| 2 | Workbench PR is in-scope; gstack PR is out-of-scope for /CJ_personal-pipeline | gstack is upstream — different repo, different release cadence, different reviewers. User owns gstack PR by hand. /CJ_personal-pipeline only mutates this repo. |
| 3 | `--suppress-readiness-gate` flag name (over `--from-pipeline`, `--non-interactive`, `--auto-merge`) | Descriptive but long is fine for a flag callers rarely see. Matches the pattern of `--suppress-final-gate`. (User-confirmed taste decision in /autoplan.) |
| 4 | PR_NUM parsing in Branch(f) → inline duplicate the Step 5 parsing block | DRY-via-helper would require a /CJ_run-internal helper function abstraction we don't have yet; ~15 lines duplicated is cheaper than introducing the abstraction. (User-confirmed taste decision in /autoplan.) |
| 5 | Step 6 deploy-failure AUQ and Step 7 canary-failure AUQ — keep as AUQ under suppression | These only fire on red, never on green; user said "ask when needed (like a merge conflict)". Deploy-failure and canary-red are exactly that case. |
| 6 | Reuse current branch (`claude/modest-meitner-0c7600`) instead of creating a new branch | User explicitly chose to reuse this branch; v3.3.2 was just merged here, branch is clean. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Forward-compat: workbench passes flag, gstack doesn't recognize it yet | Implementation note in the gstack PR: arg parser uses case-statement that warns-and-continues on unknown flags. Verified at v1 land-time. |
| Step 5 deploy-strategy AUQ (no platform config) — fires every run on this workbench | Out of scope for this design (different blast radius). Follow-up TODO: populate `## Deploy Configuration` in CLAUDE.md, defaulting to "no deploy". |
| Step 1.5 first-run dry-run AUQ under suppression | Leave as-is. Already CONFIRMED for this workbench; the dry-run is genuinely valuable on first contact with a fresh project. |

## Definition of done

- [ ] `skills/CJ_run/run.md` Step 5 passes `--suppress-readiness-gate` when invoking /land-and-deploy.
- [ ] `skills/CJ_run/run.md` Branch(f) `open_pr` mode (around line 267) auto-dispatches /land-and-deploy with the flag + parsed PR_num (inline-duplicate the Step 5 parsing block).
- [ ] `skills/CJ_run/SKILL.md` description + Phase 4 entry updated to mention `--suppress-readiness-gate` and the AUQ-free-on-green behavior.
- [ ] CJ_run version bumped 0.4.0 → 0.5.0 in SKILL.md frontmatter.
- [ ] CHANGELOG entry added describing the workbench-side change + forward-compat note.
- [ ] `scripts/validate.sh` passes (catalog/manifest/template integrity check).
- [ ] `/CJ_personal-workflow check` passes on F000018 + S000040.

## Not in scope

- gstack PR adding the `--suppress-readiness-gate` flag to `/land-and-deploy` itself — out of scope; user owns this PR by hand in the gstack repo.
- Step 5 deploy-strategy AUQ suppression — different semantic change; follow-up TODO to populate CLAUDE.md `## Deploy Configuration` instead.
- Step 1.5 first-run dry-run suppression — already CONFIRMED for this workbench; not a per-invocation gate.
- A `--non-interactive` flag for fully unattended runs — separate story if needed later.

## Pointers

- Parent tracker: [F000018_TRACKER.md](F000018_TRACKER.md)
- Roadmap: [F000018_ROADMAP.md](F000018_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-modest-meitner-0c7600-design-20260513-205017.md`
- Pattern reference: `skills/CJ_personal-pipeline/pipeline.md` (`--suppress-final-gate` contract)
