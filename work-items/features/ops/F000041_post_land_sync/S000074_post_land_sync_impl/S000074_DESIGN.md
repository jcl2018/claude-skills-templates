---
type: design
parent: S000074
title: "post-land-sync helper + CLAUDE.md docs + test wiring — Story Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic story: brief per-section content is fine. Cross-story context lives
     in the parent feature design (F000041_DESIGN.md). -->

## Problem

`gh pr merge` (the workbench convention) is a remote merge that bypasses the local
post-merge auto-sync hook, so after a skill PR lands the operator's
`~/.claude/skills/` and the manifest `collection_version` go stale until a manual
`skills-deploy install`. See parent [F000041_DESIGN.md](../F000041_DESIGN.md) for
the full problem context and the live 6.0.8→6.0.10 drift evidence.

## Shape of the solution

A `scripts/post-land-sync.sh` helper resolves `.source` from
`~/.claude/.skills-templates.json`, guards it (exists, on `main`, clean tree),
runs `git -C "$_SRC" pull --ff-only` then `"$_SRC/scripts/skills-deploy" install`,
and reports `collection_version` before→after. `--dry-run` previews without
mutation. CLAUDE.md's "CI/CD merge convention" gains the post-merge step + bypass
reason + drift note. A `tests/post-land-sync.test.sh`, wired into
`scripts/test.sh`, exercises resolution + guards + `--dry-run` against a temp
fixture so it never touches the real `~/.claude`.

## Big decisions

Helper over doc-only reminder (Approach A): encodes the correct
pull-checkout + install-from-where once, is testable, and is dogfoodable. Guards
refuse on non-main/dirty `.source` (`--ff-only`, never force) per the
no-clobber constraint. See parent design's Big decisions table for the full
rationale and rejected alternatives.

## Risks & open questions

The test must never mutate the real `~/.claude` — mitigated by exercising the
helper via `--dry-run` and/or a temp fixture only. Helper behavior on a
dirty/non-main `.source` is resolved here: detect + warn + exit non-zero. Whether
to wire the helper into `/land-and-deploy`'s tail is deferred (out of scope v1).

## Definition of done

- [ ] `scripts/post-land-sync.sh` implements `--dry-run` preview, the real guarded pull + install, the guards, and the before→after version report.
- [ ] `tests/post-land-sync.test.sh` passes and is wired into `scripts/test.sh`.
- [ ] `CLAUDE.md` documents the post-merge step (a) + bypass reason (b) + drift note (c).
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` are green.

## Not in scope

- Wiring the helper into `/land-and-deploy`'s tail — deferred to a follow-up.
- Any automatic hook on `gh pr merge` — excluded by the no-auto-mutate constraint.
- Re-architecting `skills-deploy` — the helper is a thin wrapper only.

## Pointers

- Parent feature design: [../F000041_DESIGN.md](../F000041_DESIGN.md)
- Parent tracker: [../F000041_TRACKER.md](../F000041_TRACKER.md)
- This story's spec: [S000074_SPEC.md](S000074_SPEC.md)
- This story's test-spec: [S000074_TEST-SPEC.md](S000074_TEST-SPEC.md)
