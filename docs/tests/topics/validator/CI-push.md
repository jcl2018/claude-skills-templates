# validator @ CI-push — the per-PR merge signal

Realizes the [validator dream](../../../goals/validator.md)'s **every-boundary
firing** property at the push/PR boundary: no PR merges while the tree is
structurally broken.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`validate`](../../infra/CI-push/validate.md) | deterministic | **Whole-contract coverage, per PR** | `.github/workflows/validate.yml` runs `bash scripts/validate.sh` on every push/PR; any ERROR fails the check and blocks the merge. |

## How this layer achieves the dream

CI-push is the *gating* boundary: whatever the hook or a local run missed, this
run stops at the PR. It executes the full check battery — catalog ⇔ filesystem,
the doc contract (declared-exists / orphans / no work-item IDs in human docs),
the test contract (coverage cross-check, topic contract, topic docs), and the
generated-surface freshness diffs (README, test catalog, workflow docs) — on a
clean runner, so "works on my machine" drift cannot merge.

## How to run

```bash
bash scripts/validate.sh          # the exact command CI runs
/CJ_test_run validate
/CJ_test_run --topic validator
```

For the per-check breakdown, see the [validate family doc](../../validate.md).
