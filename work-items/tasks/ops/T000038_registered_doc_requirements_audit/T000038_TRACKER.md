---
name: "Registered-doc requirements audit for /CJ_document-release (Job 2)"
type: task
id: "T000038"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-095407-47056"
blocked_by: ""
---

<!-- Source design doc (/office-hours, APPROVED — hardened through TWO adversarial reviews):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-095407-47056-design-20260604-100207.md
     Design context distilled into ## Insights below. This is Job 2 (the real
     "tighten /CJ_document-release" audit) of a two-job split; Job 1 (the doc/WORKFLOWS.md
     reorg) shipped as T000037 / v6.0.23 / PR #213. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
   (no parent — standalone task scaffolded from an APPROVED /office-hours design doc)
2. Create working branch: `git checkout -b feat/{slug}`
   (ships in the existing `cj-feat-20260604-095407-47056` worktree branch / same PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from the design's file-by-file plan (§1–§6) + Success Criteria

**Gates:**
- [x] Parent scope read (N/A — standalone task; scope read from APPROVED design doc)
- [x] Working branch created (`branch` field populated: cj-feat-20260604-095407-47056)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + the file-by-file plan in ## Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-095407-47056-design-20260604-100207.md`
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

<!-- The file-by-file plan from the design's "Recommended Approach" (Approach A —
     Lean-complete, wrapper-produced). Each group maps to a design section §N.
     LOAD-BEARING ordering: §1 (producer) + §1.5 (surfacing) are the feature;
     §2–§4 are the requirement data + docs it reads; §5 hygiene; §6 the proof. -->

