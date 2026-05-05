---
type: architecture
parent: S000013_relocate_with_catalog_driven_paths
feature: F000006_relocate_deprecated_skills
title: "Relocate with catalog-driven paths — Architecture"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
prd: S000013_PRD.md
reviewers: []
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context.
     If there are multiple related components (e.g., a main skill and its test harness),
     introduce all of them here so readers see the full picture upfront. -->

Move `skills/company-workflow/` and `templates/company-workflow/` to `deprecated/company-workflow/` (with `templates/` as a sub-directory under it). Update consumer scripts to derive paths from `skills-catalog.json` `files[]` and `templates[]` arrays instead of hardcoding `skills/{name}/`. The catalog becomes the single source of truth for where a skill's source files live; future relocations are a one-line catalog change instead of a multi-script refactor. The work-copilot byte-mirror invariant continues to hold — `validate.sh` Error check 10's `MIRROR_SPECS` array retargets all 7 source paths to `deprecated/company-workflow/...`; destination paths under `work-copilot/` are unchanged.

## Architecture

<!-- High-level system design. Which components are affected? How do they interact?
     Include an ASCII diagram for any non-trivial data flow. -->

```
                           ┌─────────────────────────┐
                           │   skills-catalog.json   │  ← single source of truth
                           │                         │
                           │   company-workflow {    │
                           │     status: deprecated  │
                           │     files: [            │
                           │       deprecated/...    │  ← updated paths
                           │     ]                   │
                           │     templates: [...]    │  ← updated paths
                           │   }                     │
                           └────────────┬────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
              ▼                         ▼                         ▼
   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
   │ scripts/           │   │ scripts/           │   │ scripts/           │
   │ skills-deploy      │   │ validate.sh        │   │ generate-readme.sh │
   │ (refactored)       │   │ (refactored)       │   │ (catalog-driven    │
   │                    │   │                    │   │  already, no edit) │
   │ - line 260: path   │   │ - line 30: catalog │   │                    │
   │   from files[]     │   │   walker uses path │   │                    │
   │ - line 278: source │   │   from files[]     │   │                    │
   │   root from files[0]│   │ - line 71: orphan │   │                    │
   │   parent           │   │   check walks both │   │                    │
   │                    │   │   skills/ AND      │   │                    │
   │                    │   │   deprecated/      │   │                    │
   │                    │   │ - 205-211: MIRROR  │   │                    │
   │                    │   │   _SPECS retarget  │   │                    │
   └────────────────────┘   └────────────────────┘   └────────────────────┘

           Filesystem (post-move):
           ─────────────────────────────────────────
           skills/
           ├── personal-workflow/   (active)
           └── system-health/       (active)

           templates/
           ├── personal-workflow/
           └── doc-SKILL-DESIGN.md

           deprecated/
           ├── README.md
           └── company-workflow/
               ├── SKILL.md
               ├── WORKFLOW.md
               ├── bin/, philosophy/, examples/, fixtures/, reference/
               ├── company-artifact-manifests.json
               └── templates/   (14 files; mirror source for work-copilot/templates/)

           work-copilot/   (unchanged destinations)
           ├── templates/         ← mirror of deprecated/company-workflow/templates/
           ├── WORKFLOW.md        ← mirror of deprecated/company-workflow/WORKFLOW.md
           ├── reference/         ← mirror of deprecated/company-workflow/reference/
           ├── philosophy/        ← mirror of deprecated/company-workflow/philosophy/
           ├── examples/          ← mirror of deprecated/company-workflow/examples/
           ├── fixtures/          ← mirror of deprecated/company-workflow/fixtures/
           └── copilot-artifact-manifests.json  ← mirror (manifest shape) of company-artifact-manifests.json
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `skills/company-workflow/` | claude-skills-templates | Moved | 53 files relocated to `deprecated/company-workflow/` (preserving subdirs) |
| `templates/company-workflow/` | claude-skills-templates | Moved | 14 templates relocated to `deprecated/company-workflow/templates/` |
| `deprecated/` | claude-skills-templates | New | Top-level directory for deprecated skills (lifecycle-named) |
| `deprecated/README.md` | claude-skills-templates | New | 5-line note explaining purpose |
| `skills-catalog.json` | claude-skills-templates | Modified | `company-workflow` entry's `files[]` and `templates[]` paths updated |
| `scripts/skills-deploy` | claude-skills-templates | Modified | Lines 260, 278: paths derived from catalog `files[]` instead of hardcoded `skills/{name}/` |
| `scripts/validate.sh` | claude-skills-templates | Modified | Lines 30 (catalog walker), 71 (orphan check), 205-211 (MIRROR_SPECS), 387 (COMPANY_MANIFEST), 480 (fixtures find) |
| `scripts/test.sh` | claude-skills-templates | Modified | Introduce `COMPANY_PATH` / `COMPANY_TPL` constants near top; ~40 hardcoded refs replaced |
| `CLAUDE.md` | claude-skills-templates | Modified | Lines 57, 73, 75 (paths) + new line documenting `deprecated/` convention |
| `README.md` | claude-skills-templates | Regenerated | `scripts/generate-readme.sh` output reflects new paths |

### Data Flow

<!-- How does data move through the system for the primary use case?
     Step-by-step, component to component. -->

**Use case: clean-target install with `--include-deprecated`**

1. User runs `scripts/skills-deploy install --include-deprecated` with `SKILLS_DEPLOY_TARGET` set to a fresh directory.
2. `skills-deploy` reads `skills-catalog.json` and iterates entries.
3. For each entry, `skill_status` returns `active` or `deprecated`.
4. For `company-workflow` (status: deprecated), the include-deprecated flag passes the gate.
5. `skills-deploy` reads `files[]` from the catalog: `["deprecated/company-workflow/SKILL.md", "deprecated/company-workflow/WORKFLOW.md", "deprecated/company-workflow/company-artifact-manifests.json"]`.
6. Source root is derived as `dirname(files[0])` → `deprecated/company-workflow/` (relative to repo root).
7. `skills-deploy` symlinks/copies subdirectories of the source root into `~/.claude/skills/company-workflow/` (destination path unchanged from F000005 behavior).
8. Manifest entry written: `{ path: "deprecated/company-workflow/SKILL.md", installed_at: <ts> }` — path field reflects source location, not destination.
9. Templates loop reads `templates[]` from the catalog and resolves them to `deprecated/company-workflow/templates/...` via the resolver mechanism (Decision Q1 below).

**Use case: validate.sh Error check 10 (mirror invariant)**

1. `validate.sh` iterates `MIRROR_SPECS` entries.
2. For each entry, parses `src|dst|shape|orphan_policy`.
3. Source paths are now `deprecated/company-workflow/...`; destination paths under `work-copilot/...` are unchanged.
4. For each shape (single, flat, recursive, manifest), runs the appropriate `_mirror_check_*` helper.
5. `cmp -s` (or shape-specific equivalent) verifies byte-identity between source and destination.
6. Reports PASS / FAIL / WARN per spec's `orphan_policy`.
7. All 7 entries should report PASS post-move.

## API Changes

<!-- New or modified APIs, function signatures, message formats.
     Skip this section if no API changes. -->

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| `skills-deploy` source path resolution (line 278) | `local src="$SKILLS_SRC/$name"` (hardcoded `skills/`) | `local src="$REPO_ROOT/$(dirname "$(catalog_files_first $name)")"` (or via new helper) | Catalog drives paths; future relocations don't require script edits |
| `skills-deploy` manifest path field (line 260) | `--arg p "skills/$name/SKILL.md"` | `--arg p "$(catalog_files_first $name)"` | Manifest reflects actual source location |
| `validate.sh` catalog walker (line 30) | `fail "$name is in catalog but skills/$name/SKILL.md does not exist"` | Check existence of catalog's resolved SKILL.md path; fail with that path in the error message | Hardcoded `skills/$name/` no longer assumed |
| `validate.sh` orphan check (line 71) | Walks `skills/` only | Walks `skills/` AND `deprecated/`; orphan rule symmetric | Catches orphans in both locations |
| `validate.sh` MIRROR_SPECS source paths (lines 205-211) | `skills/company-workflow/...` | `deprecated/company-workflow/...` (templates entry: `deprecated/company-workflow/templates`) | Source moved; mirror retargets |

### New APIs (helpers, optional — see Decision Q2)

| API | Signature | Description |
|-----|-----------|-------------|
| `catalog_files_first` (bash function) | `catalog_files_first NAME → path` | Returns the first entry of catalog `files[]` for a given skill name. Used by both skills-deploy and validate.sh to avoid re-implementing the jq query. |
| `catalog_source_root` (bash function) | `catalog_source_root NAME → path` | Returns `dirname(files[0])` — the source root directory. Convenience wrapper. |

## Dependencies

<!-- Technical dependencies: libraries, frameworks, other features, build requirements.
     This is the single place for all dependency tracking. -->

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| `jq` (already required by skills-deploy) | Tool | Available | Used for catalog queries; no version bump needed |
| F000005 (deprecated skill status) | Feature | Shipped (v1.2.0) | Provides the `status: deprecated` lifecycle this feature builds on |
| F000004 (work-copilot bundle) | Feature | Shipped | Provides the byte-mirror invariant (validate.sh Error check 10) that constrains source-path retarget |

## Risk Assessment

<!-- What could go wrong? What are the unknowns? -->

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| MIRROR_SPECS retarget has a typo → byte-identity verification fails on a single entry | Med | High (CI red, mirror invariant broken) | T000014's first verification step is `./scripts/validate.sh` Error check 10; any failure surfaces immediately |
| `skills-catalog.json` `templates[]` entries turn out to be filesystem-relative under `templates/` AND the resolver hardcodes `templates/{key}` → resolver also needs an update | Med | Med (additional script edit) | ARCHITECTURE Q1 below; trace skills-deploy templates-resolution from line ~278 onward during implementation. If resolver hardcodes `templates/`, either change to read a `templates_source` field on the catalog entry OR change entries to be filesystem-relative paths. |
| `skills-deploy` source-root derivation from `files[0]` fails because `files[0]` is not always SKILL.md | Low | Med | Convention check during ARCHITECTURE: scan all 4 catalog entries' `files[]` arrays. If SKILL.md is always first, derive from `dirname(files[0])`. If not, introduce a `source_dir` catalog field instead. |
| `git mv` loses blame history | Low | Low | Verify with `git log --follow` on a moved file post-commit. If lost, fall back to a separate "move-only" commit followed by edits. |
| Pre-existing `~/.claude/skills/company-workflow/` install on user's machine becomes inconsistent with new manifest path | Low | Low | T000014 idempotency case: install once with `--include-deprecated`; run again; verify no-op. Manifest path may be stale post-upgrade but no functional break. |
| Test fixture path references in test.sh slip through the COMPANY_PATH replacement (e.g., a hardcoded path inside a heredoc) | Med | Med | After global replace, run `grep -n "skills/company-workflow\|templates/company-workflow" scripts/test.sh` and expect 0 matches. Manual scan for any remaining string. |

## Design Decisions

<!-- Choices made and alternatives rejected. Future readers need to know why. -->

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| New top-level dir name | `deprecated/` | `bundle-sources/`, `_upstream/`, `skills/_deprecated/` | Names the lifecycle state; scales naturally if more skills get deprecated; stays out of `skills/`. `bundle-sources/` named the function but reads against the lifecycle. `_upstream/` is hidden-dotfile-adjacent. `skills/_deprecated/` doesn't solve the stated complaint. |
| Templates location | `deprecated/company-workflow/templates/` (with the skill) | Leave at `templates/company-workflow/` (split source) | Whole concept lives in one self-contained directory. `templates/` top-level stays clean. Mirror destination paths under `work-copilot/templates/` are unchanged — only the source path retargets. |
| Path resolution refactor scope | All consumers (skills-deploy line 260 + 278, validate.sh line 30 + 71) derive from catalog | Special-case "if status==deprecated, look in deprecated/" branch | Catalog already has the data. Special-casing trades short-term diff for long-term debt. Catalog-driven works for any future move. |
| Source-root derivation | `dirname(files[0])` (convention: SKILL.md is always files[0]) | New `source_dir` catalog field (explicit) | `files[0]` already encodes the source root. A `source_dir` field would duplicate information. Convention is documented in CLAUDE.md as part of the feature. |
| `test.sh` cleanup | Introduce `COMPANY_PATH` / `COMPANY_TPL` constants; replace ~40 refs | Leave hardcoded; just update the strings | One-time pain to add constants makes the next move trivial and reduces visual noise in the test file. Same principle as the script refactor. |
| `validate.sh` orphan check scope | Walk both `skills/` and `deprecated/` | Walk only `skills/` (active skills) | Catches orphan entries in `deprecated/` too — e.g., a stale dir without a corresponding catalog entry. Symmetric and cheap. |

### Open question Q1: templates[] catalog field shape

`skills-catalog.json` company-workflow `templates[]` entries are shaped like `"company-workflow/tracker-feature.md"`. Two interpretations:

**Interpretation A: filesystem-relative path under `templates/`.** Resolver does `"templates/" + entry`. Post-move, entries become `"deprecated/company-workflow/templates/tracker-feature.md"` (with explicit prefix) and resolver concatenates `"" + entry` (no prefix), OR entries stay `"company-workflow/tracker-feature.md"` and resolver looks up the template source root from a catalog field.

**Interpretation B: catalog key relative to the skill's templates directory.** Resolver does `"templates_source_root_for_this_skill/" + entry`. Post-move, entries stay `"company-workflow/tracker-feature.md"` (unchanged) and the resolver reads a `templates_source` field on the catalog entry pointing at `deprecated/company-workflow/templates/`.

**Resolution path:** Read `scripts/skills-deploy` lines 290-340 (the templates loop) during implementation. If the resolver hardcodes `templates/`, refactor it to read from `templates_source` (Interpretation B with new field) OR change entries to be fully filesystem-relative (Interpretation A with explicit prefix). Pick whichever is the smaller diff with the same principled outcome.

### Open question Q2: should helpers `catalog_files_first` and `catalog_source_root` exist?

Two options:

**A. Inline jq queries.** Each call site has its own `jq -r --arg n "$name" '...'` invocation. Simpler, no new abstraction.

**B. Bash functions in skills-deploy or a shared helper.** Two call sites in skills-deploy + two in validate.sh = 4 query duplications. A helper de-duplicates.

**Resolution path:** Default to A (no new helper) for this PR; if the duplication grows beyond 4 sites in a future PR, factor out then. Avoid premature abstraction.
