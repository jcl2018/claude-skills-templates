---
type: roadmap
parent: F000059
title: "test-pipeline — a generated, check-level human view of the verification surface — Roadmap"
date: 2026-06-10
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals (identity), decomposition
     (which user-stories carry the work), and delivery timeline. -->

## Scope

Give a human a readable, trustworthy map of everything that verifies this
repo: a new docs/test-pipeline.md enumerating every validate.sh check (both
ID namespaces + the warning checks), every test.sh unit (registered
tests/*.test.sh sub-suites + inline families), the standalone suites
(test-deploy, eval, windows-smoke), the CI workflows, the git hooks, and the
regression ratchets — each with its label, what it asserts, hard/advisory
disposition, and when it runs. The doc is GENERATED from a new 4th
spec-registry member (spec/test-pipeline.md) by a new parser
(scripts/test-pipeline.sh) via scripts/generate-doc-views.sh, kept in sync by
an extended hard Check 23, and kept COMPLETE by a new hard Check 24 coverage
cross-check (forward anchor-grep + reverse live-surface sweep + floor-assert)
— which also permanently closes the live silently-never-runs test-file gap.
The view registers as a required general-tier doc (the portable Common seed
grows 10 → 11); the registry registers as custom/operational. One atomic
child story carries the whole build.

## Non-Goals

- Re-explaining the layer model — spec/gate-spec.md stays the owner of "what stops a broken change at which LAYER"; the new doc owns check-level enumeration and links to gate-spec (one owner per concern).
- Pipeline-gate registry rows — the rendered view carries a single pointer line to gate-spec's gates[]; orchestrator halt gates are not verification-unit rows.
- Semantic meaning-sync — a check whose behavior changes under a stable banner while its one-line purpose rots is caught by the advisory registered-doc audit, not by the mechanical checks; we buy structural sync, not meaning sync.
- Reverse-sweep coverage of future standalone suites / new inline test.sh families outside the banner grammar — documented forward-anchor-only boundary.
- Any new skill, decision-tree entry, or workflow.md orchestrator section — this feature ships scripts + spec + docs + checks only.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `./scripts/validate.sh` + `./scripts/test.sh` fully green: Check 23 extension diffs the third view; new Check 24 HARD with a clean baseline (stray-test triage resolved); config-test 13 seed byte-identity green with the grown seed.
- [ ] `bash scripts/test-pipeline.sh --validate` passes on the live registry; `--render` is idempotent and work-item-ID-free; docs/test-pipeline.md opens with the per-family summary table and enumerates all 25 numbered validate check IDs + 2 warning checks, every registered test sub-suite + 15 inline families, 3 standalone suites, 3 CI workflows, 2 hooks, and 3 ratchets with disposition + trigger.
- [ ] The four drift drills pass in tests/test-pipeline-spec.test.sh (temp-dir isolated): fake banner reverse-flagged, broken anchor forward-flagged, hand-edited view fails the Check 23 extension, removed runner block forward-flags the orphaned test row.
- [ ] The doc-spec registry declares both new docs; doc-general/doc-custom views regenerate; the Common seed carries eleven general docs in lockstep copies (config-test 13 byte-identity).
- [ ] A first-time reader answers "what protects this repo, where, and when" from the summary table alone in under a minute.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000101](S000101_registry_parser_view_and_checks/S000101_TRACKER.md) | test-pipeline registry + parser + generated view + hard sync/coverage checks | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000101 (stray-test triage + registry + parser + view + Check 23 ext + Check 24 + seed lockstep + tests + secondary docs) | 2026-06-10 | Not Started | chjiang | Single-PR build via /CJ_goal_feature; single-commit atomicity for doc+registry+seed+views | — |
| 2 | End-to-end pipeline run (QA → doc-sync → portability gate → /ship → PR) | 2026-06-10 | Not Started | chjiang | PR is the architecture gate; merge is a separate human step | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-10: Scaffolded F000059 + S000101 from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000101 (registry + parser + view + hard checks + seed lockstep) ──> #2 End-to-end pipeline run (QA → doc-sync → portability → /ship → PR)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| cj-goal-feature-smoke triage: register in test.sh's hand-wired runner section vs retire? | S000101 Step 0 — read the file against the landed feature-verb behavior; both outcomes keep the Check 24 baseline clean |
| Inline test.sh family granularity: do the 15 section-banner anchors stay stable across future test.sh refactors? | Accepted risk; revisit if a rename slips past the coverage check |
