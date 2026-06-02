---
name: "Per-repo cj-document-release.json strict-required config"
type: feature
id: "F000037"
status: active
created: "2026-06-02"
updated: "2026-06-02"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-114944-26619"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `cj-feat-20260602-114944-26619` (auto-created by /CJ_goal_feature worktree phase from origin/main HEAD post-PR #192 merge; no upstream stacking)
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
5. Run `/land-and-deploy` — merges and verifies deployment (deferred — /CJ_goal_feature stops at PR)
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets (deferred)

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

- [ ] `cj-document-release.json` exists at repo root with `schema_version: 1`, non-empty `whitelist_patterns` array of globs, and a `categories` object mapping token names to glob arrays.
- [ ] `scripts/cj-document-release-config.sh` exists, executable, with subcommands `--parse`, `--expand-whitelist`, `--resolve <token>`, `--validate`. `--validate` exits 0 against the workbench's JSON.
- [ ] `scripts/cj-document-release-config.sh --resolve readme` returns `README.md`; `--expand-whitelist` returns ≥6 real files matching the seed globs.
- [ ] `skills/CJ_document-release/SKILL.md` no longer contains the F000036 hardcoded whitelist regex (`^(README|CHANGELOG|CLAUDE|ARCHITECTURE)\.md$`). The skill delegates to the helper script via `--parse` / `--expand-whitelist` / `--resolve`.
- [ ] `skills/CJ_document-release/USAGE.md` has a new "Per-repo config" subsection under Mental model, a new common-pitfall row for `[doc-sync-no-config]`, and a bumped `last-updated` ISO-8601 second-resolution timestamp.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain a new `[doc-sync-no-config]` row (halt class `halted_at_doc_sync_no_config`), inserted between `[doc-sync-red]` and `[doc-sync-non-doc-write]`. USAGE.md `last-updated` bumped for all 3 cj_goal skills to silence Check 14.
- [ ] `validate.sh` Check 16 enforces JSON schema when `cj-document-release.json` exists: ERRORs on invalid JSON, missing/unsupported `schema_version`, missing-or-empty `whitelist_patterns` array, missing/non-object `categories`, or per-category non-array values. Conditional — non-adopting repos pass.
- [ ] `tests/cj-document-release.test.sh` extended with ≥8 new assertions covering JSON existence, helper-script existence + executable, `--validate` green, `--parse` shape, `--expand-whitelist` ≥6 files, `--resolve readme`, `--resolve nonexistent` emits `[doc-sync-no-config]`, SKILL.md mentions cj-document-release.json post-rewrite.
- [ ] `tests/cj-document-release-config.test.sh` exists with ≥6 assertions validating the workbench's JSON itself: valid JSON, `schema_version=1`, non-empty whitelist_patterns, non-empty categories, identifier-shape category names, and presence of the 6 F000036-compat categories (readme, changelog, claude, architecture, philosophy, skill-catalog).
- [ ] `scripts/test.sh` wires both test files (extension + new file).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD (all 16 checks pass).
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (superset suite).
- [ ] `CLAUDE.md` has a new "cj-document-release.json convention" H2 section inserted between F000034's tracked-doc/ manifest section and the TODOS.md hygiene section.
- [ ] `VERSION` reads `6.0.2` (PATCH bump from 6.0.1) — slot confirmed free via `./scripts/check-version-queue.sh`.
- [ ] `CHANGELOG.md` has a new `## [6.0.2] — 2026-06-02` entry under `### Added` in user-forward voice, naming F000037 + the strict-required posture + the helper-script pattern (mirrors F000029).
- [ ] PR opened against main via `/ship`. PR body notes F000036 lineage (this is the direct follow-up that externalizes F000036's hardcoded whitelist + token map) and the F000029 helper-pattern parallel. /CJ_goal_feature stops at PR per design.
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/` or `deprecated/` or `work-copilot/`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000070 (`cj_document_release_config_impl`) — single atomic user-story carrying the helper script + JSON config + CJ_document-release SKILL.md/USAGE.md rewrite + 3 cj_goal SKILL.md halt-taxonomy edits + 4 USAGE.md timestamp bumps + validate.sh Check 16 + CLAUDE.md convention section + 2 tests + scripts/test.sh wiring + VERSION + CHANGELOG.
- [ ] End-to-end pipeline run — `/ship` opens PR against main; `./scripts/validate.sh` PASS; `./scripts/test.sh` PASS; manual smoke A (post-merge) = invoke `/CJ_document-release --docs readme` from a feature branch with a stale README; helper resolves token → file list; only README auto-commits; success summary printed. Manual smoke B (post-merge) = temporarily rename `cj-document-release.json` → `.bak`, invoke `/CJ_document-release`; helper exits 1 with `[doc-sync-no-config]`; orchestrator halts with `halted_at_doc_sync_no_config`; rename back, rerun green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. Direct follow-up to F000036 (PR #192, v6.0.1, ~30 min ago). Externalizes F000036's hardcoded doc-only auto-commit whitelist + `--docs` token map to a strict-required `cj-document-release.json` at repo root (schema v1: `whitelist_patterns` globs + `categories` object). New helper `scripts/cj-document-release-config.sh` parses/validates/expands (mirrors F000029's `skills-doc-sync-check` + thin SKILL.md shape). New halt class `[doc-sync-no-config]` (halted_at_doc_sync_no_config) fires when JSON missing/invalid/schema_version-unsupported — strict-required posture, no fallback to F000036's hardcoded defaults (operator agreed to D2 option C). New `validate.sh` Check 16 enforces schema when file exists. Bundled-in-same-PR: workbench's own JSON seeds with F000036's existing whitelist set + workbench-specific paths (`doc/**/*.md`, `templates/doc-*.md`). First "skill reads a per-repo JSON config" pattern in the workbench — template for future per-repo CJ_* skill configs. `portability: workbench` stays in v1; flip to standalone deferred until at least one downstream adoption.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-document-release-config.sh` (NEW — bash helper; mirrors F000029's `skills-doc-sync-check` shape)
- `cj-document-release.json` (NEW — workbench's own config, seeded with F000036 set + workbench paths)
- `skills/CJ_document-release/SKILL.md` (MODIFIED — hardcoded whitelist removed; delegates to helper script; new Step 0.5: Read config)
- `skills/CJ_document-release/USAGE.md` (MODIFIED — new "Per-repo config" Mental-model subsection; `[doc-sync-no-config]` pitfall; `last-updated` bumped)
- `skills/CJ_goal_feature/SKILL.md` (MODIFIED — halt-taxonomy: new `[doc-sync-no-config]` row inserted between doc-sync-red and doc-sync-non-doc-write)
- `skills/CJ_goal_defect/SKILL.md` (MODIFIED — same halt-taxonomy row)
- `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED — same halt-taxonomy row)
- `skills/CJ_goal_feature/USAGE.md` (MODIFIED — `last-updated` bumped to silence Check 14)
- `skills/CJ_goal_defect/USAGE.md` (MODIFIED — `last-updated` bumped)
- `skills/CJ_goal_todo_fix/USAGE.md` (MODIFIED — `last-updated` bumped)
- `scripts/validate.sh` (MODIFIED — new Check 16: schema enforcement when file exists)
- `tests/cj-document-release.test.sh` (MODIFIED — ≥8 new assertions for JSON + helper)
- `tests/cj-document-release-config.test.sh` (NEW — ≥6 assertions for the JSON itself)
- `scripts/test.sh` (MODIFIED — wire the new test file)
- `CLAUDE.md` (MODIFIED — new "cj-document-release.json convention" section)
- `VERSION` (MODIFIED — PATCH bump 6.0.1 → 6.0.2)
- `CHANGELOG.md` (MODIFIED — new [6.0.2] entry in user-forward voice)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **First "skill reads a per-repo JSON config" pattern in the workbench.** F000034's CLAUDE.md tracked-doc/ manifest is project-context PROSE (closed enum, narrow audit metadata). F000037's `cj-document-release.json` is the workbench's first MACHINE-PARSEABLE per-repo skill config (open category set, schema-versionable, machine-readable). Different concerns, different surfaces — author resisted the temptation to consolidate into one file. Template for future per-repo CJ_* skill configs.
- **Strict-required over backward-compat fallback (D2 option C).** No fallback to F000036's hardcoded defaults when the JSON is missing. Operator must declare upfront. Matches memory `feedback_skill_contracts_strict`: convention-strict beats convenience-fallback. Bundled-in-same-PR with the workbench's own JSON = zero day-1 breakage; downstream adoption requires authoring the JSON (one-time cost). The cost compounds → no surprise behavior across repos.
- **Helper script + thin SKILL.md (Approach B, mirrors F000029).** Three approaches considered: A (pure SKILL.md prose with inline bash globstar), B (helper script + thin SKILL.md), C (Node/Bun .mjs). B chosen because it pattern-matches across F000029's proven shape, isolates the bash globstar edge cases in one testable surface, and avoids introducing a Node/Bun runtime dependency to a skill that didn't need one.
- **Globs, not regex, in the JSON.** F000036's hardcoded whitelist was regex (`^doc/.+\.md$`). F000037's JSON uses globs (`doc/**/*.md`). Operator-readable, bash globstar-compatible, matches the .gitignore mental model. Bash globstar has edge cases (e.g., dotfiles), isolated to the helper script (`shopt -s globstar nullglob`).
- **`[doc-sync-no-config]` is a new halt class for the "operator forgot to configure" path.** Distinct from F000036's `[doc-sync-red]` (audit failed) and `[doc-sync-non-doc-write]` (upstream misbehaved). Three orthogonal failure modes for the doc-sync surface; each gets its own halt class for diagnostic clarity.
- **Schema versioned from day one (`schema_version: 1`).** Future v2 bumps add migration steps; v1 readers refuse v2 files with `[doc-sync-no-config]` (schema_version_unsupported). Cheap to design in v1; expensive to retrofit.
- **CLAUDE.md convention section is a SIBLING of F000034's tracked-doc/ manifest, not a replacement.** F000034's manifest = audit-class metadata (closed enum, narrow). F000037's JSON = doc-sync whitelist + category metadata (open set, machine-parseable). Different concerns, deliberately separate.
- **F000034 audit_class enum mirror in the JSON: explicitly deferred.** The JSON could declare each whitelist pattern's audit_class for cross-tool unification; out-of-scope for v1. F000034's manifest stays the audit-class source of truth; this JSON stays the whitelist/category source of truth. Separation of concerns over false coupling.
- **Portability stays workbench in v1.** The catalog entry continues to read `portability: workbench`. F000037 is the *enabler* for future portability (downstream repos can now declare their own doc surface), but the actual flip to `standalone` requires at least one downstream repo successfully consuming the JSON first. Separate decision, separate PR.
- **Atomic commit ordering through pre-commit hook.** Same constraint as F000036: stage everything together. Validate.sh Check 16 fires on the JSON; SKILL.md prose rewrite removes the hardcoded whitelist that Check 16 would otherwise flag if landed independently. Test wiring + scripts/test.sh must also land atomically.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Approach B (helper script + thin SKILL.md) chosen over A (pure SKILL.md prose) and C (Node/Bun .mjs). Summary: B mirrors F000029's proven `scripts/skills-doc-sync-check + thin SKILL.md` shape. Operators pattern-match across the two skills. Parse logic in a single bash file is testable in isolation. A would balloon SKILL.md prose (~80 lines of new bash); C would introduce a Node/Bun runtime dependency the workbench currently avoids in `scripts/`.
- 2026-06-02 [decision] Strict-required (D2 option C) over backward-compat fallback. Summary: No fallback to F000036's hardcoded whitelist when JSON missing/invalid/schema-unsupported. `[doc-sync-no-config]` HALT fires. Bundled-in-same-PR with workbench's own JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON (one-time cost, compounding win). Matches memory `feedback_skill_contracts_strict`.
- 2026-06-02 [decision] Globs (not regex) in the JSON. Summary: Operator-readable (`doc/**/*.md` not `^doc/.+\.md$`), matches .gitignore mental model. Bash globstar via `shopt -s globstar nullglob` in the helper. Glob edge cases (dotfiles, `**` semantics) isolated to one testable surface.
- 2026-06-02 [decision] Schema versioned from day one (`schema_version: 1`). Summary: v2 readers will migrate; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported). Cheap to design in v1; expensive to retrofit.
- 2026-06-02 [decision] CLAUDE.md convention section is a sibling of F000034's tracked-doc/ manifest, not a replacement. Summary: F000034 manifest = audit metadata (closed enum, narrow). F000037 JSON = doc-sync whitelist + categories (open set, machine-parseable). Different concerns, separate surfaces. Author explicitly resisted "consolidate into one file."
- 2026-06-02 [decision] audit_class enum mirror from F000034 in the JSON: explicitly deferred. Summary: F000034 stays the audit-class source of truth; F000037 stays the whitelist/category source of truth. Cross-tool unification deferred indefinitely (separation of concerns over false coupling).
- 2026-06-02 [decision] No `--skip-docs` negation flag in v1. Summary: v1 only positive subset via `--docs <token>`. Negation deferred to v2 schema bump if operator demand surfaces. Keeps parser surface small.
- 2026-06-02 [decision] Portability stays workbench in v1; flip to standalone deferred. Summary: F000037 is the *enabler* for future portability. Actual portability flip requires at least one downstream repo successfully consuming the JSON. Separate decision, separate PR.
- 2026-06-02 [decision] Helper script lives in `scripts/`, not in skill folder. Summary: Mirrors F000029's `scripts/skills-doc-sync-check` placement. Workbench convention: scripts/ for cross-skill bash helpers, skills/{name}/ for skill bodies. Helper reached via `$REPO_ROOT/scripts/cj-document-release-config.sh` from inside any worktree.
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation across 16 files). Summary: Helper + JSON + SKILL.md rewrite + USAGE.md update + 3 cj_goal halt-taxonomy edits + 3 USAGE.md timestamp bumps + Check 16 + 2 tests + scripts/test.sh + CLAUDE.md section + VERSION + CHANGELOG all ship atomically. Same shape as F000036 (S000069). Pre-commit hook + Check 13 + Check 14 + Check 16 require atomic landing.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy in this PR. Summary: /CJ_goal_feature stops at PR by design. Per memory `project_workbench_auto_deploy_unsafe`. Step 5.5's existing wiring just keeps using the (now-config-driven) skill — no orchestrator semantic changes.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only scope). Summary: Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. Upstream invoked via Skill tool with project-context priming; the new config-driven filter logic lives in the workbench skill, not upstream. Mirrors F000036's "no upstream modification" precedent.
