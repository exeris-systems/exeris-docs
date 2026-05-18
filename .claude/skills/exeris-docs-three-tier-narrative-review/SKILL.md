---
name: exeris-docs-three-tier-narrative-review
description: Three-tier narrative review for exeris-docs. Use whenever Tier 1 / Tier 2 / Tier 3 / Family-product framing appears in an edit, or when claims about engine swap / cap manifest / SKU runtime / Spring Runtime consumers surface.
---

# Exeris Docs Three-Tier Narrative Review

## Purpose
Enforce the three-tier framing as the canonical structural narrative across HLA, whitepaper, ADRs, and any cross-cutting doc. Drift in this framing cascades — this skill catches it early.

## When to Use
- Any PR touching Tier 1 / Tier 2 / Tier 3 framing.
- Any PR mentioning the Enterprise engine swap.
- Any PR mentioning capability manifests / cap composition / cap-tier Wall.
- Any PR mentioning SKU runtime (Spring vs kernel-direct).
- Any PR mentioning Spring Runtime consumers.
- Any PR mentioning Family products.

## The Canonical Framing (per HLA §§2.2/3/4/5 + whitepaper §3)

**Tier 1 — Substrate**
- Exeris kernel (SPI + Core + Community/Enterprise drivers, ADR-007).
- `exeris-sdk` + `exeris-tooling` (build-time, ADR-015).
- Community driver = Maven modules inside `exeris-kernel/` (NOT a sibling repo).
- Enterprise driver (`exeris-kernel-enterprise`) = io_uring/IOCP, QUIC TLS, HTTP/3, slab pools, NUMA. Enterprise swap is **Tier 1 substrate driver swap** (Maven coordinate), NOT Tier 2 cap manifest swap. No `exeris-caps-quic-*` / `exeris-caps-io-uring-*`.
- `exeris-spring-runtime` = **independent Tier 1 product**. Two consumers: brownfield Spring customer apps + BudgetHQ. Platform itself does NOT depend on it.

**Tier 2 — Capability Ecosystem**
- ~50 `exeris-caps-*` repos across seven layers (substrate aggregates, Gateway building blocks, Gateway policies, Service Boundary platform caps, Domain primitives, AI Abstraction, Cross-cutting).
- Driver-agnostic by construction.
- Spring-free per cap-tier Wall (extension of ADR-006).

**Tier 3 — Vertical SaaS SKUs**
- First-party `exeris-sku-*` cap compositions.
- **All run kernel-direct** (no Spring Runtime).
- HTTP surface from `@ExerisDomain` + `@Action` + `rest-emission` codegen (ADR-015), NOT Spring `@RestController`.

**Family products** (separate axis, HLA §9)
- Commercially independent SaaS products built by Exeris Systems on the platform.
- Structurally distinct from Platform SKUs.
- BudgetHQ = first Family product, singular Spring-on-Exeris dogfooding case.
- **All future Family products will be pure-Exeris** on SDK + tooling.

## Required Inputs
- PR diff.
- Stated framing claims (which tier; engine swap nature; cap composition; SKU runtime; Spring Runtime consumers; Family product framing).

## Review Procedure
1. **Tier assignment** — confirm each mentioned component is placed in the correct tier.
2. **Enterprise engine swap framing** — must be Tier 1 substrate driver swap, not Tier 2 cap manifest swap.
3. **Community driver framing** — Maven module inside `exeris-kernel/`, NOT a sibling repo.
4. **`exeris-caps-quic-*` / `exeris-caps-io-uring-*`** — these do NOT exist; reject any mention.
5. **SKU runtime** — all Platform SKUs kernel-direct; no SKU claims Spring Runtime.
6. **Cap composition** — caps are driver-agnostic + Spring-free; no cap `@Requires: exeris-spring-runtime`.
7. **Spring Runtime consumers** — exactly two: brownfield apps + BudgetHQ. No "the platform uses Spring Runtime" framing.
8. **Family products** — separate axis from SKUs; BudgetHQ singular Spring-on-Exeris case; future Family products pure-Exeris.
9. **License + visibility** — three-value license (ADR-023) + two-value visibility (ADR-020), separate axes.
10. **Decision and report** — `APPROVE` / `CONDITIONAL` / `REJECT`.

## Decision Logic
- **APPROVE**: All framing points match canonical narrative.
- **CONDITIONAL**: Minor phrasing drift; propose canonical phrasing.
- **REJECT**: Tier misassignment; Enterprise swap framed as Tier 2; `exeris-caps-quic-*` / `exeris-caps-io-uring-*` mentioned; SKU claims Spring Runtime; cap `@Requires` Spring Runtime; "platform uses Spring Runtime"; Family products generic.

## Completion Criteria
- All 9 framing points audited.
- Verdict and remediation recorded.

## Review Output Template
1. **Scope analysed** (sections / claims touched)
2. **Tier assignment** (correct per component)
3. **Enterprise engine swap framing**
4. **Community driver framing**
5. **Non-existent caps mention** (yes / no)
6. **SKU runtime claims**
7. **Cap composition claims**
8. **Spring Runtime consumers**
9. **Family products framing**
10. **License + visibility taxonomy**
11. **Verdict** (`APPROVE` / `CONDITIONAL` / `REJECT`)
12. **Required actions** (precise and minimal)

## Non-Negotiable Rules
- Never approve Enterprise swap framed as Tier 2 cap manifest swap.
- Never approve `exeris-caps-quic-*` / `exeris-caps-io-uring-*` (they do not exist).
- Never approve SKU claiming Spring Runtime.
- Never approve cap `@Requires: exeris-spring-runtime`.
- Never approve "platform uses Spring Runtime" framing.
- Never approve "Family products run on Spring Runtime" framing.
