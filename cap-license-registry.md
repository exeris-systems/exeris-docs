---
title: Capability Licence Registry
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-10-14
---

# Capability Licence Registry

**Scope:** platform · **Discharges:** [ADR-023](adr/ADR-023-capability-licensing-taxonomy.md) open
follow-up 1 (per-cap licence registry)

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
| `community` | 4 |
| `commercial` | 55 |
| `enterprise-private` | 1 |
| **total** | **60** |

The single `enterprise-private` cap is `bot-fingerprinting`, and the reason is structural rather
than commercial: it depends on a kernel-tier SPI extension that ships in `exeris-kernel-enterprise`.
The four `community` caps are the commodity ones — `cors-policy`, `i18n`, `token-issuer`,
`observability-bridge` — chosen to drive adoption and ecosystem integration rather than to carry
revenue. `token-issuer` is among them because EdDSA token issuance and JWKS publication are a
standard that other systems integrate against (ADR-099).

## Build vocabulary

The `Build` column records how far a cap has been built.

| Build | Meaning |
|---|---|
| `specified` | The cap exists in HLA §3.2 with its `@Provides` / `@Requires` shape agreed. No repository. |
| `scaffolded` | Repository exists, builds, and emits a stamped `cap-manifest.json`. Behaviour may be partial. |
| `implemented` | Feature-complete against its `@Provides` contract, with tests. |

Eleven caps are past `specified`, all `scaffolded`: `exeris-caps-cors-policy`,
`exeris-caps-service-boundary-core`, `exeris-caps-audit-trail`, `exeris-caps-rate-limiting`,
`exeris-caps-jwt-validation` and the six identity caps named in the notes below. Each has a public
repository that builds and carries a stamped `cap-manifest.json`; none is declared feature-complete,
so none is `implemented`.

## Status vocabulary

The `Status` column records how far a cap has been released, and it is independent of `Build`: a cap
can be `scaffolded` and still `poc`. Exactly one of three values; where the evidence is mixed or
missing, the lower value applies.

| Status | Meaning |
|---|---|
| `poc` | Anything else: the repository exists only locally, or has no published artefact, or has no repository at all. |
| `snapshot` | The repository is on GitHub and publishes SNAPSHOT artefacts to GitHub Packages, but has no release. |
| `released` | A non-SNAPSHOT release tag exists on the repository and the artefact is published to Maven Central or as a GitHub Packages release. |

Every cap is `poc` today: no cap repository has a release tag or a published artefact.

### Layer 1 — Substrate aggregates

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-gateway-core` | `commercial` | public | specified | poc |
| `exeris-caps-service-boundary-core` | `commercial` | public | **scaffolded** | poc |

### Layer 2 — Gateway building blocks

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-route-registry` | `commercial` | public | specified | poc |
| `exeris-caps-upstream-pool` | `commercial` | public | specified | poc |
| `exeris-caps-policy-chain` | `commercial` | public | specified | poc |
| `exeris-caps-backend-health` | `commercial` | public | specified | poc |
| `exeris-caps-admin-control-plane` | `commercial` | public | specified | poc |

