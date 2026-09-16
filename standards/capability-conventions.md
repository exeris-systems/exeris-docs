---
title: Capability Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-16
---

# Capability Conventions

Binding per ADR-085 §M.37. Applies to every capability repository (`exeris-caps-*`) in the Tier 2 Capability Ecosystem.

**Where this does not apply, and what it costs.** Not to the kernel and not to a SKU: the kernel's boundary is ADR-006's and a composition's is `sku-conventions.md`, and a repository that is neither is governed by the artefact-kind standards alone. Not to an internal module inside an existing capability either — the unit here is the repository, so splitting a capability to satisfy a rule about repositories is the rule being misread. The cost is real: one capability per repository buys an enforceable boundary and a separately versioned artefact, and pays for it in release coordination, because a change spanning two capabilities is then two pull requests in two repositories with a pin between them.

A capability is a self-contained, composable unit of platform functionality governed by [ADR-024](../adr/ADR-024-capability-composition-model.md) (Composition Model), [ADR-023](../adr/ADR-023-capability-licensing-taxonomy.md) (Licensing Taxonomy), [ADR-006](../adr/ADR-006-spring-free-kernel-boundary.md) / [ADR-055](https://github.com/exeris-systems/exeris-tooling/blob/main/docs/adr/ADR-055-cap-tier-wall-guard.md) (The Wall), and [ADR-015](https://github.com/exeris-systems/exeris-tooling/blob/main/docs/adr/ADR-015-codegen-emission-strategy.md) (Tooling & Codegen).

## Hard rules

1. **Repository naming and Maven coordinates.** `[L1: pom enforcer]`
   - Repository name: `exeris-caps-<kebab-name>`.
   - Coordinates: `groupId=eu.exeris.caps`, `artifactId=exeris-caps-<kebab-name>`.
   - Version follows the active ecosystem line (e.g. `0.1.0-SNAPSHOT` or release tag).
2. **Package root and boundary isolation (The Wall).** `[L1: exeris-tooling CapTierWall]`
   - The package root must be `eu.exeris.caps.<sanitized_name>`. The segment immediately following `eu.exeris.caps.` identifies the capability name owned by this build.
   - Public contract types belong strictly under `eu.exeris.caps.<sanitized_name>.api`.
   - Implementation types belong strictly under `eu.exeris.caps.<sanitized_name>.internal` (or subpackages).
   - **No sibling `internal` access:** Reading any class inside a sibling's `internal` package fails the build.
   - **No Spring, Netty, or Servlet imports:** Any direct or transitive bytecode reference to `org.springframework.*`, `io.netty.*`, or `jakarta.servlet.*` fails the build via the Class-File API scan (ADR-055).
   - **No kernel-core or driver imports:** A capability may reference only `eu.exeris.kernel.spi.*`, never kernel internals or concrete execution drivers.
3. **Module declaration class.** `[L1: exeris-processor]`
   - Exactly one class at the package root (`<Name>Module.java`) annotated with `@CapabilityModule`.
   - Services offered must be declared via `@Provides(service = ..., version = ...)`.
   - Dependencies must be declared via `@Requires(service = ..., versionRange = ..., optional = ...)`. An empty or speculative `@Requires` is forbidden because it injects artificial edges into the composition DAG and skews derived `initOrder`.
   - Version strings must adhere to empty-string normalization: `version = ""` represents an unversioned contract (hashed as `service@`), distinct from `"0.0.0"`.
4. **Lifecycle hooks contract.** `[L1: exeris-sdk-composition-lifecycle]`
   - If the capability manages stateful resources, background workers, or caches, it declares a class annotated with `@CapabilityLifecycle` implementing `CapabilityLifecycleHooks`.
   - The lifecycle class must declare a **public no-argument constructor**.
   - `initialize()` must be idempotent and must not call services of other capabilities.
   - `ready()` is the all-capabilities barrier where cross-capability interactions become safe.
   - `drain(Duration remaining)` must respect its allotted timeout budget during shutdown.
   - `terminate()` must be safe against re-entry and must **never throw checked exceptions**.
5. **Licensing and visibility consistency.** `[L2: registry check]`
   - The licence declared in `pom.xml` and `LICENSE` must match the capability's assignment in [`cap-license-registry.md`](../cap-license-registry.md) and [HLA §3.2](../high-level-architecture.md).
   - `community`: Apache-2.0 or MIT, public repository.
   - `commercial`: Exeris Commercial License (source-available), public repository.
   - `enterprise-private`: closed-source, private repository (only `exeris-caps-bot-fingerprinting`).
6. **Build configuration and two-pass protocol.** `[L1: CI / maven verify]`
   - Java baseline: JDK 25 LTS (`<maven.compiler.release>25</maven.compiler.release>`).
   - Maven baseline: 3.9+.
   - `exeris-processor` must be declared under `annotationProcessorPaths`.
   - `exeris-codegen-maven-plugin` must bind both goals: `generate` (at `generate-sources`) and `verify-capabilities` (at `process-classes`).
   - Clean checkouts require the two-pass execution protocol:
     ```bash
     mvn compile -Dexeris.codegen.skip=true   # pass 1: processor seeds metadata
     mvn verify                               # pass 2: generate manifest and scan Wall
     ```
7. **Zero runtime dependency creep.** `[L1: maven enforcer / dependency:analyze]`
   - SDK annotations (`exeris-sdk-annotations`) must be taken at `compile` scope (`@Retention(SOURCE)` ensures zero bytecode overhead at runtime).
   - Capabilities must not drag logging implementations (e.g. Logback, Log4j2) into their runtime classpath; use `System.Logger` (ADR-060).
8. **Standard repository anatomy.** `[L1: docs-lint]`
   - Every capability repository must carry:
     - `pom.xml`
     - `LICENSE`
     - `SECURITY.md`
     - `CONTRIBUTING.md`
     - `README.md` (conforming to `readme-skeleton.md`)
     - `AGENTS.md` (conforming to `agents-md-schema.md`)
     - `CLAUDE.md` (referencing Cap-Tier Wall rules and two-pass build)

---

## Canonical Layout

```
exeris-caps-<name>/
├── .github/
│   └── workflows/
│       ├── build.yml                 # calls .guardrails reusable workflows
│       └── guardrails.yml
├── docs/
│   └── adr/                          # ADR link stubs or cap-specific decisions
├── src/
│   ├── main/
│   │   └── java/eu/exeris/caps/<name>/
│   │       ├── <Name>Module.java             # @CapabilityModule declaration
│   │       ├── <Name>LifecycleHooks.java     # optional @CapabilityLifecycle
│   │       ├── api/                          # exported public interfaces
│   │       └── internal/                     # private implementation
│   └── test/
│       └── java/eu/exeris/caps/<name>/       # unit & contract tests
├── AGENTS.md
├── CLAUDE.md
├── CONTRIBUTING.md
├── LICENSE
├── pom.xml
├── README.md
└── SECURITY.md
```

---

## Filter questions

Before opening a pull request or tagging a release on any capability:

1. Did I place all public contracts in `eu.exeris.caps.<name>.api` and all implementation details in `eu.exeris.caps.<name>.internal`?
2. Did I ensure zero imports of Spring (`org.springframework.*`), Netty (`io.netty.*`), and Servlet APIs in both source and test dependencies?
3. Did I declare only `@Requires` edges that are genuinely consumed by this capability?
4. If implementing `CapabilityLifecycleHooks`, does my class have a public no-arg constructor and does `terminate()` avoid throwing checked exceptions?
5. Did I verify that `exeris-codegen-maven-plugin` has both `generate` and `verify-capabilities` goals bound in `pom.xml`?
6. Does `mvn verify` pass cleanly on a fresh build after seeding with `-Dexeris.codegen.skip=true`?
7. Does the `LICENSE` file match the assigned tier in [`cap-license-registry.md`](../cap-license-registry.md)?
8. Are `AGENTS.md`, `CLAUDE.md`, and `README.md` present and compliant with repository hygiene standards?
