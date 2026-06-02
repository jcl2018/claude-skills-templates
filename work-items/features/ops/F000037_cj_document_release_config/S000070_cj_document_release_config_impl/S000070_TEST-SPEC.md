---
type: test-spec
parent: S000070
feature: F000037
title: "Per-repo cj-document-release.json strict-required config — Test Specification"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | R1-R5, R11 | JSON exists at repo root + helper exists+executable + all 4 helper subcommands behave correctly | The new config + helper machinery is structurally complete | `bash tests/cj-document-release.test.sh` (asserts: cj-document-release.json exists at repo root; scripts/cj-document-release-config.sh exists + executable; `--validate` exits 0; `--parse` returns valid JSON with schema_version/whitelist_patterns/categories keys; `--expand-whitelist` returns ≥6 lines; `--resolve readme` returns `README.md`; `--resolve nonexistent-category` exits 1 + emits `[doc-sync-no-config]`; SKILL.md mentions cj-document-release.json) |
| S2 | core | R12 | Workbench's own cj-document-release.json passes content assertions | The seed JSON is well-formed and matches F000036-compat semantics | `bash tests/cj-document-release-config.test.sh` (asserts: valid JSON; schema_version=1; whitelist_patterns non-empty string array; categories non-empty object; each category value is non-empty array of strings; category names match `^[a-z][a-z0-9-]*$`; all 6 F000036-compat tokens present: readme/changelog/claude/architecture/philosophy/skill-catalog) |
| S3 | core | R6, R8 | CJ_document-release SKILL.md no longer contains hardcoded whitelist regex; all 3 cj_goal SKILL.md halt-taxonomy tables contain `[doc-sync-no-config]` row in correct position | The skill rewrite landed + halt-taxonomy is symmetric across the cj_goal family | `! grep -E "^.{0,50}\^\(README\\\|CHANGELOG\\\|CLAUDE\\\|ARCHITECTURE\)" skills/CJ_document-release/SKILL.md && grep -q '\[doc-sync-no-config\]' skills/CJ_goal_feature/SKILL.md && grep -q '\[doc-sync-no-config\]' skills/CJ_goal_defect/SKILL.md && grep -q '\[doc-sync-no-config\]' skills/CJ_goal_todo_fix/SKILL.md && grep -q 'cj-document-release\.json' skills/CJ_document-release/SKILL.md` |
| S4 | resilience | R10, R15 | validate.sh + test.sh green on PR HEAD; Check 16 PASSes on bundled JSON | No regressions; new check integrates cleanly with the existing 15 checks | `./scripts/validate.sh && ./scripts/test.sh` (both exit 0; validate.sh output explicitly names `Check 16: cj-document-release.json schema` as PASS) |
| S5 | core | R14, R16, R17 | CLAUDE.md has new convention section; VERSION = 6.0.2; CHANGELOG has [6.0.2] entry | Ancillary artifacts wired | `grep -q '^## cj-document-release\.json convention' CLAUDE.md && grep -q '^6\.0\.2' VERSION && grep -q '^## \[6\.0\.2\]' CHANGELOG.md` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section below).
-->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | R6, R7 | Operator reads rewritten SKILL.md + USAGE.md and understands the config-driven shape | Open `skills/CJ_document-release/SKILL.md`. Read top-to-bottom. Open `USAGE.md`. Read the 5 sections including the new "Per-repo config" subsection and the new `[doc-sync-no-config]` pitfall. | A new operator who hasn't seen F000037 can answer: "Where does the doc-only whitelist come from now? What happens if I don't author a cj-document-release.json? How do I add a new category for `--docs <newtoken>`?" | PASS if all three questions answered correctly from SKILL.md + USAGE.md alone. FAIL if any answer requires reading CLAUDE.md, the helper script, or this TEST-SPEC. |
| E2 | core | R8, R9 | Diff review: 3-way symmetric edits across cj_goal_feature/defect/todo_fix | `git diff main...HEAD -- skills/CJ_goal_{feature,defect,todo_fix}/SKILL.md skills/CJ_goal_{feature,defect,todo_fix}/USAGE.md` | The new `[doc-sync-no-config]` row is byte-for-byte identical across all 3 SKILL.md halt-taxonomy tables (positioned between doc-sync-red and doc-sync-non-doc-write). All 3 USAGE.md files have `last-updated` bumped to the same ISO-8601 timestamp. | PASS if diff confirms symmetry. FAIL if any cj_goal SKILL.md has a divergent halt-taxonomy row (different halt class, different marker text, wrong position) or any USAGE.md is missing the timestamp bump. |
| E3 | resilience | R10, R15 | Walk the full pipeline locally: validate.sh + test.sh + version queue check | `./scripts/check-version-queue.sh; ./scripts/validate.sh; ./scripts/test.sh` | check-version-queue.sh confirms 6.0.2 slot is free. validate.sh exits 0 with 0 errors / 0 warnings; output names `Check 16: cj-document-release.json schema` as PASS. test.sh exits 0; both new/extended test files run and PASS. | PASS if all three commands exit 0 + validate.sh explicitly names Check 16 + Check 13/14/15 still PASS for CJ_document-release (audit set still = 12 routable skills). FAIL if any check fails, Check 16 silently skips, or audit-set count regresses. |
| E4 | core post-ship | R4, R5 | Live dogfood A: `/CJ_document-release --docs readme` from a feature branch with a stale README | After this PR merges + next feature branch: `git checkout -b feat-test-docconfig`; touch a code file referenced in README; commit; `/CJ_document-release --docs readme`; observe behavior. | Skill runs: (a) Step 0.5 reads config via helper `--parse`; (b) Step 4 resolves `readme` → `README.md` via helper `--resolve`; (c) project-context block passes `audit_files=["README.md"]` to upstream `/document-release`; (d) if README needs updating → auto-commit "docs: post-build sync via CJ_document-release"; (e) success summary printed. | PASS if the skill respects `--docs readme` filter best-effort + auto-commits doc-only changes + prints success summary. PASS even if `/document-release` audits other docs too (best-effort filter, per F000036 precedent). FAIL if skill emits a halt marker without cause, modifies non-doc files, or skips README. |
| E5 | core post-ship | R5 | Live dogfood B: temporarily rename JSON → `.bak`, verify `[doc-sync-no-config]` halt | After this PR merges + a feature branch: `mv cj-document-release.json cj-document-release.json.bak`; invoke `/CJ_document-release` (no args); observe behavior. Then `mv cj-document-release.json.bak cj-document-release.json`; re-invoke; observe behavior. | First invocation: helper exit 1; `[doc-sync-no-config]` halt marker emitted; orchestrator (if invoked from /CJ_goal_*) HALTs with `halted_at_doc_sync_no_config` and writes journal entry naming resume_cmd. Second invocation: helper exit 0; skill runs to green; success summary printed. | PASS if both invocations produce the expected outcomes (halt on missing, green on present). FAIL if the strict-required posture leaks (skill falls back to F000036's hardcoded defaults) OR the halt marker is missing/wrong shape. |

<!-- If an E2E test skill exists for this feature, reference it here:
     N/A — manual smoke + live dogfood post-merge. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether downstream (non-workbench) repos can adopt `/CJ_document-release` by authoring their own cj-document-release.json | Requires a non-workbench target repo to test; live dogfood post-merge | Mitigation = the helper script + JSON schema are designed to be portable. The portability flip (`workbench` → `standalone`) is gated on at least one successful downstream adoption; that adoption attempt IS the validation. |
| Bash globstar edge cases with dotfiles (e.g. `**/.md` matching `.github/...`) | Workbench seed doesn't use patterns that would hit this; risk is downstream-repo-specific | Mitigation = helper uses `nullglob` (not `dotglob`); dotfiles excluded by default — matches operator intent. If downstream needs dotfile matching, that's a v2 schema feature (`include_dotfiles: true`). |
| Real cron-mode `/CJ_goal_todo_fix --quiet` interaction with `[doc-sync-no-config]` halt | Manual smoke required (cron scheduling); not feasible in unit tests | Mitigation = SKILL.md and CLAUDE.md prose documents that `--quiet` doesn't suppress halt-on-config-missing (same posture as halt-on-red per F000036). Operator reads halt journal at convenience. |
| Behavior when `cj-document-release.json` is a symlink to a file outside the repo | Out of scope for v1 (unusual setup); helper resolves via `$REPO_ROOT/cj-document-release.json` directly | Mitigation = if the symlink target exists and is valid JSON, helper passes; if not, halt-emit naturally. No special-casing needed. |
| Race condition: helper invoked while operator is mid-edit of cj-document-release.json | Out of scope; helper reads file once at invocation; partial-write semantics depend on filesystem | Mitigation = `jq empty` catches partially-written invalid JSON; helper halt-emits naturally. Re-invoke after edit completes. |
| Validate.sh Check 16 behavior when `cj-document-release.json` exists but `scripts/cj-document-release-config.sh` is missing | Edge case: someone deleted the helper but kept the JSON. The cross-check step in Check 16 would skip (per `[ -x scripts/... ]` guard) | Mitigation = the inline jq-based checks still fire; the missing helper is a separate orthogonal bug (script removed by accident). validate.sh doesn't try to "fix" this; operator restores the helper. |
| Whether `[doc-sync-no-config]` halt journal entries are machine-readable (telemetry consumers can parse them) | v1 follows F000027 halt-marker shape; JSON shape not yet schematized | Mitigation = same shape as F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]` entries; analytics layer reads via line-anchored parse. Schema tightening is a separate follow-up. |
| Whether the JSON schema upgrade (v1 → v2) has a smooth migration path | v2 doesn't exist yet; migration plan is "v1 readers refuse v2 with `[doc-sync-no-config] schema_version=2 unsupported`" | Mitigation = explicit unsupported-version error tells operators what to do. When v2 ships, a migration script can be added; in v1 we just guard against forward-incompat. |
| Whether multiple cj-document-release.json files in nested repos (e.g., a monorepo with subpackages) work | Helper hardcodes `$(git rev-parse --show-toplevel)/cj-document-release.json`; doesn't scan subdirs | Mitigation = workbench is single-repo; monorepo support is multi-repo federation (deferred). |
| Whether the `--docs <token>` resolution handles comma-lists (`--docs readme,changelog`) | F000036 parses comma-lists; F000037's helper currently takes ONE token per `--resolve` invocation. The SKILL.md prose may invoke `--resolve` multiple times for a comma-list | Mitigation = SKILL.md prose handles the comma-list parsing (split on `,`); each token resolves independently via helper. Helper stays single-token; composition happens in SKILL.md. |
| Whether `scripts/test.sh` runs `tests/cj-document-release-config.test.sh` in isolation (no dependency on tests/cj-document-release.test.sh ordering) | Both test files run in the same phase; ordering isn't load-bearing | Mitigation = each test file is self-contained (sources workbench root, runs assertions, exits with status). Order-independent. |
