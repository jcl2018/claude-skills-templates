# Goal: validator — no structurally broken change ever lands

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/validator/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**A change that breaks the repo's structural contracts never lands — and ideally
never even leaves the machine that made it.** The workbench is contract-driven:
the skill catalog must match the filesystem, every declared doc must exist (and
no orphan may appear), the test and workflow registries must validate, and the
generated surfaces (README, test catalog, workflow docs) must byte-match a fresh
render. `scripts/validate.sh` is the ONE deterministic program that asserts all
of it. If the validator is green, the tree is structurally sound; if a boundary
exists where the validator does not fire, that boundary is where broken changes
slip through.

This is not one test — it is a **topic**: the same validator run held to every
verification layer. The goal decomposes into three properties. All three must
hold for the end goal to hold.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Whole-contract coverage** | One run asserts the *entire* structural contract — catalog ⇔ filesystem, the doc contract, the test contract, generated-surface freshness. | A new contract surface ships without a covering check; a check is silently weakened. |
| **Every-boundary firing** | The same validator fires at every boundary a change crosses: `git commit` (the pre-commit hook), every push/PR (CI), and nightly on a clean runner. | The hook isn't installed; a CI workflow is edited to skip it; the nightly cadence is dropped. |
| **Anywhere-runnable** | Deterministic, free, no model and no network dependency — cheap enough to afford at *every* boundary. | A check grows a network / model / platform dependency that makes some boundary skip it. |

### Why one program at three boundaries works

The validator's checks are deterministic and self-contained, so the SAME command
(`bash scripts/validate.sh`) is affordable everywhere: seconds after an edit (the
hook), as the PR merge signal (CI-push), and as a clean-runner re-proof (nightly,
inside the full suite). Each boundary catches what the earlier one missed — and
because it is one program, there is never a "the hook passed but CI disagrees"
split-brain.

## How this goal is achieved (the tests)

The full "how" — which test proves each boundary, and how to run it — lives in
the topic pages:

- **[Overview + coverage matrix](../tests/topics/validator/index.md)** — the boundary → test → layer map.
- **[CI-push layer](../tests/topics/validator/CI-push.md)** — the per-PR merge signal.
- **[CI-nightly layer](../tests/topics/validator/CI-nightly.md)** — the clean-runner nightly re-proof.
- **[local-hook layer](../tests/topics/validator/local-hook.md)** — the commit-boundary hook run.

## Coverage at a glance

| Boundary | Proven at | By |
|----------|-----------|-----|
| Every push / PR | CI-push | `validate` (`.github/workflows/validate.yml`) |
| Nightly, clean runner | CI-nightly | `validate-nightly` (`nightly.yml` → `test.sh` → `validate.sh`) |
| `git commit`, locally | local-hook | `validate-hook` (the `setup-hooks.sh` pre-commit hook) |

No agentic proof is declared for this topic — the validator is deterministic by
nature, and the topic contract treats the local-hook agentic point as advisory
(the check prints a per-topic note, never a finding).
