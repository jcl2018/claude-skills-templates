---
type: design
parent: S000063
title: "Move + rewrite philosophy.md → doc/PHILOSOPHY.md, add doc/ARCHITECTURE.md, README + CLAUDE.md edits — Story Design"
version: 1
status: Approved
date: 2026-05-31
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md — brief; the heavy design context lives at the
     parent feature's F000030_DESIGN.md. This stub captures the per-story
     shape just enough that /CJ_personal-workflow check passes (all 7
     standard sections required). -->

## Problem

F000030 needs a single, coherent implementation slice: create `doc/` at repo root, move existing `philosophy.md` → `doc/PHILOSOPHY.md` via `git mv` (preserves history; one shot on case-insensitive APFS because destination path differs), rewrite to current state, add NEW `doc/ARCHITECTURE.md` with five required sections, edit root `README.md` (+ `## Deeper reading`), and add a new section to root `CLAUDE.md` (`## /document-release workbench audit conventions` with literal jq commands). No upstream skill modification. See parent [F000030_DESIGN.md](../F000030_DESIGN.md) for the full problem framing (why the workbench needs a content-side close on the F000028+F000029 doc-sync loop).

## Shape of the solution

One PR with six touched files (1 moved + 1 fully rewritten at the new path + 1 new + 2 edited + 1 CHANGELOG):

| Concern | File | Change Type |
|---------|------|-------------|
| Move the explanation root | `philosophy.md` → `doc/PHILOSOPHY.md` | `git mv` (preserves history) |
| Rewrite to current state | `doc/PHILOSOPHY.md` | Full rewrite (drop retired-skill refs except in `## Retired skills`; replace `/CJ_goal_auto`/`/CJ_goal_run` with `/cj_goal_feature`/`/cj_goal_defect`; add `## Decision tree`) |
| Mechanism reference | `doc/ARCHITECTURE.md` | New — five required sections |
| Discoverability | `README.md` | Modified — add `## Deeper reading` section |
| Project-instructions-teach-upstream-skill | `CLAUDE.md` | Modified — add `## /document-release workbench audit conventions` section with literal jq commands |
| Release note | `CHANGELOG.md` | Modified — F000030 entry (Unreleased section) |

