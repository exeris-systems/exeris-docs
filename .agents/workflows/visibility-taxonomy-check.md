---
description: Verify visibility taxonomy (ADR-020) is two-valued (`public` / `enterprise-private`) and not conflated with license taxonomy (ADR-023, three-valued).
argument-hint: ADR / doc / cap description that mentions visibility or license
---

Audit the visibility / license claim below.

Change: $ARGUMENTS

The authoritative values, the cap census, and the SKU source-visibility split
live once in `.agents/references/capability-layer.md`, and in `adr/ADR-020` (visibility)
and `adr/ADR-023` (license). Read those — this command does not restate the census.

Steps:
1. Run `.agents/scripts/taxonomy-check.sh $ARGUMENTS` (when a file is in scope).
   It flags `public-staged`, visibility/license contexts, and likely conflations,
   marking probable negations with `⟵ (neg? verify)`.
2. Adjudicate against the ADRs:
   - Visibility two-valued (`public` / `enterprise-private`); any live
     `public-staged` (not a "deprecated"-mention) is a hard reject.
   - License three-valued (`community` / `commercial` / `enterprise-private`);
     a two-value taxonomy for caps is wrong.
   - Visibility (where the doc lives) and license (how the code is licensed) are
     orthogonal axes — confirm they are not conflated.
3. Report the minimal correction if the taxonomy is at risk.

For ADR PRs, prefer the `exeris-docs-adr-registry-discipline-review` skill, which
now subsumes this check end-to-end.
