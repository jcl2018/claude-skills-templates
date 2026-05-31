---
type: design
parent: S000062
title: "Marker-pickup AUQ implementation — Story Design"
version: 1
status: Approved
date: 2026-05-30
author: chjiang
reviewers: []
---

<!-- Atomic-story DESIGN.md — brief; the heavy design context lives at the
     parent feature's F000029_DESIGN.md. This stub captures the per-story
     shape just enough that /CJ_personal-workflow check passes (all 7
     standard sections required). -->

## Problem

F000029 needs a single, coherent implementation slice: ship the new `scripts/skills-doc-sync-check` (mirror of `scripts/skills-update-check`), wire it into each of the 3 cj_goal SKILL.md preambles with identical 4-line bash blocks + AUQ-instruction prose, add the flat-convention test file, append the CLAUDE.md sibling subsection, and add the CHANGELOG entry. See parent [F000029_DESIGN.md](../F000029_DESIGN.md) for the full problem framing (why F000028's hook needs an operator-facing AUQ consumer).

## Shape of the solution

One PR with seven touched files:

| Concern | File | Change Type |
|---------|------|-------------|
| Detection script (the runtime artifact) | `scripts/skills-doc-sync-check` | New — mirror `scripts/skills-update-check` |
| Test coverage of the 8 scenarios | `tests/skills-doc-sync-check.test.sh` | New (flat convention) |
| Preamble call + AUQ-instruction prose (skill 1) | `skills/cj_goal_feature/SKILL.md` | Modified — extend Preamble section |
| Preamble call + AUQ-instruction prose (skill 2) | `skills/cj_goal_defect/SKILL.md` | Modified — extend Preamble section (identical block) |
| Preamble call + AUQ-instruction prose (skill 3) | `skills/CJ_goal_investigate/SKILL.md` | Modified — extend Preamble section (identical block) |
| Doc note to operators | `CLAUDE.md` | Modified — add "Doc-sync check mechanism (F000028 follow-up)" sibling subsection below "Update-check mechanism (F000009)" |
| Release note | `CHANGELOG.md` | Modified — F000029 entry |

The bash block in each preamble is verbatim (~4 lines). The AUQ-instruction prose block is also verbatim (~30 lines: copy-paste AUQ template + branch-detection + each option's follow-through). See parent F000029_DESIGN.md and the upstream `~/.gstack/projects/.../chjiang-cj-feat-20260530-222955-29095-design-20260530-223418.md` for the load-bearing decisions (no PID dedup, branch-aware AUQ option ordering, auto-commit on Y).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single PR for all seven file changes; no per-file split. | All seven are mutually load-bearing — script without preamble calls is dead code; preamble calls without the script fail silently; tests must ship with the code they cover; CLAUDE.md note + CHANGELOG are required ship hygiene. Splitting adds review overhead with zero independent value. |
| 2 | Tests at `tests/skills-doc-sync-check.test.sh` (flat), not `tests/skills-doc-sync-check/`. | Parent design Success Criteria explicitly require flat `tests/<name>.test.sh` convention. Matches existing convention; `./scripts/test.sh` picks it up without configuration. |
| 3 | Cache file at `~/.gstack/doc-sync-cache.json`, NOT inside the repo. | Mirrors F000009's `~/.claude/.skills-templates-update.json` location pattern (user-global state, not repo state). Marker file `~/.gstack/doc-sync-pending/<slug>.json` is also user-global per F000028. Keeping cache and marker in the same root makes operator inspection easy (one `ls ~/.gstack/` shows everything). |
| 4 | Subcommand surface mirrors `skills-update-check`: `--snooze [hours]` / `--skip <head_sha>` / `--resolved`. | Operator who's used the update check already knows the verbs. `--resolved` is the only novel addition (update check doesn't need it — upgrade either happens or stays available); for doc-sync, `--resolved` is the natural Y-path closer. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Test fixture needs to create a temp `~/.gstack/doc-sync-pending/` and `~/.gstack/doc-sync-cache.json` without trashing the operator's real state. | Use `mktemp -d` for a fresh fake `$HOME` per test row (`HOME=$TMPDIR bash scripts/skills-doc-sync-check ...`); clean up via `trap`. Cover the test fixture itself with a smoke run before the assertions start. |
| Heredoc-style copy-paste of the AUQ template into the SKILL.md prose risks subtle indentation/quoting drift across the 3 SKILL.md files. | Author once, copy-paste verbatim into the other 2; run `diff` of the 3 prose blocks before commit; QA test step asserts the 3 are identical modulo skill-name comment. |
| Stale-marker test (f) requires constructing a marker with a SHA that isn't in the repo's refs. | Construct fixture: write a marker with `head_sha = "0000000000000000000000000000000000000000"`; assert `rev-parse --verify` fails → script silent-deletes marker → no AUQ. |
| Corrupted-JSON test (g): how malformed before `jq -r '.head_sha // empty'` errors instead of returning empty? | Test with a literal `{` (truncated JSON) and a non-JSON string. Both should land in the stale-SHA path (empty SHA → `rev-parse --verify` fails → silent delete). |
| Branch-aware AUQ option ordering (main vs feature branch) lives in SKILL.md prose; how to test the prose? | E2E test only: invoke `/cj_goal_feature` from a real feature branch, plant a marker, assert the AUQ recommends "Snooze 1h" (not "Run /document-release"). Smoke tests cover the script; prose is exercised at runtime via the actual orchestrator. |

## Definition of done

- [ ] All 12 Acceptance Criteria from [S000062_TRACKER.md](S000062_TRACKER.md) checked off.
- [ ] All 12 P0 requirements from [S000062_SPEC.md](S000062_SPEC.md) implemented.
- [ ] All 8 smoke rows from [S000062_TEST-SPEC.md](S000062_TEST-SPEC.md) pass; all 3 E2E rows verified by operator before `/ship`.
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` both green.

## Not in scope

- `/CJ_goal_todo_fix` preamble call — separate follow-up.
- `/CJ_suggest` / `/CJ_system-health` preamble — out of trigger surface.
- Per-marker snooze — current design is global snooze.

## Pointers

- Parent tracker: [../F000029_TRACKER.md](../F000029_TRACKER.md)
- Parent design: [../F000029_DESIGN.md](../F000029_DESIGN.md)
- Parent roadmap: [../F000029_ROADMAP.md](../F000029_ROADMAP.md)
- Own SPEC: [S000062_SPEC.md](S000062_SPEC.md)
- Own TEST-SPEC: [S000062_TEST-SPEC.md](S000062_TEST-SPEC.md)
- Upstream design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260530-222955-29095-design-20260530-223418.md`
- Architectural precedent: `scripts/skills-update-check` (F000009 mirror)
- Predecessor feature (hook): [../../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md](../../F000028_doc_sync_post_merge_hook/F000028_TRACKER.md)
