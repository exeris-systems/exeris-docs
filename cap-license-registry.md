# Capability Licence Registry

**Status:** living document · **Scope:** platform · **Owns:** ADR-023 open follow-up 1

The per-cap source of truth for which licence a capability artefact carries, whether its repository
is public, and how far it has actually been built.

> **Derived, not retyped.** Every row below is generated from the tables in
> [`high-level-architecture.md`](high-level-architecture.md) §3.2, which is the authoritative
> inventory. Editing a licence here without editing HLA §3.2 creates exactly the drift this registry
> exists to prevent — change §3.2 first, then regenerate. On any conflict between this file and
> [ADR-023](adr/ADR-023-capability-licensing-taxonomy.md), **ADR-023 wins**.

## The three values

Licensing (ADR-023) is a separate axis from visibility (ADR-020). A cap can be source-available and
still require a subscription to run in production; that combination is the norm here, not an
exception.

| Licence | Terms | Production use |
|---|---|---|
| `community` | Apache 2.0 / MIT | Free for anything, including production. No subscription. |
| `commercial` | Exeris Commercial License (source-available, BSL-style) | Requires an active Platform SKU subscription or Platform-tier licence. Source is public for audit and evaluation. |
| `enterprise-private` | Exeris Enterprise License (closed-source) | Enterprise-tier subscribers only. |

**Visibility** is `public` for both `community` and `commercial` — source-available is still public.
Only `enterprise-private` implies a private repository.

## Totals

| Licence | Caps |
|---|---|
| `community` | 3 |
| `commercial` | 50 |
| `enterprise-private` | 1 |
| **total** | **54** |

The single `enterprise-private` cap is `bot-fingerprinting`, and the reason is structural rather
than commercial: it depends on a kernel-tier SPI extension that ships in `exeris-kernel-enterprise`.
The three `community` caps are the commodity ones — `cors-policy`, `i18n`, `observability-bridge` —
chosen to drive adoption and ecosystem integration rather than to carry revenue.

## Status vocabulary

| Status | Meaning |
|---|---|
| `specified` | The cap exists in HLA §3.2 with its `@Provides` / `@Requires` shape agreed. No repository. |
| `scaffolded` | Repository exists, builds, and emits a stamped `cap-manifest.json`. Behaviour may be partial. |
| `implemented` | Feature-complete against its `@Provides` contract, with tests. |

As of this writing exactly one cap is past `specified`. That is the honest state: the composition
pipeline was finished before any cap consumed it from outside `exeris-tooling`'s own test fixtures.

### Layer 1 — Substrate aggregates

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-gateway-core` | `commercial` | public | specified |
| `exeris-caps-service-boundary-core` | `commercial` | public | specified |

### Layer 2 — Gateway building blocks

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-route-registry` | `commercial` | public | specified |
| `exeris-caps-upstream-pool` | `commercial` | public | specified |
| `exeris-caps-policy-chain` | `commercial` | public | specified |
| `exeris-caps-backend-health` | `commercial` | public | specified |
| `exeris-caps-admin-control-plane` | `commercial` | public | specified |

### Layer 3 — Gateway policies

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-rate-limiting` | `commercial` | public | specified |
| `exeris-caps-jwt-validation` | `commercial` | public | specified |
| `exeris-caps-tls-termination` | `commercial` | public | specified |
| `exeris-caps-request-routing` | `commercial` | public | specified |
| `exeris-caps-circuit-breaker` | `commercial` | public | specified |
| `exeris-caps-cors-policy` | `community` | public | **scaffolded** |
| `exeris-caps-waf-rules` | `commercial` | public | specified |
| `exeris-caps-bot-fingerprinting` | `enterprise-private` | enterprise-private | specified |

### Layer 4 — Service Boundary platform caps

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-multi-tenancy` | `commercial` | public | specified |
| `exeris-caps-audit-trail` | `commercial` | public | specified |
| `exeris-caps-rbac-policy` | `commercial` | public | specified |
| `exeris-caps-soft-delete` | `commercial` | public | specified |
| `exeris-caps-entity-versioning` | `commercial` | public | specified |
| `exeris-caps-i18n` | `community` | public | specified |
| `exeris-caps-attachment-storage` | `commercial` | public | specified |
| `exeris-caps-search-index` | `commercial` | public | specified |
| `exeris-caps-workflow-engine` | `commercial` | public | specified |
| `exeris-caps-notification-dispatch` | `commercial` | public | specified |
| `exeris-caps-import-export` | `commercial` | public | specified |
| `exeris-caps-rest-emission` | `commercial` | public | specified |
| `exeris-caps-graphql-emission` | `commercial` | public | specified |
| `exeris-caps-openapi-emission` | `commercial` | public | specified |

