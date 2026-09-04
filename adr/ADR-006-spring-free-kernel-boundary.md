---
title: 'ADR-006: Spring-Free Kernel Boundary ("The Wall")'
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
slug: adr/ADR-006
---

# ADR-006: Spring-Free Kernel Boundary ("The Wall")
<!-- VERIFY(sweep-2026-09): last-verified is 2026-09-04 because every claim on this page was checked against source in this sweep, but several of them do NOT match the code and are left unrepaired pending maintainer approval (see the markers below). docs-style-guide defines last-verified as 'the date a human last confirmed this page matches the code'. Rendered Markdown hides these comments, so a reader sees only the recent date. Maintainer should decide whether the date holds or the sweep brief's rule needs the qualification -->

| Attribute       | Value                                                                                                         |
|:----------------|:--------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED** (drafted 2026-05-08; decision date 2026-02-22)                                                   |
| **Deciders**    | Arkadiusz Przychocki                                                                                          |
| **Date**        | 2026-02-22                                                                                                    |
| **Scope**       | cross-repo (binds `exeris-kernel`, `exeris-kernel-enterprise`, `exeris-sdk`, `exeris-spring-runtime`)         |
| **Owning Repo** | `exeris-docs` (cross-repo platform copy; the seam this ADR governs is implemented in `exeris-spring-runtime`) |
| **Driven By**   | Abandonment of the original Spring-as-platform model; ADR-007 update (2026-02-22) clarified runtime ownership |
| **Compliance**  | [Strategic Pillar: Clean IP & Detachment](../../exeris-kernel/docs/architecture.md), `module-boundaries.md`   |

<!-- VERIFY(sweep-2026-09): ADR-006 Scope binds exeris-kernel, exeris-kernel-enterprise, exeris-sdk and exeris-spring-runtime, but only exeris-kernel carries docs/adr/ADR-006.link.md and adr-index.md:118 lists only that repo. adr-conventions rule 5 requires a stub in every consuming repo before a cross-repo ADR is ACCEPTED. Add three stubs or narrow the declared Scope -->

## Context and Problem Statement

The original Exeris platform was structured around Spring as both the application framework AND the runtime owner — Spring Boot bootstrapped the JVM, Spring DI wired every collaborator, Spring Web (Tomcat/Jetty/Reactor) owned the HTTP request lifecycle, and Spring Data owned persistence.

That model was abandoned. Three forces drove the abandonment:

1. **No Waste Compute is incompatible with Spring's hot-path overhead.** Spring Web's request DTO churn, reactive bridge wrapping, and reflection-heavy ApplicationContext lookups are the exact costs the platform exists to eliminate.
2. **Open-core distribution requires a Spring-free kernel.** The kernel ships as `exeris-kernel-spi`, `exeris-kernel-core`, `exeris-kernel-community`, and `exeris-kernel-enterprise`. None of these can transitively pull `org.springframework:*` into a customer's classpath — that would inflate jar sizes by ~30 MB and lock the customer into Spring's release cadence.
   <!-- VERIFY(sweep-2026-09): the '~30 MB' jar-inflation figure has no report path and no figure state; it appears nowhere else in the corpus and is not in exeris-benchmarks CLAIMS.md. Maintainer decision under rule 8: gate it or drop it -->
3. **Code Detachment (the IP business model — see ADR-001 and the underlying commercial policy) requires a kernel that is not Spring-shaped.** Customers must be able to "take the code" without inheriting a framework dependency they didn't choose.

Without a hard boundary, even well-intentioned PRs leak Spring concerns into the kernel: a `@Service` annotation here, a `BeanFactoryAware` reference there, and within months the Spring-free goal is unreachable. The boundary needs an architectural rule, not just a coding convention.

## 🏁 The Decision

**Spring is the application framework. Exeris is the runtime owner. The kernel ships zero Spring imports.**

This is The Wall, expressed as architectural law.

**Concrete obligations:**

