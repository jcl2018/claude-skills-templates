---
type: roadmap
parent: F000058
title: "General docs are required — reclassify the contract/agent/backlog docs + views as section: common — Roadmap"
date: 2026-06-09
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline. -->

## Scope

Make the doc-spec contract's general tier honest and complete: the 6 docs every
adopting repo needs (`spec/doc-spec.md`, `CLAUDE.md`, `CHANGELOG.md`,
`TODOS.md`, `docs/doc-general.md`, `docs/doc-custom.md`) become
`section: common`, the portable Common seed grows to declare all 10 general
docs with portable requirement strings, the Common prose is restated as a
10-doc general table carrying the explicit rule "General docs are required,"
the two generated views are regenerated to match, `/CJ_document-release`
states the tier logic and gains an advisory missing-general-doc audit rule,
and philosophy's "Two tiers, one portable pass" principle states
required-ness. One atomic child story carries the whole restatement.

## Non-Goals

- Machine-enforced "required" (`--list-general-docs` + a hard validate.sh check) — rejected for now; Premise 3 keeps "required" on existing machinery + an advisory audit line, never a halt.
- Reclassifying `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md` — they stay `custom` (Premise 2 boundary).
- Any new validate.sh check or `scripts/test.sh` fixture edit — Check 17 is section-agnostic; the build is check-neutral.
- Editing historical records (`CHANGELOG.md`, `work-items/**`) in the secondary-reference sweep — history stays as written.
- `audit_class` changes — the flip touches `section:` only.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `bash scripts/doc-spec.sh --render general` emits 10 rows; `--render custom` emits 3 rows (`CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`).
- [ ] The seed (`doc-spec.sh --seed`) declares the 10 general docs, states "General docs are required," and passes `--validate`; drift test 13 (heredoc == template) green.
- [ ] Workbench Common section byte-identical to the seed Common section (incidental diagram-line drift fixed).
- [ ] `/CJ_document-release` SKILL.md states the tier logic + advisory missing-general-doc audit rule; USAGE.md refreshed (Check 14 green).
- [ ] `docs/philosophy.md` "Two tiers, one portable pass" states the general tier is required in every adopting repo.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` fully green with no new checks and no fixture edits.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000100](S000100_general_docs_required_restatement/S000100_TRACKER.md) | General docs required — complete contract restatement | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000100 (registry flip + seed growth + views + skill statement + philosophy + sweep + tests) | 2026-06-09 | Not Started | chjiang | Single-PR build via /CJ_goal_feature; PR-stop | — |
| 2 | End-to-end pipeline run (QA → doc-sync → portability gate → /ship → PR) | 2026-06-09 | Not Started | chjiang | PR is the architecture gate; merge is a separate human step | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-09: Scaffolded F000058 + S000100 from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000100 (complete contract restatement) ──> #2 End-to-end pipeline run (QA → doc-sync → portability → /ship → PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Add a TODOS row for deferred Approach C (machine-enforced `--list-general-docs` + hard check)? | Only if the operator asks — design says no row by default |
