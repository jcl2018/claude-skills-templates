---
name: "Consolidate docs/philosophy.md by grouping principles under named topics: the five harness-engineering principles under a Harness-engineering best practices topic, and one-source-of-truth / two-delivery / doc-contract under a new Deployment topic"
type: task
id: "T000044"
status: active
created: "2026-06-07"
updated: "2026-06-07"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/cj-task-20260607-132717-28505"
branch: "cj-task-20260607-132717-28505"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/consolidate_docs_philosophy_md_by`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/consolidate_docs_philosophy_md_by/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Introduce a **topic** (principle-group) layer in `docs/philosophy.md`: two `##` topics, each grouping its principles as `###` sub-sections.
- [x] Topic A = **Deployment** — groups the three build/delivery principles (one source of truth · two delivery surfaces · doc contract).
- [x] Topic B = **Harness-engineering best practices** — groups the five runtime principles (curate context · externalize state · stateless handoff · verify the path · permissions first-class).
- [x] Redesign the leading summary table to a Topic / Principle / one-line shape (Check 20 — table must precede the first `##`).
- [x] Fix the `#principle-2-two-delivery-surfaces-one-contract` anchor link in `docs/architecture.md` after the heading rename.
- [x] Preserve the `## Decision tree: which CJ_ skill do I call?` heading byte-for-byte (3 inbound anchor links + the New-skills check) and keep it the final `##`.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-07: Created. Auto-scaffolded by /CJ_goal_task from topic: Consolidate docs/philosophy.md by grouping principles under named topics: the five harness-engineering principles under a Harness-engineering best practices topic, and one-source-of-truth / two-delivery / doc-contract under a new Deployment topic
- 2026-06-07: Implemented via /CJ_implement-from-spec (--auto). Reorganized docs/philosophy.md into two `## Topic:` groups + fixed the architecture.md anchor link. `bash scripts/validate.sh` exits 0 (Checks 15/15a/15b/16/17/19/20 + portability all PASS).
- 2026-06-07: Core changes committed to branch cj-task-20260607-132717-28505 (philosophy.md topic reorg + architecture.md anchor fix + this work-item) — pre-QA commit per the task-type commit-gate + doc-sync precommit contract.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `docs/philosophy.md` — modified — the reorganization: two `## Topic:` headings (Deployment, Harness-engineering best practices), 3 Deployment `###` + 5 numbered harness `###` principles, the 4 install-model sub-sections demoted `###` → `####`, redesigned Topic/Principle/In-one-line front table, reworded intro + 2 "Principles 1-3" cross-refs → "the Deployment topic". Decision tree heading kept byte-for-byte and last.
- `docs/architecture.md` — modified — one anchor-link fix on line 342: `philosophy.md#principle-2-two-delivery-surfaces-one-contract` → `philosophy.md#two-delivery-surfaces-one-contract` (visible link text "Two delivery surfaces" unchanged). The `#decision-tree-…` link on line 356 left untouched.

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): Consolidate docs/philosophy.md by grouping principles under named topics: the five harness-engineering principles under a Harness-engineering best practices topic, and one-source-of-truth / two-delivery / doc-contract under a new Deployment topic

### Target structure for `docs/philosophy.md`

Introduce a **topic** = a named group of related principles. Two topics, each a
`##` heading; every principle becomes a `###` under its topic. Final shape:

```
# Philosophy
<intro — reword "arranged by principle" → "arranged by topic; each topic groups
 the principles that share a concern">
<front table — REDESIGNED, see below, MUST precede the first ## (Check 20)>

## Topic: Deployment
   <1–2 sentence topic intro: these principles are about how the workbench is
    BUILT and DELIVERED — the producer/consumer side.>
   ### One source of truth — this checkout        (was "## Principle 1: …")
      #### The install model: install == clone      (was ###, demote one level)
      #### The reference model: every repo references the one install   (was ###)
      #### Why this is the first principle           (was ###)
      #### Windows: the model holds, the mechanism changes   (was ###)
   ### Two delivery surfaces, one contract         (was "## Principle 2: …")
   ### The doc contract is one file, human + machine   (was "## Principle 3: …")

## Topic: Harness-engineering best practices
   <topic intro: keep the existing "second, orthogonal lens — how the cj_goal
    agent loop behaves at runtime" framing; this is the runtime standard.>
   ### 1. Context is a finite resource — curate it   (was list item 1; KEEP numbering)
   ### 2. Externalize state to durable storage
   ### 3. Design for stateless handoff
   ### 4. Verification is a continuous gate — judge the path
   ### 5. Tools & permissions are first-class
   <KEEP the closing synthesis paragraph ("The first three are the framework's
    strongest habits…") — its "first three" reference stays valid since the five
    keep their 1–5 numbering.>

## Decision tree: which CJ_ skill do I call?   (UNCHANGED — heading byte-identical)
```

### Hard constraints (these are the QA rows — all must hold)

1. **Front table (Check 20)** — a summary table MUST appear before the first `## `
   heading. Redesign it to a 3-column **Topic / Principle / In one line** shape:
   group the 3 Deployment principles under a **Deployment** topic cell, the 5
   harness principles under a **Harness-engineering best practices** topic cell,
   and keep a trailing **Decision tree** row (topic cell `—`).
2. **No work-item IDs (Check 19)** — philosophy.md must contain ZERO `[FSTD]NNNNNN`
   references (it has 0 today). Do not introduce any.
3. **Decision tree anchor + New-skills check** — keep `## Decision tree: which CJ_
   skill do I call?` byte-for-byte (3 docs link to its slug
   `#decision-tree-which-cj_-skill-do-i-call`) AND keep it the LAST `##` section.
   It must still name every routable skill (the table rows + the internal
   phase-step paragraph) — do not drop any skill name.
