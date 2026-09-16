---
title: "ADR-088: Cryptographic License Manifest Format and Offline Verification"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
slug: adr/ADR-088
---

# ADR-088: Cryptographic License Manifest Format and Offline Verification

| Attribute       | Value                                                                                                                                                                                                         |
|:----------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                                                                                                                  |
| **Deciders**    | Arkadiusz Przychocki                                                                                                                                                                                          |
| **Date**        | 2026-09-12                                                                                                                                                                                                    |
| **Scope**       | cross-repo (`exeris-kernel-core`, `exeris-tooling`)                                                                                                                             |
| **Owning Repo** | `exeris-docs`                                                                                                                                                                                                 |
| **Driven By**   | Technical implementation of ECA Part V; requirement for tamper-proof, air-gapped, zero-phone-home cryptographic license attestation with zero runtime performance impact                                      |
| **Compliance**  | [`standards/eca-specification.md`](../standards/eca-specification.md) (ECA Specification §5), [ADR-089](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md), the commercial entitlement and schedule taxonomy |

---

## Context and Problem Statement

ADR-089 established the runtime execution contract and the *Build ≠ License* boundary, but deliberately decoupled the cryptographic format of the attestation token (`license-manifest.json`). The Exeris platform operates in environments ranging from developer laptops to sovereign clouds, high-frequency financial exchanges, and classified defense networks. This deployment spectrum creates severe cryptographic constraints:

1. **Strict Air-Gap Isolation:** Banking, telecom, and defense runtimes prohibit any outbound network socket during bootstrap or execution. Traditional license servers (FlexLM, SaaS license daemons, OCSP pings) are strictly forbidden. The license manifest must be completely self-contained and mathematically verifiable offline.
2. **The JSON Canonicalization Trap:** The manifest must be human-readable and GitOps-friendly (viewable in Git, inspectable in Kubernetes ConfigMaps, verifiable via `jq`). However, JSON allows non-semantic formatting variances (arbitrary key ordering, whitespace differences, numeric formatting). Standard digital signatures over raw text break whenever DevOps tooling reformats or pretty-prints the file.
3. **Startup Latency Budget:** Exeris keeps cold start short by eliminating reflection and classpath scanning, and the licensing check has to fit inside that budget rather than enlarge it. No figure is quoted: a startup number belongs in a benchmark report with its environment and figure state. Heavy cryptography, such as RSA-4096 signature verification, complex X.509 certificate chain parsing, or external crypto library dependencies (e.g. BouncyCastle), degrades startup performance and expands the attack surface.

We must define a deterministic, tamper-proof attestation format that guarantees authenticity, survives GitOps reformatting, verifies with standard JDK primitives at a cost small enough not to change the startup budget, and requires zero outbound network calls.

This ADR answers: **What is the canonical schema of `license-manifest.json`, how is deterministic canonicalization achieved, which digital signature algorithm provides offline attestation, and how is the root of trust managed in `exeris-kernel-core`?**

---

## 🏁 The Decision

**We standardize on JSON Schema v1 for `license-manifest.json`, RFC 8785 (JSON Canonicalization Scheme - JCS) for deterministic serialization, and Ed25519 (RFC 8032) for asymmetric digital signatures verified offline against an embedded `TrustedIssuerKeyStore` during Phase 0 of the kernel bootstrap.**

All cryptographic verification is strictly local, asymmetric, and free of third-party library dependencies. No latency figure is stated here; see the Verification Cost bullet for why.

### 1. Canonical Schema Specification: `license-manifest.json` (v1)

The manifest is an UTF-8 encoded JSON document conforming to `https://specs.exeris.eu/schema/v1/license-manifest.json`. It is partitioned into five functional blocks plus an detached signature block:

