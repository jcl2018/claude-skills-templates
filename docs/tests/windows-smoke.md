# Test catalog — `windows-smoke` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `windows-smoke` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| Windows smoke — CRLF + portable date + copy-mode + parity (completeness/fidelity) | CI-push | hard-fail | pr-ci push-main manual | `scripts/test.sh` · `scripts/windows-smoke.sh` | Git Bash portability assertions: CRLF tolerance, portable date math, copy-mode install and the in-place install stamp (S1-S4), plus the fast per-PR parity assertions (S5 completeness — a full install lands every catalog skill, count == SKILL_COUNT; S6 fidelity — deployed source_checksums match) that gate 'another machine gets the same skills' on every PR without the slow deploy suite. |
