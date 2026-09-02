# RFC-2026-09-02: The platform control plane — which operational concerns have no home in the three-tier model, where should they live, and what does that make public?

| Field             | Value                                                                 |
|:------------------|:----------------------------------------------------------------------|
| **Status**        | **DRAFT**                                                            |
| **Author(s)**     | arkstack-dev                                                          |
| **Date Opened**   | 2026-09-02                                                           |
| **Date Closed**   | —                                                                    |
| **Scope**         | platform / cross-repo (binds ADR-024's obligation 8c, the open-core boundary of `exeris-platform`, and the Studio / CMS split) |
| **Owning Repo**   | `exeris-docs` (an ecosystem-shape question, not a platform-internal one) |
| **Target ADR(s)** | TBD — one platform-scope ADR fixing the control-plane boundary, plus an amendment to [ADR-024](../adr/ADR-024-capability-composition-model.md) disambiguating obligation 8c. Numbers reserved in [`adr-index.md`](../adr-index.md) only once this RFC is accepted. |
| **Affected Repos**| `exeris-docs` (this RFC, the eventual ADR, HLA §2/§6 alignment), `exeris-platform` (what stays and what leaves), a new private repository if the recommendation is adopted. **Commercial terms — pricing, licence enforcement, IP-detachment mechanics — belong to the private business decision registry and are referenced here descriptively only.** |
| **Reviewers**     | —                                                                    |

## Question

The HLA is complete on the axis of *what runs*: kernel, ~50 capabilities across seven layers, seven Platform SKUs, the codegen pipeline, telemetry. It is close to silent on the axis of *who operates the platform, on whose behalf, and how a composition reaches infrastructure we do not own*. The phrase "control plane" appears in the HLA exactly once, and it refers to `exeris-caps-admin-control-plane` — the Gateway SKU's own runtime admin API, which is a different thing.

**Which operational concerns genuinely have no home today, do they form one plane or several unrelated gaps, where should that plane live — and what does the answer make public?**

## Context

I am opening this now rather than later for three reasons.

**ADR-024 obligation 8c already nominates `exeris-platform` as "the deploy-time control plane", and I wrote that phrase to do more work than it can bear.** Nothing in that repository consumes `exeris-sdk-composition-spec` today, so the obligation has never been tested against an implementation. "Deploy-time" spans two unlike things: validating and previewing a composition, which is design-time and credential-free, and executing a deployment against a customer's cloud account, which is neither. The obligation does not distinguish them, so the boundary it draws is currently unfalsifiable — and I would rather fix that in an amendment than discover it in an implementation.

**My working rule for what stays public is a criterion by example, and that will not scale.** I have been describing `exeris-platform` as an integrator of components plus dogfooding — landing, login and so on — with the strong differentiating surfaces, the bidirectional Studio above all, kept private. Deciding element by element whether something is "strong enough to keep private" is a judgement I will make inconsistently across a year. I want a structural test instead.

**Concrete work is already blocked on this.** Authentication for Studio, and integrations with git and with AWS/GCP/Azure for deployment, are needed and have nowhere to live. Each is small alone. Together they are a plane, and building them one at a time into whichever repository happens to be open is how a plane gets built by accident.

## Investigation

### What is already decided, and is not re-opened here

Two candidates dissolve on inspection. I want that on the record, because the next person to look at this will otherwise re-derive them.

- **Licence enforcement is deliberately contractual, not technical.** [ADR-023](../adr/ADR-023-capability-licensing-taxonomy.md) says so twice — for caps in §Consequences, for SKUs in obligation 10 — and bounds the leak rate with three named mitigations rather than a licence server. Anything proposed here that issues, validates or revokes a licence key contradicts an accepted decision of mine. Subscription *state* may still be operational data the platform holds; **enforcing** it is out of scope by decision, not by omission.
- **Distribution and discovery are covered.** [RFC-2026-06-25](RFC-2026-06-25-publishable-unit-marketplace.md) already asked what a marketplace needs beyond ADR-024 and ADR-023, and found the net-new gap narrow — a thin catalog facet, nothing more. This RFC cites that finding and stays out of the marketplace surface entirely.

### What has no home

| Concern | Nearest existing thing | Why it does not cover it |
|:---|:---|:---|
| **Operator identity and tenancy** — who signs in to Studio, whose workspace this is, which subscription state applies | `exeris-caps-jwt-validation`, `exeris-caps-rbac-policy`, kernel `IdentityProvider` (ADR-040), `exeris-caps-service-identity` | Every one is runtime-facing: an end user of the *customer's* application, or a workload proving itself to another workload. None answers "who is this person to **us**". A cap runs inside a customer deployment; this question is asked before one exists. |
| **Delivery to customer infrastructure** — image build, provisioning, rollout, configuration and secrets, drift detection, and the git and cloud-provider integrations that implies | ADR-024 obligation 8c, ADR-053 (manifest format) | The manifest is the *input* to delivery, not delivery. Nothing describes what turns a validated manifest into a running SKU on infrastructure we do not own. |
| **Subscription-validation telemetry** — ADR-023 obligation 10 mitigation (b) promises it "operates without phone-home but requires an active subscription manifest at production scale" | ADR-023 itself; `exeris-caps-observability-bridge` | **Asserted, not built.** I checked. It is load-bearing for the commercial model — it is one of the three mitigations that bound the leak rate — and it currently has no owner. That makes it a control-plane obligation, not a cap detail. |
| **Schema migration across a composition** | `KernelFlywayGenerator` in `exeris-codegen-java` | Generates migrations for one domain. A composition of 10–15 caps each carrying schema needs ordering and cross-cap compatibility. I searched the corpus: no ADR or RFC addresses it. |
| **Provenance of AI-assisted authorship** | `exeris-caps-ai-prompt-templating` (version-pinned prompts), ADR-025 (agent bridge) | The cap pins prompts at *runtime*. Nothing records, at design time, which sources an agent authored, against which model and prompt version. For a source-available platform whose commercial model includes a Code Detachment Fee, that is an audit question about what is being detached. |

### Constraints that bound any answer

- **ADR-024 obligation 9** — no stamp, manifest or capability awareness may be pushed into the kernel. A control plane must not become the reason the kernel stops being cap-blind.
- **ADR-024, the stamp is not a gate** — the composition stamp is a correctness and operability check, never a signature, attestation or licence gate. Entitlement may not ride on it.
- **ADR-020 / ADR-023** — the visibility and licence axes are orthogonal and already defined. This RFC applies them; it does not extend them.
- **ADR-025** — the agent bridge is read-only and barred from the write path. A control plane must not become a back door into it.
- **The Wall (ADR-006)**, in spirit: a control plane sits above the runtime and must not smuggle operational concepts into the SPI.

## Options Considered

### Option A: No new plane — fold everything into `exeris-platform`

One repository. Studio, LSP, backend, landing, login and deploy integrations live together; sensitivity is managed by module boundaries rather than repository boundaries.

- **[+]** Simplest topology: one build, one release line, nothing to split.
- **[+]** The most honest dogfooding surface — everything the platform does is visible.
- **[−]** Puts customer cloud credentials and subscription state in a public, source-available repository. My objection is not that someone copies it; it is blast radius.
- **[−]** Discards the intent to keep differentiating surfaces private without replacing it with anything.

### Option B: One private `exeris-control-plane` repository; everything operational moves

`exeris-platform` keeps the LSP, the landing and the dogfooding surface. A new private repository takes identity, tenancy, delivery, and whichever Studio surfaces I judge differentiating.

- **[+]** Clean blast-radius boundary: the public repository holds nothing touching customer infrastructure.
- **[+]** Matches my instinct directly.
- **[−]** Draws the line by sensitivity alone, which leaves 8c ambiguous: composition *validation* is design-time and harmless, yet it would move simply because it shares a name with deployment.
- **[−]** Risks hollowing out the public repository until the dogfooding claim is no longer demonstrable.

### Option C: Split on the time axis, not the sensitivity axis

Disambiguate 8c into two planes. **Design and deploy-time** — manifest validation, `@Requires` graph checking, Wall enforcement, composition preview — stays public in `exeris-platform`, which is what 8c can mean without holding a credential. **Operational** — operator identity and tenancy, subscription state and its validation telemetry, delivery execution, cloud and git credentials — is private.

- **[+]** Yields a structural test in place of per-element judgement: *does this hold a credential to, or act upon, infrastructure we do not own?*
- **[+]** Keeps the public repository genuinely demonstrative. Validating and previewing a composition is the most legible thing the platform does, and it is exactly what a prospective customer should be able to read.
- **[+]** Resolves an ambiguity in an accepted ADR instead of working around it.
- **[−]** Requires an ADR-024 amendment; 8c has to be restated.
- **[−]** Some surfaces straddle — a deployment preview that reads live cloud state — and the straddle needs its own rule.

### Option D: Build the operational plane as an Exeris SKU (composable with B or C)

Whatever repository it lives in, construct the operational plane out of Tier 2 caps — `multi-tenancy`, `rbac-policy`, `audit-trail`, `usage-metering`, `outbound-credentials`, `workflow-engine` — rather than as bespoke code.

- **[+]** The strongest dogfooding claim available: our own operations run as a composition, so every cap is proven under the operator's load before a customer sees it.
- **[+]** `outbound-credentials` exists for exactly the cloud and git credential problem. Not building a second mechanism is the entire point of having a cap ecosystem.
- **[−]** Couples our uptime to the cap layer's maturity; a bug in a cap becomes an outage.
- **[−]** Private placement plus cap composition means some caps are exercised where nobody outside can read the result. The benefit is real but partly unverifiable from outside.

## Recommendation

**Option C for placement, with Option D for construction: split on the time axis, and build the private half out of Tier 2 caps.**

C gives me the test my current framing lacks — *does this hold a credential to, or act upon, infrastructure we do not own?* Everything I have been sorting by hand sorts itself under it. Landing and the integrator surface are public; login and the deploy integrations are not. Usefully, the bidirectional Studio lands private not as a special case I argued for, but because it is the differentiating product surface rather than the demonstration of one — which is the answer I wanted, arrived at by a rule instead of by preference. Where a surface straddles, the credential decides and not the intent: a deployment preview that reads live cloud state with a customer credential is operational, however read-only it looks.

D is what stops the private plane from quietly becoming a second, unexamined stack. `outbound-credentials`, `multi-tenancy` and `usage-metering` exist precisely for these problems. An operator that reimplements them alongside is evidence that the cap layer is not sufficient for its own author, and I would rather find that out on our own load than in a customer's.

I am proposing neither technical licence enforcement — ADR-023 decided against it and that decision stands — nor any marketplace or distribution surface, which RFC-2026-06-25 owns.

### Why not the alternatives?

- **Option A (one public repository)** — puts customer cloud credentials and subscription state in a source-available repository. Rejected on blast radius, not on copying.
- **Option B (split by sensitivity)** — right instinct, wrong axis. It leaves obligation 8c ambiguous and would move composition validation into the private half purely because "deploy" appears in both names, costing the public repository the one surface that best demonstrates the platform.
- **Option D alone (build as an SKU, placement unresolved)** — answers *how* without answering *where*, which is the question this RFC exists for. It is adopted as a companion, not an alternative.

### Risks of the recommendation

- **The straddle rule gets stretched.** "It only reads" is the argument that will be made for putting a credential-holding surface in the public half. The rule is the credential, not the verb; the ADR must say so in those words.
- **Coupling our uptime to cap maturity.** Option D is the right dogfooding, and it means a cap regression is an operator outage. Acceptable while we are the only operator; revisit before the first external Platform-tier customer.
- **Hollowing out the public repository anyway.** C is designed to prevent it, but if Studio's differentiating half and the operational plane both leave, what remains has to be enough to substantiate the dogfooding claim. That is a thing to measure after the split, not to assume.
- **An ADR-024 amendment reopens a settled document.** Obligation 8c has been cited as-is elsewhere; restating it means checking those citations rather than only editing the source.

## Decision Record

<Filled in when status reaches ACCEPTED / REJECTED / WITHDRAWN.>

| Field                | Value                                                              |
|:---------------------|:-------------------------------------------------------------------|
| **Outcome**          | TBD                                                                |
| **Date**             | TBD                                                                |
| **Resulting ADR(s)** | TBD — control-plane boundary ADR + ADR-024 amendment               |
| **Notes**            | TBD                                                                |

## Open questions / follow-ups

1. **CMS authoring surfaces.** Content editing holds no customer-infrastructure credential, so the C test puts it public — and it is nonetheless part of Studio, which I am keeping private. My reading is that it is a *separable* part rather than a contradiction: unlike the bidirectional model editor, it is achievable as a plain Angular surface, which suggests it may fit better as its own unit than as a Studio module. Worth deciding on fit before the split, not after.
2. **Where schema migration lands.** It looks like a control-plane concern to me: tooling is build-time, and ordering migrations across a composition is not. The one way it becomes a tooling question is if we decide cross-cap migration is itself build-time — which is the actual decision to make, and it should be made explicitly rather than inherited from whichever repository implements it first.
3. **AI-authorship provenance.** This is the hardest of the four and I do not have an answer. It does not look build-time either, which argues against `exeris-tooling` owning it by default. It may need its own RFC once the control-plane boundary is fixed, because where it belongs depends on what that boundary turns out to be.
