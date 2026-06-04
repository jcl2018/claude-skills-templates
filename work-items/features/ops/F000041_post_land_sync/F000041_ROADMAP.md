---
type: roadmap
parent: F000041
title: "Post-land local skills install + collection_version drift fix — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Add a `scripts/post-land-sync.sh` helper that, after a `gh pr merge` lands a skill
PR, reconciles the operator's local install in one command: resolve `.source`,
guarded `git pull --ff-only`, `skills-deploy install`, and a
`collection_version` before→after report. Document the step + the
`gh pr merge`-bypasses-the-local-hook reason in CLAUDE.md, and ship a test wired
into `scripts/test.sh`.

## Non-Goals

<!-- Explicit non-goals. -->

- Wiring the helper into `/land-and-deploy`'s tail — deferred to a follow-up.
- Any automatic hook on `gh pr merge` — excluded by the no-auto-mutate-`~/.claude` constraint.
- Re-architecting `skills-deploy` — the helper is a thin wrapper over existing resolution + install.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `scripts/post-land-sync.sh --dry-run` previews (resolves `.source`, shows would-run `git pull --ff-only` + `skills-deploy install` + current collection_version) and mutates nothing.
- [ ] Real run performs the guarded pull + install and prints collection_version before→after.
- [ ] `./scripts/validate.sh` → 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` → 0 failures, including the new `tests/post-land-sync.test.sh`.
- [ ] `CLAUDE.md` "CI/CD merge convention" documents (a) the post-merge step, (b) the bypass reason, (c) the drift note.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000074](S000074_post_land_sync_impl/S000074_TRACKER.md) | post-land-sync helper + CLAUDE.md docs + test wiring | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000074 (helper + docs + test) | — | Not Started | chjiang | Single child carries the whole feature | — |
| 2 | End-to-end pipeline run (validate + test.sh green, /ship → PR) | — | Not Started | chjiang | PR is the architecture gate | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-03: Created. Feature scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000074 (helper + docs + test) --> #2 End-to-end pipeline run (validate/test green, /ship PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Helper behavior on a dirty/non-main `.source` | Resolved in implementation: detect + warn + exit non-zero. |
| Wire the helper into `/land-and-deploy`'s tail? | Deferred to a follow-up; out of scope v1. |
