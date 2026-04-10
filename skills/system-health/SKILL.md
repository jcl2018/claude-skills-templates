---
name: system-health
description: "Unified health dashboard: Waza config hygiene (layers 1-6) + governance checks (layer 7) + doc quality (layer 8) + deploy state (layer 9). Replaces /project:audit."
allowed-tools:
  - Bash
  - Read
  - Edit
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# /health — Unified Health Dashboard

9-layer health check for home-setup. Layers 1-6 come from Waza's config hygiene
checks (inlined). Layers 7-9 are custom governance, doc quality, and deploy state.

Replaces: /project:audit. Calls /align-feature-contract for doc triplet checks.

## Usage

- `/health` — full 9-layer audit
- `/health --scope docs/<family>/` — doc triplet quality only (layer 8)
- `/health --scope work-items/<slug>/` — work item quality (tracker + triplet)
- `/health --layer config` — Waza config hygiene only (layers 1-6)
- `/health --layer governance` — governance + deploy only (layers 7, 9)
- `/health --layer docs` — doc quality only (layer 8)

## Step 0: Parse arguments and detect scope

Parse the user's invocation for `--scope <path>` and `--layer <name>` arguments.
Default: all 9 layers, no scope restriction.

Valid `--layer` values: `config` (1-6), `governance` (7, 9), `docs` (8), `all` (1-9).

If `--scope` is provided, only layer 8 checks run, scoped to that directory.

## Step 1: Collect data (deterministic)

Run the deterministic health checks script:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
bash "$REPO_ROOT/scripts/health-checks.sh"
```

This produces structured output for layers 7 and 9. Capture and parse the results.

## Step 2: Layers 1-6 — Config Hygiene (from Waza)

Skip if `--layer governance` or `--layer docs` or `--scope` is set.

Run Waza's data collection to gather config state:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
bash "$REPO_ROOT/skills/waza/health/scripts/collect-data.sh"
```

Then apply the 6-layer Waza rubric to the collected data:

### Layer 1: CLAUDE.md Quality
- Is it short and executable (not prose-heavy)?
- Does it have build/test commands?
- Are there nested CLAUDE.md conflicts (global vs local)?
- Are there duplicate or conflicting rules between global and local?

### Layer 2: Rules Structure
- Are rules properly split by concern (not monolithic)?
- Do rule `paths:` globs match at least one file?
- Are language-specific rules in separate files?

### Layer 3: Skills
- Are skill descriptions under 12 words and trigger-specific?
- Do all skills have valid SKILL.md frontmatter?
- Are there orphan skills (installed but not in catalog)?

### Layer 4: Hooks
- Are hooks present if the project needs them?
- Do configured hooks reference scripts that exist?
- Are there dead hooks pointing to missing scripts?

### Layer 5: Sub-agents
- Are sub-agents properly configured (if used)?

### Layer 6: Verifiers
- MCP servers: are they configured and responsive?
- settings.json: does it exist and validate?

Score each layer 0-10. Aggregate as config hygiene score (35% weight).

## Step 3: Layer 7 — Governance

Skip if `--layer config` or `--layer docs` or `--scope` is set.

Read the output from scripts/health-checks.sh for these checks:

- **Upstream freshness:** Is gstack version current? Is Waza version current?
- **Skill usage analytics:** Check `~/.gstack/analytics/skill-usage.jsonl` for unused skills
- **Template coverage:** All artifact types in artifact-manifests.json have templates
- **Contract coverage:** All active custom skills have entries in skill-contracts.json
- **Principle alignment:** CLAUDE.md rules match the 5 active principles
- **Contract validation:** Run `bash scripts/validate-skill-contracts.sh`
- **CLI dependencies:** git, gh, jq, codex available?
- **Commands non-empty:** All command .md files have content
- **Overlapping scope:** No skill/rule duplication

Score 0-10. Weight: 20%.

## Step 4: Layer 8 — Doc Quality

Skip if `--layer config` or `--layer governance` is set.

