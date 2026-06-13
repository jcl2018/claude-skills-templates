---
name: "Reconcile engines + audit-skill wiring for self-healing contract files"
type: user-story
id: "S000109"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: "F000065"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-audit-self-heal"
blocked_by: ""
---

<!-- Prerequisite: this atomic story derives directly from the parent feature's
     /office-hours session; the parent's DESIGN is sufficient context and this
     story's DESIGN.md is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b cj-feat-audit-self-heal` (shipping in the same PR as the parent feature)
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
- [x] Tasks broken down (N/A — atomic story; work is one cohesive change sequenced into two internal phases)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
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

- [ ] Phase 1: `scripts/doc-spec.sh` gains a read-only `--classify` (emits `GENERATION=<canonical|legacy|absent>`, `POSITIONS=<comma-list>`, `DUPLICATE=<0|1>`, `CANONICAL_PATH=<spec/ path>`) that labels absent/canonical/legacy/duplicate fixtures correctly, and an opt-in `--reconcile` that migrates a legacy YAML fixture → canonical 3-column Markdown preserving every declared row (atomic temp→`--validate`-clean→`mv`, `.bak` kept, migration report, idempotent `RECONCILE: already canonical` on a canonical file). The `audit_class` asymmetry guard fires `RECONCILE-WARN` for a `docs/*` row declared `operational`.
- [ ] Phase 1: `scripts/test-spec.sh` gains the symmetric `--classify` (+ `--reconcile` scoped to whatever legacy form exists / dedup-and-no-op if test-spec never had a divergent on-disk legacy format).
- [ ] Phase 2: `skills/CJ_doc_audit/SKILL.md` + `skills/CJ_test_audit/SKILL.md` generalize the Step-2 "seed if missing" step into a reconcile step driven by `--classify` (absent → seed unchanged; canonical → ok; legacy/duplicate → an advisory `RECONCILE:` directive into the Stage-1 report naming the issue + remedy, NO auto-write), and add an opt-in audit `--reconcile` flag that forwards to the engine (standalone only — the in-QA path never passes it).
- [ ] Phase 2: the canonical contract-file template (required = the general file of each pair; optional = the `*-custom.md` overlays; canonical position = `spec/`; root accepted as fallback; format = 3-column Markdown table) is documented in each audit's USAGE.md + the `spec/doc-spec.md` / `spec/test-spec.md` prose.
- [ ] A plain (no-flag) audit run on a legacy/duplicate repo emits the advisory `RECONCILE:` directive and writes nothing; `--reconcile` is the only new write path; a canonical repo emits zero reconcile lines.
- [ ] `scripts/validate.sh` stays green (0/0); the live workbench classifies `canonical` with no reconcile noise. New `tests/*.test.sh` (classify + reconcile fixtures for both engines, incl. the 40+-row legacy fixture) are registered in `scripts/test.sh` AND `spec/test-spec-custom.md`.

## Todos

<!-- Actionable items for this story. -->

