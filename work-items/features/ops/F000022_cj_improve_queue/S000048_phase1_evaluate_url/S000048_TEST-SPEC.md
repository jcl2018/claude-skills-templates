---
type: test-spec
parent: S000048
feature: F000022
title: "Phase 1: /CJ_improve-queue evaluate <url> — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | security | AC-7, AC-9 | Preflight gates fire correctly | Dirty-TODOS.md refuses; non-Darwin refuses | `cd /tmp && touch TODOS.md && echo "uncommit" >> TODOS.md && bash skills/CJ_improve-queue/scripts/improve_queue.sh evaluate https://docs.anthropic.com/ 2>&1; uname -s` |
| S2 | resilience | AC-3 | URL canonicalization | Trailing slash, fragments, query params, www-prefix, default port all normalize as documented | `bash skills/CJ_improve-queue/scripts/improve_queue.sh evaluate-prepare "https://www.docs.anthropic.com:443/p/?utm_source=x#frag" \| grep CJ_IMPROVE_QUEUE_HANDOFF_BEGIN -A1 \| jq -r .canonical_url` |
| S3 | core, security | AC-4 | Allowlist gate | Off-allowlist URL refused without --allow-untrusted-source; on-allowlist proceeds | `bash skills/CJ_improve-queue/scripts/improve_queue.sh evaluate https://random-blog.example.com/x 2>&1 \| grep "is not on the allowlist"` |
| S4 | observability | AC-10, AC-11 | Verdict-handling paths via stub fixtures | match/reject/fetch_failed/malformed/novel/conflict all behave as documented | `for fix in tests/fixtures/CJ_improve-queue/sample-verdict-*.json; do cat "$fix" \| bash skills/CJ_improve-queue/scripts/improve_queue.sh apply 2>&1; done` |
| S5 | core | AC-1, AC-12, AC-13 | Idempotency probe + heading regex + backup rotation | Second run on same URL is NO-OP; row heading matches `^(.*) \(P[1-4], [SML]\)$`; backup retention keeps last 5 | `cat tests/fixtures/CJ_improve-queue/sample-verdict-novel.json \| bash skills/CJ_improve-queue/scripts/improve_queue.sh apply && cat tests/fixtures/CJ_improve-queue/sample-verdict-novel.json \| bash skills/CJ_improve-queue/scripts/improve_queue.sh apply 2>&1 \| grep "signature already in TODOS.md" && ls /tmp/cj-improve-queue/TODOS.md.bak.* \| wc -l` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3, AC-4 | Killer test: real Anthropic docs URL produces a draft TODOS row | (1) Commit any pending TODOS.md changes. (2) Run `/CJ_improve-queue evaluate https://docs.anthropic.com/claude-code/<real-page>`. (3) Open TODOS.md in editor. (4) Verify new row at bottom matches the schema (heading with `<!--impr-draft-->`, source comment-wrapped, signature in trailer). | A single new row appears; `<!--impr-draft-->` is invisible in GitHub preview / rendered markdown; signature is a 16-char hex token in the trailer | Pass = row matches schema exactly; signature present; source quote in HTML comment; rendered markdown shows no draft marker. Fail = any of the above absent or malformed. |
| E2 | usability, core | AC-5 | Promotion to active TODO row | (1) After E1, locate the new row. (2) Edit TODOS.md to remove the `<!--impr-draft-->` token from the heading. (3) Run `/CJ_suggest` (after its awk filter patch ships). | The row appears in `/CJ_suggest`'s ranked top-5 at P3 (orphan path). | Pass = row is ranked at P3, visible in top-5; before promotion it was filtered out. |
| E3 | resilience | AC-6 | Atomic-write under interruption | (1) Background a fake-slow `evaluate` invocation that sleeps between mktemp and mv. (2) `kill -9 $!` between mktemp + mv. (3) Verify TODOS.md is byte-identical to its pre-run state. | TODOS.md SHA-256 = pre-run SHA-256; backup at `/tmp/cj-improve-queue/TODOS.md.bak.<timestamp>` matches | Pass = byte-identical; backup present. Fail = any divergence. |
| E4 | resilience | AC-8 | Concurrency lock contention | (1) Launch two parallel `evaluate` invocations on different on-allowlist URLs. (2) Observe write-step ordering via stderr timestamps. | First acquires lock and writes; second either retries successfully (within 3 × 0.5s) or exits 0 with "another instance is writing TODOS.md; please retry". No mv race; both URLs end up in TODOS.md (or one is told to retry). | Pass = serial writes, no corruption, deterministic outcome. |
| E5 | core, integration | AC-1, AC-5 | End-to-end ship: row -> PR | (1) Run E1 + E2 above. (2) Run `/loop /CJ_goal_todo_fix` (or `/CJ_goal_todo_fix` direct) and let it drain the new row. (3) Wait for PR. (4) Inspect PR commit body. | PR exists in GitHub; commit body cites the source URL from the row's `**Source:**` field. | Pass = PR materializes, source URL present in commit body. Fail = no PR or source missing. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| IDN domain canonicalization (unicode hosts) | Phase 1 user pool is Anthropic docs (ASCII-only); IDN handling defers to v1.1 if encountered | Mis-canonicalization of IDN URLs could produce duplicate rows; observed in killer-test if it ever happens, then patched |
| WebFetch on PDFs / very large pages | Anthropic docs are HTML; subagent emits `fetch_failed` for any non-text response; defer behavior tuning until first encountered | Some legitimate Anthropic content might be PDF-only and silently fail; acceptable v1 risk |
| Subagent reasoning accuracy on edge-case patterns (multi-paragraph, ambiguous, deeply technical) | Subagent is the trust boundary; v1 accepts its verdict with `confidence < 7 -> REVIEW:` prefix as the only safety net | First-run validation gives a real-world calibration data point |
| Cross-machine portability (Linux/Windows users) | macOS gate is loud; non-Darwin is a hard refusal | Users on non-macOS get a clear error message; no silent breakage |
| Behavior when TODOS.md doesn't exist yet | Workbench always has a TODOS.md committed; if missing, script's preflight `git status` would surface it before reaching write | Acceptable; not a real-world failure mode for this workbench |
| Subagent timeout / hang | The orchestrator's Agent dispatch has its own timeout; bash envelope doesn't time out the verdict stdin read because Agent's stdout closes signal completion | Hung Agent surfaces as a no-stdin condition in `apply`; jq parse fails; stderr line + exit 0 (correct behavior) |
| Multiple rows from one URL (subagent returns array) | Subagent contract is one verdict object per invocation; multi-pattern URLs would require a different schema | v1 accepts the one-pattern-per-URL constraint; revisit if Anthropic publishes multi-pattern articles |
