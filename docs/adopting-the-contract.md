# Adopting the drift-proofing contract in your repo

Want structural drift — a stale generated catalog, an undeclared doc, an
unregistered test, a malformed registry — to **red your PR automatically**, the
same way it does in this workbench, without any per-machine hook discipline and
with no `~/.claude` dependency on your CI runner? This page is the one-command
path.

## One command

From the root of your repo (a git repo you own — a *consumer* of the workbench,
not the workbench itself):

```bash
skills-deploy install-contract-gate
```

That single command does four things, in order:

1. **Seeds the contracts.** Writes the three portable contract registries into
   `spec/` — `spec/doc-spec.md` (what docs you carry), `spec/test-spec.md` (what
   tests you carry), `spec/workflow-spec.md` (your workflow docs). Idempotent: an
   existing contract is left alone.
2. **Completes adoption.** Refreshes the generated surfaces (`docs/` catalogs) and
   auto-declares the seeded docs, so your repo is contract-clean from the first
   commit — the gate never bricks a fresh adopter.
3. **Vendors the gate.** Copies the four deterministic gate engines —
   `cj-contract-gate.sh`, `doc-spec.sh`, `test-spec.sh`, `workflow-spec.sh` — into
   a `.cj-contract/` directory in your repo. Each carries a stamped provenance
   header (`# vendored from claude-skills-templates v<version>`) so you can see it
   is generated and how to re-sync it. The four scripts are co-located, so the
   gate finds its sibling engines with nothing installed on the machine — no
   `~/.claude` required.
4. **Drops the CI workflow.** Writes `.github/workflows/cj-contract-gate.yml`, a
   GitHub Actions job that checks out your repo, installs `jq`, and runs
   `bash .cj-contract/cj-contract-gate.sh --repo .` on every `pull_request` and on
   pushes to `main`.

It also installs a local pre-commit hook, so drift is caught at commit time too —
but the vendored gate + workflow are what make your **push** path enforce the
contract on a bare CI runner.

## What to commit

After running the command, commit the two new artifacts:

```bash
git add .cj-contract/ .github/workflows/cj-contract-gate.yml
git commit -m "chore: adopt the contract gate"
```

Also commit the seeded `spec/` registries and the refreshed `docs/` surfaces if
you want the gate to enforce them (the adopt step already made them clean). From
then on, **any structural drift reds the PR**: the CI job exits non-zero when a
declared doc is missing, an orphan doc is undeclared, a test is unregistered, a
generated catalog is stale, or a registry is malformed. A clean repo passes; an
unadopted contract is a clean skip.

## Re-syncing

The vendored scripts are a point-in-time copy stamped with the workbench version.
To pull newer engines, just re-run `skills-deploy install-contract-gate` — it
overwrites the vendored copies (sync semantics) and re-stamps them. Your
hand-edits are never clobbered silently: a workflow you wrote yourself (one
without the vendor sentinel) is left untouched with a note, and only a prior
auto-drop is overwritten.

## Removing it

```bash
skills-deploy install-contract-gate --remove
```

Reverses all of it — the pre-commit hook, `.cj-contract/`, and the dropped
workflow — but **only the workbench-owned, unmodified copies**. Anything you
hand-edited is left in place. Adoption is fully reversible without touching your
own files.

## Why this proves cross-machine

The whole point is that enforcement does not depend on anything installed under
`~/.claude`. Because the four engines are vendored into your repo and the gate
resolves its siblings from its own directory, `bash .cj-contract/cj-contract-gate.sh
--repo .` runs correctly on a fresh GitHub Actions runner — the same green / red /
skip verdicts you get locally. That cross-machine faithfulness is what the
`portability` topic proves for the workbench itself: the same contract, the same
result, on any machine.
