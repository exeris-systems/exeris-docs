---
title: "ADR-098: Split the Platform Control Plane on the Time Axis"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-10-07
slug: adr/ADR-098
---

# ADR-098: Split the Platform Control Plane on the Time Axis

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **ACCEPTED** |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-10-07 |
| **Scope**       | platform / cross-repo (`exeris-platform` keeps the validation and preview plane; a private repository, not yet created, takes the operational plane; restates ADR-024 obligation 8c) |
| **Owning Repo** | `exeris-docs` (an ecosystem-shape decision; neither plane's repository holds it) |
| **Driven By**   | [RFC-2026-09-02](../rfc/RFC-2026-09-02-platform-control-plane.md) (accepted 2026-10-07 — Option C for placement, Option D for construction); the amendment it requires to [ADR-024](ADR-024-capability-composition-model.md) obligation 8c |
| **Compliance**  | [ADR-024](ADR-024-capability-composition-model.md) (composition model; obligation 9 and the stamp-is-not-a-gate rule), [ADR-006](ADR-006-spring-free-kernel-boundary.md) (the Wall), [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) and [ADR-023](ADR-023-capability-licensing-taxonomy.md) (visibility and licence axes), [ADR-025](https://github.com/exeris-systems/exeris-ai-bridge/blob/main/docs/adr/ADR-025-ai-agent-bridge.md) (the agent bridge reads, never writes), [ADR-088](ADR-088-cryptographic-license-manifest-and-offline-verification.md) and [ADR-089](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) (entitlement verification) |

## Context and Problem Statement

The three-tier model says what runs: kernel, capabilities, SKUs, the codegen pipeline, telemetry.
It does not say who operates the platform, on whose behalf, or how a composition reaches
infrastructure Exeris does not own. Several concerns sit in that gap with no home: who an operator
is to Exeris and which tenancy and subscription state applies to them; delivery to customer
infrastructure, with the git and cloud-provider integrations it implies; and the subscription
validation telemetry that ADR-023 obligation 10 names as one of its mitigations without assigning
an owner.

ADR-024 obligation 8c named `exeris-platform` "the deploy-time control plane". "Deploy-time" covers
two unlike things. Validating and previewing a composition happens at design time and needs no
credential. Executing a deployment against a customer's cloud account needs both a credential and
a target Exeris does not own. Because 8c does not separate them, nobody can tell whether a given
change violates it, and the boundary of the public repository was being settled one surface at a
time by judgement.

Doing nothing has a concrete cost. Operator authentication and the git and cloud integrations are
needed now. Built one by one into whichever repository is open, they become a control plane by
accident, and customer credentials end up in a source-available repository.

This ADR answers: **where does the line between the public platform and the private operational
plane fall, by what test is a surface placed on one side of it, and from what is the private side
built?**

## 🏁 The Decision

**The control plane is split on the time axis. Design- and deploy-time validation and preview stay
public in `exeris-platform`. Everything that holds a credential to, or acts upon, infrastructure
Exeris does not own forms a private operational plane, and that plane is composed from Tier 2
capabilities rather than written as a separate stack.**

The placement test is one question: *does this hold a credential to, or act upon, infrastructure we
do not own?* A surface for which the answer is yes is operational and private. The test replaces
deciding surface by surface which parts are differentiating enough to keep private.

**Concrete obligations:**

1. **The structural test places every surface.** A module, endpoint, job or user interface that
   holds a credential to infrastructure Exeris does not own, or that acts upon such infrastructure,
   belongs to the private operational plane. It is not committed to `exeris-platform` or to any
   other public repository. A review answers this as a yes/no question about the change.
2. **The credential decides, not the verb.** A surface that reads live customer state with a
   customer credential is operational, however read-only it looks. A deployment preview that
   queries a customer's cloud account is private. A preview computed from the workspace and the
   build artefacts alone is public. "It only reads" is not a reason to put a surface in the public
   half.
3. **The public plane is `exeris-platform`, and it holds no credential.** It is where manifests are
   validated, the `@Requires` graph is checked, the Wall is enforced and a composition is previewed,
   consuming the composition library of ADR-024 (`exeris-sdk-composition-spec` and
   `-runtime`). These are served through the LSP server and its protocol, which stay public. Every
   input of this plane is a workspace, a source tree or a build artefact. None is a live system.
4. **The private operational plane holds, by enumeration:** operator identity and tenancy;
   subscription state and its validation telemetry; delivery execution (image build, provisioning,
   rollout, configuration and secrets, drift detection); git and cloud-provider credentials; and the
   deploy agent that acts on a customer's infrastructure. Subscription state goes with the plane
   because the plane reads it before it acts on a customer's behalf.
5. **The private plane is an Exeris composition.** It is built from `exeris-caps-multi-tenancy`,
   `exeris-caps-rbac-policy`, `exeris-caps-audit-trail`, `exeris-caps-usage-metering`,
   `exeris-caps-outbound-credentials` and `exeris-caps-workflow-engine`, plus an operator identity
   capability. That capability has no entry in [`cap-license-registry.md`](../cap-license-registry.md)
   yet, and gets its entry and licence under ADR-023 when it is specified. A private-plane module that
   reimplements what one of these capabilities provides, such as a second credential store, tenancy
   model, audit log, metering path or workflow engine, violates this obligation. A gap in a
   capability is fixed in the capability.
6. **Frontends follow the same line.** The public marketing site is public. The Console UI (the
   operator-facing interface of the control plane), the control plane itself, and the Studio
   product surface are private. Studio is a closed consumer of the public LSP server. It is private
   because it is the product surface and not the demonstration of one, and `exeris-platform` holds
   no Studio module.
7. **Constraints the private plane may not cross:**
   - a. **The kernel stays capability-blind.** The control plane adds no type, reader or check to any kernel
     package (ADR-024 obligation 9), and no kernel SPI gains an operational concept such as an
     operator, a tenant of Exeris, a deployment or a cloud account. That is ADR-006 applied above
     the runtime.
   - b. **The stamp is not a gate.** The control plane never reads the composition stamp of ADR-024
     obligation 7 as an entitlement or as permission to deploy. The stamp is a correctness check.
     Entitlement is carried by the licence manifest of ADR-088 and ADR-089 and by nothing the
     control plane adds.
   - c. **Nothing waits on the control plane online.** No deployment's build or boot depends on a
     verdict from the control plane at run time (ADR-089 obligation 3, zero phone-home). Validation
     telemetry reaches the plane only through forwarding the customer has configured (ADR-089
     obligation 5).
   - d. **The agent bridge stays read-only.** `exeris-ai-bridge` may consume the public validation
     and preview surface, read-only, as ADR-025 allows. It holds no control-plane credential, and no
     control-plane endpoint that writes is reachable through it.
   - e. **The two axes stay orthogonal.** Placement in the private plane is a visibility decision
     under ADR-020. It does not change any capability's licence under ADR-023. Public documents
     refer to the private repository by name with a *(content private)* marker and never link into
     it.

## Consequences

### ✅ Positive Outcomes

- **[+] One test instead of a running judgement.** Every surface sorts under the credential
  question, so the boundary of the public repository stops depending on case-by-case calls.
- **[+] The public repository stays demonstrative.** Validating and previewing a composition is
  the most legible thing the platform does, and it stays readable by a prospective customer.
- **[+] Customer credentials never enter a source-available repository.** The blast radius of the
  public repository holds no access to infrastructure Exeris does not own.
- **[+] The operator runs on the capability layer.** Exeris's own operations run as a composition,
  so every capability it uses is exercised under operator load before a customer depends on it.
- **[+] ADR-024 obligation 8c becomes testable.** It is restated rather than worked around.

### ⚠️ Trade-offs

- **[-] Operator uptime is coupled to capability maturity.** A regression in one of the six
  capabilities becomes an operator outage. This is acceptable while Exeris is the only operator.
- **[-] Some capability behaviour is exercised where nobody outside can read the result.** The
  dogfooding benefit is real but partly unverifiable from outside, because the plane is private.
- **[-] The private plane waits on capabilities that are `specified`, not built.** All six are
  `specified` in `cap-license-registry.md`, and obligation 5 forbids the shortcut of writing their
  function into the plane in the meantime.
- **[-] ADR-024 is amended again**, and its obligation 8c is cited in other repositories, which
  each owe an update.

### 📋 What is NOT in scope

- **Licence enforcement.** This ADR neither adds nor moves any licence mechanism. The current
  position is set elsewhere. ADR-089 checks entitlement at build time in `exeris-tooling`
  (`Capabilities_declared ⊆ Capabilities_entitled` on production targets) and at boot in the kernel
  bootstrap, ahead of FOUNDATION, with `HARD` / `SOFT` / `AUDIT` levels. ADR-088 fixes the signed,
  offline-verified `license-manifest.json`. ADR-023's contractual terms remain the backstop for
  source-available code, whose checks a fork can remove. The control plane issues, validates and
  revokes nothing at run time.
- **Licence issuance and custody of the issuer's signing key.** They are governed by ADR-088 and the
  commercial policy. The structural test does not decide them, because the issuer key acts upon no
  customer's infrastructure.
- **Marketplace, distribution and discovery.** [RFC-2026-06-25](../rfc/RFC-2026-06-25-publishable-unit-marketplace.md)
  owns them.
- **Commercial terms**, referenced descriptively only. They belong to the private business
  decision registry.
- **Whether CMS authoring ships as its own unit or as a Studio module**, where cross-composition
  schema migration lands, and provenance of AI-assisted authorship. These are the RFC's open
  questions and stay open.

### 🚫 Non-Goals

- **No licence server.** The private plane is not an online authority that a deployment consults.
- **No second stack.** The private plane does not grow its own tenancy, credential, audit or
  workflow machinery beside the capability layer.
- **No hollowing-out by default.** Moving surfaces out of `exeris-platform` is not a goal. Only what
  fails the test moves.

### ⚠️ Risks and Assumptions

- **Assumes:** a useful composition preview can be computed from the workspace and build artefacts
  alone, without live customer state.
- **Assumes:** the six capabilities can carry the operator's load once built.
- **Reversed by:** a preview that cannot be useful without a customer credential, which would leave
  the public plane nothing worth demonstrating and reopen Option B; or a capability that cannot carry
  the operator's load without a bespoke replacement, which would reopen Option D. Revisit the second
  before the first external Platform-tier customer.
- **Risk:** the straddle rule gets stretched. "It only reads" is the argument that will be made for
  putting a credential-holding surface in the public half. Obligation 2 is worded so that a reviewer
  can refuse it, and the reviewer of a change to `exeris-platform` is the one who notices first.
- **Risk:** what remains public is not enough to substantiate the dogfooding claim once Studio and
  the operational plane are both private. This is measured after the split, not assumed.

## Cross-references

- [RFC-2026-09-02](../rfc/RFC-2026-09-02-platform-control-plane.md) — the options, the investigation
  and the recommendation this ADR records.
- [ADR-024](ADR-024-capability-composition-model.md) — obligation 8c is restated as 8c′ by its
  2026-10-07 amendment; obligations 7 and 9 bound this ADR.
- [ADR-023](ADR-023-capability-licensing-taxonomy.md) — the licence axis and obligation 10's
  mitigations, one of which is the validation telemetry this ADR gives an owner.
- [ADR-088](ADR-088-cryptographic-license-manifest-and-offline-verification.md) and
  [ADR-089](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) — where entitlement
  is verified, and the zero-phone-home and customer-controlled telemetry obligations the control plane
  inherits.
- [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) — the visibility taxonomy and the
  *(content private)* marker.
- [ADR-025](https://github.com/exeris-systems/exeris-ai-bridge/blob/main/docs/adr/ADR-025-ai-agent-bridge.md)
  — the read-only bridge.
- [ADR-006](ADR-006-spring-free-kernel-boundary.md) — the Wall.
- [ADR-053](ADR-053-sku-composition-manifest-format.md) — the manifest format the public plane
  validates.
- [`cap-license-registry.md`](../cap-license-registry.md) — the state of the six capabilities.

## Engineering Protocol

1. **ADR-024 is amended in the same change.** Obligation 8c′ replaces 8c, and the registry row
   carries the amendment date.
2. **`exeris-platform` takes a stub and three updates, in its own pull request:**
   `docs/adr/ADR-098.link.md`, and `docs/adr/ADR-024.link.md`, `README.md` and
   `.agents/policies/composition-runtime-placement.md`, which cite obligation 8c as "the deploy-time
   control plane". The removal of Studio's frontend and backend modules from `exeris-platform` is
   commit `3703b21` on its branch `chore/remove-studio-from-open-core`, not yet on `main`.
   Obligation 6 holds once that branch merges.
3. **The private repository** (working name `exeris-control-plane`) is created when the first
   operational code is written, not before. It takes its *(private repo)* marker in the
   cross-repo-stubs table of `adr-index.md` then.
4. **Review-time assertion.** A change to `exeris-platform` that adds a credential, a cloud or git
   client acting on an account Exeris does not own, or an operator account fails obligation 1. Until a
   check exists, this is `[L2]`.
5. **Documentation drift.** `high-level-architecture.md` still places Studio in `exeris-platform`
   (the C4 container diagram, the note under it and the open-core split table). It is aligned under
   [`editing-large-documents.md`](../.agents/policies/editing-large-documents.md) in a follow-up.
