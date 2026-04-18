---
type: feature-summary
parent: F000004
title: "knowledge-integration — Feature Summary"
date: 2026-04-16
author: chjiang
status: Draft
---

## Scope

Introduce a first-class "knowledge" concept into the company-workflow skill.
Knowledge is reference material that lives outside the repo — e.g. language
coding guidance (cpp style guide, error-handling patterns) and company-specific
domain knowledge (internal systems, jargon, conventions) — and is consumed by
the skill during doc-driven development workflows. The feature assumes a
dedicated knowledge folder located somewhere on the user's machine (path is
configurable, not hardcoded). Delivery includes the folder convention, the
resolution mechanism the skill uses to find and read knowledge, and the
surfacing model that brings relevant knowledge into context during Track /
Implement / Review phases.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] Knowledge folder location is resolved via the `AI_KNOWLEDGE_DIR` environment variable; when unset, the skill emits a one-line warning on every invocation and continues working (graceful degradation)
- [ ] Given a category with `.knowledge.yml { surface: always }`, its files are injected into context on every skill invocation without user action
- [ ] Given a category with `.knowledge.yml { surface: on-demand, triggers: [...] }`, its files are loaded iff the user's prompt contains a declared trigger (case-insensitive whole-word match, or a matched multi-word phrase)
- [ ] The skill supports arbitrary top-level category subfolders (no fixed taxonomy); nesting within a category is allowed (e.g. `coding/cpp/*.md`)
- [ ] A category without a `.knowledge.yml` is treated as on-demand with empty triggers (dark until the user writes the file)
- [ ] Existing company-workflow commands (validate, scaffolding) produce byte-identical output with and without `AI_KNOWLEDGE_DIR` set (zero regression)
- [ ] The folder convention and `.knowledge.yml` schema are documented in SKILL.md or WORKFLOW.md, with at least one fixture demonstrating a valid layout

## Constituent User-Stories

<!-- Markdown links to the nested user-story TRACKER files that decompose
     this feature. The validator does not enforce this list, but it's the
     canonical map for human readers. -->

- [S000004 — env-var-resolution](S000004_env_var_resolution/S000004_TRACKER.md) — skill detects `AI_KNOWLEDGE_DIR`, warns when unset or invalid, exposes resolved path. No knowledge loaded yet. **Unblocks S000005 and S000006.**
- [S000005 — always-on-loading](S000005_always_on_loading/S000005_TRACKER.md) — `.knowledge.yml { surface: always }` files auto-injected every invocation via Claude Read tool. Malformed-yml warnings isolated per category.
- [S000006 — on-demand-matching](S000006_on_demand_matching/S000006_TRACKER.md) — bash emits on-demand candidates (category + triggers + file paths); Claude tokenizes user prompt, matches triggers, Reads matched categories. Case-insensitive whole-word / quoted-phrase semantics.

## Out-of-Scope

<!-- Explicit non-goals. Things this feature deliberately does NOT do, and
     why. Prevents scope creep during Implement and gives reviewers an
     unambiguous boundary. -->

- Authoring the full cpp coding guide or company domain knowledge base — this feature delivers the integration mechanism and a seed, not the complete corpus
- Cross-skill knowledge sharing (personal-workflow integration) — deferred; may become a follow-up feature once the company-workflow model proves out
- Fuzzy / semantic knowledge retrieval (embeddings, ranking) — scope is deterministic file lookup by convention
- Editing or authoring tooling for knowledge files — knowledge is maintained by hand or by separate tooling
- Syncing knowledge from external sources (Confluence, Notion, etc.) — out of scope; the folder is the source of truth
