---
description: Verify a new / amended ADR follows the registry discipline — number reserved first, filename pattern correct, location matches scope, visibility taxonomy correct, link stubs in affected repos.
argument-hint: ADR PR / new ADR file / index update to audit
---

Audit the ADR change below against registry discipline.

Change: $ARGUMENTS

The rules live once in `.agents/policies/adr-registry.md` (see" and
`adr/ADR-020-open-core-documentation-mirror-policy.md`; the mechanical checks live
in `.claude/scripts/`. Read those — this command does not restate the rule text.

Steps:
1. Run `.claude/scripts/adr-filename-check.sh <adr-file>` — verifies the filename
   matches `ADR-NNN-<lowercase-kebab-title>.md` AND that the number already has a
   row in `adr-index.md` (reserve-number-first). Exit 1 = real violation.
2. Run `.claude/scripts/taxonomy-check.sh <changed-files>` for visibility (ADR-020,
   two-valued; no live `public-staged`) and license (ADR-023, three-valued; not
   conflated with visibility).
3. Confirm by hand against `.agents/policies/adr-registry.md`:
   - Location matches scope (platform / per-repo / cross-repo / enterprise-private).
   - Cross-repo ADRs have `ADR-NNN.link.md` stubs in every affected repo.
   - Not a refactor-only change masquerading as an ADR (→ refactor-notes / PR description).
   - No `budgetHQ/` / `pbm/` portfolio entry in `adr-index.md`.
4. Report the minimal correction if discipline is at risk.

For the full procedure use the `exeris-docs-adr-registry-discipline-review` skill.
