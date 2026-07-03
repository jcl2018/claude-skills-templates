---
type: design
parent: F000076
title: "QA-gate slimming — relocate the agent-judged audit to CI-nightly — Feature Design"
version: 1
status: Draft
date: 2026-07-03
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. -->

## Problem

Every orchestrated `CJ_goal_*` build (feature, task, defect, todo_fix) pays ~5-8
min of **agent-judged Stage 2/3 doc+test audit** on the critical path, wrapped in
a lot of machinery: the `DEFER_AUDIT: true` handoff (QA skips its inline audit so
the orchestrator can run it later), **Step 5.6** (a combined post-sync
`/CJ_doc_audit` + `/CJ_test_audit` subagent), the **Step 3.4/4.5/8.5** QA-audit
checkpoint AUQ, and the halt state `halted_at_qa_audit` + the markers
`[qa-audit-declined]` / `[qa-audit-waived]`.

Two facts make this removable from the hot path: (1) the audits' Stage 1 is
deterministic and already runs per-PR in CI — the engine calls ARE `validate.sh`
Checks 15-19/24/26/27/28, which `validate.yml` runs on every PR and the pre-commit
hook runs locally, so re-running Stage 1 inline is redundant; and (2) Stage 2/3
(the ~5-8 min part) is already advisory — it never flips QA red, it surfaces
findings at a checkpoint the operator can Continue past. So it is an advisory
drift-catch, not a hard gate.

## Shape of the solution

Keep the deterministic hard gate per-PR (unchanged). Relocate the advisory
agent-judged audit to a CI-nightly Claude sweep of `main` that files findings.
The orchestrator QA tail loses two whole steps (the post-sync audit + the
checkpoint); `DEFER_AUDIT: true` STAYS, its meaning shifting from "defer to the
orchestrator's post-sync re-run" to "skip the inline audit; the nightly CI job
covers it." Standalone `/CJ_qa-work-item` is unchanged (keeps its inline 8.6c/8.6d
audit); `/CJ_doc_audit` and `/CJ_test_audit` are unchanged (the nightly job calls
them). The nightly job (`.github/workflows/audit-nightly.yml` + a gated
`scripts/audit-nightly.sh` runner + a deterministic `tests/audit-nightly.test.sh`)
is modeled on the existing `eval-nightly.yml`. This is a single atomic multi-file
change — all edits (orchestrator removals, the new job, the registry/gate edits,
the regenerated docs, the prose) must land together so the pre-commit `validate.sh`
+ CI `test.sh` stay green. The whole scope is one cohesive reshape, so it
decomposes into a single user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Remove the inline post-sync audit + QA-audit checkpoint from all four cj_goal orchestrator paths and relocate the audit to a new CI-nightly Claude job (`.github/workflows/audit-nightly.yml` + `scripts/audit-nightly.sh` + `tests/audit-nightly.test.sh`), keeping the deterministic per-PR gate + standalone audit verbs intact | S000126 | [S000126_relocate_audit_to_nightly/S000126_TRACKER.md](S000126_relocate_audit_to_nightly/S000126_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Relocate the audit to CI-nightly — do NOT delete it, and do NOT keep it inline | Deleting the audit entirely loses the advisory drift-catch that has real value on a doc-first workbench. Keeping it inline is the status quo (the ~5-8 min + machinery being removed). Relocating to a nightly `claude --print` sweep of `main` preserves the drift-catch while taking it off every build's critical path — the only option that both slims the tail AND keeps the audit. |
| 2 | Keep `DEFER_AUDIT: true` in the QA dispatch (repurpose it), rather than removing it and re-enabling QA's inline 8.6c/8.6d for orchestrator runs | The point is to REMOVE ~5-8 min from the orchestrated build; re-enabling QA's inline audit would just move the cost, not remove it. `DEFER_AUDIT: true` already suppresses QA's inline audit — its meaning shifts from "orchestrator re-runs post-sync" to "nightly CI covers it." Minimal surface: the QA↔orchestrator handshake and the RESULT shape (`AUDITS=deferred`, no `AUDIT_FINDINGS` block) are unchanged; only the deferred-path prose is reworded. |
| 3 | Model the nightly job on `eval-nightly.yml` (cron + `workflow_dispatch`, secret pre-check, budget cap, `SKIP` without `ANTHROPIC_API_KEY`), file findings to ONE create-or-update `audit-drift` GitHub issue | `eval-nightly.yml` is a proven in-repo precedent for running `claude --print` in CI nightly with bounded spend and a secret-less-fork `SKIP`. Reusing the pattern means the safety story (no surprise model spend on a normal `test.sh` / a secret-less fork) is already established. An issue (not a blocking gate) matches the advisory posture — the maintainer watches the `audit-drift` issue, surfaced in the job summary. |
| 4 | Single-story decomposition (one atomic change), not multi-story | The orchestrator removals, the new job, the registry/gate edits, and the regenerated docs must land together to keep the pre-commit `validate.sh` + CI `test.sh` green — an intermediate state (e.g. checkpoint removed but the `qa-audit` gate row still declared, or the job added but the marker still referenced) would be red. There is one cohesive concern (move the audit off the hot path), so one user-story carries it. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Self-modifying pipeline: this build runs a `CJ_goal_*` orchestrator that edits the very orchestrators (`CJ_goal_feature/pipeline.md` etc.) executing it. Once implement removes Step 5.6 + the checkpoint, this run's own post-sync-audit step no longer exists. | The run recognizes the audit step is removed by this change (its explicit intent) and proceeds from doc-sync straight to `/ship`. No behavior the run still depends on is deleted mid-flight. Verified by QA: a dry-run/read of the resulting `pipeline.md` shows the doc-sync → `/ship` tail with no audit node. |
| A stray leftover marker (`[qa-audit-declined]` / `[qa-audit-waived]` / `halted_at_qa_audit`, or the `qa-audit` gate row in `spec/test-spec-custom.md`) trips `validate.sh` Check 24 (gate-marker drift) or leaves dead references. | QA: the grep-is-empty smoke row + `./scripts/validate.sh` passing (Check 24 clean). The `qa-audit` gate row + its markers must be removed together so Check 24 stays consistent. |
| The new `audit-nightly.yml` / `scripts/audit-nightly.sh` could accidentally spend model budget on a normal `test.sh` run or a secret-less fork. | `scripts/audit-nightly.sh` SKIPs (exit 0) without `ANTHROPIC_API_KEY`; the deterministic `tests/audit-nightly.test.sh` asserts the SKIP path with no key and stubs `claude`/`gh` for the findings-parse → issue-decision logic. QA runs `bash scripts/audit-nightly.sh` with no key and confirms `SKIP` + exit 0. |
| `shellcheck` (CI `validate.yml` fails on ANY finding) could reject the new `scripts/audit-nightly.sh`. | QA runs `shellcheck scripts/audit-nightly.sh` locally before ship (part of the verify-before-push discipline). |
| The generated workflow docs (`docs/workflow.md` + `docs/workflows/*.md`) and test catalog (`docs/test-catalog.md` + `docs/tests/*.md`) drift from their registries after the `spec/workflow-spec.md` / `spec/test-spec-custom.md` edits. | Edit the registries, then regenerate via `workflow-spec.sh --render-docs` + `test-spec.sh --render-docs`; QA confirms Check 27 + Check 26 pass. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] Step 5.6 (post-sync audit) + the QA-audit checkpoint (Step 3.4/4.5/8.5) are gone from all four `skills/CJ_goal_*/` paths; `grep -rn "halted_at_qa_audit\|qa-audit-declined\|qa-audit-waived"` over those four dirs returns nothing.
- [ ] `DEFER_AUDIT: true` STAYS in the QA dispatch; `skills/CJ_qa-work-item/qa.md` keeps its detection + the 8.6c/8.6d skip, deferred-path RESULT prose reworded to "nightly CI covers the audit."
- [ ] `.github/workflows/audit-nightly.yml` + `scripts/audit-nightly.sh` + `tests/audit-nightly.test.sh` exist and follow the `eval-nightly.yml` pattern.
- [ ] `bash scripts/audit-nightly.sh` with no `ANTHROPIC_API_KEY` prints `SKIP` and exits 0.
- [ ] `./scripts/validate.sh` passes (esp. Check 24, Check 26, Check 27, Check 28); `./scripts/test.sh` full suite green (incl. the new + updated tests); `shellcheck scripts/audit-nightly.sh` clean.
- [ ] The deterministic per-PR gate (validate.sh / validate.yml / pre-commit) + standalone `/CJ_qa-work-item` + `/CJ_doc_audit` + `/CJ_test_audit` are unchanged.

