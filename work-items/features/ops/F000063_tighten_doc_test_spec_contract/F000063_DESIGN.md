---
type: design
parent: F000063
title: "Tighten the doc-spec & test-spec contract format (table-as-source + gate-spec merge) — Feature Design"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. Source: /office-hours design doc
     chjiang-claude-upbeat-williams-043b2a-design-20260612-194619.md. -->

## Problem

The spec-contract files (`spec/doc-spec.md`, `spec/test-spec.md`) are portable
seeds that `/CJ_doc_audit` and `/CJ_test_audit` drop into arbitrary repos via
`--seed`. Today they are heavy: `doc-spec.md` is 196 lines of prose wrapped
around a verbose fenced-YAML registry, plus it spawns two generated views
(`docs/doc-general.md`, `docs/doc-custom.md`) via `scripts/generate-doc-views.sh`
— three representations of one list. `test-spec.md` (75 lines) states five
abstract rules the operator finds too general; they do not answer the practical
question "what kinds of tests do we need, what do they do, when do they
trigger?". Meanwhile `spec/gate-spec.md` (252 lines) answers exactly that
question (a four-layer map: local-hook / ci / pipeline-gate / ratchet + per-mode
pipeline-gate halts) but lives as a separate contract.

The goal: make the spec files lightweight, table-shaped, and versatile as seeds,
and consolidate the test/gate verification story into one place.

## Shape of the solution

