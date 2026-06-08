---
name: "gate-spec.md — one human-readable verification contract for all cj_goals"
type: feature
id: "F000054"
status: active
created: "2026-06-07"
updated: "2026-06-07"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/priceless-grothendieck-367489"
branch: "claude/priceless-grothendieck-367489"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/gate_spec_verification_contract`
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

- [ ] `gate-spec.md` exists at root: a human can read it top-to-bottom and answer "what stops a broken cj_goal change from landing, and at which layer?" without opening any script (S000096 ACs).
- [ ] `scripts/gate-spec.sh --validate` exits 0 on the committed registry; `--list-gates` / `--list-layers` emit the right sets (S000096 ACs).
- [ ] A new advisory `validate.sh` Check 22 is GREEN on the clean tree and REPORTS a finding when a declared literal marker is removed from the registry or from both of its mode's files; advisory in v1 (mirrors Check 21) so a finding prints but does not exit non-zero (S000096 ACs).
- [ ] The word "gate" is disambiguated in the docs (CI checks vs pipeline gates vs ratchets), and architecture.md no longer mislabels validate.sh as "the CI gate" without qualification (S000096 ACs).
- [ ] The story lands as one PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review; doc-sync + portability stay green and the PR carries the registered-doc + portability verdicts.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000096 — gate-spec.md contract: the doc-spec mirror for gates (one declarative verification contract + reader + advisory conformance check). Single-story feature.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-07: Created. gate-spec.md — one human-readable verification contract for all cj_goals (the doc-spec / permission-policy family's third member).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `gate-spec.md` (S000096 — NEW: human verification map + fenced yaml registry of layers + gates)
- `scripts/gate-spec.sh` (S000096 — NEW: reader; `--validate` / `--list-layers` / `--list-gates`)
- `scripts/validate.sh` (S000096 — advisory Check 22: registry parses + per-mode marker drift guard)
- `scripts/test.sh` (S000096 — parallel regression guard + zzz-test-scaffold integration coverage)
- `doc-spec.md` (S000096 — register `gate-spec.md`; section: custom, audit_class: operational)
- `docs/architecture.md` (S000096 — new "The gate-spec.md contract" section + relabel the mislabeled "CI gate" heading)
- `docs/philosophy.md` (S000096 — §4 pointer to gate-spec.md)
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_todo_fix/{pipeline.md,SKILL.md}`, `skills/CJ_goal_task/pipeline.md` (S000096 — one-line canonical-gate-sequence reference near each halt taxonomy)
- `CLAUDE.md` (S000096 — pointer to gate-spec.md as the single verification map)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The repo ALREADY solved this exact problem for documentation: `doc-spec.md` is ONE file that is simultaneously the human-readable map (prose + table + ASCII) AND the machine source of truth (a fenced yaml registry parsed by `scripts/doc-spec.sh`). The structural fix for verification is not a new mechanism — it is applying the doc-spec pattern to gates. Maximum human-understandability comes from symmetry with something already in the repo.
- `gate-spec.md` is the THIRD member of an established family: `doc-spec` → `permission-policy` → `gate-spec`. `permission-policy.md` + `scripts/permission-policy.sh` + `validate.sh` Check 21 (a cross-orchestrator drift check, same F000053 saga) is the closest structural template for the new conformance check, and Check 21 shipped ADVISORY — so Check 22 follows the same advisory-first posture (flip-to-strict is a tracked follow-up).
- The schema must model marker irregularity honestly: the isolation gate has THREE different markers for one concept (`[feature-not-isolated]` / `[investigate-not-isolated]` for defect / `[task-not-isolated]`), and todo has no isolation marker at all. Only `[portability-red]` + `[doc-sync-red]` are universal across all four cj_goals. So `markers` is a per-mode map (NOT a single string), and a value is either a literal `"[marker]"` (greppable) OR `{enforced_by: subagent|auq}` (the escape hatch that keeps the baseline honestly clean).
- Because the registry is authored honestly, the advisory check is GREEN on the clean baseline today — so flipping it strict later is a one-line follow-up TODO (a free ratchet), not a reconciliation project.
- Known blind spot: every new `validate.sh` check historically requires a parallel edit to `test.sh`'s `zzz-test-scaffold` integration test, and the implement subagent has forgotten this on F000032 / F000034 / F000035. The implement prompt MUST pre-flight this (Check 22 greps `skills/CJ_goal_*/`, and `zzz-test-scaffold` is not a `CJ_goal_*` skill, so it is naturally skipped — but verify, don't assume).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- **[decision]** 2026-06-07 — Approach A (full doc-spec mirror) over Approach B (registry inside cj-goal-common.sh) and Approach C (gate-spec.md + grep conformance, no reader script). A is the truest mirror of the in-repo doc-spec idiom (maximum legibility) and is still shippable in one PR because it adds a new artifact + reader + one check + doc and only lightly edits the four pipelines (it does NOT re-plumb gate execution). The operator chose the structural refactor over the recommended minimal doc-only option, then confirmed all four scoping premises without softening them.
- **[decision]** 2026-06-07 — Declarative contract, NOT a central executor (Premise 1). Some gates are interactive AskUserQuestion prompts (design-summary gate) or subagent dispatches (QA) that cannot run from one shared bash entry point. "Shared gate contract" means a single DECLARED definition of the ordered sequence all cj_goals reference + a conformance check — NOT a `--run-all-gates` function. Gate implementations stay exactly where they are; re-plumbing gate execution into a shared runner is explicitly deferred to a future multi-PR epic.
- **[decision]** 2026-06-07 — Advisory in v1, mirroring Check 21. An earlier design draft assumed "hard ERROR from day one"; the adversarial review correctly flagged that as inconsistent with the Check 21 precedent and risky for a hand-authored registry's first cut. Consistency with the immediately-preceding sibling check (permission-policy / Check 21, same F000053 saga) is itself a legibility win.
