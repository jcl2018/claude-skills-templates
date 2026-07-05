---
type: design
parent: F000082
title: "Three-layer test contract per topic — Feature Design"
version: 1
status: Draft
date: 2026-07-04
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The workbench's two-axis test contract (F000078: category × layer + mode) and
F000081's "three test levels per category" advisory matrix get a test to the
right *layer* (`{CI-push, CI-nightly, local-hook}`), but nothing makes a **test
topic** (e.g. portability) prove itself at all three layers, and nothing makes
the **local layer carry both a deterministic AND an agentic test**.

The concrete hole that motivated this: F000081's `git ls-remote`
version-notification has a DETERMINISTIC local test (`portability-version-check`,
a stubbed-`ls-remote` unit test that passes green) but its **agentic** variant is
explicitly DEFERRED in its own front-door doc. The hermetic test proves the
*script logic* while masking whether an operator running a skill preamble in a
stale install actually SEES the nudge. A stubbed test passing green while the real
behavior is unproven is exactly the blind spot an agentic sandbox test closes.

The operator's framing: **every test topic should have three layers of tests
(CI-nightly, CI-push, local); the local layer — because it runs on a machine with
Claude installed — should cover BOTH deterministic and agentic; the agentic test
must run in a sandbox that makes no assumption about the current repo; and all of
this is enforced by the two cj_test_ skills (`/CJ_test_audit`, `/CJ_test_run`).**

## Shape of the solution

Approach B — a first-class `topic:` axis + per-topic ENROLLMENT + a HARD
declaration-only Check + a reusable repo-neutral agentic-sandbox lib, with
portability enrolled as the first proof and every other topic labeled +
grandfathered. Seven change areas:

1. **`topic:` axis (schema)** — an optional 9th column (closed `[a-z0-9-]+`) on every
   `categories:` row, backfilled across all 12 existing rows; touches six consumer
   sites in `test-spec.sh` + `test-run.sh` (parser flush, `--validate`, `--list-categories`,
   `--check-structure` readers, category-mode slicer, `--render-docs`/`--seed-docs` stub).
2. **Enrollment (`topic_contracts:`)** — an overlay-level list naming the topics UNDER
   the three-layer contract: `topic_contracts: [portability]`. The grandfather seam.
3. **Hard Check** — `test-spec.sh --check-topic-contract` (mirrors `--check-workflow-coverage`):
   each enrolled topic must reach ≥1 CI-push, ≥1 CI-nightly, ≥1 local-hook+deterministic
   AND ≥1 local-hook+agentic, each with its front-door doc. Wired into `validate.sh` as a
   new hard Check + a targeted negative test.
4. **Reusable agentic-sandbox lib** — `scripts/lib/agentic-sandbox.sh` (3 helpers), generalizing
   `eval.sh --portability` + `e2e-local`'s `sandbox.sh`, reusing the `SKILLS_UPDATE_REMOTE_URL`
   remote seam (NO `git` PATH-shim).
5. **Portability agentic test** — `tests/portability-version-agentic.test.sh` (command-only row,
   local-only, SKIP-clean); drives the update-check preamble through `claude --print` and PASSES
   iff a `{surfaced_nudge, evidence}` verdict shows the agent relayed the nudge.
6. **`/CJ_test_run` execution** — confirm category/name selection already works; add the ONE new
   `--topic <t>` selector.
7. **Docs + grandfather** — general seed prose + overlay backfill + CLAUDE.md; label the 11
   non-portability topics unenrolled and file follow-up TODOs.

