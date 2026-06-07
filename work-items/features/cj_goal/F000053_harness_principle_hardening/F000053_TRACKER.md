---
name: "cj_goal harness-principle hardening"
type: feature
id: "F000053"
status: active
created: "2026-06-06"
updated: "2026-06-06"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/tender-elion-267bd0"
branch: "claude/tender-elion-267bd0"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/harness_principle_hardening`
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

- [ ] A resumed user-story/feature run re-verifies (re-validates the receipt; re-runs E2E on a missing/stale receipt) rather than trusting a date-keyed marker or a phase-skip; an artifacts-only or stale-state work-item cannot read green (S000093 ACs).
- [ ] One declared allow/ask/deny policy exists; the live enforcement points reference it and an advisory check flags drift; risky verbs (git push to main, gh pr merge, rm, network) are explicit deny/ask (S000094 ACs).
- [ ] The office-hours inline phase writes a receipt the orchestrator continues from rather than the raw transcript (S000095 ACs).
- [ ] Each story lands as its own PR, green on `validate.sh` + `test.sh` + the windows-latest Git-Bash job, PR-stopped for human review. No regression to P2 (state) or P3 (handoff).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000093 — Trajectory QA: QA that cannot lie about correctness (P4). Build first (correctness-first).
- [ ] Ship S000094 — Permission policy: one declared allow/ask/deny contract (P5). Build second.
- [ ] Ship S000095 — Within-phase receipts: continue from receipts, not transcript (P1). Build third.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. cj_goal harness-principle hardening (replay-safe, review-safe, permission-legible).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_qa-work-item/qa.md` (S000093 — Step 3 NO-OP logic + receipt emission + fail-closed verdict)
- `skills/CJ_goal_feature/pipeline.md` (S000093 resume QA re-dispatch; S000095 office-hours receipt boundary)
- `templates/CJ_personal-workflow/` tracker template (S000093/S000095 — execution-receipt block)
- new permission-policy file + its `scripts/` parser (S000094)
- `scripts/cj-handoff-gate.sh` (S000094 — dormant denylist derives from policy)
- `scripts/validate.sh` + `scripts/test.sh` (S000094 — advisory drift check + parallel integration fixture)
- `scripts/cj-goal-common.sh` (S000095 — possibly)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The spine (Codex's framing, adopted): make the chains **replay-safe, review-safe, and permission-legible, so a human can trust a resumed run the same way they trust a fresh one.** This is not "more process" — it closes three concrete holes where orchestrators usually rot: false confidence from stale verification, fuzzy authority boundaries, and context pressure.
- The framework is already strong where it is *expensive* to be strong (P2 state, P3 handoff: per-branch resume state file, committed tracker journal, SPEC/DESIGN/TEST-SPEC triplet, validate-before-skip resume, leaf subagents returning a one-line RESULT). This saga finishes the *affordable tail* (P4/P5/P1) that turns it from "a pile of conventions" into a system whose resumed runs are as trustworthy as fresh ones.
- The three gaps are concrete holes, not principle-worship: the same-SHA resume that skips QA (date-only `[qa-pass]` marker; feature `pipeline.md` phase-skip), the three-places-no-contract permission rule (`allowed-tools` allow + sensitive-surface AUQ ask both live; `cj-handoff-gate.sh` deny dormant), and the inline office-hours transcript that never compacts.
- Do not reinvent: port `work-copilot`'s tracker-frontmatter `receipts:` block convention inward. Its `receipts.qa` block (`work-copilot/prompts/qa.prompt.md:222-285`) is a near-exact prototype for S000093's execution receipt; `receipts.scaffold/implement` are the S000095 precedent. The resume state file is already a proto-receipt to generalize.
- Per-machine cost-curation matters: do NOT unconditionally re-pay the ~5-min E2E budget on every same-SHA resume (`qa.md:539`) — re-run the expensive E2E subagent ONLY when the receipt is missing/incomplete/stale-SHA.
- What makes this cool: the framework is becoming a *real system*. Codex's "tell" — if one coherent allow/ask/deny contract that orchestrators, leaf skills, AND shell helpers all honor can be expressed, it is a system; if not, the rest is polish on an unsafe control plane (S000094 is that test).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- **[decision]** 2026-06-06 — Codex-driven correctness-first reorder. Summary: The stated wedge was permissions-first (S000094 is the cleanest, most self-contained deliverable — "the tell"). An independent Codex cold-read challenged it: a system that can silently bless stale or fake QA is *already lying about correctness*, while fuzzy permissions are mostly a containment/governance defect given the existing PR-stop + human review. Its falsification test ("show one same-SHA resume path where QA is skipped but behavior changed and still yields ready") is already satisfied by the GAP A analysis, so the challenge stands. Accepted on the strength of the argument, not the source: build order reordered to correctness-first — **S000093 Trajectory QA ships first**, then S000094 Permission policy, then S000095 Within-phase receipts. ("S3 is the tell" — the permission story remains the proof the framework is a real system, just not the first bet.) The three stories stay independent (value/risk order, not a hard dependency chain); S4 (cross-branch state index + per-phase telemetry + crash checkpointing) deferred to TODOS, built only after S1-3 land.
