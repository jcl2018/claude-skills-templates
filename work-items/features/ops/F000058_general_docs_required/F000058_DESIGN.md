---
type: design
parent: F000058
title: "General docs are required — reclassify the contract/agent/backlog docs + views as section: common — Feature Design"
version: 1
status: Draft
date: 2026-06-09
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-story — do not duplicate it
     here. Distilled from the APPROVED /office-hours design doc
     chjiang-claude-pensive-robinson-08ad9c-design-20260609-191404.md. -->

## Problem

The doc-spec contract has a two-tier model (general `section: common` vs
per-repo `section: custom`), but today the general tier is only the 4 human
docs. The contract file itself (`spec/doc-spec.md`), the agent instructions
(`CLAUDE.md`), the changelog (`CHANGELOG.md`), the backlog (`TODOS.md`), and
the two generated views (`docs/doc-general.md`, `docs/doc-custom.md`) are all
labeled `custom` — even though every repo that adopts the contract needs them.
The portable Common seed still says "four human docs" and declares
`doc-spec.md` as `custom` in its own seed registry. Nothing states the rule
"general docs are required."

Operator ask (verbatim intent): make `docs/doc-general`, `docs/doc-custom`,
`TODOS.md`, `CLAUDE.md`, `CHANGELOG.md`, `spec/doc-spec.md` general docs, make
general docs required, and have `/CJ_document-release` state this logic.

## Shape of the solution

A complete contract restatement (Approach B), carried by one atomic child
story: flip the 6 registry entries to `section: common`, rewrite the
Common-prose contract as a 10-doc general table with an explicit "General docs
are required" rule (all three seed copies byte-identical where required), grow
the seed registry to 10 portable entries, regenerate the two views, state the
tier logic + an advisory missing-general-doc audit rule in
`/CJ_document-release`, amend philosophy's "Two tiers, one portable pass"
principle, and sweep secondary references for stale "four human docs" claims.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Complete contract restatement (registry flip + seed growth + views + skill statement + philosophy + sweep + tests) | S000100 | [S000100_general_docs_required_restatement/S000100_TRACKER.md](S000100_general_docs_required_restatement/S000100_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | "General = required" lands in the portable Common seed, not just this repo's registry | A registry-only flip would be a workbench-only claim (Premise 1) |
| 2 | The general set becomes exactly 10 docs; `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md` stay `custom` | The set boundary was the operator's named ask (Premise 2) |
| 3 | "Required" = must exist, enforced by EXISTING machinery (Check 15/17 + stub-scaffold + seed declaring all 10); the skill STATES the logic plus an advisory audit finding, never a halt | No new hard gate; document-don't-enforce-harder survived premise challenge (Premise 3) |
| 4 | Seed requirement strings stay portable; the workbench registry keeps specialized requirement strings for the same paths | Established precedent: philosophy's `front_table` specialization of a common entry (Premise 4) |
| 5 | Approach B (complete restatement) over Approach A (seed-minimal) | A leaves the "four human docs" framing in the same Common section that states the new rule — the seed argues with itself |
| 6 | Approach C (machine-enforced `--list-general-docs` + hard check) rejected for now | New check ⇒ test.sh fixture churn + a hard-gate posture Premise 3 rejected; eligible as a later TODOS row |
| 7 | Audit enumeration of the general set reuses the parser (`--seed` to temp file + `DOC_SPEC_PATH` override + `--render general`), never hand-parsed yaml | `--list-declared` would silently over-enumerate if the seed ever regains a custom entry; render-general filters by `section: common` |
| 8 | Path equivalence: a registry path whose basename is `doc-spec.md` satisfies the seed's root-style `doc-spec.md` entry | Mirrors doc-spec.sh's own spec/-then-root resolution; without it the workbench false-positives on every run |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 3-way byte-identical coupling (workbench Common section ↔ `templates/doc-spec-common.md` ↔ `doc-spec.sh` heredoc) — easy to drift one copy | Drift test 13 (heredoc == template) + the S000100 E2E byte-compare before /ship |
| Common-prose rewrite must not add a second ```` ```yaml ```` fence and must preserve the H1 phrase "what docs this repo carries" | Existing test assertions (single-fence + test 8 grep) run in test.sh during QA |
| Seed must still pass `--validate` after growing to 10 entries | Self-bootstrap regression test 12 path, run during QA |
| Editing `skills/CJ_document-release/SKILL.md` trips Check 14 USAGE.md drift | USAGE.md refresh in the same change (content or `last-updated:` bump idiom) |
| Approach C deferred — does the operator want a TODOS row? | Only if the operator asks; no row by default (design's Open Questions) |

## Definition of done

- [ ] The 6 named docs are `section: common` in the workbench registry; `docs/doc-general.md` lists all 10 general docs; `docs/doc-custom.md` lists exactly `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md`.
- [ ] The portable seed (all three copies, byte-identical where required) declares the 10 general docs and states "general docs are required."
- [ ] `/CJ_document-release` SKILL.md states the tier logic (general = required + stub-scaffolded; custom = per-repo) and carries the advisory missing-general-doc audit rule.
- [ ] `docs/philosophy.md` "Two tiers, one portable pass" states required-ness.
- [ ] Workbench Common section is byte-identical to the seed Common section (incidental drift fixed).
- [ ] `validate.sh` + `test.sh` fully green with no new checks and no fixture edits.

## Not in scope

- Approach C: `doc-spec.sh --list-general-docs` + a hard validate.sh check that the registry declares every general-contract doc — rejected for now (fixture churn + hard-gate posture Premise 3 rejected); eligible as a later TODOS row only if the operator asks.
- Reclassifying `CONTRIBUTING.md`, `spec/gate-spec.md`, `spec/permission-policy.md` — they stay `custom` per Premise 2.
- Any new validate.sh check or `scripts/test.sh` fixture edit — the build is deliberately check-neutral (Check 17 is section-agnostic; no validator change needed).
- Editing historical records (`CHANGELOG.md` entries, `work-items/**` archives) during the secondary-reference sweep — history is not reconciled.
- `audit_class` changes — the flip is `section:` only (operational stays operational; the two views stay human-doc).

## Pointers

- Parent tracker: [F000058_TRACKER.md](F000058_TRACKER.md)
- Roadmap: [F000058_ROADMAP.md](F000058_ROADMAP.md)
- Child story: [S000100_general_docs_required_restatement/S000100_TRACKER.md](S000100_general_docs_required_restatement/S000100_TRACKER.md)
- Source design doc (APPROVED): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-pensive-robinson-08ad9c-design-20260609-191404.md`
- Doc contract: `spec/doc-spec.md` + `docs/architecture.md` `## The doc-spec.md contract + /CJ_document-release`
- Predecessor features: `work-items/features/ops/F000055_standalone_cj_document_release_principle/`, `work-items/features/ops/F000056_cleaner_doc_contract_generated_views/`, `work-items/features/ops/F000057_relocate_spec_registry_family_into_spec_folder/`
