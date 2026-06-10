---
type: design
parent: F000059
title: "test-pipeline — a generated, check-level human view of the verification surface — Feature Design"
version: 1
status: Draft
date: 2026-06-10
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-story — do not duplicate it
     here. Distilled from the APPROVED /office-hours design doc
     chjiang-claude-hardcore-napier-1efc3f-design-20260610-071551.md. -->

## Problem

A human cannot currently survey this repo's verification surface without
reading source: scripts/validate.sh is 1069 lines (~24 live numbered checks
across two ID grammars, plus 2 warning checks), scripts/test.sh is 2773 lines
(~29 distinct test units: 13 registered tests/*.test.sh sub-suites, 1 stray
test file on disk that is never wired in, and ~15 inline families), and the
rest of the surface is scattered across scripts/test-deploy.sh,
scripts/eval.sh, scripts/windows-smoke.sh, three GitHub Actions workflows, two
git hooks, and three regression ratchets. spec/gate-spec.md answers "what
stops a broken change, at which LAYER" — by design it does NOT enumerate
individual rules. There is no doc a human can read to learn "which validate
rules exist, line by line," what each test family covers (including
doc-consistency checks), which CI gates fire when, and which regressions are
ratcheted.

The fix: docs/test-pipeline.md — a REQUIRED general-tier doc giving the
check-level human view, following the repo's two-layer structure (spec/
machine registry → docs/ generated human view), the same shape as
spec/doc-spec.md → docs/doc-general.md.

## Shape of the solution

A 4th spec-registry member carries the machine truth and everything else is
derived or enforced from it: spec/test-pipeline.md (prose + ONE fenced yaml
registry, one row per verification unit, ~65 rows at land), parsed by
scripts/test-pipeline.sh (gate-spec.sh idiom: --validate / --list-units /
--render with a rendered-field work-item-ID lint), rendered to
docs/test-pipeline.md as a third generate-doc-views.sh output, kept honest by
two HARD validate.sh changes (Check 23 extended to diff the third view; NEW
Check 24 coverage cross-check: forward anchor-grep + reverse live-surface
sweep + floor-assert ≥ 20 tokens), registered in the doc-spec contract (view:
common/human-doc/front_table-required; registry: custom/operational) with the
portable Common seed grown 10 → 11 in lockstep copies, and tested by
tests/test-pipeline-spec.test.sh (registered in test.sh — the exact
silent-skip trap the coverage check mechanizes). One atomic child story
carries the whole build, including the Step-0 triage of the live silent-skip
instance (tests/cj-goal-feature-smoke.test.sh) so the Check 24 baseline lands
clean.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Full build: stray-test triage + registry + parser + generated view + Check 23 extension + hard Check 24 + doc-spec/seed lockstep + tests + secondary-doc sweep | S000101 | [S000101_registry_parser_view_and_checks/S000101_TRACKER.md](S000101_registry_parser_view_and_checks/S000101_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Complement, don't duplicate gate-spec: the new doc owns CHECK-level enumeration and links to spec/gate-spec.md for the layer model | One owner per concern (Premise 1); pipeline-gate units are deliberately NOT rows — the view carries a single pointer line to gate-spec's gates[] |
| 2 | General tier: the portable seed grows 10 → 11 and every adopting repo becomes required to carry docs/test-pipeline.md | "How is this repo tested" is a universal doc kind; the line-by-line content is per-repo (Premise 2) |
| 3 | Approach C (generated view from a 4th spec registry) over A (hand-written + advisory audit) and B (hand-written + token-presence ratchet) | A hand-maintained line-by-line list WILL drift (Premise 3); the repo previously judged judgment-only doc freshness unreliable (the USAGE-freshness ratchet exists for that reason); B proves mention, not sync — operator chose the full by-construction architecture at the alternatives gate |
| 4 | Check 24 ships HARD from day one (with SKIP-when-registry-absent) | The advisory-soak convention covered checks inheriting baselines they didn't control; here the same PR authors the full registry, so the baseline is clean by construction and any finding is new by definition — the same rationale that made the generated-views check hard on day one |
| 5 | `disposition` (hard-fail \| advisory) and `skips_when_absent` are two orthogonal axes, never conflated; `ratchet` is a flag, never a layer value | The adversarial review caught the original enum conflating failure severity with skip behavior |
| 6 | Work-item-ID-free binds EVERY rendered registry field (label AND purpose); literal ID-bearing banner strings live in the non-rendered `anchor` | docs/test-pipeline.md is a human-doc under hard Check 19; test.sh's natural banners are saturated with work-item IDs and must be paraphrased into ID-free labels |
| 7 | For tests/*.test.sh rows, `source` MUST be scripts/test.sh and `anchor` MUST be the literal runner path | The forward check then proves the file is actually WIRED into the suite — this is the mechanism that closes the silent-skip gap (live instance: cj-goal-feature-smoke) |
| 8 | The SEED requirement string is mechanism-neutral; only the WORKBENCH registry entry names the generator + Check 23 | A hand-maintained consumer copy must fully satisfy the portable contract (matches the seed's precedent for the generated views) |
| 9 | Naming: spec/test-pipeline.md + scripts/test-pipeline.sh + docs/test-pipeline.md; deliberately NOT "test-spec" | Name-pairing across the two layers; avoids collision with the per-work-item TEST-SPEC.md artifact that already has a distinct meaning in this repo |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| test.sh family granularity: the ~15 inline family rows fossilize an editorial segmentation; renames inside test.sh that don't move the anchor strings are invisible to the coverage check | Accepted at design time — anchors are chosen to be the most stable literal strings available (section banners + runner paths); revisit if a rename slips through |
| Consumer-repo rendering: adopting repos get docs/test-pipeline.md as a required stub unless they also adopt the registry+parser | Mechanism-neutral seed requirement string means a hand-maintained consumer copy fully satisfies the contract; verified during implementation (skip-posture tests) |
| cj-goal-feature-smoke triage outcome: register vs retire | Decided at implementation (S000101 Step 0) after reading the file against the landed feature-verb behavior; both outcomes keep the Check 24 baseline clean |
| Semantic drift: a check's behavior changes under a stable banner while its one-line `purpose` rots — NOT mechanized | Stays with the advisory registered-doc requirements audit on every cj_goal run (accepted residual risk) |

## Definition of done

- [ ] `./scripts/validate.sh` and `./scripts/test.sh` green, including: extended Check 23 covering the third view; new Check 24 HARD with a clean baseline (the stray-test triage resolved); config-test 13 seed byte-identity passing with the grown seed.
- [ ] docs/test-pipeline.md is fully generated, idempotent under re-render, opens with the summary table, contains ZERO work-item IDs, and enumerates at land time: all 25 live numbered validate.sh check IDs (both namespaces, including the new Check 24 itself; Check 15 as one row) + 2 warning checks, every registered test sub-suite + the 15 inline families, the 3 standalone suites, the 3 CI workflows, the 2 git hooks, and the 3 ratchets — each with disposition + trigger.
- [ ] Drift drills pass (in the new test file, temp-dir isolated): (a) fake `=== Check 99` banner → reverse flags it; (b) broken anchor in a temp registry copy → forward flags it; (c) hand-edited temp copy of the generated view → Check 23-extension diff fails; (d) removed runner block in a temp test.sh copy → forward flags the orphaned test row (the silent-skip catch).
- [ ] The doc-spec registry declares both new docs; doc views regenerate; the Common seed carries eleven general docs in lockstep copies.
- [ ] A first-time reader can answer "what protects this repo, where, and when" from docs/test-pipeline.md's summary table alone in under a minute.

## Not in scope

- Semantic meaning-sync of `purpose` one-liners — we buy structural sync, not meaning sync; semantic accuracy stays with the existing advisory registered-doc audit (same posture as every other registered doc).
- Enumerating pipeline-gate units as registry rows — spec/gate-spec.md stays the layer-model and gate-sequence owner; the view links, never re-explains.
- Reverse-sweep coverage of NEW standalone suite scripts (the next windows-smoke.sh) or new inline test.sh families outside the banner grammar — documented, accepted boundary; those are forward-anchor-only.
- Any new skill — no decision-tree or workflow.md orchestrator edits; this is scripts + spec + docs + checks only.
- Resurrecting retired Check 12 — naive extraction must not re-introduce it.

## Pointers

- Parent tracker: [F000059_TRACKER.md](F000059_TRACKER.md)
- Roadmap: [F000059_ROADMAP.md](F000059_ROADMAP.md)
- Child story: [S000101_registry_parser_view_and_checks/S000101_TRACKER.md](S000101_registry_parser_view_and_checks/S000101_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-hardcore-napier-1efc3f-design-20260610-071551.md` (Status: APPROVED; carries the full Registry inventory appendix — the scaffold input the registry is authored from)
- Sibling spec-registry members: [spec/doc-spec.md](../../../../spec/doc-spec.md), [spec/gate-spec.md](../../../../spec/gate-spec.md), [spec/permission-policy.md](../../../../spec/permission-policy.md)
