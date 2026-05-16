---
type: roadmap
parent: F000022
title: "/CJ_improve-queue — Roadmap"
date: 2026-05-15
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

`/CJ_improve-queue` is a new skill that surfaces *what should be in the backlog* (vs `/CJ_suggest`'s *what's next from the backlog*). Phase 1 ships a single sub-command (`evaluate <url>`) that takes a Claude-best-practice article URL, asks a subagent whether the pattern it describes is present in `skills/**/SKILL.md`, and writes a draft TODOS.md row when the pattern is novel or conflicts with current usage. The row carries an inline `<!--impr-draft-->` marker (invisible in rendered markdown); promotion to active = remove the marker, then `/CJ_suggest -> /CJ_goal_todo_fix -> /ship` pipeline carries the work to a merged PR. The compound effect: the more URLs the user feeds, the more the workbench auto-aligns to evolving Anthropic patterns.

## Non-Goals

- Phase 2 (`audit`) and Phase 3 (`research <topic>`) — deferred until Phase 1 has been used on >=3 real URLs and the cross-reference subagent's accuracy is observed.
- Extending `/CJ_suggest` with new modes (rejected Approach A) — its deterministic, stateless, fast contract is load-bearing for `/CJ_goal_todo_fix` and `/loop /CJ_goal_todo_fix`.
- Direct `evaluate`-to-PR (skipping TODOS.md review) — improvement rows MUST sit in TODOS.md for human review before promotion; the inline `<!--impr-draft-->` marker is the explicit gate.
- Migration of existing TODOS.md rows to the improvement-row schema — `/CJ_improve-queue` only writes NEW rows.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report). -->

- [ ] `/CJ_improve-queue evaluate <claude-docs-url>` writes a single inline-comment-marked TODOS.md row matching the existing schema (synthetic-ID-free heading, source quote in HTML comment, signature in trailing HTML comment).
- [ ] Re-running `evaluate` on the same canonical URL is a NO-OP (signature grep hit; idempotent).
- [ ] The full flow works end-to-end: user removes `<!--impr-draft-->` -> `/CJ_suggest` ranks at P3 (orphan path) -> `/CJ_goal_todo_fix` drains -> merged PR cites the source URL in commit body.
- [ ] Atomic-write discipline holds (kill -9 between mktemp + mv leaves TODOS.md byte-identical).
- [ ] Pre-write `git status --porcelain TODOS.md` clean check; refuse on dirty.
- [ ] Concurrent `evaluate` invocations serialize via mkdir-based lock; second invocation retries or exits 0.
- [ ] WebFetch source-domain allowlist (`docs.anthropic.com`/`anthropic.com`/`claude.com`/`github.com/anthropics/*`); off-allowlist requires `--allow-untrusted-source`.
- [ ] Subagent stub via `CJ_IMPROVE_QUEUE_VERDICT_FILE` env var produces deterministic test output; malformed verdict handled gracefully.
- [ ] `verdict: "fetch_failed"` produces stderr line + exit 0 + no row appended.
- [ ] macOS-only gate fires loudly on non-Darwin.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000048](S000048_phase1_evaluate_url/S000048_TRACKER.md) | Phase 1: `evaluate <url>` mode (MVP) | Open |

Phase 2 (`audit`) and Phase 3 (`research <topic>`) ship as version bumps on the same skill (v1.1.0, v1.2.0) AFTER Phase 1 has been validated on >=3 real URLs. No new user-stories scaffolded until that gate clears.

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | F000021 (CJ_run / CJ_goal family rename) lands | 2026-05-15 | In Progress | chjiang | Must land first to avoid TODOS.md churn against legacy command names. | — |
| 2 | Ship S000048 (Phase 1: `evaluate <url>`) | 2026-05-16 | Not Started | chjiang | Includes optional `/CJ_suggest` patch (one-line awk filter) if bundled with this ship. | #1 |
| 3 | Killer test on real Anthropic docs URL | 2026-05-16 | Not Started | chjiang | Run `/CJ_improve-queue evaluate https://docs.anthropic.com/claude-code/<real-page>`; observe row appearance; promote; watch PR materialize. | #2 |
| 4 | Defer Phase 2 + Phase 3 decision (post >=3 real URLs) | TBD | Not Started | chjiang | Gate on Phase 1 production usage. | #2, #3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-05-15: Scaffolded. F000022 directory tree created with one user-story child (S000048).

## Dependency Graph

```
#1 F000021 lands  -->  #2 Ship S000048 (Phase 1)  -->  #3 Killer test  -->  #4 Defer Phase 2/3 decision
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should the `/CJ_suggest` patch (one-line awk filter for `<!--impr-draft-->`) ship in the same PR as S000048 or as a separate prereq PR? | Decided during S000048 implementation; either path is acceptable. |
| What's the right `--allow-untrusted-source` UX — single flag, or per-URL prompt? | Decided during S000048 implementation. v1 ships single flag; per-URL prompt deferred unless v1 footguns surface. |
