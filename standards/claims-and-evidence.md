---
title: Claims and Evidence in Documentation
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-16
---

# Claims and Evidence in Documentation

Thin by design. The methodology — figure states, retraction register, citation canon, matched-contract gating — lives in `exeris-benchmarks/docs/CLAIMS.md` and is not restated here. This file only says what **documentation** must do with a number.

## Hard rules

1. **Any performance, footprint, throughput or cost figure outside `exeris-benchmarks/results/reports/` cites the report path and carries a figure state:** `citable`, `unartifacted`, or is absent. `retracted` and `forbidden` figures do not appear at all. `[L2 — HARD BLOCK on release gates and on `whitepaper`, `high-level-architecture`, README]`
2. **Consumers copy, never paraphrase** (CLAIMS.md rule). A number is quoted with its fence — the qualifier that makes it true (`matched-heap`, `n=6`, `light contract`). Heavy-contract throughput ratios are never quotable. `[L2]`
3. **Retractions travel.** When a `CLAIMS.md` entry is retracted, every document that quoted it is edited in the same PR or listed in the retraction entry as pending; the commit carries `Claim: <id>`. `[L1: commit trailer check when `CLAIMS.md` changes]`
4. **The registered drift patterns are lint.** The figures and phrasings withdrawn in the registered drift patterns (`.agents/policies/drift-patterns.md` in `exeris-docs`) (items 10–13) are Vale `existence` rules at **error** level — the one place Vale is allowed to fail a build. `[L1: vale Exeris.RetractedFigures]`
5. **Benchmark reports** (`type: benchmark-report`) carry the section set `CLAIMS.md` requires and a frontmatter `claims:` list of the IDs they support. `[L1: frontmatter_check.py]`

6. **A record carries no figures at all** (ADR-085 §G.26a). An ADR and a standards page say what is decided and what it costs in kind; where the decision rests on a measurement they cite the report and do not repeat the number. This is narrower than rule 1 on purpose: rule 1 permits a cited figure anywhere, and a figure repeated in a record is a maintenance obligation nobody tracks — when the measurement moves, the record goes quietly false. The figures this rule removes are usually real ones; the page is what makes them wrong. `[L2]`
   - **Exception — a falsification threshold.** A `Reversed by:` clause names the evidence that would overturn the decision, and a threshold without a number is not falsifiable. It states a condition on future evidence, not a property of the system, and is written so a reader can tell the difference.
   - **RFC and Research documents are outside this rule.** Reporting measurements is what they are for.

## Filter

- Does every number on this page have a path and a state?
- Is the qualifier next to the number, or three paragraphs away?
- Did you check the retraction register before quoting?
