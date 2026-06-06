---
name: "doc-spec.md doc-driven development + retire repo-init/json/CJ-DOC-RELEASE.md"
type: feature
id: "F000050"
status: active
created: "2026-06-06"
updated: "2026-06-06"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/pedantic-agnesi-68fa3f"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/doc_spec_driven_dev`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] A root `doc-spec.md` exists: portable **Common** section, repo **Custom** section, and a single fenced ```yaml machine registry (`schema_version: 1`; `docs[]` each with `path`/`section`/`audit_class`/`purpose`/`requirement`; `audit_class` enum = {human-doc, operational}).
- [ ] The `doc/` trio is renamed to `docs/` (lowercase) via tracked `git mv`: `doc/PHILOSOPHY.md`→`docs/philosophy.md`, `doc/ARCHITECTURE.md`→`docs/architecture.md`, `doc/WORKFLOWS.md`→`docs/workflow.md` (singular).
- [ ] All 41 work-item refs are scrubbed from the three `docs/` files (21 ARCHITECTURE, 18 WORKFLOWS, 2 PHILOSOPHY); ASCII charts present; human-facing.
- [ ] `README.md` is brought to spec: a folder-structure section + a getting-started section naming the major workflows; no work-item refs.
- [ ] `scripts/validate.sh` Checks 15/15a/15b/16/17 re-pointed to `doc-spec.md` + `docs/`; NEW Check 19 (no-work-item-ref lint on every `human-doc`) added; all green end-to-end.
- [ ] `scripts/test.sh`'s `zzz-test-scaffold` integration fixture is updated in lockstep with EVERY validate.sh check change (the known, repeatedly-forgotten blind spot — explicit AC).
- [ ] `/CJ_document-release` (+ its helper) rewritten to read `doc-spec.md`, self-bootstrap a missing `doc-spec.md`, stub-scaffold any missing declared doc, run the no-ref audit, and derive the doc-only auto-commit whitelist from the registry.
- [ ] `cj-document-release.json` is deleted; Check 16 + helper no longer reference it (grep-clean).
- [ ] `/CJ_repo-init` is retired via the paired-layer convention: catalog `status` flip + skill-source relocation + work-item-history relocation + removal from `rules/skill-routing.md`, `docs/philosophy.md` decision tree, and `docs/workflow.md`.
- [ ] `CJ-DOC-RELEASE.md` content is absorbed (into `docs/architecture.md` + `doc-spec.md`) and the file is removed (grep-clean); its repo-init presence-check is gone.
- [ ] `CLAUDE.md` updated: both manifests removed, stale prose fixed, scripts table + routing prose updated, points to `doc-spec.md`.
- [ ] A portable Common seed ships (`templates/doc-spec-common.md` or in-skill seed) so any repo can adopt `doc-spec.md`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement the full 12-step sequence (see child story S000090 SPEC) — single cohesive change, carried by the child user-story.
- [ ] Verify `validate.sh` + `test.sh` green; run QA against TEST-SPEC.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. doc-spec.md doc-driven development: one root registry declares the repo's docs (portable Common + repo Custom + machine YAML); /CJ_document-release enforces + self-heals it; retire /CJ_repo-init, cj-document-release.json, CJ-DOC-RELEASE.md.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc-spec.md` (new, root)
- `templates/doc-spec-common.md` (new — portable Common seed)
- `doc/PHILOSOPHY.md` → `docs/philosophy.md` (rename + rewrite)
- `doc/ARCHITECTURE.md` → `docs/architecture.md` (rename + rewrite)
- `doc/WORKFLOWS.md` → `docs/workflow.md` (rename + rewrite)
- `README.md` (rewrite)
- `scripts/validate.sh` (Checks 15/15a/15b/16/17 + new 19)
- `scripts/test.sh` (zzz-test-scaffold parallel fixture)
- `skills/CJ_document-release/SKILL.md` (+ helper script)
- `CLAUDE.md` (remove 2 manifests + stale prose; scripts table; routing)
- `skills-catalog.json` (repo-init status + doc paths)
- `rules/skill-routing.md` (drop repo-init)
- `cj-document-release.json` (delete)
- `CJ-DOC-RELEASE.md` (absorb + remove)
- `skills/CJ_repo-init/` (relocate) + its work-item history

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The "what docs does this repo carry + what does each mean" contract is today scattered across four surfaces (a YAML manifest in `CLAUDE.md`, `cj-document-release.json`, `CJ-DOC-RELEASE.md`, `/CJ_repo-init`) and is workbench-coupled — it can't travel to another repo without that repo replicating the workbench's CLAUDE.md structure. One portable `doc-spec.md` collapses all four into a single human+machine source of truth and is the portability unlock.
- The doc-only auto-commit whitelist is DERIVED from the registry (every declared `path` + `doc-spec.md` itself + `docs/**/*.md`), so nothing hand-maintains a second whitelist after `cj-document-release.json` is retired.
- Large single-PR blast radius (CI gating + doc-release engine + three retirements + multi-file doc rewrite) is mitigated by strict implementation ordering, the test.sh fixture pre-flight, and the human PR review as the architecture gate (the `/CJ_goal_feature` contract).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-06: v1 scope = **Full migration** (rename `doc/`→`docs/`, scrub all work-item refs, ASCII charts, README to spec, fold the two `CLAUDE.md` manifests into `doc-spec.md`, add a no-work-item-ref lint). Rejected Convention-only / Conv+front-docs — user wants the complete vision in one PR. Summary: full migration over an incremental v1.
- [decision] 2026-06-06: Doc registry = **Consolidate** into `doc-spec.md` (single human+machine source of truth). Rejected three-registries-side-by-side — drift surface + blocks portability. Summary: one consolidated registry is the portability unlock for other repos.
- [decision] 2026-06-06: Create-on-the-fly = **Scaffold stub** (skeleton + `<!-- TODO: fill in -->`, never auto-generated prose). Rejected auto-generate full doc content — slop risk in an autonomous build. Summary: stubs, not generated prose.
- [decision] 2026-06-06: `/CJ_repo-init` = **Retire** — its responsibilities fold into the on-the-fly self-bootstrap (docs) + lazy-create in consuming skills (non-doc: `work-items/`, `TODOS.md`). Summary: repo-init redundant under doc-spec.md self-heal.
