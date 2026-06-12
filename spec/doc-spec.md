<!-- DOC-SPEC-COMMON:BEGIN (portable — keep byte-identical across adopting repos) -->
# doc-spec.md — what docs this repo carries

This file is the single answer to two questions: **what documents does this
repo carry, and what is each one for?** It is both the human-readable map (the
prose below) and the machine source of truth (the fenced `yaml` registry at the
end). One file, no second list to keep in sync.

This file is the **general tier** of a two-tier contract, delivered verbatim
(`doc-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific docs are declared
in an optional **`doc-spec-custom.md` overlay** next to this file (the same
fenced-yaml grammar, `section: custom` entries). The parser merges the two
internally, so every consumer sees ONE registry; a repo without an overlay
simply carries the general contract alone. Nothing about the repo's other
tooling has to change.

## The doc contract

Every repo that adopts this contract carries eleven **general docs** — the
`section: common` tier, sub-grouped below.

**Human docs** — what a person (not just an agent) reads to understand the
project:

| Doc | What it is for |
|-----|----------------|
| `docs/philosophy.md` | The major design logic — one `## Principle N` section per idea. States the repo's first principle(s). |
| `docs/workflow.md` | The major workflows from a human's point of view; names the major entry points. ASCII flowcharts preferred. |
| `docs/architecture.md` | The meaningful machinery under the hood — deeper than `workflow.md`. ASCII diagrams preferred. |
| `README.md` | The landing page: folder structure + how to get started. |

**Operational docs** — agent- and ops-facing, so they may reference work items:

| Doc | What it is for |
|-----|----------------|
| `spec/doc-spec.md` | The doc contract itself — this file (tooling resolves `spec/doc-spec.md` first, then a root `doc-spec.md` fallback). |
| `spec/test-spec.md` | The general test contract — the portable rules the repo's verification surface is held to (same two-tier shape: a `test-spec.sh --seed` general file + an optional `test-spec-custom.md` overlay). |
| `CLAUDE.md` | Agent operating instructions. |
| `CHANGELOG.md` | Release history, updated on every release. |
| `TODOS.md` | The operational backlog. |

**Generated views (human docs)** — readable lists derived from the registry, so
there is never a second list to hand-maintain:

| Doc | What it is for |
|-----|----------------|
| `docs/doc-general.md` | Readable list of the `section: common` (general) docs. |
| `docs/doc-custom.md` | Readable list of the `section: custom` docs. |

Three rules make these docs trustworthy:

- **General docs are required.** Every `section: common` doc must exist in an
  adopting repo; the doc-release skill stub-scaffolds any missing one.
  `section: custom` docs (declared in the overlay) are the repo's chosen
  additions.
- **Human docs carry no work-item IDs.** A reference of the shape
  `<F|S|T|D>` followed by six digits is internal-tracker noise; it does not
  belong in a doc a newcomer reads. This is enforced (a hard CI lint), not a
  guideline.
- **The registry is the source of truth.** The `yaml` block below — merged with
  the overlay's, when one exists — declares every doc the repo carries. Tooling
  parses it; the prose explains it. Add a doc by adding a registry entry —
  never by editing a second list somewhere else.

## How the registry is used

Two consumers parse the merged `yaml` registry (this file + the overlay):

```
  doc-spec.md (general — this file)   doc-spec-custom.md (optional overlay)
  ┌───────────────────────────┐       ┌──────────────────────────────┐
  │ Common prose               │       │ repo-specific prose          │
  │ yaml machine registry      │       │ yaml registry — section:     │
  │   schema_version: 1        │       │   custom entries in the      │
  │   docs[]: path / section / │       │   same grammar               │
  │     audit_class / purpose /│       └───────────────┬──────────────┘
  │     requirement /          │                       │
  │     front_table (optional) │                       │
  └───────────┬────────────────┘                       │
              └────────────────┬───────────────────────┘
                               │ merged by the parser (duplicate path ⇒ error)
                ┌──────────────┴───────────────┐
                │ parses                       │ parses
    ┌───────────▼──┐                     ┌─────▼─────────────────┐
    │ a CI validator│                     │ a doc-release skill   │
    │ declared ⇔    │                     │ self-bootstrap missing│
    │  on-disk      │                     │  doc-spec.md          │
    │ schema valid  │                     │ stub missing docs     │
    │ no work-item  │                     │ audit each vs its     │
    │  IDs in human │                     │  requirement          │
    │  docs         │                     │ derive doc whitelist  │
    └───────────────┘                     └───────────────────────┘
```

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` is declared (no orphans), that the merged registry schema
  is valid, and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + the contract files + `docs/**/*.md`).

## audit_class (closed enum)

Each registry entry declares one `audit_class`:

- **`human-doc`** — human-facing. Must exist; must contain **no work-item IDs**
  (`[FSTD]NNNNNN`); ASCII flowcharts/diagrams preferred (advisory).
- **`operational`** — must exist; work-item references are allowed (these are
  agent/ops docs, e.g. a changelog or an agent-instructions file).

## front_table (optional field)

A registry entry MAY carry `front_table: required` — enforced only where the
field is present. A flagged doc must **open with a summary table**: the first
Markdown table (a `|`-row immediately followed by a `|---|`-style delimiter
row) must appear **before the doc's first `## ` heading**, giving a reader an
at-a-glance index. The gate asserts a leading table only — it does not
prescribe the table's columns. The seed flags `docs/philosophy.md` (a row per
principle) and `docs/workflow.md` (a row per major workflow/entry point); a
stub-scaffolded copy of a flagged doc must therefore open with a summary
table. Flagging another doc later is a one-line registry edit — no validator
change.

