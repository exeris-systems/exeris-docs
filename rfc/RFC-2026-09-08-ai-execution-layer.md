---
title: "RFC-2026-09-08: The AI execution layer — against which oracle does V0 observe, and what must be preregistered before the dataset may justify a routing decision?"
type: rfc
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-09
---

# RFC-2026-09-08: The AI execution layer — against which oracle does V0 observe, and what must be preregistered before the dataset may justify a routing decision?

| Field             | Value |
|:------------------|:------|
| **Status**        | **ACCEPTED** |
| **Author(s)**     | arkstack-dev |
| **Date Opened**   | 2026-09-08 |
| **Date Closed**   | 2026-09-09 |
| **Scope**         | platform / cross-repo (a new sibling repository, a seam into `exeris-agents`, and a consumer relationship with `exeris-ai-bridge` under ADR-025) |
| **Owning Repo**   | `exeris-docs` (an ecosystem-shape question; the layer has no repository yet) |
| **Target ADR(s)** | **ADR-086** — one platform-scope ADR fixing the layer's boundary against ADR-025 and the agent bundle. Reserved in [`adr-index.md`](../adr-index.md) by this pull request; content pending. |
| **Affected Repos**| `exeris-docs` (this RFC, the eventual ADR), a new `exeris-ai-execution` repository, `exeris-agents` (a telemetry sink contract in the hook dispatcher), `exeris-ai-bridge` (a context adapter, later), `exeris-benchmarks` (unaffected — the System Construction Benchmark is a separate programme and is not that repository) |
| **Reviewers**     | — |

## Question

Exeris is preparing a provider-neutral **AI Execution / Workload Intelligence** layer whose eventual job is to decide which class of model does which part of a task. Its staged plan is deliberate about the biggest danger — V0 observes and does not route — and its V0.5 rests on a "True Done oracle" borrowed from the System Construction Benchmark.

That oracle does not run yet. SCB v1.3 (2026-09-01) is *ready for Phase 0* and its own overriding rule forbids a campaign before Phase 0, before the mutation self-test passes and before the neutrality audit is published. So the layer's first deliverable depends on an instrument that is designed, rigorous, and unbuilt.

**Against which oracle does V0 observe, what is therefore its first domain, and what discipline must the dataset carry from day one so that a later routing claim is a result rather than a story told over telemetry?**

Placement is *not* the open question — see §Context. The open questions are the oracle, the first domain, and the preregistration discipline.

## Context

Three programmes converged in the last week and they now constrain each other.

**The agent layer reached v2** (2026-09-08): vendor-neutral role profiles, an L0 runtime enforcement layer, three decision schemas, runtime-independent evals, and a versioned bundle that repositories vendor and verify by digest. Two of its artefacts bear directly on this RFC — a hook dispatcher that already normalises six vendors' tool-call wire formats, and a `verdict` schema whose `checks_run` carries a three-valued result including `not-run`.

**The System Construction Benchmark reached v1.3** (2026-09-01) and is *pre-Phase-0*. It is the most methodologically careful instrument in the ecosystem: fail-closed gates, `UNKNOWN` counting as `FAIL`, an oracle that must catch 100% of a mutation suite before its `PASS` means anything, a contract audited for neutrality by someone outside the project, preregistered hypotheses with falsification conditions, and validity fences that invalidate prior results when the instrument itself is found defective. **It is a plan, not a running system**, and it is held outside the repositories as working material — like the ADR-085 Phase 0 inventory, it is named here rather than linked.

**The AI execution plan exists in draft** with a V0→V10 staging. Its central discipline — V0 observes, V0 does not route — is correct and is not in question here. The ladder in §Recommendation **replaces** that numbering rather than continuing it: it stages on *what a stage is permitted to emit*, not on how much is automated, so its V-numbers are not the plan's and stop at V4+. Nothing from the plan's later stages is dropped by the renumbering; they simply cease to be numbered until there is evidence to number them against.

