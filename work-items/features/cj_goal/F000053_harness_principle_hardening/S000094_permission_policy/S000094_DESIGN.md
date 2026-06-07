---
type: design
parent: F000053
title: "Permission policy — one declared allow/ask/deny contract — Design"
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
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

GAP B (P5) of F000053: cj_goal permission is implicit and scattered across three unconnected places, only two of them live — `allowed-tools` frontmatter (allow, live), the sensitive-surface AskUserQuestion in leaf-skill code (ask, live), and `cj-handoff-gate.sh`'s denylist (deny, DORMANT — its consumers `/CJ_goal_auto` + `/CJ_goal_run` are deleted). Risky verbs (git push to main, gh pr merge, rm, network) are not enumerated as explicit deny anywhere, and the rule cannot be audited as one contract. See parent `F000053_DESIGN.md`.

## Shape of the solution

ONE declared allow/ask/deny policy artifact (a `doc-spec.md`-style file: prose + a fenced machine-readable block) parsed by a small `scripts/` helper. The two LIVE enforcement points reference it; the dormant handoff-gate denylist derives from it (forward-looking). An advisory `validate.sh` drift check + its parallel `test.sh` fixture close the loop. This is the single story for the concern below; full feature decomposition is in `F000053_DESIGN.md`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Permission policy — one declared allow/ask/deny contract (P5) | S000094 | [S000094_TRACKER.md](S000094_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | `doc-spec.md`-style policy (prose + fenced machine-readable block) parsed by a small `scripts/` helper | Mirrors a pattern the repo already trusts (doc-spec.md) rather than inventing a new artifact shape; minimal row schema `{verb, mode ∈ allow|ask|deny, scope}`. |
| 2 | A verb absent from the policy resolves to deny | "Design permission before capability" (P5) — fail closed, not open. |
| 3 | Live points reference the policy; dormant handoff-gate denylist DERIVES from it | The two live enforcement points (allowed-tools, sensitive-surface AUQ) are the audited contract today; deriving the dormant denylist is forward-looking correctness-if-reactivated, NOT a live-enforcement claim. |
| 4 | Advisory-first `validate.sh` check | Established workbench pattern (portability Check 18); a follow-up PR flips it strict once the policy is reconciled. REQUIRED, not stretch — it is what makes the single-source-of-truth enforceable. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The advisory check could over-flag legitimate enforcement-point divergence | Validated by the `test.sh` injected-drift fixture during implement; advisory exit-0 means false positives never halt CI. |
| Implement step forgets the parallel `test.sh` zzz-test-scaffold fixture for the new `validate.sh` check | Pre-flighted in the implement prompt + recorded as a Todo; enforced in the same PR (repo convention). |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] AC1: one declared allow/ask/deny policy artifact exists (in-scope edits = allow, sensitive surfaces = ask, risky verbs git-push-to-main / gh-pr-merge / rm / network = deny or ask).
- [ ] AC2: the two live enforcement points reference the policy; the dormant handoff-gate denylist derives from it.
- [ ] AC3: a verb absent from the policy resolves to deny.
- [ ] AC4: an advisory `validate.sh` check flags policy↔enforcement drift, with the parallel `test.sh` fixture in the same PR.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Flipping the `validate.sh` check from advisory to strict — its own follow-up PR once the policy is reconciled (advisory→strict ratchet).
- Reactivating `cj-handoff-gate.sh` as a live enforcement point — the denylist only derives from the policy; live enforcement remains out of scope (no live consumer exists).
- Story 1 (trajectory QA, P4) and Story 3 (within-phase receipts, P1) — sibling stories of F000053, shipped as their own PRs.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [../F000053_TRACKER.md](../F000053_TRACKER.md)
- Parent design: [../F000053_DESIGN.md](../F000053_DESIGN.md)
- Story spec: [S000094_SPEC.md](S000094_SPEC.md)
- Story test-spec: [S000094_TEST-SPEC.md](S000094_TEST-SPEC.md)
