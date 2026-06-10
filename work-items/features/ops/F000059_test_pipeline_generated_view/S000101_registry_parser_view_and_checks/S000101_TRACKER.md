---
name: "test-pipeline registry + parser + generated view + hard sync/coverage checks"
type: user-story
id: "S000101"
status: active
created: "2026-06-10"
updated: "2026-06-10"
parent: "F000059"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/hardcore-napier-1efc3f"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
# receipts:               # optional; WRITTEN AT RUNTIME by /CJ_qa-work-item Step 9 (F000053/S000093), not at scaffold.
#   qa:                   # The SHA-anchored execution receipt qa.md Step 3's resume re-validation gate checks.
#     phase: 3            # Schema = work-copilot receipts.qa (work-copilot/prompts/qa.prompt.md) + a `commit` field.
#     commit: "<sha>"     # The commit this receipt vouches for (stale-SHA detection).
#     completed_at: "<ISO-8601 UTC>"
#     test_rows_run: 0
#     ac_ids_covered: []
#     ac_ids_uncovered: []
#     diff_audit: { changed_files_without_tests: [] }
#     ready_for_ship: false
#     next_legal: []
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/test_pipeline_generated_view` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
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
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
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

- [ ] spec/test-pipeline.md exists as the 4th spec-registry member: prose preamble + ONE fenced yaml registry (schema_version 1), one row per verification unit (~65 rows authored from the design doc's Registry inventory appendix, re-verified against the live tree), each row carrying id / family (closed enum: validate | test | test-deploy | eval | windows-smoke | ci | hook) / label (work-item-ID-free, namespace prefixes preserved — "Error check 11" and "Check 11" are distinct rows) / anchor (literal grep string; MAY carry work-item IDs, never renders) / source / layer (local-hook | ci) / disposition (hard-fail | advisory) with optional skips_when_absent + ratchet booleans / trigger (each token in pre-commit | post-merge | pr-ci | push-main | nightly | manual) / purpose (single-line, ID-free). For tests/*.test.sh rows, source is scripts/test.sh and anchor is the literal runner path.
- [ ] scripts/test-pipeline.sh (gate-spec.sh awk idiom, ~200 lines) supports --validate (schema check incl. rendered-field work-item-ID lint), --list-units, --render (AUTO-GENERATED header + leading per-family summary table + per-family unit tables + single gate-spec pointer line for the pipeline-gate layer); resolves the registry spec/-then-root via git rev-parse --show-toplevel; passes the stricter apt shellcheck in CI.
- [ ] docs/test-pipeline.md is fully GENERATED via scripts/generate-doc-views.sh (third output; skips cleanly with a note when parser or registry is absent), idempotent, opens with the summary table before the first `## ` heading, contains zero work-item IDs, and links to spec/gate-spec.md for the layer story.
- [ ] validate.sh Check 23 is extended (HARD): the temp-regen+diff loop covers docs/test-pipeline.md, running ONLY when scripts/test-pipeline.sh AND spec/test-pipeline.md are both present (consumer-repo skip with a note).
- [ ] validate.sh Check 24 (NEW, HARD, SKIP-when-registry-absent) passes with a clean baseline: forward — every registry anchor greps -F in its declared source; reverse — every live `=== Check N` banner / `# Error check N:` / `# Warning check` comment in validate.sh, every tests/*.test.sh on disk, every .github/workflows/*.yml, and every install_hook invocation in scripts/setup-hooks.sh resolves to exactly one registry row in its namespace; floor-assert ≥ 20 reverse tokens; tests/cj-goal-feature-smoke.test.sh triaged (registered or retired) BEFORE the check lands.
- [ ] Both docs are doc-spec-registered (docs/test-pipeline.md: common / human-doc / front_table: required, workbench requirement naming the generator + Check 23; spec/test-pipeline.md: custom / operational) and the Common seed grows 10 → 11 in lockstep (templates/doc-spec-common.md + scripts/doc-spec.sh heredoc byte-identical full-file; spec/doc-spec.md Common marker block + prose counts; mechanism-neutral seed requirement string; doc-spec.sh header-comment count corrected); docs/doc-general.md + docs/doc-custom.md regenerated; config-test 13 green.
- [ ] tests/test-pipeline-spec.test.sh exists, is REGISTERED in scripts/test.sh's hand-wired sub-suite runner, and covers: parser round-trip (--validate passes live; --render idempotent + ID-free; malformed-registry fixtures fail) and the four temp-dir-isolated drift drills (fake banner → reverse flag; broken anchor → forward flag; hand-edited view → Check 23-extension fail; removed runner block → orphaned-row forward flag); test.sh also gains the Check-23-extension mirror and the zzz-test-scaffold integration fixture is verified invariant; self-inclusion loop-back rows added (Check 24 itself + the new test suite) and the view re-rendered.
- [ ] Consumer-repo safety: generator and both new/extended checks skip cleanly when the registry/parser is absent, mirroring Check 16/23's SKIP posture.
- [ ] Secondary docs swept: CLAUDE.md scripts-reference table row for test-pipeline.sh + updated generate-doc-views.sh description; spec-registry family counts 3 → 4 in CLAUDE.md / docs/architecture.md doc-contract sections; architecture.md gains the test-pipeline mechanism; `./scripts/validate.sh` + `./scripts/test.sh` fully green.

## Todos

<!-- Actionable items for this story. -->

- [x] Step 0: triage tests/cj-goal-feature-smoke.test.sh (the live silent-skip instance) — register in test.sh's hand-wired runner section if current, retire if superseded; Check 24 baseline must be clean either way. → REGISTERED (see journal [impl-decision]).
- [x] Step 1: author spec/test-pipeline.md (prose + ~65-row registry) from the design doc's Registry inventory appendix, re-verified against the live tree. → 66 rows (the appendix's 65 + the new F000059 inline-guard family row).
- [x] Step 2: build scripts/test-pipeline.sh (--validate / --list-units / --render + rendered-field ID-lint), gate-spec.sh idiom; apt-shellcheck-clean. → also carries --check-coverage (the Check 24 engine, REPO_ROOT/TEST_PIPELINE_PATH-overridable for the temp-dir drills).
- [x] Step 3: wire generate-doc-views.sh third output (skip-when-absent); generate docs/test-pipeline.md.
- [x] Step 4: doc-spec registry entries for both docs + Common-seed lockstep (3 copies + prose counts, exact requirement strings per the feature DESIGN) + regenerate doc views.
- [x] Step 5: validate.sh — extend Check 23 (registry+parser-presence skip predicate); add Check 24 (hard, floor-asserted, documented reverse boundary).
- [x] Step 6: tests/test-pipeline-spec.test.sh + test.sh registration + Check-23-extension mirror + zzz-test-scaffold invariance assert; run the four drift drills. → suite passes standalone (23/23 OK incl. all four drills); zzz invariance asserted by the existing integration cycle running the now-extended validate.sh (full test.sh deferred to QA).
- [x] Step 6.5: self-reference loop-back — add registry rows for Check 24 itself and tests/test-pipeline-spec.test.sh; re-render docs/test-pipeline.md; re-run validate. → rows authored up-front (validate-check-24, test-test-pipeline-spec, test-cj-goal-feature-smoke, testsh-test-pipeline-guards); coverage clean: rows=66 reverse_tokens=47 findings=0.
- [x] Step 7: CLAUDE.md / docs/architecture.md secondary-doc sweep; full validate + test green (no tree mutations while test.sh runs). → validate.sh PASS 0/0; full test.sh deferred to QA per the restore-trap caution.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-10: Created. Single atomic story carrying the full test-pipeline build: stray-test triage, ~65-row spec registry, parser, generated human view, hard Check 23 extension + hard Check 24 coverage cross-check, doc-spec/seed lockstep growth to 11 general docs, new registered test suite with four drift drills, and the secondary-doc sweep.
- 2026-06-10: Implementation complete (uncommitted, this worktree). All 9 steps done: smoke harness REGISTERED (Step 0), 66-row registry authored + every anchor re-verified against the live tree, parser/renderer/coverage engine shipped (shellcheck-clean), third generated view live, Check 23 extended + Check 24 added (hard, skip-when-registry-absent), seed grown 10 → 11 in lockstep (3 byte-identical copies; config-test 13 green), tests/test-pipeline-spec.test.sh 23/23 green standalone + registered, CLAUDE.md/architecture.md swept (family 3 → 4). ./scripts/validate.sh PASS 0 errors 0 warnings; re-render byte-idempotent.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- spec/test-pipeline.md (new)
- scripts/test-pipeline.sh (new)
- docs/test-pipeline.md (new, generated)
- scripts/generate-doc-views.sh (modified)
- scripts/validate.sh (modified — Check 23 extension + new Check 24)
- spec/doc-spec.md (modified)
- templates/doc-spec-common.md (modified)
- scripts/doc-spec.sh (modified)
- docs/doc-general.md, docs/doc-custom.md (regenerated)
- tests/test-pipeline-spec.test.sh (new)
- scripts/test.sh (modified)
- tests/cj-goal-feature-smoke.test.sh (triaged: REGISTERED in scripts/test.sh — file itself unchanged)
- CLAUDE.md, docs/architecture.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The forward anchor rule for test rows (source = scripts/test.sh, anchor = the literal runner path) is the mechanism that turns "did anyone remember to register the test file?" from comment-discipline into a hard check — tests/cj-goal-feature-smoke.test.sh is its first catch.
- Extraction grammar honors live irregularities: regexes written `[0-9]+[a-z]?` with namespace prefixes kept; Check 15 is ONE row (15a/15b are bare comments); Check 17 is echo-anchored only; retired Check 12 must not be resurrected.
- test.sh wrapper blocks that merely invoke a standalone suite share that suite's row via multi-valued triggers (e.g. windows-smoke: "pr-ci push-main manual") — no duplicate rows.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-10 [impl-decision] Step 0 triage verdict: REGISTER tests/cj-goal-feature-smoke.test.sh (not retire). Evidence: the harness runs green on the live tree (6/6 cases, exit 0); cases 3–4 cover seams NO registered suite duplicates (`--phase ship` alias → pr-check fail-soft; `--phase telemetry` JSONL receipt emission — `grep 'phase telemetry' tests/ scripts/test.sh` has zero other hits); cases 1–2 overlap tests/cj-worktree-init.test.sh (h1) + the inline goal-common phase family but harmlessly. The file's pre-skill framing is historical, its assertions are current; "the natural fix for an unwired-but-green test is to WIRE it" is the very principle this feature mechanizes. File registered byte-unchanged; registry row test-cj-goal-feature-smoke added; Check 24 baseline clean with the registration.
- 2026-06-10 [impl-decision] Check 24's engine lives in scripts/test-pipeline.sh (`--check-coverage`), not inline in validate.sh: the helper honors `REPO_ROOT`/`TEST_PIPELINE_PATH` overrides, which is what lets the four drift drills run temp-dir isolated against a COPY of the swept surface (the validate.sh block stays a thin presence-gated wrapper, mirroring Check 16's helper posture: registry-absent → SKIP; registry-present-helper-missing → ERROR).
- 2026-06-10 [impl-decision] Row count landed at 66, not the appendix's 65: the new parallel-assertion block in test.sh (`# === F000059: test-pipeline registry + coverage guards ===`) is itself a live inline family, so it got the 16th inline-family row (testsh-test-pipeline-guards) — the self-inclusion principle applied one level deeper than the design enumerated. Splits: validate 27 (12 error + 13 banner incl. Check 24 + 2 warning), test 31 (15 registered incl. the smoke + the new suite, + 16 inline), suites 3, ci 3, hooks 2.
- 2026-06-10 [impl-decision] hook-post-merge row is disposition: advisory (the appendix left it unstated): the live hook body ends `exit 0` unconditionally ("Best-effort: always exit 0 to avoid blocking git operations") — calling it hard-fail would misdocument the surface the row exists to describe.
- 2026-06-10 [impl-finding] TSV-over-bash-read gotcha: tab is IFS *whitespace*, so consecutive tabs (empty optional skips_when_absent/ratchet columns) COLLAPSE under `read` and shift every later column left — first parse blamed a present `trigger` as missing. Fixed structurally in _parse_units: empty fields emit a literal `-` placeholder; every reader normalizes `-` → "". (gate-spec.sh/doc-spec.sh never hit this — their TSVs have no empty middle columns.)
- 2026-06-10 [impl-finding] The reverse-sweep floor counts 47 live tokens today (13 banners + 12 error comments + 2 warning comments + 15 test files + 3 workflows + 2 hooks), comfortably above the 20 floor; the warning-check namespace matches by anchor-containment (one member is unnumbered) where the numbered namespaces match by derived row id.
- 2026-06-10 [impl] 15 files changed (5 new: spec/test-pipeline.md, scripts/test-pipeline.sh, docs/test-pipeline.md, tests/test-pipeline-spec.test.sh + this tracker set pre-existing; 10 modified: generate-doc-views.sh, validate.sh, test.sh, spec/doc-spec.md, templates/doc-spec-common.md, scripts/doc-spec.sh, docs/doc-general.md, docs/doc-custom.md, CLAUDE.md, docs/architecture.md). Verified: validate.sh PASS 0/0 (Check 23 third-view PASS + Check 24 PASS rows=66 reverse_tokens=47 findings=0); re-render byte-idempotent (3-way per-file diff); rendered view ID-free + front-table-shaped + gate-spec-linked; seed heredoc == template byte-identical AND spec/doc-spec.md Common block byte-identical (config-test 13 + manual diff both green); tests/test-pipeline-spec.test.sh standalone 23 OK / 0 FAIL; both new/extended test.sh inline blocks extracted + run green in isolation; shellcheck clean on all 5 touched scripts. Full ./scripts/test.sh deferred to QA (restore-trap vs in-flight tree caution).
- 2026-06-10 [impl-pass] S000101: implementation complete. Phase 2 implementer-owned gates transitioned (Todos current; Files updated). QA-owned gates left for /CJ_qa-work-item.