**Placement is settled and is recorded here as context, not as an option.** The layer belongs in a new sibling repository. ADR-025 gives most of the argument: the bridge's mission runs from Exeris surfaces **to** agents and this layer runs the other way; its "adjacent AI-integration artefacts" clause is qualified by that same responsibility; and §3 chose TypeScript on the reasoning that no Java was needed, where the layer's own skeleton is Java. `exeris-agents` is excluded by construction — it is defined by being vendored and digest-verified, and a mutable dataset with a capture process breaks the property that makes a pinned import verifiable. The plan's own "the planner and the router do not know MCP" then requires the bridge to be downstream, not host.

The cost of leaving the *oracle* question unanswered is concrete: V0 either stalls waiting for SCB Phase 0, or quietly invents a second, uncalibrated judge of the same runs — which the plan explicitly does not want.

## Investigation

### Prior art

**The strongest prior art is internal.** SCB v1.3 has already solved, for a harder case, most of the measurement problems the execution layer is about to meet. Five of its rules transfer directly and are treated below as constraints rather than suggestions:

| SCB rule | Why it binds the execution layer |
|:--|:--|
| §0.1 fail-closed — a gate the instrument cannot judge is `UNKNOWN`, and `UNKNOWN` counts as `FAIL` | A run whose outcome cannot be established is not a success with a missing field. Recorded as an outcome value, not as a null |
| §0.2 calibration before measurement — an oracle that has never emitted `FAIL` on a known-broken build is unvalidated | The execution layer's oracle needs its own mutation suite before any `TRUE_DONE` it emits is admissible |
| §0.3 the contract author is a competitor | The founder would author the oracle, author the router, and be the sole annotator. Three roles, one person |
| §1.3 everything the oracle does not check is optimised down by the agent | See §Risks — a router *trained on oracle outcomes* does not merely tolerate this, it selects for it |
| §9.5 validity fences — a defect found mid-campaign invalidates prior results for affected gates, which are marked rather than deleted | A dataset spanning model, harness and oracle changes needs the same mechanism, or it silently mixes incomparable rows |

External prior art is thinner than it looks. Published model-routing work optimises benchmark accuracy per token on *single-turn* tasks; none of it addresses cost-to-completion on multi-turn repository work, which is the quantity this layer exists to measure. There is no usable external baseline — an argument for measuring carefully, not quickly.

### Constraints

1. **ADR-025** bounds `exeris-ai-bridge` to bridging Exeris surfaces to agents; it may feed the layer, not host it.
2. **`agents-md-schema.md` rule 8** forbids fetching policies, instructions or executable scripts at agent runtime, and requires a pinned, digest-verified import. A telemetry sink shipped through the bundle must therefore be reviewed code inside the vendored tree, not a callback fetched at session time.
3. **ADR-085 §J** already defines the enforcement layering L0–L3. The execution layer adds no layer; it *observes* L0–L2 and consumes their verdicts.
4. **SCB §7.1 and §8** — token-to-token comparison is valid only within one model (across models the units are USD and wall time), and a model reference is `id + snapshot + harness + system-prompt hash`. Both are discharged by the run record in §Recommendation.
5. **Privacy** — "separate metadata from potentially sensitive content" is a hard constraint, not a preference: prompts and file content may carry customer or private-repository material.

### Data gathered

What exists today, measured in this workspace on 2026-09-08 rather than assumed:

- **A docs-domain oracle runs.** `agents_file_check.py`, `agents_render.py --check`, `agents_bundle.py verify`, `frontmatter_check.py`, `registry_check.py` and 14 eval scenarios. 24 files / 0 errors on the migrated tree, with negative behaviour exercised rather than assumed: 5 malformed agent-layer states caught, a hand-edited vendored policy caught with both digests printed, a hand-edited adapter caught as a diff, 7 malformed verdict instances rejected offline. In SCB's terms that is a proto mutation suite — small, never yet run as a suite, but the right shape.
- **A six-vendor telemetry tap exists.** The vendored hook dispatcher intercepts pre-tool, post-tool and stop events and normalises the stdin shapes of Claude Code, Copilot, Codex, Gemini CLI, Antigravity and Cursor. It is the only provider-neutral tool-call interception point in the ecosystem today.
- **An outcome record shape exists.** `verdict.base.schema.json`: `decision`, findings each bound to a clause, and `checks_run[]` with `pass | fail | not-run`.
- **The SCB metric vocabulary is in none of the repositories.** A workspace-wide search for `true_done`, `false_DONE_rate`, `first_pass_gap`, `turns_to_true_done` and `runs_reaching_100` returns zero hits across every checked-out repository. `exeris-benchmarks` is the JMH/wrk performance harness; the System Construction Benchmark is a different programme and is not in that repository. This is a statement about the checkout, not about the plan — the plan exists and is detailed — and it fixes the sequencing: **nothing can consume SCB output until SCB Phase 0 has run.**
- **Antigravity's CLI selects agents silently.** `agy` 1.1.27 runs a turn with the default agent and exits 0 when `--agent` names something that does not resolve. Any per-run capture that records "which agent ran" from that runtime must assert it, not trust the invocation.

### Spike outcomes

No spike was built for this RFC. The agent-layer v2 work is treated as an incidental spike for two of its claims — that a provider-neutral hook dispatcher is small (one file, six wire formats) and that a content-addressed digest survives history rewriting (verified: the bundle digest was unchanged across a squash). Both bear on V0's feasibility and neither was built for that purpose.

## Options Considered

The options are over **V0's oracle**, which decides V0's first domain and therefore what the first
dataset is worth. Recorded here as the trail behind a settled recommendation.

### Option A: Wait for SCB Phase 0

Build capture; gate the first `TRUE_DONE` on the System Construction Benchmark reaching Phase 4.

**Pros:** one quality system, no competing judge; SCB's labels inherit a mutation suite and a neutrality audit; construction domains are where model choice plausibly matters most.
**Cons:** V0 blocks on all six of SCB's own unresolved items (its Appendix D), including who performs the neutrality audit; SCB's frozen contract measures *system construction* and would not oracle a documentation sweep, the workload that motivated this layer; nothing is captured meanwhile, so the first row is months away and the capture code goes unexercised.
**Cost:** low to build, high latency, and a real risk the capture design is wrong in ways only rows reveal.

### Option B: V0 observes the documentation and agent-layer domain, against the guardrail suite

Ship capture now against the oracle that already runs. SCB becomes the *second* oracle at Phase 4, under one shared interface.

**Pros:** the oracle exists, is machine-runnable and has a partially exercised negative suite (§Data gathered); it is exactly the workload the layer was conceived to explain; the outcome record already has a schema, so capture and oracle meet at a shape that exists; SCB stays unhurried and joins later as a second implementation, which is a stronger design than one hard-wired judge; capture-design failures surface within days, on cheap workloads.
**Cons:** the oracle is narrow — it answers "is the corpus structurally consistent", never "is this document any good", a large unmeasured surface SCB §1.3 warns will be optimised down; documentation work may be unrepresentative of where routing matters most; two oracles of different rigour risk being reported as one unless every row carries its oracle's calibration state.
**Cost:** moderate. The oracle is done; the workload model, event sink, store and a docs mutation suite are not.

### Option C: Build an execution-layer-owned oracle

**Pros:** uniform across domains from the start; free of either existing instrument's blind spots.
**Cons:** a third judge needs its own calibration, audit and mutation suite before its verdicts are results; largest build of the three and delivers no row sooner than B; two uncalibrated judges disagreeing about one run is worse than one narrow judge with a stated scope.
**Cost:** high, and it duplicates the hardest part of SCB.

### Option D (do nothing): keep choosing models by hand

**Pros:** zero cost; the founder's judgement is the current router and is not obviously bad.
**Cons:** unfalsifiable — with no record of what a cheaper model would have done, the cost of every choice is invisible; it leaves the platform's most differentiating claim unevidenced, and no competitor can make that claim without the same dataset; once the tap exists the marginal cost of capture is near zero, so not capturing is a decision to discard data already flowing past.
**Cost:** nil now, compounding later.

