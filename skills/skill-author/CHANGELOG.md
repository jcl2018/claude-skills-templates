# Changelog: skill-author

## [0.1.0] - 2026-04-10
### Added
- 5-stage guided pipeline: intake, scaffold, author, check, ship
- Resume via file existence (no checkpoint JSON needed)
- Guided authoring with targeted questions for SKILL.md content
- Fix loop in check stage (auto-fixes mechanical errors, surfaces subjective ones)
- Version idempotency check (prevents double-bump on retry)
- Optional design doc context from /office-hours
