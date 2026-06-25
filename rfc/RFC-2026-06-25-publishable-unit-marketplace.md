# RFC-2026-06-25: Publishable-unit / marketplace surface — what does the ecosystem need beyond the composition model (ADR-024) and the licensing taxonomy (ADR-023), and which repo owns each part?

| Field             | Value                                                                 |
|:------------------|:----------------------------------------------------------------------|
| **Status**        | **DRAFT**                                                            |
| **Author(s)**     | arkstack-dev                                                          |
| **Date Opened**   | 2026-06-25                                                           |
| **Date Closed**   | —                                                                    |
| **Scope**         | platform / cross-repo (binds the capability + SKU layers, the codegen pipeline, the Studio marketplace surface, and the SDK source model) |
| **Owning Repo**   | `exeris-docs` (cross-cutting strategy; an ecosystem question, not an SDK-internal one) |
| **Target ADR(s)** | TBD — a platform-scope "publishable-unit / marketplace" ADR alongside [ADR-024](../adr/ADR-024-capability-composition-model.md) / ADR-023, plus *at most* a thin SDK-side "catalog facet" ADR (sibling to ADR-024's deferred "concrete annotation classes" SDK follow-up). Numbers reserved in [`adr-index.md`](../adr-index.md) only once the build gate opens. |
| **Affected Repos**| `exeris-docs` (this strategy + the eventual ADR + HLA/whitepaper alignment), `exeris-sdk` (the thin optional catalog/discovery descriptor — the only candidate SDK slice; see the [presentation/front RFC](../../exeris-sdk/docs/rfc/RFC-2026-06-25-presentation-front-model.md) for the front facet), `exeris-tooling` (catalog extraction alongside the ADR-024 cap-manifest emission), `exeris-platform` (Studio marketplace / catalog UI + the composition runtime that already exists per ADR-024). **Commercial terms — pricing, licence enforcement, IP-detachment mechanics — are owned by the private business decision registry and are referenced here descriptively only, never encoded in this public RFC.** |
| **Reviewers**     | —                                                                    |

## Question

The platform's direction is a **marketplace**: third parties author and sell their own capabilities, SKUs, and even kernel subsystems (the kernel is versatile / composable by design). A large part of the machinery this needs **already exists or is already decided**: the capability composition contract (`@Provides` / `@Requires` / `@CapabilityModule` / lifecycle, composition manifest, validation stamp, content binding — [ADR-024](../adr/ADR-024-capability-composition-model.md)), the licensing taxonomy and its *contractual-not-technical* enforcement (ADR-023), the Code-Detachment / IP-sovereignty policy (whitepaper §5.4 / §6, private business registry), and the entity (ADR-003) + presentation (the SDK [presentation/front RFC](../../exeris-sdk/docs/rfc/RFC-2026-06-25-presentation-front-model.md)) facets that make up a unit's *content*. **So the question this RFC answers is narrow and honest: does a marketplace need anything those decisions do not already provide — and if so, exactly what (a discovery/catalog descriptor?), owned by which repo, and with what commitment/timing — without duplicating ADR-024's composition manifest or ADR-023's licensing, and without dragging commercial policy into any public, source-retention surface?**

## Context

This is asked now because the direction is being mapped while the SDK milestone is light, so the productive move is to *pin the marketplace direction and each repo's slice on paper* — the same design-now / build-on-usage discipline the SDK's universe and declarative-behaviour RFCs used. It pairs with the SDK presentation/front RFC opened the same day, which established the **two-facet model**: a generated artifact has a *backend facet* (data/API) and a *front facet* (presentation), each independently present or absent (entity-driven, composition, front-only, API-only). A **publishable unit** is precisely a packaging of some combination of those facets: an API-only cap (backend, no front), a full SKU (backend + front), a front-only template/theme (front, no backend), a kernel subsystem (a substrate-level backend unit). The marketplace is the commercial+discovery layer over units so shaped.

The decisive constraint is that **the heavy machinery is already placed, and placed across specific repos on purpose.** ADR-024 makes composition a build-time concern owned by `exeris-tooling`, the composition manifest a SKU-repository convention, and — critically — `@CapabilityModule` a **pure marker with no metadata**: a cap's *identity* comes from its repository coordinate and the licensing taxonomy, explicitly *not* from an annotation attribute. ADR-024's own "what is NOT in scope" defers the concrete annotation classes to a separate `exeris-sdk` ADR and the manifest format to the SKU convention. So any marketplace surface must slot *beneath* those decisions, not re-open them. The wrong answer here is a "publishable-unit manifest" — in the SDK or anywhere — that duplicates the ADR-024 composition manifest, re-encodes ADR-023 licensing, or — worst — pulls pricing / detachment terms (private business policy) into a public artefact.

The other constraint is honesty discipline: a published `0.x` surface with no consumer is a regression on arrival. The marketplace and the first `exeris-caps-*` / `exeris-sku-*` repositories are H1-2027→2028 targets (ADR-024 Engineering Protocol; whitepaper §7 Track B); none exist on disk today. So whatever slice any repo owns is **designed now, built when the marketplace and a real unit corpus exist** — the same gate as the presentation RFC.

This RFC's deliverable is therefore the **map of the marketplace direction + the per-repo ownership split + the public/private boundary**, plus an explicit build gate — not a shipped surface.

## Investigation

### Prior art

- **Within the ecosystem (already decided)** — ADR-024 (composition model), ADR-023 (licensing taxonomy, contractual enforcement), ADR-015 (codegen emission, `exeris-tooling`), ADR-020 (open-core doc boundary), HLA §4 (capability composition) + §3.2 SKU families, whitepaper §3.2 (cap inventory with licence tiers) / §5.4 / §6 (detachment + sovereignty). These *are* the marketplace's backbone; this RFC adds nothing to them.
- **Within the SDK source model** — `@CapabilityModule` (pure marker, no name/metadata — by ADR-024 decision), `@Provides` / `@Requires` / `@CapabilityLifecycle` (the backend-facet composition surface, 0.4.0); `@ExerisDomain` + `@Action` (the data/API backend facet, ADR-003); the presentation IR (the front facet, the SDK RFC). Between them, a unit's *content* is already (or will be) fully source-describable. What is **not** describable from source today is a unit's *catalog/discovery presentation* — the human-facing "what is this, what does it give me, what does it look like" a buyer or Studio browses before composing.
- **The design-now/build-on-usage discipline** — the universe and declarative-behaviour precedents: settle the shape, ship behind a real consumer (or reserved with an honesty note) only when the informing usage lands.
- **External shape-setters** — every plugin/extension marketplace (VS Code Marketplace, JetBrains, npm, Shopify/WordPress) separates three concerns the platform has already separated too: **(1) the contract** (what the unit provides/requires — ADR-024 here), **(2) the licence/commerce** (pricing, terms — ADR-023 + private business policy here), and **(3) the listing/catalog** (display name, summary, category, media, screenshots — *the only one with no home in the ecosystem yet*). The consistent lesson: the listing is a thin, separate descriptor; folding it into the contract manifest (concern 1) is the classic mistake.

### Constraints

- **Do not duplicate ADR-024 / ADR-023.** Composition, identity, manifest, validation stamp, lifecycle, and licensing are decided and owned (tooling + SKU convention + the licensing taxonomy). A marketplace surface may *reference* a unit's facets; it must not re-encode the composition manifest or the licensing taxonomy.
- **Public/private boundary (load-bearing).** Pricing, licence-enforcement mechanics, and IP-detachment terms live in the private business decision registry (per the ecosystem ADR-registry rule). No public artefact — least of all a `@Retention(SOURCE)` annotation — carries commercial terms; at most a neutral licence-tier *tag* already implied by ADR-023, and even that is questionable (see Open questions). The catalog facet is *discovery presentation*, not commerce.
- **Zero runtime coupling + wire-format (ADR-037) + parity (ADR-042)** (for any SDK-side descriptor) — records/strings, additive, by-name, round-tripped; `-io` reads it only once the processor writes it.
- **Inert-attribute honesty.** No marketplace surface ships before a consumer (Studio catalog / tooling catalog emission) exists, or it ships reserved with an honesty note — and only once a real unit corpus exists.

### Data gathered

- No publishable-unit / catalog / listing descriptor exists in any repo today — greenfield, and the *only* greenfield slice (the contract, licensing, and detachment slices are already specified).
- The first `exeris-caps-*` (H1 2027), first `exeris-sku-*` (Q2 2027), and the marketplace itself (later) do not exist on disk. The build trigger is **not** met.
- The presentation RFC's 2×2 already gives the marketplace its unit taxonomy; this RFC does not re-derive it.

## Options Considered

Fixed by ADR-024/023: composition/identity/manifest/licensing are owned (tooling + SKU convention + licensing taxonomy); commercial terms are private; the entity + capability + presentation facets are the unit's content. The genuinely open fork is **what — if anything — any repo adds for discovery/catalog, and where.**

### Fork 1 — does the ecosystem need a marketplace descriptor at all, what kind / timing

#### Option A: A full publishable-unit manifest (in the SDK or a new surface)

A surface carrying unit identity, version, composed units, licence tier, compatibility, (and the temptation of) pricing/detachment hooks.

**Pros:** one "publishable unit" object.
**Cons:** directly duplicates the ADR-024 composition manifest and `@CapabilityModule`'s deliberate no-identity decision; re-encodes ADR-023 licensing; and structurally invites commercial policy into a public artefact — the exact public/private violation the registry rule forbids. Wrong layer on three counts.
**Cost:** high; high regret; conflicts with accepted ADRs.

#### Option B: A thin **catalog / discovery facet** only (SDK source model)

Add *one* new, optional concern — the **listing**: a unit's human-facing discovery metadata (display title, summary, category, tags, icon, an optional front-preview reference into the presentation IR). It attaches in the SDK source model to whatever carries a unit (a `@CapabilityModule` cap, an SKU root marker, or a presentation `@View` for templates) and references — never re-encodes — the facets and the licence tier. Composition, identity, manifest, and licensing stay exactly where ADR-024/023 put them.

**Pros:** fills the one genuine gap (concern 3, the listing) without touching concerns 1–2; keeps the public/private boundary clean (discovery, not commerce); makes a unit self-describing for a Studio catalog from source, consistent with Entity-First's "source is the SoT"; small additive surface.
**Cons:** still a new `0.x` surface that must not ship inert — so it pairs with Option-C timing; the scope-creep risk toward Option A must be actively resisted (the boundary is the deliverable).
**Cost:** low-moderate; the discipline is in holding the line at "listing only".

#### Option C (do-nothing-for-now / design-on-paper): Map the direction, pin the per-repo split as "facets already owned + (at most) a thin catalog facet", gate the build

Ship nothing this milestone. The deliverable is **this map**: the marketplace = ADR-024 (composition) + ADR-023 (licensing) + private business policy (commerce/detachment) + the entity & presentation facets (content) + *at most* a thin catalog facet (Option B) for discovery. Gate the catalog-facet build on the marketplace + a real `exeris-caps-*` / `exeris-sku-*` unit corpus.

**Pros:** discipline-consistent (universe / declarative-behaviour); avoids a fresh inert surface; resolves the "move now" ask as a *design* deliverable; the expensive part (the boundary against ADR-024/023 + public/private) is done now.
**Cons:** nothing ships; relies on the corpus arriving — mitigated by naming the gate and by the cost of waiting being zero (no unit repos exist yet).
**Cost:** lowest; the map *is* the deliverable.

### Fork 2 — where the catalog facet attaches (if Option B is built)

- **Option α: Extend `@CapabilityModule` with catalog fields** — but ADR-024 made it a pure marker on purpose (identity from repo coordinate, not annotation). Even though *display* ≠ *identity*, loading display fields onto it strains that decision and only covers caps (not SKUs or front-only templates).
- **Option β: A separate, optional `@Listing` / `@Catalog` annotation** (`@Target(TYPE)`) usable on a cap module, an SKU root, or a presentation `@View` — keeps `@CapabilityModule` a pure marker, separates discovery-presentation from the composition contract, and covers all unit kinds uniformly. → `CatalogMetadata(title, summary, category, tags, icon, previewRef)` AST record in the SDK source model.
- **Option γ: Catalog metadata only in tooling / SKU manifest, never in the SDK** — defensible given ADR-024 already put the manifest outside the SDK; but then Studio/LSP cannot render a catalog preview *from source*, losing the self-describing-from-source property the rest of the SDK has. Keep as the fallback if the corpus shows the listing is better authored in the SKU manifest than in source.

## Recommendation

**Adopt the Option C map now, with Option B (a thin catalog/discovery facet in the SDK source model) as the *only* candidate net-new slice and Fork 2 Option β (a separate optional `@Listing`/`@Catalog` annotation) as its shape — built later, gated on the marketplace + a real unit corpus. Nothing is added to composition (ADR-024), licensing (ADR-023), or commerce (private business policy); a publishable unit's *content* is the facets the SDK already owns or plans (entity/capability backend facet + presentation front facet), and the single genuine gap is the *listing*.**

The investigation's strongest finding is subtractive: the marketplace is mostly already decided, and decided across specific repos on purpose, so the honest net-new contribution is small and well-bounded. Mapping that explicitly is itself the valuable deliverable — it prevents the tempting Option-A mistake (a publishable-unit manifest) that would collide with ADR-024's manifest, ADR-024's deliberately metadata-free `@CapabilityModule`, ADR-023's licensing, and the public/private registry boundary all at once. Option B fills the one real gap (the listing / discovery descriptor) and nothing more; Option β keeps it a separate, optional annotation so `@CapabilityModule` stays the pure marker ADR-024 made it and so SKUs and front-only templates are covered uniformly. Option C timing is mandatory because no unit repositories exist yet — shipping a catalog surface now would be inert, and the corpus that should size its fields (which categories, which tags, what a front-preview reference must point at) does not exist.

The placement also follows the ecosystem rule that RFCs are repo-local to the decision owner: this is a cross-repo strategic question whose eventual home is a platform-scope ADR alongside ADR-024/023, so it lives in `exeris-docs`. The SDK keeps only the surface it genuinely owns — the presentation IR (front facet) and, later, the thin catalog facet.

### The marketplace map (pinned on paper)

| Concern | Owner | Status |
|:---|:---|:---|
| Composition contract (`@Provides`/`@Requires`/lifecycle, manifest, validation stamp, DAG) | `exeris-tooling` + SKU convention, per **ADR-024** | decided |
| Licensing taxonomy (community/commercial) + contractual enforcement | **ADR-023** | decided |
| Pricing, licence-enforcement mechanics, IP-detachment terms | **private business decision registry** | private; referenced descriptively |
| Unit *content* — backend facet (data/API) | `@ExerisDomain` / `@Action` (**ADR-003**) + capabilities (ADR-024), in `exeris-sdk` | exists / planned |
| Unit *content* — front facet (presentation) | presentation IR (SDK **presentation/front RFC**, IN-REVIEW) | designed, build-gated |
| Unit *listing* — discovery/catalog presentation | **this RFC — the one net-new gap** → optional `@Listing` facet in `exeris-sdk` | designed, build-gated |
| Marketplace UI, discovery, install/compose UX | `exeris-platform` (Studio) | future |

### Designed surface (decided on paper — not built)

- **`@Listing`** (working name; `@Catalog` alt) — `@Target(TYPE)`, `@Retention(SOURCE)`, **optional**, in `exeris-sdk`, placed on a `@CapabilityModule`, an SKU root marker, or a presentation `@View`. Attributes: `title` / `titleKey`, `summary` / `summaryKey` (i18n-key-friendly), `category` (opaque string), `tags` (`String[]`), `icon` (opaque key), `previewRef` (opaque ref into the presentation IR for a front preview, or `""`). **No** version, composed-units, licence-enforcement, or pricing attributes — those are ADR-024 / ADR-023 / private policy.
- **AST** — `CatalogMetadata(title, summary, category, tags, icon, previewRef)`; attaches as an optional facet on the relevant carrier metadata (`DomainMetadata` / a capability-module metadata / `PresentationMetadata`). Records, `@JsonInclude(NON_NULL)`, blank→null normalization, round-trip-tested.
- **Licence tier** — *not* re-declared here. If a catalog view needs the tier, it is read from the ADR-023 source of truth (the per-cap-repo licensing property / cap manifest), not duplicated onto `@Listing`. (Open question: whether even a read-only tier *tag* belongs on the listing for display convenience, or stays a tooling join.)
- **Parity** — `-io` reads `CatalogMetadata` only once the `exeris-tooling` processor writes it, in lock-step (ADR-042).

### Build gate — NOT yet met

Build when **both**: (1) a real **`exeris-caps-*` / `exeris-sku-*` unit corpus** exists to size the listing fields (categories, tags, what `previewRef` resolves to) — the first caps repo is an H1-2027 target (ADR-024 Engineering Protocol); and (2) a **consumer exists** — the Studio catalog UI or the tooling catalog emission — so the facet never ships inert. Until both land, this map is the deliverable.

### Why not the alternatives?

- **Option A (full unit manifest)** — duplicates ADR-024, contradicts the metadata-free `@CapabilityModule`, re-encodes ADR-023, and invites private commercial policy into a public artefact. Rejected on all four.
- **Option C-as-permanent (never build a catalog facet)** — viable *if* the corpus later shows the listing is better authored in the SKU manifest (that is Fork 2 γ); kept open, not pre-decided.
- **Fork 2 α (extend `@CapabilityModule`)** — strains ADR-024's pure-marker decision and only covers caps; β covers all unit kinds and keeps the marker clean.
- **Fork 2 γ (listing only in tooling)** — loses self-describing-from-source; kept as the fallback the corpus may select.

### Risks of the recommendation

- **Scope-creep from listing → manifest.** The single largest risk: an `@Listing` that grows version/composition/licence fields becomes the Option-A mistake. Mitigation: the boundary table above is the contract — listing carries *discovery presentation only*; anything else is ADR-024/023/private.
- **Public/private leakage.** A contributor adds a `price` / `licenseKey` attribute "for convenience." Mitigation: an explicit guard note in the catalog-facet ADR and the same `visibility-taxonomy` discipline used elsewhere.
- **The listing may belong in the SKU manifest, not source.** Genuinely open until the corpus exists; Fork 2 γ is the named fallback, so an early miscut costs no generated artifact to unwind (nothing ships before the gate).
- **Designing before the unit corpus exists.** Bounded by the additive-surface discipline and the build gate; field lists here are a hypothesis the corpus validates.

## Decision Record

<Filled in when status reaches ACCEPTED / REJECTED / WITHDRAWN. The build gate must open first.>

| Field            | Value                                                                  |
|:-----------------|:-----------------------------------------------------------------------|
| **Outcome**      | — (DRAFT)                                                              |
| **Date**         | —                                                                      |
| **Resulting ADR(s)** | TBD — a platform-scope marketplace ADR (next to ADR-024/023) + at most a thin SDK-side "catalog facet" ADR; numbers reserved in `adr-index.md` only once the build gate opens. |
| **Notes**        | —                                                                      |

## Open questions / follow-ups

- **Read-only licence-tier tag on `@Listing`?** Display convenience vs. single-source-of-truth (ADR-023). Default: join in tooling, do not duplicate. — owner: SDK roadmap; target: build gate.
- **Listing home — SDK source vs. SKU manifest** (Fork 2 β vs γ). Decide against the first real `exeris-sku-*` repository. — owner: SDK + tooling + SKU convention.
- **`previewRef` semantics** — exactly what a front-preview reference resolves to in the presentation IR (a `@View` name? a `PresentationMetadata` of `kind = FRAGMENT`?). — owner: coordinated with the SDK presentation/front RFC.
- **Kernel-subsystem units** — a marketplace "subsystem" unit is a substrate-level backend unit; whether it is describable through the same capability/listing surface or needs a kernel-side descriptor is a kernel + SDK question, not settled here. — owner: kernel + SDK.
- **Whitepaper / HLA alignment** — add a "marketplace = composition + licensing + listing + facets" framing to HLA §4 / whitepaper §3.2 once this RFC is accepted. — owner: `exeris-docs`.
