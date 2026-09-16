---
title: Exeris Contract Architecture Specification
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-16
slug: standards/eca-specification
---

# Exeris Contract Architecture (ECA) Specification

Formal architectural and normative specification for legal, commercial, cryptographic, and execution contracts across the Exeris platform.

Binding per ADR-085 §M.38.

**Where this does not apply, and what it costs.** It governs what an entitlement permits and how that permission is proved, not how a capability is built or a SKU assembled — `capability-conventions.md` and `sku-conventions.md` own those, and a rule about repository shape does not belong here however close it reads. It says nothing about pricing: the commercial terms sit in the private business registry, and this page names them by what they decide rather than restating them. The cost of proving entitlement offline is that revocation is not immediate — a manifest is valid until its epoch key rotates or its term ends, and there is no call home to shorten that. That is the trade the air-gap requirement buys.

Binding per [ADR-023](../adr/ADR-023-capability-licensing-taxonomy.md) (Licensing Taxonomy), [ADR-024](../adr/ADR-024-capability-composition-model.md) (Capability Composition), [ADR-053](../adr/ADR-053-sku-composition-manifest-format.md) (SKU Composition Manifest), and the R&D cooperation model (IP sovereignty), a business decision kept in the private registry.

---

## Part I — Architectural Model & The Four Truths

Exeris unifies technical execution with legal and commercial governance under a four-stage pipeline:

**Define** → **Compose** → **Attest** → **Execute**

Every level of the system executes only what it has been formally authorized to execute by contract. The platform distinguishes four orthogonal categories of truth to prevent semantic leakage between legal drafting and runtime execution.

```
+-----------------------------------------------------------------------------+
|                                 LEGAL TRUTH                                 |
|            Master Agreement / ECSL v1.x / Schedules A–D (Law/Courts)        |
+--------------------------------------+--------------------------------------+
                                       |
                                       | human/legal translation
                                       v
+-----------------------------------------------------------------------------+
|                              COMMERCIAL TRUTH                               |
|        Order Form / Commercial Entitlement (Business Relationship)          |
+--------------------------------------+--------------------------------------+
                                       |
                                       | controlled issuance (Attestation)
                                       v
+-----------------------------------------------------------------------------+
|                             CRYPTOGRAPHIC TRUTH                             |
|          Signed License Manifest (Ed25519 Asymmetric Offline Proof)         |
+--------------------------------------+--------------------------------------+
                                       |
                                       | local parsing & verification (Phase 0)
                                       v
+-----------------------------------------------------------------------------+
|                              EXECUTION TRUTH                                |
|        In-Memory Typed Record: ExecutionContract (Kernel Bootstrap DAG)     |
+--------------------------------------+--------------------------------------+
```

### 1.1 The Four Truths

1. **Legal Truth (Human Law & Agreement):** Governed by civil and commercial law. Defined in the Exeris Commercial Source-Available License (ECSL) and attached legal Schedules. Answers: *What may the licensee legally do with the source code and binaries?*
2. **Commercial Truth (Commercial Entitlement):** Defined in the signed Order Form. Establishes the exact commercial model, authorized capabilities, environment limits, capacity commitments, and financial terms. Answers: *What has the customer purchased or been granted?*
3. **Cryptographic Truth (Attestation Token):** The machine-readable `license-manifest.json` signed with Ed25519 by the Exeris License Issuer (CA). The Issuer acts as a **trusted translation authority**, not a creator of rights. It certifies: *"Exeris Systems formally attests that the specified entitlement was issued to the named licensee."* Answers: *What cryptographic proof does the environment possess?*
4. **Execution Truth (Runtime State):** The materialized, typed `ExecutionContract` record instantiated in `exeris-kernel-core` memory during Phase 0 of the `KernelBootstrap` DAG. Answers: *What capability composition and execution parameters is the kernel authorized to execute in this process?*

### 1.2 The ECA Invariant

The runtime state is mathematically constrained by the attestation, which is in turn constrained by the legal entitlement:

`E_runtime ⊆ E_manifest ⊆ E_entitlement ⟹ E_runtime ⊆ E_entitlement`

> **Normative Rule 1 (The ECA Invariant):**  
> The execution contract may restrict the legal entitlement, but it may never expand it. A technical defect or clerical error in a license manifest that reflects broader parameters than the underlying Order Form conveys no legal grant to the licensee.

### 1.3 Offline Trust Boundary & Revocation Strategy

The Exeris Kernel strictly enforces **Zero Phone-Home Compliance**. The runtime never connects to external networks to validate licensing status. Trust is rooted in the Exeris Root CA public key embedded directly in `exeris-kernel-core`.

Offline contract lifecycles are governed by five mechanisms:

1. **Natural Expiration:** Subscriptions carry an explicit `validUntil` ISO-8601 timestamp. Past this window, the runtime transitions to a deterministic grace period or halts.
2. **Manifest Replacement:** A newer signed manifest with an incremented monotonic `sequenceNumber` supersedes earlier manifests.
3. **Root Key Epoch Rotation:** Exeris root keys rotate on planned 24-month epochs. Pinned detached licenses preserve historical epoch keys.
4. **Offline Revocation Lists (CRL):** In extreme legal termination scenarios, signed cryptographic CRL artifacts are incorporated into substrate release streams and security patches.
5. **Deterministic Grace Period:** A configurable window (`gracePeriodDays`, default: 14) during which expired production systems emit high-priority audit warnings to standard logging and JFR rings without immediately halting critical business traffic.

---

## Part II — Legal Licensing Framework

### 2.1 The Source-Available Boundary (Glass Box)

Exeris Tier 2 commercial capabilities and Tier 3 Platform SKUs are published under the **Exeris Commercial Source-Available License (ECSL)**. 

* ECSL is **not** an OSI-approved open-source license. It is a **Source-Available Commercial License**.
* Code is publicly visible across public repositories to uphold the *Glass Box Thesis* (whitepaper §1): customers audit source code, verify benchmark assertions, and inspect security routines prior to purchase.
* **Non-Production Use** (evaluation, academic study, local debugging, pre-production testing) is royalty-free and unrestricted.
* **Production Use** requires an active commercial entitlement and a matching signed manifest.
* Machine metadata standard: `SPDX-License-Identifier: LicenseRef-Exeris-ECSL-1.0`.

### 2.2 Hosted Service and Service Provider Restriction

To prevent non-contributing cloud hyper-scalers and hosting providers from commoditizing the platform without commercial return, ECSL enforces a strict functional boundary:

**Permitted Internal Business SaaS** vs. **Restricted Infrastructure Service**

1. **Permitted Internal Business SaaS:** A customer (e.g., a financial institution, e-commerce operator, or logistics enterprise) executing Exeris to power its proprietary applications, user interfaces, customer-facing portals, or internal processing workflows is fully authorized under standard Commercial and Enterprise schedules.
2. **Restricted Infrastructure / Managed Service:** Offering Exeris runtime execution, API gateway proxying, dynamic orchestration, or capability execution as a direct, hosted infrastructure product to third parties (where the third party configures and consumes the Exeris data plane directly) is strictly prohibited under standard schedules and requires an explicit **Service Provider / OEM Agreement (Schedule D)**.

### 2.3 Legal Schedules Taxonomy

The core ECSL text establishes baseline terms. Commercial rights attach via four standardized schedules:

* **Schedule A (Commercial Production):** Grants production execution rights for named Platform SKUs within agreed workload boundaries.
* **Schedule B (Enterprise Operations):** Unlocks the closed-source substrate driver (`exeris-kernel-enterprise` with `io_uring`, QUIC/HTTP/3, and NUMA slab pools), enterprise security modules (`bot-fingerprinting`), 24/7 L3 engineering support, and full Intellectual Property Indemnification.
* **Schedule C (Code Detachment & Sovereignty):** Converts a recurring subscription into an irrevocable, perpetual internal-use grant for a version-pinned source tree (governed by the R&D cooperation model and the code detachment and perpetual sovereign licensing governance — both private business decisions — and by Part IV).
* **Schedule D (Service Provider & OEM):** Authorizes multi-tenant hosting, white-label bundling, and infrastructure resale under commercial revenue-share or wholesale terms.

---

## Part III — Commercial Models & Capacity Transformation

### 3.1 The Anti-Infrastructure Monetization Principle

> **Normative Principle 2 (Capacity Monetization):**  
> Exeris does not license infrastructure consumption. It licenses authorized capability execution within a defined workload envelope.

Because the Exeris zero-copy architecture is designed to do the same work on less CPU and less resident memory than a traditional framework, licensing per vCPU or per server node creates an **Efficiency Penalty** — penalizing Exeris for its own optimization. Conversely, billing for non-existent virtual hardware destroys customer ROI perception.

Exeris resolves this by monetizing the **economic result of workload transformation**.

### 3.2 The Five Commercial Models

Every commercial agreement adopts exactly one of five models, all of which compile into the standard runtime `ExecutionContract`:

| Model | Target Segment | Pricing Basis | Capacity Definition |
| :--- | :--- | :--- | :--- |
| **`STANDARD`** | SMB, Mid-Market | Published catalog tier per SKU | Standard throughput cap (e.g., 25k RPS, 5 environments) |
| **`ENTERPRISE`** | Large Enterprise | Negotiated custom annual fee | Custom capability set, custom environment quotas, 24/7 SLA |
| **`CAPACITY` (EECA)** | Heavy Middleware Migrations | Fixed annual contract based on transformed baseline | Committed Workload Profile (W) + Node Cap (H) + Growth Allowance |
| **`VALUE_SHARE`** | Cloud Cost Take-Out Programs | Shared infrastructure cost reduction | Fixed baseline fee + percentage of documented infrastructure savings |
| **`OEM`** | Cloud Providers, Integrators | Wholesale / Revenue share | Multi-tenant tenant volume, aggregate platform throughput |

### 3.3 Exeris Enterprise Capacity Agreement (EECA) & Equivalence

Under the `CAPACITY` model, Exeris does not guarantee generic, unconditioned hardware multipliers. Instead, it enters into an **Exeris Enterprise Capacity Agreement (EECA)** rooted in reproducible empirical data from `exeris-benchmarks`.

Capacity Equivalence is defined as:

`Capacity_Exeris(W, SLO, H) ≥ Capacity_committed`

Where:
* `W`: Formally registered **Workload Profile** (request distribution, payload size, concurrency, TLS parameters, and required capability set).
* `SLO`: Agreed quality-of-service boundary (P99 latency ceiling, error rate, availability floor).
* `H`: Hardware and node envelope allocated for the deployment.
* `Capacity_committed`: The operational throughput and processing capacity Exeris guarantees to sustain.

#### The Certification Pipeline:
1. **Profile Registration:** Customer baseline workload is captured as a formal specification (e.g., `WP-2026-PAYMENTS-01`).
2. **Lab Verification:** The scenario is executed in `exeris-benchmarks` under matched-contract fairness gating.
3. **Capacity Equivalence Certificate:** A cryptographically signed report verifying that `N` Exeris nodes sustain workload `W` previously requiring `M` competitor nodes (`M ≫ N`).
4. **Commercial Execution:** The certificate binds the Order Form, generating an entitlement with an authorized instance quota plus an agreed growth allowance (e.g., +20%).

---

## Part IV — Entitlement & Environment Taxonomy

### 4.1 Platform Editions

1. **`community`:** Open-source substrate (`exeris-kernel-community`) and commodity capabilities (`cors-policy`, `i18n`, `observability-bridge`). Apache 2.0. Unrestricted.
2. **`commercial`:** Source-available Tier 2 capabilities and Tier 3 Platform SKUs. Requires active Commercial Entitlement for production execution.
3. **`enterprise`:** High-performance substrate driver (`exeris-kernel-enterprise`), kernel-bypass networking, NUMA memory management, and closed-source threat detection capabilities (`bot-fingerprinting`).

### 4.2 License Modes

* **`SUBSCRIPTION`:** Active term-bound grant. Entitles the licensee to ongoing releases, vulnerability patches, signed capability manifests, and operational support. Subject to expiration.
* **`PERPETUAL_INTERNAL` (Detached):** Permanent, irrevocable internal operating grant for a specific, version-pinned release (e.g., `==1.4.7`). Detachment transfers a perpetual non-exclusive operating and modification right to the customer's internal fork. Exeris retains 100% of underlying intellectual property and copyrights. Re-distribution to third parties is strictly prohibited.

### 4.3 Environment Classification

To eliminate procurement disputes, environment rights are strictly categorized:

```
                      +--- Evaluation (Non-production: free, unstamped)
                      +--- Development (Non-production: free, unstamped)
NON-PRODUCTION -------+--- Test & Staging (Non-production: free, unstamped)
                      +--- Cold Standby / Backup Archive (Free, non-traffic-serving)

                      +--- Production (Requires active Entitlement)
PRODUCTION -----------+--- Active Disaster Recovery (Hot/Warm standby serving traffic)
                      +--- Production Load Simulation (Traffic on live data planes)
```

1. **Evaluation / Development / Test / Staging:** Dedicated exclusively to verification, testing, and pre-release validation. May run unstamped builds without a commercial manifest.
2. **Cold Standby (Disaster Recovery):** Replicated storage and dormant compute nodes that process no live network traffic. Permitted without additional subscription fees across all commercial tiers.
3. **Hot Standby / Active DR:** Redundant nodes actively running parallel state machines, in-memory caches, or processing live traffic splits. Counted towards active instance or throughput quotas as specified in the Order Form.

---

## Part V — Cryptographic Manifest Specification

### 5.1 JSON Schema Structure

The manifest is an immutable, canonical JSON document (`license-manifest.json`):

Its fields, their constraints and the example document are defined once, in
[ADR-088](../adr/ADR-088-cryptographic-license-manifest-and-offline-verification.md) — the record that
decides the schema. This page states what the manifest is FOR and where it sits in the architecture;
what it contains is ADR-088's to say, and restating it here would put the same schema in two places
with nothing keeping them equal.

