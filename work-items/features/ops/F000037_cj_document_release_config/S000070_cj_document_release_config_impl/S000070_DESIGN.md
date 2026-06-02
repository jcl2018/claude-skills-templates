---
type: design
parent: S000070
title: "Per-repo cj-document-release.json strict-required config — implementation design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A user-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000037_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

F000036 (PR #192, v6.0.1, shipped 30 min ago) introduced `/CJ_document-release` with a HARDCODED doc-only auto-commit whitelist + `--docs <token>` map in SKILL.md prose. Two coupled problems with that shape: (1) per-repo variation — workbench's doc surface (`doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `doc/SKILL-CATALOG.md`, root convention docs) isn't transferable to other repos; (2) `--docs` flag's utility caps at "what F000036's author imagined" (6 baked-in tokens), not "what THIS repo declares." F000034's CLAUDE.md tracked-doc/ manifest is the right shape for audit-class metadata (closed enum, narrow purpose) but the wrong shape for CJ_document-release's needs (open category set, machine-parseable, schema-versionable, per-repo customizable).

This story externalizes both to a strict-required `cj-document-release.json` at repo root (schema v1: `whitelist_patterns` globs + `categories` token-to-glob map). See parent `F000037_DESIGN.md` for the full Approach A/B/C analysis (B chosen, helper script + thin SKILL.md, mirroring F000029) + strict-required posture rationale (D2 option C, no fallback).

## Shape of the solution

Atomic implementation across 16 files in one PR (one commit, staged together for the pre-commit hook):

1. `scripts/cj-document-release-config.sh` (NEW) — bash helper, ~70 lines.
2. `cj-document-release.json` (NEW) — workbench's own config.
3. `skills/CJ_document-release/SKILL.md` (MODIFIED) — hardcoded whitelist + token list removed; delegates to helper.
4. `skills/CJ_document-release/USAGE.md` (MODIFIED) — new Per-repo-config subsection + new pitfall + last-updated bump.
5-7. 3 cj_goal SKILL.md halt-taxonomy edits ([doc-sync-no-config] row inserted).
8-10. 3 cj_goal USAGE.md last-updated bumps (cosmetic Check 14 silence).
11. `scripts/validate.sh` (MODIFIED) — new Check 16: schema enforcement when file exists.
12. `tests/cj-document-release.test.sh` (MODIFIED) — ≥8 new assertions.
13. `tests/cj-document-release-config.test.sh` (NEW) — ≥6 assertions.
14. `scripts/test.sh` (MODIFIED) — wire the new test file.
15. `CLAUDE.md` (MODIFIED) — new "cj-document-release.json convention" H2 section.
16. `VERSION` + `CHANGELOG.md` — PATCH bump 6.0.1 → 6.0.2 + user-forward entry.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | Atomic under pre-commit hook. Same shape as F000036 (S000069). Splitting adds bookkeeping without splitting risk. Check 13 (USAGE.md presence) + Check 14 (USAGE.md drift) + Check 16 (JSON schema) would block intermediate-state commits anyway. |
| 2 | `[doc-sync-no-config]` is a SEPARATE halt class from `[doc-sync-red]` and `[doc-sync-non-doc-write]` | Three orthogonal failure modes: config-missing/invalid (F000037), audit-failed (F000036), upstream-misbehaved (F000036). Each gets its own halt class for diagnostic clarity in the journal. |
| 3 | Helper script uses bash globstar via `shopt -s globstar nullglob`, not Node minimatch | Mirrors F000029's `scripts/skills-doc-sync-check` (also pure bash). Avoids introducing a Node/Bun runtime dependency to `scripts/` (first `.mjs` should be a separate decision, not folded into this PR). Glob edge cases isolated to one testable surface. |
| 4 | Workbench's own JSON seed values reproduce F000036's hardcoded set BYTE-FOR-BYTE in glob form | Zero day-1 breakage. F000036's regex (`^doc/.+\.md$`) becomes glob (`doc/**/*.md`); same files matched. Test `tests/cj-document-release-config.test.sh` asserts all 6 F000036-compat token names present. |
| 5 | `validate.sh` Check 16 is CONDITIONAL — skips silently when `cj-document-release.json` missing | Non-adopting repos (without the skill installed, or in transition before the JSON is authored) pass Check 16. Once the file exists, Check 16 is strict. Mirrors F000034 Check 15's conditional shape for `doc/` files. |
| 6 | `last-updated` bumps for 3 cj_goal USAGE.md files use ISO-8601 second-resolution UTC | Required by F000033 Check 14's staged-aware override pattern. `$(date -u +%Y-%m-%dT%H:%M:%SZ)` matches the CLAUDE.md-documented convention. Pre-commit hook's staged-aware Check 14 won't block these timestamp-only commits. |
| 7 | New CLAUDE.md "cj-document-release.json convention" section goes between F000034's tracked-doc/ manifest section and TODOS.md hygiene section | Logical sibling of F000034's section (both are "workbench-internal docs governance"). TODOS.md hygiene is separate concern, comes after. |
| 8 | No `--config <path>` arg on the helper; hardcoded `$(repo-root)/cj-document-release.json` | Matches F000029's helper (no `--config` either). Workbench convention: per-repo configs live at repo root with hardcoded names. If multi-repo federation becomes a need later, that's a v2 schema bump. |
| 9 | `portability: workbench` stays in catalog (no change) | F000037 is the enabler for future portability flip but doesn't trigger the flip itself. Requires at least one downstream adoption first. Separate decision, separate PR. |
| 10 | Halt-taxonomy row ordering: `[doc-sync-no-config]` BETWEEN `[doc-sync-red]` and `[doc-sync-non-doc-write]` | Ordered by configuration-time → run-time → output-time concerns: no-config (configuration missing) → red (audit failed at runtime) → non-doc-write (upstream produced bad output). Same ordering across all 3 cj_goal SKILL.md tables. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 16 files in one PR is a wide diff | Mitigation: largely additive (new helper + new JSON + new check + new test + new docs sections). Skill rewrite is the only non-additive surface; covered by smoke test S1 (grep that hardcoded regex is gone + helper-script delegation in SKILL.md). |
| Atomic-commit ordering with pre-commit hook | Same constraint as F000036: stage all 16 files once. Intermediate states would fire Check 13 or Check 14 or Check 16. |
| Test asserting `--expand-whitelist` returns ≥6 files depends on workbench having ≥6 matching files | Mitigation: the 6 entries in `whitelist_patterns` correspond to 6+ real files in the workbench seed (README.md, CHANGELOG.md, CLAUDE.md, ARCHITECTURE.md, doc/PHILOSOPHY.md, doc/ARCHITECTURE.md, doc/SKILL-CATALOG.md, templates/doc-*.md). The workbench seed will return ≥6; test asserts `-ge 6`. |
| Bash globstar quirk with dotfiles | Mitigation: helper uses `shopt -s globstar nullglob` (not `dotglob`). Dotfiles excluded by default — matches operator intent for doc-sync (don't sync `.github/`, `.gitignore`, etc.). |
| Helper script line count | Target: ~70 lines. Bash is verbose but readable; keep it under 100. If it balloons, consider extracting a JSON-validation function (mirrors F000029 helper's `--validate` extraction). |
| `[doc-sync-no-config]` halt journal entry shape | Use the F000027 halt-marker shape (next_action / resume_cmd / pr_url / aux fields). Same shape as F000036's `[doc-sync-red]` and `[doc-sync-non-doc-write]` halt entries. |
| Strict-required when JSON exists but is malformed (e.g., `schema_version: 2` for a not-yet-existing v2) | Helper exits 1 + emits `[doc-sync-no-config] schema_version=2 unsupported (this helper supports 1)`. Operator sees the explicit unsupported-version message → can downgrade JSON or wait for v2 helper release. |
| Check 16 false-positives in fresh-clone scenarios | Mitigation: non-adopting repos pass (skip silently when file missing). Workbench's own JSON is committed in this same PR → Check 16 fires on PR HEAD and PASSes immediately. |
| `--docs` arg parsing edge cases when token doesn't exist in `categories` | Helper exits 1 + emits `[doc-sync-no-config] category 'xyz' not declared in cj-document-release.json`. Operator sees the explicit not-declared message → can add to JSON or use a different token. |
| The CLAUDE.md convention section is in the project-context block read by /document-release | Yes, F000034's `/document-release` reads CLAUDE.md as project context. The new section will be picked up automatically; no separate wiring needed. |

## Definition of done

- [ ] All acceptance criteria from S000070_TRACKER.md verified.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both exit 0 on PR HEAD.
- [ ] PR opened against main via /ship; /CJ_goal_feature stops at PR per design.

## Not in scope

- Upstream `/document-release` modification (per F000036 precedent).
- Per-verb overrides (`categories_by_verb`) — deferred to v2 schema bump.
- audit_class enum mirror from F000034 in the JSON — F000034 stays audit-class source of truth.
- `--docs` negation flag (`--skip-docs <token>`) — deferred to v2.
- JSON Schema file (`cj-document-release.schema.json`) — Check 16 covers v1.
- Multi-repo federation — deferred indefinitely.
- Portability flip to standalone — separate PR after downstream adoption.
- /land-and-deploy in this PR — /CJ_goal_feature stops at PR.
- README.md per-skill chart column (F000034 deferred).
- work-copilot/ analog config — workbench-only scope.

## Pointers

- Parent feature design: [../F000037_DESIGN.md](../F000037_DESIGN.md)
- Parent feature tracker: [../F000037_TRACKER.md](../F000037_TRACKER.md)
- Parent feature roadmap: [../F000037_ROADMAP.md](../F000037_ROADMAP.md)
- SPEC: [S000070_SPEC.md](S000070_SPEC.md)
- TEST-SPEC: [S000070_TEST-SPEC.md](S000070_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-114944-doc-config-design-20260602-121101.md`
- F000036 (PR #192, v6.0.1) — direct predecessor; the CJ_document-release skill being restructured. Hardcoded whitelist + token list becomes seed data for F000037's JSON.
- F000034 (PR #189, v5.0.19) — tracked-doc/ manifest; deliberately separate (audit-class vs whitelist are different concerns).
- F000033 (PR #188, v5.0.18) — Check 14 (USAGE.md freshness); same staged-aware override pattern reused for the 3 cj_goal USAGE.md timestamp bumps.
- F000032 (PR #186, v5.0.17) — per-skill USAGE.md convention; CJ_document-release/USAGE.md follows it.
- F000029 (PR #178, v5.0.9) — `scripts/skills-doc-sync-check` is the pattern F000037's helper mirrors. F000029's marker-AUQ flow unchanged.
