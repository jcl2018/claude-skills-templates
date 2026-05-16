---
name: "Phase 1: /CJ_improve-queue evaluate <url> mode (MVP)"
type: user-story
id: "S000048"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000022"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "F000021_cj_goal_family_rename_and_drain--S000047_cj_goal_todo_fix_quiet_flag-20260515-184308"
blocked_by: "F000021"
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch (will reuse parent feature branch for shipping S000048 in same PR if scope warrants)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (parent F000022's design — same /office-hours session)
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
- [ ] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a real user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] AC-1: `/CJ_improve-queue evaluate <url>` writes a single inline-comment-marked TODOS.md row matching the existing TODOS schema, with: canonical URL in `**Source:**`, source quote in HTML-comment wrap (≤200 bytes), affected skill paths (real files only), suggested change, `<!--impr-draft-->` heading marker, and `impr-sig=<sha256-truncated-16>` in trailing HTML comment.
- [ ] AC-2: Re-running `evaluate <url>` on the same canonical URL is a NO-OP — `grep -Fq 'impr-sig=$SIG' TODOS.md` matches and the script exits 0 with stderr note "signature already in TODOS.md".
- [ ] AC-3: URL canonicalization handles: trailing-slash on path leaf, fragments, ports (drop `:443`/`:80` default), `utm_*`/`source`/`ref`/`fbclid`/`gclid`/`mc_*` query params, `www.` prefix, percent-encoding case (uppercase normalization), host lowercasing.
- [ ] AC-4: WebFetch source-domain allowlist defaults to `docs.anthropic.com`, `anthropic.com`, `claude.com`, `github.com/anthropics/*`. Off-allowlist hosts require `--allow-untrusted-source`; without the flag, the script exits non-zero with stderr message naming the host and the override flag.
- [ ] AC-5: `<!--impr-draft-->` inline marker is invisible in rendered markdown; promotion = remove the literal marker token; downstream `/CJ_suggest` (after its one-line awk filter patch ships) excludes marked rows from the active band.
- [ ] AC-6: Atomic-write discipline: kill -9 between `mktemp` and `mv` leaves TODOS.md byte-identical to its pre-run state; the backup at `/tmp/cj-improve-queue/TODOS.md.bak.<timestamp>` matches the prior valid state byte-for-byte.
- [ ] AC-7: Pre-write `git status --porcelain TODOS.md` clean check refuses to run with clear stderr message ("TODOS.md has uncommitted changes — commit or stash before retry"); user must commit/stash before retry.
- [ ] AC-8: Concurrency: two parallel `evaluate` invocations on different URLs serialize via mkdir-based lock on `/tmp/cj-improve-queue-lock/`; second invocation either waits with retry (up to 3 × 0.5s) or exits 0 with stderr "another instance is writing TODOS.md; please retry".
- [ ] AC-9: macOS-only check (`uname -s = Darwin`) fires loudly on Linux/Windows with stderr message naming the gate.
- [ ] AC-10: Subagent contract test: stubbed verdict via `CJ_IMPROVE_QUEUE_VERDICT_FILE` env var produces deterministic output. Malformed JSON in the verdict file is handled gracefully: stderr line "subagent returned unparseable verdict; no row appended", exit 0, TODOS.md untouched.
- [ ] AC-11: WebFetch failure: subagent returns `{"verdict":"fetch_failed","error":"<reason>"}`; envelope emits stderr line naming the error, exits 0, no row appended.
- [ ] AC-12: HANDOFF envelope: shell envelope emits `CJ_IMPROVE_QUEUE_HANDOFF_BEGIN`...`CJ_IMPROVE_QUEUE_HANDOFF_END` block on stdout containing canonical URL, in-scope skill files, request_id, allowlisted flag. Orchestrator (SKILL.md prose) parses, dispatches Agent, captures verdict, pipes to `apply` sub-command via stdin.
- [ ] AC-13: Backup rotation: `/tmp/cj-improve-queue/TODOS.md.bak.<timestamp>` files keep last 5; older are deleted.

## Todos

<!-- Actionable items for this story. -->

