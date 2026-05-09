---
type: design
parent: S000021
feature: F000012
title: "Per-type implement/qa pipeline branching — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story under F000012; full design context in parent.
     This stub captures story-scope decisions; structural sections preserved
     per personal-workflow check Step 16 enforcement. -->

## Problem

`/implement-from-spec` and `/qa-work-item` are F000010 pipeline skills that explicitly hard-fail on non-user-story work-items. The hard-fail is in `skills/implement-from-spec/SKILL.md:130` ("Error: /implement-from-spec operates on user-story dirs only; got {type}") and the equivalent in `qa-work-item`. `/scaffold-work-item` (the third pipeline skill) accepts all 4 types — so the pipeline is asymmetric: scaffold accepts all, implement/qa reject most.

This story removes the asymmetry. Both skills branch on the `type:` field in `_TRACKER.md` frontmatter and read type-appropriate input artifacts per `personal-artifact-manifests.json`.

## Shape of the solution

Same shape in both skills:

1. **Type detection** — read `type:` from the work-item's TRACKER frontmatter. If missing/malformed, error with a clear message.
2. **Input artifact resolution** — per-type lookup of which files to read as the SPEC equivalent:

| Type | `/implement-from-spec` reads | `/qa-work-item` reads |
|---|---|---|
| user-story (today) | `SPEC.md` + `DESIGN.md` | `TEST-SPEC.md` |
| defect (new) | `RCA.md` + `test-plan.md` | `test-plan.md` |
| task (new) | `task-spec` + `test-plan.md` | `test-plan.md` |
| feature (new) | AskUserQuestion to pick a child user-story (delegates to existing user-story path) | AskUserQuestion to pick a child user-story (delegates) |

3. **Boundary check + idempotency + AUQ** — unchanged. These all use `/personal-workflow check` and the manifest, which already understands all 4 types.
4. **Error tables** — remove "Wrong type" entries; replace with type-specific guidance (e.g., "frontmatter `type:` missing").

## Big decisions

- **Treat `test-plan.md` as de-facto SPEC for defect implement; RCA is context only.** Test-plan defines desired post-fix behavior; RCA explains "what went wrong + history pointer" the implementer reads to know what NOT to revert. (F000012_DESIGN big decision #3.)
- **Defect QA: no smoke/E2E split in v1.** All `test-plan.md` rows treated as smoke-equivalent; no E2E subagent dispatch for defects. (F000012_DESIGN big decision #4.)
- **Feature-level: AskUserQuestion to pick child, not auto-pick.** Preserves the existing path. (F000012_DESIGN big decision #5.)
- **No manifest changes.** `personal-artifact-manifests.json` already lists per-type artifacts; this story reads it, doesn't change it.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Each skill grows ~30%; new code paths (defect, task, feature-delegate) need their own tests | Implementation phase: extend test fixtures; one fixture per type (defect first since it's the dogfood path for S000022) |
| Task type ships but no real task work-items yet to verify | First task work-item flowing through pipeline post-merge is the verification |
| What if a future work-item type is added to the manifest but not to the per-type branch in implement/qa? | Resolved: per-type lookup table is the single read of the manifest. New types fail with "type X has no implement/qa path defined yet." |

## Definition of done

- [ ] `/implement-from-spec <defect-dir>` succeeds; existing user-story behavior unchanged.
- [ ] `/qa-work-item <defect-dir>` succeeds; existing user-story behavior unchanged.
- [ ] Type detection from `_TRACKER.md` frontmatter; explicit error on missing/malformed `type:` field.
- [ ] Error tables updated; "Wrong type" hard-fails removed.
- [ ] Test fixtures cover both new code paths (defect happy path; user-story regression).

## Not in scope

- Defect QA smoke/E2E split — accepted gap in v1; revisit if defect QA needs deeper coverage.
- Auto-pick child for feature-level invocation — v1 uses AskUserQuestion explicitly.
- New work-item types beyond the 4 in the manifest.
- Tasks-through-pipeline real-world dogfood — code path ships; verification waits for first task work-item.

## Pointers

- Parent feature design: [../F000012_DESIGN.md](../F000012_DESIGN.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-pipeline-parity-design-20260508-180219.md`
- Sibling story (rides through new defect path): [../S000022_traceability_comma_split/S000022_TRACKER.md](../S000022_traceability_comma_split/S000022_TRACKER.md)
- Files: `skills/implement-from-spec/`, `skills/qa-work-item/`, `skills/personal-workflow/personal-artifact-manifests.json` (read-only)
