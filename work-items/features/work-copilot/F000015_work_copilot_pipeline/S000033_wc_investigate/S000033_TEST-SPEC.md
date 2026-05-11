---
type: test-spec
parent: S000033
feature: F000015
title: "/wc-investigate — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000033_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-6 | All 3 domain skeleton files exist | Bundle complete | `for f in domain-knowledge coding-conventions architecture-overview; do test -f "work-copilot/domain/$f.template.md" || exit 1; done; echo OK` |
| S2 | core | AC-1 | `investigate.prompt.md` exists with correct `tools:` array | Prompt installed | `test -f work-copilot/prompts/investigate.prompt.md && grep -q "tools: \['codebase', 'search', 'searchResults', 'editFiles'\]" work-copilot/prompts/investigate.prompt.md` |
| S3 | core | AC-5 | Prompt documents required design-doc frontmatter fields | Frontmatter contract | `grep -E "(status: DRAFT\|work_item_type\|scaffolded_to: null\|receipts.investigate)" work-copilot/prompts/investigate.prompt.md \| wc -l` (expect ≥ 4) |
| S4 | core | AC-7 | `copilot-deploy.py` mentions `[KEEP-USER]` | First-install rule wired | `grep -q "KEEP-USER" scripts/copilot-deploy.py` |
| S5 | core | AC-8 | `copilot-deploy.py` creates `designs/.gitkeep` | designs/ folder seeded | `grep -q "designs/.gitkeep" scripts/copilot-deploy.py \|\| grep -E "designs.*gitkeep" scripts/copilot-deploy.py` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-6,7,8 | First-install populates skeletons + designs/.gitkeep | (1) Pick an empty test target repo. (2) Run `python3 scripts/copilot-deploy.py install <target>`. (3) Inspect `<target>/.github/work-copilot/domain/` and `designs/`. | (a) 3 `.md` files under domain/ (stripped of `.template.md`). (b) `designs/.gitkeep` zero-byte file present. | All files present; correct names; correct content. |
| E2 | core | AC-7 | Re-install preserves filled content | (1) After E1, edit `<target>/.github/work-copilot/domain/domain-knowledge.md` to add real company content. (2) Re-run `copilot-deploy.py install <target>`. | Output shows `[KEEP-USER] domain-knowledge.md`; file content unchanged. | Filled content preserved; `[KEEP-USER]` log line printed. |
| E3 | core | AC-1,2,3,4,5 | Happy-path investigate in Copilot Chat | (1) In a target repo with the bundle installed, fill the 3 domain files. (2) Open Copilot Chat. (3) Invoke `/wc-investigate <topic>`. (4) Walk the 4-question conversation. | (a) Design-doc lands at `.github/work-copilot/designs/<slug>-design-<datetime>.md`. (b) Body has Problem Statement, Approaches, Recommended Approach, Open Questions, Success Criteria sections. (c) Frontmatter has all required fields including receipts.investigate. | Design-doc parses as valid Markdown; frontmatter parses as valid YAML; all 5 frontmatter fields present. |
| E4 | resilience | AC-10 | No codebase matches doesn't abort | (1) In a fresh target with no codebase entities matching the topic, invoke `/wc-investigate <obscure-topic>`. | Prompt prints "no codebase matches — proceeding with domain context only" and continues. | Conversation proceeds; design-doc is produced; no abort. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Resume-from-draft (AC-11) | V1 P2 feature; nice-to-have, not blocking. | Risk: users may have to redo a long conversation. Acceptable for V1; revisit if friction. |
| Multi-language scoping | Out of V1 scope. | English-only conversations are the norm at the company. |
| Domain folder shared across N repos | V1 says re-author per repo; V2 candidate. | Domain drift across repos — acceptable for V1. |
