# ADR-024: Capability Composition Model — `@Provides` / `@Requires` / Build-Time Validation

| Attribute       | Value                                                                                                                |
|:----------------|:---------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                         |
| **Deciders**    | Arkadiusz Przychocki                                                                                                 |
| **Date**        | 2026-05-13                                                                                                           |
| **Scope**       | platform (binds every `exeris-caps-*` repository, every `exeris-sku-*` repository, the `exeris-tooling` codegen pipeline, and the kernel bootstrap lifecycle contract) |
| **Owning Repo** | `exeris-docs`                                                                                                        |
| **Driven By**   | 2026-05-12 whitepaper / HLA restructure that introduced the three-tier architecture; Tier 2 Capability Ecosystem requires a formal contract for how caps compose into Tier 3 SKUs |
| **Compliance**  | [HLA §4 Capability Composition Model](../high-level-architecture.md), [Whitepaper §3.2 Tier 2 — Capability Ecosystem](../b2b-technical-whitepaper.md), [ADR-006 The Wall](ADR-006-spring-free-kernel-boundary.md), [ADR-015 Codegen Emission Strategy](../../exeris-tooling/docs/adr/ADR-015-codegen-emission-strategy.md) |

## Context and Problem Statement

The 2026-05-12 whitepaper / HLA restructure established a three-tier architecture: Tier 1 Substrate (kernel + drivers + Spring Runtime as independent product) — Tier 2 Capability Ecosystem (`exeris-caps-*`) — Tier 3 Vertical SaaS SKUs (`exeris-sku-*`). HLA §4 sketches the Capability Composition Model that binds Tier 2 caps into Tier 3 SKU manifests. Whitepaper §3.2 mirrors the same model for buyer-facing communication. Both documents forward-reference "a forthcoming ADR" for the formal contract. This ADR is that contract.

Without a formal model, three classes of failure recur as the cap layer scales beyond a handful of repositories:

1. **Unresolved dependencies discovered at runtime.** A cap declares `@Requires(SomeOther)` but the SKU manifest doesn't include `SomeOther`. With no build-time validation, the failure surfaces at kernel bootstrap or — worse — at the first request that exercises the missing dependency. The cap layer must fail at build time, not at runtime.
2. **Cycles between caps.** Cap A `@Requires` cap B; cap B `@Requires` cap A directly or transitively. Without DAG enforcement, the bootstrap order is ill-defined and the developer experience degrades fast — the same class of bug Spring Boot's `@DependsOn` chains and OSGi service-tracker dependencies have produced for two decades.
3. **Cap-tier Wall violations.** A cap reaches into Spring internals, into a sibling cap's private classes, or into a kernel private package. The substrate-tier Wall (ADR-006) is enforced by ArchUnit-style tests in `exeris-kernel` and `exeris-spring-runtime`; the cap tier needs its own extension of the same discipline because caps are the layer where third-party glue code is most tempted to short-cut the SPIs.

A fourth concern is **detachability** (whitepaper §5.4 Code Detachment Fee + §6 Sovereignty). A cap composition is only truly portable as IP if a customer can lift the composition into a customer-owned fork without dragging hidden classpath dependencies. The model must structurally guarantee that detachment is mechanical, not a multi-week rewrite.

This ADR answers: **what is the formal contract surface of an `exeris-caps-*` repository, how does the build-time pipeline validate compositions of such caps, and what is the relationship between the capability composition model and the kernel bootstrap lifecycle?**

## 🏁 The Decision

**A capability is a named module declaring three contract surfaces — `@Provides`, `@Requires`, and a lifecycle — through annotations consumed by the `exeris-tooling` codegen pipeline (ADR-015). A composition is a directed acyclic graph of capabilities with no unresolved `@Requires`. The codegen pipeline validates compositions at build time; the kernel refuses to start any composition that fails validation. This contract is enforced uniformly across every Tier 2 `exeris-caps-*` repository and every Tier 3 `exeris-sku-*` SKU manifest.**

### Capability contract surface

Every `exeris-caps-*` repository declares its contract surface through three annotation families and one lifecycle interface:

1. **`@Provides(Service service, [version = "M.m.p"])`** — a service interface this cap exposes to other caps and to user / SKU code. Multiple `@Provides` declarations per cap are permitted (a "substrate-aggregate" cap like `exeris-caps-gateway-core` provides `RouteRegistry`, `UpstreamPool`, `PolicyChain`, `BackendHealthMonitor`, `AdminControlPlane`). The annotation lives on a `@CapabilityModule` class in the cap's API package.
2. **`@Requires(Service service, [versionRange = "[M.m.p,N.x.x)"], [optional = false])`** — a service this cap depends on. Resolution at build time matches a `@Requires` edge against a `@Provides` declaration in another cap on the same composition. Optional `@Requires` (with `optional = true`) is permitted for cross-cutting concerns where the cap degrades gracefully — typically observability and telemetry hooks.
3. **`@CapabilityLifecycle`** — a marker on the class implementing the lifecycle hooks (see lifecycle subsection below). A cap may have at most one `@CapabilityLifecycle` class.

