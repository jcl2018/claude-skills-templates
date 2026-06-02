---
type: design
parent: F000037
title: "Per-repo cj-document-release.json strict-required config — Feature Design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

F000036 (PR #192, v6.0.1, shipped ~30 min ago) introduced `/CJ_document-release` with a HARDCODED doc whitelist in SKILL.md prose:

```
^(README|CHANGELOG|CLAUDE|ARCHITECTURE)\.md$     # root-level convention docs
^doc/.+\.md$                                     # workbench doc/ folder
^templates/doc-.*\.md$                           # template-doc convention
```

Plus a hardcoded `--docs <token>` mapping: `readme` / `changelog` / `claude` / `architecture` / `philosophy` / `skill-catalog`. Unknown tokens warn-and-skip.

Two coupled problems with that shape:

1. **Per-repo variation.** The workbench tracks `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `doc/SKILL-CATALOG.md` plus root-level convention docs. A different repo would track `docs/api/**/*.md`, `MIGRATIONS.md`, a `RUNBOOK.md`, or whatever its own structure dictates. F000036's `portability: workbench` catalog entry exists precisely because this hardcoded set isn't transferable.

2. **`--docs` flag is hardcoded.** Operators can only narrow to the 6 baked-in tokens. A Rails repo would want `--docs models` or `--docs api-reference`; a Python lib would want `--docs sphinx`. The flag's utility caps at "what F000036's author imagined" instead of "what THIS repo declares."

F000034 (v5.0.19) established a related precedent: a tracked-doc/ manifest inline in CLAUDE.md (YAML), with each `doc/*.md` file registered against an `audit_class` enum. That manifest is `/document-release`'s reading material for the workbench's project context. It's the right shape for audit-class metadata (closed enum, narrow purpose) but the wrong shape for CJ_document-release's needs (open category set, machine-parseable, schema-versionable, per-repo customizable).

This PR (F000037) externalizes CJ_document-release's whitelist + categories to a **strict-required** `cj-document-release.json` at the repo root.

## Shape of the solution

One atomic PR. Sixteen files touched:

1. `scripts/cj-document-release-config.sh` (NEW) — bash helper; subcommands `--parse` / `--expand-whitelist` / `--resolve <token>` / `--validate`. Mirrors F000029's `scripts/skills-doc-sync-check` shape.
2. `cj-document-release.json` (NEW) — workbench's own config, seeded with F000036's existing hardcoded set + workbench-specific paths (`doc/**/*.md`, `templates/doc-*.md`).
3. `skills/CJ_document-release/SKILL.md` (MODIFIED) — hardcoded whitelist removed; new "Step 0.5: Read config" block delegates to helper; Step 1 parses `--docs` raw; Step 4 resolves via helper; Step 6 auto-commit whitelist becomes a glob-set from helper.
4. `skills/CJ_document-release/USAGE.md` (MODIFIED) — new "Per-repo config" subsection under Mental model; new common-pitfall row for `[doc-sync-no-config]`; `last-updated` bumped to ISO-8601 second-resolution.
5. `skills/CJ_goal_feature/SKILL.md` (MODIFIED) — halt-taxonomy: new `[doc-sync-no-config]` row inserted between `[doc-sync-red]` and `[doc-sync-non-doc-write]`.
6. `skills/CJ_goal_defect/SKILL.md` (MODIFIED) — same halt-taxonomy row.
7. `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED) — same halt-taxonomy row.
8. `skills/CJ_goal_feature/USAGE.md` (MODIFIED) — `last-updated` bumped to silence Check 14 (cosmetic — halt-taxonomy added).
9. `skills/CJ_goal_defect/USAGE.md` (MODIFIED) — same.
10. `skills/CJ_goal_todo_fix/USAGE.md` (MODIFIED) — same.
11. `scripts/validate.sh` (MODIFIED) — new Check 16: enforces JSON schema when `cj-document-release.json` exists.
12. `tests/cj-document-release.test.sh` (MODIFIED) — extended with ≥8 new assertions for JSON + helper.
13. `tests/cj-document-release-config.test.sh` (NEW) — ≥6 assertions for the JSON itself.
14. `scripts/test.sh` (MODIFIED) — wire the new test file in.
15. `CLAUDE.md` (MODIFIED) — new "cj-document-release.json convention" H2 section, sibling of F000034's tracked-doc/ manifest section.
16. `VERSION` + `CHANGELOG.md` (MODIFIED) — PATCH bump 6.0.1 → 6.0.2 + user-forward [6.0.2] entry.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| cj-document-release.json strict-required config + helper + CJ_document-release SKILL.md rewrite + 3 cj_goal halt-taxonomy edits + validate.sh Check 16 + CLAUDE.md convention + tests + VERSION + CHANGELOG (atomic implementation) | S000070 | `S000070_cj_document_release_config_impl/S000070_TRACKER.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B (helper script + thin SKILL.md) over A (pure SKILL.md prose) and C (Node/Bun .mjs) | B mirrors F000029's proven `scripts/skills-doc-sync-check + thin SKILL.md` shape. Parse logic isolated in one bash file → testable in isolation. A would balloon SKILL.md prose (~80 lines of new bash); C would introduce a Node/Bun runtime dependency the workbench's `scripts/` currently doesn't have. |
| 2 | Strict-required (D2 option C) over backward-compat fallback | No fallback to F000036's hardcoded defaults when JSON missing/invalid/schema-unsupported. `[doc-sync-no-config]` HALT fires. Bundled-in-same-PR with workbench's own JSON ensures zero day-1 breakage; downstream adoption requires authoring the JSON (one-time cost, compounding win). Matches memory `feedback_skill_contracts_strict`. |
| 3 | Globs (not regex) in the JSON | Operator-readable (`doc/**/*.md` not `^doc/.+\.md$`), matches the .gitignore mental model. Bash globstar via `shopt -s globstar nullglob` in the helper. Glob edge cases (dotfiles, `**` semantics) isolated to one testable surface (the helper) rather than scattered through SKILL.md prose. |
| 4 | Schema versioned from day one (`schema_version: 1`) | Future v2 bumps add migration steps; v1 readers refuse v2 with `[doc-sync-no-config]` (schema_version_unsupported). Cheap to design in v1; expensive to retrofit. |
| 5 | CLAUDE.md convention section is a SIBLING of F000034's tracked-doc/ manifest, not a replacement | F000034 manifest = audit metadata (closed enum, narrow). F000037 JSON = doc-sync whitelist + categories (open set, machine-parseable). Different concerns, separate surfaces. Resisted "consolidate into one file" because the shapes don't align. |
| 6 | audit_class enum mirror from F000034 in the JSON: explicitly deferred | F000034 stays the audit-class source of truth; F000037 stays the whitelist/category source of truth. Cross-tool unification deferred indefinitely (separation of concerns over false coupling). |
| 7 | `[doc-sync-no-config]` is a new halt class, separate from F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]` | Three orthogonal failure modes for the doc-sync surface: config-missing/invalid (F000037), audit-failed (F000036), upstream-misbehaved (F000036). Each gets its own halt class for diagnostic clarity in the journal. |
| 8 | Single user-story decomposition (atomic implementation across 16 files) | Same shape as F000032/F000033/F000034/F000036. Pre-commit hook + Check 13 + Check 14 + Check 16 require atomic landing. Splitting adds bookkeeping without splitting risk. |
| 9 | `portability: workbench` stays in v1 | F000037 is the *enabler* for future portability (downstream repos can now declare their own doc surface), but the actual flip to `standalone` requires at least one downstream repo successfully consuming the JSON first. Separate decision, separate PR. |
| 10 | PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy in this PR | /CJ_goal_feature stops at PR by design — PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`. Step 5.5's existing wiring just keeps using the (now-config-driven) skill — no orchestrator semantic changes. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Per-verb overrides (`categories_by_verb: { feature: [...], defect: [...] }`)? | Resolution: deferred to v2 (schema_version 2). If a verb-specific carve-out becomes load-bearing (e.g., `/CJ_goal_todo_fix` shouldn't sync ARCHITECTURE.md on small drains), add it then. |
| audit_class enum mirror — should the JSON also declare each whitelist pattern's audit_class (mirror of F000034)? | Resolution: deferred. F000034's manifest stays the audit-class source of truth; this JSON stays the whitelist-and-category source of truth. Separation of concerns. |
| `--docs` negation flag (`--skip-docs README`)? | Resolution: deferred to v2 if operator demand surfaces. v1 = positive subset only; keeps parser surface small. |
| JSON Schema file (`cj-document-release.schema.json`) for IDE validation + ajv-strict parsing? | Resolution: deferred. Check 16's inline validation covers the workbench's needs; an external schema is over-engineering for v1. |
| Multi-repo federation (a global JSON that all consuming repos inherit defaults from)? | Resolution: deferred indefinitely; per-repo isolation is the simpler default. |
| Portability flip to standalone — when does it happen? | Resolution: only after at least one downstream repo successfully adopts `/CJ_document-release` with its own JSON. Don't pre-emptively flip. File a follow-up at that time. |
| Helper script ergonomics — should the helper take `--config <path>` arg instead of hardcoding `$(repo-root)/cj-document-release.json`? | Resolution: deferred. Hardcoded repo-root path matches F000029's helper and workbench convention. |
| Glob semantics edge cases — bash globstar quirks with dotfiles? | Mitigation: test coverage in Step 8 includes at least one `**`-using pattern. Helper isolates the quirks; SKILL.md doesn't need to know about them. |
| Bundled-in-same-PR risk: workbench's own JSON must match F000036's existing seed values or day-1 breaks | Mitigation: JSON's `whitelist_patterns` literally reproduces F000036's regex set in glob form; categories reproduce the 6 token mappings. Test `tests/cj-document-release-config.test.sh` asserts presence of all 6 F000036-compat tokens. |
| Atomic-commit ordering risk with pre-commit hook (Check 13 + Check 14 + Check 16 all fire on this PR) | Mitigation: stage all 16 files in one commit; intermediate states would fire validators. Same constraint as F000036; same stage-everything-once mitigation. |
| F000036 just shipped 30 min ago — is the workbench warm enough to do this follow-up? | Mitigation: yes. F000036's hardcoded set is fresh in operator memory; externalizing it now (while the design intent is still legible) is cheaper than later. Test fixtures from F000036 still relevant. |

## Definition of done

- [ ] `cj-document-release.json` exists at repo root with valid schema_version=1 + whitelist_patterns + categories.
- [ ] `scripts/cj-document-release-config.sh` exists, executable, `--validate` green against workbench's JSON.
- [ ] `skills/CJ_document-release/SKILL.md` no longer contains the F000036 hardcoded whitelist regex; delegates to helper.
- [ ] `skills/CJ_document-release/USAGE.md` documents the new convention; `last-updated` bumped.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain `[doc-sync-no-config]` row.
- [ ] All 3 cj_goal `USAGE.md` files have `last-updated` bumped to silence Check 14.
- [ ] `validate.sh` Check 16 enforces JSON schema when file exists.
- [ ] `tests/cj-document-release.test.sh` extended; `tests/cj-document-release-config.test.sh` new — both pass.
- [ ] `scripts/test.sh` wires both.
- [ ] `./scripts/validate.sh` exits 0 / 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] `CLAUDE.md` has new "cj-document-release.json convention" section.
- [ ] `VERSION` = 6.0.2; `CHANGELOG.md` has [6.0.2] entry in user-forward voice.
- [ ] PR opened against main via /ship.

## Not in scope

- Upstream `/document-release` modification — not ours to edit (per F000036 precedent, memory `project_workbench_auto_deploy_unsafe`).
- Per-verb overrides (`categories_by_verb`) — deferred to v2 schema bump.
- audit_class enum mirror from F000034 in the JSON — F000034 stays audit-class source of truth; F000037 stays whitelist/category source of truth.
- `--docs` negation flag (`--skip-docs <token>`) — v1 positive subset only.
- JSON Schema file (`cj-document-release.schema.json`) for IDE validation — deferred (Check 16 covers v1 needs).
- Multi-repo schema federation — deferred indefinitely; per-repo isolation is simpler default.
- Portability flip to `standalone` — requires at least one downstream adoption first; separate decision, separate PR.
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design.
- README.md per-skill workflow-chart column — out of scope, F000034 deferred.
- work-copilot/ analog config — workbench-only scope.
- Deprecation of any existing CJ_* skill — additive only.
- Behavior change for non-cj_goal callers of `/document-release` — they continue to call upstream directly.

## Pointers

- Parent tracker: [F000037_TRACKER.md](F000037_TRACKER.md)
- Roadmap: [F000037_ROADMAP.md](F000037_ROADMAP.md)
- Child story: [S000070_cj_document_release_config_impl/S000070_TRACKER.md](S000070_cj_document_release_config_impl/S000070_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-114944-doc-config-design-20260602-121101.md`
- F000036 (PR #192, v6.0.1) — direct predecessor; CJ_document-release skill being restructured. F000036's hardcoded whitelist becomes the seed for F000037's JSON.
- F000034 (PR #189, v5.0.19) — tracked-doc/ manifest convention. F000037 deliberately keeps separate (audit-class vs doc-sync-whitelist are different concerns).
- F000033 (PR #188, v5.0.18) — USAGE.md drift detection (Check 14). F000037 bumps CJ_document-release/USAGE.md `last-updated` (real content change) + 3 cj_goal USAGE.md timestamps (cosmetic — halt-taxonomy added).
- F000032 (PR #186, v5.0.17) — per-skill USAGE.md convention.
- F000029 (PR #178, v5.0.9) — `scripts/skills-doc-sync-check` is the pattern F000037's helper mirrors. F000029's marker-AUQ flow is unchanged.
