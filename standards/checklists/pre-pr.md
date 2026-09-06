---
title: Pre-PR Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Pre-PR Checklist — 10 questions before "ready for review"

Run after the code is done and the template is filled. Not a gate; a filter. If you answer "no" twice, the PR is not ready.

1. **Scope class first.** Did I classify the change (hot path / non-hot / test-tooling / docs-only) *before* deciding how much review it needs — and does the diff agree with the class I wrote?
2. **The Wall.** Does any import cross an edge [ADR-006](../../adr/ADR-006-spring-free-kernel-boundary.md) forbids? Did I say `none` because I checked, or because it is the default?
3. **Category B.** Did I touch a `@Generated` / `@generated` file by hand — Java or a `src/app/generated/**` tree? (Then stop.)
4. **TCK.** If observable SPI behaviour changed, which `Abstract*Tck` covers it, and which Community binding test runs it?
5. **Compatibility.** Did japicmp (Java) or the API golden (TS: `api/*.api.md`, `api/tools.api.json`) run, and does the PR's *Compatibility impact* line match its report?
6. **Numbers.** Does every figure in the description have a report path and a state?
7. **The why.** Does *Motivation* name a constraint, failure or measurement — not an intention?
8. **The no.** Does *Result* say what this PR does **not** do?
9. **Verification.** Did I run the commands in *Verification* after the last push, and do they prove the claim I make (a green default build does not run tagged tests)?
10. **Docs.** Did the change move a doc out of date — subsystem page, ADR, CHANGELOG, `last-verified`? If yes, is the fix in this PR or in a linked one?
