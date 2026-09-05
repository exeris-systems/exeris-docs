---
title: Policy — editing the whitepaper and the HLA
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Policy — editing the whitepaper and the HLA

Strong defaults. Depart from one only with a stated reason in the pull request.

The whitepaper and the HLA are long and heavily cross-referenced. When editing them:

- Run a targeted grep before any edit (`grep -nE '<pattern>' high-level-architecture.md` etc.) to find every site that needs the same correction. Single-edit changes leave inconsistencies.
- After a non-trivial edit, sweep the edited file for every pattern in `.agents/policies/drift-patterns.md`.
- Don't silently delete superseded content — mark superseded paragraphs, don't rewrite them in place. The record-side form of the same discipline is [`standards/adr-conventions.md`](../../standards/adr-conventions.md) rule 7.
