---
type: design
parent: F000066
title: "test-spec behavior-coverage axis — Feature Design"
version: 1
status: Draft
date: 2026-06-16
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

The two-tier `test-spec` verification contract models only the **plumbing** of
verification: `layers[]` (where/when verification fires), `rules[]` (whether the
test inventory is honest/complete), and the per-repo `units[]` overlay (one row
per verification mechanism — each validate check, test sub-suite, hook, workflow).
None of these represents **what behavior the software must be proven to do.**

The contract is *closed-world over existing tests*: `--check-coverage` can flag an
orphaned or mis-anchored test, but a behavior that *should* have a test and
doesn't is structurally invisible — there is nothing to miss. Concrete pain: a
consumer repo (an options portfolio) has no place to declare or verify "adding a
short put is valid," so the absence of that test never surfaces as a finding. The
workbench has the same blind spot.

## Shape of the solution

Flip part of the contract from closed-world to **open-world**: a repo *declares*
the behaviors the software must prove, and the absence of a covering test becomes
a detectable gap. By making **test level** (`unit | integration | contract |
workflow | property`) first-class on the behavior (the obligation), the contract
stops answering only "are tests wired up?" and starts answering "what must be
true, and is it proven at the right depth of the pyramid?"

Mechanically (Approach A, minimal honest v1): two new overlay-only arrays —
`behaviors:` (the obligations, each with a closed `level` enum) and a normalized
`behavior_coverage:` many-to-many relation linking each behavior to a test-bearing
`units[]` row plus a `source`/`anchor` for semantic evidence. The general seed
gains *prose only* (the axis description + the `level` enum + an explicit
"deterministic checks verify structure, not completeness" caveat); its machine
block is unchanged and `schema_version` stays `1`. `scripts/test-spec.sh` gains
the parser for both blocks, six deterministic conformance checks, two plumbing
items (`--list-behaviors` / `--list-behavior-coverage` + a `--validate` lint), and
the absent/inactive parity path. A new agent-judged `/CJ_test_audit` Stage-2
sub-check verifies behavior *substance* (the load-bearing P5 stage). The whole
change is dogfooded with ~8 behavior rows for test-spec itself.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| behaviors[] + behavior_coverage[] parser, the 6 deterministic checks, seed prose, validate.sh Check 24 wiring, the /CJ_test_audit Stage-2 sub-check, and the ~8 dogfood rows | S000110 | [S000110_behaviors_and_coverage_in_test_spec/S000110_TRACKER.md](S000110_behaviors_and_coverage_in_test_spec/S000110_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Keep `schema_version: 1` everywhere; the two arrays are optional-on-schema-1, overlay-only; the seed's machine block is UNCHANGED (prose-only seed edit) | Bumping the seed version would be meaningless (its machine block doesn't change) and would break the byte-identical-seed test; the parser already tolerates absent optional blocks, so no `SUPPORTED_SCHEMA_VERSIONS` change is needed and the one-fenced-yaml-block invariant is preserved. |
| 2 | `level` lives on the **behavior** (the obligation), NOT on `units[]` | One suite legitimately proves multiple levels, so leveling the mechanism is wrong; leveling the obligation is right (Codex P3, agreed-revised). |
| 3 | The agent-judged `/CJ_test_audit` Stage-2 substance check is **load-bearing**, not optional (P5) | Without it the blind spot merely relocates: a self-attested low-granularity behavior row links to one broad smoke suite, the contract goes green, and the real behavior is still invisible (Codex risk #2). |
| 4 | `behavior_coverage.unit` must reference a **test-bearing** family (`test | test-deploy | eval | windows-smoke`); reject `validate | ci | hook` | A behavior's proof must be an actual test, not a structural lint or a CI plumbing row. |
| 5 | `behavior_coverage.anchor` must locate **semantic evidence** (the behavior named in the test/spec text) via fixed-string `grep -F`, NOT route through the family-shaped `_fwd_match` dispatcher | Otherwise the deterministic check passes on "a test file exists" rather than "this behavior is named in a test"; behavior anchors are arbitrary semantic-evidence prose, not `=== Check N` / runner-path shapes. |
| 6 | Chose Approach A (minimal honest v1); defer Approaches B (pyramid-aware + diff-aware) and C (executable-spec) | A closes the actual gap with proven machinery and respects the portability premise; C imposes a spec-runner convention on every adopter (fights portability); B is the natural fast-follow. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| False confidence from self-attested, low-granularity behavior rows (Codex risk #2) — a broad behavior linked to one broad suite goes green while a specific behavior stays invisible. | Mitigated by the load-bearing `/CJ_test_audit` Stage-2 substance check (P5); verify at QA that Stage-2 flags a vague/over-claimed/mis-leveled row. |
| Migration for already-adopted repos — a repo already carrying `test-spec.md` gets the new general-file prose on its next seed-refresh, but `behaviors:` rows are opt-in. | Lean: opt-in is enough for v1; defer a `--reconcile`-style nudge. Revisit if adoption stalls. |
| `area` taxonomy — free-text vs a per-repo declared enum. | Lean: free-text in v1, PARSED-AND-IGNORED (reporting-only, deferred to Approach B). Revisit when level-distribution reporting lands. |
| Regression of the rules-only consumer path (no `units:` ⇒ "coverage cross-check inactive" today). | A no-`behaviors:` repo must stay equally quiet ("behavior coverage inactive" + exit 0); covered by a TEST-SPEC consumer-parity row. |

## Definition of done

- [ ] `test-spec.sh --check-coverage` FAILS when a declared behavior has no covering row, the anchor doesn't grep live, or it points at a non-test-bearing unit.
- [ ] A behavior pointing at a real, green, semantically-matching test PASSES.
- [ ] A repo with no `behaviors:` reports "behavior coverage inactive" and stays green (consumer parity preserved).
- [ ] `spec/test-spec.md` is byte-identical to `test-spec.sh --seed` (seed-identity test still green).
- [ ] `/CJ_test_audit` Stage-2 flags a vague / over-claimed / mis-leveled behavior row.
- [ ] The ~8 dogfood behavior rows for test-spec itself are green on the live tree.
- [ ] `scripts/validate.sh` and `scripts/test.sh` both green.

## Not in scope

- Per-`area` pyramid expectations + level-distribution reporting — Approach B (deferred fast-follow).
- Diff-aware flagging of behavior-adding changes with no new behavior row (extends `new-code-tested` to behaviors) — Approach B (deferred).
- Executable-spec behaviors (given/when/then spec files that *are* the test) — Approach C (rejected; fights the portability premise).
- A deterministic `source != unit.source` guard — kept minimal; P5 (agent-judged) owns the "is this genuine semantic evidence?" judgment.
- Repo-wide inventory, pyramid quotas, level inference, reverse-discovery of behaviors — all deferred past v1.
- A `--reconcile`-style migration nudge for already-adopted repos — opt-in is enough for v1.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000066_TRACKER.md](F000066_TRACKER.md)
- Roadmap: [F000066_ROADMAP.md](F000066_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-angry-wozniak-0b3ea3-design-20260615-175911.md`
- Extends the test-spec contract last touched by F000063 (tighten doc/test-spec contract) and F000060 (two-tier audit contract).
