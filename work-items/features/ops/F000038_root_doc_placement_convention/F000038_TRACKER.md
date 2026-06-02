---
name: "Root-doc placement convention + validate.sh Check 17"
type: feature
id: "F000038"
status: active
created: "2026-06-02"
updated: "2026-06-02"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260602-152028-3848"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `cj-feat-20260602-152028-3848` (auto-created by /CJ_goal_feature worktree phase from origin/main HEAD post-PR #194 merge, commit 10644ac; no upstream stacking)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment (deferred — /CJ_goal_feature stops at PR)
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets (deferred — folded into Step 5.5 inline /CJ_document-release)

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `CLAUDE.md` has a new `## Doc placement convention (root vs doc/)` section containing the prose rule (explanation docs live in `doc/` + tracked-doc manifest; root `*.md` limited to the allowlist; configs stay at root; per-subtree docs out of scope) PLUS a `### Tracked root docs allowlist` block with all 5 entries (path + reason): README.md, CLAUDE.md, CHANGELOG.md, CONTRIBUTING.md, TODOS.md.
- [ ] The CLAUDE.md prose just ABOVE the YAML block (NOT inside the fence) states the two load-bearing constraints: (1) no `#`-leading comment lines inside the block (Check 17's parser disarms on any `#` and silently drops every entry below it); (2) the `### Tracked root docs allowlist` heading text is matched literally (renaming parses to an empty allowlist → cascades to an orphan ERROR for every root `*.md`).
- [ ] `scripts/validate.sh` has a new Check 17 inserted after Check 16: parses the allowlist via a flag-based awk that disarms on ANY heading (`/^#/`, not just `^###`); enumerates root `*.md` via `find . -maxdepth 1 -type f -name '*.md'`; ERRORs on orphan (root `*.md` not allowlisted) and on missing (allowlist entry pointing to a missing file) using the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form (NOT the older `fail()` helper); counts entries once into a var and prints a single PASS line when the allowlist parsed (`PASS: root *.md allowlist parsed (N entries)`).
- [ ] On the clean PR HEAD, `./scripts/validate.sh` exits 0 (Check 17 PASS, 0 errors, 0 warnings) — all 5 current root docs are on the allowlist, so nothing violates the rule day-one.
- [ ] Synthesized violation: `touch STRAY.md` at repo root → `validate.sh` exits non-zero with the Check 17 orphan message (`  ERROR: root doc STRAY.md is not in the CLAUDE.md ...`). `rm STRAY.md` → exits 0 again.
- [ ] `scripts/test.sh` `zzz-test-scaffold` integration is extended with the Check 17 orphan assertion (the KNOWN BLIND SPOT — every prior new validate.sh check, F000032/F000034/F000035/F000037, needed this parallel edit and the implement step systematically forgot it): in the scaffolded fixture repo, `touch STRAY.md` at root → assert validate.sh exits non-zero AND output contains the literal `  ERROR: root doc STRAY.md is not in the CLAUDE.md`; then `rm STRAY.md` → assert validate.sh exits 0.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD (superset suite, including the extended zzz-test-scaffold integration test).
- [ ] No `SKILL.md` / `USAGE.md` / `skills-catalog.json` / manifest-JSON modified (no doc-drift Check 13/14, no catalog churn) — this is a CLAUDE.md + validate.sh + test.sh change only.
- [ ] README.md, CLAUDE.md, and all 4 root config files (skills-catalog.json, cj-document-release.json, template-registry.json, VERSION) remain at root, byte-for-byte unchanged (zero file moves).
- [ ] `CHANGELOG.md` has a new user-forward entry under `### Added` naming F000038 + the root-doc placement convention + Check 17 + the symmetry with F000034's tracked-doc/ manifest (together they partition the top-level doc surface).
- [ ] `VERSION` bumped to the next free slot (6.0.3 → likely 6.0.4 PATCH; `./scripts/check-version-queue.sh` resolves the queue before /ship).
- [ ] PR opened against main via `/ship` (pre-landing review included). /CJ_goal_feature stops at PR per design; no auto-merge, no /land-and-deploy in this PR. PR body notes the F000034 lineage (symmetric root-side counterpart, reuses Check 15's parse shape) + F000037 (the most recent root JSON, the event that made root consolidation a live question).
- [ ] No upstream `/document-release` modification. No changes to `~/.claude/`, `deprecated/`, or `work-copilot/`.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] Ship S000071 (`root_doc_placement_convention_impl`) — single atomic user-story carrying the CLAUDE.md `## Doc placement convention (root vs doc/)` section + `### Tracked root docs allowlist` YAML manifest (5 entries) + scripts/validate.sh Check 17 + scripts/test.sh zzz-test-scaffold Check 17 orphan assertion + VERSION + CHANGELOG.
- [ ] End-to-end pipeline run — `/ship` opens PR against main; `./scripts/validate.sh` PASS (Check 17 PASS, 0 errors / 0 warnings); `./scripts/test.sh` PASS. Synthesized-violation smoke (`touch STRAY.md` → ERROR+exit1; `rm` → exit0) walked before ship.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-02: Created. Self-enforcing capstone of the F000032→F000037 doc-infra lineage. Codifies + enforces the repo's root-vs-doc/ placement boundary with ZERO file moves. Original ask ("group human-readable configs and docs into a single doc folder") was reframed during /office-hours: the explanation docs already moved (F000034); what remains at root is pinned (README = GitHub landing), tool-conventioned (CLAUDE.md auto-load, CHANGELOG = /ship + /document-release write target, CONTRIBUTING = GitHub-surfaced), or operational state (TODOS = wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14); configs are tooling-pinned (skills-catalog.json ~246 refs, VERSION ~120). The real gap is that the placement boundary was implicit + unenforced — a new `FOO.md` could land at root with nothing catching it. F000038 adds a symmetric "Tracked root docs allowlist" in CLAUDE.md (mirrors F000034's tracked-doc/ manifest shape, `reason:` per entry instead of `audit_class:`) parsed by a new validate.sh Check 17. ERROR-strict on day one — all 5 current root docs are allowlisted, nothing violates. Branch cut from origin/main HEAD post-PR #194 merged (F000037 v6.0.3, commit 10644ac). No upstream stacking.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `CLAUDE.md` (MODIFIED — new `## Doc placement convention (root vs doc/)` section with prose rule + load-bearing-constraint comment + `### Tracked root docs allowlist` YAML block, 5 entries each with a reason; placed adjacent to the F000034 "/document-release workbench audit conventions" section for locality)
- `scripts/validate.sh` (MODIFIED — new Check 17 inserted after Check 16: flag-based-awk allowlist parser disarming on any heading, `find -maxdepth 1` root-md enumeration, orphan + missing ERROR branches via the inline `echo "  ERROR:"; ERRORS=$((ERRORS+1))` form, count-once PASS line)
- `scripts/test.sh` (MODIFIED — zzz-test-scaffold integration extended: `touch STRAY.md` → assert validate.sh ERROR+exit1 with the literal Check 17 orphan prefix; `rm STRAY.md` → assert exit0. KNOWN BLIND SPOT — mandatory parallel edit for every new validate.sh check)
- `VERSION` (MODIFIED — PATCH bump 6.0.3 → next free slot, likely 6.0.4; resolved via `./scripts/check-version-queue.sh`)
- `CHANGELOG.md` (MODIFIED — new entry under `### Added` in user-forward voice naming F000038 + the convention + Check 17 + F000034 symmetry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- **The two manifests fully partition the top-level doc surface.** F000034's tracked-doc/ manifest declares what lives in `doc/` (Check 15); F000038 adds a symmetric "Tracked root docs" allowlist declaring what is allowed at root and *why* (Check 17). Together they make every top-level `*.md` placement decision explicit and machine-checked — no human-readable doc can land at root by accident again. New explanation doc → `doc/` + tracked-doc manifest entry; new root `*.md` → justified + added to the root allowlist. Drift either way fails validate.sh.
- **Self-enforcing capstone of the F000032→F000037 doc-infra lineage.** Those PRs built the doc surface (per-skill USAGE conventions, SKILL-CATALOG, tracked-doc/ manifest, CJ_document-release, cj-document-release.json). This one locks down where new docs go, so the surface stays coherent without manual vigilance.
- **Self-documenting + zero blast radius.** Each allowlist entry carries a `reason:` (README = GitHub landing, CLAUDE = auto-load, etc.), so the convention explains itself at the point of enforcement. Nothing moves; nothing currently violates the rule, so it ships ERROR-strict on day one with no migration.
- **The original ask was reframed, not executed literally.** "Group configs and docs into a folder" became "codify where they belong" the moment the data showed the explanation docs had already moved (F000034) and the configs were tooling-pinned (246 refs to skills-catalog.json). Optimized for the convention, not the file move — the move was the surface ask, the convention was the real one. The coupling numbers killed the config-move ambition without a fight.
- **Chose the CLAUDE.md manifest (Approach B) over a JSON config (C) and a hardcoded bash array (A).** B is symmetric with F000034's doc/ manifest, single-source-of-truth, self-documenting via `reason:`, and reuses Check 15's proven parse shape. A would split the allowlist (validate.sh) from its rationale (CLAUDE.md prose) into two drifting places. C would add another root config surface — ironic for a feature about keeping the root tidy (the chosen option explicitly named that irony; same "don't add a knob you don't need" instinct that picked JSON-not-YAML in F000037, applied in the opposite direction here because the cost/benefit flipped).
- **Check 17 disarms on ANY heading (`^#`), not just `^###` — more robust than Check 15.** The allowlist is the last `###` subsection under its `##` section; disarming only on `###` would over-capture `- path:` lines from a following `##` section. Retrofitting Check 15's parser to the same robust form is out of scope (Check 15 works as-is given its position).
- **Empty-allowlist is not separately guarded; it fails loudly via orphan errors.** A renamed heading or a `#`-comment-line mid-block parses to an empty allowlist, which surfaces as an orphan ERROR for every root `*.md` — never a silent pass. The constraint comment in CLAUDE.md warns the editor; the check itself needs no extra guard.
- **The test.sh zzz-test-scaffold edit is a KNOWN RECURRING BLIND SPOT.** F000032 (Check 13), F000034 (Check 15), F000035, F000037 (Check 16) all needed a parallel edit to scripts/test.sh's integration fixture, and the implement step systematically forgot it each time. For Check 17 it is a mandatory pre-flight item in the implement prompt + an explicit TEST-SPEC row, not an afterthought.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-02 [decision] Driver = convention consistency (D1). Summary: All human-readable *explanation* docs already live in `doc/` (F000034 moved them). The work is to make the placement boundary EXPLICIT + ENFORCED, not to move more files. Reframed the original "group configs and docs into a folder" ask once the data showed the migration was essentially done and the configs were tooling-pinned.
- 2026-06-02 [decision] Scope = codify + enforce only (D2). Summary: No file moves. Configs (skills-catalog.json ~246 refs, cj-document-release.json, template-registry.json, VERSION ~120 refs) stay at root because tooling hardcodes `./` paths. The convention DOCUMENTS config placement (addressing the original "configs" framing) but adds NO config-file enforcement in v1. High-blast-radius churn for no functional gain was rejected.
- 2026-06-02 [decision] Mechanism = manifest in CLAUDE.md (D3, Approach B). Summary: A "Tracked root docs allowlist" YAML block in CLAUDE.md parsed by a new validate.sh Check 17, the same flag-based-awk way Check 15 parses the tracked-doc/ manifest. Chosen over Approach A (hardcoded bash array + separate prose — splits allowlist from rationale into two drifting places) and Approach C (JSON config — over-engineering for 5 filenames; adds another root config surface, ironic for a tidy-the-root feature).
- 2026-06-02 [decision] Root allowlist = the 5 current root docs, each with a stated reason. Summary: README.md (GitHub landing page), CLAUDE.md (Claude Code auto-loads ./CLAUDE.md), CHANGELOG.md (/ship + /document-release write ./CHANGELOG.md), CONTRIBUTING.md (GitHub surfaces from root/docs/.github), TODOS.md (operational backlog wired into /CJ_suggest, /CJ_goal_todo_fix, /ship Step 14). Nothing currently violates it → ERROR-strict ships safely day one.
- 2026-06-02 [decision] ERROR-strict, not warning. Summary: Matches the repo ethos (F000037 strict-required, the ERROR-strict Checks 12–16). Safe because all 5 current root docs are allowlisted; a stray new root `*.md` ERRORs + exits 1, forcing the contributor to either move it to `doc/` (+ tracked-doc manifest) or allowlist it with a reason.
- 2026-06-02 [decision] Check 17 scoped to root `*.md` only (`find . -maxdepth 1`). Summary: `doc/` is Check 15's job. Docs under `skills/`, `templates/`, `work-copilot/`, `work-items/`, `tests/` follow their own conventions (per-skill USAGE.md, template naming, work-item taxonomy) and are explicitly out of scope. Non-`.md` root files (LICENSE, .shellcheckrc, .gitignore) are out of scope — the convention governs human-readable `*.md` only.
- 2026-06-02 [decision] Check 17 inline ERROR form, not the fail() helper. Summary: Checks 15/16 increment ERRORS inline with the `  ERROR:` prefix; Check 17 matches that form rather than the older `fail()` helper (prefix `  FAIL:`) that checks 12–16 abandoned. Keeps the new check consistent with its immediate neighbors and makes the test.sh assertion grep for the right literal (`  ERROR:`).
- 2026-06-02 [decision] Single user-story decomposition (atomic implementation). Summary: CLAUDE.md section + Check 17 + test.sh assertion + VERSION + CHANGELOG ship atomically in one commit/PR. Same shape as F000037 (S000070). Pre-commit hook runs validate.sh; staging everything once avoids intermediate-state failures.
- 2026-06-02 [decision] No SKILL.md changes → no USAGE.md drift. Summary: This is a CLAUDE.md + validate.sh + test.sh change only. Check 13 (USAGE.md presence) + Check 14 (USAGE.md drift) untouched; no catalog churn; no manifest-JSON edits. Keeps the diff narrow + additive.
- 2026-06-02 [decision] Config-placement enforcement deferred to v2. Summary: A sibling "tracked root configs" manifest is deferred. Configs are tooling-pinned + stable; documenting the rule (Step 1 prose) is enough now. Honors the original "configs" mention without adding enforcement churn.
- 2026-06-02 [decision] PR-stop at /ship per /CJ_goal_feature semantics. Summary: /CJ_goal_feature stops at PR by design — PR is the architecture gate (human review). No /land-and-deploy in this PR. Per memory `project_workbench_auto_deploy_unsafe`.
- 2026-06-02 [decision] No upstream `/document-release` modification (workbench-only scope). Summary: Per memory `feedback_workbench_scope` + `project_workbench_auto_deploy_unsafe`. The new section rides /document-release's existing CLAUDE.md project-context read at Step 2; no upstream skill modification.
