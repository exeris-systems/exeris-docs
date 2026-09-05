---
title: Reference — the three-tier architecture
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Reference — the three-tier architecture

Authoritative source: [`high-level-architecture.md`](../../high-level-architecture.md) §§2.2, 3, 4, 5 and §9.

What follows is the short form an agent needs before editing a document that touches this
subject. It does not restate the source and is not authority: when they disagree, the source wins
and this file is the defect.

The platform is structured in three tiers, formalized in HLA §§2.2, 3, 4, 5 and whitepaper §3. Any doc edit that frames the platform differently is wrong:

- **Tier 1 — Substrate.** The Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007) plus `exeris-sdk` and `exeris-tooling` for the build-time pipeline (ADR-015).
  - **Community driver** lives as Maven modules inside `exeris-kernel/` (`exeris-kernel-community`, `exeris-kernel-community-kafka`, `exeris-kernel-community-testkit`) — NOT as a separate sibling repository. Don't enumerate it as a sibling repo.
  - **Enterprise driver** (`exeris-kernel-enterprise`) ships `io_uring`/IOCP transport, `EnterpriseQuicTlsEngine`, HTTP/3, slab pools, NUMA. The Enterprise engine swap is a Tier 1 substrate driver swap (Maven coordinate change), **NOT** a Tier 2 cap manifest swap. There is no `exeris-caps-quic-*` or `exeris-caps-io-uring-*` cap.
  - **`exeris-spring-runtime`** is an **independent Tier 1 product**, sold separately. Used by exactly two consumers: (a) customers with existing Spring applications doing brownfield migration; (b) BudgetHQ as the singular Family-product dogfooding case for the Spring-on-Exeris combination. The platform itself (kernel + caps + SKUs) does **not** depend on it.
- **Tier 2 — Capability Ecosystem.** ~50 `exeris-caps-*` capabilities across seven layers (substrate aggregates, Gateway building blocks, Gateway policies, Service Boundary platform caps, Domain primitives, AI Abstraction, Cross-cutting), enumerated with their licence and build status in [`cap-license-registry.md`](../../cap-license-registry.md) — one cap repository exists today (`exeris-caps-cors-policy`, scaffolded); the rest are `specified`. Driver-agnostic by construction; Spring-free per the cap-tier Wall (extension of ADR-006).
- **Tier 3 — Vertical SaaS SKUs.** First-party `exeris-sku-*` cap compositions. **All run kernel-direct** (no Spring Runtime). HTTP surface comes from `@ExerisDomain` + `@Action` + `rest-emission` codegen (ADR-015), NOT from Spring `@RestController`.

**Family products** (BudgetHQ being the first) are commercially independent SaaS products built by Exeris Systems on the platform — structurally distinct from Platform SKUs (HLA §9). BudgetHQ is the singular Spring-on-Exeris Family product; **all future Family products will be pure-Exeris** on `exeris-sdk` + `exeris-tooling`.
