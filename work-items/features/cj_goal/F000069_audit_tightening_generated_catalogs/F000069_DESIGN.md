---
type: design
parent: F000069
title: "Tighten doc/test audits — generated human catalogs, forced seeding, consumer enforcement — Feature Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Distilled from the APPROVED /office-hours design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/audit-tightening-design-20260628-200601.md
     Story-scope detail (SPEC/TEST-SPEC) lives on the nested user-story S000114. -->

## Problem

The two audit verbs (`/CJ_doc_audit`, `/CJ_test_audit`) and the doc/test contract
they enforce have three gaps the operator hit in practice:

1. **No human-readable test catalog.** `spec/test-spec-custom.md` enumerates ~71
   verification units in machine YAML (for AI/engine review), but there is no
   human-browsable rendering of "what tests exist and what each proves." The
   workflow side already has the two-level human surface (`docs/workflow.md`
   index + `docs/workflows/*.md` per-workflow); the test side has nothing parallel.
2. **The human surfaces aren't generated → they rot.** `docs/workflows/*.md`
   (ASCII charts + 4-bullet Touches blocks) are hand-authored and drift from
   reality. A second, hand-maintained copy of registry-derivable content fights
   the contract's own `single-owner` rule.
3. **The audits aren't reliably available, seeded, or enforced outside the
   workbench.** The audit skills seed `spec/doc-spec.md` / `spec/test-spec.md`
   only lazily (when the audit runs, and only when `--classify` says `absent`). A
   stale repo-local engine can SHADOW the newer `_cj-shared` one (repo-local
   wins), so seeding silently no-ops. And nothing installs a deterministic gate in
   a consumer repo, so the contract is enforced only inside the workbench
   (`validate.sh` + pre-commit hook + CI).

## Shape of the solution

A unified **"generated human catalog, freshness-gated, audit-owned"** model
applied to BOTH the test surface and the workflow surface, plus **forced
(proactive) seeding** of the contracts at adoption and a **deterministic Stage-1
enforcement gate** installable in any consumer repo. The single source of truth
stays the `spec/` registries; the `docs/` surfaces become generated views the
audits keep fresh.

The reusable primitive (already proven once by `README.md` ↔ `generate-readme.sh`
↔ `validate.sh` Check 25):

```
spec registry ──(engine --render-docs)──> generated docs/ surface
                                               │
                      validate.sh freshness check (regenerate → diff → ERROR on mismatch)
                                               │
                      audit Stage 1 runs the SAME freshness check (enforced standalone, any repo)
```

Three instances exist after the full epic:

| Surface | Registry (source of truth) | Generator | Freshness gate |
|---------|----------------------------|-----------|----------------|
| `README.md` | `skills-catalog.json` | `generate-readme.sh` | Check 25 (exists) |
| `docs/tests/*.md` + `docs/test-catalog.md` | `spec/test-spec*.md` | `test-spec.sh --render-docs` | **Check 26 (Story 1)** |
| `docs/workflows/*.md` + `docs/workflow.md` | `spec/workflow-spec*.md` | `workflow-spec.sh --render-docs` | **Check 27 (Story 2)** — replaces hand-authored 15b/15c |

The epic decomposes into four independently-shippable user-stories:

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Generated `docs/tests/` catalog + the freshness primitive (P1) | S000114 | [S000114_gen_tests_catalog_freshness/S000114_TRACKER.md](S000114_gen_tests_catalog_freshness/S000114_TRACKER.md) |
| Workflows full symmetric generation (P2) | (deferred) | tracked in `F000069_TRACKER.md` "Deferred stories" |
| Forced seeding + stale-engine fix (P3) | (deferred) | tracked in `F000069_TRACKER.md` "Deferred stories" |
| Consumer Stage-1 enforcement gate (P4) | (deferred) | tracked in `F000069_TRACKER.md` "Deferred stories" |

