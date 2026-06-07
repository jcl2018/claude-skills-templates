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
receipts:
  qa:
    phase: 3
    commit: "abe0705f176b6b0eefdbf88247065b41800bbda8"   # QA-time HEAD (working tree; impl committed in the same PR immediately after)
    completed_at: "2026-06-07T06:43:50Z"
    test_rows_run: 7
    ac_ids_covered: [AC1, AC2, AC3, AC4]
    ac_ids_uncovered: []
    diff_audit:
      changed_files_without_tests: []
    journal_entries: ["[qa-e2e-summary] green (E1+E2+E3 PASS, independent inspection + drift injection)", "[qa-pass] S000094 green smoke + green E2E"]
    ready_for_ship: true
    next_legal: [ship]
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
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] AC1: one declared allow/ask/deny policy artifact exists, enumerating in-scope edits (allow), sensitive surfaces (ask), and risky verbs git-push-to-main / gh-pr-merge / rm / network (deny or ask).
- [x] AC2: the two LIVE enforcement points (`allowed-tools`, sensitive-surface AUQ) reference the policy; the dormant handoff-gate denylist derives from it.
- [x] AC3: a verb absent from the policy is treated as deny (design permission before capability).
- [x] AC4: an advisory `validate.sh` check flags drift between the policy and the enforcement points (advisory-first, like portability Check 18; a follow-up flips it strict once reconciled). REQUIRED, not stretch.

## Todos

<!-- Actionable items for this story. -->

- [x] Author the policy file (`permission-policy.md`, `doc-spec.md`-style: prose + a fenced machine-readable block) with the row schema `{verb, kind, mode ∈ allow|ask|deny, scope}`.
- [x] Write `scripts/permission-policy.sh` (awk parser: `--validate` / `--resolve <verb>` (absent ⇒ deny) / `--surface-globs` / `--deny-verbs`).
- [x] Add the policy reference to the 3 `skills/CJ_goal_*` SKILL.md (a `## Permission policy` pointer; the two live enforcement points).
- [x] Rewire `scripts/cj-handoff-gate.sh`'s denylist to DERIVE from `permission-policy.sh --surface-globs ask` (forward-looking — the gate is dormant).
- [x] Add the advisory `scripts/validate.sh` Check 21 drift check (advisory-first, exit 0; like portability Check 18) + register `permission-policy.md` in `doc-spec.md` (Check 17).
- [x] Added the parallel `scripts/test.sh` fixture in the SAME PR as Check 21 (repo convention).
- [x] Ran `/CJ_personal-workflow check`; `validate.sh` + `test.sh` green (windows Git-Bash job verified at /ship); PR-stop for human review.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-06: Created. Story 2 of F000053 (ship second). Closes GAP B (P5): permission is implicit and scattered across three unconnected places, only two live (`allowed-tools` = allow/live, sensitive-surface AUQ = ask/live, `cj-handoff-gate.sh` denylist = deny/DORMANT). Introduces ONE declared allow/ask/deny policy artifact the live enforcement points reference and the dormant denylist derives from, plus an advisory drift check.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `permission-policy.md` — NEW: the declared allow/ask/deny policy (prose + fenced yaml; rows `{verb, kind, mode, scope}`; absent verb ⇒ deny).
- `scripts/permission-policy.sh` — NEW: awk parser (`--validate` / `--resolve` / `--surface-globs` / `--deny-verbs`); mirrors `doc-spec.sh`.
- `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md` — MODIFIED: `## Permission policy` pointer (live points reference the policy).
- `scripts/cj-handoff-gate.sh` — MODIFIED: `DENYLIST_GLOBS` derives from `permission-policy.sh --surface-globs ask` (was a hand-list); parser-absent fallback + self-protection retained.
- `scripts/validate.sh` — MODIFIED: advisory Check 21 (policy parses; gate derives; 3 orchestrators reference it).
- `scripts/test.sh` — MODIFIED: F000053/S000094 permission-policy regression guards (parser + derivation + Check-21 wiring + fail-closed drift path).
- `doc-spec.md` — MODIFIED: registered `permission-policy.md` (section: custom, audit_class: operational) so root-doc Check 17 passes.

## Insights

