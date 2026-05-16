---
type: design
parent: F000022
title: "/CJ_improve-queue — Feature Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_suggest` (v1.1.0) is a tight, deterministic, stateless TODO ranker — exactly what its downstream callers (`/CJ_goal_todo_fix --for-skill cj-goal --limit 15`, `/loop /CJ_goal_todo_fix`) need. It tells you *what's next from the backlog*. It does not tell you *what should be in the backlog in the first place*.

This workbench builds Claude Code skills. Anthropic ships new patterns continuously (tool use, hooks, AskUserQuestion shapes, agent SDKs, claude.md conventions). The repo's skills drift from current best practices, conventions diverge across skills, and external articles that should trigger consolidation work go unnoticed because there's no surface for "here's a URL — does this apply to us?"

The user wants a "proactive improver" that scans three input dimensions — this repo's state, online Claude best-practice sources, and user-supplied URLs — and surfaces improvement work as TODOS.md rows that the existing `/CJ_suggest -> /CJ_goal_todo_fix -> /ship -> /land-and-deploy` pipeline already knows how to consume.

## Shape of the solution

A new skill `/CJ_improve-queue` that lives under `skills/CJ_improve-queue/`. Three planned sub-commands roll out in phases; only Phase 1 ships in v1.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Phase 1: URL evaluation (`evaluate <url>`) | S000048 | [S000048_phase1_evaluate_url/S000048_TRACKER.md](S000048_phase1_evaluate_url/S000048_TRACKER.md) |
| Phase 2: Repo audit (`audit`) | deferred | (post-v1) |
| Phase 3: Topic research (`research <topic>`) | deferred | (post-v1) |

