# Layer build order — what is actually unblocked, and what is waiting on whom

The platform is built bottom-up, from kernel to Studio and platform integrations. That is the
strategy, and it is not in question here. What this document records is the **ordering constraints
between the layers** — which are not obvious from any single repository's roadmap, because most of
them are edges *between* repositories.

> **This is a snapshot of a moving target, and it will rot.** Every row below is stated against
> another repository's released state. Two rules keep it honest, both learned the expensive way:
> **re-verify a row whenever you edit it** — and check what a release *contains*, not merely that
> it exists; and **cite ADR obligation numbers, never another repo's roadmap line numbers**, since
> an accepted ADR does not move and a sibling roadmap renumbers at every milestone.
>
> Verified 2026-09-02 against: `exeris-kernel` v0.11.0 (dev 0.12.0), `exeris-sdk` v0.11.0,
> `exeris-tooling` v0.8.0, `exeris-platform` `0.4.0-SNAPSHOT` (no releases).

## The ordering

| Layer | Waiting on | Kind of blockage |
|:---|:---|:---|
| **Platform backend as an Exeris application**, and its generated front | nothing | — |
| **Control plane** — operator identity, delivery, cloud/git integrations | acceptance of [RFC-2026-09-02](rfc/RFC-2026-09-02-platform-control-plane.md) | a decision, not code |
| **`relationships` in `exeris/domainDescribe`** | an ADR — ADR-025 pins that method's wire shape for the agent bridge | process latency, not implementation |
| **Studio live editing** | kernel 0.12 (ADR-084, WebSocket provider SPI) | another repository's release |
| **Presentation IR / the CMS lane** | the presentation RFC's build gate (emitter + corpus) | partly self-created — see below |
| **Real SKU composition in Studio** | `exeris-caps-*` repositories; first is an H1-2027 target per ADR-024's Engineering Protocol | distant |

## Why the first row is first

It is the only layer with no upstream edge at all. `exeris-codegen-java` (30 generators — service,
repository, handler, saga, event, OpenAPI, Flyway, GraphQL sync, stream clients, and tests for
each) and `exeris-codegen-ts` (an Angular 21+ frontend generator: list, detail, form, view, store,
guard, routing, specs) both ship in `exeris-tooling` v0.8.0. `exeris-studio-backend` is a single
`package-info.java`, so there is nothing to migrate away from.

It also pays three times over. It is the dogfooding proof the layers above it rely on for
credibility; it gives `exeris-ai-bridge`'s `lsp:*` family a subject in that repository, which today
holds no `@ExerisDomain` source at all; and it produces a corpus of real page and composition
shapes.

**That last point is an argument, not a fact, and the distinction matters.** The presentation/front
RFC gates its build on (a) an Angular emitter being authored in tooling and (b) a corpus produced
by the **Headless CMS SKU / `content-types`** workloads — it names CMS specifically. A front
generated for the platform's own backend would be a *first* corpus, not the one that RFC points at,
so treating it as gate-opening is a deliberate widening of the gate and should be decided as one.
Two details to check before relying on it: that gate says "Angular 22 signal-first emitter" while
`@exeris/codegen-ts` describes itself as "Angular 21+", and whether those are the same artifact
evolving.

## The fronts do not accumulate

The count of layers overstates the concurrent load, which matters when the team is one person.

Rows one and five are **one engineering front** — the same `@ExerisDomain` definition emits the
backend and the front, and the corpus falls out of doing it. Row two is **a document**. Rows four
and six are **waiting**, not working. Row three is small implementation behind an ADR that can
mature in the background.

So the real parallel load is **one engineering front plus one decision**, not six tracks.

## One thing worth pulling forward

`relationships` in `exeris/domainDescribe` is small — the SDK's `DomainMetadata` already carries
`relationships`, `events`, `projections`, `eventHandlers` and more, while the platform's
`DomainDescription` projects only fields, actions and artefacts. But it is ADR-level, because
ADR-025's 2026-06-24 amendment pins the wire shape of that method for the agent bridge, and
ADR-level work has process latency rather than implementation latency. It sits on the critical path
of anything Studio ever renders from the model, so the ADR is better started while the layer below
it is being built than after.
