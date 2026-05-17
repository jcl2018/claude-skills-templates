---
name: "/CJ_goal_investigate zero-match draft capture + promote"
type: user-story
id: "S000055"
status: active
created: "2026-05-16"
updated: "2026-05-16"
parent: "F000024"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/youthful-volhard-114916"
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
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
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

- [x] `/CJ_goal_investigate "freshly observed bug"` with no canonical match creates `work-items/defects/.inbox/freshly_observed_bug/DRAFT.md` and proceeds into the pipeline (Row 1) — no D-ID allocated yet.
- [x] After `/investigate` populates a root cause and the Iron-Law gate passes, the draft is promoted to `work-items/defects/uncategorized/D000NNN_freshly_observed_bug/` with canonical TRACKER/RCA/test-plan, and `.inbox/freshly_observed_bug/` is removed.
- [x] If `/investigate` fails the Iron-Law gate, no promotion and no D-ID consumed; the draft remains and a re-invocation resumes it.
- [x] Verbatim re-invocation pre-promotion resolves the existing draft (no duplicate); post-promotion resolves the canonical dir.
- [x] The canonical resolver (`if`/`MATCHES`/`MATCH_COUNT` block) is byte-for-byte unchanged; drafts are never a canonical match.
- [x] Concurrent invocations don't race the D-ID counter (mkdir-lock around the highest-N scan + canonical mkdir in Step 7.4).
- [x] `--dry-run` on a zero-match fragment prints what it would create/resume/promote and exits 0 with `end_state=dry_run_preview` — no draft created.
- [x] Telemetry line for promoted runs includes `auto_scaffolded: true`.
- [x] C1 satisfied: Step 2 `pipeline.md:105-107` TRACKER/RCA_PATH/TEST_PLAN_PATH recompute is wrapped in `if [ "${IS_DRAFT:-0}" != "1" ]; then … fi`; draft vars survive.
- [x] C2 satisfied: blank `$DEFECT_ID` never leaks — Step 5 dispatch prompt and every Step 7 halt `resume_cmd=` use `$DRAFT_FRAGMENT` when `IS_DRAFT=1`.
- [x] C3 satisfied: atomic promotion protocol — `DRAFT_OLD` captured first, canonical TRACKER written as the durable commit point before `rm -rf` of the draft, all inside the mkdir-lock.
- [x] C4 satisfied: lock-timeout halt writes a `[promote-lock-timeout]` journal entry + telemetry `end_state=halted_at_promote_lock_timeout` + the 13th end-state row in SKILL.md halt taxonomy.
- [x] C5 satisfied: resuming an existing draft echoes the stored `fragment:` from DRAFT.md; a v1.2 open question for draft-level partial-fix detection is recorded.
- [x] C6 satisfied: a one-line comment in the Step 2 `0)` body states the slug lowercasing is load-bearing for resolver isolation.
- [x] C7 satisfied: every non-happy transition (draft capture, draft resume, each Step 7 halt + the Step 7.4 lock-timeout, promotion, `--dry-run`) prints the pinned plain-English operator message to the terminal, not only the journal.
- [x] CJ_personal-workflow validator tolerates `auto_scaffolded` + `promoted_from_draft` frontmatter keys (verified before implementing; allowlist extended in same PR if strict).
- [x] SKILL.md frontmatter `version` bumped 1.0.0 → 1.1.0; "Not in scope" ad-hoc-bug line moved to a v1.1 feature line; description "deferred to v1.1" sentence updated.

## Todos

<!-- Actionable items for this story. -->