## Not in scope

<!-- Explicit non-goals. -->

- The deterministic per-PR gate — `scripts/validate.sh` (all checks), `.github/workflows/validate.yml`, the pre-commit hook — untouched. It stays the hard merge gate.
- Standalone `/CJ_qa-work-item` — its inline Step 8.6c/8.6d audit is KEPT (only the orchestrator-driven `DEFER_AUDIT: true` path changes meaning); the deferred-path RESULT prose is the sole `qa.md` edit.
- `/CJ_doc_audit` + `/CJ_test_audit` (the audit verbs themselves) — unchanged; the nightly job CALLS them standalone.
- `DEFER_AUDIT: true` — the directive is KEPT (repurposed as the skip-inline switch), not removed.
- Step 5.5 doc-sync (`/CJ_document-release`) + the idempotent pre-doc-sync commit — KEPT; only the audit step that FOLLOWED doc-sync is removed.
- `cj-e2e-gate.sh` — its `qa-audit` allowlist arm goes dormant-for-orchestrators but is LEFT in place (pure helper, still unit-tested). Cleaning that arm out is a follow-up TODO.
- Follow-up TODOs (out of scope): physically moving test scripts into `tests/<category>/`; cleaning the dormant `qa-audit` arm out of `cj-e2e-gate.sh` + its test; email/Discord notification beyond the GitHub issue.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000076_TRACKER.md](F000076_TRACKER.md)
- Roadmap: [F000076_ROADMAP.md](F000076_ROADMAP.md)
- Child story (authoritative file inventory): [S000126_relocate_audit_to_nightly/S000126_SPEC.md](S000126_relocate_audit_to_nightly/S000126_SPEC.md)
- Source /office-hours design doc: `C:/Users/chang/AppData/Local/Temp/claude/E--projects-claude-skills-templates--claude-worktrees-wonderful-burnell-e85b3a/33df94cb-8d06-4da0-a343-721fbc15956e/scratchpad/qa-gate-redesign-DESIGN.md`
- Precedent (nightly `claude --print` job pattern): `.github/workflows/eval-nightly.yml` + `scripts/eval.sh`.
- Origin of the audit being relocated: F000064 (post-sync-authoritative-audit reorder — the Step 5.6 + checkpoint being removed).
