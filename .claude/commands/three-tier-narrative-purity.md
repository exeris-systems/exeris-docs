---
description: Audit a doc edit for three-tier narrative purity — Tier 1 substrate / Tier 2 capability ecosystem / Tier 3 SKUs / Family products as separate axis.
argument-hint: doc edit / new section / framing claim to audit
---

Audit this change for three-tier narrative purity.

Three-tier architecture (per `high-level-architecture.md` §§2.2/3/4/5 + whitepaper §3):

- **Tier 1 — Substrate.** Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007) + `exeris-sdk` + `exeris-tooling` (build-time, ADR-015).
  - Community driver = Maven modules inside `exeris-kernel/`, NOT a sibling repo.
  - Enterprise driver (`exeris-kernel-enterprise`) ships io_uring/IOCP, QUIC TLS, HTTP/3, slab pools, NUMA. Enterprise swap is a **Tier 1 substrate driver swap** (Maven coordinate), NOT a Tier 2 cap manifest swap. There is no `exeris-caps-quic-*` or `exeris-caps-io-uring-*`.
  - `exeris-spring-runtime` is an **independent Tier 1 product**. Two consumers: brownfield Spring customer apps + BudgetHQ. Platform itself does NOT depend on it.

- **Tier 2 — Capability Ecosystem.** ~50 `exeris-caps-*` repos across seven layers. Driver-agnostic by construction; Spring-free per cap-tier Wall.

- **Tier 3 — Vertical SaaS SKUs.** First-party `exeris-sku-*` cap compositions. **All run kernel-direct** (no Spring Runtime). HTTP comes from `@ExerisDomain` + `@Action` + `rest-emission` codegen (ADR-015), NOT Spring `@RestController`.

- **Family products** (separate axis, HLA §9): BudgetHQ first; structurally distinct from Platform SKUs. **All future Family products will be pure-Exeris** on SDK + tooling. BudgetHQ is the singular Spring-on-Exeris dogfooding case.

Change:
$ARGUMENTS

Please review:
1. Is Tier 1 / Tier 2 / Tier 3 framing correct (no SKUs claiming Spring Runtime; no caps claiming native-bypass transport)?
2. Is the Enterprise engine swap described as Tier 1 substrate driver swap, not as Tier 2 cap manifest swap?
3. Is `exeris-spring-runtime` framed as independent Tier 1 (not "part of the platform")?
4. Are caps framed as driver-agnostic + Spring-free (no cap `@Requires: exeris-spring-runtime`)?
5. Are Family products framed as a separate axis from Platform SKUs, with BudgetHQ as the singular dogfooding case?
6. Is the open-core split (Apache 2.0 substrate vs Commercial caps per ADR-023) accurate?
7. Minimal correction if three-tier narrative is at risk.

This is the single most load-bearing framing across the repo. Drift here cascades through every dependent doc.
