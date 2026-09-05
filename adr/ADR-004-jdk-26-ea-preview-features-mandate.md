---
title: "ADR-004: JDK 26 EA + Preview Features Mandate"
type: adr
visibility: public
owning-repo: exeris-docs
status: superseded
last-verified: 2026-09-05
slug: adr/ADR-004
---

# ADR-004: JDK 26 EA + Preview Features Mandate

| Attribute       | Value                                                                                                  |
|:----------------|:---------------------------------------------------------------------------------------------------------|
| **Status**      | **SUPERSEDED** (2026-09-05 — see ADR-066, ADR-068, ADR-069; formal record authored 2026-05-08) |
| **Deciders**    | Arkadiusz Przychocki                                                                                     |
| **Date**        | 2025-12-26                                                                                               |
| **Scope**       | platform (binds every Exeris repository — kernel, sdk, spring-runtime, tooling, enterprise)              |
| **Owning Repo** | `exeris-docs`                                                                                            |
| **Driven By**   | No-Waste Compute thesis; JDK 26 EA availability (work started 2025-09-16 when EA dropped)                |
| **Compliance**  | [Strategic Pillar: No-Waste Compute](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/whitepaper.md)                             |

> **Retrospective record.** The decision was made on 2025-12-26 and operationalized across all repositories well before this ADR was written. The formal record was authored on 2026-05-08 as part of the ADR registry bootstrap. The Date field reflects the actual decision date, not the authoring date.


## Context and Problem Statement

The Exeris platform's "No Waste Compute" thesis depends on JVM features that crystallised across JDK 21–26:

- **Virtual Threads** went stable in JDK 21 — but the `synchronized` carrier-pinning fix did not land until **JEP 491 (JDK 24)**. Before that fix, any `synchronized` method on a VT-mounted carrier would pin the carrier thread, defeating the entire scalability model.
- **Foreign Function & Memory API (Panama FFM)** went stable in **JEP 454 (JDK 22)**. This is the load-bearing API for enterprise tier features: `io_uring` ring management, QUIC OpenSSL BIO pairs, off-heap slab pools, and zero-copy `MemorySegment` paths.
- **ScopedValue (JEP 506)** matured into a real `ThreadLocal` replacement — required for context propagation under VTs without the GC pressure and pinning hazards of TL.
- **StructuredTaskScope (JEP 525)** matured into a real `ExecutorService` replacement for orchestration — required for the structured-concurrency discipline mandated across kernel hot paths.
- **Valhalla previews** continue to evolve toward value classes (JEP 401 family). Records and immutable final classes designed today against current preview semantics will scalarise via C2 escape analysis when Valhalla GAs.

A platform pinned at JDK 21 LTS (or even JDK 25 LTS) cannot honour these contracts. JDK 21 lacks the pinning fix, FFM stability, and mature ScopedValue/StructuredTaskScope. JDK 25 lacks JEP 491. The platform's value proposition is incompatible with LTS.


## 🏁 The Decision

**Mandate JDK 26 (EA → GA when released) with `--enable-preview` across every Exeris repository.** No backport to LTS.

**Concrete obligations:**

1. **Compiler target.** Every `pom.xml` sets `<maven.compiler.release>26</maven.compiler.release>` and passes `--enable-preview` to both `maven-compiler-plugin` and `maven-surefire-plugin`.
2. **Test JVM args.** Test runners use `-XX:+UnlockExperimentalVMOptions -XX:+UseZGC --enable-preview` (consult repo-specific `pom.xml` for additional flags).
3. **Operator deployment.** Production deployments require JDK 26 (EA acceptable until GA). There is no "fallback to 21 LTS" path.
4. **Preview-feature drift.** Preview features may shift between EA versions. Code MUST track the latest EA semantics, not pin to an older preview shape. CI runs against the latest stable EA build.
5. **Enforcement.** Build fails if `release` is set below 26; `PureModeClasspathGuardTest`-style guards check the runtime JVM major version on bootstrap.


**History note:** JDK 26 EA work in this codebase started on **2025-09-16** (the day the EA build dropped). The platform-level mandate was formalised on **2025-12-26**. The 3-month gap covers the period during which compatibility with JDK 25 LTS was still being evaluated and rejected.

## Consequences

### ✅ Positive Outcomes

