# Test: `tag-release` (`regression` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `tag-release` |
| Category | `regression` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/regression/CI-push/tag-release.test.sh` |
| Tier | `free` |

## What it is

The post-land release-tag drill: the tag-release helper publishes the v<VERSION> tag to a hermetic local bare origin — created + pushed, idempotent on re-run, --version override honored, non-semver rejected, and the strict-fails vs default-fail-softs push-failure split — guarding the once-inert version notification whose ls-remote tag compare starved when the land flow bumped VERSION without ever tagging.

## How to run

```bash
bash tests/regression/CI-push/tag-release.test.sh
```

Run via the category contract: `/CJ_test_run tag-release` (single test),
`/CJ_test_run --category regression` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This regression test exists because the workbench once shipped a version
notification that could never fire: the land flow bumped `VERSION` and the
changelog on every ship but never published a matching `v<VERSION>` git tag, so
the update-check's `git ls-remote --tags` comparison read a years-stale newest
tag and stayed silent forever — a green-but-inert release pipeline. The fix
added the tag-publish helper to the post-land sync, and this drill keeps that
fix honest: against a hermetic local bare origin (no network), it asserts the
tag is created and pushed, that a re-run is an idempotent no-op, that a version
override is honored, that a non-semver version is rejected with a non-zero
exit, and that a push failure fail-softs by default but hard-fails under the
strict flag. It runs per-PR as part of the full suite (`scripts/test.sh`
invokes it), model-free.

It is also the declared proof of the release-tag-inertness row in the
defect-coverage ledger (`spec/test-spec-custom.md`, `defect_coverage:`), so
removing or unwiring it fails the ledger check rather than rotting silently.
The per-unit breakdown behind this front door lives on the
[test-family units-detail page](../../test.md); the whole catalog is at
[docs/test-catalog.md](../../../test-catalog.md).
