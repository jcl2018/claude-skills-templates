---
name: CJ_improve-queue
description: "Phase 1 MVP — given a URL to an Anthropic best-practices article, evaluate fit against existing workbench skills via WebFetch + subagent reasoning, then append a draft `<!--impr-draft-->`-marked TODOS.md row that flows through /CJ_suggest -> /CJ_goal_todo_fix -> /ship once the marker is removed. Workbench-only (macOS); allowlist + HTML-comment-wrap defense for WebFetch trust; mkdir-based write lock; atomic mv; backup rotation. Phases 2 (audit) and 3 (research <topic>) deferred."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - WebFetch
  - Agent
---

## Overview

`/CJ_improve-queue evaluate <url>` runs the Phase 1 MVP flow: take an Anthropic
best-practices URL, ask a fresh-context subagent whether the pattern is already
adopted in this workbench, and (on `novel` / `conflict` verdict) append a draft
TODOS.md row marked with the inline `<!--impr-draft-->` HTML comment. The user
promotes the row to active TODO state by deleting the marker token; from there
`/CJ_suggest` ranks it and `/CJ_goal_todo_fix` can drain it end-to-end like any
other row.

Trust split:

```
+----------------+  HANDOFF block  +-------------------+  Agent prompt  +------------+
| bash envelope  | --------------> | orchestrator      | -------------> | subagent   |
| (this script)  |                 | (this SKILL.md)   |                | (general-  |
|                | <-- verdict --- |                   | <-- JSON ----- |  purpose)  |
| bash apply     |   on stdin      +-------------------+                +------------+
+----------------+
```

- **Bash envelope** (`scripts/improve_queue.sh`): deterministic I/O, canonicalization, allowlist, locking, atomic write. No network reads.
- **Orchestrator** (this prose): parses the HANDOFF block, dispatches Agent, pipes verdict back into `apply` via stdin.
- **Subagent** (general-purpose, fresh context): WebFetch + reasoning. Emits a strict JSON verdict.

## Routing

Invoke this skill when the user says any of:

- "evaluate this URL"
- "is this a good Claude pattern"
- "should we adopt this"
- "/CJ_improve-queue evaluate <url>"

## Step 1: Validate args + invoke the envelope

The user invokes `/CJ_improve-queue evaluate <url>` (optionally with `--allow-untrusted-source`).

Run from the workbench repo root:

```bash
bash skills/CJ_improve-queue/scripts/improve_queue.sh evaluate-prepare "<url>" [--allow-untrusted-source]
```

Note: invoke `evaluate-prepare` (NOT `evaluate`) from this orchestrator path —
`evaluate-prepare` does only preflight + canonicalization + HANDOFF emission
and exits 0. `evaluate` is reserved for the one-shot user-facing entry that
short-circuits via `CJ_IMPROVE_QUEUE_VERDICT_FILE` in tests.

Capture stdout. If the script exits non-zero, surface the stderr message verbatim
and stop. Preflight failures (`TODOS.md has uncommitted changes`, off-allowlist
host without override, non-Darwin) print to stderr and stop the run cleanly.

## Step 2: Parse the HANDOFF block

The script emits exactly one block of this shape on stdout:

```
CJ_IMPROVE_QUEUE_HANDOFF_BEGIN
{"canonical_url":"...","in_scope_skill_files":["skills/.../SKILL.md", ...],"request_id":"...","allowlisted":true}
CJ_IMPROVE_QUEUE_HANDOFF_END
```

Extract the JSON line between the BEGIN/END markers. The JSON has these keys:

- `canonical_url` (string) — normalized URL the subagent will WebFetch.
- `in_scope_skill_files` (array of strings) — every workbench `skills/*/SKILL.md` the subagent should read for pattern-fit analysis.
- `request_id` (string) — opaque UUID for tracing.
- `allowlisted` (boolean) — `true` if the URL host is on the default allowlist; `false` if `--allow-untrusted-source` was passed for an off-list host.

## Step 3: Dispatch the Agent subagent

Spawn an Agent subagent with `subagent_type: general-purpose`. The prompt
template (stable preamble first, variable tail last):

