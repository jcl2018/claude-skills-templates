---
type: design
parent: F000024
title: "/CJ_goal_investigate zero-match draft capture + promote — Feature Design"
version: 1
status: Draft
date: 2026-05-16
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

`/CJ_goal_investigate <D-id|fragment>` (shipped at v1.0 by S000049) takes a
*scaffolded* defect work-item and ships a fix end-to-end. The resolver at
`pipeline.md` Step 2's `case "$MATCH_COUNT" in 0)` branch halts whenever the
fragment doesn't match an existing `work-items/defects/<domain>/D000NNN_<slug>/`
directory. This forces a two-command flow when the user has a bug fresh in
their head: `/CJ_scaffold-work-item --type defect …` then
`/CJ_goal_investigate D000NNN`. The user wants one command — if a defect dir
exists, resolve to it; if not, silently capture a mutable draft and continue
the pipeline. No AUQ, no second command.

SKILL.md's "Not in scope" section defers this to v2.0; this story pulls it
into v1.1. This is the next increment to the same `/CJ_goal_investigate` skill
that F000024's S000049 created at v0.1.0.

## Shape of the solution

Modify `pipeline.md` Step 2's zero-match `0)` branch from "halt" to
"resolve-or-create a non-canonical draft, then continue." Add a new **Step
7.4** that promotes a draft to a canonical defect dir *after* the Iron-Law
gate passes. The D-ID / canonical slug / domain are minted only at promotion
(the moment of clarity, after `/investigate` determined the actual root
cause) — never at the raw-fragment intake. Duplicate-fragment entropy is
structurally bounded to the non-canonical `work-items/defects/.inbox/`, which
is never a resolver match. This is a single atomic user-story (no child
tasks): the change spans `pipeline.md` + `SKILL.md` + the test script, all
within `skills/CJ_goal_investigate/`.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Zero-match draft capture, promotion, Iron-Law-gated D-ID allocation, crash safety, C1-C7 contract | S000055 | [S000055_TRACKER.md](S000055_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Draft/inbox model, NOT direct canonical scaffold (Approach D) | Both /autoplan CEO voices independently flagged near-duplicate D-ID dirs polluting future resolution as the #1 6-month regret. Every typo'd/re-worded fragment under Approach D would mint a canonical D-ID the resolver must disambiguate forever — search entropy `rm -rf` does not fix (recall trust degrades). The draft model bounds the entropy to the explicitly non-canonical `.inbox/`. USER DECISION at the premise gate. |
| 2 | D-ID / slug / domain minted only at promotion (post-/investigate) | Canonical namespace is touched exactly once per *real* defect, at the moment of clarity. Iron-Law strengthened: a D-ID is never spent on a defect that didn't get a root cause. |
| 3 | Resolver Step 2 `if`/`MATCHES`/`MATCH_COUNT` block byte-for-byte unchanged; only the `0)` case body changes | Drafts are invisible to the canonical resolver by construction (no `D[0-9]{6}_` basename → excluded from BASENAME_HITS; `DRAFT.md` not `*_TRACKER.md` → excluded from NAME_HITS). New behavior strictly subsumes the old; existing invocations unaffected; no backwards-compat shim needed. |
| 4 | Draft-capture + promotion logic inlined in `pipeline.md`, not a shared template | `/CJ_scaffold-work-item` consumes design docs, not bug fragments. One reuse site; abstraction not yet earned. Promote-to-shared-template is a tracked v1.2 trigger (Open Q #5) if a second skill needs it. |
| 5 | C1-C7 binding implementation contract from dual-voice eng + DX review | /autoplan Phase 3 ran two independent eng reviewers (Claude + Codex) + dual DX. All independently found the same first-pass gaps. Each item is mechanical (one correct answer) — pinned, not implementer's discretion. |
| 6 | Canonical TRACKER write = the durable commit point in the promotion protocol (C3) | A crash after the TRACKER exists resumes the canonical dir by fragment (NAME_HITS) with no second D-ID. A crash before it leaves a harmless empty orphan that the highest-N scan still counts. Removes the duplicate-D-ID crash window. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| New TRACKER frontmatter keys `auto_scaffolded` + `promoted_from_draft` could crash `/CJ_qa-work-item` on the first promoted defect if a strict key-allowlist validator exists | PRE-IMPLEMENTATION PREREQUISITE: grep `skills/CJ_personal-workflow/` + inspect `personal-artifact-manifests.json`. If strict, extend allowlist in same PR; if pass-through (most likely), no extra work. |
| Re-worded re-invocation pre-promotion creates a second draft in `.inbox/` (different slug) | Accepted v1.1 limitation, bounded to non-canonical inbox — never pollutes canonical resolution. Recovery: `rm -rf .inbox/<dup>`. Fuzzy match is v1.2 (Open Q #4). |
| Resumed-draft dirty-tree rerun: a prior `/investigate` that wrote partial code before halting leaves the rerun starting dirty (C5) | Accepted v1.1 limitation — the existing canonical R/F/P/M ladder has the same blind spot pre-RCA and `/investigate` does its own `git status` check. C5 requires echoing the stored fragment on resume + a v1.2 open question (Open Q #6) for draft-level partial-fix detection. |
| Concurrent invocations racing the D-ID counter at promotion | mkdir-based POSIX-atomic lock (stock macOS has no flock) around the highest-N scan + canonical mkdir in Step 7.4. Lock-timeout path has full C4 bookkeeping (journal + telemetry + 13th end-state). |
| Domain defaults to `uncategorized` at promotion | Domain inference is v1.2 (Open Q #2); `mv` to a more specific subdir is a documented manual step in the auto-scaffolded journal entry. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] Zero-match fragment creates `.inbox/<slug>/DRAFT.md`, no D-ID, pipeline continues at Row 1.
- [ ] Iron-Law pass → promotion to `work-items/defects/uncategorized/D000NNN_<slug>/` with canonical TRACKER/RCA/test-plan; `.inbox/<slug>/` removed.
- [ ] Iron-Law fail → no promotion, no D-ID consumed; draft remains; re-invocation resumes it.
- [ ] Canonical resolver block byte-for-byte unchanged; drafts never a canonical match (regression-guarded).
- [ ] All of C1-C7 satisfied and individually test-covered.
- [ ] `--dry-run` on zero-match prints plan, creates nothing, exits 0 with `end_state=dry_run_preview`.
- [ ] Promoted-run telemetry includes `auto_scaffolded: true`.
- [ ] CJ_personal-workflow validator tolerates the two new frontmatter keys.
- [ ] SKILL.md version 1.0.0 → 1.1.0; "Not in scope" line moved to v1.1 feature; 13th end-state in halt taxonomy.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Domain inference at promotion (vs `uncategorized` default) — v1.2 (Open Q #2); needs `git diff --name-only` heuristic + optional env override.
- Fuzzy/token match so re-worded fragments resume the right draft/defect — v1.2 (Open Q #4); honest limitation bounded to `.inbox/`.
- Closest-existing-defect hint after draft capture — v1.2 (Open Q #1); lower priority now since drafts are non-canonical and the entropy this guarded against is structurally bounded.
- Garbage-collect stale `.inbox/` drafts (`--gc-drafts` / age-based prune) — v1.2 (Open Q #3).
- Promote draft-capture into a shared template — v1.2 (Open Q #5); only if a second skill needs the intake path.
- Draft-level partial-fix detection (smarter resume row than unconditional Row 1) — v1.2 (Open Q #6 / C5).

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [../F000024_TRACKER.md](../F000024_TRACKER.md)
- Roadmap: [../F000024_ROADMAP.md](../F000024_ROADMAP.md)
- Sibling story (v1.0 single-defect mode): [../S000049_phase1_single_defect_mode/S000049_TRACKER.md](../S000049_phase1_single_defect_mode/S000049_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-portfolio/chjiang-main-design-20260516-133940.md`
- Implementation target: `skills/CJ_goal_investigate/` (workbench source; `skills-deploy install` syncs to `~/.claude/skills/CJ_goal_investigate/`)
