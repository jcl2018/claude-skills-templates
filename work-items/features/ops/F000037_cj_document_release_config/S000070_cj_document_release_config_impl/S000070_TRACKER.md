---
name: "Per-repo cj-document-release.json strict-required config — implementation"
type: user-story
id: "S000070"
status: active
created: "2026-06-02"
updated: "2026-06-02"
parent: "F000037"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-114944-26619"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `cj-feat-20260602-114944-26619` (parent's worktree branch; ships in same PR as parent F000037)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

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
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR (against main), bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment (deferred — /CJ_goal_feature stops at PR)

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review) against main
- [ ] `/land-and-deploy` — merged and deployed (deferred)

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `cj-document-release.json` exists at repo root, valid JSON, with:
  - `schema_version: 1`
  - `whitelist_patterns: ["README.md", "CHANGELOG.md", "CLAUDE.md", "ARCHITECTURE.md", "doc/**/*.md", "templates/doc-*.md"]` (≥6 entries; matches F000036 hardcoded set in glob form)
  - `categories: { readme, changelog, claude, architecture, philosophy, skill-catalog }` (all 6 F000036-compat tokens present, each mapping to a non-empty array of globs)
- [ ] `scripts/cj-document-release-config.sh` exists, executable (`chmod +x`), parses workbench's JSON, with:
  - `--parse` echoes the parsed JSON shape via jq
  - `--expand-whitelist` expands globs against the working tree, returns sorted unique file list (≥6 files)
  - `--resolve <token>` resolves a category token to a file list; halt-emits if token not declared
  - `--validate` exits 0 on green; exit 1 + emits `[doc-sync-no-config] <reason>` on red
  - All four subcommands use `shopt -s globstar nullglob` for glob expansion
  - Reads `$REPO_ROOT/cj-document-release.json` (resolves via `git rev-parse --show-toplevel`)
  - Supported schema versions: `(1)` (extensible array)
- [ ] `skills/CJ_document-release/SKILL.md` rewrite:
  - Removes hardcoded whitelist regex block from "Step 2: Branch + clean-tree gate" (or wherever it lived in F000036)
  - Removes hardcoded `--docs` known-token list from "Step 1: Parse arguments"
  - New "Step 0.5: Read config" block: invokes `scripts/cj-document-release-config.sh --parse`, captures output, emits `[doc-sync-no-config]` halt verbatim on non-zero exit
  - "Step 1: Parse arguments" parses `--docs <token>` raw; defers resolution to Step 4
  - "Step 4: Build context block" uses `scripts/cj-document-release-config.sh --resolve <token>` to expand `--docs` filter into concrete file list; passes into project-context block as `audit_files: [...]`
  - "Step 6: Auto-commit doc-only" whitelist regex becomes a glob-set from `scripts/cj-document-release-config.sh --expand-whitelist`; same `[doc-sync-non-doc-write]` halt class on non-whitelist writes
