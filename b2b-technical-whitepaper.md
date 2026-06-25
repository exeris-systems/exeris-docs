# Exeris: B2B Technical Whitepaper
## Reclaiming Structural Efficiency in Cloud Computing

**Status:** TRL-3 (Validated Architectural Prototype) · **Target:** Java 26+ · **Author:** Arkadiusz Przychocki, Founder & Lead Architect

---

### 1. The Challenge: Software Inflation

Modern enterprise infrastructure is burdened by **Software Inflation** — the steady accumulation of abstraction layers (framework auto-wiring, reactive runtimes, JSON serializers, GC-managed byte buffers) that consume more resources than the business logic they wrap. Processing a 4 GB network payload routinely triggers >160 GB of temporary heap allocations for wrappers and DTOs. Garbage collection, serialization (Jackson), and reactive scheduling can absorb up to 60% of CPU cycles, forcing massive over-provisioning of cloud instances.

The cost is structural, not configurational. No amount of tuning of a Spring + Reactor + Netty stack closes the gap — the abstractions themselves are the tax. The runtime needs to be replaced underneath the application, not the application replaced on top of the runtime.

Exeris addresses this in three coupled tiers. **Tier 1 (Substrate)** replaces the inflated runtime with a zero-copy, off-heap execution kernel. **Tier 2 (Capability Ecosystem)** turns that substrate into composable, build-time-validated capability modules. **Tier 3 (Vertical SaaS SKUs)** ships pre-composed capability manifests for specific verticals — API Gateway, Edge Proxy, Bot Blocker, IDP, PIM, OMS, Headless CMS API, Context-Centric CRM. Each tier in this document is grounded in source-of-truth ADRs and subsystem documents the buyer can re-read independently.

### 2. The Exeris Solution: Runtime-Owned Execution

Exeris is a **zero-copy runtime platform** built on modern Java — Project Panama (FFM API), Project Loom (Virtual Threads, Structured Concurrency), Project Valhalla readiness. Two design moves carry the Tier 1 substrate value proposition:

- **Data is a stream, not an object.** Network bytes stay off-heap, managed by deterministic `LoanedBuffer` ownership, until the application layer needs domain semantics. The JVM heap is bypassed on the hot path.
- **The runtime owns the request lifecycle.** Exeris owns ingress, backpressure, off-heap memory, and provider discovery (`ServiceLoader`). The application framework — Spring, when present — owns DI, configuration binding, and bean lifecycle. This separation (ADR-006, ADR-010 — "The Wall") lets existing Spring applications adopt Exeris incrementally without rewriting their business logic.

The Tier 1 substrate kernel is a **library embedded in your application JVM** (`exeris-kernel-core` plus one driver module). No sidecar, no proxy, no middleware server. Observability is in-process via Java Flight Recorder with sub-1% CPU overhead, with a separate open-spec decoder track (ADR-018) for offline analysis and live attach.

### 3. Strategic Platform Components

The platform is organized in three structural tiers. Tier 1 is the substrate — kernel, runtime, build tooling, observability. Tier 2 is the capability ecosystem — composable, named modules with explicit `@Provides` / `@Requires` contracts. Tier 3 is the SKU layer — first-party vertical SaaS products packaged as pre-wired capability compositions.

#### 3.1 Tier 1 — Substrate Repositories

| Component | Repository | Role |
|---|---|---|
| **Exeris Kernel** | `exeris-kernel` | Off-heap runtime — SPI, Core, Community driver, TCK. The substrate that all higher tiers compose against (ADR-007). |
| **Enterprise Kernel** | `exeris-kernel-enterprise` | Alternative substrate driver (`exeris-kernel`-SPI implementation) shipping `io_uring` (Linux) / IOCP (Windows) transport, `EnterpriseQuicTlsEngine` (QUIC TLS via OpenSSL `BIO_DGRAM` pair), HTTP/3 codec, slab-pool memory; NUMA-aware allocation via `libnuma mbind()` (see `exeris-kernel-enterprise/docs/subsystems/memory.md` §"NUMA-Aware Allocation"). Activated by Maven-coordinate swap with the open-core `exeris-kernel` Community driver (custom NIO H1/H2 + portable Off-Heap TLS over TCP). |
| **Exeris SDK** | `exeris-sdk` | `@ExerisDomain`, `@Action`, `@Field`, `@Relationship`, `@RequiresRole` annotations; source-model AST; Tailwind UI kit. Build-time only — no runtime coupling (ADR-003). |
| **Exeris Tooling** | `exeris-tooling` | Annotation processor + Java/TypeScript codegen — emits handlers, sagas, OpenAPI, Flyway migrations, Angular components (ADR-015). |
| **Exeris Spring Runtime** | `exeris-spring-runtime` | **Independent Tier 1 product** (separately purchased). Hosts existing Spring applications on the Exeris kernel for brownfield customer migration; not used by the platform itself, by any Platform SKU, or by future Family products (BudgetHQ is the singular Family-product consumer, dogfooding the Spring-on-Exeris combination — §8). The structural showcase that **Exeris is a runtime, not a framework** (ADR-010, ADR-011). |
| **Exeris Studio** | `exeris-platform` | Bidirectional visual editor synchronizing with `@ExerisDomain` Java sources via LSP. Visual modeling without low-code lock-in. |
| **Telemetry & Observability** | `exeris-telemetry-spec`, `exeris-enterprise-observability` | JFR-first wire format (open) plus decoder/CLI/forensics (enterprise) per ADR-018. Replaces sidecar-based APM. |
| **Benchmark Lab** | `exeris-benchmarks` | Reproducible JMH / wrk / h2load / k6 harness with matched-contract fairness gating. Open. |

