# /implement-from-spec — Fixtures

Per the v1 design (Issue 3.1A from /plan-eng-review), `/implement-from-spec`
ships with **one golden fixture** for manual testing.

## Golden fixture: `example-user-story/`

A synthetic single-file user-story. The SPEC asserts an exact filename and exact
content; the skill must write that file verbatim during the dogfood.

- `S888000_TRACKER.md` — minimal user-story tracker (Phase 1 fully green;
  Phase 2 gates unchecked)
- `S888000_DESIGN.md` — minimal design stub
- `S888000_SPEC.md` — asserts `output/greeting.txt` with content
  `Hello from /implement-from-spec\n`
- `S888000_TEST-SPEC.md` — smoke checks file presence + exact content; E2E
  validates the propose-and-confirm and --auto flows
- `output/` — empty by default (modulo `.gitkeep`); the dogfood produces
  `output/greeting.txt` here

## Manual snapshot-diff workflow

```bash
# Reset state — delete any prior dogfood artifact
rm -f skills/implement-from-spec/fixtures/example-user-story/output/greeting.txt

# Run the skill (default mode: propose-and-confirm)
/implement-from-spec skills/implement-from-spec/fixtures/example-user-story/

# Or run with --auto (trivial-mode short-circuit)
/implement-from-spec skills/implement-from-spec/fixtures/example-user-story/ --auto
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
12. **Step 12 print summary:** `IMPLEMENT COMPLETE: S888000` block + `Next: /qa-work-item ...`

**Expected behavior** (with `--auto`):

Same as above EXCEPT Step 8 is skipped (no preview, no AUQ — direct write). The
journal includes a `[impl-auto]` entry alongside `[impl]`.

**Pass criteria:**

- [ ] `output/greeting.txt` exists with exact content `Hello from /implement-from-spec\n`
- [ ] Tracker journal contains `[impl-decision]`, `[impl]`, `[impl-pass]` entries (and `[impl-auto]` if --auto was used)
- [ ] Phase 2 implementer-owned gates marked CHECKED (`Todos section reflects remaining work`, `Files section updated with changed files`)
- [ ] Phase 2 QA-owned gates remain UNCHECKED (`Acceptance criteria verified met`, `Smoke tests pass`) — those are `/qa-work-item`'s job
- [ ] Step 10 boundary check PASS

**Fail criteria:**

- File missing or content mismatch (`Hello from /implement-from-spec` exact, no extra whitespace, no different capitalization)
- Verbose subagent-style "here's what I did" content in the file (the skill should be writing greeting.txt, not a meta-description of the implementation)
- Phase 2 QA-owned gates marked CHECKED (would mean the skill is overstepping into /qa-work-item's job)
- Step 11 boundary check FAIL (writes broke compliance)

**Cleanup after dogfood:**

```bash
# Remove produced file
rm -f skills/implement-from-spec/fixtures/example-user-story/output/greeting.txt

# Restore tracker to canonical state (revert journal/Files/gate edits)
git checkout -- skills/implement-from-spec/fixtures/example-user-story/S888000_TRACKER.md
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
git checkout -- skills/implement-from-spec/fixtures/example-user-story/
rm -f skills/implement-from-spec/fixtures/example-user-story/output/greeting.txt
```

## Why a synthetic single-file fixture (not a real work-item bootstrap)?

`/scaffold-work-item` uses F000010 itself as its dogfood (the catalog
demonstration that "this skill works"). `/qa-work-item` uses a planted-bug
fixture (the catalog demonstration that "the QA engineer subagent finds
known-red criteria").

`/implement-from-spec` could in principle use S000017's SPEC as its dogfood
("re-implement scaffold-work-item from SPEC"), but doing that would either
overwrite the shipped skill or hit Write-on-existing-file errors. A trivial
synthetic SPEC keeps the dogfood reproducible and free of side effects on real
shipped code.

The real cross-skill dogfood is documented in `S000018_TEST-SPEC.md` E1 — that
gets exercised when `/implement-from-spec` is used on the next real user-story
that ships through the personal-workflow pipeline.
