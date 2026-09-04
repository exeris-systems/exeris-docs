---
title: 'ADR-006: Spring-Free Kernel Boundary ("The Wall")'
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-05
slug: adr/ADR-006
---

# ADR-006: Spring-Free Kernel Boundary ("The Wall")

| Attribute       | Value                                                                                                         |
|:----------------|:--------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED** (drafted 2026-05-08; decision date 2026-02-22)                                                   |
| **Deciders**    | Arkadiusz Przychocki                                                                                          |
| **Date**        | 2026-02-22                                                                                                    |
| **Scope**       | cross-repo (binds `exeris-kernel`, `exeris-kernel-enterprise`, `exeris-sdk`, `exeris-spring-runtime`)         |
| **Owning Repo** | `exeris-docs` (cross-repo platform copy; the seam this ADR governs is implemented in `exeris-spring-runtime`) |
| **Driven By**   | Abandonment of the original Spring-as-platform model; ADR-007 update (2026-02-22) clarified runtime ownership |
| **Compliance**  | [Strategic Pillar: Clean IP & Detachment](../../exeris-kernel/docs/architecture.md), `module-boundaries.md`   |


## Context and Problem Statement

The original Exeris platform was structured around Spring as both the application framework AND the runtime owner — Spring Boot bootstrapped the JVM, Spring DI wired every collaborator, Spring Web (Tomcat/Jetty/Reactor) owned the HTTP request lifecycle, and Spring Data owned persistence.

That model was abandoned. Three forces drove the abandonment:

1. **No Waste Compute is incompatible with Spring's hot-path overhead.** Spring Web's request DTO churn, reactive bridge wrapping, and reflection-heavy ApplicationContext lookups are the exact costs the platform exists to eliminate.
2. **Open-core distribution requires a Spring-free kernel.** The kernel ships as `exeris-kernel-spi`, `exeris-kernel-core`, `exeris-kernel-community`, and `exeris-kernel-enterprise`. None of these can transitively pull `org.springframework:*` into a customer's classpath — that would inflate jar sizes by ~30 MB and lock the customer into Spring's release cadence.
3. **Code Detachment (the IP business model — see ADR-001 and the underlying commercial policy) requires a kernel that is not Spring-shaped.** Customers must be able to "take the code" without inheriting a framework dependency they didn't choose.

Without a hard boundary, even well-intentioned PRs leak Spring concerns into the kernel: a `@Service` annotation here, a `BeanFactoryAware` reference there, and within months the Spring-free goal is unreachable. The boundary needs an architectural rule, not just a coding convention.

## 🏁 The Decision

**Spring is the application framework. Exeris is the runtime owner. The kernel ships zero Spring imports.**

This is The Wall, expressed as architectural law.

**Concrete obligations:**

1. **Zero Spring on the kernel side.** No `org.springframework.*` import in `exeris-kernel-spi`, `exeris-kernel-core`, `exeris-kernel-community`, or `exeris-kernel-enterprise`. No `@Component`, no `@Autowired`, no `BeanPostProcessor`, no `ApplicationContext` lookups. No Spring on the kernel-tck classpath either.
2. **Provider discovery via `ServiceLoader`, never IoC.** The kernel discovers `PersistenceProvider`, `TransportProvider`, `MemoryProvider`, `GraphProvider`, `SecurityProvider`, `ConfigProvider`, `TelemetrySink`, etc. via `META-INF/services`. There is no Spring-aware fallback path.
3. **Bootstrap is owned by Exeris.** `KernelBootstrap.bootstrap()` runs the DAG (`Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow} → READY`). Spring's `refresh()` invokes Exeris bootstrap via `ExerisRuntimeLifecycle` (a `SmartLifecycle`), not the other way around.
4. **The bridge lives in `exeris-spring-runtime`.** Every Spring-side type (`HttpServletRequest`, `DataSource`, `PlatformTransactionManager`, `Environment`) that needs to interoperate with the kernel does so through an explicitly-named adapter in one of: `exeris-spring-boot-autoconfigure`, `exeris-spring-runtime-web`, `exeris-spring-runtime-tx`, `exeris-spring-runtime-data`, `exeris-spring-runtime-actuator`. None of these adapters add Spring types to the kernel — they translate.
5. **Wall enforcement is automated.** The boundary is verified by:
   - `WallIntegrityTest` (ArchUnit-style) in `exeris-spring-boot-autoconfigure` — asserts no `org.springframework.*` reaches `eu.exeris.kernel.spi.*` or `eu.exeris.kernel.core.*`.
   - `PureModeClasspathGuardTest` per spring-runtime module — asserts banned dependencies (Tomcat, Jetty, Undertow, Netty, Reactor, jakarta.servlet, HikariCP) are absent from the runtime classpath in pure mode (per ADR-011).
   - Build-time: kernel modules' POMs declare zero Spring dependencies; CI fails if a transitive Spring import sneaks in.
