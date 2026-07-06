---
type: design
parent: F000086
title: "Demote the topic contract's agentic coverage point to ADVISORY (global) + enroll validator and full-suite as deterministic three-layer topics — Feature Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. Distilled from
     the /office-hours design doc
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-practical-kilby-0ee2a8-design-20260706-021054.md
     (Status: APPROVED, Mode: Builder). -->

## Problem

The three-layer topic contract (`test-spec.sh --check-topic-contract`, surfaced
as `validate.sh` Check 30 and `/CJ_test_audit` Stage 1) HARD-requires every
ENROLLED topic to carry FOUR coverage points: a CI-push test, a CI-nightly test,
a local-hook DETERMINISTIC test, and a local-hook AGENTIC test (the
"both-modes-at-local rule"). Agentic tests are difficult to build and run on
this machine, and the operator's standing posture is that agentic proofs run
on-demand / are handled by another agent — they should not be a REQUIREMENT for
enrollment. The rule is currently the blocker: 7 distinct labeled topics sit
UNENROLLED on the advisory matrix (validator, full-suite, deploy-harness,
cj-goal-eval, doc-sync, e2e, cj-goal-gate — the overlay comment's "11" is a
stale count this feature also corrects). For `validator`/`full-suite`, every
missing point EXCEPT agentic corresponds to a surface that already runs today
and needs only declaring; the agentic point is the only one with no buildable
surface on this machine. So the hard, can't-rot layer verification the contract
exists to provide covers exactly one topic (`portability`).

This feature (1) demotes the local-hook+agentic coverage point from a hard
FINDING to a visible ADVISORY note for ALL enrolled topics — the contract
becomes "three deterministic points required, agentic encouraged" — and
(2) uses the relaxed contract to enroll two of the three testing-infra topics,
`validator` and `full-suite`, by declaring honest `categories:` rows for
surfaces that already run today. `deploy-harness` deliberately stays unenrolled.

## Shape of the solution

