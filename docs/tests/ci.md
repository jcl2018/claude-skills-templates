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
| audit-nightly workflow — nightly doc/test audit | CI-nightly | hard-fail | nightly manual | `.github/workflows/audit-nightly.yml` · `name: Audit Nightly` | Runs /CJ_doc_audit + /CJ_test_audit headless (scripts/audit-nightly.sh) on a nightly schedule + manual dispatch, filing findings to the audit-drift GitHub issue — the relocated home of the advisory agent-judged audit, off the CJ_goal_* build hot path (CI-nightly cadence). |
| eval-nightly workflow — scheduled evals | CI-nightly | hard-fail | nightly manual | `.github/workflows/eval-nightly.yml` · `name: Eval Nightly` | Runs the behavioral eval harness on a daily schedule, with a manual dispatch trigger. |
| validate workflow — PR gate | CI-push | hard-fail | pr-ci | `.github/workflows/validate.yml` · `name: Validate Skills` | Runs the validator, the full test suite and shellcheck on every pull request. |
| windows workflow — Git Bash smoke gate | CI-push | hard-fail | pr-ci push-main | `.github/workflows/windows.yml` · `name: Windows (Git Bash)` | Runs the fast Windows smoke (windows-smoke.sh) under Git Bash on every pull request and push to main — the CI-push cadence; the slow skills-deploy suite moved to the nightly workflow. |
| windows-nightly workflow — nightly skills-deploy suite | CI-nightly | hard-fail | nightly manual | `.github/workflows/windows-nightly.yml` · `name: Windows Nightly (skills-deploy suite)` | Runs the full skills-deploy suite (test-deploy.sh) on windows-latest under Git Bash on a nightly schedule, with a manual dispatch trigger — the CI-nightly cadence windows-deploy test. |
