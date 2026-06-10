<!-- AUTO-GENERATED from scripts/test-pipeline.sh --render — do not edit. Edit spec/test-pipeline.md, then run scripts/generate-doc-views.sh. -->
# Test pipeline — the verification surface

Every validator check, test family, standalone suite, CI workflow and git hook that protects this repo — what each asserts, how it fails (hard-fail vs advisory, with skip-when-absent and regression-ratchet flags), and when it runs. Generated from the machine registry; do not edit by hand.

| Family | Units | Hard / advisory | Triggers |
|--------|-------|-----------------|----------|
| validate — scripts/validate.sh checks | 27 | 22 hard / 5 advisory | pre-commit, pr-ci |
| test — scripts/test.sh suite | 31 | 31 hard / 0 advisory | pr-ci |
| test-deploy — skills-deploy suite (scripts/test-deploy.sh) | 1 | 1 hard / 0 advisory | pr-ci, push-main, manual |
| eval — behavioral eval harness (scripts/eval.sh) | 1 | 1 hard / 0 advisory | nightly, manual |
| windows-smoke — Git Bash smoke (scripts/windows-smoke.sh) | 1 | 1 hard / 0 advisory | pr-ci, push-main, manual |
| ci — GitHub Actions workflows | 3 | 3 hard / 0 advisory | pr-ci, push-main, nightly, manual |
| hook — git hooks (scripts/setup-hooks.sh) | 2 | 1 hard / 1 advisory | pre-commit, post-merge |

Pipeline-gate enforcement (the inline goal-pipeline halts during a run) is deliberately not enumerated here — [spec/gate-spec.md](../spec/gate-spec.md) owns the gate sequence and the four-layer model.

## validate — scripts/validate.sh checks

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| Error check 1 — catalog entries have SKILL.md on disk | Every catalog entry's declared SKILL.md exists on disk; templates-only entries are exempt. | hard-fail | pre-commit, pr-ci |
| Error check 2 — SKILL.md frontmatter required fields | Every SKILL.md carries name and description in its YAML frontmatter. | hard-fail | pre-commit, pr-ci |
| Error check 3 — declared templates exist on disk | Every catalog templates entry resolves to a file on disk, honoring per-skill source overrides. | hard-fail | pre-commit, pr-ci |
| Error check 4 — no orphan skill directories | Every skill directory on disk (active or lifecycle-relocated) is claimed by a catalog entry. | hard-fail | pre-commit, pr-ci |
| Error check 5 — doc triplets complete with type frontmatter | Any per-skill doc directory carries all three design docs, each with type frontmatter. | hard-fail | pre-commit, pr-ci |
| Error check 6 — skill dependencies resolve | Every declared skill dependency names another catalog entry. | hard-fail | pre-commit, pr-ci |
| Error check 7 — VERSION file valid semver | The VERSION file exists and parses as semver. | hard-fail | pre-commit, pr-ci |
| Error check 8 — VERSION never regresses | VERSION is at least the latest collection v-tag; a version regression fails the build (ratchet). | hard-fail · ratchet | pre-commit, pr-ci |
| Error check 9 — catalog skill versions valid semver | Every catalog entry's version field parses as semver. | hard-fail | pre-commit, pr-ci |
| Error check 9b — catalog status closed enum | Every catalog status is one of active, experimental or deprecated; typos fail loudly. | hard-fail | pre-commit, pr-ci |
| Error check 10 — Copilot bundle file existence | Every required Copilot bundle file in the expected-files array is present on disk. | hard-fail | pre-commit, pr-ci |
| Error check 11 — manifest reconciliation | Work-item dirs and valid fixtures carry every artifact their manifest requires for their tracker type. | hard-fail | pre-commit, pr-ci |
| Warning check — orphan doc directories | Flags per-skill doc directories with no matching catalog entry. | advisory | pre-commit, pr-ci |
| Warning check 3 — orphan template files | Flags template files not referenced by any catalog entry, across the default dir and overrides. | advisory | pre-commit, pr-ci |
| Check 11 — rules deploy health | Every rules file is deployed to the local rules target; warn-degrades when the deploy target is absent. | hard-fail · skips when absent | pre-commit, pr-ci |
| Check 13 — USAGE.md present with required sections | Every routable non-deprecated skill has a USAGE.md with the five required section headings. | hard-fail | pre-commit, pr-ci |
| Check 14 — USAGE.md content freshness | USAGE.md's last commit is at least as recent as its sibling SKILL.md's (git timestamps, staged-aware); skips untracked files (ratchet). | hard-fail · skips when absent · ratchet | pre-commit, pr-ci |
| Check 15 — doc registry declared matches on-disk + workflow doc completeness | 15a: every declared doc exists and every doc under docs/ and spec/ is declared (no orphans); 15b: the workflow doc carries a charted section plus a four-bullet Touches block per goal orchestrator. | hard-fail | pre-commit, pr-ci |
| Check 16 — doc registry schema | The doc registry parses: one yaml fence, supported schema version, required keys, closed enums; skips when the registry is absent. | hard-fail · skips when absent | pre-commit, pr-ci |
| Check 17 — root-doc placement allowlist | Every root markdown doc on disk is a declared registry path, and every declared root doc exists. | hard-fail | pre-commit, pr-ci |
| Check 18 — skill portability audit | Each skill's declared portability matches its actual executed dependencies; the clean zero-findings baseline is the ratchet (strict mode flips findings to errors); skips when the engine is absent. | advisory · skips when absent · ratchet | pre-commit, pr-ci |
| Check 19 — no work-item refs in human docs | No registry human-doc contains an internal work-item ID; skips when the doc registry is absent. | hard-fail · skips when absent | pre-commit, pr-ci |
| Check 20 — front-table docs open with a summary table | Every front-table-flagged doc opens with a Markdown table before its first section heading; skips when the doc registry is absent. | hard-fail · skips when absent | pre-commit, pr-ci |
| Check 21 — permission-policy drift | The permission policy parses, the handoff gate derives its denylist from it, and every goal orchestrator references it; skips when the policy is absent. | advisory · skips when absent | pre-commit, pr-ci |
| Check 22 — gate-spec marker drift | The gate-spec registry parses and every declared literal halt marker appears in its mode's pipeline files; skips when the registry is absent. | advisory · skips when absent | pre-commit, pr-ci |
| Check 23 — generated doc views in sync | Regenerates the doc views (general, custom, and — when the test-pipeline registry and parser are present — the test-pipeline view) into a temp dir and diffs against docs/; any drift fails. | hard-fail · skips when absent | pre-commit, pr-ci |
| Check 24 — test-pipeline coverage cross-check | Forward: every test-pipeline registry anchor greps in its declared source. Reverse: every live validate banner and comment, test file on disk, workflow, and hook resolves to exactly one registry row, with a floor of twenty reverse tokens; skips when the registry is absent. | hard-fail · skips when absent | pre-commit, pr-ci |

