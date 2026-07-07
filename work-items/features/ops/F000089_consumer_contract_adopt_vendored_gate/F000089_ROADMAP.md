---
type: roadmap
parent: F000089
title: "Propagate the contract to other repos, enforced — Roadmap"
date: 2026-07-07
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Make the doc/test/workflow drift-proofing contract self-propagating and enforced
on push in any consumer repo. Extend the existing `skills-deploy
install-contract-gate` (consumer path only) so that, alongside the seeding +
adoption + pre-commit hook it already does, it vendors the 4 gate engine scripts
into a committed `.cj-contract/` dir and drops a `.github/workflows/cj-contract-gate.yml`
that runs the vendored gate — so structural drift reds the PR on a bare CI runner,
agent-free and at $0, with no `~/.claude` dependency. Ship with a one-command-adopt
doc and isolated-temp-dir deploy-harness coverage.

## Non-Goals

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and why.
     Prevents scope creep during Implement and gives reviewers an unambiguous
     boundary. -->

- A reusable GH workflow / composite action for public consumers — deferred; vendoring is the robust default.
- An auto-updating "contract-sync" bot for a consumer's vendored `.cj-contract/` — for now re-run the deploy.
- A dedicated advisory `.cj-contract/` staleness check — the stamped-version header is the v1 signal.
- Any change to the gate's contract semantics — `cj-contract-gate.sh` already IS the minimal enforced contract.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] `skills-deploy install-contract-gate` in a consumer repo vendors the 4 gate scripts into `.cj-contract/` + drops `.github/workflows/cj-contract-gate.yml`; `--remove` cleans both up; the workbench self-repo is skipped.
- [ ] The vendored `.cj-contract/cj-contract-gate.sh --repo .` runs with NO `~/.claude/_cj-shared` present: green on a clean seeded contract, non-zero on a planted structural violation, clean SKIP on an unadopted contract.
- [ ] `docs/adopting-the-contract.md` exists, is declared in `spec/doc-spec-custom.md`, and carries no work-item IDs.
- [ ] `test-deploy.sh` covers vendor + drop + gate-runs + remove + self-repo-skip.
- [ ] `validate.sh` + full `scripts/test.sh` green; seed byte-identity intact; shellcheck clean.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000138](S000138_vendor_gate_ci_workflow/S000138_TRACKER.md) | Vendor the gate + drop the CI workflow (adopt doc + test-deploy case) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000138 (vendor + drop + `--remove` + CI template + adopt doc + test-deploy case) | — | Not Started | chang | The whole feature in one story | — |
| 2 | End-to-end pipeline run (bare-runner gate proof: green / red / SKIP with no `_cj-shared`) | — | Not Started | chang | Proves CI would gate a consumer | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-07-07: Scaffolded from the APPROVED /office-hours design (F000089).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000138 (vendor + drop + remove + CI template + adopt doc + test-deploy)
      --> #2 End-to-end pipeline run (bare-runner gate proof)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| CI template as a tracked `templates/` file vs an embedded heredoc in skills-deploy? | Implementation: pick whichever matches the existing skills-deploy idiom (hook body is embedded); if tracked, wire into the relevant `validate.sh` expected-file list. |
| Should `--remove` also delete a `.cj-contract/` that a consumer hand-edited? | Implementation: remove only sentinel-marked / unmodified files, symmetric with the hook removal. |
