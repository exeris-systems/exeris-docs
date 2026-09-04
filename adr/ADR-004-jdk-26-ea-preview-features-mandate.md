---
title: "ADR-004: JDK 26 EA + Preview Features Mandate"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-05-11
slug: adr/ADR-004
---

# ADR-004: JDK 26 EA + Preview Features Mandate

| Attribute       | Value                                                                                                  |
|:----------------|:---------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED** (formal record authored 2026-05-08 — see retrospective note below)                          |
| **Deciders**    | Arkadiusz Przychocki                                                                                     |
| **Date**        | 2025-12-26                                                                                               |
| **Scope**       | platform (binds every Exeris repository — kernel, sdk, spring-runtime, tooling, enterprise)              |
| **Owning Repo** | `exeris-docs`                                                                                            |
| **Driven By**   | No-Waste Compute thesis; JDK 26 EA availability (work started 2025-09-16 when EA dropped)                |
| **Compliance**  | [Strategic Pillar: No-Waste Compute](../../exeris-kernel/docs/whitepaper.md)                             |

> **Retrospective record.** The decision was made on 2025-12-26 and operationalized across all repositories well before this ADR was written. The formal record was authored on 2026-05-08 as part of the ADR registry bootstrap. The Date field reflects the actual decision date, not the authoring date.

<!-- VERIFY(sweep-2026-09): the Decision below no longer describes the default distributable line. exeris-kernel/pom.xml:113, exeris-kernel/exeris-kernel-build-config/pom.xml:24, exeris-sdk/pom.xml:95, exeris-tooling/pom.xml:112, exeris-platform/pom.xml:120 and exeris-caps-cors-policy/pom.xml:42 all set <maven.compiler.release>25</maven.compiler.release>, and no pom.xml in kernel, sdk, tooling, platform or caps passes --enable-preview. The mandate still holds where it was never lifted: exeris-kernel-enterprise/pom.xml:33 and :35, exeris-spring-runtime/pom.xml:51, exeris-enterprise-observability/pom.xml:18, and the eu.exeris.preview:* line. Driven by kernel ADR-066 (accepted 2026-08-08, shipped 0.11.0), sdk ADR-069 (2026-08-12) and spring-runtime ADR-068 (2026-08-08) - none of which records a supersession: ADR-066's header reads "Supersedes / amends: none". Founder must rule: superseded by ADR-066, or ACCEPTED with a dated "## Amendments" entry rescoping the mandate to the preview line - and the adr-index.md:25 row, still "accepted (2025-12-26)", moves in the same change. -->

## Context and Problem Statement

The Exeris platform's "No Waste Compute" thesis depends on JVM features that crystallised across JDK 21–26:

- **Virtual Threads** went stable in JDK 21 — but the `synchronized` carrier-pinning fix did not land until **JEP 491 (JDK 24)**. Before that fix, any `synchronized` method on a VT-mounted carrier would pin the carrier thread, defeating the entire scalability model.
- **Foreign Function & Memory API (Panama FFM)** went stable in **JEP 454 (JDK 22)**. This is the load-bearing API for enterprise tier features: `io_uring` ring management, QUIC OpenSSL BIO pairs, off-heap slab pools, and zero-copy `MemorySegment` paths.
- **ScopedValue (JEP 506)** matured into a real `ThreadLocal` replacement — required for context propagation under VTs without the GC pressure and pinning hazards of TL.
- **StructuredTaskScope (JEP 525)** matured into a real `ExecutorService` replacement for orchestration — required for the structured-concurrency discipline mandated across kernel hot paths.
  <!-- VERIFY(sweep-2026-09): StructuredTaskScope (JEP 525) is still a preview API on JDK 26 GA - javac on build 26+35-2893 rejects `import java.util.concurrent.StructuredTaskScope;` with "StructuredTaskScope is a preview API and is disabled by default". The Context bullet above is consistent with this ADR's own --enable-preview mandate and is not withdrawn here; what changed is downstream. ADR-066 moved StructuredTaskScope off the default critical path onto the `preview` branch, substituting a Core-owned fork/join/cancel layer over virtual threads + ScopedValue (both GA), and exeris-kernel/CLAUDE.md §B scopes "Prefer StructuredTaskScope" to the 1.0-preview artefact. -->
