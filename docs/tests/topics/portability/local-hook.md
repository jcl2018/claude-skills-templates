# portability @ local-hook — the freshness-signal proofs

Realizes the [portability dream](../../../goals/portability.md)'s **freshness
signal** supporting guarantee: a machine that installed once must be nudged to
re-sync when a newer collection version ships, or it slowly diverges from the
repo. Proven in both modes — deterministic (the script emits the banner) and
agentic (an agent actually *surfaces* it) — at `local-hook` because the agentic
proof needs a machine with `claude` (keeping model spend out of CI).

## What runs here, and which property it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`portability-version-check`](../../infra/local-hook/portability-version-check.md) | deterministic | **Freshness signal** (script) | a stubbed `git ls-remote` + a `.source`-absent manifest → the script prints `SKILLS_UPGRADE_AVAILABLE <local> <remote>`. |
| [`portability-version-agentic`](../../infra/local-hook/portability-version-agentic.md) | agentic | **Freshness signal** (surfaced) | a cold agent runs the skill preamble in a stale sandbox and actually RELAYS the nudge (via `claude --print`). |

## How this layer achieves the dream

- **Deterministic: does the script fire?** `portability-version-check`
  (`tests/skills-update-check.test.sh`) is hermetic — no network, no real
  `~/.claude`. It stubs `git ls-remote --tags` with canned tags and asserts the
  full truth table: banner when remote > local; silent when equal, when remote <
  local (never a downgrade nudge), when `ls-remote` errors, and when there are no
  v-tags. This proves the *mechanism* emits the signal.
- **Agentic: does a human actually see it?** `portability-version-agentic`
  (`tests/portability-version-agentic.test.sh`) closes the "green-but-inert" blind
  spot the deterministic test can't see: a script can print a banner that an agent
  never relays. It builds a repo-neutral sandbox with a `git init --bare` upstream
  tagged `v<newer>`, drives the `skills-update-check` preamble through
  `claude --print`, and PASSes **iff the agent surfaces the nudge** — not merely
  that the banner text exists.

## How to run

```bash
# deterministic — always runnable, no model:
bash tests/skills-update-check.test.sh
/CJ_test_run portability-version-check

# agentic — LOCAL-ONLY; needs a machine with claude:
CJ_E2E_LOCAL=1 bash tests/portability-version-agentic.test.sh
/CJ_test_run --topic portability --e2e        # includes the agentic proof
```

## Why the agentic proof is local-only

`mode: agentic ⇒ tier: local-only`, so a default free `/CJ_test_run` and CI SKIP
it (exit 0, no `claude` call). It runs only under `--e2e`/`--all` on a machine
with a usable `claude` login. Under the **three-layer topic contract**
(`test-spec.sh --check-topic-contract`, `validate.sh` Check 30) an agentic row is
*advisory*, never required — agentic proofs run on-demand, so enrollment is not
gated on them. Portability declares its agentic row anyway (it earned the proof),
so the check prints no advisory note for it: if this row were ever dropped, the
gap would surface as a per-topic `note:` wherever the contract is read, while the
build stays green.
