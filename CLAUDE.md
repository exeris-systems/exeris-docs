# CLAUDE.md — exeris-docs

Guardrails for AI assistants (Claude Code, Copilot, Cursor) working inside `~/exeris-systems/exeris-docs/`. Human-facing repository description lives in [`README.md`](README.md); this file captures the constraints, conventions, and "what to do when" rules that an AI session must respect when editing the central documentation surface.

## What this repo is — load-bearing facts

`exeris-docs` is the **central documentation hub** for the Exeris Systems ecosystem. It holds the ADR registry (single numbering namespace across ~20 sibling repositories), the platform-scope ADRs, the High-Level Architecture, the customer-facing whitepaper, the decision-document templates, and the execution-plan trail behind major restructures. Per-repo docs (subsystem docs, repo-specific ADRs, build notes) live next to the code they describe in the owning repository.

This is **not** a monorepo. The ecosystem is ~20 sibling repos under `~/exeris-systems/`; the top-level routing rules live in [`~/exeris-systems/CLAUDE.md`](../CLAUDE.md).

## Documentation precedence — which doc is authoritative for which question

When sources disagree, prefer in this order:

1. **The canonical subsystem doc in the owning repo** (e.g. `exeris-kernel/docs/subsystems/bootstrap.md` for the bootstrap DAG, `exeris-kernel/docs/subsystems/graph.md` for graph engine support). Subsystem docs reflect implementation reality; everything else is summarising them.
2. **The ADR registry** ([`adr-index.md`](adr-index.md)) and the ADR file it points at. ADRs are the long-lived architectural intent.
3. **High-Level Architecture** ([`high-level-architecture.md`](high-level-architecture.md)) for the ecosystem-wide structural narrative (C4 model, three-tier architecture, capability composition model, SKU compositions, open-core split, telemetry path, Family-product framing).
4. **B2B technical whitepaper** ([`b2b-technical-whitepaper.md`](b2b-technical-whitepaper.md)) for the buyer-facing summary and roadmap.

If a higher-precedence source contradicts a lower one, the higher source wins and the lower source is a doc-drift task. Never the reverse.

## The three-tier architecture (load-bearing — every doc edit must respect)

The platform is structured in three tiers, formalized in HLA §§2.2, 3, 4, 5 and whitepaper §3. Any doc edit that frames the platform differently is wrong:

- **Tier 1 — Substrate.** The Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007) plus `exeris-sdk` and `exeris-tooling` for the build-time pipeline (ADR-015).
  - **Community driver** lives as Maven modules inside `exeris-kernel/` (`exeris-kernel-community`, `exeris-kernel-community-kafka`, `exeris-kernel-community-testkit`) — NOT as a separate sibling repository. Don't enumerate it as a sibling repo.
  - **Enterprise driver** (`exeris-kernel-enterprise`) ships `io_uring`/IOCP transport, `EnterpriseQuicTlsEngine`, HTTP/3, slab pools, NUMA. The Enterprise engine swap is a Tier 1 substrate driver swap (Maven coordinate change), **NOT** a Tier 2 cap manifest swap. There is no `exeris-caps-quic-*` or `exeris-caps-io-uring-*` cap.
  - **`exeris-spring-runtime`** is an **independent Tier 1 product**, sold separately. Used by exactly two consumers: (a) customers with existing Spring applications doing brownfield migration; (b) BudgetHQ as the singular Family-product dogfooding case for the Spring-on-Exeris combination. The platform itself (kernel + caps + SKUs) does **not** depend on it.
- **Tier 2 — Capability Ecosystem.** ~50 `exeris-caps-*` repositories across seven layers (substrate aggregates, Gateway building blocks, Gateway policies, Service Boundary platform caps, Domain primitives, AI Abstraction, Cross-cutting). Driver-agnostic by construction; Spring-free per the cap-tier Wall (extension of ADR-006).
- **Tier 3 — Vertical SaaS SKUs.** First-party `exeris-sku-*` cap compositions. **All run kernel-direct** (no Spring Runtime). HTTP surface comes from `@ExerisDomain` + `@Action` + `rest-emission` codegen (ADR-015), NOT from Spring `@RestController`.

**Family products** (BudgetHQ being the first) are commercially independent SaaS products built by Exeris Systems on the platform — structurally distinct from Platform SKUs (HLA §9). BudgetHQ is the singular Spring-on-Exeris Family product; **all future Family products will be pure-Exeris** on `exeris-sdk` + `exeris-tooling`.

## Capability layer — licensing and composition (ADR-023, ADR-024)

Caps participate in two orthogonal dimensions:

