---
name: "Relocate the spec-registry family (doc-spec/gate-spec/permission-policy) into a spec/ folder"
type: feature
id: "F000057"
status: active
created: "2026-06-08"
updated: "2026-06-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/relocate_spec_registry_family_into_spec_folder`
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

- [ ] `spec/doc-spec.md`, `spec/gate-spec.md`, `spec/permission-policy.md` exist (history preserved via `git mv`); root no longer has any of the three.
- [ ] All 3 helpers resolve `spec/` first, root second; `doc-spec.sh --validate`, `gate-spec.sh --validate`, `permission-policy.sh --validate` all green from the repo.
- [ ] `validate.sh` PASS 0/0 — Checks 16/19/20/21/22 print `PASS:` (NOT `SKIP:` — the silent-skip regression must not occur); Check 17 correct without the 3 files; the new `spec/*.md` orphan scan green; Check 23 (views in sync) green.
- [ ] Env-override regression intact: `PERMISSION_POLICY_PATH=/nonexistent … --validate` still FAILS (test.sh:113); analogous for the new `DOC_SPEC_PATH`/`GATE_SPEC_PATH` overrides (env is OUTERMOST in the resolution).
- [ ] `scripts/test.sh` PASS, including S94 (permission-policy) and S96 (gate-spec); seed test #13 green (seed unchanged, byte-identity).
- [ ] Generated views regenerated, reference `spec/doc-spec.md`; Check 23 in sync.
- [ ] No stale root-path reference to the 3 files remains anywhere (adversarial completeness sweep clean).
- [ ] A simulated "root-only" repo (no `spec/`, file at root) still resolves via the helper fallback (proves the knowledge-base consumer is unaffected) — verified with a temp.
- [ ] Pre-ship portability gate green; PR opens and STOPS (PR-stop, no auto-merge).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Implement S000099 — the 8-delta relocation + back-compat fallback + reviewer must-fixes A–G (single lockstep commit).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Relocate the spec-registry family (doc-spec/gate-spec/permission-policy) into a `spec/` folder with a back-compat `spec/`→root resolution fallback in each helper; workbench-internal, no consumer/seed change.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc-spec.md` → `spec/doc-spec.md` (git mv)
- `gate-spec.md` → `spec/gate-spec.md` (git mv)
- `permission-policy.md` → `spec/permission-policy.md` (git mv)
- `scripts/doc-spec.sh`, `scripts/gate-spec.sh`, `scripts/permission-policy.sh` (resolution fallback)
- `scripts/validate.sh` (Checks 15a/16/17/19/20/21/22/23 + new `spec/*.md` orphan scan)
- `scripts/test.sh` (S94/S96 path refs + zzz-scaffold orphan-scan mirror)
- `scripts/generate-doc-views.sh`, `scripts/generate-readme.sh`
- `docs/doc-general.md`, `docs/doc-custom.md`, `README.md` (regenerated views)
- `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `docs/workflow.md` (prose path sweep)
- `skills/CJ_document-release/SKILL.md` (self-bootstrap guard + Step 6.7.1 parser), plus 5 other skill MD path refs

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The operator pressure-tested the same object six ways ("unnecessary? → two sets? → slim? → rename? → folder?") before converging on the structural fix. The `spec/` folder is the glance-level signal that these are machine config, not human docs.
- The back-compat fallback alone does NOT save consumers that gate on a literal root `[ -f ]` BEFORE calling the helper — the reviewer-found break-set (validate.sh silent-SKIP class, test.sh hard-FAIL class, the CJ_document-release self-bootstrap duplicate-file bug) is the load-bearing part of the change, not the `git mv`.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Scope is workbench-internal (Approach A), NOT the ecosystem-wide convention change (Approach B). Summary: move the 3 files to `spec/` in THIS repo only + add a `spec/`→root fallback to each helper; the portable seed + self-bootstrap stay root-style so test #13 stays byte-identical and the knowledge-base consumer needs no migration.
- [decision] Treat the 3 as a family, not single out `doc-spec.md`. Summary: all three are the same pattern (root `.md` + one `yaml` block + `scripts/<name>.sh`); moving only one makes it an odd-one-out.
- [decision] All doc-contract / gate / permission GUARANTEES stay — the registries remain the source of truth; the readable views are generated FROM them and cannot replace them. Summary: this is a relocation + role-clarity change, not a removal of any guarantee.
