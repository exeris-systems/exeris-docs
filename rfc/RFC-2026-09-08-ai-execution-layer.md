---
title: "RFC-2026-09-08: The AI execution layer — against which oracle does V0 observe, and what must be preregistered before the dataset may justify a routing decision?"
type: rfc
visibility: public
owning-repo: exeris-docs
status: draft
last-verified: 2026-09-08
---

# RFC-2026-09-08: The AI execution layer — against which oracle does V0 observe, and what must be preregistered before the dataset may justify a routing decision?

| Field             | Value |
|:------------------|:------|
| **Status**        | **DRAFT** |
| **Author(s)**     | arkstack-dev |
| **Date Opened**   | 2026-09-08 |
| **Date Closed**   | — |
| **Scope**         | platform / cross-repo (a new sibling repository, a seam into `exeris-agents`, and a consumer relationship with `exeris-ai-bridge` under ADR-025) |
| **Owning Repo**   | `exeris-docs` (an ecosystem-shape question; the layer has no repository yet) |
| **Target ADR(s)** | TBD — one platform-scope ADR fixing the layer's boundary against ADR-025 and the agent bundle. Number reserved in [`adr-index.md`](../adr-index.md) only once this RFC is accepted. |
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

**The AI execution plan exists in draft** with a V0→V10 staging. Its central discipline — V0 observes, V0 does not route — is correct and is not in question here.

**Placement is settled and is recorded here as context, not as an option.** The layer belongs in a new sibling repository, not in `exeris-agents` and not in `exeris-ai-bridge`:

- ADR-025 states the bridge's mission as exposing Exeris surfaces **to** agents, and its clause admitting "adjacent AI-integration artefacts" is qualified by "when they share the same fundamental responsibility: bridging Exeris semantic surfaces to AI agents". A layer that consumes signals **about** agent runs is the opposite direction. ADR-025 §3 also chose TypeScript on the reasoning that no Java was needed; the execution layer's own draft skeleton is Java.
- `exeris-agents` is defined by being vendored and digest-verified — immutable content plus small deterministic tools, with no runtime. A mutable dataset and a long-running capture process would break exactly the property that makes a pinned import verifiable.
- The plan's own constraint, "the planner and the router do not know MCP", requires the bridge to be a downstream context adapter. Hosting the layer inside the bridge inverts that dependency on day one.

The cost of leaving the *oracle* question unanswered is concrete: V0 either stalls waiting for SCB Phase 0, or quietly invents a second quality system — which the plan explicitly says it does not want, and which would then be a competing, uncalibrated judge of the same runs.

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
4. **SCB §7.1** — token-to-token comparison is valid only within one model; across models the units are USD and wall time. This constrains the cost model before it is written.
5. **SCB §8** — a model reference is `id + snapshot/date + harness + system-prompt hash`. The plan's V0.2 already mirrors this; it is restated here because it is the field most often dropped and the one that makes a dataset uninterpretable a quarter later.
6. **Privacy** — the plan's own "separate metadata from potentially sensitive content" is a hard constraint, not a preference: prompt and file content may carry customer or private-repository material.

### Data gathered

What exists today, measured in this workspace on 2026-09-08 rather than assumed:

- **A validated docs-domain oracle now runs.** `agents_file_check.py`, `agents_render.py --check`, `agents_bundle.py verify`, `frontmatter_check.py`, `registry_check.py`, plus 14 eval scenarios. On the migrated `exeris-docs` tree it reports 24 files / 0 errors, and its negative behaviour has been exercised rather than assumed: 5 malformed agent-layer states are caught (a vendor `tools:` list in canonical frontmatter, a lowercase `agent.md`, a skill on disk the manifest does not name, a read-only role holding `edit`, a hook state directory not git-ignored), a hand-edited vendored policy is caught with both digests printed, a hand-edited adapter is caught as a unified diff, and 7 malformed verdict instances are rejected offline by the composing schema.
- **That set is, in SCB's terms, a proto mutation suite** — small, and never yet run as one, but the shape is right.
- **A six-vendor telemetry tap exists.** `.agents/vendor/…/hooks/bin/hook.py` intercepts pre-tool, post-tool and stop events, normalises the stdin shapes of Claude Code, Copilot, Codex, Gemini CLI, Antigravity and Cursor, and already writes session state. It is the only provider-neutral tool-call interception point in the ecosystem today.
- **An outcome record shape exists.** `verdict.base.schema.json` carries `decision` (PASS/CONDITIONAL/BLOCKED), findings each bound to a clause, and `checks_run[]` with `pass | fail | not-run`.
- **The SCB metric vocabulary is in none of the repositories.** A workspace-wide search for `true_done`, `false_DONE_rate`, `first_pass_gap`, `turns_to_true_done` and `runs_reaching_100` returns zero hits across every checked-out repository. `exeris-benchmarks` is the JMH/wrk performance harness; the System Construction Benchmark is a different programme and is not in that repository. This is a statement about the checkout, not about the plan — the plan exists and is detailed — and it fixes the sequencing: **nothing can consume SCB output until SCB Phase 0 has run.**
- **Antigravity's CLI selects agents silently.** `agy` 1.1.27 runs a turn with the default agent and exits 0 when `--agent` names something that does not resolve. Any per-run capture that records "which agent ran" from that runtime must assert it, not trust the invocation.

