---
type: test-spec
parent: S000074
feature: F000041
title: "cj-repo-init detection engine + skill + tests + wiring — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Runnable from tests/cj-repo-init.test.sh. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Run script default in a temp repo with CJ_ skills "deployed" → table + `GAPS=<n>` emitted | Detection builds the prereq set and prints the machine-readable contract | `tests/cj-repo-init.test.sh::detect_emits_gaps` |
| S2 | core | AC-3, AC-5 | Run `--fix` in a temp repo with all 3 repo-level gaps → files created, exit 0; re-run → no-op, exit 0 | `--fix` scaffolds seeds and the re-run is idempotent | `tests/cj-repo-init.test.sh::fix_then_noop` |
| S3 | security | AC-6 | Generated `cj-document-release.json` parses as JSON with `schema_version` 1 | Scaffolded config passes `validate.sh` Check 16; invalid existing config is flagged as a gap | `tests/cj-repo-init.test.sh::config_valid_and_invalid_detected` |
| S4 | resilience | AC-4 | Run `--dry-run` in a temp repo with gaps → no file/dir created, exit reflects gap count | `--dry-run` never mutates | `tests/cj-repo-init.test.sh::dry_run_no_write` |
| S5 | resilience | AC-9 | Run outside a git repo AND with the deployed manifest absent → clean error/degrade, no crash | Graceful degradation paths | `tests/cj-repo-init.test.sh::degrades_cleanly` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-7 | Fresh-repo init via the skill | In a repo with CJ_ skills deployed but no config files, invoke `/CJ_repo-init`; observe the table; answer the single confirm AUQ with "scaffold now" | The skill prints a 3-row gap table, asks exactly ONE confirm question, then scaffolds `TODOS.md` + `cj-document-release.json` + `work-items/` and prints a clean post-fix table | PASS if exactly one AUQ, all 3 prereqs created, post-fix table shows no repo-level gaps |
| E2 | core | AC-5 | Idempotent re-run | Invoke `/CJ_repo-init` again on the now-healthy repo | Prints the health table with all rows green; no AUQ; exit 0 (no-op) | PASS if no writes, no AUQ, exit 0 |
| E3 | integration | AC-8 | Suite green | Run `./scripts/validate.sh` then `./scripts/test.sh` | Both pass: catalog entry, USAGE.md 5 sections, SKILL-CATALOG section + tag, routing rule, and `cj-repo-init.test.sh` all green | PASS if both scripts exit 0 |

<!-- post-ship rows: none. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior in a non-workbench adopting repo with a different deployed-skill set | No such fixture repo available in CI; tests use a synthetic temp repo | Portability regressions in a foreign repo may surface only on first real adoption |
| Interaction with a partially-corrupted `~/.claude/.skills-templates.json` (valid JSON, wrong shape) | v1 fallback chain only handles missing/unreadable manifest | A malformed-but-parseable manifest could mis-detect the deployed set |
