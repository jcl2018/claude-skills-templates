---
name: "Greeting fixture"
type: user-story
id: "S999000"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F999999"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/CJ_qa-work-item"
blocked_by: ""
---

<!-- Synthetic fixture for /CJ_qa-work-item. NOT a real work item — lives under
     skills/CJ_qa-work-item/fixtures/, invisible to the work-items/ tree walk.
     The "planted bug" is in fixture-impl.txt: the impl says "Hello, world"
     but the TEST-SPEC asserts "Hello, World!" (capital W, exclamation). The
     QA engineer subagent should detect the mismatch and report red. -->

## Lifecycle

### Phase 1: Track

1. (synthetic) Track this fixture
2. Read parent (none — synthetic)

**Gates:**
- [x] /office-hours design referenced (synthetic — none)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. (synthetic) Author fixture-impl.txt with the planted bug
2. Pretend implementation is done

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [x] Todos section reflects remaining work
- [x] Files section updated with changed files

### Phase 3: Ship

1. (synthetic) Not applicable for fixtures

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] fixture-impl.txt contains the exact greeting `Hello, World!` (capital W, exclamation point)

## Todos

- [x] Author fixture-impl.txt with planted bug
- [ ] /CJ_qa-work-item must detect the planted bug as a red E2E finding

## Log

- 2026-05-08: Created. Synthetic fixture for /CJ_qa-work-item v1 manual testing.

## PRs

<!-- N/A — fixture, not real work. -->

## Files

- `skills/CJ_qa-work-item/fixtures/example-user-story/fixture-impl.txt` (NEW — planted-bug greeting file)

## Insights

- **Planted bug rationale:** the fixture's `fixture-impl.txt` deliberately disagrees with TEST-SPEC's expected greeting. The whole point is that `/CJ_qa-work-item`'s QA engineer subagent (Step 7 of `qa.md`) should read TEST-SPEC, read fixture-impl.txt, diff them, and report a red E2E finding. If the subagent reports green, the QA orchestration is broken (false negative on a known defect).
- **Smoke is intentionally simple.** S1 just checks the file exists; S2 checks it's non-empty. Both should pass — the bug is content, not presence.

## Journal

- 2026-05-08 [decision] Fixture lives at `skills/CJ_qa-work-item/fixtures/example-user-story/` rather than `work-items/`, so the synthetic ID `S999000` doesn't pollute the real work-items tree walk (Tier 2 of /CJ_personal-workflow check only descends into `./work-items/`).
- 2026-05-08 [decision] One planted-bug fixture is the v1 design (Issue 3.1A from /plan-eng-review). More fixtures can be added in v2 if the QA engineer subagent pattern needs more coverage.
