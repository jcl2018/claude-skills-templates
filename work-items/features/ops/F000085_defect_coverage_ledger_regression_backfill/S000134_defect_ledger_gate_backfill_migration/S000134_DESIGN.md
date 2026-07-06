---
type: design
parent: S000134
title: "Defect-coverage ledger + regression migration — Story Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — this DESIGN is a brief per-section distillation; the full
     cross-story design lives in the parent F000085_DESIGN.md and the source
     design doc it points at. -->

## Problem

38 defect dirs under `work-items/defects/**` have ZERO declared `regression`
rows and no machine-checked defect↔proof linkage — proof that a past defect
stays fixed is scattered across dedicated test files, inline `scripts/test.sh`
D-blocks, and shared suites, and an inventory agent demonstrably hallucinated
citations. See parent [F000085_DESIGN.md](../F000085_DESIGN.md) `## Problem`.

## Shape of the solution

One story, six ledger-first commits: Stage 1 (commits 1–3) ships the
`defect_coverage:` overlay axis + parser, the `--check-defect-coverage` engine
check, HARD `validate.sh` Check 32 + hermetic negative test, and the verified
38-row backfill; Stage 2 (commits 4–6) ships the reverse-sweep token-grammar
fix + doc-sync orphan resolution, the 4-file pure-drill migration to
`tests/regression/CI-push/`, and the regression `categories:` rows + front-door
docs + catalog regen. Full component detail: parent `## Shape of the solution`.

## Big decisions

Inherited from the parent's `## Big decisions` table (F000085_DESIGN.md) —
notably: overlay-only linkage home; full-dir-path keys; three closed
dispositions; deterministic-only engine-enforced; token-grammar (not glob
surgery) sweep change; intermediate-state anchor→re-anchor→flip rule. See
[../F000085_DESIGN.md](../F000085_DESIGN.md).

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Check 24 machinery regression from the token-grammar change | Existing negative tests + full `scripts/test.sh` before push; ledger commits precede migration commits (descope point after commit 3) |
| VERIFY-flagged backfill rows shift covered→waived at verification | Verify-before-declare at commit 3; failures default to `waived: "gap — …"` + TODOS row |
| A migration candidate proves shared behavior and must stay put | Re-verify all 4 candidates at commit 5 before `git mv` |
| D000018 shape-guard vs waiver | Implementer decides by cost at commit 3 (≤30-line cap, no new fixture) |

## Definition of done

The story's eight acceptance criteria (AC-1…AC-8 in
[S000134_TRACKER.md](S000134_TRACKER.md)) — equivalently the parent's
`## Definition of done`: 38/38 dispositioned with 0 findings + vacuous
consumer SKIP, Check 32 live + negative-tested, ≥4 deterministic+free
regression rows runnable green by `/CJ_test_run --category regression`,
Check 24 + structure checks (a–f) green, full suite + shellcheck green.

## Not in scope

See parent `## Not in scope`: no inline D-block extraction, no shared-suite
moves, no waived-gap drill authoring beyond the ≤30-line/cap-3 exception, no
agentic purge / portability un-enrollment, no general-seed edit.

## Pointers

- Parent feature design: [../F000085_DESIGN.md](../F000085_DESIGN.md)
- Parent tracker: [../F000085_TRACKER.md](../F000085_TRACKER.md)
- Roadmap: [../F000085_ROADMAP.md](../F000085_ROADMAP.md)
- Story spec: [S000134_SPEC.md](S000134_SPEC.md)
- Story test spec: [S000134_TEST-SPEC.md](S000134_TEST-SPEC.md)
- Source design doc (APPROVED): `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-affectionate-villani-b5b6f4-design-20260706-014929.md`
