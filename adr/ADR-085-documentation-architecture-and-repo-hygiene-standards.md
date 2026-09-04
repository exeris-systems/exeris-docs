---
title: "ADR-085: Adopt a Federated Documentation Architecture and Repo-Hygiene Standards"
type: adr
visibility: public
owning-repo: exeris-docs
status: draft
last-verified: 2026-09-04
slug: adr/ADR-085
---

# ADR-085: Adopt a Federated Documentation Architecture and Repo-Hygiene Standards

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **PROPOSED** (number 085 verified free on `main` and on all 21 remote branches of `exeris-docs` as of 2026-09-04 — reserve the row in `adr-index.md` before this file merges) |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-09-04 |
| **Scope**       | platform (binds every Exeris repository — public open-core and private enterprise alike; portfolio products such as `budgetHQ` follow §B only) |
| **Owning Repo** | `exeris-docs` |
| **Driven By**   | [RFC-2026-09-04 docs-guardrails open decisions](../rfc/RFC-2026-09-04-docs-guardrails-open-decisions.md); the Phase 0 inventory, the reference analysis and the generator spike — local-only working material, named rather than linked |
| **Compliance**  | [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) (visibility & mirror policy), [ADR-025](../../exeris-ai-bridge/docs/adr/ADR-025-ai-agent-bridge.md) (agent surface reads repos, not the site), [ADR-065](../../exeris-kernel/docs/adr/ADR-065-spi-compatibility-gate.md) (compatibility gate) |

## Context and Problem Statement

Exeris documentation is ~3.3 MB of Markdown spread over fourteen repositories with no site, no navigation across repos, no metadata on any file, and no lint of any kind. The inventory of 2026-09-04 found: Conventional Commits practised at 67–96 % but with no gate and subjects that run to 130 characters; PR descriptions that are rich prose with none of the sections the review routines ask for; a strict Javadoc gate in the SDK and a disabled one (`doclint=none`, ~160 findings) in the kernel SPI; ADR filenames in two conventions; the ADR registry linking six kernel ADRs that exist only on `development/0.12.0` and one row linking into a private repo; and agent instructions duplicated across `CLAUDE.md`, `copilot-instructions.md`, `.cursorrules` and `.github/agents`. ADR-025 already records that agents violate numbering discipline because the rules live in lazily-loaded markdown.

Five reference projects (OpenJDK, Spring, Quarkus, Micronaut, Netty) were read for how they close these gaps. They gate *structure* by machine — format, presence, ordering, API compatibility — and leave prose to reviewers; none validates PR bodies, none has a docs-type validator that errors, and Quarkus's optional Diátaxis attribute stalled at 22 % adoption. Exeris is ahead of all five on design records and evidence discipline and behind three of them on mechanical gates.

The site-generator default in the plan (MkDocs Material) entered maintenance mode in November 2025; a build spike on the real corpus showed Docusaurus needs no plugins to resolve the corpus's 489 relative links and zero MDX fixes, while Starlight needed mandatory frontmatter, two plugins and an opt-in to Astro's now-legacy Markdown pipeline. The canonical domain is `exeris.eu`, DNS is on Cloudflare, and the kernel Community tier moves to plain Apache-2.0 at 0.12.

The cost of doing nothing is compounding: every new repo copies a slightly different `CLAUDE.md`, every ADR link from the registry is one merge away from a 404, and the first external contributor will land with no stated terms. This ADR answers: **where does Exeris documentation live, how is it built and published, what metadata and conventions do docs, Javadoc, commits and PRs carry, and which of those rules are enforced by machine?**

## 🏁 The Decision

**Documentation stays federated in each repository's `docs/` tree, is aggregated by a Docusaurus build in `exeris-docs` and published at `docs.exeris.eu` on Cloudflare Pages; every doc carries a validated frontmatter block; commits, PRs, Javadoc, ADRs and agent files follow the standards in `exeris-docs/standards/`; structure is gated in CI, prose by review.**

