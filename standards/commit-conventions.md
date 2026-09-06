---
title: Commit Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Commit Conventions

Binding per ADR-085 §D. Applies to every commit that reaches a protected branch in any Exeris repository. Squash-merged PRs: the squash commit is the commit that counts, so the PR title and body are what gets linted.

## Hard rules

1. **Conventional Commits subject.** `type(scope): summary` — `[L1: commitlint]`
   - `type` ∈ `feat fix docs chore refactor test build ci perf release report research revert`. Nothing else. `wip` may exist on a feature branch and never on `main` or `development/*`.
   - `scope` is a module, subsystem or benchmark scenario, lowercase: `kernel-spi`, `core`, `persistence`, `sdk-model`, `codegen-ts`, `ai-bridge`, `ui-kit`, `studio-frontend`, `entity-read-by-id`. Omit the module prefix when the repo has one module. Domain words that used to be prefixes are scopes now: `test(fuzz):`, `report(entity-read-by-id):`, not `fuzz:` / `report:`.
   - `release` takes the version as scope: `release(0.12.0): integrate v0.12.0 milestone into main`.
2. **Subject ≤ 100 characters**, imperative mood, no trailing period, no issue number in the subject (the `(#N)` suffix that squash-merge appends is exempt). `[L1: commitlint header-max-length=100]`
3. **Body required, with three labelled sections, for `feat`, `fix`, `perf`, `refactor`, `release`:** `[L1: commitlint body-empty + custom rule mmr-sections]`

   ```
   Motivation:
   <why — the constraint, failure or measurement that made this necessary>

   Modification:
   <what changed, at the level of contracts and seams, not files>

   Result:
   <what is different after this commit; what is explicitly NOT covered>
   ```
   Other types may use free prose or no body at all.
4. **Trailers are grammar.** One per line, at the end of the body: `[L1: commitlint trailer-exists for Refs when the diff touches docs/adr/**]`
   - `Closes #N` / `Fixes #N` — GitHub issue.
   - `Refs: ADR-NNN[, ADR-MMM]` — mandatory when the commit touches an ADR file or claims compliance with one.
   - `Claim: <claim-id>` — mandatory when a `CLAIMS.md` entry changes state (see `claims-and-evidence.md`).
   - `Co-authored-by: <name> <email>` — kept for AI assistance (see `ai-provenance.md`).
   - `Signed-off-by:` — external contributors (DCO app enforces; org members exempt).
5. **English.** Subject and body. `[L2]`
6. **One logical change per commit on the protected branch.** Squash fixups before merge; do not squash unrelated commits together. `[L2]`

## Why these numbers

Phase 0 measured the median subject at 73–86 characters with 60–85 % over 72; the house style is a one-sentence narrative and it is good. Spring's 55-character limit would reject most of it; 100 keeps the sentence and forces the second clause into the body. Bodies already exist on 90–100 % of commits — the three labels only make what they say checkable.

## Examples

Before (real, 113 characters):

```
fix(persistence): SPI unwrap seam so JDBC compat bridge survives request-session wrapping (0.8.1) (#164)
```

After:

```
fix(persistence): add an SPI unwrap seam for the JDBC compat bridge

Motivation:
Request-session wrapping in 0.8.1 hid the native connection from the JDBC
compatibility bridge, so `Connection.unwrap(...)` returned the wrapper and
Spring's `DataSourceUtils` path failed under compat mode.

Modification:
`PersistenceSession` exposes `unwrap(Class<T>)` on the SPI; the core wrapper
delegates to the driver session; the compat bridge calls it instead of
casting.

Result:
Compat-mode JDBC access survives wrapping; the seam is additive on the SPI
(japicmp: no incompatible change). Pure-mode paths are untouched.

Refs: ADR-011
Closes #160
```

Benchmark repo, domain prefix turned into a scope:

```
report(entity-read-by-id): the Valhalla carrier sweep costs 1.3 MB non-heap and buys 43 B/req (n=6)

Claim: C-041
```

## Filter (before you push)

- Could someone write the CHANGELOG line from the subject alone?
- Does *Motivation* name a constraint, failure or number — not "improve" or "clean up"?
- Does *Result* say what is **not** covered?
- Is every ADR you relied on in `Refs:`?
- Would `git log --oneline` for this scope still read as a changelog after this commit?
