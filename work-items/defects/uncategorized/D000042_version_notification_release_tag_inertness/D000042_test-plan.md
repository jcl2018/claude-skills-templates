---
type: test-plan
parent: D000042
title: "Version-notification release-tag inertness — regression test plan"
date: "2026-07-05"
author: "/CJ_goal_defect"
status: Draft
---

<!-- Scope: ONE fix (defect D000042). Cases are regression cases for the specific bug —
     the release/land flow never published a v<VERSION> tag, so the upgrade nudge was
     permanently inert. Each row proves the defect stays fixed; all are runnable from a
     script / CI (hermetic, no network). -->

## Scope

The fix adds the missing release-tag producer and wires it into the land flow:

- `scripts/tag-release.sh` (new) — publishes `v<VERSION>` to origin at land if absent;
  idempotent + fail-soft; `--strict`/`--version`/`--dry-run`/`--remote`/`--ref` flags.
- `scripts/post-land-sync.sh` (modified) — invokes `tag-release.sh` fail-soft after
  `skills-deploy install`; surfaced in the `--dry-run` plan + header docstring.
- `tests/tag-release.test.sh` (new) — hermetic 9-assert regression (local bare origin).
- `spec/test-spec-custom.md` + `scripts/test.sh` (modified) — register + wire the test.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `tag-release.sh` publishes `v<VERSION>` to origin when absent | `bash tests/tag-release.test.sh` (assert #3) | The `v<VERSION>` tag now exists on the (hermetic bare) origin; RESULT: PASS | Pass |
| 2 | Idempotent — no-op when the tag already exists | `bash tests/tag-release.test.sh` (assert #4) | Second run is a no-op, exit 0, no duplicate/force-push | Pass |
| 3 | Fail-soft — a push failure never halts a land | `bash tests/tag-release.test.sh` (asserts #8/#9) | `--strict` → non-zero (rc 2); default → WARN + exit 0 | Pass |
| 4 | Bad invocation guarded | `bash tests/tag-release.test.sh` (assert #7) | Non-semver VERSION → exit 1, nothing pushed | Pass |
| 5 | `post-land-sync.sh` surfaces + invokes the step | `bash scripts/post-land-sync.sh --dry-run` | Plan prints `would run: …/tag-release.sh (publish v<VERSION> to origin if absent)` | Pass |

## Verification Steps

<!-- How the fix was verified beyond the regression rows above (deterministic, no network). -->

- [ ] Local build succeeds (Windows/Linux) — `bash tests/tag-release.test.sh` → RESULT: PASS (9/9)
- [ ] Registry valid — `bash scripts/test-spec.sh --validate` → `OK schema_version=1`
- [ ] New unit anchored — `bash scripts/test-spec.sh --check-coverage` → `findings=0` (the `test-tag-release` forward anchor resolves)
- [ ] Catalog fresh — `bash scripts/test-spec.sh --render-docs --check` → in sync (Check 26)
- [ ] Lint clean — `shellcheck scripts/tag-release.sh scripts/post-land-sync.sh tests/tag-release.test.sh`
- [ ] Manual reproduction confirms fix — `post-land-sync.sh --dry-run` shows the new tag-release plan line

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| Windows 10 (Git-Bash) | branch `cj-def-20260705-101333-1358` | Pass (9/9 asserts; hermetic local bare origin, no network) |

<!-- Coverage gaps (risks accepted):
     - A real push to the real origin: the hermetic test uses a local `git init --bare`
       fake origin (no network / no real remote mutation). The real one-time backfill of
       `v6.0.119` is an operator-gated operational step, verified by hand.
     - Live `git ls-remote` catching a future re-inertness: deferred to the F000082
       follow-up (c) portability smoke (nightly/on-demand, never per-PR). A future
       producer regression would surface via that smoke, not per-PR. -->
