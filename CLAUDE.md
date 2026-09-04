---
title: "CLAUDE.md — exeris-docs"
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# CLAUDE.md — exeris-docs

Guardrails for AI assistants (Claude Code, Copilot, Cursor) working inside `~/exeris-systems/exeris-docs/`. Human-facing repository description lives in [`README.md`](README.md); this file captures the constraints, conventions, and "what to do when" rules that an AI session must respect when editing the central documentation surface.

## What this repo is — load-bearing facts

`exeris-docs` is the **central documentation hub** for the Exeris Systems ecosystem. It holds the ADR registry (single numbering namespace across ~20 sibling repositories), the platform-scope ADRs, the High-Level Architecture, the customer-facing whitepaper, the decision-document templates, the RFCs, and the documentation standards. Per-repo docs (subsystem docs, repo-specific ADRs, build notes) live next to the code they describe in the owning repository.

This is **not** a monorepo. The ecosystem is ~20 sibling repos under `~/exeris-systems/`; the top-level routing rules live in `~/exeris-systems/CLAUDE.md` — a workstation path, not a repository file, so it is deliberately not a link.

## Documentation precedence

When sources disagree, prefer in this order:

1. **The canonical subsystem doc in the owning repo** (e.g. `exeris-kernel/docs/subsystems/bootstrap.md` for the bootstrap DAG, `exeris-kernel/docs/subsystems/graph.md` for graph engine support). Subsystem docs reflect implementation reality; everything else is summarising them.
2. **The ADR registry** ([`adr-index.md`](adr-index.md)) and the ADR file it points at. ADRs are the long-lived architectural intent.
3. **High-Level Architecture** ([`high-level-architecture.md`](high-level-architecture.md)) for the ecosystem-wide structural narrative (C4 model, three-tier architecture, capability composition model, SKU compositions, open-core split, telemetry path, Family-product framing).
4. **B2B technical whitepaper** ([`b2b-technical-whitepaper.md`](b2b-technical-whitepaper.md)) for the buyer-facing summary and roadmap.

If a higher-precedence source contradicts a lower one, the higher source wins and the lower source is a doc-drift task. Never the reverse.

## Rule levels

Three levels in the schema's vocabulary. **A)** is enforced or non-negotiable; **B)** is the default you need a stated reason to depart from; **C)** is a checklist to sweep an edited file against.

### A) Hard constraints

Single numbering namespace across the ecosystem. The full rules are in [`adr-index.md`](adr-index.md) and formalized in [`adr/ADR-020-open-core-documentation-mirror-policy.md`](adr/ADR-020-open-core-documentation-mirror-policy.md). Essentials any AI session must follow:

<!-- NOTE(sweep-2026-09): the gates these standards cite are not yet wired into this repository. .github/workflows/ holds only claude-code-review.yml and claude.yml, and no workflow references registry_check.py, frontmatter_check.py or claude_md_check.py; the scripts live in an untracked shared tree reached via the .guardrails symlink to ~/exeris-systems/.guardrails. Until a caller workflow lands, no rule may be dropped from this file on the grounds that "CI reports it instead" (claude-md-schema.md rule 5). -->

- **Reserve the number first.** A new ADR adds its row to `adr-index.md` (PR or commit) **before** the ADR-content file lands. Numbering is chronological by decision date with reserved gap-fillers for backdated decisions.
- **Filename pattern.** `ADR-NNN-<lowercase-kebab-title>.md` — 3-digit zero-padded, then `-`, then the title in lowercase kebab-case. Replace `&` with `and`; drop other punctuation. Examples: `ADR-023-capability-licensing-taxonomy.md`, `ADR-024-capability-composition-model.md`.
- **Authoritative location per scope.** Platform-scope ADRs → `exeris-docs/adr/`. Per-repo ADRs → `<owning-repo>/docs/adr/`. Cross-repo ADRs → owning repo's `docs/adr/` plus `ADR-NNN.link.md` stubs in every affected repo. Enterprise-private ADRs → `<enterprise-repo>/docs/adr/` (number publicly registered, content private).
- **Visibility taxonomy is two-valued** per ADR-020: `public` or `enterprise-private`. The legacy `public-staged` is deprecated.
- **License taxonomy is a separate axis** per ADR-023 — three values (`community` / `commercial` / `enterprise-private`) that apply to capability artefacts, not to ADR files. Don't conflate visibility with license.
- **Refactor-only docs are not ADRs.** They live in `<repo>/docs/refactor-notes/` (or in PR descriptions) and never get ADR numbers.
- **Out of scope for the registry.** `budgetHQ/`, `pbm/`, and similar portfolio products have internal namespaces and do not enter `adr-index.md`.

