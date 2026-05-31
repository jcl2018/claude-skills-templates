---
type: roadmap
parent: F000028
title: "Doc-sync via post-merge git hook (zero changes to the three cj_goal skills) — Roadmap"
date: 2026-05-30
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Extend `scripts/setup-hooks.sh` to install a `post-merge` + a `post-rewrite` git hook (per-developer, not committed). Both hooks share a trigger block that, when HEAD moves on `main` non-trivially, atomically writes a marker file at `~/.gstack/doc-sync-pending/<repo-slug>.json`. The marker tells the operator to run `/document-release` in their next Claude session — the hook does NOT spawn Claude itself. Symmetric for all three cj_goal pipelines because all three eventually result in main moving. Zero changes to the three orchestrator skill files.

## Non-Goals

- Editing any of the three cj_goal skill files — design's core decision is ZERO changes to them.
- Marker-pickup AUQ inside cj_goal skills — separate follow-up, out of scope here.
- Alignment cleanup of cj_goal skills (resume-state, telemetry, halt-marker naming) — user said "ship doc-sync first" at D2; alignment is a separate follow-up work-item.
- Spawning `claude --print /document-release` from the hook — rejected as too disruptive (~30–60s synchronous inside user's merge).
- Per-machine opt-out flag (`~/.gstack/doc-sync-disabled` sentinel) — deferred to v2.
- Coverage of `git reset --hard origin/main` — uncoverable by hooks; documented as known gap.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside — not internal code state. -->

- [ ] `./scripts/setup-hooks.sh` installs both hooks with the `# doc-sync trigger block` marker comment present (grep-verifiable) and the existing `# Auto-installed by scripts/setup-hooks.sh` sentinel preserved.
- [ ] Simulated main-moving merge (test fixture) writes `~/.gstack/doc-sync-pending/<slug>.json` atomically with valid `head_sha` + `diff_base`.
- [ ] Same-HEAD re-run is a NO-OP (idempotency via `.doc-sync-last-head`).
- [ ] Doc-only merge skips marker write — unless `DOC_SYNC_FORCE=1`.
- [ ] `git pull --rebase` on main triggers the same marker via `post-rewrite`.
- [ ] Existing D000013 skills-deploy auto-sync section + F000011 lifecycle-gate section continue to run in `post-merge` (no regression).
- [ ] `validate.sh` passes (no new shellcheck violations).
- [ ] `test.sh` includes 6 new doc-sync test rows.
- [ ] CLAUDE.md `setup-hooks.sh` row APPENDED with "post-merge + post-rewrite doc-sync trigger" (existing wording not overwritten).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000061](S000061_doc_sync_post_merge_hook_impl/S000061_TRACKER.md) | Implement post-merge + post-rewrite doc-sync trigger block and test it end-to-end | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000061 (hook install + tests + CLAUDE.md note + CHANGELOG) | 2026-05-30 | Not Started | chjiang | One coherent diff; PR-stop per `/cj_goal_feature` | — |
| 2 | End-to-end pipeline run: PR opens, human reviews, PR merges, hook fires on first `git pull` of main — instant dogfood of the doc-sync trigger | 2026-05-31 | Not Started | chjiang | Confirms marker is written for this PR's own merge | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-05-30: Created via /office-hours + /CJ_scaffold-work-item.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000061 (hook + tests + docs)  -->  #2 End-to-end dogfood on this PR's merge
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Per-machine opt-out config flag (`~/.gstack/doc-sync-disabled` sentinel) — should v1 ship it or defer? | Deferred to v2 per design Open Question 1; revisit if v1 hook is noisy in real use. |
| Marker-pickup AUQ — should it live in each cj_goal skill or in a new `CJ_doc_sync` helper skill? | Decided in the follow-up work-item, after observing v1 in production for ~1 week of dogfood. |
