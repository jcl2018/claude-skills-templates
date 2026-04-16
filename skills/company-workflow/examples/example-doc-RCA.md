---
type: rca
parent: D000099
title: "Rate Limiter False Positive on Tenant Plan Upgrade — Root Cause Analysis"
date: 2026-03-12
author: Marcus Liu
severity: P2
status: Resolved
---

## Symptom

After upgrading from the Free plan (100 req/min) to the Pro plan (1,000 req/min),
tenant `acme-corp` continued to be rate-limited at the old 100 req/min threshold.
The issue persisted for 5-10 minutes after the plan change was committed to the
database. Two other tenants reported the same behavior on 2026-03-11. Reproduction
rate: 100% on any plan upgrade while the tenant is actively sending requests.

## Reproduction Steps

1. Set tenant `test-tenant-01` to Free tier (100 req/min) in the admin console
2. Send 80 requests within 60 seconds (all succeed with 200)
3. Upgrade tenant to Pro tier (1,000 req/min) via admin console
4. Immediately send 30 more requests within the same 60-second window
5. **Observe:** requests 81-100 succeed, but requests 101+ return 429 despite the
   new 1,000 req/min limit

**Environment:** API Gateway v3.2.1, Redis 7.2, Node.js 20.11, staging cluster

## Investigation Trail

| Time | Action | Finding |
|------|--------|---------|
| 09:15 | Checked config-service logs for plan change event | Plan upgrade event emitted correctly at 09:02 with new tier "pro" |
| 09:20 | Inspected Redis counter for tenant | Redis key `ratelimit:acme-corp:window:1710244920` showed count=98, limit=100 |
| 09:25 | Checked gateway pod config cache | Local cache still held tier=free for acme-corp; TTL had 4 minutes remaining |
| 09:30 | Reviewed config cache invalidation code | No cache invalidation on plan-change webhook; relies solely on TTL expiry |
| 09:35 | Tested with cache TTL=0 (no caching) | Plan upgrade took effect immediately; confirmed cache is the root cause |
| 09:40 | Checked if Redis counter also stale | Redis counter key stores the limit at window creation time; not re-read mid-window |

## Root Cause

**Root cause:** The gateway's local config cache (60-second TTL) does not
invalidate on plan-change events. When a tenant upgrades, the old tier's rate
limit remains in the local cache until TTL expires. Additionally, the Redis
counter key stores the limit value at window creation time and does not update
mid-window, extending the stale period by up to one additional window.

**Location:** `platform/gateway/lib/rate-limiter.ts:47` (config cache lookup)
and `platform/gateway/lib/redis-sync.ts:82` (window key creation)

## Affected Components

| Component | File/Module | Impact |
|-----------|------------|--------|
| Config cache | gateway/lib/config-cache.ts | Serves stale tier data for up to 60s after plan change |
| Redis sync | gateway/lib/redis-sync.ts | Window key embeds limit at creation; ignores mid-window changes |
| Rate limiter | gateway/lib/rate-limiter.ts | Reads stale limit from both cache and Redis, rejects valid requests |

## Fix Description

Two changes were applied. First, the config cache now subscribes to the
config-service's plan-change webhook and evicts the affected tenant's cache entry
on receipt. Second, the Redis window key no longer embeds the limit value;
instead, the limit is read from the (now-invalidated) config cache on each check,
so a mid-window upgrade takes effect within seconds rather than waiting for the
next window.

## Regression Risk

| Area | Risk Level | Why | Mitigation |
|------|-----------|-----|------------|
| Config cache performance | Low | Webhook adds one invalidation path | Monitor cache hit rate; should stay above 95% |
| Redis key format change | Med | Existing window keys use old format | Migration script converts keys; old keys TTL out in 60s naturally |
| Webhook reliability | Low | Missed webhook = old TTL behavior (60s delay) | Add metric for webhook delivery failures; alert if > 0 |
