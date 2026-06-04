---
type: design
parent: F000041
title: "Post-land local skills install + collection_version drift fix — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The workbench's merge convention is `gh pr merge` — a **remote** merge. The local
post-merge auto-sync hook (`setup-hooks.sh` → `skills-deploy install`, which
re-deploys skills/templates) only fires on a local `git pull`/`merge`. So after a
skill PR lands, `main` on the server has the new skill but the operator's
`~/.claude/skills/` is not refreshed and the manifest `collection_version` is not
updated — the skill lives on `main` yet isn't invocable as a `/`-command until
someone manually runs `skills-deploy install`.

Live evidence this session: after merging PR #200 + #201,
`~/.claude/.skills-templates.json` `collection_version` read **6.0.8** while
`.source` (main) was at **6.0.10** — a 2-version drift. (Deployed skill files are
symlinks into `.source`, so existing-skill *content* is fresh once `.source` is
pulled, but NEW skills need `skills-deploy install` to get symlinks, and the
manifest version refreshes only on install.)

## Shape of the solution

A new `scripts/post-land-sync.sh` helper collapses the post-merge install (a) and
the drift reconciliation (c) into one operator command, and CLAUDE.md documents
the step plus the bypass reason (b). The helper resolves `.source` from
`~/.claude/.skills-templates.json`, guards it (`.source` exists, on `main`, clean
tree — else warn + exit non-zero), runs `git -C "$_SRC" pull --ff-only` then
`"$_SRC/scripts/skills-deploy" install`, and reports `collection_version`
before→after. `--dry-run` previews without mutation. A new
`tests/post-land-sync.test.sh` (wired into `scripts/test.sh`) exercises resolution
+ guards + `--dry-run` output without mutating the real `~/.claude`.

This feature is atomic — a single helper + docs + test — so it decomposes into one
user-story that carries the whole implementation surface.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| post-land-sync helper + CLAUDE.md docs + test wiring | S000074 | [S000074_post_land_sync_impl/S000074_TRACKER.md](S000074_post_land_sync_impl/S000074_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: a `post-land-sync.sh` helper + CLAUDE.md docs (CHOSEN over Approach B, doc-only) | A helper makes the convention a single correct command (pull-the-right-checkout + install-from-where encoded once), is testable via `--dry-run`, and is dogfoodable against the live 6.0.8→6.0.10 drift. Approach B's "run `git pull && skills-deploy install` after merge" line is two commands the operator must remember + get right. |
| 2 | Scope held to a+b+c (operator-chosen), NOT a re-architecture of skills-deploy | The fix is a small, low-risk addition; re-architecting skills-deploy would be out of proportion to the gap (a missing post-remote-merge install step). |
| 3 | The fix is an explicit operator command (or documented step), never an automatic hook on `gh pr merge` | Constraint: must NOT auto-mutate `~/.claude`. An automatic hook on a remote merge would surprise the operator; an explicit helper keeps the operator in control. |
| 4 | `git pull` on `.source` is `--ff-only` and refuses on non-main/dirty | Constraint: never force. A guarded pull avoids clobbering local state on `.source`; refuse-with-message is safer than a best-effort pull. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Helper safety on a dirty/non-main `.source` (could pull/install into a wrong state) | Resolved in implementation: detect + warn + exit non-zero (do NOT pull/install). Covered by a TEST-SPEC guard row. |
| Whether to also wire the helper into `/land-and-deploy`'s tail | Out of scope v1; the convention doc + manual invocation is enough. Noted as a follow-up. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `scripts/post-land-sync.sh --dry-run` previews (resolves `.source`, shows the would-run `git pull --ff-only` + `skills-deploy install` + current collection_version) and mutates nothing.
- [ ] Real run: `git -C <.source> pull --ff-only` + `<.source>/scripts/skills-deploy install`, then prints collection_version before→after.
- [ ] `./scripts/validate.sh` → 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` → 0 failures, INCLUDING a new `tests/post-land-sync.test.sh` wired into `scripts/test.sh`.
- [ ] `CLAUDE.md` "CI/CD merge convention" documents the post-merge step (a) + the bypass reason (b) + the drift note (c).

## Not in scope

<!-- Explicit non-goals. -->

- Wiring `post-land-sync.sh` into `/land-and-deploy`'s tail — deferred to a follow-up; v1 ships the convention doc + manual invocation.
- Any automatic hook on `gh pr merge` — explicitly excluded by the no-auto-mutate-`~/.claude` constraint.
- Re-architecting `skills-deploy` — the fix reuses the existing `.source` resolution + `skills-deploy install`; it adds a thin wrapper only.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000041_TRACKER.md](F000041_TRACKER.md)
- Roadmap: [F000041_ROADMAP.md](F000041_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-180257-28011-design-20260603-180920.md`
