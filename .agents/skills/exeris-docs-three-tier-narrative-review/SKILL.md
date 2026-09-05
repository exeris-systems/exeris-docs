---
name: exeris-docs-three-tier-narrative-review
description: Three-tier narrative review for exeris-docs. Use whenever Tier 1 / Tier 2 / Tier 3 / Family-product framing appears in an edit, or when claims about engine swap / cap manifest / SKU runtime / Spring Runtime consumers surface.
---

# Exeris Docs Three-Tier Narrative Review

## Purpose
Enforce the three-tier framing as the canonical structural narrative across HLA,
whitepaper, ADRs, and any cross-cutting doc. Drift here cascades — catch it early.

**Single source.** The canonical framing (Tier 1 substrate / Tier 2 capability
ecosystem / Tier 3 SKUs / Family products as a separate axis) lives once in
`.agents/references/three-tier-architecture.md` and `.agents/references/capability-layer.md`, and in
`high-level-architecture.md` §§2.2/3/4/5 + whitepaper §3. This skill does NOT
restate it — read those sections for the authoritative wording, and use
`.agents/scripts/drift-sweep.sh` to locate the greppable failure modes (the
structural drift patterns #1,#3,#4,#5,#8 are exactly the tier-misassignment ones).

## When to Use
- Any PR touching Tier 1 / Tier 2 / Tier 3 framing.
- Any PR mentioning the Enterprise engine swap, capability manifests / cap composition / cap-tier Wall.
- Any PR mentioning SKU runtime (Spring vs kernel-direct) or Spring Runtime consumers.
- Any PR mentioning Family products.

## Required Inputs
- PR diff + the stated framing claims (which tier; engine-swap nature; cap composition; SKU runtime; Spring Runtime consumers; Family-product framing).

## Review Procedure
Check each claim against the canonical sections above. The load-bearing tests:
1. **Tier assignment** — each component placed in the correct tier.
2. **Enterprise engine swap** — Tier 1 substrate driver swap (Maven coordinate), NOT a Tier 2 cap-manifest swap.
3. **Community driver** — Maven module inside `exeris-kernel/`, not a sibling repo.
4. **Non-existent caps** — `exeris-caps-quic-*` / `exeris-caps-io-uring-*` do not exist (run `drift-sweep.sh`, pattern #3; confirm any hit is a negation).
5. **SKU runtime** — all Platform SKUs kernel-direct; no SKU claims Spring Runtime.
6. **Cap composition** — caps driver-agnostic + Spring-free; no cap `@Requires: exeris-spring-runtime`.
7. **Spring Runtime consumers** — exactly two (brownfield apps + BudgetHQ); platform does not depend on it.
8. **Family products** — separate axis from SKUs; BudgetHQ the singular Spring-on-Exeris case; future Family products pure-Exeris.
9. **License + visibility** — three-value license (ADR-023) and two-value visibility (ADR-020) kept as separate axes (run `taxonomy-check.sh`).
10. **Verdict** — `APPROVE` / `CONDITIONAL` / `REJECT`.

## Decision Logic
- **APPROVE**: every framing point matches the canonical sections.
- **CONDITIONAL**: minor phrasing drift — quote the canonical wording as the fix.
- **REJECT**: tier misassignment; Enterprise swap framed as Tier 2; non-existent caps asserted (not negated); SKU claims Spring Runtime; cap `@Requires` Spring Runtime; "platform uses Spring Runtime"; Family products framed generically.

## Review Output Template
1. **Scope analysed** (sections / claims touched).
2. **Per-point results** (1–9 above: pass / drift + canonical fix).
3. **Verdict** (`APPROVE` / `CONDITIONAL` / `REJECT`).
4. **Required actions** (precise and minimal).

## Non-Negotiable Rules
- Never approve the Enterprise swap framed as a Tier 2 cap-manifest swap.
- Never approve an *assertion* (not negation) of `exeris-caps-quic-*` / `exeris-caps-io-uring-*`.
- Never approve a SKU claiming Spring Runtime, or a cap `@Requires: exeris-spring-runtime`.
- Never approve "platform uses Spring Runtime" or "Family products run on Spring Runtime" framing.
- Never adjudicate from memory — read the canonical `.agents/references/` page and the HLA section it names.
