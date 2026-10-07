---
title: "ADR-099: Compose Identity as a Tier 3 Platform SKU"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-10-07
slug: adr/ADR-099
---

# ADR-099: Compose Identity as a Tier 3 Platform SKU

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **ACCEPTED** |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-10-07 |
| **Scope**       | platform (adds one Service Boundary SKU, `exeris-sku-identity`, and six layer-5 capabilities to HLA §3.2 and §3.3; amends ADR-098 obligation 5) |
| **Owning Repo** | `exeris-docs` (an inventory and composition decision; the SKU and capability repositories do not exist yet) |
| **Driven By**   | [ADR-098](ADR-098-split-the-platform-control-plane-on-the-time-axis.md) obligation 5, which composes the private operational plane from Tier 2 capabilities "plus an operator identity capability" that has no specification |
| **Compliance**  | [HLA §3.2 and §3.3](../high-level-architecture.md), [ADR-024](ADR-024-capability-composition-model.md) (composition model), [ADR-023](ADR-023-capability-licensing-taxonomy.md) (licence axis and SKU source visibility), [ADR-006](ADR-006-spring-free-kernel-boundary.md) (the Wall), [ADR-088](ADR-088-cryptographic-license-manifest-and-offline-verification.md) and [ADR-089](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) (entitlement) |

## Context and Problem Statement

ADR-098 builds the private operational plane from six Tier 2 capabilities and "an operator identity
capability", which has no entry in [`cap-license-registry.md`](../cap-license-registry.md) and gets
one when it is specified. Identity is not one concern. It covers registration and email
verification, password login with lockout, password recovery and change, sessions with
refresh-token rotation and revocation, multi-factor authentication with recovery codes, login
through an external OAuth 2.0 / OIDC provider, issuing signed access tokens with a published key
set, and inviting people into a tenant.

Specified as one capability, all of that becomes one module with one release line. A consumer that
needs only token issuance, or only invitations, takes the whole of it, and replacing one part, such
as the multi-factor method, means forking the capability. That is the problem the capability layer
exists to remove: HLA §3.2 decomposes domain primitives below the SKU so that a capability can back several
compositions without a fork.

Identity also has more than one consumer. The control plane and the Console of ADR-098 need it for
Exeris's own operators. BudgetHQ's identity service already implements the same flows on Spring
Runtime, and it is a candidate to move onto the platform. And an identity service that a customer
runs inside their own boundary is a product in its own right.

This ADR answers: **what is the operator identity capability of ADR-098, and from what is it
built?**

## 🏁 The Decision

**Identity is a Tier 3 Platform SKU in the Service Boundary family, `exeris-sku-identity`, composed
of capabilities as every other SKU is. Its own logic lives in six new layer-5 domain-primitive
capabilities, each `commercial` and public, and the rest of the composition reuses existing
capabilities.**

The SKU is named **Identity**. It is not "IDP": in HLA §3.3 and §6.3, IDP names the Intelligent
Document Processing SKU (`exeris-sku-idp`).

**The six new capabilities** (HLA §3.2, layer 5):

| Cap | `@Provides` | `@Requires` | Licence |
|:---|:---|:---|:---|
| `exeris-caps-credential-store` | `CredentialStore` (password credentials per subject: set, verify, change; Argon2id PHC hashes; failed-attempt lockout), `AccountVerification` (single-use, hashed, expiring email-verification tokens), `CredentialRecovery` (forgot and reset through single-use hashed tokens) | `service-boundary-core`, `notification-dispatch`, kernel Security SPI (`KernelPasswordEncoder`), kernel Persistence SPI, `session-management` (optional), `audit-trail` (optional) | commercial |
| `exeris-caps-session-management` | `SessionStore` (one session per sign-in: list, revoke one, revoke all for a subject), `RefreshTokenRotation` (opaque single-use refresh tokens stored hashed, rotated on every use) | `service-boundary-core`, `token-issuer`, kernel Persistence SPI, `audit-trail` (optional) | commercial |
| `exeris-caps-mfa-totp` | `TotpFactorRegistry` (enrol with a secret and an `otpauth://` provisioning URI, confirm, disable), `TotpVerifier` (RFC 6238), `RecoveryCodes` (batches of single-use codes stored hashed), `MfaChallenge` (the short-lived step between the password and the second factor) | `service-boundary-core`, `credential-store`, kernel Persistence SPI, `audit-trail` (optional) | commercial |
| `exeris-caps-federated-login` | `FederatedLoginFlow` (OAuth 2.0 authorization code with PKCE, `state` and `nonce`; OIDC ID-token validation), `ExternalIdentityLink` (binds an issuer and subject pair to a local subject), `FederationProviderRegistry` (provider adapters, GitHub and Google first) | `service-boundary-core`, `outbound-credentials`, kernel HTTP SPI, kernel Security SPI (`TokenValidator`), kernel Persistence SPI | commercial |
| `exeris-caps-token-issuer` | `AccessTokenIssuer` (short-lived JWT access tokens signed with EdDSA over Ed25519), `JwksPublisher` (the JWKS document of the current and retiring public keys), `SigningKeyRotation` (key generations, overlap window, retirement) | `service-boundary-core`, kernel Persistence SPI, kernel Scheduling SPI | commercial |
| `exeris-caps-invitations` | `InvitationService` (issue, list, revoke and consume single-use hashed invitation tokens bound to a tenant, a role and an invitee address, with an expiry) | `service-boundary-core`, `multi-tenancy`, `rbac-policy`, `notification-dispatch`, kernel Persistence SPI, `audit-trail` (optional) | commercial |

