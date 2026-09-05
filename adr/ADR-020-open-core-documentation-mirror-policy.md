---
title: "ADR-020: Open-Core Documentation Boundary & Cross-Repo Mirror Policy"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-05
slug: adr/ADR-020
---

# ADR-020: Open-Core Documentation Boundary & Cross-Repo Mirror Policy

| Attribute       | Value                                                                                                       |
|:----------------|:--------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED** (formal record authored 2026-05-08 — see retrospective note below)                               |
| **Deciders**    | Arkadiusz Przychocki                                                                                          |
| **Date**        | 2026-05-05                                                                                                    |
| **Scope**       | platform (binds every Exeris repository — public open-core and private enterprise alike)                      |
| **Owning Repo** | `exeris-docs`                                                                                                 |
| **Driven By**   | ADR-008 (Open-Core Strategy); cleanup pass on 2026-05-07 that consolidated platform-scope ADRs                |
| **Compliance**  | [`adr-index.md`](../adr-index.md) §Rules §Visibility                                                          |

> **Retrospective record.** The decision was made on 2026-05-05 and the cleanup pass that operationalized it landed on 2026-05-07. The formal record was authored on 2026-05-08 as part of the ADR registry bootstrap. The Date field reflects the actual decision date, not the authoring date.

## Context and Problem Statement

Exeris is distributed as **open-core**: a set of public repositories that any consumer can clone, build, and deploy, plus a set of private enterprise repositories that ship the high-density runtime extensions.

**Public open-core repos** (consumers see these): `exeris-kernel` (umbrella for SPI, Core, Community drivers, TCK — Community lives as Maven modules `exeris-kernel-community`, `exeris-kernel-community-kafka`, `exeris-kernel-community-testkit` inside this repo, not as a separate sibling repo), `exeris-sdk`, `exeris-spring-runtime`, `exeris-tooling`, `exeris-platform`, `exeris-benchmarks`, `exeris-telemetry-spec`, `exeris-docs`.

**Private enterprise repos** (commercial overlay): `exeris-kernel-enterprise`, `exeris-benchmarks-enterprise`, `exeris-enterprise-observability`.

ADRs and architectural documents move freely across both sides. Some examples:
- ADR-001 (Cloud Native) lives in `exeris-docs` and applies to every repo, public and private.
- ADR-007 (Next-Gen Runtime) lives in `exeris-kernel` (public) and binds `exeris-kernel-enterprise` (private).
- ADR-018 (Observability Tooling Repo Split) lives in `exeris-kernel-enterprise` (private), is enterprise-private content, but its number is publicly registered in `adr-index.md` and consumed by `exeris-telemetry-spec` (public) via a `.link.md` stub.

Without a clear policy, three classes of bug recur:

1. **Duplicate full-content copies.** The same document gets full-content copies in multiple repos, each editable, each eventually drifting. (Discovered during the 2026-05-07 cleanup: ADR-001 had two full copies — in `exeris-kernel/docs/adr/` and in `exeris-kernel-enterprise/docs/adr/` — that had already drifted in line endings and were on a path to substantive divergence.)
2. **Refactor leakage.** Internal refactor working notes — sometimes Polish-language R&D archaeology — get filed as ADRs and assigned global numbers. (Discovered: local refactor docs at numbers 010/011/012 inside `exeris-kernel-enterprise/docs/adr/` that used the global ADR-NNN namespace despite being internal-only.)
3. **Number collisions.** When local-only refactor docs use the global ADR-NNN numbering, they collide with the registry's authoritative assignments. (Discovered: kernel-enterprise local ADR-010 (Persistence SPI Refactor) collided with global ADR-010 (Host Runtime Model, owned by `exeris-spring-runtime`).)

The 2026-05-07 cleanup fixed the immediate state. This ADR locks in the policy that prevents these failure modes from recurring.

## 🏁 The Decision

**The open-core boundary is repo-level. Each document has exactly one authoritative location. Cross-repo navigation uses `.link.md` stubs. Drift between authoritative copies and stubs is build-detectable.**

### 1. Authoritative-location rule

Every ADR and every architecturally-load-bearing document (whitepaper, architecture, performance-contract, subsystem docs, module docs) has **one and only one** authoritative full-content location. That location is determined by ownership:

