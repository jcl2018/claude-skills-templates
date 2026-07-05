# Test: `portability-deploy` (`infra` / `CI-nightly`)

> **Topic:** [portability](../../topics/portability/index.md) · **Goal:**
> [another machine gets the same skills](../../../goals/portability.md) ·
> **Layer view:** [CI-nightly](../../topics/portability/CI-nightly.md).
> This test achieves **completeness** + **fidelity** exhaustively (the full
> catalog), off the per-PR path.

| Field | Value |
|-------|-------|
| Name | `portability-deploy` |
| Category | `infra` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## What it is

The full `skills-deploy` end-to-end harness — install / remove / relink / doctor /
drift across the *entire* catalog. It is the heavy `CI-nightly` sibling of
`portability-smoke`: the same "same skills" properties, proven exhaustively on a
Windows-native runner (`.github/workflows/windows-nightly.yml`) rather than on
every PR (it is too slow for the push cadence).

## What it proves

| Case | Assertion | Achieves |
|------|-----------|----------|
| **Test 1** | install all → deployed skill-dir count `== SKILL_COUNT` (catalog-derived: non-deprecated skills with files) | **Completeness** (full catalog) |
| **Test 4** | a second install is idempotent (still `== SKILL_COUNT`) | Completeness (stable) |
| **C1** | the manifest records non-empty per-file `source_checksums`; each matches the installed copy's SHA-256 | **Fidelity** (bytes match) |
| **C3** | `doctor` FAILs when a deployed file is edited away from source | **Fidelity** (drift *detected*) |
| **C4** | `relink` re-copies a drifted file back to source → `doctor` healthy again | **Fidelity** (self-heal) |
| **Test 8c** | `doctor` flags a CRLF-rewritten template independently of the checksum | **Fidelity** (Windows line-ending drift) |

## How to run

```bash
bash scripts/test-deploy.sh                  # full harness (runs on the host platform)
# via the contract:
/CJ_test_run portability-deploy
/CJ_test_run --category infra
/CJ_test_run --layer CI-nightly
```

## Explanation

This is the exhaustive proof of the two "same skills" halves of the
[dream](../../../goals/portability.md). **Completeness**: Test 1 installs the whole
catalog and asserts the deployed count equals `SKILL_COUNT`, so a deploy bug that
drops even one skill fails here. **Fidelity**: C1 proves the recorded checksums
match the bytes; C3 proves drift is *detected* (not merely recorded — a subtle gap,
since a CRLF install can record the CRLF sum); C4 proves `relink` *repairs* it; and
Test 8c catches a Windows CRLF rewrite the checksum comparison alone could miss.

On a normal per-PR `test.sh` this suite is skipped under `TEST_FAST=1` and gates
via the nightly full-suite instead; the fast per-PR stand-ins for its two core
properties are `portability-smoke` S5/S6 (see
[portability @ CI-push](../../topics/portability/CI-push.md)).

For the per-unit breakdown of what the suite asserts, see the
[test-deploy family doc](../../test-deploy.md); for the layer-level "how", see
[portability @ CI-nightly](../../topics/portability/CI-nightly.md).
