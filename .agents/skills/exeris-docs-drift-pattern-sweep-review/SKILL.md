---
name: exeris-docs-drift-pattern-sweep-review
description: Drift-pattern sweep review for exeris-docs. Use after any non-trivial HLA / whitepaper / large-doc edit to catch the 10 recurring drift patterns.
---

# Exeris Docs Drift-Pattern Sweep Review

## Purpose
Confirm the 10 recurring drift patterns are absent from edited files — and that
any correction was applied to **every** site, not just the one the PR touched.

**Single source.** The 10 patterns (why each is wrong) live once in
`.agents/policies/drift-patterns.md`. The greppable locators live once
in `.agents/scripts/drift-sweep.sh`. This skill does NOT restate them — it runs
the script and adjudicates the candidates.

## When to Use
- After any non-trivial `high-level-architecture.md` or `b2b-technical-whitepaper.md` edit.
- After any ADR edit that frames cross-tier or cross-repo structure.
- After any amendment to a record the page draws on.
- On request as a standalone audit pass.

## Required Inputs
- File(s) edited + an edit summary.

## Review Procedure
1. **Run the locator** on every edited file:
   `.agents/scripts/drift-sweep.sh <file>…`
2. **Adjudicate each candidate.** The script marks likely-correct negations with
   `⟵ (neg? verify)`. For each candidate decide: real drift, or a correct
   negation/mention? When unsure of canonical phrasing, read the relevant
   `.agents/policies/drift-patterns.md` (see" entry (numbered 1–10 to match the
   script's `#N`).
3. **Prioritise STRUCTURAL hits** (the script tags patterns 1,3,4,5,7,8) — they
   propagate downstream; review them first.
4. **Single-edit consistency.** For every confirmed drift, grep the *whole* doc
   (not just the diff) and confirm the same correction is applied at every site.
5. **Verdict:** `CLEAN` / `CORRECTIONS_REQUIRED` / `INVESTIGATION_REQUIRED`.

## Decision Logic
- **CLEAN**: script clean, or all candidates confirmed correct negations/mentions.
- **CORRECTIONS_REQUIRED**: ≥1 confirmed drift with a known canonical fix — emit a patch list.
- **INVESTIGATION_REQUIRED**: a candidate is ambiguous between drift and intentional framing — escalate to `exeris-docs-architect`.

## Review Output Template
1. **Scope** (files swept; script exit code).
2. **Adjudication** — per candidate: pattern `#N`, line, `drift` | `correct-negation` | `ambiguous`.
3. **Single-edit consistency check** (same correction applied everywhere?).
4. **Verdict** (`CLEAN` / `CORRECTIONS_REQUIRED` / `INVESTIGATION_REQUIRED`).
5. **Patch list** (precise corrections per confirmed drift).

## Non-Negotiable Rules
- Never declare CLEAN without running `drift-sweep.sh` on every edited file.
- Never resolve a candidate from memory when the canonical phrasing is in reach — read the entry in `.agents/policies/drift-patterns.md`.
- Never fix one site and leave another; confirmed drift is corrected at every site.
- Never silently drop an ambiguous candidate — escalate.
