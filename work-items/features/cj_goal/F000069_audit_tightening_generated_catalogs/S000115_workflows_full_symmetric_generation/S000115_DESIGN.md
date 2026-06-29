---
type: design
parent: S000115
title: "Workflows full symmetric generation — Story Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Atomic story design. Full epic context: ../F000069_DESIGN.md and the parent's
     /office-hours design doc (Part 2). Story-2 design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/workflows-gen-design-20260628-225608.md -->

## Problem

`docs/workflows/*.md` (6 files) + the `docs/workflow.md` index are hand-authored.
The 4 `CJ_goal_*` orchestrator docs carry an ASCII chart + a 4-bullet **Touches**
block; the Touches blocks enumerate the skills/steps/scripts/docs a workflow
touches and drift on every workflow change (hand-edited, easy to forget). The
hand-structure is policed by `validate.sh` Check 15b (each orchestrator doc has a
chart + 4 anchored Touches bullets) + Check 15c (the index links each), but those
checks only assert *shape*, not *truth/freshness*. Story 1 built the
generate→freshness→audit primitive for the test catalog; Story 2 applies the same
model to the workflow docs so they cannot rot.

## Shape of the solution

A new `spec/workflow-spec.md` registry as the single source of truth for the
workflow docs, a `scripts/workflow-spec.sh` engine that renders ALL 6
`docs/workflows/*.md` + the `docs/workflow.md` index, a `validate.sh` Check 27
freshness gate (regenerate→diff, the README/Check 25 / test-catalog/Check 26
pattern), and `/CJ_doc_audit` Stage-1 freshness enforcement so it holds
standalone in any repo. Checks 15b/15c are retired, their intent folded into the
engine's `--validate` (registry-completeness = the no-vanish guarantee) + Check 27.

```
spec/workflow-spec.md  (single source of truth — 2 entry shapes)
        │
        ▼  workflow-spec.sh --render-docs   (orchestrator: chart + 4 Touches axes
        │                                     + "In words"; roster: verbatim body;
        │                                     header: index preamble)
   docs/workflow.md (index)  +  docs/workflows/<name>.md (×6)   (committed generated surface)
        │
        ├── validate.sh Check 27 ── regenerate→temp→diff→ERROR on mismatch (15b/15c RETIRED)
        └── /CJ_doc_audit Stage 1 ── workflow-spec.sh --render-docs --check
```

The registry carries TWO entry shapes: **orchestrator** (the 4 `CJ_goal_*`) is
structured (`kind`, status, category, source, invoke_when, a verbatim fenced
`chart`, the four Touches axes skills/steps/scripts/docs, and an "In words"
summary), **roster** (the 2 prose docs) is free-form (`kind: roster` + a verbatim
`body` block). A registry header block holds the `docs/workflow.md` index prose
preamble so generation reproduces it. `--render-docs --check` is the single
freshness primitive both Check 27 AND the audit Stage 1 call, so the workbench
gate and the portable standalone audit agree by construction.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | All 6 docs + index, truly symmetric (two entry shapes in one registry) | The operator chose full symmetry: generation owns the ENTIRE workflow surface (orchestrator pages AND the two prose rosters AND the index), not just the orchestrator docs — so nothing in the surface can rot out of band. |
| 2 | Normalized template, one-time reviewed reformat (NOT a strict byte round-trip) | Charts + roster bodies + the index preamble are stored + emitted verbatim, but structural bits (headers, Touches ordering, whitespace) may reformat; migrating the 6 docs + regenerating produces a ONE-TIME diff reviewed in this PR. |
| 3 | Retire Checks 15b/15c; fold into `--validate` registry-completeness + Check 27 | 15b/15c only assert SHAPE; the generated model makes the docs un-rottable, and `--validate` completeness (every `CJ_goal_*` has an entry) is a STRONGER no-vanish guarantee than 15c's index-link grep. |
| 4 | One `--render-docs --check` entry point shared by Check 27 + audit Stage 1 | One owner of the regenerate→diff logic; the workbench gate and the portable audit can't disagree (same shape as Story 1's Check 26). |
| 5 | Store the index prose preamble as a registry header block | The index file has a prose intro above the table; the generator must own it so regeneration doesn't drop it. |
| 6 | Add the parallel `scripts/test.sh` Check-27 integration fixture in THIS story | A new `validate.sh` check ALWAYS needs the parallel test.sh fixture (the recurring implement-subagent blind spot F000032/34/35); pin it as a P0 requirement + a TEST-SPEC row. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| One-time reformat of 6 docs diffs against the hand-authored files | Implement + PR review: the diff is expected (not a regression); charts + roster prose + index preamble reproduced VERBATIM, only structural whitespace/ordering may shift — verified by reviewing the regeneration diff in the PR. |
| Retiring 15b/15c regresses the no-vanish guarantee | Implement: the new `--validate` registry-completeness check is the replacement; the hermetic test includes a remove-an-entry drill proving `--validate` fails closed. |
| Engine size — a new bash engine + a 6-doc migration is a large single implement | Implement: the SPEC pins the concrete registry format, the normalized template, and the field set per kind so the implement has no ambiguity. |
| The index prose preamble gets dropped on regeneration | Implement: store it as a registry header block; the hermetic test asserts the rendered index contains the preamble; Check 27 diff catches a dropped preamble. |
| ASCII-chart / roster-body byte fidelity | Implement: store charts + bodies in verbatim fenced registry blocks; the regeneration diff (reviewed in PR) confirms verbatim reproduction; only structural whitespace/ordering may shift. |
| The generated docs leak a work-item ID (Check 19) | Implement: the rendered fields + verbatim blocks must stay ID-free; the hermetic test greps the rendered output for `[FSTD][0-9]{6}` and asserts none; Check 19 stays green. |

