# /CJ_implement-from-spec — Fixtures

Per the v1 design (Issue 3.1A from /plan-eng-review), `/CJ_implement-from-spec`
ships with golden fixtures for manual testing.

S000021 (F000012) added `example-defect/` to exercise the per-type defect
branch added when the skill became multi-type aware. Each fixture targets
one type-dispatch path:

| Fixture | Type | Tests |
|---|---|---|
| `example-user-story/` | user-story | The original SPEC + DESIGN read path; propose-and-confirm; --auto trivial-mode |
| `example-defect/` | defect | The new RCA + test-plan read path; per-type Phase 2 gate transition (`RCA doc updated` + `Todos`, NOT `Fix committed`) |

## Golden fixture: `example-user-story/`

A synthetic single-file user-story. The SPEC asserts an exact filename and exact
content; the skill must write that file verbatim during the dogfood.

- `S888000_TRACKER.md` — minimal user-story tracker (Phase 1 fully green;
  Phase 2 gates unchecked)
- `S888000_DESIGN.md` — minimal design stub
- `S888000_SPEC.md` — asserts `output/greeting.txt` with content
  `Hello from /CJ_implement-from-spec\n`
- `S888000_TEST-SPEC.md` — smoke checks file presence + exact content; E2E
  validates the propose-and-confirm and --auto flows
- `output/` — empty by default (modulo `.gitkeep`); the dogfood produces
  `output/greeting.txt` here

## Manual snapshot-diff workflow

```bash
# Reset state — delete any prior dogfood artifact
rm -f skills/CJ_implement-from-spec/fixtures/example-user-story/output/greeting.txt

# Run the skill (default mode: propose-and-confirm)
/CJ_implement-from-spec skills/CJ_implement-from-spec/fixtures/example-user-story/

# Or run with --auto (trivial-mode short-circuit)
/CJ_implement-from-spec skills/CJ_implement-from-spec/fixtures/example-user-story/ --auto
```

**Expected behavior** (without `--auto`):

1. **Step 1 input validation:** type=user-story, TRACKER + SPEC found
2. **Step 2 boundary check at start:** PASSES — Phase 1 fully green; structural compliance OK
3. **Step 3 idempotency:** does NOT NO-OP — implementer-owned gates unchecked, no `[impl-pass]` entry yet
4. **Step 4 read context:** reads SPEC, DESIGN, TRACKER
5. **Step 5 SPEC gap check:** PASSES — no placeholders, all required sections present
6. **Step 6 plan:** Components Affected = 1 file (greeting.txt) — TRIVIAL=true, SENSITIVE=false
7. **Step 7 sensitive surface:** SKIPPED (SENSITIVE=false)
8. **Step 8 propose-and-confirm:** PROPOSED IMPLEMENTATION preview shown; AUQ asks Apply / Modify / Cancel
9. **Step 9 write code:** on Apply, writes `output/greeting.txt` with exact content
10. **Step 10 tracker update:** journal gets `[impl-decision]`, `[impl]`, `[impl-pass]` entries; Phase 2 implementer-owned gates marked CHECKED; Files section updated
11. **Step 11 boundary check at end:** PASSES — TRACKER structure compliant after writes
12. **Step 12 print summary:** `IMPLEMENT COMPLETE: S888000` block + `Next: /CJ_qa-work-item ...`

**Expected behavior** (with `--auto`):

Same as above EXCEPT Step 8 is skipped (no preview, no AUQ — direct write). The
journal includes a `[impl-auto]` entry alongside `[impl]`.

**Pass criteria:**

- [ ] `output/greeting.txt` exists with exact content `Hello from /CJ_implement-from-spec\n`
- [ ] Tracker journal contains `[impl-decision]`, `[impl]`, `[impl-pass]` entries (and `[impl-auto]` if --auto was used)
- [ ] Phase 2 implementer-owned gates marked CHECKED (`Todos section reflects remaining work`, `Files section updated with changed files`)
- [ ] Phase 2 QA-owned gates remain UNCHECKED (`Acceptance criteria verified met`, `Smoke tests pass`) — those are `/CJ_qa-work-item`'s job
- [ ] Step 10 boundary check PASS

**Fail criteria:**