## Testing

V0's testable surface is the **oracle**, and it inherits SCB §4.4's entry condition: an oracle whose `PASS` has never been contradicted by a known-broken input is not validated.

**Mutation suite for the docs oracle** — each mutant a deliberately broken repository state at least one gate must catch, run as a suite with a published result, as SCB publishes `oracle-selftest.json`:

- an ADR file whose number has no registry row (registry gate);
- a registry row whose link does not resolve on the branch it names (link gate);
- a hand-edited generated adapter (render gate);
- a hand-edited vendored bundle policy (digest gate);
- a `public-staged` visibility value (taxonomy gate);
- a frontmatter block missing `last-verified` (frontmatter gate);
- a profile whose `output` schema does not exist (agent-file gate);
- **an empty or absent corpus reported as clean** — SCB's M-16 by analogy, and the one mutant that catches the instrument rather than the target.

Seven of these have been exercised individually in the course of the agent-layer work; none has been run as a suite, and the eighth has never been run at all. Until it passes as a suite, V0 records outcomes as `UNKNOWN`, which under fail-closed accounting is not a success.

**What cannot be tested before implementation:** whether captured event streams are sufficient to reconstruct a run well enough to characterise it. That is answerable only with rows, and is the main reason to prefer Option B's short feedback loop.

## Recommendation

**Adopt Option B: V0 observes the documentation and agent-layer domain against the existing guardrail suite, behind an oracle interface that SCB implements as a second provider once it reaches Phase 4 — and the dataset carries SCB's measurement discipline from its first row, not from its first routing claim.**

The decisive argument is not that the guardrail suite is a good oracle; it is narrow and its narrowness must be declared. It is that **the alternative to a narrow, running, declared-scope oracle is not a broad one — it is no oracle for months, and capture code that has never met a real row.** SCB's own methodology makes this case better than this RFC can: it insists on calibration before measurement precisely because an unexercised instrument is the thing most likely to be wrong, and Option A leaves the execution layer's instrument unexercised for exactly as long as it protects it from being wrong in public.

Option B also preserves what makes SCB valuable. Under one oracle interface SCB arrives as a second implementation carrying its own calibration state, coverage declaration and fences — rather than as a dependency V0 was blocked on and therefore tempted to approximate. Two oracles of different rigour are a problem only if calibration state is not carried per row, and carrying it is one field.

### What this oracle is, and what it is not

It answers exactly one question: **does this workload satisfy a stated set of machine-verifiable properties?** It does not answer whether the documentation is any good. That distinction is the scope declaration this recommendation stands on, and it must survive into the ADR verbatim — because the moment `TRUE_DONE` is read as "the work was good", every risk in §Risks becomes active at once.

For the same reason V0's domain is an **instrumentation and calibration workload, not a representative one.** V0 answers whether we can capture, normalise, classify, oracle, measure and reproduce a run. Whether documentation work is decent material for a *router* is a question the data answers later, and this RFC deliberately declines to assume it.

### The ladder, and the rule that keeps V0 honest

| Stage | Produces | Exit criteria |
|:--|:--|:--|
| **V0** | capture only | mutation suite calibrated and published; event capture validated against replayed runs; exact model identity on every row; accounting modes separated; run records reproducible; paired-task capture works; **no routing and no recommendation** |
| **V1** | descriptive analysis | complexity features correlate measurably with execution difficulty; annotation noise quantified; ≥1 held-out workload set; no evidence the features are artefacts of one domain |
| **V2** | complexity estimation | planner decomposes a workload reproducibly; phase-level outcomes available |
| **V3** | recommendation | capability registry entries carry evidence provenance; recommendations evaluated against held-out runs |
| **V4+** | routing | `P(TRUE_DONE \| router) ≥ P(TRUE_DONE \| frontier baseline)` **and** `Cost(router) < Cost(frontier baseline)` |

The V4 exit is stated as a conjunction on purpose. "The router is cheaper" is not a routing result; it is the thing a router trivially achieves by being worse.

