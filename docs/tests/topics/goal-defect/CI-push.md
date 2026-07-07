# goal-defect @ CI-push — the fast per-PR shape proof

**Dream:** [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

Every PR must prove the defect verb's deterministic plumbing SHAPE still holds
before it merges — cheaply. The per-PR point is
[`goal-defect-smoke`](../../workflow/CI-push/goal-defect-smoke.md)
(`bash tests/cj-goal-defect-smoke.test.sh`), the mirror of the feature-path
smoke, probing each seam in isolation with `--dry-run`:

- **worktree entry** — `cj-worktree-init.sh --caller defect` mints a
  `cj-def-*` branch, `state=created`;
- **shared phases** — `cj-goal-common.sh --phase worktree|ship|telemetry
  --mode defect` each answer their documented `KEY=VALUE` contract (the
  telemetry receipt carries `mode=defect`);
- **leaf targets** — the `CJ_qa-work-item` + `CJ_document-release` `SKILL.md`s
  the pipeline dispatches exist on disk (the gstack `/investigate` / `/ship` /
  `/land-and-deploy` tails are deliberately not asserted — a bare CI checkout
  does not have them).

Before this point existed, the defect verb had NO per-PR deterministic proof at
all — this smoke is what closed that gap.

## What this layer does NOT prove

Composition through the LAND tail (D-ID claim, recap pair, land-sync preview)
waits for the [CI-nightly chain drill](CI-nightly.md); the land-tail guards
live at [local-hook](local-hook.md); the agent-executed pipeline prose —
including the root-cause iron-law gate — has no required proof at any layer
(the deterministic-only posture — see the dream doc).

## Run it

```bash
bash tests/cj-goal-defect-smoke.test.sh
/CJ_test_run goal-defect-smoke
```