6. **Bidirectional rule.** Just as Spring may not enter the kernel, the kernel may not assume Spring. Kernel APIs are not designed around `BeanFactory`, `ApplicationContext`, `@Conditional*`, or any Spring lifecycle hook. `KernelBootstrap` works with or without Spring on the classpath.

## Consequences

### ✅ Positive Outcomes

- **[+] Open-core distribution viable.** Kernel jars ship without Spring. Customers using Quarkus, Micronaut, plain `main()`, or no framework at all consume `exeris-kernel-*` directly.
- **[+] Code Detachment legally clean.** When a Code Detachment event triggers under the IP-detachment commercial policy, the kernel source has no framework lock-in; customers inherit pure runtime code, not a framework adapter.
- **[+] Performance contract intact.** Spring's request-path overhead never enters the kernel hot path. The kernel's < 5 µs PAQS shed decision and zero-allocation TLS path are protected from accidental Spring-DTO wrapping.
- **[+] Compile-time enforcement.** "Did this PR violate the Wall?" is a build outcome, not a review judgment call.

### ⚠️ Trade-offs

- **[-] Spring users get an adapter layer.** Application code on Spring talks to `exeris-spring-runtime-*` modules, not directly to kernel SPI. The adapter cost is real (mostly construction-time, not request-time) and is documented in `exeris-spring-runtime/docs/architecture/kernel-integration-seams.md`.
- **[-] Some Spring conveniences require careful bridging.** `@Transactional` semantics translate via `ExerisPlatformTransactionManager`. `SecurityContextHolder` (a `ThreadLocal`-bound API) is bridgeable only in Compatibility Mode (per ADR-011); pure mode uses ScopedValue-based context.
- **[-] Operators must understand the split.** "Why does my `@Component` not show up in JFR's bootstrap event?" — because Spring-side and Exeris-side bootstrap are distinct phases. Onboarding docs must address this.

### 📋 What is NOT changed

- This ADR does not require applications to drop Spring. Most Exeris applications continue to use Spring as their application framework — the platform supports that explicitly.
- This ADR does not preclude other framework adapters. A future `exeris-quarkus-runtime` or `exeris-micronaut-runtime` would follow the same pattern.

## Amendments

