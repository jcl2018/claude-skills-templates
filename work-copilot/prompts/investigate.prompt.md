---
mode: agent
description: "Scoping conversation for a new CJ_company-workflow work item — loads .github/work-copilot/domain/*.md as ambient context, greps the codebase for entities in the user's prompt, walks a 4-question chat (problem, target user, narrowest wedge, key risks), and synthesizes a design-doc at .github/work-copilot/designs/<slug>-design-<datetime>.md with required frontmatter + receipts.investigate block."
tools: ['codebase', 'search', 'searchResults', 'editFiles']
---

# /wc-investigate

Scoping conversation that produces a structured design-doc with the required
YAML frontmatter and a `receipts.investigate` block. Five steps:
(1) read `.github/work-copilot/domain/*.md` as ambient context,
(2) grep/search the target codebase for entities mentioned in the user's
prompt, (3) walk the 4-question scoping conversation in plain chat,
(4) synthesize a design-doc to `.github/work-copilot/designs/<slug>-design-<datetime>.md`,
(5) write `receipts.investigate` into the design-doc's own frontmatter.

This prompt is **build #4 of the work-copilot pipeline**. The
`receipts.investigate` schema below conforms to the contract locked by
`/wc-qa` (S000030) / `/wc-implement` (S000031) / `/wc-scaffold` (S000032) —
same field shapes, same YAML-edit pattern (read whole, parse, merge, write
whole), same design-doc-required invariant that roots `/wc-pipeline`'s
drift-math chain. Downstream prompts (`/wc-scaffold`, `/wc-ship`,
`/wc-pipeline`) consume this schema. If you change the schema fields, update
the downstream prompts in the same PR.

The output is the **starting node** for the pipeline: `/wc-scaffold` consumes
the design-doc + its `receipts.investigate` block as input.

## Usage

```
/wc-investigate <topic>
```

- `<topic>` is required — a short free-form description of what the user
  wants to investigate (e.g. `add a webhook retry queue`,
  `fix the flaky payment test`, `extract billing into its own service`).
- If `<topic>` is omitted: print the usage block above and stop.

## Bundle paths (relative to repo root)

- Domain context (per-target user data): `.github/work-copilot/domain/*.md`
  (the prompt skips `*.template.md` skeleton files)
- Designs output folder: `.github/work-copilot/designs/`
- QA prompt (schema source): `.github/prompts/qa.prompt.md`
- Implement prompt (schema source): `.github/prompts/implement.prompt.md`
- Scaffold prompt (schema source): `.github/prompts/scaffold.prompt.md`

**Anti-hallucination rule:** Use your file-read tool (`codebase`) to Read
these files when you need them. Do NOT recall their contents from memory.
The whole point of receipts is verifying real files against real schemas —
hallucinated rules defeat it.

## Mode

**Walkthrough mode only.** This prompt does NOT have an `--auto` flag.
Copilot has no AskUserQuestion tool and no shell — every conversation step
is plain chat, and the final design-doc write is the only `editFiles` call.
The parent `/office-hours` (Claude side) has a richer AUQ surface; we mirror
the spirit here with plain-chat forcing questions.

## Steps

### 1. Read domain context — ambient

List the contents of `.github/work-copilot/domain/` via `codebase`. For every
file whose name ends in `.md` AND does NOT end in `.template.md`, read it
into memory. Treat each one as ambient context for the conversation.

**Resilience:**
- If `.github/work-copilot/domain/` does not exist: print
  `No domain context found at .github/work-copilot/domain/ — run \`python3 scripts/copilot-deploy.py install <repo>\` first to seed skeletons, or proceed with codebase-only context.`
  Then continue (V1: proceed without domain context).
- If the directory exists but every `.md` is actually a `.template.md`
  skeleton (no user-filled content): print
  `Domain skeletons present but none filled in — proceeding with codebase-only context. Fill .github/work-copilot/domain/<name>.md after this run for richer future investigations.`
  Then continue.
- If a `.md` file's content is empty or whitespace-only: skip it silently.

Capture the list of files actually read as `<domain_files_read>` — a list of
relative paths used as `inputs_read` in the receipt.

### 2. Codebase grep — expand context

From the user's `<topic>`, extract candidate entities to search for:

- Quoted strings (e.g., `"createUser"`, `'webhook-retry'`)
- CamelCase / PascalCase tokens (e.g., `createUser`, `WebhookRetry`)
- snake_case or kebab-case tokens (e.g., `webhook_retry`, `webhook-retry`)
- File paths (anything containing `/` or ending in `.py`, `.ts`, `.go`, `.rs`,
  `.java`, `.rb`, `.md`, etc.)