The five `doc/ARCHITECTURE.md` sections are content-gated, not word-count-gated: each must answer its specific questions (see SPEC #4-#8). The CLAUDE.md convention contains both literal jq commands AND the annotation suppression rules (mentions inside `## Retired skills` OR inside `~~strikethrough~~` OR within 200 chars of `DEPRECATED`/`sunset`/`tombstone` are skipped). See parent F000030_DESIGN.md and the upstream `~/.gstack/projects/.../chjiang-cj-feat-20260531-123255-4461-design-20260531-124744.md` for the load-bearing decisions (drop-vs-tombstone rule; no manifest layer; CLAUDE.md mechanism duplication accepted for v1).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single PR for all six file changes; no per-file split. | The six are mutually load-bearing — `doc/` folder with stale philosophy is incomplete; CLAUDE.md convention with no `doc/PHILOSOPHY.md` to audit is dead config; README link to non-existent doc is broken. Splitting adds review overhead with zero independent value. Same logic as F000029's "single PR for 7 file changes" decision (S000062 #1). |
| 2 | `git mv` in one shot (not two-step rename) | Source `./philosophy.md` and destination `./doc/PHILOSOPHY.md` differ in directory component; case-insensitive APFS handles this in a single `git mv` invocation. Verified at design time (parent F000030_DESIGN.md risks-and-questions). Two-step fallback (`philosophy.md.tmp`) is documented but not the default. |
| 3 | Drop-vs-tombstone rule for retired skill names | Single `## Retired skills` subsection at end of PHILOSOPHY holds one paragraph each for `/workflow`, `/contracts`, `/docs`, `/CJ_goal_auto`, `/CJ_goal_run`. All OTHER mentions throughout PHILOSOPHY/ARCHITECTURE are dropped. Annotation suppression rule in CLAUDE.md convention is the symmetric escape hatch. |
| 4 | ARCHITECTURE sections are content-gated, not word-count-gated | Each ARCHITECTURE section has a list of questions it must answer (e.g., S000057 section must name phases + modes + consumers). QA validates against content presence (grep for specific entity names), not paragraph count. Better signal than a 200-word floor. |
| 5 | Literal jq commands in CLAUDE.md convention, not pseudocode | Operator (or `/document-release`) can copy-paste and run; reduces ambiguity at audit time. Same shape as the existing CI/CD merge convention section's literal `gh pr merge <PR#> --squash --delete-branch` snippet. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Rewrite of `doc/PHILOSOPHY.md` could accidentally drop a load-bearing section while editing for current state. | AC checks: explicit list of sections that MUST be preserved (design-principles 1-5, "What this intentionally does NOT optimize for", "Key patterns and conventions", "How to extend without breaking its character", "Dependencies and assumptions", "Failure modes and maintenance risks"). Implementation checklist forces a section-by-section pass before commit. |
| `## Decision tree` heading anchor in PHILOSOPHY must match what the new-skills audit grep looks for. | CLAUDE.md convention spec EXACTLY says `doc/PHILOSOPHY.md ## Decision tree` as the grep target; implementer must use that exact heading text. |
| `doc/ARCHITECTURE.md` could end up too thin (just headings + one-sentence summaries) and miss the content gates. | Per-section content checklist in SPEC (S #4-#8) lists the named entities each section must mention. QA greps for those entities; missing → fail. |
| `git mv` could fail unexpectedly on case-insensitive APFS for unforeseen reasons. | Fallback documented: `git mv philosophy.md philosophy.md.tmp; git mv philosophy.md.tmp doc/PHILOSOPHY.md`. Implementer first tries the one-shot path; falls back only on actual failure. |
| `/document-release` may not actually read CLAUDE.md project context during its run. | Out of scope here (post-merge smoke test #1 verifies). If broken, escalate as a TODOS follow-up — does not invalidate the structural shipment. |

## Definition of done

- [ ] All 17 Acceptance Criteria from [S000063_TRACKER.md](S000063_TRACKER.md) checked off.
- [ ] All 11 P0 requirements from [S000063_SPEC.md](S000063_SPEC.md) implemented.
- [ ] All smoke rows from [S000063_TEST-SPEC.md](S000063_TEST-SPEC.md) pass; all E2E rows verified by operator (or marked `post-ship` deferred where structurally appropriate).
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` both green.

## Not in scope

- Edits to `~/.claude/skills/document-release/SKILL.md` (upstream gstack skill).
- Fix for `/document-release` Step 1 base-branch abort (separate F000029 contract gap; TODOS follow-up).
- New manifest layer (no skills-manifest.yaml).
- CLAUDE.md mechanism prose extraction (Approach C — rejected at scope AUQ).
- Changes to F000028 hooks or F000029 marker-pickup AUQ.
- `doc/README.md` index file (YAGNI at 2 files in `doc/`; revisit at 4+).
- Edits to root-convention files beyond README.md and CLAUDE.md (CONTRIBUTING.md, TODOS.md, skills-catalog.json untouched).

## Pointers

- Parent tracker: [../F000030_TRACKER.md](../F000030_TRACKER.md)
- Parent design: [../F000030_DESIGN.md](../F000030_DESIGN.md)
- Parent roadmap: [../F000030_ROADMAP.md](../F000030_ROADMAP.md)
- Own SPEC: [S000063_SPEC.md](S000063_SPEC.md)
- Own TEST-SPEC: [S000063_TEST-SPEC.md](S000063_TEST-SPEC.md)
- Upstream design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260531-123255-4461-design-20260531-124744.md`
- Predecessor mechanism (hook): [../../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md](../../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md)
- Predecessor mechanism (AUQ): [../../F000029_marker_pickup_auq/F000029_TRACKER.md](../../F000029_marker_pickup_auq/F000029_TRACKER.md)
- Architectural precedent: CLAUDE.md `## CI/CD merge convention` section (project-instructions-teach-upstream-skill pattern)
