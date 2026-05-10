---
type: test-spec
parent: S000099
feature: F000099
title: "API Rate Limit Enforcement — Test Specification"
version: 1
status: Approved
date: 2026-03-05
author: Priya Patel
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: [Marcus Liu, Dana Chen]
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Reject request when quota exhausted | AC-1 | Tenant at 100/100 used | Send one more GET /api/data | HTTP 429 with Retry-After header | P0 | Integration |
| 2 | core | Allow request within quota | AC-1 | Tenant at 50/100 used | Send GET /api/data | HTTP 200, X-RateLimit-Remaining: 49 | P0 | Integration |
| 3 | core | Isolate tenants on same pod | AC-2 | Tenant A at limit, Tenant B at 0 | Send request as Tenant B | Tenant B gets 200 | P0 | Integration |
| 4 | observability | Metrics exported to Prometheus | AC-3 | Rate limiter active | Scrape /metrics endpoint | rate_limit_current gauge present per tenant | P0 | E2E |
| 5 | resilience | Fallback on Redis failure | AC-5 | Redis connection severed | Send 50 requests | Requests allowed up to local-only conservative limit | P1 | Integration |
| 6 | usability | Status endpoint returns quota | AC-4 | Tenant at 73/100 used | GET /rate-limit-status | JSON: { limit: 100, remaining: 27, reset_at: ... } | P1 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | RateLimiter class exists | Module exports the rate limiter | `node -e "require('./lib/rate-limiter')"` |
| S2 | core | Config schema includes rate limits | Tier config has rate_limit_per_min field | `jq '.tiers[].rate_limit_per_min' config/tiers.json` |
| S3 | observability | Prometheus metrics registered | rate_limit_* metrics are defined | `grep 'rate_limit_' src/metrics.ts` |
| S4 | core | Middleware is wired into pipeline | Rate limit middleware in gateway setup | `grep 'rateLimitMiddleware' src/gateway.ts` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Burst over limit | Send 110 requests in 10 seconds to a 100/min tenant | First 100 return 200; requests 101-110 return 429 with valid Retry-After | Pass: all 429s have Retry-After > 0 and <= 60 |
| E2 | core | Cross-pod consistency | Send 50 requests to pod A, then 60 to pod B for same tenant | Pod B rejects at request 51 (global counter = 101) | Pass: rejection happens between requests 50-55 on pod B |
| E3 | resilience | Redis failover | Kill Redis primary mid-test, continue sending requests | Requests continue with local-only limiting; no 500 errors | Pass: zero 5xx responses; 429s appear at conservative local limit |
| E4 | usability | Quota reset after window | Exhaust quota, wait 60 seconds, retry | First retry after window reset returns 200 | Pass: 200 response with X-RateLimit-Remaining = limit - 1 |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Rolling deploy with mixed versions | Requires multi-version cluster; tested manually pre-launch | Brief inconsistency during 60s deploy window is acceptable |
| Rate limits > 10,000 req/min | No load test infra for Enterprise-tier volumes yet | Enterprise tier launches in v2; will add load tests then |
| Admin API for dynamic limit updates | P2 feature, not implemented in v1 | No risk; feature does not exist yet |
