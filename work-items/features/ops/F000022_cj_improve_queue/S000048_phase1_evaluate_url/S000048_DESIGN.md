---
type: design
parent: S000048
title: "Phase 1: /CJ_improve-queue evaluate <url> — Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. -->

## Problem

Phase 1 of F000022 (`/CJ_improve-queue`) ships the `evaluate <url>` sub-command — the single highest-value, smallest-surface entry point of the three planned (audit/research deferred). The user has a URL in hand (e.g. a new Anthropic best-practices article) and wants a one-keystroke way to ask "is this pattern in our skills, and if not, where would it apply?" without manually opening the article, scanning every SKILL.md, and writing a TODOS.md row by hand.

For full background on the cross-phase shape and the larger improvement-as-TODO design, see the parent feature's DESIGN at [../F000022_DESIGN.md](../F000022_DESIGN.md).

## Shape of the solution

A new skill at `skills/CJ_improve-queue/` with two surfaces:

1. **`scripts/improve_queue.sh`** — bash envelope owning argument parsing, URL canonicalization, allowlist gate, preflight (macOS + dirty TODOS.md), HANDOFF block emission, idempotency probe, write-lock + atomic `mv`, heading-regex post-write validation, backup rotation. Three sub-commands: `evaluate <url>` (one-shot orchestrator entry), `evaluate-prepare <url>` (HANDOFF emission, exit 0), `apply` (verdict JSON read from stdin, row append).
2. **`SKILL.md`** — main-agent prose driving the three-step flow: invoke `evaluate-prepare` -> parse HANDOFF block -> dispatch `Agent` tool with Subagent Contract prompt -> capture verdict JSON -> pipe to `apply` via stdin.

The subagent (general-purpose) owns `WebFetch` on the canonical URL, reads each in-scope `SKILL.md` file, classifies the pattern (match / conflict / novel / reject / fetch_failed), and emits a strict JSON verdict.

| Concern | Story | Artifact |
|---------|-------|----------|
| Shell envelope (canonicalization, allowlist, locking, write) | S000048 | [S000048_SPEC.md](S000048_SPEC.md) |
| SKILL.md orchestrator prose (HANDOFF parsing, Agent dispatch, verdict piping) | S000048 | [S000048_SPEC.md](S000048_SPEC.md) |
| Test fixtures (verdicts + frozen fetch sample) | S000048 | [S000048_SPEC.md](S000048_SPEC.md) |

This is an atomic story; the parent feature F000022 covers the full design context.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Three-sub-command split (`evaluate`, `evaluate-prepare`, `apply`) inside one script | Mirrors `/CJ_goal_todo_fix`'s envelope; `evaluate` is user-facing one-shot, `evaluate-prepare`/`apply` are testable in isolation (stub verdict via env var bypasses the subagent for CI). |
| 2 | Verdict JSON read from stdin in `apply` (not file path arg) | Avoids writing a per-run verdict file under the repo or `~/.claude/`; consistent with `/CJ_goal_todo_fix`'s precedent (no temp-file writes under sacred dirs). |
| 3 | Heading-regex validation uses the exact `suggest.sh:207` regex | Ensures the appended row is parseable by `/CJ_suggest` immediately on next run; failure restores from backup. Coupling these regexes prevents future drift between writer and reader. |
| 4 | Signature = `sha256(canonical_url + "|" + pattern_name)`, truncated to 16 chars | Pattern name from subagent disambiguates when the same URL is interpreted as proposing different patterns (rare but plausible). 16 chars = 64 bits of collision space, enough for any realistic TODOS.md size. |
| 5 | Test fixtures stub the subagent (CJ_IMPROVE_QUEUE_VERDICT_FILE env var) rather than mocking WebFetch | Subagent is the trust boundary; stubbing at that boundary makes the verdict-handling logic deterministically testable without committing to a specific WebFetch mock contract. Live network exercised manually in killer-test. |
| 6 | Phase 1 emits NO synthetic ID in the heading | Improvement rows flow through `/CJ_suggest`'s existing orphan-row path (no tracker join, +2 unblocked, default P3/M). Closes /autoplan CRITICAL-3 — no regex broadening needed across validator + scaffolder + drain. |
| 7 | Backup retention = last 5 (rotation in `/tmp/cj-improve-queue/`) | Restoring from a backup older than the last 5 evaluate runs is vanishingly rare; keeping more accumulates unused state. Rotation is simple `ls -t \| tail -n +6 \| xargs rm -f`. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| URL canonicalization corner cases (IDN domains, percent-encoded path components with mixed case, multiple consecutive slashes) | First-run validation on real URLs during killer-test (Next Steps #6 in source design); v1 ships the documented rules and accepts the over-match risk. |
| Subagent confidence calibration: when does `confidence: 5` mean "ship REVIEW" vs "reject"? | First-run validation on real URLs; if `REVIEW:` rows dominate, tighten the confidence floor in v1.1 or expose a `--confidence-floor` flag. |
| Allowlist drift: Anthropic might publish on a new domain (e.g., a redirect from a new docs subdomain) that's not in the allowlist | First-run validation; v1 ships fixed allowlist with `--allow-untrusted-source` escape valve. |
| WebFetch behavior on PDFs / non-HTML / large pages | Defer until first encountered; subagent emits `verdict: "fetch_failed"` for any WebFetch error (graceful). |
| `/CJ_suggest` patch coordination: must ship before improvement rows promote, or rows sit in TODOS.md but get ranked through the orphan path with the `<!--impr-draft-->` marker visible-in-grep-but-not-in-rendered-markdown | Decided at /ship time; either order is acceptable. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] All 13 acceptance criteria on [S000048_TRACKER.md](S000048_TRACKER.md) verified green via TEST-SPEC smoke + E2E.
- [ ] `skills-catalog.json` entry shipped with `status: experimental`, `portability: standalone`.
- [ ] `rules/skill-routing.md` includes URL-evaluation phrasings ("evaluate this URL", "is this a good Claude pattern", "should we adopt this") routing to `/CJ_improve-queue evaluate <url>`.
- [ ] `/CJ_personal-workflow check` passes on the scaffolded work-item dir.
- [ ] `scripts/validate.sh` exits 0 after implementation (catalog + frontmatter + structural checks all green).

## Not in scope

- Phase 2 (`audit` — offline repo scan) and Phase 3 (`research <topic>` — WebSearch top-3) — both deferred to future stories on F000022 once Phase 1 usage data is available.
- Per-URL `--allow-untrusted-source` AskUserQuestion prompt — v1 ships single flag; per-URL prompt deferred unless footguns surface.
- `/CJ_suggest` patch (one-line awk filter for `<!--impr-draft-->`) — depending on bundling decision at /ship time, either ships in same PR or as prereq.
- Cross-skill pattern consistency analysis (e.g., do all CJ_* skills use the same TODOS.md hygiene phrasing) — Phase 2 territory.

## Pointers

- Parent tracker: [S000048_TRACKER.md](S000048_TRACKER.md)
- Parent feature design: [../F000022_DESIGN.md](../F000022_DESIGN.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-F000021_cj_goal_family_rename_and_drain-design-20260515-175709.md` (the design's actual subject is F000022 / `/CJ_improve-queue`, not F000021)
- Sibling skill (precedent for HANDOFF envelope): `skills/CJ_goal_todo_fix/SKILL.md` + `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`
- Downstream consumer (orphan-row ranking): `skills/CJ_suggest/scripts/suggest.sh`
