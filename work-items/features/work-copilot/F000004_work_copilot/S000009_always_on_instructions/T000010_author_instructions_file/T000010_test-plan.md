---
type: test-plan
parent: T000010_author_instructions_file
title: "Author copilot-instructions.md — Test Plan"
date: 2026-04-22
author: chjiang
status: Draft
---

<!-- Scope: ONE task. -->

## Scope

This task authors the `copilot-instructions.md` file and wires it into the
install-manifest. Scope: structural correctness of the file, budget
compliance, and Tier 1 invariants.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | File exists | `test -f work-copilot/instructions/copilot-instructions.md` | Exit 0 | Pending |
| 2 | Size within budget | `[ $(wc -c < work-copilot/instructions/copilot-instructions.md) -le 8192 ]` | Exit 0 | Pending |
| 3 | Mentions `/validate` | `grep -q '/validate' work-copilot/instructions/copilot-instructions.md` | Exit 0 | Pending |
| 4 | ID regex present | `grep -qE '\[FSTD\]\[0-9\]\{6\}\|F[0-9]{6}' work-copilot/instructions/copilot-instructions.md` | Exit 0 | Pending |
| 5 | Phase names present in order | `grep -qiE 'Track.*Implement.*Ship' work-copilot/instructions/copilot-instructions.md` | Exit 0 | Pending |
| 6 | Source links present | Manual read: every H2 ends with a `Source:` link | Pass | Pending |
| 7 | Manifest wires install target | `jq -e '.files[] \| select(.dest == ".github/copilot-instructions.md")' work-copilot/install-manifest.json` | Exit 0 | Pending |
| 8 | No per-section overflow | Per-section byte count <= 1024 | All sections within budget | Pending |

## Verification Steps

- [ ] Local build succeeds on macOS
- [ ] Tier 1 smoke checks from parent TEST-SPEC pass
- [ ] Manual read-through: claims align with `skills/personal-workflow/WORKFLOW.md`
- [ ] E2E (parent E1): ask Copilot the 3 AC scenarios in a fresh repo; answers align

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | feat/work-copilot HEAD | Pending |
| Windows 11 + VS Code Copilot Chat | feat/work-copilot HEAD | Pending |
