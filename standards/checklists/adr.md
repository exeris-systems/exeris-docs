---
title: ADR Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# ADR Checklist — before PROPOSED becomes ACCEPTED

1. **Number.** Reserved in `adr-index.md` first; verified free on every branch, not just `main` (the ADR-026 collision).
2. **Shape.** Is this an ADR, or an RFC (options still open) or a RESEARCH (measurement missing) in an ADR's clothes?
3. **Question.** Does *Context* end with the one question the ADR answers?
4. **Enforceable.** Can each obligation be answered yes/no for a given PR? Which layer checks it (`[L1]` gate named, `[L2]`, `[L3]`)?
5. **Alternatives.** Is the rejected option recorded with its real cost, not a strawman?
6. **Non-Goals.** Are the adjacent decisions that look like they belong here named as out of scope?
7. **Risks and Assumptions.** What evidence would reverse this decision? If nothing would, it is a preference.
8. **Trade-offs.** Is at least one cost stated that the author would rather not admit?
9. **Stubs and links.** Cross-repo: are the `.link.md` stubs in the same or a linked PR, and does the registry link resolve on the named branch? Private targets as markers, not links?
10. **Protocol.** Does *Engineering Protocol* say whether existing repos comply, who migrates, and by when?
