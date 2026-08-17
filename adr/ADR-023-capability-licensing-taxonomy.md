# ADR-023: Capability Licensing Taxonomy — `community` / `commercial` / `enterprise-private`

| Attribute       | Value                                                                                                                |
|:----------------|:---------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                         |
| **Deciders**    | Arkadiusz Przychocki                                                                                                 |
| **Date**        | 2026-05-13                                                                                                           |
| **Scope**       | platform (binds every `exeris-caps-*` repository and downstream license-aware tooling)                               |
| **Owning Repo** | `exeris-docs`                                                                                                        |
| **Driven By**   | 2026-05-12 whitepaper / HLA restructure that introduced the Tier 2 Capability Ecosystem; ADR-020 visibility taxonomy was insufficient for the cap layer |
| **Compliance**  | [HLA §3.2 Composable Capabilities](../high-level-architecture.md), [Whitepaper §3.2 Tier 2 — Capability Ecosystem](../b2b-technical-whitepaper.md) |

## Context and Problem Statement

ADR-020 introduced a two-valued **documentation visibility** taxonomy: `public` (content lives in a public open-core repo) and `enterprise-private` (content lives in a private enterprise repo, number is publicly registered, content is not). That taxonomy is correct and remains binding for ADR files and architecturally-load-bearing documents.

It is, however, **insufficient for Tier 2 capability artefacts** — the `exeris-caps-*` repositories introduced by the 2026-05-12 whitepaper/HLA restructure. The cap layer is where most of the platform's commercial value lives:

- ~50 capabilities across seven layers (substrate aggregates, Gateway building blocks, Gateway policies, Service Boundary platform caps, Domain primitives, AI Abstraction Layer, Cross-cutting). See HLA §3.2.
- First-party Platform SKUs (`exeris-sku-api-gateway`, `exeris-sku-edge-proxy`, `exeris-sku-bot-blocker`, `exeris-sku-idp`, `exeris-sku-pim`, `exeris-sku-oms`, `exeris-sku-content-api`) are commercial-licensed compositions of these caps.

Tagging the whole cap layer as ADR-020 `public` would be inconsistent with the SKU monetization model — customers would consume the caps for free under the open-core licence and the SKU subscription would be reduced to a packaging fee. Tagging the whole cap layer as `enterprise-private` would hide the source code from prospective customers and forfeit the engineering-credibility benefit the platform earns by making its code visible. Neither extreme matches the commercial intent.

The cap layer therefore needs a **three-valued licensing dimension** that is orthogonal to (and does not replace) ADR-020's two-valued visibility taxonomy. This ADR formalises that dimension.

This ADR answers: **what license terms govern an `exeris-caps-*` repository's source code and runtime artefacts, and how does that licensing dimension relate to ADR-020 visibility?**

## 🏁 The Decision

**Every `exeris-caps-*` repository declares exactly one of three license values: `community`, `commercial`, or `enterprise-private`. This taxonomy is a separate axis from ADR-020 visibility and applies only to capability artefacts — not to ADR files, HLA / whitepaper documents, or kernel-tier code.**

