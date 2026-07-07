---
type: design
parent: F000089
title: "Propagate the contract to other repos, enforced — Feature Design"
version: 1
status: Draft
date: 2026-07-07
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

Phase 3 of the "Testing roadmap → dream test suite" saga. The drift-proofing
contract (doc/test/workflow) should travel to EVERY repo, enforced — not by
copy-paste discipline. The standalone substrate is ~80% built: `test-spec.sh
--seed` drops the portable contract, `skills-deploy install-contract-gate` seeds +
completes adoption + installs a `cj-contract-gate.sh` pre-commit hook, and
`cj-contract-gate.sh` is the registry-gated, engine-only (agent-free) Stage-1
subset of `validate.sh`.

The gap is CI enforcement. The pre-commit hook is bypassable (`git commit
--no-verify`) AND it resolves the gate from `~/.claude/_cj-shared/scripts` — which
a fresh GitHub Actions runner does not have. So a consumer's *push* is not gated:
structural drift does not red the PR for the team. One command in any repo
(`skills-deploy install-contract-gate`) should make structural drift red the PR
there too — the same free automatic gate the workbench enjoys, propagated without
hoping someone runs a hook locally.

## Shape of the solution

Extend the ONE existing entry point (`skills-deploy install-contract-gate`, the
consumer path only; the self-repo stays skipped) so that after seeding + adoption
+ the pre-commit hook it ALSO (a) vendors the 4 gate scripts into `.cj-contract/`
(committed), and (b) drops `.github/workflows/cj-contract-gate.yml` that runs the
vendored gate on push. The gate finds its sibling engines from its own dir on a
bare CI runner, so no `~/.claude` is needed. Drift is re-synced by re-running the
deploy — matching the workbench's `install == clone` model. Ship as a single
user-story; add the one-command-adopt doc + the test-deploy coverage in the same
story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Vendor gate scripts + drop CI workflow; `--remove` symmetric; CI template; adopt doc; test-deploy case | S000138 | [S000138_vendor_gate_ci_workflow/S000138_TRACKER.md](S000138_vendor_gate_ci_workflow/S000138_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach 1 — Vendor + re-sync (copy the 4 gate scripts into `.cj-contract/` + drop a CI workflow) | Self-contained, offline, no external dependency; drift re-synced by re-running the deploy — matches the workbench's `install == clone` / re-sync model. Operator-selected 2026-07-07 after an explainer. |
| 2 | Rejected Approach 2 — reusable GH workflow / action (`uses: jcl2018/...@vX`) | Turnkey but the workbench maintains it forever and the consumer pins a ref (its own staleness knob); public/same-org only. |
| 3 | Rejected Approach 3 — fetch at runtime (clone workbench / download tarball in CI) | Network-dependent + couples the consumer's green build to the workbench being reachable. |
| 4 | EXTEND `install-contract-gate` rather than add a new entry point | It already seeds + completes adoption + installs the pre-commit hook, guarded + self-repo-safe — one command stays one command. |
| 5 | Co-locate all 4 scripts in one vendored dir | The gate resolves engines from its own dir (`BASH_SOURCE` dirname) as last resort, so co-location makes it find its siblings on a bare CI runner without `~/.claude`. |
| 6 | Ship as a single user-story (M-sized) | The change set is one cohesive extension of one entry point plus its doc + test — no parallel sub-units warranting multiple stories. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Clobbering a consumer's hand-authored `cj-contract-gate.yml` | Implementation: skip-with-note if a workflow of that name exists + differs from the sentinel-marked auto-drop (mirror the hook's back-up/skip posture); overwrite only a prior auto-dropped one. |
| Regressing the workbench self-repo (an accidental vendor/CI drop in the workbench) | Implementation: the deploy already skips seeding/adoption for the self-repo; the vendor + CI-template drop must skip it too. Covered by the test-deploy self-repo-skip assertion. |
| Vendored `.cj-contract/` staleness (a consumer's engines lag the workbench) | v1 signal is the stamped-version header on each vendored script; a dedicated advisory staleness check is a deferred follow-up. |
| Should the CI template be a tracked `templates/` file or an embedded heredoc? | Implementation: whichever matches the existing skills-deploy idiom (the pre-commit hook body is embedded); the implementer picks the consistent one, and if it becomes a tracked file, wire it into the relevant `validate.sh` expected-file list. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] `skills-deploy install-contract-gate` in a consumer repo vendors the 4 gate scripts into `.cj-contract/` + drops `.github/workflows/cj-contract-gate.yml`; `--remove` cleans both up; the workbench self-repo is skipped.
- [ ] The vendored `.cj-contract/cj-contract-gate.sh --repo .` runs with NO `~/.claude/_cj-shared` present: green on a clean seeded contract, non-zero on a planted structural violation, clean SKIP on an unadopted contract.
- [ ] The one-command adopt is documented (`docs/adopting-the-contract.md`, declared, ID-free).
- [ ] `test-deploy.sh` covers vendor + drop + gate-runs + remove + self-repo-skip.
- [ ] `validate.sh` + full `scripts/test.sh` green; seed byte-identity intact; shellcheck clean.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- A GitHub composite action (Approach 2) as an additional turnkey path for public consumers — vendoring is the robust default; the action can come later.
- An auto-updating "contract-sync" bot that refreshes a consumer's vendored `.cj-contract/` on a schedule — for now re-run the deploy.
- A dedicated advisory `.cj-contract/` staleness check — the stamped-version header is the v1 signal.
- Any change to the gate's contract itself (`cj-contract-gate.sh` semantics) — nothing new to design there; it IS the minimal enforced contract already.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000089_TRACKER.md](F000089_TRACKER.md)
- Roadmap: [F000089_ROADMAP.md](F000089_ROADMAP.md)
- Child story: [S000138_vendor_gate_ci_workflow/S000138_TRACKER.md](S000138_vendor_gate_ci_workflow/S000138_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-consumer-contract-adopt-design-20260707-021735.md`
- Sibling test-contract features: F000074–F000088 (`work-items/features/ops/`)
