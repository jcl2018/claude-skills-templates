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
| `docs/test-pipeline.md` | Check-level map of the verification surface — every validator check, test family, CI workflow, and hook: what each asserts and when it runs. |

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

A freshly bootstrapped repo carries no extra docs yet. Add any repo-specific
docs here in prose, and a matching entry (with `section: custom`) in the
registry below.

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
    purpose: "Major design logic, one '## Principle N' section each."
    requirement: "Arranged by principle; states the repo's first principle(s); human-readable; no work-item IDs."
  - path: docs/workflow.md
    section: common
    audit_class: human-doc
    purpose: "The major workflows from a human's perspective; names the major entry points."
    requirement: "Lists every major workflow/entry point a human would invoke; ASCII flowcharts preferred; no work-item IDs."
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
  - path: docs/test-pipeline.md
    section: common
    audit_class: human-doc
    purpose: "Check-level map of the repo's verification surface (validators, test suites, CI workflows, hooks, ratchets)."
    requirement: "Check-level enumeration of the repo's verification surface (validators, test suites, CI workflows, hooks, ratchets) with what each asserts and when it runs; kept matching the live surface; no work-item IDs."
  - path: doc-spec.md
    section: common
    audit_class: operational
    purpose: "The doc contract itself (this file)."
    requirement: "Present; Common section verbatim from the seed; registry parses with schema_version 1; registry declares every general-contract doc."
  - path: CLAUDE.md
    section: common
    audit_class: operational
    purpose: "Agent operating instructions."
    requirement: "Present; agent operating instructions; work-item references allowed."
  - path: CHANGELOG.md
    section: common
    audit_class: operational
    purpose: "Release history."
    requirement: "Present; release history; updated on every release."
  - path: TODOS.md
    section: common
    audit_class: operational
    purpose: "Operational backlog."
    requirement: "Present; operational backlog; work-item references allowed."
  - path: docs/doc-general.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: common (general) registry docs."
    requirement: "Readable list of the section: common (general) docs, kept matching the registry; no work-item IDs."
  - path: docs/doc-custom.md
    section: common
    audit_class: human-doc
    purpose: "Generated readable view of the section: custom registry docs."
    requirement: "Readable list of the section: custom docs, kept matching the registry; no work-item IDs."
```