Capabilities consume **kernel SPIs** (Transport, HTTP, Crypto, Persistence, Graph, Events, Flow, Security, Telemetry, Memory) through the same `@Requires` mechanism, with kernel SPIs declared as well-known service identifiers (`KERNEL_TRANSPORT`, `KERNEL_HTTP`, etc.). This unifies "depends on another cap" and "depends on a kernel subsystem" into one contract surface, which keeps the build-time validator simple.

### Lifecycle

Every capability participates in a four-phase lifecycle bound to the kernel bootstrap state machine (`exeris-kernel/docs/subsystems/bootstrap.md` — canonical bootstrap DAG: `FOUNDATION: Memory → SERVICES: Crypto & Persistence & Graph & Transport (parallel) → RUNTIME: Events & Flow & HTTP (parallel) → KERNEL READY`):

| Phase | Trigger | Cap responsibility |
|:---|:---|:---|
| `initialize` | After kernel `READY`, before first request | Acquire owned resources (off-heap buffers, native handles, registry slots). Idempotent — must support replay during composition validation dry-runs. |
| `ready` | After every cap in the composition completes `initialize` | Cap announces readiness to accept work. The composition emits a "composition ready" event only when every cap has signalled. |
| `drain` | On orderly shutdown, before `terminate` | Cap stops accepting new work, completes in-flight units, flushes telemetry. Must complete within the configured drain deadline (default 30s; configurable per SKU). |
| `terminate` | After `drain` completes or its deadline expires | Cap releases owned resources unconditionally. Re-entry-safe — a `terminate` call on an already-terminated cap is a no-op. |

The lifecycle ordering between caps is **derived mechanically** from the `@Requires` DAG: a cap's `initialize` runs after the `initialize` of every cap it transitively requires; a cap's `terminate` runs before the `terminate` of every cap that transitively requires it. There is no `@CapabilityOrder` annotation or hand-written priority — declared dependencies are the only ordering source.

### Composition

A **composition** is a manifest file (`composition.yaml` or equivalent, format TBD by the codegen team in coordination with `exeris-tooling`) that names:

- A set of cap coordinates (group / artefact / version per cap).
- Per-cap configuration overrides (typed property maps).
- A signature (per ADR-020 the manifest is itself a versioned artefact; signing detail is delegated to the SKU repository convention).

A composition is **valid** when all four predicates hold:

