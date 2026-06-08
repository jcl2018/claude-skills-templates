---
type: design
parent: F000054
title: "gate-spec.md — one human-readable verification contract for all cj_goals — Feature Design"
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

The workbench verifies a change at four separate layers that grew up
independently, with overlaps and an overloaded vocabulary. A human cannot
currently answer one basic question: **"What stops a broken cj_goal change from
landing, and at which layer?"**

The four layers today:

1. **Local pre-commit hook** — `scripts/setup-hooks.sh` installs a `pre-commit` hook that runs `scripts/validate.sh` (hard-fail, blocks the commit).
2. **GitHub Actions CI** — `validate.yml` (runs `validate.sh` + `test.sh` + shellcheck, gates PRs), `windows.yml` (Git-Bash smoke + deploy tests, gates PRs), `eval-nightly.yml` (behavioral eval, non-gating).
3. **In-orchestrator gates** — inline halts inside each cj_goal pipeline: isolation gate, design-summary gate, QA gate, doc-sync (`/CJ_document-release`) halt, portability gate, ship gate. "The primary position to check if the intention is wired correct."
4. **Regression ratchets** — monotonic guards: `validate.sh` Check 8 (VERSION never regresses), the portability `FINDINGS=0` baseline ratchet (Check 18 / the strict orchestrator gate), Check 14 (USAGE.md freshness).

Three concrete symptoms of the legibility gap:

- **The verification story is scattered across three docs** with no single map. `docs/philosophy.md §4` ("Verification is a continuous gate") states the *why*; `docs/architecture.md` has a section literally titled "The CI gate (`scripts/validate.sh`)" that actually only covers the *doc-spec* checks yet claims the name "CI gate"; `docs/workflow.md` documents individual gate scripts. Plus a dozen CLAUDE.md sections.
- **The word "gate" is overloaded.** It means an inline orchestrator halt (portability gate, isolation gate) *and* it means `validate.sh`-as-a-whole (architecture.md calls validate.sh "the CI gate"). Same word, two referents, no disambiguation.
- **The contract is duplicated per orchestrator, and regression guards are bolted on ad-hoc.** Each cj_goal `pipeline.md` re-describes its own gate sequence in prose, and each recent story (S000093 / S000094 / S000095) added its own bespoke regression-guard block to `scripts/test.sh`. There is no shared contract that says "this is the verification sequence every cj_goal runs," and nothing structurally keeps the four pipelines in sync.

## Shape of the solution

Apply the **doc-spec pattern** to gates. The repo already solved this exact
problem for documentation — `doc-spec.md` is ONE file that is simultaneously the
human-readable map (prose + summary table + ASCII diagram) AND the machine source
of truth (a fenced `yaml` registry parsed by `scripts/doc-spec.sh`). The
structural fix for verification is not a new mechanism; it is the third member of
an established family: **doc-spec → permission-policy → gate-spec.**