| Document type                                              | Authoritative location                                  |
|:-----------------------------------------------------------|:--------------------------------------------------------|
| Platform-scope ADR                                         | `exeris-docs/adr/`                                      |
| Per-repo ADR (kernel, sdk, spring-runtime, tooling, ...)   | `<repo>/docs/adr/`                                      |
| Cross-repo ADR                                             | Owning repo's `docs/adr/`; other repos hold link stubs  |
| Enterprise-private ADR                                     | `<enterprise-repo>/docs/adr/`                           |
| Subsystem doc (transport, persistence, crypto, ...)        | `<repo>/docs/subsystems/<name>.md` in the owning repo   |
| Whitepaper / architecture / performance-contract           | `exeris-kernel/docs/` is the canonical home for kernel-platform documents; an enterprise-private extension may live at `exeris-kernel-enterprise/docs/<doc>.md` only when it materially extends the public document — and the extension must clearly cite the canonical version it overlays |

If a document is intended for public consumption, its authoritative copy lives in a public repo. If it is enterprise-private, its authoritative copy lives in an enterprise repo. There is no third option.

### 2. Cross-repo navigation via `.link.md` stubs

When a document owned by repo A is referenced by repos B, C, ..., each consuming repo MAY hold a `<docname>.link.md` (or `ADR-NNN.link.md`) stub that:

- Names the authoritative path (relative or absolute, but unambiguous).
- States in one short paragraph why the consuming repo cares.
- Lists "when to consult" triggers relevant to the consuming repo.