## test — scripts/test.sh suite

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| cj-worktree-init suite — worktree creation helper | Caller prefixes, dirty-checkout guard and base-freshness fork behavior of the worktree-init helper. | hard-fail | pr-ci |
| cj-worktree-cleanup suite — post-run worktree janitor | PR-state-gated sweep, orphan-dir removal, guard refusals and pipeline seams of the worktree janitor. | hard-fail | pr-ci |
| cj-task-scaffold suite — task complexity gate + scaffold | Complexity-gate refusals, dry-run preview, live scaffold and idempotency of the task scaffolder. | hard-fail | pr-ci |
| setup-hooks suite — git hook installer | The installed post-merge hook re-deploys skills without mutating trackers; hook install is clobber-safe. | hard-fail | pr-ci |
| drain-one-todo suite — deployed-path resolution | A deployed drain helper resolves the worktree-init helper via the manifest source path. | hard-fail | pr-ci |
| drain-one-todo suite — unreachable-helper fail-loud | The drain halts loudly when the worktree helper is unreachable instead of scaffolding in place. | hard-fail | pr-ci |
| cj-document-release suite — doc-release skill structure | Doc-release skill structure, frontmatter, halt markers and config-helper assertions. | hard-fail | pr-ci |
| doc-release config suite — doc registry + helper + seed | Doc registry shape, every doc-spec helper subcommand, strict no-config gates, and the byte-identical embedded seed. | hard-fail | pr-ci |
| goal doc-sync wiring suite — symmetric step wiring | The doc-sync step and halt-taxonomy rows are present and correctly ordered in the goal orchestrators. | hard-fail | pr-ci |
| post-land-sync suite — post-merge local sync helper | Sync-helper guards refuse a bad source checkout; dry-run previews without mutating the live home. | hard-fail | pr-ci |
| goal-common sync suite — pre-build skills-sync phase | Dry-run, opt-out, guard-refusal and real-run paths of the pre-build sync phase all emit the four-key schema, fail-soft and hermetic. | hard-fail | pr-ci |
| goal-common portability suite — pre-ship portability gate | A clean catalog passes, dry-run runs nothing, a dishonest declaration yields findings, and an absent engine skips fail-soft. | hard-fail | pr-ci |
| cj-id-claim suite — atomic work-item ID claim | Concurrent-race uniqueness, both reap modes, prefix isolation, same-branch reuse and worktree-shared claim-root resolution. | hard-fail | pr-ci |
| feature-path smoke suite — worktree entry + common phases | Feature-caller worktree entry, the shared helper's worktree/ship/telemetry phases, and leaf dispatch targets present on disk. | hard-fail | pr-ci |
| test-pipeline suite — registry parser + drift drills | Parser round-trip, malformed-registry fixtures, and the temp-dir drift drills (banner, anchor, view, runner, hook-env, unregistered file, source pin, dead text, disabled check, vanished suite) for the coverage cross-check and view-sync. | hard-fail | pr-ci |
| Inline — full validator re-run | Runs the whole validator inside the test suite so every check gates the test run too. | hard-fail | pr-ci |
| Inline — harness-principle regression guards | Static guards that the trajectory-QA, permission-policy, gate-spec and within-phase-receipt fixes stay in place. | hard-fail | pr-ci |
| Inline — catalog + frontmatter + doc-triplet smoke | No duplicate skill names; SKILL.md frontmatter parses; doc triplets carry their required sections. | hard-fail | pr-ci |
| Inline — advisory-script crash + generator idempotency | Doctor, lint and deps scripts run without crashing; the README and doc-view generators are idempotent (temp-only). | hard-fail | pr-ci |
| Inline — manual skill-creation integration cycle | A scaffolded temp skill keeps the validator green; plant-and-restore negatives prove the doc checks actually fire. | hard-fail | pr-ci |
| Inline — goal-common phase integration | Sync, portability-audit and task-worktree phases of the shared goal helper, end-to-end and hermetic. | hard-fail | pr-ci |
| Inline — template content + validator portability + orphan negatives | Tracker templates carry required sections; the workflow validator stands alone; orphan-directory detection fires. | hard-fail | pr-ci |
| Inline — defect and story regression battery | Shipped defect and story fixes stay fixed: CRLF wrappers, the merge-convention guard, template sync, copy-mode fallback and more. | hard-fail | pr-ci |
| Inline — Copilot bundle coverage + round-trip | Bundle completeness coverage, the instructions size budget and the deploy round-trip. | hard-fail | pr-ci |
| Inline — backlog append POSIX-clean guard | The improve-queue append path keeps the backlog file POSIX-clean. | hard-fail | pr-ci |
| Inline — version-queue preflight smoke | The version-queue preflight runs read-only and degrades cleanly when offline. | hard-fail | pr-ci |
| Inline — handoff-gate deterministic suite | Denylist hits, size caps, rename/symlink/test-weakening detection and the QA predicate of the deterministic handoff gate. | hard-fail | pr-ci |
| Inline — static wiring checks | Portable POSIX runtime idioms, registered-doc audit wiring, defect tracker promotion and the workflow-doc Touches blocks. | hard-fail | pr-ci |
| Inline — portability-engine hermetic fixture | The portability-audit engine's verdicts against a controlled fixture catalog. | hard-fail | pr-ci |
| Inline — install equals clone integration battery | Shared-script self-containment, bundle install, develop-in-place and the in-place install-equals-clone contract. | hard-fail | pr-ci |
| Inline — test-pipeline registry + coverage guards | The test-pipeline parser validates, the rendered view stays free of work-item IDs, the generated view is in sync, and the coverage cross-check passes on the live tree. | hard-fail | pr-ci |