- Notable terms — nouns the user emphasized (best-effort).

For each candidate (cap at 5 to keep the prompt short), use the `search` tool
(or `searchResults`) over `codebase` to locate references. For each hit,
record the file path + line snippet (1-2 lines of surrounding context).

**Resilience — no matches** (per AC-10): if a candidate has no codebase
matches, print exactly:

```
no codebase matches for <entity> — proceeding with domain context only
```

…and continue. Do NOT abort. Partial context is better than no context.

Capture all hit paths (deduped) as `<codebase_paths_referenced>` — appended
to `inputs_read` in the receipt.

### 3. Scoping conversation — 4 forcing questions

Walk the user through these four questions in plain chat. Ask one at a time;
wait for the user's reply before moving to the next.

> **Q1. Problem statement.** In one sentence: what's the problem we're
> solving (or the opportunity)? Ground it in the domain context and the
> codebase references where you can.

(Wait for reply.)

> **Q2. Target user.** Who feels this problem most acutely? A specific
> persona, role, or system. The narrower the better.

(Wait for reply.)

> **Q3. Narrowest wedge.** What's the smallest possible thing we could
> build/change to make the problem measurably better for that user? A
> one-paragraph wedge — not a roadmap.

(Wait for reply.)

> **Q4. Key risks.** Top 2-3 things that could derail this wedge. For each
> risk, name a next-check (test, prototype, conversation) that would
> reduce it.

(Wait for reply.)

If the user gives a short / hand-waving reply to any question, follow up
once with a focused clarifying ask (e.g. "Can you name the specific
persona?"). After one clarifying round, accept what you have.

Capture each reply as `<reply_1>` through `<reply_4>` for synthesis in
step 4.

### 4. Synthesize design-doc

Derive a slug from the topic + Q1 reply. Slug rules (per AC-9):

- Lowercase only
- Characters: `[a-z0-9_-]+`
- No spaces, no capitals, no punctuation
- Max 40 characters
- Hyphen-separated where possible (kebab-case)

Examples:
- topic `add a webhook retry queue` → slug `webhook-retry-queue`
- topic `fix the flaky payment test` → slug `flaky-payment-test`

Then compute a datetime stamp:

- Format: `YYYYMMDD-HHMMSS` (UTC, no timezone suffix)
- Example: `20260511-152347`

Build the design-doc file path:

```
.github/work-copilot/designs/<slug>-design-<datetime>.md
```

Propose-and-confirm: print the planned path and a short outline of the body
sections in chat:

```
Planned design-doc:
  Path: .github/work-copilot/designs/<slug>-design-<datetime>.md
  Sections:
    - Problem Statement
    - Approaches Considered
    - Recommended Approach
    - Open Questions
    - Success Criteria
  Frontmatter:
    title, generated_by: /wc-investigate, generated_at, status: DRAFT,
    work_item_type: <suggested type>, scaffolded_to: null,
    receipts.investigate (phase 0, inputs_read, outputs, next_legal: [scaffold])

Confirm to write (reply "ok" or describe a revision).
```

Wait for the user's confirmation. If the user requests a revision (different
slug, different work_item_type, different section breakdown), revise the plan
and re-prompt. Do NOT call `editFiles` until the user confirms.

Once confirmed, suggest a `work_item_type` based on the topic + replies:

| Signal in topic / replies | Suggested type |
|--------------------------|----------------|
| "fix", "bug", "broken", "regression" | `defect` |
| "add", "build", "implement" + multi-story scope | `feature` |
| "add", "build", "implement" + single-story scope | `user-story` |
| "refactor", "extract", "rename", "cleanup" + small scope | `task` |
| "review", "audit", "investigate <existing thing>" | `review` |

If ambiguous, ask the user once before writing.

Build the design-doc body. The body sections (Markdown headers) MUST be:

```markdown
## Problem Statement
<synthesized from Q1 + domain context>

## Approaches Considered
<2-3 approaches, each with a one-line tradeoff>

## Recommended Approach
<the chosen approach, with a brief rationale>

## Open Questions
<unresolved items + suggested next checks; pull from Q4>

## Success Criteria
<measurable criteria the wedge will be judged by>
```

### 5. Write design-doc + receipts.investigate — single editFiles write

Compose the full file content: YAML frontmatter + body. The frontmatter MUST
include all of the following (per AC-5):

