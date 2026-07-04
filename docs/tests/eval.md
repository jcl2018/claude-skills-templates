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
| behavioral eval harness — headless skill evals | CI-nightly | hard-fail | nightly manual | `.github/workflows/eval-nightly.yml` · `scripts/eval.sh` | Spawns the headless CLI against scratch worktrees per eval case with JSON-schema output validation; budget-capped per case and per run. |