**This build pass delivers Story 1 only** (the buildable, fully-specified slice);
the design's "Phasing" section names the order, and one silent autonomous build
cannot deliver all four reliably.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Generated + freshness-gated test catalog, NOT hand-authored | A hand-maintained second copy of registry-derivable content fights the contract's own `single-owner` rule; the generated-view model keeps `spec/` the single source of truth. |
| 2 | Reuse the proven README↔generate-readme↔Check-25 primitive | The pattern is already battle-tested once; Story 1 builds the second instance, Story 2 the third — symmetric engine-resolution + classify/seed idioms across `doc-spec.sh` / `test-spec.sh` / `workflow-spec.sh`. |
| 3 | Render ONLY rendered fields (`label`/`purpose`/`layer`/`disposition`/`trigger`); show `anchor` as a code reference, never a claim | Rendered fields are already work-item-ID-free by the existing rendered-field lint, so the generated human-docs satisfy Check 19 by construction. |
| 4 | Audits own freshness end-to-end (Stage 1 invokes the engine freshness check) | A consumer repo with no `validate.sh` still catches a stale catalog the moment the audit runs — portable enforcement. |
| 5 | Phase the epic into 4 stories; build Story 1 first | Each story is independently shippable + fully testable; Story 1 establishes the reusable pattern and is fully E2E-testable in the workbench. |
| 6 | (Story 2, deferred) FULL symmetric workflow generation, charts included | Operator chose option B over a lighter Touches-only generation, accepting that chart-generation is the costliest/least-certain-payoff part. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| ASCII-chart migration fidelity (Story 2) — multi-line charts in a registry must render byte-faithfully | Resolved in Story 2: fenced verbatim registry blocks + a byte-diff acceptance test; an explicitly-approved normalized rendering is the documented fallback. |
| Retiring Checks 15b/15c (Story 2) must preserve the no-vanish guarantee | Story 2: `workflow-spec --validate` ERRORs if a routable `CJ_goal_*` has no registry entry. |
| Consumer enforcement (Story 4) is cross-machine — not fully E2E-verifiable inside the workbench | Story 4: verify via a temp-dir adopt drill. |
| A new `validate.sh` check (Check 26) needs the parallel `scripts/test.sh` integration fixture (recurring blind spot) | Story 1 SPEC pins it as a P0 requirement (#3) and TEST-SPEC asserts it — built in the same story. |
| Epic size — one silent build cannot deliver all four reliably | Mitigated by the phased multi-story plan; Story 1 is the only buildable child this pass. |

## Definition of done

<!-- Epic-level. Story 1's slice is the buildable portion this pass; full closure
     spans all four stories across subsequent passes. -->

- [ ] **(Story 1)** `test-spec.sh --render-docs` generates `docs/tests/<family>.md` + `docs/test-catalog.md`, deterministic + ID-free; `--render-docs --check` diffs and exits non-zero on mismatch.
- [ ] **(Story 1)** `validate.sh` Check 26 hard-errors on a stale catalog; the parallel `scripts/test.sh` fixture asserts it; `tests/test-spec-render.test.sh` is green.
- [ ] **(Story 1)** Generated docs committed + declared in `spec/doc-spec-custom.md`; new units in `spec/test-spec-custom.md`; `/CJ_test_audit` Stage 1 freshness + Stage 3 generated-surface recognition wired.
- [ ] **(Story 1)** `scripts/validate.sh` + `scripts/test.sh` green; post-sync `/CJ_doc_audit` + `/CJ_test_audit` report 0 findings.
- [ ] **(Deferred)** Stories 2–4 scaffolded + built in subsequent passes (workflows generation; forced seeding + stale-engine fix; consumer Stage-1 gate).

## Not in scope

- Stories 2, 3, 4 implementation — tracked as "Deferred stories" in `F000069_TRACKER.md`; not built this pass (epic is delivered in phases).
- Touching upstream gstack skills — the contract is enforced via this repo's `validate.sh` / audits, never by editing upstream `/ship` / `/document-release` / `/land-and-deploy`.
- Changing the `spec/` registry GRAMMAR — Story 1 reads the EXISTING merged test-spec registry's rendered fields; it adds a renderer, not a new registry axis.

## Pointers

- Parent tracker: [F000069_TRACKER.md](F000069_TRACKER.md)
- Roadmap: [F000069_ROADMAP.md](F000069_ROADMAP.md)
- Story 1: [S000114_gen_tests_catalog_freshness/S000114_TRACKER.md](S000114_gen_tests_catalog_freshness/S000114_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/audit-tightening-design-20260628-200601.md`
