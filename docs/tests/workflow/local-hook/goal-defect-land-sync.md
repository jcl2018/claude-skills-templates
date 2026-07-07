# Test: `goal-defect-land-sync` (`workflow` / `local-hook`)

> **Topic:** [goal-defect](../../topics/goal-defect/index.md) · **Goal:**
> [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
> **Layer view:** [local-hook](../../topics/goal-defect/local-hook.md).
> This test proves the defect verb's post-land sync tail, deterministically.

| Field | Value |
|-------|-------|
| Name | `goal-defect-land-sync` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash tests/post-land-sync.test.sh` |
| Tier | `free` |

## What it is

The post-land-sync suite: `scripts/post-land-sync.sh` — the helper the defect
verb's land tail runs after `gh pr merge` to pull + reinstall the merged skills
locally — proven against a temp fixture manifest whose `.source` is a
throwaway git repo. `--dry-run` resolves `.source`, prints the would-run
`git pull --ff-only` + `skills-deploy install` commands, and mutates nothing;
each guard (missing `.source`, not a git repo, off-`main`, dirty tracked tree)
refuses with a named message; untracked-only files never trip the dirty guard.
The real `~/.claude` is never read or written.

## How to run

```bash
bash tests/post-land-sync.test.sh
# via the contract:
/CJ_test_run goal-defect-land-sync
/CJ_test_run --category workflow
/CJ_test_run --layer local-hook
```

## Explanation

This is the `goal-defect` topic's **local-hook deterministic** point: the
defect verb is a LANDING verb — its run ends with `/land-and-deploy` plus this
repo's post-land sync, so the sync helper's guards and preview ARE the verb's
last deterministic mile. A quick, zero-model-spend check a maintainer runs on
demand before land-tail changes leave the machine (it also runs per-PR inside
the full suite; a `local-hook` row's `layer` is descriptive placement). It
reuses the existing deterministic test of the land tail rather than adding a
new harness — zero new maintenance, per the topic's deterministic-only
enrollment posture (see the [dream doc](../../../goals/goal-defect.md)). The
same helper is also previewed inside the composed
[`goal-defect-chain`](../CI-nightly/goal-defect-chain.md) drill nightly.

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
