---
title: "ADR-085: Adopt a Federated Documentation Architecture and Repo-Hygiene Standards"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-05
slug: adr/ADR-085
---

# ADR-085: Adopt a Federated Documentation Architecture and Repo-Hygiene Standards

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **ACCEPTED** (2026-09-04) |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-09-04 |
| **Scope**       | platform (binds every Exeris repository — public open-core and private enterprise alike; portfolio products such as `budgetHQ` follow §B only) |
| **Owning Repo** | `exeris-docs` |
| **Driven By**   | Standardising documentation and repository hygiene across the organisation. The option comparison, the inventory of what the repositories do today and the reference analysis behind it are internal working material and are not part of this repository. |
| **Compliance**  | [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) (visibility & mirror policy), [ADR-025](https://github.com/exeris-systems/exeris-ai-bridge/blob/main/docs/adr/ADR-025-ai-agent-bridge.md) (agent surface reads repos, not the site), [ADR-065](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-065-spi-compatibility-gate.md) (compatibility gate) |

## Context and Problem Statement

Exeris documentation is ~3.4 MB of Markdown under `docs/` in the nine public core repositories alone (2026-09-04 inventory); the portfolio and results trees outside that scope add far more — `budgetHQ/docs/` is 10.4 MB on its own and `exeris-benchmarks/results/` another ~2 MB — with no site, no navigation across repos, no metadata on any file, and no lint of any kind. The inventory found: Conventional Commits practised at 67–96 % **where it matters**, but with no gate and subjects running to 131 characters in `exeris-tooling` and 184 in `exeris-benchmarks`; PR descriptions that are rich prose with none of the sections a reviewer can rely on; and agent-instruction files in four different section vocabularies.

Five reference projects (OpenJDK, Spring, Quarkus, Micronaut, Netty) were read for how they close these gaps. They gate *structure* by machine — format, presence, ordering, API compatibility — and leave prose to reviewers; none validates PR bodies, none has a docs-type validator that errors, and Quarkus's optional Diátaxis attribute stalled at 22 % adoption. Exeris is ahead of all five on design records and evidence discipline and behind three of them on mechanical gates.

The site-generator default in the plan (MkDocs Material) entered maintenance mode in November 2025; a one-day, 123-file build spike showed Docusaurus resolves **424 of the corpus's 489 relative links** natively — 87 %, zero plugins, zero MDX fixes; the remainder point outside the sampled corpus — while Starlight needed mandatory frontmatter, two plugins and an opt-in to Astro's now-legacy Markdown pipeline to reach the same 424. The canonical domain is `exeris.eu`, DNS is on Cloudflare, and the kernel Community tier moves to plain Apache-2.0 at 0.12.

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
9. **Working artefacts do not live at repo root.** Reports, refactor notes, session notes and crash dumps go under `docs/working-notes/` (type `working-note`, git-ignored or committed per repo policy) or are deleted; repo root holds only community files (`README`, `CONTRIBUTING`, `SECURITY`, `LICENSE*`, `CHANGELOG`, `ROADMAP`, `MIGRATION*`, `AGENTS.md`) and build files. Thin provider adapters such as `CLAUDE.md` are allowed only when required by a supported client.

### C. Standards home and shared configuration

10. **`exeris-docs/standards/` is the single home of the standards** listed in §D–§I, one file per artefact kind plus `checklists/`. Repos link to them from `CONTRIBUTING.md`; they never copy them (ADR-020 applies to standards as it does to ADRs).
11. **`exeris-systems/.github` (organisation repository) holds the shared enforcement**: default `CONTRIBUTING.md` and `PULL_REQUEST_TEMPLATE.md`, reusable workflows (`docs-lint`, `commit-lint`, `pr-body-check`, `javadoc-gate`), the Vale style package, `markdownlint` and `commitlint` configuration, and the frontmatter/registry validator scripts. Each repo calls the reusable workflows; it does not re-implement them.

### D. Commit messages

12. **Conventional Commits.** Subject `type(scope): summary`. Allowed types: `feat fix docs chore refactor test build ci perf release report research revert`. `wip` never reaches a protected branch. Scope is the module or scenario name (`kernel-spi`, `sdk-model`, `entity-read-by-id`); domain prefixes such as `destructive:` or `fuzz:` become scopes (`test(fuzz): …`).
13. **Subject ≤ 100 characters**, imperative, no trailing period. Longer narrative moves to the body.
14. **Body structure for `feat`, `fix`, `perf`, `refactor`, `release`:** the body contains the labelled sections `Motivation:`, `Modification:`, `Result:` (Netty form). Other types may use free prose.
15. **Trailers are grammar, not prose:** `Closes #N` / `Fixes #N`; `Refs: ADR-NNN` whenever an ADR is touched or relied on; `Claim: <id>` when a benchmark claim changes state; `Co-authored-by:` for AI assistance is kept as provenance (see §I).

### E. Pull requests


16. **One PR template for every repo**, starting with Motivation / Modification / Result and continuing with: **Scope class** (`runtime hot path | runtime non-hot | test-tooling | docs-only`), **Wall impact** (`none | <edge>`), **Generated files touched** (`yes | no`, SDK-using repos only), **TCK obligation** (`satisfied | debt #N | n/a`), **Compatibility impact** (`none | additive | breaking (ADR-NNN)`), **Cross-repo impact**, **ADRs referenced**, **Evidence state** for any number (`citable | unartifacted | n/a`), and an optional `Release note:` line.
17. **The body checker verifies presence and parseability of the headings and trailer lines, nothing more.** Substance is reviewed, not linted.
17a. **Issues are the input side of the same conventions** (added 2026-09-05, see Amendments). Four forms and no blank issues; issue titles use commit grammar so they can become pull-request titles unchanged; labels come from one organisation taxonomy applied additively; and a review finding the pull request does not resolve is filed as an issue before it merges, which is what makes the monthly audit able to count debt rather than estimate it. `standards/issue-conventions.md` holds the rules; `exeris-systems/.github` holds the forms, the taxonomy and the two workflows.

### F. Javadoc

18. **Prose rules are the Oracle doc-comment conventions**: summary first sentence; third-person declarative; implementation-independent; `@param` on every parameter, `@return` on every non-void method, `@throws` for checked exceptions and for unchecked ones a caller would catch; no restating the signature; `{@code}`/`{@link}` over HTML.
19. **Tag vocabulary:** `@implSpec` for what an implementer must honour, `@apiNote` for caller guidance, `@implNote` for facts about the current implementation, `@since` on every public element of a released module. `@author` and `@version` are banned (Git is the author record). Examples use `{@snippet}`, never pasted `<pre>` blocks.
20. **Contract lines on SPI types that touch buffers, memory or threads:** the type-level comment states, in this order, **Allocation** (`zero-alloc on hot path | allocates`), **Thread confinement** (`owner thread | any thread | virtual-thread-safe`), **Ownership** (who releases; `LoanedBuffer`/`MemorySegment` semantics).
21. **Gate:** `maven-javadoc-plugin` with `failOnWarnings=true` on `exeris-kernel-spi`, `exeris-sdk-annotations` and every module published to Maven Central (the SDK configuration is the port target); Checkstyle Javadoc modules `JavadocType`, `JavadocMethod`, `JavadocStyle`, `NonEmptyAtclauseDescription`, `AtclauseOrder` (order `@param @return @throws @since @see @deprecated`) and a warning-level regexp for history in a doc comment (§F.12), shipped in `exeris-systems/.github`. Kernel Core and everything else: diff-aware only.

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

29. **`AGENTS.md` is the canonical agent-instruction entry point per repo; `.agents/` is the canonical semantic source.** `AGENTS.md` is concise and points to policies, Agent Skills (`.agents/skills/*/SKILL.md`), role profiles, workflows and authoritative references. Provider directories (`.claude/`, `.github/`, `.codex/`, `.cursor/`, `.gemini/`) are thin adapters or provider-owned operational configuration, never independently authored copies of project rules. Rules already enforced by CI are not repeated in agent files. The precise schema and migration policy live in `../standards/agents-md-schema.md` (historical filename retained for stable links).
30. **AI provenance policy:** AI-assisted commits keep the `Co-authored-by:` trailer; the human author is accountable for every line and must be able to defend it in review; agents do not open PRs or file issues without a named human author. Recorded in `standards/ai-provenance.md`, linked from every `CONTRIBUTING.md`.

### J. Enforcement layering

31. **L1 (CI, hard):** commit format (`commitlint`); PR body headings; frontmatter schema; ADR/RFC filename regex and registry-row presence; link check (`lychee`) including public→private path detection; Javadoc gates of §F.21; japicmp (ADR-065); Category-B files edited without regeneration marker.
32. **L1 (CI, warning):** Vale with the Exeris style (seeded from Quarkus's package plus the terminology in each repository's registered drift patterns (`exeris-docs/.agents/policies/drift-patterns.md`)); `markdownlint`.
33. **L2 (Claude review):** a `docs-guardrails-review` step added to the `pr-review.md` router — a Claude Project document maintained outside the git repositories, whose patch is drafted and staged alongside the guardrail bundle together with the review routine itself; findings adopt a new bracketed severity tag **`[DOC DEBT]`**, added after the existing `[TCK DEBT]` tag in that document.
34. **L3 (checklists):** `standards/checklists/{pre-pr,doc-page,adr,release-notes}.md`, each ≤ 10 questions. Not gated.

### K. Contributor terms

35. **DCO.** External contributions require a `Signed-off-by` trailer, enforced by the DCO GitHub App with organisation members exempt. `CONTRIBUTING.md` states the licence each module is offered under *(added 2026-09-05: and the contributor-terms instrument that repository asks for, if any — a decision owned by the private business decision registry, not by this ADR)*. ~~No CLA.~~ *(withdrawn 2026-09-05 — see `## Amendments`.)*

### L. Explicitly deferred

36. Enterprise-private documentation site (trigger: first commercial customer needing docs outside the repo; path: Cloudflare Access on a second Pages project). Versioned docs per release line (trigger: Kernel 1.0 GA). Both require an amendment, not a new ADR.

## Consequences

### ✅ Positive Outcomes

- **2026-09-05 — §F.21's Javadoc gate becomes real, gains a history rule, and moves house.** The
  Checkstyle Javadoc modules were described as living in `exeris-kernel-build-config`; they ship in
  `exeris-systems/.github` and the gate reads them from the checkout, because a ruleset copied into
  each repository is a ruleset that drifts. The module set gains a warning-level regexp for
  `javadoc-conventions.md` rule 12, which until now carried an `[L1 (planned)]` marker — a claim
  about a check that did not exist. It warns rather than fails because whether a sentence is
  archaeology or a statement about the present is a reviewer's call, and its token list is anchored
  by measurement: unanchored it fires 36 times on `exeris-kernel-spi`, 21 of those on `no longer`
  alone and nearly all correct; anchored, twice, both genuine.

- **[+] One URL space for the nine public repositories eligible under §A.3** without moving a single document; the ai-bridge and GitHub readers are unaffected because the site is a projection.
- **[+] Drift becomes a build failure**, not a session finding: filenames, registry rows, private links, missing metadata and broken links stop at CI, where Quarkus's structural gates stop them.
- **[+] The kernel's Javadoc reaches the standard the SDK already meets**, and SPI contracts state allocation, threading and ownership in a form implementers can rely on — a differentiator no reference project has.
- **[+] Agent instructions have one source per repo**, ending the four-way duplication found in the inventory.
- **[+] External contribution has stated terms** on the day the licence PR lands.

### ⚠️ Trade-offs

- **[-] Frontmatter on ~250 public files and ~1,150 in budgetHQ.** A scripted backfill (title from H1, type from directory, `last-verified` = last commit date) is required before the error-level gate can be enabled; until then the validator runs in warning mode on unchanged files and error mode on changed ones.
- **[-] ~160 kernel doclint findings, across `spi`, `core` and `community` combined** (`exeris-kernel/pom.xml`, release-profile comment). The SPI-only subset that §F.21's gate actually requires has not been counted separately and must be measured before `failOnWarnings` is turned on there. Bounded, but real work on a module under active 0.12 development.
- **[-] Subject-length and body-structure rules will reject the current house style** for `feat`/`fix` commits until authors and skills adopt the three-section body. Expect a fortnight of friction.
- **[-] Docusaurus builds are slower than a static-Markdown pipeline**, and its React toolchain is a new dependency for a JVM organisation; mitigated by CI caching and by the named Starlight alternative.
- **[-] Cloudflare concentrates DNS, public site and future private site**; GitHub Pages remains a same-day fallback because the hostname is owned.
- **[-] Every repo gains a workflow caller and a PR template**; twenty small PRs, one per repo, plus the org `.github` repo.

### 📋 What is NOT in scope

- The content and voice of any individual document; the review checklists (L3) are filters, not rules, and live outside this ADR.
- The claims/evidence methodology (`exeris-benchmarks/docs/CLAIMS.md`) — referenced, not changed.
- The 0.12 licence change itself (kernel release work) and the copyright-holder update after the sp. z o.o. registration.
- Landing-site domains (`exeris.systems`, `exeris-kernel.io`) — landing work; only `docs.exeris.eu` is fixed here.
- Business ADRs (`BUS-NNN`) and portfolio-product internal namespaces.

## Amendments

- **2026-09-05 — §E gains 17a: issues.** The ADR covered commits, pull requests, Javadoc, ADRs,
  changelogs and agent files, and said nothing about the tracker they all flow from. §C.10 scopes
  `standards/` to "the standards listed in §D–§I", so a tenth standard had no section to rest on:
  `issue-conventions.md` was drafted citing a *proposed* §E.17a, which is not an authority. This
  amendment writes it. Nothing already decided changes — §E.16 and §E.17 stand as written, and the
  pull-request template is untouched. What is new is that the input side is now governed: the forms,
  the label taxonomy, and the rule that a `[DOC DEBT]` or `[TCK DEBT]` finding becomes a filed issue
  rather than a line in a PR thread. Alternative considered and rejected: leaving issues ungoverned
  on the grounds that a solo repository has few of them — rejected because the monthly audit of §J is
  specified to count debt, and it cannot count what was never filed. (PR #96)
- **2026-09-05 — §K.35's "No CLA" is withdrawn; contributor licensing is not this ADR's to decide.**
  The sentence was written on 2026-09-04, one line inside a documentation-and-hygiene ADR, and it
  settled a commercial and IP question: whether a contributor licence agreement is asked for at all.
  Two rules already said it could not. Business decisions — legal, IP, financial, procurement — are
  kept in the private business decision registry, and a public tech ADR invokes such a policy
  descriptively rather than deciding it. That registry held no decision on contributor terms when
  §K.35 was written, so the sentence was not even restating one; the contribution policy is
  recorded there as of this amendment. And §C.10 makes `standards/` the home of the standards
  listed in §D–§I, while `ai-provenance.md` is created by §I.30, whose mandate is exactly three
  things: the `Co-authored-by:` trailer, human accountability, and agents not opening pull
  requests. Contribution terms are in none of them.
  The substance was wrong for an open-core organisation as well. A DCO sign-off and a contributor
  licence agreement are not alternatives and do not overlap: the trailer certifies origin per commit
  and grants nothing, while the agreement is the instrument that grants the right to place a
  contribution in the Enterprise tier — a right Apache-2.0 §5 inbound-equals-outbound does not
  supply, which is the entire reason an open-core project asks for one. The founder's contribution
  strategy of 2026-05-13 targets both, and `exeris-kernel`'s `CONTRIBUTING.md` had stated the
  agreement and its reasoning since before this ADR was written, so §K.35 contradicted a live
  repository policy it never cited.
  What changes: §K.35 keeps the `Signed-off-by` requirement and the obligation that `CONTRIBUTING.md`
  states the licence each module is offered under, gains the obligation to state the contributor-terms
  instrument, and loses "No CLA"; `ai-provenance.md` loses its "Not a CLA" bullet and rule 7 now says
  what a sign-off does and does not do. No gate config moves — §K.35's `[L1]` is the DCO App, which
  checks the trailer either way. Alternative considered and rejected: keeping "No CLA" and treating
  `exeris-kernel/CONTRIBUTING.md` as the defect, which would remove the only instrument that makes
  the Enterprise tier lawful for external contributions, on the authority of a documentation ADR.
  (PR #95)

- **2026-09-05 — cross-repo links are absolute and name a branch; §A.2's "relative links resolve
  unchanged" is narrowed to intra-repo links.** The first live `docs-lint` run reported 118 broken
  links in this repository, 92 of them in `adr-index.md`. Every one was a cross-repo reference
  written as a sibling-layout path, the form `docs-style-guide.md` rule 8 mandated because §A.2
  assumed the federation build would make it resolve. It resolves only in a workspace holding every
  sibling repo, so on github.com and in a single-repo CI checkout all 118 were dead, and `site/`
  holds no tracked files yet. No target was wrong; all 96 cross-repo targets exist. (The 97 org
  URLs the repository now carries are those 96 plus one pre-existing link to a pull request,
  which is not a cross-repo document reference.) A cross-repo link is now an
  absolute `https://github.com/exeris-systems/<repo>/blob/<branch>/<path>` URL naming the branch
  that carries the file. It is the only form correct on every surface at once: readable now, and
  mechanically convertible later, whereas no build can repair a sibling path for github.com.
  §A.2 is not rewritten — the layout mirroring it decides still governs intra-repo links and the
  shape of a site URL. What it gains is an obligation: the federation build must rewrite these
  org URLs to internal routes from the same `sources.yml`, so the site keeps in-site navigation.
  Whether `onBrokenLinks` and `onBrokenMarkdownLinks` cover routes produced by a remark rewrite is
  the design intent but is unverified, because `site/` does not exist; if they do not, the plugin
  validates its own targets. Either way this is an acceptance obligation on `site/`, not an option.
  Side effect: §23 becomes mechanically checkable, because a relative path carries no branch while
  this form does — six kernel ADRs (071, 073, 074, 077, 080, 083) were rows claiming
  `development/0.12.0` beside a link that does not resolve on `main`. Consequence for the gate: the
  link check now leaves the checkout, and `lychee.toml` accepts 429, so a rate-limited run passes
  silently — the lychee step needs `GITHUB_TOKEN` for the check to be real. Alternative considered
  and rejected: keeping the relative form and excluding it from `lychee`, which leaves 92 registry
  rows dead for every reader on github.com and removes the only check that would catch a wrong
  path. (PR #93)

- **2026-09-05 — `adr-conventions` rule 8 now names the decorated section headings the corpus uses.**
  Rule 8 was written on 2026-09-04 naming `### Non-Goals` and `### Risks and Assumptions` as literal
  strings. The ADR corpus does not write headings that way: 74 of its 80 files carry a leading emoji,
  `### 🏁 The Decision` 61 times, `### ⚠️ Trade-offs` 47, `### ✅ Positive Outcomes` 45 and
  `### 📋 What is NOT in scope` 38. The template the rule was written alongside already used the same
  form for the two new sections, so the rule created an exception in one file rather than describing
  the practice. It now names `### 🚫 Non-Goals` and `### ⚠️ Risks and Assumptions` and says which
  existing headings it is matching. Nothing about which sections an ADR must carry changes, and no
  gate config moves — rule 8 is `[L2]`. Alternative considered and rejected: stripping the emoji from
  all 74 files, a corpus-wide diff across five repositories for a style the owner authored
  deliberately. (PR #91)

## Cross-references

- ADR-020 (Open-Core Documentation Boundary & Cross-Repo Mirror Policy) — visibility model this ADR builds on; §A.3 and §G.24 make it machine-checked.
- The forms, taxonomy and workflows §E.17a names live in `exeris-systems/.github`, which is an
  organisation repository rather than a documentation one and so carries no ADR of its own.
- ADR-025 (AI Agent Bridge) — the agent surface reads repos; §A keeps `<repo>/docs/**` and `adr-index.md` as the contract.
- ADR-065 (SPI Compatibility Gate) — §H.28 adds the justified accepted-changes file.
- ADR-008 (Open-Core Strategy), ADR-023 (Capability Licensing Taxonomy) — to be amended when the 0.12 licence change reaches `main`. The relicense itself is done: `development/0.12.0` carries plain Apache-2.0 and it ships with the 0.12 merge; `main` still carries Apache-2.0 + Commons Clause until then. §K reads as written from that merge onward.
- The option comparison behind §A, §J and §K — internal working material, not part of this repository.
- The Phase 0 inventory of what the repositories do today, the reference analysis of OpenJDK, Spring, Quarkus, Micronaut and Netty, and the generator spike — evidence. All three are local-only working material and are deliberately not part of the repository, so they are named rather than linked.
- External: Oracle "How to Write Doc Comments for the Javadoc Tool"; JDK-8008632 (`@apiNote`/`@implSpec`/`@implNote`); Conventional Commits 1.0; Keep a Changelog 1.1; Diátaxis; Netty "Writing a commit message".

## Engineering Protocol

Existing repos do **not** comply; this ADR is prescriptive. Migration owner: founder. Target window: standards and gates within four weeks of acceptance (plan Phases 3–4), rollout over the following four (Phase 5).

1. **Registry (before acceptance):** reserve 085 in `adr-index.md`; add the cross-repo-stubs row listing `.link.md` stubs in every public repo (`exeris-kernel`, `exeris-sdk`, `exeris-spring-runtime`, `exeris-tooling`, `exeris-platform`, `exeris-ai-bridge`, `exeris-benchmarks`, `exeris-caps-cors-policy`) and *(private repo)* markers for the enterprise repos; mark rows 071/073/074/077/080/083 `pending merge` or merge `development/0.12.0` docs to `main`; replace ADR-018's relative link into `exeris-telemetry-spec` with a *(content private)* marker.
2. **Phase 3 — standards** (`exeris-docs/standards/`): `commit-conventions.md`, `pr-conventions.md`, `javadoc-conventions.md`, `docs-style-guide.md`, `readme-skeleton.md`, `adr-conventions.md`, `changelog-conventions.md`, `agents-md-schema.md`, `ai-provenance.md`, `claims-and-evidence.md` (thin), `checklists/*.md`; extend the kernel skills `exeris-pr-preflight`, `exeris-docs-adr-check`, `exeris-adr-register` rather than adding a new surface; update `ADR-TEMPLATE.md` and `RFC-TEMPLATE.md` per §G.26.
3. **Phase 4 — enforcement** (`exeris-systems/.github`): reusable workflows and configs of §C.11; frontmatter validator modelled on Quarkus's `YamlMetadataGenerator` (errors to the step summary, exit 1); registry validator (§G.23–24); `docs-guardrails-review.md` routine and the `[DOC DEBT]` line in `pr-review.md`; DCO app installed at organisation level.
4. **Phase 5 — rollout:** pilot `exeris-sdk` (Javadoc: already passes) and `exeris-kernel` (commit/PR gates) in warning mode for two weeks, then hard; fan out via workflow callers; frontmatter backfill script run per repo; site live at `docs.exeris.eu` from `sources.yml` with strict link mode enabled once item 1 is done.
5. **Phase 6 — upkeep:** `docs-guardrails-audit.md` monthly routine (re-run the Phase 0 inventory script, diff, report `[DOC DEBT]` count and age); `doc-drift-check.md` written to use `last-verified`.
6. **Domain cleanup (tracked as `[DOC DEBT]`):** JSON-schema `$id` in `exeris-benchmarks` (`exeris.io` → `exeris.eu`, schema version bump + changelog); landing targets aligned to `exeris.eu` before the landing ships.
7. **Acceptance criterion for closing this ADR's protocol:** every public repo has the PR template, a `CONTRIBUTING.md` linking the standards and the DCO paragraph, a schema-conformant `AGENTS.md` and `.agents/` where it exposes reusable agent behaviour, frontmatter on every file under `docs/`, the four reusable workflows green, and the site building with `onBrokenMarkdownLinks: 'throw'`.
