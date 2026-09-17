---
title: SKU Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-16
---

# SKU Conventions

Binding per ADR-085 §M.37. Applies to every Platform SKU repository (`exeris-sku-*`) in the Tier 3 Platform SKU layer.

**Where this does not apply, and what it costs.** Not to a capability, which `capability-conventions.md` governs, and not to a customer's own assembly of capabilities: a SKU is a composition Exeris names, versions and licenses, and an assembly nobody sells is not one. Not to a demo or a benchmark harness that composes capabilities to exercise them rather than to ship them. The cost is that a SKU pins its capabilities by version, so a capability fix reaches a customer only when the SKU is re-composed and re-released — the driver-swap transparency rule below is what keeps that from meaning a re-qualification as well.

A Platform SKU is a named, version-pinned, commercial-licensed composition of Tier 2 capabilities, packaged as an executable deployable artifact on top of the Exeris Kernel substrate. Governed by [ADR-024](../adr/ADR-024-capability-composition-model.md) (Composition Model), [ADR-053](../adr/ADR-053-sku-composition-manifest-format.md) (Manifest JSON format), [ADR-023](../adr/ADR-023-capability-licensing-taxonomy.md) (Licensing Taxonomy), and [HLA §3.3 / §5](../high-level-architecture.md) (Platform SKUs).

## Hard rules

1. **Repository naming and Maven coordinates.** `[L1: pom enforcer]`
   - Repository name: `exeris-sku-<kebab-name>` (e.g. `exeris-sku-api-gateway`, `exeris-sku-content-api`).
   - Coordinates: `groupId=eu.exeris.sku`, `artifactId=exeris-sku-<kebab-name>`.
   - Package root: `eu.exeris.sku.<shortname>` (e.g. `eu.exeris.sku.gateway`, `eu.exeris.sku.content`).
2. **Canonical manifest `composition.json`.** `[L1: JUnit test & composition assertion]`
   - The authored composition manifest must be located at the repository root and copied to `target/classes/composition.json` (or `src/main/resources/composition.json`).
   - Must conform to the `CapManifest` JSON schema defined in `exeris-sdk-composition-spec` (ADR-053). The schema version is that spec's to state and is not pinned here: ADR-053 names no version, so a number written on this page would be sourced from nothing.
   - Must carry a valid `stamp` containing:
     - `validated: true`
     - `compositionVersion`: matching SKU version
     - `contentBinding`: the deterministic SHA-256 hash computed over the resolved capability list by `CompositionBinding.compute(...)`
   - Runtime and test enforcement: the application entrypoint and test suite must execute `CompositionStampAssertion.assertConsistent(manifest)` before booting capabilities.
3. **Kernel-Direct execution model.** `[L1: CapTierWall / dependency:analyze]`
   - Platform SKUs execute directly on the Exeris Kernel substrate (`KernelBootstrap`) orchestrated by `CompositionConductor`.
   - **Absolute ban on Spring Framework in data plane:** No `spring-boot-starter-*`, no Spring MVC, WebFlux, or Spring DI context in first-party Platform SKUs. The data plane is 100% Exeris-native.
   - Endpoint exposure mechanism:
     - **Service Boundary family:** Endpoints generated from `@ExerisDomain` + `@Action` via `rest-emission` codegen (ADR-015), registered directly into `ApiSurfaceRegistry`.
     - **Gateway family:** Request forwarding and policy chains wired via `GatewayCoreModule`, `PolicyChain`, and `RequestRouter`.
4. **Substrate driver-swap transparency.** `[L1: CapTierWall]`
   - The composition manifest (`composition.json`) and capability code must be **byte-identical** between Community and Enterprise deployments.
   - SKUs reference only kernel SPIs (`eu.exeris.kernel.spi.*`).
   - Swapping from Community (`exeris-kernel-community`) to Enterprise (`exeris-kernel-enterprise`) is strictly a Maven coordinate substitution or classpath driver selection, never a capability manifest change.