When asked to "draft an ADR," check the question shape first: if upstream measurement is missing, suggest a Research; if option-comparison is missing, suggest an RFC; if the decision is already informally made, go straight to ADR. The three template shapes live in [`templates/`](templates/) and are not interchangeable (see `templates/README.md`).

<!-- NOTE(sweep-2026-09): this numbered list is load-bearing for two standards. docs-style-guide.md rule 10 seeds Vale existence rules from it by section name ("Common drift patterns"), and claims-and-evidence.md rule 4 makes items 10-13 error-level Vale rules, citing them by number. Item numbering and the section heading are therefore frozen: renaming the section, renumbering an item, or relocating the block requires editing both standards in the same PR, and standards/ is exempt from this sweep. Note the trap this creates: items 10, 11 and 13 are the sentences that name the forbidden figures in order to forbid them, so the Exeris Vale package must exempt this file (the RetractedFigures off/on comments below are the local mitigation) or the file that defines the rules will be the first to fail them. The same applies to whitepaper §4.1's retraction box. -->

### B) Strong defaults

The whitepaper and the HLA are long and heavily cross-referenced. When editing them:

- Run a targeted grep before any edit (`grep -nE '<pattern>' high-level-architecture.md` etc.) to find every site that needs the same correction. Single-edit changes leave inconsistencies.
- After a non-trivial edit, sweep for the drift-patterns list above on the edited file.
- Don't silently delete superseded content — mark superseded paragraphs, don't rewrite them in place. The record-side form of the same discipline is [`standards/adr-conventions.md`](standards/adr-conventions.md) rule 7.

### C) Heuristics

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

<!-- vale Exeris.RetractedFigures = NO -->

10. **The 2026-05-05 `e2e-shop-order-saga` table — never cite it again.** The dev-laptop run of 2026-05-05 (459 MB / 752 MB / 1,312 MB RSS; 0% / 1.82% / 1.22% compensation-unresolved columns; the 3.4× / 4.7× density multipliers; the "structural signature of async event-sourced dispatch returning before the work is done" mechanism) is **retracted in full** — see whitepaper §4.1's retraction box and entry **#23** in `exeris-benchmarks/docs/CLAIMS.md`'s retraction register. Three independent grounds: the Quarkus arm never ran an Axon saga (`grep '@Saga' exeris-benchmarks/targets/quarkus-benchmark-app*/src` is empty — the orchestration was hand-rolled over Axon's command bus); the correctness columns tracked a harness defect (the k6 poller's terminal-state dictionary did not recognise `CANCELLED`, documented in `AxonOrderSagaProjection`); and `exeris-benchmarks/scenarios/e2e-shop-order-saga/CONTRACT-v2.md` §10 classes the v1 findings **superseded** and any mixed-population latency table **"invalid under v2, do not cite"**. Two standing rules follow: **"Axon" never appears next to a number**, and **no figure may depend on the v1 unresolved-rate gap.** No v2 comparative saga numbers exist yet. This is the one retraction in that register that reached distributed artefacts — site, both CVs, blog EN + PL, dev.to — so treat any surviving copy of it as live, not historical.
11. **Unsourced inflation magnitudes** — *"~60% CPU waste"*, *">160 GB of allocations on a 4 GB payload"*. Withdrawn from whitepaper §1 and HLA §3.1; no campaign in `exeris-benchmarks` supports either. The gated replacements are **−25.6% / −33.3% CPU per request** and the **~1/2.7 RSS ratio with its matched-heap qualifier (1.18–1.26×)**, from `results/reports/2026-07-21-entity-read-by-id-tuned-pg-triad-comparison-eligible.md`.
12. **Quoting a benchmark figure without its fence.** `exeris-benchmarks/docs/CLAIMS.md` is the citation authority and says *"consumers copy, never paraphrase"*; read its **retraction register** and **citation canon** before quoting. Heavy-contract throughput ratios are never quotable (they read the Postgres ceiling); use CPU/req. Footprint claims travel with the budget-matched-vs-heap-matched qualifier.
13. **TRL-5 or higher claimed for the platform-aggregate state** — currently TRL-3 (Validated Architectural Prototype). Subsystems are ahead (Crypto TRL-4). Per whitepaper §7 roadmap, Q3 2026 = TRL-4 integration-tested **for the kernel subsystem set**; Q4 2026 = TRL-5 component validation + the RC SPI lock; H1 2027 = TRL-6 with Kernel 1.0 GA + Spring Runtime 1.0 GA shipped together. (2027+ horizons use half-year notation — never quarters; matches the arkstack.dev roadmap canon.)

