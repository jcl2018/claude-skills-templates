# personal-workflow fixtures

Each subdirectory or `.md` file demonstrates a single scenario for `/personal-workflow check`.

## File-level fixtures (Tier 1 File Mode)

| Fixture | Demonstrates |
|---|---|
| `valid-tracker.md` | A well-formed tracker file — `check` should report VALID |
| `invalid-bad-frontmatter.md` | YAML frontmatter cannot be parsed |
| `invalid-missing-lifecycle.md` | Missing `## Lifecycle` section |
| `invalid-missing-section.md` | Missing one of the contract.json required sections |
| `invalid-wrong-order.md` | Sections appear in the wrong order |

## Directory-level fixtures (Tier 1 Directory Mode + Tier 2 hierarchy walk)

| Fixture | Demonstrates | Expected check behavior |
|---|---|---|
| `valid-feature-dir/` | A feature directory with both required artifacts | All PASS |
| `invalid-missing-artifact-dir/` | A feature directory missing the milestones artifact | `[MISSING] milestones` |
| `valid-nested-feature/` | Full hierarchy: feature -> user-story -> task, all directories ID-prefixed | All PASS in Tier 2 (template, lifecycle, structure) |
| `invalid-unprefixed-subdir/` | A feature with a child directory that lacks the `{ID}_{slug}` prefix | `[MISFORMATTED]` on the bare-slug child |
| `invalid-missing-required-child/` | A user-story with zero task children, violating `hierarchy.user-story.min` | `[INCOMPLETE]` on the user-story |

## How to test fixtures

Tier 1 (single dir or file):

```bash
/personal-workflow check skills/personal-workflow/fixtures/valid-feature-dir/
/personal-workflow check skills/personal-workflow/fixtures/valid-tracker.md
```

Tier 2 rules (`MISFORMATTED`, `INCOMPLETE`, hierarchy walks) only fire when
`check` walks a full `work-items/` tree. To test a Tier 2 fixture, point
`check` at a temp `work-items/` containing the fixture, or copy the fixture
into a real `work-items/` tree and run `/personal-workflow check`.

## Notes on minimality

Some directory fixtures contain only the artifacts needed to demonstrate the
target rule, not the full required artifact set per
`personal-artifact-manifests.json`. Running `check` on them in isolation will
report additional `[MISSING]` artifacts beyond the one(s) the fixture targets.
This is intentional — fixtures isolate one scenario each.
