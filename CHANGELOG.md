# Changelog

All notable changes to this collection will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [4.6.2] - 2026-05-15

### Fixed

- **`/CJ_improve-queue` no longer corrupts TODOS.md's end-of-file newline on
  every row append.** The append path captured the row block via command
  substitution (`$(build_row ...)`), which strips trailing newlines, then wrote
  it with `printf '%s'` (no newline) — so each `audit` / `evaluate` / `research`
  append left TODOS.md ending without a terminating `\n` (not POSIX-clean). All
  three modes funnel through one write path (`cmd_apply` → `atomic_append`); the
  fix re-adds exactly one trailing newline there (`printf '%s\n'`), so appended
  rows are separated by a single blank line and the file always ends with
  exactly one `\n`. Consecutive appends no longer drop or double the EOF
  newline. The earlier manual `printf '\n' >> TODOS.md` (commit 8c2ee8f) only
  patched one artifact; this fixes the source. Added a `scripts/test.sh`
  regression test (isolated temp git repo, novel + conflict fixtures) asserting
  the post-append TODOS.md ends with exactly one `\n` across two consecutive
  appends.

## [4.6.1] - 2026-05-15

### Removed

- **S000053 (F000023 phase 2): delete the deprecated `CJ_company-workflow` skill.** Completes F000023 retirement. The byte-mirror relationship was inverted in S000052 (v4.5.5); S000053 deletes the now-orphaned source. Total: 53 files in `deprecated/CJ_company-workflow/` gone (SKILL.md, WORKFLOW.md, bin/, templates/, reference/, philosophy/, examples/, fixtures/, company-artifact-manifests.json).
- **Catalog entry**: `CJ_company-workflow` removed from `skills-catalog.json`. The `templates_source` field handler in `scripts/skills-deploy` stays for future deprecated skills.
- **`scripts/test.sh` CJ_company-workflow blocks (~1042 lines)**: COMPANY_PATH / COMPANY_TPL var declarations, knowledge-helpers (T000006), AI_KNOWLEDGE_DIR resolution (T000004), Knowledge Loading / On-Demand Matching test blocks, deprecated SKILL.md content checks (D000006, D000007), deprecated tracker template gates, WORKFLOW.md subsection checks. All tested gone implementation details; surgical edits preserved CJ_personal-workflow halves of shared-scope blocks.
- **`scripts/test-deploy.sh` Tests 13–15 + 17–19 (subdir behaviors)**: deleted the CJ_company-workflow-specific subdirectory symlink tests. Test 16 (no-subdirs case for CJ_system-health) preserved as regression coverage.
- **`template-registry.json`**: `sets.CJ_company-workflow` entry removed.
- **`CLAUDE.md`**: "What this repo is" updated (2 custom skills now), "Skill routing" paragraph updated, "Work item templates" rewritten with `work-copilot/` as canonical, "Template naming" rewritten (no more byte-mirror language).
- **`README.md`**: CJ_company-workflow row removed from the Skills table.

### Preserved

- `deprecated/` top-level directory + `deprecated/README.md` kept (convention for future deprecated skills, even when empty of skills).
- `deprecated/work-items/` (F000007 historical work-item relocation) untouched.
- `scripts/copilot-deploy.py` and `work-copilot/` bundle untouched. Bundle continues to deploy byte-identical to before. Already-deployed bundles in target repos unaffected.

## [4.6.0] - 2026-05-15

### Added

- **`/CJ_goal_investigate` v0.1.0 (F000024 / S000049): defect-to-shipped-fix pipeline orchestrator.**
  Third sibling in the `CJ_goal_*` family, alongside `/CJ_goal_run` (user-stories) and
  `/CJ_goal_todo_fix` (TODOs). Takes a scaffolded defect work-item (legacy
  `work-items/defects/<domain>/D000NNN_<slug>/` layout in v1.0) and ships a deployed
  fix end-to-end via `/investigate` (Agent subagent, sentinel-wrapped JSON output) →
  RCA + test-plan artifact writes → `/CJ_qa-work-item` → `/ship` → `/land-and-deploy`.
  Iron-Law gate enforced automatically: no fixes ship without a populated root cause.
  Machine-readable `/investigate` handoff (`DEBUG_REPORT_BEGIN_JSON ... DEBUG_REPORT_END_JSON`)
  eliminates free-text parser brittleness. 9-state halt-on-red taxonomy with
  `next_action=` / `resume_cmd=` / `raw_output_path=` journal entries. 5-row
  idempotency resume table for mid-chain re-entry. `--dry-run` previews chain plan +
  write paths without mutation. Workbench-only; drain mode / family-drain lock /
  sunset criterion / freestanding defect convention all deferred to v1.1. Catalog
  entry status `experimental`. Routing rule added to `rules/skill-routing.md`.
  Files: `skills/CJ_goal_investigate/{SKILL.md, pipeline.md, scripts/test-*.sh}`,
  `skills-catalog.json` (+1 entry), `rules/skill-routing.md` (+1 rule),
  `work-items/features/ops/F000024_cj_goal_investigate/` (DESIGN, ROADMAP, TRACKER,
  S000049 child story with SPEC + DESIGN + TEST-SPEC + TRACKER).

## [4.5.5] - 2026-05-15

### Changed

- **S000052 (F000023 phase 1): invert the work-copilot/ byte-mirror.** `work-copilot/`
  is now the canonical source-of-truth for the Copilot consumer bundle.
  `scripts/validate.sh` Error check 10 collapses from ~190 lines of MIRROR_SPECS
  machinery (array + per-shape dispatch helpers + orphan reporter) into a single
  existence-check sweep. `EXPECTED_BUNDLE_FILES` grew from 10 entries to 61,
  covering every file the bundle is required to ship (17 templates, 1 WORKFLOW.md,
  7 reference, 3 philosophy, 14 examples, 8 fixtures, 1 manifest, plus the 10
  pre-existing F000015 prompts + domain templates). `validate.sh` size: 684 → 545.
- **`scripts/test.sh`: delete T000011 MIRROR_SPECS sync-check block.** The seven
  smoke tests (drift detection, orphan FAIL-vs-WARN policy, manifest schema parity)
  validated the byte-mirror machinery that S000052 removed; with no mirror there
  is no drift surface to test. The existence-check that replaces it is exercised
  directly by every `./scripts/validate.sh` CI run.

### Fixed