<!-- vale Exeris.RetractedFigures = YES -->

## Scoped bans

Absolute in this repository. The reasoning sits in the rule levels above and is not repeated here.

- **Never cite the 2026-05-05 `e2e-shop-order-saga` run**, in whole or in part — C-10. Two rules follow from it: "Axon" never appears next to a number, and no figure may depend on the v1 unresolved-rate gap.
- **Never assert a benchmark figure without its report path and figure state** — C-12, gated by [`standards/claims-and-evidence.md`](standards/claims-and-evidence.md). A withdrawal is fenced with the Vale toggle, never edited away.
- **Never edit an ADR's decision text in place.** A change of substance is a dated entry under `## Amendments` — [`standards/adr-conventions.md`](standards/adr-conventions.md) rule 7.
- **Never give a `budgetHQ/` or `pbm/` decision a number from this registry** — A, "Out of scope for the registry".

## Language

English everywhere — source, comments, commit messages, PR titles, ADRs, this file. Conversation with the founder happens in Polish; persisted artefacts are English.

Legacy Polish-language refactor notes inside `exeris-kernel-enterprise/docs/refactor-notes/` are deliberately not promoted to the unified ADR registry.

## Cross-repo ADRs to consult

Open these before editing the documents they govern. Each has a row in [`adr-index.md`](adr-index.md).

- [ADR-006](adr/ADR-006-spring-free-kernel-boundary.md) — the Spring-free kernel boundary ("the Wall"). Any statement about what the kernel may depend on.
- [ADR-020](adr/ADR-020-open-core-documentation-mirror-policy.md) — open-core documentation mirror policy. Every `(content private)` marker and every public-to-private link decision.
- [ADR-023](adr/ADR-023-capability-licensing-taxonomy.md) — capability licensing taxonomy, the three-value licence axis.
- [ADR-024](adr/ADR-024-capability-composition-model.md) — capability composition model: manifests, `@Requires`, build-time validation.
- [ADR-053](adr/ADR-053-sku-composition-manifest-format.md) — SKU composition manifest format.
- [ADR-085](adr/ADR-085-documentation-architecture-and-repo-hygiene-standards.md) — the documentation standards this file answers to.
- [ADR-001](adr/ADR-001-cloud-native-and-agnostic-infrastructure-strategy.md) and [ADR-002](adr/ADR-002-unified-database-strategy.md) — infrastructure and database strategy. ADR-002 scopes itself as a platform recommendation, not a kernel mandate.
- [ADR-004](adr/ADR-004-jdk-26-ea-preview-features-mandate.md) — the JDK mandate. Read its own Status before quoting a baseline from it.

## Conventions

The binding standards live in [`standards/`](standards/) and are not restated here. When this file and a standard disagree, the standard wins and this file is the defect.

- [`standards/commit-conventions.md`](standards/commit-conventions.md)
- [`standards/pr-conventions.md`](standards/pr-conventions.md)
- [`standards/javadoc-conventions.md`](standards/javadoc-conventions.md)
- [`standards/docs-style-guide.md`](standards/docs-style-guide.md)
- [`standards/adr-conventions.md`](standards/adr-conventions.md)
- [`standards/ai-provenance.md`](standards/ai-provenance.md)

## Auto-memory

Persistent memory for this workspace lives at `~/.claude/projects/-home-arkstack-exeris-systems-exeris-docs/memory/`. Use it for **process feedback** and **user preferences** — not for project facts. Project facts belong in this CLAUDE.md (versioned, visible to humans and other AI tools) or in the canonical docs / ADRs.

## The three-tier architecture (load-bearing — every doc edit must respect)

