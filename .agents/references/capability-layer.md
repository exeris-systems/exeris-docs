---
title: Reference — the capability layer
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Reference — the capability layer

Authoritative sources: [ADR-023](../../adr/ADR-023-capability-licensing-taxonomy.md) for the licence axis,
[ADR-024](../../adr/ADR-024-capability-composition-model.md) for composition, and
[`cap-license-registry.md`](../../cap-license-registry.md) for the per-capability table.

What follows is the short form an agent needs before editing a document that touches this
subject. It does not restate the source and is not authority: when they disagree, the source wins
and this file is the defect.

Caps participate in two orthogonal dimensions:

**Licensing taxonomy** (ADR-023, three values — orthogonal to ADR-020 visibility):
- `community` (Apache 2.0 / MIT) — 3 caps: `cors-policy`, `i18n`, `observability-bridge`
- `commercial` (Exeris Commercial License, source-available, BSL-style) — 50 caps (the bulk of Tier 2)
- `enterprise-private` (closed-source, Enterprise tier only) — 1 cap: `bot-fingerprinting`

**SKU repository source-visibility** (ADR-023 same-day amendment 2026-05-13):
- 6/7 Platform SKUs are **source-available** public repositories under Exeris Commercial License (API Gateway, Edge Proxy, IDP, PIM, OMS, Headless CMS API)
- 1/7 Platform SKU is **closed-source** on anti-abuse-security principle: Bot Blocker (the named exception, principled — published detection logic helps adversaries circumvent the protection)

**Composition model** (ADR-024, amended through 2026-07-21): caps declare `@Provides(Service, version)`, `@Requires(Service, versionRange, optional?)`, and a four-phase lifecycle (`initialize → ready → drain → terminate`). Compositions are DAGs of caps with no unresolved `@Requires`, no cycles, no version conflicts, no Wall violations. Validated at build time by the codegen pipeline (`exeris-tooling`, ADR-015), which stamps the manifest (validation stamp + content binding); the SDK-side composition runtime in the generated SKU bootstrap asserts the stamp after `KERNEL READY`, before any cap `initialize`. The kernel is **cap-blind** — no stamp check, no manifest reader, no cap-tier `Subsystem` registration. Manifest format is JSON (ADR-053).

**The Wall extends to caps.** No cap imports `org.springframework.*`, `io.netty.*`, `reactor.*`, `jakarta.servlet.*`, or any host-runtime-specific package. Spring `@RestController` paths in customer code or BudgetHQ depend on caps via `@Provides`; the dependency arrow never reverses. No cap `@Requires` `exeris-spring-runtime`. No SKU manifest layers it in.
