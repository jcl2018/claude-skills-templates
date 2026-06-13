---
type: design
parent: F000062
title: "Required reference.md — a general-tier curated external-references doc — Feature Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. -->

## Problem

The workbench has no home for the external references that shaped it — the
Anthropic/Claude Code docs, gstack, Keep-a-Changelog, shellcheck, the GitHub
CLI, and similar. A contributor (human or agent) has to rediscover the canonical
sources each time. The operator wants a **required** `docs/reference.md` that
collects useful repos / links / blogs / articles for building this repo,
governed by the same doc contract as the rest.

The operator's word "required" maps to a specific tier in this repo's contract
vocabulary: the **general** (`section: common`) tier — the seed every adopting
repo carries, stub-scaffolded where missing and audited like any other contract
doc. This is a deliberate consumer-ripple choice over a quieter custom-overlay
row: the rule then means the same thing in every adopting repo.

## Shape of the solution

A single feature with one child user-story (single-story scope). The child
carries all six mechanical pieces: the curated `docs/reference.md` file itself;
the registry row added byte-identically to all three seed copies; the
"Human docs" prose-table row in all three; the `eleven`→`twelve` count sweep
(3 seed copies + `spec/doc-spec-custom.md` + the CLAUDE.md parenthetical); the
`docs/doc-general.md` view regeneration; and the contract+test verification
(including the growth-safe config-test-8b confirmation). This reuses the exact
row + count + view mechanics F000058 used when it flipped six docs to
`section: common`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Curated reference.md + 3-way seed row/table/count + view regen + config-test-8b verify + QA dogfood | S000104 | [S000104_curated_reference_doc_and_seed_row/S000104_TRACKER.md](S000104_curated_reference_doc_and_seed_row/S000104_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | General-seed tier, not a custom-overlay row (D15.1) | "Required everywhere" — pay the consumer-ripple cost so the rule means the same thing in every adopting repo; a custom-overlay row would be quieter but repo-local. |
| 2 | Curated v1, not an empty stub (D15.2) | The doc ships with real grouped entries grounded only in sources the repo demonstrably references (grep-verified); the operator prunes/extends at the PR. |
| 3 | No `front_table` | reference.md is a categorized link shelf, not a principle/workflow index — only philosophy.md + workflow.md require a leading summary table, so Check 20 deliberately does not apply. |
| 4 | The `requirement` string asserts SHAPE + PURPOSE, never specific links | Links churn; the doc must not self-stale when one entry is added or removed — the audit judges the requirement, not the link list. |
| 5 | `validate.sh` is NOT edited | Checks 15/15a/17/19/20 read the merged registry, so a newly-declared doc is picked up automatically; an extra validate.sh edit would be redundant and out of scope. |
| 6 | 3-way seed byte-identity is a hard invariant | The registry row + prose-table row + count edit must land identically in `scripts/doc-spec.sh`'s heredoc, `templates/doc-spec-common.md`, and `spec/doc-spec.md`; verified post-edit via `--seed | cmp -` against both copies. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| A seed copy drifts (row/table/count lands in only 2 of 3) | The 3-way `cmp` (S000104 TEST-SPEC smoke row) catches it before commit; Check 16 also fails a malformed registry. |
| A `docs/reference.md` entry is invented / not actually referenced by the repo | Content-honesty rule: every entry grep-grounded in `CLAUDE.md` / `scripts/` / `CHANGELOG.md` / `docs/` / `.github/`; Stage-3 `/CJ_doc_audit` cross-walk during QA. |
| A work-item ID slips into the human-doc | Check 19 (HARD, no-work-item-ID lint on human-docs) fails the commit; TEST-SPEC smoke row asserts a clean grep. |
| Config test 8b breaks on count 12 | It is inclusion-based / growth-safe (asserts the seed INCLUDES core docs, not an exact count) — verify it tolerates 12 and add a `docs/reference.md` include-assertion. |
| Link liveness (HTTP-resolvability) | Out of the contract's deterministic scope; Stage 2/3 agent judgment covers staleness. |

## Definition of done

- [ ] `docs/reference.md` exists, declared `section: common` / `audit_class: human-doc` / no `front_table`, curated with real grouped entries, no work-item IDs.
- [ ] The registry row + Human-docs prose-table row + `eleven`→`twelve` count edit land byte-identically in all 3 seed copies.
- [ ] `eleven`→`twelve` swept in `spec/doc-spec-custom.md` + the CLAUDE.md parenthetical (~L539) gains `docs/reference.md`.
- [ ] 3-way seed byte-identity holds (`--seed | cmp -` clean against both copies).
- [ ] `docs/doc-general.md` regenerated to list 12 docs; Check 23 green.
- [ ] `scripts/validate.sh` PASS 0/0 (no validate.sh edit); `scripts/test.sh` PASS (config test 8b tolerates 12 + lists reference.md).
- [ ] QA's `/CJ_doc_audit` reports reference.md `satisfies` (Stage 2) + `no-drift` (Stage 3).

## Not in scope

- A `reference-custom.md` overlay — not requested; the general doc + the existing custom-overlay mechanism already let a repo extend.
- Auto-validation that links resolve (HTTP-checking) — out of the contract's deterministic scope; agent-judged staleness covers it.
- Any `validate.sh` edit — the registry-reading checks cover the new doc automatically.
- `scripts/drain-one-todo.sh` / orchestrator-layer changes — this is a pure doc-contract addition.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. -->

- Parent tracker: [F000062_TRACKER.md](F000062_TRACKER.md)
- Roadmap: [F000062_ROADMAP.md](F000062_ROADMAP.md)
- Child story: [S000104_curated_reference_doc_and_seed_row/S000104_TRACKER.md](S000104_curated_reference_doc_and_seed_row/S000104_TRACKER.md)
- Design source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-unruffled-kalam-e25974-design-20260612-reference-doc.md`
- Precedent: F000058 (general-docs-required row+count+view mechanics); F000060 (two-tier seed); F000061 (the three-stage audit that vets this doc).
