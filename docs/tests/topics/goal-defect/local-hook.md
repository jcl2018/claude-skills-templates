# goal-defect @ local-hook — the land-tail safety proof

**Dream:** [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The defect verb is a LANDING verb: its run ends past the merge, with
`scripts/post-land-sync.sh` pulling the merged trunk and reinstalling the
skills into the operator's live `~/.claude`. That helper's guards are the last
deterministic mile between a remote merge and the live install — the local-hook
deterministic point is
[`goal-defect-land-sync`](../../workflow/local-hook/goal-defect-land-sync.md)
(`bash tests/post-land-sync.test.sh`):

- `--dry-run` resolves the fixture `.source`, prints the would-run
  `git pull --ff-only` + `skills-deploy install`, and mutates NOTHING;
- each guard refuses with a named message — a missing `.source`, a non-repo, an
  off-`main` checkout, a dirty TRACKED tree;
- untracked-only files never trip the dirty guard;
- the real `~/.claude` manifest is never read or written (a
  `POST_LAND_SYNC_MANIFEST` temp fixture stands in).

Zero model spend, runnable on demand before land-tail changes leave the machine
(it also rides the per-PR full suite — `layer` placement is descriptive).

## The deterministic-only note

Under the both-modes contract this layer would ALSO require an agentic proof.
This topic is enrolled **deterministic-only**, and the defect verb declares no
agentic row at all — its on-disk eval case stays undeclared by choice (see the
[dream doc](../../../goals/goal-defect.md)'s posture section). The
deterministic smoke + chain + this land-tail proof are the accepted proxy for
the verb's agent-executed prose.

## Run it

```bash
bash tests/post-land-sync.test.sh
/CJ_test_run goal-defect-land-sync
```
