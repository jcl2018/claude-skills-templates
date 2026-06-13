---
name: "qa.md Step 8.6 split + DEFER_AUDIT directive"
type: user-story
id: "S000106"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: "F000064"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/friendly-sinoussi-cef30d"
blocked_by: ""
---

<!-- Atomic story: derives directly from the parent feature's /office-hours session.
     Parent's design is sufficient context; DESIGN.md is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/post_sync_authoritative_audit` (or use parent's branch if shipping in same PR)
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

- [ ] qa.md Step 8.6a/8.6b (the spec-overlay refresh writes) keep running inline in QA on every green path, unchanged.
- [ ] qa.md Step 8.6c/8.6d (the three-stage doc/test audits) become deferrable: when the QA dispatch prompt contains the literal `DEFER_AUDIT: true` directive, QA SKIPS 8.6c/8.6d and the RESULT's `AUDITS=` field reports `deferred`.
- [ ] Standalone `/CJ_qa-work-item` (no `DEFER_AUDIT: true` directive present) runs 8.6c/8.6d inline exactly as today, and still emits the `AUDIT_FINDINGS` fenced block.
- [ ] When deferred, the `AUDIT_FINDINGS` block is NOT emitted by QA — the post-sync orchestrator audit step emits it instead.

## Todos

- [x] Edit `skills/CJ_qa-work-item/qa.md` Step 8.6 to split the overlay-writes (8.6a/8.6b) from the audits (8.6c/8.6d).
- [x] Add the `DEFER_AUDIT: true` directive detection (literal-string match on the dispatch prompt) and the skip path that sets `AUDITS=deferred`.
- [x] Keep the inline-audit + `AUDIT_FINDINGS` emission path for standalone (no directive) runs.
- [x] Update the qa.md Step 8.6 narrative ("contract updated then verified" now spans the sync boundary).

## Log

- 2026-06-13: Created. qa.md Step 8.6 split: keep overlay writes inline; make the doc/test audits deferrable via the `DEFER_AUDIT: true` dispatch directive.

## PRs

## Files

- `skills/CJ_qa-work-item/qa.md` — modified: Step 8.6 split (new 8.6.0 defer detection; 8.6a/8.6b always inline; 8.6c/8.6d deferral guards; deferred vs inline Extended RESULT paths; summary deferred-case note)
- `skills/CJ_qa-work-item/SKILL.md` — modified: description + Overview audit-block bullet now spell out the DEFER_AUDIT: true defer behavior
- `skills/CJ_qa-work-item/USAGE.md` — modified: Mental model two-half (writes always inline / audits deferrable) rewrite; last-updated bumped

## Insights

- The defer signal is a literal `DEFER_AUDIT: true` string in the dispatch prompt, NOT an argv flag — `/CJ_qa-work-item` is dispatched as an Agent-tool subagent prompt, not a CLI with argv. Greppability comes from the literal string in the pipeline.md prompt templates.

## Journal

- [decision] 2026-06-13: 8.6a/8.6b (overlay writes) stay inline pre-sync with the code; only 8.6c/8.6d (the three-stage audits) become deferrable. Summary: writes belong with the code, audits belong after the last doc-mutating step.
- 2026-06-13 [impl-decision] Carried the SPEC's Tradeoff #1 forward: defer signal is the literal `DEFER_AUDIT: true` string in the dispatch prompt (NOT an argv flag) — QA is dispatched as a subagent prompt, and the literal string is greppable in the sibling pipeline.md templates that S000107 will consume.
- 2026-06-13 [impl-decision] Deferred-path `AUDITS=` shape resolved (SPEC Open Question): `AUDITS=deferred,spec_updates:<summary>` (the spec-update summary from 8.6a/8.6b still rides, since those writes always run); the inline path keeps the existing `AUDITS=doc:..,test:..,spec_updates:..` shape.
- 2026-06-13 [impl] Modified 3 files: qa.md (new Step 8.6.0 defer-detection sub-step + deferral guards on 8.6c/8.6d + a deferred vs inline split of the Extended RESULT contract + a Step 11 summary deferred-case note), SKILL.md (description + Overview audit-block bullet), USAGE.md (Mental model rewrite + last-updated bump). No catalog/manifest/validator/sibling-pipeline edits (S000107/S000108 scope).
- 2026-06-13 [impl-auto] Auto-mode run; --auto allowed (2 source files in Components Affected, no sensitive surface).
- 2026-06-13 [impl-pass] S000106: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-13 [qa-smoke-summary] green: 5/5 non-manual smoke rows green (S1-S4 greps PASS; S5 validate.sh exit=0). DEFER_AUDIT detection branch present, AUDITS=deferred wired, 8.6a inline, inline CJ_doc_audit+CJ_test_audit retained.
- 2026-06-13 [qa-e2e-summary] green (static-verifiable E2E): E1 (deferred path emits AUDITS=deferred + no AUDIT_FINDINGS) and E2 (standalone inline path emits AUDIT_FINDINGS) both verified present in qa.md Step 8.6.0/8.6c/8.6d + the Extended RESULT contract's deferred vs inline split.
- 2026-06-13 [qa-pass] S000106 (user-story): green smoke + green E2E. Phase 2 gates transitioned.
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator)
