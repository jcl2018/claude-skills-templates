# Test: `portability-version-agentic` (`infra` / `local-hook`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `portability-version-agentic` |
| Category | `infra` |
| Layer | `local-hook` |
| Mode | `agentic` |
| Command | `bash tests/portability-version-agentic.test.sh` |
| Tier | `local-only` |
| Topic | `portability` |

## What it is

The local AGENTIC proof of the deploy/install harness's version-notification — a repo-neutral sandbox + a bare upstream tagged v-newer drives the skills-update-check preamble through claude --print and asserts the agent SURFACES the upgrade nudge to a human (not merely that the banner text exists); portability's local-hook agentic level, closing the green-but-inert blind spot the deterministic version-check cannot see. Local-only (SKIPs clean without CJ_E2E_LOCAL=1 + a claude login), so CI never spends a model.

## How to run

This is a `local-only` agentic test — it SKIPs cleanly (exit 0, no model spend)
unless you run it locally with a usable claude login:

```bash
CJ_E2E_LOCAL=1 bash tests/portability-version-agentic.test.sh
```

Run via the category contract (the `local-only` tier means you must pass
`--e2e` or `--all`, or a default free run SKIPs it):

```bash
/CJ_test_run portability-version-agentic --e2e   # this single test
/CJ_test_run --topic portability --e2e           # every portability-topic test
/CJ_test_run --layer local-hook --e2e            # every local-hook test
```

Without `CJ_E2E_LOCAL=1` (or without `claude` + a verified login + `gh`) the test
prints a `SKIP:` line and exits 0, so `scripts/test.sh` and CI never touch a model.

## Explanation

This test is portability's **local-hook + agentic level** — the counterpart to the
deterministic [`portability-version-check`](portability-version-check.md). The
deterministic test proves the *script* (`scripts/skills-update-check`) emits the
`SKILLS_UPGRADE_AVAILABLE` banner; this test proves an **agent** running the skill
preamble in a stale install actually **surfaces** that nudge to a human. A stubbed
test passing green while the real behavior is inert is exactly the blind spot the
agentic layer closes.

When run locally with a login, it builds a repo-**neutral** sandbox (a
`.source`-absent manifest via `scripts/lib/agentic-sandbox.sh`) plus a
`git init --bare` upstream tagged `v<newer>`, points `skills-update-check` at it via
the documented `SKILLS_UPDATE_REMOTE_URL` seam (no PATH-prepended `git` shim), drives
the update-check preamble through `claude --print` (JSON output, budget `$0.50`), and
extracts a `{surfaced_nudge, evidence}` verdict — PASS iff the agent relays the
upgrade nudge, not merely that the banner text exists. Because `mode: agentic ⇒
tier: local-only`, the row is present in CI but never executed there; the per-PR
hard Check (`test-spec.sh --check-topic-contract`) proves this coverage point is
DECLARED, while `/CJ_test_run --e2e` proves the BEHAVIOR, local-only.

For the per-unit breakdown of the `skills-update-check` regression this drives, see
the [test family doc](../../../test.md).