**The SKU composition** (HLA §3.3, sorted by layer):

| Layer | Caps | Role in Identity |
|:---|:---|:---|
| 1 | `gateway-core`, `service-boundary-core` | `service-boundary-core` is the SB substrate. `gateway-core` resolves the `policy-chain` requirement below. |
| 2 | `policy-chain` | Resolves the `@Requires` that HLA §3.2 gives `rate-limiting` and `jwt-validation`. |
| 3 | `rate-limiting`, `jwt-validation` | Login, recovery and verification throttling; verification of the tokens Identity issues. |
| 4 | `multi-tenancy`, `audit-trail`, `rbac-policy`, `notification-dispatch`, `rest-emission`, `openapi-emission` | Tenant scope, the security audit log, role grants, verification and reset mail, the emitted HTTP surface and its OpenAPI description. |
| 5 | `credential-store`, `session-management`, `mfa-totp`, `federated-login`, `token-issuer`, `invitations` | The identity logic. |
| 7 | `outbound-credentials`, `observability-bridge` | OAuth client secrets; telemetry. |

Nineteen capabilities in all. The flows (register, verify email, log in, refresh, list and revoke sessions,
forgot, reset and change password, enrol and verify TOTP, use and regenerate recovery codes, invite
and accept) are `@Action` methods of the SKU's `@ExerisDomain` types, which orchestrate the
capabilities' `@Provides` services. The behavioural reference for those flows is BudgetHQ's
identity service. It runs on Spring Runtime, so it is a reference for logic only and contributes no
code, type or dependency.

**Why an SKU and not one capability.** Each concern is a capability that a composition can swap or
omit: a deployment without federation leaves out `federated-login`, and a second factor other than
TOTP is a new capability beside `mfa-totp` rather than a fork of it. The same capabilities are
reusable by other SKUs and by BudgetHQ: any Service Boundary SKU that needs sign-in composes
`credential-store`, `session-management` and `token-issuer` without taking the SKU. And the SKU is
sold standalone, as an identity service a customer runs on premises.

**Concrete obligations:**

1. **`exeris-sku-identity` is a Service Boundary SKU listed in HLA §3.3, §5 and §6.3**, with the
   composition above as its full manifest. It is `commercial`-licensed and source-available in a
   public repository under ADR-023's SKU Repository Source-Visibility Policy. It is not a
   closed-source exception of the Bot Blocker kind.
2. **The six capabilities are rows of HLA §3.2 layer 5 and of
   [`cap-license-registry.md`](../cap-license-registry.md)**, each `commercial`, public and
   `specified`, with the `@Provides` and `@Requires` above. A change to a capability's contract
   changes HLA §3.2 first and regenerates the registry.
3. **The manifest resolves every `@Requires`** (ADR-024, validity predicate 1). Every edge in the
   tables above resolves inside the composition. `rate-limiting` and `jwt-validation` keep the
   `@Requires` on `policy-chain` that HLA §3.2 gives them, so the manifest carries `policy-chain`
   and `gateway-core`.
4. **No Spring and no host runtime.** The SKU is kernel-direct: its HTTP surface is emitted by
   `rest-emission` and `openapi-emission` from `@ExerisDomain` types and `@Action` methods (ADR-015)
   and registered through `service-boundary-core`. No capability of this ADR imports
   `org.springframework.*` or any package the capability-tier Wall of ADR-024 forbids, and none
   `@Requires` `exeris-spring-runtime` (ADR-006).