Each entry records a claim the code contradicts. The obligations above are not rewritten; read them
together with the entry that corrects them. All six were verified against the working tree on
2026-09-05. (PR #91)

- **2026-09-05 — Obligation 2 names a service that is not service-loaded.** The obligation lists
  `TelemetrySink` among the `ServiceLoader`-discovered providers. No `META-INF/services` file for it
  exists anywhere in `exeris-kernel`; the telemetry service files are
  `eu.exeris.kernel.spi.telemetry.TelemetryProvider` and `…KernelTelemetryProvider`. Sinks are
  constructed by the discovered provider, not discovered themselves. Read the list as
  `PersistenceProvider, TransportProvider, MemoryProvider, GraphProvider, SecurityProvider,
  ConfigProvider, TelemetryProvider`.

- **2026-09-05 — Obligation 3 describes an entry point and a boot order that do not exist.**
  `KernelBootstrap` has no `bootstrap()` method — the string appears zero times in the class — and the
  entry point is `public void boot(Runnable kernelMain)` at
  `exeris-kernel-core/…/bootstrap/KernelBootstrap.java:133`. There is no six-node
  `Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow}` DAG
  and no `Exceptions` subsystem: ordering is the three-phase `BootstrapPhase` enum — `FOUNDATION`,
  `SERVICES`, `RUNTIME` — each phase resolved in dependency-safe rounds. Which subsystem sits in which
  phase is deliberately not restated here: `BootstrapPhase`'s javadoc and
  `exeris-kernel/docs/subsystems/bootstrap.md` disagree with each other, and reconciling them belongs
  to the kernel, not to this record.

- **2026-09-05 — Obligation 4's `HttpServletRequest` example is contested, not settled.** Three
  sources in `exeris-spring-runtime` point two ways. `ADR-011:49` reserves a "Narrow
  `*.compat.servlet.*` bridge for legacy `HttpServletRequest`";
  `exeris-spring-runtime-web/pom.xml:34` says "Compatibility mode (Phase 2) will add an opt-in MVC
  dispatch bridge"; and `docs/phases/phase-2-spring-compat.md:137` marks `HttpServletRequest` and
  `HttpServletResponse` "Banned in all modes (`jakarta.servlet.*` not on classpath)". No such adapter
  exists today. The example is withdrawn from this obligation until that repository settles its own
  contradiction; the rest of obligation 4 stands — `DataSource`, `PlatformTransactionManager` and
  `Environment` are bridged through the named adapter modules.

- **2026-09-05 — Obligation 5 credits the wrong test with the runtime bans.**
  `PureModeClasspathGuardTest` is real and ships across the runtime's modules, but its assertions are
  the servlet API, Netty and Reactor, WebFlux server abstractions, and `DispatcherServlet` — not
  Tomcat, Jetty, Undertow or HikariCP. Those are carried by `WallIntegrityTest`,
  `ExerisBootstrapIntegrationTest`, `ModuleBoundaryTest`, `DataModuleBoundaryTest` and
  `ExerisDataAutoConfigurationTest`. The Wall is enforced more broadly than the obligation says, by
  five classes rather than one; only the attribution was wrong.

- **2026-09-05 — The "~30 MB" jar figure is overstated; the "< 5 µs" figure is a contract target,
  not an unsourced claim.** Two figures in Consequences were checked directly.

  The Context clause says a transitive `org.springframework:*` pull "would inflate jar sizes by
  ~30 MB". Measured 2026-09-05 against the local Maven repository, the Spring Framework set —
  `spring-core`, `spring-beans`, `spring-context`, `spring-aop`, `spring-web`, `spring-webmvc`,
  `spring-expression`, `spring-tx`, `spring-jdbc`, `spring-orm`, `spring-jcl`, newest version of each —
  totals **9.02 MB**. Roughly 30 MB is reachable only with Spring Boot, its starters and their
  transitive tree (Tomcat, Jackson, Micrometer and the rest), which is not what this clause describes.
  Read the figure as the order of magnitude of a Boot application's dependency tree, not of the
  framework jars the clause names. The argument does not depend on the number: the objection to
  pulling Spring into the kernel is the release-cadence lock-in stated in the same sentence.

  The "< 5 µs PAQS shed decision" is **not** an Enterprise-private assertion, which an earlier draft of
  this entry claimed. It is a public, TCK-enforced design limit: `exeris-kernel/docs/whitepaper.md:156`
  and `exeris-kernel/docs/modules/05-tck.md:71` both state `≤ 5 µs` with "Nanosecond timer in TCK" as
  the enforcement, for Community and Enterprise alike; the Enterprise performance contract repeats it
  as still binding rather than originating it. It is a contract target rather than a measurement —
  `exeris-kernel-enterprise/docs/performance-contract.md:225` records that PAQS routing is not yet
  wired, so nothing has been measured against it — and this ADR should write it `≤ 5 µs`, matching the
  kernel.

- **2026-09-05 — The declared Scope is not backed by stubs.** Scope binds `exeris-kernel`,
  `exeris-kernel-enterprise`, `exeris-sdk` and `exeris-spring-runtime`, and only `exeris-kernel`
  carries `docs/adr/ADR-006.link.md`. The other three are missing. Tracked as `[DOC DEBT]`, one pull
  request per repository; `adr-conventions` rule 5 makes stub coverage an `[L2]` review obligation
  rather than a CI gate, so this does not reopen the decision.

## Cross-references

- ADR-001 (Cloud Native & Agnostic) — sets up the Code Detachment business model that this Wall protects.
- ADR-007 (Next-Gen Runtime Architecture) — defines the kernel runtime model that must remain framework-free.
- ADR-008 (Open-Core Strategy) — depends on the kernel being Spring-free for the open-core / enterprise split to work.
- ADR-010 (Host Runtime Model) — describes how Exeris owns the runtime when Spring is the application framework on top.
- ADR-011 (Pure Mode vs Compatibility Mode) — defines where ThreadLocal-based Spring features (e.g., `SecurityContextHolder`) may be bridged.
- `exeris-kernel/CLAUDE.md` — operationalises the Wall from the kernel side ("No framework DI in runtime kernel code").
- `exeris-spring-runtime/CLAUDE.md` — operationalises the Wall from the Spring-runtime side ("Spring is the application framework. Exeris is the runtime owner.").

## Engineering Protocol

Once this decision is ACCEPTED, the existing `WallIntegrityTest` and `PureModeClasspathGuardTest` suites are the canonical enforcement. PRs that disable or weaken these tests must cite this ADR and either explain why the change preserves the Wall or propose a superseding ADR.

