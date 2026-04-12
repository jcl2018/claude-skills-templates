---
type: test-spec
parent: ""
feature: F000002_system_health_v1
title: "system-health V1 — Test Specification"
version: 1
status: Approved
date: 2026-04-11
author: chjiang
prd: F000002_PRD.md
architecture: F000002_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Skill scan produces output | AC-1 | ~/.claude/skills/ has skills | Run Step 1 bash | SKILL:/FM:/REF: lines emitted | P0 | E2E |
| 2 | core | Graph analysis produces adjacency list | AC-2 | Scan output available | Run Step 2 bash | EDGE:/INDEG:/ORPHAN: lines emitted | P0 | E2E |
| 3 | core | Filesystem checks produce output | AC-3 | ~/.claude/ exists | Run Step 3 bash | DISK:/HISTORY:/SESSIONS: lines emitted | P0 | E2E |
| 4 | core | Scored composite computed | AC-4 | Steps 1-3 completed | Run Step 5 | 4 bucket scores + composite | P0 | E2E |
| 5 | observability | Usage trends produce output | AC-5 | skill-usage.jsonl exists | Run Step 4.5 | USAGE_* lines emitted | P0 | E2E |
| 6 | integration | Waza runs when installed | AC-6a | Waza at expected path | Run Step 4 | Waza output in appendix | P1 | E2E |
| 7 | resilience | Waza absent degrades gracefully | AC-6b | Waza not installed | Run Step 4 | "Waza not installed" message, no crash | P0 | E2E |
| 8 | resilience | jq absent degrades gracefully | — | jq not in PATH | Run full skill | Structural checks work, settings/usage skipped | P1 | E2E |
| 9 | resilience | Corrupt usage JSONL handled | — | Invalid JSON in file | Run Step 4.5 | USAGE_PARSE_ERROR, no crash | P1 | E2E |
| 10 | resilience | Empty usage file handled | — | File exists but empty | Run Step 4.5 | USAGE_NO_DATA message | P1 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md exists | Skill file present | `test -f skills/system-health/SKILL.md` |
| S2 | core | Frontmatter has name field | Required frontmatter | `grep -q '^name:' skills/system-health/SKILL.md` |
| S3 | core | Frontmatter has version field | Version tracked | `grep -q '^version:' skills/system-health/SKILL.md` |
| S4 | core | Frontmatter has description field | Description present | `grep -q '^description:' skills/system-health/SKILL.md` |
| S5 | core | Frontmatter has allowed-tools | Security boundary defined | `grep -q 'allowed-tools:' skills/system-health/SKILL.md` |
| S6 | core | No Edit in allowed-tools | Read-only enforced | `! grep -A10 'allowed-tools:' skills/system-health/SKILL.md \| grep -q 'Edit'` |
| S7 | core | No Write in allowed-tools | Read-only enforced | `! grep -A10 'allowed-tools:' skills/system-health/SKILL.md \| grep -q 'Write'` |
| S8 | core | Catalog entry exists | Registered in catalog | `jq -e '.[] \| select(.name=="system-health")' skills-catalog.json` |
| S9 | core | Catalog version matches SKILL.md | Version consistency | Compare catalog version with SKILL.md version |
| S10 | core | DESIGN.md exists | Design documented | `test -f skills/system-health/DESIGN.md` |
| S11 | core | CHANGELOG.md exists | History tracked | `test -f skills/system-health/CHANGELOG.md` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full health check | Invoke `/system-health` | Dashboard with all 5 sections, scored composite, recommendations | All sections present, score 0-10, no errors |
| E2 | core | Quick mode | Invoke `/system-health --quick` | Dashboard without waza or usage trends | Waza and usage sections absent, scored sections present |
| E3 | resilience | No waza | Remove waza, invoke `/system-health` | "Waza not installed" message, rest of dashboard works | No crash, install instructions shown |
| E4 | observability | Usage with all 3 schemas | Populate skill-usage.jsonl with simple/intermediate/v1 entries | All entries normalized, per-skill breakdown shown | No parse errors, all schemas handled |
| E5 | core | Trend tracking | Run /system-health twice | Second run shows delta from first | "up/down X.X from last run" appears |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Linux compatibility | Dev environment is macOS only | bash/jq commands are POSIX-compatible, low risk |
| 100+ skills performance | No test environment with that many skills | Grep scope limited to *.md/*.json, should scale |
| Circular dependency detection | Best-effort in bash, no formal cycle detection algorithm | Documented as best-effort in SKILL.md |
| Concurrent runs | Single-user skill, no locking needed | JSONL append is atomic on most filesystems |
