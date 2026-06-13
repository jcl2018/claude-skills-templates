---
type: test-spec
parent: S000104
feature: F000062
title: "Curated reference.md + 3-way seed row/table/count + view regen — Test Specification"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | reference.md exists + clean | docs/reference.md present and carries no work-item IDs | `test -f docs/reference.md && ! grep -Eq '[FSTD][0-9]{6}' docs/reference.md` |
| S2 | core | AC-2, AC-3, AC-4 | declared + count swept | merged registry declares docs/reference.md; `eleven` is gone from the seed prose; CLAUDE.md parenthetical includes it | `bash scripts/doc-spec.sh --list-declared \| grep -qx docs/reference.md && ! grep -q 'eleven' spec/doc-spec.md && grep -q 'docs/reference.md' CLAUDE.md` |
| S3 | resilience | AC-6 | 3-way seed byte-identity | the seed heredoc == spec/doc-spec.md == templates/doc-spec-common.md | `bash scripts/doc-spec.sh --seed \| cmp - spec/doc-spec.md && cmp spec/doc-spec.md templates/doc-spec-common.md` |
| S4 | core | AC-5 | registry valid + views in sync | doc-spec.sh --validate OK; validate.sh Check 23 (view-sync incl. docs/doc-general.md) green | `bash scripts/doc-spec.sh --validate && ./scripts/validate.sh` |
| S5 | observability | AC-7 | config test 8b growth-safe + lists reference.md | the seed-growth test tolerates 12 and asserts docs/reference.md | `bash tests/cj-document-release-config.test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-8 | The build dogfoods the three-stage doc audit on the doc it just declared | During QA, the Step 8.6c `/CJ_doc_audit` runs; read its per-stage report for `docs/reference.md` | Stage 2 quotes the doc's requirement and verdicts `satisfies`; Stage 3 cross-walks and verdicts `no-drift` | PASS = reference.md `satisfies` (Stage 2) + `no-drift` (Stage 3); FAIL = any FINDING on reference.md |
| E2 | core | AC-1, AC-3 | A reader can use reference.md as a real reference shelf | Open `docs/reference.md`; skim the grouped categories; spot-check 3 entries against the repo (grep the URL/tool/standard) | Each category is coherent; spot-checked entries are genuinely referenced in the tree and carry a one-line why; the Human-docs table (in the seed) names it | PASS = all spot-checks grounded + grouped + intro present; FAIL = an invented/ungrounded entry or missing grouping |

<!-- Post-ship rows: none — every check is verifiable pre-merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| HTTP link-liveness (do the URLs resolve?) | Out of the contract's deterministic scope; would add a network dependency to the suite | A link may rot; Stage 2/3 agent judgment + operator review at the PR catch staleness |
| Exhaustive "is every formative source listed?" | "Useful" is an editorial call reserved for the operator at the PR (The Assignment) | v1 may omit a source the operator rates highly; pruning/extending is the explicit post-land assignment |
| Consumer-repo stub-scaffold of the new general doc | Verified by the existing `/CJ_document-release` stub path, not re-tested here | Adoption ripple is covered by the same path that stubs any missing declared doc |
