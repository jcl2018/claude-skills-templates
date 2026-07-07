---
name: "Propagate the contract to other repos, enforced — one-command adopt + a vendored CI gate"
type: feature
id: "F000089"
status: active
created: "2026-07-07"
updated: "2026-07-07"
repo: "E:/projects/claude-skills-templates"
branch: "claude/consumer-contract-adopt"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/consumer_contract_adopt_vendored_gate`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `skills-deploy install-contract-gate` in a consumer repo vendors the 4 gate scripts into `.cj-contract/` + drops `.github/workflows/cj-contract-gate.yml`; `--remove` cleans both up; the workbench self-repo is skipped.
- [ ] The vendored `.cj-contract/cj-contract-gate.sh --repo .` runs with NO `~/.claude/_cj-shared` present (proving it works on a bare CI runner): green on a clean seeded contract, non-zero on a planted structural violation, clean SKIP on an unadopted contract.
- [ ] The one-command adopt is documented (`docs/adopting-the-contract.md`, declared in `spec/doc-spec-custom.md`, ID-free).
- [ ] `test-deploy.sh` covers the vendor + drop + gate-runs + remove + self-repo-skip case.
- [ ] `validate.sh` + the full `scripts/test.sh` green (CI-gated); seed byte-identity intact; shellcheck clean.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000138 — Extend `install-contract-gate` to vendor the 4 gate scripts + drop the CI workflow (consumer-only, self-repo-skip, `--remove` symmetric); add the CI-workflow template; write `docs/adopting-the-contract.md`; extend `test-deploy.sh`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-07: Created. Propagate the doc/test/workflow contract to consumer repos, enforced on push — extend `skills-deploy install-contract-gate` to vendor the gate engines into `.cj-contract/` + drop a CI workflow, plus a one-command-adopt doc.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/skills-deploy` — extend `install-contract-gate` (vendor + drop; `--remove` symmetric)
- `templates/cj-contract-gate.yml` (or embedded heredoc) — CI-workflow template source of truth
- `docs/adopting-the-contract.md` — new declared human-doc (the one-command adopt)
- `spec/doc-spec-custom.md` — declare the new doc
- `scripts/test-deploy.sh` — new vendor/drop/gate-runs/remove/self-skip case

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The gate resolves its engines from its own dir as a last resort (`BASH_SOURCE` dirname), so co-locating the 4 scripts in one vendored `.cj-contract/` dir makes the gate find its siblings on a bare CI runner — no `~/.claude` needed.
- `install-contract-gate` already seeds + completes adoption + installs the pre-commit hook, guarded + self-repo-safe. This feature EXTENDS that one entry point; it does not add a new one.
- Vendor + re-sync (chosen over a reusable workflow / runtime-fetch) matches the workbench's existing `install == clone`, deploy-re-syncs philosophy — offline, no external coupling; drift handled by re-running the deploy.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-07: Chose Approach 1 (Vendor + re-sync) over Approach 2 (reusable GH workflow / action) and Approach 3 (fetch-at-runtime). Rationale: matches the existing install==clone re-sync model, most robust (offline, no external coupling); operator-selected at the 2026-07-07 AUQ after an explainer.
