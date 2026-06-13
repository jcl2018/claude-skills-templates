# doc-spec-custom.md — this repo's doc-contract overlay

This file is the **custom tier** of the two-tier doc contract: the
repo-specific docs this workbench carries beyond the twelve general docs
declared in [`spec/doc-spec.md`](doc-spec.md) (the portable seed, never edited
in place). `scripts/doc-spec.sh` merges this overlay's registry into the
general one internally, so every consumer — `validate.sh` Checks 15–23,
`/CJ_document-release`, `scripts/generate-doc-views.sh` — sees ONE registry. A
path declared in BOTH files is a `--validate` error (duplicate-path guard).

This workbench's custom tier is five docs: `CONTRIBUTING.md` (the contributor
authoring guide, surfaced by GitHub from the repo root) plus the repo-specific
spec-registry files (`spec/gate-spec.md`, `spec/permission-policy.md`) and the
two overlay files themselves (`spec/doc-spec-custom.md`,
`spec/test-spec-custom.md` — each self-declared here). The spec-registry
family lives under `spec/` — a dedicated folder that signals "machine config,
not hand-read docs" at a glance. The full general/custom doc lists are
**generated** from the merged registry into
[`docs/doc-general.md`](../docs/doc-general.md) +
[`docs/doc-custom.md`](../docs/doc-custom.md) (do not hand-edit — regenerate
with `scripts/generate-doc-views.sh`); the contract's *why* (the logic) lives
in [`docs/philosophy.md`](../docs/philosophy.md) `## Topic: Doc contract`.

Repo notes:

- The three core human docs and the two generated views live under `docs/`
  (lowercase). `docs/workflow.md` is singular.
- The spec-registry family lives under `spec/` (this repo); each helper
  resolves `spec/<name>.md` first, then a root `<name>.md` fallback, so a
  root-only consumer still resolves its registry unchanged.
- The root operational docs (`CHANGELOG.md`, `CLAUDE.md`, `TODOS.md` — general
  tier — plus the custom `CONTRIBUTING.md`) stay at the repo root because
  external tooling (GitHub rendering, Claude Code's `./CLAUDE.md` auto-load,
  `/ship`'s changelog writer) hardcodes those root paths.
- The doc-only auto-commit whitelist used by `/CJ_document-release` is derived
  from the merged registry — there is no separate hand-maintained whitelist
  file.

## Machine registry (overlay)

The block below is merged into the general registry by `scripts/doc-spec.sh`.
Keep it the only fenced `yaml` block in this file.

```yaml
# doc-spec custom overlay (merged into spec/doc-spec.md by scripts/doc-spec.sh)
schema_version: 1
docs:
  - path: spec/gate-spec.md
    section: custom
    audit_class: operational
    purpose: "The cj_goal verification contract — what stops a broken change from landing, and at which layer (parsed by scripts/gate-spec.sh)."
    requirement: "Present; one fenced yaml registry of layers[] + gates[] parsing with schema_version 1; every declared literal marker present in its mode's pipeline."
  - path: spec/permission-policy.md
    section: custom
    audit_class: operational
    purpose: "The cj_goal allow/ask/deny permission contract (parsed by scripts/permission-policy.sh)."
    requirement: "Present; one fenced yaml policy registry parsing with schema_version 1; risky verbs enumerated as deny/ask."
  - path: CONTRIBUTING.md
    section: custom
    audit_class: operational
    purpose: "Contributor authoring guide."
    requirement: "Present; surfaced by GitHub from the repo root."
  - path: spec/doc-spec-custom.md
    section: custom
    audit_class: operational
    purpose: "This repo's doc-contract overlay (this file) — the custom-tier rows merged into the general contract by scripts/doc-spec.sh."
    requirement: "Present; one fenced yaml registry of section: custom entries parsing with schema_version 1; declares every repo-specific doc (including itself); no path duplicated against the general file."
  - path: spec/test-spec-custom.md
    section: custom
    audit_class: operational
    purpose: "This repo's test-contract overlay — the unit-level enumeration of the verification surface (parsed by scripts/test-spec.sh)."
    requirement: "Present; one fenced yaml registry of units parsing with schema_version 1; every anchor present in its declared source (validate.sh Check 24)."
```
