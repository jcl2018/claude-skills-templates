# Test: `portability-version-check` (`infra` / `local-hook`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `portability-version-check` |
| Category | `infra` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash tests/skills-update-check.test.sh` |
| Tier | `free` |

## What it is

The local sandbox check of the deploy/install harness's version-notification — a stubbed git ls-remote + a .source-absent manifest proving skills-update-check nudges when a newer release is published; portability's local-hook level (deterministic fill; the agentic model-surfaced-prompt variant is deferred).

## How to run

```bash
bash tests/skills-update-check.test.sh
```

Run via the category contract: `/CJ_test_run portability-version-check` (single test),
`/CJ_test_run --category infra` (the whole category), or
`/CJ_test_run --layer local-hook` (the whole layer).

## Explanation

This test is portability's **local-hook level**: a quick, local proof that the
deploy/install harness's version-notification (`scripts/skills-update-check`)
correctly nudges an operator when a newer release is published. It runs the
`skills-update-check` unit test, which stubs `git ls-remote` on PATH and points the
script at a `.source`-absent manifest, then asserts the `SKILLS_UPGRADE_AVAILABLE`
banner fires when the remote tag is newer, stays silent when equal/older, and
fail-softs silently when the remote is unreachable — all with no real network. It
is an `infra` test (standing verification of the deploy/install harness, the same
harness `portability-smoke` / `portability-deploy` cover at the other layers) filled
DETERMINISTICALLY; the canonical "quick agentic" local-hook variant (a real
`claude --print` skill preamble in a stale sandbox asserting the model surfaces the
nudge) is a deferred follow-up.

For the per-unit breakdown of the `skills-update-check` regression this drives, see
the [test family doc](../../../test.md).