- [ ] **§1 PRODUCER (load-bearing) — `skills/CJ_document-release/SKILL.md`.** Add a new ADVISORY **Step 6.7: Registered-doc requirements audit** on the green/green-noop TAIL of Step 6 (after the auto-commit RESULT print, so it runs only on the non-exiting path; it NEVER halts). The step: (a) **reads doc/ requirements** by parsing the CLAUDE.md `### Tracked doc/ files manifest` block, capturing each entry's `requirement:` value — which may WRAP to a continuation line, so read the FULL value, not just `$3` (review nit #5); (b) **enumerates skill MDs** via `jq -r '.[] | select(.status=="active") | select((.files|length)>0) | .name' skills-catalog.json`, reading each skill's optional `doc_requirement` (else the shared default); (c) **agent-judges** each registered doc (read doc + requirement + `git diff <base>...HEAD`) → one verdict line; (d) **EMITS** the grep-able `### Registered-doc requirements` block to the wrapper RESULT **AND writes it to a gitignored scratch file** `"$_REPO_ROOT/.cj-goal-feature/registered-doc-verdicts.md"`. Verdict taxonomy: `up-to-date` / `stale: <why>` / `missing-requirement` / `n/a`; positive line `Registered-doc requirements: all current` ONLY when every verdict is up-to-date. `missing-requirement` is a soft verdict, never a halt.
- [ ] **§1.5 SURFACING (D4=A) — `skills/CJ_goal_feature/pipeline.md`.** After Step 4 (`/ship` opens the PR, PR# captured), add **Step 4.6: surface registered-doc verdicts** — read the scratch file `.cj-goal-feature/registered-doc-verdicts.md` (written by §1 at Step 5.5) and `gh pr edit <PR#>` to insert-or-replace a `### Registered-doc requirements` subsection under the PR body's `## Documentation` section. Idempotent (replace-if-present). Best-effort: a failed `gh pr edit` logs a note and does NOT fail the run (verdicts still live in the run output + scratch file). NO upstream `/ship` modification. v1 wires this into `/CJ_goal_feature` ONLY (defect/todo surfacing is a Job-2.1 follow-up; the §1 producer is shared by all three regardless).
- [ ] **§2a CLAUDE.md — tracked-doc manifest `requirement:` lines (3).** Add a bespoke `requirement:` child line to each of the 3 `### Tracked doc/ files manifest` entries: `doc/PHILOSOPHY.md` ("`## Decision tree` lists every active routable skill (matches the New-skills check); the overview + design principles reflect the current CJ_ skill family and the two delivery surfaces"), `doc/ARCHITECTURE.md` ("`## Component skills (non-workflow roster)` lists every non-workflow active routable skill; each mechanism section matches the current load-bearing **scripts OR skill steps**" — worded to ACCEPT a SKILL.md-step mechanism so §4 doesn't self-flag, review finding #6), `doc/WORKFLOWS.md` ("Has a `### <name>` section for every `CJ_goal_*` orchestrator, each with an ASCII chart + a Touches block reflecting the current chain"). **Parser-safety:** Check 15a extracts `$3` from `- path:` lines only, so adding `requirement:` child lines does NOT break it — verify Check 15a still GREEN.
- [ ] **§2b CLAUDE.md — new `## Registered-doc requirements audit` convention section** (sibling to `## /document-release workbench audit conventions`). DOCUMENTS what the §1 wrapper step does (NOT a directive to an unwired upstream): registered set = (i) tracked-doc manifest entries (their `requirement:`) + (ii) every active routable skill's SKILL.md (requirement = optional `doc_requirement` in skills-catalog.json, else the **shared default**: "The SKILL.md frontmatter `description` and the documented behavior/steps match the skill's current implementation; the skill's USAGE.md is current"). Verdict taxonomy (up-to-date / stale: <why> / missing-requirement / n/a). Surfacing → PR body `## Documentation` under `### Registered-doc requirements`; positive line when all up-to-date. Producer note: the §1 wrapper step is the producer; the existing F000030 `### Skill-routing drift` / `### Doc/ manifest drift` subheadings had NO wired producer until now (emitting those two is OPTIONAL in v1; the new subheading is the deliverable). Posture: ADVISORY, agent-judged, NEVER a hard gate; no upstream modification; no new hard validate.sh check in v1. Scope: the 3 tracked-doc/ files + active routable skill MDs (root convention docs out of scope).
- [ ] **§2c CLAUDE.md — update the existing `### Reporting` subsection** of `## /document-release workbench audit conventions` to list the new `### Registered-doc requirements` subheading alongside `### Skill-routing drift` + `### Doc/ manifest drift`, noting all three are emitted by the §1 wrapper step.
- [ ] **§2d CLAUDE.md — document the optional `doc_requirement` catalog field** (in 2b and/or the `### Catalog format` note): "Optional per-skill `doc_requirement` string overrides the shared default skill-MD requirement; absent ⇒ shared default applies."
- [ ] **§3 skills-catalog.json — add `doc_requirement` to ONE exemplar (`CJ_document-release`).** A short string that does NOT enumerate step numbers (§1 adds Step 6.7, which would self-stale a "Step 0.5–Step 7" string — review nit #3), e.g. "The wrapper flow + the cj-document-release.json schema reference match the current `cj-document-release-config.sh` subcommands and the registered-doc audit step." **Tolerated:** there is NO closed catalog schema (only `status` is a closed enum; Check 1/2 only check SKILL.md presence + frontmatter) — confirm Check 1/2 GREEN at implement.
- [ ] **§4 doc/ARCHITECTURE.md — new `## Registered-doc requirements audit (Job 2)` mechanism section** (F000037-section style) documenting the §1 producer step + the registry-with-requirements. **Self-reference:** this section's mechanism is a SKILL.md step, not a `scripts/*.sh` — §2a's ARCHITECTURE `requirement:` is worded to accept a SKILL.md-step mechanism so this section doesn't self-flag a cosmetic soft-stale verdict on run 1.
- [ ] **§5 TODOS.md — strike the Job-2 row DONE.** Rows ~19–23 (`### Job 2: registered-doc requirements audit for /CJ_document-release (P2, M)`) → standard completion annotation (`~~…~~ DONE — closed by T000038 (vX.Y.Z, PR #NNN)`) so `/CJ_suggest` excludes it.
- [ ] **§6a Deterministic PRODUCER-wired smoke check — `scripts/test.sh`.** Assert `skills/CJ_document-release/SKILL.md` contains the §1 audit step: the `jq` enumeration selector AND the literal `### Registered-doc requirements` emit string AND the scratch-file write (`.cj-goal-feature/registered-doc-verdicts.md`).
- [ ] **§6b Deterministic SURFACING-wired smoke check — `scripts/test.sh`.** Assert `skills/CJ_goal_feature/pipeline.md` contains the Step 4.6 surfacing step: the `gh pr edit` call AND the `registered-doc-verdicts.md` scratch read. (Together §6a+§6b prove the FULL producer→PR-body path is wired — what the re-review required.)
- [ ] **§6c Verify GREEN.** `./scripts/validate.sh` exit 0 (Check 15a still parses the manifest with new `requirement:` lines; Check 1/2 tolerate `doc_requirement`; Check 16 unaffected). `./scripts/test.sh` exit 0 (no validate.sh Check added → zzz-test-scaffold fixture SHOULD be unaffected, but VERIFY per `project_implement_subagent_blind_spot_test_sh`).
- [ ] **§6d Live dogfood (best-effort).** Because v1 wires surfacing into `/CJ_goal_feature`, THIS PR's own body should carry a real `### Registered-doc requirements` section — a true end-to-end proof on top of the structural checks.
- [ ] **CHANGELOG.md.** `/ship` adds the new entry.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Job 2 — a NEW advisory "is THIS registered doc up to date against ITS declared requirement?" audit for `/CJ_document-release`, covering both the 3 tracked-doc/ files AND the active routable skill MDs. Producer = a new Step 6.7 in the workbench-owned wrapper SKILL.md (the first REAL producer for the PR-body audit subheadings); surfacing = a new post-/ship Step 4.6 `gh pr edit` in CJ_goal_feature/pipeline.md; requirement data in the CLAUDE.md tracked-doc manifest + skills-catalog.json `doc_requirement`. Scaffolded from APPROVED /office-hours design doc via /CJ_scaffold-work-item under /CJ_goal_feature.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_document-release/SKILL.md` (PLANNED — §1 PRODUCER: new advisory Step 6.7 on the green-tail of Step 6; reads CLAUDE.md tracked-doc manifest `requirement:` lines + jq-enumerated skill `doc_requirement`s, agent-judges each registered doc, emits the `### Registered-doc requirements` block to RESULT AND writes the gitignored scratch file `.cj-goal-feature/registered-doc-verdicts.md`; NEVER halts)
- `skills/CJ_goal_feature/pipeline.md` (PLANNED — §1.5 SURFACING: new post-/ship Step 4.6 reads the scratch file and `gh pr edit <PR#>` to insert/replace `### Registered-doc requirements` under the PR body `## Documentation`; idempotent; best-effort, never fails the run; v1 = CJ_goal_feature only)
- `CLAUDE.md` (PLANNED — §2a 3 tracked-doc manifest `requirement:` lines [ARCHITECTURE worded to accept a SKILL.md-step mechanism]; §2b new `## Registered-doc requirements audit` convention section; §2c `### Reporting` subsection updated to name the new subheading; §2d optional `doc_requirement` field documented)
- `skills-catalog.json` (PLANNED — §3 `doc_requirement` on the `CJ_document-release` exemplar entry; string with NO hardcoded step numbers)
- `doc/ARCHITECTURE.md` (PLANNED — §4 new `## Registered-doc requirements audit (Job 2)` mechanism section, F000037-section style)
- `TODOS.md` (PLANNED — §5 strike the Job-2 row DONE with `~~…~~ DONE — closed by T000038 (vX.Y.Z, PR #NNN)`)
- `scripts/test.sh` (PLANNED — §6a PRODUCER-wired smoke check [jq selector + `### Registered-doc requirements` emit + scratch-file write in CJ_document-release/SKILL.md]; §6b SURFACING-wired smoke check [Step 4.6 `gh pr edit` + scratch read in CJ_goal_feature/pipeline.md])
- `CHANGELOG.md` (PENDING — new entry added by /ship)

## Insights

<!-- Design context distilled from the APPROVED /office-hours design doc
     (hardened through TWO adversarial spec reviews). -->

- **Two jobs, second shipped.** "Tighten /CJ_document-release" split into (1) the doc/WORKFLOWS.md workflow-centric reorg (Job 1 = T000037 / v6.0.23 / PR #213) and (2) THIS audit — a general "is THIS registered doc up to date against ITS declared requirement?" pass covering both `doc/*.md` files AND skill `SKILL.md`s. Job 2 is the operator's "real tightening."
- **The workbench already had the shape — Job 2 generalizes it.** Check 14 is literally "is USAGE.md up to date vs its requirement (SKILL.md)?" for one doc-pair; the skill-routing-drift convention is literally "agent-judged verdict surfaced in the PR body." Job 2 unifies these: every registered doc carries its requirement IN its registration, and `/document-release` emits a verdict per doc.
- **BLOCKING mechanism correction (first adversarial review, 4/10).** The original premise — "upstream /document-release reads CLAUDE.md `## …audit conventions` prose as audit DIRECTIVES" — does NOT exist: upstream Step 2 is a FIXED set of generic per-file heuristics; it reads CLAUDE.md only as a doc to AUDIT. Worse, the existing F000030 `### Skill-routing drift` / `### Doc/ manifest drift` subheadings have NO wired producer — they are aspirational prose applied ad-hoc by a knowledgeable agent. So Job 2 cannot "ride an existing pattern"; it must INTRODUCE the first real producer, and the correct home is the **workbench-owned `/CJ_document-release` wrapper** (which already reads `cj-document-release.json` + builds a project-context block) — NOT upstream. Without this the feature would have shipped inert.
- **BLOCKING surfacing correction (second adversarial review, 6/10).** The §1 producer is sound, but the original "the agent composing the PR body at /ship includes it" surfacing was hand-waved: upstream `/ship` Step 18 regenerates the PR body from a FRESH `/document-release` subagent that never sees the wrapper RESULT, so the verdict would die in stdout (grep confirmed ZERO emitters of the F000030 subheadings anywhere). **Resolved by D4=A:** §1 writes the block to a gitignored scratch file, and §1.5 adds a deterministic post-/ship `gh pr edit` surfacing step in `/CJ_goal_feature`, with a surfacing-wired smoke check (§6b) so the FULL producer→PR-body path is proven, not just the producer.
- **"No upstream modification" only ever meant the upstream gstack skill** (`/document-release`, `/ship`) — NOT the workbench-owned wrapper or pipeline. Modifying `skills/CJ_document-release/SKILL.md` (§1) + `skills/CJ_goal_feature/pipeline.md` (§1.5) breaks no constraint; they are this repo's own files.
- **Advisory + additive, by design (D1).** Verdicts are agent-judged and surface in the PR body; the proven hard gates (Check 14/15/16) are NOT touched, replaced, or consolidated in v1. A registered doc lacking a requirement gets a `missing-requirement` *advisory* verdict, not a CI error. Hardening requirement-presence into a validate.sh check is the Job-2.1 follow-up — deliberately deferred because it would ALSO drag in the `project_implement_subagent_blind_spot_test_sh` zzz-fixture edit that v1 avoids.
- **Requirement lives in the registration record (D2).** doc/ files → a `requirement:` field in the CLAUDE.md tracked-doc manifest; skill MDs → an optional `doc_requirement` in skills-catalog.json, defaulting to a shared skill-MD requirement when absent. Lean authoring (D3): 3 bespoke doc requirements + one shared skill-MD default + ONE exemplar per-skill override; no helper script, no bespoke-per-skill, no hard schema enforcement of the new fields in v1.
- **No hardcoded skill count.** Registered skills are enumerated by the SAME selector the F000030 New-skills check uses (`jq -r '.[] | select(.status=="active") | select((.files|length)>0) | .name'`) — the design dropped the original hardcoded "13 skills" (review nit #5) so the audit auto-tracks the catalog.
- **Verified-correct (no change needed):** Check 15a's `$3`-only parser is `requirement:`-safe; there is no closed catalog schema (so `doc_requirement` is tolerated); the "no new hard validate.sh check" posture is internally consistent.
- **The deterministic guarantee is producer+surfacing WIRING, not verdict CONTENT.** Verdict content is agent-judged (non-deterministic). QA's proof = the two structural smoke checks (§6a producer-wired, §6b surfacing-wired) + validate/test GREEN + the 3 manifest requirements + the catalog field tolerated. A live run surfacing real verdict text (the dogfood on THIS PR) is best-effort on top, NOT the proof the feature shipped.

## Journal

<!-- Structured entries (decision/finding/blocker) with Summary fields. -->

- [decision] 2026-06-04 — Scaffolded as a **task** (not a user-story or parent feature). Rationale: the design is a single, coherent, directly-implementable change (a wrapper audit step + a pipeline surfacing step + requirement data + docs) with a test plan; under /CJ_goal_feature's silent subagent context a user-story would error at scaffold.md Step 8 (user-stories must nest under a parent feature, which the directly-implementable mandate forbids), while a standalone task (TRACKER + test-plan) is an established on-disk convention (work-items/tasks/ops/). Mirrors Job 1's T000037, scaffolded as a task for the identical reason. Component `ops` matches the F000030/F000034/F000037/T000037 doc-infra lineage.
- [decision] 2026-06-04 — Approach A (Lean-complete, wrapper-produced) confirmed at design D1+D2+D3=A/A/A: requirement in the registration record; a new advisory audit step in the workbench-owned `/CJ_document-release` wrapper (§1) emits agent-judged verdicts; both surfaces (3 doc/ files + active routable skill MDs) covered with a shared skill-MD default + ONE exemplar override. Rejected B (full rigor + `cj-doc-requirements.sh` helper + schema enforcement → Job-2.1, over-invests before the requirement format is proven AND adds the zzz-fixture blind spot) and C (doc-only v1 → under-delivers "skill md as well").
- [decision] 2026-06-04 — D4=A surfacing: §1 writes the verdict block to a gitignored scratch file `.cj-goal-feature/registered-doc-verdicts.md`; §1.5 adds a post-/ship Step 4.6 `gh pr edit` in CJ_goal_feature/pipeline.md to land it in the PR body. v1 wires surfacing into `/CJ_goal_feature` ONLY (the PR-stop orchestrator where review matters most + dogfoodable on THIS PR); defect/todo surfacing deferred to Job-2.1 (they auto-land → short PR-review window). The §1 producer is shared by all three.
- [decision] 2026-06-04 — ARCHITECTURE.md's own new `requirement:` (§2a) is worded to ACCEPT a SKILL.md-step mechanism (e.g. "…load-bearing scripts OR skill steps"), not only `scripts/*.sh` (review finding #6). Rationale: §4's new ARCHITECTURE section documents a mechanism that IS a SKILL.md step, not a script — a scripts-only requirement would make ARCHITECTURE self-flag a cosmetic soft-stale verdict on run 1.
- [decision] 2026-06-04 — skills-catalog.json `doc_requirement` exemplar (§3) is de-step-numbered (review nit #3): §1 adds Step 6.7, so a "Step 0.5–Step 7" string would self-stale immediately. The exemplar describes the wrapper flow + config-schema reference + the audit step WITHOUT enumerating step numbers.
- [decision] 2026-06-04 — Two deterministic smoke checks (§6a producer-wired in CJ_document-release/SKILL.md, §6b surfacing-wired in CJ_goal_feature/pipeline.md) are the QA proof, NOT the verdict text. Together they prove the full producer→PR-body path is wired — the explicit requirement from the second adversarial review (6/10) that a producer-only check would leave the path observably inert.
- 2026-06-04 [qa-smoke] T1 (§6a PRODUCER-wired, DETERMINISTIC): green — skills/CJ_document-release/SKILL.md contains all 3 grep hits: `### Registered-doc requirements` emit (1), `select(.status=="active")` jq selector (1), `.cj-goal-feature/registered-doc-verdicts.md` scratch write (1). Producer Step 6.7 is wired.
- 2026-06-04 [qa-smoke] T2 (§6b SURFACING-wired, DETERMINISTIC): green — skills/CJ_goal_feature/pipeline.md contains both grep hits: `gh pr edit` (4 occurrences, incl. Step 4.6) + `registered-doc-verdicts.md` scratch read (2). T1+T2 prove the full producer→PR-body path is wired (the second-adversarial-review requirement).
- 2026-06-04 [qa-smoke] T3 (§2a CLAUDE.md manifest requirement: lines): green — exactly 3 `requirement:` child lines in the `### Tracked doc/ files manifest` block (PHILOSOPHY/ARCHITECTURE/WORKFLOWS); ARCHITECTURE's carries the "scripts OR skill steps" wording so §4 does not self-flag a soft-stale verdict on run 1.
- 2026-06-04 [qa-smoke] T4 (§2b/c/d CLAUDE.md convention+reporting+field): green — `## Registered-doc requirements audit (Job 2 / T000038)` H2 present (sibling to the workbench-audit-conventions section); `### Reporting` names the new `### Registered-doc requirements` subheading alongside Skill-routing-drift + Doc/-manifest-drift; optional `doc_requirement` field + shared default skill-MD requirement documented.
- 2026-06-04 [qa-smoke] T5 (§3 skills-catalog.json doc_requirement exemplar): green — `doc_requirement` present on the CJ_document-release entry, non-empty, NO `Step N` token (de-step-numbered per review nit #3); `jq empty skills-catalog.json` succeeds (valid JSON).
- 2026-06-04 [qa-smoke] T6 (§4 doc/ARCHITECTURE.md mechanism section): green — `## Registered-doc requirements audit (Job 2)` section present at doc/ARCHITECTURE.md:75 (F000037-section style).
- 2026-06-04 [qa-smoke] T7 (§5 TODOS.md Job-2 row struck DONE): green — the Job-2 row (TODOS.md:19) is `~~…~~ DONE — closed by T000038 (vX.Y.Z, PR #NNN)`; strikethrough present so /CJ_suggest excludes it (version/PR placeholders filled by /ship).
- 2026-06-04 [qa-smoke] T8 (validate.sh GREEN): green — `./scripts/validate.sh` exit=0, RESULT: PASS, 0 errors / 0 warnings. Check 14 (CJ_document-release/USAGE.md current) PASS; Check 15 doc/ manifest parses clean with the new `requirement:` child lines (no orphan/FAIL — the `$3`-only `- path:` parser is requirement:-safe); Check 16 (cj-document-release.json schema_version=1) unaffected.
- 2026-06-04 [qa-smoke] T9 (test.sh GREEN incl. two new §6 smoke checks): green — `./scripts/test.sh` exit=0, RESULT: PASS, Failures: 0. `OK: T000038a` (producer step) + `OK: T000038b` (Step 4.6 surfacing) both present and green. Explicitly VERIFIED per project_implement_subagent_blind_spot_test_sh: scripts/validate.sh NOT touched by a8f7377 → no new validate.sh Check added → zzz-test-scaffold integration fixture UNAFFECTED (no zzz/integration failures). No-upstream-modification confirmed: commit touches only workbench-owned files (no gstack /document-release or /ship).
- 2026-06-04 [qa-smoke] T10 (live dogfood — THIS PR body carries the section): n/a — deferred-to-ship, NOT a QA blocker. No PR exists for this branch yet (`gh pr list --head` returns `[]`) and the scratch file is unwritten (the Step 6.7 producer runs at the orchestrator's Step 5.5 doc-sync, AFTER this QA step). Marked BEST-EFFORT in the test-plan; the deterministic proof is T1+T2, which are green.
- 2026-06-04 [qa-smoke-summary] green: 9/9 runnable rows green (T1–T9); T10 deferred-to-ship (n/a, best-effort, not a gate). 0 manual rows.
- 2026-06-04 [qa-pass] T000038 (task): green smoke from test-plan rows (9 runnable rows green; T10 deferred-to-ship). No qa-owned Phase 2 gates per task template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. The two DETERMINISTIC wiring checks (T1 §6a producer-wired + T2 §6b surfacing-wired) — the proof the feature is wired, not inert — are both green.