```
ROLE: pattern-fit evaluator for Anthropic best-practices articles.

TASK:
  1. WebFetch the canonical URL below.
  2. Read each in-scope SKILL.md listed below.
  3. Classify the article's primary pattern against the workbench's existing
     skills. Pick exactly one verdict:
       - "match"        — pattern is already adopted by ≥1 skill (cite which).
       - "conflict"     — pattern conflicts with how a skill solves the same
                          problem today; merits a TODO to reconcile.
       - "novel"        — pattern is not in the workbench and is a good fit.
       - "reject"       — pattern is real but not a fit (cite reason).
       - "fetch_failed" — WebFetch errored or returned non-text content.
  4. Emit a single JSON object on stdout matching the schema below.

CONSTRAINTS:
  - Quote no more than 200 bytes from the article in `source_quote`. Trim
    aggressively. The string will be wrapped in an HTML comment by the
    envelope; trust assumption is that it does not contain the literal
    sequence "-->" (the envelope neutralizes this defensively, but minimize
    surface).
  - `pattern_name` is a short noun phrase (e.g., "subagent contract testing",
    "atomic-mv write discipline"). Avoid jargon-laden multi-clause phrases.
  - `short_source_name` is a 1-3 word handle for the source (e.g.,
    "anthropic-docs", "claude-code-blog").
  - `affected_skills` is an array of paths from the in-scope list (NOT
    invented paths). For "novel", pick the 1-5 skills where the pattern
    would best apply. For "conflict", pick the skills that today solve
    the same problem differently. For "match"/"reject", pick the cited
    skills (may be empty for "reject").
  - `suggested_change` is one sentence describing what to do, NO code.
    If your confidence is < 7, the envelope will prefix it with
    "REVIEW:" automatically — do NOT add the prefix yourself.
  - `confidence` is an integer 1-10. Be honest. The envelope uses < 7
    to mark the row for human review.

RETURN CONTRACT — emit a single JSON object on stdout, no prose before or after:

{
  "verdict": "match" | "conflict" | "novel" | "reject" | "fetch_failed",
  "canonical_url": "<echo back from input>",
  "pattern_name": "<short noun phrase>",
  "short_source_name": "<1-3 word handle>",
  "affected_skills": ["skills/.../SKILL.md", ...],
  "suggested_change": "<one sentence>",
  "source_quote": "<≤200 byte verbatim quote from the article>",
  "confidence": <integer 1-10>,
  "error": "<only present if verdict=fetch_failed; describe the WebFetch error>"
}

INPUTS (substitute below):
  canonical_url: <CANONICAL_URL>
  in_scope_skill_files: <JSON_ARRAY_FROM_HANDOFF>
```

Substitute `<CANONICAL_URL>` and `<JSON_ARRAY_FROM_HANDOFF>` from the parsed
HANDOFF block.

## Step 4: Capture the verdict + pipe to `apply`

Extract the JSON object from the subagent's stdout. The subagent's contract is
"emit a single JSON object" — if multiple JSON objects appear or if the output
is wrapped in markdown code fences, peel the outermost JSON object cleanly.

If the subagent emits no parseable JSON, treat it as a `fetch_failed` with
`error: "subagent returned no parseable JSON"` and synthesize the verdict
locally before passing to apply. The envelope's `apply` step handles malformed
verdicts gracefully (stderr line, exit 0, no row appended), so passing the
subagent's literal output through is also safe.

Run:

```bash
echo '<VERDICT_JSON>' | bash skills/CJ_improve-queue/scripts/improve_queue.sh apply
```

Capture stdout + stderr; surface to the user.

## Step 5: Summarize the outcome

After `apply` returns, print a one-line summary to the user:

- On `novel` / `conflict` (row appended): "appended draft row impr-sig=<SIG>; remove `<!--impr-draft-->` from the heading in TODOS.md to promote."
- On `match` / `reject` (no row appended): "no row appended (verdict=<V>): <reason from stderr>."
- On `fetch_failed`: "fetch failed: <error>; no row appended."

## Test mode (CI / fixtures)

For deterministic regression testing, set `CJ_IMPROVE_QUEUE_VERDICT_FILE` to a
path containing a stub verdict JSON file:

```bash
CJ_IMPROVE_QUEUE_VERDICT_FILE=tests/fixtures/CJ_improve-queue/sample-verdict-novel.json \
  bash skills/CJ_improve-queue/scripts/improve_queue.sh evaluate "https://docs.anthropic.com/some-page"
```

The envelope's `evaluate` sub-command honors the env var by skipping HANDOFF
emission + Agent dispatch and feeding the stub directly to `apply`. Preflight
gates (Darwin, dirty TODOS.md) still fire.

## Acceptance & test surface

See `S000048_SPEC.md` Story #1-#13 and `S000048_TEST-SPEC.md` Smoke S1-S5 / E2E
E1-E5 for the full contract.

## Error handling

| Error | Surface | Recovery |
|---|---|---|
| TODOS.md has uncommitted changes | stderr from envelope, exit non-zero | `git stash` or commit TODOS.md, then retry |
| Off-allowlist host | stderr from envelope, exit non-zero | re-run with `--allow-untrusted-source` if you trust the source |
| Non-Darwin OS | stderr from envelope, exit non-zero | run on macOS (v1 is workbench-only) |
| Lock contention | stderr "another instance is writing TODOS.md; please retry", exit 0 | wait a second and retry |
| Subagent returns malformed JSON | stderr "subagent returned unparseable verdict; no row appended", exit 0 | re-run; if reproducible, inspect subagent output |
| Heading-regex validation failure | stderr "heading regex validation failed; restoring from <backup>", exit 1 | inspect /tmp/cj-improve-queue/ backup; the envelope already restored TODOS.md |
