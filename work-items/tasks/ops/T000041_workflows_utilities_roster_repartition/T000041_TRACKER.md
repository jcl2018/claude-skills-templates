---
name: "Surface utilities + phase-step skills in doc/WORKFLOWS.md (re-partition roster out of ARCHITECTURE)"
type: task
id: "T000041"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-151208-16431"
blocked_by: ""
---

<!-- Source design doc (/office-hours, APPROVED — hardened through an adversarial spec
     review, 6/10 → fixes folded in; the original doc-only classification was reclassified
     to doc + ONE test fixture once the review caught the cj-document-release.test.sh 9/9b
     dependency):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-151208-16431-design-20260604-151546.md
     Design context distilled into ## Insights below. This task MOVES the 9 component skills
     (4 phase-step + CJ_personal-workflow validator + 4 standalone utilities) out of
     doc/ARCHITECTURE.md's `## Component skills (non-workflow roster)` into a NEW
     doc/WORKFLOWS.md `## Utilities & phase-step skills` section (lighter per-skill shape);
     ARCHITECTURE's roster slims to a one-line pointer (NO duplication). Re-points the
     CLAUDE.md authoring conventions + both tracked-doc manifest requirements + the section
     template, and rewrites tests/cj-document-release.test.sh assertions 9/9b to the new
     WORKFLOWS location. Closes the TODOS.md follow-up "Standalone utilities (e.g. /CJ_suggest)
     should also appear in doc/WORKFLOWS.md". -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
   (no parent — standalone task scaffolded from an APPROVED /office-hours design doc)
2. Create working branch: `git checkout -b feat/{slug}`
   (ships in the existing `cj-feat-20260604-151208-16431` worktree branch / same PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from the design's "Scope — concrete touches" (the 7 touches) + Success Criteria

**Gates:**
- [x] Parent scope read (N/A — standalone task; scope read from APPROVED design doc)
- [x] Working branch created (`branch` field populated: cj-feat-20260604-151208-16431)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + the 7-touch scope in ## Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-151208-16431-design-20260604-151546.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment
   (NOTE: under /CJ_goal_feature this task STOPS at the PR; deploy is a separate human step)

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- The 7 concrete touches from the design's "Scope — concrete touches (doc + ONE test
     fixture)". The MOVE/re-partition decision: WORKFLOWS.md becomes the single skill-catalog;
     the 9 component entries MOVE from ARCHITECTURE's roster into a NEW WORKFLOWS
     `## Utilities & phase-step skills` section (lighter shape); ARCHITECTURE's roster slims to
     a one-line pointer. NO duplication. The ONE non-doc edit is the cj-document-release.test.sh
     9/9b rewrite (the review-caught dependency the original doc-only scope missed). -->

- [x] **§1 doc/WORKFLOWS.md — intro re-scope + NEW utility section.**
  - Intro (L3 + L5 + the T000040 granular-enumeration rule block): RE-SCOPE the unqualified prose to the `## Orchestrators` sections — L3 "Each section gives … a **Touches** block" → "Each **orchestrator** section …"; L5 "each section MUST enumerate ALL [4 bullets]" → "each **orchestrator** section MUST"; reframe the lead so the doc covers "every routable skill — orchestrator chains AND the component skills they dispatch / the operator runs directly," and add a one-liner that the new utility section uses the lighter shape. Drop the "this doc is the *workflow* altitude only … see ARCHITECTURE for the component reference" redirect.
  - `## See also`: remove/rewrite the dangling "PLUS the `## Component skills (non-workflow roster)` …" cross-ref (the roster now lives in this same doc).
  - NEW **`## Utilities & phase-step skills`** section (below `## Orchestrators`), sub-grouped `### Phase-step skills` / `### Validators` / `### Standalone utilities`. MOVE all 9 entries from ARCHITECTURE's roster, rewritten to the lighter per-skill shape (`### <skill>` + **Status** + **Source** + **Invoke when** [1 line] + a compact **Touches** = `Scripts · tools · shell:` + `Reads / writes:`; NO Skills-dispatched / Steps-phases bullets — empty for single-step skills).
