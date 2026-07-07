---
type: design
parent: F000084
title: "Backfill the three-layer topic contract for the three cj_goal verbs (deterministic-only enrollment) — Feature Design"
version: 1
status: Approved
date: 2026-07-06
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do not duplicate it
     here. Distilled from the APPROVED /office-hours design doc
     `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-festive-margulis-b0841b-design-20260706-011500.md`. -->

## Problem

The three-layer topic contract exists (a `topic:` axis on the `categories:` rows +
a `topic_contracts:` enrollment list + the HARD `test-spec.sh
--check-topic-contract` surfaced as `validate.sh` Check 30) and its doc-legibility
companion Check 31 requires a `docs/goals/<topic>.md` dream doc + a
`docs/tests/topics/<topic>/` subdir per enrolled topic. But only **`portability`**
is enrolled. The three primary workflow orchestrators — `/CJ_goal_feature`,
`/CJ_goal_task`, `/CJ_goal_defect` — are the workbench's main user-facing surface,
yet their testing sits on the advisory matrix: feature + task share one bundled
`cj-goal-eval` topic covering ONLY the local-hook agentic point, and defect has NO
categories row at all. None of the three reaches CI-push, CI-nightly, or the
local-hook deterministic point as a topic.

This feature backfills the testing for the three verbs as three SEPARATE enrolled
topics — settling the backlog's Open-Question-1 ("one bundled cj-goal-eval topic
or per-verb?") as **per-verb topics**. An operator constraint reshapes the
contract engine itself: only DETERMINISTIC tests may be required (the operator
plans to REMOVE the agentic tests later), so enrollment must not depend on any
agentic row. The existing contract hard-requires a `local-hook`+`agentic` test
per enrolled topic (the both-modes-at-local rule), so this feature adds a
**deterministic-only enrollment flavor** to the contract engine.

## Shape of the solution

Four parts, delivered by one child user-story (one coherent PR; enrollment is the
LAST edit inside it):

1. **The contract-engine seam** — a second optional overlay key
   `topic_contracts_deterministic:` (same slug grammar; cross-list duplicate guard
   in `--validate`); a det-only arm in `--check-topic-contract` requiring three
   points (≥1 `CI-push` + ≥1 `CI-nightly` + ≥1 `local-hook`+`deterministic`, each
   with its front-door doc) while tolerating agentic rows; **union iteration +
   inactive-gate rework in BOTH `_run_topic_contract` AND `_run_topic_docs`**
   (either list non-empty = active; each topic checked under its own list's rule;
   summary-line format + inactive-grep contracts preserved); the
   `spec/test-spec.md` topic-axis prose update mirrored byte-identically into
   `_emit_seed`; a 3-arm negative drill in `scripts/test.sh`.
