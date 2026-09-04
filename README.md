# exeris-docs

Central documentation hub for the Exeris Systems ecosystem. This repository holds the artifacts that are intentionally cross-cutting — the ADR registry, the platform-scope ADRs, the High-Level Architecture, the customer-facing whitepaper, the RFCs, the documentation standards, and the decision-document templates. Per-repo documentation (subsystem docs, repo-specific ADRs, build notes) lives next to the code it describes in the owning repository.

The ecosystem itself is organized as **~20 sibling repositories under `~/exeris-systems/`** — `exeris-kernel`, `exeris-kernel-enterprise`, `exeris-sdk`, `exeris-spring-runtime`, `exeris-tooling`, `exeris-platform`, `exeris-benchmarks`, `exeris-telemetry-spec`, `exeris-enterprise-observability`, plus Family products and supporting repos. The ecosystem-wide map and routing rules live in `~/exeris-systems/CLAUDE.md`.

## Three-tier architecture (one-paragraph summary)

The platform is structured in three tiers, detailed in `high-level-architecture.md` and `b2b-technical-whitepaper.md`:

- **Tier 1 — Substrate.** The Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007) plus `exeris-sdk` and `exeris-tooling` for the build-time pipeline (ADR-015). `exeris-spring-runtime` ships as an **independent Tier 1 product** for customers doing brownfield Spring migration — the platform itself does not use it.
- **Tier 2 — Capability Ecosystem.** `exeris-caps-*` repositories — composable, build-time-validated modules with `@Provides` / `@Requires` contracts. Spring-free; the cap-tier Wall (extension of ADR-006) is enforced by the codegen pipeline.
- **Tier 3 — Vertical SaaS SKUs (Platform SKUs).** First-party cap compositions sold as products — API Gateway, Edge Proxy, Bot Blocker, IDP, PIM, OMS, Headless CMS API. (Context-Centric CRM is a cross-cutting capability, `exeris-caps-contact-graph`, not a standalone SKU repository — ADR-023.) Kernel-direct API surface (`@ExerisDomain` + `@Action` + `rest-emission` codegen); no Spring.

**Family products** (BudgetHQ being the first) are commercially independent SaaS products built by Exeris Systems on the platform; they are structurally distinct from Platform SKUs and are detailed in HLA §9. BudgetHQ is the singular Spring-on-Exeris Family product (dogfooding `exeris-spring-runtime` as a product). All future Family products will be pure-Exeris on SDK + tooling.

## Top-level artifacts

| File | What it is |
|---|---|
| [`high-level-architecture.md`](high-level-architecture.md) | C4 model, capability composition model, SKU compositions, open-core split, telemetry architecture, Family-product framing. The authoritative architecture document. |
| [`b2b-technical-whitepaper.md`](b2b-technical-whitepaper.md) | Buyer-facing summary — three-tier structure, empirical evidence, deployment models, sovereignty/IP framing, roadmap. |
| [`adr-index.md`](adr-index.md) | The central tech ADR registry. Single numbering namespace (`ADR-NNN`) across the entire ecosystem. |
| [`adr/`](adr/) | Platform-scope tech ADRs that live in this repo (ADR-001, ADR-002, ADR-004, ADR-006, ADR-020, ADR-023, ADR-024, ADR-053). Per-repo ADRs live next to their owning code. |
| [`templates/`](templates/) | Decision-document templates: `RESEARCH-TEMPLATE.md`, `RFC-TEMPLATE.md`, `ADR-TEMPLATE.md`. See lifecycle notes in [`templates/README.md`](templates/README.md). |
| [`rfc/`](rfc/) | Platform-scope RFCs — multi-option strategic questions whose output is a recommendation, not a decision. No central registry. |
| [`standards/`](standards/) | The documentation, commit, PR, Javadoc, ADR, changelog and agent-file standards for every Exeris repository (ADR-085). Repos link here; they never copy. |
| [`cap-author-guide.md`](cap-author-guide.md) | How to author a Tier 2 capability — the module class, `@Provides` / `@Requires` contracts, the four-phase lifecycle hooks, the build wiring, the cap-tier Wall. |
| [`cap-license-registry.md`](cap-license-registry.md) | Per-capability licence, visibility and build status across the seven layers. |

<!-- VERIFY(sweep-2026-09): ADR-085 is the ADR that would make `standards/` binding, and it is not accepted yet. Its header table reads **PROPOSED**, its frontmatter reads `status: draft`, and its registry row — added to `adr-index.md` during this sweep, at line 115 — reads `proposed (2026-09-04)`. Until the maintainer accepts it, no page in this repo may describe `standards/` as *binding*; the row above therefore names ADR-085 as the standards' origin without asserting that they bind anything yet. The row satisfies claude-md-schema.md rule 3 (every ADR named must have a registry row) as of this sweep — re-check it if the 085 row is reverted. -->