- [x] P1.1 Recover the old-generation YAML doc-spec grammar from git history (root `doc-spec.md` @ pre-F000057, e.g. commit `716a537`) — the converter's input grammar. Read `git show 716a537:doc-spec.md`: fenced ```yaml block, `docs[]` with `path`/`section`/`audit_class`/`front_table`/`purpose`/`requirement`.
- [x] P1.2 Build `doc-spec.sh --classify` (read-only): probe the contract file(s) at `spec/`-then-root; emit `GENERATION`/`POSITIONS`/`DUPLICATE`/`CANONICAL_PATH`. `legacy` requires NO canonical table AND the old-generation signature; a no-table no-signature file => `GENERATION=malformed` (the `[doc-sync-no-config]` halt preserved, NOT legacy).
- [x] P1.3 Build `doc-spec.sh --reconcile` (the ONLY new write path, opt-in): for `legacy`, parse the old entries and emit the canonical Markdown table preserving every declared row (`path`→Doc, `purpose`→Purpose, `requirement`→Requirement; drop `section`/`audit_class`/`front_table`); write atomically (temp → `--validate`-clean → `mv`), keep a `.bak`, emit the migration report. `duplicate` => reconcile the canonical copy + report the redundant one (no auto-delete). Idempotent: `--reconcile` on canonical = `RECONCILE: already canonical`.
- [x] P1.4 Add the `audit_class` asymmetry guard: a migrated row whose declared `audit_class` was `operational` but whose path derives `human-doc` fires `RECONCILE-WARN: <path> audit_class was 'operational' but path derives 'human-doc' — verify no work-item IDs`.
- [x] P1.5 Confirm the legacy test-spec on-disk signature from git history (CONFIRMED: test-spec has ALWAYS been the fenced-yaml format — introduced at `ce7af57` under `spec/test-spec.md`, never a divergent on-disk format). So `test-spec.sh --classify` reduces to canonical/absent + duplicate (never `legacy`) and `--reconcile` is a dedup/no-op — symmetric subcommands, reduced legacy branch, documented in the code comments.
- [x] P1.6 Run `./scripts/validate.sh` + `./scripts/test.sh` green; the live workbench classifies `canonical` (`GENERATION=canonical`, `DUPLICATE=0`) with zero reconcile lines. (validate 0/0; full test.sh PASS.)
- [x] P2.1 Wire `skills/CJ_doc_audit/SKILL.md` Step 2: generalized "seed if missing" → classify-driven reconcile step (absent → seed; canonical → ok; legacy/duplicate → advisory `RECONCILE:` directive into the Stage-1 report, NO auto-write); added the opt-in audit `--reconcile` flag (Step 0) forwarding to `doc-spec.sh --reconcile` (standalone only).
- [x] P2.2 Mirror P2.1 in `skills/CJ_test_audit/SKILL.md` for `test-spec.sh` (reduced: no `legacy` branch; duplicate-only directive).
- [x] P2.3 The `RECONCILE:` directive is ADVISORY (like D000034's `REMEDIATION:`): documented in both SKILL.mds + error-handling tables + USAGE.md as never crashing the audit or flipping QA red; the cj_goal post-QA checkpoint owns Continue/Halt.
- [x] P2.4 Document the canonical contract-file template (required/optional files + positions + format) in `skills/CJ_doc_audit/USAGE.md`, `skills/CJ_test_audit/USAGE.md`, and the `spec/doc-spec.md` / `spec/test-spec.md` prose (added via the seed heredocs, propagated byte-identically to the spec files + `templates/doc-spec-common.md`).
- [x] P2.5 Bumped the audit-skill version (`0.2.0` → `0.3.0`) + reconcile-aware `description` in `skills-catalog.json` (kept byte-identical to the SKILL.md frontmatter) + the SKILL.md frontmatter `description`/`version`. (No `CJ_goal_*` SKILL.md was touched, so the four `CJ_goal_*` USAGE.md `last-updated:` bumps are N/A.)
- [x] P2.6 Added `tests/doc-spec-reconcile.test.sh` (classify 4 generations + 40+-row legacy migration preserving every row + asymmetry guard + idempotent + malformed-no-clobber + live-canonical-no-noise) and `tests/test-spec-reconcile.test.sh` (symmetric classify + dedup/no-op + duplicate + malformed-halt). Registered BOTH in `scripts/test.sh` AND `spec/test-spec-custom.md` (`test-doc-spec-reconcile`, `test-test-spec-reconcile` units).
- [x] P2.7 Run `./scripts/validate.sh` (0 errors / 0 warnings) + `./scripts/test.sh` (0 failures) green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-13: Created. Atomic story carrying both internal phases of F000065: Phase 1 reconcile engines (`--classify` + `--reconcile` for `doc-spec.sh` + `test-spec.sh`), Phase 2 audit-skill wiring (Step-2 directive + opt-in flag) + canonical-template docs + fixtures.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- Phase 1 (engines): `scripts/doc-spec.sh` (new `--classify` + `--reconcile` + the legacy-yaml parser/asymmetry-guard/atomic-migrate machinery), `scripts/test-spec.sh` (symmetric `--classify` + reduced dedup/no-op `--reconcile`).
- Phase 2 (wiring + docs + tests): `skills/CJ_doc_audit/SKILL.md` (Step 0 `--reconcile` flag + classify-driven Step 2 + report/error-table), `skills/CJ_doc_audit/USAGE.md` (canonical-template section + mental-model reconcile note + `last-updated`), `skills/CJ_test_audit/SKILL.md` (symmetric), `skills/CJ_test_audit/USAGE.md` (symmetric), `spec/doc-spec.md` + `templates/doc-spec-common.md` + the `doc-spec.sh --seed` heredoc (canonical-template prose, 3-way byte-identical), `spec/test-spec.md` + the `test-spec.sh --seed` heredoc (canonical-template prose, byte-identical), `skills-catalog.json` (version 0.3.0 + reconcile-aware description for both audit skills — sensitive surface, pre-authorized), `tests/doc-spec-reconcile.test.sh` (NEW), `tests/test-spec-reconcile.test.sh` (NEW), `scripts/test.sh` (registered both new test runners), `spec/test-spec-custom.md` (registered `test-doc-spec-reconcile` + `test-test-spec-reconcile` units).
- NOT touched by this implement run (orchestrator-owned): `CLAUDE.md`, `CHANGELOG.md`, `VERSION` (the cj_goal pipeline folds CHANGELOG/VERSION at `/ship`; any CLAUDE.md convention note is a doc-sync concern, not implement scope).

## Insights

<!-- Non-obvious findings worth remembering. -->

- `legacy` ≠ `genuinely malformed`: the `--classify` `legacy` label requires BOTH "no canonical registry table" AND an old-generation *signature* match (fenced ```yaml + `schema_version:` + `docs:`). Without the signature gate, `--reconcile` would clobber a hand-broken canonical file instead of letting the existing `[doc-sync-no-config]` halt fire.
- The write must preserve EVERY declared row — a re-seed (Approach B) would replace a 47-doc registry with the ~10-row template. The migrate parses the old entries and re-emits them; atomic temp→`--validate`-clean→`mv` + `.bak` guarantees no half-written registry and a recoverable original.
- The audit can't prompt (no AskUserQuestion; runs inline-in-QA as a subagent). So the "prompt to update" is a report-borne advisory `RECONCILE:` directive + an opt-in `--reconcile` flag the in-QA path never passes — exactly D000034's `REMEDIATION:` shape.
- The implement-subagent systematically forgets the parallel `scripts/test.sh` integration fixture for a new engine/validate behavior (F000032/F000034/F000035 all hit it) — P2.6 calls it out explicitly.

## Journal

<!-- Structured entries from the work-track journal command. -->

- [decision] 2026-06-13 — Single atomic story carries both phases (no task children). Per WORKFLOW.md, tasks are optional for an atomic story whose work is one cohesive change; the two internal phases (reconcile engines, then audit-skill wiring + docs + tests) are build sequencing within the one PR, not separate decomposable units. Summary: recorded the Phase 1 gate `[x] Tasks broken down (N/A — atomic story)`.
- [decision] 2026-06-13 — `--reconcile` is the ONLY new write path and is opt-in; a plain audit run stays read-mostly. The in-QA path never passes the flag; non-canonical states surface only as the advisory `RECONCILE:` directive. Summary: read-mostly default preserved.
- [finding] 2026-06-13 — Re-point/grep sweeps and test registration MUST be exhaustive: every new `tests/*.test.sh` is registered in BOTH `scripts/test.sh` and `spec/test-spec-custom.md`, or the unregistered-test gate (Check 24) hard-fails. Summary: register tests in both homes.
- [impl-decision] 2026-06-13 — The canonical-template prose (P2.4) was added to the `--seed` HEREDOCS, not directly to `spec/doc-spec.md` / `spec/test-spec.md`. The general spec files are byte-identical to `--seed` (a 3-way lockstep for doc-spec: heredoc == `spec/doc-spec.md` == `templates/doc-spec-common.md`, guarded by `tests/doc-spec-overlay.test.sh`; a 2-way for test-spec). Editing the seed and regenerating the spec files keeps all copies identical; editing a spec file directly would break the identity guard.
- [impl-decision] 2026-06-13 — The legacy `path:` extraction needed a dedicated `strip_listkey()` awk helper: the existing `strip()` only handled `  key: value` lines, not the `  - path: value` list-item form (the leading `- ` dash). Without it the migrated Doc column carried a literal `- path:` prefix AND the asymmetry guard's `_audit_class_for` always derived `operational` (silently disarmed). Caught by the row-preservation + asymmetry test assertions before any commit.
- [impl-finding] 2026-06-13 — test-spec has NO divergent legacy on-disk format (OQ3 resolved): git history shows `test-spec.md` was born fenced-yaml at `ce7af57`. So `test-spec.sh --classify` never emits `legacy` and `--reconcile` is a dedup/no-op — the symmetric subcommands exist with a reduced legacy branch, documented in the code comments + USAGE.md + the SKILL.md description.
- [impl-finding] 2026-06-13 — qa.md Step 8.6c/8.6d needed NO edit: the in-QA path follows the audit SKILL.md generically ("execute all three stages"), never passes `--reconcile` (a standalone arg), and the report shape is unchanged (the RECONCILE directive rides inside the Stage-1 section, not a new headline field) — fully backward-compatible.
- [impl] 2026-06-13 — Phase 1: `scripts/doc-spec.sh` gained `--classify`/`--reconcile` + the legacy-yaml parser, asymmetry guard, and atomic temp→validate→mv migrate; `scripts/test-spec.sh` gained the symmetric (reduced) pair. Phase 2: both audit SKILL.mds (Step 0 flag + classify-driven Step 2 + report/error-table), both USAGE.mds (canonical-template section), the seed heredocs + spec files + `templates/doc-spec-common.md` (canonical-template prose, identity preserved), `skills-catalog.json` (v0.3.0 + reconcile-aware descriptions), two new `tests/*-reconcile.test.sh` registered in `scripts/test.sh` + `spec/test-spec-custom.md`. All shellcheck-clean (`--norc`); validate 0/0; full test.sh PASS.
- [impl-auto] 2026-06-13 — Run under `/CJ_implement-from-spec --auto` (cj_goal silent-build runner role, no AUQ available). The catalog edit (a normally-sensitive surface) was PRE-AUTHORIZED by the approved design + the runner contract; proceeded without halting on the sensitive-surface gate.
- [impl-pass] 2026-06-13 — S000109: implementation complete. Phase 2 implementer-owned gates transitioned (Todos + Files); the QA-owned gates (Acceptance criteria verified met / Smoke tests pass) are left for /CJ_qa-work-item.