### 5.2 Canonicalization and Verification

1. **Canonicalization:** The JSON payload (excluding the `signature` block) is normalized strictly according to **RFC 8785 (JSON Canonicalization Scheme - JCS)**.
2. **Signature:** Generated using **Ed25519** over the UTF-8 bytes of the canonical JSON string.
3. **Verification:** `exeris-kernel-core` resolves the public key identified by `issuer.keyId` from its internal keystore and validates the signature during Phase 0 bootstrap before initializing off-heap memory or network sockets.

---

## Part VI — Runtime & Tooling Enforcement

### 6.1 Build-Time Enforcement: *Build ≠ License*

To safeguard the Glass Box developer experience, build tooling (`exeris-tooling` and Maven/Gradle plugins) enforces an explicit distinction between compilation and production stamping:

`Source Code` → `mvn clean compile` → `Local Artifact` (Always permitted for evaluation)

* Developers may clone public repositories, compile code, execute unit/integration tests, and run local prototypes without any license manifest.
* When targeting a production release profile (`-Pproduction`), `exeris-tooling` verifies:
  1. The presence of a valid `license-manifest.json`.
  2. That all composed capabilities declared via `@Requires` satisfy:
     `Capabilities_declared ⊆ Capabilities_entitled`
* Unstamped artifacts fail deployment validation if booted in environments declared as `production`.

### 6.2 Enforcement Levels (`HARD`, `SOFT`, `AUDIT`)

Constraint enforcement is decoupled from raw network blocking:

1. **`HARD` Enforcement (Fail-Fast Rejection):**
   * Trigger: Composition includes unentitled commercial capabilities, execution in an unauthorized environment class, or signature tampering.
   * Action: `KernelBootstrap` throws `ContractBreachException` and terminates the JVM immediately.
2. **`SOFT` Enforcement (Non-Fatal Warning):**
   * Trigger: Node count exceeds `authorizedInstances` during emergency failover, or manifest enters the `gracePeriodDays` window.
   * Action: Emits structured error logs to `STDERR` and attaches high-severity events to the in-process JFR ring. System continues serving traffic.
3. **`AUDIT` Enforcement (Continuous Metering):**
   * Trigger: Traffic bursts exceed `maxThroughputRps` or connections exceed `maxConnections`.
   * Action: System serves traffic without dropping packets. Telemetry records the peak envelope in local metrics for subsequent commercial true-up reconciliation.

### 6.3 Typed Runtime Model: `ExecutionContract`

The kernel never parses JSON on request paths. Phase 0 bootstrap transforms the validated manifest into a typed, immutable Java record:

The record's fields, its package and the contract it carries are defined once, in
[ADR-089](../adr/ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) — the record that
decides them. This page does not restate the declaration: a second copy is a second thing to keep
in step, and the one that drifts is always the copy rather than the decision.

---

## Implementation Roadmap

The adoption of the Exeris Contract Architecture proceeds across the platform registry:

```
   1. ECA Specification (exeris-docs/standards/eca-specification.md) [FROZEN]
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
   2. Business decision                  3. ADR-088 (Tech ADR)
   Commercial & Entitlement Model        Manifest Schema & Ed25519 Proof
            │                                     │
            ▼                                     ▼
   4. Business decision                  5. ADR-089 (Tech ADR)
   Detachment & Sovereignty Governance   Tooling & Phase 0 Enforcement Engine
            │                                     │
            └──────────────────┬──────────────────┘
                               ▼
                 6. Formal Legal Drafting
                 ECSL v1.0, Schedules A–D, Order Form
```

---

## References

* [ADR-020: Open-Core Documentation Boundary & Cross-Repo Mirror Policy](../adr/ADR-020-open-core-documentation-mirror-policy.md)
* [ADR-023: Capability Licensing Taxonomy](../adr/ADR-023-capability-licensing-taxonomy.md)
* [ADR-024: Capability Composition Model](../adr/ADR-024-capability-composition-model.md)
* [ADR-053: SKU Composition Manifest Format](../adr/ADR-053-sku-composition-manifest-format.md)
* [ADR-088: Cryptographic License Manifest Format and Offline Verification](../adr/ADR-088-cryptographic-license-manifest-and-offline-verification.md)
* [ADR-089: Capability Entitlement Enforcement and Runtime Execution Contract](../adr/ADR-089-capability-entitlement-enforcement-and-runtime-contract.md)
* The R&D cooperation model (IP sovereignty), the contributor terms, the commercial entitlement and
  schedule taxonomy, and the code detachment and perpetual sovereign licensing governance. These are
  business decisions and live in the private business registry; a public page names them by what they
  decide, never by their identifier or their path.
* [B2B Technical Whitepaper](../b2b-technical-whitepaper.md)