1. **Zero Spring on the kernel side.** No `org.springframework.*` import in `exeris-kernel-spi`, `exeris-kernel-core`, `exeris-kernel-community`, or `exeris-kernel-enterprise`. No `@Component`, no `@Autowired`, no `BeanPostProcessor`, no `ApplicationContext` lookups. No Spring on the kernel-tck classpath either.
2. **Provider discovery via `ServiceLoader`, never IoC.** The kernel discovers `PersistenceProvider`, `TransportProvider`, `MemoryProvider`, `GraphProvider`, `SecurityProvider`, `ConfigProvider`, `TelemetrySink`, etc. via `META-INF/services`. There is no Spring-aware fallback path.
   <!-- VERIFY(sweep-2026-09): obligation 2 lists TelemetrySink among the ServiceLoader-discovered providers. The SPI service files under META-INF/services name telemetry.TelemetryProvider, not TelemetrySink; sinks are constructed by the discovered provider via TelemetryProvider.createSinks(TelemetryConfig) and are not themselves service-loaded. The obligation itself (ServiceLoader, never IoC) holds. Rule 5 forbids editing the obligation in place; maintainer must approve a dated ## Amendments entry -->
3. **Bootstrap is owned by Exeris.** `KernelBootstrap.bootstrap()` runs the DAG (`Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow} → READY`). Spring's `refresh()` invokes Exeris bootstrap via `ExerisRuntimeLifecycle` (a `SmartLifecycle`), not the other way around.
   <!-- VERIFY(sweep-2026-09): obligation 3 restates a boot sequence that does not exist in exeris-kernel-core on either main or development/0.12.0 — there is no KernelBootstrap.bootstrap() (the entry point is boot(Runnable)), no Exceptions subsystem, and Config is resolved via ServiceLoader<ConfigProvider> before the orchestrator rather than being a DAG node; ordering is BootstrapPhase FOUNDATION/SERVICES/RUNTIME, each phase run in dependency-safe rounds on the calling thread since v0.11 (ADR-066). Rule 5 forbids editing the obligation in place; maintainer must approve a dated ## Amendments entry. Canonical narrative: exeris-kernel/docs/subsystems/bootstrap.md -->
   <!-- VERIFY(sweep-2026-09): before amending obligation 3, note the intended source is itself inconsistent — BootstrapPhase javadoc (identical on main and development/0.12.0) puts crypto and telemetry in FOUNDATION, while CommunityCryptoSubsystem.phase() returns SERVICES; and bootstrap.md's Boot DAG diagram omits Security, Scheduling, Storage and WebSocket, which the Community driver does register. The amendment should name the phase enum and the entry point and defer membership to bootstrap.md, not restate a member list -->
4. **The bridge lives in `exeris-spring-runtime`.** Every Spring-side type (`HttpServletRequest`, `DataSource`, `PlatformTransactionManager`, `Environment`) that needs to interoperate with the kernel does so through an explicitly-named adapter in one of: `exeris-spring-boot-autoconfigure`, `exeris-spring-runtime-web`, `exeris-spring-runtime-tx`, `exeris-spring-runtime-data`, `exeris-spring-runtime-actuator`. None of these adapters add Spring types to the kernel — they translate.
   <!-- VERIFY(sweep-2026-09): obligation 4 lists HttpServletRequest among bridged Spring-side types. No such adapter exists in exeris-spring-runtime today (no jakarta.servlet reference in any src/main), but ADR-011:49 reserves a narrow *.compat.servlet.* bridge for it in Compatibility Mode and exeris-spring-runtime-web/pom.xml:34 says Phase 2 will add one, while docs/phases/phase-2-spring-compat.md:137 says it is banned in all modes. Three sources, three positions. Maintainer must reconcile ADR-006 and ADR-011 together; do not amend ADR-006 alone -->
5. **Wall enforcement is automated.** The boundary is verified by:
   - `WallIntegrityTest` (ArchUnit-style) in `exeris-spring-boot-autoconfigure` — asserts no `org.springframework.*` reaches `eu.exeris.kernel.spi.*` or `eu.exeris.kernel.core.*`.
   - `PureModeClasspathGuardTest` per spring-runtime module — asserts banned dependencies (Tomcat, Jetty, Undertow, Netty, Reactor, jakarta.servlet, HikariCP) are absent from the runtime classpath in pure mode (per ADR-011).
     <!-- VERIFY(sweep-2026-09): obligation 5 attributes the Tomcat/Jetty/Undertow/HikariCP bans to PureModeClasspathGuardTest, which asserts none of them (it guards servlet API, Netty, Reactor, WebFlux server abstractions and DispatcherServlet as ArchUnit source imports across 8 modules). The bans are real but carried by WallIntegrityTest:97, ExerisBootstrapIntegrationTest:135, ModuleBoundaryTest:68 and DataModuleBoundaryTest:92. The same misattribution originates in ADR-011:41, so closing it in ADR-006 alone leaves the upstream record wrong. Maintainer must approve a coordinated ## Amendments entry -->
   - Build-time: kernel modules' POMs declare zero Spring dependencies; CI fails if a transitive Spring import sneaks in.