- **`scripts/test.sh` zzz-test-scaffold cleanup race.** The integration test that
  manually creates a `skills/zzz-test-scaffold/` fixture and adds it to the
  catalog only cleaned up via the EXIT trap, but `scripts/test-deploy.sh` runs
  earlier in the same script and reads the modified catalog. From a git worktree,
  `skills-deploy doctor` resolved the source to the main toplevel (per T000025)
  while the fixture lived in the worktree path, so Test 8 ("Doctor on healthy
  install") consistently failed with `WARN: zzz-test-scaffold — source directory
  missing in repo`. Now the fixture is removed inline once the manual-scaffold
  block completes; the EXIT trap remains as a fallback for unexpected exits.

### Preserved

- `deprecated/CJ_company-workflow/` stays on disk for this phase — it is now
  structurally orphaned (no script reads it for byte-mirror purposes) but
  remains intact until S000053 deletes it together with the catalog entry,
  CJ_company-workflow-specific test.sh assertions, `template-registry.json`
  entry, and `CLAUDE.md` / `README.md` references.
- `scripts/copilot-deploy.py`: unchanged. The bundle continues to deploy from
  `work-copilot/` byte-identical to before. Already-deployed Copilot bundles
  in target repos are unaffected.

## [4.5.3] - 2026-05-15

### Fixed

- **`/CJ_suggest --for-skill cj-goal` filter: three new heading-level gates (3c/3d/3e)** that catch rows `/CJ_goal_todo_fix` drain mode would halt on at preflight. The drain helper requires `(Pn, X)` suffix with `P != 1` and size `S|M`; rows under date-trigger H2 sections (e.g. `## Scheduled checkpoints`), rows with `YYYY-MM-DD —` heading prefix, and rows carrying terminal-marker literals (`WON'T FIX`, `SUPERSEDED`, `SHIPPED`, `RESOLVED`) all currently leak through and waste drain iterations on `halted_at_preflight`. Gates fire before body extraction (cheap heading-only checks) and emit `[CJ_suggest] excluded: ... reason=...` log lines to stderr matching the existing exclusion-log shape. Workbench TODOs unchanged (no false positives); portfolio-repo fallback-mode TODOs now correctly admit only drainable rows.

## [4.5.4] - 2026-05-15

### Changed

- **All remaining workbench subagent prompt templates wrapped in XML tags (closes TODOS row "Adopt XML-tag delimited subagent prompts from anthropic-docs").** Follow-on to v4.5.3 which did `/CJ_improve-queue` Step 3 only. This PR converts the remaining 5 dispatch templates:
  - `skills/CJ_personal-pipeline/pipeline.md` Step 3 (Phase 1 scaffold subagent), Step 5.3 (implement subagent), Step 7 (Phase 3 QA subagent) — three dispatches that drive the full personal-workflow pipeline.
  - `skills/CJ_qa-work-item/qa.md` Step 7 (E2E QA engineer subagent) — the leaf-node subagent that verifies E2E acceptance criteria.
  - `skills/CJ_goal_run/run.md` Step 3 (CJ_personal-pipeline subagent dispatch under --suppress-final-gate) — the top-level pipeline-runner dispatch.

  Each template now uses `<role>` / `<task>` / `<constraints>` / `<return-contract>` / `<inputs>` XML tags per Anthropic prompt-engineering guidance, so subagents parse mixed instructions + variable inputs unambiguously. No behavioral change to the contracts themselves — only the prompt-template structure. Closes the row that opened in v4.4.0 (F000022) and partially closed in v4.5.3.

## [4.5.3] - 2026-05-15

### Changed

- **5 SKILL.md descriptions shortened (closes TODOS row "Adopt concise discovery-focused descriptions from anthropic-docs").** `CJ_goal_run`, `CJ_goal_todo_fix`, `CJ_personal-pipeline`, `CJ_qa-work-item`, `CJ_implement-from-spec` frontmatter `description` fields now follow Anthropic skill-authoring best practices: 1-3 sentences leading with what+when, embedded version-rename history and flag mechanics moved to the SKILL.md body. Improves Claude's skill-selector discrimination across 100+ skills.
- **`/CJ_improve-queue` Step 3 subagent prompt template wrapped in XML tags (PARTIAL closure of TODOS row "Adopt XML-tag delimited subagent prompts from anthropic-docs").** `<role>`, `<task>`, `<constraints>`, `<return-contract>`, `<inputs>` sections replace plain-text `ROLE:` / `TASK:` / `CONSTRAINTS:` headers, per Anthropic prompt-engineering guidance. Remaining: wrap subagent prompts in `CJ_personal-pipeline/pipeline.md`, `CJ_qa-work-item/qa.md`, and `CJ_goal_run/run.md` — each load-bearing enough to warrant its own focused PR. Tracked as the residual half of the original TODOS row.

## [4.5.2] - 2026-05-15

### Fixed

- **`/CJ_improve-queue` allowlist subdomain matching (follow-on to v4.5.0).** `is_allowlisted()` in `scripts/improve_queue.sh` used exact-host comparison only, rejecting legitimate Anthropic surfaces like `code.claude.com`, `platform.claude.com`, `docs.claude.com`, `support.claude.com` — all of which are subdomains of the allowlisted `claude.com` host. Found by the Phase 3 research-mode killer test: WebSearch returned 6 valid `*.claude.com` results, all blocked. Fix: add suffix match (`*.h`) alongside exact match in the allowlist loop. Typosquat protection holds (`evilclaude.com` still rejected because the literal `.` is required for suffix match). Verified with both positive (`code.claude.com` accepted) and negative (`evilclaude.com` rejected) smoke tests.

### Added (via Phase 3 research mode)

- **Draft TODO: Adopt XML-tag delimited subagent prompts (novel, conf=7).** Anthropic prompt-engineering docs recommend wrapping prompt sections in named XML tags for unambiguous parsing. Workbench currently uses plain-text `ROLE:`/`TASK:`/`CONSTRAINTS:` section headers in subagent dispatch templates (CJ_personal-pipeline, CJ_improve-queue, CJ_qa-work-item, CJ_goal_run). Row landed in TODOS.md with `<!--impr-draft-->` marker; remove the marker to promote.
- **Draft TODO: Adopt concise discovery-focused descriptions (conflict, conf=8).** Anthropic skill-authoring best practices say the SKILL.md description should be a 1-2 sentence what+when discovery handle. Workbench descriptions for CJ_goal_run, CJ_goal_todo_fix, CJ_personal-pipeline, CJ_qa-work-item, and CJ_implement-from-spec embed version-rename history, flag mechanics, and changelog detail — too long for Claude's skill-selector to discriminate cleanly across 100+ skills. Row landed in TODOS.md with `<!--impr-draft-->` marker; remove the marker to promote.

## [4.5.1] - 2026-05-15

### Fixed

- **`/CJ_improve-queue` SKILL.md frontmatter sync (follow-on to v4.5.0).** Frontmatter `description` and `version` fields were stale ("Phase 1 MVP / 0.1.0") even though Phase 2 + Phase 3 sections shipped in the body. The routing layer reads the SKILL.md frontmatter description for skill discovery — without this fix, `/CJ_improve-queue` would not surface for "audit my skills" or "research <topic>" routing phrases. Also adds `WebSearch` to `allowed-tools` so the Phase 3 research flow's WebSearch invocation passes the tool-restriction gate.

## [4.5.0] - 2026-05-15

### Added

- **`/CJ_improve-queue audit` Phase 2 (S000050).** Offline repo self-scan, no network. Two deterministic checks per skill: (1) **stale-skill** — no entry in `~/.gstack/analytics/skill-usage.jsonl` within last 30 days (confidence 6, REVIEW-flagged because analytics naming drift can produce false positives); (2) **missing-frontmatter** — `SKILL.md` lacks `version:` or `allowed-tools:` (confidence 9, deterministic). Each finding goes through the same `cmd_apply` path the evaluate flow uses, with synthetic `repo-audit://<check>/<target>` URLs that sidestep the allowlist gate and produce stable signatures for idempotency. Re-running audit on an unchanged repo is a NO-OP.

- **`/CJ_improve-queue research <topic>` Phase 3 (S000051).** Orchestrator-driven flow (no new bash code) composing Phase 1 primitives. Three steps: (R1) privacy AskUserQuestion gate before sending topic to WebSearch provider (matches `/office-hours` Phase 2.75 convention); (R2) WebSearch capped at 3 results, filtered to allowlist hosts only (`--allow-untrusted-source` NOT respected — trust boundary stays tight); (R3) per-result loop calling existing `evaluate-prepare` + Agent dispatch + `apply`. Aggregates into a single summary line.

### Tested

- **Killer test on 3 real Anthropic docs URLs**: `claude-code/skills` → match (SKILL.md authoring conventions already adopted), `claude-code/hooks-guide` → reject (harness/settings layer, orthogonal to skills), `claude-code/sub-agents` → match (fresh-context dispatch already in CJ_personal-pipeline + CJ_goal_run). No false-positive rows appended; all 3 verdicts correctly classified. Confirms end-to-end: HANDOFF emit, subagent dispatch, WebFetch, JSON verdict parse, apply gates, allowlist all working.

## [4.4.3] - 2026-05-15

### Added

- **Origin URL pinning for the skills-update-check upgrade path (T000031).** `skills-deploy install` now captures `git remote get-url origin` of the source repo at install time and writes it to `manifest.upstream_url` in `~/.claude/.skills-templates.json`. `skills-update-check` reads the pinned URL and, when set, compares it against the source repo's current `origin` URL. On mismatch, the upgrade banner is suppressed and a warning is emitted to stderr telling the user to re-run `skills-deploy install` from a trusted clone to re-pin. Hardening: closes the manifest-tampering window where a writer of `~/.claude/.skills-templates.json` could redirect `git -C "$source" pull --ff-only origin main` to attacker-controlled code. Backward-compatible: pre-T000031 manifests (no `upstream_url` field) skip the check and behave exactly as before. Covered by 4 new tests in `scripts/test-deploy.sh` (U29-U32). Closes TODOS:58.

## [4.4.2] - 2026-05-15

### Fixed

- **`/CJ_suggest` skips `<!--impr-draft-->` headings (S000049, follow-on to F000022).** One-line `awk` filter extension in `suggest.sh` active-band scan (both `CJ_personal-workflow` and domain-grouped TODOS conventions). Without this, draft rows emitted by `/CJ_improve-queue evaluate` rank in `/CJ_suggest`'s top-N alongside real backlog — defeating the invisible-marker promotion gate from F000022. Mirrors the existing strikethrough skip pattern. Verified with a fixture TODOS containing a draft row + two real rows: draft is filtered, real rows rank.

## [4.4.1] - 2026-05-15

### Changed

- **F000016 deferred decisions captured in tracker (T000030).** Added a `## Deferred decisions` section to `work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/F000016_TRACKER.md` recording the 5 items deferred during the 2026-05-13 autoplan review (budget gate, `--no-auto-iterate` escape hatch, `--run-id` passthrough, `--work-item-dir` migration guide, dependency-aware batching). Closes TODOS:114. The feature itself (S000036 / S000037) is still active; this is a doc-only capture so future reviewers don't re-litigate the same items.

## [4.4.0] - 2026-05-15

### Added

- **New `/CJ_improve-queue` skill (F000022 / S000048).** Takes a URL to a Claude-best-practice page, dispatches an independent reviewer subagent to compare the article's pattern against the workbench's existing skills, and appends a draft improvement-TODO row to `TODOS.md` for the existing `/CJ_suggest → /CJ_goal_todo_fix → /ship → /land-and-deploy` pipeline to consume. Composes with `/loop /CJ_goal_todo_fix` so the more best-practice URLs you feed it, the more your skill collection auto-aligns to evolving Claude patterns through the same shipping pipeline you already use.
- **HANDOFF envelope dispatch protocol** mirroring `/CJ_goal_todo_fix`'s proven pattern: bash envelope emits `CJ_IMPROVE_QUEUE_HANDOFF_BEGIN/END` on stdout with the canonical URL + in-scope skill files, orchestrator drives the `Agent` dispatch and pipes the verdict back to `apply` via stdin. No prose-only re-invocation contracts; no `.claude/tmp/` writes.
- **WebFetch source-domain allowlist** (`docs.anthropic.com`, `anthropic.com`, `claude.com`, `github.com/anthropics/*`) with `--allow-untrusted-source` override flag. Off-allowlist URLs emit a stderr warning and tag the row body as untrusted. Closes the attacker-controlled-URL trust boundary into TODOS.md sensitive-surface preflight.
- **HTML-comment-wrapped source quotes** in generated rows (`<!-- source-quote: "..." -->`). Renders verbatim attacker content as a markdown comment so `/CJ_goal_todo_fix`'s sensitive-surface regex (`goal.sh:289`) cannot false-match on quoted tokens. The operator-visible `**Affected skills:**` and `**Suggested change:**` fields remain in the subagent's reasoning trust boundary.
- **Inline `<!--impr-draft-->` draft marker in heading** replaces the original prefix-string convention. Invisible in rendered markdown, opt-out by single token removal. Avoids the `DRAFT—` vs `DRAFT — ` vs `Draft —` prefix-typo footgun. `/CJ_suggest` filters draft-marked headings via a one-line `awk` extension (follow-on S000049).
- **`mkdir`-based write-lock** at `/tmp/cj-improve-queue-lock/` (no `flock` dependency; macOS doesn't ship GNU flock by default — mirrors `/CJ_goal_todo_fix`'s lockfile pattern). Lock scope: only the TODOS.md write step (sub-second), not the entire fetch+reason flow — parallel `evaluate <urlA> + evaluate <urlB>` run network/reasoning concurrently.
- **Idempotent per source** via `sha256(canonical_url + pattern_name)[:16]` signature stored in trailing HTML comment. URL canonicalization strips `utm_*`, `source`, `ref`, `fbclid`, `gclid`, `mc_*` query params, fragments, default ports, www-prefix; lowercase host + uppercase percent-encoding.
- **Test fixtures** at `tests/fixtures/CJ_improve-queue/`: `sample-verdict-novel.json`, `sample-verdict-conflict.json`, `sample-verdict-fetch-failed.json`, `sample-verdict-malformed.json`, and `sample-fetch-anthropic-skills-page.html` — enables deterministic CI verification of the apply step without live WebFetch.

### Changed

- **`skills-catalog.json`**: new `CJ_improve-queue` entry (version 0.1.0, status `experimental`, depends `CJ_suggest`).
- **`rules/skill-routing.md`**: new routing rules for "evaluate this URL", "is this a good Claude pattern", "should we adopt this".

## [4.3.0] - 2026-05-15

### Added

- **`--quiet` schedule-friendly flag in `/CJ_goal_todo_fix` (F000021 / S000047).** When set, the script suppresses the Phase 3 summary AUQ + start-of-run banner; instead, `[scheduled-drain-summary]` lines are written to the new session log at `~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl`. Designed for cron / `/schedule` consumers where there's no human at the keyboard to answer AUQs. Composes with `--max-drain N` and single-TODO mode (`T000NNN` or fragment). The `CJ_GOAL_DRAIN_HANDOFF` block now includes a `QUIET=<0|1>` line so the orchestrator that drives the per-TODO chain can suppress its own Phase 3 summary AUQ when set. **Critical constraint: `--quiet` does NOT suppress /ship Gate #2** — drained PRs queue for human review at the operator's cadence (per F000021 autonomy ceiling: "schedule-friendly = PRs queue for review at cadence; NOT auto-merge").
- **New `scheduled_run` field in `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`.** Always present (`true` when `--quiet`, `false` otherwise) so retro tooling can distinguish cron-driven drain from operator-driven drain via `jq 'select(.scheduled_run == true)'` without conditionals on field presence.
- **New session log at `~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl`.** Append-only JSONL written when `--quiet` is set. Each line: `{ts, run_id, marker:"scheduled-drain-summary", summary}`. Replaces the suppressed Phase 3 AUQ for post-cron auditability.
- **Cron-pattern documentation** in workbench `CLAUDE.md` (new "Schedule-friendly drain" section) + `skills/CJ_goal_todo_fix/SKILL.md`. Example: `/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am`. Doc-only — no schema-binding to the upstream `/schedule` skill.

### Changed

- `skills/CJ_goal_todo_fix/SKILL.md` bumped to v2.2.0 (additive: `--quiet` flag, `scheduled_run` telemetry field, session log path, cron-pattern example, expanded Notes). Frontmatter description updated to mention `--quiet`.
- `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`: added `--quiet` to the flag-aware arg loop; new `write_scheduled_drain_summary()` helper; `write_telemetry()` now emits `scheduled_run` (true/false); the two `nothing_to_drain` exit paths route through the helper under `--quiet` instead of printing to stdout; `CJ_GOAL_DRAIN_HANDOFF` block gains a `QUIET=...` line. Net script delta: ~50 LOC additive.

### Migration notes

- **For operators:** no migration required. Existing `/CJ_goal_todo_fix` invocations (with or without `--max-drain N` / single-TODO arg / `--dry-run`) are unchanged. Pass `--quiet` to opt into schedule-friendly behavior.
- **For cron / `/schedule` consumers:** the documented pattern is `/schedule create "/CJ_goal_todo_fix --max-drain N --quiet" <cadence>`. Cron output stays empty when there's nothing to do; `[scheduled-drain-summary]` entries in the session log preserve the fact. Operator reviews PRs via `gh pr list --author @me --state open` at their own cadence.
- **For downstream consumers of `CJ_goal_todo_fix.jsonl`:** the new `scheduled_run` field is additive (always present from v4.3.0+; absent on pre-v4.3.0 lines). Filters that don't read it keep working; new tooling can `jq 'select(.scheduled_run == true)'` to isolate cron-driven runs.
- **For `/CJ_personal-pipeline` orchestrators that drive the per-TODO chain:** read the new `QUIET=...` line in the `CJ_GOAL_DRAIN_HANDOFF` block. When `QUIET=1`, suppress the Phase 3 summary AUQ at the orchestrator layer (write to the per-tracker journal entry instead). The orchestrator-side change is opt-in: existing orchestrators that don't read the flag still work — they just emit the AUQ as before, which produces a noisy cron line but no functional regression.

## [4.2.0] - 2026-05-15

### Added

- **Native drain mode in `/CJ_goal_todo_fix` (F000021 / S000046).** Default invocation (no positional arg) now enumerates easy-fix TODOs via `/CJ_suggest --for-skill cj-goal` and drains up to `--max-drain N` (default 10) end-to-end through `/CJ_personal-pipeline` + `/ship` + `/land-and-deploy`. No `/loop` wrapper needed; cron- and `/schedule`-eligible. Single-TODO mode (T-ID or fragment arg) preserved unchanged; `--dry-run` works in both modes.
- **`--max-drain N` flag** on `/CJ_goal_todo_fix` (default 10; `--max-drain=N` form also accepted; `N=0` errors with hint to use `--dry-run` for preview).
- **`scripts/drain-one-todo.sh` shared helper** under `skills/CJ_goal_todo_fix/scripts/`. Per-TODO inner loop with lockfile acquire/release, `todo_fix.sh` delegation, and `CJ_GOAL_HANDOFF` emission. Called by BOTH `/CJ_goal_todo_fix` Phase 2 (drain mode) AND `/CJ_goal_run` Phase 5 (post-deploy TODO drain) — one source of truth for the per-TODO chain. Subcommands: `acquire`, `release`, `dispatch`. Shellcheck-clean.
- **Shared cross-skill lockfile** at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`. Per-day TTL (self-cleaning; no GC). Prevents `/CJ_goal_run` Phase 5 and `/CJ_goal_todo_fix` Phase 2 from double-scaffolding the same heading when run concurrently. Loser-of-race emits `STATUS=lock_skip` and continues with the next eligible TODO.
- **New `end_state` values** in `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`: `nothing_to_drain` (Phase 1 returns empty — cron-friendly success, exit 0), `drain_handoff_pending` (Phase 1 enumeration complete; orchestrator drives Phase 2). Plus orchestrator-emitted `drained_complete` / `drained_partial` matching the schema added in v4.1.0 for `/CJ_goal_run`.
- **Telemetry fallback-read of legacy `CJ_goal.jsonl`** (pre-rename file). Sunset-trip-wire consumers MUST merge both paths via the new `telemetry_invocation_count` helper in `scripts/todo_fix.sh` so the v4.0.0 rename window doesn't reset the trip-wire counter. Current-run writes continue to go only to the new path.

### Changed

- `skills/CJ_goal_todo_fix/SKILL.md` bumped to v2.1.0 (additive: drain mode flow, `--max-drain` flag, lockfile mechanics, new end_state classes, telemetry fallback-read pattern). `skills-catalog.json` `CJ_goal_todo_fix` entry bumped 2.0.0 → 2.1.0; `files` list adds `scripts/drain-one-todo.sh`; `tools` list adds `shasum`.
- `skills/CJ_goal_todo_fix/scripts/todo_fix.sh`: replaced positional-only arg parsing with a flag-aware loop; added Phase 1/3 drain block emitting `CJ_GOAL_DRAIN_HANDOFF` for orchestrator consumption; `halt()` treats `nothing_to_drain` as exit 0 (cron success); added `telemetry_invocation_count()` for merged-file reads.
- `skills/CJ_goal_run/run.md` Step 5.5.4: per-TODO inner-loop comment block refactored to describe the new helper invocation contract (`drain-one-todo.sh dispatch ... + release`). No behavioral change for `/CJ_goal_run` orchestrators — the Skill-tool chain still runs at the orchestrator layer; the helper owns lockfile + preflight delegation.

### Migration notes

- **For operators:** `/CJ_goal_todo_fix` (no args) now enters drain mode. Previously this would `/CJ_suggest` top-1 then fix that one TODO. Behavior diff: instead of one PR per invocation, expect up to 10 (default cap). To preserve the v2.0.0 single-shot habit pattern, pass `--max-drain 1`. Single-TODO modes (`T000NNN` or fragment) are unchanged.
- **For `/loop /CJ_goal_todo_fix` users:** the wrapper is now redundant for backlog drain — native drain mode replaces it. Existing `/loop` invocations still work (each iteration drains up to N, then exits cleanly with one of `drained_complete` / `drained_partial` / `nothing_to_drain` — all loop-continue end_states).
- **For cron / `/schedule` consumers:** `nothing_to_drain` exits 0 so scheduled drains don't alert on empty backlogs. Distinguish via the telemetry `end_state` field.
- **For downstream consumers of `CJ_goal_todo_fix.jsonl`:** the JSON line schema is unchanged for per-TODO writes. New end_state strings (`nothing_to_drain`, `drain_handoff_pending`) are additive; filters that gated on `end_state == "green"` should be widened to `end_state in ["green", "drained_complete", "drained_partial", "nothing_to_drain"]` for "successful run" counts.

### Follow-up work (F000021 family — remaining)

- **S000047** — `--quiet` schedule-friendly flag (suppresses summary output for cron consumers).

## [4.1.0] - 2026-05-15

### Added

- **Phase 5 TODO drain in `/CJ_goal_run` (F000021 / S000045).** Post-`/land-and-deploy`, the orchestrator diffs `TODOS.md` additions in the merged PR (`git diff <PR-base>..HEAD -- TODOS.md`), counts new `^### ` headings → `new_todos_count`. If 0: emit `end_state: green` silently. If >0: AUQ "Drain N new TODOs?" with cap=5 recommendation (yes if N ≤ 5, no otherwise). On yes: per-TODO loop invoking `/CJ_goal_todo_fix` as a subroutine; halt-on-red emits `drained_partial`, all green emits `drained_complete`. Closes the new-debt loop in the same pipeline invocation; the operator no longer needs to manually invoke `/loop /CJ_goal_todo_fix` after every feature ships.
- **`--no-drain` escape-hatch flag** on `/CJ_goal_run`. Strips at any arg position, bypasses Phase 5 entirely (no diff, no AUQ, no loop), records `no_drain_flag: true` in telemetry. Use when this run's new TODOs need different reviewers / timing / deferral.
- **New `end_state` values** in `~/.gstack/analytics/CJ_goal_run.jsonl`: `drained_complete`, `drained_partial`. Both exit 0 (the feature shipped green; Phase 5 is post-deploy forward-iteration, not a halt condition). Sunset trip-wire excludes both — they are Phase 5 outcomes, not orchestration brittleness.
- **Extended telemetry schema**: new fields `new_todos_count` (int), `drained_count` (int), `drained_pr_urls` (array of strings), `no_drain_flag` (bool). Backward-compatible — `jq` filters that select only `end_state` / `multi_story_mode` keep working; new fields are additive.

### Changed

- `skills/CJ_goal_run/SKILL.md` bumped to v1.1.0 (additive: Phase 5 docs, `--no-drain` flag, extended error table with `drained_*` halt classes). `skills-catalog.json` `CJ_goal_run` entry bumped 1.0.0 → 1.1.0.
- `skills/CJ_goal_run/run.md`: Step 1 gains `--no-drain` pre-pass + extended state-file schema; Step 5 Branch (a) flows into new Step 5.5 (Phase 5) before Step 6; Step 6.1 telemetry write emits the new schema fields via jq + bare-shell fallback; Step 6.2 summary prints Phase 5 outcomes; Step 7.1 exit code maps `drained_complete` / `drained_partial` to 0.

### Migration notes

- **For operators:** no migration required. Existing `/CJ_goal_run <design-doc>` invocations are unchanged on the happy path (the new Phase 5 fires only on green deploys, and silently no-ops when 0 new TODOs are added). On runs that add TODOs, an AUQ surfaces — answer "no" to preserve pre-v4.1.0 behavior, or pass `--no-drain` to skip Phase 5 entirely.
- **For sunset trip-wire / retro tooling:** `drained_complete` and `drained_partial` are normal exit values for green runs. Filters that gated on `end_state == "green"` should be widened to `end_state in ["green", "drained_complete", "drained_partial"]` for "successful run" counts. The brittleness trip-wire in Step 7 is unchanged (the regex never matched the new classes).
- **For downstream consumers of `CJ_goal_run.jsonl`:** the JSON line is forward-compatible. Older parsers that select specific keys keep working; the new fields are additive.

### Follow-up work (F000021 family — remaining)

- **S000046** — native drain semantics + drain-one-todo.sh script (extracts the Phase 5 inner loop into a shared helper so `/CJ_goal_run` Phase 5 and `/CJ_goal_todo_fix` native-drain mode share a single code path).
- **S000047** — `--quiet` schedule-friendly flag.

## [4.0.0] - 2026-05-15

### Changed (BREAKING — slash-command surface rename)

- **Batched rename of /CJ_run + /CJ_goal into the `_goal_*` family (F000021 / S000044).**
  - `git mv skills/CJ_run → skills/CJ_goal_run` (unified pipeline entry point).
  - `git mv skills/CJ_goal → skills/CJ_goal_todo_fix` (auto-resolve a TODO into a shipped PR).
  - `git mv skills/CJ_goal_todo_fix/scripts/goal.sh → todo_fix.sh` (cosmetic; matches the new skill name).
  - `skills-catalog.json`: two existing entries renamed (`CJ_run` → `CJ_goal_run` v1.0.0; `CJ_goal` → `CJ_goal_todo_fix` v2.0.0; both `status: active`).
  - `rules/skill-routing.md`, workbench `CLAUDE.md`, and supporting skill descriptions (`CJ_personal-pipeline`, `CJ_suggest`, template tracker) updated to reference the new names.
  - Telemetry paths migrated: writes go to `~/.gstack/analytics/CJ_goal_run.jsonl` and `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`. The `/CJ_goal_run` sunset trip-wire fallback-reads the legacy `~/.gstack/analytics/CJ_run.jsonl` during the v4.x grace window so historical invocations are still counted; reads of the legacy `CJ_goal.jsonl` are not currently wired into a sunset path (the canonical `/CJ_goal_todo_fix` skill doesn't yet implement a sunset trip-wire — file is preserved on disk for forward use).

### Added

- **Two new deprecated-alias skills (`skills/CJ_run/SKILL.md`, `skills/CJ_goal/SKILL.md`).** Thin SKILL.md wrappers (no scripts, no run.md) that print a one-line deprecation banner ("renamed to /CJ_goal_run; will be removed in v5.0.0" / "renamed to /CJ_goal_todo_fix; ..."), then delegate to the canonical skill via the Skill tool. Catalog entries marked `status: deprecated`. Soft-cutover so operator muscle memory survives the rename window.

### Migration notes

- **For operators:** `/CJ_run <design-doc-path>` and `/CJ_goal <T-ID>` continue to work during v4.x with the deprecation banner. Update muscle memory at your pace; the aliases are removed in v5.0.0.
- **For downstream consumers (e.g., jcl2018-portfolio):** pull this workbench, run `./scripts/skills-deploy install`. The catalog now exposes 4 entries in this family (2 canonical + 2 deprecated aliases); `skills-deploy doctor` reports the alias entries as INFO, not WARN. No code-level migration required during v4.x.
- **For CI / scripted invocations:** prefer the canonical names (`/CJ_goal_run`, `/CJ_goal_todo_fix`) starting today. v5.0.0 will remove the alias dirs and catalog entries.

### Why a major bump for a rename

The slash-command surface is a public contract. Renaming it is breaking-by-name even when semantics are preserved by aliases, so semver compliance requires a major bump (3.x → 4.x). No semantic changes ship in this version; the only operator-visible delta is the new canonical names.

### Follow-up work (F000021 family)

- **S000045** — Phase 5 drain in /CJ_goal_run (forward-iterate /loop /CJ_goal_todo_fix after Phase 4 completes).
- **S000046** — native drain semantics + drain-one-todo.sh script.
- **S000047** — `--quiet` schedule-friendly flag.

## [3.6.5] - 2026-05-15

### Changed

- **`/CJ_goal` preflight v1.2 polish — Gate 4 + Gate 5 regex extensions (S000044).** Both regex gaps surfaced by `/loop /CJ_goal` iter 3 on 2026-05-15 (logged as TODOs in v3.6.4) are closed in this PR.
  - **Gate 4 (sensitive-surface body scan)** at `goal.sh:303-304` now matches `skills/[^/]+/.+\.md` in addition to `skills/[^/]+/scripts/`. Catches markdown skill definition files (`SKILL.md`, `pipeline.md`, `scaffold.md`, `implement.md`, `qa.md`, etc.) which are just as load-bearing as scripts. Fixes the gap where T000031 (targeting `/CJ_personal-pipeline` — entirely markdown, no `scripts/` subdir) didn't trip the gate.
  - **Gate 5 (design-needed keyword scan)** at `goal.sh:319-322` now matches `redesign|re-?do|re-?ground|rewrite|rescope` and the literal `/office-hours` command reference, in addition to the original `needs design|figure out|investigate|spike|unclear|need to decide|TBD`. Catches "this needs design rework, not implementation" signals like T000031's body step (1): "`/office-hours` from a new worktree with the closed-PR design as starting context." `re-?do` matches `redo`/`re-do` only, not `rename`/`refactor` (preserves scope to genuine re-design signals).

### Verification

Both extensions tested live against TODOS.md before commit:
- `bash skills/CJ_goal/scripts/goal.sh "Re-do brief-mode" --dry-run` → halts at Gate 5 with `needs design (matched: /office-hours)` (was: dispatched to scaffold).
- `bash skills/CJ_goal/scripts/goal.sh --dry-run` (no args, picks the v3.6.4 sensitive-surface gap row) → halts at Gate 4 with `TODO touches sensitive surface(s): skills/CJ_personal-pipeline/pipeline.md skills/*/SKILL.md...` (was: dispatched to scaffold).

`./scripts/test.sh`: 0 failures, RESULT: PASS. Regex extensions are pure additions — no regression risk for previously-eligible rows.

### Notes

- `skills-catalog.json` bumps `CJ_goal` 1.1.0 → 1.2.0 (semantic — preflight rules expanded; downstream `/loop /CJ_goal` consumers should re-deploy via `./scripts/skills-deploy install`).
- TODOS:156 + :158 (the two gap rows logged in v3.6.4 #121) marked DONE in this PR.
- F000020 v1.1 polish bundle's last child (D000020 — skip-list reset RCA + instrumentation defect) still pending; expected as v3.6.6 once the instrumentation reproduces the truncation event.

## [3.6.4] - 2026-05-15

### Added

- **Two new TODOS rows logging /CJ_goal preflight gaps** surfaced by `/loop /CJ_goal` iter 3 after the v3.6.x bundle + hygiene cleanup landed:
  - **Design-needed regex gap** — `goal.sh` line ~300 catches `needs design`, `investigate`, `spike`, `unclear`, `need to decide`, `TBD` but misses `/office-hours from`, `Re-do`, `re-ground`. T000031 (P2/M, body says step 1 is `/office-hours from a new worktree`) auto-dispatched without halting at preflight. Fix sketch: extend regex.
  - **Sensitive-surface markdown gap** — regex at `goal.sh:289` catches `skills/*/scripts/` but not `skills/*/*.md`. Editing `pipeline.md` or `SKILL.md` is just as load-bearing as editing scripts. Fix sketch: add `skills/[^/]+/(SKILL|pipeline)\.md|skills/[^/]+/[a-z-]+\.md`.
- Both rows tagged P3/S; suggested as a paired `/CJ_goal preflight v1.2 polish` PR when next prioritized. Reference annotations link them to this iteration's findings so future operators have the full diagnostic chain.

### Notes

- Pure docs PR — no code changes. The two gaps are observed-but-not-yet-fixed; this PR captures them as TODOS so they don't get lost. Demonstrates the new TODOS hygiene conventions from v3.6.3 in practice: when /loop surfaces a real finding, log it as a TODO with full context (what was picked, what tripped, why preflight didn't fire, fix sketch), then stop the loop and ship the discovery.

## [3.6.3] - 2026-05-15

### Added

- **`## TODOS.md hygiene conventions` section in CLAUDE.md.** Documents two known auto-marking gaps that operators must handle by hand: (1) partial closes need explicit `~~strikethrough~~ PARTIAL — sub-item (X) closed by ...` annotations because `/ship` Step 14's auto-marker conservatively skips them; (2) multi-PR bundles via `/CJ_run` Branch (b) need a small post-bundle `chore: TODOS.md post-bundle cleanup` PR because `/ship` only sees each child's narrow diff and can't auto-mark cross-PR closures. Both gaps were diagnosed via `/investigate` after observing `/loop /CJ_goal` repeatedly picking already-addressed rows in this session — the iron law (no fix without root cause) revealed there's no `/CJ_goal` bug, just a documentation + convention gap.

### Changed

- **TODOS:108 marked PARTIAL.** `Pre-ship vs post-ship AC categorization for /CJ_qa-work-item` — sub-item (b) closed by T000027 (v3.5.4, PR #114): qa.md Step 4 filters post-ship E2E rows out of subagent dispatch with `[qa-e2e-deferred]` journal entry. Remaining sub-items (a) `phase: post-ship` TEST-SPEC field, (c) Phase 3 `Post-ship ACs verified` gate, (d) `/CJ_personal-workflow check --update` post-merge inference are deferred until the next work-item with structurally post-ship ACs hits the QA flow.

### Notes

- Pure docs PR — no code changes. Unblocks `/loop /CJ_goal` iterations that were burning cycles re-picking TODOS:108 (the `IDEMPOTENT_SKIP=1` route would dispatch a no-op chain). Future operators following the new conventions in CLAUDE.md should not recreate the gap.

## [3.6.2] - 2026-05-15

### Changed

- **TODOS.md post-bundle cleanup for F000020.** Marked two rows DONE with strikethrough + close-by annotations: the `/CJ_suggest` top-5 limit row (closed by S000042 / v3.6.0 / PR #117 — covers both queue depth and the "no /CJ_suggest pre-filter against preflight" sub-item embedded in the body) and the `/CJ_goal` sensitive-surface auto-decline row (closed by S000043 / v3.6.1 / PR #118 — halt-class semantic rename + continue-set add). The skip-list reset row stays open (D000020 / WI-C — RCA-driven, ships as v3.6.3 once the instrumentation reproduces the truncation event in a real /loop session).

### Notes

- Pure docs change, surfaced when a `/loop /CJ_goal` smoke run picked TODOS:167 first iteration — the row was already addressed by v3.6.0 but `/CJ_suggest`'s ranker still saw it as active (no strikethrough). Marking the rows here unblocks future `/loop /CJ_goal` drains in the workbench so they don't burn iterations re-confirming already-shipped work.

## [3.6.1] - 2026-05-15

### Changed

- **`/CJ_goal` halt-class semantic rename: `halted_at_sensitive_surface_user_declined` → `halted_at_sensitive_surface_auto_declined` (S000043, F000020 polish bundle WI-B).** `goal.sh:296` (now line 310) emits the renamed end_state at the bash auto-default site. The `halt()` case ladder adds it to the **continue** branch (mirrors `halted_at_preflight` skip-list-and-exit-2 mechanic). Under bash there is no AUQ tool — the gate auto-defaults regardless of whether a human is present, so the prior `_user_declined` name was a misnomer and the STOP halt-class lied: under `/loop /CJ_goal` no human declined; the script just couldn't ask.
- **`/loop /CJ_goal` now continues past sensitive-surface rows instead of halting.** Defense-in-depth alignment for v3.6.0's queue-layer pre-filter: even on bypass paths (interactive `/CJ_goal "fragment"` from inside /loop, regex update drift) where a sensitive-surface row reaches the gate, the loop defers the row to the skip-list and iterates. The gate's purpose (human review before sensitive change ships) is preserved — the next interactive `/CJ_goal` invocation re-surfaces the row and the human can choose then.
- **`halted_at_sensitive_surface_user_declined` reserved for future interactive AUQ.** Halt-class table keeps the slot with a "(reserved for future interactive AUQ; not emitted in v1.1)" annotation. STOP loop behavior preserved for when an orchestrator-layer AUQ ships and a real human can decline. Contract change for telemetry consumers grepping for `_user_declined`: 0 events from v3.6.1 onwards (script no longer emits it). Update queries to grep both names if you need the union.

### Notes

- Second child PR of the F000020 v1.1 polish bundle. WI-A shipped as v3.6.0 (queue-layer pre-filter); WI-C (skip-list reset RCA + instrumentation, defect type) follows as v3.6.2.
- /autoplan skipped per user choice (workbench polish, design doc comprehensive). Pipeline subagent: 3 files modified, smoke + validate.sh PASS, 1 mechanical + 2 user-challenge-approved decisions logged.
- `skills-catalog.json` bumps `CJ_goal` 1.0.0 → 1.1.0 reflecting the semantic rename.

## [3.6.0] - 2026-05-15

### Added

- **`/CJ_suggest --for-skill cj-goal` flag (S000042, F000020 polish bundle WI-A).** New flag teaches `/CJ_suggest` to apply `/CJ_goal`'s preflight predicates at ranking time — excludes rows that match priority P1, size L|XL, sensitive-surface regex (`skills-catalog.json | manifest | validate.sh | skills/*/scripts/ | git-hooks | templates/CJ_personal-workflow/`), or design-needed keyword. Rows /CJ_goal would reject 100% of the time never enter the candidate window, so `/loop /CJ_goal` doesn't waste cycles scaffolding-to-bail. Predicates mirror `goal.sh` gates 3-5 verbatim — drift between the two would defeat the purpose; if you change one, change the other.
- **`/CJ_suggest --limit N` flag (S000042).** Extends the top-N output cap (default still 5 for un-flagged callers — no behavior change for interactive `/suggest` users). Lets downstream consumers like `/CJ_goal` request a deeper queue. Per-row `[CJ_suggest] excluded:` stderr log for excluded rows aids debugging.
- **`/CJ_goal` no-args path now invokes `/CJ_suggest --for-skill cj-goal --limit 15`.** One-line update at `goal.sh:186`. Defense-in-depth: /CJ_goal's own preflight (gates 1-5) still runs after this — the pre-filter is an optimization, not a replacement. /loop /CJ_goal's "grind through the backlog" use case becomes structurally coherent: legitimate skip-list churn no longer starves the queue against the prior top-5 cap, and sensitive-surface rows defer to the next interactive `/CJ_goal` invocation rather than halting the loop.

### Notes

- First child PR of the F000020 v1.1 polish bundle (3 work-items: WI-A here, WI-B halt-class semantic rename to ship as v3.6.1, WI-C skip-list reset RCA + instrumentation as v3.6.2 defect). Bundle scope + rationale documented in `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-125052.md`.
- /autoplan was skipped per user choice (workbench polish, design doc already comprehensive). Pre-landing review condensed to inline structural check; impl + QA via /CJ_personal-pipeline subagent (9/9 smoke tests green, including AC#3 invocation verify; unflagged `/CJ_suggest` regression preserved byte-identical).
- `skills-catalog.json` bumps `CJ_suggest` 1.0.0 → 1.1.0 reflecting the additive flag surface.

## [3.5.6] - 2026-05-14

### Added

- **CI-enforced workbench-coupling boundary at `pipeline.md:528` (T000029, Approach F+I).** `scripts/validate.sh` gains a new "Error check 12: pipeline.md Step 6 guard present" that greps `skills/CJ_personal-pipeline/pipeline.md` for the literal token `[ -x ./scripts/validate.sh ]`. If a future skill-author edits Step 6 and accidentally removes the guard, CI fails with a pointer back to T000028 / Approach D — preventing silent regression of the downstream `/CJ_goal` portability fix. The pipeline.md prose is unchanged; the executable invariant in `validate.sh` is now the contract.

### Changed

- **`TODOS.md`** — retired both v2 follow-up entries logged in PR #115 (Approach B handoff, Approach E ship-validate-subset). After closer inspection of `scripts/validate.sh` coverage (11 workbench-wide invariants — catalog, copilot-mirror, work-copilot bundle, manifest, VERSION sanity, rules deploy) vs `skills/CJ_personal-workflow/check.md` (per-work-item structural via templates+manifest), neither approach delivers meaningful improvement over v1 (T000028 / Approach D). Both retirements include a "reopen if downstream acquires per-repo catalog/manifest surfaces" caveat. The genuine v2 opportunity (executable enforcement) landed as Error check 12.

### Notes

- Autoplan CEO review caught Approach G (markdown 2a/2b restructure of pipeline.md Step 6) as "aesthetic theater without enforcement" — splitting a parenthetical into a numbered sub-step makes future deletion slightly harder but provides zero structural protection. Pivoted to F+I, which puts the guard inside the workbench's own validate-everything-on-every-PR loop.
- v3.5.6 is contract enforcement, not a feature. Workbench gets one more PASS line on every /ship CI run; downstream is unaffected (validate.sh doesn't run downstream because it doesn't ship there).

## [3.5.5] - 2026-05-14

### Fixed

- **`/CJ_goal` works in downstream repos (T000028, Approach D).** The post-scaffold boundary check in `scripts/goal.sh` previously ran `./scripts/validate.sh` unconditionally — every downstream repo without `validate.sh` halted with `halted_at_scaffold` (exit 127), making `/loop /CJ_goal` drain unusable outside the workbench. Two-location fix:
  - Deleted the workbench-coupled `validate.sh` call at `scripts/goal.sh:526` entirely. The original call was both downstream-broken AND duplicate work — `/CJ_personal-pipeline` Step 6 re-runs the same check seconds later in the dispatch chain.
  - Updated `skills/CJ_personal-pipeline/pipeline.md` Step 6 to describe `scripts/validate.sh` as "workbench-only — skipped silently when absent or non-executable." Workbench behavior preserved bit-identical; downstream repos pass through `/CJ_personal-workflow check` (portable) and skip `validate.sh` (workbench-coupled).
  - Surgical fix to `goal.sh`'s `awk -v body=...` block that emitted `awk: newline in string` warnings when a TODO body contained newlines. Uses a tmpfile + `getline` rather than interpolating the body via `-v`. `RESOLVED_BODY` is explicitly NOT mutated (used in 3 places including the sensitive-surface scan at `~line 289-290`).
  - Updated `skills/CJ_goal/SKILL.md` "Workbench-only scope" Note to reflect that the skill is portable; workbench is the development/curation surface, not a scope restriction.

### Notes

- Autoplan CEO review caught the half-fix premise in the original design: `/CJ_personal-pipeline/pipeline.md:528` ALSO calls `scripts/validate.sh`. Approach A (guard goal.sh only) would have shipped a fix that broke at the very next pipeline step in downstream repos. Approach D (delete goal.sh's call + guard pipeline.md's) is the two-location fix that actually solves the user's downstream `/loop /CJ_goal` drain.
- Two v2 follow-up TODOs logged: replace `pipeline.md:528` with a handoff to `/CJ_personal-workflow check` (Approach B), and ship `validate.sh` (or a scaffold-only subset) to downstream via `skills-deploy install` (Approach E).

## [3.5.4] - 2026-05-15

### Fixed

- **`/CJ_qa-work-item` filters post-ship E2E rows out of subagent dispatch (T000027, TODOS:108).**
  Previously, when TEST-SPEC E2E rows were structurally only verifiable post-ship (e.g., S000025 ACs 2/3/4/7 needed `gh workflow run eval-nightly.yml` against merged main), the QA subagent returned `ambiguous` for those rows, the user adjudicated "treat as green," and Phase 2 QA-owned gates flipped to `[x]` even though those ACs weren't actually verified. **v1 narrow fix (a+b only, c+d deferred per TODO body's recommended narrowing):** (a) extends the E2E Tests `Tag` column semantics in `doc-TEST-SPEC.md` to recognize literal token `post-ship`; (b) qa.md Step 4 now filters `post-ship`-tagged rows out of the E2E subagent dispatch and writes a `[qa-e2e-deferred]` journal entry naming the rows + their ACs. **Schema taste decision:** reuse existing Tag column (literal `post-ship` token) instead of a new column or section header — no migration to existing TEST-SPECs, opt-in per row, matches the existing `e2e-parent` Tag-override pattern. **Deferred to follow-up TODO:** (c) dedicated Phase 3 gate `Post-ship ACs verified` on tracker templates; (d) `/CJ_personal-workflow check --update` inference from `[qa-e2e-deferred]` journal entries.
  Fourth PR auto-scaffolded by `/CJ_goal` (T000024 → T000025 → T000026 → T000027).

## [3.5.3] - 2026-05-14

### Fixed

- **`/CJ_run` Branch(g) now dedups against PR state (T000026, TODOS:123).**
  Branch(g)'s candidate filter previously used TRACKER Phase 1/2/3 gate states alone — a tracker with `[x]` gates that was force-merged or hand-edited could slip past as a "false-in-progress" candidate. **Fix:** added per-invocation parallel-array PR-state cache (Bash 3.2 compatible) calling `gh pr view "$PR_URL" --json state -q .state`. Candidates whose PR state is `MERGED` are excluded; default-permissive on lookup failure (offline / unauthenticated / `UNKNOWN` → include the candidate, preserving prior behavior). `templates/CJ_personal-workflow/tracker-user-story.md` got an optional `pr:` frontmatter field (commented, backwards-compatible) so the parser can find PR URLs without scanning the markdown `## PRs` section.
  Third PR auto-scaffolded by `/CJ_goal` in this session (T000024 → v3.5.1; T000025 → v3.5.2; this PR → v3.5.3).

## [3.5.2] - 2026-05-14

### Fixed

- **`skills-deploy install` no longer pins manifest `source` to a worktree path (T000025, TODOS:111).**
  Previously, `scripts/skills-deploy install` recorded `manifest.source` (in `~/.claude/.skills-templates.json`) as the running clone's `REPO_ROOT` — computed from the script's own path. When invoked from `.claude/worktrees/<name>/scripts/skills-deploy`, the manifest got pinned to that ephemeral worktree path. Once the worktree was removed (Conductor cleanup, `git worktree remove`), `skills-deploy doctor` reported `FAIL: source path '<dead-worktree>' no longer exists` for every skill, and update-check's inline `git pull --ff-only` fallback silently broke.
  **Fix:** resolve `manifest.source` to the main repo toplevel via `git rev-parse --path-format=absolute --git-common-dir` (its parent is the canonical toplevel regardless of which worktree the script ran from). Falls back to `$REPO_ROOT` if the git call fails (non-worktree contexts).
  This is the fourth task-type work-item shipped via direct dispatch in this session (T000022, T000023, T000024 prior) — and the **second auto-scaffolded by `/CJ_goal`** (T000024 was first).

## [3.5.1] - 2026-05-14

### Fixed

- **`/CJ_scaffold-work-item` Step 5 idempotency hole (T000024, TODOS:67).**
  Step 5 of `skills/CJ_scaffold-work-item/scaffold.md` previously generated a fresh ID every time, then relied on Step 9's boundary check to detect duplication — but Step 9 uses `TARGET_PATH` derived from the freshly-generated `NEW_ID`, so the existing scaffold dir was never inspected. Re-running scaffold on an existing design doc would write a duplicate work-item alongside the original.
  **Fix:** new Step 5.0 idempotency pre-check before fresh-ID generation. Two probes: (A) read the source design doc's `**Status: SCAFFOLDED → <path>**` footer that Step 12 writes; (B) grep `work-items/**/TRACKER.md` for trackers referencing this design-doc path. On match, set `NEW_ID = existing ID` and `TARGET_PATH = existing path` so Step 9 boundary-check NO-OPs as designed. Step 5 fresh-ID generation renumbered to 5.1.
  **/CJ_goal first real-run validation:** this PR is the third task-type work-item shipped via /CJ_personal-pipeline direct dispatch in the same session as v3.4.1-3.5.0 (T000022 chmod+x, T000023 refuse-vacuous-PASS). T000024 is `/CJ_goal`'s first auto-scaffolded green run — proves the full chain (TODOS.md row → preflight → scaffold → pipeline → ship → deploy) works end-to-end.

## [3.5.0] - 2026-05-14

### Added

- **`/CJ_goal` — auto-resolve TODOs that other tasks drop into TODOS.md (F000019, S000041).**
  New top-level skill that bridges a TODOS.md row → green PR via the existing implement-QA-ship-deploy chain. Takes optional `/CJ_goal <T-ID>` for exact-tracker lookup, `/CJ_goal "<fragment>"` for fuzzy heading match, `/CJ_goal --dry-run` for preview, or no args (consumes /CJ_suggest top-1). All non-trivial logic lives in `skills/CJ_goal/scripts/goal.sh` (#!/usr/bin/env bash shebang per D000017 lesson).

  Pipeline: resolve TODO → pre-flight gates (suffix-parse for P0-P4 + S/M/L/XL; priority/size cap refuses P1 + L/XL; body-too-vague halt <50 chars; sensitive-surface AUQ on body regex match; design-needed keyword halt; idempotency via traceability footer grep) → auto-scaffold T-task (TRACKER + test-plan from `templates/CJ_personal-workflow/`) → boundary check via `/CJ_personal-workflow check` → direct dispatch chain (`/CJ_personal-pipeline --work-item-dir --suppress-final-gate` via Agent subagent → `/ship` → `/land-and-deploy --suppress-readiness-gate`) → hash-verify TODOS.md DONE-mark write → telemetry.

  **Substrate dependencies (all shipped today):** v3.4.1 (D000019) type-aware Step 7 halt + Step 5.1 input selection; v3.4.2 (T000022) implement-chmod-+x; v3.4.3 (T000023) refuse-on-vacuous-PASS. Without these, /CJ_goal would have shipped vacuous green PRs.

  **`/loop /CJ_goal` semantics (Theme B):** continue set = `{green, idempotent_skip, halted_at_preflight}`. Benign per-TODO halts skip-and-continue via per-session skip-list (`/tmp/cj-goal-skip-${RUN_ID}.txt`, post-filtered into /CJ_suggest output via `grep -vFxf`). Substantive halts (`halted_at_ship`, `halted_at_pipeline_*`, `halted_at_deploy`, `halted_at_scaffold`, `halted_at_sensitive_surface_user_declined`, `halted_at_todos_md`) stop the loop for human review. Best fit: 1-5 small TODOs per focused session (one /ship Gate #2 diff-review pause per TODO is intentional friction — upstream gstack constraint).

  **Eval coverage:** 7 preflight-halt fixtures at `tests/eval/CJ_goal/halt-*/`. Green-path eval deferred per per-case $0.50 budget cap (matches /CJ_personal-pipeline precedent).

  Provenance: 4 autoplan rounds (8 design patches, /CJ_goal-internal Theme B + per-session-skip-list + footer Themes Resolution), 3 substrate PRs (v3.4.1/.2/.3), single F-feature with one user-story child (S000041_skill_skeleton).

## [3.4.3] - 2026-05-14

### Fixed

- **`/CJ_qa-work-item` refuses vacuous-PASS on placeholder-only test plans (T000023, Theme C from /CJ_goal autoplan).**
  Previously `qa.md` Step 4 "Edge cases" treated test plans with only placeholder rows (filtered out as `#=1 AND Steps={steps}`) as vacuous PASS — logged `INFO: ... treating as vacuous PASS`, wrote `[qa-pass]` to the tracker, and skipped to Step 9 gate transition. Result: any work-item scaffolded from the `doc-test-plan.md` template and left unpopulated would silently pass QA. /CJ_goal's autoplan flagged this as one of the load-bearing Theme C blockers — under `/loop /CJ_goal`, an auto-scaffolded task with an unpopulated test-plan would have shipped a green PR with zero real tests run.
  **Fix:** the edge case now HALTs (all types — defect, task, user-story). Returns refuse-RESULT `SMOKE=red; E2E=red; PHASE2_GATES=partial` (orchestrator's Step 7 interprets as halt-at-gate). Writes `[qa-refused]` journal entry naming the affected work-item. Refuses to write `[qa-pass]`. Surfaces "populate the test-plan, then re-run" message. Stale `[qa-pass] ... vacuous PASS` journal template at Step 9 reconciled.
  Closes /CJ_goal autoplan Theme C blocker. /CJ_goal's design can now ship with a placeholder test-plan generator AND know that QA will refuse the gate until real test cases land.

## [3.4.2] - 2026-05-14

### Fixed

- **`/CJ_implement-from-spec` now sets the executable bit on new shell scripts (TODOS:97, T000022).**
  When the implement subagent writes a new `.sh` file via the `Write` tool, the file lands at mode 644 (non-executable) by default. Downstream consumers (skills-deploy install smoke checks, test-plan rows asserting "executable bit set", /ship Step 9 pre-landing review) flag the discrepancy. On D000017 (PR #84), the implement subagent shipped `skills/CJ_suggest/scripts/suggest.sh` at mode 644; /ship Step 9 caught it as a `[LOW] AUTO-FIX` and `chmod +x`d the file pre-commit. **Fix:** post-write `chmod +x` sub-step added to `skills/CJ_implement-from-spec/implement.md` Step 9, applied to files matching `*.sh`, `*.bash`, or no-extension files whose first line is a `#!` shebang. Step 11 boundary check left advisory in v1 (any miss still surfaces at /ship Step 9 per D000017 precedent).

- **First real validation of v3.4.1's pipeline substrate fix end-to-end.**
  T000022 (this PR) is the first task-type work-item to ship via `/CJ_personal-pipeline --work-item-dir` → `/ship` → `/land-and-deploy` since v3.4.1's type-aware Step 7 + Step 5.1 fixes. The pipeline reached `end_state=green` without taste-override on `RESULT: SMOKE=green; E2E=ambiguous; PHASE2_GATES=green` — the failure mode that previously halted D000017 (taste-override workaround) and T000020 (strict halt). Validates the substrate fix in production conditions.

## [3.4.1] - 2026-05-14

### Fixed

- **`/CJ_personal-pipeline` Step 7 strict halt-on-ambiguous now type-aware (TODOS:94, D000019).**
  Previously, Step 7's "Any red/ambiguous → halt-at-gate" rule made `end_state=green` structurally
  unreachable for `defect` and `task` work-items: `/CJ_qa-work-item`'s inner E2E subagent only
  dispatches for user-stories, so `E2E=ambiguous` from a defect/task QA always means "n/a for this
  type" — but the strict rule treated it as "uncertain test result" and halted. Verified failure
  modes: D000017 (defect, taste-override workaround) and T000020 (task, strict-halt). New
  type-aware branch in Step 7: if `WORK_ITEM_TYPE in {defect, task}` AND `SMOKE=green` AND
  `PHASE2_GATES=green` AND `E2E=ambiguous`, continue silently to Step 8 (same path as the
  user-story green branch). User-story type-strict behavior preserved unchanged. Step 7 dispatch
  prompt also tightened to make defect/task E2E=ambiguous semantics explicit (NOT rewritten as
  E2E=green — preserves qa.md's "n/a for type" contract at line 179).

- **`/CJ_personal-pipeline` Step 5.1 sensitive-surface scan now type-aware (TODOS:91, D000019).**
  The scan previously only matched `skills/[^/]+/scripts/[^/]+\.sh` against `$SPEC`, but defects
  and tasks have no SPEC (RCA + test-plan for defects; TRACKER + test-plan for tasks). D000017
  shipped a new `skills/CJ_suggest/scripts/suggest.sh` past this gap — only caught by codex
  adversarial review at `/ship` Step 11. Two fixes: (a) Step 5.1 regex broadened from
  `skills/[^/]+/scripts/[^/]+\.sh` to `skills/[^/]+/scripts/[^/]+` (any file under scripts/,
  including `.bash`, `.py`, extensionless executables — trust boundary is the directory, not the
  extension); (b) input artifact selection is now type-aware (defects scan RCA + test-plan; tasks
  scan TRACKER + test-plan; user-stories continue to scan SPEC). New row added to the
  Sensitive-Surface Pre-Scan Reference table.

- **`/CJ_personal-pipeline` `WORK_ITEM_TYPE` + `TRACKER` now loaded as orchestrator-side bash variables.**
  Prerequisite for the Step 5.1 / Step 7 / Step 8 type-aware fixes. The orchestrator-model carries
  these as prose state and re-asserts them in each fresh Bash block (bash variables don't persist
  across orchestrator-model Bash calls). Frontmatter-anchored awk parser (`/^---$/{n++; next}
  n==1 && /^type:/`) restricts the match to the YAML frontmatter between the first two `---`
  lines, avoiding false matches on `type:` mentions in tracker prose / code blocks. CRLF-safe
  via `tr -d '\r'` (handles Windows-line-ending trackers). Empty-`$SCAN_INPUTS` guard at the
  Step 5.1 grep prevents the security gate from silently bypassing on defect/task work-items
  missing both RCA/test-plan/TRACKER.

## [3.4.0] - 2026-05-13

### Added

- **`/CJ_run` Phase 4 now passes `--suppress-readiness-gate` to `/land-and-deploy`
  (CJ_run v0.4.0 → v0.5.0).** End-to-end pipeline runs (design-doc mode, Branch
  c) on an all-green pipeline now surface only the two existing wrapper-AUQ
  gates (`/autoplan` final approval + `/ship` diff review); `/land-and-deploy`'s
  pre-merge Step 3.5a-bis (stale-review offer) and Step 3.5e (readiness gate)
  are suppressed under the flag. Mirrors the proven `--suppress-final-gate`
  pattern that `/CJ_personal-pipeline` already uses internally for its Step 8.5
  + 9.2 AUQs. Hard stops (CI red, merge conflict, free-test regression at
  Step 3.5b, deploy workflow failure, canary red) remain unaffected — they
  remain pre-3.5 STOPs or post-3.5 AUQs and still halt `/CJ_run` cleanly via
  the existing `halted_at_deploy` branch.

- **Branch(f) `open_pr` mode auto-continues into `/land-and-deploy`.** Previously
  the `open_pr` handler in `skills/CJ_run/run.md` printed `PR already open at
  $PR_URL. Run /land-and-deploy to merge.` and exited 0 — a dead-end that broke
  the "let it run to the end" promise for the resume-from-PR-open path. Now the
  handler parses `PR_NUM` inline (verbatim duplicate of Step 5's parsing block
  — `${PR_URL##*/}` → `gh pr list --head ...` fallback → `""` on failure) and
  dispatches `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` via the
  Skill tool. Step 5's verdict-handling branches (green → `END_STATE=green`;
  canary-revert → `deploy_red`; halted pre-merge → `halted_at_deploy`) all
  apply, and the telemetry write happens at Step 6 instead of an early exit 0.

### Forward-Compat Notes

- **Order-of-operations between gstack and workbench is symmetric.** The flag
  itself ships in a separate gstack PR (`skills/land-and-deploy/SKILL.md`,
  owned by the user by hand). If the workbench lands first, gstack's loose
  arg parser (case-statement that warns-and-continues on unknown flags)
  silently ignores the flag — legacy AUQs fire, no regression. If gstack
  lands first, the workbench's flag default is "off" until v0.5.0 ships
  here — also no regression. Users see no breakage in either order.

- **Direct `/land-and-deploy` callers are unaffected.** Suppression is opt-in
  via the flag — users invoking `/land-and-deploy` outside of `/CJ_run` still
  get today's readiness gate as their final sanity check (gstack-side).

### Out of Scope (deferred follow-ups)

- The gstack PR adding the `--suppress-readiness-gate` flag to
  `/land-and-deploy` itself. Owned by the user; out-of-scope for this
  workbench's CJ_personal-pipeline.
- Suppression of `/land-and-deploy` Step 5 deploy-strategy AUQ (fires when no
  platform config is detected and no production URL was passed). Different
  semantic change with its own blast radius; cleaner fix is to populate
  `## Deploy Configuration` in CLAUDE.md per `/land-and-deploy`'s detection
  logic. Follow-up TODO.
- Step 1.5 first-run dry-run AUQ. One-time setup gate, already CONFIRMED for
  this workbench; not per-invocation. Leave as-is.

## [3.3.2] - 2026-05-13

### Fixed

- **`scripts/setup-hooks.sh` now works from git worktrees.** The wrapper
  previously computed `HOOK_DIR="$REPO_ROOT/.git/hooks"` and aborted with
  `.git/hooks directory not found` whenever it was run from a worktree under
  `.claude/worktrees/`, because `$REPO_ROOT/.git` is a *file* there (pointing
  to `<main_repo>/.git/worktrees/<name>/`), not a directory. Now resolves
  the shared hooks directory via `git rev-parse --git-common-dir` and
  normalizes its relative-or-absolute return value to an absolute path
  before the existence check. Hooks land in the parent repo's `.git/hooks/`
  in both regular checkouts and worktrees, which unblocks v3.3.1's pickup
  step ("run `./scripts/setup-hooks.sh` after pulling") for anyone
  developing inside a worktree. Hook bodies (pre-commit, post-merge) are
  unchanged; only the path-resolution wrapper.

## [3.3.1] - 2026-05-13

### Fixed

- **Phase 3 gate-auto-update no longer false-fires on sibling-story trackers.**
  Adds a Phase 2 `[x]`-count delta preflight to the post-merge hook in
  `scripts/setup-hooks.sh`: a touched tracker now invokes
  `check-gates-update.sh` only if its Phase 2 implementer-owned gates
  transitioned from `[ ]` to `[x]` in `ORIG_HEAD..HEAD`. Without the guard,
  the engine resolved PR via `gh pr list --search <work-item-id>`, which
  matches the ID anywhere in PR title OR body and falsely advanced Phase 3
  ship + deploy + smoke gates whenever one PR documented multiple
  work-item IDs in its body. Observed twice: PR #99 marked
  S036/S037/S039 gates while shipping only S038; PR #100 re-corrupted
  S037/S039 while shipping only S036. Tracker-only edits (journal
  cleanup, doc edits on sibling-story trackers) now skip with
  `[skip] <dir>: Phase 2 [x]-count N -> M (no shipped code in this merge)`.
- **Pickup:** run `./scripts/setup-hooks.sh` after pulling so the new
  post-merge body lands in `.git/hooks/post-merge`. The shipped change is
  to `setup-hooks.sh` itself; the live hook is regenerated on the next
  invocation.

## [3.3.0] - 2026-05-14

### Added

- **`/CJ_run` Branch(b): multi-story auto-iterate loop (S000037).** Replaces the
  prior halt-with-manual-instructions behavior. When the pipeline returns
  `green` on a multi-story feature scaffold, Branch(b) now iterates each
  child user-story sequentially:
  - **Enumeration:** `find $WORK_ITEM_DIR -maxdepth 1 -mindepth 1 -type d -name 'S[0-9]*' | sort`
  - **v1 guard:** AskUserQuestion if more than 3 children (inline Skills accumulate ~3K tokens per child; v2 will subagent-dispatch).
  - **Resume guard:** `gh pr list --state merged --search 'head:${FEATURE_NAME}--${CHILD_NAME}-'` skips already-merged children on re-run.
  - **Per-child git setup:** branch off `origin/<base>` (timestamp-suffixed: `${FEATURE_NAME}--${CHILD_NAME}-YYYYMMDD-HHMMSS`), sparse-copy scaffold from feature branch, commit.
  - **Pipeline dispatch:** Agent subagent runs `/CJ_personal-pipeline --work-item-dir <child> --suppress-final-gate`. Per-child decision log via `GSTACK_PIPELINE_DECISION_LOG_PATH`.
  - **Ship + deploy:** on green, `/ship` + `/land-and-deploy` via Skill (inline; Gate #2 fires per child).
  - **Failure halt:** repo restored to feature branch; state written; loop breaks; remaining children listed.
- State file extended: `CHILDREN_TOTAL`, `CHILDREN_DONE`, `CHILDREN_FAILED`, `CHILD_PR_URLS` (per-run accumulator). `write_state()` helper updated.
- Step 6.1 telemetry: renamed `multi_story_scaffold_only` → `multi_story_mode` (boolean); added `multi_story_children_shipped` (count). Sunset trip-wire and PRIOR_5 summary jq selectors check both old and new field names for backward compatibility with pre-v3.3.0 log entries.
- Step 6.2 green summary: new multi-story block shows `children_shipped=N/M` and lists per-child PR URLs.
- `skills/CJ_run/SKILL.md`: version 0.3.0 → 0.4.0.
- `skills-catalog.json`: CJ_run version 0.3.0 → 0.4.0.

## [3.2.0] - 2026-05-14

### Added

- **`/CJ_run` Branch(f): full phase-detection + dispatch (S000039).** Replaces the v3.0.0
  placeholder stub. Branch(f) now reads TRACKER phase state (Phase 2 implementer + qa gate
  strings, plus PR URL from frontmatter or `## PRs` section), resolves one of six MODE
  values, and dispatches the right sub-pipeline:
  - `impl_qa_ship` (IMPL_GATE=0): Agent-dispatches `/CJ_personal-pipeline --work-item-dir`
    with `--suppress-final-gate`, then runs `/ship` + `/land-and-deploy` via Skill.
  - `qa_ship` (IMPL_GATE=1, QA_GATE=0): Skill-invokes `/CJ_qa-work-item`, then `/ship` +
    `/land-and-deploy`.
  - `ship` (both gates green, no PR URL): Skill-invokes `/ship` + `/land-and-deploy`.
  - `open_pr` (PR URL set, `gh pr view` returns OPEN/DRAFT): prints pointer + exits 0.
  - `already_shipped` (PR URL set, state=MERGED): graceful NO-OP exit 0.
  - `pr_unknown_state` (gh offline / unexpected PR state): presents AskUserQuestion with
    `retry-ship` / `treat-as-merged` / `abort` options; no auto-decide.
- Branch(f) integrates with Branch(g) (S000038): when Branch(g) picks a single candidate,
  it sets `INPUT_MODE=work-item-dir` and falls through to Branch(f) phase-detection.
  Single source of truth for phase logic.
- Gate strings (verbatim from `templates/CJ_personal-workflow/tracker-user-story.md` Phase 2):
  IMPL = `Todos section reflects remaining work`, QA = `Acceptance criteria verified met`.
  Template drift is a known fragile surface — if those strings change, Branch(f) breaks
  silently. Documented in `run.md` Step 1.1 comments.
- Type filter: Branch(f) v0.2 supports user-story TRACKERs only. Defect/task types print
  a clear error directing the user to invoke sub-skills directly (extend in v0.3).
- Telemetry: `~/.gstack/analytics/CJ_run.jsonl` gains a `mode: <MODE>` field per
  Branch(f) invocation for diagnostic visibility.
- `skills/CJ_run/SKILL.md` description updated to reflect Branch(f) is live (no longer
  a placeholder); version 0.2.0 → 0.3.0.
- `skills-catalog.json`: CJ_run version 0.2.0 → 0.3.0; description updated.

### Fixed

- **Tracker corruption recurrence (S000039 only).** PR #100's land-and-deploy hook re-marked
  Phase 3 ship/deploy/smoke gates on S000039_TRACKER.md (despite S000039's actual impl not
  being in that PR). Unchecked the gates and removed the stale PR #99 reference. Same hook
  bug as v3.1.0; defect tracked for follow-up (spawn-task chip).

## [3.1.0] - 2026-05-14

### Added

- **`/CJ_personal-pipeline --work-item-dir <path>` flag (S000036).** Pipeline now
  accepts a pre-staged work-item directory as an alternative to a design-doc path.
  In this mode, Step 1 validates the dir contains `*_TRACKER.md`, Step 2 fires a
  new Branch (e) that skips footer search + Phase 1 scaffold entirely, Step 4
  sub-step 1 (footer write-back confirm) is carved out, Step 9.1 telemetry adds
  `work_item_dir_mode: true`, and Step 9.3 summary handles empty DESIGN_DOC. Used
  by `/CJ_run` Branch (b) multi-story auto-iterate (S000037) and Branch (f)
  phase-detection dispatch (S000039) to dispatch per-child pipeline runs without
  a design doc. The flag is type-agnostic (works on user-story / defect / task
  dirs). Combines cleanly with `--suppress-final-gate` in either order.
- `skills/CJ_personal-pipeline/SKILL.md` Usage section updated with both input
  modes (design-doc + work-item-dir) and version bumped to 1.1.0.
- `skills-catalog.json`: CJ_personal-pipeline version 1.0.0 → 1.1.0 (drift
  reconciliation; SKILL.md was stale at 0.1.0).

### Fixed

- **Tracker corruption from PR #99's land-and-deploy hook (S036/S037/S039).**
  When PR #99 (S000038 rename) merged, the land-and-deploy hook auto-marked
  Phase 3 ship/deploy/smoke gates on three sibling trackers (S000036, S000037,
  S000039) that were on the same feature branch but whose implementation wasn't
  in that PR. Reverted: unchecked Phase 3 gates in all three trackers; removed
  stale PR #99 references from their PRs sections; documented the correction
  via `[impl-finding]` journal entries. S036 also marked its Phase 1
  "Tasks broken down" gate as `[x] N/A — atomic story` per the office-hours
  premise.
- `work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/S000036_pipeline_work_item_dir_flag/S000036_TEST-SPEC.md`: smoke test S4 expected version reconciled to `1.1.0` to match implementation reality (SPEC's nominal `0.2.0` was based on the stale SKILL.md baseline).

## [3.0.0] - 2026-05-13

### Changed (BREAKING)

- **Renamed `/CJ_ship-feature` to `/CJ_run`.** Single unified public entry point for the CJ pipeline. The new name accurately reflects "run the pipeline" rather than being feature-specific. Direct callers of `/CJ_ship-feature` (scripts, aliases, memory files) must update — no backward-compat shim. Routing keys for both `/CJ_ship-feature` and `/CJ_personal-pipeline` now map to `/CJ_run`.
- **`/CJ_personal-pipeline` removed from public routing.** Kept in `skills/` as the internal pipeline orchestrator invoked by `/CJ_run`; SKILL.md and catalog descriptions prefixed with "INTERNAL — invoked by /CJ_run. Do not call directly." Still invocable directly as an escape hatch, but no longer surfaced in routing rules.

### Added

- **`/CJ_run` Branch(g): no-arg branch scan.** `/CJ_run` with no arguments scans `work-items/` for in-progress user-stories on the current branch (Phase 1 fully green + Phase 2 implementer-owned gates unchecked + not yet QA'd or shipped). Single candidate → auto-dispatch. Multiple → emits `MULTI_CANDIDATE_AUQ_REQUIRED` marker for the orchestrator to render AskUserQuestion. Empty `work-items/` → graceful "Nothing to resume" message. bash 3.2 compatible (uses `while IFS= read -r`, not `mapfile`). Documents the canonical Phase 1 Gates block scoping for cross-skill use.
- **`/CJ_run` Branch(f): work-item-dir input mode (placeholder).** Accepts a work-item directory path; phase-detection and dispatch table tracked under S000039 (blocked on F000016). v3.0.0 ships a clear-message placeholder that prints next-step guidance and exits 0; full impl_qa_ship/qa_ship/ship/open_pr/already_shipped/pr_unknown_state dispatch lands in the follow-up story.
- **`work-items/features/ops/F000017_cj_run_entry_point/`** — feature scaffold with two child user-stories: S000038 (this rename + Branch g) and S000039 (Branch f phase-detection + dispatch, blocked on F000016).
- **`work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/`** — feature scaffold from a prior `/office-hours` session for multi-story auto-iterate; included in this PR for traceability. Children S000036 and S000037 remain unimplemented; will land in a future PR.
- `TODOS.md`: new P2 entry for Branch(g) full PR-state detection follow-up (current candidate filter uses Phase 1/2/3 gate states; full `gh pr view` integration deferred).

### Fixed

- `skills/CJ_run/fixtures/README.md` and `skills/CJ_run/fixtures/synthetic-approved-design.md`: stale `/CJ_ship-feature` references replaced with `/CJ_run`. Fixtures are now runnable post-rename.
- `skills/CJ_personal-pipeline/pipeline.md`: 3 stale `/CJ_ship-feature` references updated to `/CJ_run` (wrapper-relationship paragraphs).
- `rules/skill-routing.md`: collapsed `/CJ_ship-feature` and `/CJ_personal-pipeline` routing entries into unified `/CJ_run` entries; added explicit notes that Branch(f) work-item-dir mode is a placeholder until S000039.


## [2.2.1] - 2026-05-13

### Changed

- `tests/eval/README.md`: added "## Why this exists" section explaining V1 narrow scope (5 cases, all `check.md`) vs V2 value (scaffold/implement/qa mutations); makes the harness purpose clear without reading the tracker.
- `TODOS.md`: S000025 post-ship bullet updated — nightly CI deferral rationale documented (V1's 5 cases cover only `check.md`; ~$1/run cost not justified until V2 adds mutating-skill cases; trigger manually before shipping changes to `check.md`).
- `templates/CJ_personal-workflow/tracker-defect.md`: synced workbench source with deployed template — added post-v2.2 note about freestanding-file convention for new defects (D000019+); retained dir-wrapper note for legacy defects D000001-D000018.
- `S000025_TRACKER.md`: cleared stale `blocked_by: S000024` (S000024 shipped v1.16.1), updated date, added deferral decision journal entry.

## [2.2.2] - 2026-05-13

### Added

- `rules/skill-routing.md` — canonical global routing rules for top-level `CJ_*` pipelines and utilities. `skills-deploy install` now deploys this file to `~/.claude/rules/skill-routing.md`, making routing active in every Claude Code session (not just the workbench repo). Source of truth for routing; workbench `CLAUDE.md` is a stub pointer.
- `scripts/skills-deploy`: rules/ deploy pipeline — installs `rules/*.md` → `~/.claude/rules/` during `install`, removes them on `remove --all`, reports MISSING/WARN/OK in `doctor`. Includes `--no-overwrite` WARN mode, documentation-file exclusion guard (README.md etc.), cp error recovery, and `remove_all` gate (single-skill remove does not touch rules).
- `scripts/validate.sh` Check 11: verifies `rules/*.md` files are deployed to `~/.claude/rules/`; CI-safe (WARN when deploy target absent, not a hard fail on fresh checkouts).
- `scripts/test-deploy.sh` T9 suite (T9a–T9g): tests for rules install, content-match, `--no-overwrite` WARN, doctor MISSING/WARN paths, `remove --all` cleanup, and regression guard (single-skill remove preserves rules).
- `README.md` + `scripts/generate-readme.sh`: skills-deploy entry updated to describe the rules/ pipeline and T9 test suite.

### Changed

- `CLAUDE.md` skill routing section converted to a 2-line stub pointing at `rules/skill-routing.md`. Routing routes trimmed to top-level pipelines only: `/CJ_system-health`, `/CJ_ship-feature`, `/CJ_personal-pipeline`, `/CJ_suggest`. Internal step skills (scaffold/implement/qa) are no longer direct-routed; they are invoked transitively by pipeline orchestrators.
- `rules/skill-routing.md`: tightened trigger phrases — removed overbroad `"auto mode"` trigger (was catching unrelated phrases globally); renamed `"health check"` to `"check installed skills"` / `"skill system health"` to avoid collision with gstack `/health` skill.

## [2.2.0] - 2026-05-12

### Added

- New skill `/CJ_ship-feature` — end-to-end wrapper from an APPROVED `/office-hours` design doc to a verified production deploy. Chains `/autoplan` (review) → `/CJ_personal-pipeline` (scaffold→impl→QA, dispatched as Agent subagent with `--suppress-final-gate` from v2.1.4) → `/ship` (PR creation) → `/land-and-deploy` (merge + verify). Exactly 2 wrapper-orchestrated AUQ gates: `/autoplan` final-approval (design decisions) + `/ship` diff review (code-level); sub-skill native AUQs pass through. `CJ_personal-pipeline` 8.5 + 9.2 AUQs are SUPPRESSED via the wrapper contract; decisions logged to `/tmp/cj-ship-feature-$RUN_ID-pipeline-decisions.jsonl` and surfaced in the wrapper's final-summary tail. Halt-on-red default; idempotent per sub-skill re-entry paths; sunset criterion on the 6th invocation counts only orchestration-brittleness end_states (`halted_at_autoplan`, `halted_at_pipeline`, `halted_at_deploy`, `subagent_crashed`) — excludes `halted_at_ship` (healthy review catch), `deploy_red` (production state), and multi-story-scaffold-only rows. Multi-story features halt cleanly at the scaffold gate per existing `CJ_personal-pipeline` behavior; wrapper skips `/ship` + `/land-and-deploy` and prints per-child invocation instructions. Per [chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md](https://github.com/jcl2018/knowledge-base/blob/main/.gstack/projects/jcl2018-knowledge-base/chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md) (PR2 of 3; PR1 was v2.1.4 `--suppress-final-gate`; PR3 = real first run + docs).
- New skills-catalog entry `CJ_ship-feature` (status: experimental, portability: standalone, depends on `CJ_personal-pipeline`).
- New fixture `skills/CJ_ship-feature/fixtures/` — `README.md` documenting the smoke workflow (copy synthetic design to `~/.gstack/projects/scratch/`, invoke wrapper, stop manually before /ship creates a real PR) + `synthetic-approved-design.md` minimum-valid fixture for pre-flight exercises.


## [2.1.4] - 2026-05-12

### Added

- `/CJ_personal-pipeline` learns `--suppress-final-gate` flag (paired with `GSTACK_PIPELINE_DECISION_LOG_PATH` env var). When set, Step 8.5's final-approval AUQ AND Step 9.2's sunset-checkpoint AUQ are skipped; decision log redirects to the wrapper-specified path; tracker journal records `[auto-pipeline-clean]` (zero Taste + zero User-Challenge-Approved decisions) or `[auto-final-gate-suppressed] N mechanical, M taste, K user-challenge-approved` (non-empty); telemetry write is unchanged, with `mode: "auto-suppressed"` distinguishing wrapper-invoked from standalone runs. Designed for wrapper skills (e.g. forthcoming `/CJ_ship-feature`) that dispatch the pipeline as an Agent subagent — AskUserQuestion is unreachable inside subagents (S000026 spike), so the flag makes that unreachability explicit and lets the wrapper handle decision surfacing itself (typically via `/ship`'s diff review). Standalone behavior (flag absent) is unchanged. Per [chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md](https://github.com/jcl2018/knowledge-base/blob/main/.gstack/projects/jcl2018-knowledge-base/chjiang-claude-stupefied-ellis-2949b6-design-20260511-220642.md) (PR1 of 3; PR2 = wrapper skill, PR3 = real first run).
- New `Suppression Contract` subsection under `## Decision Gates` in `pipeline.md` documenting the flag + env var contract. New `Step 8.5 + 9.2 with $SUPPRESS_FINAL_GATE` row in the per-gate classification table.
- New fixture `skills/CJ_personal-pipeline/fixtures/regression-suppress-final-gate/` covering: (a) with-flag path — 8.5 + 9.2 AUQs skipped, journal entry present, decisions land in custom log; (b) no-flag regression — behaves identically to v2.1.3; (c) flag-without-env-var negative test — soft warning to stderr, pipeline still proceeds.

### Changed

- Step 1 in `pipeline.md` adds a soft-warning to stderr if `--suppress-final-gate` is set but `GSTACK_PIPELINE_DECISION_LOG_PATH` is not (supported but not recommended: would mingle suppressed-gate decisions with standalone-run history).


## [2.1.3] - 2026-05-11

### Added

- TODOS.md entry captures the `skills-deploy install` worktree-pinning bug surfaced during a `/investigate` session: running the installer from `.claude/worktrees/<name>/` records the worktree path in `~/.claude/.skills-templates.json` as `source`, then `skills-deploy doctor` reports FAIL for every skill once the worktree is removed (the per-skill SKILL.md symlinks still resolve fine — only the global `source` anchor breaks). Entry proposes three fix options and recommends auto-resolving to the main git common-dir.


## [2.1.2] - 2026-05-11

### Fixed

- `/CJ_qa-work-item` E2E subagent no longer silently degrades to structural source inspection when an E2E row needs to invoke a `/skill` command. The Step 7 subagent prompt now lists Skill alongside Read/Bash/Grep/Glob and explicitly forbids the structural-fallback shortcut. Behavior change for any user-story whose TEST-SPEC E2E rows describe user-facing flows — verdicts are now real `green`/`red` instead of `ambiguous via structural inspection` (D000018).

### Added

- Step 4.5 tool-need classifier in `/CJ_qa-work-item` partitions each E2E row into one of four categories (`read-only`, `skill-invoking`, `interactive`, `recursive`). Rows the subagent can handle (read-only + skill-invoking) dispatch to the existing Step 7 subagent; rows that need AskUserQuestion or recursive Agent dispatch run parent-inline (new Step 7.5) with the orchestrator's full toolbelt. TEST-SPEC authors can force parent-inline via a `Tag: e2e-parent` cell override (D000018).
- Step 6.5 `[qa-e2e-run-start]` journal marker + Step 8 scope-after-marker aggregation so re-runs don't pick up prior runs' verdicts. Step 8's row-number regex `\[qa-e2e\] (E[0-9]+) \(` anchors on the trailing `(` so `E1` no longer absorbs `E10`'s verdict on TEST-SPECs with 10+ rows (D000018 R5/R6 mitigations from ship-time adversarial review).

### Changed

- `tests/spike/subagent-capabilities/findings.md` appends a 2026-05-11 re-probe note correcting the implication-by-omission in the 2026-05-09 spike. Both `subagent_type: "claude"` and `"general-purpose"` have `Skill=yes` (the original spike's blind spot — the Step 7 prompt-text was the actual bug, not subagent capability).


## [2.1.1] - 2026-05-11

**`/CJ_personal-pipeline` final summary now points at gstack `/qa` for web-app polish.** Adds `/qa` as a sibling entry to `/ship` inside Step 9.3's printed `Next:` block — one line, conditionally phrased ("if work-item touched a web app — visual / E2E polish"). When the pipeline finishes a green run, users now see `/qa` alongside `/ship` instead of having to remember it exists.

Scope-disciplined per design doc decision: text-only pointer, no new dependency on gstack, no schema change, no commit-ownership tangle with `/CJ_qa-work-item`. The four ruled-out heavier integrations (TEST-SPEC frontmatter flag, full pipeline integration, hard dependency, etc.) all violate one of P2 (subagent-AUQ unreachability per S000026 spike), P3 (commit-owner conflict between `/qa`'s autonomous fix-and-commit loop and `/CJ_qa-work-item`'s contract-driven gate transitions), or P4 (workbench portability — `skills-deploy install` must continue to work without gstack present).

Origin: T000020 task work-item scaffolded + implemented + QA'd by `/CJ_personal-pipeline` itself (eating its own dog food). Design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-epic-williams-a2c0c2-design-20260511-145646.md` (approved via /office-hours on 2026-05-11).

### Added

- **`/CJ_personal-pipeline` final summary names `/qa`** — `skills/CJ_personal-pipeline/pipeline.md:652` adds one column-aligned entry under the existing `Next:` block in Step 9.3. The inline comment (`# if work-item touched a web app — visual / E2E polish`) makes the line self-filtering at read time so non-web work-items aren't bothered by it. Discoverability surface for `/qa` at the moment it's relevant; no runtime coupling.

### Changed

- **`TODOS.md` entry "Step 7 strict halt-on-ambiguous blocks defects" → "blocks defects and tasks"** — extended the existing P3 entry to capture a second occurrence (T000020 strict-halt path) alongside the prior D000017 taste-override path. Two halts on the same root cause across two work-item types confirms the bug is structural, not a one-off; the existing fix proposal (type-aware halt rule, treat `E2E=ambiguous` as green when `WORK_ITEM_TYPE in {defect, task}` AND smoke green AND gates green) now also recommends tightening the Phase 3 dispatch prompt to map task/defect E2E to `green` explicitly. Reference run: 20260511-150733-27826.

## [2.1.0] - 2026-05-11

**F000015 work-copilot pipeline: feature-complete.** Ships the final four Copilot slash commands (`/wc-scaffold`, `/wc-investigate`, `/wc-ship`, `/wc-pipeline`) plus three domain-knowledge skeleton templates and a first-install rule in `copilot-deploy.py`. The full receipt-driven pipeline (`/wc-investigate` → `/wc-scaffold` → `/wc-implement` → `/wc-qa` → `/wc-ship`) is now installable end-to-end on a Copilot target repo, with `/wc-pipeline` as the read-only status compiler that reads receipts from tracker frontmatter and computes drift math across the chain.

Minor bump (vs the v2.0.7–2.0.9 PATCH cadence) reflects feature completion across 6 user-facing Copilot commands + new on-disk surface (`work-copilot/domain/`, `work-copilot/designs/`). v2.0.8 and v2.0.9 shipped milestones 1 and 2; this PR closes milestones 3-6.

Origin: F000015 design at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-zealous-antonelli-5f8036-design-20260511-095218.md` (approved via /office-hours on 2026-05-11). Build order followed Codex's Approach C bottom-up: /wc-qa first (schema-lock), then /wc-implement, /wc-scaffold, /wc-investigate, /wc-ship, /wc-pipeline.

### Added

- **`work-copilot/prompts/scaffold.prompt.md`** (new, 451 lines) — `/wc-scaffold` Copilot slash command (build #3 of 6). Reads a design-doc path's frontmatter for `status:` + `receipts.investigate` (idempotency check, mirrors `/CJ_scaffold-work-item` Step 9 intent via frontmatter not footer), reads the bundle manifest + templates, picks the next work-item ID, writes the directory tree with all required artifacts populated, runs `/validate <new-dir>` as a structural gate, copies `receipts.investigate` from the design-doc frontmatter into the new tracker's frontmatter (preserves lineage), writes `receipts.scaffold` block to the new tracker, updates the design doc's frontmatter `status: SCAFFOLDED` + `scaffolded_to: <work-item-dir>`. Design-doc-required invariant: `/wc-scaffold` refuses to scaffold without a design doc (user can author a stub if needed).

- **`work-copilot/prompts/investigate.prompt.md`** (new) — `/wc-investigate` Copilot slash command (build #4 of 6). Reads every `.md` under `.github/work-copilot/domain/` (skipping `.template.md` skeletons) as ambient context, greps/searches the target codebase for entities mentioned in the user's prompt, walks the user through a scoping conversation in chat (no AUQ available in Copilot — plain back-and-forth), synthesizes a design doc to `.github/work-copilot/designs/<slug>-design-<datetime>.md` with the required frontmatter contract, writes `receipts.investigate` block into the design-doc frontmatter (no tracker exists yet at this stage).

- **`work-copilot/domain/{domain-knowledge,coding-conventions,architecture-overview}.template.md`** (new, 3 files) — domain-knowledge skeleton templates installed once per target repo by `copilot-deploy install`. Each is a small structured Markdown skeleton (TODO sections) the target-repo user fills in once; provides stable ambient context for `/wc-investigate` to ground its scoping conversations. Per F000015 P3: domain folder is user data, never byte-mirrored from the workbench.

- **`work-copilot/prompts/ship.prompt.md`** (new) — `/wc-ship` Copilot slash command (build #5 of 6). Runs `/validate` first, reads tracker + PRD/RCA (per type) + existing `PR-DESCRIPTION.md` template, runs the Working-Tree Rule paste pattern in WARN mode (distinct from `/wc-implement` and `/wc-qa` which hard-stop — synthesized PR description is useful even with an unpushed working tree), synthesizes a PR description from tracker journal + AC coverage from `receipts.qa` + commits in `receipts.implement.commits_since_scaffold`, prints to chat for clipboard paste, optionally writes to `<work-item>/PR-DESCRIPTION.md`. Writes `receipts.ship` with `pr_opened: false`, `pr_url: null` — user manually flips `pr_opened: true` after opening the PR on GitHub. `pr_opened` is the canonical truth (NOT `pr_url`) for `/wc-pipeline`'s ship-not-opened drift rule.

- **`work-copilot/prompts/pipeline.prompt.md`** (new, 549 lines) — `/wc-pipeline` read-only status compiler (build #6 of 6, **final**). `tools: [codebase, search, searchResults]` — NO `editFiles` (read-only diagnostic). Reads receipts from work-item tracker frontmatter (multi-phase drift math) OR design-doc frontmatter (DRAFT / APPROVED / SCAFFOLDED state) — input mode auto-detected by file shape. Reads `.git/HEAD` via the `codebase` tool (a plain file read; no shell access needed) and compares string-equality against `receipts.implement.latest_sha_at_implement` for the stale-check. Five drift rules computed: Missing (any phase receipt absent), Stale (HEAD moved past `latest_sha_at_implement`), Coverage holes (`qa.ac_ids_uncovered` non-empty), Diff audit drift (`qa.diff_audit.changed_files_without_tests` non-empty), Ship-not-opened (`ship.pr_opened == false AND completed_at older than 24h`). Plus Next Legal computed as union of all receipts' `next_legal` minus already-completed phases. Prints a single fixed-format status block; no mutations.

### Changed

- **`scripts/copilot-deploy.py`** — extended with the first-install rule for the 3 domain skeleton templates: on `install`, strip the `.template.md` suffix and write to `<target>/.github/work-copilot/domain/<name>.md` ONLY IF the target file doesn't already exist. Re-install on a target that has filled-in `<name>.md` content emits a `[KEEP-USER]` line and preserves the user's content byte-for-byte (verified via fixture: install → user-edit one file → re-install → shasum identical). Also creates an empty `<target>/.github/work-copilot/designs/.gitkeep` on install (user-data folder for `/wc-investigate` output, never byte-mirrored or overwritten). New `[USER-DATA]` doctor classification for paths under `.github/work-copilot/{domain,designs}/` — `copilot-deploy doctor` no longer treats per-target user content as `[ORPHAN]`.

- **`scripts/validate.sh`** — `EXPECTED_BUNDLE_FILES` array (Error check 10b, shipped in v2.0.8 / T000019) extended by SIX lines to require the 4 new prompts + 3 new domain skeletons. The array now lists all 10 F000015 bundle files; each is gated for existence at workbench-validation time. Progressive gating pattern is now mature (v2.0.8 introduced the gate with 1 entry; v2.0.9 extended by 1; v2.1.0 extends by 6 to complete F000015).

- **`VERSION`** — 2.0.9 → 2.1.0 (MINOR; F000015 feature-complete across 6 milestones touching 6+ user-facing commands + new on-disk surface).

- **Phase 2 gates all green** for S000032 / S000033 / S000034 / S000035 trackers. Notably S000033's `/wc-investigate` got `E2E=green` (not ambiguous) because the first-install rule + `[KEEP-USER]` re-install behavior is bash-exercisable from a Claude-side QA subagent against a `mktemp` target. S000032 / S000034 / S000035 got `E2E=ambiguous` (standard steady state for Copilot stories requiring interactive Copilot Chat).

### Now installable end-to-end

After `python3 scripts/copilot-deploy.py install <target-repo>` from a clone of this collection:

```
<target>/.github/copilot-instructions.md          # always-on ambient context
<target>/.github/prompts/validate.prompt.md        # /validate (pre-F000015)
<target>/.github/prompts/qa.prompt.md              # /wc-qa
<target>/.github/prompts/implement.prompt.md       # /wc-implement
<target>/.github/prompts/scaffold.prompt.md        # /wc-scaffold
<target>/.github/prompts/investigate.prompt.md     # /wc-investigate
<target>/.github/prompts/ship.prompt.md            # /wc-ship
<target>/.github/prompts/pipeline.prompt.md        # /wc-pipeline
<target>/.github/work-copilot/                     # manifest + templates + reference (byte-mirrored)
<target>/.github/work-copilot/domain/*.md          # 3 user-authored skeletons (first-install only)
<target>/.github/work-copilot/designs/.gitkeep     # empty user-data folder for /wc-investigate output
```

Open Copilot Chat in the target repo and invoke any of the 6 `/wc-*` commands. Recommended flow on a new feature: `/wc-investigate` → `/wc-scaffold <design-doc-path>` → `/wc-implement <work-item-path>` → `/wc-qa <work-item-path>` → `/wc-ship <work-item-path>` → open PR on GitHub → flip `pr_opened: true` in the tracker → `/wc-pipeline <work-item-path>` for status / drift math.

### Deferred follow-ups (non-blocking for installation testing)

- `T000020_tracker_receipts_stub` — adds `receipts: {}` to `deprecated/CJ_company-workflow/templates/tracker-*.md` (byte-mirror source-of-truth) for `MIRROR_SPECS` propagation. Not blocking runtime: the prompts use read-whole / merge / write-whole patterns that handle missing `receipts:` keys gracefully. Defer until real end-to-end usage surfaces a need.


## [2.0.10] - 2026-05-11

Fixes `/CJ_suggest` silently returning "No actionable items." in non-`CJ_personal-workflow` repos (e.g. the downstream portfolio consumer). Root cause: the script's band-pass required a `## Active work` section header in `TODOS.md`. Repos that group work items under domain-specific section headers (`## Dispatcher`, `## Alert Rules`, …) never flipped the awk active flag → empty candidate set → silent zero output, which surfaced to the user as the skill being "ignored." The skill's own SKILL.md called out the constraint ("tied to the CJ_personal-workflow tracker shape and TODOS.md `(Pn, X)` heading convention"), but the failure mode was silent enough that it looked like a routing miss in consumer-repo `CLAUDE.md`. Fix is workbench-side only — the portable fallback handles the domain-grouped shape without changing CJ_personal-workflow behavior.

### Fixed

- **`skills/CJ_suggest/scripts/suggest.sh`** — band-pass now detects which TODOS convention the repo uses. If `## Active work` exists (the CJ_personal-workflow shape), the existing gate runs unchanged. Otherwise the script falls back to scanning all `### ` headings across every `## ` section EXCEPT terminal/completed buckets (`## Completed | Done | Archive | Archived | Shipped | Deferred work`). Headings without the `(Pn, X)` suffix continue to default to P4/M downstream (premise #3 unchanged), so portable TODOs rank by recency/blocked-status alone. The `next` clause in the fallback awk prevents fallthrough from the terminal-section matcher to the generic `## ` matcher — without it, `## Completed` would re-enable the active flag a line later. Verified end-to-end: workbench output byte-identical to v2.0.9 baseline (5 ranked rows, same titles, same scores); portfolio consumer goes from `No actionable items.` → 5 ranked rows. `scripts/validate.sh` PASS (0 errors / 0 warnings), `scripts/test.sh` PASS.

### Changed

- **`skills/CJ_suggest/SKILL.md`** — Overview documents the two supported TODOS conventions explicitly (CJ_personal-workflow shape + domain-grouped shape) with the detection rule ("presence of `## Active work` switches modes") and the terminal-section exclusion list. Removes the "this-repo only" framing that contradicted the new portable behavior.
- **`VERSION`** — 2.0.9 → 2.0.10 (PATCH; bug fix, no behavior change for existing CJ_personal-workflow callers).

### Known concerns (DONE_WITH_CONCERNS)

- **No automated regression test added.** No `tests/eval/CJ_suggest/` harness exists today; building fixture + eval scaffolding for this fix would be larger than the fix itself. The verification is currently manual (byte-comparing workbench output, running against the portfolio repo). Adding a CJ_suggest eval suite is a reasonable follow-up if regressions become a concern.
- **Downstream consumer `CLAUDE.md` routing gap is separate.** The portfolio repo's `CLAUDE.md` skill-routing block listed 12 skills but not CJ_suggest, so even with this fix, Claude may not auto-invoke `/CJ_suggest` on "what's next" in that repo. That edit lives in the portfolio repo, not the workbench, and is the consumer's to commit.


## [2.0.9] - 2026-05-11

Ships build #2 of F000015 (work-copilot pipeline): the `/wc-implement` Copilot slash command, which performs per-type implementation dispatch with a walkthrough flow (NOT auto). Locks in the second prompt against the receipt schema fixed by S000030's `/wc-qa` in v2.0.8. Four of six F000015 child user-stories remain to ship (S000032 wc-scaffold, S000033 wc-investigate, S000034 wc-ship, S000035 wc-pipeline).

### Added

- **`work-copilot/prompts/implement.prompt.md`** (new, 381 lines) — the `/wc-implement` Copilot slash command. Per-type dispatch reads different input artifacts depending on tracker `type:` field: user-story → PRD + ARCHITECTURE + TEST-SPEC; defect → RCA + test-plan; task → TRACKER + test-plan; feature → feature-summary + DESIGN + milestones (multi-story → delegates to child user-story via chat-prompt); review → review-notes (degenerate receipt path: empty arrays, `open_risks` records review action). Walkthrough mode only — never runs auto; the prompt proposes a plan, user confirms in chat, edits code, re-confirms. Encodes the user-paste pattern for `git rev-parse HEAD` and `git log --oneline <scaffold_sha>..HEAD` to populate `latest_sha_at_implement` and `commits_since_scaffold` receipt fields. Working-Tree Rule (hard-stop on uncommitted changes in `files_touched`) via user-paste of `git status --porcelain`. Writes `receipts.implement` block to tracker frontmatter using the same read-whole / parse-YAML / merge / write-whole contract established by `qa.prompt.md`.

### Changed

- **`scripts/validate.sh`** — `EXPECTED_BUNDLE_FILES` array extended by one line to require `work-copilot/prompts/implement.prompt.md`. Progressive gating per Error check 10b shipped in v2.0.8 (T000019): each F000015 child story extends the array as its prompt ships, so the bundle existence check stays in sync with what's actually deployed.
- **`.gitignore`** — added `.gstack/deploy-reports/` alongside the existing `.gstack/sessions/` + `.gstack/analytics/` + `.gstack/learnings.jsonl` machine-local exclusions. Deploy reports written by `/land-and-deploy` are per-machine artifacts (not project history); ignoring them keeps `git status` clean across sessions without polluting the repo with workflow output.
- **`VERSION`** — 2.0.8 → 2.0.9 (PATCH; partial feature milestone, second of six F000015 builds).

### Deferred / known-state at this PR

- `S000032_wc_scaffold` (build #3), `S000033_wc_investigate` (#4), `S000034_wc_ship` (#5), `S000035_wc_pipeline` (#6) — scaffolded stubs only. Subsequent PRs ship each prompt and extend `EXPECTED_BUNDLE_FILES` accordingly.
- `T000020_tracker_receipts_stub` — not yet scaffolded. Adds `receipts: {}` to `deprecated/CJ_company-workflow/templates/tracker-*.md` (byte-mirror source-of-truth) for `MIRROR_SPECS` to propagate. Not blocking runtime: both `qa.prompt.md` and `implement.prompt.md` use the read-whole / merge / write-whole pattern that handles a missing `receipts:` key gracefully (created on first write).
- `S000031_wc_implement` Phase 2 QA-owned gates shipped GREEN this cycle (vs S000030's `partial`) — the QA subagent now treats `E2E=ambiguous + green smoke + structural surrogates over the same ACs` as sufficient. E2E rows remain structurally manual for Copilot-side stories (require interactive walks against an installed bundle); full green E2E is unachievable from a Claude-side subagent regardless of implementation quality.


## [2.0.8] - 2026-05-11

Lands the first milestone of F000015 (work-copilot pipeline) plus the prerequisite validator gate. Scaffolds the feature tree (F000015 + 6 user-story children for the 6 planned Copilot slash commands), ships the schema-locking `/wc-qa` prompt content (S000030), and adds the validator existence check that gates the bundle (T000019). Five sibling stories (S000031–S000035) remain unimplemented — this PR closes 1 of 6 prompts, not the full feature.

Origin: `/office-hours` produced a workbench-scoped design doc for porting `/CJ_personal-pipeline` to GitHub Copilot's runtime (no `Agent` subagent dispatch, no `AskUserQuestion`). The design adopted Codex's "make the work-item folder a visible state machine" reframe — each phase command writes a structured receipt block into tracker frontmatter, and `/wc-pipeline` (still pending in S000035) reads receipts to compute drift math. `S000030_wc_qa` ships first per Codex's argument that "a printer with weak child prompts is theater" — /qa locks the receipt schema before downstream prompts conform.

`/CJ_personal-pipeline` ran scaffold cleanly. The implement-batch attempt halted twice on S000030 (fixture-placement MIRROR_SPECS violation, then a post-QA gap where `validate.sh` didn't enforce prompt-file existence). The user chose to scaffold T000019 to close the second gap inline; T000019 ships in this PR alongside S000030.

### Added

- **`work-copilot/prompts/qa.prompt.md`** (new, 310 lines) — the schema-locking `/wc-qa` Copilot slash command. 9-step prompt body: (1) `/validate` first; (2) read test-plan or TEST-SPEC and print numbered checklist; (3) extract AC IDs from SPEC/PRD/RCA and flag uncovered; (4) ask user to paste `git log --name-only --since=…` (with first-run fallback to `receipts.scaffold` SHA); (5) Working-Tree Rule paste pattern (hard-stop on uncommitted changes); (6) walk checklist; (7) write `[smoke-pass]` / `[qa-fail]` journal entries; (8) write `receipts.qa` block to tracker frontmatter; (9) print `READY_FOR_SHIP` gate. Locks the receipt schema (`phase`, `completed_at`, `test_rows_run`, `ac_ids_covered`, `ac_ids_uncovered`, `diff_audit.changed_files_without_tests`, `journal_entries`, `ready_for_ship`, `next_legal`) that S000031–S000035 will conform to. Encodes the "read-whole-file / parse-YAML / merge / write-whole-file" frontmatter-edit pattern (surgical edits from Copilot are unreliable; this matches the existing `validate.prompt.md` precedent).
- **`work-items/features/work-copilot/F000015_work_copilot_pipeline/`** — full feature scaffold (TRACKER + DESIGN + ROADMAP) with 6 child user-stories (S000030 wc_qa, S000031 wc_implement, S000032 wc_scaffold, S000033 wc_investigate, S000034 wc_ship, S000035 wc_pipeline). Each child has TRACKER + DESIGN + SPEC + TEST-SPEC stubs. Build order documented as Approach C from the design doc: `/wc-qa` → `/wc-implement` → `/wc-scaffold` → `/wc-investigate` → `/wc-ship` → `/wc-pipeline` (Codex's contract-forcing bottom-up reasoning).
- **`work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa/fixtures/uncovered_ac/`** — work-item-local fixture (`PRD.md`, `ARCHITECTURE.md`, `TEST-SPEC.md`, `milestones.md`, `TRACKER.fixture.md`) giving `/wc-qa` a deliberately-uncovered-AC target to exercise the diagnostic. Initial placement under `work-copilot/fixtures/valid-feature-dir/S999001_uncovered_ac/` violated the `MIRROR_SPECS` byte-mirror invariant (no upstream counterpart in `deprecated/CJ_company-workflow/fixtures/`); moved here and `TRACKER.md` renamed to `TRACKER.fixture.md` so the work-items walker (`find -name 'TRACKER.md' -o -name '*_TRACKER.md'`) doesn't treat the fixture as a real work-item.
- **`work-items/tasks/work-copilot/T000019_validate_sh_existence_check/`** (TRACKER + test-plan; hand-scaffolded per "skip-design-for-small-todos") — task ownership for the new `validate.sh` Error check 10b.
- **`scripts/validate.sh`** Error check 10b (~30 lines added after the MIRROR_SPECS loop, before manifest reconciliation) — asserts work-copilot-only bundle files exist. Structurally distinct from the existing Error check 10 (byte-identity vs upstream); catches a different drift mode (file deleted or never shipped, not content drift). Progressive gating via an `EXPECTED_BUNDLE_FILES` array — currently lists `validate.prompt.md` + `qa.prompt.md`; each F000015 child story will extend the array by one line when its prompt ships. Test plan cases 1-4 all pass: current state PASS; synthetic-delete of `qa.prompt.md` fires correct FAIL; restore brings PASS; existing MIRROR_SPECS behavior preserved without overlap.

### Changed

- **`VERSION`** — 2.0.7 → 2.0.8 (PATCH; partial feature milestone, not breaking).

### Deferred / known-state at this PR

- `S000031_wc_implement`, `S000032_wc_scaffold`, `S000033_wc_investigate`, `S000034_wc_ship`, `S000035_wc_pipeline` — scaffolded only. Their `/CJ_implement-from-spec` runs land in subsequent PRs. Each will extend `EXPECTED_BUNDLE_FILES` in `scripts/validate.sh` by one line when its prompt ships.
- `T000020_tracker_receipts_stub` — not yet scaffolded. Adds `receipts: {}` to `deprecated/CJ_company-workflow/templates/tracker-*.md` (byte-mirror source-of-truth) for `MIRROR_SPECS` to propagate. Not blocking runtime: `qa.prompt.md`'s read-whole / merge / write-whole pattern handles missing `receipts:` key gracefully (writes it on first invocation).
- `S000030_wc_qa` Phase 2 QA-owned gates ship at `partial` — smoke green (5/5 after T000019 closed the existence-check gap), E2E `ambiguous` (E1-E4 rows require interactive Copilot Chat against an installed bundle and cannot be exercised from a Claude-side subagent). This is the steady state for Copilot-side stories; full green requires manual walks documented in each TEST-SPEC.


## [2.0.7] - 2026-05-11

Closes F000013 V1 (behavioral eval harness) by shipping the nightly CI workflow that operationalizes the runner from S000023 + cases from S000024. The harness goes from "works when chjiang remembers to invoke it locally" (= approximately never under sustained development) to "produces regression signal nightly without human intervention." Marks the parent `## TODOS.md` entry DONE-V1 with the F000013 link + V2 trajectory bullets so any future reader sees what shipped vs what's deferred. Implementation flowed `/CJ_suggest` → `/CJ_implement-from-spec` → `/CJ_qa-work-item` → `/ship` cleanly; full scaffold work (S000025_SPEC.md + DESIGN.md + TEST-SPEC.md + TRACKER.md) was already in place before this PR's branch opened.

Three of seven SPEC ACs (AC-2 first-run completes, AC-3 V1 success criteria observed, AC-4 cost recorded, AC-7 failure-notification verified) are explicitly post-ship: they require `gh workflow run eval-nightly.yml` against the merged-to-main workflow, which a `/ship` pre-merge skill structurally cannot do. These are tracked as user-owned in `S000025_TRACKER.md` Todos lines 90-93 + flagged in the new "Pre-ship vs post-ship AC categorization for /CJ_qa-work-item" follow-up so future work-items with the same shape don't repeat the adjudication overhead.

Pre-landing review found 14 hardening gaps in the workflow file. Auto-fix path applied 7 mechanical wins inline (permissions block, concurrency block, explicit `shell: bash`, npm version pin to `@^2`, cron offset, `apt-get update`, secret pre-check); the 4 deferred items needing design judgment (F1 secret-exfil via workflow_dispatch from non-main refs, F3 prompt-injection RCE via eval.sh's bypassPermissions mode, F11 GITHUB_STEP_SUMMARY injection via case-dir names, F12 failure artifact upload) are consolidated into the new "Eval workflow hardening" P1 follow-up so they don't get lost.

### Added

- **`.github/workflows/eval-nightly.yml`** (new, ~150 lines including comments) — nightly + manual GitHub Actions workflow running `bash scripts/eval.sh` at 09:17 UTC daily. `workflow_dispatch` enabled for debug/verification without waiting for cron. 15-min `timeout-minutes` bounds runaway cost (25% headroom over the V1 success criterion of 12 min). `ANTHROPIC_API_KEY` secret wired via job-level env. npm-installs `@anthropic-ai/claude-code@^2` (caret range mitigates yanked-from-latest supply-chain risk; bump major deliberately after release-note review). PASS/FAIL summary written to `$GITHUB_STEP_SUMMARY` with backtick-sanitized failure list (visible in Actions UI without expanding the log). Hardening notes (`permissions: contents: read`, `concurrency: eval-nightly` group, `defaults: shell: bash` for guaranteed pipefail, `apt-get update` before install, secret pre-check) all applied during `/ship` pre-landing auto-fix.
- **TODOS.md** — new P3-S follow-up: "Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item`". Captures the workflow gap surfaced during S000025 QA (`/CJ_qa-work-item` returns ambiguous on structurally-impossible-pre-ship E2E rows; user adjudicates "treat as green" each time; pretend-green-then-track-in-Todos pattern is repeated per work-item). Fix sketch: optional `phase: post-ship` field on TEST-SPEC E2E rows + dedicated Phase 3 gate `Post-ship ACs verified` + post-merge inference in `/CJ_personal-workflow check --update`.
- **TODOS.md** — new P1-M follow-up: "Eval workflow hardening" consolidating 4 deferred items from `/ship` pre-landing review on this PR. Covers F1 (secret-exfil ingress via workflow_dispatch from non-main refs — needs Environment + branch-protection design), F3 (prompt-injection RCE via bypassPermissions in eval.sh's case fixtures — fundamental design issue), F11 (GITHUB_STEP_SUMMARY full markdown-control-char sanitization — partial backtick-only mitigation already applied), F12 (failure artifact upload via `actions/upload-artifact` — already P2 in S000025_SPEC).

### Changed

- **`TODOS.md`** — "Behavioral eval harness (P1, M)" entry under `## Active work` heading marker changed to `### ~~Behavioral eval harness (P1, M)~~ DONE-V1`. The "Pending in F000013 follow-ups:" framing flipped to "Shipped in F000013 follow-ups:". S000025 bullet marked shipped with explicit post-ship verification scope (ACs 2/3/4/7 require `gh workflow run` against merged main). V2 trajectory paragraph (6 bullets) preserved intact for future reference.
- **`work-items/features/ops/testing/F000013_eval_harness_v1/F000013_ROADMAP.md`** — Delivery History section appended with 2026-05-11 entry naming the workflow file, TODOS marker, and ROADMAP entry. Workflow PR link + first-run cost/wall-clock metrics noted as pending ship + manual `gh workflow run` (drives ROADMAP milestone #4).
- **`work-items/features/ops/testing/F000013_eval_harness_v1/S000025_nightly_ci/S000025_TRACKER.md`** — frontmatter `branch:` corrected from stale "main" to current worktree (`claude/funny-yonath-b817ec`); `updated:` advanced to 2026-05-11. Phase 1 "Working branch created" gate transitioned to `[x]` (was unchecked despite `branch:` field being populated — two-source-of-truth drift fixed). Phase 2 implementer-owned + qa-owned gates all transitioned to `[x]`. Todos section reflects done items vs post-ship-deferred + conditional-on-first-run-data items. Journal extended with full impl + qa story: 7 `[impl-*]` entries (decisions for npm install + post-ship deferral; findings for F000011 gate matcher bug + ROADMAP staleness + Phase 1 gate drift; impl summary; impl-pass), 6 `[qa-smoke]` entries (S1-S5 + summary), 4 `[qa-e2e]` entries (E1/E2/E3 ambiguous-deferred-to-post-ship + E4 green), `[qa-e2e-summary]`, `[qa-adjudication]` recording user's D5 "treat as green" choice with rationale, `[qa-pass]` success marker.
- **`VERSION`** — 2.0.6 → 2.0.7 (PATCH; ships F000013 V1 final deliverable + auto-fix hardening; no skill behavior change beyond the new CI surface).


## [2.0.6] - 2026-05-11

Workbench-side mitigations for the queue-collision + auto-merge silent-fail pattern that bit 3 of 3 PRs (#79, #82, #83) in the v2.0.0 → v2.0.4 ship sequence. Each collision cost ~5-10 min recovery (re-fetch, resolve CHANGELOG conflict, rebump VERSION, update PR title, retest, re-merge). One operator mistake on PR #83's `/land-and-deploy` (premature `gh api DELETE` after `gh pr merge --auto` silently failed → GitHub auto-closed the PR) is now structurally prevented. Two changes:

- **`CLAUDE.md` `## CI/CD merge convention` rewrite.** Removed `--auto` from the prescribed `gh pr merge` invocation. Auto-merge is disabled in this repo's settings, so `gh pr merge --auto` exits 0 even when the actual merge fails (error goes to stderr), making it easy to miss the failure. New invocation: `gh pr merge <PR#> --squash --delete-branch`. Added a new "Verify before cleanup" paragraph requiring agents to confirm `state=MERGED` via `gh pr view --json state` before any cleanup step (especially the `gh api -X DELETE` worktree-workaround, which auto-closes PRs whose branch is deleted while still OPEN). Added a "Queue-collision preflight" pointer to the new script below. The D000008 regression guard in `scripts/test.sh` enforces all four pieces (the new invocation, the "do NOT use --auto" warning, the verify-MERGED guidance, and the preflight pointer).

- **`scripts/check-version-queue.sh`** (new). 70-line preflight script that scans open PRs targeting main via `gh pr list --state open --base main --limit 5 --json number,title`, extracts `v<X.Y.Z>` from title prefixes (anchored regex `^v[0-9]+\.[0-9]+\.[0-9]+` to avoid false-matching embedded versions in PR descriptions), and prints next-free VERSION slot. Run before `/ship` when multiple worktrees may be active to catch collisions earlier than `/land-and-deploy` Step 3.4 post-push drift detection. Workbench-side fallback for when gstack's `bin/gstack-next-version` queue util is offline in this repo (the typical state). Distinguishes active claims (`>= BASE_VERSION`) from stale claims (`< BASE_VERSION`, surfaced as a separate warning so the agent can investigate). Detects and surfaces duplicate-claim collisions (two open PRs claiming the same version). Skips with a one-line note on `gh` offline/unauthenticated; read-only, no mutations. Both human-readable and `--json` modes; exits 0 in all degraded scenarios so it never blocks `/ship`. Built with several bash gotchas in mind: `MODE="${1-}"` default-expansion prevents `set -u` crash on no-args invocation; `|| true` on the version-extract pipeline so `grep -oE` returning 1 (no matches — common when no open PRs claim versions) doesn't trip `set -o pipefail`; `to_array()` jq wrapper emits clean `[]` instead of `[""]` when the source variable is empty.

Rebumped from v2.0.5 after queue collision with PR #86's v2.0.5 (D000017 TODOS followups) which landed first — the 4th queue collision of the session and itself a live demonstration of exactly the failure mode this PR mitigates. Followup shellcheck disables added inline for `SC2086` (intentional word-splitting in `to_array()`) and `SC2016` (literal backticks inside regex pattern in `test.sh` D000008 guard) to satisfy CI's `shellcheck` step.

### Added

- **`scripts/check-version-queue.sh`** — workbench-side queue-collision preflight. Catches version-slot collisions before `/ship` runs the local-only bump.

### Changed

- **`CLAUDE.md` `## CI/CD merge convention`** — removed `--auto` from prescribed `gh pr merge` invocation; added "Verify before cleanup" + "Queue-collision preflight" paragraphs.
- **`scripts/test.sh` D000008 regression guard** — extended to cover the v2.0.6 convention: prescribed invocation without `--auto`, "do NOT add --auto" warning, verify-MERGED guidance, preflight pointer. Plus a new smoke-test block that runs `./scripts/check-version-queue.sh` in both default and `--json` modes and asserts exit 0 + valid JSON output.
- **`VERSION`** — 2.0.4 → 2.0.6 (PATCH; workbench tooling improvement, no skill behavior change; v2.0.5 burned by PR #86 landing first).


## [2.0.5] - 2026-05-11

Internal-planning TODO update only. Three followups from the D000017 (PR #84) auto-pipeline + ship pass logged to `TODOS.md` under `## Active work`. No skill behavior change, no script changes, no test changes — pure planning churn so the gaps surfaced during D000017 don't get lost.

### Added (TODOS.md)
- **P3** — `/CJ_personal-pipeline` Step 5.1 sensitive-surface regex misses `skills/*/scripts/`. New shell-script files created by `/CJ_implement-from-spec` (e.g. D000017's `skills/CJ_suggest/scripts/suggest.sh`) auto-approve through the pipeline without surfacing at Step 8.5; codex caught the trust-boundary hole at /ship Step 11 instead. Fix path: extend the regex to match `skills/[^/]+/scripts/[^/]+\.sh` and add a sensitive-surface table row.
- **P3** — `/CJ_personal-pipeline` Step 7 strict halt-on-ambiguous blocks defects. `E2E=ambiguous` from defect/task QA is structural (no E2E subagent dispatches for those types), not uncertain — should be treated as green when SMOKE+PHASE2_GATES are green. Fix path: type-aware halt logic reading `WORK_ITEM_TYPE` from tracker frontmatter.
- **P4** — `/CJ_implement-from-spec` should `chmod +x` shell scripts it creates. D000017 shipped `suggest.sh` at mode 644; /ship Step 9 caught it as [LOW] AUTO-FIX. Fix path: post-write `chmod +x` for `*.sh`/`*.bash`/shebang-bearing files in the implement skill's per-type write loop.


## [2.0.4] - 2026-05-10

Documentation sync. The `CJ_qa-work-item` and `CJ_implement-from-spec` skills have actually handled all four work-item types (user-story, defect, task, feature-via-child-AUQ) since v1.11.0 (F000012 / S000021), but their `skills-catalog.json` entries still described scope as "a CJ_personal-workflow user-story" — and `README.md` is auto-generated from the catalog, so the staleness propagated to the public Skills table. v2.0.4 syncs both catalog entries to match the (correct) SKILL.md frontmatter descriptions and regenerates `README.md`. Closes the open `qa-work-item + implement-from-spec catalog descriptions` P3 TODO that's been on the books since v1.13.0's post-ship audit. Pure doc churn — no skill behavior change, no script changes, no test changes. Caught in this session while running /document-release after the v1.16.0 + v2.0.0 + v2.0.1 + v2.0.2 chain landed; the CJ_ rename + auto-only refactor + eval cases + scaffold queue-collision fix had each touched their own surface but none touched these two skills' catalog entries to close the staleness gap. Rebumped from v2.0.3 after queue collision with PR #84's v2.0.3 (D000017 /CJ_suggest zsh crash fix) which landed first.

### Changed

- **`skills-catalog.json`** — synced `CJ_qa-work-item` and `CJ_implement-from-spec` `description` fields to the per-type dispatch wording from their respective SKILL.md frontmatter (was: "user-story" only; now: "user-story, defect, or task" / "user-story, defect, task, or feature").
- **`README.md`** — regenerated from `skills-catalog.json` to pick up the description updates.
- **`TODOS.md`** — marked `qa-work-item + implement-from-spec catalog descriptions` as DONE (closed in v2.0.4).
- **`VERSION`** — 2.0.3 → 2.0.4 (PATCH on top of v2.0.3; doc-only sync, no skill behavior change).

## [2.0.3] - 2026-05-10

### Fixed
- D000017 — `/CJ_suggest` no longer crashes with `read-only variable: status`
  on zsh-eval'd Bash-tool invocations. The ~250-line bash body in
  `skills/CJ_suggest/SKILL.md` moves to a new
  `skills/CJ_suggest/scripts/suggest.sh` with `#!/usr/bin/env bash` shebang
  and `set -euo pipefail`; SKILL.md routing collapses to a one-liner that
  dispatches to the deployed script. The shebang pins execution to bash
  regardless of harness shell, fixing the `status=$(...)` collision with
  zsh's read-only `$status` builtin. Rebumped from v2.0.1 after queue
  collisions with PR #81 (v2.0.1) and PR #82 (v2.0.2) which landed first.
- `sort | head -n 5` under `set -o pipefail` hardened with `|| true` for
  forward-compat against SIGPIPE on inputs large enough to outgrow the sort
  buffer.

### Changed
- `/CJ_suggest` routing resolves the script via
  `$HOME/.claude/skills/CJ_suggest/scripts/suggest.sh` (the deployed path)
  instead of `$(git rev-parse --show-toplevel)/skills/...`. Closes a
  trust-boundary hole flagged by codex adversarial review: any repo
  containing `skills/CJ_suggest/scripts/suggest.sh` would otherwise have run
  as the skill. Workbench developers iterating on the script must run
  `./scripts/skills-deploy install` to sync (existing convention).
- `skills-catalog.json` `CJ_suggest` entry's `files` array gains
  `skills/CJ_suggest/scripts/suggest.sh`.

## [2.0.2] - 2026-05-10

`/CJ_scaffold-work-item` Step 5 now scans open PRs for claimed work-item IDs in addition to local `work-items/` to prevent queue-collision IDs across parallel worktrees. The original Step 5 generated next ID from `find work-items -name "${PREFIX}*_TRACKER.md"` only, so two worktrees scaffolding from the same baseline (e.g. main at S000028) both grabbed S000029 — exactly what happened with PR #80 (`S000029_auto_default` under F000014) and closed PR #79 (`S000029_phase0_spike` under F000015) on 2026-05-09. Different parent dirs avoided filesystem collision but duplicated the global S000029 ID, and the second branch only learned about it at /land-and-deploy Step 3.4 post-push. New Step 5 caps the open-PR scan at 5 PRs (`gh pr list --state open --base main --limit 5` then `gh pr view --json files` per PR), treats any `${PREFIX}NNNNNN_*_TRACKER.md` path in an open PR as a claimed ID, and skip-silents if `gh` is offline/unauthenticated. Adds 2-5s to scaffold runtime when gh is available — acceptable cost given that scaffold runs once per work-item creation. Also fixes a latent octal-interpretation bug in arithmetic: `$((HIGHEST + 1))` interpreted leading-zero strings like `000029` as octal under bash, breaking on digits 8/9; new code uses `$((10#$HIGHEST + 1))` to force base-10. Verified under both bash and zsh. Limitation: only catches collisions where the parallel worktree has ALREADY pushed and opened a PR; two worktrees both scaffolding without push still collide, with /land-and-deploy Step 3.4 as the safety net. TODOS.md updated: P3 marked DONE, P2 (brief-mode redo) updated to use `CJ_*` skill names post-v2.0.0 rename, P4 dropped (out-of-workbench-scope — `/office-hours` is a gstack skill, not a workbench skill). Rebumped from v2.0.1 after queue collision with PR #81's v2.0.1 (S000024 V1 eval case coverage) which landed first.

### Fixed

- **`skills/CJ_scaffold-work-item/scaffold.md` Step 5: queue-collision detection at ID-pick time.** Open-PR scan added before `NEW_ID` generation; latent octal-interpretation bug in `$((HIGHEST + 1))` fixed via `10#` base-10 prefix.

### Changed

- **`VERSION`** — 2.0.1 → 2.0.2 (PATCH on top of v2.0.1; bug fix to scaffold ID-pick logic, no skill-surface change).

## [2.0.1] - 2026-05-10

S000024 — V1 eval case coverage for `/CJ_personal-workflow check`. Adds 5 new cases under `tests/eval/CJ_personal-workflow/` on top of S000023's runner: a multi-AC traceability case for the S000022 comma-split regression (`check-step18-faithful-comma-split`), a canonical valid-feature baseline that locks `overall: PASS` (`check-passing-feature`), an incomplete-frontmatter detection case (`check-missing-frontmatter`), a within-phase gate-row drift case distinct from S000023's missing-phase case (`check-lifecycle-drift`), and a Step 18 UNTESTED P0 detection case (`check-untested-p0`). The S000023 existing case (`check-flags-missing-lifecycle`) is also moved from `tests/eval/personal-workflow/` to `tests/eval/CJ_personal-workflow/` and its prompt updated to `/CJ_personal-workflow check`, fixing a v2.0.0 oversight where the rename touched skill directories but not the eval prompts. With the existing case, the harness now ships at 6 cases — within the SPEC AC-7 6–10 range and within the design's $1.50/run cost target ($0.99 observed for the full suite at xargs -P 4 in ~72s wall-clock pre-rebase; re-verification post-rebase recorded in the tracker journal). `bash scripts/eval.sh` auto-discovers cases under any directory beneath `tests/eval/` other than `lib/` and `schemas/`, so no runner changes are needed for the rename. Two findings worth carrying forward into V2 sit honestly in the work-item's Reviewer Concerns: (1) the system-health behavioral cases (`report-clean-system`, `report-with-issues`) are deferred — `tests/eval/lib/run-case.sh` doesn't override `$HOME` and `CJ_system-health` hard-codes `~/.claude/`, so a fixture under `tests/eval/CJ_system-health/<case>/fixture/` is invisible to the skill; the path forward is an opt-in `HOME=$tmpdir` runner flag. (2) The S000022 regression-detection signal is weaker than the SPEC anticipated — when Step 18's comma-split spec is reverted on a throwaway test branch, Claude still comma-splits from common sense and the case still PASSes; the deterministic regression coverage waits for V2's parser-extraction work in `scripts/check-helpers/parse-traceability.sh`. The harness is also flaky at ~33% for `check-untested-p0` based on 3 runs (LLM variance per the SPEC's pre-acknowledged Coverage Gap); nightly CI at S000025 will surface flake rates empirically.

### Added

- **`tests/eval/CJ_personal-workflow/check-step18-faithful-comma-split/`** — multi-AC traceability case (`AC-1, AC-2, AC-3` + `AC-1, AC-2`); schema asserts `all_p0_covered: true` so any failure to comma-split flips the verdict.
- **`tests/eval/CJ_personal-workflow/check-passing-feature/`** — canonical valid feature baseline using the existing `valid-feature-dir/` fixture content; schema requires `overall: PASS` with every sub-check PASS.
- **`tests/eval/CJ_personal-workflow/check-missing-frontmatter/`** — feature tracker missing 7 of 9 required frontmatter fields; schema requires `overall: FAIL` with `missing_fields: [≥3]`.
- **`tests/eval/CJ_personal-workflow/check-lifecycle-drift/`** — every Phase header present but only 5 lifecycle checkboxes vs template minimum of ~13; schema requires `missing_phases: []` (proves it's gate-drift, not phase-drift) and `below_minimum: true`.
- **`tests/eval/CJ_personal-workflow/check-untested-p0/`** — SPEC has P0 #1, #2; TEST-SPEC's `ac_set` only contains `AC-1`; schema requires `untested_p0_stories: [2]`. Complements `check-step18-faithful-comma-split` (which proves coverage detection works) by proving uncovered detection works.

### Changed

- **`tests/eval/personal-workflow/` → `tests/eval/CJ_personal-workflow/`** — directory renamed via `git mv` so blame follows. Includes the existing S000023 `check-flags-missing-lifecycle` case alongside the 5 new S000024 cases.
- **`tests/eval/CJ_personal-workflow/check-flags-missing-lifecycle/prompt.md`** — slash-command updated from `/personal-workflow check` to `/CJ_personal-workflow check` (closing a v2.0.0 oversight).
- **`tests/eval/README.md`** — V1 case index expanded to cover #2–#6; all paths updated from `personal-workflow` to `CJ_personal-workflow`; "Deferred to V2" subsection added documenting the system-health $HOME-faking blocker; empirical caveat for `check-step18-faithful-comma-split` recorded next to the case entry; observed authoring-cost band updated ($0.13–$0.35, median $0.16).
- **`work-items/features/ops/testing/F000013_eval_harness_v1/S000024_v1_case_coverage/S000024_TRACKER.md`** — Phase 1 working-branch gate transitioned (the `branch:` field had stale value `main` from prescaffold time); Phase 2 implementer-owned and qa-owned gates all transitioned green; AC checkboxes ticked for #1, #3, #4, #5, #7, #8 with system-health AC-6 marked DEFERRED; Reviewer Concerns RC1 (system-health $HOME blocker) and RC2 (S000022 regression-detection empirical weakness) added; AC paths updated to `CJ_personal-workflow`; journal extended with the full /implement-from-spec + /qa-work-item run plus the v2.0.0 rebase note.
- **`VERSION`** — 2.0.0 → 2.0.1 (PATCH on top of v2.0.0; continuation work on F000013 shipped in v1.12.0, mechanically aligned with the v2.0.0 rename).

## [2.0.0] - 2026-05-09

T000018 — Rename all 8 user-authored skills to use the `CJ_` prefix. Pure
disambiguation, zero functional change: `personal-workflow` → `CJ_personal-workflow`,
`system-health` → `CJ_system-health`, `scaffold-work-item` → `CJ_scaffold-work-item`,
`implement-from-spec` → `CJ_implement-from-spec`, `qa-work-item` → `CJ_qa-work-item`,
`personal-pipeline` → `CJ_personal-pipeline`, `suggest` → `CJ_suggest`,
`company-workflow` → `CJ_company-workflow`. Aligns with the existing
`anthropic-skills:*` and `KB_*` namespacing on the user's machine, ends the
slash-command collision risk with the catalog of upstream/native skills, and
unambiguously marks ownership.

**Breaking:** all slash-command names change. Old forms
(`/personal-workflow`, `/scaffold-work-item`, etc.) are gone post-deploy. After
pulling this release on each consuming machine, run
`./scripts/skills-deploy install --include-deprecated` to re-link the renamed
skills under `~/.claude/skills/CJ_*/` and the renamed templates under
`~/.claude/templates/CJ_personal-workflow/`. Existing in-flight `/personal-pipeline`
runs that were started under the old name continue unaffected (the agent already
holds its skill assets in context); next invocation requires the `CJ_*` form.

### Changed

- **`skills-catalog.json`** — all 8 user-authored entries renamed (`name`,
  `files`, `templates`, `templates_source`, `depends.skills[]`). Major version
  bump on each touched skill (breaking change). `templates` entry forms
  retain `{skill}/foo.md` per-skill prefix convention; only the `{skill}/`
  prefix changed.
- **Directory layout** — `skills/{name}/` → `skills/CJ_{name}/` (7 active /
  experimental); `deprecated/company-workflow/` → `deprecated/CJ_company-workflow/`
  (1 deprecated). `templates/personal-workflow/` → `templates/CJ_personal-workflow/`;
  `deprecated/CJ_company-workflow/templates/` retained at new parent path. All
  via `git mv` so blame history follows.
- **`work-copilot/` byte-mirror** — internal references updated to track
  upstream rename. `validate.sh` Error check 10 (`MIRROR_SPECS`) stays green:
  byte-identity preserved with the renamed `deprecated/CJ_company-workflow/`
  source.
- **Scripts hardcoding skill names** — `validate.sh` `MIRROR_SPECS` array,
  `scripts/test.sh`, `scripts/test-deploy.sh`, `scripts/skills-deploy`,
  `scripts/eval.sh`, `scripts/check-gates-update.sh` — all updated to the
  `CJ_*` names.
- **`CLAUDE.md` skill-routing block** — 8 slash-command names updated so the
  router maps natural-language requests to the renamed skills.
- **`README.md`** — regenerated from the updated catalog.
- **`VERSION`** — 1.15.1 → 2.0.0 (MAJOR bump for breaking rename).

## [1.16.0] - 2026-05-09

S000029 — `/personal-pipeline` polarity flip. Auto-decision becomes the only mode; the `--auto` flag from v1.14.0 is now a silent no-op (and `--manual` is symmetrically accepted-and-discarded for forgiveness). This change explicitly **reverses S000028 premise 1** ("preserve manual as the default; auto is opt-in"): lived experience after v1.14.0 confirmed the manual path is dead-by-policy — nothing outside personal habit recommended it, and the `/autoplan` precedent (single mode, no toggle) had already proved that "two ways to do the same thing" UX is unnecessary for auto-decision skills. The structural deletion is ~40-50 lines of conditional gating in `pipeline.md` (`$AUTO_MODE` references, "Skip if `$AUTO_MODE=false`" guards, "Manual mode: …" / "Auto mode (Step N): …" parity prose at 7 sites) plus the entire 50-line `## Auto Mode` section in `SKILL.md`. The Auto Mode Overlay's substance — 6 principles, decision classification (Mechanical / Taste / User-Challenge), `$DECISION_LOG` schema, Step 8.5 final approval gate logic — is preserved by promotion (overlay → main flow), not deletion. A future revert would re-wrap in conditionals (~1 hour) rather than re-author. Telemetry `mode` field stays in v1.16.0 emitting `"auto"` literal; field deletion deferred to v1.17.0 (TODOS.md follow-up) so external JSONL readers get one release of grace. Sub-skills (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`) remain individually callable as the manual escape hatch.

### Changed

- **`/personal-pipeline`** — auto-decision mode is now the only mode. The orchestrator runs through Steps 2/4/5.2/5.3/6/8 with auto-classification (Mechanical / Taste / User-Challenge-Approved / User-Challenge-Halt-at-Gate); Taste + User-Challenge-Approved decisions surface at Step 8.5's final approval gate; Halt-at-Gate User Challenges halt at the originating step. Result envelope unchanged: pipeline runs through, Step 8.5 surfaces decisions, sub-skills callable individually.
- **`skills/personal-pipeline/pipeline.md`** — `$AUTO_MODE` variable fully removed (all references AND assignments). Step 1 flag parser collapsed: `case --auto|--manual) ;;  # accept and discard for backwards compat` (was: `--auto) AUTO_MODE=true ;;` plus `AUTO_MODE=false` init). Auto Mode Overlay framing dropped ("Active when `$AUTO_MODE=true`. When inactive, this entire section is a no-op" → "The orchestrator runs in auto-decision mode unconditionally."). Per-step "Manual mode: … / Auto mode (Step N branch): …" pairs collapsed into single unconditional paragraphs at all 7 sites (lines 224, 255, 310, 372, 409, 434, 485 of the v1.15.1 baseline). Step 8.5 `Skip if $AUTO_MODE=false` guard deleted (Step 8.5 always fires subject to existing empty-state short-circuit and two-halt-categories carve-out). Telemetry `_MODE=$([ "$AUTO_MODE" = "true" ] && echo "auto" || echo "manual")` replaced with `_MODE="auto"` literal. Closing prose reworded as cohesive single-mode narration ("in both modes" framing dropped).
- **`skills/personal-pipeline/SKILL.md`** — `## Auto Mode` section (~50 lines) deleted. Usage code-fence reads `/personal-pipeline <design-doc-path>` only (no `[--auto]`). Dual-example block collapsed to a single example. "Optional `--auto` flag opts into auto-decision mode" line removed. "`--auto`-equivalent" reworded to "auto-equivalent" in the Phase 2 overview bullet.
- **`skills-catalog.json`** — `personal-pipeline` `description` field updated to drop "auto vs manual" duality and reflect single-mode behavior.
- **`README.md`** — regenerated from the updated catalog.
- **`VERSION`** — 1.15.1 → 1.16.0 (MINOR bump: removed flag is accept-and-discard so zero break for existing invocations; default behavior changed but the result envelope is preserved; mirrors v1.13.x → v1.14.x precedent).
- **`TODOS.md`** — added v1.17.0 follow-up entry: drop telemetry `mode` field from `~/.gstack/analytics/personal-pipeline.jsonl` JSONL writes (always `auto` literal in v1.16.0; no consumer needs the field). P4/S sizing.

## [1.15.1] - 2026-05-10

Pre-existing CI flake fix. Two consecutive releases (PR #74 / v1.13.1 and PR #75 / v1.14.0) shipped under `--admin` overrides because seven `echo "$_t11_out" | grep -qF "needle"` call sites in `scripts/test.sh` (lines 1879/1893/1907/1918/1929/1950/1970, T000011 + autoplan D5 blocks) raced against `set -o pipefail` (inherited from `lib.sh`) on GitHub Actions runners — `grep -qF` matches early and exits, `echo`'s next write hits a closed pipe, SIGPIPE flips the pipeline non-zero, the enclosing `if` becomes false, and `fail_test` triggers spuriously. Locally the race window is too tight to reproduce; in CI it tripped 2-3 times per run. Replaced each pipeline with a SIGPIPE-free `case "$_t11_out" in *"needle"*) true;; *) false;; esac` form. No behavioral change to the test assertions; same needles, same gates, same passing path. Out-of-scope sites at lines 1700/1713/1732/1741/1816/1835 use the same shape but are in different test blocks (S000010 + autoplan G3) — left as-is, same fix can be applied if they ever flake. Rebumped from v1.14.1 after queue collision with PR #76's v1.15.0 (`/suggest` skill).

### Fixed

- **`scripts/test.sh` SIGPIPE race in T000011 + autoplan D5 test blocks** — 7 `echo "$_t11_out" | grep -qF "needle"` call sites converted to `case "$_t11_out" in *"needle"*) true;; *) false;; esac`. Eliminates the spurious CI failures that forced `--admin` overrides on the last two ships.

### Changed

- **`VERSION`** — 1.15.0 → 1.15.1 (PATCH bump for CI-only fix; no user-facing behavior change).

## [1.15.0] - 2026-05-10

T000017 — `/suggest` skill. New slash command that prints a top-5 ranked "what's next?" markdown table by reading `TODOS.md` (the candidate set) and joining against `work-items/**/*_TRACKER.md` YAML frontmatter for live `status` / `blocked_by` / `updated`. Score = priority weight (P1=4..P4=1) + size inverse (S=3..L=1) + unblocked bonus (+2) − recency penalty (1 per 14d since `updated`); tie-break alphabetic by title. Pure bash + standard Unix tools (find, awk, grep, sed, sort, BSD `date -j`); single-file SKILL.md, no script extraction in v1, no new runtime deps. macOS-targeted with explicit `uname` guard. Read-only and idempotent. Status: experimental — promote to `active` after one week of soak. Defensive hardening from ship-time adversarial review: pipe-in-title parsing rewritten to three separate sed captures (the single-sed `|`-delimited form would have corrupted titles containing `|` and broken markdown table rendering); active-section band-pass tightened to reset on any `## ` heading other than `## Active work` (was leaking if a future `## Triage`-style section landed between Active and Deferred); `find` now skips hidden subdirs; explicit not-in-git-repo error replaces silent fallback to `pwd`. Rebumped from v1.14.0 after `/ship` queue collision with PR #75's v1.14.0 (`/personal-pipeline --auto`).

## [1.14.0] - 2026-05-10

S000028 — `/personal-pipeline --auto` flag adds autoplan-style auto-decision mode to the F000014 orchestrator. One keystroke runs scaffold/implement/QA end-to-end with intermediate AUQs auto-decided by 6 principles; close calls surface at one final approval gate (Step 8.5) instead of inline across the run. Manual mode (no flag) stays byte-identical to v1.13.1 — every auto-mode behavior is gated on `$AUTO_MODE=true`. The 6 principles port `/autoplan`'s framework with one substitution: P6 becomes "bias toward halt-on-doubt" instead of "bias toward action," reflecting the higher blast radius of code-mutating pipeline vs plan-review. User Challenge classification splits into Approve-with-surfacing (sensitive-surface AUQs at Step 5.2 — auto-pick approve forward, surface at 8.5 for confirmation) and Halt-at-Gate (gate-red at Steps 5.3/6/8 — halt now, log for audit). Halt-regardless paths (boundary check red, subagent crash) skip the decision log entirely; Halt-at-Gate User Challenges DO log a `user_challenge_halt` line for audit before halting. Step 8.5 final approval gate fires only on the green-or-recoverable path with empty-state short-circuit (no Taste + no User-Challenge-Approved → silent `[auto-pipeline-clean]` to tracker). Reject at 8.5 is "Abort + show what to revert" (per-decision files-affected list grouped by gate; user runs `git restore` manually) — no programmatic rollback in v1. Telemetry gains `mode: auto|manual` field; sunset trip-wire counts both modes pooled. Decision log is a single shared file at `~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl`, run_id-tagged.

### Added

- **`/personal-pipeline --auto` flag** — new mode flag on the F000014 orchestrator. Auto-decides intermediate AUQs at Steps 2/4/5.2/5.3/6/8 using 6 principles + decision classification (Mechanical / Taste / User-Challenge-Approved / User-Challenge-Halt). Default behavior (no flag) is unchanged.
- **Auto Mode Overlay section** in `skills/personal-pipeline/pipeline.md` — the 6 principles, classification rules, halt categories with distinct logging contracts, `$DECISION_LOG` schema with jq -nc emit example. Single discoverable section at the top.
- **Step 8.5 Final Approval Gate** — fires only when `$AUTO_MODE=true` and pipeline reaches it (no Halt-at-Gate fired). Single AUQ in gstack format with two options: Approve all (commit decisions, set `end_state=green`) or Abort + show what to revert (per-decision files-affected list grouped by gate; pipeline state preserved for manual `git restore`). Empty-state short-circuit writes `[auto-pipeline-clean]` to tracker and skips the AUQ when no Taste/User-Challenge-Approved decisions accumulated.
- **Per-step auto-mode callouts** at Steps 2b/2c/4/5.2/5.3/6/8 in `pipeline.md` — 7 inline callouts cross-referencing the Auto Mode Overlay's classification table.
- **Decision log** — new artifact at `~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl`, single shared file, run_id-tagged per line. Schema: `{run_id, step, gate_id, classification, decision, recommendation, reasoning, context_missing, files_affected, ts}`.

### Changed

- **`skills/personal-pipeline/SKILL.md`** — Usage section gains `[--auto]` syntax; new `## Auto Mode` subsection (~50 lines) summarizes the 6 principles, classification, halt-regardless contract, and Step 8.5 with pointer to pipeline.md's overlay section.
- **`skills/personal-pipeline/pipeline.md`** — Step 1 parses `--auto` flag at the front of `$@`; sets `$AUTO_MODE=true|false`; initializes `$DECISION_LOG` constant path. Step 9.1 telemetry adds `mode: auto|manual` field. Decision Gates summary section names Step 8.5. ~250 lines added; manual code path remains byte-identical (every new behavior gated on `$AUTO_MODE=true`).
- **`skills-catalog.json`** — `personal-pipeline` description bumped to mention `--auto` flag and `/autoplan` parity.
- **`README.md`** — regenerated from the updated catalog.
- **`VERSION`** — 1.13.1 → 1.14.0 (MINOR bump for new user-facing capability).

## [1.13.1] - 2026-05-09

T000016 — repo-local gstack output via project-slug symlink. Two scripts (setup + teardown) redirect `~/.gstack/projects/<slug>/` into `<main-repo>/.gstack/`, so gstack design docs, plans, reviews, and checkpoints commit alongside code instead of staying machine-local. The `.gitignore` flips from blanket `.gstack/` ignore to a specific machine-local denylist (sessions, analytics, learnings, .gbrain*, etc.) — designs and plans now track in git. README + CLAUDE.md document the per-machine setup and the parallel `.gstack/` (lateral) vs `work-items/` (structured) design surfaces. Defensive hardening from ship-time adversarial review: `eval "$(gstack-slug)"` replaced with regex extraction (no arbitrary code execution), and rsync gets `--backup --suffix=.predeploy.bak` so a misjudged `--force` is recoverable.

### Added

- **`scripts/setup-gstack-symlink.sh`** — per-machine symlink wiring. rsyncs existing `~/.gstack/projects/<slug>/` into `<main-repo>/.gstack/`, backs up the original (`$SRC.bak.<timestamp>`), replaces the source dir with a symlink. Idempotent; `--force` for re-pointing existing symlinks or merging non-empty targets. Resolves the MAIN repo via `git rev-parse --git-common-dir` so it works from worktrees too. SLUG extracted via regex (no `eval`); `set -euo pipefail`; shellcheck-clean.
- **`scripts/teardown-gstack-symlink.sh`** — reversal. Removes the symlink, rsyncs DEST contents back into the home-dir SRC. Refuses if the symlink target doesn't match the expected `<main-repo>/.gstack/` (no blind reverts).
- **`work-items/tasks/ops/T000016_repo_local_gstack_output/`** — task tracker + 12-case regression test-plan covering fresh setup, idempotent re-runs, `--force` semantics, teardown safety, write integration, `.gitignore` correctness, `gstack-slug` failure modes, and worktree resolution. Verification is manual (scripts modify the user's `$HOME/.gstack/`).

### Changed

- **`.gitignore`** — removed blanket `.gstack/` line; added 8 specific machine-local patterns under `.gstack/` (`sessions/`, `analytics/`, `learnings.jsonl`, `timeline.jsonl`, `.gbrain*`, `.brain-*`, `.pending-*`, `tmp/`). Designs, ceo-plans, reviews, and checkpoints under `.gstack/` now track in git by default.
- **`scripts/generate-readme.sh`** — new `## gstack plans live in this repo` section (between Installation and Scripts) + 2 new rows in the Scripts table for `setup-gstack-symlink.sh` and `teardown-gstack-symlink.sh`.
- **`README.md`** — regenerated from the updated generator (same delta as `scripts/generate-readme.sh`).
- **`CLAUDE.md`** — new `### .gstack/ vs work-items/ (parallel design surfaces)` subsection under Conventions, documenting that gstack output (lateral/exploratory) and `work-items/` (structured per-feature) are parallel surfaces, not merged.
- **`VERSION`** — 1.13.0 → 1.13.1 (PATCH bump: operational tooling, no new feature surface; rebumped from 1.12.1 to 1.13.1 after `/ship` queue collision with PR #73's v1.13.0).

## [1.13.0] - 2026-05-09

F000014 `/personal-pipeline` orchestrator — single-keystroke wrapper over the three pipeline skills (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`). Closes the deferred TODOS.md:20 entry from the 2026-05-08 office-hours session. Each phase runs in a fresh-context Agent subagent with file-only handoff between subagents (orchestrator-as-broker). Independent inter-step quality gates (pre-scaffold idempotency check with 4-branch recovery, post-scaffold structural check + footer-write-back confirm, post-implement `/personal-workflow check` + `validate.sh`, post-QA tracker journal parse). AUQs are pre-collected at the orchestrator BEFORE Phase 2 dispatch — S000026 spike found `AskUserQuestion` is not reachable inside Agent subagents in Claude Code 2.1.91, so the original "subagent reports `AUQ_NEEDED`" pattern was supplanted. RESULT-line parsing is lenient (strips markdown blockquote prefixes and code fences) — spike trials hit RESULT content reliably but formatted it inconsistently 60% of the time. Sunset criterion baked in: telemetry to `~/.gstack/analytics/personal-pipeline.jsonl`; on the 6th invocation (then every 5 thereafter), the orchestrator AUQs keep/delete based on a mechanical trip-wire (≥3 of 5 `halted_at_gate` recommends delete). PHILOSOPHY.md:11/:61 anti-orchestration warning honored: this is structural plumbing (Agent dispatch + file-only handoff), not prose composition.

Bootstrap validation: ran `/personal-pipeline` end-to-end on a synthetic design doc for the Fork-aware update detection P3 entry (TODOS.md:8). Full 9-step pipeline ran green; T000015 task scaffolded, implemented, QA-passed; `scripts/skills-update-check` modified with a fork-aware `origin` → `upstream` fallback.

### Added

- **`/personal-pipeline`** — new LLM-driven orchestrator skill. Status: `experimental`. Depends on `scaffold-work-item`, `implement-from-spec`, `qa-work-item`, `personal-workflow`. Two files: `skills/personal-pipeline/SKILL.md` (entry: preamble, 2-level path resolution + upstream-skill verification, usage, error-handling table, sunset section) + `skills/personal-pipeline/pipeline.md` (9-step orchestration: input validation, pre-scaffold idempotency check with 4 branches, Phase 1 scaffold-runner subagent, post-scaffold gate, Phase 2 SPEC pre-scan + AUQ pre-collection + threaded implement-runner dispatch, post-implement gate, Phase 3 qa-runner subagent, post-QA gate, telemetry write + sunset checkpoint). Lenient `parse_result()` bash function strips `>` blockquote prefixes and ` ``` ` / `~~~` code fences before grep. Sensitive-surface pre-scan regex covers catalog, manifests, templates, validators, git hooks. ~636 lines total skill markdown (under 800-line budget).
- **`skills/personal-pipeline/fixtures/`** — 5 README-stub fixtures: index README, `example-design-doc/` (happy path), `regression-pre-scaffold-idempotency/` (Step 2 branch (a) reuse), `regression-partial-write-halt/` (Step 2 branch (c) crash recovery), `regression-broken-validate/` (Step 6 post-implement halt). Each documents setup steps + expected outcome; fully-self-contained test artifacts deferred to v2.
- **`tests/spike/subagent-capabilities/`** — S000026 throwaway probes used to verify F000014 design assumptions before pipeline.md was written. `probe-auq.sh` (operator-driven; prints a paste-into-fresh-session prompt + verdict rubric, `--try-headless` flag for secondary `claude -p` signal) + `probe-result.sh` (5-trial automated; lenient last-line check; raw outputs preserved under `raw-outputs/`) + `findings.md` (verdicts: AUQ_BUBBLES=no SUBCLASS=error, RESULT_LINE_HITS=2/5; recommended action: both redesigns).
- **F000014 work-item tree** at `work-items/features/personal-workflow/F000014_personal_pipeline_orchestrator/` with TRACKER, DESIGN (Big decisions table extended with rows 2.1+2.2 reflecting spike-driven Phase 2 + parser overrides), ROADMAP, plus user-stories S000026 (spike) and S000027 (skill implementation). All Phase 2 green via /qa-work-item.
- **T000015 work-item tree** at `work-items/tasks/ops/T000015_fork_aware_update_detection/` (TRACKER + test-plan). Task type, scaffolded as part of the bootstrap pipeline run.

### Changed

- **`scripts/skills-update-check`** — fork-aware remote resolution: tries `origin/main` first, falls back to `upstream/main` if origin is missing OR origin's fetch fails (dead URL, deleted/renamed branch, no main on that remote). Silent no-op if neither remote yields a VERSION. Closes TODOS.md:8. Caught and corrected during the orchestrator's own pre-landing review: the original "config-only" gate (`git config --get` triggering before fetch) couldn't fall through on dead origins, so the loop now drives off fetch success instead of remote-configured-ness.
- **`skills-catalog.json`** — appended one entry for `personal-pipeline` (status: `experimental`, depends.skills: scaffold-work-item + implement-from-spec + qa-work-item + personal-workflow). 8 active skills total.

### Fixed

- Adversarial review caught five real bugs in pipeline.md before the first commit landed: (1) `find -o` POSIX precedence — Step 5.1's SPEC-locator was missing parens around the alternation, so it ignored `-maxdepth 1` and pulled SPEC.md from arbitrarily-nested subdirs (e.g. a child user-story's SPEC instead of the parent's). Fixed with explicit `\( ... -o ... \)` grouping. (2) Telemetry JSON breakage on paths containing quotes/special chars — Step 9.1 used raw shell interpolation, now uses `jq -nc --arg` with a sanitized-echo fallback for jq-less environments. (3) Sunset checkpoint AUQ recurrence — gate previously fired on every run from invocation 6 onward; now fires once at 6, then every 5 (`(N - 6) % 5 == 0`). (4) Step 2 branch (c) work-items glob assumed cwd=repo-root — fixed with `git rev-parse --show-toplevel` + `find ... -name TRACKER.md` so the partial-write-recovery branch fires regardless of invocation directory. (5) Inverted fork-aware fallback semantics in `skills-update-check` (see Changed above) — would have let a dead origin remote silently freeze updates indefinitely.

## [1.12.0] - 2026-05-09

F000013 behavioral eval harness V1 — first slice (S000023): a bash + jq runner that spawns the real `claude` CLI headless against scratch worktrees, validates structured JSON output via `--json-schema` enforcement, and runs cases under `xargs -P 4`. Spike 0 resolved live against the workbench: direct `--plugin-dir` skill loading works, inline `--json-schema` syntax works, schema mismatch exit-fails (no need for ajv-cli post-validation). First passing case `check-flags-missing-lifecycle` lands at $0.10/15s with the model output matching fixture truth exactly. Security hardening from /ship review baked in. Remaining V1 stories (S000024 case coverage + S000025 nightly CI) scaffolded as follow-up PRs.

### Added

- **`scripts/eval.sh`** — top-level eval runner. Discovers cases under `tests/eval/<skill>/<case>/`, accepts positional `<skill> <case>` filter args, dispatches via `xargs -P 4`, sums per-case cost from PASS/FAIL output, warns on aggregate `EVAL_TOTAL_BUDGET_USD` overrun (default $10). Whitespace-guards skill + case path names so the xargs -L 1 splitting can't silently mis-route cases under TMPDIR-with-spaces. shellcheck-clean.
- **`tests/eval/lib/run-case.sh`** — per-case execution. Seeds fixture into a fresh tmpdir via seed-fixture.sh, spawns `claude -p` with `--plugin-dir <repo>/skills` (direct, post-Spike-0 — no fake-`$HOME` needed), parses model output via `jq -r '.result | fromjson'`, lints schemas for external `$ref` (only internal `#/...` refs allowed), unsets common CI/dev secrets (GITHUB_TOKEN, NPM_TOKEN, AWS_*, OPENAI_API_KEY, etc.) before invoking the subprocess so the model can't exfiltrate them via the `Bash` tool. Per-case `--max-budget-usd 0.50` cap. Trap on EXIT/INT/TERM cleans tmpdir on Ctrl-C.
- **`tests/eval/lib/seed-fixture.sh`** — fixture seeder. Rejects fixtures containing symlinks (would otherwise let a malicious fixture symlink to `~/.ssh/` and have the model `cat` it). Uses `cp -RP` to preserve symlinks as symlinks (belt-and-braces). Surfaces git init/add/commit failures loudly instead of silently corrupting the eval state.
- **`tests/eval/README.md`** — case-authoring guide, local invocation, debug tips. Includes the empirical Spike 0 findings (S0.0 `--bare` requires ANTHROPIC_API_KEY, S0.1 direct `--plugin-dir` works, S0.2 inline JSON schema syntax works, S0.3 schema mismatch exit-fails after retry storm, observed cost ~$0.10–$0.15 per case, projected V1 cost ≤$1.50/run for 6–10 cases).
- **`tests/eval/personal-workflow/check-flags-missing-lifecycle/`** — first eval case. `prompt.md` (explicit `/personal-workflow check` invocation + JSON-only output contract), `fixture/work-items/tasks/T000099_broken/T000099_TRACKER.md` (deliberately missing Phase 3 lifecycle gates), `expected.schema.json` (asserts overall=FAIL, missing_phases includes "Ship", checkbox_count=7, below_minimum=true). Verified end-to-end PASS at $0.10/15s.
- **`work-items/features/ops/testing/F000013_eval_harness_v1/`** — work-item scaffold for the feature + 3 user stories: S000023 (this PR — spike + skeleton + first case, all gates green), S000024 (V1 case coverage — personal-workflow + system-health cases, blocked on S000023), S000025 (nightly CI workflow + first run validation + TODOS.md update, blocked on S000024). Sub-grouping under `ops/testing/` matches the existing `ops/deprecation/` precedent.

### Changed

- **`VERSION`** — 1.11.1 → 1.12.0 (MINOR bump for new feature + new module + new top-level script).

## [1.11.1] - 2026-05-09

S000022 (F000012 pipeline parity, second of two children) — closes TODOS.md #5: `/personal-workflow check` Step 18 traceability parser missed multi-AC cells like `AC-1, AC-2, AC-3`. The bug existed in prose ambiguity, not in code (`check.md` is LLM-interpreted spec); the fix is tightening the prose with explicit comma-split + trim + filter ordering, plus two worked examples illustrating the rule. F000012 now fully shipped.

### Fixed

- **`skills/personal-workflow/check.md` Step 18 sub-step 3** — replaced the ambiguous "extract all values from the AC column" instruction with explicit "split the cell on comma and trim whitespace from each token; each resulting token contributes one value." Multi-AC cells in real TEST-SPECs (S000018:24 `AC-1, AC-2, AC-3`, S000018:26 `AC-5, AC-6`, S000019:32 `AC-2, AC-4`) now correctly contribute each AC individually to `ac_set` instead of being treated as one literal string. Eliminates spurious `[UNTESTED] P0 story #N` findings on multi-AC P0 stories.

### Added

- **Worked examples in Step 18** — two inline blocks showing the parser's data flow. The first walks through a multi-AC cell (`AC-1, AC-2, AC-3`) → split → trim → filter → set add. The second shows the rare-but-real mixed case (`AC-{n}, AC-1`) where comma-split + placeholder filter together drop the placeholder while keeping the real AC. The second example pins the split-before-filter ordering visually so future readers / LLMs don't accidentally invert it.
- **Contract paragraph at the end of Step 18 sub-step 3** — names the durable load-bearing rule: "a cell can mix real ACs with leftover placeholders during partial scaffolding, and the parser must extract the real ACs without being poisoned by the placeholder." Future modifications to Step 18 should preserve this contract.

### Changed

- **TODOS.md** — closed #5 (Step 18 comma-split fix, P3/S). #6 (F000010 pipeline gap) was marked PARTIAL in v1.11.0 and remains PARTIAL — the per-type generalization shipped, the live defect-path E2E walkthrough is still deferred to first real defect post-merge.

## [1.11.0] - 2026-05-08

F000012 pipeline parity — generalize `/implement-from-spec` and `/qa-work-item` to accept all 4 work-item types (user-story, defect, task, feature) instead of hard-failing on non-user-story input. Closes the partial pipeline gap surfaced during F000011's dogfood (TODOS.md #6 partial: option 1 implemented). Existing user-story flows preserved identically — verified via structural inspection and S000021's QA pass. **What's NOT in this PR:** S000022 (TODOS.md #5 Step 18 traceability comma-split parser fix) is scaffolded but not yet implemented; will ship as a separate PR. **Defect-path live integration test** (manual smoke S1 in S000021's TEST-SPEC) deferred to first real defect work-item flowing through the pipeline post-merge.

### Added

- **Per-type input dispatch in `/implement-from-spec`** — reads `type:` from `_TRACKER.md` frontmatter and routes to per-type input artifacts: user-story → SPEC + DESIGN (unchanged); defect → RCA + test-plan; task → TRACKER + test-plan; feature → AskUserQuestion to pick a child work-item (existing path preserved). Added a per-type dispatch table in `skills/implement-from-spec/SKILL.md`'s Overview + concrete examples in Usage. Implementation in `skills/implement-from-spec/implement.md` Step 1 (type dispatch + per-type artifact resolution), Step 4 (per-type read context with sub-steps for user-story/defect/task), Step 5 (per-type input gap check), Step 6 (per-type plan source: SPEC's Components Affected for user-stories, RCA's Affected Components for defects, TRACKER's Files for tasks).
- **Per-type test-row dispatch in `/qa-work-item`** — same shape as implement-from-spec. user-story → TEST-SPEC.md (`## Smoke Tests` + `## E2E Tests` with subagent dispatch, unchanged); defect / task → test-plan.md (`## Regression Test Cases` table treated as smoke-equivalent in v1; no E2E subagent dispatch); feature → AskUserQuestion to pick a child. Implementation in `skills/qa-work-item/qa.md` Step 1 (type dispatch), Step 2 (per-type Phase 2 implementer-owned gate check, including commit-gate enforcement for defects/tasks), Step 4 (per-type test-row reading), Step 7 (user-story-only E2E subagent guard).
- **Per-type Phase 2 gate transitions** — `/implement-from-spec` now marks the type-appropriate Phase 2 implementer-owned gates: user-story (Todos + Files), defect (RCA doc updated + Todos), task (Todos + Files). Commit gates (`Fix committed` for defects, `Core changes committed` for tasks) remain user/`/ship`-owned — the skill writes files but doesn't commit. Documented in `implement.md`'s "Phase 2 Gate Ownership (per type)" section. `/qa-work-item` parallel: user-story marks AC-verified + Smoke-pass; defect / task records `[qa-pass]` journal entry only (no qa-owned Phase 2 gates per template; verification lands at Phase 3 `Test-plan verified` gate).
- **`skills/implement-from-spec/fixtures/example-defect/`** — synthetic defect fixture (parallel to existing `example-user-story/`) for manual testing of the new defect-path code. Files: D888000_TRACKER.md (defect frontmatter, Phase 1 green, Phase 2 implementer-owned gates unchecked), D888000_RCA.md (Symptom + Root Cause + Fix Description + Affected Components for the synthetic "missing greeting file" bug), D888000_test-plan.md (Regression Test Cases asserting `output/fixed.txt` content), output/.gitkeep (empty default state). Updated `fixtures/README.md` with per-type fixture table + dogfood walkthrough for the defect path.
- **`work-items/features/personal-workflow/F000012_pipeline_parity/`** — feature work-item bundling S000021 (per-type pipeline branching, this PR) and S000022 (Step 18 comma-split fix, deferred to next PR). Full F000012 scaffold: TRACKER, DESIGN (with per-concern decomposition), ROADMAP (decomposition + delivery timeline + dependency graph). S000021 Phase 2 fully green (Todos + Files implementer-owned; AC-verified + Smoke-pass qa-owned). S000022 scaffolded only — Phase 1 green, Phase 2 unchecked.

### Changed

- **`skills/implement-from-spec/SKILL.md`** — description, overview, usage, error table updated for multi-type acceptance. Removed the "Wrong type (not user-story)" hard-fail row from the error-handling table; replaced with "Frontmatter type missing or malformed" + "Unknown type" + "Required input artifact missing" rows. Variable name standardized to `WORK_ITEM_DIR` (alias `USER_STORY_DIR` documented for backwards compat in any code paths still referencing the old name).
- **`skills/qa-work-item/SKILL.md`** — parallel updates to implement-from-spec/SKILL.md. Same removal of "Wrong type" hard-fail; same per-type dispatch documented in Overview; same usage examples for all 4 types.
- **`skills/qa-work-item/qa.md`** — Step 2 now requires the commit gate (`Fix committed` for defects, `Core changes committed` for tasks) to be CHECKED at start, in addition to implementer-owned content gates. This enforces the "implementer writes files, ship/user commits" contract — running QA on uncommitted defect/task work would produce spurious green from stale on-disk state. Step 9's [qa-pass] journal entry now records the work-item type explicitly (e.g., `[qa-pass] {ID} (defect): green smoke from test-plan rows...`).

F000011 Phase 3 lifecycle-gate auto-update — closes the P2/M TODO observed across every PR shipped today (S000017/S000019/S000018/D000016 all left Phase 3 gates blank). Adds `/personal-workflow check --update` flag plus a git post-merge hook trigger. After every successful ship + merge + `git pull main`, the touched work-item's Phase 3 gates auto-mark from external state (`gh pr view`, `gh pr checks`, child tracker recursion). `E2E walked manually` is explicit-excluded — never auto-marked, since human verification has no external signal. **First end-to-end pipeline dogfood:** F000011 is the first work-item to flow through the full F000010 chain (`/office-hours` → `/scaffold-work-item` → `/implement-from-spec` → `/qa-work-item` → `/ship`). Process bugs surfaced and were fixed inline (TEST-SPEC drift after refactor, post-merge hook composition with existing D000013 hook).

### Added

- **`/personal-workflow check --update <work-item-dir>`** — new flag on the existing `/personal-workflow check` skill. Runs structural validation (existing behavior), then infers Phase 3 lifecycle-gate state from external sources and writes `[x]` to the inferable gates. Idempotent + additive only (never downgrades `[x]` → `[ ]`). Skips `E2E walked manually` entirely (human-driven, no signal). Appends merged PR link to `## PRs` section + `[gates-update]` journal entry summarizing changes. Implementation in `skills/personal-workflow/check.md` Step 13.5; delegates to `scripts/check-gates-update.sh` so the same logic powers both the skill and the post-merge hook.
- **`scripts/check-gates-update.sh`** (NEW, ~250 lines) — Phase 3 lifecycle-gate inference engine in plain bash. Resolves the work-item PR via `gh pr list --search "<work-item-id>"` (falling back to `--head <branch>`). For each Phase 3 gate label, reads the corresponding external signal: `/ship — PR created` (PR exists), `/land-and-deploy — merged + deployed` (PR state == MERGED), `Smoke tests pass in CI` (`gh pr checks` no fail/pending), `All children shipped` (recursive: every direct child's `/land-and-deploy` is `[x]`), `/document-release` (heuristic: `docs:` commit on main between PR's merge commit and `origin/main` HEAD). Operates ONLY inside the Phase 3 block of the tracker (avoids accidentally marking Phase 1 / Phase 2 gates that share label substrings like "Smoke tests pass"). Best-effort contract: prints warnings on partial failure (e.g., `gh` offline) but exits 0 unless the input is fundamentally invalid.
- **Post-merge hook gates-update integration** — `scripts/setup-hooks.sh` extends the existing inline post-merge HOOK heredoc (originally D000013 — re-deploys skills/templates on relevant pulls) to also call `scripts/check-gates-update.sh` on every work-item dir touched by the incoming pull. Fires only on `main`; silently no-ops on feature branches. Best-effort: failures print warnings but exit 0 to never block git operations. Composes cleanly with the existing D000013 re-deploy logic; both run on the same hook fire.
- **`work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/`** — feature work item bundling the engine + hook in one user-story child (S000020). Phase 2 fully green: 7/7 smoke + 4 E2E green via QA engineer subagent static checks + 1 E2E deferred (E1: ship + pull + verify auto-mark — requires post-ship verification, which F000011's own ship cycle naturally provides).

### Changed

- **TODOS.md** — removed two closed entries (`Phase 3 lifecycle-gate auto-update gap` — closed by this PR; `F000010 pipeline gap: implement+qa skills are user-story-only` — captured early in this branch as a follow-up). Net change: 1 closure, 1 new follow-up entry from /implement-from-spec dogfood.

## [1.9.1] - 2026-05-08

D000016 defect fix — wire `test-deploy.sh` into CI and re-point stale `doc-RCA.md` template references onto a still-flat template. Closes the two TODOs that were blocking CI from running the U1–U28 update-check tests added in v1.6.0. Also adds a P2/M follow-up to TODOS.md tracking the Phase 3 lifecycle-gate auto-update gap discovered during the v1.7.0 land-and-deploy.

### Fixed

- **`scripts/test-deploy.sh`** — re-pointed 22 references to `doc-RCA.md` (subfoldered to `templates/personal-workflow/doc-RCA.md` in v1.3.x) onto `templates/doc-SKILL-DESIGN.md` (the only remaining flat-path template). Tests T2/T4-T7 now pass end-to-end. Closes the deferred "Pre-existing template-ownership test failures" TODO.
- **`scripts/test.sh`** — wired in `scripts/test-deploy.sh` between the T11 manifest schema-parity tests and the Summary block. The existing wrapper-grep pre-flight check stays as-is (structural assertion). Negative test confirmed wire-up catches future regressions: reintroducing one stale reference produces `RESULT: FAIL` with named failure, restored → PASS. Closes the deferred "Wire test-deploy.sh into CI / test.sh" TODO.

### Changed

- **`TODOS.md`** — Phase 3 lifecycle-gate auto-update gap captured as P2/M follow-up. Discovered during 2026-05-08 land-and-deploy of PR #65 (F000010 v1.7.0): `/ship` and `/land-and-deploy` are upstream gstack skills with no personal-workflow tracker awareness, so Phase 3 gates stay UNCHECKED after a successful workflow. Four resolution options listed in the entry (wrappers, hooks, smart `/personal-workflow check --update`, upstream gstack contributions); recommendation is option 3 as the cheapest first cut.
- **`work-items/defects/personal-workflow/D000016_test_deploy_stale_templates/`** — work-item tracking for the defect, RCA, and test-plan added.

## [1.9.0] - 2026-05-08

New `/implement-from-spec` skill — third and final pipeline skill, completing the personal-workflow lifecycle automation. Reads SPEC + DESIGN + TRACKER for a user-story and writes code per the SPEC's Components Affected and Data Flow. Sensitive-surface AUQ before catalog/manifest/validator/template changes (mandatory; cannot be bypassed by `--auto`). Propose-and-confirm by default; `--auto` for trivial changes (≤2 files AND no sensitive surface AND no Open Questions AND no live-alternative tradeoffs). Idempotent (NO-OP if already implemented). Boundary check refuses on incomplete Phase 1; verifies post-write compliance. Bootstrap-validated by dogfooding the `--auto` path on a synthetic single-file fixture: skill correctly classified TRIVIAL=true, wrote the asserted file with byte-exact content, transitioned implementer-owned Phase 2 gates while leaving QA-owned gates untouched, and passed the post-write boundary check.

### Added

- **`/implement-from-spec`** — new LLM-driven skill that implements a personal-workflow user-story from its SPEC. Status: `experimental`. Depends on `personal-workflow` (boundary check via `/personal-workflow check`). Three files: `skills/implement-from-spec/SKILL.md` (entry point: preamble, path resolution, usage, error handling) + `skills/implement-from-spec/implement.md` (12-step orchestration: input validation, boundary check at start, idempotency, read context, SPEC gap check, plan with sensitive-surface and triviality detection + mode resolution, sensitive-surface AUQ if needed, propose-and-confirm preview if not auto, write code, update tracker with `[impl-*]` journal entries + Phase 2 implementer-owned gate transitions, boundary check at end, print summary) + `skills/implement-from-spec/fixtures/example-user-story/` (synthetic single-file fixture for `--auto` path; hand-toggle variations documented for sensitive-surface AUQ, Phase-1-incomplete refusal, idempotency NO-OP, and SPEC-gap halt).
- **Phase 2 gate ownership pairing complete.** `/implement-from-spec` (Step 10) marks `Todos section reflects remaining work` + `Files section updated with changed files`; `/qa-work-item` (v1.8.0, Step 9) marks `Acceptance criteria verified met` + `Smoke tests pass`. Together the two skills move a user-story Phase 1 → Phase 2 → Phase 3 ready, with the implementer pair untouched by QA and the QA pair untouched by implementation.
- **Sensitive-surface paths enumerated** in `implement.md` Step 6.4: `skills-catalog.json`, `personal-artifact-manifests.json`, `company-artifact-manifests.json`, `templates/personal-workflow/*`, `templates/company-workflow/*`, `scripts/validate.sh`, `scripts/test.sh`, `scripts/test-deploy.sh`, `.git/hooks/*`. The list captures every load-bearing structural file in v1; expanding it is a v2 concern.
- **`work-items/features/personal-workflow/F000010_pipeline_skills/S000018_implement_from_spec/`** — Phase 2 fully green. 9 of 10 ACs verified directly by content inspection; AC-1 (full code-write loop) verified empirically via fixture dogfood. F000010's three pipeline skills (S000017 scaffold, S000019 qa, S000018 implement) are now all Phase 2 ready; the F000010 feature itself can move to Phase 3 once /qa-work-item runs on the implementations end-to-end.

### Changed

- **`README.md`** — regenerated skills table to include `/implement-from-spec` alongside `/scaffold-work-item` and `/qa-work-item`.

## [1.8.0] - 2026-05-08

New `/qa-work-item` skill — second of three pipeline skills automating the personal-workflow lifecycle. Runs smoke tests from TEST-SPEC's Smoke Tests table first; on green, dispatches a QA engineer subagent (Agent tool, fresh context, 5-min cap) for E2E verification per the E2E Tests table. Writes findings to tracker journal, transitions Phase 2 gates on green smoke + green E2E. Idempotent (NO-OP if already QA'd green). Boundary check refuses on incomplete Phase 2 implementation gates. Bootstrap-validated by dogfooding on a planted-bug fixture: the subagent correctly detected a content mismatch in a single ~30-token sentence — well under the 200-token Premise 1 cap — confirming the QA-engineer-subagent pattern works in practice on first run.

### Added

- **`/qa-work-item`** — new LLM-driven skill that QAs a personal-workflow user-story per its TEST-SPEC.md. Status: `experimental`. Depends on `personal-workflow` (boundary check via `/personal-workflow check`). Three files: `skills/qa-work-item/SKILL.md` (entry point: preamble, path resolution, usage, error handling) + `skills/qa-work-item/qa.md` (11-step orchestration: input validation, boundary check at start, idempotency check, read TEST-SPEC, run smoke, smoke-red short-circuit, spawn QA engineer subagent with cache-friendly stable-preamble-first prompt, process subagent verdict — green silent / red AUQ / ambiguous AUQ — transition Phase 2 gates if both green, boundary check at end, print summary) + `skills/qa-work-item/fixtures/example-user-story/` (planted-bug fixture: greeting file with content mismatch — subagent must detect and report red, plus 3 hand-toggle variations for smoke-red short-circuit, idempotency NO-OP, and boundary refusal).
- **Phase 2 gate ownership** explicitly defined in `qa.md` Step 2: implementer-owned gates (`Todos section reflects remaining work`, `Files section updated with changed files`) must be CHECKED at start; QA-owned gates (`Acceptance criteria verified met`, `Smoke tests pass`) get marked on green smoke + green E2E. Resolves an ambiguity in S000019_SPEC Story #7 between "Acceptance criteria verified unchecked → refuse" and AC-5's "the skill marks that gate green."
- **`work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item/`** — Phase 2 implementation gates marked green. 11 of 13 ACs verified directly via fixture dogfood + content inspection; AC-11 (prompt-cache hit on second run) deferred to a separate token-cost inspection. Mirrors the deferred-AC pattern from S000017.

### Changed

- **`TODOS.md`** — added two P3/S deferred entries surfaced during S000018/S000019 verification: (1) `/scaffold-work-item` Step 5 idempotency hole — always increments max tracker ID, never maps a source design doc back to an existing work item, so re-running on F000010's source design doc would write a duplicate F000011 instead of NO-OPing. Closes the deferred S000017 AC-5 once fixed. (2) `/personal-workflow check` Step 18 traceability parser may miss comma-separated AC cells like `AC-1, AC-2, AC-3` if the implementation uses field-by-field equality. Verify against real TEST-SPEC tables before fixing.

## [1.7.0] - 2026-05-08

New `/scaffold-work-item` skill — first of three pipeline skills automating the gap between `/office-hours` and `/ship` in the personal-workflow lifecycle. Takes a design-doc path, produces a compliant work-item directory tree per WORKFLOW.md scaffolding rules. Reads templates + manifest + WORKFLOW.md as runtime sources of truth; runs `/personal-workflow check` at boundaries; idempotent (re-run on same input is NO-OP). Bootstrap-validated by re-scaffolding F000010 itself via the new skill — proof revealed and fixed a real bug in the user-story DESIGN.md section instructions before shipping.

### Added

- **`/scaffold-work-item`** — new LLM-driven skill that scaffolds a personal-workflow work item from an `/office-hours` design doc. Status: `experimental`. Depends on `personal-workflow` (templates + manifest + WORKFLOW.md). Three files: `skills/scaffold-work-item/SKILL.md` (entry point: preamble, path resolution, usage, error handling) + `skills/scaffold-work-item/scaffold.md` (13-step logic: input validation, design-doc parsing, type detection from branch with AskUserQuestion fallback, ID generation, slug derivation, component grouping, multi-story decomposition with AskUserQuestion confirmation, idempotency check, write tree, boundary check at end, optional SCAFFOLDED footer append) + `skills/scaffold-work-item/fixtures/README.md` (F000010 as canonical fixture; manual snapshot-diff workflow).
- **`work-items/features/personal-workflow/F000010_pipeline_skills/`** — feature work item for the three-skill pipeline (scaffold + implement + qa). Hand-scaffolded as the bootstrap, then validated by re-scaffolding via the new skill itself. Contains feature-level TRACKER + DESIGN + ROADMAP, plus 3 user-story children (S000017 scaffold-work-item, S000018 implement-from-spec, S000019 qa-work-item) each with TRACKER + DESIGN + SPEC + TEST-SPEC. S000017 is Phase 2 complete (this PR); S000018 + S000019 remain Phase 1 for follow-up.

### Changed

- **`TODOS.md`** — added P3/M deferred entry: `/personal-pipeline` orchestrator wrapping the three pipeline skills (Approach B from office-hours). Decision deferred until S000017+S000018+S000019 ship and have been used on real work items for 2+ weeks.

### Notes

- The Phase 1 design (`~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md`) was produced via `/office-hours` and refined via `/plan-eng-review`. Eng review surfaced 4 substantive issues, all addressed before scaffolding: idempotency premise (1.1A), work-item granularity (1.2A — scaffold full tree; implement/QA at user-story level only), boundary validation premise (1.3A — every skill calls `/personal-workflow check` at start AND end), and one golden fixture per skill (3.1A).
- Bootstrap proof was non-trivial: a fresh-context Agent subagent acted as `/scaffold-work-item` against F000010's design doc; the diff against the hand-scaffolded baseline revealed 3 user-story DESIGN.md files producing 3 sections instead of the 7 required by `doc-DESIGN.md`. Root cause: `scaffold.md` Step 10 "brief stub" instruction was too permissive. Fixed in this PR: instruction now explicitly requires all 7 sections (content can be brief, structure cannot be omitted). Logged as the `brief-stub-ambiguity` pitfall learning (confidence 9/10).
- v1 ships with manual fixture-based testing per Step 0A choice during eng review. Behavioral eval harness (TODOS.md P1) deferred until after the three skills ship and the per-skill pattern is stable.

## [1.6.1] - 2026-05-08

Documentation hygiene: removed the dormant top-level `TODO.md` (last touched 2026-04-10 in v1.4.x era, 37 lines, all items already DONE-marked). The active list lives in `TODOS.md` — having both files alongside each other was confusing for anyone navigating the repo. The DONE history is preserved in git log.

### Removed

- **`TODO.md`** — legacy file consolidated. `TODOS.md` is the single source of truth for open and completed work. No content was lost; all items in `TODO.md` were already DONE-marked when retired.

### Notes

- No code, manifest, or skill changes. Pure repo cleanup.
- No references to `TODO.md` anywhere in the repo (verified by grep) — removing it doesn't break any docs or scripts.

## [1.6.0] - 2026-05-08

Update-nudge mechanism so consumers on other machines learn when a new collection version ships. Models gstack's pattern: each instrumented skill's preamble runs a check; if `origin/main` has a newer `VERSION` than what's installed, the user sees a `SKILLS_UPGRADE_AVAILABLE 1.5.3 → 1.6.0` banner and is prompted to Upgrade now / Snooze 24h / Skip this version. Upgrade runs `git pull --ff-only && skills-deploy install --from-upgrade <old>` from the user's clone, then the next skill invocation prints `SKILLS_JUST_UPGRADED 1.5.3 → 1.6.0` once. Closes the gap where users only learned about new versions by happening to `git pull`.

### Added

- **`scripts/skills-update-check`** — new ~280 LOC bash script. Default action emits banners; subcommands `--snooze [hours]`, `--skip <version>`, `--prompted <session>`, `--should-prompt <session>` let skill bodies update cache state without writing JSON themselves. Reads installed version from `manifest.collection_version` (catches "pulled but didn't reinstall"); reads remote from `git show origin/main:VERSION` after a 24h-cached `git fetch`. Reuses `version_gte` from `scripts/lib.sh` for semver compare; atomic cache writes via `mktemp` + `mv`; defensive numeric guards on every cache field consumed in arithmetic so a corrupted cache can't crash the silent preamble.
- **`scripts/skills-deploy install --from-upgrade <version>`** flag — when set, writes `~/.claude/.skills-templates-just-upgraded` after a successful install. The next `skills-update-check` invocation reads, unlinks, and emits the `SKILLS_JUST_UPGRADED` line once.
- **`skills-deploy doctor`** — surfaces `Update check:` section: last-check timestamp (portable BSD/GNU date), cached local/remote versions, snooze-until time, skipped versions. Also flags a missing `manifest.source` path (e.g., user deleted their clone) as FAIL with recovery hint.
- **`skills/personal-workflow/SKILL.md`** — `AskUserQuestion` added to `allowed-tools`; preamble snippet runs the check; `## Update Nudge Handling` section instructs how to react to banners (parse, debounce via `--should-prompt`, branch-state precondition, three-option AskUserQuestion, call `--snooze`/`--skip`/`--prompted`).
- **`skills/system-health/SKILL.md`** — same preamble snippet + `## Update Nudge Handling` block. `AskUserQuestion` was already in its allowed-tools.
- **`scripts/test-deploy.sh`** — 28 new tests (U1–U28): subcommand semantics, atomic-write debris check, marker round-trip, E2E with a temp git fixture verifying banner emission / cache TTL / snooze / skip / source-deleted silent / marker emit-and-unlink. Plus the `--from-upgrade` flag's three branches (missing value rejected, non-semver rejected, marker written) and doctor's cache surface (populated + never-run).

### Changed

- **`.github/workflows/validate.yml`** — `shellcheck` step now covers `scripts/skills-deploy` and `scripts/skills-update-check` (the existing `scripts/*.sh` glob misses them — both lack the `.sh` extension). Closes a CI gap that pre-dated this PR.
- **`scripts/test-deploy.sh`** — `SKILL_COUNT` now excludes `status: deprecated` catalog entries to mirror what `skills-deploy install` actually deploys (was over-counting, hid pre-existing test failures). Tests that intentionally install `company-workflow` now pass `--include-deprecated` explicitly. Pre-existing template-ownership tests (T2/T4–T7) are still failing — they reference a flat `doc-RCA.md` that no longer exists at the top level (subfoldered to `company-workflow/doc-RCA.md` in v1.3.x). Out of scope for this PR; tracked for follow-up.
- **`CLAUDE.md`** — `## Scripts reference` table gains a row for `skills-update-check`; new `## Update-check mechanism (F000009)` section documents the state files (`.skills-templates.json`, `.skills-templates-update.json`, `.skills-templates-just-upgraded`), the manual-override path (`rm` the cache), and the in-snippet path-resolution shape.

### Notes

- **Not in scope:** Copilot-bundle (`work-copilot/`) consumers — they have no preamble surface; defer until there's a real signal anyone wants it. Fork-aware detection (fall back to `upstream/main` when `origin/main` is missing) — tracked as a follow-up.
- **Acknowledged limitation:** preamble auto-runs `$source/scripts/skills-update-check` based on `manifest.source`. A user who can write to `~/.claude/.skills-templates.json` can redirect every skill invocation to attacker-controlled code. Same trust boundary already applies to all installed skills (deployed via skills-deploy from this manifest); the update check doesn't enlarge the attack surface beyond what's already there. Pinning the `origin` URL would tighten the upgrade path; deferred.
- **Pre-existing template-ownership tests** in `scripts/test-deploy.sh` (T2/T4–T7) still fail. They were already broken on `main` (the SKILL_COUNT fix made them visible by un-masking the run path). Tracked as a follow-up.

## [1.5.3] - 2026-05-07

Documentation hygiene: the Scripts table in `README.md` and the matching reference in `CLAUDE.md` had drifted from the actual contents of `scripts/`. Five entries described scripts that no longer exist (`skill-design.sh`, `create-skill.sh`, `skill-check.sh`, `skill-version.sh`, `skill-ship.sh`) and five real scripts were missing (`skills-deploy`, `setup.sh`, `test-deploy.sh`, `collection-version.sh`, `copilot-deploy.py` in README; `skills-deploy`, `setup.sh`, `test-deploy.sh` in CLAUDE.md). The README's Quick Start block also pointed at the phantom `create-skill.sh`. The drift had survived multiple ships because the stale content lived inside `scripts/generate-readme.sh`'s hardcoded heredoc, so re-running the generator just re-emitted the same wrong table.

### Changed

- **`README.md`** and **`scripts/generate-readme.sh`** — Scripts table reflects actual repo contents (was: 5 phantom scripts, missing 5 real ones). Quick Start block drops the phantom `./scripts/create-skill.sh my-new-skill` line; new-skill creation is manual per CLAUDE.md.
- **`CLAUDE.md`** — Scripts reference table adds `setup.sh`, `skills-deploy`, and `test-deploy.sh` (was missing the workhorse installer plus its bootstrap and test driver).

### Notes

- No skill, manifest, or behavioral changes — pure documentation sync. `skills-catalog.json`, all SKILL.md versions, and per-skill manifests are untouched.
- No tracker work item filed; the change is a single-PR doc reconciliation that doesn't merit a TRACKER + RCA + test-plan triple.
- The drift *mechanism* (hardcoded heredoc) remains. This PR fixes the current snapshot, not the structural cause — the next script add/rename/delete can re-introduce the same drift. A follow-up to derive the table from `ls scripts/` (or to add a `validate.sh` check that asserts the heredoc table covers every executable in `scripts/`) is the right next step; out of scope here.

## [1.5.2] - 2026-05-07

`skills-deploy install` now overwrites drifted templates and rules by default — running it after a workbench pull just makes `~/.claude/` match source, no flag required. The previous safe-by-default behavior (skip on checksum mismatch, log a WARN) inverted the realistic mental model: every routine deploy hit the warning and had to be retried with `--overwrite`. The post-merge git hook from D000013 already passed `--overwrite` unconditionally, so the automation had quietly concluded the same thing. Closes D000015.

### Changed

- **`scripts/skills-deploy`** — default install now overwrites drifted templates and rules. Renamed log line `OVERWRITE: ... (--overwrite used)` → `UPDATE: ... (checksum differs)`. The old WARN-and-skip path is reachable via the new `--no-overwrite` flag, where it now logs `PRESERVE: ... (--no-overwrite, keeping deployed copy)`. The doctor reset hint and `install --help` text are updated to match.
- **`CLAUDE.md`** — "Template deployment" bullet rewritten to document the new default and the `--no-overwrite` opt-out.
- **`scripts/test-deploy.sh`** — Test T6 split into three sub-cases asserting the new default-overwrites behavior, the `--no-overwrite` opt-out, and the legacy `--overwrite` no-op compat.

### Added

- **`scripts/test.sh`** — D000015 regression block (6 grep checks): default value, `--no-overwrite` handler, legacy `--overwrite` tolerance, removal of stale WARN copy, help-text update, CLAUDE.md sync.
- **`work-items/defects/ops/skills-deploy/D000015_skills_deploy_install_overwrite_default/`** — defect work item (TRACKER + RCA + test-plan).

### Notes

- `--overwrite` is retained as a tolerated no-op so D000013's post-merge git hook (which still passes the flag unconditionally) continues to work without modification. The flag can be retired in a future cleanup; no urgency.
- Live smoke test: drift → default install → `UPDATE`; drift → `--no-overwrite` → `PRESERVE` (drift preserved); drift → legacy `--overwrite` → `UPDATE`. All three paths verified on `~/.claude/templates/personal-workflow/tracker-defect.md`.

## [1.5.1] - 2026-05-07

Adds a Phase 3 gate for `/document-release` to the feature tracker template — closes the loop on post-ship doc drift. The recent v1.5.0 ship surfaced one such drift (README skill table left at v2.0.0 after the manifest moved to v3.0.0); the new gate makes the post-merge audit an explicit checkbox instead of freelance hygiene. Feature trackers only — user-stories and tasks unchanged so atomic work doesn't pick up gate overhead.

### Changed

- **`templates/personal-workflow/tracker-feature.md`** — Phase 3 grows from 5 gates to 6: adds `[ ] /document-release — post-ship doc audit done; drifts fixed inline or spawned as D-tickets` and the matching numbered step.
- **`skills/personal-workflow/examples/example-tracker-feature.md`** — mirrors the new gate.
- **`skills/personal-workflow/fixtures/valid-feature-dir/F999999_TRACKER.md`** — mirrors the new gate so the fixture stays byte-aligned with the template.

### Notes

- No artifact set or manifest changes — purely additive content inside an existing tracker section. `personal-artifact-manifests.json`, `skills-catalog.json`, `template-registry.json`, and `SKILL.md` versions all stay at 3.0.0.
- Historical feature work items (F000001, F000002, F000004, F000005, F000006, F000008) are not retroactively migrated; they shipped under the 5-gate Phase 3 contract and remain valid as-is.

## [1.5.0] - 2026-05-07

Personal-workflow tracker re-cut. Replaces the old artifact set (feature-summary, PRD, ARCHITECTURE, milestones) with a workflow-mirrored set where every persistent doc maps 1:1 to a step the engineer actually runs: `DESIGN.md` from `/office-hours`, `SPEC.md` from the scaffolding step (was PRD + ARCHITECTURE merged), `ROADMAP.md` for feature-level scope and timeline (was feature-summary + milestones merged), `TEST-SPEC.md` for smoke + E2E. Tracker templates' Phase 3 surfaces smoke and E2E as separate gates instead of one collapsed "TEST-SPEC verified" check. WORKFLOW.md task-required rule relaxed: atomic user-stories may ship without task children. Single sweep PR migrates 13 historical work items + 1 fixture + all examples to the new shape.

### Added

- **`templates/personal-workflow/doc-SPEC.md`** *(new)* — user-story specification merging requirements (`### P0 (Must-Have)`, `### P1`, `### P2` sub-sections under `## Requirements`) with architecture decisions and tradeoffs. Replaces PRD + ARCHITECTURE.
- **`templates/personal-workflow/doc-ROADMAP.md`** *(new)* — feature roll-up: scope, non-goals, decomposition, delivery timeline (with `### Delivery History` sub-section to absorb shipped milestone history), dependency graph. Replaces feature-summary + milestones.
- **`work-items/features/personal-workflow/F000008_tracker_recut/`** — feature work item that drove the re-cut, decomposed into S000014 (templates + manifest + check.md), S000015 (historical migration), S000016 (examples + repo-level surfaces).

### Changed

- **`skills/personal-workflow/personal-artifact-manifests.json`** — bumped to `version: 3.0.0`. New artifact set: feature = TRACKER + DESIGN + ROADMAP (3); user-story = TRACKER + DESIGN + SPEC + TEST-SPEC (4); task and defect unchanged.
- **`skills/personal-workflow/SKILL.md`** — version bumped to 3.0.0.
- **`skills/personal-workflow/check.md`** — Step 18 cross-reference traceability rewritten: source filename `PRD.md` → `SPEC.md` (4 references at lines 303-329); 4 incidental `PRD`/`ARCHITECTURE` mentions updated for consistency (lines 84, 218, 220, 365); `## Test Matrix` legacy clause deleted (dead code post-v1.4.0 sweep). `### P0/P1/P2` sub-section parsing preserved — same logic, new source file.
- **`skills/personal-workflow/WORKFLOW.md`** — 8 surfaces updated: artifact-count list (lines 21-22), Step 2 narrative (lines 38, 41), Step 3 narrative (line 49), Type-to-Artifact Mapping table (lines 64-65), validation rule (line 190). Plus line 120: user-story task-required rule relaxed from "at least 1 task child" to optional with explicit atomic-story escape hatch (`[x] Tasks broken down (N/A — atomic story)`).
- **`templates/personal-workflow/tracker-feature.md`** + **`tracker-user-story.md`** — full rewrite. Adds `/office-hours` Prerequisite line above Phase 1; Phase 1 reordered to start from branch creation, then DESIGN distillation, then SPEC/ROADMAP scaffolding; Phase 3 expanded to 5 explicit gates (`/personal-workflow check`, smoke pass, E2E walked, `/ship`, `/land-and-deploy`).
- **`templates/personal-workflow/tracker-task.md`** — adds optional `/office-hours` Prerequisite block; no gate or section changes.
- **`templates/personal-workflow/doc-DESIGN.md`** — line 15 prose, line 71 cross-link comment, line 76 hard-coded `Milestones:` link rewritten to `Roadmap:`.
- **`templates/personal-workflow/doc-TEST-SPEC.md`** — frontmatter cross-references (`prd: PRD.md` + `architecture: ARCHITECTURE.md`) collapsed to single `spec: SPEC.md`; instructional comments updated PRD → SPEC throughout.
- **`skills-catalog.json`** — personal-workflow entry version 3.0.0; templates list drops 4 (doc-PRD, doc-ARCHITECTURE, doc-feature-summary, doc-milestones), adds 2 (doc-SPEC, doc-ROADMAP).
- **`template-registry.json`** — personal-workflow `doc_types` array updated; version bumped to 3.0.0.
- **`CONTRIBUTING.md`** lines 44-45 and **`PHILOSOPHY.md`** lines 25, 42, 43 — narrative references PRD/ARCHITECTURE/feature-summary/milestones swept to SPEC/ROADMAP/DESIGN where active.
- **`scripts/test.sh:594-606`** — D000012 deployed-template guard loop split per-workflow: personal-workflow iterates `[doc-DESIGN, doc-SPEC, doc-ROADMAP]`; company-workflow keeps `[doc-DESIGN, doc-feature-summary]` (deprecated, byte-mirror source). Plus template-count assertion at line 299 updated 12 → 10.
- **`scripts/test-deploy.sh`** — canary template name swapped from `doc-PRD.md` to `doc-RCA.md` (19 references); manual line-414 path correction adds `personal-workflow/` subdir.
- **5 historical features migrated** (F000001, F000002, F000004, F000005, F000006): feature-summary + milestones consolidated into ROADMAP per item; existing DESIGN cross-links rewritten; old files deleted. Each ROADMAP includes the canonical 7 v3 sections + `### Delivery History`.
- **8 historical user-stories migrated** (S000001, S000006, S000007–S000010, S000012, S000013): PRD + ARCHITECTURE consolidated into SPEC per item; new DESIGN.md stub written per item (predates the v3 convention); TEST-SPEC frontmatter migrated; old files deleted. SPEC files preserve PRD's `### P0/P1/P2` sub-sections inside `## Requirements`.
- **F000008's three child user-stories** (S000014, S000015, S000016) self-migrated as part of the sweep with the same per-item recipe.
- **Sibling tracker Phase 1 lifecycle text refreshed** (F000001/F000004/F000005/F000006/F000008) to reference v3 templates (DESIGN, SPEC, ROADMAP) instead of deleted v2 templates.
- **Examples**: `example-doc-SPEC.md` and `example-doc-ROADMAP.md` (new, Reading List CLI consistent); `example-tracker-feature.md` and `example-tracker-user-story.md` rewritten to mirror the new tracker shapes.
- **Fixtures**: `valid-feature-dir/` rewritten to match the v3 manifest (TRACKER + DESIGN + ROADMAP).

### Removed

- **`templates/personal-workflow/doc-PRD.md`**, **`doc-ARCHITECTURE.md`**, **`doc-feature-summary.md`**, **`doc-milestones.md`** — replaced by SPEC + ROADMAP.
- **`example-doc-PRD.md`**, **`example-doc-ARCHITECTURE.md`**, **`example-doc-feature-summary.md`**, **`example-doc-milestones.md`** — corresponding examples.

### Why workflow-mirrored

The old artifact set framed itself around document types as nouns (PRD, ARCHITECTURE, feature-summary, milestones). The new set frames artifacts around the workflow step that produces them: `/office-hours` produces DESIGN, scaffolding produces SPEC + ROADMAP, the engineer running smoke + E2E produces TEST-SPEC content. Reading the artifact list now answers "where does this come from?" without a separate map.

### Open questions deferred

- Sibling-tracker drift in pre-existing migrated content (S000010_SPEC.md inline references to deleted PRD/ARCHITECTURE filenames, F000004_DESIGN.md links to repo paths deleted by F000006 in v1.3.x). Both are documentation-quality issues in sealed historical content; the validator passes (Step 16 only checks section headers + frontmatter, not body prose). Better suited to a separate content-polish pass.
- Mirroring the v3 shape to `deprecated/company-workflow/templates/` and `work-copilot/` byte-mirror sources is intentionally deferred (deprecated, sealed).

### Migration notes

- The catalog version bump triggers a `skills-deploy install --overwrite` requirement on existing user installs. The /ship validator's D000012 guard catches drift but does not auto-fix.
- Validator ran `/personal-workflow check` against the migrated `work-items/` tree; structural compliance (Step 16) PASS for all 14 migrated items.

## [1.4.0] - 2026-05-05

Personal-workflow TEST-SPEC template restructure. Drops the redundant Test Matrix + Test Tiers shape and replaces it with two compact tables — Smoke Tests and E2E Tests — distinguished by who edits them and when they run. Smoke tests are automated regression that lives in CI; E2E tests are manual user-scenario verification done before /ship. Soft cap of 5 rows per tier acts as a forcing function to pick the tests that prove the story works rather than tests that demonstrate completeness. The validator (`/personal-workflow check`) gets stricter: Step 18 traceability scans the new tier tables for AC values with a placeholder-filter to prevent freshly-scaffolded files from silently passing, a new Step 18.5 emits an `[INFO]` cap-advisory when either tier exceeds 5 rows, and Step 20's template badge ladder picks up `INFO` between `PASS` and `WARN` so cap-advisory signals route to the right column.

### Changed

- **`templates/personal-workflow/doc-TEST-SPEC.md`** — three top-level sections only: `## Smoke Tests`, `## E2E Tests`, `## Coverage Gaps`. Both tier tables include an AC column for PRD↔test traceability. Soft 5-row cap stated in template comments.
- **`skills/personal-workflow/check.md` Step 18** — replaces the `## Test Matrix` AC scan with a unified scan over `## Smoke Tests` + `## E2E Tests` AC columns, filters out the literal `AC-{n}` template placeholder so unfilled scaffolded files correctly flag as `[UNTESTED]`, and runs P0 + P1/P2 loops over a single shared `ac_set`. No legacy fallback — files that still use `## Test Matrix` fail Step 16's section check at the source.
- **`skills/personal-workflow/check.md` Step 18.5** *(new)* — emits `[INFO]` cap-advisory when Smoke or E2E row count exceeds 5. Row counting uses regex `^\s*\|.*\|\s*$` between heading and next `## ` header, minus 2 for the markdown header + separator rows.
- **`skills/personal-workflow/check.md` Step 20** — extends the **template** badge severity ladder to `PASS < INFO (cap-advisory) < WARN (EXTRA sections) < DRIFT < MISSING`. Traceability ladder unchanged.
- **`scripts/test.sh:107-117`** — replaces the dormant `## Test Matrix` grep with a loop that requires both `## Smoke Tests` AND `## E2E Tests` for any `docs/<skill>/TEST-SPEC.md` file. Pattern matches the surrounding feature-summary.md check.
- **`skills/personal-workflow/examples/example-doc-TEST-SPEC.md`** — re-synced to the new template shape using the reading-list-CLI domain. 5 smoke + 5 E2E rows, AC-mapped.
- **`skills/personal-workflow/examples/example-doc-test-plan.md`** — re-synced to the (unchanged) existing test-plan template. Closes a long-standing example/template drift.
- **8 historical TEST-SPEC.md files swept** to the new shape: `S000001` (workflow_implementation), `S000006` (personal_workflow_port), `S000007`–`S000010` (work-copilot subfeatures), `S000012` (deprecated_status_semantics), `S000013` (relocate_with_catalog_driven_paths). Each file consolidated to ≤5 rows per tier where natural; AC values converted from `Story #N` / `Story N` formats to `AC-N` for validator traceability. S000001's pre-existing `## Coverage Notes` heading was renamed to `## Coverage Gaps` to match the (unchanged-named) template section.

### Why two tiers, distinguished by editor

The old tier model (Test Matrix + Tier 1 Smoke + Tier 2 E2E as h3 children of `## Test Tiers`) framed the split around static-vs-dynamic execution. The new model frames it around the engineer's relationship to the tests: smoke = automated regression you write once and never touch, E2E = manual user-scenario verification you sit down and run before ship. That cognitive split shows up in the file as separate top-level sections so it's visible at a glance, not buried in a `Type` column.

### Validator behavior on legacy files

The 2 deprecated test-specs at `deprecated/work-items/features/F000003_company_workflow/{S000003,S000004}/` are not walked by the validator (Step 14 walks `./work-items/` only, not `deprecated/`). They retain the old Test Matrix shape and stay as frozen historical artifacts.

### Open question deferred

Mirroring this restructure to `templates/company-workflow/doc-TEST-SPEC.md` (and the byte-mirrored copies under `work-copilot/`) is intentionally deferred to a follow-up F-level work item per the design doc default. Touching company-workflow means coordinating template + reference + philosophy + example + 4 byte-mirror sources.


## [1.3.3] - 2026-05-05

Refines v1.3.2's grouping into a two-axis split: **skills** (per-subfolder for actual deployable skills) vs **ops** (umbrella for everything else — deprecation lifecycle, deploy tooling, ship workflow, generic workflow defects). The directory now reads as a clean taxonomy: if it's a skill, find it under its own name; if it's not, find it under `ops/`.

### Changed
- **`work-items/features/deprecation/`** → **`work-items/features/ops/deprecation/`** (F000005 + F000006).
- **`work-items/defects/skills-deploy/`** → **`work-items/defects/ops/skills-deploy/`** (D000005, D000013).
- **`work-items/defects/ship/`** → **`work-items/defects/ops/ship/`** (D000008).
- **`work-items/defects/workflow/`** → **`work-items/defects/ops/workflow/`** (D000001, D000002, D000007, D000014).

Skill subfolders (`personal-workflow/`, `system-health/`, `work-copilot/`) are unchanged. Same `git mv` blame-preservation rule + same hands-off policy on cross-references in completed trackers.

### Final shape

```
work-items/
├── features/
│   ├── personal-workflow/F000001
│   ├── system-health/F000002
│   ├── work-copilot/F000004
│   └── ops/
│       └── deprecation/{F000005, F000006}
└── defects/
    ├── personal-workflow/{D000009, D000012}
    ├── work-copilot/{D000010, D000011}
    └── ops/
        ├── skills-deploy/{D000005, D000013}
        ├── ship/{D000008}
        └── workflow/{D000001, D000002, D000007, D000014}
```

### Notes for contributors
- Future per-skill work (a new defect for personal-workflow, a feature for system-health) lands under the skill's existing subfolder.
- Future ops work (a new tooling category, a new lifecycle arc beyond deprecation) lands under `ops/{new-category}/`.
- `validate.sh`'s manifest reconciliation walk uses `find -type f` recursively, so the new depth (`work-items/{features,defects}/ops/{category}/{F-or-D}/`) is handled without script changes.

## [1.3.2] - 2026-05-05

Pure tree reorganization. Active features and defects in `work-items/` are now grouped into subject-component subfolders so the directory tree scales as more work items land. No content changes; `git mv` preserved blame for all files.

### Changed
- **`work-items/features/`** — 5 features grouped into 4 subfolders:
  - `personal-workflow/F000001_personal_workflow`
  - `system-health/F000002_system_health`
  - `work-copilot/F000004_work_copilot`
  - `deprecation/F000005_deprecated_skill_status` + `deprecation/F000006_relocate_deprecated_skills` (cross-cutting deprecation lifecycle arc)
- **`work-items/defects/`** — 11 defects grouped into 5 subfolders:
  - `personal-workflow/` — D000009, D000012
  - `work-copilot/` — D000010, D000011
  - `skills-deploy/` — D000005, D000013
  - `ship/` — D000008
  - `workflow/` — D000001, D000002, D000007, D000014 (generic workflow lifecycle/template defects that span multiple skills)

### Notes for contributors
- `deprecated/work-items/` is intentionally left flat — all contents are about the one deprecated skill (`company-workflow`), so sub-grouping there is redundant. If a second skill ever gets deprecated, the same per-component subfolder pattern will apply there too.
- Cross-references in completed work-item trackers and historical CHANGELOG entries point at the OLD flat paths. Same rule as F000007: frozen historical prose isn't updated. Unique IDs (D-numbers, F-numbers) resolve cross-references via either path.
- `validate.sh`'s manifest reconciliation walk uses `find -type f` recursively, so the new depth isn't a problem — no script changes needed.
- The `ship/` subfolder is a singleton today (D000008 only) but will absorb future ship-related defects without re-organization, matching the F000006 principle: name the subject explicitly so future entries know where to land.

## [1.3.1] - 2026-05-05

F000007 finishes the deprecation lifecycle by relocating the work-item history for
the deprecated `company-workflow` skill. F000005 made the catalog skip-on-install,
F000006 moved the skill source out of `skills/`, and F000007 moves the four
work-item directories whose primary subject is `company-workflow` to a new
`deprecated/work-items/` parent. `work-items/` now contains only active feature
and defect history; chronological IDs are preserved so cross-references in
CHANGELOG and other historical artifacts remain readable.

### Changed
- **`work-items/features/F000003_company_workflow/`** → **`deprecated/work-items/features/F000003_company_workflow/`** (the company-workflow feature itself, with TRACKER + DESIGN + feature-summary + milestones + nested user-story).
- **`work-items/defects/D000003_company_workflow_feature_artifact_duplication/`** → `deprecated/work-items/defects/`.
- **`work-items/defects/D000004_company_workflow_contract_template_drift/`** → `deprecated/work-items/defects/`.
- **`work-items/defects/D000006_company_workflow_test_verification_gates/`** → `deprecated/work-items/defects/`.
- **`scripts/validate.sh` Error check 4 (orphan check):** `deprecated/` is now allowed to host non-skill subtrees. The check still flags any directory under `skills/` without a catalog entry (the zzz-test-orphan regression case still trips), but under `deprecated/` it only inspects dirs that contain a `SKILL.md` or are claimed by a catalog entry. `deprecated/work-items/` is a sibling concept to `deprecated/{name}/` skill sources, not an orphan.
- **`deprecated/README.md`:** documents the `deprecated/work-items/` convention alongside the existing skill-source-of-truth note. Includes the rule-of-thumb: when deprecating another skill, move its primary work-item directories (the feature itself + any defects whose primary subject is this skill) here too.

### Notes for contributors
- D000007 (`workflow_template_single_source_of_truth`) was deliberately NOT moved — it was generic single-source-of-truth principle work that landed alongside the company-workflow refactor and ALSO refactored personal-workflow templates. Moving it would imply the principle is deprecated, which it isn't. Same logic for D000005, D000008, D000010-D000014: each is generic-tooling work that happened to surface on company-workflow but isn't *about* it.
- F000004 (work-copilot) stays active. The Copilot bundle is the live consumer of `deprecated/company-workflow/` via byte-mirror; the feature itself is still in production.
- Cross-references in completed work-item trackers (D000007, D000009) and historical CHANGELOG entries point at the OLD `work-items/...` paths. These are not updated — they're frozen historical prose describing past work, and revising them would be revisionist editing of the record. The chronological IDs (F000003, D000003, D000004, D000006) stay unique across both `work-items/` and `deprecated/work-items/`, so future cross-references can use either path or just the ID.

## [1.3.0] - 2026-05-05

F000006 finishes the deprecation lifecycle that F000005 started. Where F000005
made `skills-deploy install` skip deprecated skills, this release moves the
source files out of `skills/` entirely so the directory contains only deployable
skills. `company-workflow` now lives at `deprecated/company-workflow/` (with its
templates as a sub-directory) and consumer scripts derive paths from the catalog
instead of hardcoding `skills/{name}/`. Future relocations are a one-line catalog
change.

### Added
- **Top-level `deprecated/` directory.** Source-of-truth for skills marked
  `status: deprecated` in the catalog. Contents are NOT deployable skills —
  they stay in the repo because byte-mirrored bundles (e.g. `work-copilot/`)
  reference them as upstream truth, enforced by `validate.sh` Error check 10's
  `MIRROR_SPECS` array. `deprecated/README.md` explains the convention.
- **Optional `templates_source` catalog field** for skills whose templates live
  outside the default `templates/{name}/` shape. When set, `skills-deploy` and
  `validate.sh` resolve template SRC paths via `$REPO_ROOT/$templates_source/
  $(basename $tpl)`; DST paths under `~/.claude/templates/{skill}/` are
  unchanged, so user-visible install locations stay the same.
- **Catalog-driven path helpers** in three scripts. `scripts/skills-deploy`,
  `scripts/validate.sh`, and `scripts/test.sh` each gained `skill_md_path`,
  `skill_source_dir(_abs)`, and (where relevant) `skill_templates_source`
  helpers that read paths from the catalog's `files[]` and `templates_source`
  fields. The `SKILLS_SRC` constant is gone — skills can live anywhere the
  catalog points.

### Changed
- **`skills/company-workflow/` → `deprecated/company-workflow/`** (53 files).
  `git mv` preserved blame history. The skill is still installable via
  `skills-deploy install --include-deprecated`; the destination path under
  `~/.claude/skills/company-workflow/` is unchanged.
- **`templates/company-workflow/` → `deprecated/company-workflow/templates/`**
  (14 templates). Co-located with the skill; `templates/` top-level now contains
  only `personal-workflow/` and `doc-SKILL-DESIGN.md`.
- **`scripts/skills-deploy`:** `discover_skills()` iterates the catalog instead
  of walking `skills/*/`; `do_install`, `do_relink`, and `do_doctor` derive the
  source directory from `dirname(catalog files[0])` (relink + doctor read the
  manifest's `path` field, with a fallback to the legacy shape for older
  installs). The templates loop honors `templates_source` overrides.
- **`scripts/validate.sh`:** MIRROR_SPECS source paths retargeted to
  `deprecated/company-workflow/...`; orphan check (Error check 4) extended to
  walk both `skills/` and `deprecated/`; catalog walker (Error check 1/2) reads
  SKILL.md path from the catalog; orphan-template walker (Warning check 3)
  walks both default and override template directories. `declare -A` avoided
  for bash 3.2 portability on macOS.
- **`scripts/test.sh`:** introduces `COMPANY_PATH` and `COMPANY_TPL` constants
  near the top; ~40 hardcoded `skills/company-workflow` and `templates/
  company-workflow` references replaced. The next relocation, if any, is a
  one-line edit instead of a search-and-replace pass.
- **`scripts/doctor.sh`:** version-staleness check reads the SKILL.md path from
  catalog `files[0]` instead of hardcoding `skills/{name}/SKILL.md`. Was
  silently skipping the check for any catalog entry whose source had moved.
- **`template-registry.json`:** `company-workflow` paths point at
  `deprecated/company-workflow/...`. Currently no script consumes these fields
  at runtime, but the registry is documentation that should match reality.
- **`CLAUDE.md`:** path references updated; new "Deprecated skills convention"
  subsection documents the catalog-driven shape.
- **`README.md`:** regenerated; rendered output unchanged from v1.2.0 (the
  generator reads catalog metadata, not paths).

### Verified
- `./scripts/validate.sh` PASS (0 errors, 0 warnings); Error check 10 byte-
  identity verified for all 7 `MIRROR_SPECS` entries at the new source paths.
- `./scripts/test.sh` PASS (Failures: 0); the path-constants refactor surfaced
  19 latent failures that `test.sh` had been silently masking — all fixed.
- T000014's 6 regression cases on a fresh `SKILLS_DEPLOY_TARGET`: default
  install skips with 1 WARN, `--include-deprecated` installs from the new path
  (manifest path field reflects `deprecated/company-workflow/SKILL.md`),
  doctor reports INFO, idempotent re-install no-op, relink + doctor walk the
  new source dir cleanly with 16 OK lines for templates.

### Notes for contributors
- To deprecate another skill in the future: flip its catalog `status` to
  `deprecated`, `git mv skills/{name}/` → `deprecated/{name}/`, set
  `templates_source: "deprecated/{name}/templates"` if the skill has templates,
  and update any `MIRROR_SPECS` source paths. The consumer scripts honor the
  catalog automatically.
- Pre-existing `WARN: templates source missing at .../skills/templates` from
  `skills-deploy relink` is unchanged by this PR — `templates` is a templates-
  only catalog entry that has no skill directory; the WARN was there before
  F000006 and is out of scope.

## [1.2.0] - 2026-05-02

F000005 introduces a `deprecated` skill status so retired skills can stay in the
repo as upstream truth (e.g. for byte-mirrored bundles like `work-copilot/`)
without being pushed onto fresh machines. `skills-deploy install` skips them with
a single warning by default; `--include-deprecated` is the explicit opt-in. First
migration: `company-workflow`, superseded by the GitHub Copilot bundle (F000004)
on the Windows work machine.

### Added
- **`status: deprecated` semantics in `skills-catalog.json` (S000012).** The
  `status` field is now a closed enum `{active, experimental, deprecated}`
  enforced by `scripts/validate.sh` (Error check 9b). Typos like `depricated`
  fail the build instead of silently behaving like a missing status.
- **`scripts/skills-deploy install --include-deprecated` flag.** By default,
  install skips deprecated skills with one warning per skipped skill
  (`WARN: skipping deprecated skill: <name> (use --include-deprecated to
  install)`); the flag is the explicit opt-in. Filter applies to both the skill
  loop and the templates loop, so a deprecated skill's templates are also
  skipped when the skill is.
- **`scripts/skills-deploy doctor` deprecated-aware reporting.** Deprecated
  skills are reported as `INFO`, never `WARN` — both
  `INFO: <name> — deprecated, not installed by default` (the expected state)
  and `INFO: <name> — deprecated, installed (--include-deprecated)` (when the
  user opted in). Doctor exit code unchanged.
- **`scripts/generate-readme.sh` separate "Deprecated" section.** Active and
  experimental skills render in the main table; deprecated skills appear under
  a labeled `### Deprecated` section with a one-line explanation, gated on
  count > 0 so the section disappears when no deprecations exist.

### Changed
- **`company-workflow` flipped to `status: deprecated`** in
  `skills-catalog.json` (T000013). Source files at `skills/company-workflow/`
  remain in-repo (the `work-copilot/` byte-mirror invariant in `validate.sh`
  Error check 10 requires them); only install/visibility is affected.

### Notes
- 100% backwards-compatible for active and experimental skills — install,
  doctor, remove, and README rendering behave identically for non-deprecated
  entries. Existing pre-deprecation installations of `company-workflow` are
  preserved (install only skips, never removes).


## [1.1.3] - 2026-05-01

D000014 closes two co-located coverage gaps from prior manifest changes that
D000012 + D000013 didn't address: WORKFLOW.md type-to-artifact tables drifted
behind the manifest (4 entries across both workflows), and the D000012 drift
block only iterated workbench → deployed (deployed-extras slipped through).
The new regression checks force WORKFLOW.md and the deployed templates dir
into bidirectional sync with the manifest source-of-truth.

### Fixed
- `skills/personal-workflow/WORKFLOW.md` — feature row + prose updated from
  "TRACKER + milestones (2 artifacts)" to "TRACKER + feature-summary + DESIGN +
  milestones (4 artifacts)" to match the manifest. AI scaffolding now reads the
  correct count.
- `skills/company-workflow/WORKFLOW.md` — feature row + prose 3 → 4 (added
  DESIGN); defect 3 → 4 and task 2 → 3 (both added PR-DESCRIPTION). `work-copilot/WORKFLOW.md`
  is byte-mirrored in lockstep per `MIRROR_SPECS`.

### Added
- `scripts/test.sh` D000012 block extended with a reverse-direction loop:
  every file in `~/.claude/templates/{workflow}/` must also exist in the
  workbench source. Catches stale templates left after a workbench removal.
  Tagged with `D000014 guard` in failure messages.
- `scripts/test.sh` new D000014 block: parses every type's required-array
  length from each manifest and grep's the `| <type> |` row count column from
  WORKFLOW.md. Mismatch fails CI with the workflow, type, and both counts.
  Manifest is authoritative; future manifest changes will fail this check
  until WORKFLOW.md is updated.

### Notes
- D000012 TRACKER's deferred items "WORKFLOW.md type-to-artifact tables" and
  "Deployed-extra detection" are now closed and cross-link D000014.
- Skipped: `skills-deploy install --prune` for auto-cleanup of deployed-extras.
  Test.sh detection + manual `rm` is enough for now; revisit if extras become
  common.

## [1.1.2] - 2026-05-01

D000013 skills-deploy auto-sync hook — closes D000012's deferred Option C2.
After re-running `./scripts/setup-hooks.sh`, every workbench `git pull` that
touches `templates/`, `skills/`, `skills-catalog.json`, or `rules/` automatically
re-runs `scripts/skills-deploy install --overwrite`. `~/.claude/templates/` is
ready before the next skill invocation needs it. Drift detection (D000012
regression block) stays in place as the safety net.

### Added
- `scripts/setup-hooks.sh` now installs a `post-merge` hook alongside the existing
  pre-commit hook. Hook filters `git diff-tree ORIG_HEAD HEAD` for deploy-relevant
  paths and silently no-ops on unrelated pulls. Per-machine, untracked, idempotent
  (re-running `setup-hooks.sh` rewrites both hooks).
- `scripts/test.sh` D000013 regression block (3 grep-level checks): `setup-hooks.sh`
  emits a post-merge hook block, that hook calls `skills-deploy install --overwrite`,
  and it filters on `templates/|skills/|skills-catalog.json|rules/`. Source-level
  verification only — does not fire the hook itself, so CI on non-deployed hosts
  passes cleanly.

### Notes
- **Bootstrap step on each clone:** run `./scripts/setup-hooks.sh` once after
  cloning (or after upgrading past v1.1.2) to install both hooks. Existing pre-commit
  installations are rewritten in place; no manual cleanup needed.
- C1 (symlink the deployed templates dir into the workbench checkout) was the
  alternative considered in D000012's RCA. Not implemented — revisit only if the
  workbench-must-exist constraint becomes a real problem.

## [1.1.1] - 2026-05-01

D000012 personal-workflow + company-workflow deploy drift — restores
`~/.claude/templates/{personal,company}-workflow/` to byte-match the workbench
source and adds a generic `scripts/test.sh` regression block so future workbench
template edits can't silently fall behind the deployed copy.

### Fixed
- `~/.claude/templates/personal-workflow/` and `~/.claude/templates/company-workflow/`
  now match the workbench source after running `scripts/skills-deploy install --overwrite`.
  Previously, `doc-DESIGN.md` (added in v0.13.1) and `doc-feature-summary.md` (added in
  v0.14.2) were missing from the deployed copy, plus `tracker-feature.md`,
  `tracker-user-story.md` (personal), `tracker-feature.md`, and `doc-milestones.md`
  (company) had drifted from workbench edits. Repos using personal-workflow or
  company-workflow from a non-workbench checkout now resolve every template the
  manifest declares.

### Added
- `scripts/test.sh` D000012 regression block (~50 lines) covering both workflows.
  Verifies (a) `skills-catalog.json` declares `doc-DESIGN.md` and `doc-feature-summary.md`
  for both workflows and (b) when `~/.claude/templates/{workflow}/` exists, every
  workbench template is byte-identical in the deployed copy. Skips with an INFO line
  on hosts where `skills-deploy` hasn't run (e.g. CI). Future workbench template edits
  without a re-deploy fail this check with a pointer to `scripts/skills-deploy install --overwrite`.

## [1.1.0] - 2026-04-27

F000004 work-copilot v2 realignment — closes the artifact-completeness gap
between `work-copilot/` and `skills/company-workflow/`. Same templates and
validator that shipped in v0.14.0, plus full procedural backbone, how-to guides,
rationale notes, example artifacts, and complete fixtures — all byte-identically
mirrored from upstream and CI-enforced.

### Added
- **Bundle artifact mirrors (S000010).** `work-copilot/` now ships `WORKFLOW.md`,
  `reference/guide-*.md` (7 files), `philosophy/rationale-*.md` (3 files),
  `examples/example-*.md` (14 files), and the previously-missing fixture entries
  (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`,
  `invalid-wrong-order.md`, `valid-feature-dir/DESIGN.md`) plus a refreshed
  `valid-feature-dir/TRACKER.md`. All byte-identical to upstream.
- **`scripts/validate.sh` Error check 10 generalized to `MIRROR_SPECS` array (T000011).**
  Single composite check enforcing byte-identity sync on 7 mirror entries
  (templates, WORKFLOW.md, reference/, philosophy/, examples/, fixtures/, manifest pair).
  Uses `find -name '*.md' -print0` for the recursive shape — POSIX-portable, works on
  bash 3.2 (macOS default) without `shopt -s globstar`. Future mirror dirs add as one new line.
- **Mirror orphan policy split (autoplan D3).** New authoritative mirrors
  (`reference/`, `philosophy/`, `examples/`, `fixtures/`, `WORKFLOW.md`) FAIL on
  orphan — stale bundle copies served to Copilot are exactly the failure mode v2
  prevents. Templates retain v1 WARN-only behavior for backward compatibility.
- **Manifest pair sync via schema parity (autoplan D5).** Sync check parses both
  manifests and diffs with the `description` field stripped via `jq 'del(.description)'`.
  No code grep-consumes the description field, so byte-identity unification was
  test-driven coupling, not product value. Schema parity reflects the actual contract.
- **`scripts/copilot-deploy.py` defense-in-depth path-traversal check (autoplan G3 / D4).**
  `doctor` and `remove` resolve `install-manifest.json` `dest` entries and refuse
  any path that escapes the target directory. Exits 2 with a clear error.
  Closes a latent vulnerability that pre-dates v2 but was widened by the bundle expansion.
- **`scripts/copilot-deploy.py --dry-run` (DX3).** `install --dry-run` and
  `remove --dry-run` preview filesystem changes without writing or deleting.
  Output prefixed `(would write)` / `(would delete)` so it's diff-greppable.
- **`scripts/copilot-deploy.py` Python 3.8+ guard (DX1).** Pre-flight check at
  `main()` exits with a friendly upgrade hint when run on Python <3.8 instead of
  failing later with a confusing `argparse` traceback.
- **`scripts/copilot-deploy.py --help` enriched (DX4).** `RawDescriptionHelpFormatter`
  + `description=__doc__` surfaces the module docstring (subcommands, platform
  notes) in `--help` for free.
- **`work-copilot/README.md` quickstart (DX2).** Single human-facing entry point:
  prerequisites, install / use / upgrade / health-check / uninstall, and a
  troubleshooting table. New users / re-installers no longer have to navigate
  PRD/DESIGN docs to find the install command.
- **`work-copilot/instructions/copilot-instructions.md` Bundle layout + Troubleshooting
  sections (DX5 + DX6).** Adds a per-mirror-dir pointer table ("when to read each file")
  plus inline quoted anchors from `WORKFLOW.md` and `philosophy/` so canonical phrasing
  lands even if Copilot's path-following is unreliable. Troubleshooting table covers
  "/validate not recognized", "Copilot ignores the bundle", drift on prior-experiment
  files, and bundle-cite paths that don't exist. Total file size: 7821 bytes (≤8192 budget).
- **14 new test cases in `scripts/test.sh`** covering the v2 surface: 8 KB budget guard,
  bundle-layout pointer presence, install spot-checks for each new bundle dir,
  doctor DRIFT on nested fixture (the file that historically drifted),
  path-traversal defense, --dry-run filesystem-untouched assertion, T000011
  drift detection across single/flat/recursive shapes, orphan FAIL/WARN policy split,
  and manifest schema parity (rejects schema changes, allows description-only divergence).

### Fixed
- **`templates/company-workflow/doc-milestones.md` frontmatter aligned with actual
  feature-level milestone convention.** Dropped stale `parent: {USER_STORY_ID}`
  comment + `feature: {FEATURE_ID}` key. Every real milestones file in the
  workbench (F000001-F000004) uses `parent: {FEATURE_ID}` with no separate
  `feature` key — matches the personal-workflow template convention. The
  drift was harmless workbench-side (no real artifact had the `feature` key
  for the validator to demand) but surfaced on Windows when Copilot's
  validator self-test on `fixtures/valid-feature-dir/milestones.md` reported
  [DRIFT] for missing `feature` field. Bundle mirror updated in lockstep
  (sync check enforces it).

### Notes
- v2 plan packet was reviewed via `/autoplan` (CEO + Eng + DX dual voices). 4 taste
  decisions (D2 find-print0, D3 orphan FAIL/WARN split, D4 path-traversal defense,
  D5 manifest schema parity) and 1 user challenge (UC1: gate v2 on citation spike +
  S000009 Windows E2E) all resolved. Eng-review test-plan addendum identified 13
  test-coverage gaps; G3-G10 absorbed into this release, G11-G13 deferred. See
  `work-items/features/F000004_work_copilot/F000004_DESIGN.md` v2.1 for full audit.
- **UC1 citation spike PASSED** on Windows work box (2026-04-28): Copilot cited
  `.github/work-copilot/{WORKFLOW.md, examples/, philosophy/, reference/}` for
  all 4 procedural / how-to / rationale / example queries. The autoplan-mandated
  premise held. The DX5 inline-quoted-anchor hedge is still the right defense
  in depth, but path-following worked.
- The S000009 Windows-box live E2E acceptance criterion remains outstanding —
  expanded bundle does not prove v1 worked. Tracked separately under S000009.
- Knowledge integration (`$AI_KNOWLEDGE_DIR`, two-tier surfacing,
  `bin/knowledge-helpers.sh`) is **not** mirrored into the bundle. Copilot has no
  shell at prompt time and no env-var resolution; the helpers go away when a
  follow-up feature ships their Copilot-native redesign. `bin/` intentionally
  absent from `work-copilot/` per design Decision #10.
- Re-install on existing v0.14.0 targets picks up the new mirror artifacts
  automatically (`scripts/copilot-deploy.py rglob("*")` already routes everything
  not in `prompts/` or `instructions/` to `.github/work-copilot/<same>`). If a
  target has a manual `WORKFLOW.md` (or any other newly-mirrored file) from prior
  experiments, re-install reports `[DRIFT]` — use `--overwrite`.
- `./scripts/validate.sh` PASS (0 errors, 0 warnings, 33 mirror entries verified).
  `./scripts/test.sh` PASS (0 failures, 14 new v2 test cases green).
  `/personal-workflow check work-items/features/F000004_work_copilot/` PASS.

## [1.0.0] - 2026-04-25

First major release. The skill bundle (`personal-workflow`, `company-workflow`,
`system-health`, plus the `work-copilot/` Copilot port) is feature-complete for
the 1.x line; future work in this stream is bug fixes and incremental
enhancements rather than ground-up changes.

### Changed (BREAKING)
- **Knowledge integration: removed the per-repo `.claude/knowledge-enabled` opt-in marker.** Knowledge loading now activates whenever `$AI_KNOWLEDGE_DIR` resolves to a valid directory; the marker file is no longer consulted by `## Knowledge Loading`, `## On-Demand Matching`, or `## Diagnostic: knowledge-doctor` in `skills/company-workflow/SKILL.md`. **Cross-context isolation is now the user's responsibility** — scope `$AI_KNOWLEDGE_DIR` per shell (don't export globally if you work across multiple clients), or use `AI_KNOWLEDGE_DISABLE=1` for one-shot bypass. Rationale: F000003_DESIGN.md decision #4 and S000004_ARCHITECTURE.md already documented the marker as REJECTED ("redundant on top of two-tier surfacing + env-var control"); the v0.12.0 marker implementation never matched the v1.0 design intent. v0→1.0.0 is the right semver boundary for the breaking change.
  - **Migration:** if you previously relied on `.claude/knowledge-enabled` as a security gate, the file is now a no-op. Replace it with per-shell scoping of `AI_KNOWLEDGE_DIR`. The marker file itself can be safely deleted; nothing reads it.
- **`skills/company-workflow/SKILL.md` simplified:** preconditions list went from 5 → 4 entries, the helpful-diagnostic branch for "marker absent + has always-on" is gone, the `_marker_ok` variable is removed from `knowledge-doctor`, and the `marker:` line no longer appears in doctor output.
- **`skills/company-workflow/WORKFLOW.md` Security section rewritten** to put cross-context isolation guidance front and center (per-shell `AI_KNOWLEDGE_DIR` scoping + `AI_KNOWLEDGE_DISABLE=1` + per-category on-demand triggers). The marker-as-security-control framing is gone.

### Removed
- **7 marker-specific test cases** from `scripts/test.sh`: G1 marker-absent gates (cases 18, 19), the symlink/directory/nested-marker hardening trio (cases 22, 23, 24), `knowledge-doctor` marker-missing (case 31), and on-demand G2 marker-absent (c3 case 21). Cases 4 + 8 inverted to assert the marker string does NOT appear in `SKILL.md` / `WORKFLOW.md`. Case 20 simplified. Case 30 inverted to require no `marker:` line in `knowledge-doctor` output.

### Fixed
- **Tracker reconciliation across the `work-items/` tree.** Drift accumulated as work shipped without trackers being closed:
  - **F000003 (company-workflow):** journal entry added recording the v1.0.0 implementation realignment.
  - **F000004 (work-copilot):** S000007 + S000008 closed (status: shipped) — bundle, validator prompt, installer, doctor, smoke test all shipped in v0.14.0 (PR #43). S000009 + parent F000004 stay `active` because their last AC requires live E2E in Copilot chat on a Windows box, which is a user-side acceptance test, not a build artifact. Phase 2 + most Phase 3 gates updated to match the v0.14.0 ship state.
  - **D000007** (eliminate `contract.json`) and **D000009** (require DESIGN.md for personal-workflow features) closed. D000007's evidence: `find . -name contract.json` returns zero hits + F000003_DESIGN.md decision #2 codifies templates-as-SSoT. D000009's evidence: `jq '.types.feature.required'` on the personal manifest now includes `design`/`DESIGN.md` (shipped v0.13.1); v0.14.2 extended the same pattern to `feature-summary.md`.

### Added
- **`.context/` added to `.gitignore`.** Local retro / scratch directory was being shown as an untracked path on every `git status`; gitignored now.

### Notes
- Pure realignment + tracker hygiene + version semantics. No new features. The bundle that ships here is the same bundle that shipped in v0.14.3 minus the marker code path.
- `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures, all knowledge-loading + on-demand + doctor + copilot-deploy regression blocks green after the marker removal and test-case revisions).

## [0.14.3] - 2026-04-24

### Changed
- **Knowledge helpers extracted to `skills/company-workflow/bin/knowledge-helpers.sh` — one canonical implementation, sourced by every `## Knowledge ...` block in `SKILL.md`.** Replaces 4× inline duplication of `parse_knowledge_yml`, `parse_knowledge_triggers`, `list_categories`, `list_md_files` (Helpers, Loading, On-Demand Matching, Diagnostic blocks). Diagnostic block's `_parse` shim and inline trigger awk parser also replaced with calls to the canonical helpers.
- **`SKILL.md`: 1109 → 851 lines (~258 saved)** — duplicated awk parsers gone. Token cost on every `/company-workflow` invocation reduced commensurately.
- **Drift tripwires removed from `scripts/test.sh`** — impossible by construction now that there's only one definition. Replaced with structural greps verifying each Knowledge block sources `bin/knowledge-helpers.sh`. Test fixture repos now symlink the helpers in so the Loading / On-Demand / Doctor blocks resolve them via the workbench-relative fallback.

### Notes
- Pure refactor. `knowledge-doctor` smoke-test (unset env + tiny knowledge dir) produces identical output to v0.14.2. `./scripts/test.sh` PASS (0 failures).

## [0.14.2] - 2026-04-24

### Fixed
- **`feature-summary.md` is now required for personal-workflow features.** Adds the artifact to `personal-artifact-manifests.json`, copies the template + example from company-workflow, and backfills F000001-F000004 (and a `milestones.md` for F000002 which had been missing). Personal-workflow scaffolds and company-workflow scaffolds now produce the same 4-artifact set for `type: feature`.
- **F000003 + both `valid-feature-dir/` fixtures pass their own validators.** F000003 had been missing `feature-summary.md` since it was scaffolded with personal-workflow templates; the company-workflow fixture had been missing `DESIGN.md` since D000009 added it as a required artifact (v0.13.1) without updating the fixture. Both `tracker-feature.md` Phase 1 gates updated to mention DESIGN.
- **`F000003_DESIGN.md` big-decisions table populated** with 6 lifted journal entries (was a stub backfill from D000009).

### Added
- **`scripts/validate.sh` Error check 11 — pure-bash manifest reconciliation gate.** Enumerates every `*_TRACKER.md` directory under `work-items/` plus every `valid-*-dir/` fixture, strips the ID prefix, and compares against `required[].filename` in the matching manifest. Catches manifest-vs-filesystem drift that the LLM-driven `/personal-workflow check` and `/company-workflow validate` commands would otherwise miss in CI.

### Notes
- Pure compliance + tooling fix. No skill behavior change. `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures).

## [0.14.1] - 2026-04-24

### Changed
- **Work item consolidation: one feature per skill.** Each skill in the workbench (`personal-workflow`, `system-health`, `company-workflow`, `work-copilot`) now maps to exactly one canonical feature work item, so future work on a skill has an obvious home and the skill's full arc reads in one tracker. F000001 renamed `workflow_alpha` → `personal_workflow`. F000002 renamed `system_health_v1` → `system_health`. F000003 renamed `company_spec_system` → `company_workflow` and absorbed former F000004's shipped knowledge-integration stories (S000004 + S000005). F000004's deferred personal-workflow port (S000006) reparented to F000001. F000005 renumbered to F000004 (`work_copilot`) so feature IDs stay contiguous. Story and task IDs are unchanged — they are globally unique, not per-feature.
- **External references updated to point at the new IDs.** `skills/company-workflow/SKILL.md`, `skills/company-workflow/WORKFLOW.md`, `scripts/test-helpers/knowledge.sh`, `work-copilot/instructions/copilot-instructions.md`, `work-copilot/prompts/validate.prompt.md`, and the example tree output in `skills/personal-workflow/check.md` were updated. CHANGELOG and defect tracker references (D000009, D000010) intentionally left as historical records — they describe state at the time of writing.
- **Status fields aligned to actual delivery state.** F000001 / F000002 / F000003 flipped to `status: shipped` (previously a mix of `closed` and `active` that didn't reflect the merged shipped work). F000004 (work-copilot) stays `active` — three child stories still mid-flight.

### Notes
- Pure restructure of `work-items/` plus six small documentation pointers. No skill code, template, validator, or manifest changed. `./scripts/validate.sh` PASS (0 errors, 0 warnings); `./scripts/test.sh` PASS (0 failures).

## [0.14.0] - 2026-04-23

### Added
- **`work-copilot/` — a standalone GitHub Copilot bundle that ports the `/company-workflow` validation logic to VS Code Copilot Chat (F000005).** Installable into any repo with one command: `python3 scripts/copilot-deploy.py install <target>`. Produces `.github/copilot-instructions.md` (always-on context, 5 KB) + `.github/prompts/validate.prompt.md` (slash command, 7 KB) + `.github/work-copilot/` (templates, manifest, fixtures). Lets a Windows work machine get the same "scaffold + validate + ship" discipline Claude users have, without installing Claude.
- **`scripts/copilot-deploy.py` — Python 3 stdlib installer (no pip)** with three subcommands: `install` (SKIP/UPDATE/DRIFT/OVERWRITE/WRITE tri-state logic — skips user-edited files by default, replaces skill-upstream-updated files, respects `--overwrite` for forced replacement), `doctor` (PASS/MISSING/DRIFT/ORPHAN reporting against the install-manifest), and `remove` (cleans up only files the installer wrote). Text files (.md, .json, .yaml) are CRLF/CR → LF normalized before SHA256 hashing so hashes are stable across macOS and Windows regardless of git autocrlf settings.
- **`scripts/test.sh` — `copilot-deploy.py` installer smoke test** — install → doctor (expect all PASS) → CRLF-mutation → doctor (still PASS, guarding the CRLF normalization) → remove round-trip, executed against a tmp target. Closes the previous 0% automated coverage gap on the 264-LoC installer.
- **`work-copilot/instructions/copilot-instructions.md`** — 6 H2 sections (work-item conventions, IDs, hierarchy, lifecycle phases, validation, sources of truth). Every section ends with a `Source:` footer linking back to the template, manifest, or validator — single source of truth pattern.
- **`work-copilot/prompts/validate.prompt.md`** — ports the full `/company-workflow check` validator logic (File Mode + Directory Mode, PASS/MISSING/DRIFT/EXTRA/WARN/VALID/VIOLATION output contract) to a single Copilot `.prompt.md` file.
- **`work-copilot/fixtures/`** — one known-good fixture + one known-bad fixture for E2E self-test on any machine: `/validate work-copilot/fixtures/valid-feature-dir/` prints all `[PASS]`; the invalid fixture prints at least one `[MISSING]`.
- **`scripts/validate.sh` Error check 10** — enforces byte-for-byte sync between `templates/company-workflow/*.md` and `work-copilot/templates/*.md`, so the Copilot bundle can't silently drift from the Claude-side source of truth.

### Changed
- **`work-copilot/copilot-artifact-manifests.json`** mirrors `skills/company-workflow/company-artifact-manifests.json` with an annotation noting the mirror relationship. Includes the `design` artifact entry added by D000009.
- **`work-copilot/instructions/copilot-instructions.md` — lifecycle section corrected from 3 phases to 4 (Track, Implement, Review, Ship)** to match all five `tracker-*.md` templates. The previous "three phases" wording (copied from personal-workflow) would have made Copilot give wrong answers about Phase 3 being Ship, when Phase 3 is actually Review. Surfaced by Codex adversarial review during the /ship of F000005.

### Deferred
- **D000010 — copilot-deploy.py security hardening (path traversal + symlink escape).** Adversarial review (Claude + Codex) found the installer trusts `install-manifest.json` `dest` values verbatim (doctor/remove can read/unlink outside the target repo given a poisoned manifest) and follows symlinks in both source and destination trees. Both are latent in the current single-user self-install threat model. Tracker: `work-items/defects/D000010_copilot_deploy_security_hardening/`. Fix before recommending `copilot-deploy.py` to other users.

## [0.13.1] - 2026-04-22

### Added
- **`DESIGN.md` is now a required feature artifact for both personal-workflow and company-workflow (D000009).** Feature work items must now carry a cross-story engineering design doc — capturing the problem, solution shape, big decisions, risks, and ship criteria that don't fit in any single user-story's `ARCHITECTURE.md`. Two new templates (`templates/personal-workflow/doc-DESIGN.md` with 7 sections, `templates/company-workflow/doc-DESIGN.md` with 6 sections — company's drops "Not in scope" since `feature-summary.md` already owns Out-of-Scope). `feature.required` updated in both artifact manifests. Existing closed features (F000001–F000004) get a minimal `status: Backfill` DESIGN.md pointing at the original TRACKER/ARCHITECTURE for context.
- D000009 regression block in `scripts/test.sh` — 4 checks guarding against the DESIGN entry silently disappearing from either manifest or either template file vanishing.

### Changed
- Template count for personal-workflow bumps from 10 → 11 (new `doc-DESIGN.md`); `scripts/test.sh` count assertion updated to match.
- `skills-catalog.json` template lists for both personal-workflow and company-workflow now include `doc-DESIGN.md`.

## [0.13.0] - 2026-04-20

### Added
- **On-demand trigger matching for `/company-workflow` (F000004, S000005 c3).** Drop `.knowledge.yml { surface: on-demand, triggers: [pricing, "pricing engine"] }` next to a category directory. New `## On-Demand Matching` section in `skills/company-workflow/SKILL.md` enumerates on-demand categories with non-empty triggers and emits a `## On-Demand Knowledge Candidates` block listing each category, its triggers, and its files. Claude matches the latest user message against triggers (case-insensitive whole-word for single-word triggers, phrase match at token boundaries for quoted multi-word triggers), loads every matched category's files, and logs `[knowledge] matched: <cat> via <trigger>` for each hit. Categories with `surface: on-demand` but no triggers are documented as intentionally inert. Together with always-on loading (v0.12.0), this completes the knowledge-loading vertical slice.
- **`parse_knowledge_triggers` helper.** New bash function in `## Knowledge Helpers` that tolerates both YAML flow form (`triggers: [a, "b c", 'd']`) and block form (`triggers:` followed by `  - a`); strips single + double quotes; honors `#` comments, CRLF, and UTF-8 BOM — same grammar tolerance as `parse_knowledge_yml`. Defined in Knowledge Helpers and inlined byte-for-byte into the On-Demand Matching block; drift tripwire (c3 case 8) diffs the two copies on every test run.
- **`knowledge-doctor` distinguishes loadable vs inert on-demand categories.** Output now shows `runbooks surface=on-demand files=5 loads=on-match (triggers: pricing, "pricing engine")` for categories that will activate vs `staging surface=on-demand files=2 loads=no (empty triggers)` for inert ones. Same diagnostic covers both always-on (c2) and on-demand (c3) surfacing.
- **25 new c3 test assertions in `scripts/test.sh`.** Structural (section presence, matching-semantics spec, helper drift across blocks), unit tests for `parse_knowledge_triggers` (inline flow, block form, empty list, missing key, quote stripping), behavioral tests (always-on excluded from on-demand block, missing yml excluded, empty triggers excluded, single-trigger emission, quoted phrase emission, multi-category correctness), gate tests (marker absent, env unset, `AI_KNOWLEDGE_DISABLE=1` all suppress the block), and instruction-presence + doctor-output assertions.
- **WORKFLOW.md trigger authoring guidance.** New section covering single-word vs multi-word phrase semantics, why quoting matters, hygiene tips (keep triggers concrete, avoid single common verbs, quote multi-word phrases to scope them to contiguous token matches).

### Changed
- **`skills/company-workflow` bumped to v3.2.0.** Additive feature; no breaking changes. `## On-Demand Matching` inserted between `## Knowledge Loading` and `## Diagnostic: knowledge-doctor`. Always-on loading behavior unchanged; on-demand categories that previously parsed-and-discarded now enumerate + emit.
- **Removed "v1 deferred" language throughout `skills/company-workflow/WORKFLOW.md` and SKILL.md.** On-demand is no longer deferred; both surfacing modes ship in this release. The Loading block's `on-demand)` case now reads "handled by On-Demand Matching block; not emitted here" instead of "v1 deferred — forward-compat for c3 follow-up."
- **c2 test extraction bounds updated.** Tests that extract the Knowledge Loading bash block now bound at `## On-Demand Matching` (not `## Diagnostic: knowledge-doctor`) so the Loading extraction captures only the Loading block. Drift tripwire and A2-leak test now pass deterministically regardless of On-Demand Matching's presence.

### Skipped (explicit non-scope)
- **50KB on-demand soft threshold.** Dual-voice review flagged the proposed soft-cap-with-warning as theater: no real protection (still loads), no user action (just noise), and the existing hard 500-path / 100KB caps in Loading already protect always-on. Skipping reduces complexity without reducing safety. If on-demand bloat becomes a real incident, revisit with a concrete threshold tuned to observed pain.

### Rationale
Completes F000004 S000005. Knowledge integration now supports both loading modes: always-on (v0.12.0, ship with every invocation) and on-demand (this release, ship when Claude matches triggers in the user's message). The c1 + c2 + c3 split was deliberate — each slice shipped something usable on its own, and c3's scope was re-evaluated after c2 landed. One piece of c3's original scope (50KB soft threshold) was dropped at the gate rather than shipped reflexively. Boiling the lake means doing the complete thing, not every proposed thing.


## [0.12.0] - 2026-04-21

### Added
- **Always-on knowledge loading for `/company-workflow` (F000004, S000005).** Drop `.knowledge.yml { surface: always }` + `*.md` files under a category directory in `$AI_KNOWLEDGE_DIR`, touch `.claude/knowledge-enabled` in any repo where you want knowledge injected, and every `/company-workflow` invocation in that repo automatically includes your house-style guidance in Claude's context. No more copy-pasting a cpp style guide into every prompt. New `## Knowledge Helpers` + `## Knowledge Loading` sections in `skills/company-workflow/SKILL.md` do the discovery (category enumeration, `.knowledge.yml` parsing with tolerance for quoted values, inline comments, CRLF, and UTF-8 BOM), emit a `## Always-On Knowledge` block with absolute paths, and instruct Claude to Read them before answering.
- **Per-repo opt-in marker: `.claude/knowledge-enabled`.** Prevents cross-context contamination — a global `$AI_KNOWLEDGE_DIR` pointing at Company A's knowledge folder will NOT inject Company A guidance into Company B or OSS repos. Only loads when the current repo explicitly opts in. Marker hardening rejects symlinks, directories, and `repo/.claude -> /tmp/attacker` redirection.
- **`/company-workflow knowledge-doctor` diagnostic subcommand.** Prints the state of every precondition and every category (env var, repo root, marker presence, category surface modes, byte totals, cap status, final verdict). Debug setup issues in one shot instead of iterating with canary tests.
- **`AI_KNOWLEDGE_DISABLE=1` one-shot escape hatch.** Bypass loading for a single invocation without touching the committed marker. Useful when debugging a bad knowledge file. Accepts only explicit truthy values (`1`/`true`/`yes`/`on` and capitalized variants) — `AI_KNOWLEDGE_DISABLE=false` leaves loading enabled, matching user intuition.
- **Helpful missing-marker diagnostic.** When `$AI_KNOWLEDGE_DIR` is configured AND at least one category has `surface: always` AND the repo's marker is absent, emits exactly one stderr line naming the missing marker and the fix command. Problem + cause + fix in one line; silent fail used to train users to distrust the feature.
- **Forward compatibility for on-demand surfacing.** Categories authored today with `surface: on-demand` + `triggers: [...]` parse cleanly and are silently skipped in v1. When the on-demand follow-up ships, these files activate automatically — no re-authoring needed.
- **Shared fixture builder `scripts/test-helpers/knowledge.sh`.** `build_knowledge_fixture()` synthesizes knowledge dirs in `mktemp -d` per test case with canary strings (`CANARY_<cat>_TOP`, `CANARY_<cat>_NESTED`). No fixtures committed under `skills/` — the knowledge dir is user-owned and external by design.
- **35+ new test assertions across `scripts/test.sh`.** T000006 c1: 15 helper self-tests covering parser edge cases (quoted/comment/CRLF/BOM/malformed) + enumeration determinism + nonexistent-dir handling. T000006 c2: 20 behavioral tests covering always-on emission, on-demand forward-compat, marker hardening (symlink/directory/nested-subdir all fail closed), 500-path cap enforcement, yml edge cases, absolute-path-with-spaces, invalid-env pass-through, and knowledge-doctor state reporting. Drift tripwire does real byte-level diff of helper function bodies between `## Knowledge Helpers` and `## Knowledge Loading` blocks — prevents silent drift between the canonical definitions and their inlined copy.
- **WORKFLOW.md `## Knowledge Configuration` rewrite with Quick Start IA.** Copy-paste 5-line quick-start, troubleshooting table with problem+cause+fix for every common trap, documented escape hatches, explicit security callout covering prompt-injection risk + control-char rejection + hidden-dir skip + parent-symlink hardening.

### Changed
- **`skills/company-workflow` bumped to v3.1.0.** Additive feature; no breaking changes to existing `validate` command behavior. Zero regression assertion: `/company-workflow validate` output is byte-identical when `$AI_KNOWLEDGE_DIR` is unset and `.claude/knowledge-enabled` is absent.
- **F000004 scope restructure.** Collapsed former S000005 "always-on-loading" + S000006 "on-demand-matching" stories into single `S000005_knowledge_loading` (same PR, both surfacing modes' infrastructure shared one helper layer; slice boundary was bookkeeping). S000006 slot now holds `S000006_personal_workflow_port` (parity port of the knowledge feature to `/personal-workflow`), which was scaffolded, /autoplan-reviewed, and DEFERRED after dual-voice CEO review flagged it as symmetry work rather than product work for a single-user workbench. Unblock condition: a specific personal-repo user incident where missing knowledge-loading blocks work.

### Deferred
- **On-demand trigger matching (c3 follow-up).** Parsing infrastructure is in place (forward-compat parse-and-discard); matching logic + trigger DSL + match log + 50KB soft threshold will land in a follow-up story. Unblock condition: a specific user incident where always-on alone was insufficient and on-demand triggers would have saved context or time. Re-evaluated if Anthropic ships native Claude Code knowledge-base support first.

### Rationale
Ships the user-visible half of F000004. Knowledge moves from "the skill knows where your folder is" (v0.11.0) to "the skill reads from your folder and Claude acts on it" (this release). The half-deferred (on-demand matching) was explicitly evidence-gated after /autoplan CEO dual-voice review converged that v1 had 60% of the complexity for 30% of the value without documented user demand. Boiling the lake here means deciding what NOT to boil, not just what to boil.


## [0.11.0] - 2026-04-19

### Added
- **Knowledge integration scaffolding for company-workflow (F000004, S000004 slice).** Introduces the `AI_KNOWLEDGE_DIR` environment variable as the seam between the skill and an external knowledge folder for coding guidance and company-specific domain knowledge. When set to a valid directory, downstream features (always-on category loading in S000005, on-demand trigger matching in S000006 — both unshipped) will consume its contents. When unset or invalid, the skill still functions; only knowledge features are disabled. New `## Knowledge Resolution` section in `skills/company-workflow/SKILL.md` (bash block running after Path Resolution) resolves the env var, validates the path with `[-e]` and `[-d]` checks, sets skill-local `$_KNOWLEDGE_DIR`, and emits one of three distinct warnings on stderr (not-set / not-found / not-a-directory). Exit code stays 0. New `## Knowledge Configuration` section in `skills/company-workflow/WORKFLOW.md` documenting setup, the flexible top-level category layout (arbitrary subfolder names, nesting allowed), and the `.knowledge.yml` schema (`surface: always | on-demand` + `triggers: [...]`) that S000005/S000006 will consume.
- **Full work-item decomposition for F000004 knowledge integration.** 1 feature TRACKER + feature-level milestones, 3 user-stories (S000004 env-var-resolution, S000005 always-on-loading, S000006 on-demand-matching) each with TRACKER + PRD + ARCHITECTURE + TEST-SPEC, and 8 tasks (T000003..T000010) each with TRACKER + test-plan. Uses personal-workflow structure (3-phase lifecycle Track / Implement / Ship). 30 artifacts total. S000004 shipped complete in this PR; S000005 and S000006 are future slices that share `skills/company-workflow/SKILL.md` and must land sequentially.
- **T000004 test coverage for the Knowledge Resolution block.** New "Regression test (T000004)" section in `scripts/test.sh` with 11 scripted assertions covering every branch and edge case: Tier 1 structural greps (section present, variable references, WORKFLOW.md docs, no stdout leakage), Tier 2 extract-and-exec against mocked env states (unset, empty-string, nonexistent path, path-is-file, valid dir, hostile newline input, parent-shell `set -e` safety). Uses portable `mktemp` patterns (GNU + BSD), single tmpdir with final cleanup. Case 9 (end-to-end regression diff) documented as manual-only — `/company-workflow validate` is an LLM-driven SKILL.md and cannot be invoked from bash CI per D000004 RCA.

### Fixed
- **Warning output in the Knowledge Resolution block is now newline-safe and terminal-safe.** The three invalid-path warnings previously echoed `$AI_KNOWLEDGE_DIR` raw. A hostile env var (embedded newline or terminal escape sequences) could split the warning into multiple stderr lines, breaking the documented "exactly one warning line" contract, or emit ANSI escapes that polluted the user's terminal. Now strips control characters via `tr -d '[:cntrl:]'` and truncates display at 200 characters with `...` before rendering. The filesystem tests still use the raw value; only display output is sanitized. Caught by Codex outside-voice during /plan-eng-review; pinned by T000004 case 13.

### Rationale
Three vertical slices for F000004 (resolve → load always-on → match on-demand) keep each PR reviewable on its own. S000004 ships the smallest viable increment: the skill knows where knowledge lives but does not read any knowledge file yet. Users can `export AI_KNOWLEDGE_DIR="$HOME/knowledge"` today and get the warning-every-invocation nudge if unset. Content loading lands in S000005 / S000006. Personal-workflow port is captured as a follow-up TODO in F000004 TRACKER, blocked on S000006.

### Migration note
Existing users will see a new stderr warning on every `/company-workflow` invocation until they configure `AI_KNOWLEDGE_DIR`. Exit code is unchanged (still 0) — the warning is intentional, it's the nudge to configure, not an error. `/company-workflow validate` stdout is byte-identical to before. All automated consumers (CI, scripting) are unaffected. Deploy: run `skills-deploy install --overwrite` to refresh `~/.claude/skills/company-workflow/SKILL.md` and `WORKFLOW.md`.

## [0.10.0] - 2026-04-17

### Changed
- **Hierarchy & Placement rules moved from enforcement to spec.** Both `skills/personal-workflow/WORKFLOW.md` and `skills/company-workflow/WORKFLOW.md` gain a new `### Hierarchy & Placement` section under "Scaffolding Conventions" that documents parent-child requirements (feature requires ≥1 user-story child; user-story requires ≥1 task child; defects/reviews/standalone-tasks have no required children), placement rules (features go in `features/`, defects in `defects/`, reviews in `reviews/` for company; user-stories nest under features; tasks nest under user-stories), and directory naming regex (`{ID}_{slug}/` where ID matches the type prefix F/S/T/D/R and slug matches `[a-z0-9_-]+`). The generating AI reads this spec at scaffolding time and follows it. Same trust model as D000007 (v0.9.0): templates + WORKFLOW.md are the single source of truth.

### Removed
- **`hierarchy` and `placement` blocks from `skills/personal-workflow/personal-artifact-manifests.json`** — these were the data feed for the enforcement code removed below. Schema is smaller and more consistent with D000007's "no separate config as source of truth" philosophy.
- **Hierarchy / placement enforcement from `skills/personal-workflow/check.md`** — the `[INCOMPLETE]` and `[MISPLACED]` flags (old Steps 19a, 19b, 19c, 19e) are gone. Old Step 19 "Check 4 — Structural Completeness + Orphan Detection" collapses into a single "Check 4 — Stray Directory Detection" that flags `[STRAY]` for non-work-item directories containing `.md` files. The `structure` badge, `completeness` field in the graph artifact, and `structural_rules` top-level field are all removed. The Badge Summary and Structural Summary sections in the generated report drop the corresponding columns. The `company-workflow` validator was NEVER wired to enforce these rules, so no changes there.
- **`/personal-workflow tree` subcommand and `skills/personal-workflow/tree.md`** — the tree subcommand was explicitly a structural-only view (per its own `tree.md` lines 4, 85, 116: "Non-structural badges always show '—'"). With structural enforcement gone, the command had no remaining purpose — `/personal-workflow check` already renders a tree view with the remaining template/lifecycle/traceability badges. Removed the file, the `tree` entry from `SKILL.md` usage + subcommand routing, the `tree (quick hierarchy view)` section in `WORKFLOW.md`, the `tree.md` entry from `skills-catalog.json` `files[]`, and `/personal-workflow tree` lines from both tracker templates, fixtures, and examples. Also scrubbed "structural completeness checks" phrasing from SKILL.md frontmatter descriptions and both catalog entries, and the stray "and tree" reference in `personal-artifact-manifests.json`'s description.

### Rationale
Adding hierarchy enforcement via a new config field + validator logic would have recreated the exact drift mechanism D000007 (v0.9.0, merged yesterday) eliminated by deleting `contract.json`. Putting the rules in `WORKFLOW.md` as prose that the AI reads is consistent with the rest of the skill architecture. If AI obedience proves unreliable in practice, a future validator can read its rules from `WORKFLOW.md` (one place, same spec the AI follows) rather than a separate config field.

### Migration note
Existing `work-items/features/*/` directories that have no user-story children (e.g., `F000002_system_health_v1/`) no longer surface as `[INCOMPLETE]` in the `/personal-workflow check` output. Pure behavior change for that validator. If your team depended on `[INCOMPLETE]` as a signal, move the check into a PR review step or a pre-commit hook that greps `WORKFLOW.md`'s "Required children" section.

## [0.9.1] - 2026-04-17

### Fixed
- **`/ship` and `/land-and-deploy` no longer waste 30 seconds on a wrong-then-right merge command in this repo** (D000008). Two related operational defects, both observed twice in this session: (1) `gh pr merge --auto --delete-branch` (per the upstream gstack /ship and /land-and-deploy Step 4) silently fails because gh CLI requires an explicit merge method when `--auto` is set — gh prints help and exits 0, no merge gets queued, the LLM only notices on the next `gh pr view`. (2) The fall-back `--delete-branch` flag does a local `git checkout main` for cleanup, which fails inside a worktree where the parent repo has `main` checked out. Local fix in this repo: a `## CI/CD merge convention` section in `CLAUDE.md` directing the LLM to use `gh pr merge <PR#> --auto --squash --delete-branch` (combined flags) and to use `gh api -X DELETE refs/heads/<branch>` for worktree-aware remote-branch cleanup. The next `/ship` + `/land-and-deploy` cycle in this repo will use the correct invocation directly with no fallback.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000008)" — 3 checks) that prevent the `## CI/CD merge convention` section in CLAUDE.md from being silently dropped: section header presence, `gh pr merge ... --auto --squash` invocation present, `gh api -X DELETE git/refs/heads` workaround present.

### Migration note
Upstream gstack fix is filed as a separate follow-up (out of scope for this PR). The local guard in `CLAUDE.md` is defense-in-depth and works regardless of which gstack version is installed.

## [0.9.0] - 2026-04-17

### Changed
- **Templates are now the single source of truth for both workflow skills** (D000007, supersedes D000004). Both `skills/company-workflow/contract.json` and `skills/personal-workflow/contract.json` are deleted. The validator now derives every structural rule (required frontmatter, required sections, section order, lifecycle phases, minimum checkbox count) from the matching template at runtime: it parses `templates/{skill}/tracker-{type}.md`, extracts frontmatter keys + `##` headers + `### Phase N:` headers + `- [ ]` count from the Lifecycle section, and validates instances against THAT. Edit a template, the validator's expectations move with it. Single source. No more drift between contract and templates.
- Skill major versions bumped: `personal-workflow` 1.0.0 → 2.0.0, `company-workflow` 2.1.0 → 3.0.0. Reflects the breaking change to the validator's input contract (no more `contract.json`).
- **`frontmatter.recommended` distinction is gone.** `repo` and `branch` were "recommended but not enforced" under the old contract. Under template-derived rules they're required (templates emit them). No observable change for compliant trackers.
- **`type_specific_optional` is gone too.** Per-type optional sections (e.g., `Reproduction Steps` for defects) are now inferred structurally — if the per-type template includes the section, instances need it; if not, they don't. Less declarative metadata, less drift.
- **Stricter checkbox enforcement.** The minimum checkbox count is read from the template at runtime, not from a config field. Trackers authored against an older template version that pre-dates new gates will surface as out-of-date — strictly correct, called out by the validator instead of silently passing.

### Removed
- `skills/company-workflow/contract.json` and `skills/personal-workflow/contract.json` — both deleted. After upgrading, run `skills-deploy install --overwrite` to refresh deployed copies. Existing deployed `~/.claude/skills/{company,personal}-workflow/contract.json` symlinks may linger as broken until manually removed (`rm ~/.claude/skills/{company,personal}-workflow/contract.json`); follow-up planned for `skills-deploy` to auto-clean orphan symlinks.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000007)" — 6 checks) that prevent re-introduction of the two-source-of-truth pattern: contract.json absent in both skills, validator files don't load contract.json at runtime (cat/jq/Read pattern grep), skills-catalog.json no longer references contract.json.

## [0.8.0] - 2026-04-16

### Added
- **PR description templates for company-workflow `task` and `defect` work items.** Two new templates designed as self-contained PR bodies that fit TFS's 4,000-character limit (TFS reviewers cannot click links to local work-item files like `RCA.md` or `test-plan.md`, so the PR body must inline-summarize). Defect template (~1,331 chars scaffolding, verified ~2,224 chars when filled with a realistic example): `[ID] {Name} (P{N})` → Summary → Symptom → Root Cause + Location → Fix → Changes → Test Coverage table. Task template (~976 chars scaffolding): `[ID] {Name}` → Summary → Motivation → Changes → Affected Workflows → Test Plan table. Both include strip-before-pasting instructions in an HTML comment header (frontmatter and comment block are stripped before pasting; only the body goes to TFS).
- `pr-description` artifact entry in `skills/company-workflow/company-artifact-manifests.json` for both `task` (template: `doc-pr-description-task.md`) and `defect` (template: `doc-pr-description-defect.md`). Filename is `PR-DESCRIPTION.md` in both cases. Aligns with the Phase 4: Ship lifecycle gate "PR description generated" already present in `tracker-task.md` and `tracker-defect.md`.
- `skills-catalog.json`: company-workflow templates list adds the two new templates (14 → 16 templates).

### Migration note
Existing company-workflow consumers with active `task` or `defect` work item directories will now see `PR-DESCRIPTION.md` flagged as missing by the directory-mode validator. Recommended migration: scaffold `PR-DESCRIPTION.md` from the new template at PR creation time (Phase 4: Ship). Older completed work items can either be backfilled or excluded from validation.

## [0.7.2] - 2026-04-16

### Changed
- **company-workflow Phase 2 trackers now gate on test verification** (D000006). All 4 tracker templates (defect, task, user-story, feature) gained a Phase 2 gate that requires the linked test-doc to be marked Pass before advancing to Review/Ship. Closes the loop where a tracker could ship with a half-empty `test-plan.md` that nobody ran. Defect: `Regression test added AND all cases in test-plan.md marked Pass`. Task: `All test cases in test-plan.md marked Pass`. User-story: `All P0 cases in TEST-SPEC.md marked Pass; remaining cases marked Pending/Skip with reason`. Feature: roll-up over child user-stories' TEST-SPECs.
- **test-plan vs TEST-SPEC scope contract is now explicit** (D000006). Top-of-file scope comments added to `templates/{company,personal}-workflow/doc-test-plan.md` ("ONE fix or ONE task; cases concrete and reproducible") and `doc-TEST-SPEC.md` ("ENTIRE user story; every PRD acceptance criterion across happy/edge/error paths"). New `### test-plan vs TEST-SPEC` subsection added to `skills/company-workflow/WORKFLOW.md` codifying the concrete-vs-broader split so authors pick by parent type, not preference.
- **`templates/{company,personal}-workflow/doc-test-plan.md` placeholders generalized** so the same template renders cleanly for both defects and tasks: `parent: {DEFECT_ID}` → `parent: {ITEM_ID}`, `title: "{Defect Name} — Regression Test Plan"` → `title: "{ITEM_NAME} — Test Plan"`. Both placeholders match the canonical UPPER_SNAKE form in WORKFLOW.md and are detectable by the directory-mode validator's `\{[A-Za-z_]+\}` placeholder regex.

### Added
- Regression tests in `scripts/test.sh` ("Regression test (D000006)" — 10 checks) that guard the new Phase 2 gates, scope comments, title generalization, and WORKFLOW.md subsection against silent removal. Greps anchor on `^- [ ]` checkbox prefix + key tokens so a future minor reword (`marked Pass` → `is Pass`) still trips the gate detection.

## [0.7.1] - 2026-04-16

### Fixed
- **`skills-deploy` now works on Windows** (D000005). Root cause: `jq.exe` on Windows writes output with CRLF line endings, which broke two things in `scripts/skills-deploy` — template-name validation (trailing `\r` failed `\.md$` regex checks) and integer comparisons (`files | length` returning `0\r` caused `[: : integer expression expected`). Fix: a single-line `jq()` shell-function wrapper that pipes `command jq` output through `tr -d '\r'`. No-op on Unix (no `\r` to strip); fixes every existing call site on Windows without per-call edits.
- The wrapper lives in three places for full coverage: `scripts/lib.sh` (picked up by the 8 scripts that source it — validate.sh, test.sh, doctor.sh, lint-skill.sh, deps.sh, generate-readme.sh, sync-upstream.sh, collection-version.sh), `scripts/skills-deploy` (standalone, does not source lib.sh), and `scripts/test-deploy.sh` (standalone).

### Added
- Regression tests in `scripts/test.sh` (5 checks under "Regression test (D000005)") that guard the `jq()` wrapper against silent removal and verify it strips CR while correctly propagating `jq -e` exit status through the `tr` pipe (requires `pipefail`, which all relevant scripts already set).

## [0.7.0] - 2026-04-16

### Added
- `templates/company-workflow/doc-feature-summary.md` — new feature-level roll-up template (Scope, Success Criteria, Constituent User-Stories, Out-of-Scope). Replaces the duplicated PRD/ARCHITECTURE/TEST-SPEC at feature scope.
- `feature-summary` artifact entry in `skills/company-workflow/company-artifact-manifests.json` (feature now requires tracker + feature-summary + milestones, 3 artifacts).
- D000003 defect spun into two: `D000003_company_workflow_feature_artifact_duplication` (this fix) and `D000004_company_workflow_contract_template_drift` (Issues 1 + 3, blocked on architectural rethink — see D000004 tracker).

### Changed
- **company-workflow feature artifact set narrows from 5 to 3.** Feature now requires `tracker + feature-summary + milestones`; user-story unchanged at 5 (`tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones`). The change eliminates duplicated PRD/ARCH/TEST-SPEC content between parent feature dirs and nested user-story dirs (verified concretely in ai-content `F973012/` containing `S1441024-hfss-integration/`).
- `templates/company-workflow/tracker-feature.md`: lifecycle gate "Doc triplet created (PRD + ARCHITECTURE + TEST-SPEC)" replaced with "Feature summary + milestones created"; review-phase "Doc triplet passes doc alignment check" replaced with "Feature summary + milestones pass alignment check".
- `skills/company-workflow/WORKFLOW.md`: Step 1 list and type-to-artifact summary table updated to reflect the 3-artifact feature set; rationale paragraph added pointing to D000003.
- `skills-catalog.json`: company-workflow templates list adds `company-workflow/doc-feature-summary.md` (13 templates → 14).

### Migration note
Existing company-workflow consumers (e.g., the ai-content repo) may have feature directories carrying legacy `PRD.md`, `ARCHITECTURE.md`, and `TEST-SPEC.md` files at feature scope. The validator no longer **requires** these files at feature scope. Note: the validator currently iterates only the manifest's required-artifact list and does not scan for unexpected files, so legacy files happen to be ignored — but this is implementation behavior, not a guaranteed contract. Recommended migration: keep one canonical copy of PRD/ARCHITECTURE/TEST-SPEC at the user-story level (the nested `S*-*/` directory); clean up the feature-scope copies when convenient. New features scaffolded after this version use only `feature-summary.md` + `milestones.md` at the feature level.

### Out of scope (deferred to D000004)
Two related drift defects originally bundled with this work — `workflow_type` frontmatter contract/template drift and `Acceptance Criteria` / `Reproduction Steps` section-order drift — were spun out to D000004 because they hit a separate architectural blocker (the validators are LLM-driven SKILL.md, not executable scripts; the originally-planned bash round-trip runner is unimplementable as designed). See `work-items/defects/D000004_company_workflow_contract_template_drift/` for the rethink. This release ships Issue 2 (artifact duplication) cleanly without that question resolved.

## [0.6.0] - 2026-04-15

### Added
- New `/personal-workflow` skill: self-contained work item validation with check + tree subcommands
- `skills/personal-workflow/SKILL.md`: thin router with 2-level path resolution and stale rules detection
- `skills/personal-workflow/check.md`: Tier 1 (contract.json foundation) + Tier 2 (hierarchy, cross-refs, graph, report)
- `skills/personal-workflow/tree.md`: quick hierarchy view with structural badges
- `skills/personal-workflow/WORKFLOW.md`: scaffolding conventions, 3-phase lifecycle, branch naming rules
- `skills/personal-workflow/contract.json`: 3-phase lifecycle structural validation rules
- `skills/personal-workflow/personal-artifact-manifests.json`: type-to-artifact mapping with hierarchy enforcement
- 7 test fixtures (5 file-mode, 2 directory-mode) for personal-workflow validation
- Personal-workflow templates at `templates/personal-workflow/` (10 templates: 4 trackers + 6 docs)
- Portability, catalog, and stale-reference tests for personal-workflow in test.sh

### Changed
- Templates moved from flat `templates/` to `templates/personal-workflow/` (mirrors company-workflow pattern)
- Template fallback chain simplified from 3-level to 2-level (dropped `~/.claude/spec/templates/`)
- CLAUDE.md updated: 3 skills listed, routing includes /personal-workflow, template docs reflect named sets
- template-registry.json: "workbench" set replaced with "personal-workflow" set
- skills-catalog.json: "docs" entry replaced with "personal-workflow", "templates" entry reduced to doc-SKILL-DESIGN.md only
- validate.sh orphan template detection now walks subdirectories recursively
- test.sh template content tests updated from root paths to `templates/personal-workflow/`
- test-deploy.sh multi-file skill test updated from docs to personal-workflow
- Tracker templates reference `/personal-workflow check` and `/personal-workflow tree` (was `/docs check` and `/docs tree`)

### Removed
- `/docs` skill (skills/docs/) including init.md, check.md, tree.md, DESIGN.md, CHANGELOG.md
- Narrative doc generation (PHILOSOPHY.md/OVERVIEW.md) and claims sidecar staleness detection
- `artifact-manifests.json` at repo root (moved into skill as personal-artifact-manifests.json)
- `rules/work-items.md` global rules file (replaced by WORKFLOW.md inside the skill)
- 10 flat templates at `templates/` root (moved to `templates/personal-workflow/`)

## [0.5.0] - 2026-04-15

### Added
- WORKFLOW.md: doc-driven development guide with scaffolding conventions, ID generation, directory layout, and 4-phase lifecycle
- 13 example files (1 per template) for AI-assisted doc generation, themed around API rate limiting
- `skills-deploy` now symlinks skill subdirectories (examples/, reference/, philosophy/, fixtures/)
- `skills-deploy remove` cleans up subdirectory symlinks
- `skills-deploy relink` recreates subdirectory symlinks
- `skills-deploy doctor` checks subdirectory symlink health (missing + broken)
- Migration guard: diff-then-replace for manual-to-symlink subdirectory migration
- 7 new automated tests for subdirectory lifecycle (Tests 13-19)
- PRD Step 3 (Implement and Iterate) fleshed out with validate-as-continuous-gate workflow

### Changed
- SKILL.md now references WORKFLOW.md via Getting Started section
- skills-catalog.json includes WORKFLOW.md in company-workflow files array
- S000003 work items closed (all children shipped)

### Fixed
- test-deploy.sh referenced deleted skill-author skill (replaced with system-health)
- shellcheck SC2088 warning in test.sh (tilde in quotes)

## [0.4.0] - 2026-04-15
### Changed
- Company-workflow skill (v2.0.0): unified validate command replaces 3 separate subcommands (validate/check/create)
- File mode validates single trackers against contract.json; directory mode validates entire work items against company-artifact-manifests.json
- Type spelling normalized from `userstory` to `user-story` across manifest, templates, and registry
- Tracker-review.md now uses phase headings (### Phase N:) matching all other tracker types
- Tracker-feature.md doc triplet is unconditionally required (removed "N/A for small features")
- Handoff section removed from contract.json and tracker-review.md (unused across all types)

### Added
- `company-artifact-manifests.json` declares type-to-artifact mapping for all 5 company types
- Directory-mode fixtures: `valid-feature-dir/` (5 artifacts) and `invalid-missing-artifact-dir/` (missing PRD)
- Placeholder detection in frontmatter values (regex `{[A-Za-z_]+}`)
- CLAUDE.md routing rule for `/company-workflow validate`
- `skills-deploy` now deploys JSON files alongside skill markdown
- `skills-deploy` now supports subfolder templates (e.g., `company-workflow/tracker-feature.md`)

### Fixed
- `skills-deploy` template name validation blocked subfolder paths (regex extended for one subfolder level)
- `skills-deploy` path traversal prevention (blocked `..` segments in template names)
- `skills-deploy relink` now creates parent directories for nested templates

### Removed
- T000005 (check subcommand) and T000006 (create subcommand) work items (never implemented, replaced by unified validate)

## [0.3.8] - 2026-04-13
### Fixed
- Work items now live in type subfolders: `work-items/features/` and `work-items/defects/`
- All artifact filenames consistently ID-prefixed (`D000001_TRACKER.md`, `F000001_milestones.md`)
- Defect template Phase 2 gate simplified to "Fix committed" (removed "with regression test")
- D000001 tracker and test-plan closed out (was left active after fix shipped in #28)
- `/docs check` placement validation updated for type subfolders (placement, stray detection, tree rendering, graph paths)

### Added
- D000002 work item scaffolded: work item format consistency defect with full artifact set

## [0.3.7] - 2026-04-13
### Fixed
- Milestones artifact moved from user-story to feature type in manifest and rules (milestones track feature delivery, not individual stories)
- Feature tracker template now scaffolds milestones.md at feature level
- User-story tracker template no longer references milestones scaffolding
- Template frontmatter parent placeholder updated from `{USER_STORY_ID}` to `{FEATURE_ID}`
- F000001 milestones.md relocated from story level (S000001) to feature level
- First defect work item (D000001) scaffolded with full defect artifact set

## [0.3.6] - 2026-04-13
### Changed
- Lifecycle simplified from 4 phases (Track/Implement/Review/Ship) to 3 phases (Track/Implement/Ship) across all 4 tracker templates
- `/review` gate removed from templates since `/ship` runs pre-landing review internally
- Doc checks (`/docs check`, `/docs tree`) moved into Ship phase as pre-flight steps
- Template fallback chain standardized to 3-level across all docs: `templates/` > `~/.claude/spec/templates/` > `~/.claude/templates/`
- Task tracker "Design doc approved" gate removed (parent story concern, not task concern)
- F000002 tracker status corrected from `active` to `closed` to match checkbox state
- Stale examples in check.md and tree.md updated to reflect current hierarchy (1 story, 1 task)
- PHILOSOPHY.md aligned: doc triplet now described as user-story-only, fallback chain updated to 3-level

### Removed
- 8 feature-level docs that violated manifest rules: PRD, ARCHITECTURE, TEST-SPEC, milestones from both F000001 and F000002 (features get tracker only per artifact-manifests.json)

## [0.3.5] - 2026-04-13
### Changed
- Closed F000001_workflow_alpha: verified consistency across 12 work item docs (structure, logic, cross-refs), fixed stale lifecycle gates, aligned architecture diagram with manifest
- Feature type now requires only TRACKER in manifest; doc triplet (PRD, ARCHITECTURE, TEST-SPEC, milestones) lives at user-story level
- Feature tracker template no longer suggests decomposing into tasks directly (hierarchy requires tasks under stories)

### Removed
- 7 dead templates: GENERATION-GUIDE (4 files), contract-ARCHITECTURE, contract-PRD, contract-TEST-SPEC

## [0.3.4] - 2026-04-13
### Changed
- Consolidated F000001 work items: 3 user stories (S000001, S000002, S000003) merged into S000001_workflow_implementation, 4 tasks merged into T000001_implement_workflow
- Doc triplet from S000003 (most complete) preserved via git mv with rename history
- All acceptance criteria, insights, and journal entries merged with source attribution

### Removed
- S000002_template_consolidation directory and all artifacts
- S000003_structural_completeness directory and all child tasks (T000002, T000003, T000004)

## [0.3.3] - 2026-04-12
### Added
- `/docs check` now writes a human-readable health report to `.docs/work-item-report.md` (tree, badge summary table, findings by severity, structural summary)
- `/docs tree` now writes a lightweight tree report to `.docs/work-item-tree.md`
- Runbook-style lifecycle phases in all 4 tracker templates: numbered procedural steps with exact commands + checkbox completion gates
- Each work item type gets its own runbook (feature coordinates via children, user-story uses `/office-hours` + doc triplet, task is simpler, defect uses `/investigate`)

### Changed
- All 8 existing trackers migrated to runbook format with checkbox states preserved
- Feature Phase 2 shifts from hands-on implementation to child coordination
- `.docs/` directory now gitignored (generated artifacts, regenerated each run)
- `MISSING` and `STRAY` statuses now included in report severity mapping

## [0.3.2] - 2026-04-12
### Added
- `/docs check` now enforces structural completeness: features must have user stories, stories must have tasks
- `/docs tree` standalone subcommand for quick hierarchy view with structural badges
- Work item tree report with per-node badges (template, lifecycle, traceability, structure)
- Machine-readable `.docs/work-item-graph.json` artifact with nodes, badges, completeness, and structural rules
- Hierarchy and placement rules in `artifact-manifests.json` (configurable per-project)
- Orphan/misplaced item detection (tasks under features flagged as MISPLACED)
- Lifecycle cross-reference: "broken down" checked with 0 children flags LIFECYCLE_INCONSISTENT
- Badge taxonomy mapping all check statuses to 4 categories with severity ordering
- S000003 work item (structural completeness) with T000002 (implementation) and T000003 (human-readable report)

### Changed
- `/docs check` no longer stops when claims.json is missing; staleness checks skip, work item checks run independently
- docs skill bumped to v0.3.0

## [0.3.1] - 2026-04-11
### Added
- PHILOSOPHY.md with claims sidecar for staleness detection
- S000002 milestones and T000001 test-plan (scaffolded from templates)
- F000001 and S000002 TEST-SPEC traceability entries for untested P0 stories

### Fixed
- S000001 and S000002 tracker type spelling ("userstory" to "user-story")
- S000001 and S000002 missing parent field in tracker frontmatter
- S000002 TEST-SPEC stale references to deleted tracker-review.md
- VERSION format (4-digit to semver)

## [0.3.0] - 2026-04-11
### Added
- `/docs check` now validates work items against their templates: template compliance, lifecycle consistency, and PRD-to-TEST-SPEC traceability
- Normalization layer handles type spelling mismatches and ID-prefixed filenames automatically
- P0-only traceability enforcement (P1/P2 stories get advisory-level flags, not warnings)
- Defensive error handling for missing manifests, templates, and malformed frontmatter

### Fixed
- Removed stale review-type references from F000001 work items (leftover from /workflow deletion)

## [0.2.4] - 2026-04-11
### Added
- system-health V1: feature work item (F000002) with TRACKER, PRD, ARCHITECTURE, TEST-SPEC, and milestones
- system-health version bump to 1.0.0 (no functional changes from 0.3.0)
- Backfilled missing system-health [0.3.0] CHANGELOG entry (usage trends, anomaly detection)

## [0.2.3] - 2026-04-11
### Removed
- `/skill-author` skill: 6-stage guided pipeline replaced by CLAUDE.md "Creating a new skill" section + direct script usage
- 6 lifecycle scripts: `skill-design.sh`, `create-skill.sh`, `skill-check.sh`, `skill-version.sh`, `skill-ship.sh`, `skill-migrate.sh`

### Changed
- Moved skill-author's 5 templates (doc-SKILL-DESIGN.md, generation guides) to the `templates` catalog entry
- Rewrote test.sh integration tests to use manual skill creation instead of deleted scaffolding scripts
- Fixed lint-skill.sh exit code handling in test.sh (pre-existing issue, warnings are non-zero exit)
- Updated CLAUDE.md, README.md, CONTRIBUTING.md to reflect 2-skill repo

### Added
- CLAUDE.md "Creating a new skill" section with frontmatter schema, catalog JSON format, and validation instructions

## [0.2.2] - 2026-04-11
### Removed
- `/workflow` skill (7 files): implement, review, and ship phases were redundant with gstack; track phase replaced by CLAUDE.md rules
- `/contracts` skill (3 files): doc triplet enforcement replaced by CLAUDE.md validation rules
- Orphan doc directories for deleted skills (docs/workflow/, docs/contracts/)

### Added
- `## Work Item Templates` section in CLAUDE.md: type-aware scaffolding, 3-level template fallback, branch conventions, ID generation, git-journal synthesis, contract validation
- `templates` catalog entry: templates-only distribution vehicle (no SKILL.md, 13 templates)
- `artifact-manifests.json` at repo root: canonical type-to-artifact mapping (previously external-only)
- Templates-only support in skills-deploy: install, remove, and doctor handle catalog entries with no SKILL.md

### Changed
- skills-catalog.json: workflow and contracts entries replaced by templates entry
- test-deploy.sh: test fixtures rewritten from workflow/contracts to docs/templates
- README.md: updated to template library identity (3 skills + template library)
- skills/docs references to /contracts updated to reflect removal

## [0.2.1] - 2026-04-11
### Changed
- Tracker templates rewritten for solo-dev workflow: removed enterprise gates ("reviewer noted", "Linux branch build"), JIRA/TFS URLs, and redundant `workflow_type` field
- User-story template now includes `parent` field and normalized `type: user-story` (was `userstory`)
- Template validation in track.md is now type-aware: defect/task no longer require PRD/ARCHITECTURE/TEST-SPEC templates

### Removed
- Review work item type: deleted tracker-review.md, doc-review-notes.md, doc-scrum.md, and TRACKER-TEMPLATE.md
- Scrum subcommand and `review-*` branch pattern from workflow skill
- 4 orphaned template references from skills-catalog.json

### Added
- 6 template content smoke tests in test.sh (enterprise gate checks, JIRA/TFS detection, gate count validation, review type removal)

## [0.2.0] - 2026-04-11
### Added
- New `/docs` skill with two subcommands: `init` (generate PHILOSOPHY.md or OVERVIEW.md) and `check` (staleness detection + coherence)
- Claims sidecar (`.docs/claims.json`) maps doc sections to evidence files with commit SHAs for diff-based staleness detection
- Unreachable commit guard for rebase/force-push resilience in staleness checks
- Schema validation for claims.json on read with clear error messages
- Quick Start workflow example in SKILL.md

## [0.1.0] - 2026-04-11
### Added
- Collection versioning with VERSION file at repo root
- `collection-version.sh` script (get, bump, manifest subcommands)
- Auto-bump collection version on `skill-ship.sh`
- VERSION consistency checks in `validate.sh`
- Collection version tracking in `skills-deploy` manifest
- Drift detection via on-demand manifest regeneration in `skills-deploy doctor`
- Semver semantics defined (patch/minor/major for the collection)

### Changed
- `skill-ship.sh` now creates a single commit with both skill tag and collection v-tag
- `skills-deploy install` records `collection_version` and `collection_commit`
- `skills-deploy doctor` reports collection version status and template drift
- `lib.sh` gains `file_checksum()`, `read_version()`, and `version_gte()` helpers
