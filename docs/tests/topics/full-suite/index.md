# Topic: full-suite — how the goal is achieved

**The dream:** [the whole verification surface stays green](../../../goals/full-suite.md).
That page is the WHAT (the end goal + the three properties). This subdir is the
HOW — the same suite held to every verification **layer**, each page listing
*how to achieve* the dream at that layer.

## The boundary → run → layer map

| Boundary (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Every push / PR (fast)** | `validate.yml` runs `TEST_FAST=1 test.sh` — the trimmed per-PR gate | `suite` | [CI-push](CI-push.md) |
| **Nightly, full + untrimmed** | `nightly.yml` runs the full `test.sh` (deploy harness included) | `suite-nightly` | [CI-nightly](CI-nightly.md) |
| **Before push, locally** | the documented run-locally-before-push discipline | `suite-local` | [local-hook](local-hook.md) |

## Coverage matrix (property × layer)

| | CI-push (per-PR, fast) | CI-nightly (full) | local-hook |
|---|:---:|:---:|:---:|
| Superset execution | ✅ `suite` (trimmed) | ✅ `suite-nightly` (untrimmed) | ✅ `suite-local` |
| Nothing silently skipped | — (`TEST_FAST=1` trim) | ✅ compensates the trim | ✅ full local run |
| Green before it ships | ✅ gates the merge | ✅ nightly re-proof | ✅ first signal |

The per-PR trim (`TEST_FAST=1` skips the heavy `test-deploy.sh`) is honest ONLY
because the nightly untrimmed run compensates it — the pairing is the point of
holding this topic to all three layers. No agentic row is declared for this
topic; the topic contract's local-hook agentic point is advisory (the check
prints a per-topic `note:`, never a finding).

## Run it end to end

```bash
/CJ_test_run --topic full-suite           # every full-suite test the current tier allows
bash scripts/test.sh                      # the one underlying command (full run)
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`, `--layer local-hook`.

## The subtests (front-door docs)

Each run's authoritative "what it asserts" description lives in its front-door doc:

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `suite` | infra / CI-push / deterministic | [doc](../../infra/CI-push/suite.md) |
| `suite-nightly` | infra / CI-nightly / deterministic | [doc](../../infra/CI-nightly/suite-nightly.md) |
| `suite-local` | infra / local-hook / deterministic | [doc](../../infra/local-hook/suite-local.md) |

> This subdir is required by the topic contract: an enrolled topic
> (`topic_contracts:` in `spec/test-spec-custom.md`) must carry this `index.md`,
> a page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
