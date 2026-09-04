---
title: Documentation Page Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Documentation Page Checklist — 10 questions before you push a doc

Adapted from the arkstack voice checklist for a project voice: same purpose, no first person.

1. **One type.** Is the page exactly one `type` — and only that? (A how-to that explains is two pages.)
2. **Boundary.** Does it say where it does **not** apply — hot path vs whole application, closed-world vs plugin, preview vs stable?
3. **Trade-off.** Is there one visible cost on the page? If only the winning side appears, it is marketing.
4. **Rejected.** For any design description: is there one sentence on what was rejected and what it cost?
5. **Concrete subject.** Is the subject of most sentences a module, a seam, an ADR or a code — not "the kernel" or "the platform"?
6. **Numbers.** Does every figure carry a report path and a state, with the qualifier next to it?
7. **Terminology.** capability not cap; hot path; Category A/B/C; Community/Enterprise tiers — did Vale pass at warning level, and did you read the warnings rather than dismiss them?
8. **Headings.** Are they nouns that make the page findable, not labels that make it sound finished?
9. **Frontmatter.** Is `last-verified` the date you *checked the code*, not the date you edited prose?
10. **Anonymity test.** Could this page have been written for any JVM project? Then it says nothing about Exeris — add the constraint that makes it ours.
