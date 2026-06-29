# Test catalog — `test-deploy` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `test-deploy` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| skills-deploy suite — install/doctor/remove in isolation | ci | hard-fail | pr-ci push-main manual | `scripts/test.sh` · `scripts/test-deploy.sh` | Template ownership, drift overwrite, copy-mode fallback, shared-script orphan pruning (manifest-keyed, ownership-safe), and doctor verdicts (incl. the shared-scripts health section) in isolated temp homes; runs inside the test suite, in the Windows workflow, and by hand. |
