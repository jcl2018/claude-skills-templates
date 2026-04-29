---
type: architecture
parent: S000099
feature: F000099
title: "API Rate Limit Enforcement — Architecture"
version: 1
status: Approved
date: 2026-03-03
author: Marcus Liu
prd: PRD.md
reviewers: [Dana Chen, Raj Gupta]
---

## Overview

Per-tenant API rate limiting via a two-tier token bucket: a local in-memory
bucket for the hot path (zero network calls) and a Redis global counter for
cross-pod accuracy. Keeps P99 latency under 2ms. See the PRD for requirements.

## Architecture

```
  Request -> Auth MW (extract tenant_id)
               |
          RateLimit MW
           /        \
     Local Bucket   Redis Counter
      (in-mem)       (global sync)
           \        /
        200 or 429 response
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| api-gateway | platform/gateway | Modified | Add rate limit middleware |
| rate-limiter | platform/gateway/lib | New | Token bucket with Redis sync |
| tenant-config | platform/config-svc | Modified | Expose per-tier limits |
| grafana-dashboards | infra/monitoring | New | Rate limit dashboard |

### Data Flow

1. Auth middleware extracts `tenant_id` from the JWT
2. Rate limit middleware looks up plan tier from local config cache (60s TTL)
3. Local token bucket checks remaining tokens; if allowed, Redis INCR syncs globally
4. On success: request proceeds; on rejection: 429 with `Retry-After` header

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| GET /rate-limit-status | (tenant_id) -> { limit, remaining, reset_at } | Current quota for authenticated tenant |
| RateLimiter.check() | (tenant_id, tier) -> Allow/Deny | Core rate check, called per request |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| Gateway.handleRequest() | (req, res) -> void | adds rate limit middleware | Rate check before routing |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Redis 7.x cluster | Infra | Available | Needs new keyspace for rate counters |
| ioredis 5.x | Code | Available | Already in gateway package.json |
| prom-client | Code | Available | Exposing rate limit metrics to Prometheus |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Redis latency spike | Low | High | Local bucket handles hot path; Redis sync is non-blocking |
| Redis unavailable | Low | Med | Fallback to local-only mode with conservative limits |
| Clock skew across pods | Low | Low | Use Redis server time for window boundaries |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Token bucket algorithm | Token bucket with Redis sync | Sliding window log | Token bucket adds < 1ms; sliding window needs a Redis call per request |
| Fallback behavior | Degrade to local-only | Fail open (no limiting) | Failing open defeats the purpose; local-only is safe |
| Window size | Fixed 60-second windows | Sliding window | Simpler to debug; acceptable burst at window boundaries |
