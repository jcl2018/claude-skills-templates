# goal-feature @ local-hook — the gate-seam safety proof

**Dream:** [a one-line topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The feature verb owns the one interactive design gate between the operator's
approval and the autonomous build spend — and a deterministic auto-answer seam
(`scripts/cj-e2e-gate.sh`) that a local E2E harness can drive through it. The
local-hook deterministic point is
[`goal-feature-gate-seam`](../../workflow/local-hook/goal-feature-gate-seam.md)
(`bash tests/cj-e2e-gate.test.sh`), the seam's full verdict matrix:

- flag-only and marker-only are both `inactive` (the **double hard guard** — a
  normal run is behavior-unchanged);
- `design-gate` auto-approves (`continue`) only under both guards;
- a qa-audit digest with findings always `halt`s (never auto-waived);
- any non-allowlisted gate id (ship / merge / land / deploy) stays `inactive`
  — the seam can never answer a gstack ship gate.

Zero model spend, seconds-fast: a maintainer runs it on demand before any
gate-adjacent change leaves the machine (it also rides the per-PR full suite —
`layer` placement is descriptive, and this check is deliberately cheap
everywhere).

## The deterministic-only note

Under the both-modes contract this layer would ALSO require an agentic proof.
This topic is enrolled **deterministic-only**: the agentic
`goal-feature-eval` row is tolerated, never required (see the
[dream doc](../../../goals/goal-feature.md)'s posture section). If the
auto-answer harness is ever retired with the agentic assets, the documented
fallback is re-declaring the [chain drill](CI-nightly.md) at this layer (two
rows sharing one command — the `test-deploy` / `portability-deploy` precedent).

## Run it

```bash
bash tests/cj-e2e-gate.test.sh
/CJ_test_run goal-feature-gate-seam
```
