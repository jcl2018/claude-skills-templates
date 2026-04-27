---
name: "work-copilot"
type: feature
id: "F000004_work_copilot"
status: active
created: "2026-04-22"
updated: "2026-04-26"
repo: "claude-skills-templates"
branch: "feat/v1-cut"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/work-copilot`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Milestones scaffolded
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all children pass validation
2. Ensure all child stories have shipped
3. Run `/ship` — creates feature PR, includes pre-landing code review
4. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [x] `/personal-workflow check` — all children pass validation
- [ ] All children shipped — S000007 + S000008 shipped; S000009 has 1 outstanding AC (live E2E in Copilot chat on Windows box)
- [x] `/ship` — PR created (#43)
- [x] `/land-and-deploy` — merged and deployed (v0.14.0)

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. v1 ACs (validator-only scope) shipped v0.14.0.
     v2 ACs (bundle artifact completeness) added 2026-04-26 per the v2
     realignment design doc. -->

### v1 — validator core (shipped v0.14.0)

- [x] `work-copilot/` directory contains a portable bundle that mirrors the
  intent of `skills/company-workflow/`: templates, artifact manifest,
  validation instructions, reference guides
- [x] The bundle installs into a target repo's `.github/` directory as a
  `copilot-instructions.md` file plus `.prompt.md` prompt files
- [ ] A GitHub Copilot user in the target repo can invoke the equivalent of
  `/company-workflow check` via a Copilot prompt/chat mode and get
  [PASS]/[MISSING]/[DRIFT] output on work items — pending live E2E verification
- [ ] Installation works on a Windows work machine with Copilot (matches the
  "work machine" delivery constraint) — pending Windows box install
- [x] Zero dependency on Claude Code, gstack, or any Anthropic-specific
  tooling — the bundle is Copilot-native
- [x] `scripts/copilot-deploy.py install <target-repo>` copies the bundle
  into `<target-repo>/.github/` idempotently — verified via test.sh smoke

### v2 — bundle artifact completeness (in flight)

- [ ] `work-copilot/WORKFLOW.md` exists, byte-identical to `skills/company-workflow/WORKFLOW.md`
- [ ] `work-copilot/reference/guide-*.md` exists with 7 files, byte-identical to `skills/company-workflow/reference/guide-*.md`
- [ ] `work-copilot/philosophy/rationale-*.md` exists with 3 files, byte-identical to `skills/company-workflow/philosophy/rationale-*.md`
- [ ] `work-copilot/examples/example-*.md` exists with 14 files, byte-identical to `skills/company-workflow/examples/example-*.md`
- [ ] `work-copilot/fixtures/` contains all 5 fixtures (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`, `invalid-wrong-order.md` flat; `valid-feature-dir/DESIGN.md` nested; `valid-feature-dir/TRACKER.md` drift resolved)
- [ ] `scripts/validate.sh` Error check 10 iterates a config-driven list of mirror artifacts and enforces byte-identity sync on every entry plus the counterpart-warning loop; CI fails on drift
- [ ] `scripts/copilot-deploy.py install` walks the new artifacts and lays them down idempotently; `doctor` reports them; `remove` cleans them up
- [ ] `work-copilot/instructions/copilot-instructions.md` references the new artifacts without exceeding the 8 KB budget; budget enforcement location is documented
- [ ] `bin/` is **not** present in `work-copilot/`; absence is intentional per Decision #10
- [ ] `S000010_bundle_artifact_completeness/` and `T000011_validate_sync_check_extension/` scaffolded with full personal-workflow artifact set; `/personal-workflow check work-items/features/F000004_work_copilot/` passes

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] [S000007_copilot_prompt_packaging](S000007_copilot_prompt_packaging/S000007_TRACKER.md) — port the validator as a Copilot prompt file (shipped v0.14.0)
- [x] [S000008_template_delivery_and_install](S000008_template_delivery_and_install/S000008_TRACKER.md) — deliver templates + install into target repo's `.github/` (shipped v0.14.0)
- [ ] [S000009_always_on_instructions](S000009_always_on_instructions/S000009_TRACKER.md) — author `copilot-instructions.md` for always-on workflow context — file shipped v0.14.0; live E2E in Copilot chat on Windows box still pending
- [ ] [S000010_bundle_artifact_completeness](S000010_bundle_artifact_completeness/S000010_TRACKER.md) — mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` + missing fixtures from `skills/company-workflow/` into `work-copilot/` (v2 realignment)
- [ ] [T000011_validate_sync_check_extension](S000010_bundle_artifact_completeness/T000011_validate_sync_check_extension/T000011_TRACKER.md) — extend `validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array enforcing byte-identity sync on every mirror entry

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-22: Created. Port company-workflow semantics (templates + validator + install) to GitHub Copilot so it can run on the user's work machine without Claude Code.
- 2026-04-24: Renumbered from F000005 → F000004 as part of the one-feature-per-skill consolidation (former F000004_knowledge_integration was merged into F000003_company_workflow). Also renamed `created` and `updated` reflect the renumber. Story IDs (S000007, S000008, S000009) and task IDs (T000008, T000009, T000010) preserved — they are globally unique, not per-feature.
- 2026-04-25: Tracker reconciliation during F000003 v1.0.0 cut. Build artifacts (bundle, validator prompt, installer, doctor) all shipped in v0.14.0 (PR #43). S000007 + S000008 closed. S000009 + parent stay `active` until live E2E verification on Windows machine — that AC requires a running Copilot session, not a build check.
- 2026-04-26: v2 realignment per /office-hours design (APPROVED 2026-04-26). DESIGN.md transcribed v1 → v2 in place (F000003-style sections; office-hours-only sections stripped). Tracker, milestones, feature-summary updated to expanded scope. S000010 + T000011 scaffolded with full personal-workflow artifact set. Knowledge integration explicitly deferred to a follow-up feature; `bin/` not mirrored. Implementation deferred to a separate session.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#43](https://github.com/jcl2018/claude-skills-templates/pull/43) — merged 2026-04-23 (v0.14.0). Full work-copilot bundle: validator prompt, installer (install/doctor/remove), instructions file, fixtures, smoke tests.

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- work-items/features/F000004_work_copilot/F000004_DESIGN.md  # feature-level plan (v2 supersedes v1)
- work-copilot/                           # bundle root
- work-copilot/prompts/                   # .prompt.md files
- work-copilot/instructions/              # copilot-instructions.md source
- work-copilot/templates/                 # mirrored from templates/company-workflow/
- work-copilot/WORKFLOW.md                # v2: mirrored from skills/company-workflow/WORKFLOW.md
- work-copilot/reference/                 # v2: mirrored from skills/company-workflow/reference/
- work-copilot/philosophy/                # v2: mirrored from skills/company-workflow/philosophy/
- work-copilot/examples/                  # v2: mirrored from skills/company-workflow/examples/
- work-copilot/fixtures/                  # v2: complete the partial fixtures mirror
- work-copilot/copilot-artifact-manifests.json
- scripts/copilot-deploy.py               # Python 3 stdlib installer (install/doctor/remove)
- scripts/validate.sh                     # template-sync check (v2: extended to MIRROR_SPECS array)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Copilot's `.prompt.md` files are the closest analog to Claude Code slash
  commands; `.github/copilot-instructions.md` is the closest analog to an
  always-on SKILL.md.
- Copilot has no shell execution at prompt time: the validator logic must be
  expressible as instructions to the model, not a bash script. The company
  skill's SKILL.md is already mostly prose + checklists, so port cost is low.
- Work machine is Windows with Copilot; installer must avoid bash-only
  assumptions. A cross-platform path (Python or PowerShell) may be required.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-22 — decision
Target GitHub Copilot via `.github/copilot-instructions.md` (always-on) plus
`.github/prompts/*.prompt.md` (slash-command equivalents). Rejected
`.chatmode.md`-only because chat modes require the user to switch modes
manually; always-on + prompts keeps parity with the Claude Code UX.

### 2026-04-22 — decision
Feature-level plan captured in [F000004_DESIGN.md](F000004_DESIGN.md)
(in lieu of a full `/office-hours` run — the scope was already well-defined
by the three child PRDs, so a consolidated design doc is the lighter-weight
artifact). DESIGN.md enumerates the 7 big decisions, risks, sequencing, and
definition of done.

### 2026-04-26 — decision
Realignment scope sealed: F000004 closes the easy gaps between
`work-copilot/` and `skills/company-workflow/` (mirror `WORKFLOW.md` +
`reference/` + `philosophy/` + `examples/` + missing fixtures), and
explicitly defers knowledge integration (`$AI_KNOWLEDGE_DIR`, two-tier
surfacing, `bin/knowledge-helpers.sh`) to a follow-up feature where it
gets a real Copilot-native design pass. `bin/` is not mirrored — Copilot
has no shell execution at prompt time. Realignment expands F000004
in-place; the feature ID stays the same. Originating office-hours design:
`~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-v1-cut-design-20260426-024148.md`
(APPROVED).

### 2026-04-26 — decision
Approach B chosen for v2 decomposition: 1 story
([S000010_bundle_artifact_completeness](S000010_bundle_artifact_completeness/S000010_TRACKER.md))
+ 1 task
([T000011_validate_sync_check_extension](S000010_bundle_artifact_completeness/T000011_validate_sync_check_extension/T000011_TRACKER.md)).
Rejected Approach A (4 stories, one per artifact category — 4 near-identical
PRDs for what is structurally one mirror operation) and Approach C (single
task, no story scaffolding — loses the PRD/ARCHITECTURE Copilot itself reads
on the work box). Mirrors F000003's actual decomposition shape (2 stories
total, not one per template dir).

