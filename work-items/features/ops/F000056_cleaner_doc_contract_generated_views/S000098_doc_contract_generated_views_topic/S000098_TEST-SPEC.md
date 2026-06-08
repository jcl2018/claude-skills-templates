---
type: test-spec
parent: S000098
feature: F000056
title: "Generated general/custom doc views + philosophy Doc-contract topic — Test Specification"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, CI-runnable. AC maps to a SPEC #. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `--render general` emits 4 rows; `--render custom` emits 9 rows | Render row sets are exact; tables have a header + `|---|`; cells are quote-stripped and pipe-escaped | `scripts/doc-spec.sh --render general \| grep -c '^\|' ; scripts/doc-spec.sh --render custom \| grep -c '^\|'` |
| S2 | core | AC-2 | Generator is idempotent | Generating into a temp dir twice yields byte-identical `doc-general.md` + `doc-custom.md` | `t1=$(mktemp -d); t2=$(mktemp -d); scripts/generate-doc-views.sh --output-dir "$t1"; scripts/generate-doc-views.sh --output-dir "$t2"; diff -r "$t1" "$t2"` |
| S3 | resilience | AC-6 | Check 23 drift gate | `validate.sh` fails when `docs/` views differ from a fresh regen, passes when in sync, skips cleanly if the generator is absent | `scripts/validate.sh` (Check 23 segment) |
| S4 | core | AC-3 | Views declared + no work-item IDs + seed intact | `validate.sh` Check 15a (declared ⇔ on-disk), Check 19 (no `[FSTD][0-9]{6}` in the views), and the registry validates clean | `scripts/validate.sh; scripts/doc-spec.sh --validate; grep -nE '[FSTD][0-9]{6}' docs/doc-general.md docs/doc-custom.md` |
| S5 | integration | AC-7 | Full suite + seed test #13 green | `test.sh` (incl. the Check 23 temp-only mirror) + the seed drift guard pass; README regen is idempotent | `scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification before /ship. One user-visible scenario per row. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-3 | Render row sets are exactly the contracted docs | Run `scripts/doc-spec.sh --render general` and `--render custom`; read the tables | general = README.md, docs/philosophy.md, docs/workflow.md, docs/architecture.md (4); custom = doc-spec.md, gate-spec.md, CLAUDE.md, CHANGELOG.md, CONTRIBUTING.md, TODOS.md, permission-policy.md + docs/doc-general.md + docs/doc-custom.md (9) | PASS iff both lists match exactly (count + identity) |
| E2 | usability | AC-5 | Philosophy Doc-contract topic reads well and is positioned right | Open `docs/philosophy.md`; locate `## Topic: Doc contract`; confirm it carries the 2 moved principles + a registry→views lead-in, is BEFORE `## Decision tree`, and the front-summary-table labels are updated | The topic exists with both principles + lead-in; Decision tree is still last; front-table labels honest | PASS iff topic present, correctly positioned, labels updated, Check 19/20 green |
| E3 | usability | AC-4 | Slimmed Custom prose keeps its rationale; seed intact | Open `doc-spec.md`; confirm the root-operational-docs table is replaced by a pointer, the "Repo notes" nuggets + `front_table` explanation remain, and the Common section is unchanged | Pointer present; rationale preserved; Common section byte-identical to `templates/doc-spec-common.md` | PASS iff pointer + rationale present AND seed test #13 green |
| E4 | resilience | AC-6 | Drift is caught end-to-end | Hand-edit `docs/doc-custom.md` (e.g. delete a row), run `scripts/validate.sh`; then regenerate via `scripts/generate-doc-views.sh` and re-run | First run ERRORs with the drift message naming the regen command; after regen, `validate.sh` is green | PASS iff drift fails and a regen clears it |
| E5 | integration | AC-7 | README + script reference are consistent | Run `scripts/generate-readme.sh`; confirm `git diff README.md` is empty (already regenerated); confirm the `docs/` blurb mentions the views and `CLAUDE.md` Scripts table has a `generate-doc-views.sh` row | README is in sync; blurb + CLAUDE.md row present | PASS iff no README diff after regen AND blurb + row present |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Consumer-repo behavior when adopting the (unchanged) seed | The Common seed is out of scope (untouched); consumer repos are unaffected | None — seed parity is guarded by test #13 |
| Auto-regen-on-`/ship` | Deferred follow-up; v1 leaves regen manual gated by Check 23 | A maintainer must regen on drift; CI catches it |
| Pipe characters appearing inside `purpose:`/`requirement:` values | Values are pipe-free today; pipe-escape is defensive | Low — escape logic covers it if a value gains a pipe |
