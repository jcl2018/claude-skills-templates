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

On the LIVE path it prints a **detailed report** (T000057) — a delimited `AGENTIC-DETAIL BEGIN … END` block showing the cold agent's full exchange: the EXACT prompt sent to `claude --print`, the raw claude response JSON, and the extracted `{surfaced_nudge, evidence}` verdict — alongside the one-line `PASS:`/`FAIL:` summary. Run via `/CJ_test_run`, that block is folded into the materialized report (`tests/test-run/reports/<ts>.md`). The SKIP path emits nothing extra.

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
the update-check preamble through `claude --print` (JSON output, `--model sonnet`, budget `$1.00`), and
extracts a `{surfaced_nudge, evidence}` verdict — PASS iff the agent relays the
upgrade nudge, not merely that the banner text exists. Because `mode: agentic ⇒
tier: local-only`, the row is present in CI but never executed there; the per-PR
hard Check (`test-spec.sh --check-topic-contract`) proves this coverage point is
DECLARED, while `/CJ_test_run --e2e` proves the BEHAVIOR, local-only.

**Detailed report (T000057).** So the run is inspectable rather than a black-box
`PASS`, the live path surfaces the cold agent's full exchange. `run_preamble_via_claude`
takes an optional 6th `prompt-out-path` argument and writes the EXACT prompt it sends
to `claude --print` there (a byte-identical copy — it never alters the payload); the
test captures that file and prints an `AGENTIC-DETAIL BEGIN … END` block containing the
prompt (verbatim), the raw claude response JSON, and the extracted verdict. When the
test runs via `/CJ_test_run` (e.g. `--topic portability --e2e`), `scripts/test-run.sh`
folds that block into the materialized report under a `## Agentic detail` heading via a
marker-keyed passthrough (`_cm_extract_detail`) that leaves non-agentic tests
untouched. The SKIP path returns before the block, so a skipped run stays clean with no
model spend. The plumbing is regression-tested hermetically (no model) by
`tests/portability-version-agentic-detail.test.sh` (the `test-portability-version-agentic-detail`
unit — see the [test family doc](../../../test.md)).

For the per-unit breakdown of the `skills-update-check` regression this drives, see
the [test family doc](../../../test.md).
