---
title: "RFC-2026-10-24: Where does pre-construction discovery live, and what does it produce?"
type: rfc
visibility: public
owning-repo: exeris-docs
status: draft
last-verified: 2026-10-24
---

# RFC-2026-10-24: Where does pre-construction discovery live, and what does it produce?

| Field             | Value |
|:------------------|:------|
| **Status**        | **DRAFT** (v1) |
| **Author(s)**     | Arkadiusz Przychocki (options analysis assisted by Claude) |
| **Date Opened**   | 2026-10-24 |
| **Date Closed**   | — |
| **Target ADR(s)** | ADR-DISCOVERY-BRIEF (new, owned by `exeris-sdk`: the brief contract; number reserved after acceptance); an amendment to **ADR-025** (stateless prompt templates, and `build-validate_brief`) |
| **Affected Repos**| `exeris-sdk` (the brief records and a processor-emitted schema), `exeris-ai-bridge` (`discover-requirements` prompt, schema resource, `build-validate_brief`), `exeris-docs` (this RFC), `exeris-ai-execution` (none now; a later consumer of derived metadata only) |
| **Reviewers**     | — |

## Question

Before an agent authors an `@ExerisDomain` entity or previews generation for an application developer, someone has to find out what is being built: who uses it, what it must do, which data it owns, what it must never do, and how anyone will know it is done. **Which repository owns that discovery stage, what artefact does it produce, and how does that artefact reach an agent working on a machine with no ecosystem checkout?** Four sub-questions, answered together because each constrains the next:

- **Q1 — Output.** Does discovery produce an artefact, and of what shape?
- **Q2 — Contract owner.** If the artefact has a schema, which repository owns it, and in what form?
- **Q3 — Delivery.** How does the procedure reach an agent: as data only, as an MCP prompt, as an agent-bundle skill, or as server-driven elicitation?
- **Q4 — The execution layer.** What, if anything, does `exeris-ai-execution` take from it?

The persona is P2, the application developer. Ecosystem contributors (P1) are out of scope: their questions already have Research, RFC and ADR, and no generator consumes a brief in an infrastructure repository, so a brief there would be a fourth decision document with no reader.

## Context

The P2 track of ADR-025 (2026-08-16 amendment) gives an application developer's agent the means to *build*: `sdk:*` for the annotation vocabulary, `build:*` for the project's own artefacts, `caps:*` for the composition manifest, and from 0.9.0 the `author-domain` prompt and `build-preview_generation`. Every one of them starts from the assumption that the agent already knows what to build. Nothing in the ecosystem covers the step before: an agent asked to "make an invoicing system" goes straight to entities, and the requirements it never asked about surface later as rework, or never surface.

The two candidate homes each look plausible and each is bounded against it. `exeris-ai-bridge` is the agent-facing surface, but ADR-025 states that the bridge "exposes *data*; agents bring their own *behavior*" and excludes authoring agent-facing prompts. The bridge's own 0.9.0 prompt list already sits uneasily against that sentence, and a discovery procedure is behaviour in the plainest sense. `exeris-ai-execution` is where task-level intelligence is headed, but ADR-086 bounds it to observation through V3, makes it a consumer of the agent layer rather than a host (§A.1–A.3), and holds its records to metadata only: "prompts, file content and tool arguments never appear in a run record" (§C.12). A requirements interview is content from its first sentence.

The cost of leaving the question open is that discovery gets built anyway, in whichever repository someone happens to be working in, and the artefact it produces becomes a second description of the domain beside the annotated class, which ADR-003 declares to be the only one.

## Investigation

### Prior art

