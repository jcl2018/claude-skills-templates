---
type: design
parent: F000054
title: "gate-spec.md contract — the doc-spec mirror for gates — Design"
version: 1
status: Draft
date: 2026-06-07
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

The workbench verifies a cj_goal change at four separate layers (local pre-commit
hook / GitHub Actions CI / in-orchestrator pipeline gates / regression ratchets)
that grew up independently, with overlaps and an overloaded "gate" vocabulary. No
single map answers "what stops a broken cj_goal change from landing, and at which
layer?" — the verification story is scattered across three docs, the word "gate"
means both an inline orchestrator halt AND `validate.sh`-as-a-whole, and the
contract is duplicated per orchestrator (each `pipeline.md` re-describes its own
gate sequence, each recent story bolts a bespoke `test.sh` regression guard).
Nothing structurally keeps the four pipelines in sync. See parent
`F000054_DESIGN.md`.

## Shape of the solution

Apply the proven in-repo `doc-spec.md` pattern to gates — the third member of the
`doc-spec → permission-policy → gate-spec` family. Deliver:

1. A new root `gate-spec.md` — ONE file that is both the human-readable
   verification map (prose intro + a four-layer summary table + an ASCII diagram +
   a "division of labor" assigning each guarantee to exactly one owning layer) AND
   the machine source of truth (a fenced `yaml` registry of layers + gates).
2. A new `scripts/gate-spec.sh` reader (mirrors `scripts/doc-spec.sh`) —
   `--validate` / `--list-layers` / `--list-gates`.
3. A new advisory `validate.sh` Check 22 — structurally a clone of Check 21
   (permission-policy): the registry parses AND a per-mode marker drift guard
   cross-checks the four cj_goal pipelines against the one registry.

