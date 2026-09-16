---
title: "ADR-089: Capability Entitlement Enforcement and Runtime Execution Contract"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
slug: adr/ADR-089
---

# ADR-089: Capability Entitlement Enforcement and Runtime Execution Contract

| Attribute       | Value                                                                                                                                                                 |
|:----------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                                                                          |
| **Deciders**    | Arkadiusz Przychocki                                                                                                                                                  |
| **Date**        | 2026-09-12                                                                                                                                                            |
| **Scope**       | platform / cross-repo (`exeris-tooling`, `exeris-kernel-core`, `exeris-caps-*`, `exeris-sku-*`)                                                                      |
| **Owning Repo** | `exeris-docs`                                                                                                                                                         |
| **Driven By**   | Commercialization of Tier 2/3 capabilities; need to enforce capability entitlement without violating the Glass Box developer experience or coupling runtime to legal jargon |
| **Compliance**  | [`standards/eca-specification.md`](../standards/eca-specification.md) (ECA Specification), [ADR-023](ADR-023-capability-licensing-taxonomy.md) (Licensing Taxonomy), [ADR-024](ADR-024-capability-composition-model.md) (Capability Composition), the commercial entitlement and schedule taxonomy (Commercial Entitlement) |

---

## Context and Problem Statement

ADR-023 established the three-valued licensing taxonomy for capabilities (`community`, `commercial`, `enterprise-private`) and SKU visibility, but explicitly left open the enforcement mechanism (Obligation 6 & 10). The platform cannot rely on honor systems or post-hoc litigation alone to defend its commercial Tier 2/3 monetization, nor can it accept traditional license-enforcement patterns that break deep-tech development:

1. **The Glass Box Developer Dilemma:** Developers must be able to clone public source-available repositories, compile code, execute tests, and evaluate capabilities locally without entering commercial license keys or talking to sales. A naive build-time check that rejects unstamped builds breaks the Glass Box thesis (whitepaper §1).
2. **Runtime Leaks of Legal Vocabulary:** A runtime that parses legal terms ("Schedule B", "Enterprise Addendum", "Master Services Agreement") tightly couples code to mutable contracts. If legal counsel renames a schedule, the runtime engine must not break.
3. **The Danger of Hard Network Blocking:** High-throughput systems handling financial or mission-critical traffic must never experience hard packet drops due to transient traffic spikes exceeding throughput quotas. A sudden burst beyond an agreed RPS cap on Black Friday is an accounting concern, not a security breach.

We must define how capability entitlement is verified across the build and runtime pipeline, how the typed runtime model is materialized in memory, and how different constraint classes are enforced without introducing online phone-home dependencies.

This ADR answers: **How does Exeris enforce capability licensing across the build-time codegen pipeline and runtime bootstrap, what is the structure of the in-memory execution contract, and how are constraint breaches categorized?**

---

## 🏁 The Decision

**We enforce capability entitlement by evaluating a strict set inclusion invariant across build-time tooling and Phase 0 of the kernel bootstrap, materializing a typed, immutable `ExecutionContract` record in `exeris-kernel-core` with decoupled enforcement tiers (`HARD`, `SOFT`, `AUDIT`).**

The runtime evaluates pure technical entitlements, remaining completely agnostic of legal schedule designations.

### 1. The Build-Time Boundary: *Build ≠ License*

We explicitly decouple source compilation from production deployment authorization:

* Developers can always clone, compile, test, and package source-available capabilities without a license manifest.
* Stamping a build artifact for production target execution requires a valid, cryptographically verified `license-manifest.json`.
* The tooling pipeline (`exeris-tooling`) validates that all composed capabilities declared via `@Requires` satisfy:
  `Capabilities_declared ⊆ Capabilities_entitled`
* An unstamped artifact booted in an environment marked as `production` fails at bootstrap.

### 2. Typed Runtime Contract: `ExecutionContract`

The kernel never parses JSON manifests or computes cryptographic signature hashes on hot execution paths. During Phase 0 of the `KernelBootstrap` DAG (prior to off-heap memory allocation or socket binding), the validated manifest is converted into an immutable record:

```java
package eu.exeris.kernel.core.contract;

import java.time.Instant;
import java.util.Map;
import java.util.Set;

public record ExecutionContract(
    String contractId,
    String commercialModel,
    String edition,
    String licenseMode,
    String sku,
    Set<String> entitledCapabilities,
    Set<String> authorizedEnvironments,
    int authorizedInstances,
    WorkloadEnvelope envelope,
    Instant validFrom,
    Instant validUntil,
    int gracePeriodDays,
    Map<String, EnforcementLevel> enforcementRules
) {
    public boolean allowsCapability(String capabilityId) {
        return entitledCapabilities.contains(capabilityId);
    }

    public boolean isEnvironmentAuthorized(String environment) {
        return authorizedEnvironments.contains(environment);
    }

    public EnforcementLevel getEnforcement(String constraintKey) {
        return enforcementRules.getOrDefault(constraintKey, EnforcementLevel.AUDIT);
    }
}
```