4. **architecture.md anchor fix** — `docs/architecture.md` line ~342 links to
   `philosophy.md#principle-2-two-delivery-surfaces-one-contract`. After renaming
   that heading to `### Two delivery surfaces, one contract`, update the link to
   `philosophy.md#two-delivery-surfaces-one-contract` (and the visible link text if
   it embeds "Principle 2"). Leave the two `#decision-tree-…` links untouched.
5. **Internal cross-references** — the doc currently says "Principles 1-3 are about
   how the workbench is built" in 2–3 places (the runtime-standard intro and the
   Decision-tree intro). Reword these to refer to the **Deployment topic** instead
   of "Principles 1-3", since the global 1/2/3 numbering is gone.
6. **Preserve all prose** — this is a REORGANIZATION, not a rewrite. Move/regroup
   existing paragraphs and demote heading levels; do not delete content or invent
   new claims. Only the headings, the front table, the intro framing, and the
   handful of "Principles 1-3" cross-references change wording.
7. **Editing scope** — docs only (`docs/philosophy.md` + `docs/architecture.md`).
   No catalog / skill / template / validator / script edits (keeps the run off the
   sensitive-surface gate).


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: Consolidate docs/philosophy.md by grouping principles under named topics: the five harness-engineering principles under a Harness-engineering best practices topic, and one-source-of-truth / two-delivery / doc-contract under a new Deployment topic -->

- 2026-06-07 [impl-decision] Treated this as a pure reorganization per Insights constraint #6: moved/regrouped existing prose and demoted heading levels only. No paragraph deleted, no new claim invented. Reworded only the headings, the front table, the two intro paragraphs, and the two "Principles 1-3" cross-references (runtime-standard intro + Decision-tree intro) → "the Deployment topic".
- 2026-06-07 [impl-decision] Renamed `## Principle 2: Two delivery surfaces, one contract` → `### Two delivery surfaces, one contract`, which changes its GitHub slug from `principle-2-two-delivery-surfaces-one-contract` to `two-delivery-surfaces-one-contract`; updated the one inbound link in docs/architecture.md (line 342) to match. Visible link text was already "Two delivery surfaces" (no "Principle 2" embedded), so only the anchor changed.
- 2026-06-07 [impl-finding] The 4 sub-sections under old Principle 1 (install model / reference model / why first principle / Windows) were already `###`; demoted them to `####` so the new `### One source of truth` principle owns the `###` level under the Deployment topic. The Decision tree heading was kept byte-for-byte and remains the LAST `##` (slug `#decision-tree-which-cj_-skill-do-i-call` preserved — 3 inbound links + New-skills check intact).
- 2026-06-07 [impl] Modified 2 files: docs/philosophy.md (full reorganization) + docs/architecture.md (1 anchor-link fix). 0 files created, 0 removed. Tracker updated (Files, Todos, Log, Journal). Phase 2 implementer-owned gates transitioned.
- 2026-06-07 [impl-auto] Auto-mode run; --auto honored (2 files touched, docs-only, no sensitive surface — catalog/manifest/validator/template/git-hook all untouched).
- 2026-06-07 [impl-pass] T000044: implementation complete. Phase 2 implementer-owned gates transitioned. `bash scripts/validate.sh` exits 0 (0 errors / 0 warnings); test-plan rows 2-8 verified by grep; row 1 verified by validate.sh green.
- 2026-06-07 [qa-smoke] 1 (validate.sh stays green): green — `bash scripts/validate.sh` exit 0; Validation Summary 0 errors / 0 warnings; Checks 15/15a/15b/16/17/19/20 + portability + New-skills all PASS.
- 2026-06-07 [qa-smoke] 2 (front table precedes first ##): green — first markdown table at line 9, first `## ` heading at line 21; the redesigned Topic/Principle/In-one-line table precedes the first `##` (Check 20 PASS corroborates).
- 2026-06-07 [qa-smoke] 3 (no work-item IDs): green — `grep -nE '[FSTD][0-9]{6}' docs/philosophy.md` returns zero matches (Check 19 PASS corroborates).
- 2026-06-07 [qa-smoke] 4 (two topic headings): green — `^## Topic: Deployment` (line 21) and `^## Topic: Harness-engineering best practices` (line 150) both present.
- 2026-06-07 [qa-smoke] 5 (all former principles survive as ###): green — exactly 3 Deployment `###` (One source of truth / Two delivery surfaces / The doc contract is one file) + 5 harness `###` (numbered 1-5) principle headings present; no content deleted.
- 2026-06-07 [qa-smoke] 6 (decision-tree anchor preserved): green — `## Decision tree: which CJ_ skill do I call?` present at line 222 and is the LAST `##` heading (slug `#decision-tree-which-cj_-skill-do-i-call` intact).
- 2026-06-07 [qa-smoke] 7 (every routable skill named in Decision tree): green — all 3 active-routable skills (CJ_system-health, CJ_personal-workflow, CJ_goal_todo_fix) appear in the Decision-tree section; matches the New-skills selector.
- 2026-06-07 [qa-smoke] 8 (architecture.md anchor link fixed): green — `docs/architecture.md:342` points at `philosophy.md#two-delivery-surfaces-one-contract`; no dangling `#principle-2-…` link; the `#decision-tree-…` link on line 356 untouched.
- 2026-06-07 [qa-smoke-summary] green: 8/8 non-manual rows green (0 manual rows pending)
- 2026-06-07 [qa-pass] T000044 (task): green smoke from test-plan rows (8 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