- File missing or content mismatch (`Hello from /CJ_implement-from-spec` exact, no extra whitespace, no different capitalization)
- Verbose subagent-style "here's what I did" content in the file (the skill should be writing greeting.txt, not a meta-description of the implementation)
- Phase 2 QA-owned gates marked CHECKED (would mean the skill is overstepping into /CJ_qa-work-item's job)
- Step 11 boundary check FAIL (writes broke compliance)

**Cleanup after dogfood:**

```bash
# Remove produced file
rm -f skills/CJ_implement-from-spec/fixtures/example-user-story/output/greeting.txt

# Restore tracker to canonical state (revert journal/Files/gate edits)
git checkout -- skills/CJ_implement-from-spec/fixtures/example-user-story/S888000_TRACKER.md
```

## Variations to exercise other paths

The fixture covers the core "single-file implementation" path. To exercise
other paths, vary the fixture by hand:

- **Sensitive-surface AUQ (AC-8):** edit SPEC's Components Affected to add a
  row pointing at `skills-catalog.json` (any change type). Re-run with `--auto`
  — verify the AUQ fires anyway and `--auto` is silently demoted (the demotion
  appears as an `[impl-finding]` journal entry).
- **Phase 1 incomplete refusal (AC-5):** edit `S888000_TRACKER.md` to uncheck
  one Phase 1 gate (e.g., `Acceptance criteria defined`). Re-run; verify the
  skill refuses at Step 2 with "Phase 1 incomplete; resolve before
  implementing."
- **Idempotency NO-OP (AC-4):** after a successful dogfood run, re-run the
  skill on the same fixture without resetting. Verify Step 3 prints "INFO:
  S888000 already implemented; nothing to do." and exits without rewriting the
  file.
- **SPEC gap halt (AC-11):** edit SPEC.md to introduce an unresolved
  placeholder like `{ITEM_NAME}` somewhere in the body, or delete the
  `## Tradeoffs` section. Re-run; verify Step 5 detects the gap and stops
  with a "SPEC gap detected" message naming the issue.

After each variation, **revert the fixture** so the canonical state stays
consistent for downstream runs:

```bash
git checkout -- skills/CJ_implement-from-spec/fixtures/example-user-story/
rm -f skills/CJ_implement-from-spec/fixtures/example-user-story/output/greeting.txt
```

## Defect fixture: `example-defect/`

A synthetic single-file defect. The RCA + test-plan together describe a Write
operation; the skill must execute that Write during the dogfood, exercising
the per-type defect branch added in S000021.

- `D888000_TRACKER.md` — minimal defect tracker (Phase 1 fully green; Phase 2 implementer-owned gates unchecked)
- `D888000_RCA.md` — Symptom + Root Cause + Fix Description + Affected Components
- `D888000_test-plan.md` — Regression Test Cases assert `output/fixed.txt` content; verification steps
- `output/` — empty by default (modulo `.gitkeep`); the dogfood produces `output/fixed.txt` here

### Manual snapshot-diff workflow (defect)

```bash
# Reset state
rm -f skills/CJ_implement-from-spec/fixtures/example-defect/output/fixed.txt

# Run the skill (default mode: propose-and-confirm)
/CJ_implement-from-spec skills/CJ_implement-from-spec/fixtures/example-defect/

# Or run with --auto
/CJ_implement-from-spec skills/CJ_implement-from-spec/fixtures/example-defect/ --auto
```

**Expected behavior** (without `--auto`):

1. **Step 1 input + type dispatch:** type=defect, TRACKER + RCA + test-plan found
2. **Step 2 boundary check at start:** PASSES — Phase 1 fully green; structural compliance OK
3. **Step 3 idempotency:** does NOT NO-OP — implementer-owned gates unchecked, no `[impl-pass]` entry yet
4. **Step 4 read context (defect):** reads RCA, test-plan, TRACKER (NO SPEC/DESIGN; this is the per-type defect path)
5. **Step 5 input gap check (defect):** PASSES — no placeholders, all required RCA + test-plan sections present
6. **Step 6 plan (defect):** Affected Components from RCA = 1 file (fixed.txt) — TRIVIAL=true, SENSITIVE=false
7. **Step 7 sensitive surface:** SKIPPED (SENSITIVE=false)
8. **Step 8 propose-and-confirm:** PROPOSED IMPLEMENTATION preview shown; AUQ asks Apply / Modify / Cancel
9. **Step 9 write code:** on Apply, writes `output/fixed.txt` with exact content
10. **Step 10 tracker update (defect):** journal gets `[impl-decision]`, `[impl]`, `[impl-pass]` entries; Phase 2 implementer-owned gates marked CHECKED — specifically `RCA doc updated` and `Todos section reflects remaining work`. **`Fix committed` stays UNCHECKED** (commit is user/`/ship`-owned).
11. **Step 11 boundary check at end:** PASSES — TRACKER structure compliant after writes
12. **Step 12 print summary:** `IMPLEMENT COMPLETE: D888000` block + `Next: /CJ_qa-work-item ...`

**Pass criteria (defect-specific):**

- [ ] `output/fixed.txt` exists with exact content `Hello from defect fix\n`
- [ ] Tracker journal contains `[impl-decision]`, `[impl]`, `[impl-pass]` entries
- [ ] Phase 2 implementer-owned gates marked CHECKED (`RCA doc updated`, `Todos section reflects remaining work`)
- [ ] **Phase 2 commit gate `Fix committed` remains UNCHECKED** — that's user/`/ship`-owned
- [ ] Step 11 boundary check PASS

**Fail criteria (defect-specific):**

- File missing or content mismatch
- `Fix committed` gate marked CHECKED (would mean the skill is overstepping into the commit gate's user/`/ship` ownership)
- The skill tried to read SPEC.md or DESIGN.md (would mean the type-dispatch routed to the user-story branch by mistake)

**Cleanup:**

```bash
rm -f skills/CJ_implement-from-spec/fixtures/example-defect/output/fixed.txt
git checkout -- skills/CJ_implement-from-spec/fixtures/example-defect/D888000_TRACKER.md
```

## Why a synthetic single-file fixture (not a real work-item bootstrap)?

`/CJ_scaffold-work-item` uses F000010 itself as its dogfood (the catalog
demonstration that "this skill works"). `/CJ_qa-work-item` uses a planted-bug
fixture (the catalog demonstration that "the QA engineer subagent finds
known-red criteria").

`/CJ_implement-from-spec` could in principle use S000017's SPEC as its dogfood
("re-implement CJ_scaffold-work-item from SPEC"), but doing that would either
overwrite the shipped skill or hit Write-on-existing-file errors. A trivial
synthetic SPEC keeps the dogfood reproducible and free of side effects on real
shipped code.

The real cross-skill dogfood is documented in `S000018_TEST-SPEC.md` E1 — that
gets exercised when `/CJ_implement-from-spec` is used on the next real user-story
that ships through the CJ_personal-workflow pipeline.
