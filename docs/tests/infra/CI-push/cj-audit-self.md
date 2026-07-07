# Test: `cj-audit-self` (`infra` / `CI-push`)

| Field | Value |
|-------|-------|
| Name | `cj-audit-self` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/cj-audit-skills.test.sh` |
| Tier | `free` |

## What it is

The self-test of the **audit-skills surface** — `tests/cj-audit-skills.test.sh`,
which proves the deterministic helpers shared by the `/CJ_doc_audit` and
`/CJ_test_audit` engines behave. It is the `categories:` promotion of the
existing `test-cj-audit-skills` units-row, making "the audit tooling tests
itself" a first-class verification surface.

## How to run

```bash
bash tests/cj-audit-skills.test.sh
# via the category contract:
/CJ_test_run cj-audit-self
/CJ_test_run --category infra      # the whole category
/CJ_test_run --layer CI-push       # the whole layer
```

## Explanation

The audit verbs are the standalone-in-any-repo doc/test drift detectors; their
deterministic Stage-1 helpers are what a maintainer relies on to trust an audit
report. If those helpers regressed, the audit would report clean while the repo
drifted — a silent false-negative. This suite guards that surface on every PR,
deterministically (no `claude --print`, no model spend). For the per-unit
breakdown of what the `test` family asserts, see the
[test family doc](../../test.md) and the catalog at
[docs/test-catalog.md](../../../test-catalog.md).