- [ ] `skills/CJ_document-release/USAGE.md` updated:
  - New "Per-repo config" subsection under "Mental model": "`cj-document-release.json` at repo root declares the whitelist + categories. Schema v1: `whitelist_patterns` (globs) + `categories` (token → glob array). Strict-required — `/CJ_document-release` HALTs with `[doc-sync-no-config]` when the file is missing/invalid/schema_version-unsupported."
  - New "Common pitfalls" row: "`[doc-sync-no-config]` halt means cj-document-release.json is missing/invalid/version-unsupported. Copy the workbench's seed JSON as a starting point."
  - `last-updated` frontmatter field bumped to ISO-8601 second-resolution UTC (matches Check 14's staged-aware override pattern)
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain a new row inserted between `[doc-sync-red]` and `[doc-sync-non-doc-write]`:
  - `halted_at_doc_sync_no_config | [doc-sync-no-config] | Step 5.5 doc-sync: cj-document-release.json missing/invalid/schema_version-unsupported (F000037 strict-required)`
- [ ] All 3 cj_goal `USAGE.md` files have `last-updated` bumped to ISO-8601 second-resolution UTC timestamp (cosmetic edit to silence Check 14).
- [ ] `scripts/validate.sh` Check 16 inserted after Check 15, with logic:
  - Skip silently when `cj-document-release.json` missing (non-adopting repos pass)
  - Otherwise: ERROR on invalid JSON, missing-or-unsupported `schema_version` (≠ 1), missing/empty `whitelist_patterns` array, missing/non-object `categories`, per-category non-array values
  - Final cross-check: call `bash scripts/cj-document-release-config.sh --validate`; ERROR if exits non-zero
  - PASS message on success: `PASS: cj-document-release.json schema_version=<n>`
- [ ] `tests/cj-document-release.test.sh` extended with ≥8 new assertions:
  - JSON file exists at repo root (`cj-document-release.json`)
  - Helper script exists + executable (`scripts/cj-document-release-config.sh`)
  - `bash scripts/cj-document-release-config.sh --validate` exits 0
  - `bash scripts/cj-document-release-config.sh --parse` returns valid JSON with `.schema_version`, `.whitelist_patterns`, `.categories` keys
  - `bash scripts/cj-document-release-config.sh --expand-whitelist` returns ≥6 lines (real files in workbench seed)
  - `bash scripts/cj-document-release-config.sh --resolve readme` returns `README.md`
  - `bash scripts/cj-document-release-config.sh --resolve nonexistent-category` exits non-zero AND emits `[doc-sync-no-config]` to stdout/stderr
  - `skills/CJ_document-release/SKILL.md` mentions `cj-document-release.json` (post-rewrite check that the SKILL.md actually delegates to the helper)
- [ ] `tests/cj-document-release-config.test.sh` new file with ≥6 assertions:
  - Valid JSON (parses via `jq empty`)
  - `.schema_version == 1`
  - `.whitelist_patterns` is a non-empty array of strings
  - `.categories` is a non-empty object
  - Every `.categories[*]` value is a non-empty array of strings
  - Every category name matches identifier shape (lowercase, hyphens OK; regex `^[a-z][a-z0-9-]*$`)
  - All 6 F000036-compat categories present: `readme`, `changelog`, `claude`, `architecture`, `philosophy`, `skill-catalog`
- [ ] `scripts/test.sh` wires both new/extended test files (tests/cj-document-release.test.sh extension covered by existing invocation; tests/cj-document-release-config.test.sh added as new invocation block in the same phase).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD. All 16 checks PASS (Check 16 PASSes on the bundled JSON; Check 13/14/15 still PASS for CJ_document-release).
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (superset suite: validate + cj-document-release.test.sh + cj-document-release-config.test.sh + existing tests).
- [ ] `CLAUDE.md` has a new H2 section `## cj-document-release.json convention (F000037)` inserted between F000034's "tracked-doc/" manifest section and the "TODOS.md hygiene conventions" section. Section content covers: where the file lives (repo root), schema v1 shape, glob semantics, strict-required HALT class (`[doc-sync-no-config]`), the bundled-in-same-PR seed values, and the deferred-to-v2 carve-outs (per-verb overrides, audit_class mirror, --docs negation, federation).
- [ ] `VERSION` reads `6.0.2`. `./scripts/check-version-queue.sh` confirmed slot is free before /ship (no open PRs claim 6.0.2).
- [ ] `CHANGELOG.md` has a new `## [6.0.2] — 2026-06-02` entry under `### Added`, in user-forward voice, naming F000037 + the strict-required posture + the helper-pattern parallel to F000029. Body covers: per-repo customization is real; first machine-parseable per-repo skill config; strict-required (no fallback to F000036's hardcoded defaults); new halt class `[doc-sync-no-config]`; bundled JSON seeds with F000036's existing set; CLAUDE.md gains a convention section.
- [ ] PR opened against main via `/ship` (pre-landing review included). /CJ_goal_feature stops at PR per design; no auto-merge, no /land-and-deploy in this PR. PR body notes F000036 lineage (this is the direct follow-up that externalizes F000036's hardcoded whitelist + token map) and the F000029 helper-pattern parallel.
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/`, `deprecated/`, or `work-copilot/`.

## Todos

<!-- Actionable items for this story. -->

- [ ] Write `scripts/cj-document-release-config.sh` with shebang `#!/usr/bin/env bash`, `set -eu`, repo-root-relative `JSON_PATH`, supported-schema-versions array, emit_halt helper, validation chain (file exists, valid JSON, schema_version supported, whitelist_patterns array, categories object), case-statement dispatcher for `--parse` / `--expand-whitelist` / `--resolve <token>` / `--validate`. Use `shopt -s globstar nullglob` for glob expansion. Make executable (`chmod +x`).
- [ ] Write `cj-document-release.json` at repo root with `schema_version: 1`, 6-entry `whitelist_patterns` array (README.md, CHANGELOG.md, CLAUDE.md, ARCHITECTURE.md, doc/**/*.md, templates/doc-*.md), and a `categories` object with the 6 F000036-compat tokens (readme, changelog, claude, architecture, philosophy, skill-catalog) each mapping to a non-empty glob array.
- [ ] Rewrite `skills/CJ_document-release/SKILL.md`: remove hardcoded whitelist regex block; remove hardcoded `--docs` token list; add "Step 0.5: Read config" block invoking helper `--parse`; route "Step 4: Build context block" through helper `--resolve <token>`; route "Step 6: Auto-commit doc-only" through helper `--expand-whitelist`. Preserve existing halt taxonomy `[doc-sync-red]` and `[doc-sync-non-doc-write]`; add explicit `[doc-sync-no-config]` halt-on-helper-fail path.
- [ ] Update `skills/CJ_document-release/USAGE.md`: add "Per-repo config" subsection under "Mental model" describing the JSON convention; add "Common pitfalls" row for `[doc-sync-no-config]`; bump `last-updated` to `$(date -u +%Y-%m-%dT%H:%M:%SZ)`.
- [ ] Edit `skills/CJ_goal_feature/SKILL.md` halt-taxonomy table: insert new row for `[doc-sync-no-config]` between `[doc-sync-red]` and `[doc-sync-non-doc-write]`.
- [ ] Edit `skills/CJ_goal_defect/SKILL.md` halt-taxonomy table: same insert.
- [ ] Edit `skills/CJ_goal_todo_fix/SKILL.md` halt-taxonomy table: same insert.
- [ ] Bump `last-updated` on `skills/CJ_goal_feature/USAGE.md`, `skills/CJ_goal_defect/USAGE.md`, `skills/CJ_goal_todo_fix/USAGE.md` (cosmetic — silence Check 14 on the staged-aware path).
- [ ] Edit `scripts/validate.sh`: insert new Check 16 after Check 15 with schema enforcement (skip silently when file missing; ERROR on invalid JSON / missing-or-unsupported schema_version / missing-or-empty whitelist_patterns / missing-or-non-object categories / per-category non-array values; final cross-check via helper `--validate`).
- [ ] Extend `tests/cj-document-release.test.sh` with ≥8 new assertions covering JSON existence, helper script existence + executable, --validate green, --parse shape, --expand-whitelist ≥6 files, --resolve readme, --resolve nonexistent-category halt, SKILL.md mentions cj-document-release.json.
- [ ] Write `tests/cj-document-release-config.test.sh` (executable; ≥6 assertions per Acceptance Criteria above).
- [ ] Edit `scripts/test.sh` to wire the new test file into the test phase (matching existing convention).
- [ ] Insert new H2 section `## cj-document-release.json convention (F000037)` into `CLAUDE.md` between F000034's tracked-doc/ manifest section and the TODOS.md hygiene section.
- [ ] Run `./scripts/check-version-queue.sh` to confirm 6.0.2 slot is free.
- [ ] Bump `VERSION` to `6.0.2`.
- [ ] Write `CHANGELOG.md` entry for `## [6.0.2] — 2026-06-02` under `### Added`, user-forward voice, naming F000037 + strict-required + helper-pattern parallel to F000029.
- [ ] Run `./scripts/validate.sh` locally → expect 0 errors / 0 warnings (Check 16 PASSes on bundled JSON).
- [ ] Run `./scripts/test.sh` locally → expect exit 0.
- [ ] Stage all 16 files in one atomic commit (pre-commit hook + Check 13 + Check 14 + Check 16 require atomic landing) → `/ship` against main with diff-review AUQ suppressed (orchestrator behavior).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. Single-story decomposition of F000037 — helper script `scripts/cj-document-release-config.sh` (NEW) + workbench's own `cj-document-release.json` (NEW) + `skills/CJ_document-release/SKILL.md` rewrite (hardcoded whitelist removed; delegates to helper) + `skills/CJ_document-release/USAGE.md` update (new Per-repo-config subsection + new common-pitfall row + last-updated bump) + 3 cj_goal SKILL.md halt-taxonomy edits ([doc-sync-no-config] row inserted) + 3 cj_goal USAGE.md timestamp bumps (cosmetic, silence Check 14) + `scripts/validate.sh` Check 16 (NEW) + `tests/cj-document-release.test.sh` extension (≥8 new assertions) + `tests/cj-document-release-config.test.sh` (NEW; ≥6 assertions) + `scripts/test.sh` wiring + CLAUDE.md new convention section + VERSION + CHANGELOG. Branch cut from origin/main HEAD post-PR #192 merged (F000036 v6.0.1). No upstream stacking.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-document-release-config.sh` (NEW — bash helper; mirrors F000029's `skills-doc-sync-check` shape)
- `cj-document-release.json` (NEW — workbench's own config; schema_version=1; seeds with F000036 set + workbench paths)
- `skills/CJ_document-release/SKILL.md` (MODIFIED — hardcoded whitelist + token list removed; delegates to helper; new Step 0.5: Read config)
- `skills/CJ_document-release/USAGE.md` (MODIFIED — new "Per-repo config" subsection; new `[doc-sync-no-config]` pitfall; last-updated bumped)
- `skills/CJ_goal_feature/SKILL.md` (MODIFIED — halt-taxonomy: new `[doc-sync-no-config]` row between doc-sync-red and doc-sync-non-doc-write)
- `skills/CJ_goal_defect/SKILL.md` (MODIFIED — same halt-taxonomy row)
- `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED — same halt-taxonomy row)
- `skills/CJ_goal_feature/USAGE.md` (MODIFIED — last-updated bumped to silence Check 14)
- `skills/CJ_goal_defect/USAGE.md` (MODIFIED — last-updated bumped)
- `skills/CJ_goal_todo_fix/USAGE.md` (MODIFIED — last-updated bumped)
- `scripts/validate.sh` (MODIFIED — new Check 16: schema enforcement when file exists)
- `tests/cj-document-release.test.sh` (MODIFIED — ≥8 new assertions for JSON + helper)
- `tests/cj-document-release-config.test.sh` (NEW — ≥6 assertions for the JSON itself)
- `scripts/test.sh` (MODIFIED — wire the new test file)
- `CLAUDE.md` (MODIFIED — new "cj-document-release.json convention" H2 section)
- `VERSION` (MODIFIED — PATCH bump 6.0.1 → 6.0.2)
- `CHANGELOG.md` (MODIFIED — new [6.0.2] entry in user-forward voice)

## Insights

<!-- Non-obvious findings worth remembering. -->

- **First "skill reads a per-repo JSON config" pattern in the workbench.** F000034's CLAUDE.md tracked-doc/ manifest is project-context PROSE (closed enum, narrow audit metadata). F000037's `cj-document-release.json` is the workbench's first MACHINE-PARSEABLE per-repo skill config (open category set, schema-versionable, machine-readable). Different shape, different surface. Template for future per-repo CJ_* skill configs (e.g., future `CJ_test-orchestrator.json`).
- **Strict-required over backward-compat fallback is the contract-strict path.** No fallback to F000036's hardcoded defaults when JSON missing/invalid/schema-unsupported. `[doc-sync-no-config]` HALT fires. Bundled-in-same-PR with workbench's own JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON (one-time cost). Matches memory `feedback_skill_contracts_strict`: convention-strict beats convenience-fallback.
- **Helper script + thin SKILL.md (Approach B) mirrors F000029.** Operators pattern-match across the two skills' "scripts/ helper + thin SKILL.md" shape. Parse logic isolated in one bash file → testable in isolation (`bash scripts/cj-document-release-config.sh --validate`). Approach A (pure SKILL.md prose) would balloon the skill body; Approach C (Node/Bun .mjs) would introduce a runtime dependency the workbench currently avoids in scripts/.
- **Globs over regex in the JSON.** F000036 used regex (`^doc/.+\.md$`); F000037 uses globs (`doc/**/*.md`). Operator-readable, matches .gitignore mental model, bash globstar-compatible. Glob edge cases (dotfiles, `**` semantics) isolated to the helper via `shopt -s globstar nullglob`.
- **`[doc-sync-no-config]` is a NEW halt class, separate from F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]`.** Three orthogonal failure modes for the doc-sync surface: config-missing/invalid (F000037), audit-failed (F000036), upstream-misbehaved (F000036). Each gets its own halt class for diagnostic clarity in the journal.
- **Schema versioned from day one.** `schema_version: 1` ships in v1. Future v2 readers will migrate; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported). Cheap to design in v1; expensive to retrofit.
- **CLAUDE.md convention is a sibling of F000034's tracked-doc/ manifest, not a consolidation.** F000034 = audit metadata (closed enum, narrow). F000037 = doc-sync whitelist + categories (open set, machine-parseable). Author explicitly resisted "consolidate into one file" because the shapes don't align.
- **Atomic-commit ordering through pre-commit hook covers 16 files.** Check 13 (USAGE.md presence), Check 14 (USAGE.md drift), Check 16 (JSON schema) all fire on this PR. Intermediate states would block any single-file commit. Stage everything once. Same constraint as F000036; same stage-everything-once mitigation.
- **F000036 just shipped 30 min ago — the warm-iteration is the right move.** F000036's hardcoded set is fresh in operator memory; externalizing it now (while design intent is still legible) is cheaper than later. Test fixtures and skill structure stable; just one wave of catalog churn.
- **`portability: workbench` stays in v1; flip deferred to standalone after downstream adoption.** F000037 is the *enabler* for future portability — but the actual flip requires at least one downstream repo successfully consuming the JSON. Don't pre-emptively flip; file the follow-up after dogfood succeeds in a non-workbench repo.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Approach B (helper script + thin SKILL.md) chosen over A (pure SKILL.md prose with inline bash globstar) and C (Node/Bun .mjs with minimatch). Summary: B mirrors F000029's proven `scripts/skills-doc-sync-check + thin SKILL.md` shape. Parse logic isolated in one bash file is testable in isolation; SKILL.md stays focused on orchestration. A would balloon SKILL.md prose (~80 lines of new bash); C would introduce a Node/Bun runtime dependency the workbench's `scripts/` currently avoids. The first `.mjs` in `scripts/` should be a separate decision, not folded into this PR.
- 2026-06-02 [decision] Strict-required (D2 option C) over backward-compat fallback. Summary: No fallback to F000036's hardcoded defaults when JSON missing/invalid/schema-unsupported. `[doc-sync-no-config]` HALT fires. Bundled-in-same-PR with workbench's own JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON (one-time cost, compounding win). Matches memory `feedback_skill_contracts_strict`: convention-strict beats convenience-fallback.
- 2026-06-02 [decision] Globs (not regex) in the JSON. Summary: Operator-readable (`doc/**/*.md` not `^doc/.+\.md$`), matches .gitignore mental model. Bash globstar via `shopt -s globstar nullglob` in the helper. Glob edge cases (dotfiles, `**` semantics) isolated to one testable surface.
- 2026-06-02 [decision] Schema versioned from day one (`schema_version: 1`). Summary: v2 readers will migrate; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported). Cheap to design in v1; expensive to retrofit.
- 2026-06-02 [decision] CLAUDE.md convention section is a sibling of F000034's tracked-doc/ manifest, not a replacement. Summary: F000034 manifest = audit metadata (closed enum, narrow). F000037 JSON = doc-sync whitelist + categories (open set, machine-parseable). Different concerns, separate surfaces. Resisted "consolidate into one file" because the shapes don't align.
- 2026-06-02 [decision] audit_class enum mirror from F000034 in the JSON: explicitly deferred. Summary: F000034 stays the audit-class source of truth; F000037 stays the whitelist/category source of truth. Cross-tool unification deferred indefinitely (separation of concerns over false coupling).
- 2026-06-02 [decision] No `--skip-docs` negation flag in v1. Summary: v1 only positive subset via `--docs <token>`. Negation deferred to v2 schema bump if operator demand surfaces. Keeps parser surface small.
- 2026-06-02 [decision] Portability stays workbench in v1; flip to standalone deferred. Summary: F000037 is the *enabler* for future portability. Actual portability flip requires at least one downstream repo successfully consuming the JSON. Separate decision, separate PR.
- 2026-06-02 [decision] Helper script lives in `scripts/`, not in skill folder. Summary: Mirrors F000029's `scripts/skills-doc-sync-check` placement. Workbench convention: `scripts/` for cross-skill bash helpers, `skills/{name}/` for skill bodies. Helper reached via `$REPO_ROOT/scripts/cj-document-release-config.sh` from inside any worktree.
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation across 16 files). Summary: Helper + JSON + SKILL.md rewrite + USAGE.md update + 3 cj_goal halt-taxonomy edits + 3 USAGE.md timestamp bumps + Check 16 + 2 tests + scripts/test.sh + CLAUDE.md section + VERSION + CHANGELOG all ship atomically. Same shape as F000036 (S000069). Pre-commit hook + Check 13 + Check 14 + Check 16 require atomic landing.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy in this PR. Summary: /CJ_goal_feature stops at PR by design. Per memory `project_workbench_auto_deploy_unsafe`. Step 5.5's existing wiring just keeps using the (now-config-driven) skill — no orchestrator semantic changes.
- 2026-06-02 [decision] `[doc-sync-no-config]` row in halt-taxonomy goes BETWEEN `[doc-sync-red]` and `[doc-sync-non-doc-write]`. Summary: Three orthogonal doc-sync failure modes ordered by configuration-time → run-time → output-time concerns: no-config (configuration missing) → red (audit failed at runtime) → non-doc-write (upstream produced bad output). Same ordering across all 3 cj_goal SKILL.md halt-taxonomy tables.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only). Summary: Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. Upstream invoked via Skill tool with project-context priming; the new config-driven filter logic lives in the workbench skill, not upstream. Mirrors F000036 + F000034 precedent.