**Licensing taxonomy** (ADR-023, three values — orthogonal to ADR-020 visibility):
- `community` (Apache 2.0 / MIT) — 3 caps: `cors-policy`, `i18n`, `observability-bridge`
- `commercial` (Exeris Commercial License, source-available, BSL-style) — 46 caps (the bulk of Tier 2)
- `enterprise-private` (closed-source, Enterprise tier only) — 1 cap: `bot-fingerprinting`

**SKU repository source-visibility** (ADR-023 same-day amendment 2026-05-13):
- 6/7 Platform SKUs are **source-available** public repositories under Exeris Commercial License (API Gateway, Edge Proxy, IDP, PIM, OMS, Headless CMS)
- 1/7 Platform SKU is **closed-source** on anti-abuse-security principle: Bot Blocker (the named exception, principled — published detection logic helps adversaries circumvent the protection)

**Composition model** (ADR-024): caps declare `@Provides(Service, version)`, `@Requires(Service, versionRange, optional?)`, and a four-phase lifecycle (`initialize → ready → drain → terminate`). Compositions are DAGs of caps with no unresolved `@Requires`, no cycles, no version conflicts, no Wall violations. Validated at build time by the codegen pipeline (`exeris-tooling`, ADR-015); the kernel refuses to start a composition without a validation stamp.

**The Wall extends to caps.** No cap imports `org.springframework.*`, `io.netty.*`, `reactor.*`, `jakarta.servlet.*`, or any host-runtime-specific package. Spring `@RestController` paths in customer code or BudgetHQ depend on caps via `@Provides`; the dependency arrow never reverses. No cap `@Requires` `exeris-spring-runtime`. No SKU manifest layers it in.

## Graph subsystem — dual-engine, not Postgres-only

The kernel Graph SPI is **dual-engine** per `exeris-kernel/docs/subsystems/graph.md`: a unified `MATCH` DSL transpiles to either SQL:2023 PGQ (on PostgreSQL 18) or Cypher (on Neo4j / Memgraph / FalkorDB). Both engine paths ship in Community. Enterprise tier adds a native PG v3 wire-protocol driver (off-heap, no JDBC tax) plus a planned FFM Bolt v5 driver for Neo4j (TRL-4, not yet shipping).

**ADR-002** scopes itself explicitly as "platform-recommended stack for new applications, not a kernel mandate." When documenting or recommending, distinguish between (a) the platform default stack recommendation (Postgres + PGQ) and (b) the kernel's actual capability (dual-engine via SPI). Don't conflate them.

## Bootstrap DAG — canonical reference

Per `exeris-kernel/docs/subsystems/bootstrap.md`:

```
FOUNDATION: Memory (sequential)
    ↓
SERVICES: Crypto & Persistence & Graph & Transport (parallel via StructuredTaskScope)
    ↓
RUNTIME: Events & Flow & HTTP (parallel)
    ↓
KERNEL READY
```

`Config` is resolved by `KernelBootstrap` via `ServiceLoader<ConfigProvider>` before the orchestrator runs and is **not** a Subsystem in the DAG. `Exceptions` is not a Subsystem layer. `Security` is an L1 Citadel concept (ADR-012), not a boot-DAG node. The deprecated `Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow} → READY` framing should be replaced wherever it surfaces (drift detection: see `exeris-spring-runtime/CLAUDE.md` fix on 2026-05-13).

## ADR registry conventions — hard rules

Single numbering namespace across the ecosystem. The full rules are in [`adr-index.md`](adr-index.md) and formalized in [`adr/ADR-020-open-core-documentation-mirror-policy.md`](adr/ADR-020-open-core-documentation-mirror-policy.md). Essentials any AI session must follow:

- **Reserve the number first.** A new ADR adds its row to `adr-index.md` (PR or commit) **before** the ADR-content file lands. Numbering is chronological by decision date with reserved gap-fillers for backdated decisions.
- **Filename pattern.** `ADR-NNN-<lowercase-kebab-title>.md` — 3-digit zero-padded, then `-`, then the title in lowercase kebab-case. Replace `&` with `and`; drop other punctuation. Examples: `ADR-023-capability-licensing-taxonomy.md`, `ADR-024-capability-composition-model.md`.
- **Authoritative location per scope.** Platform-scope ADRs → `exeris-docs/adr/`. Per-repo ADRs → `<owning-repo>/docs/adr/`. Cross-repo ADRs → owning repo's `docs/adr/` plus `ADR-NNN.link.md` stubs in every affected repo. Enterprise-private ADRs → `<enterprise-repo>/docs/adr/` (number publicly registered, content private).
- **Visibility taxonomy is two-valued** per ADR-020: `public` or `enterprise-private`. The legacy `public-staged` is deprecated.
- **License taxonomy is a separate axis** per ADR-023 — three values (`community` / `commercial` / `enterprise-private`) that apply to capability artefacts, not to ADR files. Don't conflate visibility with license.
- **Refactor-only docs are not ADRs.** They live in `<repo>/docs/refactor-notes/` (or in PR descriptions) and never get ADR numbers.
- **Out of scope for the registry.** `budgetHQ/`, `pbm/`, and similar portfolio products have internal namespaces and do not enter `adr-index.md`.

