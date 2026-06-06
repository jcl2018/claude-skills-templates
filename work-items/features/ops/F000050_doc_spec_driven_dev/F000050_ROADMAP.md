---
type: roadmap
parent: F000050
title: "doc-spec.md doc-driven development + retire repo-init/json/CJ-DOC-RELEASE.md — Roadmap"
date: 2026-06-06
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Make the workbench **doc-driven**: introduce a single root `doc-spec.md` that
declares which docs the repo carries and what each is for (a portable **Common**
section + a repo-specific **Custom** section + a fenced ```yaml machine registry),
make `/CJ_document-release` enforce and self-heal it on every major `/cj_goal` run,
migrate the `doc/` trio to a human-readable `docs/` (scrubbing all 41 internal
work-item refs), and consolidate the scattered doc machinery — **retiring**
`/CJ_repo-init`, `cj-document-release.json`, and `CJ-DOC-RELEASE.md`. The portable
`doc-spec.md` is the unlock that lets any repo adopt this contract without
replicating the workbench's `CLAUDE.md` structure.

## Non-Goals

- Cross-repo dogfooding (portfolio repo adoption) — seeded but validated only in the workbench for v1; rollout is a follow-up.
- A full new-repo non-doc bootstrap path beyond lazy-create — noted follow-up.
- Auto-generating doc CONTENT — rejected (slop risk); missing docs become stubs only.
- Per-verb whitelist overrides / multi-repo federation / audit_class extensions — deferred to future schema bumps.

## Success Criteria

<!-- Bulleted, measurable, externally observable outcomes. -->

- [ ] A human can open `doc-spec.md` and read, in one place, every doc this repo carries and what each is for.
- [ ] `scripts/validate.sh` runs green end-to-end with Checks 15/15a/15b/16/17 re-pointed to `doc-spec.md`/`docs/` + NEW Check 19 enforcing no-work-item-refs on human docs.
- [ ] `scripts/test.sh` runs green with its `zzz-test-scaffold` fixture updated in lockstep with the check changes.
- [ ] `/CJ_document-release` in a scratch tree self-bootstraps a missing `doc-spec.md` and stub-scaffolds a missing declared doc (idempotent re-run).
- [ ] No dangling references to `cj-document-release.json`, `CJ-DOC-RELEASE.md`, or `CJ_repo-init` remain in scripts/skills/routing (grep-clean); `/CJ_repo-init` is gone from routing + catalog + decision tree.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000090](S000090_doc_spec_driven_dev/S000090_TRACKER.md) | doc-spec.md doc-driven development (12-step migration + 3 retirements) | Open |

## Delivery Timeline

<!-- Forward-looking milestones. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000090 (full 12-step doc-spec migration + retirements) | — | Not Started | chjiang | Single cohesive change carrying the whole feature | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh green; /CJ_document-release scratch-tree QA; PR opened as architecture gate) | — | Not Started | chjiang | The `/CJ_goal_feature` terminal | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-06: Scaffolded F000050 + child S000090 from the APPROVED office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000090 (doc-spec migration + retirements) --> #2 End-to-end pipeline run (validate + test green, PR opened)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Can the autonomous build finish the large blast radius in one pass? | Resume state continues it across passes if not; human PR review is the architecture gate. |
| Helper shape: re-point `cj-document-release-config.sh` to parse doc-spec.md, or replace with a new `doc-spec.sh` parser? | Decided during implementation (SPEC leaves the helper-naming open); either satisfies the derived-whitelist + registry-parse requirement. |