## ADR registry conventions

**Single numbering namespace** across the ecosystem. An ADR is identified by its number (`ADR-NNN`), not by its file path — reviewers and routines cite by number. The full rules are in [`adr-index.md`](adr-index.md), formalized in [`adr/ADR-020-open-core-documentation-mirror-policy.md`](adr/ADR-020-open-core-documentation-mirror-policy.md). The essentials:

- **Reserve the number first.** A number is reserved by a PR to `adr-index.md` before the ADR-content PR merges. Numbering is chronological by decision date, with reserved gap-fillers for backdated decisions.
- **One authoritative location per ADR.** Cross-repo ADRs live in the owning repo's `docs/adr/`; every other affected repo holds a `docs/adr/ADR-NNN.link.md` stub pointing at the authoritative copy. Stubs are navigation aids, not content.
- **Visibility taxonomy is two-valued** (per ADR-020): `public` or `enterprise-private`. The legacy `public-staged` value is deprecated.
- **Refactor-only docs are not ADRs.** Documents whose primary purpose is to track the mechanics of a refactor live in `<repo>/docs/refactor-notes/` (or in PR descriptions) and never get assigned ADR numbers.
- **Out of scope for the registry:** `budgetHQ/`, `pbm/`, and similar portfolio products have their own internal namespaces and do not enter `adr-index.md`.

Capability licensing taxonomy (`community` / `commercial` / `enterprise-private`) is a separate axis from ADR-020 visibility and applies to Tier 2 cap repositories specifically. It is formalized in **ADR-023 (Capability Licensing Taxonomy, accepted 2026-05-13)**; HLA §3.2 and whitepaper §3.2 mirror it.

## Decision-document templates

Three shapes for three question kinds — they live in [`templates/`](templates/) and are not interchangeable:

- **Research** (`RESEARCH-TEMPLATE.md`) — falsifiable hypothesis ("Does X reduce Y by Z%?"). Lab-notebook shape, JMH / JFR / profiling-driven. Branch-scoped on `research/<slug>` in any repo's `docs/research/`. No central registry.
- **RFC** (`RFC-TEMPLATE.md`) — multi-option strategic question ("Should we choose A, B, or C?"). Filename: `RFC-YYYY-MM-DD-<kebab>.md`. No central registry. Output is a recommendation that may produce one or more ADRs.
- **ADR** (`ADR-TEMPLATE.md`) — a decision already made. Filename: `ADR-NNN-<lowercase-kebab-title>.md`. Enters the registry.

When drafting an ADR, check the question shape first: if upstream measurement or option comparison is missing, write a Research or an RFC before going straight to ADR.

## What lives here vs in sibling repos

| Document type | Location |
|---|---|
| Platform-scope ADR | `exeris-docs/adr/` |
| Per-repo ADR (kernel, sdk, spring-runtime, tooling, ...) | `<owning-repo>/docs/adr/` (cross-repo ADRs also leave `.link.md` stubs in every affected repo) |
| Enterprise-private ADR | `<enterprise-repo>/docs/adr/` — number publicly registered in `adr-index.md`, content private |
| Subsystem docs (transport, persistence, crypto, graph, ...) | `<owning-repo>/docs/subsystems/<name>.md` |
| Whitepaper / HLA / performance-contract | `exeris-kernel/docs/` for kernel-platform documents; `exeris-docs/` for ecosystem-wide documents (this repo) |
| Refactor working notes | `<repo>/docs/refactor-notes/` — never assigned ADR numbers |

If a task spans repos, the owning repo holds the authoritative copy and other affected repos get `.link.md` stubs.

## Language

The codebase is English-first. All documentation in this repository — ADRs, registries, templates, the HLA, the whitepaper — is in English. Conversations with the founder happen in Polish, but persisted artifacts are English. Legacy Polish-language refactor notes inside `exeris-kernel-enterprise/docs/refactor-notes/` are deliberately not promoted to the unified ADR registry.

## When to open this repo (vs. a sub-repo)

Open this repo for: looking up an ADR by number, drafting a new platform-scope ADR or template-driven document, reading the HLA or whitepaper, editing the central registries, or working on cross-cutting strategy documents. For any non-trivial implementation task, change in subsystem behaviour, or repo-specific tooling, work in the owning sibling repository instead — that is where the actionable `CLAUDE.md`, build commands, and code-level guardrails live.