### 2026-04-26 — decision
F000004_DESIGN.md superseded v1 → v2 in place. v2 strips the
office-hours-only sections (Cross-Model Perspective, Approaches Considered,
What I noticed about how you think) and follows F000003-style structure
(Problem / Shape / Big decisions / Risks / Sequencing / Definition of done /
Not in scope / Pointers). v1 lives only in git history; the diff is the
lineage.

### 2026-04-26 — decision (autoplan)
`/autoplan` reviewed v2 plan packet with dual voices (Claude subagent + Codex)
across CEO + Eng + DX phases. v2.1 plan-packet revisions:

**Cross-phase themes** (5/6 voices flagged each):
- Theme A — citation premise unverified → resolved via gating (UC1)
- Theme B — bash 3.2 globstar broken → resolved via D2 (find -print0)
- Theme C — knowledge integration is high-leverage piece, deferred → acknowledged; F000005 forward pointer
- Theme D — copilot-deploy.py path traversal → resolved via D4 (folded into v0.15.0)
- Theme E — documentation IA gap → resolved via DX1-DX7 (folded into S000010)

**User Challenge (UC1) resolved:** v2 implementation gated on (a) 30-min
Copilot citation spike on Windows work box; (b) S000009 Windows-box live E2E
completion. Both must complete before S000010/T000011 implementation begins.

**Taste decisions resolved:**
- D2 — recursive shape via `find -print0` (bash 3.2.57 portable)
- D3 — orphans FAIL for new mirrors; WARN preserved for templates (v1 compat)
- D4 — `copilot-deploy.py` path-traversal defense added to v0.15.0 scope (~10 lines Python)
- D5 — manifest sync exempts `description` field; asserts schema parity not byte-identity

**DX scope expansions auto-approved** (each <30 min CC, in radius): DX1 (Python
version guard), DX2 (work-copilot/README.md quickstart), DX3 (--dry-run flag),
DX4 (richer --help), DX5 (inline citation hedge in Bundle layout), DX6
(troubleshooting docs), DX7 (v0.15.0 release note).

**Eng test gaps absorbed:** G1 absorbed by D2; G2 absorbed by D3; G3 = D4;
G5-G10 added to T000011 test-plan and S000010 TEST-SPEC; G11-G13 deferred.

Plan packet locked at v2.1. Restore point + eng-review test-plan addendum
written to `~/.gstack/projects/jcl2018-claude-skills-templates/`.