- **Valhalla previews** continue to evolve toward value classes (JEP 401 family). Records and immutable final classes designed today against current preview semantics will scalarise via C2 escape analysis when Valhalla GAs.

A platform pinned at JDK 21 LTS (or even JDK 25 LTS) cannot honour these contracts. JDK 21 lacks the pinning fix, FFM stability, and mature ScopedValue/StructuredTaskScope. JDK 25 lacks JEP 491. The platform's value proposition is incompatible with LTS.

<!-- VERIFY(sweep-2026-09): the Context clause "JDK 25 lacks JEP 491" contradicts the Virtual Threads bullet in this same ADR's Context, which places JEP 491 in JDK 24. ADR-066 then measured the full kernel reactor green at --release 25 on JDK 25 - "No JDK-26-only API is used anywhere in the tree; the 26 in the build was never load-bearing". Correcting a Context premise changes the record, so this needs a dated "## Amendments" entry from the founder, not an in-place edit. -->

## 🏁 The Decision

**Mandate JDK 26 (EA → GA when released) with `--enable-preview` across every Exeris repository.** No backport to LTS.

**Concrete obligations:**

1. **Compiler target.** Every `pom.xml` sets `<maven.compiler.release>26</maven.compiler.release>` and passes `--enable-preview` to both `maven-compiler-plugin` and `maven-surefire-plugin`.
2. **Test JVM args.** Test runners use `-XX:+UnlockExperimentalVMOptions -XX:+UseZGC --enable-preview` (consult repo-specific `pom.xml` for additional flags).
3. **Operator deployment.** Production deployments require JDK 26 (EA acceptable until GA). There is no "fallback to 21 LTS" path.
4. **Preview-feature drift.** Preview features may shift between EA versions. Code MUST track the latest EA semantics, not pin to an older preview shape. CI runs against the latest stable EA build.
   <!-- VERIFY(sweep-2026-09): obligation 3's "EA acceptable until GA" has expired on its own terms - JDK 26 reached GA on 2026-03-17 (java -version here: build 26+35-2893) - and the shipped operator floor is stated differently: exeris-kernel/docs/support-matrix.md gives "Java 25 LTS or newer ... --enable-preview is not required (ADR-066)", exeris-kernel/README.md §Requirements "JDK 25 LTS or newer". Obligation 4's "CI runs against the latest stable EA build" is likewise dead on the default line: exeris-kernel/.github/workflows/maven.yml:38 pins JDK_VER: "25.0.4", a GA LTS, used at :80/:376/:454/:524/:586/:652/:748/:894/:982; exeris-sdk/.github/workflows/release.yml:146 and exeris-platform/.github/workflows/publish.yml:119 pin '25'. Only exeris-spring-runtime's workflows still pin '26'. -->
5. **Enforcement.** Build fails if `release` is set below 26; `PureModeClasspathGuardTest`-style guards check the runtime JVM major version on bootstrap.

<!-- VERIFY(sweep-2026-09): neither enforcement clause in obligation 5 describes a live gate, and the first describes the inverse of one. No build fails when `release` is below 26 - the only build-time JDK floor in the ecosystem is exeris-tooling/pom.xml:188 <requireJavaVersion>[25,)</requireJavaVersion>. What is enforced is a ceiling: exeris-sdk/exeris-sdk-annotations/src/test/java/eu/exeris/sdk/annotation/ClassFileBaselineTest.java:35 sets MAX_MAJOR = 69 (JDK 25) and :46 asserts isLessThanOrEqualTo, and exeris-kernel/.github/workflows/maven.yml:127 runs tools/preview-bytecode-scan/preview-bytecode-scan.sh --expect-major 69 (script default EXPECT_MAJOR=69 at :24). PureModeClasspathGuardTest exists in eight exeris-spring-runtime modules (-tx, -web, -flow, -actuator, -data, -events, -graph, exeris-spring-boot-autoconfigure) and is an ArchUnit package-dependency guard over jakarta.servlet../javax.servlet../io.netty../reactor../WebFlux server packages; it reads no JVM version. No main source under ~/exeris-systems/ performs a bootstrap JVM-major check - the two Runtime.version() uses, exeris-kernel-core/.../bootstrap/jfr/KernelStartEvent.java:81 and exeris-kernel-enterprise/.../telemetry/CrashBufferBinder.java:166, both write a telemetry field. Founder to decide whether this obligation is restated by amendment or retired with the ADR's status. -->

