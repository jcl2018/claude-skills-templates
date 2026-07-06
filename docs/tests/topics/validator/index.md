# Topic: validator — how the goal is achieved

**The dream:** [no structurally broken change ever lands](../../../goals/validator.md).
That page is the WHAT (the end goal + the three properties). This subdir is the
HOW — the same validator run held to every verification **layer**, each page
listing *how to achieve* the dream at that layer.

## The boundary → test → layer map

| Boundary (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Every push / PR** | `validate.yml` runs `scripts/validate.sh` on every push/PR — the merge signal | `validate` | [CI-push](CI-push.md) |
| **Nightly, clean runner** | `nightly.yml` runs the full `test.sh`, whose first step is `validate.sh` | `validate-nightly` | [CI-nightly](CI-nightly.md) |
| **`git commit`, locally** | the `setup-hooks.sh` pre-commit hook runs exactly `bash scripts/validate.sh` | `validate-hook` | [local-hook](local-hook.md) |

## Coverage matrix (boundary × layer)

| | CI-push (per-PR) | CI-nightly (full) | local-hook |
|---|:---:|:---:|:---:|
| Whole-contract coverage | ✅ `validate` | ✅ `validate-nightly` | ✅ `validate-hook` |
| Every-boundary firing | ✅ push/PR | ✅ nightly cron | ✅ pre-commit hook |

One program (`bash scripts/validate.sh`), three execution contexts — so there is
no boundary where a structural break can cross unchecked, and no split-brain
between what the hook and CI assert. No agentic row is declared for this topic;
the topic contract's local-hook agentic point is advisory (the check prints a
per-topic `note:`, never a finding).

## Run it end to end

```bash
/CJ_test_run --topic validator            # every validator test the current tier allows
bash scripts/validate.sh                  # the one underlying command
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`, `--layer local-hook`.

## The subtests (front-door docs)

Each test's authoritative "what it asserts" description lives in its front-door doc:

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `validate` | infra / CI-push / deterministic | [doc](../../infra/CI-push/validate.md) |
| `validate-nightly` | infra / CI-nightly / deterministic | [doc](../../infra/CI-nightly/validate-nightly.md) |
| `validate-hook` | infra / local-hook / deterministic | [doc](../../infra/local-hook/validate-hook.md) |

> This subdir is required by the topic contract: an enrolled topic
> (`topic_contracts:` in `spec/test-spec-custom.md`) must carry this `index.md`,
> a page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