When asked to "draft an ADR," check the question shape first: if upstream measurement is missing, suggest a Research; if option-comparison is missing, suggest an RFC; if the decision is already informally made, go straight to ADR. The three template shapes live in [`templates/`](templates/) and are not interchangeable (see `templates/README.md`).

## Common drift patterns to watch

These have been caught across multiple sessions — when editing whitepaper / HLA / ADRs, sweep for them:

1. **"Postgres-only graph" / "replacing Neo4j"** — wrong. Kernel ships dual-engine. ADR-002 is platform recommendation; the kernel SPI is engine-agnostic.
2. **`exeris-kernel-community` listed as a sibling repository** — wrong. It is a Maven module inside `exeris-kernel/`, not a sibling.
3. **`exeris-caps-quic-h3` / `exeris-caps-io-uring-transport`** — these caps do NOT exist. Native-bypass transport is Tier 1 substrate (`exeris-kernel-enterprise`), not Tier 2.
4. **SB-family SKUs "use Spring Runtime"** — wrong. SB SKUs are kernel-direct via `@ExerisDomain` + `rest-emission` codegen. Spring Runtime has only two consumers: brownfield customer apps and BudgetHQ.
5. **Cap `@Requires: exeris-spring-runtime`** — wrong. Violates cap-tier Wall. Caps depend only on kernel SPIs.
6. **Two-value license taxonomy for caps** — wrong. Three-value (`community` / `commercial` / `enterprise-private`) per ADR-023.
7. **Bootstrap DAG with `Config → Memory → Exceptions → {...}`** — deprecated. Replace with the canonical FOUNDATION / SERVICES / RUNTIME shape above.
8. **"Family products run on Spring Runtime"** — wrong. Only BudgetHQ runs on Spring Runtime (singular dogfooding case). All future Family products are pure-Exeris.
9. **Spring Runtime described as part of "the platform stack"** — wrong. Independent Tier 1 product.
10. **TRL-5 or higher claimed for the platform-aggregate state** — currently TRL-3 (Validated Architectural Prototype). Subsystems are ahead (Crypto TRL-4). Per whitepaper §7 roadmap, Q3 2026 = TRL-4 integration-tested; Q4 2026 = TRL-5 component validation + v0.9-RC SPI lock; H1 2027 = TRL-6 with Kernel 1.0 GA + Spring Runtime 1.0 GA shipped together. (2027+ horizons use half-year notation — never quarters; matches the arkstack.dev roadmap canon.)

## Editing discipline for large docs

The whitepaper and HLA each cleared 5,000+ words after the 2026-05-12 restructure. When editing them:

- Run a targeted grep before any edit (`grep -nE '<pattern>' high-level-architecture.md` etc.) to find every site that needs the same correction. Single-edit changes leave inconsistencies.
- After a non-trivial edit, sweep for the drift-patterns list above on the edited file.
- Don't silently delete plan content — mark superseded plan paragraphs as historical-intent in the reconciliation, don't rewrite them in place.

## Language

The codebase is English-first. All documentation in this repository — ADRs, registries, templates, HLA, whitepaper, execution plans, this CLAUDE.md — is in English. Conversation with the founder happens in Polish; persisted artefacts are English. Legacy Polish-language refactor notes inside `exeris-kernel-enterprise/docs/adr/` are deliberately not promoted to the unified ADR registry.

## When to open this repo (vs. a sub-repo)

Open this repo for: looking up an ADR by number, drafting a new platform-scope ADR or template-driven document, reading the HLA or whitepaper, editing the central registries, or working on cross-cutting strategy documents. For any non-trivial implementation task, change in subsystem behaviour, or repo-specific tooling, `cd` into the owning sibling repository instead — that is where the actionable code-level guardrails live.

## Auto-memory

Persistent memory for this workspace lives at `~/.claude/projects/-home-arkstack-exeris-systems-exeris-docs/memory/`. Use it for **process feedback** and **user preferences** — not for project facts. Project facts belong in this CLAUDE.md (versioned, visible to humans and other AI tools) or in the canonical docs / ADRs.