The Wall (ADR-006) keeps `exeris-kernel-spi` and `exeris-kernel-core` Spring-free under all configurations. Enterprise-tier code depends on SPI and Core; the reverse is forbidden and enforced by architecture tests in every consuming repository.

#### 3.2 Tier 2 — Capability Ecosystem

A **capability** is a named, build-time-composable module with three contract surfaces: `@Provides` services exposed to other capabilities; `@Requires` declarations on capabilities it depends on; and a lifecycle (initialize, ready, drain, terminate) bound to the kernel bootstrap subsystem. A **composition** is a directed acyclic graph of capabilities with no unresolved `@Requires`. The kernel codegen pipeline (ADR-015) validates the graph at build time — cycles, missing dependencies, version mismatches, and Wall violations all fail the build before the first byte of traffic. Composition is the unit of product definition: an SKU is a named, signed composition of capabilities, not a runtime configuration knob.

Capabilities are organized in seven layers. Each layer is independently reusable; SKUs compose 10–15 capabilities by selecting from across the stack. The same domain primitive used by an OMS SKU (e.g. `exeris-caps-contact-graph`) is composable into a CRM, a PIM, or a customer-defined SKU without modification.

**License taxonomy.** The two-valued open-core split from ADR-020 (`public` / `enterprise-private`) covers the Tier 1 substrate cleanly, but Tier 2 capabilities require a third value because the cap layer is where most of the platform's commercial value lives. Capabilities ship under one of three licenses:

| License tier | Terms | What it covers |
|---|---|---|
| **community** | Apache 2.0 / MIT | ~3 commodity caps that drive adoption and ecosystem integration (CORS, i18n, observability bridge). Code public, free for any use. |
| **commercial** | Exeris Commercial License (source-available; BSL-style) | The bulk of Tier 2 — substrate aggregates, Gateway building blocks, Gateway policies, all SB platform caps, all domain primitives, all AI Abstraction caps. Code visible in public repositories; production use requires an active Platform SKU subscription or Platform-tier license. |
| **enterprise-private** | Closed-source | One Tier 2 cap (`exeris-caps-bot-fingerprinting`, which depends on a kernel-tier SPI extension). Available to Enterprise-tier subscribers only. |

> **Where native-bypass transport lives.** QUIC / HTTP/3, `io_uring`, and IOCP are **Tier 1 substrate** driver implementations in `exeris-kernel-enterprise`, not Tier 2 caps. The Enterprise engine swap (see §3.3 below) is a Maven-coordinate substitution at the substrate driver layer; cap compositions in Tier 2 are byte-identical across Community and Enterprise deployments.

This taxonomy extension is on the ADR roadmap (amendment to ADR-020 or a dedicated Capability Licensing Taxonomy ADR — see §7).

| Layer | Capability repository | License | Used by |
|---|---|---|---|
| **1. Substrate aggregates** | `exeris-caps-gateway-core` | commercial | Gateway family SKUs |
|  | `exeris-caps-service-boundary-core` | commercial | Service Boundary family SKUs |
| **2. Gateway building blocks** | `exeris-caps-route-registry` | commercial | Gateway SKUs |
|  | `exeris-caps-upstream-pool` | commercial | API Gateway, Edge Proxy |
|  | `exeris-caps-policy-chain` | commercial | Gateway SKUs |
|  | `exeris-caps-backend-health` | commercial | API Gateway, Edge Proxy |
|  | `exeris-caps-admin-control-plane` | commercial | Gateway SKUs |
| **3. Gateway policies (reusable across Gateway SKUs)** | `exeris-caps-rate-limiting` | commercial | Gateway SKUs, SB SKUs at API edge |
|  | `exeris-caps-jwt-validation` | commercial | Gateway SKUs, SB SKUs |
|  | `exeris-caps-tls-termination` | commercial | Gateway SKUs |
|  | `exeris-caps-request-routing` | commercial | Gateway SKUs |
|  | `exeris-caps-circuit-breaker` | commercial | Gateway SKUs, OMS |
|  | `exeris-caps-cors-policy` | community | Gateway SKUs, SB SKUs |
|  | `exeris-caps-waf-rules` | commercial | Bot Blocker, API Gateway |
|  | `exeris-caps-bot-fingerprinting` (JA3/JA4) | enterprise-private | Bot Blocker, API Gateway |
| **4. Service Boundary platform caps (reusable across all SB SKUs)** | `exeris-caps-multi-tenancy` | commercial | All SB SKUs |
|  | `exeris-caps-audit-trail` | commercial | All SB SKUs |
|  | `exeris-caps-rbac-policy` (builds on ADR-014) | commercial | All SB SKUs |
|  | `exeris-caps-soft-delete` | commercial | All SB SKUs |
|  | `exeris-caps-entity-versioning` | commercial | All SB SKUs |
|  | `exeris-caps-i18n` | community | CMS, PIM, OMS |
|  | `exeris-caps-attachment-storage` | commercial | All SB SKUs |
|  | `exeris-caps-search-index` | commercial | All SB SKUs |
|  | `exeris-caps-workflow-engine` | commercial | OMS, IDP, CRM (state machines) |
|  | `exeris-caps-notification-dispatch` | commercial | All SB SKUs |
|  | `exeris-caps-import-export` (CSV/JSON/XLSX) | commercial | PIM, OMS, CMS |
|  | `exeris-caps-rest-emission` (auto-REST from `@ExerisDomain`) | commercial | All SB SKUs |
|  | `exeris-caps-graphql-emission` | commercial | CMS, PIM |
|  | `exeris-caps-openapi-emission` | commercial | All SB SKUs |
| **5. Domain primitives (cross-SKU reuse)** | `exeris-caps-contact-graph` | commercial | CRM, OMS, PIM, BudgetHQ |
|  | `exeris-caps-product-catalog` | commercial | PIM, OMS |
|  | `exeris-caps-pricing-engine` | commercial | OMS, retail SKU composers |
|  | `exeris-caps-inventory-tracking` | commercial | OMS, PIM |
|  | `exeris-caps-order-lifecycle` | commercial | OMS |
|  | `exeris-caps-payment-gateway` (Stripe/Adyen) | commercial | OMS, BudgetHQ |
|  | `exeris-caps-document-ingestion` | commercial | IDP |
|  | `exeris-caps-ocr-pipeline` | commercial | IDP, BudgetHQ (receipt scan) |
|  | `exeris-caps-document-classifier` | commercial | IDP |
|  | `exeris-caps-field-extraction` | commercial | IDP |
|  | `exeris-caps-form-recognition` | commercial | IDP |
|  | `exeris-caps-content-types` | commercial | CMS, PIM |
|  | `exeris-caps-content-versioning` (drafts/publish/schedule) | commercial | CMS, PIM |
|  | `exeris-caps-asset-management` (media library) | commercial | CMS, PIM |
|  | `exeris-caps-bank-aggregator` (Tink/Salt Edge) | commercial | BudgetHQ → promotable |
| **6. AI Abstraction Layer** | `exeris-caps-ai-llm-abstraction` (OpenAI/Anthropic/Azure SPI) | commercial | IDP, CMS, CRM |
|  | `exeris-caps-ai-vector-store` | commercial | IDP, semantic search composers |
|  | `exeris-caps-ai-embedding-pipeline` | commercial | IDP, search composers |
|  | `exeris-caps-ai-rag-orchestration` | commercial | IDP, CMS |
|  | `exeris-caps-ai-prompt-templating` | commercial | All AI-enabled SKUs |
| **7. Cross-cutting** | `exeris-caps-observability-bridge` (JFR → ADR-018 wire) | community | All SKUs and Family products |