5. **The capabilities code against kernel SPIs, never against a driver.** `credential-store` hashes
   through the kernel's `KernelPasswordEncoder` SPI. That SPI has no `ServiceLoader` lifecycle, so
   the SKU supplies the implementation, `exeris-kernel-community`'s `Argon2idPasswordEncoder` or
   another one, and no capability names a driver class. `federated-login` validates OIDC ID tokens
   through the kernel's `TokenValidator` SPI in the same way.
6. **The kernel gains nothing.** No kernel SPI gains a type for a session, a refresh token, an
   invitation, a TOTP factor or a federated provider, and the capabilities consume only the kernel
   SPIs that exist: Security (with the identity-provider SPI of ADR-040), Persistence, HTTP and
   Scheduling. The kernel stays capability-blind (ADR-024 obligation 9).
7. **Access tokens are EdDSA, and their verification is published.** `token-issuer` signs with
   Ed25519 and publishes its public keys as a JWKS document, keyed by `kid`, with a retired key kept
   for an overlap window after rotation. `jwt-validation`'s `JwtAdmissionPolicy` gains EdDSA
   signature verification against a JWKS document, with the algorithm pinned before the signature
   is checked. Its `@Provides` and `@Requires` are unchanged.
8. **Tokens and secrets are stored hashed or not at all.** Refresh tokens, verification, reset and
   invitation tokens, and recovery codes are persisted as hashes only; the raw value leaves the
   service once, to the user. A replayed refresh token is refused and revokes the session it
   belongs to. A completed password reset or change revokes every session of the subject.
