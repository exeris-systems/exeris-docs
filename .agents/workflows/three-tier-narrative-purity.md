---
description: Audit a doc edit for three-tier narrative purity — Tier 1 substrate / Tier 2 capability ecosystem / Tier 3 SKUs / Family products as separate axis.
argument-hint: doc edit / new section / framing claim to audit
---

Audit the change below for three-tier narrative purity.

Change: $ARGUMENTS

The canonical framing (Tier 1 substrate / Tier 2 capability ecosystem / Tier 3
kernel-direct SKUs / Family products as a separate axis) lives once in
`.agents/references/three-tier-architecture.md` and `.agents/references/capability-layer.md`, and in
`high-level-architecture.md` §§2.2/3/4/5 + whitepaper §3. Read those for the
authoritative wording — this command does not restate them.

Steps:
1. If a file is in scope, run `.claude/scripts/drift-sweep.sh $ARGUMENTS` — the
   STRUCTURAL patterns (#1,#3,#4,#5,#8) are exactly the tier-misassignment ones —
   and `.claude/scripts/taxonomy-check.sh $ARGUMENTS` for the license/visibility axes.
2. Adjudicate each candidate against the canonical sections. Load-bearing checks:
   Enterprise engine swap = Tier 1 driver swap (not Tier 2 cap-manifest); SKUs
   kernel-direct (no SKU claims Spring Runtime); no cap `@Requires:
   exeris-spring-runtime`; Spring Runtime = independent Tier 1 with exactly two
   consumers (brownfield + BudgetHQ); Family products a separate axis, BudgetHQ
   the singular Spring-on-Exeris case.
3. Report verdict (`APPROVE` / `CONDITIONAL` / `REJECT`) + minimal correction,
   quoting the canonical wording as the fix.

For the full review procedure use the `exeris-docs-three-tier-narrative-review`
skill. This is the most load-bearing framing in the repo — drift here cascades.