<!-- VERIFY(sweep-2026-09): §1 and §2 are breached by three tracked files, and not by the one the
     sweep first suspected. `exeris-kernel-enterprise/docs-open-core/` is NOT a violation: its 24
     files are untracked, appear in zero commits on zero branches, and are not gitignored — local
     scratch dated 2026-06-14, never mirrored anywhere. What does breach the policy is
     `exeris-kernel-enterprise/docs/adr/`, which holds full-content tracked copies of three
     kernel-owned public ADRs — ADR-007 (518 lines against the kernel's 118), ADR-008 (199) and
     ADR-009 (241) — where §1 allows one authoritative copy and §2 a `.link.md` stub. The same
     directory already holds correct stubs for ADR-001, 020, 033, 034, 036 and 080, and its
     enterprise-owned ADR-018 and ADR-019 are legitimately full. So this is a bounded legacy of the
     three oldest cross-repo entries, not a standing practice. All five of the older files also use
     space-separated names against adr-conventions rule 1. Fixing them belongs to that repository,
     which is outside this sweep. -->
Stubs are **navigation aids**, not content. They MUST NOT replicate the authoritative content. A stub that drifts into a half-summary is a policy violation.

### 3. Visibility taxonomy (canonical)

The `adr-index.md` Visibility column uses exactly two values:

- **`public`** — content lives in a public repo. Anyone can read it.
- **`enterprise-private`** — content lives only in a private repo. Number is publicly registered in `adr-index.md`; content is not.

The legacy value **`public-staged`** is **deprecated by this ADR**. Existing rows that carry it (if any) are reclassified as `public` (when authoritative content already lives in a public repo) or `enterprise-private` (when it does not). On acceptance of this ADR, `adr-index.md` Rules §3 must be updated to drop `public-staged` from the canonical taxonomy.

### 4. Refactor working notes are NOT ADRs

Documents whose primary purpose is to track the mechanics of a refactor — file moves, package renames, migration phases, internal R&D archaeology, Polish-language working notes — live in `<repo>/docs/refactor-notes/` (or in PR descriptions / commit messages). They are NEVER assigned ADR numbers and NEVER mirrored across repos. The 2026-05-07 cleanup relocated the historical kernel-enterprise refactor docs (Persistence SPI Refactor, Transport Provider SPI Surface, Graph Engine SPI Refactor) to `exeris-kernel-enterprise/docs/refactor-notes/` accordingly.

### 5. Drift detection (mandatory)

A CI job verifies cross-repo consistency:

- Every `<docname>.link.md` stub names a path that resolves to an existing file in the named repo.
- For every ADR row in `exeris-docs/adr-index.md`, the linked authoritative file exists at the named path.
- No two repos contain full-content copies of the same logically-identical document. (Detection heuristic: identical `# Title` headers in `docs/adr/` files across repos trigger a review flag; identical content under non-overlay filenames triggers a hard failure.)
- Every ADR file under `<repo>/docs/adr/` matches a row in `exeris-docs/adr-index.md` (either as authoritative copy or as `.link.md` stub) — orphan ADR files in any repo are a policy violation.

<!-- VERIFY(sweep-2026-09): §5 bullet 3 (no two repos hold full-content copies of the same document) has no implementation four months after acceptance — a grep for identical/duplicate/full-content/hashlib/md5/sha256 heuristics over .guardrails/orggh/scripts/ and workflows/ finds nothing. Bullets 2 and 4 are implemented in registry_check.py but bullet 2's on-disk resolution is SKIPPED as the docs-lint workflow invokes it (no --siblings-root; the script then warns "link resolution skipped"). Bullet 1 is not covered by any gate: .link.md stubs name their target as backticked plain text, not a markdown link, so lychee has nothing to check, and lychee.toml excludes the private repos outright. No repo calls docs-lint.yml yet (exeris-docs/.github/workflows/ holds only claude-code-review.yml and claude.yml). The ADR's own next sentence already concedes "Until the job lands, periodic manual audits substitute", so nothing here is false — but the maintainer should decide whether the implementation status becomes a dated ## Amendments entry, a ROADMAP item, or a withdrawal of bullet 3. -->
The drift-detection job runs in CI for `exeris-docs` and aggregates results across repos. Until the job lands, periodic manual audits (like the 2026-05-07 pass) substitute.

## Consequences

### ✅ Positive Outcomes

- **[+] Single source of truth.** Each ADR has exactly one editable location across the entire ecosystem.
- **[+] Boundary clarity.** "Is this doc public or enterprise-private?" reduces to "which repo does it live in?". No `public-staged` ambiguity.
- **[+] Refactor notes stay private.** Internal mechanics (Polish R&D, migration phases) never accidentally cross the boundary.
- **[+] Drift becomes a build outcome.** "Did this PR break a stub link?" is a CI failure, not a review judgment call.

### ⚠️ Trade-offs

- **[-] Cross-repo CI complexity.** Drift-detection requires checkouts of multiple repos; a heavier build configuration than a typical single-repo CI step. Acceptable for a release-gate job, not a per-PR step.
- **[-] Authors must classify intent at write time.** When adding a new ADR or doc, the author must answer: "Is this for public release? If yes, in which public repo?" — and act accordingly. Repo-level CLAUDE.md updates should call this out.

### 📋 What is NOT in scope

- This ADR does not redefine what `open-core` means strategically. ADR-008 owns that.
- This ADR does not retroactively reclassify existing ADRs. Index updates happen as separate PRs guided by this policy.
- This ADR does not specify any tooling for promoting an ADR from `enterprise-private` to `public`. Promotion is a manual move-file-across-repos action when the decision is ready for public release.

## Cross-references

- ADR-008 (Open-Core Strategy) — the strategic framing this policy serves.
- ADR-007 (Next-Gen Runtime Architecture) — example of a kernel-owned ADR consumed by enterprise via the boundary this policy formalizes.
- ADR-018 (Observability Tooling Repo Split) — established the `.link.md` stub pattern that this ADR generalizes.
- ADR-001 (Cloud Native) — first ADR migrated under this policy (PR on 2026-05-07 moved the authoritative copy to `exeris-docs/adr/` with link stubs in consuming repos).
- `adr-index.md` Rules §Visibility — updated alongside this ADR's acceptance to remove `public-staged` and reflect the two-value taxonomy.

## Engineering Protocol

Landed alongside this ADR's acceptance:

- `adr-index.md` Rules §3 (Visibility) updated to the two-value canonical taxonomy (`public` / `enterprise-private`); the `public-staged` value retired.

Open follow-ups (tracked separately):

- Implement the cross-repo drift-detection CI job in `exeris-docs` (or as a release-gate workflow). Until it lands, periodic manual audits substitute.
- Each repo's CLAUDE.md (or CONTRIBUTING.md) should reference this ADR when discussing where new documentation belongs.

## Amendments

**2026-09-04 — `exeris-telemetry-spec` is enterprise-private; its final disposition is open.**
The Context enumeration above lists `exeris-telemetry-spec` among the public open-core repositories
and omits it from the private list. That does not describe the repository. Verified 2026-09-04: the
GitHub repository is `PRIVATE` and carries no recognised licence (`gh repo view` reports
`visibility=PRIVATE`, `license=none`), it holds no `LICENSE` file, and its own `README.md` states
"License: Exeris Enterprise (proprietary)". The shared validator's `PRIVATE_REPOS` set and
`adr-index.md`'s row 018 already treat it as private, which is why a relative link into it was an
error rather than a style nit.

ADR-018 §Consequences records the split as making Repo C **publishable** — "can be released as an
open-spec artifact, enabling third-party decoders" — which is an option the split unlocked, not one
that has been exercised. Read the Context enumeration accordingly: `exeris-telemetry-spec` belongs
to the private set for every purpose this ADR governs, including the `(content private)` marker rule
and the ban on relative links from public files.

**Whether it stays there is not settled.** A wire-format specification that third parties are meant
to implement has an obvious argument for publication, and ADR-018 anticipated it. Making that change
is an act — choosing a licence, reversing the README's proprietary declaration, moving the
repository across the open-core boundary — and belongs to the decision that takes it, not to this
amendment. Until then the documents describe what is, and this entry keeps the open question visible
rather than resolved by silence.
