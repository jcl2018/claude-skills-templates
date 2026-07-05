# portability @ CI-push — the fast per-PR proofs

Realizes the [portability dream](../../../goals/portability.md) on the **per-PR
gate**. Everything here is cheap (seconds) so it can run on every push without
slowing the merge — the deliberate design point: the *heavy* full-catalog proof
lives at [CI-nightly](CI-nightly.md), the fast parity proofs live here.

## What runs here, and which property it achieves

| Test | Achieves | How (in one line) |
|------|----------|-------------------|
| [`portability-smoke`](../../infra/CI-push/portability-smoke.md) | **Cross-platform parity** | Git-Bash falls back to copy-mode, lands real files, and `install == clone` still holds (S1–S4). |
| [`portability-smoke`](../../infra/CI-push/portability-smoke.md) S5 | **Completeness** (fast) | a full `skills-deploy install` lands every catalog skill: deployed count `== SKILL_COUNT`. |
| [`portability-smoke`](../../infra/CI-push/portability-smoke.md) S6 | **Fidelity** (fast) | the manifest's per-file `source_checksums` match the installed copies. |
| [`portability-check18-lint`](../../infra/CI-push/portability-check18-lint.md) | **No hidden coupling** (precondition) | every skill's declared portability tier matches its actual dependencies (strict — a violation fails the PR). |

## How this layer achieves the dream

- **Parity first.** `portability-smoke` runs the same `skills-deploy install`
  path a teammate would, forced into copy-mode (`SKILLS_DEPLOY_FORCE_COPY=1`) so
  the Git-Bash behavior is exercised on *every* host — including the ubuntu CI and
  macOS — not only on `windows-latest`. If the Windows install path regresses, the
  PR is red on Linux too.
- **Completeness + fidelity, fast.** S5 and S6 make the two "same skills" halves
  of the dream gate on *every* PR without paying for the full deploy harness: S5
  counts the deployed skill dirs against the catalog-derived `SKILL_COUNT`; S6
  compares recorded checksums to the bytes on disk. The exhaustive install /
  remove / relink / doctor / drift matrix is the CI-nightly job's concern.
- **Precondition, strict.** `portability-check18-lint` is `validate.sh` Check 18
  running **strict-by-default** (`PORTABILITY_STRICT=1`): a skill that claims
  `standalone` while reaching for a workbench-only helper hard-fails the PR, so a
  skill can never ship that would "install but not run" on another machine.

## How to run

```bash
bash scripts/windows-smoke.sh            # portability-smoke (S1–S6)
bash scripts/cj-portability-audit.sh     # portability-check18-lint engine
# or via the contract:
/CJ_test_run --layer CI-push             # every CI-push test
/CJ_test_run portability-smoke           # just the smoke
```

## What is deliberately NOT here

The full `test-deploy.sh` harness (install / remove / relink / doctor / drift
across the whole catalog) is **not** on this layer — it is too slow for the
per-PR gate. It runs at [CI-nightly](CI-nightly.md). CI-push proves completeness +
fidelity with the *fast* S5/S6 assertions instead; nightly re-proves them
exhaustively.
