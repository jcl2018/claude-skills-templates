# Architecture Overview

<!-- This file is per-target-repo USER DATA. `copilot-deploy install` writes
     this skeleton on first install ONLY. Re-installs preserve your filled-in
     content (you'll see `[KEEP-USER] architecture-overview.md` in the
     install log).

     Replace each section below with your real architecture.
     /wc-investigate reads this file as ambient context for system-level
     design discussions (boundaries, data flow, key services). -->

## System diagram

<!-- A simple ASCII or text-based diagram. Don't worry about visual polish;
     /wc-investigate just needs to know the shape. -->

Example:

```
[Web/Mobile clients]
        |
        v
[API Gateway] ---> [Billing service (THIS REPO)] ---> [Postgres]
                            |
                            +----> [Stripe API] (payment processing)
                            +----> [NetSuite webhook] (revenue events)
                            +----> [SQS: billing.events] (downstream consumers)
```

Replace with: ...

## Key services / modules

<!-- The top-level components of this repo or system. One bullet each. -->

- **`<service-name>`** — <one-line description>
- **`<service-name>`** — <one-line description>

Replace with: ...

## Data flow (the happy path)

<!-- The most common request path. Numbered steps. -->

Example:

1. Web client posts `POST /subscriptions` with tenant + plan
2. API handler validates the pydantic schema
3. `services/billing.create_subscription()` runs:
   a. Inserts a `subscriptions` row (state=`pending`)
   b. Calls Stripe API to create a customer + subscription
   c. On Stripe success, updates row to `state=active`
4. Emits `subscription.created` to SQS for downstream consumers
5. Returns 201 with the subscription resource

Replace with: ...

## External dependencies

<!-- Services this repo calls or is called by. Useful for blast-radius
     discussions during /wc-investigate. -->

- **`<dep-name>`** — <inbound|outbound|both>; criticality: <hard|soft>
- **`<dep-name>`** — <inbound|outbound|both>; criticality: <hard|soft>

Replace with: ...

## Known boundaries / "things we don't do here"

<!-- Explicit scope. What lives somewhere else? -->

Example:

- Payment method UI lives in the web app, not in this service
- Tax calculation is delegated to TaxJar; we never compute it locally
- Revenue recognition is downstream of our event stream; we don't compute ARR

Replace with: ...
