---
type: design
parent: S000138
title: "Vendor the gate + drop the CI workflow — Design"
version: 1
status: Draft
date: 2026-07-07
author: chang
reviewers: []
---

<!-- Atomic story: derives directly from the parent feature's /office-hours
     session. See the parent F000089_DESIGN.md for the full cross-story
     context, approaches considered, and big decisions. This is a brief stub
     scoping the one story. -->

## Problem

A consumer repo that runs `skills-deploy install-contract-gate` today gets the
contracts seeded, adoption completed, and a pre-commit hook — but its *push* is
still not gated. The hook is bypassable (`--no-verify`) and resolves the gate from
`~/.claude/_cj-shared`, which a fresh GitHub Actions runner does not have. So
structural drift never reds the consumer's PR for the team. This story closes that
gap: vendor the gate engines into the repo and drop a CI workflow that runs them.

## Shape of the solution

Extend `install-contract-gate` (consumer path only; self-repo skipped) so that,
after the existing seed + adopt + hook install, it also: (a) copies
`cj-contract-gate.sh` + `doc-spec.sh` + `test-spec.sh` + `workflow-spec.sh` into
`<consumer>/.cj-contract/` (stamped header, LF, `+x`, overwrite-by-default); and
(b) drops `.github/workflows/cj-contract-gate.yml` from a workbench-shipped
template that runs `bash .cj-contract/cj-contract-gate.sh --repo .` on
pull_request + push:main. `--remove` deletes both (sentinel-marked / unmodified
only). Add `docs/adopting-the-contract.md` + a `test-deploy.sh` case.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Vendor into one dir + rely on the gate's `BASH_SOURCE`-dirname engine resolution | Makes the gate self-contained on a bare runner without `~/.claude`. |
| 2 | Skip-with-note on a differing hand-authored `cj-contract-gate.yml`; overwrite only a prior auto-drop | Mirrors the pre-commit hook's back-up/skip posture; never clobber operator work. |
| 3 | `--remove` is sentinel-gated | Symmetric with the hook removal; never delete a consumer's hand-edits. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| CI template as a tracked `templates/` file vs an embedded heredoc | Implementation: match the existing skills-deploy idiom (hook body is embedded); wire a tracked file into the relevant `validate.sh` expected-file list. |
| Self-repo accidentally receiving a vendor/CI drop | Covered by the test-deploy self-repo-skip assertion; the deploy already skips seeding/adoption for the self-repo. |

## Definition of done

- [ ] Vendor + drop + `--remove` + self-repo-skip all behave per the parent DoD.
- [ ] Bare-runner gate proof passes (green / red / SKIP, no `_cj-shared`).
- [ ] `docs/adopting-the-contract.md` declared + ID-free; `test-deploy.sh` case green.

## Not in scope

- Reusable GH action, contract-sync bot, staleness check — deferred (see parent).
- Any change to `cj-contract-gate.sh` contract semantics — it is unchanged.

## Pointers

- Parent feature design: [../F000089_DESIGN.md](../F000089_DESIGN.md)
- Parent tracker: [../F000089_TRACKER.md](../F000089_TRACKER.md)
- Story tracker: [S000138_TRACKER.md](S000138_TRACKER.md)
- Spec: [S000138_SPEC.md](S000138_SPEC.md)
- Test spec: [S000138_TEST-SPEC.md](S000138_TEST-SPEC.md)
