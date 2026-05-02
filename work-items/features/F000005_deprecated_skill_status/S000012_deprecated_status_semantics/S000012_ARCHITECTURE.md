---
type: architecture
parent: S000012_deprecated_status_semantics
feature: F000005_deprecated_skill_status
title: "Deprecated Status Semantics — Architecture"
version: 1
status: Draft
date: 2026-05-02
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

This story extends three existing scripts to recognize `status: deprecated` in `skills-catalog.json`. No new scripts, no new directories, no schema migration — the field already exists. The change is purely behavioral: `skills-deploy install` filters by status; `skills-deploy doctor` labels by status; `validate.sh` enforces a closed enum on status; `generate-readme.sh` renders deprecated entries in a separate section.

The catalog (`skills-catalog.json`) is the single source of truth for `status`. Three consumers already read it; this story teaches them all to branch consistently on the new value. No SKILL.md frontmatter changes — that would create a second source.

## Architecture

```
                +------------------------+
                |  skills-catalog.json   |   (status: active|experimental|deprecated)
                +------------------------+
                          |
        +-----------------+----------------+----------------+
        |                 |                |                |
        v                 v                v                v
+-----------------+ +------------+ +-----------------+ +------------------+
| skills-deploy   | | validate.  | | generate-       | | downstream:      |
| install/doctor/ | | sh         | | readme.sh       | | (readers, e.g.   |
| remove          | | (enum gate)| | (display)       | |  CI / docs)      |
+-----------------+ +------------+ +-----------------+ +------------------+

install path (after change):
  read catalog
  for each entry:
    if status == "deprecated" AND --include-deprecated NOT set:
       emit WARN line, skip
    else:
       run existing install steps
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `skills-catalog.json` | claude-skills-templates | Modified (in T000013) | Flip company-workflow `status: active` → `deprecated`. Schema unchanged — only a value change. |
| `scripts/skills-deploy` | claude-skills-templates | Modified | (a) Add `--include-deprecated` flag parsing; (b) install: filter deprecated unless flag set, emit WARN; (c) doctor: label deprecated entries as INFO (not WARN) regardless of installed state; (d) remove: no change (deprecated state is irrelevant for removal) |
| `scripts/validate.sh` | claude-skills-templates | Modified | Extend the status enum check to `{active, experimental, deprecated}`. If no enum check exists today, add one. |
| `scripts/generate-readme.sh` | claude-skills-templates | Modified | Split rendering into two `jq` passes: active skills under the existing table; deprecated skills under a new "Deprecated" section. |
| `README.md` | claude-skills-templates | Regenerated | Output of the updated `generate-readme.sh`. Diff baselined in the same PR. |
| `CLAUDE.md` | claude-skills-templates | Optional | If the file documents catalog conventions, add a short note that `status: deprecated` is now honored by install. (To be checked during Implement.) |

### Data Flow

Primary use case: `scripts/skills-deploy install` on a fresh machine.

1. User invokes `scripts/skills-deploy install` (no flag).
2. The script parses argv → `INCLUDE_DEPRECATED=false`.
3. The script reads `skills-catalog.json` via `jq`.
4. For each entry, it checks `status`:
   - `active` or `experimental` → proceed with existing install logic (copy files to `~/.claude/skills/<name>/`, copy templates, update manifest)
   - `deprecated` and `INCLUDE_DEPRECATED=false` → emit `WARN: skipping deprecated skill: <name> (use --include-deprecated to install)` and skip
   - `deprecated` and `INCLUDE_DEPRECATED=true` → proceed with existing install logic, no warning
5. Summary line at the end of the run reports installed/skipped counts.

Doctor flow:

1. User invokes `scripts/skills-deploy doctor`.
2. The script reads `skills-catalog.json` and walks `~/.claude/skills/`.
3. For each catalog entry:
   - If `status == "deprecated"`:
     - If installed → `INFO: deprecated — installed (--include-deprecated)`
     - If not installed → `INFO: deprecated — not installed by default`
   - Otherwise → existing logic (WARN if drift, INFO if clean, etc.)
4. Doctor exit code unchanged — INFO doesn't fail.

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `skills-deploy install --include-deprecated` | flag, no value | When set, install loop does not filter `status: deprecated`. No effect on `experimental` or `active`. |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| `skills-deploy install` | Installs every catalog entry | Skips entries with `status: deprecated` unless `--include-deprecated` is passed | Core feature behavior |
| `skills-deploy doctor` | (Current behavior to be confirmed during Implement) | Reports deprecated entries as INFO regardless of installed state | Avoid alert fatigue |
| `validate.sh` (status enum) | (Current check to be confirmed during Implement) | Closed enum: `{active, experimental, deprecated}` | Catch typos like `depricated` |
| `generate-readme.sh` | Single-pass `jq` rendering of all entries | Two-pass rendering: active table, then "Deprecated" section | Honest visibility |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| `jq` | Tool | Available | Already required by `generate-readme.sh` and `skills-deploy` |
| `bash` 3.2+ | Tool | Available | Repo's existing portability target (Mac default) |
| `skills-catalog.json` | Code | Available | Already exists; this story reads + writes (in T000013) |
| F000004 (work-copilot) | Feature | Shipped (v0.14.0) | Motivates the deprecation; the byte-mirror constraint is why we deprecate rather than delete |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing flag parser doesn't accommodate a new boolean flag cleanly | Med | Low | Read `skills-deploy` first; if `getopts`, just add a new case; if ad-hoc `case`, mirror the existing pattern |
| `jq` rendering of two sections introduces unrelated whitespace churn in README | Low | Low | Run `generate-readme.sh` once on `main`-state to baseline; commit the regenerated README in the same PR as the code change |
| Doctor's current output format is inconsistent (INFO vs WARN labeling not standardized) | Low | Med | Read doctor's current logic during Implement; if no INFO/WARN convention exists, introduce one and document it in the PR |
| `validate.sh` Error check 10 (work-copilot mirror) reads `skills-catalog.json` somehow and assumes active | Low | Med | Re-read Error check 10 during Implement to confirm it ignores `status`; verified: it operates on filesystem mirror checks, not catalog status |
| Backward compatibility: a user with an existing `~/.claude/skills/company-workflow/` (installed before this feature) runs the new install — they should see no destructive change | Med | Low | T000013 test-plan includes this case; install is idempotent and only adds, never removes |
| README diff in the PR is large enough to obscure the code review | Med | Low | Note in the PR body that the README change is mechanical (regeneration); reviewer can ignore it and trust the script change |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Filter happens in `skills-deploy install` | Yes | Filter in `skills-catalog.json` itself (e.g., a separate `deprecated-catalog.json`) | One catalog file is simpler; status field is the right place |
| Flag name | `--include-deprecated` | `--all`, `--no-skip-deprecated`, `--legacy` | Most explicit and least ambiguous; reads as English |
| Default behavior | Warn and skip | Silent skip / Warn and install / Hard error | Warn-but-skip surfaces the deprecation without blocking; explicit opt-in matches the user's stated preference |
| Doctor labeling | INFO for deprecated | WARN, hide, or "STALE" | Deprecated-and-not-installed is the *expected* state; warning would be alarmist |
| Validator enum | Closed `{active, experimental, deprecated}` | Open string / non-validation | Catches typos (`depricated` won't silently be treated as not-deprecated) |
| README rendering | Separate "Deprecated" section, not hidden | Hidden with footnote / Interleaved with badge | Calmest UX: deprecated skills are findable but visually distinct; honest about migration story |
| One catalog signal | Catalog `status` field is canonical | Also annotate SKILL.md frontmatter | Two signals will drift; pick one |
| Story decomposition | Single user-story (S000012) + 1 task (T000013) | Two stories: schema vs tooling | All edits land in 3 closely-related files in one PR; two stories would create artificial seams |
