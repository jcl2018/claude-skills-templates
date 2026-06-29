---
type: design
parent: S000114
title: "Generated docs/tests/ catalog + freshness primitive — Story Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Atomic story design. Full epic context: ../F000069_DESIGN.md and the parent's
     /office-hours design doc (Part 1 / U1). -->

## Problem

`spec/test-spec-custom.md` enumerates ~71 verification units in machine YAML — good
for AI/engine review, useless as a human-browsable "what tests exist and what each
proves." The workflow side already has a two-level human surface (`docs/workflow.md`
index + `docs/workflows/*.md`); the test side has nothing parallel. A hand-authored
catalog would rot (it would be a second hand-maintained copy of registry-derivable
content, fighting the contract's `single-owner` rule). This story builds the test
catalog as a GENERATED, freshness-gated view — the second instance of the proven
README↔generate-readme↔Check-25 primitive.

## Shape of the solution

Add a renderer to the existing test-spec engine that turns the merged registry's
rendered fields into human docs, commit those docs, and gate their freshness in
both `validate.sh` (workbench) and `/CJ_test_audit` Stage 1 (portable, any repo):

```
spec/test-spec.md + spec/test-spec-custom.md (merged registry, source of truth)
            │
            ▼  test-spec.sh --render-docs   (rendered fields only: label, purpose,
            │                                 layer, disposition, trigger; anchor as
            │                                 a code reference)
   docs/tests/<family>.md  +  docs/test-catalog.md   (committed generated surface)
            │
            ├── validate.sh Check 26 ── regenerate→temp→diff→ERROR on mismatch
            └── /CJ_test_audit Stage 1 ── test-spec.sh --render-docs --check
```

`--render-docs --check` is the single freshness primitive: it renders to a temp
dir, diffs vs on-disk, exits non-zero on any mismatch/missing file. Both Check 26
and the audit Stage 1 call it, so the workbench gate and the portable standalone
audit agree by construction.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Render ONLY rendered fields; show the anchor as a code reference (path:line), never a claim | Rendered fields are already work-item-ID-free by the existing rendered-field lint, so the generated human-docs satisfy Check 19 by construction. |
| 2 | One file per unit `family` + a grouped index with counts | Mirrors the workflow surface's two-level shape (index + per-unit); families are the natural human grouping (validate / test / ci / hook / windows-smoke / test-deploy / eval). |
| 3 | `--render-docs --check` is the shared freshness entry point for BOTH Check 26 and audit Stage 1 | One owner of the regenerate→diff logic; the workbench check and the portable audit can't disagree. |
| 4 | Deterministic output (stable sort, fixed headers, single emit order) | The freshness diff must be byte-stable or Check 26 flaps; mirrors generate-readme's determinism. |
| 5 | Add the parallel `scripts/test.sh` integration fixture in THIS story | A new `validate.sh` check ALWAYS needs the parallel test.sh fixture (the recurring implement-subagent blind spot); pinning it as a P0 requirement + a TEST-SPEC row prevents the drop. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Non-determinism in render order makes Check 26 flap | Implement: stable sort on (family, unit-id); fixed header strings; verify a render→render diff is empty in `tests/test-spec-render.test.sh`. |
| The renderer accidentally emits a work-item ID (e.g. from a non-rendered field) | Implement: render ONLY the rendered-field set; `tests/test-spec-render.test.sh` greps the output for `[FSTD][0-9]{6}` and asserts none. |
| Check 26 added without the parallel test.sh fixture (blind spot) | SPEC P0 #3 + TEST-SPEC S-row pin it; QA verifies both edits landed. |
| `/CJ_test_audit` Stage 3 flags `docs/tests/` as an uncontemplated orphan | Implement: Stage 3 ground-truth enumeration recognizes `docs/tests/` as a generated surface; `spec/doc-spec-custom.md` declares it. |

## Definition of done

- [ ] `test-spec.sh --render-docs` and `--render-docs --check` exist and behave per the SPEC acceptance criteria.
- [ ] `docs/tests/<family>.md` + `docs/test-catalog.md` generated, committed, declared in `spec/doc-spec-custom.md` as generated human-docs.
- [ ] `validate.sh` Check 26 + the parallel `scripts/test.sh` fixture both present and green.
- [ ] `spec/test-spec-custom.md` units rows added; Check 24 reverse-sweep resolves the new test(s).
- [ ] `/CJ_test_audit` Stage 1 runs the freshness check; Stage 3 treats `docs/tests/` as generated.
- [ ] `tests/test-spec-render.test.sh` green; full `validate.sh` + `test.sh` green; post-sync audits report 0 findings.

## Not in scope

- Workflows generation (Story 2), forced seeding (Story 3), the consumer gate (Story 4) — separate deferred stories.
- Changing the test-spec registry GRAMMAR — this story reads the existing merged rendered fields; it adds a renderer, not a new registry axis.
- Editing upstream gstack skills.

## Pointers

- Parent feature design: [../F000069_DESIGN.md](../F000069_DESIGN.md)
- Story tracker: [S000114_TRACKER.md](S000114_TRACKER.md)
- Story spec: [S000114_SPEC.md](S000114_SPEC.md)
- Story test-spec: [S000114_TEST-SPEC.md](S000114_TEST-SPEC.md)
- Reference primitive: `scripts/generate-readme.sh` + `scripts/validate.sh` Check 25 (README freshness)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/audit-tightening-design-20260628-200601.md` (Part 1 / U1)
