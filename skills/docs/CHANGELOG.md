# Changelog

## [0.2.0] - 2026-04-11

### Added
- Work item validation in `/docs check`: template compliance, lifecycle consistency, cross-reference traceability
- Normalization layer: type spelling, ID-prefix filename matching, directory-based parent resolution
- 2-level template fallback chain (repo templates/ → ~/.claude/templates/)
- Explicit work item state definitions (Open/In Progress/Closed from lifecycle checkboxes)
- P0-only traceability enforcement (P1/P2 advisory only)
- Defensive error handling: graceful skip for missing manifest, work-items dir, templates, or unparseable frontmatter

## [0.1.0] - 2026-04-11

### Added
- `/docs init` — generate PHILOSOPHY.md or OVERVIEW.md from codebase analysis
- `/docs check` — staleness detection via claims sidecar + mechanical coherence checks
- `.docs/claims.json` sidecar mapping doc sections to evidence files with commit SHAs
- Schema validation for claims.json on read
- Unreachable commit guard (rebase/force-push resilience)
- Quick Start example in SKILL.md
- Exact error messages for all failure modes
