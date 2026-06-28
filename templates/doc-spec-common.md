<!-- DOC-SPEC-COMMON:BEGIN (portable — keep byte-identical across adopting repos) -->
# doc-spec.md — what docs this repo carries

This file is the single answer to two questions: **what documents does this
repo carry, and what is each one for?** The Markdown table at the end IS the
machine source of truth — `scripts/doc-spec.sh` parses it directly. A human
reads the same table. One artifact, no second list to keep in sync.

This file is the **general tier** of a two-tier contract, delivered verbatim
(`doc-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific docs are declared
in an optional **`doc-spec-custom.md` overlay** next to this file (the same
3-column table grammar). The parser merges the two internally, so every
consumer sees ONE registry; a repo without an overlay simply carries the
general contract alone. Nothing about the repo's other tooling has to change.

## The doc contract

Every repo that adopts this contract carries the ten **general docs** listed
in the registry table below — sub-grouped here for the reader.

**Human docs** — what a person (not just an agent) reads to understand the
project: `docs/philosophy.md`, `docs/workflow.md`, `docs/architecture.md`,
`README.md`, plus every per-workflow file under `docs/workflows/`. A declared
doc whose path is under `docs/`, or the root `README.md`, is treated as a
**human doc**: it must exist and must carry **no work-item IDs** (a reference of
the shape `<F|S|T|D>` followed by six digits is internal-tracker noise; this is
a hard CI lint, not a guideline).

`docs/workflow.md` is an **overview/index**: it names + links every major
workflow, and the deep per-workflow detail (flowcharts, touches, steps) lives
one level down under `docs/workflows/<name>.md`. In an adopting repo
`docs/workflows/` is **required and non-empty**, and every `docs/workflows/*.md`
is a human doc that must be declared in the (merged) registry.

**Operational docs** — agent- and ops-facing, so they may reference work
items: `spec/doc-spec.md` (this file), `spec/test-spec.md`, `CLAUDE.md`,
`CHANGELOG.md`, `TODOS.md`. Every declared path that is NOT a human doc is
operational.

Two rules make these docs trustworthy:

- **General docs are required.** Every general doc must exist in an adopting
  repo; the doc-release skill stub-scaffolds any missing one. Overlay docs
  (declared in `doc-spec-custom.md`) are the repo's chosen additions.
- **The registry is the source of truth.** The table below — merged with the
  overlay's, when one exists — declares every doc the repo carries. Tooling
  parses it; the prose explains it. Add a doc by adding a table row — never by
  editing a second list somewhere else.

## How the registry is used

Two consumers parse the merged table (this file + the overlay):

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` (recursively — including `docs/workflows/`) and `spec/` is
  declared (no orphans), that `docs/workflows/` exists and is non-empty, that
  every root `*.md` is declared, and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `Requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + the contract files + `docs/**/*.md`).

## The canonical contract-file template

The audit verbs (`/CJ_doc_audit`, `/CJ_test_audit`) own this contract's
canonical shape — what files are required, where they live, and their format:

- **Required** — the general file of each pair: `spec/doc-spec.md` (this file)
  and `spec/test-spec.md`. Each is delivered verbatim by its engine's `--seed`
  and must exist in an adopting repo (the audit seed-delivers a missing one).
- **Optional** — the `*-custom.md` overlay next to each general file
  (`spec/doc-spec-custom.md`, `spec/test-spec-custom.md`): the repo's chosen
  additions, merged in by the parser. A repo without an overlay carries the
  general contract alone.
- **Position** — `spec/` is canonical; the repo root is an accepted fallback
  (`doc-spec.md` / `test-spec.md`) for root-style consumers. The engine
  resolves `spec/`-then-root.
- **Format** — a 3-column Markdown table (`| Doc | Purpose | Requirement |`)
  for doc-spec; a single fenced `yaml` registry for test-spec. The table /
  block IS the source of truth, parsed directly.

`doc-spec.sh --classify` reports a file's generation (canonical / legacy /
absent / duplicated); `doc-spec.sh --reconcile` migrates a legacy file to this
canonical shape preserving every declared row.

## The registry (machine source of truth)

The table below is the source of truth. It has three columns —
**Doc** (the repo-relative path), **Purpose** (what the doc is for), and
**Requirement** (what makes the doc current). Add a doc by adding a row; a
path under `docs/` or the root `README.md` is a human-doc (no work-item IDs),
everything else is operational. Cells may not contain a literal `|`.

| Doc | Purpose | Requirement |
|-----|---------|-------------|
| `docs/philosophy.md` | Major design logic, one '## Principle N' section each. | Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs. |
| `docs/workflow.md` | Overview/index that names + links every major workflow; per-workflow detail lives under docs/workflows/. | Overview/index that names + links every major workflow a human would invoke; per-workflow detail (flowcharts, touches, steps) lives under docs/workflows/<name>.md; no work-item IDs. |
| `docs/architecture.md` | Meaningful infra under the hood, deeper than workflow.md. | Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs. |
| `README.md` | Repo landing page: folder structure + how to get started. | Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs. |
| `docs/reference.md` | Curated external references for building this workbench — repos, docs, blogs, articles — grouped by category. | Lists useful external references (repos / links / blogs / articles) relevant to building this workbench, grouped by category, each with a one-line note on why it is relevant; human-readable; no work-item IDs. |
| `spec/doc-spec.md` | The doc contract itself (this file — the general tier, delivered verbatim by doc-spec.sh --seed). | Present; byte-identical to the portable seed (doc-spec.sh --seed); the registry table parses; repo-specific docs live in the optional doc-spec-custom.md overlay, never in this file. |
| `spec/test-spec.md` | The general test contract — portable rules for the repo's verification surface (parsed by test-spec.sh). | Present; rules current against the live verification surface; registry parses with schema_version 1; repo-specific units live in the optional test-spec-custom.md overlay. |
| `CLAUDE.md` | Agent operating instructions (auto-loaded by Claude Code). | Present; work-item references allowed (operational doc). |
| `CHANGELOG.md` | Release history (keep-a-changelog). | Present; updated by /ship + /document-release. |
| `TODOS.md` | The operational backlog. | Present; work-item references allowed (operational doc). |
<!-- DOC-SPEC-COMMON:END -->