Phase 1 architecture: HANDOFF envelope pattern mirroring `/CJ_goal_todo_fix`. Bash envelope (`scripts/improve_queue.sh`) owns argument parsing, URL canonicalization, allowlist gate, preflight (dirty-check + macOS gate), HANDOFF emission, idempotency probe, write-lock + atomic mv, heading-regex validation. The main agent (orchestrator, driven by SKILL.md prose) parses the HANDOFF block, dispatches `Agent` tool with the Subagent Contract prompt, captures the verdict JSON, pipes it to the `apply` sub-command. Subagent owns WebFetch, semantic comparison, verdict JSON emission.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C (`/CJ_improve-queue` writes rows to TODOS.md) over Approach B (sister skill with sub-modes emitting findings to stdout) | C composes with the user's already-running `/loop /CJ_goal_todo_fix`; B reinvents queue management and produces ephemeral findings. C reuses the existing pipeline's hygiene + ranking for free. |
| 2 | HANDOFF envelope pattern mirroring `/CJ_goal_todo_fix` over prose-only re-invocation contract | (/autoplan CRITICAL-1 fix) Prose-only enforcement is the least-reliable surface; a model skipping the re-invoke leaves orphan request.json with no row written and no error. Crisp owner separation (bash vs orchestrator vs subagent) reduces footgun. |
| 3 | `/tmp/cj-improve-queue/` for backup + lock (matches `/CJ_goal_todo_fix`'s precedent) over `.claude/tmp/` | (/autoplan CRITICAL-2 fix) `~/.claude/` is the user's global config — sacred. Backups should be ephemeral; `/tmp/` is the natural home. |
| 4 | Drop synthetic `I<NNNNNN>` IDs from heading; flow through `/CJ_suggest`'s existing orphan-row path | (/autoplan CRITICAL-3 fix) Avoids broadening `[FSTD][0-9]{6}` regex across validator + scaffolder + drain paths. Orphan rows already have a P3/M default ranking that suits improvement rows. |
| 5 | WebFetch source-domain allowlist default-on; off-allowlist URLs require `--allow-untrusted-source` | (/autoplan CRITICAL-4 fix) Combined with HTML-comment-wrapping the `source_quote`, neutralizes regex-injection attack into `/CJ_goal_todo_fix`'s sensitive-surface preflight. |
| 6 | `<!--impr-draft-->` inline HTML-comment marker over `DRAFT — ` heading prefix | (/autoplan MAJOR-14 fix) Invisible in rendered markdown; promotion = remove marker token (single op, typo-resistant). Simplifies `/CJ_suggest` patch to one-line awk filter. |
| 7 | mkdir-based lockfile over `flock` | (/autoplan MAJOR-6 fix) macOS doesn't ship GNU `flock` by default; mkdir-based locks are atomic, dependency-free, and consistent with `/CJ_goal_todo_fix`'s precedent. |
| 8 | Lock scope = write step only, NOT full fetch+reason+apply | (/autoplan MAJOR-9 fix) Holding the lock through 10-30s of network + reasoning would block legitimate parallel evaluations; sub-second write-lock is sufficient for atomicity. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| F000021 (CJ_run / CJ_goal family rename) must land first to avoid churn against TODOS.md rows that reference legacy command names. | Verified after F000021 merges; F000022 implementation does not begin in parallel. |
| `/CJ_suggest` patch to filter `<!--impr-draft-->`-tagged headings out of the active band is a hard dependency for the promotion UX. Either ships in a follow-on PR before F000022, or bundles with F000022 in the same merge. | Decided during S000048 implementation; either path is acceptable per the phased rollout. |
| Live network is exercised manually in the killer-test (Next Steps #5), not in CI. Stub-based tests via `CJ_IMPROVE_QUEUE_VERDICT_FILE` env var cover the verdict pathway; live WebFetch failure modes are exercised on real URLs in QA. | First-run validation after S000048 ships. |
| Backup rotation in `/tmp/cj-improve-queue/`: accumulating backups over many evaluate runs. v1 keeps last 5; older are deleted. | Verified during S000048 QA. |
| WebFetch availability and behavior in the Claude Code runtime: standard tool, no new MCP setup, but version churn could affect verdict subagent reliability. | First-run validation; revisit if `verdict: "fetch_failed"` rate climbs. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. -->

- [ ] S000048 (Phase 1: `evaluate <url>`) ships with all 9 success criteria green (listed in Acceptance Criteria on F000022_TRACKER.md and itemized on S000048_TRACKER.md).
- [ ] `skills-catalog.json` entry present with `status: experimental`, `portability: standalone`.
- [ ] `rules/skill-routing.md` includes URL-evaluation phrasings routing to `/CJ_improve-queue evaluate <url>`.
- [ ] `/CJ_improve-queue evaluate <real-anthropic-docs-url>` produces a TODOS row that, after marker removal, ranks at P3 via `/CJ_suggest` (orphan path), drains via `/CJ_goal_todo_fix`, and ships as a PR citing the source URL in the commit body.

## Not in scope

- Phase 2 `audit` mode (offline repo scan) — deferred until Phase 1 used on >=3 real URLs.
- Phase 3 `research <topic>` mode (WebSearch + top-3 reasoning) — deferred until Phase 1's subagent reasoning model is observed.
- Migration of any existing TODOS.md rows to the new improvement-row schema — `/CJ_improve-queue` only writes NEW rows; existing rows are untouched.
- Changes to `/CJ_suggest`'s core ranking — the patch to filter `<!--impr-draft-->`-tagged headings is a one-line awk filter, not a ranking change.

## Pointers

- Parent tracker: [F000022_TRACKER.md](F000022_TRACKER.md)
- Roadmap: [F000022_ROADMAP.md](F000022_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-F000021_cj_goal_family_rename_and_drain-design-20260515-175709.md` (filename slug reflects the branch the design was generated on; the design's subject is F000022, not F000021)
- Child user-story: [S000048_phase1_evaluate_url/S000048_TRACKER.md](S000048_phase1_evaluate_url/S000048_TRACKER.md)
- Companion skill (for HANDOFF envelope precedent): `skills/CJ_goal_todo_fix/SKILL.md`
- Downstream consumer: `skills/CJ_suggest/scripts/suggest.sh`
