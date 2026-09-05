---
title: Claims and Evidence in Documentation
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Claims and Evidence in Documentation

Thin by design. The methodology — figure states, retraction register, citation canon, matched-contract gating — lives in `exeris-benchmarks/docs/CLAIMS.md` and is not restated here. This file only says what **documentation** must do with a number.

## Hard rules

1. **Any performance, footprint, throughput or cost figure outside `exeris-benchmarks/results/reports/` cites the report path and carries a figure state:** `citable`, `unartifacted`, or is absent. `retracted` and `forbidden` figures do not appear at all. `[L2 — HARD BLOCK on release gates and on `whitepaper`, `high-level-architecture`, README]`
2. **Consumers copy, never paraphrase** (CLAIMS.md rule). A number is quoted with its fence — the qualifier that makes it true (`matched-heap`, `n=6`, `light contract`). Heavy-contract throughput ratios are never quotable. `[L2]`
3. **Retractions travel.** When a `CLAIMS.md` entry is retracted, every document that quoted it is edited in the same PR or listed in the retraction entry as pending; the commit carries `Claim: <id>`. `[L1: commit trailer check when `CLAIMS.md` changes]`
4. **The registered drift patterns are lint.** The figures and phrasings withdrawn in the registered drift patterns (`.agents/policies/drift-patterns.md` in `exeris-docs`) (items 10–13) are Vale `existence` rules at **error** level — the one place Vale is allowed to fail a build. `[L1: vale Exeris.RetractedFigures]`
5. **Benchmark reports** (`type: benchmark-report`) carry the section set `CLAIMS.md` requires and a frontmatter `claims:` list of the IDs they support. `[L1: frontmatter_check.py]`

## Filter

- Does every number on this page have a path and a state?
- Is the qualifier next to the number, or three paragraphs away?
- Did you check the retraction register before quoting?
