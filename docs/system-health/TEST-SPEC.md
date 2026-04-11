---
type: test-spec
feature: system-health
title: "System Health v0.2.0 — Test Specification"
version: 2
status: Active
date: 2026-04-11
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Full health produces scored dashboard | AC-1 | ~/.claude/ exists with skills | Run `/system-health` | 4-bucket scored dashboard with composite score | P0 | E2E |
| 2 | graph | Dependency graph detects hubs | AC-2 | 5+ skills installed | Run `/system-health` | Top 3 hubs by in-degree listed | P0 | E2E |
| 3 | graph | Orphan skills detected | AC-2 | Skill with zero in-degree exists | Run `/system-health` | Orphan skill listed | P0 | E2E |
| 4 | graph | Dead references detected | AC-3 | Skill references non-existent skill | Run `/system-health` | Dead reference listed with source and target | P0 | E2E |
| 5 | graph | Broken symlinks detected | AC-3 | Broken symlink in ~/.claude/skills/ | Run `/system-health` | Broken symlink listed | P0 | E2E |
| 6 | filesystem | Disk usage reported | AC-4 | ~/.claude/ has content | Run `/system-health` | Per-subdirectory du output | P0 | E2E |
| 7 | filesystem | Stale sessions counted | AC-4 | Session files >24h exist | Run `/system-health` | Stale count > 0 reported | P0 | E2E |
| 8 | waza | Waza output included when available | AC-5 | Waza installed | Run `/system-health` | Waza appendix appears (unscored) | P0 | E2E |
| 9 | waza | Graceful skip when waza missing | AC-5 | Waza NOT installed | Run `/system-health` | Skip message, no error | P0 | E2E |
| 10 | trend | Trend delta shown on 2nd run | AC-6 | Prior health-history.jsonl exists | Run `/system-health` twice | Delta from previous score shown | P0 | E2E |
| 11 | quick | --quick skips waza | AC-5 | Waza installed | Run `/system-health --quick` | No waza appendix in output | P1 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md exists | Skill is available | `[ -f skills/system-health/SKILL.md ]` |
| S2 | core | Valid frontmatter | name, version, description, allowed-tools present | `sed -n '/^---$/,/^---$/p' skills/system-health/SKILL.md \| grep -c 'name:\|version:\|description:\|allowed-tools:'` |
| S3 | core | No Edit in allowed-tools | Read-only skill enforcement | `! grep -q 'Edit' skills/system-health/SKILL.md` (within frontmatter) |
| S4 | core | Catalog entry correct | waza in depends.skills | `jq '.[] \| select(.name == "system-health") \| .depends.skills' skills-catalog.json` |
| S5 | core | Version matches | SKILL.md and catalog agree | Compare frontmatter version to catalog version |
| S6 | core | Doc triplet exists | PRD, ARCHITECTURE, TEST-SPEC all present | `[ -f docs/system-health/PRD.md ] && [ -f docs/system-health/ARCHITECTURE.md ] && [ -f docs/system-health/TEST-SPEC.md ]` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps | Expected Outcome | Rubric |
|---|-----|----------|-------|-----------------|--------|
| E1 | core | Full health run | Type `/system-health` in Claude Code session | Scored dashboard with 4 buckets, graph highlights, filesystem breakdown | All sections populated, score is 0-10 |
| E2 | waza | Waza degradation | Temporarily rename waza dir, run `/system-health` | Skip message for waza, no crash, 4-bucket score still computed | Graceful, no error |
| E3 | trend | Second run shows delta | Run `/system-health` twice | Second run shows score change from first | Delta line present |
| E4 | graph | Known broken symlink | Ensure broken symlink exists (e.g., cross-retro) | Broken symlink appears in graph analysis | Listed in BROKEN SYMLINKS section |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Circular dependency detection | Best-effort in v0.2.0, may miss deep cycles | Low: cycle detection is informational, not blocking |
| Grep false positives in graph | Mitigated by *.md/*.json filter + dir existence check | Medium: some false edges may appear |
| Scoring calibration accuracy | Thresholds set from design doc, not empirical measurement | Medium: scores may not match user expectations on first run |
| Cross-platform (Linux) | macOS-only testing | Low: POSIX-compatible bash, likely works |
