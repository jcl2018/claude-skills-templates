---
name: "Relocate the spec-registry family to spec/ with a back-compat helper fallback"
type: user-story
id: "S000099"
status: active
created: "2026-06-08"
updated: "2026-06-08"
parent: "F000057"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/sleepy-cerf-e8f24b"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/relocate_spec_registry_family_into_spec_folder` (shipping in same PR as parent)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (atomic story — N/A)

**Gates:**
- [x] /office-hours design referenced (parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] The 3 files are at `spec/{doc-spec,gate-spec,permission-policy}.md` (history preserved via `git mv`); root has none.
- [ ] Each helper resolves `spec/`-first, root-second, with the env override outermost; all 3 `--validate` green from the repo.
- [ ] The `doc-spec.md` registry self-declares the 3 paths as `spec/<name>.md`; `--expand-whitelist` literal updated to `spec/doc-spec.md`.
- [ ] validate.sh Checks 16/19/20/21/22 print `PASS:` not `SKIP:`; Check 17 correct; new `spec/*.md` orphan scan green (mirrored into the test.sh zzz fixture); Check 23 in sync.
- [ ] test.sh PASS incl. S94 + S96; seed test #13 green (byte-identity); `PERMISSION_POLICY_PATH=/nonexistent … --validate` still FAILS.
- [ ] Generated views regenerated + header references `spec/doc-spec.md`; full prose sweep clean (no stale root-path ref to the 3 files anywhere).
- [ ] All of the above land in ONE lockstep commit (else validate transiently ERRORs 3 orphan/missing).
- [ ] A simulated root-only repo still resolves via the fallback (knowledge-base unaffected).

## Todos

<!-- Actionable items for this story. -->

- [ ] Delta 1 — `git mv` the 3 files into `spec/` (preserve history); create `spec/` (no other files).
- [ ] Delta 2 — back-compat resolution in each helper (`spec/` first, root second, env override OUTERMOST); add a `DOC_SPEC_PATH` override to `doc-spec.sh` for symmetry. POSIX/bash-3.2 idiom: `_p="$ROOT/spec/<name>.md"; [ -f "$_p" ] || _p="$ROOT/<name>.md"`.
- [ ] Delta 3 — update the 3 `section: custom` registry self-declarations in `spec/doc-spec.md` to `path: spec/<name>.md`.
- [ ] Delta 4 — validate.sh: Check 17 (root allowlist now excludes the 3), Check 15a + new `spec/*.md` orphan scan, Checks 21+22 green via helper fallback, Check 23 regen; mirror new check logic into test.sh.
- [ ] Delta 5 — `--expand-whitelist` literal `doc-spec.md` → `spec/doc-spec.md`.
- [ ] Delta 6 — regenerate views + fix the generated-from-`doc-spec.md` header string in `generate-doc-views.sh`; regenerate `docs/doc-general.md` + `docs/doc-custom.md`.
- [ ] Delta 7 — sweep prose/path refs across `scripts/`, `skills/` (6 MDs), `docs/`, `CLAUDE.md`, `README.md` (regen), the 3 files' own family/"root" prose.
- [ ] Must-fix A — teach the silent-SKIP guards: validate.sh:716/718 (Check 16), :821 (Check 19 HARD), :855 (Check 20), :898 (Check 21), :940/:971 (Check 22) all probe `spec/`-then-root.
- [ ] Must-fix B — hard-FAIL guards: test.sh:88 (S94 `_S94_POLICY`) + :125 (S96 `_S96_SPEC`) → spec/-first.
- [ ] Must-fix C — CJ_document-release SKILL.md: self-bootstrap guard (:156,158-163) + Step 6.7.1 parser (:534) read spec/-then-root; WRITE target for a genuinely-missing-everywhere file stays root-style.
- [ ] Must-fix D — env override OUTERMOST (test.sh:113 asserts `PERMISSION_POLICY_PATH=/nonexistent` FAILS); add `DOC_SPEC_PATH` override.
- [ ] Must-fix E — lockstep single commit + mirror the new spec/ orphan scan into the test.sh zzz integration fixture (the standing implement blind spot).
- [ ] Must-fix F — prose-accuracy sweep (CLAUDE.md, README regen + generate-readme.sh:22,36, docs/{architecture,philosophy,workflow}.md, 6 skill MDs, skills-catalog.json:315/332/338, templates/doc-WORKFLOWS-section.md:70, cj-handoff-gate.sh:66-68, cj-portability-audit.sh:22,132, doc-spec.sh:168, the 3 files' own prose).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-08: Created. Atomic story carrying all 8 deltas + reviewer must-fixes A–G for the spec-registry-family relocation; lands in one lockstep commit.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `doc-spec.md`/`gate-spec.md`/`permission-policy.md` → `spec/` (git mv)
- `scripts/doc-spec.sh`, `scripts/gate-spec.sh`, `scripts/permission-policy.sh`
- `scripts/validate.sh`, `scripts/test.sh`
- `scripts/generate-doc-views.sh`, `scripts/generate-readme.sh`
- `docs/doc-general.md`, `docs/doc-custom.md`, `README.md`
- `CLAUDE.md`, `docs/architecture.md`, `docs/philosophy.md`, `docs/workflow.md`
- `skills/CJ_document-release/SKILL.md` + 5 other skill MD path refs
- `skills-catalog.json`, `templates/doc-WORKFLOWS-section.md`, `scripts/cj-handoff-gate.sh`, `scripts/cj-portability-audit.sh`

## Insights

<!-- Non-obvious findings worth remembering. -->

- The `git mv` is the small part; the load-bearing part is the break-set the back-compat fallback does NOT cover — any caller that gates on a literal root `[ -f ]` BEFORE invoking the helper (validate.sh silent-SKIP class, test.sh hard-FAIL class, the CJ_document-release self-bootstrap duplicate-file bug). Missing one of these is a silent regression (validate PASS with a check disabled), not a loud failure.
- Everything must land in ONE commit: `git mv` + the 3 registry self-paths + helper fallbacks + the new `spec/*.md` orphan scan + its test.sh zzz-scaffold mirror. Splitting them transiently ERRORs 3 orphan/missing in validate and blocks the pre-commit hook.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] Env override is OUTERMOST: `X="${ENV:-<spec-if-exists-else-root>}"`. Summary: test.sh:113 asserts `PERMISSION_POLICY_PATH=/nonexistent --validate` FAILS; nesting the override inside the spec/root fallback would wrongly pass that regression.
- [finding] The original plan under-counted the break-set; 2 adversarial reviewers (4/10 + 5/10) found the silent-SKIP class (validate.sh), the hard-FAIL class (test.sh), and the CJ_document-release self-bootstrap duplicate-file bug. All are folded in as mandatory must-fixes A–G.
- [decision] Confirmed-SAFE set (no action, per the reviews): `.github/workflows/` (0 refs), `work-copilot/` + `EXPECTED_BUNDLE_FILES` (0 refs), the seed + `_emit_seed` heredoc (stay root-style → test #13 green), the cj-portability-audit runtime match-set (no new finding), `skills-deploy` (deploys `scripts/*.sh`, not the `.md`s), the config-test temp-repo root-style fixtures.
