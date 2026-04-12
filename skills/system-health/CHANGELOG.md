# Changelog: system-health

## [1.0.0] - 2026-04-11
### Added
- Feature work item (F000002) with full artifact set: TRACKER, PRD, ARCHITECTURE, TEST-SPEC, milestones
- V1 version cut — no functional changes from 0.3.0

## [0.3.0] - 2026-04-11
### Added
- Step 4.5: Usage Trends (unscored). Reads `~/.gstack/analytics/skill-usage.jsonl`
  and surfaces skill usage analytics with per-skill breakdown, per-repo breakdown,
  peak hours, installed-vs-used overlay, and three rule-based insights
  (stopped-using, long-and-failing, discovery-gap)
- Usage-based recommendations (unscored) in Step 7
- 3-schema JSONL normalization (simple, intermediate, v1)
- Duration sanitization (duration_s > 86400 treated as null)
- Usage telemetry preamble

### Fixed
- Waza path corrected with install instructions

## [0.2.0] - 2026-04-11
### Changed
- Complete rewrite targeting ~/.claude/ filesystem health instead of home-setup repo
- Replaced 9-layer model with 5-step graph-first architecture
- Dependency graph: scan installed skills, build adjacency list, detect orphans/dead refs/hubs
- Graph computation moved to deterministic bash/jq (not Claude reasoning)
- Waza integration changed to unscored appendix (CWD-dependent)
- Settings.json extracted structurally via jq keys only (security)
- Grep limited to *.md and *.json files (noise reduction)
- Scoring: 4 buckets (Structure 25%, References 35%, Integrity 25%, Hygiene 15%)
- Trend tracking at ~/.gstack/health/claude-home-health-history.jsonl

### Added
- waza declared as runtime dependency in skills-catalog.json
- Graceful degradation when waza or jq is unavailable
- Empty glob guard (shopt -s nullglob)
- Corrupt history.jsonl fallback

### Removed
- `--scope` flag (was home-setup-specific, use /align-feature-contract instead)
- `--layer` flag (replaced by 5-step architecture)
- Edit from allowed-tools (read-only skill)
- Layers 7 (governance) and 8 (doc quality) — belonged to home-setup context

## [0.1.0] - 2026-04-10
### Added
- Initial version (retroactively documented)