All cap repositories are currently in **specified** status. Implementation cadence is driven by the SKU roadmap in §7. The Capability Composition Model and the License Taxonomy extension are both governed by forthcoming ADRs; until those land, the binding source-of-truth is the codegen pipeline (ADR-015), the kernel bootstrap lifecycle contract, and ADR-020 (interpreted as covering Tier 1 only).

**Compositional reuse is structural, not aspirational.** `exeris-caps-contact-graph` is a single cap consumed by Context-Centric CRM, OMS (customer/recipient model), PIM (B2B trading-partner model), and BudgetHQ (account-owner model). `exeris-caps-ocr-pipeline` is consumed by IDP and by BudgetHQ's receipt-scan capability — the same cap, not a fork. This is what makes Tier 2 a genuine ecosystem: a customer at the Platform tier can pull `contact-graph` + `product-catalog` + `pricing-engine` + `inventory-tracking` + `order-lifecycle` + `payment-gateway` + the SB platform layer and assemble a bespoke ERP composition that no Exeris-shipped SKU enumerates.

**Wall enforcement extends to capabilities.** A capability cannot reach into Spring internals, into a sibling capability's private classes, or into the kernel's private packages. This is what makes a cap composition portable across host runtimes and detachable as IP — the same composition runs identically under Pure Mode and (where the cap supports it) Compatibility Mode, and can be lifted into a customer's repository fork without dragging a hidden classpath dependency.

#### 3.3 Tier 3 — Vertical SaaS SKUs (Platform SKUs)

First-party Platform SKUs are pre-wired capability compositions sold or licensed by Exeris Systems. Each SKU has its own repository (`exeris-sku-*`), its own commercial positioning, and its own Enterprise-tier engine swap path. The SKU layer is where the platform's structural efficiency becomes a buyer-facing product.

| SKU | Family | Source visibility | Target customer | Commercial positioning |
|---|---|---|---|---|
| **API Gateway** | Gateway | Source-available (Exeris Commercial License) | API-first B2B platforms with sustained >50k RPS per node | Envoy/Kong density and policy parity at sub-Envoy memory and CPU footprint |
| **Edge Proxy** | Gateway | Source-available (Exeris Commercial License) | Multi-region SaaS, CDN-adjacent deployments | Sub-millisecond P99 failover at the edge; in-process telemetry without sidecars |
| **Bot Blocker** | Gateway | **Closed-source** (Exeris Commercial License) — anti-abuse security exception per ADR-023 | E-commerce, fintech, ticketing | JA3/JA4 TLS fingerprinting at the kernel layer — fingerprint extraction happens before the request reaches policy chain |
| **IDP** | Service Boundary | Source-available (Exeris Commercial License) | Document-heavy B2B operations (insurance, logistics, legal) | Page-throughput parity with hyperscaler IDP at fraction of per-page cost; on-prem deployable |
| **PIM** | Service Boundary | Source-available (Exeris Commercial License) | Multi-channel retail, B2B distributors | Headless product information with kernel-direct API surface and graph-native attribute relations |
| **OMS** | Service Boundary | Source-available (Exeris Commercial License) | Marketplaces, multi-vendor logistics | Distributed saga orchestration (ADR-013) as the order state model |
| **Headless CMS API** | Service Boundary | Source-available (Exeris Commercial License) | Editorial-driven B2B and B2C sites | Content as `@ExerisDomain` types, generated REST + GraphQL surfaces |
| **Context-Centric CRM** | Cross-cutting data model (`exeris-caps-contact-graph` cap, not a standalone SKU) | Source-available — inherits cap licensing (`commercial`) per ADR-023 | Service Boundary SKU composers | Anti-account-centric data primitive — relationship graph as first-class, not as a CRM appendage |

