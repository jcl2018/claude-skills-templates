---
type: design
parent: S000090
title: "doc-spec.md doc-driven development (12-step migration + 3 retirements) — Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- Story-level design. The cross-story shape lives on the parent feature
     (F000050_DESIGN.md); this story carries the implementable detail in its
     SPEC.md + TEST-SPEC.md. -->

## Problem

The workbench's "what docs does this repo carry + what does each mean" contract is
scattered across four surfaces (a YAML manifest in `CLAUDE.md`,
`cj-document-release.json`, `CJ-DOC-RELEASE.md`, and `/CJ_repo-init`) and is
workbench-coupled — it cannot travel to another repo. The human docs under `doc/`
are saturated with 41 internal work-item IDs and use capital filenames. This story
delivers the single cohesive change that fixes all of it: a portable root
`doc-spec.md`, a migrated human-readable `docs/`, an enforcement+self-heal
`/CJ_document-release`, and the retirement of the three redundant surfaces.

## Shape of the solution

Execute the design's **12-step sequence verbatim** (ordered to minimize mid-build CI
breakage): author `doc-spec.md` → `git mv doc/`→`docs/` → scrub refs + ASCII charts →
README to spec → `validate.sh` 15/15a/15b/16/17 + NEW Check 19 (with the lockstep
`test.sh` fixture edit) → rewrite `/CJ_document-release` + helper → delete
`cj-document-release.json` → retire `/CJ_repo-init` → absorb+remove
`CJ-DOC-RELEASE.md` → update `CLAUDE.md` → add the portable Common seed →
`validate.sh` + `test.sh` green + QA. The full requirement/architecture detail —
including the `doc-spec.md` artifact shape, the registry schema, the
`/CJ_document-release` new behavior, and the per-check `validate.sh` changes — is in
[S000090_SPEC.md](S000090_SPEC.md).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single atomic story for the whole 12-step sequence (no task children) | One cohesive, strictly-ordered migration with a single shipping unit; no parallel sub-units. |
| 2 | Strict step ordering: doc-spec.md + doc migration BEFORE the validate.sh check flips | New checks (esp. Check 19 no-ref) land green rather than red mid-build. |
| 3 | Couple the `test.sh` fixture edit to the same step as each validate.sh check change | Defuses the repeatedly-forgotten `zzz-test-scaffold` blind spot (F000032/34/35). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Large blast radius may not finish in one autonomous pass | Resume state continues it; human PR review is the architecture gate. |
| `docs/`/`doc/` rename on case-insensitive macOS | Use tracked `git mv`. |
| Helper shape (re-point existing config helper vs new `doc-spec.sh`) | Decided at implementation; SPEC leaves it open — either satisfies registry-parse + derived-whitelist. |

## Definition of done

- [ ] All 12 steps complete; `validate.sh` + `test.sh` green; the three retirements grep-clean; portable Common seed shipped. (Full per-AC list in SPEC `## Acceptance Criteria`.)

## Not in scope

- Cross-repo dogfooding (portfolio adoption), full new-repo non-doc bootstrap beyond lazy-create, auto-generated doc content, and any schema features beyond v1 — see parent F000050_DESIGN.md `## Not in scope`.

## Pointers

- Parent feature design: [../F000050_DESIGN.md](../F000050_DESIGN.md)
- Parent tracker: [../F000050_TRACKER.md](../F000050_TRACKER.md)
- This story's tracker: [S000090_TRACKER.md](S000090_TRACKER.md)
- Spec: [S000090_SPEC.md](S000090_SPEC.md)
- Test spec: [S000090_TEST-SPEC.md](S000090_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/doc-spec-driven-dev-design-20260606.md`
