---
type: test-spec
parent: S000099
feature: F000057
title: "Relocate the spec-registry family to spec/ with a back-compat helper fallback — Test Specification"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. The 7 mandated assertions from the design's reviewer
     must-fixes are split: scriptable/deterministic ones are Smoke; the
     manual-judgment ones (adversarial stale-ref sweep, the root-only temp-repo
     scenario) are E2E. The soft cap of 5 rows/tier is intentionally exceeded —
     the reviewer must-fixes A–G require each assertion; the validator emits an
     [INFO] advisory only, not a violation. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core resilience | AC-2 | All 3 helpers `--validate` green from the repo (resolving `spec/`) | The relocated registries parse correctly via the spec/-first resolution | `scripts/doc-spec.sh --validate && scripts/gate-spec.sh --validate && scripts/permission-policy.sh --validate` |
| S2 | resilience observability | AC-4, AC-7 | validate.sh Checks 16/19/20/21/22 print `PASS:` NOT `SKIP:` after the move, AND the new `spec/*.md` orphan scan is green (no false missing/orphan) | The silent-SKIP regression did not occur — no literal-root guard disabled a check — and the new spec/ declared⇔on-disk orphan scan passes | `scripts/validate.sh 2>&1 \| grep -E 'Check (16\|19\|20\|21\|22)' \| grep -q SKIP && echo FAIL \|\| echo PASS` (and `scripts/validate.sh` exits 0/0, incl. the spec/ orphan scan) |
| S3 | core resilience | AC-5, AC-7 | `scripts/test.sh` green including S94 (permission-policy), S96 (gate-spec), AND the zzz-scaffold integration fixture exercising the new `spec/*.md` orphan scan | The hard-FAIL class stayed green — test.sh path-gating callers learned spec/-then-root — and the standing zzz-mirror blind spot is covered | `scripts/test.sh` |
| S4 | core | AC-5 | Seed test #13 green (doc-spec seed byte-identity; seed unchanged) | The portable seed stayed root-style → consumer convention + test #13 untouched | `scripts/test.sh 2>&1 \| grep -E 'seed.*(#13\|byte-identit)' \| grep -qi pass` (or the named seed case in `tests/cj-document-release-config.test.sh`) |
| S5 | resilience security | AC-2 | `PERMISSION_POLICY_PATH=/nonexistent … --validate` still FAILS (env-override outermost) | The env override wins over the spec/root fallback; the regression guard at test.sh:113 holds | `PERMISSION_POLICY_PATH=/nonexistent scripts/permission-policy.sh --validate; [ $? -ne 0 ] && echo PASS \|\| echo FAIL` |
| S6 | core resilience | AC-1, AC-3, AC-10 | The 3 files are under `spec/`, gone from root; registry self-declares `spec/<name>.md`; root `*.md` = the 5 expected — all co-present at the single validated commit (the lockstep landing) | Relocation + registry self-paths landed together in one commit; Check 17 root allowlist correct; validate.sh green at HEAD proves no transient orphan/missing split | `for f in doc-spec gate-spec permission-policy; do [ -f spec/$f.md ] && [ ! -f $f.md ]; done && ls *.md && scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | resilience | AC-2 | A root-only fallback repo (the knowledge-base consumer shape) still resolves | Create a temp repo with `doc-spec.md` at root and NO `spec/` dir; run `scripts/doc-spec.sh --validate` against it (point the helper at the temp's root) | The helper resolves the root `doc-spec.md` via the fallback and validates green | PASS if it resolves + validates the root file with no spec/ present; FAIL if it errors / can't find the registry |
| E2 | usability | AC-9 | No stale root-path reference to the 3 files remains anywhere (adversarial completeness sweep) | After the diff is ready, grep the whole tree for `\b(doc-spec\|gate-spec\|permission-policy)\.md` references and inspect each hit; confirm each is either a `spec/<name>.md` path, an intentionally-root-style seed/consumer reference, or non-path prose | Zero stale root-PATH references to the 3 files; the only root-style refs are the intentional seed/`_emit_seed`/consumer-convention ones | PASS if every hit is accounted for (spec/ path or documented-intentional-root); FAIL if any stale root path to the 3 files survives |
| E3 | core | AC-6 | CJ_document-release does not re-create a duplicate root `doc-spec.md` | In this repo (spec/doc-spec.md present, no root copy), run the CJ_document-release self-bootstrap path | The guard READs spec/-then-root, finds the existing spec/ file, and does NOT write/commit a duplicate root `doc-spec.md` | PASS if no duplicate root `doc-spec.md` is created; FAIL if a spurious root copy appears |
| E4 | integration | AC-8 | Generated views regenerated + reference `spec/doc-spec.md`; Check 23 in sync | Regenerate the views (`generate-doc-views.sh`), inspect `docs/doc-general.md` + `docs/doc-custom.md` headers/rows, run validate.sh Check 23 | Views say "generated from the `spec/doc-spec.md` registry", custom rows show `spec/` paths, Check 23 green (no diff) | PASS if header + rows reference spec/ AND Check 23 is in sync; FAIL on a stale header or a Check 23 diff |

<!-- No dedicated E2E test skill for this feature. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The real knowledge-base repo (live external consumer) | Out of this repo's CI scope; the E1 root-only temp repo proves the fallback shape that the knowledge-base relies on | A knowledge-base-specific quirk beyond "root `doc-spec.md` resolves" would be missed — low risk; the consumer convention is unchanged by construction |
| `--expand-whitelist` exhaustive enumeration | Asserted indirectly via Check 23 (views in sync) + S6 (registry self-paths); a dedicated whitelist-diff row would be redundant | A whitelist entry missing a relocated path could slip; low risk — the doc-only auto-commit path is exercised by CJ_document-release's own tests |
| Windows Git-Bash path resolution of the spec/ fallback | The windows-latest CI job runs the full suite (incl. S1/S2/S3); a story-local Windows-only row would duplicate it | A POSIX-vs-Git-Bash `[ -f ]` divergence on the new path — low risk; the idiom is plain POSIX and CI gates it |
