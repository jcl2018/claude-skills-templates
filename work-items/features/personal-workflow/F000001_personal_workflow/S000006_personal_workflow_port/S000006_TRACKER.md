---
name: "personal-workflow-port"
type: user-story
id: "S000006"
status: deferred
created: "2026-04-20"
updated: "2026-04-20"
parent: "F000001_personal_workflow"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "evidence-gate — see Log 2026-04-20 autoplan review"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [ ] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] `/personal-workflow tree` — structure verified
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. This is a parity port: no new design,
     no new env var, no new schema. Everything that works under /company-workflow
     after S000004 + S000005 ship must work identically under /personal-workflow. -->

### Resolution parity (from S000004)

- [ ] `skills/personal-workflow/SKILL.md` has a `## Knowledge Resolution` block that resolves `AI_KNOWLEDGE_DIR` with the same four branches (unset, missing path, non-directory, valid) and the same sanitization contract as company-workflow
- [ ] When the env var is unset/empty: exactly one stderr warning line naming the variable; exit 0; byte-identical stdout to the pre-port baseline
- [ ] When the env var points to an invalid path (missing or not a directory): exactly one stderr warning line naming the configured path (sanitized, ≤200 chars, control chars stripped); exit 0
- [ ] When the env var points at a valid directory: no warning, `$_KNOWLEDGE_DIR` set to the resolved path
- [ ] Resolution block runs **after** Path Resolution (so user-configured knowledge dir can't break skill discovery)

### Loading parity (from S000005)

- [ ] `skills/personal-workflow/SKILL.md` has a `## Knowledge Loading` block matching company-workflow's enumeration, `.knowledge.yml` parsing, always-on emission, and on-demand candidates emission
- [ ] Per-repo opt-in gate (`.claude/knowledge-enabled` marker) is enforced identically — without the marker, no loading happens even when env var resolves
- [ ] Malformed `.knowledge.yml` in one category skips that category with a one-line warning; sibling categories continue loading; exit 0
- [ ] Categories with no `.knowledge.yml` are treated as on-demand with empty triggers (dark)
- [ ] The shared test helper (`scripts/test-helpers/knowledge.sh`, built in S000005) is reused — no duplicate fixture builder

### Docs parity

- [ ] `skills/personal-workflow/WORKFLOW.md` has a `## Knowledge Configuration` section mirroring company-workflow's (setup, layout, `.knowledge.yml` schema, current status)
- [ ] The docs reference `/personal-workflow` (not `/company-workflow`) in examples and command callouts

### Zero regression

- [ ] Existing `/personal-workflow check` command produces byte-identical output with and without `AI_KNOWLEDGE_DIR` set (same contract as S000004 proved for company-workflow)
- [ ] `./scripts/test.sh` passes end-to-end
- [ ] No change to `personal-artifact-manifests.json` (knowledge is a runtime skill concern, not a scaffolding artifact)
- [ ] `/company-workflow` knowledge behavior is untouched (port is additive)

## Todos

<!-- Actionable items for this story. Implementation lives in T000007. -->

- [ ] Confirm S000005 has landed on `main` before starting Phase 2 (hard blocker — nothing to port until then)
- [ ] Diff company-workflow's shipped `## Knowledge Resolution` + `## Knowledge Loading` blocks against the last reviewed version; flag any drift before copying
- [ ] Decide whether the port block lives at the same position in SKILL.md as company-workflow (after Path Resolution) or adapts to personal-workflow's shorter structure (leaning: same position)
- [ ] Confirm personal-workflow's `## Stale Rules Detection` block interacts cleanly with the new Knowledge Resolution block (order matters — Stale Rules runs before Overview today)
- [ ] Build T000007 test block in `scripts/test.sh` parallel to T000003's (same 11-case structure against personal-workflow's SKILL.md; adjust paths)
- [ ] Decide whether to extract company-workflow's resolution/loading bash into a shared helper file that both skills source, OR accept duplication (lift-and-shift is simpler; extraction is cleaner but bigger scope)
- [ ] Update WORKFLOW.md `## Knowledge Configuration` — mirror the company-workflow section verbatim, then s/company-workflow/personal-workflow/g and adjust the F000004 backlink
- [ ] Verify the per-repo opt-in marker path (`.claude/knowledge-enabled`) is the same across both skills (it should be; the marker is a repo-level concept, not a skill-level one)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-20: Created. Parity port of F000004's knowledge feature to /personal-workflow. Scope is lift-and-shift of the Resolution (S000004) + Loading (S000005) blocks plus the WORKFLOW.md `## Knowledge Configuration` docs; no new design, no new env var, no new schema. Blocked by S000005 landing (need the final shape of the Loading block before copying).
- 2026-04-20: Decision — single story (not split resolution+loading into two stories). Rationale: loading is the harder part and still in flight; shipping resolution alone to personal-workflow creates a half-ported state users would have to reason about. One PR, one cutover. Matches the 2026-04-19 S000005 consolidation precedent.
- 2026-04-20: **DEFERRED.** /autoplan CEO phase ran against the execution design doc with dual voices (Codex + independent Claude subagent). 5/6 consensus dimensions CONFIRMED-NO, 0 disagreements — both voices independently flagged the port as symmetry work rather than product work for a single-user workbench. Key findings: (1) plan is dependency-ahead of repo state (S000005 not on main yet; `scripts/test-helpers/knowledge.sh` doesn't exist yet); (2) no documented personal-repo workflow this unlocks; (3) drift tripwire is Approach-B-in-disguise with awk+sed fragility; (4) premises asserted not verified. User chose at premise gate to defer rather than override dual-voice signal. Unblock condition: a specific personal-repo task where missing knowledge-loading is an observed blocker. Design doc retained at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260420-203757.md` with the full review report appended — resumable if/when the evidence gate clears.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- skills/personal-workflow/SKILL.md (to be modified — `## Knowledge Resolution` + `## Knowledge Loading` blocks mirrored from company-workflow)
- skills/personal-workflow/WORKFLOW.md (to be modified — `## Knowledge Configuration` section mirrored from company-workflow)
- scripts/test.sh (to be modified — T000007 adds a parallel test block against personal-workflow's SKILL.md)

## Insights

<!-- Non-obvious findings worth remembering. -->

- Both skills share the same user-owned `$AI_KNOWLEDGE_DIR` and the same `.knowledge.yml` schema. The port is mechanical — no decision surface is re-opened. The only real judgment call is duplication vs. shared helper (see Todos), which is a code-smell question not a feature question.
- The opt-in marker (`.claude/knowledge-enabled`) is repo-level, not skill-level. Both skills honor the same marker in the same repo. That's by design — the marker answers "does THIS repo want knowledge injected?", not "does THIS skill want knowledge?".

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-20 — decision: single story for resolution + loading port

**Summary:** Port both the Resolution block (from shipped S000004) and the Loading block (from in-flight S000005) to `/personal-workflow` in a single story, blocked by S000005.

**Alternatives considered:**
- Two stories: S000006_port_resolution (unblocked, ship now) + S000007_port_loading (blocked by S000005). Rejected — ships a half-ported state where users see one skill resolve the env var but not load content, creating a support question ("why does company-workflow use my knowledge but personal-workflow only warns about it?"). The mechanical nature of the port makes PR splitting pure overhead.
- Fold the port into F000004's existing stories (stretch S000005 to cover both skills). Rejected — S000005 is already a merged-from-two story; stretching it again dilutes review surface and couples personal-workflow's port to company-workflow's feature being ready.

**Rationale:**
- Port is lift-and-shift. No new design. Same env var, same schema, same opt-in marker, same tests.
- One PR makes the cutover atomic — either both blocks land together or neither does.
- S000005's Loading block is the moving target; waiting for it to stabilize avoids a double-port.

**Consequences:**
- S000006 is Phase-1 scaffolded now; Phase-2 implementation is parked until S000005 lands.
- The F000004 follow-up TODO ("Port knowledge feature to /personal-workflow") is promoted from a bullet into this story.