The platform is structured in three tiers, formalized in HLA §§2.2, 3, 4, 5 and whitepaper §3. Any doc edit that frames the platform differently is wrong:

- **Tier 1 — Substrate.** The Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007) plus `exeris-sdk` and `exeris-tooling` for the build-time pipeline (ADR-015).
  - **Community driver** lives as Maven modules inside `exeris-kernel/` (`exeris-kernel-community`, `exeris-kernel-community-kafka`, `exeris-kernel-community-testkit`) — NOT as a separate sibling repository. Don't enumerate it as a sibling repo.
  - **Enterprise driver** (`exeris-kernel-enterprise`) ships `io_uring`/IOCP transport, `EnterpriseQuicTlsEngine`, HTTP/3, slab pools, NUMA. The Enterprise engine swap is a Tier 1 substrate driver swap (Maven coordinate change), **NOT** a Tier 2 cap manifest swap. There is no `exeris-caps-quic-*` or `exeris-caps-io-uring-*` cap.
  - **`exeris-spring-runtime`** is an **independent Tier 1 product**, sold separately. Used by exactly two consumers: (a) customers with existing Spring applications doing brownfield migration; (b) BudgetHQ as the singular Family-product dogfooding case for the Spring-on-Exeris combination. The platform itself (kernel + caps + SKUs) does **not** depend on it.
- **Tier 2 — Capability Ecosystem.** ~50 `exeris-caps-*` capabilities across seven layers (substrate aggregates, Gateway building blocks, Gateway policies, Service Boundary platform caps, Domain primitives, AI Abstraction, Cross-cutting), enumerated with their licence and build status in [`cap-license-registry.md`](cap-license-registry.md) — one cap repository exists today (`exeris-caps-cors-policy`, scaffolded); the rest are `specified`. Driver-agnostic by construction; Spring-free per the cap-tier Wall (extension of ADR-006).
- **Tier 3 — Vertical SaaS SKUs.** First-party `exeris-sku-*` cap compositions. **All run kernel-direct** (no Spring Runtime). HTTP surface comes from `@ExerisDomain` + `@Action` + `rest-emission` codegen (ADR-015), NOT from Spring `@RestController`.

**Family products** (BudgetHQ being the first) are commercially independent SaaS products built by Exeris Systems on the platform — structurally distinct from Platform SKUs (HLA §9). BudgetHQ is the singular Spring-on-Exeris Family product; **all future Family products will be pure-Exeris** on `exeris-sdk` + `exeris-tooling`.

## Capability layer — licensing and composition (ADR-023, ADR-024)

Caps participate in two orthogonal dimensions:

**Licensing taxonomy** (ADR-023, three values — orthogonal to ADR-020 visibility):
- `community` (Apache 2.0 / MIT) — 3 caps: `cors-policy`, `i18n`, `observability-bridge`
- `commercial` (Exeris Commercial License, source-available, BSL-style) — 50 caps (the bulk of Tier 2)
- `enterprise-private` (closed-source, Enterprise tier only) — 1 cap: `bot-fingerprinting`

**SKU repository source-visibility** (ADR-023 same-day amendment 2026-05-13):
- 6/7 Platform SKUs are **source-available** public repositories under Exeris Commercial License (API Gateway, Edge Proxy, IDP, PIM, OMS, Headless CMS API)
- 1/7 Platform SKU is **closed-source** on anti-abuse-security principle: Bot Blocker (the named exception, principled — published detection logic helps adversaries circumvent the protection)

**Composition model** (ADR-024, amended through 2026-07-21): caps declare `@Provides(Service, version)`, `@Requires(Service, versionRange, optional?)`, and a four-phase lifecycle (`initialize → ready → drain → terminate`). Compositions are DAGs of caps with no unresolved `@Requires`, no cycles, no version conflicts, no Wall violations. Validated at build time by the codegen pipeline (`exeris-tooling`, ADR-015), which stamps the manifest (validation stamp + content binding); the SDK-side composition runtime in the generated SKU bootstrap asserts the stamp after `KERNEL READY`, before any cap `initialize`. The kernel is **cap-blind** — no stamp check, no manifest reader, no cap-tier `Subsystem` registration. Manifest format is JSON (ADR-053).

