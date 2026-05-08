---
name: "examples-fixtures-repo"
type: user-story
id: "S000016_examples_fixtures_repo"
status: active
created: "2026-05-05"
updated: "2026-05-05"
parent: "F000008"
repo: "claude-skills-templates"
branch: "feat/tracker-recut"
blocked_by: "S000014"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea (parent's design covers this story)
3. Create working branch: already on `feat/tracker-recut`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs:
   - `PRD.md` (requirements)
   - `ARCHITECTURE.md` (architecture decisions)
   - `TEST-SPEC.md` (test scenarios)
6. Break into child tasks if scope warrants

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created
- [x] Required docs scaffolded
- [x] Tasks broken down (N/A — atomic story per relaxed WORKFLOW.md rule; surfaces are small focused edits)

### Phase 2: Implement

1. **Wait for S000014 to land** (so deletion of doc-PRD.md / doc-ARCHITECTURE.md doesn't break refs in this story's targets first)
2. **Examples (in skills/personal-workflow/examples/):**
   - DELETE: `example-doc-PRD.md`, `example-doc-ARCHITECTURE.md`, `example-doc-feature-summary.md`, `example-doc-milestones.md`
   - CREATE: `example-doc-SPEC.md` (consolidate PRD + ARCHITECTURE example content), `example-doc-ROADMAP.md` (consolidate feature-summary + milestones example content)
   - REWRITE: `example-tracker-feature.md` and `example-tracker-user-story.md` to mirror new tracker template shapes
3. **Fixtures (in skills/personal-workflow/fixtures/):**
   - `valid-feature-dir/`: replace F999999_feature-summary.md + F999999_milestones.md with F999999_ROADMAP.md; update F999999_DESIGN.md cross-link
   - `invalid-missing-artifact-dir/`: fixture file unchanged (bare TRACKER); update test assertions in scripts/test.sh that consume this fixture (expected MISSING set: was 3 items, now 2)
   - Audit `invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`, `invalid-missing-section.md`, `invalid-wrong-order.md`, `valid-tracker.md`: read each, substitute deleted artifact name references with surviving artifact names
4. **Repo-level surfaces:**
   - `CONTRIBUTING.md:44-45`: replace doc-PRD.md and doc-ARCHITECTURE.md table rows with single doc-SPEC.md row; add doc-ROADMAP.md row
   - `PHILOSOPHY.md` lines 25, 42, 43: PRD/ARCHITECTURE references → SPEC
   - `template-registry.json:9` personal-workflow.doc_types array: drop prd/architecture/milestones, add design/spec/roadmap; bump version to 3.0.0
   - `scripts/test.sh:585-592`: split per-workflow loop (personal-workflow gets new template list; company-workflow keeps current)
   - `scripts/test-deploy.sh`: bulk sed `doc-PRD.md → doc-RCA.md` (19 references), then manual fix line 414 path (`templates/` → `templates/personal-workflow/`)
   - `skills-catalog.json` personal-workflow entry: bump version to 3.0.0; update templates list (drop 4, add 2)

**Gates:**
- [ ] Examples updated (4 deleted, 2 created, 2 trackers rewritten)
- [ ] Fixtures audited; valid-feature-dir migrated; assertion updates done
- [ ] All 6 repo-level surfaces updated
- [ ] `./scripts/test.sh` passes
- [ ] `./scripts/validate.sh` passes
- [ ] `scripts/test-deploy.sh` runs cleanly (no broken paths)

### Phase 3: Ship

1. Run `/personal-workflow check` — should be at PASS state if S000014 + S000015 already landed on this branch
2. Verify TEST-SPEC alignment
3. Children: none
4. Coordinate with S000014 + S000015 — all three land in same PR via parent F000008
5. (Phase 3 ship gates complete via parent F000008)

**Gates:**
- [ ] All scripts pass (./scripts/test.sh, ./scripts/validate.sh, ./scripts/test-deploy.sh)
- [ ] No grep matches for old artifact names in active repo surfaces (excluding sealed history)
- [ ] `/ship` (handled by F000008) — PR created
- [ ] `/land-and-deploy` (handled by F000008) — merged

## Acceptance Criteria

- [ ] `skills/personal-workflow/examples/` no longer contains `example-doc-{PRD,ARCHITECTURE,feature-summary,milestones}.md`.
- [ ] `skills/personal-workflow/examples/` contains `example-doc-SPEC.md` and `example-doc-ROADMAP.md`.
- [ ] `example-tracker-feature.md` and `example-tracker-user-story.md` content mirrors the new tracker template shapes.
- [ ] `skills/personal-workflow/fixtures/valid-feature-dir/` contains the new artifact set; `invalid-missing-artifact-dir/` test assertions updated to reflect new MISSING set.
- [ ] All other fixtures audited; no fixture references a deleted artifact name in a way that breaks its intended assertion.
- [ ] `CONTRIBUTING.md:44-45` table rows updated.
- [ ] `PHILOSOPHY.md` lines 25, 42, 43 updated.
- [ ] `template-registry.json` personal-workflow entry: version 3.0.0, doc_types array updated.
- [ ] `scripts/test.sh:585-592` loop split per-workflow.
- [ ] `scripts/test-deploy.sh` doc-PRD.md → doc-RCA.md substitution complete (19 refs); line 414 path fixed.
- [ ] `skills-catalog.json` personal-workflow entry version 3.0.0, templates list reflects new set.
- [ ] `./scripts/test.sh` passes; `./scripts/validate.sh` passes; `scripts/test-deploy.sh` runs without broken-path failures.

## Todos

- [ ] examples sweep (4 delete + 2 create + 2 rewrite)
- [ ] fixtures sweep + assertion update
- [ ] CONTRIBUTING.md
- [ ] PHILOSOPHY.md
- [ ] template-registry.json
- [ ] scripts/test.sh per-workflow split
- [ ] scripts/test-deploy.sh canary swap + line 414 fix
- [ ] skills-catalog.json
- [ ] Verify all scripts pass

## Log

- 2026-05-05: Created.

## PRs

## Files

- `skills/personal-workflow/examples/` (4 deleted, 2 created, 2 rewritten)
- `skills/personal-workflow/fixtures/` (valid-feature-dir migrated; assertions in test.sh updated)
- `CONTRIBUTING.md` (lines 44-45)
- `PHILOSOPHY.md` (lines 25, 42, 43)
- `template-registry.json` (personal-workflow entry)
- `scripts/test.sh` (line 585 area)
- `scripts/test-deploy.sh` (~19 lines + line 414)
- `skills-catalog.json` (personal-workflow entry)

## Insights

## Journal