9. **Subjects are per deployment; membership is per tenant.** Credential, session and factor
   records are keyed by subject. Tenant membership and role grants are tenant-scoped through
   `multi-tenancy` and `rbac-policy`, with row-level security at the data plane (ADR-012). Every
   administrative `@Action` (inviting, revoking an invitation, revoking another subject's sessions)
   carries a compile-time role requirement (ADR-014).
10. **Identity's token keys are not licence keys.** `token-issuer` signs access tokens only. It
    holds no ADR-088 issuer key, and the Identity SKU issues, validates and revokes no licence. The
    SKU is itself subject to entitlement like any SKU: its declared capabilities are checked
    against the entitled set at build time and at boot (ADR-089).
11. **The operator deployment is private; the source is not.** The deployment of the Identity SKU
    that Exeris runs for its own operators (its configuration, data and signing keys) belongs to the
    private operational plane under ADR-098 obligation 4. The SKU's and the capabilities' source is
    public and source-available like any other SKU's. A change that moves operator configuration or
    keys into a public repository fails ADR-098 obligation 1; publishing the source does not.

## Consequences

### ✅ Positive Outcomes

- **[+] ADR-098 obligation 5 names something specified.** The control plane and the Console compose
  a SKU whose capabilities have `@Provides`, `@Requires` and a licence, instead of a placeholder.
- **[+] Each concern is swappable.** A different second factor, a different federation protocol or
  a different token format is one capability, not a fork of an identity module.
- **[+] Sign-in is reusable below the SKU.** Any Service Boundary SKU can compose
  `credential-store`, `session-management` and `token-issuer` directly.
- **[+] A sellable product.** An on-premises identity service is a standalone SKU, with the same
  source visibility and detachment terms as the others.
- **[+] A migration target for BudgetHQ.** BudgetHQ's identity service implements the same flows
  and can move onto the SKU.

### ⚠️ Trade-offs

- **[-] Six more capabilities to build before the control plane has operator sign-in.** All six are
  `specified`, and ADR-098 obligation 5 still forbids writing their function into the plane in the
  meantime.
- **[-] A Service Boundary SKU carries the Gateway substrate.** Because `rate-limiting` and
  `jwt-validation` `@Requires` `policy-chain`, the Identity manifest includes `policy-chain` and
  `gateway-core`.
- **[-] Flows span capabilities.** Login touches `credential-store`, `mfa-totp`,
  `session-management` and `token-issuer`. The orchestration lives in the SKU's `@Action` methods,
  so it is SKU code that a second consumer of the same capabilities writes again.
- **[-] The inventory grows to 60 capabilities and eight SKUs**, and HLA §3.2, §3.3, §5, §6.2 and §6.3, the
  licence registry and the whitepaper move together.

### 📋 What is NOT in scope

- **SAML 2.0.** `federated-login` starts with OAuth 2.0 / OIDC (GitHub, Google). SAML is a later
  addition to it or a capability of its own.
- **SCIM provisioning**, **WebAuthn and passkeys**, and **directory synchronisation.** Each is a
  later capability.
- **Workload identity.** `exeris-caps-service-identity` (layer 7) stays the service-to-service axis;
  this ADR covers people.
- **Kernel-edge verification of Identity tokens.** The kernel's Community OIDC `TokenValidator`
  (`CommunityOidcTokenValidator`) pins RS256. Accepting EdDSA there is a kernel decision this ADR
  does not make.
- **BudgetHQ's migration.** Whether and when BudgetHQ moves onto the SKU is a BudgetHQ decision.
- **Licence issuance and commercial terms.** Governed by ADR-088 and the commercial policy.

### 🚫 Non-Goals

- **No identity concept in the kernel.** The kernel authenticates a request through its
  identity-provider SPI and nothing more.
- **No Spring-hosted identity.** The SKU does not run on `exeris-spring-runtime`, and BudgetHQ's
  identity service is not lifted into a capability.
- **No hosted identity service run by Exeris for customers.** The SKU is software a customer runs;
  Exeris runs it only for its own operators.

### ⚠️ Risks and Assumptions

- **Assumes:** every identity flow can be expressed as `@Action` methods over the six capabilities'
  `@Provides` services, emitted by `rest-emission` without a hand-written endpoint.
- **Assumes:** the kernel's `KernelPasswordEncoder` and `TokenValidator` SPIs stay stable at 1.0.
- **Reversed by:** a flow that cannot be orchestrated in the SKU without one capability calling
  another outside its declared `@Requires`, which would show the split is wrong; or a second
  consumer that needs all six capabilities and never one of them alone, which would remove the
  case for decomposing.
- **Risk:** the `policy-chain` edge makes Service Boundary SKUs drag the Gateway substrate whenever
  they compose a layer-3 policy. The first `exeris-sku-identity` scaffold measures what it costs.
- **Risk:** tokens issued by Identity do not authenticate at a kernel-direct edge that uses the
  Community OIDC provider until that provider verifies EdDSA. The control plane is the first
  consumer to hit it.

## Cross-references

- [ADR-098](ADR-098-split-the-platform-control-plane-on-the-time-axis.md) — the private operational
  plane; obligation 5 is amended by this ADR, and obligation 4 places the operator deployment.
- [ADR-024](ADR-024-capability-composition-model.md) — composition validity, the capability-tier Wall and
  obligation 9.
- [ADR-023](ADR-023-capability-licensing-taxonomy.md) — the `commercial` licence and the SKU
  Repository Source-Visibility Policy.
- [ADR-006](ADR-006-spring-free-kernel-boundary.md) — the Wall.
- [ADR-088](ADR-088-cryptographic-license-manifest-and-offline-verification.md) and
  [ADR-089](ADR-089-capability-entitlement-enforcement-and-runtime-contract.md) — the licence key
  Identity does not hold, and the entitlement check it is subject to.
- [ADR-012](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-012-security-trust-model-upgrade-for-resource-server-validation-and-fail-closed-runtime.md)
  — tenant isolation at the data plane.
- [ADR-014](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-014-requiresrole-compile-time-rbac-generation.md)
  — compile-time role requirements.
- [ADR-040](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-040-identity-provider-spi.md)
  — the kernel's identity-provider SPI, `TokenValidator` among it.
- [ADR-053](ADR-053-sku-composition-manifest-format.md) — the manifest format `exeris-sku-identity`
  writes.
- [`high-level-architecture.md`](../high-level-architecture.md) §3.2, §3.3, §5, §6.2, §6.3 — the
  inventory this ADR extends.
- [`cap-license-registry.md`](../cap-license-registry.md) — the six capabilities' licence and status.

## Engineering Protocol

1. **ADR-098 is amended in the same change.** Its obligation 5 composes the Identity SKU in place of
   an operator identity capability, and its registry row carries the amendment date.
2. **HLA §3.2, §3.3, §5, §6.2 and §6.3, `cap-license-registry.md` and the whitepaper's §3.2 and
   §3.3 change in the same change**, with the counts moving to 60 capabilities (3 / 56 / 1) and eight SKUs.
3. **The capability repositories are created when their code is written**, each as an
   `exeris-caps-*` repository whose licence is declared in the three places ADR-023 obligation 1
   names. `exeris-sku-identity` follows the ADR-053 manifest format.
4. **`exeris-caps-jwt-validation`** takes the EdDSA and JWKS verification of obligation 7 in its own
   pull request.
5. **Review-time assertion.** A change to an Identity capability that imports a driver class, a
   Spring type or another capability's internal package, or that persists a raw token, fails
   obligations 4, 5 or 8. Until a check exists, this is `[L2]`; the capability-tier Wall scan of the
   tooling covers the import half once the repositories exist.
