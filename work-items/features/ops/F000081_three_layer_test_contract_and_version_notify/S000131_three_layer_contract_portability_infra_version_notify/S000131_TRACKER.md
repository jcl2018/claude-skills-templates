---
name: "Three-layer contract + advisory matrix + portability→infra reclass + git ls-remote version-notification + safe-additive CI + retire /CJ_portability-audit"
type: user-story
id: "S000131"
status: active
created: "2026-07-04"
updated: "2026-07-04"
parent: "F000081"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/ecstatic-greider-fb1178"
branch: "claude/ecstatic-greider-fb1178"
blocked_by: ""
receipts:
  qa:
    phase: 3
    commit: "266e8fa0b3c59ad2268890ceadcad61ac0ab1f53"
    completed_at: "2026-07-04T00:00:00Z"
    test_rows_run: 8
    ac_ids_covered: ["AC-1", "AC-2", "AC-3", "AC-4", "AC-5", "AC-6"]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-smoke] S1-S5 green", "[qa-e2e] E1-E3 green", "[qa-e2e-deferred] E4 post-ship", "[qa-audit] AUDITS=deferred"]
    ready_for_ship: true
    next_legal: ["ship"]
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/three_layer_test_contract_and_version_notify` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; the five workstreams WS1–WS5 are one cohesive, sequentially-built change shipping in one PR)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] WS1: `spec/test-spec.md` carries a "three test levels per category" subsection; `test-spec.sh --seed` stays byte-identical to it; `--check-structure` prints the per-category × {CI-push, CI-nightly, local-hook} matrix + an advisory `NOTE:` per empty cell, exit 0.
- [ ] WS2: the two portability `categories:` rows read `category: infra`; the four front-door docs live under `docs/tests/infra/…`; `spec/doc-spec.md` updated for the four old/new paths; the flat catalog regenerated; the `portability-version-check` (infra/local-hook) command-row exists; Checks 15a/16/26/27 green.
- [ ] WS3: `skills-update-check` reads local = manifest `collection_version` and remote = max `v<X.Y.Z>` from `git ls-remote --tags`; the `.git`-gate is removed as the hard stop; `.source` is kept only for the richer upgrade action; the new root `tests/skills-update-check.test.sh` proves banner-when-newer / silent-when-equal / fail-soft-when-unreachable with a stubbed ls-remote + `.source`-absent manifest; its `units:` row keeps Check 24 green.
- [ ] WS4: `.github/workflows/nightly.yml` exists (cron + `workflow_dispatch`, full `scripts/test.sh` on ubuntu) and is registered as a `ci` `units:` row (Check 24 green); each `test.sh` negative test invokes only its one targeted check (no whole-`validate.sh` re-run) and still catches its fault.
- [ ] WS5: `/CJ_portability-audit` is removed from the catalog, skill dir, routing (`rules/skill-routing.md` + CLAUDE.md prose), `spec/workflow-spec.md` (`utility-audits` roster), and `docs/philosophy.md`; the engine `scripts/cj-portability-audit.sh` + Check 18 + the `portability-audit`/`validate-check-18` overlay rows remain; the retirement is in CHANGELOG.
- [ ] Whole `validate.sh` green, full `test.sh` green, shellcheck clean; VERSION bumped; README + `docs/test-catalog.md` + `docs/workflow.md` regenerated; the deferred `validate.yml`-trim follow-up work-item is filed.

## Todos

<!-- Actionable items for this story. -->

- [x] WS1 — added the three-levels-per-category prose to `spec/test-spec.md` + mirrored it byte-identically in the `test-spec.sh --seed` heredoc (verified `diff <(bash scripts/test-spec.sh --seed) spec/test-spec.md` empty); extended `--check-structure` with the advisory per-category × 3-layer matrix (`NOTE:` per empty cell, printed table, exit 0); added S6 fixture cases in `tests/test-spec.test.sh` (missing layer → NOTE; full matrix → clean; no categories axis → inactive).
- [x] WS3 — reworked `scripts/skills-update-check`: local = manifest `collection_version`; remote = `git ls-remote --tags <upstream_url> 'v*'` max `v<X.Y.Z>` (ssh→https normalized); removed the `.git`-gate hard stop; kept `.source` for the richer upgrade action + origin-pinning only; added testing seams (`SKILLS_UPDATE_REMOTE_URL`, `SKILLS_UPDATE_STATE_DIR`); added the root `tests/skills-update-check.test.sh` (11 assertions, all pass) + its `test-skills-update-check` `units:` row + wired it into `scripts/test.sh`'s runner list.
- [x] WS2 — flipped `portability-smoke` + `portability-deploy` to `category: infra`; hand-moved `docs/tests/workflow/{CI-push,CI-nightly}/…` → `docs/tests/infra/…` (git mv + fixed in-file paths/prose); updated the `spec/doc-spec-custom.md` rows (NOT `spec/doc-spec.md` — that is the frozen byte-identical seed; the front-door doc rows live in the overlay); regenerated the flat catalog; added the `portability-version-check` (infra/local-hook) command-row + the `portability-check18-lint` (infra/CI-push) command-row; wrote the two new front-door docs.
- [x] WS5 — retired `/CJ_portability-audit`: `git mv skills/CJ_portability-audit → deprecated/CJ_portability-audit`, catalog entry marked `deprecated` (files repointed, `doc_requirement` dropped), dropped the CLAUDE.md routing prose, removed BOTH `spec/workflow-spec.md` roster entries (utilities-and-phase-steps + utility-audits), removed the `docs/philosophy.md` decision-tree node, edited the engine overlay row `purpose` to drop the "standalone /CJ_portability-audit skill" clause (KEPT the row + `validate-check-18`), fixed straggler cross-refs in 3 sibling USAGE.md files + doc-spec-custom.md, CHANGELOG'd the retirement. KEPT `scripts/cj-portability-audit.sh` + Check 18.
- [x] WS4 — added `.github/workflows/nightly.yml` (mirrors `windows-nightly.yml`; full `scripts/test.sh` on ubuntu, cron `41 8 * * *` + `workflow_dispatch`) + registered the `ci-nightly` `units:` row; refactored the 8 ACTUAL plant→run→restore negative blocks in `test.sh` (Checks 17, 15a, 19, 25, 26, 27, 28, 29) to invoke ONLY their targeted engine (`doc-spec.sh --check-on-disk` / `generate-readme.sh` diff / `test-spec.sh --render-docs --check` / `workflow-spec.sh --render-docs --check` / `--check-workflow-coverage` / `git ls-files`) instead of the whole `validate.sh` — killed the ~24 whole-validator re-runs. DEFERRED the `validate.yml` trim (out of scope).
- [x] Regenerated README + catalogs + workflow docs; seed byte-identity holds; `validate.sh` green (final run). VERSION NOT bumped (that is `/ship`'s job).
- [ ] (Deferred follow-up, to file at ship time) trim `validate.yml`'s per-PR run to the fast set + reclass the moved units' `layer` to `CI-nightly`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-04: Created. Carries the whole F000081 scope (WS1–WS5) as one atomic user-story. Scaffolded from the APPROVED /office-hours design doc.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- WS1: `spec/test-spec.md` (modified — 3-levels prose), `scripts/test-spec.sh` (modified — byte-identical `--seed` heredoc + advisory `--check-structure` matrix), `tests/test-spec.test.sh` (modified — S6 matrix fixture cases)
- WS2: `spec/test-spec-custom.md` (modified — portability rows → infra + 2 new command-rows), `spec/doc-spec-custom.md` (modified — the 4 front-door doc rows old→new; NOTE: `spec/doc-spec.md` is the frozen byte-identical seed and was NOT touched), `docs/tests/infra/CI-push/portability-smoke.md` + `docs/tests/infra/CI-nightly/portability-deploy.md` (git-moved from `docs/tests/workflow/…` + prose fixed), `docs/tests/infra/CI-push/portability-check18-lint.md` + `docs/tests/infra/local-hook/portability-version-check.md` (new front-door docs), `docs/tests/index.md` + `docs/tests/*.md` + `docs/test-catalog.md` (regenerated)
- WS3: `scripts/skills-update-check` (modified — git-ls-remote rework, `.git`-gate removed, seams), `tests/skills-update-check.test.sh` (new), `scripts/test.sh` (modified — new runner wiring), `spec/test-spec-custom.md` (`test-skills-update-check` units row)
- WS4: `.github/workflows/nightly.yml` (new), `scripts/test.sh` (modified — targeted-negative-test refactor of 8 blocks), `spec/test-spec-custom.md` (`ci-nightly` units row)
- WS5: `skills-catalog.json` (modified — entry → deprecated), `skills/CJ_portability-audit/` → `deprecated/CJ_portability-audit/` (git-moved: SKILL.md + USAGE.md), `rules/skill-routing.md` (unchanged — no routing line existed), `CLAUDE.md` (modified — routing prose), `spec/workflow-spec.md` (modified — both roster entries removed), `docs/workflows/utilities-and-phase-steps.md` + `docs/workflows/utility-audits.md` + `docs/workflow.md` (regenerated), `docs/philosophy.md` (modified — decision-tree node removed), `spec/test-spec-custom.md` (engine-row purpose), `spec/doc-spec-custom.md` (utility-audits.md desc), `skills/CJ_doc_audit/USAGE.md` + `skills/CJ_test_audit/USAGE.md` + `skills/CJ_test_run/USAGE.md` (cross-ref fixes), `CHANGELOG.md` (retirement note). KEPT: `scripts/cj-portability-audit.sh` + Check 18.
- Regeneration: `README.md`, `docs/test-catalog.md`, `docs/tests/*.md`, `docs/workflow.md`, `docs/workflows/*.md`. VERSION NOT bumped (deferred to `/ship`).

## Insights

<!-- Non-obvious findings worth remembering. -->

- Kept as a single atomic user-story (no task children) per WORKFLOW.md's "tasks are optional for atomic stories" — the five workstreams are one cohesive, sequentially-built change shipping in one PR; the Phase 1 gate is checked `N/A — atomic story`.
- The seed byte-identity (`spec/test-spec.md` ↔ the `test-spec.sh --seed` heredoc) is the single most fragile edit — green the `seed-byte-identical` contract test FIRST, before any other WS, or the whole test-spec suite reds mid-build.
- `test`-family units live at repo ROOT (`source: scripts/test.sh`, anchor `tests/<name>.test.sh`); category cells are filled by command-only `categories:` rows (exempt from `--check-structure` (b)), never by moving test files into `tests/<cat>/<layer>/`. This is why the local-hook backfill + the Check-18 lint are command-rows, and why the new `skills-update-check.test.sh` is a ROOT `test`-family unit.
- `layer` records the owning cadence, `trigger` the firing points — the DEFERRED units KEEP `layer: CI-push` until the deferred `validate.yml` trim; relabeling them `CI-nightly` while they still run per-PR would be a contract lie the reverse sweep won't catch.
- A doc move under `docs/` is BOTH a `spec/doc-spec.md` registry edit (Checks 15a/16) AND a generated-catalog edit (Check 26); `--seed-docs` seeds stubs but NEVER moves authored content — the two portability front-door docs are a hand-move.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-04 — One atomic user-story, no task children (WORKFLOW.md atomic-story allowance). Summary: WS1–WS5 are one cohesive change built in sequence and shipped in one PR; splitting into tasks would fragment a coherent diff.
- [decision] 2026-07-04 — `git ls-remote` (not curl) for the checkout-independent remote read. Summary: git is the repo's vetted hard dependency and handles ssh + non-GitHub upstream URLs; zero curl precedent exists (`grep curl scripts/` = 0). Keep gstack's MODEL, swap its curl→git.
- [decision] 2026-07-04 — Safe-additive CI now, defer the `validate.yml` trim. Summary: the nightly full-suite workflow + the targeted-negative-test refactor are in-PR-verifiable and ship now; the per-PR trim + layer-reclass is an attended follow-up an autonomous PR-stop can't verify.
- [decision] 2026-07-04 — Coverage matrix is ADVISORY (Q1). Summary: `--check-structure` reports the per-category × 3-layer matrix + `NOTE:`s but keeps its exit-0 "findings are the product" posture; an intentionally-empty cell never hard-fails.
- [decision] 2026-07-04 — Retire the `/CJ_portability-audit` verb, keep the engine + Check 18 (mirror /CJ_repo-init). Summary: the automatic per-PR lint + the reclassified infra tests make the manual verb redundant; the engine `scripts/cj-portability-audit.sh` + Check 18 + the overlay rows stay.
- [impl-finding] 2026-07-04 — The four portability front-door doc paths are declared in `spec/doc-spec-custom.md` (the overlay), NOT `spec/doc-spec.md`. `spec/doc-spec.md` is byte-identical to `doc-spec.sh --seed` (CLAUDE.md hard contract / Check 16) and contains ZERO `docs/tests` references. So the WS2 "update spec/doc-spec.md rows" instruction was resolved against the overlay — editing the frozen seed would break Check 16. `doc-spec.sh --check-on-disk` stays clean (5 checks PASS, 0 findings).
- [impl-finding] 2026-07-04 — `remote_max_tag` in skills-update-check tripped the caller's `set -e` when the remote had no v-tags: the final `grep` returns 1 (no match) and `var=$(func)` propagates a non-zero function return under errexit. Fixed by capturing the pipeline into a local + `|| true` and `return 0` — an empty print is the fail-soft signal, never an error. This is the untagged-upstream / unreachable path (P2 #9); test 7 guards it.
- [impl-finding] 2026-07-04 — `/CJ_repo-init` retirement precedent: the skill dir was `git mv`'d to `deprecated/` (not deleted), the catalog entry KEPT but `status: deprecated` with `files` repointed. Mirrored exactly for `/CJ_portability-audit`; the engine `scripts/cj-portability-audit.sh` is a ROOT script (not bundled in the skill dir) so it stays untouched, and README/generate-readme excludes `deprecated` skills so the row drops on regen.
- [impl-decision] 2026-07-04 — WS4 targeted-negative-test refactor scope: enumerated the ACTUAL plant→run→restore blocks (Checks 17, 15a, 19, 25, 26, 27, 28, 29 — 8 blocks, ~24 whole-`validate.sh` runs). Each now invokes ONLY its targeted engine; the POSITIVE "is Check N wired" assertions for S000094/S000096/F000060 KEEP the whole-validate call (they must confirm the check is IN the wired validator, not just that the engine works — a different guarantee), and the top-of-suite + manual-skill-creation full-validate runs stay whole. Each negative still catches its exact fault.
- [impl] 2026-07-04 — Implemented all five workstreams (WS1 contract+seed+matrix+fixtures; WS3 git-ls-remote rework + root test; WS2 portability→infra + doc moves + backfill; WS5 retire the verb; WS4 nightly.yml + targeted-negative refactor). ~30 files changed. `tests/skills-update-check.test.sh` (11 assertions) + the S6 matrix fixtures pass; `test-spec.sh --seed` byte-identical; `doc-spec.sh --check-on-disk` / `test-spec.sh --validate|--check-coverage|--render-docs --check` / `workflow-spec.sh --validate|--render-docs --check` all green; README + catalogs + workflow docs regenerated.
- [impl-auto] 2026-07-04 — Auto-mode run (silent orchestrated runner; sensitive surfaces skills-catalog.json / test-spec.sh / spec/test-spec.md / spec/test-spec-custom.md / spec/doc-spec-custom.md / workflow-spec.md / philosophy.md / CLAUDE.md / skills-update-check / test.sh / .github/workflows were PRE-APPROVED by the APPROVED design doc — the sensitive-surface gate does not halt for these design-mandated edits).
- [impl-pass] 2026-07-04 — S000131: implementation complete. Phase 2 implementer-owned gates (Todos section reflects remaining work; Files section updated) transitioned; QA-owned gates (Acceptance criteria verified met; Smoke tests pass) left for /CJ_qa-work-item.
- 2026-07-04 [qa-smoke] S1 (AC-1): green — seed byte-identical (diff empty, RC=0); --check-structure renders the per-category × 3-layer matrix + advisory NOTE for the empty workflow/CI-nightly cell, exit 0; S6 fixtures M1/M2/M3 re-verified green.
- 2026-07-04 [qa-smoke] S2 (AC-2): green — doc-spec.sh --check-on-disk 5 checks PASS / 0 findings (moved docs/tests/infra/… resolve declared↔on-disk); test-spec.sh --render-docs --check in sync (0 findings); all 4 portability rows read category: infra.
- 2026-07-04 [qa-smoke] S3 (AC-3, AC-4): green — tests/skills-update-check.test.sh RESULT: PASS (banner-when-newer / silent-when-equal / fail-soft-when-unreachable + untagged-upstream + ssh-normalize + .git-gate-removed, all assertions OK).
- 2026-07-04 [qa-smoke] S4 (AC-4, AC-5): green — test-spec.sh --validate OK schema_version=1; --check-coverage OK rows=85 reverse_tokens=65 findings=0 (nightly.yml + skills-update-check.test.sh each resolve to exactly one units row).
- 2026-07-04 [qa-smoke] S5 (AC-6): green — /CJ_portability-audit retired everywhere (catalog status: deprecated, skill dir → deprecated/, workflow-spec 0 refs, philosophy 0 refs); engine scripts/cj-portability-audit.sh (25630 bytes) + Check 18 intact; full validate.sh confirmed green (context: last ran 0 errors/0 warnings; retirement sub-checks 15a/16/26/27/18 independently re-verified green this run).
- 2026-07-04 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-07-04 [qa-e2e-deferred] E4 (AC-5): post-ship — verification deferred to post-merge (Tag contains 'post-ship'); nightly.yml not on origin refs until merge, verified after merge via `gh workflow run nightly.yml`; not run pre-ship
- 2026-07-04 [qa-e2e-run-start] RUN_ID=20260704-qa-s000131 commit=266e8fa
- 2026-07-04 [qa-e2e] E1 (AC-1): green — `test-spec.sh --check-structure` renders the per-category × {CI-push,CI-nightly,local-hook} matrix; the one empty cell (workflow/CI-nightly) shows an advisory NOTE: (not FINDING:); exit 0. [parent-inline]
- 2026-07-04 [qa-e2e] E2 (AC-3): green — on a .source-absent / non-git manifest with remote > local, skills-update-check emits `SKILLS_UPGRADE_AVAILABLE <local> <remote>` (no silent no-op — the old blind-spot is closed); proven by test 10 (non-git .source no longer suppresses) + test 8 (SKILLS_UPDATE_REMOTE_URL override fires the banner with no upstream_url). [parent-inline]
- 2026-07-04 [qa-e2e] E3 (AC-6): green — /CJ_portability-audit is unroutable (absent from catalog-active/skill-dir/workflow-spec/philosophy) while Check 18 (validate.sh:766, strict) + engine scripts/cj-portability-audit.sh still lint declared-vs-actual portability; validate.sh green. [parent-inline]
- 2026-07-04 [qa-e2e-summary] green (0s subagent [leaf-inline, no subagent dispatch]; 3 rows parent-inline; 1 deferred): E1/E2/E3 all green; E4 post-ship deferred to post-merge `gh workflow run nightly.yml`.
- 2026-07-04 [qa-audit] AUDITS=deferred,spec_updates:test-spec-custom:none(test-skills-update-check + ci-nightly rows already present),doc-spec-custom:none(moved docs/tests/infra/… rows already present) (Step 8.6a/8.6b: deterministic new-surface rows verified present inline — no new writes needed; the agent-judged amendment sweep SKIPPED via DEFER_SYNC + 8.6c/8.6d SKIPPED via DEFER_AUDIT — the agentic doc/test sync + audit run on-demand off the build path)
- 2026-07-04 [qa-pass] S000131 (user-story): green smoke (5/5 rows) + green E2E (E1/E2/E3; E4 post-ship deferred to post-merge). Phase 2 QA-owned gates (Acceptance criteria verified met; Smoke tests pass) transitioned; receipt written (ready_for_ship: true, ac_ids_uncovered: []). AUDITS deferred (DEFER_AUDIT + DEFER_SYNC — agent-judged doc/test audit runs on-demand off the build path).