One feature, two internal phases inside one PR (Approach B — internally
sequenced). Phase 1 makes `doc-spec.md` a 3-column markdown table that IS the
source of truth (deleting the YAML block + the two generated views + their
generator + the `--render` surface). Phase 2 does the full gate-spec →
test-spec merge: gate-spec's `layers[]` fold into the general `test-spec.md`, its
per-mode pipeline-gate `gates[]` fold into `test-spec-custom.md` as a new
top-level `gates:` array, `gate-spec.sh` folds into `test-spec.sh`, and
`validate.sh` Check 22 merges into Check 24 (keeping its marker-drift portion
advisory). All four cj_goal pipelines re-point their canonical-gate-sequence
reference to `test-spec.md`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| doc-spec table-ification (Phase 1) + test-spec/gate-spec full merge (Phase 2) | S000105 | [S000105_doc_test_spec_table_and_gate_merge/S000105_TRACKER.md](S000105_doc_test_spec_table_and_gate_merge/S000105_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Consolidation scope: FULL MERGE, retire gate-spec (D1) | The unified "verification contract" framing is worth more than test-vs-process-gate purity. Reverses the recent deliberate F000060 split — operator decision. The `test-spec` name is KEPT (renaming would roughly double blast radius); broadened meaning stated in prose. |
| 2 | doc-spec format: TABLE-AS-SOURCE, 3 columns `Doc Purpose Requirement` (D2) | The spec file stops being prose + YAML registry + a generated view of the registry (three copies of one list) and becomes one table a human and the parser both read — no second copy to drift. |
| 3 | Drop `section`, `audit_class`, `front_table` from the table (D3) | The general/custom *file* already declares the tier (section dropped). `audit_class` is re-derived into the parser TSV from path convention (under `docs/` or root `README.md` ⇒ human-doc) so Check 19 survives unchanged. `front_table` dropped + Check 20 retired (most cosmetic / workbench-specific lint, no clean 3-column home). |
| 4 | ONE PR, internally sequenced (D4 / Approach B) | Verify doc-spec green first, then the test-spec/gate-spec merge green, in the same work-item/PR. De-risks the table-parser rewrite + Check 22→24 merge + four pipeline re-points landing together vs. all-at-once (Approach A). Rejected Approach C (two work-items) — operator drives only one chain. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| `_check_on_disk` engine rewrite (3 of 6 checks read dropped fields) — top adversarial blocker | Phase 1: derive `audit_class` into the TSV from the path heuristic + cut the engine 6→4 checks; verify `CHECKS_RUN=4` + human-doc-ids still fires. |
| 3-way seed byte-identity (`spec/doc-spec.md` == `doc-spec.sh --seed` heredoc == `templates/doc-spec-common.md`) can silently drift if only one copy is edited | Phase 1: edit all three in lockstep; `doc-spec-overlay.test.sh` red-fails on drift. |
| `pipeline-gate` collides with the `units:` `layer` closed enum `{local-hook, ci}` | Phase 2: `gates[]` becomes a NEW top-level `gates:` array in test-spec-custom, NOT a `units:` row; `test-spec.sh --validate` learns its own schema. |
| Check 22 (advisory) folding into Check 24 (hard) could silently promote marker-drift to hard-fail | Phase 2: the merged check keeps the coverage portion hard AND the per-mode marker-drift portion advisory (exit 0 on a marker finding). |
| Check 24's own forward anchor-grep self-breaks on the retargeted `=== Check 22:` unit row | Phase 2: retarget the `test-spec-custom.md` unit row anchored `=== Check 22:` to `=== Check 24:` (or remove if Check 22 ceases to be a distinct banner); reverse-sweep the deleted `gate-spec.sh` row. |
| OQ1 — front_table retirement (Check 20 gone). If a leading-summary-table lint is wanted later, it returns as a tiny path-list, not a per-row field | Flagged, not blocking. |
| OQ2 — test-spec now owns process gates; the name no longer perfectly fits | Name kept to bound blast radius; prose states broadened meaning. A future rename to `verification-spec` is a separate, larger change. |
| Hidden references to deleted files/checks/`--render` survive a fixed-list edit | Re-point sweeps are grep-driven, not fixed file lists; Success Criteria require grep-clean across scripts/skills/docs/tests. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `spec/doc-spec.md` is a 3-column markdown table parsed directly; no YAML block, no `section`/`audit_class`/`front_table`; 3-way byte-identical (`doc-spec.sh --seed` + `templates/doc-spec-common.md`).
- [ ] `spec/doc-spec-custom.md` uses the same table shape and only extends.
- [ ] `docs/doc-general.md`, `docs/doc-custom.md`, `scripts/generate-doc-views.sh`, `scripts/gate-spec.sh`, `spec/gate-spec.md` deleted; grep-clean of every live reference.
- [ ] `doc-spec.sh --check-on-disk` runs 4 checks (`CHECKS_RUN=4`); human-doc-ids still works via path-derived `audit_class`; `--render` / `--list-front-table-docs` removed.
- [ ] `spec/test-spec.md` carries the `layers[]` registry in four-layer framing; `spec/test-spec-custom.md` holds `units:` + a new top-level `gates:` array that `test-spec.sh --validate` accepts.
- [ ] Check 19 still passes via the path heuristic; Checks 20 + 23 gone; Check 22 folded into Check 24 with its marker-drift portion STILL ADVISORY.
- [ ] All four cj_goal pipelines cite `test-spec.md` as the canonical gate sequence.
- [ ] `CJ_doc_audit` re-enumerates the 4 checks; both audit skills seed + run clean in a bare repo AND in this workbench.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` are green.

## Not in scope

<!-- Explicit non-goals. -->

- Renaming `test-spec` to `verification-spec` — kept to bound blast radius (OQ2); a separate, larger change.
- Reinstating a leading-summary-table lint after retiring Check 20 — if wanted later, returns as a tiny path-list, not a per-row field (OQ1).
- Splitting into two work-items / two PRs (Approach C) — rejected by the operator; one review/ship chain.
- Any external/runtime dependency change — the table parser stays in the POSIX-shell awk/bash idiom, no new runtime deps.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000063_TRACKER.md](F000063_TRACKER.md)
- Roadmap: [F000063_ROADMAP.md](F000063_ROADMAP.md)
- Child story: [S000105_doc_test_spec_table_and_gate_merge/S000105_TRACKER.md](S000105_doc_test_spec_table_and_gate_merge/S000105_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-upbeat-williams-043b2a-design-20260612-194619.md`
- Predecessors: F000056 (cleaner doc contract / generated views), F000057 (relocate spec registry into spec/), F000060 (two-tier audit contract), F000061 (three-stage audit hardening), F000054 (gate-spec verification contract).