**Source-visibility policy.** First-party Platform SKU repositories default to source-available public repositories under the Exeris Commercial License (the same source-available / subscription-required model that governs `commercial`-licensed caps per ADR-023). Source-availability operationalises the Glass Box thesis at the SKU layer — customers can audit the complete stack from kernel through cap to SKU before subscribing, and the matched-contract benchmark methodology becomes testable at the customer's desk rather than asserted in a vendor whitepaper. The Bot Blocker SKU is the single principled exception: published anti-abuse detection logic materially helps adversaries circumvent the protection, so the SKU is closed-source on the same principle that Cloudflare, Akamai Bot Manager, and every serious bot-protection vendor follows for their detection internals. The exception is named in the Bot Blocker repository's README and in customer-facing material; it does not generalise to other SKUs. See ADR-023 §"SKU Repository Source-Visibility Policy" for the full decision.

**Gateway family** (API Gateway, Edge Proxy, Bot Blocker) is kernel-level — no Spring dependency in the data plane, consistent with ADR-021 (gateway-class workloads out of `exeris-spring-runtime` scope). The **Enterprise engine swap is a Tier 1 substrate change**: the customer substitutes the `exeris-kernel-enterprise` driver (`io_uring` / IOCP transport, `EnterpriseQuicTlsEngine`, HTTP/3 codec, NUMA-aware slab pools) for the standard `exeris-kernel` Community driver (custom NIO H1/H2 + portable Off-Heap TLS over TCP). The Tier 2 cap composition manifest is byte-identical across both deployments because cap-layer code references kernel SPIs only — never `io_uring`, QUIC, NIO, or any concrete driver. This is what makes "Enterprise license unlocks engine swap" a structural fact rather than a marketing claim: the swap happens at the Maven coordinate / `ServiceLoader` level in the substrate, with zero changes upstream.

**Service Boundary family** (IDP, PIM, OMS, Headless CMS API) runs **kernel-direct** like the Gateway family — no Spring dependency. The external API surface is generated at build time from `@ExerisDomain` types + `@Action` methods through `rest-emission` / `graphql-emission` / `openapi-emission` codegen capabilities (ADR-015), executing against kernel HTTP SPIs through `service-boundary-core`. The full cap composition (`service-boundary-core` + platform-layer caps from §3.2 layer 4 — multi-tenancy, audit, RBAC, attachments, search, workflow — + domain primitives from §3.2 layer 5) is Spring-free. Heavy lifting (saga state, off-heap document processing, NUMA-aware compute paths at Enterprise tier) is kernel-level. The Spring-on-Exeris brownfield migration path (§5.2 + `exeris-spring-runtime`) is a separate product offering for customer applications that already have Spring code — it never sits underneath a first-party Service Boundary SKU.

**Context-Centric CRM data model** is not a standalone product — it is the `exeris-caps-contact-graph` cap from §3.2 layer 5, composable by any Service Boundary SKU. It encodes the anti-account-centric thesis: relationships, not accounts, are the primary key. Service Boundary SKUs that integrate it gain a graph-native customer/partner model without bolting on a separate CRM. Product-form release of a packaged CRM SKU composing `contact-graph` with the relevant platform caps is on the 2029 horizon (see §7).

##### Composition manifests (representative)

Each SKU below is a named composition of layered capabilities. The full manifests are version-pinned in the SKU repository (`exeris-sku-*`); these are the load-bearing caps a reader needs to understand the SKU's architectural shape.

- **API Gateway SKU** = `gateway-core` + `route-registry` + `upstream-pool` + `policy-chain` + `backend-health` + `admin-control-plane` + `rate-limiting` + `jwt-validation` + `tls-termination` + `request-routing` + `circuit-breaker` + `cors-policy` + `observability-bridge`.
- **Edge Proxy SKU** = `gateway-core` + `route-registry` + `request-routing` + `tls-termination` + `circuit-breaker` + `backend-health` + `observability-bridge` + edge-failover cap (SKU-specific).
- **Bot Blocker SKU** = `gateway-core` + `tls-termination` + `policy-chain` + `bot-fingerprinting` + `waf-rules` + `rate-limiting` + `observability-bridge`.
- **IDP SKU** = `service-boundary-core` + `multi-tenancy` + `audit-trail` + `rbac-policy` + `attachment-storage` + `rest-emission` + `openapi-emission` + `workflow-engine` + `document-ingestion` + `ocr-pipeline` + `document-classifier` + `field-extraction` + `form-recognition` + `ai-llm-abstraction` + `ai-prompt-templating` + `observability-bridge`.
- **PIM SKU** = `service-boundary-core` + `multi-tenancy` + `audit-trail` + `rbac-policy` + `i18n` + `attachment-storage` + `asset-management` + `search-index` + `entity-versioning` + `content-versioning` + `product-catalog` + `import-export` + `rest-emission` + `graphql-emission` + `openapi-emission` + `observability-bridge`.
- **OMS SKU** = `service-boundary-core` + `multi-tenancy` + `audit-trail` + `rbac-policy` + `workflow-engine` + `notification-dispatch` + `circuit-breaker` + `product-catalog` + `pricing-engine` + `inventory-tracking` + `order-lifecycle` + `payment-gateway` + `contact-graph` + `rest-emission` + `openapi-emission` + `observability-bridge`. The L4 Flow saga engine (ADR-013) is consumed via the kernel SPI, not as a separate cap.
- **Headless CMS API SKU** = `service-boundary-core` + `multi-tenancy` + `audit-trail` + `rbac-policy` + `i18n` + `attachment-storage` + `asset-management` + `search-index` + `content-types` + `content-versioning` + `rest-emission` + `graphql-emission` + `openapi-emission` + `observability-bridge`.