**V0 must not emit model-selection recommendations either — not only routing decisions.** A sentence like "Haiku appears appropriate for this workload" is formally not routing and is materially premature routing inference, arrived at without preregistration, without held-out data and without the correlation V1 exists to establish. The rule is `capture only`, and it is a rule about output, not about automation.

### What a run record must carry

The shape matters more than the field names, because it is what makes the one query the router will eventually need — *the same workload, on the same repository state, under the same oracle, across different models* — answerable at all.

| Component | Carries | Why it cannot be added later |
|:--|:--|:--|
| `Workload` | fingerprint, domain, scope, phase, complexity | the join key for paired runs |
| `Agent` / `Model` / `Harness` | provider, model id, snapshot, client + version, system-prompt hash | a row without these is uninterpretable once a snapshot moves |
| `RepositoryState` | commit, bundle version, dirty flag | "same repository state" is otherwise unverifiable |
| `Execution` | event stream, tool calls, turns, wall time | metadata separated from potentially sensitive content |
| `Accounting` | mode `api \| subscription \| local`, usage, provider-reported cost | under a subscription there is no per-run price; mixing modes in one column corrupts every later cost conclusion, undetectably |
| `Oracle` | id, version, **and calibration state** — suite name, status, result (e.g. `docs-mutation-v1: 8/8`) | otherwise an average across six months of drifting oracles looks scientific and means nothing |
| `Outcome` | `TRUE_DONE \| FALSE_DONE \| UNKNOWN \| UNREACHABLE`, fail-closed | a run whose gates did not run is `UNKNOWN`, never a pass |
| `InstrumentVersion` / `Fence` | capture version; the dated fence in force | rows either side of a fence are never summarised in one figure |
| `HumanBaseline` | on paired tasks: human time, outcome, changes | see below |

**Human baseline is a V0 requirement, not a follow-up.** It need not be a golden oracle and need not be large — the first paired tasks are enough. Without it, `Haiku: $0.10, 95% TRUE_DONE` reads as a triumph until one learns a human does the same work in seven minutes and Haiku takes forty-two, at which point the economic interpretation inverts. A cost figure with no human reference point is not interpretable, only quotable.

### The remaining disciplines

Each is lifted from SCB rather than invented, and each is a condition under which the later stages mean anything:

1. **Fences.** A change to the oracle, harness, dispatcher or model snapshot writes a dated fence. Rows before it are marked, never deleted.
2. **Cost-to-true-done, not raw cost**, as the primary quantity — the plan's second-best decision after "V0 does not route".
3. **Paired runs are the primary collection mode.** Observational rows across heterogeneous tasks will not support `P(TRUE_DONE | task, phase, model)` at the volumes a solo founder generates; the same task across N models will, at far smaller n. SCB's own design (3 runs × 3 arms), on a cheaper domain.
4. **Preregistration before any routing claim.** Hypotheses of the form "class X suffices for phase Y" are written with falsification conditions before the dataset is queried for them. The dataset, the oracle and the annotation share one author, which is exactly SCB §0.3's warning.
5. **Instrument cost as a published line item** (SCB §12.3) — the capture layer's own tokens and hours belong in the first report, not a footnote.

### Placement and the direction of the seam

A new `exeris-ai-execution` repository owns the workload model, the event store, the dataset, the oracle interface and everything downstream. `exeris-ai-bridge` becomes a context adapter later, under ADR-025, not before.

`exeris-agents` gains one small, versioned **telemetry sink contract** in the hook dispatcher — optional, no-op by default, reviewed code inside the vendored tree per rule 8 — and gains no runtime. The direction is deliberate and is the part the ADR must freeze:

```text
exeris-agents  ──normalized events──▶  Telemetry Sink Contract  ──▶  exeris-ai-execution
```

not `exeris-agents ──▶ AI Execution`. **The agent layer owns event semantics; the execution layer owns their interpretation.** An emitter that knew what a run *meant* would put analysis inside a bundle that twenty repositories vendor and verify by digest, which is the boundary the whole v2 design exists to hold.

### Why not the alternatives?

