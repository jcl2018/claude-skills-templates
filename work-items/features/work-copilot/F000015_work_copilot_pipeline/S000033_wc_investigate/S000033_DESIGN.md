---
type: design
parent: S000033
title: "/wc-investigate — scoping conversation + design doc + domain skeletons — Story Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

## Problem

The Claude side has `/office-hours`; the Copilot side has nothing. Users at the company hand-write design docs (or skip them entirely), so `/wc-scaffold` (S000032) has no design-doc-with-receipt to consume. `/wc-investigate` is the Copilot-side `/office-hours` equivalent — a scoping conversation that produces a structured design doc with the required frontmatter. It also seeds three per-target-repo **domain knowledge** files (skeletons on first install; never overwritten on re-install) so the investigation has ambient context to anchor on.

## Shape of the solution

Three coupled deliverables:

1. **`work-copilot/prompts/investigate.prompt.md`** — the prompt itself. Five steps: (1) read `.github/work-copilot/domain/*.md` as context (skip `.template.md`), (2) grep/search target codebase for entities, (3) walk scoping conversation in plain chat, (4) synthesize design-doc with required frontmatter, (5) write `receipts.investigate` block into design-doc frontmatter.
2. **3 domain skeleton templates** under `work-copilot/domain/`:
   - `domain-knowledge.template.md` — generic domain context (what the company builds, who the users are, key terms).
   - `coding-conventions.template.md` — language/framework conventions specific to this repo.
   - `architecture-overview.template.md` — system architecture (services, data flow, key boundaries).
3. **`scripts/copilot-deploy.py` extensions** — install skeletons (with `.template.md` → `.md` rename) on first install only; preserve filled-in content on re-install; create `.github/work-copilot/designs/.gitkeep` on first install (user-data folder seed).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `.template.md` suffix on bundle side; `.md` on install side | The suffix is the install-time signal. If target file exists without `.template.md`, it's user-filled; skip on re-install. Clean, signal-rich, no manifest tracking required. |
| 2 | 3 domain files (knowledge, conventions, architecture) | Matches the natural split: what the codebase does (knowledge), how it's coded (conventions), how it's structured (architecture). Could be 1 file or 5; 3 is the sweet spot for /wc-investigate context. |
| 3 | `.gitkeep` for `designs/` folder on first install | Without `.gitkeep`, git can't track an empty folder. `/wc-investigate` writes its first design-doc there; the folder needs to exist. |
| 4 | Domain skeletons NOT byte-mirrored | They're per-target user data (P3 in parent design). MIRROR_SPECS would require fabricating mirror paths; wrong shape. Existence check in validate.sh covers presence. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| User at company runs `copilot-deploy install` twice; expects second install to refresh skeleton if upstream changed. V1 says no — `[KEEP-USER]` skip. Is that the right UX, or should there be a `--refresh-skeletons` flag? | Track usage; add flag in V2 if friction shows up. |
| Domain skeleton content might be too company-specific to ship as defaults. V1: ship generic placeholders ("Replace with your domain context — what this repo does, who uses it, key terms"). | Verify generic-enough during exercise. |
| Scoping conversation in plain chat can run long. Should there be a per-question prompt template, or free-form chat? | V1: free-form chat. Document the 4 forcing questions in the prompt body (problem, target user, narrowest wedge, key risks) so Copilot stays on-script. |

## Definition of done

- [ ] Prompt file authored and byte-checked into `work-copilot/prompts/investigate.prompt.md`.
- [ ] 3 domain skeleton files byte-checked into `work-copilot/domain/*.template.md`.
- [ ] `scripts/copilot-deploy.py` extended; re-install on a target repo with filled `.md` content shows `[KEEP-USER]` line.
- [ ] `designs/.gitkeep` created on install.
- [ ] Full happy-path /wc-investigate produces a design-doc at `.github/work-copilot/designs/` with required frontmatter.

## Not in scope

- Multi-language scoping (English-only V1).
- AUQ-style structured questions (Copilot has no AUQ; free-form chat is V1).
- Re-running /wc-investigate on an existing design-doc to revise it — V1 says scaffold a fresh design-doc with a new datetime; the older one stays as history.

## Pointers

- Parent tracker: [../F000015_TRACKER.md](../F000015_TRACKER.md)
- Parent design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Story tracker: [S000033_TRACKER.md](S000033_TRACKER.md)
- Spec: [S000033_SPEC.md](S000033_SPEC.md)
- Test spec: [S000033_TEST-SPEC.md](S000033_TEST-SPEC.md)
- Mental model: `skills/office-hours/SKILL.md` (Claude-side analog)
- Related: `scripts/copilot-deploy.py` (file to extend)
