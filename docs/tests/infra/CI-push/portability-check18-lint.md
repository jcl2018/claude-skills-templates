# Test: `portability-check18-lint` (`infra` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `portability-check18-lint` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash scripts/cj-portability-audit.sh` |
| Tier | `free` |

## What it is

The declared-vs-actual portability lint (validate.sh Check 18's engine): each catalog skill's declared portability tier is checked against its actual repo-local dependencies — the fast per-PR portability signal of the deploy/install harness.

## How to run

```bash
bash scripts/cj-portability-audit.sh
```

Run via the category contract: `/CJ_test_run portability-check18-lint` (single test),
`/CJ_test_run --category infra` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This test makes portability's **declared-vs-actual lint** explicit at the `CI-push`
level. `scripts/cj-portability-audit.sh` is the engine behind `validate.sh` Check 18:
for each catalog skill it compares the declared `portability` tier against the
skill's actual repo-local dependencies (root `scripts/*.sh` helpers, root config,
`CLAUDE.md`, the manifest `.source` reach-back), using the strict tier ladder
(`standalone < local-only < workbench`) and emitting a per-skill verdict. A skill
that claims `standalone` but reaches for a workbench-only helper is a finding. It is
an `infra` test (standing verification of the deploy/install harness) that runs on
every PR (it is cheap — a static dependency scan). It is the same lint the retired
`/CJ_portability-audit` verb used to front — the engine stays, only the manual verb
was removed — so portability is now a property the contract proves automatically
rather than a command a maintainer remembers to run. The command-only row makes it
legible in the per-category × layer matrix alongside `portability-smoke` (CI-push),
`portability-deploy` (CI-nightly), and `portability-version-check` (local-hook).

For the per-unit breakdown of Check 18 in the validator, see the
[validate family doc](../../../validate.md).
