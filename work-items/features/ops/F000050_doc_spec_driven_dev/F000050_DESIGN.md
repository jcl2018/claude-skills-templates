---
type: design
parent: F000050
title: "doc-spec.md doc-driven development + retire repo-init/json/CJ-DOC-RELEASE.md — Feature Design"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

Today the "what docs does this repo carry, and what does each mean" contract is
**scattered and workbench-coupled**: a YAML manifest buried in `CLAUDE.md`
(`### Tracked doc/ files manifest` + `### Tracked root docs allowlist`), a JSON
sidecar (`cj-document-release.json`), a prose contract (`CJ-DOC-RELEASE.md`), and a
bootstrap skill (`/CJ_repo-init`). The human-facing docs (`doc/PHILOSOPHY.md`,
`doc/ARCHITECTURE.md`, `doc/WORKFLOWS.md`) are saturated with internal work-item IDs
(41 total: 21 in ARCHITECTURE, 18 in WORKFLOWS, 2 in PHILOSOPHY) — the opposite of
human-readable — and they sit under `doc/` (capital filenames) not the intended
`docs/`.

The result: no single human-readable answer to "what are this repo's docs," and the
machinery can't travel to another repo without that repo replicating the workbench's
`CLAUDE.md` structure. We want one portable file (`doc-spec.md`) that any repo can
adopt, and `/CJ_document-release` to enforce + self-heal it.

## Shape of the solution

