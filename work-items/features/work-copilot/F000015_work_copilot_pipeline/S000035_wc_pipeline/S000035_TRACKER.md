---
name: "/wc-pipeline — status compiler / drift math"
type: user-story
id: "S000035"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000034"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker
2. Create working branch: `git checkout -b feat/wc_pipeline`
3. Scaffold work item directory
4. Distill DESIGN.md
5. Scaffold SPEC.md
6. Scaffold TEST-SPEC.md
7. Break into child tasks if needed

**Gates:**
- [x] /office-hours design referenced
- [x] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A)

### Phase 2: Implement

1. Read DESIGN + SPEC
2. Implement
3. Smoke tests
4. `/CJ_personal-workflow check`
5. Update tracker + journal
6. Update Files

**Gates:**
- [ ] Acceptance criteria verified
- [ ] Smoke tests pass
- [ ] Todos current
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Smoke in CI
3. E2E manually
4. Children shipped
5. `/ship`
6. `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — pass
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship`
- [ ] `/land-and-deploy`

## Acceptance Criteria

- [ ] `work-copilot/prompts/pipeline.prompt.md` exists with `tools: [codebase, search, searchResults]` (READ-ONLY — no editFiles).
- [ ] Prompt accepts both inputs: work-item path OR design-doc path; routes accordingly.
- [ ] Reads receipts from tracker frontmatter (work-item mode) or design-doc frontmatter (design-doc mode).
- [ ] Reads `.git/HEAD` via `codebase` tool (file read; no shell needed).
- [ ] Computes drift math: Missing / Stale / Coverage holes / Diff audit / Ship-not-opened / Next legal.
- [ ] Stale check is BINARY ("HEAD matches" or "HEAD has moved past latest_sha_at_implement"); does NOT count commits (would require `git log`, unavailable).
- [ ] Ship-not-opened drift rule keys on `receipts.ship.pr_opened == false AND receipts.ship.completed_at older than 24h`.
- [ ] Tolerates degenerate review-type receipts (empty arrays in `files_touched`, etc.) — does NOT flag review work-items as drifted on empty arrays.
- [ ] Prints single status block in fixed format (see SPEC).
- [ ] Manual smoke pass against a deliberately-drifted fixture: verify all 5 drift signals fire correctly.

## Todos

- [ ] Author `work-copilot/prompts/pipeline.prompt.md` with frontmatter + 4 main steps.
- [ ] Two-mode input dispatch (work-item vs design-doc).
- [ ] `.git/HEAD` read via `codebase` tool (file path read, no shell).
- [ ] Drift-math logic (5 rules) documented in prompt body.
- [ ] Status-block format spec (ASCII art with check marks / X / ?).
- [ ] Build a deliberately-drifted fixture work-item under `work-copilot/fixtures/` for E2E.
- [ ] Smoke + fixture exercise.

## Log

- 2026-05-11: Created. Build #6 of Approach C (status compiler over all 5 upstream receipts). Capstone — read-only diagnostic.

## PRs

## Files

- `work-copilot/prompts/pipeline.prompt.md` (new)
- `work-copilot/fixtures/drifted-feature-dir/` (new — deliberately-drifted fixture for E2E)

## Insights

- The "binary stale check" decision is the load-bearing tradeoff for /wc-pipeline. A commit count would be more useful but requires `git log`, which requires shell. Reading `.git/HEAD` via the `codebase` tool gets a string comparison only. The prompt prints the binary signal AND tells the user the exact `git log` command they could run for a count — the user-paste pattern as documentation rather than runtime.
- "Ship printed but PR not opened" keys on `pr_opened == false` (NOT `pr_url`) because a user could paste a URL and forget the flag flip. `pr_opened` is the canonical truth.
- Empty arrays from `type: review` work-items are a valid completion state — drift math tolerates them. This is the only place where "empty receipt fields" don't mean "phase not run."

## Journal

- [decision] 2026-05-11: Binary stale check (no commit count) is the V1 design. Reasoning: `git log` requires shell; `.git/HEAD` read via `codebase` is the only available signal. Print the binary "HEAD moved" + the user-paste command for an exact count.
- [decision] 2026-05-11: 24-hour timeout on "ship printed but PR not opened" drift rule. Reasoning: gives the user reasonable time to open the PR manually before the warning fires; shorter would be noisy, longer would be missed.
