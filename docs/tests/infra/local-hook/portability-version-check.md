# Test: `portability-version-check` (`infra` / `local-hook`)

> **Topic:** [portability](../../topics/portability/index.md) · **Goal:**
> [another machine gets the same skills](../../../goals/portability.md) ·
> **Layer view:** [local-hook](../../topics/portability/local-hook.md).
> This test achieves the **freshness-signal** guarantee (deterministic half): the
> script emits the upgrade banner.

| Field | Value |
|-------|-------|
| Name | `portability-version-check` |
| Category | `infra` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash tests/skills-update-check.test.sh` |
| Tier | `free` |

## What it is

A hermetic regression for `scripts/skills-update-check`'s checkout-independent
version notification. It NEVER touches the real `~/.claude` and NEVER hits the
network: it stubs `git ls-remote --tags` with canned tags, points state at a
throwaway dir, and drives a `.source`-absent manifest (the remote-machine /
consumer shape). It proves the *mechanism* that keeps an installed machine from
drifting away from the repo actually fires.

## What it proves

| Case | Assertion | Achieves |
|------|-----------|----------|
| **Banner** | remote (max v-tag) > local, `.source` absent → prints `SKILLS_UPGRADE_AVAILABLE <local> <remote>` | Freshness signal fires |
| **Max-tag** | the highest 3-digit v-tag wins; a peeled `^{}` ref is ignored | Correct target version |
| **Silent (equal)** | remote `==` local → no output, exit 0 | No false nudge |
| **Silent (downgrade)** | remote `<` local → no output, exit 0 | Never a downgrade nudge |
| **Fail-soft** | `ls-remote` errors, or no v-tags exist → no output, exit 0 | Robust (never crashes a skill preamble) |
| **Override / normalize** | `SKILLS_UPDATE_REMOTE_URL` wins with no `upstream_url`; an ssh-form URL is normalized to https | Works on a fresh consumer clone |

## How to run

```bash
bash tests/skills-update-check.test.sh       # hermetic — no network, no real ~/.claude
# via the contract:
/CJ_test_run portability-version-check
/CJ_test_run --layer local-hook
```

## Explanation

The [dream](../../../goals/portability.md) decays over time if a machine that
installed once is never told to re-sync — so the **freshness signal** is a
supporting guarantee the goal depends on. This test proves the deterministic half:
the `skills-update-check` script, run from a stale checkout-independent install,
correctly emits the upgrade banner *and* stays silent (and fail-soft) in every case
where it should. Its agentic sibling —
[`portability-version-agentic`](portability-version-agentic.md) — proves the *other*
half: that an agent running the skill preamble actually *surfaces* the nudge to a
human, closing the green-but-inert blind spot a script-only test cannot see.

For the per-unit breakdown of the `skills-update-check` regression this drives, see
the [test family doc](../../test.md); for the layer-level "how" and why the agentic
proof is local-only, see
[portability @ local-hook](../../topics/portability/local-hook.md).