One umbrella feature, ONE child user-story (this is delivered as a single
declarative contract, not a multi-story saga). The deliverable: a new root
`gate-spec.md` (human verification map + fenced `yaml` registry of layers +
gates), a new `scripts/gate-spec.sh` reader, and a new advisory `validate.sh`
Check 22 (structurally a clone of Check 21, the permission-policy drift check).
The four orchestrators and the docs reference the one contract. The story
PR-stops for human review — it adds a `validate.sh` check and edits the four
`pipeline.md` files + `doc-spec.md`, exactly the surfaces the handoff-gate
denylist flags as unsafe-to-auto-deploy (correct here, the PR is the architecture
gate). New checks land advisory-first (the workbench's established pattern, e.g.
portability Check 18, permission-policy Check 21).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| gate-spec.md contract — one declarative verification contract (human map + yaml registry) + a reader + an advisory cross-orchestrator conformance check, mirroring doc-spec | S000096 | [S000096_gate_spec_contract/S000096_TRACKER.md](S000096_gate_spec_contract/S000096_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: full doc-spec mirror — `gate-spec.md` + `scripts/gate-spec.sh` + a `validate.sh` conformance check. | Over Approach B (registry inside `cj-goal-common.sh` — bash-embedded data reads worse as "the single map" + breaks the doc-spec symmetry) and Approach C (gate-spec.md + grep conformance, no reader — orchestrators can't programmatically consume `--list-for`; a weaker mirror). A is the truest mirror of the proven in-repo idiom (maximum legibility) and still ships in one PR. |
| 2 | Declarative contract, NOT a central executor (Premise 1). | Some gates are interactive AskUserQuestion prompts (design-summary gate) or subagent dispatches (QA) that *cannot* run from one shared bash entry point. "Shared gate contract" = a single DECLARED ordered sequence all cj_goals reference + a conformance check, NOT a `--run-all-gates` function. Gate implementations stay where they are. |
| 3 | `markers` is a per-mode map, with an `{enforced_by: subagent\|auq}` escape hatch — NOT a flat `applies_to` + single `halt_marker` string. | The real halt markers are irregular across modes: the isolation gate has THREE different markers for one concept (`[feature-not-isolated]` / `[investigate-not-isolated]` for defect / `[task-not-isolated]`), and todo has no isolation marker. Only `[portability-red]` + `[doc-sync-red]` are universal. The per-mode map encodes "in sync" honestly = "every declared per-mode marker is present where declared" — a real, enforceable invariant, just not a single global string. The escape hatch keeps the baseline honestly clean (a gate a mode runs WITHOUT a literal marker, e.g. todo's subagent QA). |
| 4 | Advisory in v1, mirroring Check 21 (NOT hard-ERROR from day one). | The immediately-preceding sibling check (permission-policy / Check 21, same F000053 saga) shipped advisory; consistency with that sibling is itself a legibility win. Because the registry is authored honestly, the advisory check is GREEN on the clean baseline today — so flipping it strict later is a one-line follow-up TODO (a free ratchet), not a reconciliation project. The review correctly flagged the earlier "hard ERROR from day one" draft as inconsistent + risky for a hand-authored registry's first cut. |
| 5 | `--seed` and `--list-for <mode>` reader subcommands are DEFERRED (no v1 consumer). | The review flagged them as speculative API. v1 ships only `--validate` / `--list-layers` / `--list-gates`; the conformance check computes the per-mode subset internally and does not need `--list-for`. Add either subcommand when an actual caller appears. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Exact gate enumeration — the full `gates[]` list is derived from the four live pipelines at implement time. | Low risk — the marker universe is now known (per-mode `markers` map + `enforced_by` escape + `order`). Implement fills the rows by grepping each mode's actual markers. |
| todo's file resolution — does the conformance rule grep `pipeline.md` or `SKILL.md`? RESOLVED. | `CJ_goal_todo_fix` keeps gate logic in BOTH `SKILL.md` and `pipeline.md` and markers are duplicated across both in every mode, so the rule is "marker present in EITHER file for that mode" (and the dir is `CJ_goal_todo_fix`, not `CJ_goal_todo`). |
| Known blind spot: any story adding a `validate.sh` check MUST add the parallel `scripts/test.sh` zzz-test-scaffold integration fixture in the SAME PR — the implement step reliably forgets this (F000032 / F000034 / F000035). | Pre-flight it in the implement prompt; verify the fixture is present before /ship. Check 22 greps `skills/CJ_goal_*/` and `zzz-test-scaffold` is not a `CJ_goal_*` skill, so it is naturally skipped — but verify, don't assume. |
| Advisory→strict ratchet timing for Check 22. | Ships advisory (mirrors Check 21); the flip-to-strict is a tracked follow-up TODO, a one-line disposition change once it has run clean across a few real cj_goal builds. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `gate-spec.md` exists at root: a human can read it top-to-bottom and answer "what stops a broken cj_goal change from landing, and at which layer?" without opening any script (S000096 ACs).
- [ ] `scripts/gate-spec.sh --validate` exits 0 on the committed registry; `--list-gates` / `--list-layers` emit the right sets (S000096 ACs).
- [ ] The new advisory `validate.sh` Check 22 is GREEN on the clean tree and REPORTS a finding when a declared literal marker is removed from the registry or from both of its mode's files; advisory in v1 (a finding prints but does not exit non-zero — exactly like Check 21) (S000096 ACs).
- [ ] The word "gate" is disambiguated in the docs (CI checks vs pipeline gates vs ratchets); architecture.md no longer mislabels validate.sh as "the CI gate" without qualification (S000096 ACs).
- [ ] The story lands as one PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review; doc-sync + portability stay green and the PR carries the registered-doc + portability verdicts.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- **Re-plumbing gate *execution* into a shared runner** (a `--run-all-gates` function) — explicitly deferred to a future multi-PR epic. Gate implementations stay exactly where they are; this feature only declares + cross-checks the sequence.
- **`--seed` and `--list-for <mode>` reader subcommands** — no v1 consumer; documented as the natural next subcommands, added when a caller appears.
- **Flipping Check 22 from advisory to strict** — its own follow-up TODO once the registry has run clean across a few real cj_goal builds (advisory→strict ratchet, Check 21 precedent).
- **A `skills-catalog.json` entry for `gate-spec.sh`** — `gate-spec.sh` is a root script like `doc-spec.sh`, which is not a catalog skill (confirm at implement; likely no entry needed).
- **Downstream-consumer / cross-repo scope** — workbench-only (this repo, macOS + POSIX shell).

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000054_TRACKER.md](F000054_TRACKER.md)
- Roadmap: [F000054_ROADMAP.md](F000054_ROADMAP.md)
- Source design (office-hours, APPROVED): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-priceless-grothendieck-367489-design-20260607-173334.md`
- Sibling-precedent (the closest structural template): `work-items/features/cj_goal/F000053_harness_principle_hardening/S000094_permission_policy/` (permission-policy.md + scripts/permission-policy.sh + validate.sh Check 21)
- The pattern this mirrors: `doc-spec.md` + `scripts/doc-spec.sh` + `validate.sh` Checks 15/16/17/19/20
