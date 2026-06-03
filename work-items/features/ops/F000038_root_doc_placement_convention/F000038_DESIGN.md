---
type: design
parent: F000038
title: "Root-doc placement convention + validate.sh Check 17 — Feature Design"
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

The workbench's human-readable surface is split between the repo root and `doc/`, and the split is implicit. Root currently holds 5 `*.md` docs (README, CHANGELOG, CLAUDE, CONTRIBUTING, TODOS) and 4 config files (skills-catalog.json, cj-document-release.json, template-registry.json, VERSION); `doc/` holds the three "explanation" docs (PHILOSOPHY, ARCHITECTURE, SKILL-CATALOG) that F000034 moved there and registered in a tracked-doc/ manifest.

The original ask was "group human-readable configs and docs into a single doc folder." Investigation reframed it: the explanation docs already moved (F000034) — under a strict "explanation docs live in `doc/`" convention, the migration is essentially done. What's left at root is pinned, tool-conventioned, or operational state, not "explanation": README (GitHub landing page), CLAUDE.md (Claude Code auto-loads `./CLAUDE.md`), CHANGELOG (`/ship` + `/document-release` write `./CHANGELOG.md`), CONTRIBUTING (GitHub surfaces it from root / `docs/` / `.github/`, not `doc/`), TODOS (wired into `/CJ_suggest`, `/CJ_goal_todo_fix`, `/ship` Step 14). Configs are tooling-pinned: `skills-catalog.json` is referenced ~246 times, `VERSION` ~120, by hardcoded root paths in scripts, validate.sh, and tests. Moving them is high-blast-radius churn for no functional gain.

So the real gap is not "files in the wrong place" — it is that **the placement boundary is implicit and unenforced**. A future contributor (human or agent) can drop a new `FOO.md` at root instead of `doc/FOO.md`, and nothing catches it. This feature codifies the convention and enforces it, with zero file moves.

## Shape of the solution

One atomic PR. Three files of substance touched (plus VERSION + CHANGELOG). The whole feature is a single directly-implementable user-story (S000071):

