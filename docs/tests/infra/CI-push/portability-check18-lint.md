# Test: `portability-check18-lint` (`infra` / `CI-push`)

> **Topic:** [portability](../../topics/portability/index.md) · **Goal:**
> [another machine gets the same skills](../../../goals/portability.md) ·
> **Layer view:** [CI-push](../../topics/portability/CI-push.md).
> This test achieves the **no-hidden-coupling precondition** of the dream.

| Field | Value |
|-------|-------|
| Name | `portability-check18-lint` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash scripts/cj-portability-audit.sh` |
| Tier | `free` |

## What it is

The declared-vs-actual portability lint — the engine behind `validate.sh`
Check 18. For each catalog skill it compares the skill's *declared* `portability`
tier against its *actual executed* dependencies and emits a per-skill verdict. It
is the fast, static per-PR guard that a skill which claims to run anywhere does not
secretly reach into workbench-only files.

## What it proves

The strict tier ladder is `standalone (0) < local-only (1) < workbench (2)`. A
dependency's minimum tier must not exceed the skill's declared tier.

| Assertion | What it checks | Achieves |
|-----------|----------------|----------|
| **Tier match** | every skill's declared tier ≥ the tier its actual deps require (a `standalone` skill executing a root `scripts/*.sh`, reading `CLAUDE.md`, or reaching the manifest `.source` is a FINDING) | No hidden coupling |
| **Unknown-tier** | an unrecognized `portability` value is itself a FINDING | contract integrity |
| **EXECUTED vs DOCUMENTED** | only a dep in a *runnable* position counts; a prose/table mention does not (avoids an all-red table of noise) | precision (no false positives) |
| **Adjudication** | a dep listed in the skill's `portability_requires` is accepted; a listed-but-unreferenced entry is an informational note | operator-controlled exceptions |
| **Strict gate** | at `validate.sh` Check 18 the engine runs `PORTABILITY_STRICT=1`, so `FINDINGS > 0` **hard-fails the PR** (not advisory) | enforced precondition |

## How to run

```bash
bash scripts/cj-portability-audit.sh            # advisory engine run (FINDINGS=N tail)
PORTABILITY_STRICT=1 bash scripts/cj-portability-audit.sh   # strict — non-zero exit on findings
# via the contract:
/CJ_test_run portability-check18-lint
/CJ_test_run --category infra      # the whole category
/CJ_test_run --layer CI-push       # the whole layer
```

## Explanation

Completeness and fidelity guarantee that another machine gets the same skill
*files*; this test guarantees those files can actually *run* there. A skill that
claims `standalone` while executing a workbench-only helper would "install" on a
teammate's machine and then fail at runtime — so this precondition is what makes
the [dream](../../../goals/portability.md) meaningful rather than a file-copy
illusion. It is cheap (a static dependency scan), so it gates every PR, and it is
**strict-by-default**: a regression from the clean zero-findings baseline
fails the build. It is the same lint the retired `/CJ_portability-audit` verb used
to front — the engine stays, only the manual verb was removed — so portability's
precondition is now a property the contract proves automatically.

For the per-unit breakdown of Check 18 in the validator, see the
[validate family doc](../../validate.md); for the layer-level "how", see
[portability @ CI-push](../../topics/portability/CI-push.md).