```json
{
  "$schema": "https://specs.exeris.eu/schema/v1/license-manifest.json",
  "contract": {
    "id": "EXR-2026-CAP-0082",
    "framework": "ECSL-1.0",
    "commercialModel": "CAPACITY"
  },
  "entitlement": {
    "edition": "enterprise",
    "sku": "exeris-sku-api-gateway",
    "licenseMode": "SUBSCRIPTION",
    "workloadProfileRef": "WP-2026-FINTECH-01",
    "capabilities": [
      "gateway.core",
      "gateway.routing",
      "gateway.rate-limit",
      "security.jwt",
      "security.tls",
      "security.bot-fingerprinting"
    ]
  },
  "execution": {
    "environments": ["production"],
    "workloadEnvelope": {
      "maxThroughputRps": 200000,
      "maxConnections": 50000,
      "growthAllowancePercent": 20
    },
    "authorizedInstances": 25,
    "validFrom": "2026-10-01T00:00:00Z",
    "validUntil": "2027-09-30T23:59:59Z",
    "gracePeriodDays": 14
  },
  "enforcementRules": {
    "capability": "HARD",
    "environment": "HARD",
    "authorizedInstances": "SOFT",
    "workloadEnvelope": "AUDIT"
  },
  "issuer": {
    "authority": "Exeris License Issuer CA",
    "keyId": "exeris-root-2026-k1",
    "issuedAt": "2026-09-12T12:00:00Z"
  },
  "signature": {
    "algorithm": "Ed25519",
    "canonicalization": "RFC-8785",
    "value": "h4K9v...[base64Encoded64ByteEd25519Signature]..."
  }
}
```

#### Field Constraints:
* `contract.commercialModel`: Restricted to `STANDARD`, `ENTERPRISE`, `CAPACITY`, `VALUE_SHARE`, or `OEM`.
* `entitlement.edition`: Must be `community`, `commercial`, or `enterprise`. **This is not ADR-023's licence taxonomy**, which reads `community` / `commercial` / `enterprise-private` and classifies a single capability. `edition` classifies the whole platform an entitlement buys, so the two share two of three values by coincidence of vocabulary and differ in the third because they answer different questions. ADR-023 records a reuse of the same kind in its own Trade-offs — its `enterprise-private` takes ADR-020's value with a slightly different meaning — so the pattern is known here and this line is what keeps this instance from being silent.
* `entitlement.licenseMode`: Must be `SUBSCRIPTION` or `PERPETUAL_INTERNAL`.
* `entitlement.capabilities`: An array of lowercase kebab-case capability identifiers matching the `@CapabilityModule.name()` ecosystem naming convention.
* `execution.environments`: A set containing one or more of `development`, `staging`, `production`, `production-load-sim`, `dr-cold`, `dr-hot`. These are the seven categories of `eca-specification.md` §4.3 collapsed to six on purpose, and the collapse is stated rather than left to be inferred: §4.3 item 1 treats Evaluation, Development, Test and Staging as one entitlement class — unstamped builds, no commercial manifest — so Evaluation carries no value of its own and is recorded as `development`. `production-load-sim` does have one, because §4.3 places Production Load Simulation under PRODUCTION and it therefore requires an active entitlement; an enum that cannot express it cannot express a manifest that entitles it.
* `signature.algorithm`: Strictly `Ed25519`.
* `signature.canonicalization`: Strictly `RFC-8785`.

### 2. Deterministic Canonicalization: RFC 8785 (JCS)

To guarantee that valid manifests remain cryptographically verifiable across GitOps transforms, Kubernetes ConfigMap injections, and pretty-printing passes, signature generation and verification apply **RFC 8785 (JSON Canonicalization Scheme)**:

1. **Detached Signature Exclusion:** The entire `"signature"` property is detached from the JSON document. The signed payload comprises all sibling keys (`$schema`, `contract`, `entitlement`, `execution`, `enforcementRules`, `issuer`).
2. **Lexicographical Key Sorting:** Object member keys are sorted strictly by UTF-16 code unit order at every depth.
3. **Whitespace Normalization:** All whitespace outside string literals is stripped (no line breaks, no spaces after colons or commas).
4. **Deterministic Number Serialization:** Numbers are formatted following ECMAScript standard serialization rules per RFC 8785 §3.2.2.3.
5. **Character Encoding:** The canonical string is converted to raw bytes using strict UTF-8 with no byte-order mark (BOM).