**ERP as a customer-defined composition.** No Exeris-shipped SKU is "the ERP". An ERP-class deployment is what a customer assembles at the Platform tier by composing OMS + PIM + Context-Centric CRM + a financial-ledger cap (forthcoming) + the SB platform layer + AI Abstraction Layer where useful. The capabilities are shared — `contact-graph` is the same cap whether it backs a CRM, an OMS customer model, or the partner ledger of a custom ERP. This is the structural meaning of "composable platform": ERP, vertical industry suites, or one-off internal tools are all expressions of the same Tier 2 surface area, not separate product lines.

### 4. Empirical Evidence (Matched-Contract Benchmarks)

Three representative rows. Full results, including JFR profiles and reproducibility metadata, are published from `exeris-benchmarks` under matched-contract fairness gating — every comparative claim carries a `claim-status.json: comparison_eligible`, scenario id, and `track_id` to prevent apples-to-oranges aggregation.

#### 4.1 Infrastructure Density — Distributed Sagas (ADR-013)

Saga frameworks make three guarantees, not one: **forward progress**, **compensation under failure**, and **termination**. Most published saga benchmarks measure only forward progress, and then call the framework "correct" if the happy path completes. Exeris evaluates all three on every comparative run, because the failure-path behaviour is what determines the operational shape of the deployment.

The reference scenario `e2e-shop-order-saga` (five-step order saga: register customer → recommend products → add to cart → get cart → create order, payment failure injected at a configured 3% rate, compensation must roll back stock reservation and release the order) is published in `exeris-benchmarks` under matched-contract fairness gating, with raw artefacts and JFR profiles for every run. The dev-laptop run on 2026-05-05 (AMD Ryzen 5 5600, 32 GB DDR4, JDK 26, loopback HTTP/1.1, 180 s window) reports the following — the table separates the *correctness asymmetry* from the *density asymmetry* because they tell two different parts of the same story:

| Stack                                | App RSS  | App threads | App CPU-s | Saga success | Compensation (cfg: 3%) | Saga unresolved |
|---|---|---|---|---|---|---|
| **Exeris (Community)**               | 459 MB   | 66          | 24.7 s    | 96.7%        | **3.32% ✓ (matched)** | **0% ✓**        |
| Quarkus 3 + Axon Framework + Neo4j   | 752 MB   | 94          | 22.3 s    | 98.2%        | **0% ✗**              | **1.82% ✗**     |
| Spring Boot 3 + Axon Framework + Neo4j | 1,312 MB | 81          | 33.3 s    | 98.8%        | **0% ✗**              | **1.22% ✗**     |

Two unrelated host runtimes (Quarkus 3 and Spring Boot 3) carrying the same Axon-Framework saga model both report **0% compensations** under a *configured* 3% failure rate. The injected failures did not disappear — they surface as `saga_unresolved` (1.82% Quarkus, 1.22% Spring): sagas dispatched into Axon Server that did not reach a terminal state before the benchmark window closed. This is not a runtime quirk; it is the structural signature of **async event-sourced dispatch returning before the work is done**. The order endpoint replies `202 Accepted` as soon as the event is published; the saga continues in a separate process with no one waiting on the request path, and a finite window cannot guarantee compensation observability.

Exeris's native `Flow` engine runs the saga state machine inline on the request virtual thread, persisting off-heap state before the HTTP response. When the response says "saga compensated", the compensation has executed. The 3.32% compensation rate matches the 3% configured injection within statistical noise; the saga-unresolved column is structurally 0% because no work is left outstanding when the request returns. The full-system density numbers compound this:

| Resource           | Exeris (in-process) | Spring + Axon (app + Axon Server)  | Quarkus + Axon (app + Axon Server) |
|---|---|---|---|
| Memory             | **459 MB**          | ~1.31 GB + ~0.85 GB = **~2.16 GB** | ~0.75 GB + ~0.79 GB = **~1.54 GB** |
| Threads            | **66**              | 81 + ~140 = **~221**               | 94 + ~123 = **~217**               |
| CPU-seconds        | **24.7 s**          | 33.3 + ~52 = **~85 s**             | 22.3 + ~26 = **~48 s**             |

Drawing the boundary tightly around the application JVM hides the Axon Server cost (separate process, ~787 MB / ~850 MB RSS, 120–148 PIDs). Drawing it around "what does it take to run a saga end-to-end?" — the Exeris in-process path is **3.4× lower memory, 3.3× fewer threads, ~1.9× lower CPU** versus Quarkus + Axon, and **4.7× lower memory, 3.3× fewer threads, ~3.4× lower CPU** versus Spring + Axon, with the additional fact that the Exeris path also compensates correctly.

These numbers are published as `claim_scope: exploratory` on `hardware_profile: dev-laptop` — the comparative-eligible re-run on `perf-box-amd64` (baremetal, WAN between load generator and target) is on the public benchmark roadmap, and the data above will either hold up or fall apart under that re-run. The compensation correctness asymmetry, however, is reproducible end-to-end today via `scripts/run-e2e-shop-order-saga-campaign.sh` in `exeris-benchmarks`, and is mechanically explained: a framework that returns before work is done will always show both the "fast" latency and the missing compensations.

#### 4.2 Extreme Throughput — TLS Record Path

Engine-level comparator on the **B5 Memory-BIO harness** (comparator labels and wiring caveats defined in `exeris-benchmarks/docs/tls-zero-copy-benchmark-matrix.md`). The Exeris row exercises `OffHeapTlsEngine` from `eu.exeris.kernel.core.crypto.*` — a Core-shared engine; the published report (`20260501-123118-all`) classifies the B5 row as **Enterprise tier**. B5 is an in-process Memory-BIO engine-level lens (no socket, no syscall) and is deliberately not equivalent to the FD-owner socket integration path (B6) — the two are reported as separate rows, never collapsed into one equivalence claim.

