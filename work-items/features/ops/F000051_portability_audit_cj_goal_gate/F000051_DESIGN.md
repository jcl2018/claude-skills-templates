---
type: design
parent: F000051
title: "Enforce /CJ_portability-audit in the cj_goal orchestrators — Feature Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_portability-audit` is the producer-side static lint that checks each catalog
skill's declared `portability` tier against its actual repo-local dependencies. It
already runs as `validate.sh` Check 18 (advisory; `PORTABILITY_STRICT=1` flips to
hard-fail), and `validate.sh` is wired into `.git/hooks/pre-commit`, so the audit
ALREADY executes on every commit a cj_goal run makes (scaffold, implement,
doc-sync, ship). The request — "add /CJ_portability-audit into the cj_goal
workflows so this universal feature is enforced" — is therefore NOT about making it
run.

It is about closing the enforcement gap: today a portability finding NEVER blocks a
cj_goal run (advisory exit 0), and the verdict is buried in `validate.sh` output
rather than surfaced in the pipeline / PR the way the registered-doc verdicts are.
The catalog baseline is currently clean (`FINDINGS=0`, even raw via
`--no-adjudication`, across all audited skills), so a strict halt-on-any-finding
gate is green today AND behaves as a regression ratchet for free: any finding is by
definition new, so the "block only on new regressions" benefit comes without any
baseline-diff machinery.

## Shape of the solution

Add a 6th shared phase to `scripts/cj-goal-common.sh` — `--phase
portability-audit` — a thin deterministic wrapper shaped like the existing
`pr-check` / `sync` phases. It resolves the engine (`cj-portability-audit.sh`) via
the same sibling-then-`.source` idiom every other phase uses, runs it under
`PORTABILITY_STRICT=1`, parses `FINDINGS=` / `SKILLS_AUDITED=`, and emits a
structured stdout block (`PHASE_RESULT=ok|findings|skipped` + a `VERDICT_LINE=`).
All three orchestrators call this one phase immediately after their Step 5.5
doc-sync block and immediately before `/ship`: clean → write the verdict to a
scratch file + continue; engine-absent → note + continue; findings → HALT with
`[portability-red]`. On green, the existing registered-doc-verdicts surfacing seam
(Step 4.6 / 9.5 / 5.6) is extended to also splice the portability verdict into the
PR body.

