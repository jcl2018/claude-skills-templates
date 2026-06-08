---
type: roadmap
parent: F000055
title: "Standalone /CJ_document-release + the general/custom doc-contract principle — Roadmap"
date: 2026-06-08
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Make `/CJ_document-release` a standalone, any-repo doc pass and name the
underlying model as a workbench principle. In plain English: document the
general/custom two-tier doc contract (general docs every repo gets by default;
custom docs a repo declares for itself) as a `docs/philosophy.md` principle;
guard the one real cold-run rough edge so the skill degrades cleanly when
`skills-catalog.json` is absent; clarify the gstack-hard-require failure message;
and document the portable wire-into-CI hook honestly. "Standalone" means
decoupled from workbench-repo-local files, not gstack-free — gstack
`/document-release` remains a hard dependency.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- Native rebuild / dropping the gstack `/document-release` dependency — operator chose hard-require gstack; the native audit + self-heal already exist.
- Building a new CI workflow file — "wire into CI later" is documented (the portable hook), not built here.
- A `doc-spec.sh --check-on-disk` subcommand — deferred to a TODOS follow-up.
- Broadcasting `philosophy.md` prose into consumer repos — the seed carries `doc-spec.md` structure only; each repo writes its own prose.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] `docs/philosophy.md` carries a new sibling principle (general/custom two-tier + portable any-repo pass + wire-into-CI hook) + a front-table row, no work-item IDs; `validate.sh` Checks 19 + 20 green.
- [ ] `/CJ_document-release` runs cold in a no-`skills-catalog.json` repo: Step 6.7.2 emits one clean skip note (no `jq` stderr noise), skips the skill-MD audit half + the `.cj-goal-feature/` scratch write; the registry-doc audit incl. the human-doc no-work-item-ID lint still runs.
- [ ] `doc-spec.sh --validate` passes cold (the mechanical portable guarantee) in a repo with no skills catalog.
- [ ] The gstack-absent failure surfaces `[doc-sync-red]` at the Step 4→5 boundary naming "gstack `/document-release` not installed" as a possible cause.
- [ ] `CJ_document-release` portability stays `local-only`; the Step 5.7 portability gate passes; USAGE.md Check-14 drift resolved.
- [ ] `docs/architecture.md` documents the portable CI hook scoped honestly; a new cold-repo smoke row in `tests/cj-document-release-config.test.sh` proves the guard path. `scripts/test.sh` + `scripts/validate.sh` green.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000097](S000097_cj_document_release_standalone_principle/S000097_TRACKER.md) | Standalone /CJ_document-release + general/custom doc-contract principle | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000097 (all five deltas) | — | Not Started | chjiang | Single atomic story | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh + portability gate green; PR opens + STOPS) | — | Not Started | chjiang | Feature-level verification | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-06-08: Feature scaffolded from APPROVED /office-hours design.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000097 (five deltas) --> #2 End-to-end pipeline run (gates green, PR opens + STOPS)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should the portable helper carry a `doc-spec.sh --check-on-disk` (declared⇔on-disk) subcommand so a consumer repo's CI gate is complete, not just schema-valid? | Deferred to a TODOS follow-up; decide later (out of scope here). |
