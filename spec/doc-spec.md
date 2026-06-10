<!-- DOC-SPEC-COMMON:BEGIN (portable — keep byte-identical across adopting repos) -->
# doc-spec.md — what docs this repo carries

This file is the single answer to two questions: **what documents does this
repo carry, and what is each one for?** It is both the human-readable map (the
prose below) and the machine source of truth (the fenced `yaml` registry at the
end). One file, no second list to keep in sync.

A repo adopts this contract by dropping in this file: copy the **Common**
section verbatim, then fill the **Custom** section with whatever else the repo
carries. Nothing about the repo's other tooling has to change.

## The doc contract

Every repo that adopts this contract carries ten **general docs** — the
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
| `doc-spec.md` | The doc contract itself — this file (a repo may keep it under `spec/`; tooling resolves `spec/doc-spec.md` first, then the root). |
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
  `section: custom` docs are this repo's chosen additions.
- **Human docs carry no work-item IDs.** A reference of the shape
  `<F|S|T|D>` followed by six digits is internal-tracker noise; it does not
  belong in a doc a newcomer reads. This is enforced (a hard CI lint), not a
  guideline.
- **The registry is the source of truth.** The `yaml` block below declares every
  doc the repo carries. Tooling parses it; the prose explains it. Add a doc by
  adding a registry entry — never by editing a second list somewhere else.

## How the registry is used

Two consumers parse the `yaml` registry:

```
            doc-spec.md  (this file)
            ┌───────────────────────────┐
            │ Common prose + Custom prose│
            │ yaml machine registry      │
            │   schema_version: 1        │
            │   docs[]: path / section / │
            │     audit_class / purpose /│
            │     requirement            │
            └───────┬───────────────┬────┘
                    │ parses        │ parses
        ┌───────────▼──┐      ┌─────▼─────────────────┐
        │ a CI validator│      │ a doc-release skill   │
        │ declared ⇔    │      │ self-bootstrap missing│
        │  on-disk      │      │  doc-spec.md          │
        │ schema valid  │      │ stub missing docs     │
        │ no work-item  │      │ audit each vs its     │
        │  IDs in human │      │  requirement          │
        │  docs         │      │ derive doc whitelist  │
        └───────────────┘      └───────────────────────┘
```

- **A CI validator** asserts that every declared doc exists, that every doc on
  disk under `docs/` is declared (no orphans), that the registry schema is valid,
  and that no human-doc contains a work-item ID.
- **A doc-release skill** reads the registry to self-heal the contract: if
  `doc-spec.md` is missing it recreates it from the portable Common seed; if a
  declared doc is missing it scaffolds a stub; it audits each doc against its
  `requirement`; and it derives the doc-only auto-commit whitelist from the
  registry (every declared path + `doc-spec.md` + `docs/**/*.md`).

## audit_class (closed enum)

Each registry entry declares one `audit_class`:

- **`human-doc`** — human-facing. Must exist; must contain **no work-item IDs**
  (`[FSTD]NNNNNN`); ASCII flowcharts/diagrams preferred (advisory).
- **`operational`** — must exist; work-item references are allowed (these are
  agent/ops docs, e.g. a changelog or an agent-instructions file).

<!-- DOC-SPEC-COMMON:END -->

<!-- DOC-SPEC-CUSTOM:BEGIN (this repo only — edit freely) -->
## Custom: this repo's additional docs

Beyond the ten general docs, this workbench's custom tier is three docs:
`CONTRIBUTING.md` (the contributor authoring guide, surfaced by GitHub from the
repo root) plus the two remaining spec-registry files (`spec/gate-spec.md`,
`spec/permission-policy.md`). The three spec-registry files
(`spec/doc-spec.md`, `spec/gate-spec.md`, `spec/permission-policy.md`) live under
`spec/` — a dedicated folder that signals "machine config, not hand-read docs"
at a glance. The full general/custom doc lists are **generated** from the machine
registry below into
[`docs/doc-general.md`](docs/doc-general.md) + [`docs/doc-custom.md`](docs/doc-custom.md)
(do not hand-edit — regenerate with `scripts/generate-doc-views.sh`); the
contract's *why* (the logic) lives in
[`docs/philosophy.md`](docs/philosophy.md) `## Topic: Doc contract`.

Repo notes:

- The three core human docs and the two generated views live under `docs/`
  (lowercase). `docs/workflow.md` is singular.
- The three spec-registry files moved into `spec/` (this repo); each helper
  resolves `spec/<name>.md` first, then a root `<name>.md` fallback, so a
  root-only consumer (or a fresh adopter) still resolves the registry unchanged.
- The root operational docs (`CHANGELOG.md`, `CLAUDE.md`, `TODOS.md` — general
  tier — plus the custom `CONTRIBUTING.md`) stay at the repo root because
  external tooling (GitHub rendering, Claude Code's `./CLAUDE.md` auto-load,
  `/ship`'s changelog writer) hardcodes those root paths.
- The doc-only auto-commit whitelist used by `/CJ_document-release` is derived
  from the registry below — there is no separate hand-maintained whitelist file.

### `front_table` (workbench-local registry field)

A registry entry MAY carry `front_table: required` — a **workbench-local**
extension (it lives only in this Custom section + the machine registry below, NOT
in the portable Common seed). A flagged doc must **open with a summary table**:
the first Markdown table (a `|`-row immediately followed by a `|---|`-style
delimiter row) must appear **before the doc's first `## ` heading**, giving a
reader an at-a-glance index. The gate asserts a leading table only — it does not
prescribe the table's columns. Today `docs/philosophy.md` (a row per principle)
and `docs/workflow.md` (a row per major workflow/entry point) are flagged.
`scripts/doc-spec.sh --list-front-table-docs` enumerates the flagged paths;
`scripts/validate.sh` Check 20 consumes that list and hard-fails any flagged doc
missing its leading table. Flagging a third doc later is a one-line registry edit
— no validator change.

<!-- DOC-SPEC-CUSTOM:END -->

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file.

```yaml
# doc-spec registry (parsed by scripts/validate.sh + /CJ_document-release)
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
    purpose: "The doc contract itself (this file)."
    requirement: "Present; Common section verbatim from the seed; registry parses with schema_version 1; registry declares every general-contract doc."
  - path: spec/gate-spec.md
    section: custom
    audit_class: operational
    purpose: "The cj_goal verification contract — what stops a broken change from landing, and at which layer (parsed by scripts/gate-spec.sh)."
    requirement: "Present; one fenced yaml registry of layers[] + gates[] parsing with schema_version 1; every declared literal marker present in its mode's pipeline."
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
  - path: CONTRIBUTING.md
    section: custom
    audit_class: operational
    purpose: "Contributor authoring guide."
    requirement: "Present; surfaced by GitHub from the repo root."
  - path: TODOS.md
    section: common
    audit_class: operational
    purpose: "Operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship."
    requirement: "Present; work-item references allowed (operational doc)."
  - path: spec/permission-policy.md
    section: custom
    audit_class: operational
    purpose: "The cj_goal allow/ask/deny permission contract (parsed by scripts/permission-policy.sh)."
    requirement: "Present; one fenced yaml policy registry parsing with schema_version 1; risky verbs enumerated as deny/ask."
  - path: docs/doc-general.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section:common (general) registry docs."
    requirement: "Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit."
  - path: docs/doc-custom.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section:custom registry docs."
    requirement: "Generated from the spec/doc-spec.md registry by scripts/generate-doc-views.sh; kept in sync by validate.sh Check 23; do not hand-edit."
```