This feature is implemented as a single user-story (one cohesive change spanning
the shared script + the 3 orchestrators + tests + docs).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Shared `--phase portability-audit` + 3-orchestrator wiring + PR surfacing + tests + docs | S000091 | [S000091_portability_phase_and_pr_surfacing/S000091_TRACKER.md](S000091_portability_phase_and_pr_surfacing/S000091_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Shared `--phase portability-audit` in `cj-goal-common.sh` (Approach B) | The idiomatic home for every cross-cutting cj_goal concern (worktree / sync / pr-check / cleanup / telemetry). DRY, one halt contract, testable. Approach A (inline per-orchestrator) triples the drift surface + needs 3 halt-table edits; Approach C (export `PORTABILITY_STRICT=1` into the pre-commit path) is fragile env-var propagation across subagent commit shells and surfaces a red as an opaque mid-subagent pre-commit failure, not a clean orchestrator halt. |
| 2 | Gate (halt-on-red) AND surface the verdict in the PR body (premise-gate option C) | The word "enforced" in the request drove the design past mere visibility to a real halt-on-red gate; the PR verdict mirrors the existing registered-doc-verdicts seam for parity. |
| 3 | `validate.sh` Check 18 stays ADVISORY (global) | Flipping its default to strict would block manual commits repo-wide — a separate, broader decision. The new gate is cj_goal-scoped enforcement, exactly as requested. |
| 4 | Engine unchanged; resolve via sibling-then-`.source` (NOT the `_cj-shared`/`CJ_SHARED_SCRIPTS` idiom) | `cj-portability-audit.sh` already supports `PORTABILITY_STRICT` + emits `FINDINGS=`. `cj-goal-common.sh` has zero `_cj-shared` references and the engine resolves its own catalog via `git rev-parse`, so the sibling call from a worktree Just Works. |
| 5 | Insert the gate by CONTENT anchor (after Step 5.5 doc-sync, before `/ship`), NOT by a new step number | The orchestrators' step numbers are already non-monotonic (feature `/ship` is "Step 4" after "Step 5.5"); a new number would be jarring and an implementer grepping a number could cross-wire (todo surfacing is "Step 5.6"). |
| 6 | Gate records NO phase boundary; unconditionally re-run on resume | It is a pure read — cheap + correct. It sits BEFORE the `/ship` boundary, so a resume after a `[portability-red]` halt restarts at the gate, not at ship. No `last_completed_phase` value is added. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `scripts/test.sh` may already enumerate cj-goal-common phases; the new phase needs a parallel test entry (implement-subagent blind spot — new shared-phase logic systematically forgets the test.sh fixture). | Implement phase: grep `test.sh` for cj-goal-common phase enumeration and extend it alongside the new `tests/cj-goal-common-portability.test.sh`. |
| `docs/workflow.md` Check 15b is a HARD gate: each `CJ_goal_*` section needs an ASCII chart + a 4-bullet Touches block. Adding a phase + gate step MUST update all 3 sections or `validate.sh` fails. | Implement phase: update all 3 charts + Touches blocks; verify via `./scripts/validate.sh`. |
| Findings-fixture construction: the test must induce a real dishonest declaration (e.g. a `standalone` skill that adds a root `scripts/*.sh` dep) so the engine returns non-zero under strict mode. | Test phase: build the fixture catalog + assert non-zero exit + `PHASE_RESULT=findings`. |
| Follow-up (OUT OF SCOPE): now that `FINDINGS=0`, consider flipping `validate.sh` Check 18 to strict-by-default in a SEPARATE PR, and refreshing the stale "advisory because we have debt" prose in `skills/CJ_portability-audit/SKILL.md`. | Separate follow-up PR (tracked as a TODO, not this feature). |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `cj-goal-common.sh --phase portability-audit --mode feature` exits 0 + `PHASE_RESULT=ok` on the current clean catalog; non-zero + `PHASE_RESULT=findings` on a fixture with a dishonest declaration; 0 + `PHASE_RESULT=skipped` when the engine is absent.
- [ ] A cj_goal run whose implement phase introduces a dishonest portability declaration HALTS at the new gate with `[portability-red]` BEFORE `/ship`, with a journal entry carrying `next_action` / `resume_cmd` / `pr_url=N/A` / `raw_output_path`.
- [ ] A clean cj_goal run passes the gate (green) and the PR body shows a `### Portability` verdict line alongside the registered-doc verdicts.
- [ ] All 3 orchestrators wired; resume/idempotency preserved (the gate is a pure read — re-running is safe).
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` pass (incl. Check 15b for the updated `docs/workflow.md` Touches blocks + the new cj-goal-common test).

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Flipping `validate.sh` Check 18 to strict-by-default — separate, broader decision (would block manual commits repo-wide); deferred to a follow-up PR.
- Editing the `cj-portability-audit.sh` engine — it already supports `PORTABILITY_STRICT` + emits `FINDINGS=`; no engine change needed.
- Modifying `scripts/drain-one-todo.sh` — the gate is orchestrator-layer; that script only locks + hands off, it does not drive impl/qa/ship.
- Refreshing the stale "advisory because we have debt" prose in `skills/CJ_portability-audit/SKILL.md` — noted as a follow-up, not part of this feature.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000051_TRACKER.md](F000051_TRACKER.md)
- Roadmap: [F000051_ROADMAP.md](F000051_ROADMAP.md)
- Child user-story: [S000091_portability_phase_and_pr_surfacing/S000091_TRACKER.md](S000091_portability_phase_and_pr_surfacing/S000091_TRACKER.md)
- Engine: `scripts/cj-portability-audit.sh` (present; unchanged)
- Host script: `scripts/cj-goal-common.sh`
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-intelligent-goodall-0860b2-design-20260606-155758.md`
