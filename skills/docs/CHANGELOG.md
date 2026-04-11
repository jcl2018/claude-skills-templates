# Changelog

## [0.1.0] - 2026-04-11

### Added
- `/docs init` — generate PHILOSOPHY.md or OVERVIEW.md from codebase analysis
- `/docs check` — staleness detection via claims sidecar + mechanical coherence checks
- `.docs/claims.json` sidecar mapping doc sections to evidence files with commit SHAs
- Schema validation for claims.json on read
- Unreachable commit guard (rebase/force-push resilience)
- Quick Start example in SKILL.md
- Exact error messages for all failure modes
