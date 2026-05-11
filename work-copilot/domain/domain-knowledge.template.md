# Domain Knowledge

<!-- This file is per-target-repo USER DATA. `copilot-deploy install` writes
     this skeleton on first install ONLY. Re-installs preserve your filled-in
     content (you'll see `[KEEP-USER] domain-knowledge.md` in the install log).

     Replace each section below with your real repo context. /wc-investigate
     reads this file as ambient context for its scoping conversations. -->

## What this repo does

<!-- One paragraph: what the product / service / library is. -->

Example: `This repo is the billing service for Acme Corp. It handles
subscription lifecycle (signup, upgrade, downgrade, cancel), invoice
generation, and webhook delivery to upstream finance systems.`

Replace with: ...

## Who uses it

<!-- The primary user persona(s). Internal teams, external customers,
     downstream services. -->

Example: `Internal users: Finance ops team (web UI), customer success team
(read-only dashboard). External consumers: Acme's web/mobile apps via REST
API. Downstream: NetSuite + Stripe via webhooks.`

Replace with: ...

## Key terms / domain vocabulary

<!-- Terms that have specific meaning in this repo. Disambiguates common
     words from their domain-specific usage. -->

- **`<term-1>`** — <one-line definition>
- **`<term-2>`** — <one-line definition>
- **`<term-3>`** — <one-line definition>

Example:

- **`tenant`** — a paying customer account; one tenant has many users
- **`grace period`** — the 7-day window after subscription cancel during which the customer keeps access
- **`dunning`** — automated retry sequence for failed payment attempts

Replace with: ...

## Recent business priorities

<!-- 2-3 bullets on what the team has been focusing on lately. Helps
     /wc-investigate ground new ideas in current context. -->

Replace with: ...
