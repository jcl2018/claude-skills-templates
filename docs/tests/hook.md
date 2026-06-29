# Test catalog — `hook` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `hook` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| post-merge hook — auto re-deploy | local-hook | advisory | post-merge | `scripts/setup-hooks.sh` · `install_hook post-merge` | Re-deploys skills, templates and rules into the local home after pulls that touch them; best-effort, never blocks git. |
| pre-commit hook — validator at commit time | local-hook | hard-fail | pre-commit | `scripts/setup-hooks.sh` · `install_hook pre-commit` | Runs the validator before every local commit; a failing check blocks the commit. |