```yaml
---
title: "<topic, capitalized as a short title>"
generated_by: /wc-investigate
generated_at: "<ISO-8601 UTC, e.g. 2026-05-11T15:23:47Z>"
status: DRAFT
work_item_type: <feature|user-story|task|defect|review>
scaffolded_to: null
receipts:
  investigate:
    phase: 0
    completed_at: "<same ISO-8601 UTC as generated_at>"
    design_doc: ".github/work-copilot/designs/<slug>-design-<datetime>.md"
    inputs_read:
      - <domain_files_read item 1>
      - <domain_files_read item 2>
      - ...
      - <codebase_paths_referenced item 1>
      - ...
    outputs:
      proposed_type: <same as work_item_type>
      scope_summary: "<one-line summary of the narrowest wedge from Q3>"
    next_legal: [scaffold]
---
```

`next_legal: [scaffold]` — investigate's only legal write-phase successor is
scaffold. `/wc-pipeline` is always legal (read-only) but is not listed in
`next_legal`.

Write the file via `editFiles`. This is a single create — no read-merge-write
pattern needed (the file doesn't exist yet).

If the file already exists at the computed path (very unlikely given the
datetime stamp), append a suffix `-2` to the slug and retry once. If the
collision repeats, abort with:

```
/wc-investigate aborted: design-doc path collision at <path>. Re-invoke with a different topic phrasing or move the existing file.
```

### 6. Print summary

Print exactly:

```
/wc-investigate complete: design-doc at .github/work-copilot/designs/<slug>-design-<datetime>.md; work_item_type=<type>; next /wc-scaffold <design-doc-path>.
```

Replace `<slug>`, `<datetime>`, `<type>`, and `<design-doc-path>` with actual
values.

## Receipt schema (locked — downstream prompts depend on this)

```yaml
receipts:
  investigate:
    phase: 0                          # always 0 for investigate (Phase 0 in the lifecycle)
    completed_at: <ISO-8601 UTC>      # when this /wc-investigate run finished
    design_doc: <string>              # relative path to the design-doc file itself (self-reference)
    inputs_read:                      # list of files used as input context
      - <path>
    outputs:
      proposed_type: <string>         # one of feature/user-story/task/defect/review
      scope_summary: <string>         # one-line summary of the narrowest wedge
    next_legal: [<string>, ...]       # phase names the user can legally invoke next; for investigate always ["scaffold"]
```

**Why this lives in the design-doc frontmatter, not a tracker:** at the
`/wc-investigate` step, no work-item tracker exists yet. The design-doc is
the only file. `/wc-scaffold` (S000032) reads this block from the design-doc
frontmatter and copies it verbatim into the new tracker as lineage — that's
how the drift-math chain roots back to the design-doc.

**Schema contract:** these field names and shapes are stable. If you need a
new field, add it; do not rename or remove existing ones without bumping the
schema version (which would require a coordinated update across all six
work-copilot prompts).

## Output contract (do not deviate)

Status tags are the grep-able surface. Match exactly:

| Tag | Meaning |
|-----|---------|
| `/wc-investigate complete:` | One-line summary on success |
| `/wc-investigate aborted:` | Hard-stop (path collision, etc.) |
| `no codebase matches for <entity>` | Resilience message (AC-10) |

Do not invent new tags or restructure the receipt block.

## Parity check

The journal-entry shape and the `receipts.investigate` schema fields are the
acceptance contract. `/wc-scaffold` (S000032) reads this block from the
design-doc frontmatter and copies it verbatim into the new tracker. If you
change the schema fields, `/wc-scaffold` will print stale diagnostics on its
next run. Keep the schema locked unless you're coordinating a downstream
update across all six work-copilot prompts.

## Known limitations (V1)

- **No resume-from-draft:** if the user closes Copilot Chat mid-conversation,
  re-invoking `/wc-investigate` starts fresh. The prior partial design-doc
  (if any) stays as history. V2 candidate (per S000033 SPEC #11): detect
  partial draft and offer to resume.
- **English-only scoping:** the 4 forcing questions are English. V1
  intentional; multi-language is out of V1 scope.
- **No AUQ-style structured replies:** Copilot has no AskUserQuestion tool,
  so questions are plain chat. The 4 forcing questions are the substitute
  for structured prompts.
- **No re-investigate over an existing design-doc:** V1 scaffolds a fresh
  design-doc with a new datetime; the older draft stays as history. To
  revise, hand-edit the existing design-doc or invoke `/wc-investigate`
  again on the same topic (collision-avoidance suffix `-2` will apply if
  needed).
- **Slug derivation is best-effort:** the slug picker is heuristic
  (lowercase, kebab-case, max 40 chars). If the user wants a specific slug,
  they can request a revision at step 4's propose-and-confirm gate.