### Spike outcomes

No spike was built for this RFC. The agent-layer v2 work is treated as an incidental spike for two of its claims — that a provider-neutral hook dispatcher is small (one file, six wire formats) and that a content-addressed digest survives history rewriting (verified: the bundle digest was unchanged across a squash). Both bear on V0's feasibility and neither was built for that purpose.

## Options Considered

The options are over **V0's oracle**, which decides V0's first domain and therefore what the first dataset is worth.

### Option A: Wait for SCB Phase 0

Build V0's capture, and gate the first `TRUE_DONE` on the System Construction Benchmark reaching Phase 4.

**Pros:**
- One quality system, exactly as the plan wants; no competing judge.
- SCB's oracle is designed to be validated (mutation suite, neutrality audit), so labels inherit that rigour.
- The construction domains are the ones where model choice plausibly matters most.

**Cons:**
- V0 blocks on all six of SCB's own unresolved questions (Appendix D), including who performs the neutrality audit.
- SCB's frozen contract measures *system construction* — 14-entity domains, sagas, migrations. It would not oracle a repository-wide documentation sweep, the workload that motivated this layer.
- Nothing is captured meanwhile: the first row is months away and the capture code goes unexercised.

**Cost:** low to build, high latency, and a real risk that the capture design is wrong in ways only rows would reveal.

### Option B: V0 observes the documentation and agent-layer domain, against the guardrail suite

Ship V0 capture now, against the oracle that already runs. First workload family: repository-wide documentation and agent-layer changes, judged by the guardrail suite plus the eval scenarios. SCB becomes the *second* oracle when Phase 4 lands, under one shared oracle interface.

**Pros:**
- The oracle exists, is machine-runnable, and has a partially exercised negative suite (§Data gathered).
- It is exactly the workload the layer was conceived to explain.
- The outcome record already has a schema; capture and oracle meet at a shape that exists.
- SCB stays unhurried and joins later as a second oracle implementation — a stronger design than one hard-wired judge.
- Capture-design failures surface within days, on cheap workloads.

**Cons:**
- The docs oracle is narrow: it answers "is the corpus structurally consistent", never "is this document any good" — a large unmeasured surface that SCB §1.3 warns will be optimised down.
- Documentation work may be unrepresentative of where routing matters most.
- Two oracles of different rigour risk being reported as one; each row must carry its oracle's calibration state.

**Cost:** moderate. The oracle is done. What is new is the workload model, the event sink, the store, and a mutation suite for the docs oracle.

### Option C: Build an execution-layer-owned oracle

Give the layer its own quality system, independent of both the guardrail suite and SCB.

**Pros:**
- Uniform across domains from the start.
- Free of either existing instrument's blind spots.

**Cons:**
- A third judge must itself be calibrated, audited and mutation-tested; until it is, its verdicts are not results.
- Largest build of the three, and delivers no row sooner than Option B.
- Two uncalibrated judges disagreeing about one run is worse than one narrow judge with a stated scope.

**Cost:** high, and it duplicates the hardest part of SCB.

### Option D (do nothing): keep choosing models by hand

**Pros:**
- Zero cost. The founder's judgement is currently the router and is not obviously bad.

**Cons:**
- Unfalsifiable: with no record of what a cheaper model would have done, the cost of every choice is invisible.
- It leaves the platform's most differentiating claim unevidenced — and no competitor can make it without the same dataset.
- Once the tap exists the marginal cost of capture is near zero, so not capturing is a decision to discard data already flowing past.

**Cost:** nil now, compounding later.

## Testing

The layer's testable surface in V0 is the **oracle**, and it inherits SCB §4.4's entry condition by analogy: an oracle whose `PASS` has never been contradicted by a known-broken input is not validated.

**Mutation suite for the docs oracle.** Each mutant is a deliberately broken repository state that at least one gate must catch, run as a suite with a published result, as SCB publishes `oracle-selftest.json`:

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

The disciplines below are **not optional additions to the plan; they are the condition under which its later stages mean anything.** Each is lifted from SCB rather than invented:

1. **Four-valued outcome, fail-closed.** `TRUE_DONE | FALSE_DONE | UNKNOWN | UNREACHABLE`, `UNKNOWN` counted as failure. The existing `checks_run.result: not-run` is the mechanism, and a run whose gates did not run is `UNKNOWN`, never a pass.
2. **Fences.** A change to the oracle, the harness, the hook dispatcher or a model snapshot writes a dated fence. Rows before it are marked, never deleted, and rows from either side of a fence are not summarised in one figure.
3. **Exact identity.** Model id, snapshot, client, client version, system-prompt hash, bundle version, repository commit. A row missing any of these is `UNKNOWN`.
4. **Accounting mode as a first-class field.** `api | subscription | local`. Under a subscription there is no per-run price; mixing the modes in one cost column silently corrupts every cost conclusion drawn from the dataset afterwards, and the corruption is undetectable after the fact.
5. **Cost-to-true-done, not raw cost, as the primary quantity** — the plan already has this and it is its second-best decision after "V0 does not route".
6. **Paired runs are the primary collection mode.** Observational rows across heterogeneous tasks will not support `P(TRUE_DONE | task, phase, model)` at the volumes a solo founder generates; the same task across N models will, at far smaller n. This is SCB's own design (3 runs × 3 arms), applied to a cheaper domain.
7. **Preregistration before any routing claim.** Hypotheses of the form "class X suffices for phase Y" are written, with falsification conditions, before the dataset is queried for them. Without this, V0's dataset becomes a device for confirming whatever the founder already believes — and it is the founder's own dataset, oracle and annotation, which is precisely SCB §0.3's warning.
8. **Instrument cost as a published line item**, as SCB §12.3 does. The capture layer's own token and hour cost belongs in the first report, not in a footnote.

**Placement**, restated as the recommendation's structural half: a new `exeris-ai-execution` repository owns the workload model, the event store, the dataset, the oracle interface and everything downstream. `exeris-agents` gains one small, versioned **telemetry sink contract** in the hook dispatcher — an optional, no-op-by-default emitter, reviewed code inside the vendored tree per rule 8 — and gains no runtime. `exeris-ai-bridge` becomes a context adapter at V8 under ADR-025, not before.

### Why not the alternatives?

- **Option A (wait for SCB)** — it blocks V0 on a programme with six unresolved questions of its own, and SCB's frozen contract would not oracle the workload that motivated this layer anyway.
- **Option C (own oracle)** — a third judge needs its own calibration and neutrality audit before its verdicts are results, which is the most expensive part of SCB rebuilt for less reason.
- **Option D (do nothing)** — the tap already exists; not capturing is a decision to discard data that is already flowing past, and it leaves the platform's most differentiating claim unevidenced.

### Risks of the recommendation

- **A router trained on oracle outcomes selects for the oracle's blind spots.** SCB §1.3 observes that an agent optimises down everything the oracle does not check. A router is worse: it *learns* which model class passes the oracle most cheaply, so it will systematically prefer models that are good at satisfying the gates over models that are good at the work. On a docs oracle that checks structure and not quality, that is a machine for finding the cheapest way to produce structurally perfect, substantively empty documentation. Partial mitigations: the change-cost idea from SCB §7.5 (a hollow implementation is expensive to modify later) and holding a human-judged sample out of the training signal entirely. **This risk does not go away and must be stated in any report the layer produces.**
- **Three roles in one person.** The founder authors the oracle, will author the router, and is the sole annotator. SCB answers this with an external neutrality audit; this layer has no equivalent and should say so rather than imply independence it does not have.
- **The calibration set is not the deployment distribution.** SCB produces high-quality labels on a narrow frozen contract; V0 telemetry produces weaker labels on a broad drifting one. Transferring a routing policy from the first to the second is an extrapolation, and the gap between them is itself a measurable quantity that should be measured rather than assumed away.
- **Annotation decays.** A 1–10 complexity scale, single-rater and unanchored, is mostly noise and is the step that gets skipped in week three. The three-valued *too weak / appropriate / overkill* judgement is cheap, carries most of the signal, and is what the recommendation keeps.
- **V6+ may never have the data.** V0–V4 should be justified as products in their own right — a dataset and an analyzer are useful without a learned router — so that the programme is not a bet on reaching V6.
- **Capability-registry seed values are claims.** Numbers like `reasoning: 7` need a source under `claims-and-evidence.md`, and at least one model name in the draft plan (`Astra`) could not be verified against any vendor list available here.

## Decision Record

| Field | Value |
|:--|:--|
| **Outcome** | — |
| **Date** | — |
| **Resulting ADR(s)** | — |
| **Notes** | — |

## Open questions / follow-ups

- **Does the layer's first ADR need to amend ADR-025?** The bridge's "adjacent artefacts" clause is arguably narrowed by making the execution layer a separate repository. — founder, before the ADR is drafted
- **Which SCB unresolved question blocks the shared oracle interface?** Appendix D lists six; at least "who performs the neutrality audit" bears on whether SCB verdicts can be admitted as labels at all. — founder / SCB Phase 1
- **Does the sink contract belong in bundle 1.1.0 or 2.0.0?** It is additive to consumers, but it changes what a vendored script may do at runtime, which touches rule 8's reasoning. — agent-layer, next bundle release
- **What is the retention and privacy policy for event payloads?** Metadata is separable from content in principle; the boundary needs writing down before the first row, not after. — founder, before V0 capture ships
- **Is the docs domain representative enough to seed a router at all**, or is V0's honest deliverable only a dataset and an analyzer for that one domain? — answerable only with rows
- **Human baseline.** SCB Phase 0 collects one for construction. The execution layer has no equivalent for documentation work, and without it "the model was appropriate" has no reference point. — founder, consider folding into the first paired experiment