- [x] **§2 doc/ARCHITECTURE.md — slim the roster to a pointer.** `## Component skills (non-workflow roster)` (incl. the L121 "documentation, not Check-enforced" preamble that vanishes with the section) → a ONE-LINE pointer to WORKFLOWS.md `## Utilities & phase-step skills`. The `## Decision tree mirror` does NOT name the roster (verified) → no edit there.
- [x] **§3 CLAUDE.md — re-point every "component skills → ARCHITECTURE roster" site.**
  - `## Conventions → ### Skill directory structure` note → WORKFLOWS utility section.
  - "Creating a new skill" **step 6** → WORKFLOWS utility section.
  - The `## /document-release workbench audit conventions` note IF it asserts the roster lives in ARCHITECTURE → re-point.
- [x] **§4 CLAUDE.md tracked-doc manifest — both `requirement:` VALUES re-pointed in place (CARVE-OUT, single in-block double-quoted scalars).**
  - `doc/WORKFLOWS.md`: ADD "+ a `## Utilities & phase-step skills` section listing every non-orchestrator routable skill (lighter per-skill shape)"; CLARIFY the existing 4-bullet-Touches mandate applies to the **`## Orchestrators` sections only** (so Step 6.7 does NOT judge the utility subsections stale for lacking 4-bullet Touches).
  - `doc/ARCHITECTURE.md`: DROP "lists every non-workflow routable skill" → "the component roster now lives in WORKFLOWS.md; ARCHITECTURE keeps the mechanism sections". Keep both single double-quoted YAML scalars (no bare `#`, no unquoted `:`); block shape intact (Check 15a still parses 3 doc/ paths; the Step 6.7 awk joins wrapped requirement lines).