<!-- DOC-SPEC-COMMON:END -->

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file.

```yaml
# doc-spec registry (parsed by scripts/doc-spec.sh; merged with the optional
# doc-spec-custom.md overlay; consumed by a CI validator + a doc-release skill)
schema_version: 1
docs:
  - path: docs/philosophy.md
    section: common
    audit_class: human-doc
    front_table: required
    purpose: "Major design logic, one '## Principle N' section each."
    requirement: "Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs; opens with a summary table at the top listing every principle."
  - path: docs/workflow.md
    section: common
    audit_class: human-doc
    front_table: required
    purpose: "The major workflows from a human's perspective; names the major entry points."
    requirement: "Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs; opens with a summary table at the top listing every major workflow/entry point."
  - path: docs/architecture.md
    section: common
    audit_class: human-doc
    purpose: "Meaningful infra under the hood, deeper than workflow.md."
    requirement: "Explains the load-bearing machinery deeper than workflow.md; ASCII diagrams preferred; no work-item IDs."
  - path: README.md
    section: common
    audit_class: human-doc
    purpose: "Repo landing page: folder structure + how to get started."
    requirement: "Has a folder-structure section and a getting-started section naming the major workflows; no work-item IDs."
  - path: spec/doc-spec.md
    section: common
    audit_class: operational
    purpose: "The doc contract itself (this file — the general tier, delivered verbatim by doc-spec.sh --seed)."
    requirement: "Present; byte-identical to the portable seed (doc-spec.sh --seed); registry parses with schema_version 1; repo-specific docs live in the optional doc-spec-custom.md overlay, never in this file."
  - path: spec/test-spec.md
    section: common
    audit_class: operational
    purpose: "The general test contract — portable rules for the repo's verification surface (parsed by test-spec.sh)."
    requirement: "Present; the general test contract — rules current against the live verification surface; registry parses with schema_version 1; repo-specific units live in the optional test-spec-custom.md overlay."
  - path: CLAUDE.md
    section: common
    audit_class: operational
    purpose: "Agent operating instructions (auto-loaded by Claude Code)."
    requirement: "Present; work-item references allowed (operational doc)."
  - path: CHANGELOG.md
    section: common
    audit_class: operational
    purpose: "Release history (keep-a-changelog)."
    requirement: "Present; updated by /ship + /document-release."
  - path: TODOS.md
    section: common
    audit_class: operational
    purpose: "The operational backlog."
    requirement: "Present; work-item references allowed (operational doc)."
  - path: docs/doc-general.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: common (general) registry docs."
    requirement: "Generated from the doc-spec registry via doc-spec.sh --render general; kept matching the merged registry; do not hand-edit."
  - path: docs/doc-custom.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: custom registry docs."
    requirement: "Generated from the doc-spec registry via doc-spec.sh --render custom; kept matching the merged registry; do not hand-edit."
```
