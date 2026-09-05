---
name: exeris-docs-adr-registry-discipline-review
description: ADR registry discipline review for exeris-docs. Use on every ADR PR — verifies number-first reservation, filename pattern, location-by-scope, visibility taxonomy, license taxonomy, and link stubs.
---

<!-- DO NOT EDIT. Generated from .agents/skills/exeris-docs-adr-registry-discipline-review/SKILL.md by the AGENTS.md adapter step
     (agents-md-schema.md rule 7). Edit the source, not this file. -->
# Exeris Docs ADR Registry Discipline Review

## Purpose
Enforce the single-namespace ADR discipline: number reserved first; filename
pattern correct; location matches scope; visibility two-valued; license a
separate three-valued axis; cross-repo link stubs present.

**Single source.** The rules (taxonomy values, location-by-scope, filename
pattern, the cap census) live once in `.agents/policies/adr-registry.md` (see" +
§ "Capability layer", and in `adr-index.md`, `adr/ADR-020`, `adr/ADR-023`. This
skill does NOT restate them — it runs the scripts and reads those sources.
(This skill subsumes the old standalone visibility/license check — there is no
separate visibility skill.)

## When to Use
- Any PR adding or amending an ADR, or changing rows in `adr-index.md`.
- Any PR adding / removing `ADR-NNN.link.md` stubs.
- Any claim about a cap's or SKU's visibility / license value.

## Required Inputs
- PR diff.
- Stated ADR scope (platform / per-repo / cross-repo / enterprise-private).
- Stated visibility (`public` / `enterprise-private`).
- For capability ADRs: the license claim (`community` / `commercial` / `enterprise-private`).

## Review Procedure
1. **Number-first** — `adr-index.md` row added BEFORE / WITH the content file.
   Run `.agents/scripts/adr-filename-check.sh <adr-file>` (checks the filename
   pattern AND that the number is already in the index). Content-without-index is a regression.
2. **Location-by-scope** — platform → `exeris-docs/adr/`; per-repo →
   `<repo>/docs/adr/`; cross-repo → owning repo + `ADR-NNN.link.md` stubs in every
   affected repo; enterprise-private → `<enterprise-repo>/docs/adr/` (number still
   publicly registered). Confirm against `.agents/policies/adr-registry.md`.
3. **Visibility + license** — run `.agents/scripts/taxonomy-check.sh` on the
   changed files; adjudicate candidates. Visibility two-valued (no live
   `public-staged`); license three-valued; the two axes not conflated. Read
   `adr/ADR-020` / `adr/ADR-023` if a value is in question.
4. **Refactor-only check** — rename / dep bump / cleanup → refuse promotion to
   ADR; route to `<repo>/docs/refactor-notes/` or the PR description.
5. **Portfolio check** — `budgetHQ/`, `pbm/` entries must NOT appear in `adr-index.md`.
6. **Link-stub coverage** — cross-repo ADRs have `ADR-NNN.link.md` in every affected repo.
7. **Verdict** — `APPROVE` / `CONDITIONAL` / `REJECT`.

## Decision Logic
- **APPROVE**: every discipline point passes.
- **CONDITIONAL**: one specific gap (missing stub, filename punctuation, visibility phrasing) — propose the correction.
- **REJECT**: number not reserved; wrong filename/location; live `public-staged`; two-value license taxonomy; refactor-only promoted; portfolio entry in registry.

## Review Output Template
1. **Scope analysed** (ADR / index changes).
2. **Number reservation + filename** (`adr-filename-check.sh` result).
3. **Location** (matches scope).
4. **Visibility + license** (`taxonomy-check.sh` adjudication; axes not conflated).
5. **Refactor-only / portfolio checks.**
6. **Link-stub coverage** (cross-repo).
7. **Verdict** (`APPROVE` / `CONDITIONAL` / `REJECT`).
8. **Required actions** (precise and minimal).

## Non-Negotiable Rules
- Never approve an ADR whose number wasn't reserved first, or whose filename drifts from `ADR-NNN-<lowercase-kebab>.md`.
- Never approve live `public-staged`, or a two-value license taxonomy for caps.
- Never approve a refactor-only change promoted to an ADR, or a portfolio entry (`budgetHQ`, `pbm`) in the registry.
- Never adjudicate a taxonomy value from memory — read `adr/ADR-020` / `adr/ADR-023`.