### Layer 5 — Domain primitive caps

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-contact-graph` | `commercial` | public | specified |
| `exeris-caps-product-catalog` | `commercial` | public | specified |
| `exeris-caps-pricing-engine` | `commercial` | public | specified |
| `exeris-caps-inventory-tracking` | `commercial` | public | specified |
| `exeris-caps-order-lifecycle` | `commercial` | public | specified |
| `exeris-caps-payment-gateway` | `commercial` | public | specified |
| `exeris-caps-document-ingestion` | `commercial` | public | specified |
| `exeris-caps-ocr-pipeline` | `commercial` | public | specified |
| `exeris-caps-document-classifier` | `commercial` | public | specified |
| `exeris-caps-field-extraction` | `commercial` | public | specified |
| `exeris-caps-form-recognition` | `commercial` | public | specified |
| `exeris-caps-content-types` | `commercial` | public | specified |
| `exeris-caps-content-versioning` | `commercial` | public | specified |
| `exeris-caps-asset-management` | `commercial` | public | specified |
| `exeris-caps-bank-aggregator` | `commercial (BudgetHQ → promotable)` | public | specified |

### Layer 6 — AI Abstraction Layer caps

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-ai-llm-abstraction` | `commercial` | public | specified |
| `exeris-caps-ai-vector-store` | `commercial` | public | specified |
| `exeris-caps-ai-embedding-pipeline` | `commercial` | public | specified |
| `exeris-caps-ai-rag-orchestration` | `commercial` | public | specified |
| `exeris-caps-ai-prompt-templating` | `commercial` | public | specified |

### Layer 7 — Cross-cutting

| Cap | Licence | Visibility | Status |
|---|---|---|---|
| `exeris-caps-observability-bridge` | `community` | public | specified |
| `exeris-caps-outbound-credentials` | `commercial` | public | specified |
| `exeris-caps-service-identity` | `commercial` | public | specified |
| `exeris-caps-idempotency` | `commercial` | public | specified |
| `exeris-caps-usage-metering` | `commercial` | public | specified |
---

## Notes on individual rows

- **`exeris-caps-bank-aggregator`** is recorded in HLA §3.2 as *"commercial (BudgetHQ → promotable)"*
  — it originates in the BudgetHQ Family product and is a candidate for promotion into the shared
  cap layer. Counted as `commercial`; the promotion is not yet a decision.
- **`exeris-caps-cors-policy`** is the first cap repository. It provides a transport-blind decision
  function and needs no kernel SPI, which makes it the cheapest possible exercise of the full
  build-time path.
- **`financial-ledger`** and the SKU-specific edge-failover cap are named elsewhere in the HLA but
  are **not** in the §3.2 layer tables, so they are deliberately absent here. This registry counts
  only what the inventory admits.

## Regenerating

The tables above are parsed from HLA §3.2 — cap name from the first column, licence from the last,
grouped by the `**Layer N — …**` headings. Re-derive after any §3.2 edit rather than hand-patching a
row, and re-check the totals against ADR-023's stated 3 / 50 / 1 split; a mismatch means one of the
two documents moved without the other.
