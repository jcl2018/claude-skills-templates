# Changelog: system-health

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
