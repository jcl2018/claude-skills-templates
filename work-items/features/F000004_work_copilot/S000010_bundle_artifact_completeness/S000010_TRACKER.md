---
name: "Bundle Artifact Completeness"
type: user-story
id: "S000010_bundle_artifact_completeness"
status: active
created: "2026-04-26"
updated: "2026-04-26"
parent: "F000004_work_copilot"
repo: "claude-skills-templates"
branch: "feat/v1-cut"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/v1-cut`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [ ] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
3. Ensure all child tasks have shipped
4. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
5. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] `work-copilot/WORKFLOW.md` exists, byte-identical to `skills/company-workflow/WORKFLOW.md`
- [ ] `work-copilot/reference/guide-*.md` exists with 7 files (`guide-architecture.md`, `guide-general.md`, `guide-prd.md`, `guide-rca.md`, `guide-review-notes.md`, `guide-task.md`, `guide-test-spec.md`), byte-identical to upstream
- [ ] `work-copilot/philosophy/rationale-*.md` exists with 3 files (`rationale-ARCHITECTURE.md`, `rationale-PRD.md`, `rationale-TEST-SPEC.md`), byte-identical to upstream
- [ ] `work-copilot/examples/example-*.md` exists with 14 files (5 trackers + 9 doc types), byte-identical to upstream
- [ ] `work-copilot/fixtures/` contains all 5 missing/drifted files: `invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`, `invalid-wrong-order.md` (flat); `valid-feature-dir/DESIGN.md` (nested, missing); `valid-feature-dir/TRACKER.md` (nested, drift resolved)
- [ ] `work-copilot/instructions/copilot-instructions.md` references the new artifacts via a "Bundle layout" pointer section, without exceeding the 8 KB budget (current 5158 bytes; expected post-add ~5658 bytes)
- [ ] `scripts/copilot-deploy.py install` walks the new artifacts and lays them down idempotently; `doctor` reports them; `remove` cleans them up — verified by extended round-trip test
- [ ] No code change in `scripts/copilot-deploy.py` is required (verified in plan-eng-review D1, 2026-04-26: installer already routes everything not in `prompts/` or `instructions/` to `.github/work-copilot/<same>` via `bundle_dir.rglob("*")`)
- [ ] `bin/` is **not** present in `work-copilot/`; absence is intentional per Decision #10 in F000004_DESIGN.md v2

## Todos

<!-- Actionable items for this story. -->

- [ ] Mirror `skills/company-workflow/WORKFLOW.md` → `work-copilot/WORKFLOW.md` (1 file)
- [ ] Mirror `skills/company-workflow/reference/guide-*.md` → `work-copilot/reference/guide-*.md` (7 files)
- [ ] Mirror `skills/company-workflow/philosophy/rationale-*.md` → `work-copilot/philosophy/rationale-*.md` (3 files)
- [ ] Mirror `skills/company-workflow/examples/example-*.md` → `work-copilot/examples/example-*.md` (14 files)
- [ ] Close fixture gap: add 3 flat files (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`, `invalid-wrong-order.md`); add nested `valid-feature-dir/DESIGN.md`; resolve drift on `valid-feature-dir/TRACKER.md`
- [ ] Add "Bundle layout" pointer section to `work-copilot/instructions/copilot-instructions.md` — single section with file-path strings, no inlined content
- [ ] Settle Open Question #1: locate where `copilot-instructions.md` 8 KB budget is enforced today; document or add a `wc -c` gate
- [ ] Confirm Open Question #2: manifest needs no new entries for mirror dirs; document in S000010_ARCHITECTURE.md
- [ ] Verify (smoke test): `python scripts/copilot-deploy.py install /tmp/target` lays down all new artifacts; `doctor` reports them; `remove` cleans them up
- [ ] T000011 sync-check extension lands (parallel task, blocking story completion)
- [ ] **GATE: citation spike on Windows work box** (autoplan UC1) — reference one mirrored file inline in copilot-instructions.md, ask 4 PRD acceptance questions, record citation behavior. Decides whether byte-mirror approach holds or fallback (DX5 inline-hedge) becomes primary.
- [ ] **GATE: S000009 Windows-box live E2E completes** (autoplan UC1) — v2 implementation begins after v1 is proven on Windows.
- [ ] DX1: Python 3.8 version guard at `copilot-deploy.py:main()` (3 lines)
- [ ] DX2: `work-copilot/README.md` quickstart (~30 lines)
- [ ] DX3: `--dry-run` flag on `install` + `remove` (~20 lines total)
- [ ] DX4: `argparse.RawDescriptionHelpFormatter` + `description=__doc__` for richer `--help`
- [ ] DX5: Inline 1-2 quoted sentences from `WORKFLOW.md` into "Bundle layout" section (citation-failure hedge; ~200 bytes within 8 KB budget)
- [ ] DX6: Troubleshooting docs ("Copilot doesn't recognize /validate" → reload VS Code; "Copilot ignores bundle" → verify .github/copilot-instructions.md present + Bundle layout section)
- [ ] DX7: v0.15.0 release note covering re-install drift on prior-experiment files
- [ ] G3: `copilot-deploy.py` path traversal defense — `Path.resolve().is_relative_to(target.resolve())` at lines 183-191 (doctor) + 227-230 (remove). ~10 lines Python. (autoplan D4)
- [ ] G5-G10: Add test cases for files-with-spaces, symlinks, empty src dir, .gitkeep filter, doctor DRIFT on nested fixture, install-then-validate-target. See [eng-review test-plan addendum](~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-eng-review-test-plan-20260426-224201.md)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-26: Created. v2 realignment per F000004_DESIGN.md (transcribed from /office-hours design APPROVED 2026-04-26). Closes the artifact-completeness gap between `work-copilot/` and `skills/company-workflow/` — mirrors `WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, and the missing fixtures. Implementation deferred to a separate session.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- work-copilot/WORKFLOW.md                    # new — mirror of skills/company-workflow/WORKFLOW.md
- work-copilot/reference/                     # new — 7 guides mirrored
- work-copilot/philosophy/                    # new — 3 rationale notes mirrored
- work-copilot/examples/                      # new — 14 example artifacts mirrored
- work-copilot/fixtures/invalid-bad-frontmatter.md         # new (flat)
- work-copilot/fixtures/invalid-missing-lifecycle.md       # new (flat)
- work-copilot/fixtures/invalid-wrong-order.md             # new (flat)
- work-copilot/fixtures/valid-feature-dir/DESIGN.md        # new (nested)
- work-copilot/fixtures/valid-feature-dir/TRACKER.md       # drift resolved (overwrite with upstream)
- work-copilot/instructions/copilot-instructions.md        # add "Bundle layout" pointer section
- scripts/test.sh                             # extend round-trip test with new install spot-checks + DRIFT case + budget guard

## Insights

<!-- Non-obvious findings worth remembering. -->

- The mirror operation is structurally one design (copy + register in sync check), not four. Decomposing by artifact category (Approach A) would have produced 4 near-identical PRDs; the chosen Approach B (1 story + 1 task) mirrors F000003's actual decomposition shape.
- `scripts/copilot-deploy.py` requires zero code change for the new mirror dirs — the installer already walks `bundle_dir.rglob("*")` and routes everything not in `prompts/` or `instructions/` to `.github/work-copilot/<same>` (verified in plan-eng-review D1, 2026-04-26). New artifacts are picked up automatically.
- The Copilot manifest indexes work-item artifact types (feature, defect, task, user-story, review), not bundle-internal directories. The new mirror dirs need no new manifest entries.
- The `copilot-instructions.md` 8 KB budget has comfortable headroom for v2 pointer additions (current 5158 bytes; pointer section estimated ~500 bytes; budget 8192). Where the budget is *enforced* in CI today is an open question — settle in PRD authoring.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-26 — decision
S000010 scaffolded under F000004_work_copilot to carry the v2 realignment
(bundle artifact completeness). Mirrors one top-level file (`WORKFLOW.md`)
plus four directory trees (`reference/`, `philosophy/`, `examples/`,
`fixtures/`) from `skills/company-workflow/` into `work-copilot/`. The
sync-check extension lives in T000011 (sibling task), not in this story —
clean PR boundary: story = bundle expansion, task = CI enforcement.

### 2026-04-26 — decision
Test plan locked in plan-eng-review D5/D6/D7: extended `copilot-deploy.py`
round-trip test gets 5 new install spot-checks (1 file per new bundle dir)
plus 1 DRIFT-detection negative case; new `copilot-instructions.md` health
test (≤8192 bytes via `wc -c`, plus `grep -F` checks that each bundle-dir
path string appears in the file); manual E2E adds one Copilot-cites query
per new dir to S000009's Windows-box checklist.

### 2026-04-26 — decision (autoplan)
`/autoplan` ran with dual voices (Claude subagent + Codex) across CEO, Eng,
and DX. Resolutions (4 taste decisions + 1 user challenge):

- **UC1 — Premise gate (CEO):** Both reviewers converged that Copilot's
  path-following behavior is unverified. User accepted gating: 30-min citation
  spike + S000009 Windows E2E precondition before implementation begins.
- **D2 — Recursive shape (Eng CRITICAL):** bash 3.2.57 verified on dev box;
  `**/*.md` silently broken. Rewrite using `find -name '*.md' -print0`
  (POSIX-portable; handles spaces/hidden/symlinks). T000011 test-plan cases 7-9
  + happy-path 10 use the new shape.
- **D3 — Mirror orphans (Eng HIGH):** New authoritative mirrors (`reference/`,
  `philosophy/`, `examples/`, `fixtures/`, `WORKFLOW.md`) FAIL on orphan, not
  WARN. Templates retain v1 WARN-only for backward compat. T000011 cases 6 + 9
  invert: assert FAIL not WARN for new mirror entries.
- **D4 — Path traversal (Eng HIGH):** Fold ~10-line
  `Path.resolve().is_relative_to(target.resolve())` defense into `copilot-deploy.py`
  at lines 183-191 (doctor) + 227-230 (remove). Supersedes design's "no installer
  code change required" assertion.
- **D5 — Manifest unification (Eng MEDIUM):** No code consumes `description`
  field. Sync check exempts the field; T000011 case 15 asserts schema parity
  (diff with `description` stripped via jq), not byte-identity.

Auto-approved DX scope expansions (each <30 min CC, in blast radius): DX1
(Python version guard), DX2 (work-copilot/README.md), DX3 (--dry-run), DX4
(richer --help), DX5 (inline-hedge for citation), DX6 (troubleshooting docs),
DX7 (v0.15.0 release note). All folded into S000010 Todos.

Test gaps G3-G10 (path traversal + spaces/symlinks/empty-dir/.gitkeep/doctor-
nested/install-then-validate) added to scope. G1 (bash version) absorbed by D2
fix. G2 absorbed by D3. G11-G13 deferred.

Restore point: `~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-autoplan-restore-20260426-182224.md`
Eng-review test-plan addendum: `~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-eng-review-test-plan-20260426-224201.md`