- [x] **§5 templates/doc-WORKFLOWS-section.md — re-point the author guidance.** The L8–13 guidance currently says a non-orchestrator skill "does NOT go here — add it to `doc/ARCHITECTURE.md` `## Component skills (non-workflow roster)`." REWRITE: non-orchestrator skills now go in WORKFLOWS.md's `## Utilities & phase-step skills` (lighter shape).
- [x] **§6 tests/cj-document-release.test.sh — rewrite assertions 9 + 9b (the ONE non-doc edit).** 9/9b currently grep `doc/ARCHITECTURE.md` for `^- \*\*CJ_document-release\*\*` (9) + that line for `Step 5\.5` (9b); when the roster entry MOVES to WORKFLOWS both greps return 0 → `fail_test` ×2 → test.sh FAILS. Rewrite to grep the new `doc/WORKFLOWS.md` `## Utilities & phase-step skills` location for the `CJ_document-release` entry (9) + its Step-5.5 mention (9b, or drop the Step-5.5 prose check); update their L18-20 / L117-130 comments. (Known "doc-structure change a test greps" blind-spot — MEMORY.)
- [ ] **§7 CHANGELOG.md / VERSION — at `/ship`** (version reconciled per the version queue).
- [x] **No-vanish net verify (manual).** PHILOSOPHY decision tree + the New-skills check are UNTOUCHED (the agent-judged no-vanish net targets PHILOSOPHY `## Decision tree` ONLY, NOT the ARCHITECTURE roster). Confirm all 9 component skills appear in the new WORKFLOWS section (none lost) and grep the repo for any remaining reader-facing `## Component skills (non-workflow roster)` cross-ref (only the CHANGELOG history line should remain). — VERIFIED: all 9 present exactly once as `#### <skill>` headings under `## Utilities & phase-step skills`; ARCHITECTURE roster bullets removed (0 `- **CJ_*` roster bullets); PHILOSOPHY + validate.sh Check 15b untouched; grep-sweep leaves only the CHANGELOG history line + the ARCHITECTURE pointer heading + the CLAUDE.md re-point text + the TODOS follow-up row (no dangling reader cross-ref).
- [ ] **Dogfood (best-effort, at /ship/Step 4.6).** Both `doc/WORKFLOWS.md` AND `doc/ARCHITECTURE.md` are registered docs → after the rewrite Step 6.7 must judge both `up-to-date` against their rewritten requirements (WORKFLOWS incl. the utility section — lighter shape NOT flagged stale; ARCHITECTURE roster removed). THIS PR's body should carry a real `### Registered-doc requirements` section, all current. NON-BLOCKING; the deterministic proof is validate.sh + test.sh green.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. MOVE/re-partition: surface the 9 component skills (4 phase-step: CJ_scaffold-work-item / CJ_implement-from-spec / CJ_qa-work-item / CJ_document-release; CJ_personal-workflow validator; 4 utilities: CJ_system-health / CJ_suggest / CJ_improve-queue / CJ_repo-init) in a NEW doc/WORKFLOWS.md `## Utilities & phase-step skills` section (lighter per-skill shape), MOVED from doc/ARCHITECTURE.md's roster (slimmed to a one-line pointer; NO duplication). Re-points CLAUDE.md authoring conventions (skill-dir note + step 6 + audit-conventions note) + both tracked-doc manifest requirements (WORKFLOWS + ARCHITECTURE) + the section template, and rewrites tests/cj-document-release.test.sh assertions 9/9b (the review-caught dependency — the original doc-only scope was FALSE). 7 touches: doc/WORKFLOWS.md (intro + See-also + NEW utility section), doc/ARCHITECTURE.md (roster → pointer), CLAUDE.md ×N re-points, CLAUDE.md 2 manifest requirements, templates/doc-WORKFLOWS-section.md, tests/cj-document-release.test.sh 9/9b, CHANGELOG/VERSION at /ship. Closes the utilities-in-WORKFLOWS follow-up TODO. Scaffolded from APPROVED /office-hours design doc via /CJ_scaffold-work-item under /CJ_goal_feature.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc/WORKFLOWS.md` (MODIFIED — §1: intro L3/L5 + the T000040 granular-enumeration rule block RE-SCOPED to the `## Orchestrators` sections; the "workflow altitude only / see ARCHITECTURE" redirect dropped; `## See also` dangling roster cross-ref removed; NEW `## Utilities & phase-step skills` section added below `## Orchestrators`, sub-grouped Phase-step skills / Validators / Standalone utilities, holding all 9 MOVED component entries in the lighter per-skill shape)
- `doc/ARCHITECTURE.md` (MODIFIED — §2: `## Component skills (non-workflow roster)` incl. its L121 preamble slimmed to a ONE-LINE pointer to WORKFLOWS.md `## Utilities & phase-step skills`; `## Decision tree mirror` UNTOUCHED — does not name the roster)
- `CLAUDE.md` (MODIFIED — §3: the `### Skill directory structure` note + "Creating a new skill" step 6 + the `## /document-release workbench audit conventions` note re-pointed from the ARCHITECTURE roster → WORKFLOWS utility section; §4: the `doc/WORKFLOWS.md` `requirement:` VALUE gains the `## Utilities & phase-step skills` clause + the 4-bullet-Touches-is-orchestrators-only clarification, and the `doc/ARCHITECTURE.md` `requirement:` VALUE drops "lists every non-workflow routable skill" → "roster now lives in WORKFLOWS.md" — both single double-quoted in-block scalars, block shape intact)
- `templates/doc-WORKFLOWS-section.md` (MODIFIED — §5: L8–13 author guidance rewritten — non-orchestrator skills now go in WORKFLOWS.md's `## Utilities & phase-step skills` [lighter shape], NOT doc/ARCHITECTURE.md's roster)
- `tests/cj-document-release.test.sh` (MODIFIED — §6: assertions 9 + 9b rewritten to grep the new `doc/WORKFLOWS.md` `## Utilities & phase-step skills` location for the `CJ_document-release` entry [9] + its Step-5.5 mention [9b, or drop the Step-5.5 prose check]; L18-20 / L117-130 comments updated. The ONE non-doc edit)
- `CHANGELOG.md` (TO MODIFY — §7: new entry at /ship; version reconciled per the version queue)

