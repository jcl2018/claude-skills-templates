---
name: "Greeting suffix fix fixture"
type: defect
id: "D888000"
status: active
created: "2026-05-08"
updated: "2026-05-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-parity"
blocked_by: ""
---

<!-- Synthetic fixture for /implement-from-spec on a DEFECT work-item type.
     NOT a real defect — lives under skills/implement-from-spec/fixtures/,
     invisible to the work-items/ tree walk. The RCA + test-plan describe a
     single-file write (`output/fixed.txt` with content
     "Hello from defect fix\n"). After dogfooding, the written file is
     removed to restore canonical state.

     This fixture exercises the per-type defect branch added in S000021
     (F000012 pipeline parity). Parallels the example-user-story fixture
     for the user-story branch. -->

## Lifecycle

### Phase 1: Track

1. (synthetic) Document reproduction: file missing or wrong content
2. RCA names the location and root cause
3. test-plan asserts post-fix behavior

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Read RCA for context (Symptom, Root Cause, Fix Description)
2. Read test-plan for post-fix behavior contract
3. Write the fix per Fix Description; verify against test-plan rows
4. Update tracker journal + Files section

**Gates:**
- [ ] Fix committed
- [ ] RCA doc updated
- [ ] Todos section reflects remaining work

### Phase 3: Ship

1. (synthetic) Not applicable for fixtures

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. Run any process that depends on `output/fixed.txt` existing with the canonical greeting.
2. **Observe:** the file is absent (or has stale content from a prior incorrect attempt).
3. Expected: file exists with exact content `Hello from defect fix\n`.

**Environment:** synthetic; not OS-dependent.

## Todos

- [ ] /implement-from-spec writes `output/fixed.txt` per RCA + test-plan
- [ ] Tracker journal records the implementation step
- [ ] RCA doc's `## Fix Description` section reflects the actual approach taken

## Log

- 2026-05-08: Created. Synthetic fixture for /implement-from-spec defect-path manual testing (S000021/F000012).

## PRs

<!-- N/A — fixture, not real work. -->

## Files

<!-- Populated by /implement-from-spec dogfood run. Canonical state: empty (modulo .gitkeep). -->

## Insights

- **Per-type plumbing:** this fixture exercises the defect branch (RCA + test-plan input). The user-story branch is exercised by the sibling `example-user-story/` fixture.
- **Triviality:** test-plan has 1 file in Components Affected (excluding TRACKER) and no sensitive-surface change. The skill should classify this as TRIVIAL=true. With `--auto` flag, MODE=auto. Without, MODE=propose.
- **Phase 2 gate ownership:** for defects, `/implement-from-spec` marks `RCA doc updated` + `Todos section reflects remaining work`. The `Fix committed` gate stays UNCHECKED until a real git commit lands (the skill writes files; commits are user/`/ship`-owned).

## Journal

- 2026-05-08 [decision] Fixture lives at `skills/implement-from-spec/fixtures/example-defect/` (parallel to `example-user-story/`). Synthetic ID D888000 doesn't pollute the real work-items tree.
- 2026-05-08 [decision] Defect fixture writes the same `output/...txt` shape as the user-story fixture, just with a different filename. Keeps the cleanup pattern uniform across fixtures.
