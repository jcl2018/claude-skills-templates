# Test catalog — `eval` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `eval` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| eval-case verification specs — driven in-session by Claude | local-hook | hard-fail | manual | `tests/eval/CJ_goal_feature/dry-run-plan/prompt.md` · `naming the planned worktree + the office-hours/scaffold/implement/qa/ship chain` | The durable, version-controlled tests/eval/<skill>/<case>/ verification specs (prompt.md + expected.schema.json + fixture) that Claude drives in-session to confirm a workflow still loads and reaches its declared outcome — the free replacement for the retired paid headless-CLI runner. Keeps the eval family declared (not orphaned) and its tests/eval/ prompt.md anchors the same ones the Check 28 workflow-coverage gate greps live. |