- **ISO/IEC/IEEE 29148** (requirements engineering; successor to IEEE 830) and the **Volere** template fix the content a specification carries: stakeholders, goals, functional and non-functional requirements, constraints, acceptance criteria, open issues. The content list below is drawn from them, cut to what an Exeris generator can act on.
- **EARS** (Easy Approach to Requirements Syntax, Mavin et al.) constrains a requirement to a few templates (`WHEN <trigger> THE SYSTEM SHALL <response>`, plus `IF/THEN` and `WHILE` variants). It is the cheapest known way to make an acceptance criterion testable without a formal language.
- **GitHub Spec Kit** stages agent work as specify → (clarify) → plan → tasks → implement, each producing Markdown under `specs/<feature>/`, with a clarify step whose job is to close gaps before planning ([GitHub Spec Kit](https://github.com/github/spec-kit)).
- **Kiro** writes `requirements.md` (user stories with EARS acceptance criteria), `design.md` and `tasks.md` under `.kiro/specs/`, with approval gates between phases ([Kiro — Specs](https://kiro.dev/docs/specs/concepts)). Third-party guidance on it names the failure mode this RFC most needs to avoid: once the code and the spec can disagree, someone has to decide which one is true.
- **MCP elicitation** (spec revision 2025-06-18) lets a server ask the user for input mid-operation through the client. Form mode is limited to flat objects with primitive properties, and how the client presents it is not mandated ([MCP — Elicitation](https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation)).

What the prior art has in common: discovery produces a document, the document is checked before the next phase starts, and the tools that do it all stop at the drift question. Exeris has an answer to the drift question that they do not: ADR-003. The annotated class is the truth about the domain, so the brief must never become a second one.

### Constraints

- **ADR-003 (Entity-First, owned by `exeris-sdk`).** The `@ExerisDomain` class is the only definition of the domain; behaviour, validation and storage are declared by annotations on the entity itself. The source model those annotations produce is wider than fields: `DomainMetadata` carries fields, relationships, validations, actions, rules (`@Rule`), sagas (`@Saga`, `@SagaStep`), event sourcing (`@EventSourced`), schedules, channels, graph queries, route access, encryption, row-level security, data scope (`@SharedScope`, `DataScope`) and presentation (`@UI`, `@View`). An artefact that re-encodes any of that structure (a field list, an action signature, a saga's steps, a view layout) is a design file beside the source. ADR-003 rejects `.proto` and OpenAPI as source for exactly that reason.
- **`exeris-sdk` contracts are emitted, not hand-written.** `annotation-catalog.json` and `ast-schema.json` are produced by annotation processors (`AnnotationCatalogProcessor`, `AstSchemaProcessor`) from Java sources, deterministic and guarded by contract tests (`.agents/policies/javadoc-and-contract-emitters.md`). `exeris-sdk-source-model` holds records and depends only on `jackson-annotations` (`.agents/policies/zero-runtime-coupling.md`).
- **ADR-025.** No model API; read-only across all families; the bridge previews and never writes into the user's project (2026-08-16 amendment, item 4); zero-checkout is a first-class mode. Over the hosted Streamable HTTP endpoint only `docs:*`, `sdk:*` and `bridge:*` are served; `build:*` and `caps:*` are unavailable by construction (2026-09-30 amendment, item 2). A tool stays inside one family (`.agents/policies/tool-surface.md`). The "What is NOT in scope" clause covers prompts and behaviour.
- **ADR-086.** The execution layer observes before it routes; it is not a host for agent work (§A.3); its records are metadata only (§C.12); `workload.scope` is a closed vocabulary, never prose (§F.30); V0 emits no recommendation (§B.5).
- **Privacy.** A brief carries a customer's product intent. It must not leave the user's project through any surface the ecosystem operates.

### Data gathered

- `exeris-sdk` already defines the vocabulary a brief needs to state intent: `DataScope` is `GLOBAL | TENANT | UNIVERSE` (RFC-2026-06-24, ADR-059), and each structural concern above is a named annotation in the catalog. A brief can point at these names and reuse their enums without copying their shapes.
- `build:*` already joins bundled data with the user's project: `build-explain_artefacts` reads `exeris-tooling`'s vendored generator catalogue (ADR-097) against the project's emitted files. A tool that checks a project file against vendored SDK data is the same shape, inside the same family.
- The bridge has no prompt registered today. The 0.9.0 list holds four P1 and four P2 prompts, none of them a discovery step, and none yet reconciled with ADR-025's "What is NOT in scope".
- No published capability catalog exists (the catalog facet of RFC-2026-06-25 is not built). A project's own composition is readable: `exeris-sdk-composition-spec` defines `CapManifest`, and `caps-list_capabilities` reads the emitted `cap-manifest.json`.

### Spike outcomes

None. This RFC decides placement and contract shape. The risk that would be worth a spike is interview quality itself, which has no oracle (see §Testing).

## Options Considered

### Q1 — What discovery produces

**Q1-A: No artefact.** The agent asks questions in conversation and proceeds. *Pros:* nothing to build. *Cons:* nothing to check, nothing to resume, nothing a second session or a human reviewer can read. The requirements live in a transcript the next session does not have.

**Q1-B: A narrative document (PRD).** Markdown in the user's project, sections from 29148/Volere. *Pros:* familiar; humans edit it easily. *Cons:* not checkable by machine, so "discovery is complete" is a judgement every time; and nothing stops a section called "Data model" from growing field lists, which is the ADR-003 drift by the back door.

**Q1-C: A structured brief that references, never re-encodes.** One document per bounded area, `docs/briefs/<area>.brief.yaml` (or `.json`) in the user's project, carrying what the source model *cannot* carry:

- purpose, goals and explicit non-goals;
- actors and roles;
- a glossary of candidate domain terms: a name, a one-line meaning, a data-scope intent drawn from `DataScope`, and optional *concern hints*, which name catalog annotations (`UI`, `Saga`, `EventSourced`, `RowLevelSecurity`, …) and never carry their attributes;
- workflows as structured EARS criteria, each an object `{ kind: when | if | while | ubiquitous, trigger?, condition?, response }`, never one string;
- non-functional requirements (load, availability, retention, residency, compliance) and integrations;
- candidate capabilities by name;
- open questions, each `blocking: true | false` with status `open | assumed | resolved`; `assumed` requires a recorded `assumption` and an `owner`.

The brief is **ready** when no blocking question is `open`. An `assumed` answer unblocks the gate and stays visible as decided on credit. Once an entity, action, rule or saga exists, the brief element it came from may point at it with a typed reference: `fulfilledBy: { kind: entity | action | rule | saga, ref }`, where `ref` is the entity's qualified name or `<entity>#<name>`. The kind is part of the reference because `ActionMetadata`, `RuleMetadata` and `SagaMetadata` each carry a `name`, so `Invoice#issue` alone does not say which one it is. The source wins any disagreement. The EARS criterion stays as the requirement it was; the code is how it was met.

*Pros:* checkable; resumable; the readiness gate is mechanical; the shape itself enforces ADR-003, because the schema has no slot for a structure the source model carries. *Cons:* a contract to design and version; a structured form is heavier to fill than prose.

**Q1-D: An entity draft.** Discovery emits `@ExerisDomain` skeletons directly. *Pros:* no new artefact; goes straight to the source of truth. *Cons:* it collapses discovery into `author-domain`, and everything that is not an entity is lost: who the users are, what done means, what the system must never do, which non-functional constraints apply.

### Q2 — Who owns the brief contract

**Q2-A: `exeris-docs`, as a template beside ADR/RFC/Research.** *Pros:* where decision-document shapes already live. *Cons:* those templates are for the ecosystem's own decisions (P1). The brief is an application developer's artefact (P2), and its references point into SDK vocabulary that `exeris-docs` does not version, so the version coupling would be checked by convention.

**Q2-B1: `exeris-sdk`, as records with a processor-emitted schema.** The brief is a set of Java records in `exeris-sdk-source-model`, in a package outside `sourcemodel` (`eu.exeris.sdk.brief`), with a one-way dependency: `brief` may import enums from `sourcemodel.ast`, and nothing under `sourcemodel` may import `brief`. The records are held to the same wire-record discipline as the AST (`WireRecords` names the packages it covers, so the brief package is added to that list explicitly), reusing `DataScope` and the catalog's annotation names by type rather than by copy. A `BriefSchemaProcessor` beside `AstSchemaProcessor` emits `brief-schema.json` into the jar. *Pros:* the repository that owns ADR-003 owns the boundary of what a brief may not carry, in the same contract-test suite; a drift between the AST vocabulary and the brief vocabulary does not compile; consumers on the JVM (Studio, tooling) get a typed model and Jackson round-trip, and non-JVM consumers get the schema, as with the AST; it reaches the bridge through the release-and-vendor pipeline the AST schema already uses. *Cons:* a pre-source artefact enters a module named for the source model; one more processor and one more set of records to keep under the wire-record tests; the SDK's release cadence gates every change to the brief.

**Q2-B2: `exeris-sdk`, as a hand-written JSON Schema resource.** *Pros:* cheapest to write. *Cons:* every wire contract in `exeris-sdk` is emitted from records (`ast.*`, `mutation.*`, `CapManifest`); a hand-written schema would be the one exception, and the guarantee that makes Q2-B attractive (vocabulary drift does not compile) does not hold.

**Q2-C: `exeris-ai-bridge` itself.** *Pros:* one repository to change. *Cons:* Studio would have to depend on an agent bridge for a domain contract; and the bridge's mission is to expose surfaces that live elsewhere, not to define them.

### Q3 — How the procedure reaches an agent

**Q3-A: Data only.** The bridge serves the schema as a resource and a validation tool; agents bring their own procedure. *Pros:* fits ADR-025's text unchanged. *Cons:* in practice every agent improvises a different interview, and the developer gets whichever one their client happens to ship.

**Q3-B: A stateless MCP prompt plus data.** A `discover-requirements` prompt in the P2 list encodes the procedure: purpose, actors, workflows, data, non-functional, non-goals, open questions, then `build-validate_brief`, and no `author-domain` while the brief is not ready. The prompt is a template the client renders. The bridge holds no session state, runs no loop and calls no model. The prompt carries knowledge about how to do discovery, and the ADR-025 amendment says so plainly rather than describing it as pure data. *Pros:* every client gets the same discovery step. *Cons:* needs an ADR-025 amendment, and the amendment covers the whole 0.9.0 prompt list, not only this prompt.

**Q3-C: An `exeris-agents` skill.** *Pros:* skills are behaviour, and the bundle is where behaviour lives. *Cons:* the bundle is vendored into Exeris repositories under ADR-085 §I; it reaches P1 contributors and never reaches an application developer's project. The persona this RFC serves is P2.

**Q3-D: Server-driven MCP elicitation.** The bridge conducts the interview by sending elicitation requests. *Pros:* a structured form per question. *Cons:* the bridge would hold dialogue state and own the procedure; form mode is flat primitives only, so goals, workflows and acceptance criteria do not fit; client support varies. Rejected.

### Q4 — The execution layer

**Q4-A: Host discovery in `exeris-ai-execution`.** Barred by ADR-086 §A.3 (it hosts no agent work) and §C.12 (no content in records).

**Q4-B: Consume derived metadata later.** A brief's shape is a natural complexity feature for V1 and a planner input for V2: term, workflow and integration counts, the mix of data scopes, whether presentation is wanted, and how many blocking questions were closed by assumption. These enter through an ADR-086 amendment when V1 opens, as a dedicated object of closed vocabularies and integer counts in a construction domain's composing schema, not as `workload.scope`. Brief content never enters.

**Q4-C (now): no relationship.** Leaves a useful feature unused, and costs nothing until V1.

### Option Z (do nothing at all)

Discovery stays implicit. Agents go straight to `author-domain`. This is acceptable only if the P2 track is never asked to build a system larger than one entity. That is the opposite of the "generate a system" goal the P2 track exists for.

## Testing

The brief is a contract that agents and, later, Studio implement, so the recommended option is verified as follows:

- **Contract tests in `exeris-sdk`**, beside `AstSchemaContractTest` and `AnnotationCatalogContractTest`: the emitted `brief-schema.json` is deterministic; every concern hint names an annotation present in the catalog of the same build; and the schema admits no property for any structure `DomainMetadata` carries. A brief carrying a field list, a type, a relationship, a validation bound, an action signature (parameters, return type, method), a saga step or a view layout fails, one case per structure. The ADR-003 guard is a property of the schema's shape, tested as one. It is never a heuristic over names or prose.
- **EARS is checked by structure, never by text.** A criterion is valid when its object has the fields its `kind` requires. No regular expression looks for `SHALL`, and no language processing runs over descriptions.
- **Readiness is a function, tested as one**: any blocking question `open` → not ready; `assumed` without `assumption` or `owner` → invalid; all blocking questions `assumed` or `resolved` → ready, with the assumed ones listed.
- **`build-validate_brief`** reads a brief from the project root and checks it against the vendored brief schema of the *project's pinned* SDK version, reporting skew as `sdk:*` does. Where the project has emitted `target/classes/exeris-metadata`, it resolves each `fulfilledBy` against `DomainMetadata` by its kind (an entity, or an action, rule or saga of that entity); a reference whose name exists under a different kind fails; where it has not, it reports those references `unchecked`, not failed. It never reads `cap-manifest.json`, because that is a `caps:*` source. The prompt has the agent compare candidate capabilities with `caps-list_capabilities` instead. Its unavailability on the hosted endpoint follows from its family and is asserted by the existing hosted-family test, with no exception written for it.
- **Planted-gap fixtures**: briefs each missing one thing (a workflow without a response, a blocking question left open, an assumption without an owner, a re-encoded structure, a dangling `fulfilledBy`) must each be reported. An empty or absent brief must never be reported as ready, which is the case that catches the instrument rather than the target (ADR-086 §D.17).
- **What cannot be tested**: whether the interview asked the *right* questions. There is no oracle for requirements quality, so the fixtures cover the gate, not the judgement. Any later claim that discovery reduces rework is a Research question with its own measurement and does not follow from this RFC.

## Recommendation

**Q1-C, Q2-B1, Q3-B, and Q4-C now with Q4-B as the path when V1 opens: a structured brief per bounded area that references the source model and never re-encodes it, defined as records in `exeris-sdk` with a processor-emitted schema, reaching agents through a stateless `discover-requirements` prompt, a schema resource and `build-validate_brief` in `exeris-ai-bridge`, with no change to `exeris-ai-execution` until V1.**

Q1-C is the only output that makes "discovery is done" a check rather than an opinion, and the only one whose shape enforces ADR-003 instead of relying on discipline. Every prior-art tool stops at the drift question; here the schema answers it by having no slot for anything the source model carries. The `assumed` status keeps the gate honest about decisions taken on credit instead of forcing a choice between stalling and deleting the question.

Q2-B1 puts the contract in the repository that owns ADR-003 and the vocabulary the brief references, and builds it the way that repository builds every wire contract: records first, schema emitted. Its real cost is a pre-source package in a module named for the source model. The alternative that avoids that cost (Q2-B2) gives up the one guarantee that justifies placing the brief in the SDK.

Q3-B is chosen over Q3-A because a discovery step that varies by client is no shared step at all. The ADR-025 amendment it needs draws the line at execution, not at knowledge: *the bridge may ship stateless MCP prompt templates that encode canonical workflows over Exeris contracts, such as requirements discovery and entity authoring, provided the bridge itself holds no session state, conducts no multi-turn loop and invokes no model.* That line legalises the 0.9.0 prompt list on the same terms. `build-validate_brief` belongs to `build:*` because it reads the user's project. That one fact makes it local-only under the 2026-09-30 amendment, so private product intent never reaches the hosted endpoint.

### Why not the alternatives?

- **Q1-A** — nothing to resume or review; requirements die with the session.
- **Q1-B** — not checkable, and the first place ADR-003 drift would appear.
- **Q1-D** — loses everything that is not an entity, which is most of what discovery is for.
- **Q2-A** — version coupling to the SDK vocabulary held by convention.
- **Q2-B2** — the only hand-written wire contract in the SDK, without the drift guarantee.
- **Q2-C** — makes Studio depend on the agent bridge for a domain contract.
- **Q3-C** — never reaches the P2 persona.
- **Q3-D** — server-held dialogue state; flat forms cannot carry workflows.
- **Q4-A** — barred by ADR-086 §A.3 and §C.12.

### Risks of the recommendation

- **The brief grows into a design document.** Every pressure on it ("just let me list the fields here") pushes toward re-encoding. The schema-shape tests are the only defence and are a hard guard, not a lint.
- **Prompt scope creep in the bridge.** Once prompts may carry procedure, the amendment's execution line (no state, no loop, no model) is what stops a prompt from becoming an agent. It has to be enforced on every later prompt, not only this one.
- **A pre-source package in `exeris-sdk-source-model`.** If the brief records and the AST start sharing types beyond enums and annotation names, the separation between intent and source erodes from inside the module. The one-way dependency is checked by test, not by convention.
- **Capability names stay unchecked** against anything wider than the project's own composition until a capability catalog exists.
- **Interview quality is unmeasured.** The gate proves completeness of form, not of substance.

## Decision Record

| Field                | Value |
|:---------------------|:------|
| **Outcome**          | — |
| **Date**             | — |
| **Resulting ADR(s)** | — |
| **Notes**            | — |

## Open questions / follow-ups

- **Brief location and cardinality.** Leaning `docs/briefs/<area>.brief.yaml`, one per bounded area. A dot-directory (`.exeris/`) reads as tool state, while a brief is a product document reviewed in pull requests. One brief per area lets area A reach ready and move to authoring while area B still has a blocking question, which a single project-wide brief cannot. Owner: ADR-DISCOVERY-BRIEF.
- **Planning, the stage after discovery.** For a small area (a handful of glossary terms), a ready brief going straight to `author-domain` is a complete path and needs no planning artefact. Decomposition across several areas overlaps ADR-086 V2's planner and should be asked as its own question once briefs exist to plan from.
- **Studio (`exeris-studio`, private) as brief editor and first-party MCP client.** A Studio assistant consumes `discover-requirements` and `build-validate_brief` from `exeris-ai-bridge` like any other client instead of re-implementing discovery, and Studio renders the same brief as a form beside the chat, so a person and the assistant edit one file. Settled already by Studio's own rule: domain sources change only through `exeris/applyMutation`, applied by Studio after a person accepts a preview the bridge or the language server produced, and the bridge stays read-only. Not settled, each its own question in the repository that owns it:
  - how Studio writes a brief, which is not a domain source and so has no `applyMutation` path;
  - where Studio's agent loop and model come from (RFC-2026-09-18's native executor is one candidate);
  - how Studio becomes an ADR-086 producer: the sink contract of §A.2 lives in `exeris-agents`' hook dispatcher, and §C.13's model reference has to be computable for a Studio run;
  - what the execution layer does with the Q4-B features Studio would carry, which is ADR-086's ladder to decide, not this RFC.
- **The ADR-086 amendment for Q4-B**: the exact fields of the construction-features object, taken when V1 opens.
