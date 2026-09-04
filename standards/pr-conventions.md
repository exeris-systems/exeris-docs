---
title: Pull Request Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Pull Request Conventions

Binding per ADR-085 §E. The template below is the organisation default (`exeris-systems/.github/PULL_REQUEST_TEMPLATE.md`); a repo may append sections, never remove them.

## Hard rules

1. **PR title = the squash-commit subject.** Same grammar as `commit-conventions.md` rule 1–2. `[L1: commitlint on PR title]`
2. **The body keeps every heading of the template**, in order, each with at least one line of content or the literal `n/a`. `[L1: scripts/pr_body_check.py]`
3. **Machine-read lines must parse:** `[L1: scripts/pr_body_check.py]`
   - `Scope class:` one of `runtime hot path | runtime non-hot | test-tooling | docs-only`
   - `Wall impact:` `none` or an edge in the form `<from-module> → <to-module>`
   - `File categories:` subset of `A B C` or `n/a` (SDK-using repos only)
   - `TCK obligation:` `satisfied | debt #<issue> | n/a`
   - `Compatibility impact:` `none | additive | breaking (ADR-NNN)`
   - `Evidence state:` `citable | unartifacted | n/a`
   - `Closes #N` / `Refs: ADR-NNN` lines as in the commit trailer grammar
4. **Draft PRs are exempt** from rules 2–3 until marked ready. `[L1]`
5. **Labels:** `adr` on any PR that adds or amends an ADR; `docs-only` when *Scope class* is docs-only (routes review to the docs step only). `[L2]`
6. **Dependabot / bot PRs** carry the template in reduced form (`Motivation` only) and skip Claude review. `[L1: workflow condition]`

## The template

```markdown
Motivation:
<!-- Why this change exists: the constraint, failure or measurement. -->

Modification:
<!-- What changed at the level of contracts, seams and behaviour. -->

Result:
<!-- What is different now. What is explicitly NOT covered. -->

## Classification
Scope class: <runtime hot path | runtime non-hot | test-tooling | docs-only>
Wall impact: <none | from-module → to-module>
File categories: <A B C | n/a>
TCK obligation: <satisfied | debt #N | n/a>
Compatibility impact: <none | additive | breaking (ADR-NNN)>
Cross-repo impact: <none | repo: what must change>
ADRs referenced: <ADR-NNN, … | none>
Evidence state: <citable | unartifacted | n/a>

## Verification
<!-- The exact commands that prove the claim ("tests pass" cites the invocation). -->

Release note: <!-- optional one-liner for CHANGELOG / release notes -->

Closes #
Refs: ADR-
```

## Why this shape

Netty's Motivation / Modification / Result is the only structured PR template among the reference projects and it forces the *why*. The Classification block mirrors what `pr-review.md` and the per-repo routines already ask reviewers to determine — scope class first, then Wall, categories, TCK, compatibility, cross-repo, evidence. Putting it in the body moves that work from the reviewer to the author and makes it greppable. The checker verifies presence and parseability only; nobody wants a regex deciding whether a trade-off is honest.

## Filter (author, before "ready for review")

- Does the description say what was **rejected**, not only what was done?
- Is there a visible trade-off, or does the PR only present the winning side?
- Could the reviewer route this PR to the right `pr-review-<repo>.md` from the body alone?
- Does every number in the body have a report path or an evidence state?
- Did you run the `Verification` commands *after* the last push?