## test-deploy — skills-deploy suite (scripts/test-deploy.sh)

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| skills-deploy suite — install/doctor/remove in isolation | Template ownership, drift overwrite, copy-mode fallback and doctor verdicts in isolated temp homes; runs inside the test suite, in the Windows workflow, and by hand. | hard-fail | pr-ci, push-main, manual |

## eval — behavioral eval harness (scripts/eval.sh)

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| behavioral eval harness — headless skill evals | Spawns the headless CLI against scratch worktrees per eval case with JSON-schema output validation; budget-capped per case and per run. | hard-fail | nightly, manual |

## windows-smoke — Git Bash smoke (scripts/windows-smoke.sh)

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| Windows smoke — CRLF + portable date + copy-mode | Git Bash portability assertions: CRLF tolerance, portable date math, copy-mode install and the in-place install stamp. | hard-fail | pr-ci, push-main, manual |

## ci — GitHub Actions workflows

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| validate workflow — PR gate | Runs the validator, the full test suite and shellcheck on every pull request. | hard-fail | pr-ci |
| windows workflow — Git Bash gate | Runs the Windows smoke and the skills-deploy suite under Git Bash on every pull request and push to main. | hard-fail | pr-ci, push-main |
| eval-nightly workflow — scheduled evals | Runs the behavioral eval harness on a daily schedule, with a manual dispatch trigger. | hard-fail | nightly, manual |

## hook — git hooks (scripts/setup-hooks.sh)

| Unit | What it asserts | Disposition | When it runs |
|------|-----------------|-------------|--------------|
| pre-commit hook — validator at commit time | Runs the validator before every local commit; a failing check blocks the commit. | hard-fail | pre-commit |
| post-merge hook — auto re-deploy | Re-deploys skills, templates and rules into the local home after pulls that touch them; best-effort, never blocks git. | advisory | post-merge |