The active instance is registered into `KernelProviders.EXECUTION_CONTRACT` and made available to capability modules and telemetry subsystems.

### 3. Three-Tier Enforcement Categorization

Enforcement actions are partitioned into three orthogonal levels:

| Level | Failure Action | Applies To | Rationale |
| :--- | :--- | :--- | :--- |
| **`HARD`** | Throws `ContractBreachException` and terminates the JVM immediately. | Unlicensed commercial capabilities, unauthorized environment class, signature invalidity, detached version mismatch. | Structural breach of copyright and contract; system has no right to execute. |
| **`SOFT`** | Logs structured error to `STDERR`, attaches high-priority event to in-process JFR ring, system remains operational. | Node count exceeds `authorizedInstances` during emergency failover; manifest enters `gracePeriodDays` window. | Operational resilience: transient infrastructure anomalies or invoice delays must not cause cascading downtime. |
| **`AUDIT`** | Telemetry records continuous metrics in local buffers for reconciliation; traffic is served with zero dropped packets. | Throughput bursts beyond `maxThroughputRps`, concurrent connections beyond `maxConnections`. | Commercial monetization: capacity overages are financial reconciliation matters (true-up), not availability faults. |


**Concrete obligations:**

1. **Tooling Capability Set Assertion:** `exeris-tooling` must extract all resolved capability identifiers from the composed `@CapabilityModule` DAG and assert `Capabilities_declared ⊆ Capabilities_entitled` whenever the build profile specifies a production target (`-Pproduction`). Missing entitlements must cause compilation to fail with an actionable diagnostic.
2. **Phase 0 Bootstrap Verification:** `exeris-kernel-core`'s `KernelBootstrap` must resolve and validate `license-manifest.json` during Phase 0 (`FOUNDATION: Contract & Memory`). **This amends the canonical Bootstrap DAG**, which defines FOUNDATION as memory only and places cryptography in the parallel SERVICES phase (`high-level-architecture.md` §2, sourced from `exeris-kernel/docs/subsystems/bootstrap.md`). The amendment is deliberate — an entitlement that is checked after off-heap allocation has already been spent is checked too late — and it is a change to that diagram rather than a reading of it, so both pages owe an update; Engineering Protocol item 6 carries the obligation. If the manifest is missing, corrupt, or signature verification fails in an environment configured as `production`, the process must terminate before binding network sockets.
3. **Zero Phone-Home Invariant:** No enforcement routine in `exeris-kernel-core`, `exeris-tooling`, or any capability module may initiate an outbound network connection to verify license status. All verification is strictly local and asymmetric.
4. **Offline Keystore Binding:** The public keys of the Exeris License CA must be embedded in `exeris-kernel-core` at build time. Historical epoch keys must remain accessible to validate version-pinned `PERPETUAL_INTERNAL` detached deployments.
5. **Separation from APM Telemetry:** In-process JFR licensing events (`eu.exeris.telemetry.license.EnforcementEvent`) are strictly customer-controlled operational records. They must never be forwarded to third-party or Exeris servers without explicit customer configuration.

---

## Consequences

### ✅ Positive Outcomes

* **[+] Glass Box Developer Ergonomics Preserved:** Developers work locally without friction, licenses, or fake mocks. Friction only appears when preparing production releases.
* **[+] Decoupled Architecture:** The kernel is completely insulated from legal agreement names; commercial contracts can change terms without requiring code refactoring.
* **[+] Operational Safety in Production:** Mission-critical traffic is never discarded due to commercial overages; `AUDIT` enforcement keeps systems online while tracking metrics for settlement.
* **[+] Air-Gapped High Security:** The platform operates flawlessly in classified defense, sovereign cloud, and banking networks without external telemetry connections.

### ⚠️ Trade-offs

* **[-] Build Complexity:** Build tooling must maintain awareness of target profiles (`dev` vs `production`) to distinguish unstamped developer jars from production deliverables.
* **[-] Reconciliation Latency:** Under `AUDIT` enforcement, customer throughput overages are reconciled asynchronously through periodic reports rather than enforced in real time.

### 🔄 Alternatives Considered and Rejected

* **Centralized SaaS / Phone-Home License Server (FlexLM / HashiCorp Vault / Cloud License Daemon):**
  * *Cost:* Violates the strict air-gapped deployment requirement of defense, sovereign cloud, and tier-1 banking institutions. Outbound network latency on boot or transient network partitions would cause mission-critical runtime crashes. Rejected outright.
