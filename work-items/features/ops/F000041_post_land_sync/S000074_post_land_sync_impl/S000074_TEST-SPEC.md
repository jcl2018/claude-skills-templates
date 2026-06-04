---
type: test-spec
parent: S000074
feature: F000041
title: "post-land-sync helper + CLAUDE.md docs + test wiring — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. These rows encode the design's Success Criteria. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from CI. Soft cap: 5 rows.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | usability | AC-1 | `post-land-sync.sh --dry-run` exits 0 and prints resolved `.source` + would-run pull/install + current collection_version, with no mutation | DoD: `--dry-run` previews and mutates nothing | `tests/post-land-sync.test.sh` (dry-run case, temp fixture) |
| S2 | resilience | AC-3 | Helper run against a missing / non-main / dirty `.source` warns naming the guard and exits non-zero, with no pull/install | DoD: guards refuse a bad `.source`; never force | `tests/post-land-sync.test.sh` (guard cases, temp fixture) |
| S3 | core | AC-2 | Helper resolves `.source` via `jq -r .source` and would invoke `git -C <.source> pull --ff-only` + `<.source>/scripts/skills-deploy install` with a before→after version read (asserted via `--dry-run` echo, no real mutation) | DoD: real-run command shape + before→after report | `tests/post-land-sync.test.sh` (command-shape assertions on --dry-run output) |
| S4 | observability | AC-4 | `CLAUDE.md` "CI/CD merge convention" contains the `post-land-sync.sh` step, the bypass-reason subsection, and the drift note | DoD: CLAUDE.md documents (a)+(b)+(c) | `grep -q 'post-land-sync.sh' CLAUDE.md && grep -qi 'bypass' CLAUDE.md` |
| S5 | integration | AC-5 | `scripts/test.sh` references `post-land-sync.test.sh` so the new test actually runs | DoD: test wired into the suite (validate↔test blind spot) | `grep -q 'post-land-sync.test.sh' scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Operator previews the post-land sync before running it | From the repo root, run `./scripts/post-land-sync.sh --dry-run` | Output shows the resolved `.source` path, the would-run `git pull --ff-only` + `skills-deploy install`, and the current collection_version; `git -C <.source> status` is unchanged; no `skills-deploy install` ran | PASS if nothing mutated AND all three pieces (source, commands, version) are printed |
| E2 | core | AC-2 | Operator reconciles their machine after merging #200/#201 | With `.source` on a clean `main`, run `./scripts/post-land-sync.sh` | Helper pulls `.source` (ff-only), runs `skills-deploy install`, and prints collection_version before→after (e.g. 6.0.8 → 6.0.10) | PASS if the after-version equals `.source`'s VERSION and the before→after line is printed |
| E3 | integration | AC-5 | Maintainer confirms the suite runs the new test | Run `./scripts/test.sh` | Suite output includes `post-land-sync.test.sh` running and passing; overall 0 failures | PASS if the named test runs AND the suite is green |

<!-- post-ship rows: none — every row is verifiable locally before merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The real `git pull --ff-only` + `skills-deploy install` against the operator's actual `~/.claude` | The automated test must never mutate the real `~/.claude`; only `--dry-run` + temp fixtures are exercised in CI. The real mutation is verified once, manually, via E2 (the dogfood run). | A regression in the real pull/install path that does not also show up under `--dry-run` could slip past CI; mitigated by the manual E2 dogfood before ship. |
| `/land-and-deploy` tail integration | Out of scope for v1 (deferred follow-up). | The helper remains a manual post-merge step; an operator who forgets it stays drifted until next manual run — the documented convention (S4) mitigates. |
