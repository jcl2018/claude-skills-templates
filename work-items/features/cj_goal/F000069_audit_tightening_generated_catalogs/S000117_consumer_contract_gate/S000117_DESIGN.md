---
type: design
parent: S000117
title: "Consumer-repo deterministic Stage-1 enforcement gate — Story Design"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
reviewers: []
---

<!-- Atomic story design. Full epic context: ../F000069_DESIGN.md and the parent's
     /office-hours design doc (Part 4 / U3). Story-4 design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/contract-gate-design-20260629-114124.md -->

## Problem

After Stories 1-3 a consumer repo HAS the contracts (seeded, reliable) and the
audits RUN on demand — but nothing FORCES the check. A developer can commit a
contract-violating change (a stale generated catalog, an unregistered test, a
malformed registry) and not know until someone manually runs `/CJ_doc_audit` /
`/CJ_test_audit`. The workbench enforces its own contract via a `validate.sh`
pre-commit hook; a consumer has no equivalent. This is the "enforced in each repo"
half of the original ask — the FINAL piece of the F000069 epic.

## Shape of the solution

A deterministic **`scripts/cj-contract-gate.sh`** — the engine-only (Stage-1)
checks, runnable with NO agent — installable as a consumer **pre-commit hook**
(auto on consumer adoption, guarded) plus a documented **CI snippet**, so a
contract violation fails the commit / the PR automatically.

| Part | Mechanism | Where |
|------|-----------|-------|
| The gate | `cj-contract-gate.sh` — resolve each engine (repo-local → stale-probe → `_cj-shared`), run the deterministic checks against cwd; `declared-exists` soft, registry-gated SKIPs, non-zero iff any HARD finding; `--quiet` | `scripts/cj-contract-gate.sh` (deployed to `_cj-shared`) |
| Auto-install (guarded) | extend `do_install`'s consumer-path block (the Story-3 seeding hook) to ALSO install the gate pre-commit hook, reusing `setup-hooks.sh`'s `install_hook` safety | `scripts/skills-deploy` (+ `scripts/setup-hooks.sh`) |
| Standalone command | `skills-deploy install-contract-gate` (install) + `--remove` (uninstall the sentinel hook) + usage | `scripts/skills-deploy` |
| CI snippet (doc-only) | a GitHub Actions copy-paste snippet that runs the gate on PRs | `docs/architecture.md` / `CLAUDE.md` |

```
consumer `git commit`
        │
        ▼  .git/hooks/pre-commit  (sentinel-carrying; installed guarded)
   cj-contract-gate.sh
        │  resolve engines (repo-local → STALE-PROBE → _cj-shared)
        ▼  run the DETERMINISTIC checks (registry-gated; declared-exists SOFT):
        doc-spec.sh --check-on-disk            HARD except declared-exists → REMEDIATION
        test-spec.sh --validate --check-coverage  HARD (rules-only ⇒ inactive)
        workflow-spec.sh --validate            HARD (no-vanish)
        test-spec.sh --render-docs --check     HARD freshness when a generated surface exists
        workflow-spec.sh --render-docs --check HARD freshness when a generated surface exists
        │  REGISTRY=absent ⇒ clean SKIP (exit 0 for that check)
        ▼
   non-zero iff any HARD check finds a violation ⇒ blocks the commit
```

The gate is the engine-only (Stage-1) subset of `validate.sh` (the deterministic
cores of Checks 15a/16/17/19/24/26/27) — NOT the agent-judged Stage 2/3, which a
git hook / CI step cannot run.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Auto-install on consumer install, guarded (operator chose) | Symmetric with Story 3's seeding: `skills-deploy install` from a consumer repo ALSO installs the pre-commit hook, reusing `setup-hooks.sh`'s `install_hook` safety. PLUS a standalone install/remove command. The workbench self-repo is skipped (it has `validate.sh` — no double-enforcement). |
| 2 | `declared-exists` is SOFT; everything else is a hard block | A freshly-seeded consumer has the contracts but not yet the declared docs, so blocking its next commit on "declared doc missing" would brick adoption. The gate prints `declared-exists` as a REMEDIATION note (pointing at `/CJ_document-release`) and does NOT block on it. |
| 3 | The gate is the engine-only (Stage-1) subset of `validate.sh` | A git hook / CI step can't run an agent. The gate runs only the deterministic engine checks; Stage 2/3 (requirement compliance + implementation drift) stay agent-judged and out of the gate. |
| 4 | Reuse the Story-3 stale-engine `--classify` probe in engine resolution | A consumer that vendored a stale `scripts/<engine>.sh` would otherwise shadow `_cj-shared`. The gate resolves repo-local → stale-probe → `_cj-shared`, falling back cleanly so a stale engine never silently mis-gates. |
| 5 | Registry-gated throughout | An absent contract (`REGISTRY=absent`) is a clean SKIP (exit 0 for that check) — a repo that hasn't adopted a given contract isn't blocked by it. |
| 6 | Factor `install_hook` into ONE shared helper (preferred) | `setup-hooks.sh` + `skills-deploy` should share ONE safe hook-install implementation rather than two drifting copies; if extraction is risky, mirror the exact behavior + a parity test. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Auto-installing a git hook is intrusive | Implement: the `install_hook` back-up-and-warn safety, the custom-`core.hooksPath`/husky SKIP, the workbench-self SKIP, the standalone `--remove`, and the `declared-exists`-soft rule together keep a fresh adopter from being bricked. |
| Cross-machine — not fully E2E-verifiable in the workbench | Implement: temp-dir drills (a fake consumer repo) in the hermetic test + `test-deploy.sh` exercise the install/skip/remove logic deterministically. |
| `install_hook` reuse risk (two drifting copies) | Implement: factor carefully so `setup-hooks.sh` + the new consumer install share ONE safe implementation; if extraction is risky, mirror the exact behavior + a test asserting parity. |
| shellcheck (CI strict) | Implement: the new bash must be clean — quote expansions, `git -C` not `cd &&`, no `local x=$(...)` masking. |
| `skills-deploy` is a sensitive deploy surface | PR-stop + human review is the gate; the change is additive (a new script + a new subcommand + a guarded consumer-only hook). |
| A new test must register in the test contract | Implement: add the `spec/test-spec-custom.md` units row(s) AND the `scripts/test.sh` runner block so Check 24 reverse-sweep resolves the new test (else a hard failure). |

