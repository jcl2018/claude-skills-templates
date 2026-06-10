---
type: test-spec
parent: S000101
feature: F000059
title: "test-pipeline registry + parser + generated view + hard sync/coverage checks — Test Specification"
version: 1
status: Draft
date: 2026-06-10
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Registry schema validates | spec/test-pipeline.md parses: single yaml fence, schema_version 1, closed enums honored, no work-item ID in any rendered field | `bash scripts/test-pipeline.sh --validate` |
| S2 | core | AC-2 | Parser round-trip | `--list-units` enumerates ≥ 60 rows; two consecutive `--render` runs are byte-identical; rendered output greps clean for `[FSTD][0-9]{6}` | `bash scripts/test-pipeline.sh --list-units \| wc -l; bash scripts/test-pipeline.sh --render > /tmp/r1.md; bash scripts/test-pipeline.sh --render > /tmp/r2.md; diff /tmp/r1.md /tmp/r2.md; ! grep -E '[FSTD][0-9]{6}' /tmp/r1.md` |
| S3 | usability | AC-3 | Generated view fresh + shaped | Regenerating produces zero diff on a clean tree; docs/test-pipeline.md opens with the summary table before the first `## ` heading and links spec/gate-spec.md | `./scripts/generate-doc-views.sh && git diff --exit-code docs/test-pipeline.md` |
| S4 | resilience | AC-5 | Check 24 green on live tree | Coverage cross-check passes (forward anchors found, reverse tokens all row-resolved, floor ≥ 20) — shows PASS, not SKIP, on the workbench | `./scripts/validate.sh` (Check 24 section green) |
| S5 | integration | AC-4, AC-6, AC-7 | Full suites green | Extended Check 23 third-view diff, config-test 13 seed byte-identity (11-doc seed), and the REGISTERED tests/test-pipeline-spec.test.sh sub-suite (round-trip + malformed fixtures + 4 drift drills) all execute and pass inside the standard runs | `./scripts/validate.sh && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-3 | First-time reader surveys the verification surface | Open docs/test-pipeline.md cold; read only the leading summary table; answer "what protects this repo, where, and when" | The table alone names every family (validate / test / standalone suites / ci / hook), unit counts, hard-vs-advisory split, and triggers — answerable in under a minute without scrolling to sections | Reader states the answer in < 1 min from the table alone; no source files opened |
| E2 | resilience | AC-5 | New check lands without a registry row (reverse drill) + test row orphaned (forward drill, the silent-skip catch) | In a temp copy of the repo fixture: (a) append a fake `echo "=== Check 99: fake ==="` banner to validate.sh; run the coverage check; (b) separately, delete a registered runner block from the temp test.sh; run again | (a) reverse sweep fails naming the unmatched "Check 99" token; (b) forward check fails naming the orphaned test row whose runner-path anchor vanished | Both failures fire with actionable messages naming the token/row; live tree untouched |
| E3 | resilience | AC-5 | Registry anchor rots (forward drill) | In a temp registry copy, corrupt one row's `anchor` string to a non-existent literal; point the check at the temp copy; run | Forward check fails naming the row id and the source file the anchor was not found in | Failure names row + source; exit non-zero; clean baseline restored after drill |
| E4 | integration | AC-4 | Human hand-edits the generated view | In a temp copy, edit one line of docs/test-pipeline.md by hand; run the Check 23 extension path | The temp-regen+diff fails with the "run scripts/generate-doc-views.sh" remediation message | Diff failure + correct remediation message; regenerating clears it |
| E5 | resilience | AC-8 | Consumer repo without the registry | In a scratch git repo with docs/ but NO spec/test-pipeline.md and NO scripts/test-pipeline.sh, run generate-doc-views.sh and validate.sh equivalents | Third view output skipped with a one-line note; Check 23 extension skips the third diff; Check 24 emits SKIP; exit 0; no docs/test-pipeline.md written | All skips are single-line notes; zero errors; nothing written |

<!-- AC-1/AC-2 are fully covered by smoke (S1/S2): registry schema and parser
     round-trip are deterministic script assertions with no user-visible
     scenario beyond them. AC-9 (secondary-doc sweep) is P1 — verified by
     review of CLAUDE.md / docs/architecture.md diffs at ship time. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Semantic accuracy of each registry `purpose` one-liner (behavior changes under a stable banner) | Not mechanizable by structural checks — by design this stays with the advisory registered-doc requirements audit on every cj_goal run | A check's description can rot while its banner/anchor stays stable; caught by agent judgment, not CI |
| Reverse-sweep coverage of FUTURE standalone suite scripts or inline test.sh families outside the banner grammar | Documented, accepted boundary — the reverse sweep covers validate banners/comments, test files, workflows, and hooks only | A brand-new suite script added without a registry row is forward-anchor-only (no row → invisible) until someone registers it |
| test.sh inline-family renames that keep the section-banner anchor strings intact | Anchors are literal strings; an editorial rename around a stable anchor is invisible to Check 24 | Stale family labels in the view until the advisory audit or a human notices |
| Cross-repo consumer adoption beyond the E5 scratch fixture (real downstream repo install) | Workbench-only scope; consumer repos exercise the seed stub path via /CJ_document-release in their own runs | A consumer-specific environment quirk could surface post-adoption |