### 3. Asymmetric Digital Signature: Ed25519 (RFC 8032)

We select **Ed25519** (Edwards-curve Digital Signature Algorithm over Curve25519 with SHA-512) as the sole signing algorithm:

* **Key and Signature Geometry:** Public keys are exactly 32 bytes; signatures are exactly 64 bytes (encoded as standard Base64 in `signature.value`).
* **Zero External Dependencies:** Verified using the standard JDK crypto provider (`java.security.Signature.getInstance("Ed25519")`, available natively since JDK 15). No BouncyCastle or native JNI bindings are required.
* **Deterministic Verification:** Ed25519 is fully deterministic and resistant to side-channel timing attacks, hash collisions, and weak random number generator vulnerabilities.
* **Verification Cost:** One signature check over a canonical byte string, performed once during Phase 0 bootstrap. No latency figure is quoted here: a number belongs in a benchmark report with its environment and figure state.

### 4. Root of Trust and Offline Key Management

1. **Embedded Trust Root:** `exeris-kernel-core` embeds an immutable, static keystore:
   ```java
   package eu.exeris.kernel.core.contract.crypto;

   import java.security.PublicKey;
   import java.util.Map;

   public final class TrustedIssuerKeyStore {
       private static final Map<String, byte[]> TRUSTED_PUBLIC_KEYS = Map.of(
           "exeris-root-2026-k1", HexFormat.of().parseHex("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c"),
           "exeris-root-2025-k1", HexFormat.of().parseHex("a5b9821d6f34e2c078a94511d9f82bc7194602ea91bc340982efcd18092a771f")
       );

       public static byte[] getPublicKeyBytes(String keyId) {
           byte[] key = TRUSTED_PUBLIC_KEYS.get(keyId);
           if (key == null) {
               throw new ContractBreachException("EX-LIC-0002", "Unknown issuer keyId: " + keyId);
           }
           return key;
       }
   }
   ```
2. **Epoch Key Lifecycles & Perpetual Detachment:** Exeris rotates license signing keys across defined multi-year epochs. When a customer executes Code Detachment under Schedule C (`licenseMode: PERPETUAL_INTERNAL`), historical epoch keys remain embedded in the pinned version line forever, guaranteeing that detached systems boot offline indefinitely without expiring trust roots.
3. **Offline Revocation Lists (CRL):** In strict air-gapped environments where online revocation checks are impossible, compromised or breached manifests are blacklisted via SHA-256 digests in regular security patch updates (`BlockedManifestRegistry`).

### 5. Phase 0 Bootstrap Verification Pipeline

During Phase 0 (`FOUNDATION: Contract & Memory`) of `KernelBootstrap`, the runtime executes the following deterministic sequence:

```
[license-manifest.json]
         │
         ▼
[1. Resolve File] ────────► If absent & env != "production" ──► Fallback to Community Edition
         │                  If absent & env == "production" ──► HALT (ContractBreachException)
         ▼
[2. Parse JSON & Extract KeyId]
         │
         ▼
[3. Resolve Public Key from TrustedIssuerKeyStore]
         │
         ▼
[4. Detach "signature" & Apply RFC 8785 Canonicalization]
         │
         ▼
[5. Ed25519 Signature Verification via JDK Signature SPI]
         │
         ├────────► Invalid Signature ──► HALT (ContractBreachException)
         ▼
[6. Temporal Validation: validFrom <= now <= validUntil + gracePeriodDays]
         │
         ├────────► Expired (outside grace) ──► HALT (ContractBreachException)
         ├────────► Within gracePeriodDays ──► Log SOFT warning & JFR event
         ▼
[7. Materialize Typed Immutable ExecutionContract Record]
         │
         ▼
[Store in KernelProviders.EXECUTION_CONTRACT]
```

