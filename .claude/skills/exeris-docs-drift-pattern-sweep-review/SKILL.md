---
name: exeris-docs-drift-pattern-sweep-review
description: Drift-pattern sweep review for exeris-docs. Use after any non-trivial HLA / whitepaper / large-doc edit to catch the 10 recurring drift patterns.
---

# Exeris Docs Drift-Pattern Sweep Review

## Purpose
Enforce: 10 recurring drift patterns are absent from edited files. Single-edit fixes leave inconsistencies; the same correction must apply to every site.

## When to Use
- After any non-trivial `high-level-architecture.md` edit.
- After any non-trivial `b2b-technical-whitepaper.md` edit.
- After any ADR edit that frames cross-tier or cross-repo structure.
- After any execution-plan amendment.
- On request as a standalone audit pass.

## Required Inputs
- File(s) edited.
- Edit summary.

## The 10 Patterns
1. **Postgres-only graph / "replacing Neo4j"** — wrong; kernel is dual-engine.
2. **`exeris-kernel-community` as sibling** — wrong; Maven module.
3. **`exeris-caps-quic-h3` / `exeris-caps-io-uring-transport`** — do NOT exist; Tier 1 substrate.
4. **SB-family SKUs "use Spring Runtime"** — wrong; kernel-direct.
5. **Cap `@Requires: exeris-spring-runtime`** — Wall violation.
6. **Two-value license taxonomy for caps** — wrong; three-value.
7. **`Config → Memory → Exceptions → {...}` bootstrap framing** — deprecated; use FOUNDATION / SERVICES / RUNTIME.
8. **"Family products run on Spring Runtime"** — wrong; only BudgetHQ.
9. **Spring Runtime "part of the platform stack"** — wrong; independent Tier 1.
10. **TRL-5+ for platform-aggregate** — currently TRL-3.

## Review Procedure
1. For each pattern, run a targeted `grep -nE` on edited file(s).
2. Report hits: line numbers + offending text.
3. For each hit, propose canonical-correct phrasing.
4. Check single-edit consistency — every site of the same pattern needs the same correction; don't fix one and leave others.
5. If hits on patterns 1, 3, 4, 5, 7, 8 (the structural ones) — flag as high-severity because they propagate downstream.
6. Decision: `CLEAN` / `CORRECTIONS_REQUIRED` / `INVESTIGATION_REQUIRED`.

## Decision Logic
- **CLEAN**: No hits on any pattern.
- **CORRECTIONS_REQUIRED**: Hits with known canonical correction; propose patch list.
- **INVESTIGATION_REQUIRED**: Hits ambiguous between drift and intentional framing — escalate to architect.

## Completion Criteria
- All 10 patterns grepped.
- Hits enumerated.
- Corrections proposed (or escalation requested).

## Review Output Template
1. **Scope** (file(s) swept)
2. **Per-pattern results**:
   - Pattern 1: hits / clean
   - Pattern 2: hits / clean
   - …
   - Pattern 10: hits / clean
3. **Single-edit consistency check** (same correction applied everywhere?)
4. **Verdict** (`CLEAN` / `CORRECTIONS_REQUIRED` / `INVESTIGATION_REQUIRED`)
5. **Patch list** (precise corrections per hit)

## Non-Negotiable Rules
- Never declare CLEAN without grepping every pattern.
- Never approve single-edit corrections that leave inconsistent sites.
- Never silently allow a pattern hit to remain (escalate if uncertain).
