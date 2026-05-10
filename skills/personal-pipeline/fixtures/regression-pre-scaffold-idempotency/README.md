# Fixture: regression-pre-scaffold-idempotency

Step 2 branch (a) — footer present, dir exists, re-run is a NO-OP for Phase 1.

## What it tests

Orchestrator's pre-scaffold idempotency check correctly detects an
already-scaffolded design doc and skips Phase 1, reusing the existing dir.
This is the F000010 design-doc regression case (the design doc that produced
this work-item itself, F000014, is a real-world canonical input).

## Setup

Use F000010's already-scaffolded design doc:

```bash
DOC=~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md
# Verify the footer is present
grep "Status: SCAFFOLDED" "$DOC"
# Should print: **Status: SCAFFOLDED → `work-items/features/personal-workflow/F000010_pipeline_skills/` on ...**
# Verify the work-item dir exists
ls work-items/features/personal-workflow/F000010_pipeline_skills/
# Should list F000010_TRACKER.md, F000010_DESIGN.md, etc.
```

If the footer is missing, this fixture is invalid (F000010 was hand-scaffolded
before /scaffold-work-item shipped Step 12). Use F000014's design doc instead
(it has the footer):

```bash
DOC=~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-135305.md
```

## Invocation

```bash
/personal-pipeline "$DOC"
```

## Expected outcome

- Step 2 takes branch (a). Stdout shows: "pre-scaffold check: branch (a) — reusing existing work-item dir at <path>; Phase 1 skipped."
- No new work-item dir is created
- Phase 2 + Phase 3 may or may not run depending on the existing dir's gate state (idempotency cascades into the inner skills)
- Telemetry line written with appropriate end_state

## Negative test (should NOT trigger this branch)

Strip the footer from the design doc and re-run; orchestrator should fall
through to branch (c) or (d) instead of (a):

```bash
sed -i.bak '/^\*\*Status: SCAFFOLDED/d' "$DOC"
/personal-pipeline "$DOC"
# Expected: branch (c) halt (because the work-item dir still exists and
# its tracker references this design doc, but no footer)
mv "$DOC.bak" "$DOC"  # restore
```

## Cleanup

No cleanup needed — fixture uses real existing artifacts.