**Concrete obligations:**

1. **Deterministic RFC 8785 Canonicalizer:** `exeris-kernel-core` and `exeris-tooling` must implement a zero-allocation, zero-dependency RFC 8785 canonicalizer (`eu.exeris.kernel.core.contract.crypto.JsonCanonicalizer`). Third-party JSON libraries must not be introduced to the kernel SPI or core runtime.
2. **Standard JDK Cryptography:** Signature verification must exclusively utilize the standard JDK `java.security.Signature.getInstance("Ed25519")` API over `NamedParameterSpec.ED25519`.
3. **Strict Tamper Detection:** A single bit modification in `license-manifest.json` outside the detached signature value must cause signature verification to fail immediately.
4. **Pre-Allocation Phase 0 Gate:** Manifest verification must execute in Phase 0 of `KernelBootstrap` prior to off-heap memory segmentation, network socket binding, or capability initialization.
5. **No Runtime Key Ingestion:** Public keys for verifying Exeris commercial licenses must not be read from dynamic remote network endpoints or unverified local files; they are permanently pinned in the immutable `TrustedIssuerKeyStore`.

---

## Consequences

### ✅ Positive Outcomes

* **[+] Absolute Air-Gap Guarantee:** Verification is 100% offline; systems operate in high-security, classified, or zero-trust air-gapped networks without telemetry leaks.
* **[+] GitOps & DevOps Resilient:** Because canonicalization complies with RFC 8785, manifests can be reformatted, minified, or pretty-printed by CI/CD pipelines and Helm charts without invalidating the cryptographic signature.
* **[+] Bounded Startup Cost:** Verification adds one signature check to Phase 0 bootstrap and no network round trip, so the startup budget is spent locally.
* **[+] Zero External Cryptographic Dependencies:** Leverages native JDK 15+ EdDSA support, avoiding bloated dependencies such as BouncyCastle.
* **[+] Clean Separation of Concerns:** Complements ADR-089 by providing the cryptographic attestation proof that produces the typed `ExecutionContract`.

### ⚠️ Trade-offs

* **[-] Static Revocation Propagation:** In air-gapped deployments, revoked manifests cannot be disabled via real-time revocation servers; revocation requires distributing security patch releases containing updated blacklist digests.
* **[-] Key Rotation Ceremony Overhead:** Rotating signing keys requires embedding new epoch public keys in future minor platform releases while preserving historical keys for perpetual licenses.

### 🔄 Alternatives Considered and Rejected

* **JWT / JOSE (RFC 7519 / RFC 7515):**
  * *Cost:* JWT tokens wrap the JSON payload in Base64URL encoding (`eyJhbGciOi...`). This obscures human inspectability and contradicts the Glass Box principle (whitepaper §1). License manifests must be directly readable and diffable in source control and Kubernetes manifests. Rejected in favor of cleartext JSON with RFC 8785 canonicalization.
* **XML-DSig / Enveloped XML Signatures:**
  * *Cost:* Extreme parsing complexity, bloated schemas, and a notorious history of canonicalization XML vulnerabilities (wrapping attacks, namespace injection, XML entity expansion). Rejected outright.
* **RSA-4096 / ECDSA P-256:**
  * *Cost:* RSA-4096 incurs large keys (512 bytes), large signatures (512 bytes), and significant verification CPU overhead. ECDSA requires random nonces during signing and is vulnerable to side-channel attacks and curve implementation flaws. Ed25519 is constant-time and compact (32/64 bytes), and its verification is cheaper — by how much is a benchmark question, and this record does not answer it.
* **Online Centralized License Server / OCSP Phone-Home:**
  * *Cost:* Completely unusable in air-gapped defense and banking infrastructure; introduces external network dependencies where network jitter or firewall misconfiguration would crash the cluster at boot. Rejected outright.

### 📋 What is NOT in scope