### Layer 3 — Gateway policies

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-rate-limiting` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-jwt-validation` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-tls-termination` | `commercial` | public | specified | poc |
| `exeris-caps-request-routing` | `commercial` | public | specified | poc |
| `exeris-caps-circuit-breaker` | `commercial` | public | specified | poc |
| `exeris-caps-cors-policy` | `community` | public | **scaffolded** | poc |
| `exeris-caps-waf-rules` | `commercial` | public | specified | poc |
| `exeris-caps-bot-fingerprinting` | `enterprise-private` | enterprise-private | specified | poc |

### Layer 4 — Service Boundary platform caps

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-multi-tenancy` | `commercial` | public | specified | poc |
| `exeris-caps-audit-trail` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-rbac-policy` | `commercial` | public | specified | poc |
| `exeris-caps-soft-delete` | `commercial` | public | specified | poc |
| `exeris-caps-entity-versioning` | `commercial` | public | specified | poc |
| `exeris-caps-i18n` | `community` | public | specified | poc |
| `exeris-caps-attachment-storage` | `commercial` | public | specified | poc |
| `exeris-caps-search-index` | `commercial` | public | specified | poc |
| `exeris-caps-workflow-engine` | `commercial` | public | specified | poc |
| `exeris-caps-notification-dispatch` | `commercial` | public | specified | poc |
| `exeris-caps-import-export` | `commercial` | public | specified | poc |
| `exeris-caps-rest-emission` | `commercial` | public | specified | poc |
| `exeris-caps-graphql-emission` | `commercial` | public | specified | poc |
| `exeris-caps-openapi-emission` | `commercial` | public | specified | poc |

### Layer 5 — Domain primitive caps

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-contact-graph` | `commercial` | public | specified | poc |
| `exeris-caps-product-catalog` | `commercial` | public | specified | poc |
| `exeris-caps-pricing-engine` | `commercial` | public | specified | poc |
| `exeris-caps-inventory-tracking` | `commercial` | public | specified | poc |
| `exeris-caps-order-lifecycle` | `commercial` | public | specified | poc |
| `exeris-caps-payment-gateway` | `commercial` | public | specified | poc |
| `exeris-caps-document-ingestion` | `commercial` | public | specified | poc |
| `exeris-caps-ocr-pipeline` | `commercial` | public | specified | poc |
| `exeris-caps-document-classifier` | `commercial` | public | specified | poc |
| `exeris-caps-field-extraction` | `commercial` | public | specified | poc |
| `exeris-caps-form-recognition` | `commercial` | public | specified | poc |
| `exeris-caps-content-types` | `commercial` | public | specified | poc |
| `exeris-caps-content-versioning` | `commercial` | public | specified | poc |
| `exeris-caps-asset-management` | `commercial` | public | specified | poc |
| `exeris-caps-bank-aggregator` | `commercial (BudgetHQ → promotable)` | public | specified | poc |
| `exeris-caps-credential-store` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-session-management` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-mfa-totp` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-federated-login` | `commercial` | public | **scaffolded** | poc |
| `exeris-caps-token-issuer` | `community` | public | **scaffolded** | poc |
| `exeris-caps-invitations` | `commercial` | public | **scaffolded** | poc |

### Layer 6 — AI Abstraction Layer caps

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-ai-llm-abstraction` | `commercial` | public | specified | poc |
| `exeris-caps-ai-vector-store` | `commercial` | public | specified | poc |
| `exeris-caps-ai-embedding-pipeline` | `commercial` | public | specified | poc |
| `exeris-caps-ai-rag-orchestration` | `commercial` | public | specified | poc |
| `exeris-caps-ai-prompt-templating` | `commercial` | public | specified | poc |

### Layer 7 — Cross-cutting

| Cap | Licence | Visibility | Build | Status |
|---|---|---|---|---|
| `exeris-caps-observability-bridge` | `community` | public | specified | poc |
| `exeris-caps-outbound-credentials` | `commercial` | public | specified | poc |
| `exeris-caps-service-identity` | `commercial` | public | specified | poc |
| `exeris-caps-idempotency` | `commercial` | public | specified | poc |
| `exeris-caps-usage-metering` | `commercial` | public | specified | poc |

---

## Notes on individual rows

- **`exeris-caps-bank-aggregator`** is recorded in HLA §3.2 as *"commercial (BudgetHQ → promotable)"*
  — it originates in the BudgetHQ Family product and is a candidate for promotion into the shared
  cap layer. Counted as `commercial`; the promotion is not yet a decision.
- **`exeris-caps-cors-policy`** is the first cap repository. It provides a transport-blind decision
  function and needs no kernel SPI, which makes it the cheapest possible exercise of the full
  build-time path.
- **`credential-store`, `session-management`, `mfa-totp`, `federated-login`, `token-issuer` and
  `invitations`** are the layer-5 caps of the Identity SKU, specified by
  [ADR-099](adr/ADR-099-compose-identity-as-a-tier-3-platform-sku.md); each has a public repository
  under `exeris-systems` and is `scaffolded`. The private operational plane
  of [ADR-098](adr/ADR-098-split-the-platform-control-plane-on-the-time-axis.md) composes that SKU for
  operator identity.
- **`financial-ledger`** and the SKU-specific edge-failover cap are named elsewhere in the HLA but
  are **not** in the §3.2 layer tables, so they are deliberately absent here. This registry counts
  only what the inventory admits.

## Regenerating

The tables above are parsed from HLA §3.2 — cap name from the first column, licence from the last,
grouped by the `**Layer N — …**` headings. `Build` and `Status` are not in §3.2: they are set from
the state of each repository and its published artefacts, and a consumer reads them by header name. Re-derive after any §3.2 edit rather than hand-patching a
row, and re-check the totals against HLA §6.2's 4 / 55 / 1 split; a mismatch means one of the
two documents moved without the other.
