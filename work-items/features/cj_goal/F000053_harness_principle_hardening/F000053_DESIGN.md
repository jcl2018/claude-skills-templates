---
type: design
parent: F000053
title: "cj_goal harness-principle hardening — Feature Design"
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

The `cj_goal` orchestrator framework (CJ_goal_feature / CJ_goal_defect /
CJ_goal_todo_fix + their shared scripts, work-item model, resume machinery, QA
step, ship/land tail) was mapped against five agent-harness engineering
principles, now recorded in `docs/philosophy.md` ("The runtime standard: five
harness-engineering principles"): P1 context is finite, curate it; P2
externalize state to durable storage; P3 design for stateless handoff; P4
verification is a continuous gate, judge the trajectory not just the artifact;
P5 tools and permissions are first-class (explicit allow/ask/deny; design
permission before capability). The framework is already strong on P2 (per-branch
resume state file + committed tracker journal + SPEC/DESIGN/TEST-SPEC triplet +
per-run telemetry) and P3 (validate-before-skip resume: recorded SHA must be
ancestor-of-HEAD, any PR must still read OPEN, the recorded design doc must still
read APPROVED; leaf subagents return a one-line RESULT, never their working
context). Those two — the hardest-to-retrofit habits — need nothing.

Three real gaps remain, and they are the cheap-to-add tail, not the core:

- **GAP A (P4) — verification can lie about correctness (user-story / feature
  path).** QA runs the test rows, but two distinct resume mechanisms can skip a
  genuine re-run. (1) `qa.md` Step 3's NO-OP short-circuits user-story QA when
  both QA-owned gates are checked AND a `[qa-pass]` journal entry is **dated-today
  OR matches HEAD** (`qa.md:144-146`); the date-only branch is the dangerous one
  (a same-day earlier-commit marker satisfies it). (2) The feature orchestrator's
  resume is phase-granular and **skips the whole QA phase** when
  `LAST_PHASE ∈ {qa, ship}` on a still-valid SHA (`pipeline.md:502`); it never
  dispatches QA, so a same-SHA resume where untracked / generated / fixture /
  environment state changed reports ready without re-verifying. (Defect/task QA
  already re-runs unconditionally, `CJ_goal_defect/pipeline.md:857`, and a stale
  SHA already demotes qa->impl, so this gap is the user-story/feature path
  specifically, not all three verbs.) Boundary checks
  (`/CJ_personal-workflow check`) validate artifact SHAPE, not behavior.
- **GAP B (P5) — permission is implicit and scattered.** The permission rule
  lives in three unconnected places, only two of them live: `allowed-tools`
  frontmatter (allow, live), sensitive-surface AskUserQuestion in leaf-skill code
  (ask, live), and `cj-handoff-gate.sh`'s denylist (deny, **dormant** — its
  consumers `/CJ_goal_auto` and `/CJ_goal_run` are deleted, so no current
  orchestrator invokes the gate; the three live orchestrators cite it only
  rhetorically to justify PR-stop). No single declared policy; the riskiest verbs
  (git push to main, gh pr merge, rm, network) are not enumerated as explicit deny
  anywhere. A deny-list that exists but nothing honors is exactly the "polish on an
  unsafe control plane" risk: it cannot be audited as one contract.
- **GAP C (P1) — no within-phase context curation.** The framework compacts
  BETWEEN phases (the silent build dispatches scaffold / implement / QA as
  depth-<=2 leaf subagents returning <=200-token summaries) but never WITHIN a
  long inline phase. `/office-hours` runs inline (subagents have no
  AskUserQuestion tool), so its full transcript sits in the orchestrator window
  through the rest of the build.

## Shape of the solution

