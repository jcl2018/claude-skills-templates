---
type: architecture
feature: system-health
title: "System Health — Architecture"
version: 1
status: Active
date: 2026-04-10
author: chjiang
prd: PRD.md
---

## Overview

The unified /health skill orchestrates a 9-layer health dashboard by combining Waza's upstream config hygiene checks (layers 1-6) with custom governance, doc quality, and deploy state layers (7-9). It is a P3 custom wrapper around a P2 upstream, preserving both principles. The `--scope` and `--layer` flags enable targeted runs.

## Architecture

```
/health (entry point — .claude/skills/system-health/SKILL.md)
  |
  +---> Step 0: Parse --scope and --layer arguments
  |
  +---> Step 1: Run scripts/health-checks.sh (layers 7, 9 data)
  |
  +---> Step 2: Layers 1-6 — Waza config hygiene
  |       +-- Run skills/waza/health/scripts/collect-data.sh
  |       +-- Apply 6-layer rubric (CLAUDE.md, rules, skills, hooks, sub-agents, verifiers)
  |
  +---> Step 3: Layer 7 — Governance
  |       +-- Upstream freshness (gstack, waza)
  |       +-- Contract validation (validate-skill-contracts.sh)
  |       +-- Audit spec closure (validate-audit-spec.sh)
  |       +-- Gen-docs freshness (gen-docs.sh --check)
  |       +-- Replaced skill detection (replaces field consumer)
  |
  +---> Step 4: Layer 8 — Doc quality
  |       +-- Discover doc triplet families under docs/
  |       +-- Invoke /align-feature-contract per family (L1/L2/L3)
  |       +-- Aggregate results into scored table
  |
  +---> Step 5: Layer 9 — Deploy state
  |       +-- deploy.sh --dry-run (repo vs ~/.claude/ drift)
  |       +-- Stale sessions, temp files, oversized files
  |       +-- Analytics volume, memory files
  |
  +---> Step 6: Composite score + recommendations
  |
  +---> Step 7: Save snapshot to docs/inspections/
```

### Components Affected

| Component | Path | Change Type | Description |
|-----------|------|------------|-------------|
| Health skill | .claude/skills/system-health/SKILL.md | Core | Entry point, orchestrates all 9 layers |
| Health checks script | scripts/health-checks.sh | Core | Deterministic checks for layers 7 and 9 |
| Waza upstream | skills/waza/health/ | Read-only (P2) | Config hygiene data collection and rubric |
| Align-feature-contract | .claude/skills/align-feature-contract/SKILL.md | Dependency | Delegated to for layer 8 doc triplet checks |
| Contract validator | scripts/validate-skill-contracts.sh | Dependency | Called by layer 7 for contract coverage |
| Deploy script | scripts/deploy.sh | Dependency | Called by layer 9 for drift detection |
| Inspections | docs/inspections/*.md | Output | Timestamped health snapshots |

### Data Flow

1. /health parses arguments (--scope, --layer) to determine which layers to run
2. health-checks.sh runs deterministic checks, producing structured output for layers 7 and 9
3. Waza's collect-data.sh gathers config state for layers 1-6
4. Each layer applies its rubric and produces findings with severity levels
5. Layer 8 delegates to /align-feature-contract per doc triplet family
6. Results are aggregated into a composite score with per-layer breakdowns
7. Snapshot is saved to docs/inspections/

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Waza upstream | Skill (P2) | Available | skills/waza/health/scripts/collect-data.sh |
| /align-feature-contract | Skill (P3) | Available | Layer 8 delegation |
| health-checks.sh | Script | Available | Deterministic layer 7/9 checks |
| validate-skill-contracts.sh | Script | Available | Contract coverage validation |
| deploy.sh | Script | Available | Drift detection via --dry-run |
| jq | External | Available | JSON parsing for catalog and spec files |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Waza upstream changes breaking data collection | Low | Medium | P2 rules: re-copy on upgrade, test after |
| /align-feature-contract output format changes | Low | Medium | Layer 8 parsing is resilient to extra fields |
| health-checks.sh becoming stale vs new catalog entries | Medium | Low | Replaces consumer catches renamed skills |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Wrapper pattern (P2+P3) | Custom wrapper calls upstream | Fork Waza's /health directly | Preserves upstream updates per P2 |
| 9-layer model | Fixed layers with --layer filter | Declarative check registry | Simpler mental model, less infrastructure |
| Delegate to /align-feature-contract | Call existing skill for layer 8 | Inline alignment checks | Reuses gold engine, avoids duplication |
| Kill /advisor + /work-audit | Replace with /health --scope | Keep all skills alive | Eliminates fragmentation, one command |
