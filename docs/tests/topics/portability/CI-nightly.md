# portability @ CI-nightly — the full deploy-harness proof

Realizes the [portability dream](../../../goals/portability.md) **exhaustively**,
off the per-PR path. Where [CI-push](CI-push.md) proves completeness + fidelity
with two fast assertions, this layer re-proves them against the *whole* catalog
with the complete `skills-deploy` lifecycle — the depth that is too slow to gate
every merge.

## What runs here, and which property it achieves

| Test | Achieves | How (in one line) |
|------|----------|-------------------|
| [`portability-deploy`](../../infra/CI-nightly/portability-deploy.md) Test 1 | **Completeness** (full) | install all → deployed skill-dir count `== SKILL_COUNT` (catalog-derived). |
| [`portability-deploy`](../../infra/CI-nightly/portability-deploy.md) C1 | **Fidelity** (full) | manifest records per-file `source_checksums`; each matches the installed copy's hash. |
| [`portability-deploy`](../../infra/CI-nightly/portability-deploy.md) C3 | **Fidelity** (drift detection) | `doctor` FAILs when a deployed file is edited away from source. |
| [`portability-deploy`](../../infra/CI-nightly/portability-deploy.md) C4 / 8c | **Fidelity** (self-heal / CRLF) | `relink` restores drift; `doctor` flags a CRLF-rewritten template. |

## How this layer achieves the dream

- **Same script, distinct context.** `portability-deploy` runs the *same*
  `scripts/test-deploy.sh` as the local full suite, but on `windows-latest`
  (`.github/workflows/windows-nightly.yml`) on a nightly schedule. The value is
  the platform × cadence: the exhaustive install / remove / relink / doctor /
  drift matrix is exercised Windows-native, without slowing any PR.
- **Completeness at full breadth.** Test 1 installs the *entire* catalog and
  asserts the deployed directory count equals `SKILL_COUNT` — the "no skill
  silently missing" half of the dream, checked against every skill rather than the
  smoke's single representative.
- **Fidelity end to end.** C1 proves the recorded checksums match; C3 proves drift
  is *detected* (not just recorded); C4 proves `relink` *repairs* it; Test 8c
  proves a Windows CRLF rewrite is caught independently of the checksum. Together
  they close the "deployed bytes == source, and drift can't hide" property.

## How to run

```bash
bash scripts/test-deploy.sh              # the full harness (runs on the host platform)
# or via the contract:
/CJ_test_run --layer CI-nightly
/CJ_test_run portability-deploy
```

> On a normal per-PR `test.sh` this suite is skipped under `TEST_FAST=1` and gates
> via the nightly full-suite instead. The fast per-PR stand-ins for its two core
> properties are `windows-smoke` S5/S6 — see [CI-push](CI-push.md).