Introduce a single root **`doc-spec.md`** — a human-readable Markdown file with
three parts: a portable **Common** section (byte-identical across adopting repos,
seeded from a template), a **Custom** section (this repo only), and a single fenced
```yaml **machine registry** that `validate.sh` and `/CJ_document-release` parse (no
table/YAML duplication; the YAML is the source, the prose explains it). `/CJ_document-release`
becomes the enforcement + self-heal engine: read `doc-spec.md` (self-bootstrap it
from the Common seed if missing), stub-scaffold any missing declared doc, audit each
declared doc against its `requirement` (plus a no-work-item-ref check for `human-doc`
entries), and derive the doc-only auto-commit whitelist from the registry. The `doc/`
trio is migrated to `docs/` (lowercase, `workflow.md` singular) with all 41 work-item
refs scrubbed; `README.md` is brought to spec; `validate.sh` checks 15/15a/15b/16/17
re-point to the new surfaces and a NEW Check 19 enforces no-work-item-refs on every
`human-doc`. Three surfaces are retired: `/CJ_repo-init`, `cj-document-release.json`,
and `CJ-DOC-RELEASE.md`.

This feature is **one cohesive change** (the user wants the complete vision in one
PR), so it decomposes into a single implementable user-story that carries the full
SPEC + TEST-SPEC for the 12-step sequence.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The full 12-step migration: author doc-spec.md; git mv doc/→docs/; scrub refs + ASCII charts; README to spec; validate.sh 15/15a/15b/16/17 + new 19; rewrite /CJ_document-release + helper; delete cj-document-release.json; retire /CJ_repo-init; absorb+remove CJ-DOC-RELEASE.md; update CLAUDE.md; portable Common seed | S000090 | [S000090_doc_spec_driven_dev/S000090_TRACKER.md](S000090_doc_spec_driven_dev/S000090_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | v1 scope = **Full migration** in one PR (rename `doc/`→`docs/`, scrub all 41 work-item refs, ASCII charts, README to spec, fold the two `CLAUDE.md` manifests into `doc-spec.md`, add a no-work-item-ref lint) | User wants the complete vision in one PR; rejected Convention-only / Conv+front-docs (smaller v1 that defers the scrub + retirements). |
| 2 | Doc registry = **Consolidate** into a single `doc-spec.md` (human + machine source of truth) | It is the portability unlock for other repos; rejected three-registries-side-by-side (doc-spec.md alongside the CLAUDE.md manifest + json) — drift surface + blocks portability. |
| 3 | Create-on-the-fly = **Scaffold stub** (title + section skeleton its `audit_class`/role implies + `<!-- TODO: fill in -->`), never auto-generated prose | Slop risk in an autonomous build; rejected auto-generate full doc content. |
| 4 | `/CJ_repo-init` = **Retire** via the paired-layer deprecation convention; non-doc duties become lazy-create in consuming skills | Redundant under doc-spec.md self-bootstrap; `work-items/` lazy-created by `/CJ_scaffold-work-item`, `TODOS.md` lazy-created (empty) by the skills that read it. Full new-repo non-doc bootstrap is a noted follow-up. |
| 5 | The doc-only auto-commit whitelist is **DERIVED** from the registry (every declared `path` + `doc-spec.md` itself + `docs/**/*.md`) | Nothing hand-maintains a second whitelist after `cj-document-release.json` is retired. |
| 6 | NEW Check 19 (no-work-item-refs) is **hard** (ERROR), not advisory | The user's "no F-0000 in human docs" requirement; the migration scrubs the docs first so it lands green. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Large blast radius in one autonomous build (touches CI-gating `validate.sh`/`test.sh`, the doc-release engine, three retirements, a multi-file doc rewrite → big PR) | Mitigated by strict implementation ordering, the `test.sh` fixture pre-flight, and the human PR review as the architecture gate. If the build can't finish in one pass, the resume state continues it. |
| The `test.sh` `zzz-test-scaffold` fixture parallel-edit is a known, repeatedly-forgotten blind spot (missed on F000032/F000034/F000035) | Pre-flighted: every validate.sh check change in step 5 gets a lockstep fixture edit; called out as its own TEST-SPEC row (S2). |
| Non-doc prerequisite bootstrap (`TODOS.md`, `work-items/`) after repo-init is retired | Handled by lazy-create in the consuming skills for v1; a fuller new-repo bootstrap path is a follow-up. |
| Cross-repo portability is designed-in + seeded but validated only in the workbench for v1 | Portfolio-repo rollout is a separate follow-up (matches the workbench-first convention). |
| `docs/` vs `doc/` rename on case-insensitive macOS | Use `git mv` carefully so the rename is tracked. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] Root `doc-spec.md` exists with Common + Custom + a fenced ```yaml registry (schema_version 1; docs[] entries with path/section/audit_class/purpose/requirement; audit_class ∈ {human-doc, operational}).
- [ ] `doc/` trio renamed to `docs/` (lowercase, `workflow.md` singular) via tracked `git mv`; all 41 work-item refs scrubbed; ASCII charts present.
- [ ] `README.md` to spec (folder-structure + getting-started, no work-item refs).
- [ ] `validate.sh` Checks 15/15a/15b/16/17 re-pointed + NEW Check 19 added; `validate.sh` green end-to-end.
- [ ] `scripts/test.sh` green with its `zzz-test-scaffold` fixture updated in lockstep with every validate.sh check change.
- [ ] `/CJ_document-release` + helper read doc-spec.md / self-bootstrap / stub-scaffold / no-ref audit / derived whitelist.
- [ ] `cj-document-release.json`, `CJ-DOC-RELEASE.md`, `/CJ_repo-init` retired with no dangling references (grep-clean).
- [ ] `CLAUDE.md` updated (manifests removed, prose fixed, scripts table + routing) and a portable Common seed ships.

## Not in scope

<!-- Explicit non-goals. -->

- Cross-repo dogfooding (e.g. the portfolio repo actually adopting `doc-spec.md`) — designed-in + seeded in v1, but validated only in the workbench; portfolio rollout is a separate follow-up.
- A full new-repo non-doc bootstrap path (replacing all of `/CJ_repo-init`'s non-doc duties beyond lazy-create) — noted follow-up; v1 relies on lazy-create in consuming skills.
- Auto-generating full doc CONTENT — explicitly rejected (slop risk); missing docs become stubs only.
- Per-verb whitelist overrides, multi-repo federation, audit_class extensions beyond {human-doc, operational} — deferred to future schema bumps.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000050_TRACKER.md](F000050_TRACKER.md)
- Roadmap: [F000050_ROADMAP.md](F000050_ROADMAP.md)
- Child story: [S000090_doc_spec_driven_dev/S000090_TRACKER.md](S000090_doc_spec_driven_dev/S000090_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/doc-spec-driven-dev-design-20260606.md`