**The Wall extends to caps.** No cap imports `org.springframework.*`, `io.netty.*`, `reactor.*`, `jakarta.servlet.*`, or any host-runtime-specific package. Spring `@RestController` paths in customer code or BudgetHQ depend on caps via `@Provides`; the dependency arrow never reverses. No cap `@Requires` `exeris-spring-runtime`. No SKU manifest layers it in.

## Graph subsystem — dual-engine, not Postgres-only

The kernel Graph SPI is **dual-engine** per `exeris-kernel/docs/subsystems/graph.md`: a unified `MATCH` DSL transpiles to either SQL:2023 PGQ (on PostgreSQL 18) or Cypher (on Neo4j / Memgraph / FalkorDB). Both engine paths ship in Community. Enterprise tier adds a native PG wire-protocol driver (off-heap, no JDBC tax) plus a planned FFM Bolt v5 driver for Neo4j (TRL-4, not yet shipping).

**ADR-002** scopes itself explicitly as "platform-recommended stack for new applications, not a kernel mandate." When documenting or recommending, distinguish between (a) the platform default stack recommendation (Postgres + PGQ) and (b) the kernel's actual capability (dual-engine via SPI). Don't conflate them.

<!-- VERIFY(sweep-2026-09): the "TRL-4" label on the planned FFM Bolt v5 Neo4j driver is contradicted inside its own repo. exeris-kernel-enterprise/docs/subsystems/graph.md:8, :55 and :93 say "planned TRL-4"; exeris-kernel-enterprise/docs/ROADMAP.md:322 calls the same EPIC-E3 work a "TRL-3 skeleton with HELLO/RUN/PULL". Both sources are enterprise-private while this file is public, and exeris-kernel/docs/subsystems/graph.md — the doc this file names as precedence #1 — carries no Enterprise driver row at all (its Driver Roadmap table at :171-175 lists only PostgreSQL JDBC, Neo4j Bolt and Memgraph Bolt, all Community/TRL-3). Maintainer to pick one TRL value or drop the number. -->

## Bootstrap DAG — canonical reference

Per `exeris-kernel/docs/subsystems/bootstrap.md`:

```
FOUNDATION: Memory (sequential)
    ↓
SERVICES: Crypto & Persistence & Graph & Transport (dependency-safe rounds, on the booting thread)
    ↓
RUNTIME: Events & Flow & HTTP (dependency-safe rounds, on the booting thread)
    ↓
KERNEL READY
```

`Config` is resolved by `KernelBootstrap` via `ServiceLoader<ConfigProvider>` before the orchestrator runs and is **not** a Subsystem in the DAG. `Exceptions` is not a Subsystem layer. `Security` is an L1 Citadel concept (ADR-012), not a boot-DAG node. The deprecated `Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow} → READY` framing should be replaced wherever it surfaces.

<!-- VERIFY(sweep-2026-09): the bootstrap DAG block above is quoted from exeris-kernel/docs/subsystems/bootstrap.md, and that file contradicts itself on the phase-start mechanism. Its "Holy Order" block (:213-215) and Diagram 1 (:66, :71) still read "SERVICES (parallel)" / "RUNTIME (parallel)", while its own ADR-066 passage (:340-355) records that the per-subsystem fork was removed and "a phase takes the sum of its subsystems' start times rather than the longest". SubsystemOrchestrator.java settles it — :691 "Each round runs on THIS thread, in order." — and the wording above follows the code. Cross-repo [DOC DEBT] against exeris-kernel; do not re-sync this block to bootstrap.md's Holy Order text until that file is fixed. -->

<!-- VERIFY(sweep-2026-09): exeris-spring-runtime/CLAUDE.md:83 carries the superseded form of the DAG corrected here — "SERVICES: Crypto & Persistence & Graph & Transport (parallel via StructuredTaskScope)" — contradicted by SubsystemOrchestrator.java:55-57 and :691 on both the default and preview kernel lines. That repo is outside this sweep's scope; cross-repo [DOC DEBT]. -->

## When to open this repo (vs. a sub-repo)

Open this repo for: looking up an ADR by number, drafting a new platform-scope ADR or template-driven document, reading the HLA or whitepaper, editing the central registries, or working on cross-cutting strategy documents. For any non-trivial implementation task, change in subsystem behaviour, or repo-specific tooling, `cd` into the owning sibling repository instead — that is where the actionable code-level guardrails live.
