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
spec-registry files (`spec/permission-policy.md` plus the workflow-docs registry
`spec/workflow-spec.md`), the two overlay files themselves
(`spec/doc-spec-custom.md`, `spec/test-spec-custom.md` — each self-declared here),
and the six per-workflow human-docs under `docs/workflows/`
(`CJ_goal_feature.md`, `CJ_goal_task.md`, `CJ_goal_defect.md`,
`CJ_goal_todo_fix.md`, `utilities-and-phase-steps.md`, `utility-audits.md` — the
detail split out of the `docs/workflow.md` index per the general contract's
two-level mandate, now GENERATED from `spec/workflow-spec.md` by
`scripts/workflow-spec.sh --render-docs` and kept fresh by `validate.sh`
Check 27). The spec-registry family lives under `spec/` — a dedicated
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
| `spec/workflow-spec.md` | This repo's workflow-docs registry — the single source of truth for the docs/workflow.md index + the six docs/workflows/*.md files (parsed by scripts/workflow-spec.sh; rendered to that surface by --render-docs). | Present; one structured-markdown registry (header + orchestrator + roster sections) parsing valid; every routable goal orchestrator has an entry (workflow-spec.sh --validate registry-completeness). |
| `docs/workflows/CJ_goal_feature.md` | GENERATED per-workflow detail for /CJ_goal_feature — the ASCII workflow chart + the 4-bullet Touches block; rendered from spec/workflow-spec.md; linked from the docs/workflow.md index. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/workflows/CJ_goal_task.md` | GENERATED per-workflow detail for /CJ_goal_task — the ASCII workflow chart + the 4-bullet Touches block; rendered from spec/workflow-spec.md; linked from the docs/workflow.md index. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/workflows/CJ_goal_defect.md` | GENERATED per-workflow detail for /CJ_goal_defect — the ASCII workflow chart + the 4-bullet Touches block; rendered from spec/workflow-spec.md; linked from the docs/workflow.md index. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/workflows/CJ_goal_todo_fix.md` | GENERATED per-workflow detail for /CJ_goal_todo_fix — the ASCII workflow chart + the 4-bullet Touches block; rendered from spec/workflow-spec.md; linked from the docs/workflow.md index. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/workflows/utilities-and-phase-steps.md` | GENERATED machinery glossary + per-skill roster for the phase-step skills, the validator, and the standalone utilities the orchestrators dispatch / the operator runs directly; rendered from spec/workflow-spec.md. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/workflows/utility-audits.md` | GENERATED standalone read-only utility audits — /CJ_doc_audit, /CJ_test_audit; rendered from spec/workflow-spec.md. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 27); human-readable; no work-item IDs. |
| `docs/test-catalog.md` | GENERATED index of the verification surface — families with per-family counts, linking each docs/tests/<family>.md; rendered from the merged test-spec registry by test-spec.sh --render-docs. | Present; generated (do-not-edit banner); byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/validate.md` | GENERATED test-catalog page for the validate family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/test.md` | GENERATED test-catalog page for the test family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/ci.md` | GENERATED test-catalog page for the ci family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/hook.md` | GENERATED test-catalog page for the hook family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/windows-smoke.md` | GENERATED test-catalog page for the windows-smoke family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/test-deploy.md` | GENERATED test-catalog page for the test-deploy family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/eval.md` | GENERATED test-catalog page for the eval family — the units rendered from the merged test-spec registry. | Present; generated by test-spec.sh --render-docs; byte-matches a fresh render (validate.sh Check 26); human-readable; no work-item IDs. |
| `docs/tests/test-hierarchy.md` | HAND-AUTHORED explainer of the workbench's test hierarchy — what each layer (shell skeleton / contract gates / behavioral eval cases / full E2E) proves, why all are needed, and the deliberate gstack-in-CI E2E gap. Editorial prose, NOT generated; exempt from the Check 26 orphan sweep via the `_HANDAUTHORED_TESTDOCS` carve-out in test-spec.sh. | Present; hand-authored (edit by hand, not a render); human-readable; no work-item IDs. |
| `docs/tests/index.md` | SEEDED test-list INDEX for the category-based test contract — references every declared category test by name, grouped by category, each linking its docs/tests/<category>/<name>.md page. Seeded/refreshed by /CJ_test_audit from the spec/test-spec-custom.md categories: axis (idempotent — present ⇒ skip); category-owned, exempt from the family-render orphan sweep. | Present; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-push/validate.md` | SEEDED per-test doc for the `validate` infra-category CI-push-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-push/suite.md` | SEEDED per-test doc for the `suite` infra-category CI-push-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-nightly/test-deploy.md` | SEEDED per-test doc for the `test-deploy` infra-category CI-nightly-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/workflow/CI-push/cj-goal-gate-shape.md` | SEEDED per-test doc for the `cj-goal-gate-shape` workflow-category CI-push-layer test — the authoritative What/How/Why front door for the cj_goal build-gate shape guard. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-push/portability-check18-lint.md` | SEEDED per-test doc for the `portability-check18-lint` infra-category CI-push-layer test — the authoritative What/How/Why front door for the declared-vs-actual portability lint (Check 18's engine). Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-push/portability-smoke.md` | SEEDED per-test doc for the `portability-smoke` infra-category CI-push-layer test — the authoritative What/How/Why front door for the Git-Bash smoke of the deploy/install harness. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/CI-nightly/portability-deploy.md` | SEEDED per-test doc for the `portability-deploy` infra-category CI-nightly-layer test — the authoritative What/How/Why front door for the Windows-native deploy suite of the deploy/install harness. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/infra/local-hook/portability-version-check.md` | SEEDED per-test doc for the `portability-version-check` infra-category local-hook-layer test — the authoritative What/How/Why front door for the local sandbox check of the harness's version-notification. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/workflow/local-hook/goal-task-eval.md` | SEEDED per-test doc for the `goal-task-eval` workflow-category local-hook-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/workflow/local-hook/goal-feature-eval.md` | SEEDED per-test doc for the `goal-feature-eval` workflow-category local-hook-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/workflow/local-hook/doc-sync.md` | SEEDED per-test doc for the `doc-sync` workflow-category local-hook-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page; seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
| `docs/tests/workflow/local-hook/e2e-local.md` | SEEDED per-test doc for the `e2e-local` workflow-category local-hook-layer test — the authoritative What/How/Why front door for one declared category test. Seeded by /CJ_test_audit from the two-axis categories: axis (idempotent; safe to edit). | Present; carries the three front-door sections `## What it is` / `## How to run` / `## Explanation` (test-spec.sh --check-structure check (f)), cross-links its docs/tests/<family>.md units-detail page (or explains why none applies); seeded by test-spec.sh --seed-docs; human-readable; no work-item IDs. |
