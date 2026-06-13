# doc-spec-custom.md — this repo's doc-contract overlay

This file is the **custom tier** of the two-tier doc contract: the
repo-specific docs this workbench carries beyond the ten general docs declared
in [`spec/doc-spec.md`](doc-spec.md) (the portable seed, never edited in
place). `scripts/doc-spec.sh` merges this overlay's table into the general one
internally, so every consumer — `validate.sh` Checks 15–24,
`/CJ_document-release` — sees ONE registry. A path declared in BOTH files is a
`--validate` error (duplicate-path guard).

This workbench's custom tier is `CONTRIBUTING.md` (the contributor
authoring guide, surfaced by GitHub from the repo root) plus the repo-specific
spec-registry file (`spec/permission-policy.md`) and the two overlay files
themselves (`spec/doc-spec-custom.md`, `spec/test-spec-custom.md` — each
self-declared here). The spec-registry family lives under `spec/` — a dedicated
folder that signals "machine config, not hand-read docs" at a glance. The
contract's *why* (the logic) lives in
[`docs/philosophy.md`](../docs/philosophy.md) `## Topic: Doc contract`.

Repo notes:

- The three core human docs live under `docs/` (lowercase). `docs/workflow.md`
  is singular.
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

## The registry (overlay)

The table below is merged into the general registry by `scripts/doc-spec.sh`.
It uses the same 3-column shape (`| Doc | Purpose | Requirement |`); a path
under `docs/` or the root `README.md` is a human-doc, everything else is
operational (path-derived, not declared). Cells may not contain a literal `|`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| `spec/permission-policy.md` | The cj_goal allow/ask/deny permission contract (parsed by scripts/permission-policy.sh). | Present; one fenced yaml policy registry parsing with schema_version 1; risky verbs enumerated as deny/ask. |
| `CONTRIBUTING.md` | Contributor authoring guide. | Present; surfaced by GitHub from the repo root. |
| `spec/doc-spec-custom.md` | This repo's doc-contract overlay (this file) — the custom-tier rows merged into the general contract by scripts/doc-spec.sh. | Present; one registry table of repo-specific docs (including itself); no path duplicated against the general file. |
| `spec/test-spec-custom.md` | This repo's test-contract overlay — the unit-level enumeration of the verification surface plus the per-mode pipeline gates (parsed by scripts/test-spec.sh). | Present; one fenced yaml registry of units + gates parsing with schema_version 1; every anchor present in its declared source (validate.sh Check 24). |