## Definition of done

- [ ] `scripts/cj-contract-gate.sh` exists: engine-resolve (repo-local → stale-probe → `_cj-shared`); runs `doc-spec.sh --check-on-disk` (HARD except `declared-exists` → SOFT remediation), `test-spec.sh --validate --check-coverage` (HARD; rules-only ⇒ "inactive"), `workflow-spec.sh --validate` (HARD), `test-spec.sh --render-docs --check` + `workflow-spec.sh --render-docs --check` (HARD freshness when a generated surface exists); registry-gated SKIPs; non-zero iff any HARD finding; compact per-check summary; `--quiet`.
- [ ] `cj-contract-gate.sh` is added to the shared-scripts deploy set in `scripts/skills-deploy` so `install` ships it to `_cj-shared`.
- [ ] `do_install`'s consumer-path block ALSO installs the gate pre-commit hook (guarded: sentinel-aware idempotent; back-up-non-workbench-with-WARN; SKIP custom `core.hooksPath`/husky with a note; workbench-self SKIP; non-git no-op); the hook body carries the `setup-hooks` SENTINEL.
- [ ] `skills-deploy install-contract-gate` (install on cwd) + `--remove` (uninstall the sentinel hook; leave a non-workbench hook untouched) + a usage line.
- [ ] A GitHub Actions CI snippet in `docs/architecture.md` / `CLAUDE.md` runs `cj-contract-gate.sh` on PRs (doc-only; no workflow file shipped into consumers).
- [ ] `scripts/test-deploy.sh` covers the gate-hook auto-install (consumer install → sentinel hook; husky/custom-hookspath skipped; workbench-self skipped; `--remove` uninstalls).
- [ ] NEW hermetic `tests/cj-contract-gate.test.sh` proves: (a) gate PASS on a clean contract, hard-FAIL on a planted violation, `declared-exists` soft (exit 0), registry-absent SKIP; (b) consumer auto-install installs a sentinel hook, SKIPS a custom `core.hooksPath`, SKIPS the workbench self-repo, `--remove` uninstalls; ends `RESULT: PASS/FAIL`.
- [ ] `spec/test-spec-custom.md` units row(s) added + `scripts/test.sh` runner block wired; Check 24 reverse-sweep resolves the new test.
- [ ] `scripts/validate.sh` 0/0; `scripts/test.sh` green incl. the new test + test-deploy coverage; shellcheck clean (CI strict); post-sync `/CJ_doc_audit` + `/CJ_test_audit` report 0 findings.

## Not in scope

- The test catalog generation (Story 1 — S000114, shipped), the workflow generation (Story 2 — S000115, shipped), and the forced contract seeding + stale-engine fix (Story 3 — S000116, shipped) — separate, already-landed stories.
- The agent-judged Stage 2/3 audits (requirement compliance + implementation drift) — a git hook / CI step can't run an agent; the gate is the deterministic Stage-1 subset only.
- Shipping a GitHub Actions workflow FILE into consumers — the CI surface is a documented copy-paste snippet only, no `.github/workflows/*.yml` written into adopting repos.
- Bumping VERSION / CHANGELOG — `/ship` owns that.
- Editing upstream gstack skills.

## Pointers

- Parent feature design: [../F000069_DESIGN.md](../F000069_DESIGN.md)
- Story tracker: [S000117_TRACKER.md](S000117_TRACKER.md)
- Story spec: [S000117_SPEC.md](S000117_SPEC.md)
- Story test-spec: [S000117_TEST-SPEC.md](S000117_TEST-SPEC.md)
- Sibling stories: [../S000114_gen_tests_catalog_freshness/S000114_SPEC.md](../S000114_gen_tests_catalog_freshness/S000114_SPEC.md) (test-catalog generation), [../S000115_workflows_full_symmetric_generation/S000115_SPEC.md](../S000115_workflows_full_symmetric_generation/S000115_SPEC.md) (workflow generation), [../S000116_forced_contract_seeding/S000116_SPEC.md](../S000116_forced_contract_seeding/S000116_SPEC.md) (forced seeding + stale-engine `--classify` probe this story reuses)
- Reference primitives: `scripts/setup-hooks.sh` `install_hook` (sentinel-aware idempotent hook install + back-up safety); the Story-3 stale-engine `--classify` capability probe in `scripts/skills-deploy` engine resolution; the deterministic check engines `scripts/doc-spec.sh` / `scripts/test-spec.sh` / `scripts/workflow-spec.sh`; `scripts/validate.sh` Checks 15a/16/17/19/24/26/27 (the gate is their engine-only subset)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/contract-gate-design-20260629-114124.md` (Part 4 / U3)
