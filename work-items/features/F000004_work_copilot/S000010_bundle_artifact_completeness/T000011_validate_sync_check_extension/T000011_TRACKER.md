---
name: "Validate Sync-Check Extension"
type: task
id: "T000011_validate_sync_check_extension"
status: active
created: "2026-04-26"
updated: "2026-04-26"
parent: "S000010_bundle_artifact_completeness"
repo: "claude-skills-templates"
branch: "feat/v1-cut"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/v1-cut`
   (use parent's branch — task ships in the same PR as S000010)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-v1-cut-design-20260426-024148.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [ ] Replace `scripts/validate.sh` Error check 10's hard-coded single-dir comparison with a config-driven `MIRROR_SPECS` array (locked in plan-eng-review D3; revised by autoplan D2) — entries shaped `src-pattern:dst-pattern shape:orphan-policy` (4-tuple: src, dst, glob shape, orphan policy)
- [ ] Implement glob-shape branching for the 3 supported shapes (autoplan D2 revision: recursive uses `find -print0`):
  - single-file: `src:dst` with no glob → one `cmp -s` call
  - flat-glob: `SRC/*.md:DST/*.md` → iterate matching files in src dir (quoted), `cmp -s` each
  - **recursive (autoplan D2):** `SRC/**:DST/**` → `find SRC -name '*.md' -print0 \| while IFS= read -r -d '' src` → preserve relative path; works on bash 3.2.57 (verified on dev box). NOT bash globstar — `**` does not work without `shopt -s globstar` in bash 4+ which dev box lacks.
- [ ] Filter file names explicitly to `*.md` (locked in plan-eng-review C1) so `.DS_Store` (macOS), `Thumbs.db` (Windows), and `.gitkeep`/`.gitattributes`/`.editorconfig` don't trip the check (autoplan G8)
- [ ] Use binary-mode `cmp -s` (no text-mode comparison) — re-protects against D000005 CRLF flap on Windows
- [ ] **autoplan D3 — Orphan policy by mirror identity:** new authoritative mirrors (`WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, `fixtures/`) emit `[ORPHAN]` and FAIL the check. Templates retain v1 WARN-only behavior for backward compat. Manifest pair: schema-parity check (see autoplan D5 below).
- [ ] Populate `MIRROR_SPECS` with 7 entries (revised per autoplan D3 + D5):
  - `templates/company-workflow/*.md:work-copilot/templates/*.md` flat warn (v1 compat)
  - `skills/company-workflow/WORKFLOW.md:work-copilot/WORKFLOW.md` single fail
  - `skills/company-workflow/reference/*.md:work-copilot/reference/*.md` flat fail
  - `skills/company-workflow/philosophy/*.md:work-copilot/philosophy/*.md` flat fail
  - `skills/company-workflow/examples/*.md:work-copilot/examples/*.md` flat fail
  - `skills/company-workflow/fixtures/**:work-copilot/fixtures/**` recursive fail (find -print0)
  - `skills/company-workflow/company-artifact-manifests.json:work-copilot/copilot-artifact-manifests.json` schema-parity (see D5)
- [ ] **autoplan D5 — Manifest schema parity, not byte-identity:** sync check parses both manifests, diffs with `description` field stripped using `jq 'del(.description)'`. Reason: no code in repo grep-consumes `description`. Supersedes plan-eng-review D4's byte-identity rule.
- [ ] **autoplan G3 (folds into S000010, sequencing flag here):** `copilot-deploy.py:183-191` (doctor) + `:227-230` (remove) get a `Path.resolve().is_relative_to(target.resolve())` defense. ~10 lines Python.
- [ ] Add 10 negative-path synthetic test cases + 1 happy-path case + 1 manifest-schema-parity case to `scripts/test.sh` per the test-plan (3 shapes × 3 failure modes + 1 all-in-sync + 1 manifest-parity + revised orphan FAIL/WARN per spec entry)
- [ ] Add G5-G10 test cases to test-plan: files with spaces, symlinks, empty src dir, .gitkeep filter, doctor DRIFT on nested fixture (`fixtures/valid-feature-dir/TRACKER.md`), install-then-validate-target. See [eng-review test-plan addendum](~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-eng-review-test-plan-20260426-224201.md)
- [ ] Refactor the orphan-warn/orphan-fail loop into a function so it doesn't get duplicated 7× across spec entries (autoplan Eng finding)
- [ ] Verify the existing v1 template-sync behavior still passes under the new array-driven structure (regression safety)
- [ ] Document the `MIRROR_SPECS` extension contract: future mirror dirs add as one new line, with explicit shape token (`single`/`flat`/`recursive`) and orphan policy (`fail`/`warn`)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-04-26: Created. Extends `scripts/validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array enforcing byte-identity sync on every mirror entry. Pattern, glob shapes, and OS-junk filtering locked in plan-eng-review D3 + C1; manifest pair sync locked in plan-eng-review D4. Test plan locked in plan-eng-review D5. Implementation deferred to a separate session.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- scripts/validate.sh                              # Error check 10 generalized to MIRROR_SPECS array
- scripts/test.sh                                  # 9 negative-path synthetic tests + 1 happy-path
- skills/company-workflow/company-artifact-manifests.json  # description field updated to name both audiences
- work-copilot/copilot-artifact-manifests.json     # description field updated; content becomes byte-identical to upstream

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- The `MIRROR_SPECS` array has only 3 supported glob shapes (single-file, flat-glob, recursive-glob). More exotic shapes (e.g., extension other than `.md`) are an explicit YAGNI — every current mirror artifact is markdown. Future non-md artifacts can add a new shape when the need is real.
- `cmp -s` runs in binary mode by default — protects against D000005's CRLF flap on Windows. Do NOT switch to `diff` or text-mode comparisons.
- Extending the existing counterpart-warning loop (which finds bundle files with no upstream and warns rather than fails) is mandatory: dropping the warning makes orphaned bundle files invisible, which is exactly the failure mode the warning was added for.
- Manifest pair sync uses different filenames (`company-artifact-manifests.json` vs `copilot-artifact-manifests.json`) but byte-identical content. The runtime contract is the filename — `company-workflow validate` (Claude Code) and `validate.prompt.md` (Copilot) each read their own. Renaming would break one runtime.
- Future mirror dirs (when knowledge integration ships its Copilot-native redesign) get added as one new `MIRROR_SPECS` line — no other code changes. This is the design's primary extensibility property; preserve it.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-26 — decision
T000011 scaffolded as a sibling task under S000010. Owns the
`scripts/validate.sh` sync-check generalization in isolation; S000010 owns
the bundle-artifact mirror content. Clean PR boundary: story = bundle
expansion, task = CI enforcement. Both land together in v0.15.0.

### 2026-04-26 — decision
Glob shapes locked to single-file / flat-glob / recursive-glob (plan-eng-review D3).
File-name filter locked to `*.md` (plan-eng-review C1) to keep OS junk out
(`.DS_Store`, `Thumbs.db`). Manifest pair description unification locked in
plan-eng-review D4 — both manifests get the same description naming both
audiences (Claude Code + Copilot).

### 2026-04-26 — decision
Test plan locked: 9 negative-path synthetic cases (3 shapes × 3 failure
modes: drift / missing-file / orphan) plus 1 happy-path case (all in sync
→ exit 0). Total ~150 lines of test bash; mimics the `mktemp -d -t ...` +
post-test cleanup pattern at `scripts/test.sh:1454-1510`.

### 2026-04-26 — decision (autoplan)
Three of T000011's locked design decisions revised by /autoplan after dual-voice
review (Claude subagent + Codex):

- **D2 (CRITICAL):** Recursive shape rewritten from bash `**/*.md` (broken on
  bash 3.2.57 dev box) to `find -name '*.md' -print0 | while IFS= read -r -d ''`.
  Portable, handles spaces/hidden/symlinks. Test cases 7-9 + 10 use new shape.
- **D3 (HIGH):** Orphan policy split by spec identity. New authoritative mirrors
  (WORKFLOW.md, reference/, philosophy/, examples/, fixtures/) FAIL on orphan;
  templates retain v1 WARN-only. Test cases 6 + 9 invert assertion for new
  mirror entries.
- **D5 (MEDIUM):** Manifest pair sync rewritten from byte-identity (cmp -s) to
  schema parity (`jq 'del(.description)'` then diff). No code consumes
  `description` field. Supersedes plan-eng-review D4. Test case 15 asserts
  schema-parity, not byte-equality.

Additional test cases mandated by autoplan eng-review test-plan addendum:
G5-G10 (files with spaces, symlinks, empty src dir, .gitkeep filter, doctor
DRIFT on nested fixture, install-then-validate-target). MIRROR_SPECS spec
grammar updated to a 4-tuple per entry: `src:dst shape:orphan-policy`.