If `--scope` is provided, run only on the scoped directory.
Otherwise, discover all doc triplet families:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
for dir in "$REPO_ROOT"/docs/*/; do
  [ -f "$dir/PRD.md" ] && [ -f "$dir/ARCHITECTURE.md" ] && [ -f "$dir/TEST-SPEC.md" ] && echo "TRIPLET: $dir"
done
```

For each family, evaluate 5 dimensions:
- **Readability (1-5):** Clear, concise, jargon-free
- **Completeness (1-5):** All sections filled, no placeholders
- **Consistency (1-5):** Docs agree with each other
- **Staleness:** Last updated vs recent commits in affected files
- **Coverage (1-5):** P0 stories have tests, components have owners

Also check (from audit-spec.json governance pass):
- Broken links in docs (G1.1)
- CLAUDE.md layout tree vs actual repo (G1.2)
- TODOS.md staleness >30 days (G1.5)
- Factual claims vs current state (G2.1)
- Doc lane compliance (G2.4)
- Cross-doc consistency (G2.5)
- Empty .md files (4.3)
- Hardcoded counts (2.6, D9 rule)

Invoke `/align-feature-contract` on each triplet via the Skill tool for template
alignment and cross-doc traceability checks.

If `--scope work-items/<slug>/` is set, also check:
- Tracker frontmatter (required fields present)
- Lifecycle section (4 phases with checkboxes)
- Log non-empty
- AC defined
- Write findings to the work item's journal (preserves /work-audit behavior)

Score 0-10. Weight: 25%.

## Step 5: Layer 9 — Deploy State

Skip if `--layer config` or `--layer docs` or `--scope` is set.

Read the output from scripts/health-checks.sh for these checks:

- **Deploy drift:** `bash scripts/deploy.sh --dry-run` and diff against installed
- **Skill sync:** Every skill in catalog is deployed to ~/.claude/skills/
- **Bin scripts:** skills/bin/* scripts exist where expected
- **Settings:** baseline + override match installed settings.json
- **Orphan skills:** installed skill dirs not in catalog
- **Stale sessions:** ~/.gstack/sessions files >24h old
- **Temp files:** .tmp, .pending-*, .bak accumulation
- **Oversized files:** >10MB detection
- **Empty dirs:** incomplete cleanup
- **~/.claude/ size:** disk usage tracking
- **~/.gstack/ size:** working dir growth
- **Analytics volume:** JSONL file growth
- **Active sessions:** leaked process detection
- **Memory files:** auto-memory accumulation
- **settings.json exists:** must exist for Claude Code to work
- **Repo status:** uncommitted changes (P11)

Score 0-10. Weight: 20%.

## Step 6: Score and Dashboard

Compute weighted composite score:

| Layer Group | Layers | Weight |
|-------------|--------|--------|
| Config hygiene | 1-6 | 35% |
| Governance | 7 | 20% |
| Doc quality | 8 | 25% |
| Deploy state | 9 | 20% |

If a layer group was skipped (via --layer or --scope), redistribute weight
proportionally among remaining groups.

Present results:

```
UNIFIED HEALTH DASHBOARD
========================

Project: home-setup
Branch:  {branch}
Date:    {date}

Layer Group      Layers    Score   Status     Details
-----------      ------    -----   ------     -------
Config hygiene   1-6       8/10    WARNING    2 rule scope issues
Governance       7         9/10    WARNING    1 unused skill
Doc quality      8         7/10    WARNING    infrastructure staleness
Deploy state     9         10/10   CLEAN      Zero drift

COMPOSITE SCORE: 8.3 / 10

Per-family doc quality:
  align-feature-contract  4.8/5
  audit                   5.0/5
  infrastructure          4.0/5
  upstream-skills          5.0/5
  work-pipeline           4.4/5
```

Status labels: 10 = CLEAN, 7-9 = WARNING, 4-6 = NEEDS WORK, 0-3 = CRITICAL.

## Step 7: Persist and Trend

```bash
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" && mkdir -p ~/.gstack/projects/$SLUG
```

Append one JSONL line to `~/.gstack/projects/$SLUG/health-history.jsonl`:

```json
{"ts":"ISO8601","branch":"main","score":8.3,"config":8,"governance":9,"docs":7,"deploy":10,"duration_s":N}
```

If prior entries exist, show trend (last 5 runs).

## Step 8: Recommendations

List top issues by impact (weight * score deficit), highest first:

```
RECOMMENDATIONS (by impact)
============================
1. [HIGH] Fix 2 rule scope issues (Config: 8/10, weight 35%)
2. [MED]  Address infrastructure doc staleness (Docs: 7/10, weight 25%)
3. [LOW]  Remove 1 unused skill (Governance: 9/10, weight 20%)
```

Save a snapshot to `docs/inspections/health-{date}.md`.

## Rules

- **Read-only by default.** Report findings, don't auto-fix.
- **Deterministic checks in bash.** scripts/health-checks.sh handles file existence,
  version comparison, deploy drift. The SKILL.md handles analysis and scoring.
- **Delegate doc triplet checks.** Call /align-feature-contract, don't duplicate its logic.
- **Preserve journal-writing.** When --scope targets a work item, write findings to its journal.
- **audit-spec.json is source of truth.** The 38 checks defined there map to layers 7-9.
  When audit-spec.json changes, update the checks in this skill accordingly.
