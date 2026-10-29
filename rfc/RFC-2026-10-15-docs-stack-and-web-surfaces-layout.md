---
title: "RFC-2026-10-15: The docs stack and the web-surfaces layout"
type: rfc
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-10-29
---

# RFC-2026-10-15: The docs stack and the web-surfaces layout — should docs.exeris.eu stay on Docusaurus, and how are the sites that make up the public web presence split across domains and repositories?

| Field             | Value |
|:------------------|:------|
| **Status**        | **ACCEPTED** |
| **Author(s)**     | arkstack-dev |
| **Date Opened**   | 2026-10-15 |
| **Date Closed**   | 2026-10-29 |
| **Target ADR(s)** | The [ADR-085](../adr/ADR-085-documentation-architecture-and-repo-hygiene-standards.md) amendment of 2026-10-29 (§A.2–A.5, §B.6); the domain split is recorded below and has no ADR of its own |
| **Affected Repos**| `exeris-docs` (ADR-085, a new `standards/messaging.md`), `exeris-web` (becomes a workspace), `exeris-benchmarks` (the lab's data source), `exeris-tooling` and `exeris-sdk` (the extraction path), the organisation `.github` repository (the community page's source) |
| **Reviewers**     | — |

## Question

[ADR-085](../adr/ADR-085-documentation-architecture-and-repo-hygiene-standards.md) §A.4 chose Docusaurus, hosted on Cloudflare Pages, for `docs.exeris.eu`. Since then the project has built a second site, `exeris.eu`, on its own generator stack. **Should `docs.exeris.eu` stay on Docusaurus (A), or be a docs app in the `exeris-web` stack (B) — and, whichever it is, how are the home page, the docs, the benchmark lab and the blog divided across domains, deploys and repositories?**

## Context

ADR-085 was written before any public site existed. Its generator comparison was a one-day build spike over the documentation corpus, and it fixed the hostname but nothing about how the docs site relates to the rest of the web presence. As of this RFC the Docusaurus site has not been built (`exeris-docs` has no `site/` directory) and `docs.exeris.eu` has no DNS record; the organisation's support page says so and deliberately does not link it. Nothing public depends on the choice yet, which is the cheapest moment to revisit it.