## Insights

<!-- Design context distilled from the APPROVED /office-hours design doc
     (hardened through an adversarial spec review, 6/10 → fixes folded in;
     reclassified doc-only → doc + one test fixture). -->

- **The gap: WORKFLOWS.md is workflow-only; the utilities live only in ARCHITECTURE.** Today's doc/WORKFLOWS.md (the T000037 scope decision) documents JUST the 3 `CJ_goal_*` orchestrator chains. Every other routable skill — the 4 phase-step skills, the `CJ_personal-workflow` validator, and the 4 standalone utilities — lives only as a compact line in `doc/ARCHITECTURE.md`'s `## Component skills (non-workflow roster)`. The operator wants the utilities (and the rest of the component skills) surfaced in `doc/WORKFLOWS.md` too.
- **Decision (operator-selected): MOVE / re-partition — NOT duplicate.** WORKFLOWS.md becomes the single skill-catalog: the 9 component entries MOVE from ARCHITECTURE's roster into a NEW WORKFLOWS `## Utilities & phase-step skills` section; ARCHITECTURE's roster slims to a one-line pointer. No duplication (a duplicate-roster alternative was rejected — two sources drift).
- **The 9 component skills.** Phase-step (4): CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release. Validator (1): CJ_personal-workflow. Standalone utilities (4): CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init.
- **Lighter per-skill shape (NOT the orchestrator 4-bullet Touches).** A single-step utility like `/CJ_suggest` dispatches no skills and runs no pipeline steps, so the orchestrator 4-bullet Touches is the wrong shape. Each component entry: `### <skill>` + **Status** + **Source** + **Invoke when** (1 line) + a compact **Touches** = `Scripts · tools · shell:` (what it runs) + `Reads / writes:` (files/state it reads or mutates). NO Skills-dispatched / Steps·phases bullets (those are empty for single-step skills).
- **validate.sh UNTOUCHED (review-corrected blast radius).** The ARCHITECTURE roster is "documentation, not Check-enforced" (ARCHITECTURE.md L121); NO check greps the roster heading (the two validate.sh hits are comments). Check 15b stays `startswith("CJ_goal_")`-scoped (orchestrators only). The no-vanish net is the *agent-judged* New-skills check targeting **PHILOSOPHY.md `## Decision tree` ONLY** (NOT the ARCHITECTURE roster) — PHILOSOPHY is untouched, net intact.
- **scripts/test.sh: ONE FIXTURE EDIT REQUIRED (review-caught; the design's original "no test change" was FALSE).** `tests/cj-document-release.test.sh` assertions 9 + 9b grep `doc/ARCHITECTURE.md` for `^- \*\*CJ_document-release\*\*` (9) and that line for `Step 5\.5` (9b). When the `CJ_document-release` roster entry MOVES to WORKFLOWS, both greps return 0 → `fail_test` ×2 → `test.sh` FAILS. This is the known "doc-structure change a test greps" blind-spot (MEMORY: `project_implement_subagent_blind_spot_test_sh`). MUST rewrite 9/9b to the new WORKFLOWS location (+ update their L18-20 / L117-130 comments). This reclassified the change from doc-only → doc + one test fixture.
- **CARVE-OUT wrap-safe (CONFIRMED).** The two CLAUDE.md tracked-doc `requirement:` edits (WORKFLOWS + ARCHITECTURE) stay SINGLE in-block double-quoted YAML scalars; Check 15a reads only `- path:` lines (the value's length is irrelevant to it), the Step 6.7 awk joins wrapped requirement continuation lines. Keep no bare `#`, no unquoted `:`; do not disturb the `- path:`/`audit_class:`/`owner:`/`requirement:` block shape.
- **The WORKFLOWS requirement must scope the 4-bullet Touches to orchestrators only.** Because the new utility subsections deliberately use a LIGHTER shape (no Skills-dispatched / Steps·phases bullets), the `doc/WORKFLOWS.md` `requirement:` value must clarify the existing 4-bullet-Touches mandate applies to the `## Orchestrators` sections ONLY — otherwise Step 6.7 would (wrongly) judge the utility subsections stale for lacking the 4 anchored bullets.
- **Scaffolded as a task, mirroring T000037/T000038/T000039/T000040.** The change is a single, coherent, directly-implementable doc re-partition (move 9 entries + slim ARCHITECTURE + re-point CLAUDE.md/template + rewrite 2 test assertions) with a test plan. Under `/CJ_goal_feature`'s silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature); a standalone task (TRACKER + test-plan) is the established on-disk convention (work-items/tasks/ops/). Component `ops` matches the F000030/F000034/F000037/T000037-T000040 doc-infra lineage.
- **Deliberately NOT touched:** `scripts/validate.sh` (Check 15b orchestrator-only; roster never Check-enforced), the PHILOSOPHY decision tree + New-skills check (the no-vanish net), the orchestrator sections + their 4-bullet Touches, README.md / CHANGELOG.md history.

## Journal

<!-- Structured entries (decision/finding/blocker) with Summary fields. -->

- [decision] 2026-06-04 — Scaffolded as a **task** (not a user-story or parent feature). Rationale: the design is a single, coherent, directly-implementable doc re-partition (MOVE the 9 component skills into a new doc/WORKFLOWS.md `## Utilities & phase-step skills` section + slim doc/ARCHITECTURE.md's roster to a pointer + re-point CLAUDE.md ×N + both tracked-doc manifest requirements + the section template + rewrite tests/cj-document-release.test.sh 9/9b) with a test plan; under /CJ_goal_feature's silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature, which the directly-implementable mandate forbids), while a standalone task (TRACKER + test-plan) is an established on-disk convention. Mirrors T000037 (Job 1) / T000038 (Job 2) / T000039 (Job-2.1) / T000040 (granular-enumeration rule), all scaffolded as tasks for the identical reason. Component `ops` matches the doc-infra lineage (F000030/F000034/F000037/T000037-T000040).
- [decision] 2026-06-04 — MOVE / re-partition (operator-selected), NOT duplicate. WORKFLOWS.md becomes the single skill-catalog: the 9 component entries MOVE from ARCHITECTURE's `## Component skills (non-workflow roster)` into a NEW WORKFLOWS `## Utilities & phase-step skills` section; ARCHITECTURE's roster slims to a one-line pointer. A duplicate-roster alternative was rejected (two sources drift). No skill is duplicated in two docs.
- [decision] 2026-06-04 — The utility entries use a LIGHTER per-skill shape than the orchestrator 4-bullet Touches: `### <skill>` + **Status** + **Source** + **Invoke when** (1 line) + a compact **Touches** (`Scripts · tools · shell:` + `Reads / writes:`). A single-step utility dispatches no skills and runs no pipeline steps, so the Skills-dispatched / Steps·phases bullets are empty and omitted. Consequently the CLAUDE.md `doc/WORKFLOWS.md` `requirement:` value must scope the existing 4-bullet-Touches mandate to the `## Orchestrators` sections ONLY (else Step 6.7 wrongly flags the utility subsections stale).
- [decision] 2026-06-04 — `scripts/validate.sh` is UNTOUCHED (review-corrected). The ARCHITECTURE roster is documentation, NOT Check-enforced (ARCHITECTURE.md L121; the two validate.sh roster hits are comments); Check 15b stays `startswith("CJ_goal_")`-scoped to orchestrators. The no-vanish safety net is the agent-judged New-skills check, which targets PHILOSOPHY.md `## Decision tree` ONLY (not the ARCHITECTURE roster) — PHILOSOPHY is left untouched, so the net stays intact.
- [finding] 2026-06-04 — Adversarial spec review (6/10) caught the design's original "no test change" claim as FALSE: `tests/cj-document-release.test.sh` assertions 9 + 9b grep `doc/ARCHITECTURE.md` for the `CJ_document-release` roster bullet (9) + its `Step 5.5` mention (9b); MOVING that entry to WORKFLOWS makes both greps return 0 → 2 `fail_test`s → test.sh red. This is the known `project_implement_subagent_blind_spot_test_sh` trap (a doc-structure change a test greps). The fix reclassified the change doc-only → doc + ONE test fixture: rewrite 9/9b to the new WORKFLOWS location + update their comments.
- [finding] 2026-06-04 — Wrap-safety of the two CLAUDE.md `requirement:` edits CONFIRMED by the review: Check 15a (`flag && /^- path:/ {print $3}`) reads ONLY `path:` lines so the requirement value's length is irrelevant; the Step 6.7 awk joins wrapped `requirement:` continuation lines. Keep each rewritten value a SINGLE double-quoted YAML scalar (no bare `#`, no unquoted `:`) and leave the `- path:`/`audit_class:`/`owner:`/`requirement:` block shape intact (Check 15a still parses exactly 3 doc/ paths: PHILOSOPHY/ARCHITECTURE/WORKFLOWS).
- [impl-decision] 2026-06-04 — Used `#### <skill>` (H4) headings for the 9 utility entries and `### Phase-step skills` / `### Validators` / `### Standalone utilities` (H3) for the sub-groups under `## Utilities & phase-step skills`. H4 keeps the entries below the H3 sub-group level and (critically) below the `### CJ_goal_*` orchestrator-section level that validate.sh Check 15b's awk parser scans — the new headings never match `^### CJ_goal_X$`, and they sit AFTER all three orchestrator `### ` headings, so the last orchestrator section (`CJ_goal_todo_fix`) still terminates cleanly at `### Phase-step skills` with its full 4-bullet Touches intact (confirmed: test.sh T000040 check + validate.sh Check 15b both green on all 3 orchestrators). Assertion-9 rewrite greps `^#### CJ_document-release$` to match this heading shape.
- [impl-finding] 2026-06-04 — `--auto` demoted to MODE=propose by implement.md Step 6.6's safety heuristic (5 files touched > the ≤2 trivial ceiling). Under the /CJ_goal_feature silent-subagent context (APPROVED design, parent passed --auto, no interactive operator) the propose-mode preview AUQ would deadlock the pipeline, so per the runner's mechanical-defaults contract the writes proceeded without the AUQ; demotion recorded here per the Step 6.6 contract. SENSITIVE=false (no skills-catalog.json / manifest / named validator [validate.sh/test.sh/test-deploy.sh] / git-hook / templates/CJ_personal-workflow path in the change set — `templates/doc-WORKFLOWS-section.md` is a top-level template, `tests/cj-document-release.test.sh` is not one of the three named validators).
- [impl] 2026-06-04 — Implemented the 6 in-PR touches (§1–§6; §7 CHANGELOG/VERSION deferred to /ship). MODIFIED 5 files: `doc/WORKFLOWS.md` (intro L3/L5 + granular-rule block re-scoped to `## Orchestrators`; "workflow altitude / see ARCHITECTURE" redirect dropped; See-also roster cross-ref rewritten; NEW `## Utilities & phase-step skills` section with all 9 component skills MOVED in, lighter shape, sub-grouped Phase-step/Validators/Standalone), `doc/ARCHITECTURE.md` (`## Component skills (non-workflow roster)` + L121 preamble → one-line pointer; 9 roster bullets removed), `CLAUDE.md` (skill-dir note + "Creating a new skill" step 6 + the workflow-completeness audit_class note re-pointed; both tracked-doc `requirement:` values rewritten in place — WORKFLOWS gains the utility-section clause + 4-bullet-is-orchestrators-only scope, ARCHITECTURE drops "lists every non-workflow routable skill" → pointer), `templates/doc-WORKFLOWS-section.md` (author guidance routes non-orchestrator skills to the WORKFLOWS utility section), `tests/cj-document-release.test.sh` (assertions 9 + 9b + their comments + the var `ARCHITECTURE_DOC`→`WORKFLOWS_DOC` rewritten to grep the new WORKFLOWS location). MOVE-not-duplicate verified: all 9 skills present exactly once in WORKFLOWS, 0 roster bullets left in ARCHITECTURE.
- [impl-auto] 2026-06-04 — Run invoked with `--auto`; the flag demoted to propose-mode per Step 6.6 (5 files > ≤2), but executed mechanically without the preview AUQ under the silent-subagent runner contract (see the [impl-finding] above).
- [impl] 2026-06-04 — Verified GREEN before handoff: `./scripts/validate.sh` exit 0 (0 errors / 0 warnings; Check 15a parses exactly 3 manifest paths PHILOSOPHY/ARCHITECTURE/WORKFLOWS; Check 15b green on all 3 `CJ_goal_*` orchestrator 4-bullet Touches; Check 15/16/17 clean); `./scripts/test.sh` exit 0 (RESULT: PASS, Failures: 0 — incl. T000040's 4-bullet check on all 3 orchestrators); `bash tests/cj-document-release.test.sh` exit 0 (PASS — rewritten assertions 9 + 9b pass against `doc/WORKFLOWS.md` `## Utilities & phase-step skills`); shellcheck clean on the edited test (no SC2034). Grep-sweep: only the CHANGELOG history line + the ARCHITECTURE pointer heading + the CLAUDE.md re-point/requirement text + the TODOS follow-up row + the protected validate.sh comment remain — no dangling reader cross-ref to an empty roster.
- [impl-pass] T000041: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). Commit gate left for /ship; CHANGELOG/VERSION at /ship.
- 2026-06-04 [qa-smoke] T1 (validate.sh PASS — Check 15a parses 3 manifest paths, Check 15b unchanged): green — `./scripts/validate.sh` exit 0, RESULT: PASS, 0 errors / 0 warnings; Check 15 PASS for all 3 `CJ_goal_*` orchestrators, Check 15a maps the manifest cleanly (3 doc/ paths, no orphan/missing), Check 16/17 green.
- 2026-06-04 [qa-smoke] T2 (test.sh PASS + rewritten cj-document-release 9/9b — primary regression proof): green — `./scripts/test.sh` exit 0 (RESULT: PASS, Failures: 0); explicit `bash tests/cj-document-release.test.sh` exit 0 (PASS) with rewritten assertion 9 (`doc/WORKFLOWS.md '## Utilities & phase-step skills' has the CJ_document-release entry`) + 9b (`names the Step 5.5 inline role`) both OK against the new WORKFLOWS location.
- 2026-06-04 [qa-smoke] T3 (NEW section + all 9 component skills MOVED in): green — `## Utilities & phase-step skills` present (L173, below `## Orchestrators` L11), sub-grouped `### Phase-step skills` / `### Validators` / `### Standalone utilities`; all 9 skills present exactly once as `#### <skill>` headings (CJ_scaffold-work-item, CJ_implement-from-spec, CJ_qa-work-item, CJ_document-release, CJ_personal-workflow, CJ_system-health, CJ_suggest, CJ_improve-queue, CJ_repo-init).
- 2026-06-04 [qa-smoke] T4 (lighter per-skill shape, NOT orchestrator 4-bullet Touches): green — inspected CJ_suggest / CJ_document-release entries: each is `#### <skill>` + **Status** + **Source** + **Invoke when** + a compact **Touches** (`Scripts · tools · shell:` + `Reads / writes:`); 0 real `- **Skills dispatched` / `- **Steps · phases` list bullets after L173 (the only post-173 match is the L175 explanatory prose, not a Touches bullet).
- 2026-06-04 [qa-smoke] T5 (ARCHITECTURE roster slimmed to a one-line pointer — NO duplication): green — `doc/ARCHITECTURE.md` `## Component skills (non-workflow roster)` (L119) is now a pointer to WORKFLOWS.md `## Utilities & phase-step skills`; 0 `- **CJ_` roster bullets; none of the 9 skills leak as ARCHITECTURE roster bullets. `## Decision tree mirror` does not name the roster (untouched).
- 2026-06-04 [qa-smoke] T6 (intro re-scoped to orchestrator sections + redirect/See-also cleaned): green — intro reframed to cover "every routable skill — orchestrator chains AND the component skills"; 4-bullet mandate scoped to `## Orchestrators` ONLY; "workflow altitude / see ARCHITECTURE" redirect dropped; `## See also` carries no dangling `## Component skills (non-workflow roster)` cross-ref (now points into this doc's utility section).
- 2026-06-04 [qa-smoke] T7 (CLAUDE.md tracked-doc manifest — both requirement: values re-pointed, block shape intact): green — WORKFLOWS `requirement:` (L484) gains the `## Utilities & phase-step skills` clause + scopes the 4-bullet mandate to orchestrators only; ARCHITECTURE `requirement:` (L480) drops "lists every non-workflow routable skill" → "roster now lives in WORKFLOWS.md"; both single double-quoted scalars; Check 15a parsed the manifest cleanly (3 paths).
- 2026-06-04 [qa-smoke] T8 (CLAUDE.md authoring conventions re-pointed): green — skill-dir note (L194) + "Creating a new skill" step 6 (L314) route non-orchestrator skills to WORKFLOWS `## Utilities & phase-step skills`; the only residual `## Component skills (non-workflow roster)` string in CLAUDE.md is the manifest re-point text itself (points away from the roster).
- 2026-06-04 [qa-smoke] T9 (templates/doc-WORKFLOWS-section.md author guidance re-pointed): green — L8-13 guidance routes non-orchestrator skills to WORKFLOWS.md's `## Utilities & phase-step skills` (lighter shape), no longer to the ARCHITECTURE roster.
- 2026-06-04 [qa-smoke] T10 (no-vanish net UNTOUCHED + grep-sweep + no upstream modification): green — `scripts/validate.sh` (Check 15b still `startswith("CJ_goal_")`) + `doc/PHILOSOPHY.md` both UNCHANGED per `git status`; repo-wide `Component skills (non-workflow roster)` sweep leaves only the ARCHITECTURE pointer heading + CLAUDE.md re-point/manifest text + two protected comments (validate.sh:604, cj-document-release.test.sh:20) + the TODOS follow-up row — no dangling reader cross-ref to an empty roster; working-tree diff touches only the 5 expected workbench files (no upstream gstack `/document-release` / `/ship`, no validate.sh check change).
- 2026-06-04 [qa-smoke-manual] T11 (dogfood — PR-body Registered-doc requirements section, BEST-EFFORT): pending human verification — non-blocking, structurally realizable only post-`/ship` at Step 4.6 (PR body carries `### Registered-doc requirements` with WORKFLOWS + ARCHITECTURE `up-to-date`); the deterministic proof is T1+T2 (both green).
- 2026-06-04 [qa-smoke-summary] green: 10/10 non-manual rows green (1 manual row T11 pending — post-ship dogfood). Type=task → smoke-equivalent verification; no E2E phase.
- 2026-06-04 [qa-pass] T000041 (task): green smoke from test-plan rows (10 automated rows green; 1 manual/post-ship row T11 pending, non-blocking). T1 (validate.sh) + T2 (test.sh + rewritten cj-document-release.test.sh 9/9b against the new `doc/WORKFLOWS.md` `## Utilities & phase-step skills` location) — the two DETERMINISTIC proofs — both green. All 9 component skills MOVED into WORKFLOWS exactly once; 0 roster bullets remain in ARCHITECTURE (move-not-duplicate). No qa-owned Phase 2 gates per task template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