1. **`CLAUDE.md` (MODIFIED)** — new `## Doc placement convention (root vs doc/)` section, placed adjacent to the F000034 "/document-release workbench audit conventions" section (which owns the doc/ manifest) for locality. Contains the prose rule + a `### Tracked root docs allowlist` YAML block with 5 entries (path + `reason:`), and — as a prose comment line just ABOVE the block, NOT inside the fence — the two load-bearing constraints on the block.
2. **`scripts/validate.sh` (MODIFIED)** — new Check 17 inserted after Check 16. Flag-based-awk parser (same shape as Check 15) that disarms on ANY heading; `find . -maxdepth 1` root-md enumeration; orphan + missing ERROR branches via the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form; count-once PASS line.
3. **`scripts/test.sh` (MODIFIED)** — zzz-test-scaffold integration assertion (the KNOWN BLIND SPOT): `touch STRAY.md` → assert validate.sh ERROR+exit1 with the literal Check 17 orphan prefix; `rm STRAY.md` → assert exit0.
4. **`VERSION` + `CHANGELOG.md` (MODIFIED)** — PATCH bump 6.0.3 → next free slot + user-forward entry.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| CLAUDE.md convention section + allowlist manifest + validate.sh Check 17 + test.sh zzz-test-scaffold assertion + VERSION + CHANGELOG (atomic implementation) | S000071 | `S000071_root_doc_placement_convention_impl/S000071_TRACKER.md` |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Driver = convention consistency (D1): make the boundary explicit, not move files | All human-readable *explanation* docs already live in `doc/` (F000034). The migration is essentially done; the gap is that the boundary is implicit + unenforced. Reframed the original "group configs and docs into a folder" ask once the data showed the move was done and configs were tooling-pinned. |
| 2 | Scope = codify + enforce only (D2): no file moves; configs stay at root | `skills-catalog.json` (~246 refs), `VERSION` (~120 refs), `cj-document-release.json`, `template-registry.json` are tooling-pinned by hardcoded `./` paths. The convention *documents* config placement (addressing the original "configs" framing) but adds no config-file enforcement in v1. High-blast-radius churn for no functional gain rejected. |
| 3 | Mechanism = manifest in CLAUDE.md (D3, Approach B) over a hardcoded bash array (A) or a JSON config (C) | B: single source of truth in CLAUDE.md, self-documenting (`reason:` per entry), symmetric with F000034's doc/ manifest (the two together partition the top-level surface), reuses Check 15's proven parse shape. A splits the allowlist (validate.sh) from its rationale (CLAUDE.md prose) into two drifting places. C is over-engineering for 5 filenames + adds another root config surface, ironic for a tidy-the-root feature. |
| 4 | Root allowlist = the 5 current root docs, each with a stated `reason:` | README (GitHub landing), CLAUDE (auto-load), CHANGELOG (/ship + /document-release write target), CONTRIBUTING (GitHub-surfaced), TODOS (operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14). Nothing currently violates it → ERROR-strict ships safely with no migration. |
| 5 | ERROR-strict, not warning | Matches the repo ethos (F000037 strict-required; Checks 12–16 are ERROR-strict). Safe because all 5 current root docs are allowlisted; a stray new root `*.md` ERRORs + exits 1. |
| 6 | Check 17 disarms on ANY heading (`^#`), not just `^###` — more robust than Check 15 | The allowlist is the last `###` subsection under its `##` section; disarming only on `###` would over-capture `- path:` lines from a following `##` section. Retrofitting Check 15 to the same form is out of scope (Check 15 works as-is given its position). |
| 7 | Check 17 uses the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form, not the older `fail()` helper | Checks 15/16 increment ERRORS inline with the `  ERROR:` prefix; Check 17 matches its immediate neighbors rather than the abandoned `fail()` helper (prefix `  FAIL:`). The test.sh assertion greps for the right literal (`  ERROR:`). |
| 8 | Single user-story decomposition (atomic implementation) | CLAUDE.md section + Check 17 + test.sh assertion + VERSION + CHANGELOG ship atomically in one commit/PR (same shape as F000037 / S000070). Pre-commit hook runs validate.sh; stage everything once. Splitting adds bookkeeping without splitting risk. |
| 9 | No SKILL.md changes → no USAGE.md drift (Check 13/14 untouched) | This is a CLAUDE.md + validate.sh + test.sh change only. No catalog churn, no manifest-JSON edits. Keeps the diff narrow + additive. |
| 10 | PR-stop at /ship per /CJ_goal_feature semantics; no /land-and-deploy | /CJ_goal_feature stops at PR by design — PR is the architecture gate (human review). Per memory `project_workbench_auto_deploy_unsafe`. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| Check 17's awk parser silently drops entries below a `#`-comment line in the YAML block | Mitigation: CLAUDE.md prose just above the block warns NO `#`-leading lines inside the block. Failure mode is loud, not silent — a dropped entry → empty/short allowlist → orphan ERROR for every root `*.md`. Smoke S4 walks the clean PASS; the constraint comment is verified by E2 diff review. |
| Renaming the `### Tracked root docs allowlist` heading parses to an empty allowlist | Mitigation: heading text is matched literally; the CLAUDE.md constraint comment flags it as load-bearing. Fails loudly (orphan ERROR for every root `*.md`), never silently passes. |
| The test.sh zzz-test-scaffold edit is a KNOWN RECURRING BLIND SPOT (F000032/F000034/F000035/F000037 all forgot it) | Mitigation: it is a mandatory pre-flight item in the implement prompt AND an explicit TEST-SPEC smoke row (S3) — not an afterthought. Verified by running `./scripts/test.sh` and confirming the new assertion executes. |
| Check 17 over-captures `- path:` lines from a following `##` section if disarm logic is wrong | Mitigation: disarm on ANY heading (`/^#/`), not just `^###`. The allowlist is the LAST `###` subsection under its `##` section, so the next `##` (or any heading) correctly terminates capture. |
| Empty-allowlist edge case not separately guarded | Accepted: an empty/renamed-heading allowlist surfaces as an orphan ERROR for every root `*.md` — acceptable, fails loudly. The heading + entries are required and present; no extra guard needed. |
| Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) | Out of scope — the convention governs human-readable `*.md` docs only. Deferred. |
| Config-placement enforcement (a sibling "tracked root configs" manifest) | Deferred to v2. Configs are tooling-pinned + stable; documenting the rule (prose) is enough now. Honors the original "configs" mention without enforcement churn. |
| Retrofit Check 15's parser to also disarm-on-any-heading | Out of scope; Check 15 works as-is given its position. Check 17 uses the more robust form. |
| `.github/`-style relocation of CONTRIBUTING | Not pursued — keeping it at root preserves GitHub's auto-surfaced "Contributing guidelines" link. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] CLAUDE.md has a `## Doc placement convention (root vs doc/)` section: prose rule + `### Tracked root docs allowlist` block with all 5 entries (path + reason) + the two load-bearing constraints stated as a prose comment just above the block.
- [ ] `scripts/validate.sh` Check 17 present; parses the allowlist (flag-based awk, disarm-on-any-heading); has both orphan and missing branches; count-once PASS line.
- [ ] On the clean PR HEAD, `./scripts/validate.sh` exits 0 (Check 17 PASS, 0 errors, 0 warnings).
- [ ] Synthesized violation: `touch STRAY.md` at repo root → `validate.sh` exits non-zero with the Check 17 orphan message. `rm STRAY.md` → exits 0.
- [ ] `scripts/test.sh` `zzz-test-scaffold` integration extended with the Check 17 orphan assertion; full `./scripts/test.sh` exits 0.
- [ ] No `SKILL.md` / `USAGE.md` / `skills-catalog.json` / manifest-JSON modified (no doc-drift, no catalog churn).
- [ ] README.md, CLAUDE.md, and all 4 root config files remain at root, byte-for-byte unchanged.
- [ ] CHANGELOG entry is user-forward; VERSION bumped to the next free slot.
- [ ] PR opened against main via /ship; /CJ_goal_feature stops at PR per design.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- File moves of any kind — codify + enforce only; nothing relocates.
- Config-file placement enforcement (a "tracked root configs" manifest) — deferred to v2; configs stay at root, the prose documents the rule only.
- Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) — convention governs human-readable `*.md` only.
- `doc/` coverage — that is Check 15's job (F000034's tracked-doc/ manifest); Check 17 is root `*.md` only.
- Docs under `skills/`, `templates/`, `work-copilot/`, `work-items/`, `tests/` — follow their own conventions (per-skill USAGE.md, template naming, work-item taxonomy), explicitly out of this convention's scope.
- Retrofitting Check 15's parser to disarm-on-any-heading — Check 17 uses the robust form; Check 15 works as-is.
- `.github/`-style relocation of CONTRIBUTING — keeping it at root preserves GitHub's auto-surfaced link.
- SKILL.md / USAGE.md / catalog / manifest-JSON edits — none touched; no doc-drift.
- Upstream `/document-release` modification — not ours to edit (memory `feedback_workbench_scope`, `project_workbench_auto_deploy_unsafe`).
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR by design.
- work-copilot/ analog convention — workbench-only scope.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000038_TRACKER.md](F000038_TRACKER.md)
- Roadmap: [F000038_ROADMAP.md](F000038_ROADMAP.md)
- Child story: [S000071_root_doc_placement_convention_impl/S000071_TRACKER.md](S000071_root_doc_placement_convention_impl/S000071_TRACKER.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-152028-3848-root-doc-convention-design-20260602-154648.md`
- F000034 (PR #189, v5.0.19) — tracked-doc/ manifest + Check 15. F000038 is the symmetric root-side counterpart; reuses Check 15's parse shape. Deliberately separate: F000034 declares `doc/` contents, F000038 declares root `*.md`; together they partition the top-level doc surface.
- F000037 (PR #194, v6.0.3) — most recent root JSON (cj-document-release.json); the event that made "should the root surface be consolidated?" a live question. F000038 answers: codify the boundary, don't consolidate.
- F000032 (PR #186, v5.0.17) — per-skill USAGE.md convention; start of the doc-infra lineage F000038 caps.
- F000033 (PR #188, v5.0.18) — USAGE.md drift detection (Check 14); F000038 deliberately makes NO SKILL.md change so Check 14 stays untouched.