| Engine | Harness | Throughput | P99 latency |
|---|---|---|---|
| Exeris `OffHeapTlsEngine` (Core engine; Enterprise-tier row) | B5 Memory-BIO | 923,617 ops/s | 2.10 µs |
| JDK `SSLEngine` baseline | B5 Memory-BIO | 905,854 ops/s | 2.96 µs |
| Exeris Community FD-owner integration path | B6 FD-owner loopback | 365,375 ops/s | — |

The B6 row carries real loopback-socket and kernel-crossing cost on the Community integration path; the delta versus the engine-level rows combines transport-model and harness effects and cannot be attributed to engine cost alone.

The Enterprise-tier `EnterpriseQuicTlsEngine` (QUIC TLS with OpenSSL `BIO_DGRAM` pair) is a separate comparator track not represented in this row — TCP/Memory-BIO and QUIC are not directly comparable to JDK `SSLEngine`, and conflating them would violate matched-contract gating.

#### 4.3 SKU-Level Benchmark Forecast

The matched-contract methodology extends to the SKU layer. Exeris commits to publishing the following SKU benchmarks under the same `claim-status.json` gating, on the dates below. The forecast does not claim numbers — it commits to methodology and publication cadence.

| SKU benchmark | Comparator | Publication target |
|---|---|---|
| API Gateway RPS at matched-contract parity | Envoy + Kong | H1 2027 |
| Edge Proxy P99 latency under multi-region failover | Cloudflare Workers, Fastly Compute | H2 2027 |
| Bot Blocker JA3/JA4 fingerprinting throughput cost | DataDome, PerimeterX | H2 2027 |
| IDP page-throughput | Azure Document Intelligence, AWS Textract | H1 2028 |

#### 4.4 Reference hardware and provenance

All Tier 1 publishable measurements target the `perf-box-amd64` reference profile: EU-hosted dedicated bare metal (Hetzner AX-class — AMD x86-64, 16 hardware threads, 64 GB RAM; Falkenstein DE / Helsinki FI), Linux, Java 26 GA, fixed JVM heap. Publishable JMH rows use `-wi 5 -i 10 -f 3` minimum. TCK-enforced limits — request P99 latency, allocation budgets, bootstrap cold start budget, saga state-transition budget — are documented in [`exeris-kernel/docs/whitepaper.md`](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/whitepaper.md) §5 and tested by `Abstract*Tck` suites in every driver implementation. SKU benchmarks (§4.3) inherit the same fairness gating and publication harness.

### 5. Deployment Models & Adoption Paths

Five coupled paths cover the realistic adoption space — three at the substrate tier, two at the SKU and Family-product tiers.

#### 5.1 Greenfield — Entity-First

Define `@ExerisDomain` types; let the build emit kernel handlers, sagas, OpenAPI, and Angular components. Studio gives visual modeling without low-code lock-in — the generated Java is idiomatic and editable. Best fit when the team owns the domain model end-to-end.

#### 5.2 Brownfield — Spring Migration

Add `exeris-spring-runtime` to an existing Spring Boot application. The kernel takes over ingress and the request lifecycle (Pure Mode); Spring continues to own DI, configuration, and beans. ADR-011's Compatibility Mode narrows ThreadLocal bridging where strictly required (e.g. `SecurityContextHolder`) — isolated in `*.compat.*` sub-packages, never auto-active on the Pure path.

Spring applications adopt Exeris **incrementally**, with explicit out-of-scope cases:

- **Pure Mode covers** Spring `@RestController` / `@RequestMapping` style on Exeris-owned ingress with ScopedValue context propagation.
- **Compatibility Mode covers** Spring MVC `@RestController` paths plus narrow ThreadLocal bridging where Spring Security or similar legacy code demands it.
- **Out of scope (ADR-021):** Gateway-class workloads (Spring Cloud Gateway, both flavours); RouterFunction style; full JPA/Hibernate emulation beyond the documented `ExerisDataSource` Compatibility-Mode bypass (ADR-017 §6.4).

For workloads in the third category, keep a dedicated reverse proxy or full Spring stack in front, or compose the Gateway family Platform SKUs from §3.3 (which are kernel-level, no Spring dependency).

#### 5.3 Edge / IoT

A target baseline RSS of ~128–200 MB (measured against the Community kernel on AWS Graviton2 ARM64; methodology to be published in `exeris-benchmarks/docs/edge-rss-baseline.md` — *planned, ships in `exeris-benchmarks` v0.8.0+*) enables running complex Java business logic on 512 MB ARM gateways and similar constrained hardware where C++/Rust was previously the only option. The same kernel binary runs cloud and edge — only driver selection and memory partition sizing differ.

#### 5.4 Vertical SKU Subscription

Customer subscribes to one or more Platform SKUs from the §3.3 inventory. The customer does not interact with the cap composition directly — they receive the SKU's pre-wired manifest, signed and version-pinned by Exeris Systems. The SKU runs on the customer's infrastructure (cloud, on-prem, or edge); Exeris Systems ships updates as new signed manifests, not as live patches to running infrastructure.

Customers can elect to upgrade to a **Platform tier** subscription at any time, at which point they gain Studio access to author and modify cap compositions directly. This is the migration path from "consume a SKU" to "compose your own SKU."

The **Code Detachment Fee** from the framing in earlier internal strategy documents is reframed at this layer as the one-time license that transfers SKU ownership permanently to the customer's repository fork. For SMB-tier SKUs the fee is in the low five-figure euros, scaling with deployment size and SLA tier. This is the structural realization of the IP sovereignty promise from §6 — paying the fee unlocks not a runtime privilege but a property right.

**What detachment includes per SKU source-visibility (per ADR-023 §"SKU Repository Source-Visibility Policy"):**

