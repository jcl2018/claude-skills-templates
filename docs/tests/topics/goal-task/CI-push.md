# goal-task @ CI-push — the fast per-PR gate + scaffold proof

**Dream:** [a small ad-hoc task becomes a reviewable PR](../../../goals/goal-task.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

Every PR must prove the task verb's two distinctive pieces — the HARD
complexity gate and the bash scaffolder — still behave, cheaply. The per-PR
point is [`goal-task-scaffold`](../../workflow/CI-push/goal-task-scaffold.md)
(`bash tests/cj-task-scaffold.test.sh`):

- **gate refusals** — a design-rework topic → `too-complex` +
  `SUGGEST=/CJ_goal_feature`; a bug/investigation topic →
  `SUGGEST=/CJ_goal_defect`; an explicit-large-scope topic halts; a legitimate
  small topic passes (bare "design" must not trip it);
- **dry-run** — plans a T-ID, writes nothing;
- **live scaffold** — a `type: task` work-item (TRACKER + test-plan + the topic
  footer) minted in a sandbox staging the real templates;
- **idempotency** — a re-run with the same topic reuses the dir
  (`IDEMPOTENT_SKIP=1`, no second T-ID).

## What this layer does NOT prove

Composition (the scaffold running INSIDE a freshly-minted worktree, then the
recap + janitor) waits for the [CI-nightly chain drill](CI-nightly.md); the E2E
harness's readiness lives at [local-hook](local-hook.md); the agent-executed
pipeline prose has no required proof at any layer (the deterministic-only
posture — see the dream doc).

## Run it

```bash
bash tests/cj-task-scaffold.test.sh
/CJ_test_run goal-task-scaffold
```
