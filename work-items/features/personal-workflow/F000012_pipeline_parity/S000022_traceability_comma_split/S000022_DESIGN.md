---
type: design
parent: S000022
feature: F000012
title: "Step 18 traceability comma-split fix — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story under F000012. Small prose tightening in check.md;
     full design context in parent F000012_DESIGN.md. Structural sections
     preserved per personal-workflow check Step 16 enforcement. -->

## Problem

`skills/personal-workflow/check.md:339-371` (Step 18: Cross-Reference Traceability) describes how to extract AC values from TEST-SPEC.md tables but doesn't specify how to handle multi-AC cells like `AC-1, AC-2, AC-3`. An LLM following the prose with field-by-field exact matching would treat the whole cell as one string and never match `AC-1`, `AC-2`, or `AC-3` individually — yielding false `[UNTESTED]` findings on real F000010 work-items:

- `S000018_TEST-SPEC.md:24` — cell `AC-1, AC-2, AC-3`
- `S000018_TEST-SPEC.md:26` — cell `AC-5, AC-6`
- `S000019_TEST-SPEC.md:32` — cell `AC-2, AC-4`

The bug is purely in the prose specification, not in any executable code. `check.md` is interpreted by the LLM running `/personal-workflow check`. Tightening the prose IS the fix.

## Shape of the solution

Edit Step 18 in `skills/personal-workflow/check.md` to:

1. **Add explicit comma-split instruction** to step 3 ("Parse TEST-SPEC.md for AC values"): "For each cell in the AC column, split on comma and trim whitespace. Each resulting token contributes one value to `smoke_acs` / `e2e_acs`."
2. **Add a worked example block** showing the comma-split + placeholder-filter ordering: `| S2 | core | AC-1, AC-2, AC-3 | ...` → split on comma → `{AC-1, AC-2, AC-3}` → set-membership check.
3. **Preserve the placeholder filter ordering**: comma-split happens BEFORE the `^AC-\{[a-zA-Z_]+\}$` filter, so `AC-{n}, AC-1` correctly yields `{AC-1}` (placeholder dropped, real AC kept).
4. **Re-confirm edge cases unchanged**: `-` or blank cells contribute nothing (existing behavior); `AC-{n}` placeholder cells still flag `[UNTESTED]` for filled SPECs.

No tracker template changes. No manifest changes. Only `check.md` is touched.

## Big decisions

- **Prose fix, not code fix.** `check.md` is the spec; the LLM is the runtime. Tightening prose is the implementation. (F000012_DESIGN big decision #6.)
- **Worked example, not just rule.** A worked example pins the comma-split + placeholder-filter ordering visually. Future readers / LLMs can pattern-match against the example faster than parsing the rule.
- **No expanded edge-case enumeration beyond what's already covered.** Step 18's existing edge-case list (smoke-only, both empty, blank cells) stays as-is. Adding more rows risks making the prose hard to read for the common case.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| LLMs may still occasionally misparse if the prose isn't unambiguous | Implementation: review revised prose against 3 sample TEST-SPECs (S000018, S000019, S000020) and confirm zero false `[UNTESTED]` |
| Step 18.5 (cap advisory) shares the same row-counting pattern; does it have the same bug? | Step 18.5 counts ROWS not AC values — independent. No fix needed. |
| Would a separate parser script be more robust than prose? | Out of scope: `check.md` is intentionally LLM-interpreted. Adding a script changes the architecture (D000007 trust model: templates + WORKFLOW.md + check.md are sources of truth, the AI executes them). |

## Definition of done

- [ ] Step 18 prose explicitly comma-splits AC cells before set-membership check.
- [ ] Worked example added.
- [ ] Placeholder-filter ordering preserved + verified by example.
- [ ] Running `/personal-workflow check` on F000010 dir produces zero false `[UNTESTED]` findings.
- [ ] Edge cases (`-` / blank cells, placeholder rows) re-verified by spot-check on existing fixtures.

## Not in scope

- Step 18 implementation rewrite into a separate parser script — out of scope per architecture (LLM-interpreted spec).
- Other Step changes in check.md — Steps 18.5, 19, 20+ are not modified.
- Template changes (TEST-SPEC, SPEC) — the existing AC column format already supports comma-separated values; the bug is in the parser prose, not the template.

## Pointers

- Parent feature design: [../F000012_DESIGN.md](../F000012_DESIGN.md)
- Sibling story (provides per-type pipeline path): [../S000021_per_type_implement_qa/S000021_TRACKER.md](../S000021_per_type_implement_qa/S000021_TRACKER.md)
- Target file: `skills/personal-workflow/check.md` (Step 18, lines 339-371)
- Affected fixtures (will exercise the fix): `work-items/features/personal-workflow/F000010_pipeline_skills/S000018_*/S000018_TEST-SPEC.md`, `S000019_*/S000019_TEST-SPEC.md`