The whole implementation is carried by ONE user-story child (S000132) — the
feature does not decompose into independent parallel units; it is a single
vertical slice whose parts must land atomically (§8 landing sequence).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Topic contract schema + enrollment + hard Check + agentic-sandbox lib + portability proof + `/CJ_test_run` wiring + docs (AC1–AC9) | S000132 | [S000132_topic_contract_portability_proof/S000132_TRACKER.md](S000132_topic_contract_portability_proof/S000132_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B: first-class `topic:` axis + per-topic enrollment + a HARD declaration-only Check | The operator wants the contract to bite, not to emit another advisory NOTE (Approach A) — and the lib alone (Approach C) doesn't make any topic provably covered. |
| 2 | Enrollment (`topic_contracts:`) gates the hard Check | A naive "every local-hook topic needs both modes" would red the build immediately — the workflow topics are all local-hook agentic-only today. Enrollment is opt-in per topic; portability first, the rest grandfathered. |
| 3 | OQ2 RESOLVED — require all three layers AND the local both-modes pair for enrolled topics | Portability already satisfies CI-push + CI-nightly, so requiring all three costs nothing and gives the stronger guarantee. |
| 4 | Reuse the `SKILLS_UPDATE_REMOTE_URL` remote seam (tagged `git init --bare`); NO `git` PATH-shim | A `.sh` git shim is fragile on Windows Git Bash where `git.exe` may not be intercepted, and it reinvents an existing hook; the env-var seam is what `e2e-local` already uses. |
| 5 | Agentic = local-only, never CI (SKIP-clean without `CJ_E2E_LOCAL=1` + a verified claude login) | No per-PR model spend. `mode:agentic ⇒ tier≠free`, so the agentic row is structurally PRESENT in CI but never EXECUTED there; the hard Check proves DECLARATION, the executor proves BEHAVIOR local-only. |
| 6 | Atomic landing: build schema + lib + agentic test + row + doc FIRST, enroll + wire the Check LAST | Enrolling portability before its agentic row exists would make `validate.sh` fail on its own landing commit. |
| 7 | YAGNI on the lib — ship only the 3 helpers the first consumer uses | The operator chose "one reusable lib," but per the review's YAGNI flag we keep it to `mk_neutral_sandbox` / `mk_tagged_bare_upstream` / `run_preamble_via_claude`; the `e2e-local` refactor + `eval.sh` migration are noted fast-follows. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Topic granularity for the workflow evals — is `goal-task-eval` + `goal-feature-eval` one topic or two? (unenrolled, non-blocking) | Settle at implement time; affects only labeling + the follow-up TODO count, not the portability proof. |
| Should portability also get a live `git ls-remote` smoke (the thing that would catch the real v1.1.0 inertness)? | Leaning follow-up / separate-defect to keep this PR about the contract + agentic mechanism, not a networked test. Tracked with the release-tag fix. |
| Dual-write footgun: any `spec/test-spec.md` edit needs a byte-identical `_emit_seed` heredoc edit in `test-spec.sh` | Guarded by the existing seed-identity test; call it out in the commit. The `topic:`/`categories:` axes are overlay-only so the machine `yaml` block does not change. |
| The six `categories:` consumer sites must all widen 8→9 fields together or the TSV field-count drifts | Adversarial-review checklist in §1 of the design; verified by `--validate` + `--list-categories` + `--check-structure` all passing after the change (AC1). |
| Windows Git Bash portability of the new lib + agentic test (POSIX+LF, jq CR-strip, `date_to_epoch`, no `git` shim) | The `windows-smoke` job + the repo's portability rules; the NO-`git`-shim decision (#4) is specifically the Windows-safety guard. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." A reviewer should be
     able to verify each item without asking the author. -->

- [ ] AC1 — `topic:` parses + validates; all 12 rows carry a topic; `--list-categories` shows it.
- [ ] AC2 — `topic_contracts: [portability]` parses; portability enrolled.
- [ ] AC3 — `--check-topic-contract` HARD-fails on a missing portability agentic row/test/doc, PASSES once present; the `scripts/test.sh` negative test plant→fail→restore→pass invokes ONLY the targeted engine.
- [ ] AC4 — `validate.sh` gains the new hard Check; green on this repo; CI-safe (declaration-only, zero model spend).
- [ ] AC5 — `scripts/lib/agentic-sandbox.sh` exists (POSIX+LF); its deterministic helpers unit-smoked with no model spend.
- [ ] AC6 — `tests/portability-version-agentic.test.sh` SKIPs clean without the local-only gate; live, it drives `claude --print` (cap `$0.50`) and PASSES iff `{surfaced_nudge, evidence}` shows the nudge relayed.
- [ ] AC7 — `/CJ_test_run portability-version-agentic` (`--e2e`/`--all`) runs it; a default `free` run SKIPs it; `/CJ_test_audit` Stage 1 reports it wired.
- [ ] AC8 — docs green: front-door doc has the three sections; index + doc-spec updated; `validate.sh` Checks 24/26/27/28 + `doc-spec --check-on-disk` pass.
- [ ] AC9 — CLAUDE.md + `spec/test-spec.md`/`--seed` + overlay prose updated; grandfathered topics + follow-up TODOs recorded.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Fixing the real release-tag inertness (upstream stuck at `v1.1.0` while VERSION is 6.0.116) — a SEPARATE defect. The agentic test's job is to be the thing that would CATCH that class of inertness (given a tagged upstream in the sandbox), not to fix tagging here.
- Migrating the 11 non-portability topics into the three-layer contract — they are labeled + grandfathered with follow-up TODOs; only portability's agentic test is actually built.
- Refactoring `e2e-local`'s `sandbox.sh` onto the new lib, and migrating `eval.sh --portability` onto it — noted fast-follows, not this PR (YAGNI: ship the 3 helpers the first consumer uses).
- Physically migrating the command-only `tests/*.test.sh` rows into `tests/<category>/<layer>/` — deferred; the new portability agentic row is a flat command-only path like the existing 11 (`--check-structure` (b) exempts it).
- A live/networked `git ls-remote` portability smoke — deferred to a separate defect (tracked with the release-tag fix).

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. -->

- Parent tracker: [F000082_TRACKER.md](F000082_TRACKER.md)
- Roadmap: [F000082_ROADMAP.md](F000082_ROADMAP.md)
- Child user-story: [S000132_topic_contract_portability_proof/S000132_TRACKER.md](S000132_topic_contract_portability_proof/S000132_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-inspiring-keller-69636a-design-20260704-132238.md`
- Predecessor feature: `work-items/features/ops/F000081_three_layer_test_contract_and_version_notify/` (the three-layer test contract + version notification whose deferred agentic test this feature closes)
