# Goal: full-suite — the whole verification surface stays green

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/full-suite/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**Every test the repo declares actually runs, and passes, end to end — on a
regular cadence, with nothing silently skipped.** The full suite
(`scripts/test.sh`) is the superset runner: it executes the validator, every
registered `tests/*.test.sh` sub-suite, the inline integration families, the
Windows Git-Bash smoke, and the heavy skills-deploy fixture harness in one pass.
If the suite is green, the repo's *behavior* — not just its structure — is
proven; if some part of the suite never runs anywhere, that part is
decoration, not verification.

This is not one test — it is a **topic**: the same suite held to every
verification layer, with the fast/heavy split made explicit and compensated.
The goal decomposes into three properties. All three must hold for the end
goal to hold.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Superset execution** | One command runs the whole declared surface: the validator plus every registered behavioral sub-suite and harness. | A new test file is never wired into the runner; a sub-suite is commented out. |
| **Nothing silently skipped** | Every skip is explicit and compensated: the per-PR run trims the heaviest work (`TEST_FAST=1` skips the deploy harness) ONLY because the nightly full run re-covers it. | The nightly cadence is dropped while the per-PR trim stays — the skipped work then runs nowhere. |
| **Green before it ships** | The suite passes before a change lands: run locally before push, gated per-PR, re-proven nightly on a clean runner. | A red suite is pushed anyway; local runs are skipped and CI becomes the first (late) signal. |

### Why the fast/heavy split is honest

The per-PR gate must stay fast, so the heaviest deterministic work (the
skills-deploy fixture suite) deliberately runs OFF the PR path. The split is
honest only while both halves exist: the fast per-PR run gates every merge, and
the nightly full run proves the untrimmed suite — heavy parts included — still
passes. The topic's three coverage points below make that pairing enforceable.

## How this goal is achieved (the tests)

The full "how" — which run proves each boundary, and how to run it — lives in
the topic pages:

- **[Overview + coverage matrix](../tests/topics/full-suite/index.md)** — the boundary → run → layer map.
- **[CI-push layer](../tests/topics/full-suite/CI-push.md)** — the fast per-PR run (`TEST_FAST=1`).
- **[CI-nightly layer](../tests/topics/full-suite/CI-nightly.md)** — the full, untrimmed nightly run.
- **[local-hook layer](../tests/topics/full-suite/local-hook.md)** — the run-locally-before-push discipline.

## Coverage at a glance

| Boundary | Proven at | By |
|----------|-----------|-----|
| Every push / PR (fast) | CI-push | `suite` (`validate.yml` runs `TEST_FAST=1 test.sh`) |
| Nightly, full + untrimmed | CI-nightly | `suite-nightly` (`nightly.yml` runs the full `test.sh`) |
| Before push, locally | local-hook | `suite-local` (the documented run-before-push harness) |

No agentic proof is declared for this topic — the suite is deterministic by
nature, and the topic contract treats the local-hook agentic point as advisory
(the check prints a per-topic note, never a finding).