<!-- Non-obvious findings worth remembering. -->

- The handoff-gate denylist is DORMANT: its consumers `/CJ_goal_auto` and `/CJ_goal_run` are deleted, so no current orchestrator invokes the gate (the live orchestrators cite it only rhetorically to justify PR-stop). Wiring it to derive from the policy is forward-looking correctness-if-reactivated, NOT a claim that it enforces anything today.
- Codex called the permission story "the tell": if one coherent allow/ask/deny contract the orchestrators, leaf skills, AND shell helpers can all honor can be expressed, the framework is becoming a real system; if not, the rest is polish on an unsafe control plane.
- AC4 (the advisory drift check) is what makes "single source of truth" enforceable rather than aspirational — REQUIRED, not stretch. A follow-up PR flips it strict once the policy is reconciled (advisory→strict ratchet, portability Check 18 precedent).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-06 [impl-decision] Policy schema = `{verb, kind (surface|op), mode (allow|ask|deny), scope}`. The `kind` field separates the ASK file-surfaces (the globs the handoff-gate derives from) from the DENY operation-verbs (push/merge/rm/network) — resolving the spec's "gate derives from the deny set" wrinkle: the gate guards FILE surfaces (= the ask globs), while the deny verbs are operation-level, already contained by the PR-stop + human-merge (the deny rows DECLARE that contract).
- 2026-06-06 [impl-decision] `cj-handoff-gate.sh` `DENYLIST_GLOBS` DERIVES from `permission-policy.sh --surface-globs ask` (broader category prefixes like `skills/`, `templates/` that still cover the old hand-list's specific dirs via the gate's prefix `case`), with a fallback when the parser is absent + always-include self-protection. Gate Test 1/3/5 still pass (they use `skills/CJ_personal-workflow/SKILL.md`, covered by `skills/`).
- 2026-06-06 [impl-decision] `permission-policy.md` is `audit_class: operational` (a machine-parsed root doc like `doc-spec.md`), registered in `doc-spec.md` to satisfy validate.sh Check 17.
- 2026-06-06 [impl] Wrote 2 new files (`permission-policy.md`, `scripts/permission-policy.sh`) + modified 6 (3 orchestrator SKILL.md, `cj-handoff-gate.sh`, `validate.sh` Check 21, `test.sh` fixture, `doc-spec.md`). propose-and-confirm mode; sensitive surfaces (validate.sh / test.sh / orchestrators / gate) approved via AUQ. `validate.sh` + `test.sh` green.
- 2026-06-06 [impl-pass] S000094: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-06 [qa-e2e-run-start] RUN_ID=20260606-234350-48290 commit=abe0705
- 2026-06-06 [qa-e2e] E1 PASS (independent inspection + drift injection): validate.sh Check 21 fires on all 3 drift vectors (policy-parse / gate-rehardcode / dropped-orchestrator-pointer) and stays advisory (exit 0, no ERRORS++); clean tree PASSes. AC4.
- 2026-06-06 [qa-e2e] E2 PASS (independent inspection): all 4 risky verbs (git-push-to-main/gh-pr-merge/rm/network-egress) are mode=deny in permission-policy.md; `--resolve <unlisted>` → deny (fail closed). AC1+AC3.
- 2026-06-06 [qa-e2e] E3 PASS (independent inspection): the 3 orchestrators each carry a `## Permission policy` section citing permission-policy.md (allow + ask points); cj-handoff-gate.sh derives DENYLIST_GLOBS from `permission-policy.sh --surface-globs ask` (11 globs, not the hand-list fallback). AC2.
- 2026-06-06 [qa-e2e-summary] green (independent inspection subagent ~140s; injected drift into throwaway copies to confirm Check 21 fires + stays advisory): all 3 E2E scenarios PASS.
- 2026-06-06 [qa-pass] S000094 (user-story): green smoke (permission-policy.sh --validate/--resolve/--surface-globs/--deny-verbs + the gate derivation + validate.sh Check 21 + full test.sh) + green E2E (E1+E2+E3 independent inspection). receipts.qa written (commit=abe0705, QA-time HEAD; impl committed in the same PR immediately after). Phase 2 QA-owned gates transitioned.