- [x] Prereq: verify CJ_personal-workflow validator pass-through for `auto_scaffolded` / `promoted_from_draft`; extend allowlist in same PR if strict, else no-op.
- [x] Step 2 `0)` rewrite — resolve-or-create draft; `IS_DRAFT=1`; `--dry-run` short-circuit; C6 lowercasing comment; canonical `if`/`MATCHES`/`MATCH_COUNT` block untouched.
- [x] Step 2 C1 guard — wrap `pipeline.md:105-107` TRACKER/RCA_PATH/TEST_PLAN_PATH recompute in `if [ "${IS_DRAFT:-0}" != "1" ]; then … fi`.
- [x] Step 3 short-circuit — `IS_DRAFT=1` → Row 1 by construction.
- [x] New Step 7.4 — promote under mkdir-lock after the Iron-Law gate; C3 atomic ordering; C4 lock-timeout bookkeeping; rebind `$DEFECT_*`; remove the consumed draft.
- [x] Step 5 + Step 7 C2 fixes — draft-aware `/investigate` dispatch prompt + fragment-based `resume_cmd=` on every halt.
- [x] Step 11 telemetry — `auto_scaffolded: true` on promoted runs.
- [x] C7 plain-English operator messages — terminal-printed on every non-happy transition.
- [x] SKILL.md — "Not in scope" → v1.1 feature; description update; `version: 1.0.0 → 1.1.0`; add `halted_at_promote_lock_timeout` as the 13th end-state in the halt-taxonomy table.
- [x] Test coverage — extend `scripts/test-resume-table.sh` per the 9 cases in TEST-SPEC.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-16: Created. /CJ_goal_investigate v1.1 — zero-match captures a non-canonical draft in `.inbox/`, promotes to a canonical D-ID dir only after /investigate passes the Iron-Law gate. Scaffolded by /CJ_scaffold-work-item from `~/.gstack/projects/jcl2018-portfolio/chjiang-main-design-20260516-133940.md`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_goal_investigate/pipeline.md` (Modified — `IS_DRAFT=0` init + Step 2 `0)` draft resolve-or-create body with C6 lowercasing comment + C7 capture/resume/dry-run messages; C1 `IS_DRAFT!=1` guard around the post-`case` TRACKER/RCA_PATH/TEST_PLAN_PATH recompute; Step 3 `IS_DRAFT=1`→Row 1 short-circuit; C2+C7 shared Step 7 halt contract; new Step 7.4 promotion under mkdir-lock with C3 atomic ordering + C4 lock-timeout bookkeeping + C7 promotion echo; Step 11 `auto_scaffolded` telemetry key; 13-end-state note)
- `skills/CJ_goal_investigate/SKILL.md` (Modified — `version: 1.0.0 → 1.1.0`; description rewritten (draft→promote, 13-state, "no D-ID without root cause"); "Out of scope" ad-hoc-bug line promoted to a v1.1 feature paragraph; 13th end-state `halted_at_promote_lock_timeout` row added to halt-taxonomy table; Error Handling table updated (zero-match no longer a halt; lock-timeout row added))
- `skills/CJ_goal_investigate/scripts/test-resume-table.sh` (Modified — appended S1-S10 + E4 structural contract assertions for C1-C7 + the 13th end-state; same grep-based doc-as-contract style as the existing 5-row check; PASS)
- `skills/CJ_personal-workflow/personal-artifact-manifests.json` (NOT modified — prereq resolved: the CJ_personal-workflow validator is pass-through on extra frontmatter keys per check.md Step 16 line 314 "Extra key: no flag (acceptable, work items accumulate fields)", so `auto_scaffolded` + `promoted_from_draft` on a promoted defect TRACKER need no allowlist change)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The premise gate chose the draft/inbox model over the original Approach D (direct canonical scaffold). Both /autoplan CEO voices independently flagged near-duplicate D-ID dirs polluting future resolution as the #1 6-month regret. The draft model bounds duplicate-fragment entropy to the non-canonical `.inbox/`, and strengthens Iron-Law: a D-ID is never spent on a rootcause-less defect.
- Resolver isolation is structural, not a filter the resolver opts into: draft dirs have no `D[0-9]{6}_` basename (excludes BASENAME_HITS) and contain `DRAFT.md` not `*_TRACKER.md` (excludes NAME_HITS). The slugifier's lowercasing is load-bearing (C6) — a future "preserve case" change would let `.inbox/D000099_*` collide with the case-sensitive `find -name "D000099_*"`.
- The canonical TRACKER write is the **durable commit point** (C3): once it exists, NAME_HITS resolves the canonical dir by fragment, so a crash after that point resumes correctly with no second D-ID. A crash before it leaves a harmless empty orphan dir that the highest-N scan still counts (next promotion gets N+1, not a duplicate).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-16 [decision] Premise gate: draft/inbox reframe chosen over /office-hours Approach D (direct canonical scaffold). Summary: USER DECISION at /autoplan Phase 1 premise gate; both CEO voices flagged dup-D-ID-dir entropy as the dominant 6-month regret. D-ID / canonical slug / domain are now minted only at promotion (moment of clarity), not at intake.
- 2026-05-16 [decision] C1-C7 pinned implementation contract is binding. Summary: /autoplan Phase 3 dual eng review (Claude + Codex) + DX dual review independently found the same gaps in the first-pass surface spec. C1 (Step 2:105-107 var-clobber), C2 (blank DEFECT_ID leak), C3 (duplicate-D-ID crash window), C4 (lock-timeout bookkeeping + 13th end-state), C5 (dirty-tree resume accepted limitation), C6 (slug lowercasing comment), C7 (plain-English terminal narration). Each is mechanical (one correct answer); not implementer's discretion.
- 2026-05-16 [decision] `--dry-run` correctness folded into v1.1 success criteria + C7. Summary: not scope creep — it is correctness of the new zero-match path being added; resolves the original plan's known-wrong `--dry-run` behavior for free.
- 2026-05-16 [impl-finding] PRE-IMPLEMENTATION PREREQUISITE (SPEC Open Q / Story #12) resolved BEFORE writing code: the CJ_personal-workflow validator is **pass-through** on extra frontmatter keys. check.md Step 16 line 314 states verbatim "Extra key: no flag (acceptable, work items accumulate fields)". Therefore `auto_scaffolded` + `promoted_from_draft` on a promoted defect TRACKER require **no `personal-artifact-manifests.json` change**. The pre-collected sensitive-surface approval for the manifest resolves to a no-op; the manifest was NOT modified. AC-12 satisfied without touching the sensitive surface.
- 2026-05-16 [impl-decision] C1-C7 implemented per the binding contract. C1: wrapped the post-`case` TRACKER/RCA_PATH/TEST_PLAN_PATH recompute (real pipeline.md lines, design-doc's "105-107") in `if [ "${IS_DRAFT:-0}" != "1" ]; then … fi`. C2: pinned the draft-aware `DEFECT_ID:` dispatch line + a shared "C2+C7 halt contract" block instructing the orchestrator-model to emit fragment-based `resume_cmd=` for all Step 7 halts when IS_DRAFT=1. C3: Step 7.4 atomic protocol — DRAFT_OLD captured first, canonical TRACKER written as the durable commit point BEFORE `rm -rf "$DRAFT_OLD"`, all inside the mkdir-lock. C4: lock-timeout path writes `[promote-lock-timeout]` journal + telemetry `end_state=halted_at_promote_lock_timeout` + the 13th SKILL.md taxonomy row + a C7 terminal block. C6: load-bearing-lowercasing comment in the 0) body. C7: pinned plain-English terminal messages on every non-happy transition (capture/resume/dry-run/halt/promotion).
- 2026-05-16 [impl-decision] C5 implemented as the accepted v1.1 limitation: the existing-draft branch echoes the stored `fragment:` from DRAFT.md (wrong-bug slug collision is operator-visible); draft-level partial-fix detection is recorded as v1.2 Open Q #6 in SPEC + DESIGN. No hard block on dirty-tree rerun (parity with the canonical R/F/P/M ladder's pre-RCA blind spot; /investigate self-checks git status).
- 2026-05-16 [impl] Modified 3 files: pipeline.md (Step 2 0) body + C1 guard + Step 3 short-circuit + C2/C7 halt contract + new Step 7.4 + Step 11 telemetry + 13-end-state note), SKILL.md (version 1.1.0 + description + v1.1 feature section + 13th end-state row + Error Handling table), scripts/test-resume-table.sh (S1-S10 + E4 contract assertions). personal-artifact-manifests.json untouched (validator pass-through). Canonical Step 2 if/MATCHES/MATCH_COUNT block byte-for-byte unchanged. All 10 pipeline.md bash blocks pass `bash -n`; test-resume-table.sh PASS; sibling test-dry-run.sh / test-halt-journal.sh / test-rca-mapping.sh still PASS (no regression).
- 2026-05-16 [impl-pass] S000055: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated). QA-owned gates (Acceptance criteria verified met; Smoke tests pass) left for /CJ_qa-work-item.

- 2026-05-16 [qa-smoke] S1 (AC-1): green — test-resume-table.sh asserts the .inbox draft-dir creation replaces the v1.0 zero-match halt
- 2026-05-16 [qa-smoke] S2 (AC-2, AC-7): green — test-resume-table.sh asserts the draft-resume branch echoes the stored fragment (C5)
- 2026-05-16 [qa-smoke] S3 (AC-3): green — test-resume-table.sh asserts the IS_DRAFT!=1 guard around the post-case TRACKER/RCA_PATH/TEST_PLAN_PATH recompute (C1)
- 2026-05-16 [qa-smoke] S4 (AC-4): green — test-resume-table.sh asserts the fragment-based resume_cmd for the draft halt path (C2)
- 2026-05-16 [qa-smoke] S5 (AC-5): green — test-resume-table.sh asserts DRAFT_OLD capture + canonical-TRACKER-before-rm ordering (C3 durable commit point)
- 2026-05-16 [qa-smoke] S6 (AC-5): green — test-resume-table.sh asserts the mkdir-based D-ID allocation lock (C3 crash-window closed)
- 2026-05-16 [qa-smoke] S7 (AC-10): green — test-resume-table.sh asserts the pinned C7 --dry-run no-side-effects message
- 2026-05-16 [qa-smoke] S8 (AC-6): green — test-resume-table.sh asserts [promote-lock-timeout] journal + halted_at_promote_lock_timeout in SKILL.md (C4 13th end-state)
- 2026-05-16 [qa-smoke] S9 (AC-8): green — test-resume-table.sh asserts the load-bearing slug-lowercasing comment (C6)
- 2026-05-16 [qa-smoke] S10 (AC-12): green — a structurally complete defect fixture carrying auto_scaffolded + promoted_from_draft frontmatter passes ./scripts/validate.sh with zero DRIFT/VIOLATION on those keys (validator pass-through confirmed; ephemeral fixture cleaned up)
- 2026-05-16 [qa-smoke-summary] green: 10/10 non-manual rows green (0 manual rows pending)

- 2026-05-16 [qa-e2e-run-start] RUN_ID=20260516-144800-45827 commit=0fd30f0

- 2026-05-16 [qa-e2e] E1 (AC-1, AC-2, AC-7): green — pipeline.md 0) body has the draft-create branch (mkdir+DRAFT.md+C7 capture msg, lines ~132/136/150), the resume branch (-d $DRAFT_DIR + stored-fragment echo + C7 resume msg, ~125/130), deterministic DRAFT_DIR=$INBOX/$SLUG (~110, no timestamp → same fragment resolves the same draft, no dup), and Step 3 IS_DRAFT=1→Row 1 (~211). Verified by contract inspection of pipeline.md; full runtime exec needs the recursive /investigate-via-Agent chain (Agent tool unavailable this env). [parent-inline]
- 2026-05-16 [qa-e2e] E2 (AC-2, AC-11): green — Step 7.4 is gated after the Iron-Law pass (pipeline.md ~546/549); promotion does D-ID alloc + CANON_DIR + canonical TRACKER (durable commit point) + C7 promotion echo (~626/629/676); Step 11 telemetry adds auto_scaffolded via $([ IS_DRAFT=1 ]) (~768/769). Contract-inspection verified; runtime exec needs Agent. [parent-inline]
- 2026-05-16 [qa-e2e] E3 (AC-3): green — Halt 3 [investigate-no-root-cause] Iron-Law gate intact (pipeline.md ~510); the shared C2+C7 halt contract emits resume_cmd=/CJ_goal_investigate "$DRAFT_FRAGMENT" + a "draft retained …, no D-ID consumed" 3-line terminal block when IS_DRAFT=1 (~445/460); Step 7.4 is guarded by IS_DRAFT=1 and Step 7 exits 1 before it, so an Iron-Law-failed draft never promotes / never consumes a D-ID. Contract-inspection verified. [parent-inline]
- 2026-05-16 [qa-e2e] E4 (AC-9, AC-13): green — SKILL.md frontmatter version: 1.1.0 (line 4); the ad-hoc-bug line is a v1.1 feature paragraph with 0 stale "Out of scope (v2.0)" occurrences; the 13th end-state halted_at_promote_lock_timeout row is in the halt-taxonomy table (line ~189); 7 C7 plain-English terminal messages (capture/resume/promotion/dry-run/halt-block) are present so the non-happy transitions are legible without reading pipeline.md. Directly verified (read-only doc + structural inspection). [parent-inline]
- 2026-05-16 [qa-e2e-summary] green (0s subagent; 4 rows parent-inline; 0 deferred): All 4 E2E criteria green. E1-E3 verified by pipeline.md contract inspection (full recursive /investigate-via-Agent runtime unavailable this env — same doc-as-contract model as the existing test harness); E4 verified directly. Tracker journal updated.

- 2026-05-16 [qa-pass] S000055 (user-story): green smoke (10/10) + green E2E (4/4). Phase 2 gates transitioned.

- 2026-05-16 [auto-final-gate-suppressed] 1 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
