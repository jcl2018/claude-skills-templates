---
skill-name: "system-health"
version: 0.2.0
status: ACTIVE
created: "2026-04-10"
last-updated: "2026-04-11"
---

# Skill Design: system-health

## Purpose

~/.claude/ health dashboard with dependency graph. Checks the physical health of
the Claude Code home folder: installed skills, dependency topology, filesystem
hygiene, and optionally waza config correctness. Not per-repo code quality (gstack
/health), not per-project config audit (waza /health). This is the filesystem and
topology layer between them.

## Behavior

**Inputs:** `/system-health` or `/system-health --quick` (skip waza).

**Steps:**
1. Scan: consolidated bash command walks ~/.claude/skills/, extracts frontmatter,
   greps *.md/*.json for cross-references, parses settings.json structurally.
2. Graph: bash/jq builds adjacency list, computes in-degree, detects orphans,
   broken symlinks, dead references. Claude interprets, doesn't compute.
3. Filesystem: du, stale sessions, temp files, history.jsonl size.
4. Waza: optional unscored appendix (CWD-dependent, excluded from scored composite).
5. Score: 4 buckets (Structure 25%, References 35%, Integrity 25%, Hygiene 15%).
   Trend tracking via ~/.gstack/health/claude-home-health-history.jsonl.

**Outputs:** Scored dashboard with dependency graph highlights, filesystem breakdown,
recommendations by impact, and optional waza appendix.

## Design Decisions

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Graph computation | bash/jq (deterministic) | Claude reasoning | Reliable for 40+ nodes, testable |
| Waza scoring | Unscored appendix | 15% weighted bucket | CWD-dependent, makes trend unreliable |
| Grep scope | *.md and *.json only | All files | Reduces false positives from binaries/JSONL |
| Settings extraction | jq keys only | Raw cat | Security: don't expose credentials |
| allowed-tools | No Edit | With Edit | Read-only skill |

## Dependencies

| Dependency | Type | Required | Notes |
|-----------|------|----------|-------|
| waza | Skill (runtime) | Optional | collect-data.sh. Graceful degradation if missing. |
| jq | CLI tool | Recommended | Settings extraction, history parsing. Fallback if missing. |

## Security Boundaries

- allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
- No Edit, no Write (read-only skill)
- Never dumps raw settings.json (extracts keys only via jq)

## Test Criteria

1. SKILL.md exists with valid frontmatter (name, version, description, allowed-tools)
2. skills-catalog.json declares waza dependency
3. Doc triplet exists (PRD, ARCHITECTURE, TEST-SPEC)
4. E2E: all 5 steps produce output when invoked
5. Waza degradation: no crash when waza is absent
