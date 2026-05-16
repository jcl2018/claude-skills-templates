---
name: "Invert mirror and collapse validator"
type: user-story
id: "S000052"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000023"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "worktree-rosy-tinkering-pearl"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/invert_mirror_and_collapse_validator` (or use parent's branch if shipping in same PR)
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
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
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

- [x] Byte-identity verified between `deprecated/CJ_company-workflow/` MIRROR_SPECS sources and their `work-copilot/` copies (final `./scripts/validate.sh` pass before the cut — confirmed PASS on origin/main HEAD before rewrite).
- [x] `scripts/validate.sh` Error check 10 (MIRROR_SPECS array + loop + shape handlers `flat`/`recursive`/`single`/`manifest`) deleted.
- [x] `scripts/validate.sh` Error check 10 (collapsed from former 10b: `EXPECTED_BUNDLE_FILES`) expanded to cover the 7 previously-mirrored paths (templates/, WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, copilot-artifact-manifests.json) plus all existing bundle-only files (F000015 prompts, domain templates).
- [x] `./scripts/validate.sh` PASSes after the rewrite (single existence-only check, no shape handlers). Confirmed: validate.sh 684 → 545 lines.
- [x] All F000015 bundle-only files (`work-copilot/prompts/*.prompt.md`, `work-copilot/domain/*.template.md`) remain covered by the expanded check.
- [x] No runtime behavior changes for `scripts/copilot-deploy.py` — the bundle continues to deploy from `work-copilot/` as-is.

## Todos

<!-- Actionable items for this story. -->

- [x] Enumerate all 7 MIRROR_SPECS entries in `scripts/validate.sh` (lines ~255–446) and their leaf files.
- [x] Run `./scripts/validate.sh` before any edit to confirm byte-identity baseline (final pre-cut check).
- [x] Pick `EXPECTED_BUNDLE_FILES` shape — chose flat extension (61 entries with comment groupings) over a directory-shape enumerator. Readable; no new abstraction needed; explicit-over-clever (Principle 5).
- [x] Delete Error check 10 (MIRROR_SPECS array + loop + shape dispatch `flat`/`recursive`/`single`/`manifest` + orphan-policy handlers).
- [x] Extend `EXPECTED_BUNDLE_FILES` array to cover the 7 previously-mirrored paths (renumbered former check 10b → 10 since old 10 is gone).
- [x] Adjust validate.sh error-check numbering and section headers (10b collapsed into 10).
- [x] Run `./scripts/validate.sh` after the rewrite — PASS confirmed.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. Structural change story for F000023 — re-home byte-identity source-of-truth to `work-copilot/` and collapse `validate.sh` Error check 10 into 10b.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/validate.sh` (Error check 10 deleted; Error check 10b expanded)

## Insights

<!-- Non-obvious findings worth remembering. -->

- This story is the critical-path landing for F000023. Once `validate.sh` Error check 10 is gone, the byte-identity enforcement that has been keeping `deprecated/CJ_company-workflow/` alive as a mirror source is removed; `deprecated/CJ_company-workflow/` is officially orphaned (still on disk, but nothing depends on it). S000053's deletes become safe to land in any order after this.
- `EXPECTED_BUNDLE_FILES` shape choice (flat vs enumerator) is low-stakes — both are valid and have no downstream consequences beyond `validate.sh` readability. Implementer's call at write time.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: Scope of S000052 — only the validate.sh structural rewrite + byte-identity verification. All cleanup (`deprecated/CJ_company-workflow/` delete, catalog entry, test.sh blocks, docs, template-registry.json) lives in S000053. Rationale: S000052's diff stays small and reviewable; its landing is the gate that orphans the deprecated dir; S000053 can then split further if churn helps.
- [renumber] 2026-05-15: Renumbered S000049 → S000052 mid-pipeline. PR #129 (CJ_suggest filter) shipped to origin/main with S000049 while this work was being planned; PR #131 also took S000050+S000051. Next free S-number was S000052. /CJ_goal_run D4 recovery option A: rename dirs + files + content refs across F000023 tree and design doc, redo child branch off latest origin/main (v4.5.1).
- [impl] 2026-05-15: Rewrote `scripts/validate.sh` Error check 10. Deleted: MIRROR_SPECS array (7 entries), `_mirror_orphan()`, `_mirror_check_single/flat/recursive/manifest()` helpers (~190 lines), per-spec dispatch loop. Added: 51 file paths to `EXPECTED_BUNDLE_FILES` (17 templates + 1 WORKFLOW.md + 7 reference + 3 philosophy + 14 examples + 8 fixtures + 1 manifest), grouped with section comments. Total: 684 → 545 lines (139-line net reduction). Old check 10b renamed to check 10 (former check 10 is gone). `./scripts/validate.sh` PASS post-rewrite (zero errors, zero warnings).
- [finding] 2026-05-15: Error check 11 (manifest reconciliation) still references `$COMPANY_MANIFEST` at `deprecated/CJ_company-workflow/company-artifact-manifests.json`. That reference remains valid during S000052 (the dir still exists); S000053 must update this when the dir is deleted.
