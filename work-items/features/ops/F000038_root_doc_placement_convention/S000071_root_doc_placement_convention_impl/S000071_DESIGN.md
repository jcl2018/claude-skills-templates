---
type: design
parent: S000071
title: "Root-doc placement convention + validate.sh Check 17 — implementation design"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
reviewers: []
---

<!-- A user-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000038_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

The workbench's human-readable surface is split between the repo root and `doc/`, and the split is implicit + unenforced. The explanation docs already moved to `doc/` (F000034) and are machine-checked by Check 15's tracked-doc/ manifest; what remains at root is pinned (README), tool-conventioned (CLAUDE.md auto-load, CHANGELOG write target, CONTRIBUTING GitHub-surfaced), or operational state (TODOS), plus tooling-pinned configs (skills-catalog.json ~246 refs, VERSION ~120). The gap: a future contributor can drop a new `FOO.md` at root instead of `doc/FOO.md` and nothing catches it. This story codifies the convention in CLAUDE.md and enforces it with a new validate.sh Check 17, with ZERO file moves. See parent `F000038_DESIGN.md` for the full Approach A/B/C analysis (B chosen — CLAUDE.md manifest symmetric with F000034) and the convention-consistency reframe.

## Shape of the solution

Atomic implementation across 3 substantive files (+ VERSION + CHANGELOG) in one PR (one commit, staged together for the pre-commit hook):

1. `CLAUDE.md` (MODIFIED) — new `## Doc placement convention (root vs doc/)` section adjacent to F000034's "/document-release workbench audit conventions" section: prose rule + a load-bearing-constraint comment line (just above the block, NOT inside the fence) + a `### Tracked root docs allowlist` YAML block with 5 entries (path + reason).
2. `scripts/validate.sh` (MODIFIED) — new Check 17 after Check 16: flag-based-awk allowlist parser disarming on ANY heading; `find . -maxdepth 1 -type f -name '*.md'` enumeration; 17-orphan + 17-missing ERROR branches via inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))`; count-once PASS line.
3. `scripts/test.sh` (MODIFIED) — zzz-test-scaffold integration assertion (KNOWN BLIND SPOT): touch STRAY.md → assert validate.sh ERROR+exit1 with the literal Check 17 orphan prefix; rm STRAY.md → assert exit0.
4. `VERSION` + `CHANGELOG.md` (MODIFIED) — PATCH bump 6.0.3 → next free slot (likely 6.0.4) + user-forward entry.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | Atomic under the pre-commit hook (runs validate.sh). Same shape as F000037 (S000070). Stage all touched files once; intermediate states could fail the very check being added. Splitting adds bookkeeping without splitting risk. |
| 2 | Mechanism = CLAUDE.md manifest (Approach B) over bash array (A) / JSON config (C) | B: single source of truth, self-documenting (`reason:` per entry), symmetric with F000034's doc/ manifest, reuses Check 15's parse shape. A splits allowlist from rationale into two drifting places. C over-engineers 5 filenames + adds a root config surface (ironic for a tidy-the-root feature). |
| 3 | Check 17 disarms on ANY heading (`/^#/`), not just `^###` | The allowlist is the LAST `###` subsection under its `##` section; disarming only on `###` would over-capture `- path:` lines from a following `##` section. Strictly more robust than Check 15's narrower form (Check 15 left as-is given its position). |
| 4 | Inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form, not the fail() helper | Checks 15/16 increment ERRORS inline with the `  ERROR:` prefix; Check 17 matches its neighbors, NOT the abandoned `fail()` helper (`  FAIL:`). The test.sh assertion greps for the `  ERROR:` literal. |
| 5 | Root allowlist = the 5 current root docs, each with a `reason:` | README/CLAUDE/CHANGELOG/CONTRIBUTING/TODOS. Nothing currently violates → ERROR-strict ships safely day-one with no migration. |
| 6 | Load-bearing constraints stated as a CLAUDE.md prose comment (above the fence, not inside) | Two constraints — no `#`-leading lines in the block (parser disarms on any `#` and drops entries below); heading text matched literally (rename → empty allowlist → orphan ERROR for every root `*.md`). Inside-the-fence comments would themselves trip the `#` disarm; the prose-comment placement is deliberate. |
| 7 | test.sh zzz-test-scaffold orphan assertion is mandatory (KNOWN BLIND SPOT) | F000032/F000034/F000035/F000037 all needed this parallel edit and the implement step forgot it each time. Pre-flight item + explicit TEST-SPEC row (S3). |
| 8 | No SKILL.md change → Check 13/14 untouched | CLAUDE.md + validate.sh + test.sh + VERSION + CHANGELOG only. No catalog churn, no manifest-JSON edits. Narrow + additive diff (except version bump). |
| 9 | ERROR-strict, not warning | Matches the repo ethos (F000037 strict-required; Checks 12–16 ERROR-strict). A stray new root `*.md` ERRORs + exits 1. |
| 10 | Config-placement enforcement deferred to v2 | Configs are tooling-pinned + stable; the prose documents the rule, no enforcement churn now. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| awk parser silently drops entries below a `#`-comment line in the block | Mitigation: CLAUDE.md prose-comment warns NO `#`-leading lines inside the block. Failure is loud (dropped entry → short/empty allowlist → orphan ERROR for every root `*.md`), not silent. Verified by clean-PASS smoke S4 + constraint-comment diff review E2. |
| Renaming the `### Tracked root docs allowlist` heading → empty allowlist | Mitigation: heading matched literally; constraint comment flags it as load-bearing. Fails loudly (orphan ERROR for every root `*.md`). |
| test.sh zzz-test-scaffold edit forgotten (recurring blind spot) | Mitigation: mandatory pre-flight item + explicit TEST-SPEC smoke row S3; verified by `./scripts/test.sh` running the new assertion. |
| Check 17 over-captures `- path:` lines from a following `##` section | Mitigation: disarm on ANY heading (`/^#/`). The allowlist is the last `###` subsection; the next heading terminates capture correctly. |
| Empty-allowlist edge case not separately guarded | Accepted: surfaces as orphan ERROR for every root `*.md` — fails loudly. Heading + entries are required + present; no extra guard needed. |
| The `  ERROR:` vs `  FAIL:` prefix mismatch would silently break the test | Mitigation: Check 17 uses the inline `  ERROR:` form (Checks 15/16); the test greps for `  ERROR: root doc STRAY.md is not in the CLAUDE.md`. Decision #4 locks this. |
| `find . -maxdepth 1` from a worktree subdir vs repo root | Mitigation: validate.sh runs from repo root (pre-commit hook + `./scripts/validate.sh`); the existing checks already assume cwd = repo root. Check 17 follows suit. |

