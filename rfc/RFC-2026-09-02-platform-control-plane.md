# RFC-2026-09-02: The platform control plane — which operational concerns have no home in the three-tier model, where should they live, and what does that make public?

| Field             | Value                                                                 |
|:------------------|:----------------------------------------------------------------------|
| **Status**        | **DRAFT**                                                            |
| **Author(s)**     | arkstack-dev                                                          |
| **Date Opened**   | 2026-09-02                                                           |
| **Date Closed**   | —                                                                    |
| **Scope**         | platform / cross-repo (binds ADR-024's obligation 8c, the open-core boundary of `exeris-platform`, and the Studio/CMS split) |
| **Owning Repo**   | `exeris-docs` (an ecosystem-shape question, not a platform-internal one) |
| **Target ADR(s)** | TBD — one platform-scope ADR fixing the control-plane boundary, and an amendment to [ADR-024](../adr/ADR-024-capability-composition-model.md) disambiguating obligation 8c. Numbers reserved in [`adr-index.md`](../adr-index.md) only once this RFC is accepted. |
| **Affected Repos**| `exeris-docs` (this RFC, the eventual ADR, HLA §2/§6 alignment), `exeris-platform` (what stays in it and what leaves), a new private repository if Option C or D is taken. **Commercial terms — pricing, licence enforcement, IP-detachment mechanics — belong to the private business decision registry and are referenced here descriptively only.** |
| **Reviewers**     | —                                                                    |

## Question

The HLA is complete on the axis of *what runs* — kernel, ~50 capabilities across seven layers, seven Platform SKUs, the codegen pipeline, telemetry. It is close to silent on the axis of *who operates the platform, on whose behalf, and how a composition reaches a customer's infrastructure*. The word "control plane" appears in the HLA exactly once, as `exeris-caps-admin-control-plane` — the Gateway SKU's own runtime admin API, a different thing entirely.

**So: which operational concerns genuinely have no home today, do they constitute one plane or several unrelated gaps, where should that plane live — and what does the answer imply for the public/private boundary of `exeris-platform`?**

## Context

Three things make this the right moment rather than premature architecture.

**ADR-024 obligation 8c already nominates `exeris-platform` as "the deploy-time control plane", and the phrase is doing more work than it can bear.** Nothing in that repo consumes `exeris-sdk-composition-spec` today, so the obligation has never been tested against an implementation. Worse, "deploy-time" spans two very different things: *validating and previewing a composition* (design-time, harmless, and plausibly public) and *executing a deployment against a customer's cloud account* (operational, credential-bearing, and obviously not). The ADR does not distinguish them, so the boundary it draws is currently unfalsifiable.

**The founder's framing needs a structural criterion.** The working description of `exeris-platform` is "an integrator of components plus dogfooding — landing, login and so on", with strong differentiating surfaces (the bidirectional Studio) kept private. That is a criterion by example. Deciding per element whether something is "strong enough to keep private" does not scale and will drift, exactly as version pins written into prose drift.

**Concrete work is already blocked on it.** Authentication for Studio, and integrations with git and with AWS/GCP/Azure for deployment, have been raised as needed and have no home. Each is small on its own; together they are a plane, and building them one at a time into whichever repo is open at the time is how a plane gets built by accident.

## Investigation

### What is already decided, and must not be re-opened here

Two candidate "gaps" dissolve on inspection, and recording that is half the value of this RFC.

- **Licence enforcement is deliberately contractual, not technical.** [ADR-023](../adr/ADR-023-capability-licensing-taxonomy.md) states it twice — for caps (§Consequences) and for SKUs (§10) — and bounds the leak rate with three named mitigations rather than a licence server. Any proposal here that issues, validates or revokes a licence key contradicts an accepted ADR. Subscription *state* may still be operational data the platform holds; **enforcing** it is out of scope by decision.
- **Distribution and discovery are covered.** [RFC-2026-06-25](RFC-2026-06-25-publishable-unit-marketplace.md) already asked what a marketplace needs beyond ADR-024 and ADR-023 and found the net-new gap to be narrow (a thin catalog facet). This RFC must not re-derive it; it references that finding and stays out of the marketplace surface.

### What has no home, verified

| Concern | Nearest existing thing | Why it does not cover it |
|---|---|---|
| **Operator identity and tenancy** — who signs in to Studio, whose workspace this is, which subscription state applies | `exeris-caps-jwt-validation`, `exeris-caps-rbac-policy`, kernel `IdentityProvider` (ADR-040), `exeris-caps-service-identity` | Every one is runtime-facing: an end user of the *customer's* application, or a workload proving itself to another workload. None answers "who is this person to **us**". A cap runs inside a customer deployment; this question is asked before one exists. |
| **Delivery to customer infrastructure** — image build, provisioning, rollout, configuration and secrets, drift detection; the git and cloud-provider integrations that implies | ADR-024 obligation 8c ("deploy-time control plane"), ADR-053 (manifest format) | The manifest is the input to delivery, not delivery. Nothing describes what turns a validated manifest into a running SKU on infrastructure the platform does not own. |
| **Schema migration across a composition** | `KernelFlywayGenerator` in `exeris-codegen-java` | Generates migrations for one domain. A composition of 10–15 caps each carrying schema needs ordering and cross-cap compatibility. No ADR or RFC in the corpus addresses it (searched). |
| **Provenance of AI-assisted authorship** | `exeris-caps-ai-prompt-templating` (version-pinned prompts), ADR-025 (agent bridge) | The cap pins prompts at *runtime*. Nothing records, at design time, which sources an agent authored, against which model and prompt version. For a source-available platform whose commercial model includes a Code Detachment Fee, that is an audit question about what is being detached. |

### Constraints that bound any answer

- **ADR-024 obligation 9** — no stamp, manifest or capability awareness may be pushed into the kernel. A control plane must not become a reason to make the kernel cap-aware.
- **ADR-024, stamp is not a gate** — the composition stamp is a correctness/operability check and never a signature, attestation or licence gate. Entitlement may not ride on it.
- **ADR-020 / ADR-023** — the visibility and licence axes are orthogonal and already defined; this RFC applies them, it does not extend them.
- **ADR-025** — the agent bridge is read-only and barred from the write path. A control plane must not become a back door to it.
- **The Wall (ADR-006)** in spirit: a control plane sits above the runtime and must not smuggle operational concepts into the SPI.

## Options Considered

### Option A: No new plane — fold everything into `exeris-platform`

Keep one repository. Studio, LSP, backend, landing, login, deploy integrations all live together; sensitivity is managed by module boundaries rather than repository boundaries.

- **[+]** Simplest topology; one build, one release line; nothing to split.
- **[+]** Honest dogfooding surface: everything the platform does is visible.
- **[−]** Puts customer cloud credentials and subscription state in a public, source-available repository. The sensitivity argument is not about copying — it is about blast radius.
- **[−]** Contradicts the stated intent to keep differentiating surfaces private, without replacing it with a criterion.

### Option B: One private `exeris-control-plane` repository, everything operational moves

`exeris-platform` keeps LSP, landing and the dogfooding surface. A new private repository takes identity, tenancy, delivery, and the Studio surfaces judged differentiating.

- **[+]** Clean blast-radius boundary; the public repo holds nothing that touches customer infrastructure.
- **[+]** Matches the founder's instinct directly.
- **[−]** Draws the line by *sensitivity* alone, which leaves ADR-024 8c ambiguous: composition **validation** is design-time and harmless, yet it would move purely because it shares a name with deployment.
- **[−]** Risks hollowing out the public repo until the dogfooding claim is not demonstrable.

### Option C: Split on the time axis, not the sensitivity axis

Disambiguate ADR-024 8c into two planes. **Design/deploy-time** — manifest validation, `@Requires` graph checking, Wall enforcement, composition preview — stays public in `exeris-platform`, which is what obligation 8c can actually mean without credentials. **Operational** — operator identity and tenancy, subscription state, delivery execution, cloud and git credentials — is private.

- **[+]** Gives a structural criterion instead of per-element judgement: *does it hold a credential to, or act upon, infrastructure we do not own?*
- **[+]** Keeps the public repo genuinely demonstrative — validating and previewing a composition is the most legible thing the platform does.
- **[+]** Resolves an ambiguity in an accepted ADR rather than working around it.
- **[−]** Requires an ADR-024 amendment; obligation 8c has to be re-stated.
- **[−]** Some surfaces straddle the line (a deployment *preview* that reads real cloud state) and need a rule for the straddle.

### Option D: Build the operational plane as an Exeris SKU (composable with C or B)

Whatever its repository, construct the operational plane out of Tier 2 caps — `multi-tenancy`, `rbac-policy`, `audit-trail`, `usage-metering`, `outbound-credentials`, `workflow-engine` — rather than as bespoke code.

- **[+]** The strongest dogfooding claim available: the platform's own operations run as a composition, so every cap it uses is proven by the operator's own load before a customer sees it.
- **[+]** `outbound-credentials` already exists for exactly the cloud/git credential problem; not building a second mechanism is the whole point of a cap ecosystem.
- **[−]** Couples the operator's uptime to the cap layer's maturity; a bug in a cap is now an outage.
- **[−]** Private placement plus cap composition means some caps are exercised where nobody can read the result — the dogfooding benefit is real but partly unverifiable from outside.

## Recommendation

**Option C for placement, with Option D for construction.**

C gives the criterion the current framing lacks: *does this hold a credential to, or act upon, infrastructure we do not own?* Everything the founder named sorts itself under it without a judgement call — landing and the integrator surface are public, deploy integrations and login are not — and, usefully, the bidirectional Studio lands private not as a special case but because it is the differentiating product surface rather than the demonstration of one. Where a surface straddles (deployment preview reading live cloud state), the rule is the credential, not the intent: reading with a customer credential is operational.

D is what stops the private plane from becoming a second, unexamined stack. `outbound-credentials`, `multi-tenancy` and `usage-metering` exist precisely for these problems; an operator that reimplements them proves the cap layer is not sufficient for its own author.

Two things are explicitly **not** proposed: any technical licence enforcement (ADR-023 decided against it), and any marketplace or distribution surface (RFC-2026-06-25 owns that question).

## Open questions

1. Does the subscription-validation telemetry ADR-023 §10 mitigation (b) describes — "requires an active subscription manifest at production scale" — exist, or is it asserted? If asserted, it is a control-plane obligation and belongs in scope.
2. Where do CMS authoring surfaces sit? Content editing is not operational under the C criterion, but it is differentiating under the founder's.
3. Is cross-composition schema migration a control-plane concern or a tooling one? It has no credential, which puts it public under C — but it is delivery-shaped.
4. Does the AI-provenance record belong here at all, or in `exeris-tooling` beside the emission it describes?