* **DRM Bytecode Obfuscation / Native Agent Wrapping:**
  * *Cost:* Obfuscating or encrypting bytecodes severely degrades HotSpot JIT compiler optimizations (inlining, escape analysis), disrupts Project Panama zero-copy off-heap memory mapping, impedes debugging, and directly violates the Glass Box ethos (whitepaper §1). Rejected outright.
* **Runtime Legal Vocabulary (Parsing "Schedule B", Order Forms, or SKU Names at Boot):**
  * *Cost:* Couples the kernel runtime lifecycle to legal contract terminology. Any contractual restructuring or schedule renegotiation would require recompiling and re-deploying the JVM engine. Rejected in favor of pure technical capability IDs.
* **Hard Packet Dropping on Throughput Quota Exceeded:**
  * *Cost:* Turning throughput overages into availability failures causes catastrophic cascade outages during organic demand spikes (e.g. Black Friday or market volatility). Capacity limits are commercial reconciliation matters, not availability kill-switches. Rejected in favor of `AUDIT` local telemetry.

### 📋 What is NOT in scope

* **Cryptographic Schema and Signature Canonicalization:** The detailed JSON schema, RFC 8785 canonicalization algorithm, and Ed25519 signature payload format are governed by ADR-088.
* **Pricing Multipliers and Detachment Fees:** Commercial pricing structures, SLA penalty matrices, and Detachment fee levels are internal business matters, governed by the commercial entitlement and schedule taxonomy and by the code detachment and perpetual sovereign licensing governance — decisions kept in the private business registry and deliberately not restated here.

### 🚫 Non-Goals

* **Digital Rights Management (DRM) Obfuscation:** Exeris does not employ bytecode obfuscation, binary wrapping, or anti-debugging routines. Enforcement is cryptographic, contractual, and verifiable.
* **Online License Revocation Servers:** The platform will not support runtime phone-home verification or OCSP-style online revocation.

### ⚠️ Risks and Assumptions

* **Assumes:** Enterprise customers will comply with annual self-certification audits when operating under `AUDIT` enforcement models.
* **Reversed by:** Evidence that major enterprise customers refuse offline cryptographic manifests in favor of centralized cloud licensing agents, or benchmark measurements showing that Phase 0 contract validation introduces non-negligible startup latency (>5ms).
* **Risk:** A compromised private signing key at the Exeris Issuer could allow unauthorized parties to generate valid manifests. Mitigated by epoch key rotations and offline CRL distribution in security patch streams.

---

## Cross-references

* [`standards/eca-specification.md`](../standards/eca-specification.md) — Exeris Contract Architecture normative specification.
* [ADR-023 (Capability Licensing Taxonomy)](ADR-023-capability-licensing-taxonomy.md) — Establishes the `community` / `commercial` / `enterprise-private` license tiers.
* [ADR-024 (Capability Composition Model)](ADR-024-capability-composition-model.md) — The capability lifecycle and composition conductor.
* [ADR-053 (SKU Composition Manifest Format)](ADR-053-sku-composition-manifest-format.md) — Canonical format for SKU capability compositions.
* [ADR-088 (Cryptographic License Manifest and Offline Verification)](ADR-088-cryptographic-license-manifest-and-offline-verification.md) — Companion tech ADR specifying JSON schema and Ed25519 cryptography.
* The commercial entitlement and schedule taxonomy — Legal and commercial schedule definitions.

---

## Engineering Protocol

1. **`exeris-kernel-core` Implementation:** Add package `eu.exeris.kernel.core.contract` containing `ExecutionContract`, `WorkloadEnvelope`, `EnforcementLevel`, and `ContractBreachException`. `ContractBreachException` extends `eu.exeris.kernel.spi.exceptions.ExerisKernelException` — ADR-083 makes it an invariant that every kernel failure reaches a handler as a subclass of it, and a HARD enforcement failure is a kernel failure like any other.
2. **Phase 0 Bootstrap Integration:** Wire `ContractBootstrapStep` into `KernelBootstrap.bootstrapFoundation()` prior to off-heap memory initialization.
3. **TCK Assertion:** Implement `AbstractExecutionContractTck` in `exeris-kernel` validating fail-fast behavior on unentitled capabilities and non-fatal logging on `SOFT` overages.
4. **Tooling Profile Gate:** Extend `exeris-tooling` annotation processor with `-Pproduction` validation against composed capability graphs.
5. **Cross-Repo Stubs:** Land `docs/adr/ADR-089.link.md` stubs in `exeris-kernel`, `exeris-tooling`, and `exeris-platform`.
6. **Bootstrap DAG Amendment:** Update `high-level-architecture.md` §2 and `exeris-kernel/docs/subsystems/bootstrap.md` so the Bootstrap DAG carries the Contract node in FOUNDATION. Until both say so, the diagrams and this record disagree, and the diagrams are what a reader trusts — tracked as `[DOC DEBT]`.