## Definition of done

- [ ] All acceptance criteria from S000071_TRACKER.md verified.
- [ ] `./scripts/validate.sh` exits 0 on PR HEAD (Check 17 PASS: 5 entries; 0 errors / 0 warnings).
- [ ] Synthesized violation walked: `touch STRAY.md` → validate.sh non-zero + Check 17 orphan ERROR; `rm STRAY.md` → exit 0.
- [ ] `./scripts/test.sh` exits 0 on PR HEAD (extended zzz-test-scaffold runs + passes).
- [ ] PR opened against main via /ship; /CJ_goal_feature stops at PR per design.

## Not in scope

- File moves of any kind — codify + enforce only.
- Config-file placement enforcement (a "tracked root configs" manifest) — deferred to v2.
- Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) — convention governs human-readable `*.md` only.
- `doc/` coverage — Check 15's job; Check 17 is root `*.md` only (`find . -maxdepth 1`).
- Per-subtree docs (skills/, templates/, work-copilot/, work-items/, tests/) — own conventions.
- Retrofitting Check 15's parser to disarm-on-any-heading — Check 17 uses the robust form; Check 15 works as-is.
- `.github/`-style relocation of CONTRIBUTING — keeping it at root preserves GitHub's auto-surfaced link.
- SKILL.md / USAGE.md / catalog / manifest-JSON edits — none touched; no doc-drift.
- Upstream `/document-release` modification — not ours to edit (memory `feedback_workbench_scope`).
- `/land-and-deploy` step in this PR — /CJ_goal_feature stops at PR.
- work-copilot/ analog convention — workbench-only scope.

## Pointers

- Parent feature design: [../F000038_DESIGN.md](../F000038_DESIGN.md)
- Parent feature tracker: [../F000038_TRACKER.md](../F000038_TRACKER.md)
- Parent feature roadmap: [../F000038_ROADMAP.md](../F000038_ROADMAP.md)
- SPEC: [S000071_SPEC.md](S000071_SPEC.md)
- TEST-SPEC: [S000071_TEST-SPEC.md](S000071_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260602-152028-3848-root-doc-convention-design-20260602-154648.md`
- F000034 (PR #189, v5.0.19) — tracked-doc/ manifest + Check 15; F000038 is the symmetric root-side counterpart, reuses Check 15's parse shape. Deliberately separate (doc/ vs root `*.md`); together they partition the top-level surface.
- F000037 (PR #194, v6.0.3) — most recent root JSON; the event that made root consolidation a live question. F000038 answers: codify the boundary, don't consolidate.
- F000033 (PR #188, v5.0.18) — Check 14 (USAGE.md freshness); F000038 makes NO SKILL.md change so Check 14 stays untouched.
- F000032 (PR #186, v5.0.17) — per-skill USAGE.md convention; start of the doc-infra lineage F000038 caps.