One user-story carries the whole implementation (engine + prose/seed mirror +
overlay enrollment + docs + audit wiring + tests + prose sweep — one coherent
PR). The implementation order: engine loop change → general prose + seed
mirror → overlay (enrollment + 4 rows) → front-door docs + index → dream docs +
topic subdirs + doc-spec declarations → Check 30 drill rewrite → prose sweep.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Advisory demotion (engine + prose/seed), validator + full-suite enrollment, topic docs, /CJ_test_audit Stage-1 wiring, Check 30 drill rewrite, prose sweep | S000135 | [S000135_advisory_demotion_and_enrollment/S000135_TRACKER.md](S000135_advisory_demotion_and_enrollment/S000135_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C — GLOBAL advisory demotion of the (local-hook, agentic) coverage point for every enrolled topic; the three deterministic points stay HARD | Chosen by the operator at D4 as an informed reversal of the session's Approach A recommendation (per-topic deterministic-only flavor; portability keeps its enforced agentic point). The operator's standing posture is "agentic tests are never a requirement — they run on-demand or via another agent"; a per-topic flavor preserves machinery for a distinction the operator does not want to maintain. No new syntax, no parser change — one loop change in `_run_topic_contract` plus prose/seed/test updates. Approach B (structured enrollment entries with `modes:`/`agentic: external`) rejected as YAGNI (parser rewrite + much larger spec/seed dual-write delta). |
| 2 | Deterministic enrollment still means all three LAYERS — CI-push + CI-nightly + local-hook{deterministic} — each row with its front-door doc, plus Check 31's dream doc + topic-subdir pages | The demotion is the agentic MODE point, never a layer. The three-layer skeleton is what actually stops rot. |
| 3 | `validator` + `full-suite` enroll by declaring rows for LIVE surfaces only (the pre-commit hook, nightly.yml, the documented local runs) — no new test scripts | Honest rows only: every new `categories:` row must describe a surface that genuinely runs at that layer today. No aspirational rows. CI-push stays fast — the new rows label EXISTING surfaces; nothing new runs in CI-push. |
| 4 | `deploy-harness` stays UNENROLLED | Its missing CI-push point is a deliberate F000081 speed decision (test-deploy moved off the per-PR gate), and claiming windows-smoke (labeled `portability`) as its CI-push row would double-count. Documented in the overlay comment + a TODOS note. |
| 5 | The general-spec prose change mirrors byte-identically into the `_emit_seed` heredoc; the Check 30 negative test is REWRITTEN for the new semantics | The dual-write footgun is guarded by the seed-identity test; the old drill asserts agentic-required semantics that become untrue. |
| 6 | Wire `--check-topic-contract` + `--check-topic-docs` into `/CJ_test_audit` Stage 1 (+ a CONDITIONAL Stage-2 agentic-row judgment clause) | Fixes an inherited drift: CLAUDE.md and the spec have claimed that surfacing since F000082, but the skill never actually invokes either engine call. After the demotion the Stage-2 clause is lawfully vacuous for agentic-row-less topics. |
| 7 | The festive-margulis session consumes the landed contract change and drops its own engine modification | Collision on the same engine function is avoided by coordination (operator action); this feature does NOT touch the cj_goal topics or that session's artifacts. The demotion supersedes its planned per-topic flavor with something strictly simpler. |
| 8 | Advisory notes surface where the contract is READ, not on every green build | The note prints in every direct engine run; `validate.sh`'s green path echoes only the `topic contract:` tail line — "topic X has no agentic proof" stays visible without ever redding a build. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Festive-margulis coordination: that session's DRAFT design includes adding a deterministic-only enrollment flavor to the same engine function; after this feature lands it should be revised to simply enroll its per-verb topics (the flavor is obsolete) | Operator coordinates after land; nothing in this feature edits that session's artifacts |
| Later re-hardening: if agentic proofs ever become cheap to run in this environment | One-line reversal (move the agentic entry back into the FINDING loop) plus the same prose/seed mirror — noted in the overlay comment, not built now |
| Accepted trade of Approach C: `portability`'s agentic proof stops being ENFORCED | It remains present, declared, and runnable via `/CJ_test_run --topic portability --e2e`; the Check 30 drill's agentic-removal arm asserts the advisory note appears |
| Consumer prose-vs-engine drift: an EXISTING consumer repo keeps the old "agentic required" prose in its seeded `spec/test-spec.md` while the deployed engine behaves advisory (`seed-contracts` is idempotent — present ⇒ skip) | Accepted, documented drift: only fresh seeds carry the new prose; the engine's advisory behavior governs regardless |
| Dual-write footgun: `spec/test-spec.md` topic-axis prose vs the `_emit_seed` heredoc | Seed-identity test guards it; scope the rewrite unit as the WHOLE `## The topic axis` section so the mirror delta is scoped once |

## Definition of done

- [ ] `bash scripts/test-spec.sh --check-topic-contract` exits 0 with `topic_contracts: [portability, validator, full-suite]` and prints exactly TWO advisory agentic notes (validator + full-suite; portability has an agentic row, so no note for it)
- [ ] Temp-registry drill: removing portability's agentic row → exit 0, advisory note present, `findings=0`; removing validator's CI-push row → exit 1, `FINDING:` line present
- [ ] `bash scripts/test-spec.sh --check-topic-docs` exits 0 (dream docs + topic subdirs present for all three enrolled topics)
- [ ] Seed identity holds: `test-spec.sh --seed` byte-identical to `spec/test-spec.md` (and `templates/` copy if applicable)
- [ ] `bash scripts/validate.sh` fully green (Checks 15/15a/17/19/24/26/27/30/31)
- [ ] `bash scripts/test.sh` green including the rewritten Check 30 negative drill; shellcheck green
- [ ] `bash scripts/test-run.sh --topic validator` and `--topic full-suite` resolve the new rows (free-tier rows run; nothing agentic executes by default)
- [ ] `skills/CJ_test_audit/SKILL.md` Stage 1 names `--check-topic-contract` + `--check-topic-docs` among its engine calls, and the advisory agentic notes appear in a Stage-1 report run against this repo

## Not in scope

- Enrolling `deploy-harness` — its missing CI-push point is a deliberate F000081 speed decision; claiming windows-smoke as its CI-push row would double-count (documented in the overlay comment + a TODOS note)
- Enrolling the remaining labeled topics (cj-goal-eval, doc-sync, e2e, cj-goal-gate) — they keep the advisory matrix until their surfaces are declared (follow-up work; the corrected unenrolled count after this feature is 5)
- The cj_goal topics / the festive-margulis session's artifacts — that session consumes the landed contract change and is coordinated by the operator
- Per-topic enrollment flavor or structured enrollment entries (Approaches A/B) — rejected; global advisory demotion needs no new syntax
- Building any new agentic test or re-hardening machinery — re-hardening is a documented one-line reversal, not built now
- `skills/CJ_test_run/SKILL.md` prose for the `--topic` selector — a pre-existing sibling gap, explicitly OUT of this feature's scope (the selector lives in the script and works)
- New per-PR CI workload — the new `categories:` rows label EXISTING surfaces; nothing new runs in CI-push

## Pointers

- Parent tracker: [F000086_TRACKER.md](F000086_TRACKER.md)
- Roadmap: [F000086_ROADMAP.md](F000086_ROADMAP.md)
- Child story: [S000135_advisory_demotion_and_enrollment/S000135_TRACKER.md](S000135_advisory_demotion_and_enrollment/S000135_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-practical-kilby-0ee2a8-design-20260706-021054.md` (APPROVED)
- Related features: `work-items/features/ops/F000082_three_layer_test_contract_per_topic/` (the contract this demotes a point of), `work-items/features/ops/F000083_portability_test_contract_materialize_enforce/` (Check 31 topic docs), `work-items/features/ops/F000081_three_layer_test_contract_and_version_notify/` (the deploy-harness speed decision)
