---
type: test-plan
parent: T000055
title: "Curate docs/reference.md with an editorial pass — make the grep-grounded reference shelf opinionated and genuinely useful to a human building this workbench — Test Plan"
date: 2026-06-28
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Editorial-only pass on `docs/reference.md` (the sole file changed). Adds a
"New here?" reader-orientation paragraph (read Claude Code + gstack first), gives
each category heading an opinionated subtitle, and rewrites each entry's note from
"why it's cited" to "**why it matters here and when you'd reach for it**" — while
keeping every entry grounded in a real repo reference (no fabricated links) and the
doc human-doc-clean (no work-item IDs). No code, no other files.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | No work-item IDs (human-doc rule) | `grep -E '[FSTD][0-9]{6}' docs/reference.md` | No match (Check 19 clean) | Pass |
| 2 | Doc registry still consistent | `bash scripts/validate.sh` | 0 errors / 0 warnings (Check 15 declared-exists, Check 17 root-allowlist, Check 19 all green) | Pass |
| 3 | Still grouped-by-category w/ grounded notes | Read docs/reference.md | 4 category sections; every entry maps to a real repo reference; notes are opinionated but concise | Pass |
| 4 | No invented references | Diff vs prior reference.md | Same link set (entries enriched, not added/removed); each URL still grounded in repo usage | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] `bash scripts/validate.sh` → 0 errors / 0 warnings (Check 19 no IDs; Check 15/17 doc registry intact)
- [x] Same link set as before (editorial enrichment only — no added/removed references)
- [ ] Post-sync doc audit confirms reference.md still satisfies its doc-spec requirement

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
