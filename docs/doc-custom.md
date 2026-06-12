<!-- AUTO-GENERATED from scripts/generate-doc-views.sh — do not edit -->
# Doc contract — custom docs

This repo's custom-tier docs (`section: custom`) beyond the general set, generated from the `spec/doc-spec.md` registry. Do not hand-edit; regenerate with `scripts/generate-doc-views.sh`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| spec/gate-spec.md | The cj_goal verification contract — what stops a broken change from landing, and at which layer (parsed by scripts/gate-spec.sh). | Present; one fenced yaml registry of layers[] + gates[] parsing with schema_version 1; every declared literal marker present in its mode's pipeline. |
| spec/permission-policy.md | The cj_goal allow/ask/deny permission contract (parsed by scripts/permission-policy.sh). | Present; one fenced yaml policy registry parsing with schema_version 1; risky verbs enumerated as deny/ask. |
| CONTRIBUTING.md | Contributor authoring guide. | Present; surfaced by GitHub from the repo root. |
| spec/doc-spec-custom.md | This repo's doc-contract overlay (this file) — the custom-tier rows merged into the general contract by scripts/doc-spec.sh. | Present; one fenced yaml registry of section: custom entries parsing with schema_version 1; declares every repo-specific doc (including itself); no path duplicated against the general file. |
| spec/test-spec-custom.md | This repo's test-contract overlay — the unit-level enumeration of the verification surface (parsed by scripts/test-spec.sh). | Present; one fenced yaml registry of units parsing with schema_version 1; every anchor present in its declared source (validate.sh Check 24). |
