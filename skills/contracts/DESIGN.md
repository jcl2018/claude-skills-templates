---
skill-name: "contracts"
version: 0.1.0
status: DRAFT
created: "2026-04-10"
last-updated: "2026-04-10"
---

# Skill Design: contracts

## Purpose

Consolidates align-feature-contract and test-align-contract into a single skill with two subcommands: check and test. Enforces doc triplet contracts (PRD + ARCHITECTURE + TEST-SPEC) against templates and provides a test harness to verify the enforcement itself.

The two original skills were always used together and shared template resolution logic. Merging them reduces routing overhead and simplifies the mental model: one skill for all contract concerns.

## Behavior

1. **check (default subcommand):** Template alignment (Layer 1: frontmatter, sections, tables, generation guide compliance) + cross-doc traceability (Layer 2: PRD-to-TEST-SPEC coverage, PRD-to-ARCH coverage, ARCH-to-TEST-SPEC coverage, TEST-SPEC internal consistency) + code/contract verification (Layer 3: WARN-only advisory). Fix mode available for Layer 1 issues only.

2. **test subcommand:** Tier 1 smoke tests (S1-S5: frontmatter exists, required fields, required sections, cross-references resolve, no placeholder text) run deterministically without AI. Tier 2 E2E invokes the check subcommand on discovered triplets and verifies expected output structure.

Templates moved to templates/contract-*.md in the repo root. Template resolution: repo root templates/ first, then ~/.claude/spec/templates/, then ~/.claude/templates/.

## Design Decisions

- **Two subcommands, not two skills.** Check and test share template resolution, triplet discovery, and output formatting. Duplication was unjustified.
- **Templates in repo root templates/ directory.** Aligns with the repo convention. Contract-specific templates use the contract-*.md prefix.
- **Test independence preserved.** Tier 1 smoke tests remain deterministic (no AI). Tier 2 E2E depends on check but is clearly separated.
- **Read-only enforcement.** This skill checks and reports. Fix mode (Layer 1 only) is explicitly gated behind user approval. No silent mutations.

## Dependencies

- No skill dependencies (standalone)
- Template files in templates/ directory (contract-*.md, doc-*.md)

## Security Boundaries

allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion

No Write or Edit. This skill is read-only by design. Fix mode prompts the user and uses AskUserQuestion to confirm, but the actual writes happen through the caller's context, not this skill's tool allowance.

## Test Criteria

- `/contracts check path/to/triplet/` produces Layer 1 + Layer 2 + Layer 3 report
- `/contracts check` with no argument discovers triplets in docs/ and work-items/
- `/contracts test` runs Tier 1 smoke on all discovered triplets
- `/contracts test` Tier 2 invokes check and validates output structure
- Template resolution falls through correctly: repo templates/ -> ~/.claude/spec/templates/ -> ~/.claude/templates/
- Fix mode only applies to Layer 1 findings, with user approval
