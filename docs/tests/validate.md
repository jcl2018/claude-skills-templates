# Test catalog — `validate` family

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

Verification units in the `validate` family, rendered from the test-spec
registry. Each row shows only registry-rendered fields; the `anchor` is a
source reference, never a claim.

| Label | Layer | Disposition | Trigger | Source · anchor | Purpose |
|-------|-------|-------------|---------|-----------------|---------|
| portability audit — declared-vs-actual skill dependency lint | ci | advisory | pre-commit pr-ci manual | `scripts/validate.sh` · `scripts/cj-portability-audit.sh` | The portability engine behind the advisory audit check and the strict pre-ship orchestrator gate: each skill's declared portability matches its actual executed dependencies; the clean baseline is the ratchet. |
| Check 11 — rules deploy health | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 11:` | Every rules file is deployed to the local rules target; warn-degrades when the deploy target is absent. |
| Check 13 — USAGE.md present with required sections | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 13:` | Every routable non-deprecated skill has a USAGE.md with the five required section headings. |
| Check 14 — USAGE.md content freshness | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 14:` | USAGE.md's last commit is at least as recent as its sibling SKILL.md's (git timestamps, staged-aware); skips untracked files (ratchet). |
| Check 15 — doc registry declared matches on-disk + workflows completeness | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 15:` | 15a: every declared doc exists and every doc under docs/ (RECURSIVE, including the docs/workflows/ subfolder) and spec/ is declared (no orphans); 15b: each goal orchestrator's per-workflow file docs/workflows/<name>.md carries a charted section plus a four-bullet Touches block; 15c (no-vanish): the docs/workflow.md index links each goal orchestrator's docs/workflows/<name>.md. |
| Check 16 — doc registry schema | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 16:` | The doc registry parses: one yaml fence, supported schema version, required keys, closed enums; skips when the registry is absent. |
| Check 17 — root-doc placement allowlist | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 17:` | Every root markdown doc on disk is a declared registry path, and every declared root doc exists. |
| Check 18 — skill portability audit | ci | advisory | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 18:` | Each skill's declared portability matches its actual executed dependencies; the clean zero-findings baseline is the ratchet (strict mode flips findings to errors); skips when the engine is absent. |
| Check 19 — no work-item refs in human docs | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 19:` | No registry human-doc contains an internal work-item ID; skips when the doc registry is absent. |
| Check 21 — permission-policy drift | ci | advisory | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 21:` | The permission policy parses, the handoff gate derives its denylist from it, and every goal orchestrator references it; skips when the policy is absent. |
| Check 24 — test-spec coverage cross-check + gate marker drift | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 24:` | Validates the merged test-spec registry, then cross-checks coverage (forward, every unit anchor matches live in its declared source; reverse, every live validate banner and comment, test file on disk, workflow, and hook resolves to exactly one unit, with a floor of twenty reverse tokens) — hard; then the advisory per-mode gate marker-drift cross-check over the gates array (absorbed from the retired Check 22); skips when the registry is absent. |
| Check 25 — README in sync with generate-readme.sh | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 25:` | README.md byte-matches the generate-readme.sh stdout, so a stale catalog-derived README cannot pass validation; read-only (the generator writes only to stdout); skips when the generator is absent. |
| Check 26 — generated test catalog in sync with test-spec.sh --render-docs | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `=== Check 26:` | The generated test catalog (docs/tests/<family>.md per unit family plus the docs/test-catalog.md index) byte-matches a fresh render from the merged registry, so a stale catalog cannot pass validation; read-only (--check renders only into a temp dir); skips when the engine is absent or no units are declared. |
| Error check 1 — catalog entries have SKILL.md on disk | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 1:` | Every catalog entry's declared SKILL.md exists on disk; templates-only entries are exempt. |
| Error check 10 — Copilot bundle file existence | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 10:` | Every required Copilot bundle file in the expected-files array is present on disk. |
| Error check 11 — manifest reconciliation | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 11:` | Work-item dirs and valid fixtures carry every artifact their manifest requires for their tracker type. |
| Error check 2 — SKILL.md frontmatter required fields | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 2:` | Every SKILL.md carries name and description in its YAML frontmatter. |
| Error check 3 — declared templates exist on disk | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 3:` | Every catalog templates entry resolves to a file on disk, honoring per-skill source overrides. |
| Error check 4 — no orphan skill directories | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 4:` | Every skill directory on disk (active or lifecycle-relocated) is claimed by a catalog entry. |
| Error check 5 — doc triplets complete with type frontmatter | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 5:` | Any per-skill doc directory carries all three design docs, each with type frontmatter. |
| Error check 6 — skill dependencies resolve | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 6:` | Every declared skill dependency names another catalog entry. |
| Error check 7 — VERSION file valid semver | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 7:` | The VERSION file exists and parses as semver. |
| Error check 8 — VERSION never regresses | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 8:` | VERSION is at least the latest collection v-tag; a version regression fails the build (ratchet). |
| Error check 9 — catalog skill versions valid semver | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 9:` | Every catalog entry's version field parses as semver. |
| Error check 9b — catalog status closed enum | ci | hard-fail | pre-commit pr-ci | `scripts/validate.sh` · `# Error check 9b:` | Every catalog status is one of active, experimental or deprecated; typos fail loudly. |
| Warning check — orphan doc directories | ci | advisory | pre-commit pr-ci | `scripts/validate.sh` · `# Warning check: Orphan doc directories` | Flags per-skill doc directories with no matching catalog entry. |
| Warning check 3 — orphan template files | ci | advisory | pre-commit pr-ci | `scripts/validate.sh` · `# Warning check 3: Orphan template files` | Flags template files not referenced by any catalog entry, across the default dir and overrides. |
