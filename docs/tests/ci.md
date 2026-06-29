# Test catalog — `ci` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `ci` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| eval-nightly workflow — scheduled evals | ci | hard-fail | nightly manual | `.github/workflows/eval-nightly.yml` · `name: Eval Nightly` | Runs the behavioral eval harness on a daily schedule, with a manual dispatch trigger. |
| validate workflow — PR gate | ci | hard-fail | pr-ci | `.github/workflows/validate.yml` · `name: Validate Skills` | Runs the validator, the full test suite and shellcheck on every pull request. |
| windows workflow — Git Bash gate | ci | hard-fail | pr-ci push-main | `.github/workflows/windows.yml` · `name: Windows (Git Bash)` | Runs the Windows smoke and the skills-deploy suite under Git Bash on every pull request and push to main. |
