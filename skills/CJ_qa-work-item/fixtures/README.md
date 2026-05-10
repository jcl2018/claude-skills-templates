# /CJ_qa-work-item — Fixtures

Per the v1 design (Issue 3.1A from /plan-eng-review), `/CJ_qa-work-item` ships
with **one golden fixture** for manual testing.

## Golden fixture: `example-user-story/`

A synthetic user-story with a deliberate content mismatch between
`fixture-impl.txt` and the expected value asserted in `S999000_TEST-SPEC.md`.

- `S999000_TRACKER.md` — minimal user-story tracker (Phase 1 + implementer
  Phase 2 gates green; QA-owned Phase 2 gates unchecked)
- `S999000_DESIGN.md` — minimal design stub
- `S999000_SPEC.md` — asserts `fixture-impl.txt` contains `Hello, World!`
  (capital W, exclamation)
- `S999000_TEST-SPEC.md` — smoke checks file presence/non-emptiness; E2E
  asserts exact content match
- `fixture-impl.txt` — contains `Hello, world\n` (lowercase w, no
  exclamation) — **the planted bug**

## Manual snapshot-diff workflow

Run the skill on the fixture:

```bash
/CJ_qa-work-item skills/CJ_qa-work-item/fixtures/example-user-story/
```

**Expected behavior** (the fixture is the test):

1. **Step 2 boundary check at start:** PASSES — implementer-owned Phase 2
   gates (`Todos section reflects remaining work`,
   `Files section updated with changed files`) are checked in
   `S999000_TRACKER.md`.
2. **Step 3 idempotency:** does NOT NO-OP — QA-owned Phase 2 gates are
   unchecked, no `[qa-pass]` journal entry yet.
3. **Step 5 smoke run:** GREEN. S1 (`test -f`) and S2 (`test -s`) both pass.
4. **Step 7 subagent dispatch:** spawned. Subagent reads the TEST-SPEC and
   `fixture-impl.txt`, diffs them, and finds the mismatch.
5. **Step 8 process result:** subagent returns a 1-2 sentence summary
   identifying E1 as red ("expected `Hello, World!`, got `Hello, world`").
   Skill detects red and AskUserQuestions for review.
6. **Step 9 gate transition:** does NOT transition — E2E was red.
7. Subagent writes a `[qa-e2e]` journal entry to `S999000_TRACKER.md`
   documenting the red finding.

**Pass criteria** (the QA orchestration is correct if):

- [ ] Smoke passes (S1 and S2 both green in journal)
- [ ] Subagent is invoked exactly once (no recursive subagent spawn)
- [ ] Subagent's response is short (1-2 sentences + file pointer)
- [ ] Subagent reports E1 as red, with the specific content mismatch named
- [ ] AskUserQuestion fires (because of the red finding)
- [ ] Phase 2 QA-owned gates remain unchecked
- [ ] Tracker journal contains `[qa-smoke]`, `[qa-smoke-summary]`,
      `[qa-e2e]`, and `[qa-e2e-summary]` entries (no `[qa-pass]`)
- [ ] Step 10 boundary check passes (the writes didn't break compliance)

**Fail criteria:**

- Subagent reports green on E1 (false negative on planted bug — the
  subagent prompt or model isn't catching the obvious mismatch)
- Subagent's response is verbose (> 200 tokens — Premise 1 violation)
- Phase 2 QA-owned gates get transitioned despite red finding
- Step 10 boundary check fails (QA writes broke template compliance)
- Subagent spawns its own subagent (recursion — anti-pattern violation)

## Variations to exercise other paths

The fixture covers the core "subagent finds planted bug" path (E1 in
`S000019_TEST-SPEC.md`). To exercise other paths, vary the fixture by hand:

- **Smoke red short-circuit (S3):** edit `S999000_TEST-SPEC.md` smoke
  S1 to `test -f /nonexistent/path`; re-run; verify subagent NOT
  invoked, AUQ fires for "smoke red."
- **Idempotency NO-OP (S4):** edit `S999000_TRACKER.md` to check off
  the QA-owned Phase 2 gates AND add a `[qa-pass]` journal entry dated
  today; re-run; verify "already QA'd green" exit.
- **Boundary check refusal (S5):** edit `S999000_TRACKER.md` to uncheck
  `Todos section reflects remaining work`; re-run; verify refusal at
  Step 2.

After each variation, **revert the fixture** so the canonical state is
the planted-bug-on-content baseline.

## Why a synthetic fixture (not a real work-item bootstrap)?

`/CJ_scaffold-work-item` uses F000010 itself as its golden fixture (real
work item, dogfooded). `/CJ_qa-work-item` can't dogfood the same way: the
canonical demonstration is "subagent finds a planted bug," and the real
F000010 implementations don't have planted bugs. A synthetic fixture is
the cheapest correct-on-purpose target.
