# CJ-DOC-RELEASE.md — the /CJ_document-release contract

This is the single canonical, human/agent-facing contract for
`/CJ_document-release` in this workbench: what it does, what it requires, and
what each registered doc must satisfy. The machine config it documents lives
beside it at the repo root in `cj-document-release.json` (the parsed sidecar this
prose explains). A repo is "ready" for doc-release when BOTH this doc and that
config are present — `/CJ_repo-init` enforces both as per-repo prerequisites.

This doc **documents and indexes** the requirement declarations; it does not
absorb them. The declarations stay co-located with what they govern (see
[Declaration-site index](#declaration-site-index)). The runtime-parsed convention
blocks — the tracked-doc manifest and its `requirement:` strings, the
`### Reporting` block, and the `## Registered-doc requirements audit` /
`## cj-document-release.json convention` heading anchors — remain verbatim and
in-place in `CLAUDE.md`, because `validate.sh` Check 15a and the
`/CJ_document-release` Step 6.7 `awk` parse them by literal heading. The
narrative prose in those `CLAUDE.md` sections points here; the load-bearing
blocks stay there.

## Wrapper flow

`/CJ_document-release` (F000036/F000037) is the workbench wrapper around upstream
gstack `/document-release`. It adds three things on top of the upstream doc-sync
pass:

- **`--docs <comma-list>` subset flag** — per-invocation doc filtering, resolved
  against the `categories` map in `cj-document-release.json`. Best-effort,
  documentation-only.
- **Halt-on-red contract** — on upstream failure it emits `[doc-sync-red]` and
  stops, rather than proceeding past a broken doc pass.
- **Doc-only auto-commit gate** — an auto-commit step gated by the per-repo
  whitelist (see below).

Config is loaded BEFORE any audit: `/CJ_document-release` HALTs with
`[doc-sync-no-config]` when `cj-document-release.json` is missing, invalid, or
declares an unsupported `schema_version`.

It is invoked **inline** by the three `cj_goal` orchestrators
(`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`) at **Step 5.5** —
between the QA pass and `/ship` — so documentation updates fold into the same
code PR instead of being chased post-merge. `/ship` Step 18 also dispatches
`/document-release` on every invocation, so a manual `/ship` still lands doc
updates in the PR.

## Doc-only auto-commit whitelist gate

The auto-commit step stages and commits ONLY files matching the
`whitelist_patterns` declared in `cj-document-release.json`. A write to any
**non-whitelisted** path HALTs the wrapper with `[doc-sync-non-doc-write]` — the
wrapper never auto-commits source code or other non-doc artifacts. This keeps
the inline doc-sync step from silently sweeping unrelated working-tree changes
into the code PR.

Because Step 5.5 runs after the feature code is already committed (the
orchestrators commit feature code post-QA, before doc-sync), a dirty
**non-doc** tracked tree at that point is itself a halt condition — commit the
feature code first, then let doc-sync fold in the doc updates.

## cj-document-release.json schema reference

`/CJ_document-release` reads a strict-required per-repo config from
`cj-document-release.json` at the repo root. The file declares which docs the
auto-commit whitelist gate honors AND which categories the `--docs <token>` flag
resolves against.

Schema (v1):

```json
{
  "schema_version": 1,
  "whitelist_patterns": ["glob", "..."],
  "categories": { "name": ["glob", "..."] }
}
```

- `schema_version` — must be `1`. Any other value HALTs with
  `[doc-sync-no-config]`.
- `whitelist_patterns` — a **non-empty array** of globs (`**` = any-depth
  recursion, e.g. `doc/**/*.md`). This is the set of paths the auto-commit gate
  may stage.
- `categories` — a **non-empty object** of named glob lists; each value is a
  non-empty array. The `--docs <token>` flag resolves a token to one category's
  glob list.

`validate.sh` Check 16 enforces this schema when the file exists.
`/CJ_repo-init`'s `verify_docrel` mirrors the same checks (parseable JSON +
`schema_version == 1` + non-empty `whitelist_patterns` + non-empty `categories`
with non-empty array values).

The workbench's own `cj-document-release.json` seeds with the F000036 hardcoded
set plus workbench-specific paths (`doc/**`, `templates/doc-*`). Other repos
adopting `/CJ_document-release` declare their own; `/CJ_repo-init --fix` writes a
generic portable starter (README / CHANGELOG / CLAUDE.md / CONTRIBUTING.md +
`doc/**/*.md`).

Deferred to future v2 schema bumps: per-verb overrides (`categories_by_verb`),
an `audit_class` enum mirror from the tracked-doc manifest, `--docs` negation,
and multi-repo federation.

## Registered-doc requirements audit

The wrapper's **Step 6.7** (ADVISORY — agent-judged, NEVER a hard gate) answers
one question the hard gates structurally can't: **is THIS registered doc up to
date against ITS declared requirement?** It generalizes the shape Check 14
already has for one doc-pair ("is USAGE.md up to date vs its requirement,
SKILL.md?").

### The registered set

1. **Tracked-doc files** — every entry in the `CLAUDE.md` `### Tracked doc/ files
   manifest` block, each carrying a bespoke `requirement:` value. The doc's
   requirement is that `requirement:` string.
2. **Routable skill MDs (active OR experimental)** — every skill returned by
   `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json`
   (the `!= "deprecated"` predicate, deliberately broader than the active-only
   New-skills check, so the audit covers the whole CJ_ family; no hardcoded skill
   count). Each skill's `SKILL.md` is a registered doc; its requirement is the
   skill's optional `doc_requirement` field in `skills-catalog.json`, else the
   shared default below.

### Shared default skill-MD requirement

When a skill has no `doc_requirement`:

> The SKILL.md frontmatter `description` and the documented behavior/steps match
> the skill's current implementation; the skill's USAGE.md is current.

### Optional `doc_requirement` catalog field

A skill MAY declare an optional `doc_requirement` string in its
`skills-catalog.json` entry to OVERRIDE the shared default; absent ⇒ the shared
default applies. Tolerated by `validate.sh` (no closed catalog schema — only
`status` is a closed enum). Authoring guidance: do NOT enumerate step numbers in
the string (a skill that gains a step would self-stale a "Step N–Step M"
requirement).

### Verdict taxonomy

Per registered doc, one verdict:

- `up-to-date` — satisfies its requirement given what the run changed.
- `stale: <one-line why>` — no longer satisfies its requirement.
- `missing-requirement` — the registered doc has no declared requirement (a
  tracked-doc manifest entry lacking a `requirement:` child). SOFT — never a halt.
- `n/a` — registered but out of scope for this run's judgment.

### Surfacing

Step 6.7 emits a `### Registered-doc requirements` block (one verdict line per
registered doc) to its RESULT and writes it to the gitignored scratch file
`.cj-goal-feature/registered-doc-verdicts.md`. The positive line
`Registered-doc requirements: all current` is emitted ONLY when every verdict is
`up-to-date`. The block lands in the PR body's `## Documentation` section via a
post-`/ship` `gh pr edit` step in all three `cj_goal` orchestrators
(`/CJ_goal_feature` Step 4.6, `/CJ_goal_defect` Step 9.5, `/CJ_goal_todo_fix`
Step 5.6; best-effort, never halts).

### Posture and scope

ADVISORY, agent-judged, NEVER a hard gate; no new hard `validate.sh` check.
Scope is the tracked-doc files + the active routable skill MDs. Root convention
docs (the README / CHANGELOG / CLAUDE.md category — and this doc itself) are out
of scope for the registered-doc audit: a root `.md` is in neither the
catalog-skill set nor the tracked-doc manifest, so it is structurally excluded.
This doc's enforcement is `/CJ_repo-init` presence (a per-repo prerequisite like
`TODOS.md`), not the registered-doc audit.

## Declaration-site index

Each requirement stays co-located with what it governs. This doc indexes where
to find each:

| Requirement | Declared in | Read by |
|---|---|---|
| Per-skill SKILL.md requirement | `skills-catalog.json` entry's optional `doc_requirement` field (absent ⇒ shared default) | Step 6.7 registered-doc audit |
| Per-tracked-doc requirement | the `CLAUDE.md` `### Tracked doc/ files manifest` block's `requirement:` child for each `- path:` entry | Step 6.7 registered-doc audit; `validate.sh` Check 15a (presence) |
| Auto-commit whitelist + `--docs` categories | `cj-document-release.json` (`whitelist_patterns`, `categories`) | the wrapper's config loader (`cj-document-release-config.sh`); `validate.sh` Check 16 |
| Root-doc placement (incl. this doc) | `CLAUDE.md` `### Tracked root docs allowlist` (`- path:` / `reason:`) | `validate.sh` Check 17 |

## See also

- `cj-document-release.json` — the machine sidecar this doc explains (root).
- `CLAUDE.md` — `## cj-document-release.json convention`,
  `## Registered-doc requirements audit`, and
  `## /document-release workbench audit conventions` carry the load-bearing,
  runtime-parsed blocks (tracked-doc manifest, `requirement:` strings,
  `### Reporting`); their narrative prose points here.
- `skills/CJ_document-release/SKILL.md` — the wrapper implementation (Step 6.7 is
  the registered-doc audit producer).
- `skills/CJ_repo-init/SKILL.md` — verifies this doc + `cj-document-release.json`
  + `TODOS.md` + `work-items/` as the four per-repo prerequisites.
