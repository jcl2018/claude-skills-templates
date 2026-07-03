---
type: design
parent: S000126
title: "Remove the inline audit + checkpoint from the cj_goal paths and relocate it to a CI-nightly job — Story Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

<!-- Atomic user-story design. Content is intentionally brief; the parent
     feature's DESIGN (F000076_DESIGN.md) and the source /office-hours doc
     carry the full rationale. The precise, load-bearing file inventory lives
     in this story's SPEC.md so implement + QA have the full scope. -->

## Problem

Every orchestrated `CJ_goal_*` build pays ~5-8 min of agent-judged Stage 2/3
doc+test audit on the critical path — the Step 5.6 post-sync audit subagent + the
Step 3.4/4.5/8.5 QA-audit checkpoint AUQ + the `DEFER_AUDIT: true` handoff + the
`halted_at_qa_audit` halt state + the `[qa-audit-declined]` / `[qa-audit-waived]`
markers. But the audit's Stage 1 is deterministic and already runs per-PR in CI
(it IS `validate.sh` Checks 15-19/24/26/27/28), and Stage 2/3 is already advisory
(it never flips QA red). So the inline audit is a redundant + advisory drift-catch
sitting on every build's hot path. This story removes it from the four cj_goal
paths and relocates the advisory audit to a CI-nightly Claude sweep of `main`.

## Shape of the solution

Relocate, don't delete (parent Decision #1). One atomic change: (1) delete Step
5.6 + the checkpoint from the four orchestrators' `pipeline.md` (+ SKILL.md +
USAGE.md), keeping `DEFER_AUDIT: true` as the repurposed skip-inline switch; (2)
light-reword `skills/CJ_qa-work-item/qa.md`'s deferred-path RESULT prose (KEEP its
detection + the 8.6c/8.6d skip); (3) add `.github/workflows/audit-nightly.yml` +
`scripts/audit-nightly.sh` + `tests/audit-nightly.test.sh` modeled on
`eval-nightly.yml`; (4) remove the `qa-audit` gate row + markers from
`spec/test-spec-custom.md` and scrub `spec/test-spec.md`, add the audit-nightly
`units:`/`categories:` rows, and regenerate the test catalog; (5) edit
`spec/workflow-spec.md` and regenerate the workflow docs; (6) refactor the three
affected test files; (7) update the prose set (`CLAUDE.md`, `docs/architecture.md`,
`README.md`, `skills-catalog.json`). The authoritative, line-referenced file
inventory is in this story's SPEC.md `## Architecture`. The deterministic per-PR
gate + standalone `/CJ_qa-work-item` + `/CJ_doc_audit` + `/CJ_test_audit` are
explicitly untouched.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Relocate to CI-nightly; keep `DEFER_AUDIT: true` as the skip-inline switch | See parent F000076_DESIGN.md Big decisions #1 + #2 — deleting loses the drift-catch, keeping it inline is the status quo being removed, and re-enabling QA's inline audit would move the cost rather than remove it. |
| 2 | Model the nightly job on `eval-nightly.yml`; file findings to one `audit-drift` GitHub issue | See parent F000076_DESIGN.md Big decisions #3 — a proven in-repo `claude --print`-in-CI pattern with bounded spend + a secret-less-fork `SKIP`; an issue matches the advisory posture. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Self-modifying pipeline (this run's orchestrator edits the orchestrators executing it; Step 5.6 removed mid-flight). | Parent F000076_DESIGN.md Risks row 1 — the run proceeds from doc-sync straight to `/ship`; verified by a read/dry-run of the resulting `pipeline.md` tail (TEST-SPEC E1). |
| A stray leftover marker (`[qa-audit-declined]` etc.) or the un-removed `qa-audit` gate row trips `validate.sh` Check 24 or leaves dead references. | TEST-SPEC S1 (grep empty) + S2 (`validate.sh` passes, Check 24 clean). |
| The new `audit-nightly.sh` spends budget on a normal `test.sh` / a secret-less fork, or `shellcheck` rejects it. | TEST-SPEC S3 (`test.sh` green incl. the SKIP-path test), S4 (`shellcheck` clean), S5 (`audit-nightly.sh` no-key ⇒ SKIP + exit 0). |

## Definition of done

- [ ] See this story's SPEC.md `## Acceptance Criteria` (Given/When/Then) and the parent ROADMAP success criteria 1-6.

## Not in scope

- The deterministic per-PR gate (`validate.sh` / `validate.yml` / pre-commit); standalone `/CJ_qa-work-item`'s inline 8.6c/8.6d audit; `/CJ_doc_audit` + `/CJ_test_audit` (the verbs); the `DEFER_AUDIT: true` directive (kept, repurposed); Step 5.5 doc-sync + the pre-doc-sync commit; the dormant `qa-audit` arm in `cj-e2e-gate.sh` (left in place — a follow-up TODO). See parent F000076_DESIGN.md `## Not in scope`.

## Pointers

- Parent feature design: [../F000076_DESIGN.md](../F000076_DESIGN.md)
- Parent tracker: [../F000076_TRACKER.md](../F000076_TRACKER.md)
- This story's SPEC (authoritative file inventory): [S000126_SPEC.md](S000126_SPEC.md)
- This story's TEST-SPEC: [S000126_TEST-SPEC.md](S000126_TEST-SPEC.md)
- Source /office-hours design doc: `C:/Users/chang/AppData/Local/Temp/claude/E--projects-claude-skills-templates--claude-worktrees-wonderful-burnell-e85b3a/33df94cb-8d06-4da0-a343-721fbc15956e/scratchpad/qa-gate-redesign-DESIGN.md`
- Precedent (nightly `claude --print` job): `.github/workflows/eval-nightly.yml` + `scripts/eval.sh`.