**History note:** JDK 26 EA work in this codebase started on **2025-09-16** (the day the EA build dropped). The platform-level mandate was formalised on **2025-12-26**. The 3-month gap covers the period during which compatibility with JDK 25 LTS was still being evaluated and rejected.

## Consequences

### ✅ Positive Outcomes

- **[+] Coherent runtime model.** ScopedValue + StructuredTaskScope + FFM + VTs (with pinning fix) compose into a single design philosophy. No subsystem has to fall back to legacy primitives.
- **[+] Zero pin-pollution.** JEP 491 closes the `synchronized` pinning gap. Slab-pool ABA-safety blocks (per ADR-007 amendment) are now legal without carrier pinning.
- **[+] Native-interop without `Unsafe`.** Panama FFM replaces every legacy `sun.misc.Unsafe` use case in the kernel and enterprise tiers.
- **[+] Valhalla-ready.** Records and immutable final classes designed today scalarise under C2 EA today and become true value types when Valhalla GAs — no migration required.

<!-- VERIFY(sweep-2026-09): the "no migration required" clause needs a founder ruling; the scalarisation clause beside it stands (exeris-kernel/docs/whitepaper.md:40-42). On JDK 26 GA the mandated JDK carries no Valhalla preview to design against - `value class P { int x; P(int x){this.x=x;} }` fails to compile on build 26+35-2893 both bare and under `javac --enable-preview --release 26`, and exeris-kernel/CLAUDE.md §B places JEP 401 and JEP 539 in JDK 28 preview. The migration is small but real and priced: whitepaper.md:46-47 calls it "a single-keyword addition (value record) per data carrier, with no architectural change required", and spring-runtime ADR-068 §"The cost: a deliberate per-line source overlay" rules that "value record and record are different source" and accepts a guarded carrier-only overlay. -->

### ⚠️ Trade-offs

- **[-] Operator JDK requirement.** Every Exeris deployment requires JDK 26+. Operators on RHEL/Ubuntu LTS with vendor-blessed JDK 21 cannot run Exeris without upgrading the JVM. This is a deliberate trade — the platform's performance contract is incompatible with LTS.
- **[-] Preview-feature volatility.** Preview features may rename, change signatures, or be removed across EA builds. The repos accept the maintenance cost of tracking EA semantics in exchange for early access to the runtime model.
- **[-] Tooling lag.** Some IDEs, static analysers, and bytecode tools lag behind preview features. Workarounds may require manual configuration.

### 📋 What is NOT in scope

- Backwards-compatibility shims for JDK 21 / 25. None are provided. Code that targets older JDKs is rejected.
- Multi-release JARs. The platform ships JDK 26 bytecode only; no `META-INF/versions/21/` paths.

## Cross-references

- ADR-007 (Next-Gen Runtime Architecture) — depends on this ADR's preview-features mandate to be possible.
- ADR-005 (JFR-First Telemetry) — depends on `@StackTrace(false)` semantics stable since JDK 21+ and refined in JDK 26.
- `exeris-kernel/CLAUDE.md` §"Hard Constraints" — operationalises the bans that this ADR's feature mandate makes possible.

## Engineering Protocol

Once this decision is ACCEPTED, every repo's `pom.xml` must reflect `<maven.compiler.release>26</maven.compiler.release>` and the `--enable-preview` flags. Existing repos already comply; this ADR codifies the existing reality.