- **Source-available SKUs** (API Gateway, Edge Proxy, IDP, PIM, OMS, Headless CMS API) — detachment transfers ownership of the SKU source repository, the cap composition manifest, the SKU-specific policy capabilities the customer is licensed for, and the build-time codegen artefacts (`exeris-tooling` outputs) required to operate the SKU independently. The customer takes a perpetual-use grant for the underlying `commercial`-licensed caps for the detached version. After detachment, the customer can operate, modify, and fork the SKU under the terms of the perpetual-use grant; they cannot redistribute under different licence terms.
- **Closed-source Bot Blocker SKU** — detachment transfers a perpetual binary-use licence for the deployed version plus the cap composition manifest, but **not** the closed security logic (the JA3/JA4 detection internals, the bot-fingerprinting cap, anti-abuse heuristics). This is honest, not a hidden carve-out: the security logic loses commercial value the moment it is publicly readable, so source detachment would devalue what the customer is paying to detach. The detached customer receives a binary that continues to operate at the deployed version indefinitely; if they want continued evolution of the security stack, they retain a Bot Blocker subscription separately.

The detachment scope is disclosed at sale time and named in the Code Detachment agreement, so the customer's expectations match the contractual reality. The bound on detachment scope is part of how the platform stays commercially sustainable while still delivering on the IP-sovereignty promise — sophisticated buyers treat this structure as proof the platform is serious, not as a concession.

#### 5.5 Family Product Hosting

Independent SaaS products in the Exeris Systems family run on the Exeris kernel — generally **pure Exeris**, on `exeris-sdk` + `exeris-tooling`. BudgetHQ is the singular exception: it is a Spring application on `exeris-spring-runtime` + Exeris Kernel, deliberately structured as the dogfooding case for the Spring-on-Exeris product. All future Family products will be pure-Exeris and will not depend on `exeris-spring-runtime`. Family products are commercially independent — pricing, customer base, branding, and roadmap are determined by each Family product's own strategy, not by the platform's. They consume platform capabilities through the same `@Provides` / `@Requires` mechanism platform subscribers do, with no special access. This is detailed in §8.

The Family Product Hosting model establishes a structural fact: the platform is genuinely usable by independent SaaS products with no privileged shortcuts. The dogfooding claim is architectural, not theatrical — BudgetHQ runs against the same SPI surface a paying platform subscriber would.

### 6. Sovereignty & IP Ownership

The IP boundary between Exeris Systems and its customers is governed by internal commercial policy that is maintained in Exeris's private decision registry and made available to counterparties under NDA during commercial discussions. The substrate-level mechanics described below — code detachment and the open-core split — are the technical guarantees that flow from those contracts and that any reader can verify against the public open-core code.

Operationally at the substrate layer:

- **Code detachment.** Business artifacts compiled against the SPI are legally and technically detachable from the runtime. The SPI is the contract; alternative implementations are admissible.
- **Open-core split (ADR-020).** Open-core repositories carry the full Community-tier capability. Enterprise capabilities (`io_uring`, QUIC, slab pools, decoder tooling, design-time RBAC) ship in private repositories under standard commercial licensing.

**Sovereignty extends to the SKU layer.** When a customer detaches a vertical SKU under the §5.4 Code Detachment model, they receive (a) the substrate code their tier already entitles them to, (b) the SKU's cap composition manifest, (c) the SKU-specific policy capabilities they are licensed for, and (d) the build-time codegen artifacts (`exeris-tooling` outputs) needed to operate the SKU independently of further Exeris updates. The fee — low five-figure euros for SMB-tier SKUs, scaling for higher SLA tiers and larger deployments — is positioned as the cost of a transferable property right, not a barrier to exit. Customers who pay it become structurally independent of Exeris Systems for the SKU they detached.

### 7. Roadmap

Exeris is currently at **TRL-3 (Validated Architectural Prototype)** at platform-aggregate level; individual subsystems are ahead (Crypto: TRL-4 / Integration-Tested Prototype per `exeris-kernel/docs/subsystems/crypto.md`). The roadmap is organized as two parallel tracks plus an independent Family-product line.

**Track A — Platform (Tier 1 substrate + Tier 2 ecosystem).**

The kernel currently ships at **v0.7.0 (2026-05-10)**; v0.8 sprint is active (quality-driven, ~8–10 weeks). Milestones below are pinned to that velocity, and Spring Runtime / Kernel GA are deliberately co-scheduled because Spring Runtime's product release depends on a stable Kernel SPI contract.

| Horizon | Milestone |
|---|---|
| Q3 2026 | Kernel v0.8 GA — quality gates closed; **TRL-4 integration-tested** for kernel subsystem set; first internal Edge/IoT pilot cohorts begin against `exeris-kernel-community` |
| Q4 2026 | Kernel v0.9 — TRL-5 component validation in relevant environment; SPI freeze candidate hardening into **v0.9-RC SPI lock**; Exeris Spring Runtime 1.0 RC (Phases 0–3 feature-complete against the locked SPI; ADR-010, ADR-011, ADR-017); Exeris Studio MVP private beta (read-only inspection + targeted edit surfaces); customer pilot cohorts expand |
| **H1 2027** | **Exeris Kernel 1.0 GA + Exeris Spring Runtime 1.0 GA shipped together** — SPI / Core / TCK stabilization (ADR-007, ADR-008); TRL-6 system prototype demonstrated in operational environment |
| 2027 | Capability composition language formal ADR; **Capability Licensing Taxonomy ADR** (amendment to ADR-020 or standalone) — locks the `community` / `commercial` / `enterprise-private` model from §3.2 |
| 2028 | `exeris-caps-*` community caps formal Apache 2.0 releases; commercial caps source-available repositories opened to customers |

