---
name: "Permission policy — one declared allow/ask/deny contract"
type: user-story
id: "S000094"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000053"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/tender-elion-267bd0"
branch: "claude/tender-elion-267bd0"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/permission_policy` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] AC1: one declared allow/ask/deny policy artifact exists, enumerating in-scope edits (allow), sensitive surfaces (ask), and risky verbs git-push-to-main / gh-pr-merge / rm / network (deny or ask).
- [ ] AC2: the two LIVE enforcement points (`allowed-tools`, sensitive-surface AUQ) reference the policy; the dormant handoff-gate denylist derives from it.
- [ ] AC3: a verb absent from the policy is treated as deny (design permission before capability).
- [ ] AC4: an advisory `validate.sh` check flags drift between the policy and the enforcement points (advisory-first, like portability Check 18; a follow-up flips it strict once reconciled). REQUIRED, not stretch.

## Todos

<!-- Actionable items for this story. -->

- [ ] Author the policy file (`doc-spec.md`-style: prose + a fenced machine-readable block) with the minimal row schema `{verb, mode ∈ allow|ask|deny, scope}`.
- [ ] Write the small `scripts/` parser/helper for the policy (parse + resolve a verb → mode; absent verb resolves to deny).
- [ ] Add the policy reference to `skills/CJ_goal_*` SKILL.md (the two live enforcement points: `allowed-tools` frontmatter + sensitive-surface AUQ).
- [ ] Rewire `scripts/cj-handoff-gate.sh`'s denylist to DERIVE from the policy (forward-looking — the gate is dormant, no live consumer; NOT a live-enforcement claim).
- [ ] Add the advisory `scripts/validate.sh` drift check (advisory-first, exit 0; like portability Check 18).
- [ ] **REPO CONVENTION: add the parallel `scripts/test.sh` zzz-test-scaffold integration fixture in the SAME PR as the new validate.sh check** — the implement step reliably forgets this; pre-flight it.
- [ ] Run `/CJ_personal-workflow check`; verify `validate.sh` + `test.sh` + the windows-latest Git-Bash job are green; PR-stop for human review.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Story 2 of F000053 (ship second). Closes GAP B (P5): permission is implicit and scattered across three unconnected places, only two live (`allowed-tools` = allow/live, sensitive-surface AUQ = ask/live, `cj-handoff-gate.sh` denylist = deny/DORMANT). Introduces ONE declared allow/ask/deny policy artifact the live enforcement points reference and the dormant denylist derives from, plus an advisory drift check.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- (planned) new policy file (`doc-spec.md`-style; prose + fenced machine-readable block)
- (planned) `scripts/` policy parser/helper
- (planned) `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md` — reference the policy
- (planned) `scripts/cj-handoff-gate.sh` — denylist derives from the policy
- (planned) `scripts/validate.sh` — advisory drift check
- (planned) `scripts/test.sh` — parallel zzz-test-scaffold integration fixture

## Insights

<!-- Non-obvious findings worth remembering. -->

- The handoff-gate denylist is DORMANT: its consumers `/CJ_goal_auto` and `/CJ_goal_run` are deleted, so no current orchestrator invokes the gate (the live orchestrators cite it only rhetorically to justify PR-stop). Wiring it to derive from the policy is forward-looking correctness-if-reactivated, NOT a claim that it enforces anything today.
- Codex called the permission story "the tell": if one coherent allow/ask/deny contract the orchestrators, leaf skills, AND shell helpers can all honor can be expressed, the framework is becoming a real system; if not, the rest is polish on an unsafe control plane.
- AC4 (the advisory drift check) is what makes "single source of truth" enforceable rather than aspirational — REQUIRED, not stretch. A follow-up PR flips it strict once the policy is reconciled (advisory→strict ratchet, portability Check 18 precedent).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
