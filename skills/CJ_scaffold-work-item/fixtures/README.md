# /CJ_scaffold-work-item — Fixtures

Per the v1 design (Issue 3.1A from /plan-eng-review), `/CJ_scaffold-work-item` ships
with **one golden fixture** for manual snapshot-diff testing.

## Golden fixture

The canonical fixture is **F000010 itself**. F000010 (`work-items/features/CJ_personal-workflow/F000010_pipeline_skills/`)
was hand-scaffolded as the bootstrap to break the chicken-and-egg problem (the
skill cannot scaffold its own work item before it ships).

- **Input:** `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`
- **Expected output:** `work-items/features/CJ_personal-workflow/F000010_pipeline_skills/`

## Manual snapshot-diff workflow

Once `/CJ_scaffold-work-item` ships, the bootstrap proof is:

```bash
# 1. Backup the hand-scaffolded baseline
cp -r work-items/features/CJ_personal-workflow/F000010_pipeline_skills/ /tmp/F000010-baseline/

# 2. Remove the existing F000010 work-item dir
rm -rf work-items/features/CJ_personal-workflow/F000010_pipeline_skills/

# 3. Re-scaffold via the skill
/CJ_scaffold-work-item ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md

# 4. Diff actual vs baseline
diff -r work-items/features/CJ_personal-workflow/F000010_pipeline_skills/ /tmp/F000010-baseline/
```

**Pass criteria:** diff shows ONLY:
- Timestamp differences (today vs the original 2026-05-08)
- Auto-generated journal entry differences (re-runs add their own log entries)
- Possibly different multi-story slugs IF the skill's slug-suggestion logic differs from
  what was hand-picked (`scaffold_work_item`, `implement_from_spec`, `qa_work_item`).
  This is acceptable so long as the structure is correct.

**Fail criteria:**
- Missing artifact (any of TRACKER, DESIGN, ROADMAP for feature; TRACKER, DESIGN, SPEC, TEST-SPEC for user-story)
- Frontmatter field missing or with unresolved `{placeholder}` values
- Section missing from any artifact (per template)
- Section out of order
- Multi-story scaffold produced wrong number of children (≠ 3)
- Boundary check (`/CJ_personal-workflow check`) on the produced dir reports MISSING/DRIFT

## Why F000010 instead of a synthetic fixture?

Synthetic fixtures need to be authored, maintained, and kept aligned with the templates.
F000010 already exists and is structurally compliant; using it as the golden fixture
amounts to "the first real run is the test." If the templates change, F000010's hand-scaffolded
baseline can be re-validated with `/CJ_personal-workflow check` and the fixture pointer here
stays correct.

If a future change makes F000010-as-fixture impractical (e.g., F000010 is deleted, or
its design doc is moved), add a synthetic fixture here in the form:

```
fixtures/
  example-input/
    chjiang-main-design-20260508-XXXXXX.md  # synthetic /office-hours doc
  example-output/
    F0XXXXX_synthetic/
      F0XXXXX_TRACKER.md
      F0XXXXX_DESIGN.md
      ...                                    # snapshot of expected output
  README.md                                  # how to run + diff
```

For v1, the F000010 pointer is sufficient.
