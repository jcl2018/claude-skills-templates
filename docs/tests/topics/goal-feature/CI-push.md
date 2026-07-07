# goal-feature @ CI-push — the fast per-PR shape proof

**Dream:** [a one-line topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

Every PR must prove the feature verb's deterministic plumbing SHAPE still holds
before it merges — cheaply. The per-PR point is
[`goal-feature-smoke`](../../workflow/CI-push/goal-feature-smoke.md)
(`bash tests/cj-goal-feature-smoke.test.sh`), which probes each seam in
isolation with `--dry-run`:

- **worktree entry** — `cj-worktree-init.sh --caller feature` mints a
  `cj-feat-*` branch, `state=created`;
- **shared phases** — `cj-goal-common.sh --phase worktree|ship|telemetry
  --mode feature` each answer their documented `KEY=VALUE` contract (the
  telemetry phase writes exactly one JSONL receipt to an isolated temp path);
- **leaf targets** — the scaffold / impl / qa `SKILL.md`s the pipeline
  dispatches exist on disk (the gstack office-hours/ship tails are deliberately
  not asserted — a bare CI checkout does not have them).

## What this layer does NOT prove

Phase COMPOSITION (one checkout flowing through all the seams in order) waits
for the [CI-nightly chain drill](CI-nightly.md); the gate seam's full verdict
matrix lives at [local-hook](local-hook.md); the agent-executed pipeline prose
has no required proof at any layer (the deterministic-only posture — see the
dream doc).

## Run it

```bash
bash tests/cj-goal-feature-smoke.test.sh
/CJ_test_run goal-feature-smoke
```
