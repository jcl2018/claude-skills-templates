# Topic: portability — how the goal is achieved

**The dream:** [another machine gets the same skills as in this repo](../../../goals/portability.md).
That page is the WHAT (the end goal + the three properties). This subdir is the
HOW — the tests that realize it, grouped by the verification **layer** they run
at, each page listing *how to achieve* the dream at that layer.

## The property → test → layer map

| Property (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Completeness** | install all → deployed count `== SKILL_COUNT` | `windows-smoke` S5 (fast) | [CI-push](CI-push.md) |
| | full harness re-checks the whole catalog | `portability-deploy` Test 1 | [CI-nightly](CI-nightly.md) |
| **Fidelity** | per-file `source_checksums` match the deployed copy | `windows-smoke` S6 (fast) | [CI-push](CI-push.md) |
| | doctor detects drift; relink repairs it | `portability-deploy` C1/C3/C4 | [CI-nightly](CI-nightly.md) |
| **Cross-platform parity** | copy-mode lands real files; install==clone holds on Git-Bash | `portability-smoke` S1–S4 | [CI-push](CI-push.md) |
| **No hidden coupling** (precondition) | declared-vs-actual dependency lint (strict) | `portability-check18-lint` | [CI-push](CI-push.md) |
| **Freshness signal** | script emits the upgrade banner | `portability-version-check` | [local-hook](local-hook.md) |
| | an agent actually *surfaces* the nudge | `portability-version-agentic` | [local-hook](local-hook.md) |

## Coverage matrix (property × layer)

| | CI-push (per-PR, fast) | CI-nightly (full) | local-hook |
|---|:---:|:---:|:---:|
| Completeness | ✅ `windows-smoke` S5 | ✅ `portability-deploy` T1 | — |
| Fidelity | ✅ `windows-smoke` S6 | ✅ `portability-deploy` C1/C3/C4 | — |
| Cross-platform parity | ✅ `portability-smoke` | — | — |
| No hidden coupling | ✅ `portability-check18-lint` | — | — |
| Freshness signal | — | — | ✅ version-check + version-agentic |

Every property is proven **at least once on the fast per-PR path** (CI-push), with
CI-nightly re-proving completeness + fidelity against the *full* catalog and
local-hook covering the freshness signal (the agentic proof needs a machine with
`claude`, so it lives local-only — see [local-hook](local-hook.md)).

## Run it end to end

```bash
/CJ_test_run --topic portability          # every portability test the current tier allows
/CJ_test_run --topic portability --e2e    # include the local-only agentic proof
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`, `--layer local-hook`.

## The subtests (front-door docs)

Each test's authoritative "what it asserts" table lives in its front-door doc:

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `portability-check18-lint` | infra / CI-push / deterministic | [doc](../../infra/CI-push/portability-check18-lint.md) |
| `portability-smoke` | infra / CI-push / deterministic | [doc](../../infra/CI-push/portability-smoke.md) |
| `portability-deploy` | infra / CI-nightly / deterministic | [doc](../../infra/CI-nightly/portability-deploy.md) |
| `portability-version-check` | infra / local-hook / deterministic | [doc](../../infra/local-hook/portability-version-check.md) |
| `portability-version-agentic` | infra / local-hook / agentic | [doc](../../infra/local-hook/portability-version-agentic.md) |

> This subdir is required by the topic contract: an enrolled topic
> (`topic_contracts:` in `spec/test-spec-custom.md`) must carry this `index.md`,
> a page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