6. **Bidirectional rule.** Just as Spring may not enter the kernel, the kernel may not assume Spring. Kernel APIs are not designed around `BeanFactory`, `ApplicationContext`, `@Conditional*`, or any Spring lifecycle hook. `KernelBootstrap` works with or without Spring on the classpath.

## Consequences

### ✅ Positive Outcomes

- **[+] Open-core distribution viable.** Kernel jars ship without Spring. Customers using Quarkus, Micronaut, plain `main()`, or no framework at all consume `exeris-kernel-*` directly.
- **[+] Code Detachment legally clean.** When a Code Detachment event triggers under the IP-detachment commercial policy, the kernel source has no framework lock-in; customers inherit pure runtime code, not a framework adapter.
- **[+] Performance contract intact.** Spring's request-path overhead never enters the kernel hot path. The kernel's < 5 µs PAQS shed decision and zero-allocation TLS path are protected from accidental Spring-DTO wrapping.
  <!-- VERIFY(sweep-2026-09): the '< 5 microsecond PAQS shed decision' figure is an Enterprise SLO whose only source is exeris-kernel-enterprise/docs/performance-contract.md:209, which states it as a less-than-or-equal bound and records at :218-226 that the PAQS scheduler is not yet wired to the pool acquire path. It is absent from the open-core performance contract, from the ADR-020 docs-open-core mirror, and from CLAIMS.md. A public ADR must not assert it. Maintainer decision under rule 8 -->
- **[+] Compile-time enforcement.** "Did this PR violate the Wall?" is a build outcome, not a review judgment call.

### ⚠️ Trade-offs

- **[-] Spring users get an adapter layer.** Application code on Spring talks to `exeris-spring-runtime-*` modules, not directly to kernel SPI. The adapter cost is real (mostly construction-time, not request-time) and is documented in `exeris-spring-runtime/docs/architecture/kernel-integration-seams.md`.
- **[-] Some Spring conveniences require careful bridging.** `@Transactional` semantics translate via `ExerisPlatformTransactionManager`. `SecurityContextHolder` (a `ThreadLocal`-bound API) is bridgeable only in Compatibility Mode (per ADR-011); pure mode uses ScopedValue-based context.
- **[-] Operators must understand the split.** "Why does my `@Component` not show up in JFR's bootstrap event?" — because Spring-side and Exeris-side bootstrap are distinct phases. Onboarding docs must address this.
  <!-- VERIFY(sweep-2026-09): 'Onboarding docs must address this' (Consequences, trade-off 3) has been open since 2026-02-22 and no page under exeris-spring-runtime/docs or exeris-kernel/docs explains the Spring-side vs Exeris-side bootstrap phase split. Discharge it beside docs/architecture/kernel-integration-seams.md, or move it to docs/roadmap-1.0-trl9.md (this repo has no ROADMAP.md) -->

### 📋 What is NOT changed

- This ADR does not require applications to drop Spring. Most Exeris applications continue to use Spring as their application framework — the platform supports that explicitly.
- This ADR does not preclude other framework adapters. A future `exeris-quarkus-runtime` or `exeris-micronaut-runtime` would follow the same pattern.

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

<!-- VERIFY(sweep-2026-09): opening a ## Amendments section on this ADR is not a self-contained edit — ADR-085 §25 and adr-conventions rule 7 require the adr-index.md status cell to change in the same PR to 'accepted (2026-02-22, upd. YYYY-MM-DD)'. Rule 8 reserves adr-index.md row edits for the maintainer, so the amendment and the registry edit must land together, not in this sweep -->