- **Option A (wait for SCB)** — it blocks V0 on a programme with six unresolved questions of its own, and SCB's frozen contract would not oracle the workload that motivated this layer anyway.
- **Option C (own oracle)** — a third judge needs its own calibration and neutrality audit before its verdicts are results, which is the most expensive part of SCB rebuilt for less reason.
- **Option D (do nothing)** — the tap already exists; not capturing is a decision to discard data that is already flowing past, and it leaves the platform's most differentiating claim unevidenced.

### Risks of the recommendation

- **A router trained on oracle outcomes selects for the oracle's blind spots.** SCB §1.3 observes that an agent optimises down everything the oracle does not check. A router is worse: it *learns* which model class passes the oracle most cheaply, so it will systematically prefer models that are good at satisfying the gates over models that are good at the work. On a docs oracle that checks structure and not quality, that is a machine for finding the cheapest way to produce structurally perfect, substantively empty documentation. Partial mitigations: the change-cost idea from SCB §7.5 (a hollow implementation is expensive to modify later) and holding a human-judged sample out of the training signal entirely. **This risk does not go away and must be stated in any report the layer produces.**
- **Three roles in one person.** The founder authors the oracle, will author the router, and is the sole annotator. SCB answers this with an external neutrality audit; this layer has no equivalent and should say so rather than imply independence it lacks.
- **The calibration set is not the deployment distribution.** SCB gives high-quality labels on a narrow frozen contract; V0 telemetry gives weaker labels on a broad drifting one. Transferring a policy between them is an extrapolation, and the gap is itself measurable rather than assumable.
- **Annotation decays.** A single-rater, unanchored 1–10 complexity scale is mostly noise and is the step skipped in week three. The three-valued *too weak / appropriate / overkill* judgement is cheap and carries most of the signal.
- **The later stages may never have the data.** Every stage through V3 must be worth building on its own — a dataset and an analyzer are useful without a learned router — so the programme is not a bet on reaching V4.
- **Capability-registry seed values are claims.** `reasoning: 7` needs a source under `claims-and-evidence.md`, and at least one model name in the draft plan (`Astra`) could not be verified against any vendor list available here.

## Decision Record

| Field | Value |
|:--|:--|
| **Outcome** | **ACCEPTED** |
| **Date** | 2026-09-09 |
| **Resulting ADR(s)** | **ADR-086** — reserved in [`adr-index.md`](../adr-index.md) by this pull request; content pending. |
| **Notes** | Accepted on the founder's decision, and on a reason narrower than the routing question the RFC opens: the observability layer is needed for the System Construction Benchmark programme whatever the routing answer turns out to be. Nothing in §Recommendation was amended to reach acceptance. The open questions in the section below stay open — they need rows or another programme's timetable, and acceptance does not pretend otherwise. |

## Open questions / follow-ups

Deliberately open, and none of them resolvable by argument — each needs either rows or another
programme's timetable. Decisions that were the author's to make have been made and are in
§Recommendation rather than parked here.

- **Is the documentation domain representative enough to seed a router at all?** Held open on purpose: V0 is scoped as a calibration workload precisely so that this is answered by data rather than assumed by the choice of first domain. A negative answer is a result, and its consequence is a second domain, not a failed V0.
- **The exact sink contract.** Direction is settled (§Recommendation); the payload, the versioning and whether it ships in bundle 1.1.0 or 2.0.0 are not. It is additive to consumers but changes what a vendored script may do at runtime, which touches rule 8's reasoning rather than its letter.
- **Retention and privacy for event payloads.** Metadata is separable from content in principle; the boundary needs writing down before the first row rather than after, and it is a policy question, not a schema question.
- **When SCB enters as the second oracle.** Its Appendix D lists six unresolved items of its own; at least "who performs the neutrality audit" bears on whether its verdicts are admissible as labels at all. Tracked against SCB Phase 1, not against this layer.
- **When the dataset becomes sufficient for a first routing hypothesis.** The V1 exit criteria are the current best answer and are themselves a guess until annotation noise has been quantified.
