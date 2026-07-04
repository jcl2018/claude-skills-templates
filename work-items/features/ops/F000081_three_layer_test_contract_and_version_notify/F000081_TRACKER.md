---
name: "Three-layer test contract per category + portability reclass + git version-notification + retire CJ_portability-audit"
type: feature
id: "F000081"
status: active
created: "2026-07-04"
updated: "2026-07-04"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/ecstatic-greider-fb1178"
branch: "claude/ecstatic-greider-fb1178"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/three_layer_test_contract_and_version_notify`
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

- [ ] `test-spec.sh --seed` stays byte-identical to the edited `spec/test-spec.md` (the `seed-byte-identical` contract test passes).
- [ ] `--check-structure` prints the per-category × 3-layer `{CI-push, CI-nightly, local-hook}` coverage matrix + an advisory `NOTE:` per empty cell, exit 0 always (never hard-fails an intentionally-empty cell).
- [ ] The two portability `categories:` rows read `category: infra` (`portability-smoke` stays CI-push, `portability-deploy` stays CI-nightly); the four front-door docs live under `docs/tests/infra/…`; `spec/doc-spec.md` updated for the four old/new paths; Checks 15a/16/26/27 green.
- [ ] Portability's local-hook cell is backfilled by a command-only `categories:` `portability-version-check` (infra/local-hook) row.
- [ ] `skills-update-check`, given a `.source`-absent manifest + a stubbed `git ls-remote`, emits `SKILLS_UPGRADE_AVAILABLE <local> <remote>` when remote > local, is silent when equal, and fail-soft when the remote is unreachable — proven by the new root `tests/skills-update-check.test.sh` (Check 24 reverse sweep green).
- [ ] `.github/workflows/nightly.yml` exists (cron + `workflow_dispatch`, full `scripts/test.sh` on ubuntu) and is registered as a `ci` `units:` row (Check 24 green); the `validate.yml` per-PR trim is NOT done this feature (deferred follow-up).
- [ ] Each negative test in `test.sh` is targeted (invokes only its one check, not the whole `validate.sh`), killing the ~16× re-run OOM flake; each negative still catches its fault.
- [ ] `/CJ_portability-audit` is retired (catalog / skill dir / routing / workflow-spec / philosophy) with the engine `scripts/cj-portability-audit.sh` + Check 18 intact; whole `validate.sh` green.
- [ ] VERSION bumped; README + generated catalogs regenerated.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] WS1 — contract prose (three test levels per category) in `spec/test-spec.md` + byte-identical `test-spec.sh --seed` heredoc + advisory per-category × 3-layer matrix in `--check-structure` + fixture tests in `tests/test-spec.test.sh`.
- [ ] WS3 — rework `scripts/skills-update-check` to be checkout-independent via `git ls-remote --tags`; remove the `.git`-gate (line ~198); add the root `tests/skills-update-check.test.sh` + its `units:` row.
- [ ] WS2 — flip the two portability `categories:` rows to `infra`; hand-move the two front-door docs under `docs/tests/infra/…`; edit the four `spec/doc-spec.md` rows; regenerate the flat catalog; add the `portability-version-check` local-hook command-row (+ optional Check-18 infra/CI-push lint row).
- [ ] WS5 — retire `/CJ_portability-audit` across all consistency touchpoints (catalog, skill dir, routing, workflow-spec, philosophy); keep the engine + Check 18; CHANGELOG the retirement.
- [ ] WS4 — add `.github/workflows/nightly.yml` + register the `ci` unit; targeted-negative-test refactor in `test.sh` (DEFER the `validate.yml` trim).
- [ ] Regenerate README + catalogs, bump VERSION, `/ship` to a PR (STOP — human review).
- [ ] File the deferred follow-up work-item: trim `validate.yml`'s per-PR coverage + the matching `layer` reclass of the moved units to `CI-nightly`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-04: Created. Three-layer test contract per category + portability→infra reclass + git ls-remote version-notification + retire /CJ_portability-audit. Scaffolded from the APPROVED /office-hours design doc.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (general contract prose + byte-identical seed)
- `scripts/test-spec.sh` (`--seed` heredoc + advisory `--check-structure` matrix)
- `spec/test-spec-custom.md` (portability rows → infra; `portability-version-check` + optional Check-18 rows; the `nightly.yml` `ci` unit row; engine-row `purpose` edit)
- `spec/doc-spec.md` (four portability front-door doc paths old→new)
- `docs/tests/infra/CI-push/portability-smoke.md`, `docs/tests/infra/CI-nightly/portability-deploy.md` (hand-moved front-door docs)
- `scripts/skills-update-check` (git ls-remote rework; `.git`-gate removal)
- `tests/skills-update-check.test.sh` (new root unit test)
- `tests/test-spec.test.sh` (advisory-matrix fixture cases)
- `.github/workflows/nightly.yml` (new nightly full-suite workflow)
- `scripts/test.sh` (targeted-negative-test refactor)
- `skills-catalog.json`, `skills/CJ_portability-audit/`, `rules/skill-routing.md`, `CLAUDE.md`, `spec/workflow-spec.md`, `docs/workflows/utility-audits.md`, `docs/philosophy.md`, `CHANGELOG.md` (retirement touchpoints)
- `VERSION`, `README.md`, `docs/test-catalog.md`, `docs/workflow.md` (regeneration)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The five parts reinforce each other into one change: portability→infra reclass (WS2) is a concrete INSTANCE of the three-layer contract (WS1); the git version-notification (WS3) is exactly portability's missing **local-hook** proof; the CI work (WS4) cashes in the `ci-push-gate-fast-only` directive; retiring `/CJ_portability-audit` (WS5) is the punchline — portability stops being a verb you remember to run and becomes a property the contract proves automatically (the engine/Check 18 keeps working).
- The design was revised after an adversarial review (5/10 → corrected) that caught a false curl-precedent premise, a test-home contradiction, an unregistered new workflow, missing doc-spec updates, and an unsafe-to-automate CI trim — all folded in. Two decisions that contradicted earlier calls were re-confirmed with the user: **`git ls-remote`** (not curl — the repo has ZERO curl precedent; `grep curl scripts/` = 0) and **safe-additive CI now, defer the trim**.
- The single most fragile edit is the `spec/test-spec.md` ↔ `test-spec.sh --seed` byte-identity: the seed emitter is a heredoc INSIDE `test-spec.sh`, so WS1 must edit both in lockstep or the test-spec suite goes red.
- `test`-family units live at repo ROOT (`source: scripts/test.sh`, anchor `tests/<name>.test.sh`); the reverse sweep globs `tests/*.test.sh` at root only. Category-axis cells are filled by command-only `categories:` rows (exempt from `--check-structure` (b)), NOT by moving test files under `tests/<cat>/<layer>/`.
- `layer` records the owning cadence, `trigger` the firing points — do NOT relabel a unit's `layer` to `CI-nightly` while it still runs per-PR (that is a contract lie the reverse sweep won't catch). This is why the deferred units KEEP `layer: CI-push` until the deferred trim.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-04 — Part 3 remote read uses `git ls-remote` on `upstream_url` (CHOSEN) over curl-raw (rejected: zero repo precedent, github.com-https-only) and gh-api-embed (rejected: too much state + auth). Summary: git is this repo's vetted hard dependency and handles ssh / non-GitHub upstream URLs a raw curl can't.
- [decision] 2026-07-04 — CI rewiring is safe-additive-now-defer-trim (CHOSEN) over all-now (rejected: an autonomous PR-stop can't verify a trimmed gate) and all-deferred (rejected: loses the free, in-PR-verifiable OOM fix + nightly infra). Summary: add the nightly workflow + the targeted-negative-test refactor now; the `validate.yml` trim + layer-reclass is a separate attended follow-up.
- [decision] 2026-07-04 — Coverage matrix is ADVISORY (Q1): report the matrix + backfill sensible cells; empty cells are `NOTE:`s, never hard-fails; `--check-structure` keeps its "findings are the product, exit 0 always" posture.
- [decision] 2026-07-04 — Ship all five workstreams as ONE feature / ONE PR (Q2): the parts lock together and the enum/contract change is cohesive.
- [decision] 2026-07-04 — Part 2 reclassifies the two `categories:` TEST rows only; it does NOT touch the `CJ_portability-audit` catalog `portability` tier or Check 18 (the engine + its per-PR lint stay).
