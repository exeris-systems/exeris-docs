---
title: ADR, RFC and Research Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# ADR, RFC and Research Conventions

Binding per ADR-085 §G. Extends `adr-index.md` §Rules and ADR-020; where they overlap, the registry's rule text wins and this file names the gate.

## Hard rules

1. **Filenames** — regex-gated in every repo: `[L1: scripts/registry_check.py]`
   - `ADR-NNN-<lowercase-kebab>.md` (3 digits; `&` → `and`; other punctuation dropped)
   - `ADR-NNN.link.md` for cross-repo stubs
   - `RFC-YYYY-MM-DD-<kebab>.md`, `RESEARCH-YYYY-MM-DD-<kebab>.md`
   - Space-separated names and the `DESIGN-` prefix are retired; existing files are renamed as `[DOC DEBT]` items (registry links updated in the same PR).
2. **Registry row first.** A new ADR number exists in `adr-index.md` before its content file merges; a content file whose number has no row fails the check. `[L1: registry_check.py]`
3. **The row's link resolves on the branch the registry names.** A row whose target is not on that branch carries status `pending merge (<branch>)`. A registry link that resolves nowhere is an error. `[L1: registry_check.py + lychee]`
4. **Private targets are never relative links.** Rows for `enterprise-private` content name the owning repo and say *(content private)*; stubs in private repos are listed in the cross-repo-stubs table as text, not links. `[L1: registry_check.py]`
5. **Cross-repo ADRs land with their stubs.** A cross-repo ADR moves to ACCEPTED only when every consuming repo has `docs/adr/ADR-NNN.link.md` and the stubs row lists them. `[L2]`
6. **Frontmatter on records:** `type: adr | adr-link | rfc | research`, `status` mirrors the header table (`draft | active | superseded | retracted`), `slug: adr/ADR-NNN` so the site URL is stable and case-preserving. `[L1: frontmatter_check.py]`
7. **Amendments are logged, not silent.** An ADR amended in place gains a `## Amendments` section with dated entries (`2026-06-25 — <what changed and why>`), and the registry status shows `accepted (…, upd. YYYY-MM-DD)`. The original decision text is not rewritten; superseded paragraphs are marked, not deleted. `[L2]`
8. **Template sections** (added to `templates/ADR-TEMPLATE.md` and `RFC-TEMPLATE.md` on 2026-09-04): ADR carries `### Non-Goals` and `### Risks and Assumptions` under *Consequences*; an RFC that proposes an SPI surface carries `## Testing`. Absent sections fail review. `[L2]`
9. **PRs that add or amend an ADR carry the `adr` label** and a `Refs: ADR-NNN` trailer. `[L1: pr_body_check.py]`
10. **Pick the shape by the question**, per `templates/README.md`: measurement missing → RESEARCH; options open → RFC; decision made → ADR. An ADR whose *Decision* cannot be turned into a CI check or a review-time assertion is still an RFC.

## Filter (ADR)

- Is the number reserved, and does the registry row link to a branch where the file will exist?
- Is the rejected alternative recorded with its real cost?
- What evidence would reverse this decision? (If none: it is a preference, not a decision.)
- Is every obligation testable with a yes/no on a given PR?
- Are the consuming repos' stubs in the same PR or a linked one?

## Filter (RFC)

- Is the question binary or a short enumerable set?
- Is *do nothing* an option with a stated cost?
- Are the numbers in *Investigation* and only the argument in *Recommendation*?
- Could it be read in 15 minutes?