2. **The coverage matrix** — 11 `categories:` rows (9 new
   `workflow`/`deterministic`/`free`, 2 re-topic'd agentic evals) filling, per
   verb: CI-push (feature: existing `cj-goal-feature-smoke.test.sh` newly
   declared; task: existing `cj-task-scaffold.test.sh` newly declared; defect: NEW
   `cj-goal-defect-smoke.test.sh`), CI-nightly (NEW per-verb chain drills), and
   local-hook deterministic (feature: existing `cj-e2e-gate.test.sh`; task:
   existing `e2e-local.test.sh`; defect: existing `post-land-sync.test.sh`).
3. **The 4 new test scripts** — 1 CI-push defect smoke + 3 CI-nightly chain drills
   driving each verb's deterministic helper chain end to end in a temp clone;
   chain drills registered in `scripts/test.sh` under the `TEST_FAST=1` guard
   (nightly-only on CI by construction).
4. **The Check-31 doc surfaces + hygiene** — 3 dream docs
   (`docs/goals/goal-{feature,task,defect}.md`) + 3 topic subdirs
   (`docs/tests/topics/goal-*/` with `index.md` + `CI-push.md` + `CI-nightly.md` +
   `local-hook.md`) + 9 front-door docs, all declared in `spec/doc-spec-custom.md`;
   prose-truthfulness sweeps (TEST_FAST guard comment, `topic_contracts:` header
   comment, Check 30/31 self-describing surfaces); CLAUDE.md line; TODOS hygiene.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Deterministic-only enrollment seam + per-verb topics + chain drills + doc surfaces + enrollment (all four parts) | S000133 | [S000133_det_only_enrollment_goal_verb_topics/S000133_TRACKER.md](S000133_det_only_enrollment_goal_verb_topics/S000133_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Per-verb topics (`goal-feature` / `goal-task` / `goal-defect`); retire the bundled `cj-goal-eval` label by re-topicing its two rows | Settles backlog Open-Question-1 the way the operator named the scope; per-verb enrollment lets each verb's coverage be judged (and later evolved) independently. `cj-goal-gate-shape` keeps its own shared `cj-goal-gate` topic, untouched. |
| 2 | Deterministic-only enrollment flavor (`topic_contracts_deterministic:`) added to the contract ENGINE, rather than declaring agentic rows the three topics would depend on | Operator directive: the agentic tests are scheduled for removal — chaining enrollment to them bakes in a dependency already planned for deletion. Existing eval rows stay declared + re-topic'd while they live, but required by nothing; deleting them later must not red Check 30. |
| 3 | Approach B — per-verb deterministic CHAIN DRILLS at CI-nightly (3 new heavier integration tests + the defect CI-push smoke) — over A (reuse + attribute; nightly = pure re-declaration) and C (eval-wiring lint fills) | The operator explicitly preferred REAL new coverage: each verb's full deterministic helper chain (worktree entry, phase dispatch, scaffolder, land tail, janitor) driven end to end nightly. C's lint would also have guarded assets scheduled for removal. B keeps A's local-det fills with named per-verb ownership justifications. |
| 4 | Chain drills are NIGHTLY: registered in `scripts/test.sh` under the `TEST_FAST=1` guard (the `test-deploy` pattern) | CI-push stays fast (operator directive); `nightly.yml` already runs the full `test.sh`, so the drills are nightly-only on CI by construction — no workflow-file changes. |
| 5 | Union iteration + inactive-gate rework in BOTH `_run_topic_contract` AND `_run_topic_docs`, preserving the summary-line format + inactive-grep contracts | Both functions today iterate ONLY `$_TOPIC_CONTRACTS` and bail "topic contract inactive" when that one list is empty — without the rework, Check 31 (and a det-only consumer's Check 30) stays GREEN vacuously. `validate.sh` Checks 30/31 SKIP on `^(REGISTRY=absent|topic contract inactive)` and `scripts/test.sh` parses the summary lines — those contracts must keep matching. |
| 6 | Enrollment order: engine seam + tests + docs FIRST, `topic_contracts_deterministic: [goal-feature, goal-task, goal-defect]` LAST | Enrolling before the coverage points + doc surfaces exist would red Checks 30/31 on the landing commit itself. |
| 7 | Local-det fills reuse existing deterministic tests OF agentic-harness plumbing (feature: `cj-e2e-gate.test.sh`; task: `e2e-local.test.sh`; defect: `post-land-sync.test.sh`) | All runnable with zero model spend today. IF the later agentic-removal also deletes those harnesses, the documented fallback is re-declaring the verb's chain drill at `local-hook` (two rows sharing one command — the `test-deploy`/`portability-deploy` precedent). Defect's fill has no agentic coupling. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| With deterministic-only enrollment the agent-driven path of each verb has NO required proof — the green-but-inert blind spot re-opens for these topics (consciously accepted; the evals remain runnable on demand while they exist) | Named in each dream doc's deliberate-posture section; revisit when the agentic-removal TODOS row is worked |
| The union/inactive-gate rework touches grep contracts other surfaces parse (`validate.sh` Checks 30/31 skip-grep; `scripts/test.sh` summary-line parse) — a format drift breaks them silently | Negative-drill arm 3 + full `validate.sh` + `scripts/test.sh` runs at QA; keep `topic contract: enrolled=N findings=M` byte-shape |
| Dual-write footgun: `spec/test-spec.md` prose edit must be byte-identical in `_emit_seed` | Seed-identity test (already in the suite) — run at QA |
| Chain drills can only reach helper SCRIPTS, never the agent-executed `pipeline.md` prose (helpers-only ceiling) | Documented in each drill's front-door doc + the dream docs; accepted by design |
| Exact assertion granularity inside each chain drill | Settled at SPEC/TEST-SPEC level in S000133 (the chain step lists are the contract); finalized during implementation |
| Whether the later agentic-removal also retires `scripts/eval.sh` / `e2e-local.sh` harness code | Out of scope here; fallback for the two local-det fills documented (Decision 7); TODOS removal row enumerates the Check 28/24 + portability blockers |
| Do the 2 re-topic'd eval front-door docs need prose edits at all? (The registry rows are today's only `cj-goal-eval` carrier — the docs may never name the topic) | Verify at build time; edit only if the docs actually name the retired label |

## Definition of done

- [ ] `bash scripts/test-spec.sh --check-topic-contract` reports the three REQUIRED coverage points present for `goal-feature`, `goal-task`, `goal-defect` (deterministic-only arm) and `portability` unchanged (four-point both-modes arm); `validate.sh` Checks 30 + 31 green.
- [ ] Deleting an agentic eval row in a scratch copy does NOT red `--check-topic-contract` for the three new topics (removal-robustness, scoped to Check 30 ONLY) — proven by negative-drill arm 2.
- [ ] `bash scripts/test-spec.sh --check-structure` green (folders + docs + INDEX + front-door sections for every new row).
- [ ] The 4 new test scripts pass locally; `TEST_FAST=1 bash scripts/test.sh` SKIPS the 3 chain drills; a full `test.sh` runs them.
- [ ] Seed-identity test green (spec prose ↔ `_emit_seed` heredoc byte-identical).
- [ ] `validate.sh` fully green (incl. Check 24 with the new units rows).
- [ ] The `cj-goal-eval` topic label no longer appears in the registry.

## Not in scope

- Any NEW agentic test or row — defect's on-disk eval case stays undeclared on the category axis; the existing eval rows are re-topic'd only (operator's deterministic-only directive).
- The agentic-test removal itself — a future TODOS row; this feature un-blocks Check 30 ONLY (Check 28 workflow behaviors, Check 24 eval-unit anchors, and portability's both-modes enrollment are enumerated blockers it does NOT clear).
- Enrolling `/CJ_goal_todo_fix` (or any other labeled topic) — a follow-up TODOS row using the same deterministic-only pattern.
- Testing the agent-executed `pipeline.md` prose of the verbs — deterministic drills reach the helper scripts only (the helpers-only ceiling, accepted and documented).
- Changing `portability`'s enrollment or the four-point both-modes rule — `topic_contracts:` semantics are untouched.
- CI workflow-file changes — `nightly.yml` already runs the full `test.sh`; the `TEST_FAST=1` guard placement is the only cadence mechanism.

## Pointers

- Parent tracker: [F000084_TRACKER.md](F000084_TRACKER.md)
- Roadmap: [F000084_ROADMAP.md](F000084_ROADMAP.md)
- Child story: [S000133_det_only_enrollment_goal_verb_topics/S000133_TRACKER.md](S000133_det_only_enrollment_goal_verb_topics/S000133_TRACKER.md)
- Source /office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-festive-margulis-b0841b-design-20260706-011500.md` (Status: APPROVED)
- Predecessor features: `work-items/features/ops/F000082_three_layer_test_contract_per_topic/` (the topic contract + Check 30), `work-items/features/ops/F000083_portability_test_contract_materialize_enforce/` (Check 31 + the portability doc surfaces)

## Reconciliation note (post-build)

The `topic_contracts_deterministic:` two-list engine seam (Big Decision / Part 1)
was DROPPED at merge time: parallel feature F000086 (v6.0.125) landed the same
goal via a global advisory-agentic demotion of the single `topic_contracts:`
list. The three goal verbs enroll in that single list; all tests + docs are
unchanged. See the F000084_TRACKER.md decision entry dated 2026-07-06.