| License value | Licence terms | Source visibility | Runtime use |
|:---|:---|:---|:---|
| `community` | Apache 2.0 or MIT (specified per-cap in the repo's `LICENSE` file) | Public — code visible in a public open-core repository | Free for any use, including production, without an Exeris subscription |
| `commercial` | Exeris Commercial License (source-available; BSL-style — see "License File" obligations below) | Public — code visible in a public open-core repository for audit, evaluation, and Code Detachment fork purposes | Production use requires an active Platform SKU subscription that includes the cap, or a Platform-tier subscription |
| `enterprise-private` | Exeris Enterprise License (closed-source) | Private — code lives in a private enterprise repository; binary artefacts ship through licensed channels | Available to Enterprise-tier subscribers only |

The 2026-05-12 cap inventory established the per-layer distribution: **3 `community` caps** (`exeris-caps-cors-policy`, `exeris-caps-i18n`, `exeris-caps-observability-bridge`), **46 `commercial` caps** (substrate aggregates, Gateway building blocks, remaining Gateway policies, SB platform caps except `i18n`, all domain primitives, all AI Abstraction caps), **1 `enterprise-private` cap** (`exeris-caps-bot-fingerprinting`, depends on a kernel-tier SPI extension shipping in `exeris-kernel-enterprise`). Total: 50 caps.

> **Inventory growth — 2026-08-16.** The paragraph above records the founding 2026-05-12 inventory and is left intact as that record. The inventory has since grown to **53 caps — 3 / 49 / 1** with three additions to layer 7, all `commercial`: `outbound-credentials`, `service-identity`, `idempotency` (HLA §3.2).
>
> The *taxonomy* is unchanged; only the counts moved. That distinction is the point of recording this as a note rather than editing the numbers in place: the three-valued decision is what this ADR decided, and a count is a fact about an inventory that lives in HLA §3.2. Future additions update HLA and [`cap-license-registry.md`](../cap-license-registry.md); this note is the pointer, not a second inventory.
>
> Worth stating plainly since it is the kind of thing that silently stops being true: the split is now **3 / 49 / 1**, and the registry asserts against that. If they disagree, one of the two documents moved without the other.

**Concrete obligations:**

1. **Every `exeris-caps-*` repository declares its licence value in three places.** A top-level `LICENSE` file with the canonical licence text; a `<license>` block in `pom.xml` (or equivalent build metadata); a `## License` section in `README.md` naming the licence value and pointing at the `LICENSE` file. A repository whose three sources disagree is a registry violation.
2. **The licence value is fixed at repository creation and is not retroactively changeable.** Promoting a cap from `commercial` to `community` is structurally an Apache-relicense and requires a tracked decision (typically a separate ADR). Demoting a `community` cap to `commercial` after publication is not permitted — the Apache grant is irrevocable for the released versions; new restrictive terms only attach to new caps.
3. **Tier 3 Platform SKUs ship as `commercial`-licensed compositions regardless of underlying cap licence mix.** An SKU's composition manifest, signature, and the right to run the named composition are commercial-licensed. The underlying caps retain their own licences — a `community` cap inside a `commercial` SKU keeps its Apache grant for direct downstream use.
4. **Code Detachment Fee (whitepaper §5.4) transfers ownership of `commercial`-licensed caps for the detached version under a perpetual-use grant.** It does not convert the licence to Apache; future versions of the same cap remain under the Exeris Commercial License. The detached customer retains rights to operate, modify, and fork the named version but cannot redistribute it under different licence terms.
5. **License taxonomy is orthogonal to ADR-020 visibility taxonomy.** A `community` cap is `public` (its source lives in a public repo). A `commercial` cap is also `public` (source-available is still source-visible). An `enterprise-private` cap is `enterprise-private` (private repo). The mapping is fixed:

   | License value | ADR-020 visibility |
   |:---|:---|
   | `community` | `public` |
   | `commercial` | `public` (source-available counts as public visibility for ADR-020 purposes) |
   | `enterprise-private` | `enterprise-private` |

   ADR-020 governs where documentation lives; this ADR governs the terms under which code may be used. The two dimensions never need to be conflated.

6. **CI verification (when cap repos materialise).** A platform-wide CI job will scan every `exeris-caps-*` repository for the three-source consistency required by obligation 1 and assert the declared licence value matches the registry table maintained in `exeris-docs/cap-license-registry.md` (planned). Until that registry and CI job land, periodic manual audits substitute, performed quarterly.

## Consequences

### ✅ Positive Outcomes

- **[+] SKU monetization model has a structural foundation.** The commercial value of platform SKUs is grounded in the licence of the underlying caps, not in obfuscation or repackaging. Prospective customers can audit `commercial` cap code and verify the engineering quality before subscribing.
- **[+] Three commodity `community` caps drive ecosystem adoption.** `cors-policy`, `i18n`, and `observability-bridge` are the kind of cross-cutting concerns where free reuse maximises ecosystem benefit. A non-paying user can compose them into their own non-Exeris stack and contribute back; the platform earns the marketing benefit.
- **[+] Source-available `commercial` licence preserves the engineering-credibility benefit of open code.** Customers can audit, fork, and evaluate `commercial` caps the same way they would inspect an open-source library — only their production-use terms differ. This is the GitLab EE / Elastic SSPL pattern, well-precedented in B2B SaaS infrastructure.
- **[+] One `enterprise-private` cap is the bound on closed-source surface.** `bot-fingerprinting` is closed because it depends on an `exeris-kernel-enterprise` SPI extension that is itself closed. The taxonomy makes the surface area of closed-source code visible and bounded.

### ⚠️ Trade-offs

- **[-] Three-value taxonomy is harder to communicate than ADR-020's two values.** Customers will need clear documentation distinguishing `commercial` from `community` — the whitepaper §3.2 and HLA §3.2 tables carry this load; a dedicated `cap-licensing-faq.md` is planned.
- **[-] Source-available `commercial` license enforcement depends on terms in the Exeris Commercial License document, not on a CI gate.** Customers can technically download `commercial` cap code from the public repo and use it in production without an SKU subscription — this is a licence violation, not a technical impossibility. Enforcement is contractual; the platform relies on legal recourse for material violations and on the Code Detachment Fee for legitimate forks.
- **[-] Pre-existing ADR-020 `enterprise-private` value is reused with a slightly different meaning at the cap layer.** ADR-020 `enterprise-private` says "documentation content is private". This ADR's `enterprise-private` says "code and licence are private to Enterprise-tier subscribers". The two meanings are aligned (both point at private repos), but the precise enforcement surface differs — documentation visibility vs. code/runtime usage rights. The conflation is intentional but worth flagging at review time when an artefact crosses both axes.

### 📋 What is NOT in scope

- **The text of the Exeris Commercial License itself.** This ADR commits to the BSL-style source-available shape; the canonical licence document lives outside this ADR (typically a `LICENSE-COMMERCIAL.md` file at the repository root of every `commercial`-licensed cap repo).
- **Per-cap pricing or SKU bundling.** This ADR is silent on commercial terms. The SKU pricing model lives in Exeris's internal business strategy registry (maintained outside this repository) and in customer-facing pricing pages.
- **License changes for kernel-tier code.** `exeris-kernel`, `exeris-kernel-enterprise`, `exeris-spring-runtime`, `exeris-sdk`, `exeris-tooling`, and other Tier 1 substrate repositories continue to ship under their existing licence terms per ADR-008 (Open-Core Strategy & Commoditization of Off-Heap TLS). This ADR does not retroactively re-licence those repositories.
- **Family product repository licensing.** `budgetHQ/` and any future Family product repositories are proprietary independent SaaS — they sit outside this taxonomy entirely per HLA §6.4.

## SKU Repository Source-Visibility Policy (2026-05-13 same-day amendment)

The body of this ADR formalises the three-value licensing taxonomy at the Tier 2 capability layer. The original "What is NOT in scope" carve-out for Platform SKU repositories left an unresolved question: **are `exeris-sku-*` repositories themselves publicly source-visible, or closed?** This amendment resolves that question on the same architectural foundation as the cap-layer taxonomy above.

### The Decision

**Platform SKU repositories ship as source-available public repositories under the Exeris Commercial License by default. The single principled exception is the Bot Blocker SKU family, which ships closed-source under the same licence on anti-abuse-security grounds.**

| SKU | Source visibility | License | Rationale |
|:---|:---|:---|:---|
| `exeris-sku-api-gateway` | **Source-available** (public repo) | Exeris Commercial License | Glass Box auditability; cap composition is the value, not opacity |
| `exeris-sku-edge-proxy` | **Source-available** (public repo) | Exeris Commercial License | Same as API Gateway |
| `exeris-sku-bot-blocker` | **Closed-source** (private repo) | Exeris Commercial License | Anti-abuse security: published detection logic helps adversaries circumvent the protection (JA3/JA4 fingerprinting, anomaly thresholds, threat intel integration) |
| `exeris-sku-idp` | **Source-available** (public repo) | Exeris Commercial License | Same as API Gateway; relevant for EU public-sector buyers under open-government IT mandates |
| `exeris-sku-pim` | **Source-available** (public repo) | Exeris Commercial License | Same as API Gateway |
| `exeris-sku-oms` | **Source-available** (public repo) | Exeris Commercial License | Same as API Gateway |
| `exeris-sku-content-api` | **Source-available** (public repo) | Exeris Commercial License | Same as API Gateway |
| Context-Centric CRM | N/A — cross-cutting cap (`exeris-caps-contact-graph`), not a standalone SKU repository | — | Covered by §3.2 cap licensing taxonomy |

### Rationale

Four reasons make source-available the right default at the SKU layer, beyond what already applies at the cap layer:

1. **Glass Box thesis applies at every audit layer.** The whitepaper's structural-efficiency claims are testable when customers can audit the kernel, the caps, AND the SKU composition glue. A customer who can audit Tier 1 and Tier 2 but not the actual product they subscribe to sees the audit story break exactly at the layer that matters most to procurement. Closing the SKU layer would weaken the architectural argument for the exact buyers the platform is targeting.
2. **The competitive moat is the kernel, not the SKU code.** Tier 3 SKU repositories contain composition manifests, integration glue, configuration logic, and SKU-specific extensions — most of which is mechanically derivable from the cap inventory in HLA §3.2. The defensible IP is the Tier 1 kernel (Enterprise tier especially) plus the Tier 2 cap implementations. Closing the SKU surface buys minimal competitive defence while costing real engineering-credibility value.
3. **Code Detachment Fee economics work better with source-available SKUs.** Whitepaper §5.4's IP-sovereignty story — "you can take the product with you if you outgrow the managed relationship" — is qualitatively stronger when "the product" includes the SKU source. Sophisticated enterprise buyers discount detachment optionality that excludes the SKU layer; they pay more for detachment that includes it.
4. **CNCF / EU grants alignment favours source-available.** The API Gateway and Service Boundary SKUs (especially IDP) are credible candidates for CNCF sandbox positioning or EU-funded reference-implementation inclusion. Both require source-available SKU repositories as a precondition. The Bot Blocker exception is consistent with this — anti-abuse infrastructure is not CNCF-positioned.

### The Bot Blocker exception, on principle

Bot Blocker is closed not because Exeris Systems is being cagey about commercial value but because **security-through-obscurity has a real and well-established role in anti-abuse infrastructure** that does not apply to functional infrastructure. Published TLS fingerprinting heuristics, anomaly detection thresholds, and rule-engine internals materially help adversaries circumvent the protection. Cloudflare, Akamai Bot Manager, and every serious bot-protection vendor maintains closed-source detection logic for exactly this reason. The closed-source posture is principled — it is named in the Bot Blocker repository's README and in customer-facing material so the inconsistency reads as commercially honest rather than concealed. The `exeris-caps-bot-fingerprinting` cap is already `enterprise-private` per the cap-layer taxonomy above for the same reason; the SKU repository simply follows the same principle to its conclusion.

### Concrete obligations (SKU layer)

7. **Every `exeris-sku-*` repository declares its source-visibility value in three places**, identical to the cap-layer obligation 1: `LICENSE` file (Exeris Commercial License for all SKUs regardless of visibility), `pom.xml` (or equivalent build metadata, including visibility marker), `README.md` (`## License` and `## Source visibility` sections naming the values and the rationale).
8. **The source-visibility decision is per-SKU at repository creation.** Promoting a closed-source SKU to source-available is a tracked decision (typically a separate ADR amendment). Demoting a source-available SKU to closed-source after publication is not permitted — once the source is public for a published version, the perpetual-use rights for that version cannot be retracted.
9. **Code Detachment Fee scope follows source-visibility.** For source-available SKUs, the Code Detachment Fee transfers ownership of the SKU source repository alongside the cap composition manifest and build artefacts (per cap-layer obligation 4). For the Bot Blocker SKU, the Code Detachment Fee transfers a perpetual binary-use licence plus the cap composition manifest, but NOT the closed security logic — the security logic loses commercial value the moment it is publicly readable. This distinction is named explicitly in whitepaper §5.4 to avoid a marketing-versus-reality gap.
10. **Source-available SKU licence enforcement.** Same trade-off as the cap layer: a customer can technically download source-available SKU code from the public repo and operate it in production without an active subscription. This is a contractual violation, not a technical impossibility. Three mitigations bound the leak rate: (a) matched-contract benchmark methodology and operational SLA guarantees are subscription-gated, materially reducing the value of unauthorised use; (b) lightweight subscription-validation telemetry through `exeris-caps-observability-bridge` operates without phone-home but requires an active subscription manifest at production scale; (c) the Code Detachment Fee provides a legitimate path for customers who genuinely want independent operation, priced well below the cost of legal recovery. The leak rate is therefore bounded, not unbounded; enterprise procurement constraints make the SMB-leakage segment commercially unimportant.

### Pricing-model framing (referenced, not normative here)

This ADR is silent on pricing. The pricing model that maps cleanly onto the three-tier architecture + source-availability posture is documented separately in Exeris's internal business strategy registry (maintained outside this repository). The intended shape, captured here only as a forward reference, is:

- **Free tier** — Community kernel + community-licensed caps, self-operated, any use. Ecosystem adoption surface.
- **Platform — Community subscription** — SKU compositions on Community kernel with operational guarantees, support, security updates, SLA. SMB and mid-market.
- **Platform — Enterprise subscription** — same SKU compositions on Enterprise kernel (`io_uring`, QUIC/H3, NUMA, slab pools, EnterpriseQuicTlsEngine), plus access to `enterprise-private` caps (Bot Blocker stack). Enterprise customers.
- **Managed cloud** — Exeris Systems operates the SKU as a managed service. Highest-tier hosted offering, usage-based pricing.
- **Code Detachment Fee** — one-time licence for perpetual ownership of the deployed SKU version, orthogonal to subscription tier, scoped per obligation 9 above based on the SKU's source-visibility value.

Comparable revenue models in source-available B2B infrastructure (GitLab, Confluent, Elastic, Hashicorp, MongoDB, Grafana Labs) demonstrate that source visibility does not constrain commercial revenue — operational guarantees, Enterprise-tier features, and managed hosting carry the revenue independently of source-licence terms. The pricing-model decision, drafted separately in Exeris's internal business strategy registry, will incorporate the specific tier pricing.

### Cross-references for this amendment

- HLA §3.3 "SKU Compositions" — buyer-facing summary of the Tier 3 SKU inventory; updated alongside this amendment with a Source-visibility column.
- Whitepaper §3.3 — same SKU inventory at buyer-detail level; updated alongside this amendment with a Source-visibility column.
- Whitepaper §5.4 "Vertical SKU Subscription" — Code Detachment Fee scope; updated alongside this amendment to distinguish source-available and closed-source SKU detachment scope per obligation 9.
- Whitepaper §6 "Sovereignty & IP Ownership" — IP-sovereignty thesis remains structurally intact; the source-available SKU default strengthens rather than weakens it.

## Cross-references

- ADR-020 (Open-Core Documentation Boundary & Cross-Repo Mirror Policy) — defines the two-valued documentation visibility taxonomy that this ADR is orthogonal to.
- ADR-008 (Open-Core Strategy & Commoditization of Off-Heap TLS) — establishes the Aggressive Open-Core pattern for the kernel tier that this ADR extends to the cap tier.
- ADR-024 (Capability Composition Model) — companion ADR that defines `@Provides` / `@Requires` / build-time validation for the same cap repositories.
- HLA §3.2 "Composable Capabilities" — the per-layer cap inventory and per-cap licence assignment that this ADR formalises.
- Whitepaper §3.2 "Tier 2 — Capability Ecosystem" — buyer-facing summary of the same taxonomy.
- Whitepaper §5.4 "Vertical SKU Subscription" + §6 "Sovereignty and IP Ownership" — Code Detachment Fee and detached-customer perpetual-use grant referenced in obligation 4.

## Engineering Protocol

This ADR is **descriptive at acceptance**: it codifies the licensing decision already documented in HLA §3.2 and whitepaper §3.2 (2026-05-12). It becomes prescriptive when cap repositories begin to materialise, expected from Q1 2027 per whitepaper §7 Track A.

Open follow-ups (tracked separately):

1. ~~**`cap-license-registry.md` in `exeris-docs/`**~~ — **Discharged 2026-08-16**, alongside the first `exeris-caps-*` repository as intended. [`cap-license-registry.md`](../cap-license-registry.md) carries all 53 caps with licence value, ADR-020 visibility, and implementation status, grouped by the seven layers.

   Two deliberate choices. The rows are **generated from HLA §3.2** rather than retyped — the inventory already exists there, and a hand-maintained second copy would drift on the first edit that touched only one of them; the registry says so and documents how to re-derive. And the **totals are asserted against this ADR's 3 / 49 / 1 split**, so a mismatch surfaces as a contradiction rather than as a quietly wrong row.

   The "single source of truth that CI jobs verify against" half is *not* yet realized: no CI job reads this file. That needs a home first — a check belongs where cap repositories are enumerated, and nothing enumerates them yet.
2. **`LICENSE-COMMERCIAL.md` canonical text** — the Exeris Commercial License document referenced by every `commercial`-licensed cap repo. Drafted before the first `commercial` cap repository ships. Lives at a stable URL referenced from each cap's `LICENSE` file.
3. **CI verification job (`exeris-docs` workflow or per-cap-repo)** — three-source consistency check per obligation 1 + registry-match check. Implementation owner: the platform team, scheduled alongside the Capability Composition Model codegen pipeline (ADR-024).
4. **`cap-licensing-faq.md`** — customer-facing FAQ distinguishing the three licence values, addressing the common confusion between `community` and `commercial`. Drafted alongside the first customer pilot that touches Tier 2 caps.

Until the registry and CI job land, the binding source-of-truth is the per-cap licence column in HLA §3.2 tables and whitepaper §3.2 cap inventory.
