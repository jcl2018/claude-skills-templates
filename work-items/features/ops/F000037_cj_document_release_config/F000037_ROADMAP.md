---
type: roadmap
parent: F000037
title: "Per-repo cj-document-release.json strict-required config — Roadmap"
date: 2026-06-02
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Externalize F000036's hardcoded doc-only auto-commit whitelist + `--docs <token>` mapping to a **strict-required** `cj-document-release.json` at repo root (schema v1: `whitelist_patterns` globs + `categories` object mapping token names to glob arrays). Add a bash helper `scripts/cj-document-release-config.sh` (subcommands `--parse` / `--expand-whitelist` / `--resolve <token>` / `--validate`) that mirrors F000029's `scripts/skills-doc-sync-check` shape. Rewrite `skills/CJ_document-release/SKILL.md` to delegate to the helper — hardcoded whitelist and `--docs` token list are removed. Add a new halt class `[doc-sync-no-config]` (halt_at_doc_sync_no_config) for missing/invalid/schema-unsupported JSON; thread it through all 3 cj_goal SKILL.md halt-taxonomy tables. Add `validate.sh` Check 16 enforcing schema when file exists. Bundle-in-same-PR the workbench's own `cj-document-release.json` seeded with F000036's existing hardcoded set + workbench paths (`doc/**/*.md`, `templates/doc-*.md`). Add a CLAUDE.md "cj-document-release.json convention" H2 section (sibling of F000034's tracked-doc/ manifest). Add 8 new assertions to `tests/cj-document-release.test.sh` + a new `tests/cj-document-release-config.test.sh`; wire both into `scripts/test.sh`. Workbench-internal — no upstream skill changes, no /land-and-deploy in this PR.

## Non-Goals

- Upstream `/document-release` modification — not ours to edit. Integration via Skill tool with project-context priming (memory `project_workbench_auto_deploy_unsafe`).
- Per-verb overrides (`categories_by_verb`) — deferred to v2 schema bump if operator demand surfaces.
- audit_class enum mirror from F000034 in the JSON — F000034 stays audit-class source of truth; F000037 stays whitelist/category source of truth.
- `--docs` negation flag (`--skip-docs <token>`) — v1 positive subset only.
- JSON Schema file (`cj-document-release.schema.json`) — Check 16 covers v1 needs.
- Multi-repo federation — deferred indefinitely.
- Portability flip from `workbench` to `standalone` — requires at least one downstream adoption first.
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design.
- README.md per-skill workflow-chart column — F000034 deferred.
- work-copilot/ analog config — workbench-only scope.

## Success Criteria

- [ ] `cj-document-release.json` exists at repo root with valid `schema_version: 1`, non-empty `whitelist_patterns` array of globs, and a `categories` object.
- [ ] `scripts/cj-document-release-config.sh` exists, executable (`chmod +x`), with subcommands `--parse` / `--expand-whitelist` / `--resolve <token>` / `--validate`.
- [ ] `bash scripts/cj-document-release-config.sh --validate` exits 0 against the workbench's JSON.
- [ ] `bash scripts/cj-document-release-config.sh --resolve readme` returns `README.md`.
- [ ] `bash scripts/cj-document-release-config.sh --expand-whitelist` returns ≥6 real files.
- [ ] `bash scripts/cj-document-release-config.sh --resolve nonexistent-category` exits non-zero with `[doc-sync-no-config]` emitted.
- [ ] `skills/CJ_document-release/SKILL.md` no longer contains the F000036 hardcoded whitelist regex (grep `^(README|CHANGELOG|CLAUDE|ARCHITECTURE)` against the file returns 0 lines outside of CHANGELOG-style references). Delegates to helper via `--parse` / `--expand-whitelist` / `--resolve`.
- [ ] `skills/CJ_document-release/USAGE.md` has new "Per-repo config" subsection under Mental model; new common-pitfall row for `[doc-sync-no-config]`; `last-updated` bumped to ISO-8601 second-resolution.
- [ ] All 3 cj_goal `SKILL.md` halt-taxonomy tables contain a new `[doc-sync-no-config]` row positioned between `[doc-sync-red]` and `[doc-sync-non-doc-write]`.
- [ ] All 3 cj_goal `USAGE.md` files have `last-updated` bumped to silence Check 14 (cosmetic SKILL.md edit).
- [ ] `scripts/validate.sh` Check 16 ERRORs on synthesized bad JSON (verify by hand-corrupting the JSON temporarily): invalid JSON, missing/unsupported `schema_version`, missing-or-empty `whitelist_patterns`, missing/non-object `categories`, per-category non-array values. Conditional — non-adopting repos pass when file absent.
- [ ] `tests/cj-document-release.test.sh` extended with ≥8 new assertions (JSON exists, helper exists+executable, `--validate` green, `--parse` shape, `--expand-whitelist` ≥6 files, `--resolve readme`, `--resolve nonexistent` halt, SKILL.md mentions cj-document-release.json post-rewrite).
- [ ] `tests/cj-document-release-config.test.sh` new file with ≥6 assertions (valid JSON, schema_version=1, whitelist_patterns non-empty array, categories non-empty object, identifier-shape category names, presence of all 6 F000036-compat tokens).
- [ ] `scripts/test.sh` wires both test files; full suite exits 0.
- [ ] `./scripts/validate.sh` exits 0 / 0 errors / 0 warnings on PR HEAD (all 16 checks pass).
- [ ] `./scripts/test.sh` exits 0 on PR HEAD.
- [ ] `CLAUDE.md` has a new "cj-document-release.json convention" H2 section inserted between F000034's tracked-doc/ manifest section and the TODOS.md hygiene section.
- [ ] `VERSION` reads `6.0.2`; queue-collision preflight via `./scripts/check-version-queue.sh` confirmed the slot is free before /ship.
- [ ] `CHANGELOG.md` has a new `## [6.0.2] — 2026-06-02` entry under `### Added`, in user-forward voice, naming F000037 + strict-required posture + helper-pattern parallel to F000029.
- [ ] PR opened against main via `/ship` (pre-landing review included). PR body notes F000036 lineage (direct follow-up) + F000029 helper-pattern parallel. /CJ_goal_feature stops at PR per design.
- [ ] Manual smoke A (post-merge): invoke `/CJ_document-release --docs readme` from a feature branch with a stale README. Helper resolves `readme` → `README.md`; only README auto-commits; success summary printed.
- [ ] Manual smoke B (post-merge): temporarily rename `cj-document-release.json` → `.bak`, invoke `/CJ_document-release` from a feature branch. Helper exits 1 with `[doc-sync-no-config]`; orchestrator halts with `halted_at_doc_sync_no_config`. Rename back; rerun green.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000070](S000070_cj_document_release_config_impl/S000070_TRACKER.md) | Per-repo cj-document-release.json strict-required config — implementation (helper script + JSON + SKILL.md/USAGE.md rewrite + 3 cj_goal halt-taxonomy edits + 4 USAGE.md timestamp bumps + validate.sh Check 16 + CLAUDE.md convention + 2 tests + scripts/test.sh + VERSION + CHANGELOG) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000070 (helper + JSON + skill rewrite + halt-taxonomy + Check 16 + CLAUDE.md + tests + VERSION + CHANGELOG) | 2026-06-02 | Not Started | chjiang | One atomic PR via /ship against main; /CJ_goal_feature stops at PR | — |
| 2 | After merge: live dogfood A — `/CJ_document-release --docs readme` from a stale-README feature branch | 2026-06+ | Not Started | chjiang | Helper resolves token; only README auto-commits; success summary printed | #1 |
| 3 | After merge: live dogfood B — rename JSON → `.bak`, invoke `/CJ_document-release`, verify `[doc-sync-no-config]` halt; restore JSON, rerun green | 2026-06+ | Not Started | chjiang | Strict-required posture confirmed in practice | #1 |
| 4 | After merge: downstream adoption — author a `cj-document-release.json` in a non-workbench repo; verify per-repo customization works | 2026-06+ | Not Started | chjiang | If green, file a follow-up to flip `portability: workbench` → `standalone` | #2, #3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-02: Created — F000037 scaffolded from /office-hours design doc (`chjiang-cj-feat-20260602-114944-doc-config-design-20260602-121101.md`).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
(branches from origin/main HEAD post-F000036 merged at PR #192, v6.0.1)
                                  |
                                  v
#1 Ship S000070 (helper + JSON + SKILL.md rewrite + 3-way halt-taxonomy + Check 16 + CLAUDE.md + tests + VERSION + CHANGELOG)
                                  |
                                  v
                            (PR review = architecture gate; human merge)
                                  |
                  +---------------+---------------+
                  v                               v
#2 Live dogfood A:                          #3 Live dogfood B:
   /CJ_document-release --docs readme         rename JSON → .bak, verify
   from feature branch                        [doc-sync-no-config] halt
                  |                               |
                  +---------------+---------------+
                                  v
#4 Downstream adoption: author cj-document-release.json in another repo;
   verify per-repo customization works; if green, file follow-up to flip
   portability workbench → standalone
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Per-verb overrides (`categories_by_verb: { feature: [...], defect: [...] }`)? | Deferred to v2 (schema_version 2). If a verb-specific carve-out becomes load-bearing, add it then. |
| audit_class enum mirror from F000034 in the JSON? | Deferred. F000034's manifest stays audit-class source of truth; this JSON stays whitelist/category source of truth. |
| `--docs` negation flag (`--skip-docs <token>`)? | Deferred to v2 if operator demand surfaces. v1 positive subset only. |
| JSON Schema file (`cj-document-release.schema.json`) for IDE validation? | Deferred. Check 16's inline validation covers v1 needs. |
| Multi-repo federation (global JSON inherited by consuming repos)? | Deferred indefinitely; per-repo isolation is simpler default. |
| Portability flip to `standalone`? | After at least one downstream adoption succeeds. Don't pre-emptively flip. |
| Helper script `--config <path>` arg instead of hardcoded repo-root JSON path? | Deferred. Hardcoded repo-root path matches F000029's helper convention. |
| Glob semantics edge cases (dotfiles, `**` quirks)? | Test coverage in Step 8 includes at least one `**`-using pattern. Helper isolates the quirks. |