## Definition of done

- [ ] `spec/workflow-spec.md` exists (header + 4 orchestrator + 2 roster sections); the 6 doc bodies + index intro migrated in.
- [ ] `scripts/workflow-spec.sh` has `--validate` (incl. registry-completeness), `--list-workflows`, `--render-docs`, `--render-docs --check`, `--classify`, `--seed` and behaves per the SPEC acceptance criteria.
- [ ] All 6 `docs/workflows/*.md` + `docs/workflow.md` regenerated from the registry; charts/rosters/preamble verbatim; Check 19 green (ID-free).
- [ ] `validate.sh` Check 27 (freshness) + the parallel `scripts/test.sh` fixture both present and green; Checks 15b/15c retired with a pointer comment.
- [ ] `spec/doc-spec-custom.md` declares `spec/workflow-spec.md`; `spec/test-spec-custom.md` units rows added; Check 24 reverse-sweep resolves them.
- [ ] `/CJ_doc_audit` Stage 1 runs the workflow freshness check; Stage 3 treats `docs/workflow.md` + `docs/workflows/` as generated.
- [ ] `tests/workflow-spec-render.test.sh` green (determinism, ID-free, `--check` pass/fail-on-edit/fail-on-missing, remove-an-entry `--validate` drill); full `validate.sh` + `test.sh` green; post-sync audits report 0 findings.

## Not in scope

- The test catalog generation (Story 1 — already shipped as S000114), forced seeding (Story 3), the consumer gate (Story 4) — separate stories.
- Changing the CONTENT of any workflow doc beyond the one-time normalized reformat — this story migrates the existing bodies into a registry + regenerates; it is not a rewrite of the workflow documentation.
- Editing upstream gstack skills.
- A strict byte round-trip of the existing 6 docs — the operator explicitly chose a normalized one-time reformat.

## Pointers

- Parent feature design: [../F000069_DESIGN.md](../F000069_DESIGN.md)
- Story tracker: [S000115_TRACKER.md](S000115_TRACKER.md)
- Story spec: [S000115_SPEC.md](S000115_SPEC.md)
- Story test-spec: [S000115_TEST-SPEC.md](S000115_TEST-SPEC.md)
- Sibling story (1st workbench instance of the primitive): [../S000114_gen_tests_catalog_freshness/S000114_SPEC.md](../S000114_gen_tests_catalog_freshness/S000114_SPEC.md)
- Reference primitives: `scripts/generate-readme.sh` + `scripts/validate.sh` Check 25 (README freshness); `scripts/test-spec.sh --render-docs` + Check 26 (test-catalog freshness)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/workflows-gen-design-20260628-225608.md` (Part 2)
