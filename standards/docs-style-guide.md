---
title: Documentation Style Guide
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Documentation Style Guide

Binding per ADR-085 §B and §J. Applies to every Markdown file under `docs/` in any repo and to the canonical documents of `exeris-docs`. Not for Javadoc (see `javadoc-conventions.md`) or records (see `adr-conventions.md` for the extra rules ADRs/RFCs carry on top of this one).

## Hard rules

1. **Markdown only.** No AsciiDoc, no `.mdx` outside `exeris-docs/site/`, no HTML beyond `<br>`, `<sub>`, `<sup>`, `<details>`. `[L1: markdownlint MD033 allow-list]`
2. **Frontmatter on every file**, validated as a build error, not a warning: `[L1: scripts/frontmatter_check.py — errors to $GITHUB_STEP_SUMMARY, exit 1]`

   ```yaml
   ---
   title: Persistence Subsystem            # required — keep the H1 too; GitHub renders the H1, the site uses `title` for nav/meta
   type: subsystem                         # required — enum below
   visibility: public                      # required — public | enterprise-private
   owning-repo: exeris-kernel              # required
   status: active                          # draft | active | stale | superseded | retracted (records: required; narrative: default active)
   last-verified: 2026-09-04               # required — the date a human last confirmed this page matches the code
   slug: subsystems/persistence            # optional — fixes the site URL; required for ADRs (see adr-conventions.md)
   ---
   ```
3. **`type` enumeration:** `adr` `adr-link` `rfc` `research` `design-note` `subsystem` `module` `tutorial` `howto` `reference` `explanation` `operations` `release-notes` `changelog` `roadmap` `benchmark-report` `claims` `methodology` `refactor-note` `working-note` `migration-guide`. Adding a value = amending ADR-085 §B.8. `[L1]`
4. **One Diátaxis type per narrative page.** A `howto` does not explain, a `reference` does not teach, an `explanation` has no steps, a `tutorial` has exactly one path. If a page needs two, split it. `[L2]`
5. **Required sections by type:** `[L1: frontmatter_check.py heading scan]`
   - `tutorial`, `howto` → `## Prerequisites` first, `## Where this does not apply` last.
   - `subsystem`, `module` → `## Contract`, `## Hot path`, `## Failure modes`, `## Owning ADRs`.
   - `benchmark-report` → the sections `CLAIMS.md` requires (see `claims-and-evidence.md`).
6. **`visibility: enterprise-private` files never appear in a public repo; public files never link to a private path.** `[L1: lychee + registry_check.py]`
7. **Filenames:** lowercase kebab-case; records follow `adr-conventions.md`; numeric ordering prefixes (`01-spi.md`) are allowed and stripped from URLs. `[L1: filename regex]`
8. **Links:** relative, to the `.md` file (the site rewrites them); cross-repo links use the sibling-layout path (`../../exeris-kernel/docs/adr/ADR-065-….md`) which resolves both on disk and on the site; links to a repo-root file (`CONTRIBUTING.md`, `MIGRATION.md`) are allowed only for files on that repo's whitelist in `exeris-docs/site/sources.yml`. `[L1: lychee]`
9. **Numbers carry evidence.** Any performance, footprint or throughput figure outside `exeris-benchmarks/results/reports/` cites the report path and a figure state (`claims-and-evidence.md`). `[L2 — HARD BLOCK on release gates]`
10. **Terminology** (Vale `Exeris` style, warning level): `[L1: vale, MinAlertLevel=warning]`
    - *capability*, not *cap*, in prose (code identifiers excepted); *The Wall*; *Category B* (generated files; `A` and `C` are not Exeris terms — see ADR-085 §E.16); *hot path* (two words); *Community* / *Enterprise* capitalised as tiers.
    - Forbidden pairs from `exeris-docs/CLAUDE.md` *Common drift patterns* are Vale `existence` rules: "Postgres-only graph", "replacing Neo4j", `exeris-kernel-community` as a sibling repo, "Axon" adjacent to a digit, "~60% CPU waste", ">160 GB", TRL-5 or higher for the platform aggregate.
    - Style rules seeded from the Quarkus package: sentence-case headings, no heading punctuation, sentence length ≤ 32 words (suggestion), no "in order to", no "utilize", American spelling.
11. **English.** `[L2]`

## Voice

Docs are the project's voice, not the author's — the first-person rules of the arkstack blog checklist do not transfer. What transfers is the purpose: traceable reasoning, no keynote tone.

- **State the boundary of applicability early.** "This holds on the hot path, not across the application." "This assumes the execution path is still under our control." A page without a boundary is a claim about everything.
- **Leave one visible trade-off.** If a mechanism only has upsides on the page, the page is marketing.
- **Prefer the concrete over the general.** Name the module, the seam, the ADR, the EX-code. "The kernel" is rarely the right subject; `exeris-kernel-core`'s `KernelBootstrap` usually is.
- **Say what was rejected** when describing a design, in one sentence, with the cost.
- **No conference-script transitions.** Sections do not need to flow; they need to be findable. Headings are nouns, not labels ("Reference-count lifecycle", not "The Missing Link").
- **Restrained edge is allowed** ("framework magic stopped looking magical and started looking expensive"), contempt for readers or other projects is not.

## Page skeletons

`subsystem` / `module`:

```
---frontmatter---
Purpose (2–4 sentences: what it owns, what it never does)
## Contract          — the SPI/interfaces, in terms of guarantees
## Hot path          — what runs per request; allocation and threading statements
## Failure modes     — EX-codes, what the caller sees, what JFR emits
## Configuration     — only if the subsystem has any
## Owning ADRs       — numbers with one line each
## Where this does not apply
```

`howto`:

```
---frontmatter---
Goal (one sentence)
## Prerequisites
## Steps             — numbered, each verifiable
## Verify            — the command and the expected output
## Where this does not apply
```

## Filter (before you push a docs change)

- Is the `type` right, and is the page only that type?
- Does the page say where it does **not** apply?
- Is there at least one trade-off on the page?
- Could this page have been written for any JVM project? Then it says nothing.
- Did you bump `last-verified` because you *checked the code*, not because you edited the text?
- Does every number have a report path?