The site is a projection. Source of truth remains annotated Markdown in Git, read directly by humans on GitHub and by agents through `exeris-ai-bridge`; the site never holds content that is not in a repo.

**Concrete obligations:**

### A. Where documentation lives and how the site is built

1. **Each repo owns `docs/`.** Narrative and record docs for a repo live under `<repo>/docs/` (exeris-docs, having no code, keeps `adr/`, `rfc/`, `standards/`, `templates/` and its canonical documents at root). No repo copies another repo's documents; cross-repo references use ADR-020 link stubs or links.
2. **The federation build mirrors the sibling layout.** `exeris-docs/site/` holds the Docusaurus configuration and a `sources.yml` listing, per repo: the Git URL, the **source branch**, and a whitelist of root files to include (`README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `ROADMAP.md`, `MIGRATION*.md`). The build clones each public source into `content/<repo-name>/` preserving the inner path, so relative links resolve unchanged.
3. **Public sources only.** `sources.yml` may list only repos whose visibility is `public` under ADR-020. A private repo name in that file fails the build.
4. **Generator and host.** Docusaurus with `markdown.format: 'detect'`; a local-search plugin; `onBrokenLinks` and `onBrokenMarkdownLinks` set to `throw` (see Engineering Protocol for the ramp). Hosted on Cloudflare Pages with per-PR preview deployments, at `docs.exeris.eu`. Switching host requires no ADR; switching hostname does.
5. **Astro Starlight is the named alternative** if a full-corpus build exceeds 10 minutes in CI; MkDocs, Zensical and Antora are not to be adopted without a superseding ADR.

### B. Format and metadata

6. **Markdown is the only documentation source format.** No AsciiDoc, no generator-specific MDX components in files that live in repos (`.mdx` is permitted only inside `exeris-docs/site/`).
7. **Every file under `docs/` and every canonical exeris-docs document carries a frontmatter block** validated in CI:

   ```yaml
   ---
   title: <string>                       # required
   type: <enum>                          # required — see 8
   visibility: public | enterprise-private   # required
   owning-repo: <repo-name>              # required
   status: draft | active | stale | superseded | retracted   # required for records; default active
   last-verified: YYYY-MM-DD             # required
   slug: <path>                          # optional; fixes the site URL
   ---
   ```
   Missing or invalid `title`, `type`, `visibility`, `owning-repo` or `last-verified` is a **build error**, not a warning.
8. **`type` enumeration** (extend by amending this ADR): `adr`, `adr-link`, `rfc`, `research`, `design-note`, `subsystem`, `module`, `tutorial`, `howto`, `reference`, `explanation`, `operations`, `release-notes`, `changelog`, `roadmap`, `benchmark-report`, `claims`, `methodology`, `refactor-note`, `working-note`, `migration-guide`. Narrative docs use the four Diátaxis values (`tutorial`, `howto`, `reference`, `explanation`); everything else is an Exeris record kind.
9. **Working artefacts do not live at repo root.** Reports, refactor notes, session notes and crash dumps go under `docs/working-notes/` (type `working-note`, git-ignored or committed per repo policy) or are deleted; repo root holds only community files (`README`, `CONTRIBUTING`, `SECURITY`, `LICENSE*`, `CHANGELOG`, `ROADMAP`, `MIGRATION*`, `CLAUDE.md`) and build files.

### C. Standards home and shared configuration

10. **`exeris-docs/standards/` is the single home of the standards** listed in §D–§I, one file per artefact kind plus `checklists/`. Repos link to them from `CONTRIBUTING.md`; they never copy them (ADR-020 applies to standards as it does to ADRs).
11. **`exeris-systems/.github` (organisation repository) holds the shared enforcement**: default `CONTRIBUTING.md` and `PULL_REQUEST_TEMPLATE.md`, reusable workflows (`docs-lint`, `commit-lint`, `pr-body-check`, `javadoc-gate`), the Vale style package, `markdownlint` and `commitlint` configuration, and the frontmatter/registry validator scripts. Each repo calls the reusable workflows; it does not re-implement them.

### D. Commit messages

12. **Conventional Commits.** Subject `type(scope): summary`. Allowed types: `feat fix docs chore refactor test build ci perf release report research revert`. `wip` never reaches a protected branch. Scope is the module or scenario name (`kernel-spi`, `sdk-model`, `entity-read-by-id`); domain prefixes such as `destructive:` or `fuzz:` become scopes (`test(fuzz): …`).
13. **Subject ≤ 100 characters**, imperative, no trailing period. Longer narrative moves to the body.
14. **Body structure for `feat`, `fix`, `perf`, `refactor`, `release`:** the body contains the labelled sections `Motivation:`, `Modification:`, `Result:` (Netty form). Other types may use free prose.
15. **Trailers are grammar, not prose:** `Closes #N` / `Fixes #N`; `Refs: ADR-NNN` whenever an ADR is touched or relied on; `Claim: <id>` when a benchmark claim changes state; `Co-authored-by:` for AI assistance is kept as provenance (see §I).

### E. Pull requests

<!-- VERIFY(sweep-2026-09): §E.16 makes authors declare "File categories touched (A | B | C, SDK-using repos only)" and §J.31 gates "Category-B files edited without regeneration marker", but no Category A/B/C file taxonomy is defined anywhere in the checkout. A case-insensitive search for "category a/b/c" and "file categories" across every exeris-* repo (public and private) and ~/.claude finds only same-day sweep files; B is implied to mean "generated" (standards/javadoc-conventions.md:35), A and C are undefined; the plan section the inventory cites for them ("the plan's G2", 2026-09-inventory.md:55) is in a docs-guardrails-plan.md that is not in the checkout; and the name collides with migration-tools/CLAUDE.md:65-70, an unrelated migration-output taxonomy in a private repo. Maintainer must define A, B and C — or drop the PR-template field and the L1 gate — before docs-style-guide.md rule 10 turns the undefined term into a binding Vale terminology rule. -->

16. **One PR template for every repo**, starting with Motivation / Modification / Result and continuing with: **Scope class** (`runtime hot path | runtime non-hot | test-tooling | docs-only`), **Wall impact** (`none | <edge>`), **File categories touched** (`A | B | C`, SDK-using repos only), **TCK obligation** (`satisfied | debt #N | n/a`), **Compatibility impact** (`none | additive | breaking (ADR-NNN)`), **Cross-repo impact**, **ADRs referenced**, **Evidence state** for any number (`citable | unartifacted | n/a`), and an optional `Release note:` line.
17. **The body checker verifies presence and parseability of the headings and trailer lines, nothing more.** Substance is reviewed, not linted.

### F. Javadoc

18. **Prose rules are the Oracle doc-comment conventions**: summary first sentence; third-person declarative; implementation-independent; `@param` on every parameter, `@return` on every non-void method, `@throws` for checked exceptions and for unchecked ones a caller would catch; no restating the signature; `{@code}`/`{@link}` over HTML.
19. **Tag vocabulary:** `@implSpec` for what an implementer must honour, `@apiNote` for caller guidance, `@implNote` for facts about the current implementation, `@since` on every public element of a released module. `@author` and `@version` are banned (Git is the author record). Examples use `{@snippet}`, never pasted `<pre>` blocks.
20. **Contract lines on SPI types that touch buffers, memory or threads:** the type-level comment states, in this order, **Allocation** (`zero-alloc on hot path | allocates`), **Thread confinement** (`owner thread | any thread | virtual-thread-safe`), **Ownership** (who releases; `LoanedBuffer`/`MemorySegment` semantics).
21. **Gate:** `maven-javadoc-plugin` with `failOnWarnings=true` on `exeris-kernel-spi`, `exeris-sdk-annotations` and every module published to Maven Central (the SDK configuration is the port target); Checkstyle Javadoc modules `JavadocType`, `JavadocMethod`, `JavadocStyle`, `NonEmptyAtclauseDescription`, `AtclauseOrder` (order `@param @return @throws @since @see @deprecated`) in `exeris-kernel-build-config`. Kernel Core and everything else: diff-aware only.

### G. ADRs, RFCs and the registry

22. **Filenames:** `ADR-NNN-<kebab>.md`, `ADR-NNN.link.md`, `RFC-YYYY-MM-DD-<kebab>.md`, `RESEARCH-YYYY-MM-DD-<kebab>.md` — regex-gated in every repo; the `DESIGN-` prefix and space-separated names are retired.
23. **Registry-row-first, and the row's link must resolve on the branch the registry names.** A row whose file is not on that branch carries status `pending merge`; the link checker treats a registry link that does not resolve as an error.
24. **Private targets are never relative links.** A public registry row for `enterprise-private` content states the owning repo and *(content private)*; it does not link into the private repo.
25. **Amendments are logged, not silent.** An ADR amended in place gains a dated entry in an `## Amendments` section; the registry status shows `upd. YYYY-MM-DD`. Immutability à la Quarkus is explicitly not adopted.
26. **Template additions:** ADR gains `Non-Goals` and `Risks and Assumptions` subsections; RFCs that propose an SPI surface gain `Testing`. A PR that adds or amends an ADR carries the `adr` label.

### H. Changelog and compatibility

27. Every repo that publishes an artefact keeps `CHANGELOG.md` in Keep-a-Changelog form with a mandatory `Breaking` section per release that agrees with the japicmp/revapi report; tooling adds one.
28. Accepted incompatible changes are recorded in a justified `accepted-api-changes.json` next to the compatibility tool (Micronaut/Netty pattern); ADR-065 remains the gate.

### I. Agent-facing files and AI provenance

29. **`CLAUDE.md` is the canonical agent instruction file per repo**, in the section order `Mission · Documentation precedence · Rule levels (hard / strong default / heuristic) · Scoped bans · Language · Cross-repo ADRs to consult · Conventions (link to standards) · Auto-memory`. `AGENTS.md`, `.github/copilot-instructions.md`, `.cursorrules` and `.github/agents/*` are one-line pointers to it or are removed. Rules already enforced by CI are not repeated in `CLAUDE.md`.
30. **AI provenance policy:** AI-assisted commits keep the `Co-authored-by:` trailer; the human author is accountable for every line and must be able to defend it in review; agents do not open PRs or file issues without a named human author. Recorded in `standards/ai-provenance.md`, linked from every `CONTRIBUTING.md`.

### J. Enforcement layering

31. **L1 (CI, hard):** commit format (`commitlint`); PR body headings; frontmatter schema; ADR/RFC filename regex and registry-row presence; link check (`lychee`) including public→private path detection; Javadoc gates of §F.21; japicmp (ADR-065); Category-B files edited without regeneration marker.
32. **L1 (CI, warning):** Vale with the Exeris style (seeded from Quarkus's package plus the terminology in `exeris-docs/CLAUDE.md` *Common drift patterns*); `markdownlint`.
33. **L2 (Claude review):** a `docs-guardrails-review` step added to the `pr-review.md` router for every repo; findings use the existing ladder, with the new tag **`[DOC DEBT]`** as a sibling of `[TCK DEBT]`.
   <!-- VERIFY(sweep-2026-09): §J.33 patches "the pr-review.md router for every repo" and calls [DOC DEBT] a sibling of [TCK DEBT] in "the existing ladder". No file named pr-review.md (nor routine-schedule.md) exists anywhere under ~/exeris-systems/ or ~/.claude, and every occurrence of "[TCK DEBT]" in the tree is a 2026-09-04 artefact of this sweep. The review routines that do exist — exeris-kernel/.claude/commands/community-pr-review.md and exeris-kernel-enterprise/.github/prompts/enterprise-pr-review.prompt.md — use "Blocking / Non-blocking / APPROVE-CONDITIONAL-REJECT" and carry no bracketed severity ladder. Maintainer must name where the router and its ladder live, or §J.33 has no patch target. -->
34. **L3 (checklists):** `standards/checklists/{pre-pr,doc-page,adr,release-notes}.md`, each ≤ 10 questions. Not gated.

### K. Contributor terms

35. **DCO.** External contributions require a `Signed-off-by` trailer, enforced by the DCO GitHub App with organisation members exempt. `CONTRIBUTING.md` states the licence each module is offered under. No CLA.

### L. Explicitly deferred

36. Enterprise-private documentation site (trigger: first commercial customer needing docs outside the repo; path: Cloudflare Access on a second Pages project). Versioned docs per release line (trigger: Kernel 1.0 GA). Both require an amendment, not a new ADR.

## Consequences

### ✅ Positive Outcomes

- **[+] One URL space for fourteen repos** without moving a single document; the ai-bridge and GitHub readers are unaffected because the site is a projection.
- **[+] Drift becomes a build failure**, not a session finding: filenames, registry rows, private links, missing metadata and broken links stop at CI, where Quarkus's structural gates stop them.
- **[+] The kernel's Javadoc reaches the standard the SDK already meets**, and SPI contracts state allocation, threading and ownership in a form implementers can rely on — a differentiator no reference project has.
- **[+] Agent instructions have one source per repo**, ending the four-way duplication found in the inventory.
- **[+] External contribution has stated terms** on the day the licence PR lands.

### ⚠️ Trade-offs

- **[-] Frontmatter on ~250 public files and ~1,150 in budgetHQ.** A scripted backfill (title from H1, type from directory, `last-verified` = last commit date) is required before the error-level gate can be enabled; until then the validator runs in warning mode on unchanged files and error mode on changed ones.
- **[-] ~160 kernel SPI doclint findings** must be cleared before `failOnWarnings` is turned on there. Bounded, but it is real work on a module under active 0.12 development.
- **[-] Subject-length and body-structure rules will reject the current house style** for `feat`/`fix` commits until authors and skills adopt the three-section body. Expect a fortnight of friction.
- **[-] Docusaurus builds are slower** (47 s for 123 pages cold) and its React toolchain is a new dependency for a JVM organisation; mitigated by CI caching and by the named Starlight alternative.
- **[-] Cloudflare concentrates DNS, public site and future private site**; GitHub Pages remains a same-day fallback because the hostname is owned.
- **[-] Every repo gains a workflow caller and a PR template**; twenty small PRs, one per repo, plus the org `.github` repo.

### 📋 What is NOT in scope

- The content and voice of any individual document; the review checklists (L3) are filters, not rules, and live outside this ADR.
- The claims/evidence methodology (`exeris-benchmarks/docs/CLAIMS.md`) — referenced, not changed.
- The 0.12 licence change itself (kernel release work) and the copyright-holder update after the sp. z o.o. registration.
- Landing-site domains (`exeris.systems`, `exeris-kernel.io`) — landing work; only `docs.exeris.eu` is fixed here.
- Business ADRs (`BUS-NNN`) and portfolio-product internal namespaces.

## Cross-references

- ADR-020 (Open-Core Documentation Boundary & Cross-Repo Mirror Policy) — visibility model this ADR builds on; §A.3 and §G.24 make it machine-checked.
- ADR-025 (AI Agent Bridge) — the agent surface reads repos; §A keeps `<repo>/docs/**` and `adr-index.md` as the contract.
- ADR-065 (SPI Compatibility Gate) — §H.28 adds the justified accepted-changes file.
- ADR-008 (Open-Core Strategy), ADR-023 (Capability Licensing Taxonomy) — amended by the 0.12 licence change; §K assumes that change has landed.
- `exeris-docs/rfc/RFC-2026-09-04-docs-guardrails-open-decisions.md` — options and pros/cons behind §A, §J, §K.
- The Phase 0 inventory of what the repositories do today, the reference analysis of OpenJDK, Spring, Quarkus, Micronaut and Netty, and the generator spike — evidence. All three are local-only working material and are deliberately not part of the repository, so they are named rather than linked.
- External: Oracle "How to Write Doc Comments for the Javadoc Tool"; JDK-8008632 (`@apiNote`/`@implSpec`/`@implNote`); Conventional Commits 1.0; Keep a Changelog 1.1; Diátaxis; Netty "Writing a commit message".

## Engineering Protocol

Existing repos do **not** comply; this ADR is prescriptive. Migration owner: founder. Target window: standards and gates within four weeks of acceptance (plan Phases 3–4), rollout over the following four (Phase 5).

1. **Registry (before acceptance):** reserve 085 in `adr-index.md`; add the cross-repo-stubs row listing `.link.md` stubs in every public repo (`exeris-kernel`, `exeris-sdk`, `exeris-spring-runtime`, `exeris-tooling`, `exeris-platform`, `exeris-ai-bridge`, `exeris-benchmarks`, `exeris-caps-cors-policy`) and *(private repo)* markers for the enterprise repos; mark rows 071/073/074/077/080/083 `pending merge` or merge `development/0.12.0` docs to `main`; replace ADR-018's relative link into `exeris-telemetry-spec` with a *(content private)* marker.
2. **Phase 3 — standards** (`exeris-docs/standards/`): `commit-conventions.md`, `pr-conventions.md`, `javadoc-conventions.md`, `docs-style-guide.md`, `readme-skeleton.md`, `adr-conventions.md`, `changelog-conventions.md`, `claude-md-schema.md`, `ai-provenance.md`, `claims-and-evidence.md` (thin), `checklists/*.md`; extend the kernel skills `exeris-pr-preflight`, `exeris-docs-adr-check`, `exeris-adr-register` rather than adding a new surface; update `ADR-TEMPLATE.md` and `RFC-TEMPLATE.md` per §G.26.
3. **Phase 4 — enforcement** (`exeris-systems/.github`): reusable workflows and configs of §C.11; frontmatter validator modelled on Quarkus's `YamlMetadataGenerator` (errors to the step summary, exit 1); registry validator (§G.23–24); `docs-guardrails-review.md` routine and the `[DOC DEBT]` line in `pr-review.md`; DCO app installed at organisation level.
4. **Phase 5 — rollout:** pilot `exeris-sdk` (Javadoc: already passes) and `exeris-kernel` (commit/PR gates) in warning mode for two weeks, then hard; fan out via workflow callers; frontmatter backfill script run per repo; site live at `docs.exeris.eu` from `sources.yml` with strict link mode enabled once item 1 is done.
5. **Phase 6 — upkeep:** `docs-guardrails-audit.md` monthly routine (re-run the Phase 0 inventory script, diff, report `[DOC DEBT]` count and age); `doc-drift-check.md` written to use `last-verified`.
6. **Domain cleanup (tracked as `[DOC DEBT]`):** JSON-schema `$id` in `exeris-benchmarks` (`exeris.io` → `exeris.eu`, schema version bump + changelog); landing targets aligned to `exeris.eu` before the landing ships.
7. **Acceptance criterion for closing this ADR's protocol:** every public repo has the PR template, a `CONTRIBUTING.md` linking the standards and the DCO paragraph, a schema-conformant `CLAUDE.md`, frontmatter on every file under `docs/`, the four reusable workflows green, and the site building with `onBrokenMarkdownLinks: 'throw'`.