The four orchestrators + the docs reference the one contract (the de-duplication).
This is the single story for the concern below; full feature framing is in
`F000054_DESIGN.md`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| gate-spec.md contract — one declarative verification contract (human map + yaml registry) + reader + advisory conformance check (P-legibility) | S000096 | [S000096_TRACKER.md](S000096_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | `doc-spec.md`-style artifact (prose map + fenced `yaml` registry) parsed by a small `scripts/` helper, plus an advisory `validate.sh` conformance check. | Truest mirror of the in-repo idiom the repo already trusts (doc-spec.md, permission-policy.md). Legibility comes from symmetry — anyone who understands doc-spec.md understands gate-spec.md on sight. Chosen over a registry inside `cj-goal-common.sh` (bash-embedded data reads worse as "the single map") and over grep-only conformance with no reader script (a weaker mirror; no programmatic `--list-for`). |
| 2 | Declarative contract, NOT a central executor. | Interactive AUQ gates (design-summary) and subagent dispatches (QA) cannot run from one shared bash entry point, so "shared gate contract" = a single DECLARED ordered sequence + a conformance check, NOT a `--run-all-gates` function. Gate implementations stay where they are. |
| 3 | `markers` is a per-mode map + an `{enforced_by: subagent\|auq}` escape hatch (NOT flat `applies_to` + single `halt_marker`). | The adversarial review caught the flat shape as a fatal over-simplification: real markers are irregular across modes (isolation has three markers — `[feature-not-isolated]` / `[investigate-not-isolated]` for defect / `[task-not-isolated]` — and todo has none; only `[portability-red]` + `[doc-sync-red]` are universal). The map encodes "in sync" honestly = "every declared per-mode marker present where declared"; the escape hatch keeps the baseline clean (a gate a mode runs WITHOUT a literal marker, e.g. todo's subagent QA). |
| 4 | Advisory-first `validate.sh` Check 22, mirroring Check 21. | The immediately-preceding sibling check (permission-policy / Check 21, same F000053 saga) shipped advisory; consistency is a legibility win. The honest registry makes the check GREEN on the clean baseline today, so flip-to-strict is a one-line follow-up TODO (a free ratchet), not a reconciliation project. |
| 5 | `--seed` / `--list-for <mode>` reader subcommands DEFERRED (no v1 consumer). | The review flagged them as speculative API. The conformance check computes the per-mode subset internally and does not need `--list-for`; there is no skill that recreates a missing `gate-spec.md` (unlike `/CJ_document-release` for `doc-spec.md`), so `--seed` has no caller. Add either when one appears. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Exact gate enumeration — the full `gates[]` list is derived from the four live pipelines at implement time. | Low risk; the marker universe is known. Implement greps each mode's actual markers and fills the rows using the per-mode `markers` map + `enforced_by` escape + `order`. |
| The advisory check could over-flag a legitimate marker rename in a pipeline. | Validated by the `test.sh` injected-drift fixture during implement; advisory exit-0 means a false positive never halts CI. |
| Implement step forgets the parallel `test.sh` zzz-test-scaffold fixture for the new `validate.sh` check (the repeated F000032/F000034/F000035 blind spot). | Pre-flighted in the implement prompt + recorded as a Todo; enforced in the same PR. Check 22 greps `skills/CJ_goal_*/` and zzz-test-scaffold is not a `CJ_goal_*` skill, so it is naturally skipped — but verify, don't assume. |
| todo's file resolution — grep `pipeline.md` or `SKILL.md`? RESOLVED. | `CJ_goal_todo_fix` keeps gate logic in BOTH files, markers duplicated, so the rule is "marker present in EITHER file for that mode" (dir is `CJ_goal_todo_fix`). |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] AC1: `gate-spec.md` exists at root as a doc-spec-style artifact and a human can answer "what stops a broken cj_goal change from landing, and at which layer?" reading only that file.
- [ ] AC2: `scripts/gate-spec.sh --validate` exits 0 on the committed registry; `--list-layers` / `--list-gates` emit the right sets; a malformed registry → exit 1 + `[gate-spec-no-config]`.
- [ ] AC3: advisory `validate.sh` Check 22 (clone of Check 21) parses the registry + runs the per-mode marker drift guard; GREEN on the clean tree, REPORTS a finding when a declared literal marker is removed from the registry or from both of its mode's files; advisory in v1 (finding prints, exit 0).
- [ ] AC4: the docs disambiguate "gate" — architecture.md new section + "CI gate" relabel; philosophy.md §4 pointer; the four pipelines + CLAUDE.md reference line; `gate-spec.md` registered in `doc-spec.md`.
- [ ] AC5: the parallel `test.sh` regression-guard row ships in the SAME PR; `validate.sh` + `test.sh` + windows Git-Bash green; PR-stop for human review.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Re-plumbing gate *execution* into a shared runner (`--run-all-gates`) — deferred to a future multi-PR epic; gate implementations stay where they are.
- `--seed` / `--list-for <mode>` reader subcommands — no v1 consumer; added when a caller appears.
- Flipping Check 22 advisory → strict — its own follow-up TODO once the registry runs clean across a few real cj_goal builds (Check 21 ratchet precedent).
- A `skills-catalog.json` entry for `gate-spec.sh` — it is a root script like `doc-spec.sh` (not a catalog skill); confirm at implement.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [../F000054_TRACKER.md](../F000054_TRACKER.md)
- Parent design: [../F000054_DESIGN.md](../F000054_DESIGN.md)
- Story spec: [S000096_SPEC.md](S000096_SPEC.md)
- Story test-spec: [S000096_TEST-SPEC.md](S000096_TEST-SPEC.md)
- Closest structural precedent: `../../F000053_harness_principle_hardening/S000094_permission_policy/` (permission-policy.md + scripts/permission-policy.sh + validate.sh Check 21)
- The pattern this mirrors: `doc-spec.md` + `scripts/doc-spec.sh` + `validate.sh` Checks 15/16/17/19/20
