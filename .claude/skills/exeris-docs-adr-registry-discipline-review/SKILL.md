---
name: exeris-docs-adr-registry-discipline-review
description: ADR registry discipline review for exeris-docs. Use on every ADR PR — verifies number-first reservation, filename pattern, location-by-scope, visibility taxonomy, license taxonomy correctness, link stubs.
---

# Exeris Docs ADR Registry Discipline Review

## Purpose
Enforce the single-namespace ADR discipline: number reserved first; filename pattern correct; location matches scope; visibility taxonomy two-valued; license taxonomy separate three-valued axis; cross-repo link stubs present.

## When to Use
- Any PR adding a new ADR.
- Any PR amending an existing ADR.
- Any PR adding / changing rows in `adr-index.md` or `business-adr-index.md`.
- Any PR adding / removing `ADR-NNN.link.md` stubs.

## Required Inputs
- PR diff.
- Stated ADR scope (platform / per-repo / cross-repo / enterprise-private).
- Stated visibility (`public` / `enterprise-private`).
- For capability ADRs: license taxonomy claim (`community` / `commercial` / `enterprise-private`).

## Review Procedure
1. **Number reservation order** — `adr-index.md` row added BEFORE / WITH the ADR-content file. Content-without-index is a regression.
2. **Filename pattern** — `ADR-NNN-<lowercase-kebab-title>.md`; 3-digit zero-padded; `&` → `and`; other punctuation dropped.
3. **Location-by-scope**:
   - Platform-scope → `exeris-docs/adr/`
   - Per-repo → `<owning-repo>/docs/adr/`
   - Cross-repo → owning repo's `docs/adr/` + `ADR-NNN.link.md` stubs in every affected repo
   - Enterprise-private → `<enterprise-repo>/docs/adr/` (number publicly registered)
4. **Visibility audit** — `public` or `enterprise-private`. `public-staged` reintroduction → hard reject.
5. **License audit** (capability artefacts only): three-valued — `community` / `commercial` / `enterprise-private`. Two-value taxonomy → hard reject. Not conflated with visibility → check.
6. **Refactor-only check** — if the change is a rename / dep bump / cleanup, refuse promotion to ADR; route to `<repo>/docs/refactor-notes/` or PR description.
7. **Portfolio entry check** — `budgetHQ/`, `pbm/` entries must NOT appear in `adr-index.md`.
8. **Link stub coverage** — cross-repo ADRs have `ADR-NNN.link.md` in every affected repo.
9. **Decision and report** — `APPROVE` / `CONDITIONAL` / `REJECT`.

## Decision Logic
- **APPROVE**: All discipline points pass.
- **CONDITIONAL**: One specific gap (missing link stub, filename punctuation, visibility phrasing) — propose the correction.
- **REJECT**: Number not reserved; filename pattern wrong; wrong location; `public-staged` reintroduction; two-value license taxonomy; refactor-only promoted; portfolio entry in registry.

## Completion Criteria
- All 8 procedure points audited.
- Verdict and remediation recorded.

## Review Output Template
1. **Scope analysed** (ADR / index changes touched)
2. **Number reservation** (order correct)
3. **Filename pattern**
4. **Location** (matches scope)
5. **Visibility taxonomy** (correct / `public-staged` reintroduced)
6. **License taxonomy** (if applicable; three-valued; not conflated)
7. **Refactor-only check**
8. **Portfolio entry check**
9. **Link stub coverage** (cross-repo)
10. **Verdict** (`APPROVE` / `CONDITIONAL` / `REJECT`)
11. **Required actions** (precise and minimal)

## Non-Negotiable Rules
- Never approve an ADR whose number wasn't reserved first.
- Never approve filename punctuation drift.
- Never approve `public-staged` reintroduction.
- Never approve two-value license taxonomy.
- Never approve refactor-only changes promoted to ADRs.
- Never approve portfolio entries (`budgetHQ`, `pbm`) in the registry.
