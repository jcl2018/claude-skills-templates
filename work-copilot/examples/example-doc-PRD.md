---
type: prd
parent: S000099
feature: F000099
title: "API Rate Limit Enforcement — Product Requirements"
version: 1
status: Approved
date: 2026-03-01
author: Dana Chen
reviewers: [Marcus Liu, Priya Patel]
---

## Problem Statement

API consumers frequently exceed plan request limits, causing cascading
degradation for other tenants. Ops engineers throttle abusers manually via
nginx config changes (15-30 min per incident), causing two outages last quarter.

## Mental Model

Two-layer rate limiting: a fast per-instance token bucket for the hot path,
backed by a Redis global counter that syncs across API gateway pods.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Reject over-limit requests? | API consumer | receive 429 with Retry-After | I know when to retry |
| 2 | core | Limits per-tenant? | Platform operator | enforce limits by subscription tier | one tenant cannot degrade others |
| 3 | observability | Operators see usage? | Ops engineer | view consumption in Grafana | I can spot tenants nearing limits |

### P1 (Important)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 4 | usability | Check remaining quota? | API consumer | call /rate-limit-status | I can backoff before 429s |
| 5 | resilience | Works without Redis? | Platform operator | fall back to local-only | limiting degrades gracefully |

### P2 (Nice-to-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 6 | integration | Change limits without deploy? | Platform operator | update via admin API | respond to abuse in real time |

## Acceptance Criteria

### Story #1: 429 on Limit Exceeded [core]
```
GIVEN a tenant has exhausted their quota for the current window
WHEN  they send an additional API request
THEN  the gateway returns HTTP 429 with a Retry-After header
```

### Story #2: Per-Tenant Enforcement [core]
```
GIVEN tenants A (Free) and B (Enterprise) share the same pod
WHEN  tenant A exceeds their 100 req/min limit
THEN  tenant A receives 429 while tenant B continues receiving 200s
```

### Story #3: Grafana Dashboard [observability]
```
GIVEN the rate limiter is active in production
WHEN  an ops engineer opens the Rate Limiting dashboard
THEN  per-tenant usage and percentage are visible, updated every 10s
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| P99 latency of rate check | < 2ms | `rate_limit_check_duration_ms` histogram |
| Manual throttling incidents/quarter | 0 | Incident tracker "manual-throttle" tag |
| False positive rate | < 0.01% | 429s / total requests per tenant per hour |

## Out of Scope

- Per-endpoint limiting (all endpoints share one tenant quota in v1)
- Billing integration or auto plan upgrades on breach
- Internal service-to-service rate limiting

## Assumptions

- Redis cluster available with sub-5ms P99 from all gateway pods
- Tenant ID extracted from Authorization header by existing auth middleware