One umbrella feature, three child user-stories, built **correctness-first**: the
QA story first, then the permission policy, then the receipts story. Each story
is independently shippable as its own reviewable PR; the build order is a
value/risk ordering, not a hard dependency chain. The implementation surface is
mostly skill `SKILL.md` / `pipeline.md` prose + shared `scripts/*.sh` + one new
declared policy file. Every story PR-stops for human review (the
`cj-handoff-gate.sh` denylist marks all of these surfaces unsafe-to-auto-deploy —
correct here, not a limitation). Existing CI is the gate: `scripts/validate.sh` +
`scripts/test.sh` + the windows-latest Git-Bash job; new checks land advisory
first (the workbench's established pattern, e.g. portability Check 18).

S000093 and S000095 share ONE execution-receipt schema (whichever ships first
sets it); the schema is ported from `work-copilot`'s tracker-frontmatter
`receipts:` block convention rather than invented.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Trajectory QA — QA that cannot lie about correctness; close both GAP A skip paths, emit a structured execution receipt, fail closed (P4) | S000093 | [S000093-trajectory_qa/S000093_TRACKER.md](S000093-trajectory_qa/S000093_TRACKER.md) |
| Permission policy — one declared allow/ask/deny contract the live enforcement points reference; risky verbs explicit (P5) | S000094 | [S000094-permission_policy/S000094_TRACKER.md](S000094-permission_policy/S000094_TRACKER.md) |
| Within-phase receipts — write a compact phase receipt after the office-hours inline phase; continue from the receipt, not the raw transcript (P1) | S000095 | [S000095-within_phase_receipts/S000095_TRACKER.md](S000095-within_phase_receipts/S000095_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: full saga (one feature, three stories), **correctness-first** sequence. | Over Approach B (permissions-first) and Approach C (QA-fix-only). C is the smallest diff but leaves the "real system" test (the permission contract) unaddressed and is less aligned with the stated multi-item-saga intent. B de-risks first but trades correctness urgency. |
| 2 | **Correctness-first reorder: S000093 (QA) ships first, not S000094 (permissions).** | Codex's challenge to the stated P5-first wedge: a system that can silently bless stale or fake QA is *already lying about correctness*, while fuzzy permissions are mostly a containment/governance defect given the existing PR-stop + human review. The falsification test ("one same-SHA resume path where QA is skipped but behavior changed, still yields ready") is already satisfied by GAP A, so the challenge stands. Accepted on the argument, not the source. |
| 3 | **S000094 (the permission contract) is "the tell."** | Codex's steelman: if one coherent allow/ask/deny contract that the orchestrators, leaf skills, AND shell helpers all actually honor can be expressed and honored, the framework is becoming a real system; if not, the rest is polish on an unsafe control plane. It ships *second* (not first) — high-value but contained by the existing PR-stop. |
| 4 | Do NOT reinvent the receipt schema: port `work-copilot`'s tracker-frontmatter `receipts:` block convention inward. | `receipts.qa` (`work-copilot/prompts/qa.prompt.md:222-285`) is a near-exact prototype for S000093; `receipts.scaffold/implement` are the S000095 precedent; the resume state file is already a proto-receipt. S000093 and S000095 share one schema (not two). |
| 5 | New permission-policy file is a `doc-spec.md`-style artifact (prose + a fenced machine-readable block) parsed by a small `scripts/` helper. | Mirrors the pattern the repo already trusts (doc-spec.md). Minimal row schema `{verb, mode ∈ allow\|ask\|deny, scope}`; a verb absent from the policy resolves to deny (design permission before capability). |
| 6 | Do NOT touch P2 (state) or P3 (handoff). | They are already strong and are the hardest-to-retrofit habits; this saga is the affordable P4/P5/P1 tail only. The per-phase receipt chain (S000095) MUST preserve P2/P3's atomic mktemp+mv write + the ancestor-SHA validate-before-skip contract. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| S000093/S000095 receipt home: generalize the existing `.cj-goal-feature/${branch}.state` into the receipt chain (one surface), or add a sibling per-phase receipt file? Leaning generalize-in-place to avoid a second state surface. | Resolved by whichever of S000093/S000095 ships first — it sets the one shared receipt schema; the other story reuses it. |
| Advisory→strict ratchet timing for S000094's `validate.sh` drift check. | Land the check advisory first (portability Check 18 precedent); the follow-up PR that flips it strict is its own small change once the policy is reconciled. |
| S000093 touches the QA + orchestrator hot path (`qa.md` Step 3 + feature `pipeline.md` resume). | Each story is small and PR-gated; the feature `pipeline.md` resume change is a DISTINCT change from the `qa.md` marker — named explicitly so reviewers see both. |
| Any story that adds a `validate.sh` check (S000094) must add the parallel `scripts/test.sh` zzz-test-scaffold integration fixture in the SAME PR — the implement step reliably forgets this. | Pre-flight it in the implement prompt for S000094; verify the fixture is present before /ship. |
| Cost regression: re-running E2E on every same-SHA resume would re-pay the ~5-min budget (`qa.md:539`). | S000093 AC1 explicitly re-runs the expensive E2E subagent ONLY when the receipt is missing/incomplete/stale-SHA; cheap receipt re-validate otherwise. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] A resumed user-story/feature run re-verifies (re-validates the receipt; re-runs E2E on a missing/stale receipt) rather than trusting a date-keyed marker or a phase-skip; an artifacts-only or stale-state work-item cannot read green (S000093 ACs).
- [ ] One declared allow/ask/deny policy exists; the live enforcement points (`allowed-tools`, sensitive-surface AUQ) reference it and an advisory `validate.sh` check flags drift; risky verbs (git push to main, gh pr merge, rm, network) are explicit deny/ask (S000094 ACs).
- [ ] The office-hours inline phase writes a compact phase receipt to `.cj-goal-feature/` via the existing atomic mktemp+mv path; the post-phase steps READ `$RECEIPT_PATH` rather than regenerating from conversation context (S000095 ACs).
- [ ] Each story lands as its own PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review. No regression to P2 / P3.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- **S4 — cross-branch state index + per-phase telemetry + crash checkpointing** — refinements, not gaps. File as TODOS.md rows; build only AFTER S000093/S000094/S000095 land, or it risks formalizing the wrong execution model.
- **P2 (externalize state) and P3 (stateless handoff) changes** — already strong (resume state file, tracker journal, validate-before-skip, leaf-subagent RESULT contract); deliberately untouched.
- **A generic "compact everything" within-phase framework** — S000095 is scoped to the known long inline phases (office-hours first) only; no general compaction machinery.
- **Downstream-consumer / cross-repo scope** — workbench-only (this repo, macOS + Git-Bash).
- **A live re-activation of `cj-handoff-gate.sh`** — S000094 rewires its denylist to DERIVE from the policy so it is correct if ever reactivated; this is forward-looking, NOT a live-enforcement claim.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000053_TRACKER.md](F000053_TRACKER.md)
- Roadmap: [F000053_ROADMAP.md](F000053_ROADMAP.md)
- Source design (office-hours, APPROVED): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-tender-elion-267bd0-design-20260606-204310.md`
- Receipt-schema precedent: `work-copilot/prompts/qa.prompt.md:222-285` (`receipts.qa`)
- Harness principles: `docs/philosophy.md` ("The runtime standard: five harness-engineering principles")