- **[+] Coherent runtime model.** ScopedValue + StructuredTaskScope + FFM + VTs (with pinning fix) compose into a single design philosophy. No subsystem has to fall back to legacy primitives.
- **[+] Zero pin-pollution.** JEP 491 closes the `synchronized` pinning gap. Slab-pool ABA-safety blocks (per ADR-007 amendment) are now legal without carrier pinning.
- **[+] Native-interop without `Unsafe`.** Panama FFM replaces every legacy `sun.misc.Unsafe` use case in the kernel and enterprise tiers.
- **[+] Valhalla-ready.** Records and immutable final classes designed today scalarise under C2 EA today and become true value types when Valhalla GAs — no migration required.


### ⚠️ Trade-offs

- **[-] Operator JDK requirement.** Every Exeris deployment requires JDK 26+. Operators on RHEL/Ubuntu LTS with vendor-blessed JDK 21 cannot run Exeris without upgrading the JVM. This is a deliberate trade — the platform's performance contract is incompatible with LTS.
- **[-] Preview-feature volatility.** Preview features may rename, change signatures, or be removed across EA builds. The repos accept the maintenance cost of tracking EA semantics in exchange for early access to the runtime model.
- **[-] Tooling lag.** Some IDEs, static analysers, and bytecode tools lag behind preview features. Workarounds may require manual configuration.

### 📋 What is NOT in scope

- Backwards-compatibility shims for JDK 21 / 25. None are provided. Code that targets older JDKs is rejected.
- Multi-release JARs. The platform ships JDK 26 bytecode only; no `META-INF/versions/21/` paths.

## Amendments

- **2026-09-05 — Superseded by the two-track JDK model. The mandate binds nothing and is retired.**
  This ADR mandated "JDK 26 (EA → GA when released) with `--enable-preview` across every Exeris
  repository". All five obligations are contradicted by the tree as it stands, verified 2026-09-05:
  `exeris-kernel`, `exeris-kernel-build-config`, `exeris-sdk`, `exeris-tooling`, `exeris-platform`
  and `exeris-caps-cors-policy` all set `maven.compiler.release=25` and pass `--enable-preview`
  nowhere (obligations 1 and 2); obligation 3's "EA acceptable until GA" expired when JDK 26 reached
  GA on 2026-03-17, and its "no fallback to 21 LTS" is contradicted by `exeris-telemetry-spec`, which
  builds at `release=21`; obligation 4's "CI runs against the latest EA" has no subject, since the
  default line runs no EA at all; and obligation 5's "build fails if `release` is set below 26"
  describes a gate that does not exist — the only version floor in the ecosystem is
  `exeris-tooling`'s `requireJavaVersion` of `[25,)`, a minimum rather than a ceiling.

  What replaced it: kernel [ADR-066](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-066-preview-clean-ga-baseline.md)
  (accepted 2026-08-08, shipped 0.11.0) put the distributable line on a preview-clean JDK 25 LTS
  baseline with a separate `preview` branch; `exeris-spring-runtime` ADR-068 (2026-08-08) adopted the
  same two-track artefact model; `exeris-sdk` ADR-069 (2026-08-12) fixed the SDK's baseline to the
  LTS. **None of the three declares a supersession** — ADR-066's own header reads "Supersedes /
  amends: none" — so it is declared here rather than inferred from them.

  The residue is not a live scope. `exeris-kernel-enterprise` still compiles at `release=26` with
  `--enable-preview`, and `exeris-enterprise-observability` at `release=26` without it, but both are
  planned to converge on 25; a repository that has not yet migrated is what the two-track model
  accounts for, not a mandate still in force. Anything that needs the preview line should cite
  ADR-066 and ADR-068, which describe it, rather than this record. (PR #91)

## Cross-references

- ADR-007 (Next-Gen Runtime Architecture) — depends on this ADR's preview-features mandate to be possible.
- ADR-005 (JFR-First Telemetry) — depends on `@StackTrace(false)` semantics stable since JDK 21+ and refined in JDK 26.
- `exeris-kernel/CLAUDE.md` §"Hard Constraints" — operationalises the bans that this ADR's feature mandate makes possible.

## Engineering Protocol

Once this decision is ACCEPTED, every repo's `pom.xml` must reflect `<maven.compiler.release>26</maven.compiler.release>` and the `--enable-preview` flags. Existing repos already comply; this ADR codifies the existing reality.
