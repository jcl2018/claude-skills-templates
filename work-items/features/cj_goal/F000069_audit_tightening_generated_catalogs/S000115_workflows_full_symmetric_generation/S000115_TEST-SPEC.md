---
type: test-spec
parent: S000115
feature: F000069
title: "Workflows full symmetric generation — Test Specification"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE story S000115. Smoke + E2E together cover every SPEC P0 AC.
     AC column maps each row to a SPEC story # (acceptance-criteria block). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2, AC-3 | Engine validate + completeness | `--validate` exits 0 on the valid registry, asserts per-kind fields + a closed `kind` enum + registry-completeness (every routable `CJ_goal_*` has an orchestrator entry) | `scripts/workflow-spec.sh --validate; echo $?` + `scripts/workflow-spec.sh --list-workflows` |
| S2 | core | AC-4 | `--render-docs` writes the whole surface | `docs/workflow.md` (preamble + index table) + one `docs/workflows/<name>.md` per entry are produced; a second render is byte-identical | `scripts/workflow-spec.sh --render-docs && git diff --quiet docs/workflow.md docs/workflows/ && echo CLEAN` |
| S3 | resilience | AC-6, AC-10 | Deterministic + ID-free output | Two consecutive renders are byte-identical AND no rendered file contains `[FSTD][0-9]{6}` | `tests/workflow-spec-render.test.sh` (stability + ID-free asserts) |
| S4 | observability | AC-5 | `--render-docs --check` round-trip | `--check` exits 0 on a fresh render; exits 1 (naming the file) on a hand-edited/missing generated doc | `scripts/workflow-spec.sh --render-docs --check; echo $?` + `tests/workflow-spec-render.test.sh` |
| S5 | integration | AC-7 | Check 27 gate + test.sh fixture + 15b/15c retired | `validate.sh` Check 27 ERRORs on a stale workflow surface; `scripts/test.sh` carries the parallel Check-27 fixture; Checks 15b/15c no longer run (pointer comment present) | `scripts/validate.sh` (Check 27 line) + `grep -n 'Check 27' scripts/test.sh` + `grep -n '15b\|15c' scripts/validate.sh` |
| S6 | integration | AC-9 | Registry declarations + coverage resolve | `spec/workflow-spec.md` declared; generated docs declared as human-docs (no orphan, no IDs); new units rows resolve in the reverse-sweep | `scripts/doc-spec.sh --check-on-disk && scripts/test-spec.sh --validate --check-coverage` |

<!-- Soft cap: 5 rows — exceeded by 1 (6 rows). Justified: the story spans a new
     registry + a new engine (validate/render/check) + the freshness gate + the
     contract-registry declarations; collapsing further would hide a P0 surface
     (each row maps to a distinct P0 AC group). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-4, AC-6 | Maintainer migrates + regenerates the workflow surface | Inspect `spec/workflow-spec.md` (header preamble + 4 orchestrator + 2 roster sections), run `scripts/workflow-spec.sh --render-docs`, then open `docs/workflow.md` + a `docs/workflows/<name>.md` and `git diff` | The index reproduces the preamble verbatim + lists all 6 entries with links; each orchestrator page shows its verbatim chart + 4 Touches axes + "In words"; each roster page shows its verbatim body; the one-time reformat diff is the only change; re-render is a no-op diff; no `[FSTD][0-9]{6}` anywhere | PASS if the surface regenerates faithfully (charts/rosters/preamble verbatim), is ID-free, and a second render is a no-op |
| E2 | core | AC-3 | Operator proves the no-vanish guarantee fails closed | Temporarily remove one orchestrator `## <name>` section from `spec/workflow-spec.md` (or a fixture copy), run `scripts/workflow-spec.sh --validate`; restore it and re-run | `--validate` fails (non-zero) naming the missing workflow when an orchestrator entry is absent; passes after restore | PASS if the registry-completeness check fails closed on a removed entry and passes when complete |
| E3 | observability | AC-5, AC-7 | Operator proves the freshness gate catches drift | Hand-edit a line in `docs/workflow.md` (or a `docs/workflows/*.md`); run `scripts/workflow-spec.sh --render-docs --check` then `scripts/validate.sh`; then regenerate and re-run both | `--check` and Check 27 both fail and name the stale file before regenerate; both pass after regenerate; Check 15b/15c are gone | PASS if the gate fails-on-stale and passes-on-fresh, naming the file, with 15b/15c retired |
| E4 | integration | AC-8 | Doc audit owns workflow freshness standalone | Run `/CJ_doc_audit` (Stage 1 + Stage 3) against the repo with a fresh surface, then with a hand-edited one | Stage 1 reports a freshness finding on the stale surface (clean when fresh); Stage 3 does NOT flag `docs/workflow.md` / `docs/workflows/` as an orphan/uncontemplated surface (recognized as generated) | PASS if Stage 1 catches staleness and Stage 3 treats the surface as generated |
| E5 | core | AC-7, AC-10 | Suite proves the engine + the no-vanish drill | Run the full suite: `scripts/test.sh` (includes `tests/workflow-spec-render.test.sh` + the Check-27 fixture) | The suite is green; `tests/workflow-spec-render.test.sh` exercises determinism, ID-freeness, `--check` pass/fail-on-edit/fail-on-missing, and the remove-an-entry `--validate` registry-completeness drill; the Check-27 fixture runs positive + negative drift + regenerate-green | PASS if `scripts/test.sh` is green incl. the new test + Check-27 fixture |

<!-- Soft cap: 5 rows — met. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Strict byte round-trip of the pre-migration 6 docs | The operator explicitly chose a normalized one-time reformat (charts/rosters/preamble verbatim, structure may shift); a byte round-trip is out of scope by decision | A future reader diffing pre/post migration sees structural whitespace/heading shifts — expected, reviewed once in the PR |
| Cross-machine consumer-repo enforcement of the workflow gate | Belongs to deferred Story 4 (consumer Stage-1 gate), not this story | Portable enforcement via the gate hook is unproven until Story 4; `/CJ_doc_audit` Stage 1 is the standalone path this story ships |
| `--seed` behavior in a real consumer-repo adopt (vacuous completeness) | SPEC P2 #12 — the empty-skeleton seed is implemented but a full consumer-repo adopt drill is deferred to Story 3 (forced seeding) | A consumer repo's seed-then-validate path is exercised only by the hermetic fixture, not a live adopt, until Story 3 |
| Human-preferred prose vs the normalized rendered template | The surface is machine-rendered by design; prose is registry-sourced, not hand-tuned | A human may find a rendered phrasing terse; acceptable since the registry is the single source of truth |