1. **Every `@Requires` edge resolves.** For every `@Requires(S)` in every cap, there exists a cap in the composition with `@Provides(S)` whose version satisfies the `versionRange`. Optional `@Requires` (`optional = true`) need not resolve; the consuming cap is responsible for `null`-safe handling.
2. **No cycles.** The `@Requires` graph across all caps in the composition is a DAG.
3. **No version conflicts.** When multiple caps declare `@Provides(S)`, the composition resolves to exactly one — either by version-range intersection (when all consumers' ranges overlap) or by an explicit `prefers:` directive in the composition. Ambiguity is a build failure.
4. **No Wall violations.** Per the cap-tier Wall extension below, no cap class imports across forbidden boundaries.

A composition that fails any predicate **fails the build**. The kernel refuses to start any composition lacking a "validated" stamp from the codegen pipeline. *(Stamp **placement** superseded by the 2026-06-17 amendment "Validation Stamp Lifecycle" below: the boot-time assertion moves to the platform composition runtime and the open kernel stays cap-blind. The build-time-validation contract itself is unchanged.)*

### The Wall, extended to capabilities

ADR-006 establishes the substrate-tier Wall: `exeris-kernel-spi` and `exeris-kernel-core` are Spring-free; `exeris-kernel-enterprise` depends only on SPI and Core. This ADR extends the same architectural discipline to the cap tier as **the cap-tier Wall**:

- **No cap imports `org.springframework.*`, `io.netty.*`, `reactor.*`, `jakarta.servlet.*`, or any host-runtime-specific package.** Caps consume kernel SPIs and other caps via `@Requires`; host-runtime selection happens at SKU manifest time at Tier 1, never inside a cap. This is what keeps `exeris-spring-runtime` an independent Tier 1 product whose absence does not break any cap (per ADR-021 amendment 2026-05-13 and the `exeris-spring-runtime/CLAUDE.md` "Who consumes this repo" section).
- **No cap reaches into another cap's private classes.** Only types annotated as `@Provides`d services are visible across the cap boundary. The convention is the same `eu.exeris.caps.<cap-name>.api.*` (visible) vs `eu.exeris.caps.<cap-name>.internal.*` (private) split that the kernel uses for SPI vs Core.
- **No cap reaches into kernel private packages.** `eu.exeris.kernel.*.internal.*` and `eu.exeris.kernel.core.internal.*` are off-limits — only the SPI surface (`eu.exeris.kernel.spi.*`) is callable from cap code.

The cap-tier Wall is validated by the same `exeris-tooling` pipeline that performs `@Requires` resolution. A cap repository whose ArchUnit-style guard fails is rejected before its artefact is published; an SKU manifest that contains a cap with disabled or stale Wall guards is rejected by the kernel at boot.

**Concrete obligations:**

1. **Every `exeris-caps-*` repository declares its contract surface through `@Provides` and `@Requires` annotations on a `@CapabilityModule` class.** Caps without these annotations are not loadable. The annotations are processed by the `exeris-tooling` annotation processor (ADR-015) at build time and emit a `cap-manifest.json` artefact alongside the cap's JAR.
2. **The kernel refuses to start any composition lacking a "validated" stamp.** The codegen pipeline emits the validation stamp into the composition manifest only when all four predicates of the validation algorithm pass. The kernel bootstrap checks for the stamp during the FOUNDATION phase, before any subsystem initialises. *(**Superseded by the 2026-06-17 amendment "Validation Stamp Lifecycle" below.** The stamp emission stays at the tooling; the boot-time assertion moves out of the kernel into the platform composition runtime. The kernel acquires no awareness of the stamp, the manifest, or the cap concept. See revised obligations 7–9.)*
3. **The cap-tier Wall is enforced by build-time ArchUnit-style guards in every cap repository.** A new `exeris-caps-*` repository scaffold ships with the standard guard set; modifying or disabling the guards is a registry violation reported through periodic audits until automated cross-repo CI lands.
4. **Lifecycle ordering is derived mechanically from `@Requires`; no manual priorities.** A cap that needs to run before another cap declares the dependency explicitly through a (potentially empty-payload) `@Requires` service marker. Priority hacks (`@Order`, integer priorities, alphabetic ordering) are not permitted and fail the build.
5. **Composition manifests are version-pinned and signed.** An SKU manifest pins every cap to an exact version (no `LATEST`, no version range broader than a single release). Signing detail is delegated to the SKU repository convention (`exeris-sku-*`) — this ADR's obligation is the pinning discipline, not the signature algorithm.
6. **Code Detachment artefact set is defined by composition validation output.** When a customer pays the Code Detachment Fee (whitepaper §5.4), the artefacts they receive are exactly the cap source repositories named in the composition manifest, plus the build-time codegen output (cap manifests, validation stamp, signed composition manifest), plus the perpetual-use grant per ADR-023 obligation 4. Detachment is mechanical because the model guarantees no hidden classpath dependencies — every dependency is declared in `@Requires` and every dependency is in the manifest.

## Consequences

### ✅ Positive Outcomes

- **[+] Composition becomes a build-time concern.** Missing dependencies, cycles, version conflicts, and Wall violations all fail the build, before any deployment. The class of bug where "the SKU starts but crashes on the first request" is structurally impossible.
- **[+] Tier 2 cap layer is uniformly enforceable.** ~50 caps across seven layers all participate in the same contract surface. Reviewers across cap repositories can apply the same rubric without per-cap special cases.
- **[+] Lifecycle ordering is derived, not declared.** Caps state their dependencies; the codegen pipeline computes the topological order; no human ranks caps with magic numbers. This is the same architectural move that made the kernel bootstrap DAG safe (subsystem ordering derived from contracts, not from `@Priority`).
- **[+] Cap-tier Wall protects detachability.** A `commercial`-licensed cap (per ADR-023) that a customer detaches under the Code Detachment Fee can be lifted into a customer-owned fork with no hidden classpath. The Wall guards that the cap doesn't secretly import Spring or sibling-cap internals are what make this guarantee mechanical.
- **[+] Cap composition model is host-runtime-independent.** A composition is byte-identical whether the SKU manifest layers in Spring Runtime (the brownfield path through ADR-021 amendment) or runs kernel-direct (the default Tier 3 Platform SKU shape per HLA §5). This is the structural foundation of "Spring Runtime is an independent Tier 1 product, not part of the platform stack" — caps don't know whether Spring is on the classpath.

### ⚠️ Trade-offs

- **[-] Annotation-driven contract has a learning curve.** Cap authors must internalise `@Provides` / `@Requires` semantics and the four-phase lifecycle before contributing. The platform absorbs this cost via `exeris-tooling` scaffolding (a `mvn archetype:generate` for new cap repos, planned) and via cap-author documentation that ships alongside the first reference cap.
- **[-] Build-time validation requires the codegen pipeline.** A cap repository builds with the `exeris-tooling` annotation processor on the classpath. A cap that needs to build outside the platform pipeline (third-party fork, bisected investigation) has to either include the annotation processor or accept that the validation stamp won't be emitted. Mitigation: the processor is a public Maven artefact under the kernel's open-core licence.
- **[-] Mechanical lifecycle ordering occasionally costs an extra empty-marker `@Requires`.** When cap A must initialise before cap B but doesn't naturally depend on a service B provides, the only way to express the ordering is for A to declare `@Requires(B_INIT_MARKER)` and B to declare `@Provides(B_INIT_MARKER)`. This is verbose but explicit; it preserves the "no manual priority" discipline at the cost of marker-service noise. Empirically rare based on the cap inventory in HLA §3.2 — the natural service dependencies cover the bulk of the cases.

### 📋 What is NOT in scope

- **The annotation library implementation (`exeris-sdk` or a new `exeris-caps-spi`).** This ADR specifies the contract; the concrete package, class, and processor implementation is a separate `exeris-sdk` ADR or implementation task — drafted alongside the first `exeris-caps-*` repository creation.
- **The composition manifest format (YAML / JSON / pkl / etc.).** Delegated to the SKU repository convention (`exeris-sku-*`) in coordination with `exeris-tooling`. The codegen pipeline owns the canonical reader; the format choice is a separate implementation decision.
- **Hot reload, dynamic cap swapping, and runtime composition change.** This ADR specifies a build-time validated, boot-time activated composition. Dynamic cap reload is a future concern (potentially after Kernel 1.0 GA) and is not in scope.
- **Per-cap performance contracts.** Whether a specific cap meets a latency or allocation budget is a per-cap concern; the model enforces composition correctness, not per-cap performance.
- **Cross-SKU cap sharing semantics.** Whether two SKUs deployed in the same JVM can share a single instance of a cap (e.g. one `exeris-caps-observability-bridge` serving both an API Gateway SKU and an IDP SKU co-located on the same node) is delegated to a future deployment-topology ADR. The default this ADR locks in is one cap instance per SKU.
- **Telemetry of the composition itself.** Capability lifecycle events emit JFR via the `exeris-caps-observability-bridge` (per ADR-018 and HLA §8). Compositional metadata (which caps loaded, manifest version, validation stamp) is exposed through the same surface, but the wire-format details belong to ADR-018, not here.

## Validation Stamp Lifecycle — Emit at Tooling, Assert at Platform (2026-06-17 amendment)

The body of this ADR (obligation 2, the Composition section, and Engineering Protocol trigger 3) located the validation-stamp check **in the kernel** — "the kernel bootstrap checks for the stamp during the FOUNDATION phase, before any subsystem initialises." Re-examination against The Wall (ADR-006) and the licensing-enforcement philosophy of the companion ADR-023 shows this is the wrong layer. This amendment moves the stamp's **boot-time assertion** out of the kernel and into the platform composition runtime. The **build-time validation contract is unchanged** — the four predicates, the DAG, and the stamp emission all stay exactly as the body specifies.

### Why the kernel is the wrong layer

The stamp is a **build-time verdict**, not a runtime computation: the codegen pipeline emits `validated:true` only when the four predicates pass, so by boot time the verdict is already frozen. A boot-time check therefore cannot be an *ordering* concern ("validate before subsystems init") — there is nothing left to compute. It can only be an *integrity* concern: confirming the artefact being booted matches the one that was validated. Three rationales were weighed; none justifies placing that integrity check in the open kernel:

1. **Ordering.** Collapses into integrity, per above — validity is decided at build time.
2. **Integrity / provenance.** A boot-time check adds security value only across a real trust boundary: a sealed, trusted verifier checking an independently-swappable, potentially-hostile artefact. The open kernel is Apache 2.0 + Commons Clause — source-available, forkable, its binary unsigned and unmeasured. An adversary who can swap the composition manifest can equally recompile the kernel with the check removed. In the open kernel the check is a speed bump, not a gate. A hardened, signature-backed gate — *if ever required* — belongs to a sealed enterprise substrate (`exeris-kernel-enterprise`) with a real signing/attestation chain, never to the open kernel.
3. **Licensing enforcement.** Reading "the kernel refuses to start an unvalidated composition" as a commercial lock directly contradicts ADR-023, which makes SKU-licence enforcement **contractual, not technical** ("a customer can technically download and run without a subscription; this is a licence violation, not a technical impossibility" — ADR-023 trade-offs and obligation 10). A runtime lock in the open kernel would be both removable and inconsistent with the companion ADR.

The honest conclusion is that the stamp is **not** a tamper-proof lock. It is a **correctness / fail-fast consistency assertion** that catches *honest* mistakes — a stale manifest, a version drift between build and deploy, a partial deploy, or a hand-edited manifest shipped without re-running the pipeline. This is exactly what a "build-time validated, boot-time activated composition" (see "What is NOT in scope") needs: an early, legible refusal instead of a confusing mid-boot crash. Consistency assertions belong with the component that owns the manifest reader and performs the cap wiring — the platform composition runtime — not with the substrate.

### The Decision

**The validation stamp is emitted by the tooling and asserted by the platform. The open kernel acquires no awareness of the stamp, the composition manifest, or the capability concept. It exposes only what it already exposes — the bootstrap DAG lifecycle and the kernel SPIs caps `@Requires`.**

| Layer | Role | Responsibility |
|:---|:---|:---|
| **Tooling** (`exeris-tooling`, build-time) | Validation authority | Runs the four predicates, computes the topological order, and emits into the composition manifest: the `validated` stamp, the **composition version**, and a **content binding** — a hash of the resolved cap set (exact artefacts + versions). The binding is what makes the stamp non-transferable: it attests "*this* composition is valid", not "*some* composition is valid". |
| **Platform** (`exeris-platform` composition runtime, boot-time) | Assertion, not re-validation | At SKU startup, before any cap enters `initialize`: confirms the stamp is present and well-formed, the manifest-pinned versions equal the `cap-manifest.json` versions actually on the classpath, and the content binding matches the loaded artefacts. On mismatch → fail-fast. This is an O(n)-over-caps check with **no DAG re-resolution** — re-deriving validity at boot would duplicate the tooling resolver in the runtime and defeat "composition becomes a build-time concern". |
| **Kernel** (`exeris-kernel`, open) | None (cap-blind) | Boots its subsystems via the existing bootstrap DAG and exposes its SPIs. It has no `Capability` / `Composition` / `Stamp` type, does not parse the manifest, and does not resolve `@Requires`. The Wall (ADR-006) is preserved: Tier 1 remains blind to Tier 2 abstractions. |

The composition runtime divides into **logic** (a generic, once-tested library in `exeris-platform`, reused across every SKU) and **call site** (the generated SKU bootstrap invokes it during its own startup, before handing control to caps). As of 2026-06-17 this library is greenfield — no prior implementation exists in `exeris-platform`.

A consequence worth stating plainly: because `exeris-platform` is itself source-available, the platform-side assertion inherits the same forkability as the kernel-side one would have had — it is **still not** a security or licensing gate, and is not intended to be. Its value is correctness and operability (catching honest configuration drift early), consistent with ADR-023's contractual-enforcement model.

**Revised obligations (supersede obligation 2):**

7. **The tooling emits `validated` stamp + composition version + content binding when all four predicates pass.** The content binding is a hash over the resolved cap set (artefact coordinates + versions) and is mandatory — a stamp without a binding is rejected by the platform assertion in obligation 8.
8. **The platform composition runtime asserts stamp consistency at SKU startup, before any cap `initialize`.** The assertion is presence + well-formedness + version-match (manifest vs classpath `cap-manifest.json`) + binding-match (manifest vs loaded artefacts). It performs no DAG re-resolution. A failed assertion aborts SKU startup with a diagnostic naming the specific divergence (missing stamp, version drift, or binding mismatch).
9. **The open kernel remains cap-blind.** No kernel package gains a stamp check, a manifest reader, or any capability/composition type. A hardened, signature-backed boot gate — should one ever be justified by a concrete threat model — is scoped to a sealed enterprise substrate with a real attestation chain, and would require its own ADR; it is explicitly out of scope for `exeris-kernel`.

### Cross-references for this amendment

- ADR-006 (Spring-Free Kernel Boundary — The Wall) — the substrate-tier boundary this amendment protects by keeping the kernel cap-blind.
- ADR-023 (Capability Licensing Taxonomy) — its contractual-not-technical enforcement model (trade-offs + obligation 10) is the consistency this amendment restores; the stamp is a correctness assertion, never a licence lock.
- ADR-015 (Codegen Emission Strategy, `exeris-tooling`) — owns the stamp + version + content-binding emission of revised obligation 7.

## Composition Runtime Placement — Boot Conductor at SDK-Runtime, Control Plane at Platform (2026-06-25 amendment)

The 2026-06-17 amendment correctly moved the stamp **assertion** out of the kernel, but it parked the whole composition runtime in `exeris-platform` **by elimination** — the kernel was excluded (obligation 9), `exeris-platform` was the standing repo, so it inherited the work. Realizing obligation 8 there (the `exeris-platform-composition-runtime` module, shipped 2026-06-17) exposed the mistake: the module is **standalone — it has zero dependencies on anything in `exeris-platform`** (Studio, the LSP server, the studio-backend). A runtime library that reads the tooling's `cap-manifest.json`, drives SDK-defined capability hooks, and binds to the kernel bootstrap has **no affinity to a design-time platform**. The 2026-06-17 amendment's rationale — "consistency assertions belong with the component that owns the manifest reader and performs the cap wiring, the platform composition runtime" — is circular: it *names* `exeris-platform` the composition runtime and then derives that the runtime belongs there. Nothing about Studio makes it the manifest reader.

The deeper error was conflating **two orchestrations at two different altitudes** into one word:

1. **The in-jar boot conductor** (runtime, per-SKU). Inside a single deployed SKU artefact, after `KERNEL READY`, something must drive that SKU's caps through `initialize → ready → drain → terminate` in the tooling-computed `initOrder`, then assert the stamp before any cap initializes. This ships **into the SKU jar** and runs wherever that jar is deployed (a k8s pod, a VM, standalone). It is substrate-adjacent runtime glue, not a design-time concern.
2. **The deploy-time control plane** (design-time + deploy-time, multi-SKU). Composing a complex distributed system out of many SKUs (service-mesh / multi-host), wiring it in Studio from SDK + Tooling + caps + SKUs, integrating with external delivery (git, cloud distributors, Kubernetes), and **deploying** it. **This is the genuine `exeris-platform` role** — the control plane that composes and ships systems, not the in-process runtime that boots one of them.

### Two realizations that sharpen the split

- **The four-phase cap lifecycle is the kernel's three-phase `Subsystem` lifecycle, finer-grained — not a parallel framework.** In `eu.exeris.kernel.spi.bootstrap.Subsystem`, `start()` ("activates the subsystem and begins accepting work") is `ready`; `stop()` ("graceful shutdown — flushes in-flight work and releases resources") is `drain` **+** `terminate` fused. The cap contract splits `stop` into two phases only to add a configurable drain deadline and an all-caps-drained barrier before terminate. The whole cap layer hangs off the kernel at **one seam** — a single opaque `Subsystem` (phase `RUNTIME`, after `KERNEL READY`) whose internals run a thin `initOrder` loop. The kernel still sees one subsystem, not N caps (obligation 9 preserved). There is no second bootstrap engine; there is one substrate lifecycle and a nested, tooling-ordered cap loop.
- **The content-binding algorithm is currently a byte-verbatim port** (`exeris-tooling`'s `CompositionStamp#computeBinding` ↔ the runtime's re-implementation), pinned by a golden test vector — any silent drift false-fails every deploy. A single **shared composition-spec** (manifest schema + the one canonical binding implementation), depended on by both the tooling emitter and the runtime asserter, eliminates the duplication **without** dragging the build-time pipeline onto the SKU classpath (the spec carries no codegen dependencies). The golden vector survives as a cross-module conformance pin.

### The Decision

**The composition runtime — the boot conductor and the stamp assertion — moves to an SDK-side runtime module shipped into each SKU artefact, not to `exeris-platform`. The manifest schema and content-binding algorithm are defined once in a shared composition-spec. `exeris-platform` is re-cast as what it actually is: the deploy-time control plane that *composes and deploys* multi-SKU distributed systems and *consumes* the composition library, never hosting the in-jar runtime. The open kernel remains cap-blind.**

| Altitude | Component | Home | Role |
|:---|:---|:---|:---|
| Build-time | Validation + emission | `exeris-tooling` | Validate the `@Requires`/`@Provides` DAG, compute `initOrder`, emit stamp + version + content binding (obligation 7, unchanged). |
| Shared contract | Composition-spec | `exeris-sdk-composition-spec` (small SDK module, no codegen deps) | The `cap-manifest.json` schema + the **one** canonical content-binding implementation, depended on by both the tooling emitter and the runtime asserter. Retires the verbatim port. |
| Cap authoring/runtime contract | Lifecycle hooks | `exeris-sdk` | `CapabilityLifecycleHooks` (`initialize`/`ready`/`drain`/`terminate`) — the runtime twin of the `@CapabilityLifecycle` marker (open follow-up 1). **Not** in the kernel (the body's "lives in kernel SPI" wording is void under obligation 9). |
| SKU-boot runtime | Boot conductor + stamp assertion | an SDK-side runtime module (extractable to a dedicated `exeris-orchestrator` repo if a second host integration appears) | Asserts the stamp before any cap `initialize`, then drives caps through the four phases in `initOrder`, reverse on shutdown with the drain deadline. Binds to the kernel bootstrap as **one** opaque `Subsystem`. Ships into the SKU jar (realizes obligation 8). |
| Deploy-time control plane | Studio + delivery integrations | `exeris-platform` | Composes multi-SKU / mesh / multi-host systems, integrates with git and cloud/Kubernetes delivery, deploys. **Consumes** the composition library for design/deploy-time validation and preview. Does **not** host the boot-time runtime. |
| Substrate | Kernel | `exeris-kernel` | Cap-blind (obligation 9, unchanged). |

### Where the composition-spec lives — and when it would leave

`exeris-sdk-composition-spec`, an SDK module, is the home — not a standalone repo — because the spec has **two coupled consumers**, not an independent set. The tooling **emits** the manifest and the SDK-runtime asserter **consumes** it; the platform control plane consumes it only **transitively** through the runtime library, and is itself — by the dogfooding principle (Platform is built with SDK + Tooling + caps + SKUs like the gateway) — already a deep SDK dependant. The tooling↔SDK pair co-evolves in lockstep (tooling already depends on SDK to process its annotations), so there is no independent producer/consumer boundary to protect with a neutral third repo.

This is the inverse of the `exeris-telemetry-spec` precedent. That wire format earned its own repo precisely because its emitter (the kernel) and decoder (`exeris-enterprise-observability`) are **independent repos that must not depend on each other** (ADR-018) — the spec had to be neutral ground. The composition-spec has no such independent pair: the natural "third consumer" candidate, a forensics decoder reading composition metadata, consumes the **telemetry** wire (ADR-018), not `cap-manifest.json` (see *What is NOT in scope — Telemetry of the composition*).

**Extraction trigger (reversible):** if a consumer later appears for which depending on the SDK is the wrong shape — a substrate-near tool that must read `cap-manifest.json` **directly** without the SDK surface — extract `exeris-sdk-composition-spec` into a standalone `exeris-composition-spec` repo. Module → repo is a mechanical move; starting standalone now would be premature structure for a two-consumer contract.

**Revised obligations (supersede the 2026-06-17 obligation 8; obligations 7 and 9 stand):**

8a. **The boot conductor and stamp assertion live in an SDK-side runtime module, shipped into every SKU artefact** — not in `exeris-platform`. The generated SKU bootstrap invokes them during its own startup, before any cap `initialize`, and the module binds to the kernel bootstrap as a single opaque `Subsystem` in the `RUNTIME` phase. It performs no DAG re-resolution; the cap order is the tooling-supplied `initOrder`.

8b. **The manifest schema and content-binding algorithm are defined once in `exeris-sdk-composition-spec`** (an SDK module, no codegen deps), depended on by both the tooling emitter and the runtime asserter. The byte-verbatim re-implementation is retired; the golden test vector is retained as a cross-module conformance pin. The spec stays in the SDK while its consumer set is the coupled tooling↔SDK-runtime pair (plus platform transitively); it extracts to a standalone `exeris-composition-spec` repo only if an SDK-independent direct consumer appears.

8c. **`exeris-platform` is the deploy-time control plane.** It composes and deploys multi-SKU / mesh / multi-host systems and integrates with external delivery (git, cloud, Kubernetes). It **consumes** the composition library for design/deploy-time validation; it does not host the boot-time runtime, and reintroducing in-jar composition machinery into a Studio/LSP/backend module is a regression.

### Migration

The validation-stamp assertion shipped in `exeris-platform-composition-runtime` (the 2026-06-17 realization of obligation 8) relocates to the SDK-side runtime module; the `exeris-platform` link stub and the repo's `CLAUDE.md` guardrail update to reflect "platform = control plane, consumes the library" rather than "platform realizes obligation 8". Tracked as a follow-up — the assertion logic and its golden vector port unchanged; only its module coordinates move.

### Cross-references for this amendment

- The 2026-06-17 amendment above — this amendment refines, not reverses, it: the kernel stays cap-blind; only the *non-kernel* home of the assertion is corrected (platform → SDK-runtime) and the genuine platform role (control plane) is made explicit.
- ADR-006 (Spring-Free Kernel Boundary — The Wall) — the one-seam binding (a single opaque `Subsystem`) is what keeps the substrate blind to the cap tier. *(Binding mechanism superseded by the 2026-07-21 amendment below — the seam survives, but as the SKU entrypoint's call site, not a DAG node.)*
- `exeris-sdk` open follow-up 1 (the concrete `@CapabilityModule`/`@Provides`/`@Requires`/`@CapabilityLifecycle` classes) — now also owns the `CapabilityLifecycleHooks` runtime interface and the composition-spec module placement.

## Boot Conductor Call Site — Invoked by the SKU Bootstrap After `KERNEL READY`, Never a Kernel Subsystem (2026-07-21 amendment)

The 2026-06-25 amendment correctly placed the boot conductor in an SDK-side runtime module, but described its kernel binding as "a single opaque `Subsystem` (phase `RUNTIME`, after `KERNEL READY`)", and its revised obligation 8a repeated that the module "binds to the kernel bootstrap as a single opaque `Subsystem` in the `RUNTIME` phase". That phrasing is **internally inconsistent with this ADR's own body**: `BootstrapPhase.RUNTIME` is a kernel bootstrap phase that completes *before* `KERNEL READY` is declared (canonical DAG: `FOUNDATION → SERVICES → RUNTIME → KERNEL READY`), while the body's lifecycle table triggers cap `initialize` *"after kernel `READY`, before first request"*. A DAG-registered `Subsystem` structurally cannot run after `KERNEL READY` — the two clauses cannot both hold. Founder ruling 2026-07-21 resolves the contradiction in favour of the lifecycle table.

### Why the `Subsystem` binding is the wrong call site

1. **Lifecycle semantics.** Cap `initialize` is defined to run after the *whole* substrate is ready — including HTTP, which boots in the `RUNTIME` phase. A cap conductor registered as a `RUNTIME`-phase `Subsystem` would run concurrently with (or, `dependsOn` notwithstanding, still *inside*) the very phase whose completion the cap contract presupposes. Only a post-bootstrap call site satisfies the body's table.
2. **Tier purity.** A `ServiceLoader`-registered `SubsystemProvider` from the cap layer would insert a cap-tier node into the kernel's bootstrap DAG — observable through `KernelDiagnostics.getBootstrapDag()` (ADR-033). Obligation 9's promise is not just that the kernel *codebase* is cap-blind, but that the substrate's runtime self-description stays pure Tier 1. Caps and SKUs are platform-tier code *above* the substrate, not subsystems *of* it.
3. **Deployment independence (code detachment, obligation 6).** The SKU artefact must boot standalone — kernel + caps + conductor in one deployable, sequenced by its own entrypoint, with no platform/control-plane runtime dependency and no reliance on kernel-side discovery of cap machinery. An SKU whose cap layer only starts because the kernel's ServiceLoader happened to find it couples the detached artefact to a discovery convention the customer's fork must then preserve; an SKU whose own `main` calls the conductor is mechanically self-describing.

### The Decision

**The generated SKU bootstrap owns the boot sequence: `KernelBootstrap` → `KERNEL READY` → composition-stamp assertion → conductor `initOrder` loop. On shutdown the SKU entrypoint drains and terminates caps first (reverse `initOrder`, drain deadline per the body's lifecycle table), then stops the kernel. The cap layer registers nothing with the kernel — no `SubsystemProvider`, no node in the bootstrap DAG. The kernel remains cap-blind (obligation 9 unchanged); the conductor's module home (obligation 8a), the shared composition-spec (8b), and the platform control-plane role (8c) are unchanged.**

The 2026-06-25 "one seam" insight survives: there is still exactly one substrate lifecycle and one nested, tooling-ordered cap loop — no second bootstrap engine. The correction is *where the seam sits*: it is the SKU entrypoint's call site immediately after `KERNEL READY`, not a node inside the kernel's DAG. The finer-grained-lifecycle observation (cap `ready`/`drain`/`terminate` as a refinement of `Subsystem.start()`/`stop()`) stands as an analogy, not as an implementation-by-interface.

**Revised obligation (supersedes the *binding clause* of the 2026-06-25 obligation 8a; its module-home clause and obligations 7, 8b, 8c, 9 stand):**

8a′. **The boot conductor and stamp assertion live in the SDK-side runtime module shipped into every SKU artefact, and are invoked by the generated SKU bootstrap after the kernel reports `KERNEL READY`** — before any cap `initialize`, performing no DAG re-resolution (the cap order is the tooling-supplied `initOrder`). The cap layer makes no `SubsystemProvider` registration and contributes no node to the kernel bootstrap DAG. Shutdown is SKU-entrypoint-driven: caps drain and terminate in reverse `initOrder` (honouring the drain deadline), then the kernel stops. The SKU artefact boots standalone, with no platform/control-plane runtime dependency.

### Cross-references for this amendment

- The 2026-06-25 amendment above — module placement (SDK-runtime home, composition-spec, platform-as-control-plane) is unchanged; only the binding mechanism ("opaque `Subsystem`, phase `RUNTIME`") is superseded.
- This ADR's body, §Lifecycle — the `initialize` trigger *"after kernel `READY`"* is the clause this amendment restores to primacy.
- ADR-033 (`KernelDiagnostics` SPI) — `getBootstrapDag()` stays a pure Tier 1 self-description; no cap-tier node appears in it.
- ADR-006 (The Wall) — tier purity rationale 2.
- Whitepaper §5.4 / obligation 6 (Code Detachment) — deployment-independence rationale 3.
- ADR-053 (SKU Composition Manifest Format — JSON) — decided the same day; resolves the *format* half of open follow-up 3.

## Cross-references

- ADR-006 (Spring-Free Kernel Boundary — The Wall) — the substrate-tier Wall that this ADR extends to the cap tier.
- ADR-015 (Codegen Emission Strategy, `exeris-tooling`) — the annotation-processor pipeline that consumes `@Provides` / `@Requires` declarations and emits the cap manifest + composition validation stamp.
- ADR-020 (Open-Core Documentation Boundary) — defines the documentation visibility taxonomy this ADR's caps live under.
- ADR-021 (Gateway-Class Workloads Out of Compatibility Scope) — its 2026-05-13 amendment cites this ADR as the binding model for Tier 3 Gateway SKU compositions.
- ADR-023 (Capability Licensing Taxonomy) — companion ADR; this ADR governs the contract, ADR-023 governs the licence under which the contract operates.
- HLA §4 "Capability Composition Model" — the document this ADR formalises.
- Whitepaper §3.2 "Tier 2 — Capability Ecosystem" — buyer-facing summary.
- `exeris-kernel/docs/subsystems/bootstrap.md` — the canonical bootstrap DAG that the capability lifecycle binds to.
- Whitepaper §5.4 "Vertical SKU Subscription" + §6 "Sovereignty and IP Ownership" — Code Detachment Fee that this ADR's obligation 6 supports structurally.

## Engineering Protocol

This ADR is **descriptive at acceptance**: it codifies the composition model already sketched in HLA §4 and whitepaper §3.2 (2026-05-12). It becomes prescriptive when:

1. The first `exeris-caps-*` repository materialises (target: H1 2027 per whitepaper §7 Track B, "Q1 2027 Capability composition language formal release").
2. The annotation-processor extension in `exeris-tooling` ships (depends on ADR-015 deliverables; planned alongside the first cap repository).
3. The platform composition runtime acquires the validation-stamp **assertion** (target: bundled with the first SKU bootstrap; greenfield in `exeris-platform` as of 2026-06-17). *(Revised by the 2026-06-17 amendment — the assertion is a platform concern, not a kernel one; the open kernel acquires nothing.)*

Open follow-ups (tracked separately):

1. **`exeris-sdk` ADR (or amendment) defining the concrete annotation classes.** Specifies the `@CapabilityModule`, `@Provides`, `@Requires`, `@CapabilityLifecycle` Java types, their retention policy, and their package location. Drafted alongside the SDK's first cap-aware release.
2. **`exeris-tooling` extension for cap manifest emission + composition validation.** Implements the four-predicate validator and the manifest emitter. Coordinated with ADR-015 deliverables.
3. **Composition manifest format specification.** YAML / JSON / pkl decision plus the canonical reader implementation. Delegated to the SKU repository convention; first SKU manifest shipped alongside `exeris-sku-api-gateway` (target: Q2 2027 per whitepaper §7 Track B).
4. ~~**Cap-author documentation set.**~~ **Discharged 2026-08-16** — [`cap-author-guide.md`](../cap-author-guide.md) covers declaring `@Provides` / `@Requires`, lifecycle hook patterns and their sharp edges, Wall-compliant import hygiene, version-range conventions, and optional-dependency patterns. Written from the shipped implementation rather than alongside a reference cap, because the implementation landed first: the pipeline validates, stamps, and conducts today, while no `exeris-caps-*` repository exists yet. The guide is explicit about that inversion and carries a known-gaps section (inert `compositionVersion`, manifest not on the runtime classpath, no cross-service resolution, no archetype) so a first cap author is not surprised by them.
5. **Cross-repo CI gate for composition validation.** A workflow in `exeris-docs` (or distributed across cap repositories) that pulls cap manifests and verifies a sample SKU composition validates. Lands when the first two cap repositories ship.

Until the codegen pipeline lands, the binding source-of-truth is the contract specified in this ADR plus the HLA §4 walked example (API Gateway SKU composition diagram). New cap repositories scaffolded before the pipeline ships must include hand-written `@Provides` / `@Requires` declarations matching this ADR's annotation grammar so that the migration to processor-validated builds is a re-compile, not a refactor.
