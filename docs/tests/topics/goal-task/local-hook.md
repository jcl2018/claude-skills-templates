# goal-task @ local-hook — the E2E-harness readiness proof

**Dream:** [a small ad-hoc task becomes a reviewable PR](../../../goals/goal-task.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The task verb is the one verb with a full local E2E harness — a real
`/CJ_goal_task` build in a throwaway sandbox (`scripts/e2e-local.sh`), the
closest thing the workbench has to proving the whole verb for real. That run
spends a model, so the required local-hook point is its DETERMINISTIC half:
[`goal-task-e2e-det`](../../workflow/local-hook/goal-task-e2e-det.md)
(`bash tests/e2e-local.test.sh`):

- the **SKIP gate** — with `CJ_E2E_LOCAL` unset or a prerequisite missing, the
  harness exits 0 without ever reaching a model;
- the **sandbox** — a mktemp clone + the `.cj-e2e-sandbox` marker + a LOCAL
  bare origin that accepts push but defeats `gh pr create` (the auto-ship
  backstop);
- the **report generator** — evidence-derived rows; a missing-evidence row
  renders `unverified`, never a false pass;
- the **auth gate** — stubbed `claude` binaries prove the
  no-key / logged-in-but-401 / logged-in-and-probe-ok splits.

Zero model spend, runnable on demand before harness-adjacent changes leave the
machine (it also rides the per-PR full suite — `layer` placement is
descriptive).

## The deterministic-only note

Under the both-modes contract this layer would ALSO require an agentic proof.
This topic is enrolled **deterministic-only**: the agentic `goal-task-eval` row
and the real `CJ_E2E_LOCAL=1` harness run are tolerated, never required (see
the [dream doc](../../../goals/goal-task.md)'s posture section). If the
harness is ever retired with the agentic assets, the documented fallback is
re-declaring the [chain drill](CI-nightly.md) at this layer.

## Run it

```bash
bash tests/e2e-local.test.sh
/CJ_test_run goal-task-e2e-det
# the REAL (model-spending) run, on demand, while it exists:
CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh
```
