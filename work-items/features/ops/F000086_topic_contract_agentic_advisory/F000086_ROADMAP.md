---
type: roadmap
parent: F000086
title: "Demote the topic contract's agentic coverage point to ADVISORY (global) + enroll validator and full-suite as deterministic three-layer topics — Roadmap"
date: 2026-07-06
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Relax the three-layer topic contract so enrollment is no longer gated on the
hardest-to-build test mode: the local-hook+agentic coverage point demotes from a
hard Check 30 FINDING to a visible per-topic ADVISORY note for ALL enrolled
topics ("three deterministic points required, agentic encouraged"), and the
relaxed contract is immediately used to enroll `validator` and `full-suite` as
deterministic three-layer topics by declaring honest `categories:` rows for
surfaces that already run today (the pre-commit hook, nightly.yml, the
documented local runs) — complete with front-door docs, dream docs, topic
subdirs, the `/CJ_test_audit` Stage-1 wiring fix, a rewritten Check 30 negative
drill, and the full prose sweep (validate.sh Check 30 surfaces, CLAUDE.md,
TODOS.md).

## Non-Goals

- Enrolling `deploy-harness` — its missing CI-push point is a deliberate F000081 speed decision; claiming windows-smoke (labeled `portability`) as its CI-push row would double-count
- Enrolling cj-goal-eval, doc-sync, e2e, or cj-goal-gate — they keep the advisory matrix until their missing surfaces are declared (follow-up TODOs; unenrolled count after this feature: 5)
- Per-topic enrollment flavors or structured enrollment entries (rejected Approaches A/B) — the demotion is global; no new syntax, no parser change
- Building new agentic tests or re-hardening machinery — re-hardening is a documented one-line reversal, not built now
- Touching the festive-margulis session's artifacts or the cj_goal topics — the operator coordinates that session post-land
- Documenting the `--topic` selector in `skills/CJ_test_run/SKILL.md` — a pre-existing sibling gap, explicitly out of scope
- Any new per-PR CI workload — the new rows label EXISTING surfaces only

## Success Criteria

- [ ] `bash scripts/test-spec.sh --check-topic-contract` exits 0 with `topic_contracts: [portability, validator, full-suite]` and prints exactly TWO advisory agentic notes (validator + full-suite)
- [ ] Temp-registry drill: removing portability's agentic row → exit 0 + advisory note + `findings=0`; removing validator's CI-push row → exit 1 + `FINDING:` line
- [ ] `bash scripts/test-spec.sh --check-topic-docs` exits 0 for all three enrolled topics
- [ ] Seed identity holds (`test-spec.sh --seed` byte-identical to `spec/test-spec.md`)
- [ ] `bash scripts/validate.sh` fully green (Checks 15/15a/17/19/24/26/27/30/31)
- [ ] `bash scripts/test.sh` green including the rewritten Check 30 negative drill; shellcheck green
- [ ] `bash scripts/test-run.sh --topic validator` / `--topic full-suite` resolve the new rows; nothing agentic executes by default
- [ ] `/CJ_test_audit` Stage 1 names `--check-topic-contract` + `--check-topic-docs` among its engine calls and surfaces the advisory notes

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000135](S000135_advisory_demotion_and_enrollment/S000135_TRACKER.md) | Advisory agentic demotion + validator/full-suite enrollment | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000135 (engine demotion + prose/seed mirror + enrollment + docs + audit wiring + drill rewrite + prose sweep) | — | Not Started | chang | One coherent PR; implementation order per DESIGN | — |
| 2 | End-to-end pipeline run (validate.sh + test.sh + temp-registry drills + test-run --topic resolution) | — | Not Started | chang | QA phase; success criteria above | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-07-06: Feature scaffolded from the APPROVED /office-hours design doc (chang-claude-practical-kilby-0ee2a8-design-20260706-021054.md).

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000135 (demotion + enrollment + docs + wiring + tests + sweep)
        |
        v
#2 End-to-end pipeline run (validate.sh / test.sh / drills / test-run --topic)
        |
        v
(post-land, operator) festive-margulis session rebases, drops its engine
flavor, enrolls its per-verb topics directly on the relaxed contract
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Festive-margulis coordination: revise that session's draft to drop its engine-flavor story and enroll its per-verb topics on the landed contract | Operator, after this feature lands |
| Re-hardening the agentic point if agentic proofs become cheap in this environment | Documented one-line reversal in the overlay comment; revisit if/when a local claude CLI becomes available |