What changed is `exeris-web`. Its site-v1 pull request (exeris-web#1) generates `exeris.eu` from View IR documents with `@exeris/codegen-ts` 0.10.0, on Angular 22 and `@exeris/ui-kit`. It carries a claims gate (`scripts/check-content.mjs`, with a lock file), a readiness-wording gate, a same-origin-only Content-Security-Policy, a command palette, and a `build-meta.json` that pins the benchmark and docs commits it was built from. A docs site built in a different stack would have a different header, different tokens, no claims gate, and a second pipeline to maintain with one maintainer.

Two further questions arrive with the same decision. The first is where the benchmark evidence lives, because the evidence is large and the web presence needs a place for it. The second is how many repositories the sites need. Leaving them open means the first public promotion goes out onto surfaces that were each decided separately.

## Investigation

### Prior art

- **ADR-085 §A** is the existing decision: federated Markdown in each repository, aggregated by a Docusaurus build, with a build spike that resolved 424 of 489 relative links natively. It names Astro Starlight as the fallback if a full-corpus build exceeds ten minutes. It specifies a `sources.yml` of public repositories at a *source branch*, not at tags.
- **The `exeris-web` pipeline** (site-v1): `scripts/fetch-data.mjs` downloads upstream sources at a pinned commit and writes JSON the build reads; `build-meta.json` records the kernel release tag, the tooling version and artifact list, and the pinned `exeris-benchmarks` and `exeris-docs` commits; `scripts/build-index.mjs` builds a static search index from the views, the capability registry, the SKU table and a concept list; `src/app/shell/fuzzy.ts` scores queries against that index and `command-palette.component.ts` renders it.
- **An earlier landing-site prototype** (a private repository) has an evidence area (TCK status, TCK JFR, TCK JMH, micro and end-to-end benchmark pages) and a docs area whose navigation is Vision, Blueprint, The Contract, ADR Registry, Benchmarks, Spring Runtime, Research. Its information structure is reusable; its code is not (see Data gathered).

### Constraints

- The public site makes no third-party requests; `exeris-web` enforces `default-src 'self'` and `connect-src 'self'`.
- Every number on a public page is bound to a registered claim; `exeris-benchmarks/docs/CLAIMS.md` is the register, and retracted figures are never cited.
- Readiness wording follows the registry status column in [`cap-license-registry.md`](../cap-license-registry.md): nothing below *released* is described as sold, supported or hosted.
- ADR-085 §A.3: only public repositories are sources of the docs site.
- ADR-085 §A.4: switching hostname needs an ADR; switching host does not.
- One maintainer. Anything that multiplies pipelines, version bumps or review surfaces is a cost paid by the same person every time.

### Data gathered

**What `exeris-web` already has toward a docs app** (read from the site-v1 branch, `feat/site-v1`):

| Need | Present | Missing |
|:--|:--|:--|
| Shared header, footer, tokens | `shell/` components, `@exeris/ui-kit` theme | — |
| Numbers gate and readiness gate | `check-content.mjs`, `claims.lock.json`, readiness rules | Applies to `content/` and `src/content/` only; docs pages need the same walk |
| Search | static index plus fuzzy command palette over pages, SKUs, capabilities, concepts and doc links | Full-text over documentation bodies; per-version indexes |
| Pinned upstream data | `fetch-data.mjs` and `build-meta.json` | Fetching a repository's `docs/` at a tag, not a commit on `main` |
| Version metadata | kernel tag, tooling version, initializr artifacts | SDK version and the npm packages |
| Page model | View IR, 14 view documents | A page kind for navigation trees and for versioned Markdown |

**What View IR offers today** (`exeris-sdk` v0.12.0 source model, `exeris-tooling` v0.10.0 `codegen-ts`): `ViewMetadata` is `name, kind, route, title, titleKey, layout, regions`. `ViewKind` is `PAGE | SECTION | COMPONENT | FRAGMENT`. `BlockType` is `HERO | LIST | GRID | RICH_TEXT | NAV | SLOT | CONTAINER | CARD | FORM | IMAGE | CUSTOM`. There is no version field on a view, and `NAV` renders a flat `<nav>` with no tree. A docs page therefore maps onto today's IR only as a `PAGE` whose body is a `CUSTOM` block; a sidebar tree and a version field would be new IR vocabulary (for example a `NAV_TREE` block type, or a `DOC_PAGE` view kind with a version), which is an SDK and tooling change, not a site change.

**The lab's data** (measured on `exeris-benchmarks` `origin/main` at `5f8012d`, with `git ls-tree -r -l`, 2026-10-15):

| Under `results/` | Tracked files | Size |
|:--|--:|--:|
| `raw/` | 20,034 | 206.0 MiB |
| `constrained/` | 2,871 | 4.0 MiB |
| `reports/` | 41 | 2.7 MiB |
| `cold-start-ttfr/` | 58 | 0.2 MiB |
| **Total** | **23,005** | **213.0 MiB** |

No tracked file exceeds 25 MiB; the largest is 16.8 MiB, and three exceed 10 MiB. The registered claims are `L1` to `L14` in `CLAIMS.md`: 14 entries, one of which (`L6`) registers no copy. Cloudflare Pages allows 25 MiB per asset and, on the free plan, 20,000 files per site (100,000 on paid plans). The tracked `results/raw/` tree alone is over the free file-count limit, so publishing the repository's results tree as a Pages build does not fit the free plan, whatever its byte size; a site that renders per-report pages would carry the 41 reports and the claim-bound data, not the raw tree.

Working checkouts disagree with `origin/main`. A checkout of a research branch tracks 93 files under `results/` (84.5 MB) and holds about 4.7 thousand files (546 MB) once untracked raw logs are counted; there, two untracked logs (289 MB and 34 MB) exceed the 25 MiB limit. Those are local artefacts, not the published tree, and any figure for the lab must be measured at the pinned commit, not in a working checkout.

**What the earlier landing prototype does that this design must not copy** (verified in its source):

- Its data service fetches `raw.githubusercontent.com` and `api.github.com` from the visitor's browser, against `main` and `gh-pages`, with no version pin. That breaks the no-third-party-requests rule, is subject to GitHub's unauthenticated limit of 60 requests per hour per IP, and shows whatever `main` holds at that moment.
- Its docs page hard-codes figures outside any claims register: ten subsystem rows carrying a `VALIDATED` status, `11.4M ops/s` and `11,413,106 telemetry events/sec` in the telemetry row, `Pure Java 26` in the Community tier rules, and `>8,500 RPS/vCPU` in the Enterprise tier rule, in the decision text and in a target table. The site's baseline is Java 25, and none of these strings is bound to a claim.

### Spike outcomes

None. The comparison of A and B rests on reading both stacks, not on a prototype of B. §Open questions lists the spike that would test B's weakest point.

## Options Considered

### Option A: Docusaurus, as ADR-085 chose

`docs.exeris.eu` is a Docusaurus build in `exeris-docs/site/` over `sources.yml`, hosted on Cloudflare Pages. `exeris.eu` remains the separate `exeris-web` site.

**Pros:**
- Versioned docs, sidebar and full-text search come with the generator.
- The link-resolution spike is already done: 87 % of relative links resolve with no plugin.
- Well-trodden; contributors recognise the shape.

**Cons:**
- A second look. The header, footer and tokens are re-implemented in a React theme, and drift is a standing cost.
- A second pipeline with its own toolchain (React, MDX) in a JVM organisation, which ADR-085 itself lists as a negative.
- No claims gate. A number in a federated Markdown page reaches the docs site unchecked, unless a second gate is written for a second stack.
- Docusaurus versioning snapshots the docs of one repository; the federation is many repositories with different version lines, so per-tag aggregation is custom work in either option.

**Cost:** low to start; recurring cost in keeping two sites visually and editorially aligned.

### Option B: a docs app in the `exeris-web` stack

`apps/docs` is an Angular 22 app on `@exeris/ui-kit`, with the same header, the same claims gate and the same View IR pipeline as the home page. At build time it fetches each public repository's documentation at a Git tag, renders Markdown, and builds the version selector, sidebar and search index itself.

**Pros:**
- One look, one pipeline, one dependency set; the header and tokens are one implementation.
- The numbers gate and the readiness gate run on docs pages as well, so a figure in a repository's `docs/` cannot reach the site without a claim.
- Reuses the existing static search (`build-index.mjs`, the palette, `fuzzy.ts`), `fetch-data.mjs` pinning and `build-meta.json`.
- Docs become the second real consumer of `codegen-ts` and `ui-kit`, which is where their gaps are found.

**Cons:**
- Tag versioning, sidebar and search must be built; Docusaurus gives all three out of the box.
- The IR has no version field and no tree block (see Data gathered), so some of the work lands in the SDK and tooling.
- The link-resolution result in ADR-085 does not transfer; relative links across repositories need a resolver written and tested.
- Larger up-front cost, paid before the first docs page exists.

**Cost:** the three missing features, plus a Markdown renderer decision. Mitigated by building them in shared libraries first (see the layout below) and by launching with a small corpus, the quickstart.

### Option C (do nothing): keep ADR-085 as written and defer the layout

Build the Docusaurus site as specified; decide where the lab lives when it is needed.

This leaves the first public promotion pointing at two differently built sites and no stated home for evidence. It is acceptable only if the docs site stays small and is never promoted.

## The web-surfaces layout

This part holds under either option, apart from where the docs source lives.

### One job per domain

| Surface | Answers | Source |
|:--|:--|:--|
| `exeris.eu` | What is it, is it real, where next | `exeris-web` |
| `docs.exeris.eu` | How to use it, per version | the public repositories at their Git tags |
| The lab | What the evidence says | `CLAIMS.md` through the claims gate; raw artefacts in the benchmarks repository |
| GitHub | The code and contributions | the repositories |
| `arkstack.dev` | The author's engineering notes, a personal blog | its own repository |

### Three doors and a standing page

The home page leads with the initializr and offers three doors: **Try it** (the docs start page: the initializr command, the Maven coordinates under group `eu.exeris`, a first application in five minutes), **Verify it** (the lab) and **Adopt it** (design partners). A standing `/community` page collects what the organisation's `.github` repository already holds: `CONTRIBUTING.md` (including the DCO sign-off rule), the Code of Conduct, the `good first issue` label and the support page that says where a question, a bug or a conduct concern goes. The page links to those files; it does not copy them, so the organisation repository stays the single source.

### Lab placement: `labs.exeris.eu` or `exeris.eu/lab`

- **`exeris.eu/lab`** keeps one deploy and one navigation. It means the home page's build carries per-report pages, and every new report rebuilds the landing. The data above says the raw tree cannot ship in a Pages build, so the page would carry reports and claim-bound data only, and the raw artefacts would live elsewhere regardless.
- **`labs.exeris.eu`** is a separate app in the workspace with its own change rhythm (per report, with a pinned benchmarks commit), per-report pages, and raw artefacts browsed from object storage rather than from a Pages build. `exeris.eu` links to it and does not duplicate its content.

The proposed placement is the second. The information structure of the earlier prototype's evidence area (TCK status, TCK JFR, TCK JMH, micro and end-to-end benchmark pages) is the starting outline; its code is not reused.

### Repository layout: separate by deploy, not by repository

One workspace (the `exeris-web` repository), several Cloudflare Pages projects:

| Path | Deploys to | Data |
|:--|:--|:--|
| `apps/landing` | `exeris.eu` | authored views, `build-meta.json` |
| `apps/labs` | `labs.exeris.eu` | a pinned snapshot of `exeris-benchmarks` |
| `apps/docs` | `docs.exeris.eu` | the repositories at tags |
| `apps/blog` (later) | a blog domain | posts |
| `libs/shell` | — | header, footer, command palette |
| `libs/blocks` | — | view blocks and their registry |
| `libs/claims` | — | fetch, gate and lock: one implementation |

CI is path-scoped, so a report pull request builds the lab and not the docs.

Against four repositories: with one maintainer, a cross-cutting change (the header, the brand tokens, the claims gate, a shared block) becomes four pull requests and four version bumps. The usual reasons to split repositories are different visibility, licence or writers, and none of them holds today: all four surfaces are public, under the same licence, written by the same person.

Against one app: the surfaces differ in change rhythm and data source. The landing changes rarely; the lab per report; the docs per tag; the blog per post. One app would rebuild everything for each of them.

### Shared look and one message

All sites carry one header and one set of tokens and the same nav items (Docs, Lab, GitHub). Versions come from `build-meta.json`, which today holds the kernel tag and the tooling version with its artifacts; the SDK version and the npm packages are additions. One messaging source, `standards/messaging.md` in this repository, holds the brand line ("Intent in. Systems out."), a one-sentence description ("Exeris generates deterministic, verifiable JVM systems from structured intent."), three or four proof points each linked to a claim or an ADR, and the banned phrases for any status below *released*. Those phrases are enforced twice: as an Exeris Vale rule on prose here, and in `check-content` on site copy.

### Versioning, and the extraction path

Versioning applies to the docs only; the lab is pinned by commit and the landing is unversioned. Versioning, search and the sidebar are built first in `libs/` for the docs. When a second consumer needs them (the blog, or a customer site), they move into `@exeris/codegen-ts` and `@exeris/ui-kit` as generator features, together with the View IR vocabulary they need.

## Recommendation

**Adopt Option B with the workspace layout: `docs.exeris.eu` is an app in the `exeris-web` workspace, the lab is a separate app at `labs.exeris.eu`, and the domain split above stands.**

The deciding factor is not the generator but the gate. The project's central discipline is that a number on a public page is bound to a claim, and the site that enforces it already exists. Documentation is where figures are most likely to be copied in loosely, as the earlier prototype's hard-coded figures show; running the same gate on docs, under the same header, is worth more than the three features Docusaurus provides and B must build. Those three features are bounded work, and a quickstart-sized corpus lets them grow with the content. The workspace layout follows from the same reasoning: one maintainer, cross-cutting changes, no reason to split by repository.

Launch order: `docs.exeris.eu` with a working quickstart, so that "Try it" lands on a page that works; then the readiness gate and the SKUs and Open core rework in `exeris-web`; then `exeris.eu` goes public; only then the first public promotion.

**Option A is the better choice if** the tag-versioned corpus must be live before the three features can be built, if a second contributor appears who knows Docusaurus and not Angular, or if the spike below shows that cross-repository link resolution costs more in B than the gate is worth. In that case ADR-085 stands, and the layout, the lab placement and the shared messaging source still apply, with the docs app replaced by the Docusaurus site and a claims check added to its build.

This RFC proposes no SPI, wire format or consumer contract; there is no testable surface and the Testing section is omitted. The gate's behaviour on docs pages is tested the way it is for the landing: fixtures in the site's test suite.

### Why not the alternatives?

- **Option A** — keeps a second look, a second toolchain and a path with no gate for figures, to save work that is bounded and can be done once.
- **Option C** — leaves the first public promotion pointing at surfaces that were decided separately, with no stated home for evidence.
- **Four repositories** — four pull requests per cross-cutting change for one maintainer, with none of the reasons that justify the split.
- **`exeris.eu/lab`** — rebuilds the landing per report and still cannot hold the raw artefacts.

### Risks of the recommendation

- Building versioning, sidebar and search is more than a configuration file, and the docs launch depends on it. The mitigation is to ship a corpus of one page first and add features as the corpus grows.
- The IR gap (no version field, no tree block) may turn part of the docs work into SDK and tooling work, which has its own release cadence.
- Object storage for raw artefacts is a new piece of infrastructure, with a cost and an availability story that the benchmarks repository did not need.
- Cross-repository links resolve in ADR-085's spike because the build mirrors the sibling layout; a per-tag build must reproduce that, and the 87 % figure does not carry over.
- A single workspace couples the surfaces' dependency upgrades. Path-scoped CI limits the build cost but not the coupling.

## Decision Record

| Field            | Value |
|:-----------------|:------|
| **Outcome**      | Accepted: Option B with the workspace layout |
| **Date**         | 2026-10-29 |
| **Resulting ADR(s)** | The ADR-085 amendment of 2026-10-29: `docs.exeris.eu` is the docs application of `exeris-web`, and the list of published files is its `projects/docs/sources.json` |
| **Notes**        | The lab is at `lab.exeris.eu`, with a summary page at `exeris.eu/lab`. The docs read each source at `main` until the 1.0 releases, and at release tags, one version of the site per release, from then. The project blog is a later app in the same workspace; its relation to `blog.arkstack.dev` is undecided. The spike below was replaced by building the docs app: it renders the kernel, SDK, tooling and platform documents with links resolved through the list, without a version selector, which waits for 1.0. |

## Open questions / follow-ups

- Spike: render one repository's `docs/` at a tag in `apps/docs`, with a version selector and resolved relative links, and compare the effort with ADR-085's Docusaurus spike — owner: arkstack-dev, before the ADR.
- IR vocabulary: a `NAV_TREE` block type or a `DOC_PAGE` view kind with a version — an RFC or issue against `exeris-sdk` and `exeris-tooling` if B is accepted.
- Where the raw benchmark artefacts live, and under what retention — a follow-up decision with the lab app.
- Whether `standards/messaging.md` is its own pull request ahead of this decision, since the brand line and banned phrases apply to every option.
- The blog domain: `arkstack.dev` is the author's personal blog; whether a project blog is wanted at all is not decided here.
