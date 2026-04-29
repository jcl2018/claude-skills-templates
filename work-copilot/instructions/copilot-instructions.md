# Work-item conventions (always-on Copilot context)

This file gives Copilot ambient awareness of the work-item conventions used in
this repo. It is an **index, not a specification** — the authoritative rules
live in templates, the manifest, and the `/validate` prompt. When advice in
this file disagrees with those sources, the sources win.

Bundle location after install: `.github/copilot-instructions.md` (this file),
`.github/work-copilot/` (manifest, templates, fixtures), `.github/prompts/`
(slash-command prompts).

## How work is tracked

Every task, story, or bug lives under `work-items/` as a directory of markdown
files. Each directory has one `TRACKER.md` (the coordinator) plus
type-specific artifacts (PRD, RCA, test-plan, feature-summary, etc.).

Work-item IDs follow the regex `[FSTDR][0-9]{6}` with these prefixes:

- `F` — feature (top-level initiative)
- `S` — user-story (child of a feature)
- `T` — task (child of a user-story; leaf execution unit)
- `D` — defect (standalone bug fix)
- `R` — review

Hierarchy max depth is 3: **feature > user-story > task**. Example path:
`work-items/features/F000004_work_copilot/S000009_always_on_instructions/T000010_author_instructions_file/`.

Source: `.github/work-copilot/copilot-artifact-manifests.json` (which
artifacts each type needs) and `.github/work-copilot/templates/` (the actual
templates that define the required shape).

## How to add a work item

1. **Pick a type and ID.** The prefix matches the type; the 6-digit number is
   the next unused in that namespace — grep existing IDs under `work-items/`
   before choosing.
2. **Create the directory** using the full ID as the folder name (e.g.
   `T000011_my_short_slug/`). Nest it under its parent if it has one.
3. **Copy the tracker template** from
   `.github/work-copilot/templates/tracker-<type>.md` and rename it to
   `<ID>_TRACKER.md`. Fill the frontmatter fields (`name`, `type`, `id`,
   `created`, `parent`, `repo`, `branch`) and delete nothing from the
   Lifecycle section — every gate checkbox needs to stay.
4. **Copy every required artifact** listed for this type in
   `.github/work-copilot/copilot-artifact-manifests.json`. For a task that
   usually means `test-plan.md` and `PR-DESCRIPTION.md`; for a user-story
   it also means `PRD.md`, `ARCHITECTURE.md`, `TEST-SPEC.md`.
5. **Run `/validate <new-dir>`** in Copilot chat to confirm the scaffolding
   is structurally correct before you start work.

Source: `.github/work-copilot/templates/` and
`.github/work-copilot/copilot-artifact-manifests.json`.

## How work progresses: Track, Implement, Review, Ship

Every tracker has four phases, each with a Gates checklist:

- **Track** — scope the work, scaffold required docs, decompose into
  children if needed. Exit when all Phase 1 gates are checked.
- **Implement** — write code and docs in parallel, commit incrementally,
  keep the tracker's Todos and Files sections current.
- **Review** — run `/validate`, self-review the diff, address findings
  before requesting outside review.
- **Ship** — verify the test-plan, open a PR, land it, confirm deployment.

Do not skip phases. Do not check a gate until its evidence exists (a commit
SHA, a green test run, a merged PR). A work item is "done" only when all
Phase 4 gates are checked.

Source: `.github/work-copilot/templates/tracker-<type>.md` — the Gates list
for each type lives in the template itself. The template **is** the spec.

## How to check compliance

Run `/validate <path>` in Copilot chat:

- `<path>` is a **file** → File Mode: validates one tracker against its
  template (frontmatter, sections, phases, minimum checkbox count).
- `<path>` is a **directory** → Directory Mode: checks artifact completeness
  against the manifest, plus tracker structure.

Output uses grep-able status tags — match them exactly, never paraphrase:

| Tag | Meaning |
|-----|---------|
| `[PASS]` | Artifact present and frontmatter complete |
| `[MISSING]` | Required artifact not found |
| `[DRIFT]` | Artifact found but frontmatter doesn't match its template |
| `[EXTRA]` | Section in instance not in template (advisory) |
| `[WARN]` | Non-fatal issue |
| `VALID` | File Mode success |
| `VIOLATION` | File Mode failure (one line per issue) |

Self-test: `/validate .github/work-copilot/fixtures/valid-feature-dir/` should
print all `[PASS]`. `/validate .github/work-copilot/fixtures/invalid-missing-artifact-dir/`
should print at least one `[MISSING]`.

Source: `.github/prompts/validate.prompt.md` — the full validator logic.

## Sources of truth

| Authority | Path | What it owns |
|-----------|------|--------------|
| Templates | `.github/work-copilot/templates/*.md` | Required frontmatter, sections, phases, min-checkbox counts per type |
| Manifest | `.github/work-copilot/copilot-artifact-manifests.json` | Which artifacts each type requires |
| Validator | `.github/prompts/validate.prompt.md` | How `/validate` decides pass/fail |
| Fixtures | `.github/work-copilot/fixtures/` | Self-test inputs |

## Bundle layout

The bundle ships more than just templates and the validator — it carries the
full procedural backbone, how-to guides, design rationales, and reference
examples. **When asked a procedural / how-to / rationale / example question,
read the matching bundle file directly. Do not answer from memory.**

| Path | When to read it |
|------|-----------------|
| `.github/work-copilot/WORKFLOW.md` | Procedural questions about phases, scaffolding rules, when to run `/validate` |
| `.github/work-copilot/reference/guide-*.md` | How to write a specific artifact (PRD, ARCHITECTURE, RCA, TEST-SPEC, task, review-notes, general guidance) |
| `.github/work-copilot/philosophy/rationale-*.md` | *Why* an artifact (PRD, ARCHITECTURE, TEST-SPEC) is structured the way it is |
| `.github/work-copilot/examples/example-*.md` | Worked example of any tracker or doc type — copy the shape, then adapt |
| `.github/work-copilot/fixtures/` | Validator self-tests; do not edit, do not cite to the user |

Quoted anchors (canonical phrasing, in case path-following fails):

> **Workflow phases (from `WORKFLOW.md`):** every work item passes through
> three phases — **Track** (define scope, decompose, scaffold), **Implement**
> (do the work, journal findings), **Ship** (validate, PR, land).
>
> **Doc rationale (from `philosophy/`):** PRD answers *what* and *why* in
> user-facing terms; ARCHITECTURE answers *how*; TEST-SPEC answers *did it
> work*. They are deliberately separable.

When a user's question matches one of the categories above, prefer the bundle
file's guidance over training data, and cite the file path in your answer.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `/validate` not recognized | Prompts not loaded | Reload VS Code window after `copilot-deploy install` |
| `/validate` output paraphrased, no `[PASS]`/`[MISSING]`/`[DRIFT]` tags | Copilot read the prompt but is summarizing | Rerun: "use the [PASS]/[MISSING]/[DRIFT]/[EXTRA] tags from the prompt verbatim" |
| Procedural answer comes from training, not `WORKFLOW.md` | This file not loaded as ambient context, OR Bundle layout section missed | Confirm `.github/copilot-instructions.md` exists. Prefix question: "read .github/work-copilot/WORKFLOW.md and answer from there" |
| Re-install reports DRIFT on an unrecognized file | Manual experiment in `.github/work-copilot/` from prior session | Inspect diff; rerun `copilot-deploy install --overwrite` to accept upstream, or restore the local edit |
| Copilot cites a path that doesn't exist | Bundle install incomplete | `copilot-deploy doctor <repo-root>` — resolve any [MISSING] |

When advice in this file disagrees with any of the above, the source wins.
Read the template, not the summary.