**Track B — Platform SKUs (Tier 3).**

| Horizon | Milestone |
|---|---|
| H1 2027 | Capability composition language formal release; SKU manifest format frozen; **API Gateway SKU** — GA |
| H2 2027 | **Edge Proxy SKU** — GA; **Bot Blocker SKU** — GA (depends on JA3/JA4 kernel proposal landing in `exeris-kernel`) |
| H1 2028 | **IDP** and **Headless CMS API** SKUs — GA (simplest Service Boundary cap compositions) |
| H2 2028 | **PIM** and **OMS** SKUs — GA |
| 2028 | Context-Centric CRM data-model ADR; cross-cutting cap promoted to formal capability |
| H2 2029 | Context-Centric CRM — first product-form release |

**Family Products (parallel, independent).** BudgetHQ enters **private beta H2 2026**, **GA H1 2027**. The BudgetHQ schedule is not subordinated to platform milestones — it is run as an independent SaaS product. See §8 for the structural role Family products play in the platform's capability development pipeline.

In-flight tracks supporting the above (not themselves milestones): Spring Runtime Phases 0–3 (ADR-010, ADR-017); Telemetry tooling, crash-ring decoder, live-stream attach (ADR-018); Persistence SPI extensions including `Instant` binders for saga state (ADR-022).

### 8. Exeris Systems Family Products

A **Family product** is built and operated by Exeris Systems itself, on the Exeris Platform, as an independent SaaS product. It is *not* a Platform SKU. It is not sold as a cap composition to platform subscribers. It runs as a commercially independent business with its own brand, pricing, customer base, and roadmap. Family products serve three strategic functions: they **dogfood the platform in production**, generating bug reports and performance data no synthetic benchmark can produce; they **diversify Exeris Systems revenue** away from B2B platform sales cycles; and they provide a **reference implementation** demonstrating real production use of capabilities under development.

**BudgetHQ** is the first Family product and the **singular Spring-on-Exeris dogfooding case**. It is an independent SaaS spanning both B2C and B2B finance through workspace types (Personal / Family / Business): consumer-side positioned in Europe as "holistic net-worth tracking for the mass affluent segment"; business-side serving freelancer and small-business finance (VAT invoicing, vendor invoices, multi-member workspaces). BudgetHQ is a Spring application running on `exeris-spring-runtime` + Exeris Kernel — deliberately, to validate the Spring-on-Exeris combination as a shippable product under real customer load. It integrates with bank-aggregator APIs (Tink, Salt Edge) through the platform's bank-aggregator capability — which is itself developed first inside BudgetHQ before being promoted to a reusable Service Boundary capability. BudgetHQ uses the IDP capability for receipt scanning; that same capability will later ship as the IDP Platform SKU listed in §3.3.

**All future Family products will be pure-Exeris**, built on `exeris-sdk` (`@ExerisDomain`, `@Action`, `@Field`, `@Relationship`, `@RequiresRole`) + `exeris-tooling` codegen + the Tier 2 cap ecosystem. BudgetHQ remains the singular Spring-on-Exeris product because its dogfooding role is to validate `exeris-spring-runtime` itself; that role is filled once and does not need to be repeated.

**How Family products feed back into the platform.** New capabilities are typically prototyped inside a Family product under real production load, then promoted to reusable platform capabilities once they have stabilized. This is the dogfooding feedback loop. BudgetHQ in 2026–2027 prototypes:

- the **bank-aggregator capability** (Tink and Salt Edge adapters, with the platform-level SPI abstraction designed first inside BudgetHQ);
- the **receipt-scan IDP integration** (consumes the AI Abstraction Layer SPI, prototype-first inside BudgetHQ);
- the **OAuth/OIDC capability** for B2C identity;
- the **subscription-billing capability** (Stripe adapter, promotable to a reusable platform cap).

Each of these capabilities lands in the platform's capability ecosystem **after** BudgetHQ has stabilized them in production — never before. This inverts the "demo product" framing from earlier internal strategy documents: BudgetHQ is not built to prove the platform works; the platform is structurally sound enough that BudgetHQ can run on it from day one, and that is the proof. The capability development pipeline replaces the "Trojan horse" lead-generation framing of earlier strategic documents.

The Family product pattern is extensible — additional Family products may emerge in other SaaS verticals (B2C or B2B) — but the platform's focus claim is preserved by not pre-committing to a long roadmap of speculative Family products beyond BudgetHQ.

### 9. Conclusion

Vertical scaling has hit the **Memory Wall**. Stacking more abstraction layers no longer recovers throughput — those layers cause the loss. Exeris removes the layers responsible for the loss while preserving the developer ergonomics teams already rely on: Spring stays where it belongs, Java idioms stay clean, and the runtime owns the data plane.

The three-tier structure — Substrate, Capability Ecosystem, Vertical SaaS SKUs — turns that structural efficiency into a product portfolio. Customers can adopt at any tier: install the substrate under an existing Spring app (§5.2); subscribe to a pre-composed Platform SKU (§5.4); or, at the Platform tier, compose their own SKUs in Studio. Family products like BudgetHQ (§8) demonstrate that the platform is structurally usable by independent SaaS businesses — including by Exeris Systems itself.

The result is measurable — in RSS, threads, CPU-seconds, SKU benchmark numbers, and cloud bills — and the evidence is gated by fairness rules the buyer can re-run.

---

**Further reading.** [`high-level-architecture.md`](high-level-architecture.md) — C4 model, capability composition model, SKU compositions, and Family product architecture. [`exeris-kernel/docs/whitepaper.md`](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/whitepaper.md) — substrate technical pillars, SLA/SLO baseline, operational mantras. [`adr-index.md`](adr-index.md) — full decision registry.