* **Private Key Storage and Issuance Infrastructure:** The internal PKI, air-gapped Hardware Security Modules (HSMs), and operational signing pipelines used by Exeris to issue customer manifests are governed by internal security procedures.
* **Runtime Capability Mapping:** The mapping of entitled capabilities to classloader modules and enforcement actions (`HARD`, `SOFT`, `AUDIT`) is governed by ADR-089.
* **Pricing and SKU Definitions:** The commercial terms and packaging reflected in `contract` and `entitlement` are a business matter, governed by the commercial entitlement and schedule taxonomy in the private business decision registry and deliberately not restated here.

### 🚫 Non-Goals

* **Hardware Dongles or Node Fingerprinting:** Exeris does not bind license manifests to MAC addresses, CPU serial numbers, or physical hardware dongles. Such mechanisms break containerization, auto-scaling, and cloud portability.
* **Runtime Bytecode Decryption:** The platform does not use encrypted bytecode classes that decrypt dynamically in memory.

### ⚠️ Risks and Assumptions

* **Assumes:** All target JDK distributions (OpenJDK, Temurin, Corretto, GraalVM) maintain native support for standard `Ed25519` via Java Security Provider SPI.
* **Reversed by:** Evidence that a critical enterprise customer operates on an exotic JDK distribution lacking native Ed25519 support, or mathematical compromise of the Edwards-curve discrete logarithm problem.
* **Risk:** Loss or compromise of an active Exeris Issuer private key. Mitigated by short signing epochs (1–2 years), cold storage HSM keys, and offline blacklist distribution in patch releases.

---

## Cross-references

* [`standards/eca-specification.md`](../standards/eca-specification.md) — Exeris Contract Architecture §5 (Cryptographic Manifest Specification).
* [ADR-089 (Capability Entitlement Enforcement and Runtime Execution Contract)](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) — Companion tech ADR defining `ExecutionContract` and runtime enforcement.
* The commercial entitlement and schedule taxonomy — Business definitions of commercial models and entitlement tiers.
* [RFC 8785](https://www.rfc-editor.org/rfc/rfc8785) — JSON Canonicalization Scheme (JCS).
* [RFC 8032](https://www.rfc-editor.org/rfc/rfc8032) — Edwards-Curve Digital Signature Algorithm (EdDSA).

---

## Engineering Protocol

1. **`exeris-kernel-core` Cryptographic Engine:**
   * Implement `eu.exeris.kernel.core.contract.crypto.JsonCanonicalizer` strictly following RFC 8785 without third-party dependencies.
   * Implement `eu.exeris.kernel.core.contract.crypto.TrustedIssuerKeyStore` containing the static public key array for `exeris-root-2026-k1`.
   * Implement `eu.exeris.kernel.core.contract.crypto.LicenseManifestVerifier` invoking `java.security.Signature.getInstance("Ed25519")`.
2. **Phase 0 Bootstrap Integration:**
   * Wire `LicenseManifestVerificationStep` into `KernelBootstrap.bootstrapFoundation()` before memory pool configuration.
3. **`exeris-tooling` Manifest Generator:**
   * Add `exeris-manifest-tool` CLI module capable of parsing commercial entitlement YAMLs, canonicalizing via RFC 8785, and signing via an Ed25519 private key.
4. **TCK Assertion Suite:**
   * Implement `AbstractLicenseManifestCryptoTck` in `exeris-kernel`:
     * Test 1: Bit-flip in capability list causes immediate signature validation failure.
     * Test 2: Whitespace and key reordering (RFC 8785 invariance) produces identical signature and passes verification.
     * Test 3: Unregistered `keyId` throws `EX-LIC-0002`.
     * Test 4: Manifest expired beyond `gracePeriodDays` throws `EX-LIC-0003`.
5. **Cross-Repo Stubs:**
   * Land `docs/adr/ADR-088.link.md` in `exeris-kernel` and `exeris-tooling`.
