---
name: "Split CI into push/nightly cadence categories; move slow Windows suite to nightly"
type: feature
id: "F000075"
status: active
created: "2026-07-03"
updated: "2026-07-03"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/eloquent-cohen-54b476"
branch: "claude/eloquent-cohen-54b476"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/ci_push_nightly_cadence_split`
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

- [ ] The portable category taxonomy is bumped V1 `{workflow, CI}` → V2 `{workflow, CI-push, CI-nightly}` in BOTH byte-identical copies (`spec/test-spec.md` and the `--seed` heredoc in `scripts/test-spec.sh`); `tests/test-spec.test.sh`'s `cmp -s` seed==file assertion stays green.
- [ ] Every category-enum site in `scripts/test-spec.sh` is updated (parser `--validate` enum + the three `--check-structure` loops), and `--check-structure` folder checks (b/c/d) DERIVE from the distinct declared category values, not a hardcoded three-set — so a consumer declaring only `workflow` + `CI-push` is not forced to create an empty `tests/CI-nightly/`.
- [ ] `spec/test-spec-custom.md` `categories:` axis re-keys the `CI` rows to `CI-push` (`validate`, `suite`, `test-deploy`, `windows`) and ADDS a `windows-deploy` row under `CI-nightly`.
- [ ] Folders + docs renamed: `tests/CI/` → `tests/CI-push/` plus new `tests/CI-nightly/`; `docs/tests/CI/` → `docs/tests/CI-push/` plus `docs/tests/CI-nightly/windows-deploy.md`; `docs/tests/index.md` re-renders from the axis.
- [ ] `spec/doc-spec-custom.md` registry rows for `docs/tests/CI/*.md` are rewritten to `docs/tests/CI-push/*.md` and a `docs/tests/CI-nightly/windows-deploy.md` row is added — in the implementation commit, NOT doc-sync — so `validate.sh` Check 15/15a stays green.
- [ ] `scripts/test-run.sh`'s own hardcoded category enum + the literal error string (`outside the V1 taxonomy {workflow, CI}`) are updated to the V2 set; `--category CI-push` / `--category CI-nightly` select correctly (verified via `--dry-run`).
- [ ] `.github/workflows/windows.yml` keeps `on: pull_request + push [main]` but runs ONLY `windows-smoke.sh` (the `test-deploy.sh` step is dropped) = the fast `CI-push` Windows smoke.
- [ ] NEW `.github/workflows/windows-nightly.yml` runs `test-deploy.sh` on `windows-latest` on `schedule` (cron offset from :00) + `workflow_dispatch`, with `permissions: contents: read`, a `concurrency:` guard, and `defaults: shell: bash` = the `CI-nightly` suite.
- [ ] Both cj_test skills document the V2 cadence taxonomy: `skills/CJ_test_audit/SKILL.md` + `USAGE.md` (the `--check-structure` set + new folders) and `skills/CJ_test_run/SKILL.md` + `USAGE.md` (`--category CI-push|CI-nightly`).
- [ ] Tests updated: `tests/test-spec.test.sh` (V2 enum + derive-from-declared-categories folder logic + `CI-push`/`CI-nightly` coverage, `--seed` byte-identity green) and `tests/test-run.test.sh` (new `--category CI-push`/`CI-nightly` selection cases + the updated negative enum-rejection test).
- [ ] `CLAUDE.md` taxonomy + Windows-CI references updated to V2 (folded in via doc-sync); full `test.sh` green + `validate.sh` green (esp. Checks 15/15a, 24, 26, 28) + shellcheck clean.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Deliverable 1 — portable seed + parser taxonomy V2 bump (`spec/test-spec.md` + `scripts/test-spec.sh` seed heredoc, both byte-identical copies; every category-enum site; derive `--check-structure` folder checks from declared categories)
- [ ] Deliverable 2 — contract overlay rows (`spec/test-spec-custom.md` `categories:` re-key + `windows-deploy` `CI-nightly` row; block-comment V1→V2 update; `runners:` coherence)
- [ ] Deliverable 3 — folders + docs + the `spec/doc-spec-custom.md` registry rewrite (BLOCKER; belongs in the code commit, not doc-sync)
- [ ] Deliverable 4 — `scripts/test-run.sh` enum + error string V2
- [ ] Deliverable 5 — actual CI workflows (`windows.yml` fast smoke; new `windows-nightly.yml`)
- [ ] Deliverable 6 — the two cj_test skills' SKILL.md + USAGE.md
- [ ] Deliverable 7 — tests (`tests/test-spec.test.sh` + `tests/test-run.test.sh`)
- [ ] Deliverable 8 — convention docs (`CLAUDE.md`, via doc-sync) + confirm `validate.sh` Check 15/15a green post-rename

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-03: Created. Split CI into push/nightly cadence categories and move the slow Windows `test-deploy.sh` suite off the PR path to a nightly schedule; taxonomy V2 `{workflow, CI-push, CI-nightly}`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec.md` (portable seed — taxonomy V2)
- `scripts/test-spec.sh` (`--seed` heredoc + every category-enum site + `--check-structure` derive-from-declared)
- `spec/test-spec-custom.md` (`categories:` axis re-key + `windows-deploy` row)
- `spec/doc-spec-custom.md` (registry rows for the renamed/new `docs/tests/` paths)
- `scripts/test-run.sh` (category enum + error string)
- `tests/CI/` → `tests/CI-push/`, new `tests/CI-nightly/`
- `docs/tests/CI/` → `docs/tests/CI-push/`, new `docs/tests/CI-nightly/windows-deploy.md`, `docs/tests/index.md`
- `.github/workflows/windows.yml`, new `.github/workflows/windows-nightly.yml`
- `skills/CJ_test_audit/SKILL.md` + `USAGE.md`, `skills/CJ_test_run/SKILL.md` + `USAGE.md`
- `tests/test-spec.test.sh`, `tests/test-run.test.sh`
- `CLAUDE.md`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The operator went for the second-order problem: not "make the Windows job faster" but "the two cj_test skills should KNOW the split." The contract is being designed, not the symptom patched.
- Taxonomy expansion was chosen over an orthogonal `cadence:` field so the category name IS the cadence — `--category CI-push`/`CI-nightly` is the whole selection API, no new flag.
- A fast Windows check is deliberately KEPT on PRs (`windows-smoke.sh`); only the slow native-Windows `test-deploy.sh` moves to nightly — protecting the per-PR signal, not just chasing speed.
- Key correctness fix from spec review: `--check-structure` folder checks (b/c/d) must DERIVE from the distinct declared categories, else the V2 seed would force an empty `tests/CI-nightly/` on THIS repo AND every consumer that upgrades the seed — silently red-ing consumers that declare no nightly test.
- The `spec/doc-spec-custom.md` rewrite is doc-CONTRACT (registry) editing and MUST land in the implementation commit, not Step 5.5 doc-sync — otherwise Check 15/15a hard-fails on orphaned/undeclared `docs/tests/` paths.
- Case-insensitive-FS trap: the lowercase `docs/tests/ci.md` is the `ci` FAMILY render (units axis), unrelated to the `CI` category dir — do NOT rename it.
- No `platform:` field on the `categories:` axis means `--category CI-nightly` runs `test-deploy.sh` on the LOCAL platform locally, not a real `windows-latest` run — the value is intent-declaration + audit cross-check; a `platform:` field is a deferred refinement.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-03 — Change the real `.github/workflows/windows.yml`, not just the contract. Summary: operator rejected a "contract only" option; the slow Windows work actually moves off the PR path.
- [decision] 2026-07-03 — Keep a fast Windows check on PRs. Summary: `windows-smoke.sh` stays PR-gating (`CI-push`); only the slow `test-deploy.sh`-on-`windows-latest` run moves to nightly (`CI-nightly`). Accepted tradeoff: a PR still pays a smaller `windows-latest` spin-up; native-Windows `test-deploy` regressions surface nightly.
- [decision] 2026-07-03 — Model the split by expanding the category taxonomy, not an orthogonal `cadence:` field. Summary: cadence IS the category, so `--category` is the selection mechanism and no new flag is needed. Effectively V2 of the portable taxonomy inherited by consumer repos.
- [decision] 2026-07-03 — `--check-structure` folder checks derive from declared categories (spec-review blocker fix). Summary: iterate the DISTINCT category values present in the overlay's `categories:` rows instead of hardcoding three, so upgrading the seed does not force an empty `tests/CI-nightly/` on every consumer.
- [decision] 2026-07-03 — Keep `test-deploy` (ubuntu/push) AND `windows-deploy` (nightly) as two rows. Summary: same script, two distinct CI contexts (platform + cadence); the two per-test docs must explain WHY the same command appears twice; a `platform:` field is the deferred refinement.