5. **Licensing and source visibility.** `[L2: registry check]`
   - The composition manifest itself ships under the Exeris Commercial License (`commercial`).
   - Repository source visibility defaults to **source-available (public)** per ADR-023 §"SKU Repository Source-Visibility Policy" to enable Glass Box verification and customer Code Detachment.
   - The single closed-source (`enterprise-private`) exception is `exeris-sku-bot-blocker` on anti-abuse-security grounds.
6. **Per-SKU measured default JVM settings and diagnostics.** `[L2]`
   - Each SKU must establish its **default JVM settings** from a workload-profiling pass, bake them into the container entrypoint (rule 7), and record them in its own `README.md`. There they are figures like any other: rule 1 of [`claims-and-evidence.md`](claims-and-evidence.md) applies, so each carries a report path and a figure state — `unartifacted` where the pass was run but its report is not published.
   - The settings are not written on this page. Collector choice and heap sizing follow the SKU's workload shape: zero-copy off-heap buffering in a Gateway, heap-resident document and graph work in an IDP domain. One SKU's result written here would be read as every SKU's default, and a record carries no figures at all (`claims-and-evidence.md` rule 6).
   - Every SKU must expose standard health and allocation diagnostics:
     - `/health` or `/actuator/health` (liveness and readiness probes).
     - `/actuator/allocations` (thread allocation tracking via `ThreadMXBean` or kernel telemetry).
7. **Containerization and packaging.** `[L1: docker build]`
   - Must include a production-ready multi-stage `Dockerfile` based on an official, minimal Java 25 runtime image.
   - The entrypoint must incorporate the SKU's default JVM settings as environment defaults while allowing operational overrides.
8. **Standard repository anatomy.** `[L1: docs-lint]`
   - Every SKU repository must carry:
     - `pom.xml`
     - `composition.json`
     - `Dockerfile`
     - `LICENSE` (Exeris Commercial License)
     - `SECURITY.md`
     - `CONTRIBUTING.md`
     - `README.md` (conforming to `readme-skeleton.md`)
     - `AGENTS.md` (conforming to `agents-md-schema.md`)
     - `CLAUDE.md`

---

## Canonical Layout

```
exeris-sku-<name>/
├── .github/
│   └── workflows/
│       ├── build.yml                 # calls .guardrails reusable workflows
│       └── guardrails.yml
├── docs/
│   └── adr/                          # ADR link stubs
├── src/
│   ├── main/
│   │   ├── java/eu/exeris/sku/<shortname>/
│   │   │   ├── <Name>SkuApplication.java     # Runnable entrypoint
│   │   │   ├── <Name>SkuServer.java          # Conductor & Kernel bootstrap
│   │   │   └── handler/                      # Handlers / generated endpoints
│   │   └── resources/
│   │       └── composition.json              # Canonical composition manifest
│   └── test/
│       └── java/eu/exeris/sku/<shortname>/
│           ├── <Name>SkuTest.java            # Manifest consistency & startup test
│           └── <Name>SkuE2EIT.java           # End-to-end integration test
├── AGENTS.md
├── CLAUDE.md
├── composition.json                          # Authored manifest at repo root
├── CONTRIBUTING.md
├── Dockerfile
├── LICENSE
├── pom.xml
├── README.md
└── SECURITY.md
```

---

## Filter questions

Before publishing an SKU repository or creating a release tag:

1. Is `composition.json` present at the repository root and does it pass `CompositionStampAssertion.assertConsistent(...)` in tests?
2. Does the SKU execute 100% kernel-direct without any Spring runtime dependencies in the data plane?
3. Are all composed capabilities listed in `composition.json` genuine `@CapabilityModule` implementations matching the inventory in HLA §3.3?
4. Is the manifest driver-swap transparent (no references to concrete driver implementations like `io_uring` or `NIO`)?
5. Has a workload-profiling pass established the SKU's default JVM settings, are they recorded in `README.md` with a report path and a figure state, and are they baked into the `Dockerfile` entrypoint?
6. Are the diagnostics endpoints (`/health`, `/actuator/allocations`) wired and functional?
7. Does the repository include a multi-stage `Dockerfile` targeting JDK 25?
8. Are `AGENTS.md`, `CLAUDE.md`, and `README.md` present and compliant with repository hygiene standards?