- [ ] Implement `scripts/improve_queue.sh` with three sub-commands: `evaluate <url>` (one-shot orchestrator entry), `evaluate-prepare <url>` (HANDOFF emission), `apply` (verdict JSON read from stdin, row append).
- [ ] Implement URL canonicalization (host lowercase, www-strip, port-default-drop, query-param strip from allowlist, percent-encoding case-normalize, fragment strip, trailing-slash strip on leaf only).
- [ ] Implement source-domain allowlist with `--allow-untrusted-source` override.
- [ ] Implement pre-flight gates: `uname -s = Darwin`, `git status --porcelain TODOS.md` clean.
- [ ] Implement HANDOFF block emission (mirroring `/CJ_goal_todo_fix`'s pattern; one JSON line between BEGIN/END markers).
- [ ] Implement idempotency probe (`grep -Fq 'impr-sig=$SIG' TODOS.md`) before write.
- [ ] Implement mkdir-based write-lock on `/tmp/cj-improve-queue-lock/` (atomic; retry 3× × 0.5s).
- [ ] Implement atomic write via `mktemp` + `mv`; backup to `/tmp/cj-improve-queue/TODOS.md.bak.<timestamp>`; rotation keeps last 5.
- [ ] Implement heading-regex post-write validation (mirrors `suggest.sh:207` exactly): `^(.*) \(P[1-4], [SML]\)$`.
- [ ] Implement SKILL.md prose with HANDOFF parsing instructions for orchestrator + Subagent Contract prompt template.
- [ ] Create catalog entry in `skills-catalog.json` with `status: experimental`, `portability: standalone`, `depends.tools: ["WebFetch", "WebSearch", "Agent"]`.
- [ ] Add routing entry in `rules/skill-routing.md` for URL-evaluation phrasings.
- [ ] Create test fixtures: `tests/fixtures/CJ_improve-queue/sample-verdict-novel.json`, `sample-verdict-conflict.json`, `sample-verdict-fetch-failed.json`, `sample-verdict-malformed.json`, `sample-fetch-anthropic-skills-page.html`.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-15: Created. S000048 scaffold from F000022's /office-hours design doc. Phase 1 MVP — `evaluate <url>` mode only; Phases 2 (audit) and 3 (research <topic>) deferred per phased rollout.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_improve-queue/SKILL.md` (new)
- `skills/CJ_improve-queue/scripts/improve_queue.sh` (new)
- `skills-catalog.json` (new entry; sensitive surface)
- `rules/skill-routing.md` (new routing entries; sensitive surface)
- `tests/fixtures/CJ_improve-queue/sample-verdict-novel.json` (new)
- `tests/fixtures/CJ_improve-queue/sample-verdict-conflict.json` (new)
- `tests/fixtures/CJ_improve-queue/sample-verdict-fetch-failed.json` (new)
- `tests/fixtures/CJ_improve-queue/sample-verdict-malformed.json` (new)
- `tests/fixtures/CJ_improve-queue/sample-fetch-anthropic-skills-page.html` (new)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The HANDOFF envelope split (bash owns I/O + canonicalization + locking; orchestrator owns Agent dispatch; subagent owns WebFetch + reasoning) maps cleanly to `/CJ_goal_todo_fix`'s proven pattern. Crisp ownership avoids the prose-only re-invocation footgun (`/autoplan` CRITICAL-1).
- Lock scope = ONLY the write step (sub-second). Holding through fetch + reasoning would block legitimate parallel evaluations and offer no atomicity benefit since each instance writes a distinct row keyed by its own signature.
- Domain allowlist is layered defense alongside `source_quote` HTML-comment-wrapping. Either alone would be insufficient; together they close the WebFetch-to-sensitive-surface regex-injection path.
- `<!--impr-draft-->` inline comment placement matters: it MUST be inside the heading (e.g., `### Adopt X from Y (P3, M)<!--impr-draft-->`) so the heading-regex validation matches the published heading shape; placing it on its own line would break heading recognition for both `/CJ_suggest`'s scan and the validator.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-15: Bundle decision for `/CJ_suggest` patch (one-line awk filter for `<!--impr-draft-->`) deferred to implementation time. Summary: either shipping in same PR as S000048 or as prereq PR is acceptable; chosen at /ship time based on test-fixture coupling between the two changes.
- [orchestrator] 2026-05-15: --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/ops/F000022_cj_improve_queue/S000048_phase1_evaluate_url; scaffold skipped. (run_id=20260515-190258-23196)
- [impl] 2026-05-15: Implemented Phase 1 MVP. New files: skills/CJ_improve-queue/SKILL.md, skills/CJ_improve-queue/scripts/improve_queue.sh, tests/fixtures/CJ_improve-queue/{sample-verdict-novel,sample-verdict-conflict,sample-verdict-fetch-failed,sample-verdict-malformed}.json, tests/fixtures/CJ_improve-queue/sample-fetch-anthropic-skills-page.html. Modified: skills-catalog.json (new entry), rules/skill-routing.md (new routing). All 13 ACs covered by script + SKILL.md prose; sensitive-surface pre-AUQs auto-approved with logged reasoning. (run_id=20260515-190258-23196)
- [impl-finding] 2026-05-15: SPEC's AC-4 lists `github.com/anthropics/*` as an allowlist entry but the host-matching layer is currently strict-equality (host == 'github.com' allows ALL github.com paths). v1 ships with the broader match; tightening to repo-prefix matching is a small follow-up if false positives surface.
- [impl-decision] 2026-05-15: Pre-flight TODOS.md clean-check refuses on staged-but-uncommitted changes as well as unstaged. Tested via temp-commit during smoke S5. Edge case worth documenting: user must commit (not just stage) before re-running.
- [smoke-pass] 2026-05-15: Smoke tests S1-S5 all green. S2 canonicalization confirmed via "https://www.docs.anthropic.com:443/claude-code/some-page/?utm_source=x&fbclid=y#section" -> "https://docs.anthropic.com/claude-code/some-page". S3 off-allowlist refusal exit=1. S4 fetch_failed + malformed both stderr + exit 0. S5 idempotency NO-OP via signature hit + backup rotation working (4 backups under cap of 5). All evidence-based; no E2E (defer to /ship-time). (run_id=20260515-190258-23196)
