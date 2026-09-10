---
title: "ADR-086: Bound the AI Execution Layer to Observation Before Routing"
type: adr
visibility: public
owning-repo: exeris-docs
status: draft
slug: adr/ADR-086
---

# ADR-086: Bound the AI Execution Layer to Observation Before Routing

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **PROPOSED** |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-09-10 |
| **Scope**       | platform / cross-repo (a new sibling repository; a seam into `exeris-agents`; a consumer relationship with `exeris-ai-bridge` under ADR-025; a producer relationship with the CI publication step of ADR-087) |
| **Owning Repo** | `exeris-docs` (the layer's boundary is an ecosystem-shape decision; the layer's own repository holds the contract, not the decision) |
| **Driven By**   | [RFC-2026-09-08](../rfc/RFC-2026-09-08-ai-execution-layer.md) (accepted 2026-09-09); the oracle question for the review domain, settled after acceptance and recorded here rather than by amending the RFC |
| **Compliance**  | [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) (visibility taxonomy), [ADR-025](https://github.com/exeris-systems/exeris-ai-bridge/blob/main/docs/adr/ADR-025-ai-agent-bridge.md) (the bridge's direction of responsibility), [ADR-085](ADR-085-documentation-architecture-and-repo-hygiene-standards.md) §I and §J (agent files, enforcement layering) |

## Context and Problem Statement

Exeris is preparing a provider-neutral AI execution / workload-intelligence layer whose eventual job is to decide which class of model does which part of a task. RFC-2026-09-08 settled the three things that had to be settled before a single row could be captured honestly: the oracle V0 observes against (the existing documentation and agent-layer guardrail suite, behind an interface the System Construction Benchmark implements later as a second provider), the first domain (documentation and the agent layer — an instrumentation and calibration workload, not a representative one), and the preregistration discipline the dataset carries from its first row. It also settled placement: a new sibling repository, with `exeris-ai-bridge` as a downstream context adapter and `exeris-agents` gaining a telemetry sink contract and nothing else.

Two things happened after acceptance that an RFC cannot hold. The run record was written down as a schema (`exeris-ai-execution/schemas/run-record.schema.json`, transcribed field for field from the RFC's table) and, in the course of that, four decisions were made that the table does not contain: how a paired run is declared, how a task is identified without leaking what it was, how a row's visibility is fixed, and which rules a schema cannot see and a validator must. And the review workload — the cheapest, most regular source of rows, produced by the CI publication step of ADR-087 — turned out to have no oracle: the L1 gates judge a pull request, not the reviewer that reviewed it, so the RFC's oracle does not mean on a review row what it means on a sweep row.

The cost of leaving these in prose is the cost RFC-2026-09-08 itself names: a router trained on telemetry whose oracle, pairing and visibility were never fixed produces a story told over telemetry. The cost of leaving the review oracle undecided is subtler and nearer: the first producer will fill `oracle.id` with whatever is convenient, and an average across rows whose oracles mean different things looks scientific and means nothing.

This ADR answers: **where does the layer sit, what may it emit at each stage, what must every row carry, which oracle judges which domain and with what standing, and which of those rules are enforced by machine?**

## 🏁 The Decision

**The AI execution layer lives in `exeris-ai-execution`, observes and does not route until the V4 exit is met, consumes normalised events through a sink contract owned by `exeris-agents`, records every run in the shape of `run-record.schema.json` under fail-closed accounting, judges each domain by a declared oracle whose calibration state travels on the row, and splits its dataset — never its contract — by ADR-020 visibility.**

The layer adds no enforcement layer to ADR-085 §J. It observes L0–L2 and consumes their verdicts; it is a consumer of the agent layer's events, not a rule-holder, and a consumer of CI's verdicts, not a gate.

**Concrete obligations:**

### A. Placement and the direction of the seam

1. **`exeris-ai-execution` owns the workload model, the event store, the dataset, the oracle interface and everything downstream.** It is a sibling repository, public, under the organisation's shared enforcement (`caller-example/guardrails.yml`) like every other public repository.
2. **`exeris-agents` gains one small, versioned telemetry sink contract in the hook dispatcher and gains no runtime.** The sink is optional, no-op by default, and reviewed code inside the vendored tree — `agents-md-schema.md` rule 8 forbids anything fetched at session time. The direction is fixed and is the part a reviewer checks first:

   ```text
   exeris-agents  ──normalized events──▶  Telemetry Sink Contract  ──▶  exeris-ai-execution
   ```

   **The agent layer owns event semantics; the execution layer owns their interpretation.** A change that puts analysis, aggregation or a sentence about which model did better inside the bundle is a `[HARD BLOCK]` in `exeris-agents`, whatever its size.
3. **`exeris-ai-bridge` is a context adapter to this layer, later, under ADR-025 — never its host.** The bridge's mission runs from Exeris surfaces *to* agents; this layer runs the other way. A pull request that adds capture, a dataset or an oracle to the bridge is out of bounds.
4. **The System Construction Benchmark is a separate programme.** It enters this layer as a *second oracle implementation* behind the same interface when it reaches its Phase 4, carrying its own calibration state and fences; it is not hosted here and its output is not consumed before its own Phase 0 has run.

### B. What each stage may emit

5. **V0 emits capture only.** No routing decision, and no model-selection recommendation — a sentence of the form "model X appears appropriate for this workload" is premature routing inference and is barred from every artefact the layer produces: reports, README, commit messages, review comments. The rule is about *output*, not automation: capture may be fully automatic and still nothing may say which model to use.
6. **The ladder stages on what a stage is permitted to emit**, and its exit criteria are the RFC's:

   | Stage | Produces | Exit criteria |
   |:--|:--|:--|
   | **V0** | capture only | mutation suite calibrated and published; event capture validated against replayed runs; exact model identity on every row; accounting modes separated; run records reproducible; paired-task capture works; no routing and no recommendation |
   | **V1** | descriptive analysis | complexity features correlate measurably with execution difficulty; annotation noise quantified; at least one held-out workload set; no evidence the features are artefacts of one domain |
   | **V2** | complexity estimation | a planner decomposes a workload reproducibly; phase-level outcomes available |
   | **V3** | recommendation | capability-registry entries carry evidence provenance; recommendations evaluated against held-out runs |
   | **V4+** | routing | `P(TRUE_DONE \| router) ≥ P(TRUE_DONE \| frontier baseline)` **and** `Cost(router) < Cost(frontier baseline)` |

   The V4 exit is a conjunction on purpose: "the router is cheaper" is what a router trivially achieves by being worse.
7. **The schema carries no field that expresses a routing decision, and none may be added that does.** A schema change that introduces one is a MAJOR change under §C.9 and a `[HARD BLOCK]` until the V3 exit is met.
8. **Every stage through V3 must be worth building on its own.** A dataset and an analyser are useful without a learned router; the programme is not a bet on reaching V4, and no stage is justified by the stage after it.

### C. What a run record carries

9. **`exeris-ai-execution/schemas/run-record.schema.json` is the contract.** It is transcribed from RFC-2026-09-08's table *What a run record must carry*; every component of that table is required because the table's third column lists what cannot be added later. The schema is versioned by SemVer over the contract, as the agent bundle is: a new required field, a removed or renamed field or a changed enum is MAJOR and writes a fence; a new optional field is MINOR; wording is PATCH.
10. **Five additions to the table are accepted, each marked "Not from the RFC table" on its own field:** `run_id` and `started_at` (a row that cannot be named or dated is on neither side of a fence); `repository_state.repository` (a commit alone does not resolve across twenty sibling repositories); `repository_state.visibility` (§F); and `pairing` (§E.16). Each is a condition of one of the table's own disciplines being executable, not a new discipline.
11. **One deliberate departure from the table is recorded:** the table names `Workload.fingerprint` as "the join key for paired runs". It is not. The join key is `pairing.group_id`, declared before the arms run (§E.16); `fingerprint` identifies the *same task across time* — the same planned task re-run after a fence — and nothing else. The schema says so on both fields.
12. **Metadata only.** Prompts, file content and tool arguments never appear in a run record. `execution.event_stream` references the stream (a location, a digest and an event count); it does not carry it. The artefact it points at is stored outside the dataset and is subject to the retention policy of §H.
12a. **An oracle that judges after the run is a second record, not a later edit.** A run record carries the outcome known *when the run ended*; where the oracle's verdict arrives later — a disposition read from a pull request's history, an SCB judgement of an earlier run, a re-judgement after a fence — it is written as a **judgement record** (`schemas/judgement-record.schema.json`): `run_id`, `oracle` with its calibration state, `judged_at`, `outcome`, and for the review domain the per-finding dispositions. Judgement records are appended under the same inbox rules and the same fail-closed constraint as run records (a judgement from an uncalibrated oracle carries `UNKNOWN`), and a run's outcome is read as the latest judgement inside the fence in force, else the run record's own. One run may have many judgements; a judgement has exactly one run. This is the general shape of "the oracle orders differently from the run", and it is the reason a row never needs an artefact to outlive the pull request it came from.
13. **A model reference is `id + snapshot + harness + system-prompt hash`** (SCB §8), and all four are required. `system_prompt_sha256` covers the instruction material the *repository* controls — the prompt text a workflow passes, the routine file, `AGENTS.md` at the recorded commit — and the harness's own prompt changes are covered by `harness.version`. A producer that cannot compute the hash so defined records no row rather than a row with a convenient hash.
14. **Accounting modes are never mixed.** `accounting.mode` is `api | subscription | local`; only an `api` row may carry `provider_reported_cost`, and a cost figure computed from a price list — including one a runtime prints under a subscription — is imputed and is dropped. The schema enforces the first half; the producer is responsible for the second.

### D. Domains and their oracles

15. **Each `workload.domain` names its oracle, and each oracle's standing is declared per row in `oracle.calibration`.** The domains this ADR admits, their oracles, and what each oracle's verdict is admissible as:

   | `workload.domain` | Oracle (`oracle.id`) | What it answers | Calibration suite | Admissible as |
   |:--|:--|:--|:--|:--|
   | `docs-sweep` — an agent edits documentation or the agent layer | `docs-guardrails` — the L1 guardrail suite (`frontmatter_check`, `registry_check`, `agents_file_check`, `agents_render --check`, `agents_bundle verify`, the eval scenarios) | does the corpus satisfy a stated set of machine-verifiable structural properties — never whether the documentation is any good | `docs-mutation-v1` — the eight mutants of RFC-2026-09-08 §Testing, run as a suite, result published | labels, once the suite passes as a suite |
   | `docs-review-calibration` — a reviewing role reviews a pull request from a **seeded corpus** | `review-planted` — planted-defect recall: the review's `findings[]` cover every seeded defect with the correct `why` clause, and no `blocking` finding lands on a clean control | did the reviewer find what was there to find, and refrain from finding what was not | `review-planted-selftest-v1` — the four cases of obligation 17 | labels, once the self-test passes; the primary source of review-domain labels |
   | `docs-review-live` — a reviewing role reviews a real pull request in CI | `review-disposition` — per-finding disposition read from the pull request's subsequent history: a finding whose `location` file changed after the review and whose thread was resolved is *addressed*; a blocking finding merged over with the file unchanged is *overruled*; the rest is *unresolved* | what the human did with the review | none available — the judge is the founder on the founder's own pull request (SCB §0.3) | **observational only**; never a label on its own, never summarised in one figure with `review-planted`, reported only beside it |
   | any construction domain | `scb` — the System Construction Benchmark at its Phase 4 | per SCB's frozen contract | SCB's own `oracle-selftest` and neutrality audit | labels, under SCB's own rules |

   A `docs-review-live` row is **complete when the review ends and its outcome is `UNKNOWN`** — the oracle has not judged yet, and fail-closed says exactly that. The disposition arrives when the pull request closes, and it arrives as a **judgement record** (§C.12a), keyed by `run_id`, appended then; the run record is never touched. This is what keeps §E.20 true for an oracle that judges after the fact: a row written at review time and "filled in" at merge would be a rewrite, and a row written only at merge would need artefacts to outlive the pull request. Neither is required.

   `review-disposition` carries an incentive that is not the blind-spot risk of §Trade-offs and is recorded separately: a reviewer that reports few, safe findings is never overruled and scores well; one that catches hard things and is sometimes wrong scores worse. It rewards timidity, not blindness. That is tolerable on an oracle marked observational and intolerable on one that labels — which is the second reason, after SCB §0.3, that the *Admissible as* column says what it says.

16. **Two review-domain oracles are rejected, and the reasons are recorded because both are cheap enough to be reached for again once the reason has faded.** *Agreement with the L1 gates* (the review's `checks_run` and `decision` compared with CI's check-run conclusions) measures exactly the part of a review that is redundant with CI — the routine's own instruction is to review "the substance those gates cannot judge" — so a router trained on it selects the model best at restating CI; SCB §1.3 in its purest form. *The guardrail suite applied to the pull request* judges the author of the pull request, not the reviewer, and would make a review's outcome a function of somebody else's frontmatter.
17. **The planted-defect oracle is calibrated before it labels**, by a self-test of at least four cases, each of which must produce `FAIL`: a verdict that omits one seeded defect; an empty verdict on a seeded pull request; a `blocking` finding on a clean control; and an empty or absent corpus reported as clean — the one case that catches the instrument rather than the target. Until the self-test passes as a suite, `oracle.calibration.status` is `not-run` and the schema admits no `TRUE_DONE` or `FALSE_DONE` on any row naming it — the same mechanism that holds `docs-guardrails`, with no additional rule.
18. **The seeded corpus is a set of planned tasks.** Each seeded pull request is a task in the private task registry (§F.24) with a `reg:` fingerprint, and a run of the corpus across N runners is a declared group (§E.16). It is the first paired collection this layer can plan, and it is held out from anything that could train on it: seeded pull requests are rotated, and a mutant that has appeared in a report is retired from the labelling set.

### E. Collection disciplines

19. **Fail-closed.** `outcome` is `TRUE_DONE | FALSE_DONE | UNKNOWN | UNREACHABLE`. A run whose oracle did not run, or whose oracle's calibration status is `fail` or `not-run`, is `UNKNOWN`, never a pass; a run that never got far enough to be judged is `UNREACHABLE`. The schema enforces the calibration half.
20. **Fences.** A change to an oracle, a harness, the dispatcher, the capture version or a model snapshot writes a dated fence (`instrument.fence`). Rows on either side of a fence are never summarised in one figure. Rows are appended and marked, never rewritten or deleted; a correction is a new row and a fence.
21. **Cost-to-true-done, not raw cost, is the primary quantity**, and across models the only comparable units are USD and wall time (SCB §7.1); token counts compare within one model only.
22. **Paired runs are the primary collection mode, and a pair is declared, not inferred.** `pairing.group_id` is assigned when the task is planned — before any arm runs — and every arm carries it; `pairing.arm` is a slot in the plan, unique within the group, so replicates are distinct slots and `pairing.arms_planned` counts the model rows expected. Observational rows across heterogeneous tasks do not support `P(TRUE_DONE | task, phase, model)` at the volumes one maintainer generates; the same task across N models does, at far smaller n.
23. **The human arm runs first.** `human_baseline` is a field on each model row, not a row of its own, so it is known when each model row is written and no row is rewritten later; and the human has not seen a model's output. A group declares `pairing.baseline: human | none` when it is planned; `human` requires `human_baseline` on every row, `none` is admitted and marks a group that can never carry an economic claim — a cost figure with no human reference point is not interpretable, only quotable. The moment `human_baseline` needs a second field about the *human* rather than about the *work*, it stops being a field and becomes a record; that is a MAJOR change and is anticipated here so that it is recognised rather than discovered.
24. **Annotation is three-valued and attributed.** `workload.complexity.judgement` is `too-weak | appropriate | overkill`, with `rater` and `rated_at`; a single-rater, unanchored numeric scale is not admitted. The dataset, the oracle and the annotation share one author, which is SCB §0.3's warning; naming the rater on every row is the least the record can do about it, and it is what makes V1's "annotation noise quantified" computable when a second rater exists.
25. **Preregistration before any routing claim.** A hypothesis of the form "class X suffices for phase Y" is written with its falsification condition before the dataset is queried for it, in the private task registry, dated.
26. **Instrument cost is a published line item.** The capture layer's own tokens and hours appear in the first report, not in a footnote (SCB §12.3).

### F. Visibility, privacy and the task registry

27. **The contract is public; the rows are split by visibility.** `exeris-ai-execution` holds the schema, the tooling, the published reports and the inbox for rows whose `repository_state.visibility` is `public`. `exeris-ai-execution-enterprise` holds the inbox for `enterprise-private` rows and the task registry. The precedent is ADR-018 (public spec beside a private decoder) and the `exeris-benchmarks` / `exeris-benchmarks-enterprise` pair; the dataset is one dataset logically, read from two roots.
28. **Visibility is the ADR-020 two-valued vocabulary and the mapping from the hosting platform is fail-closed:** only a repository the platform reports as public maps to `public`; every other value — private, internal, unknown — maps to `enterprise-private`. Visibility is recorded at capture time and is never re-derived: a repository made public later does not reclassify its earlier rows, and a row already published under `public` is not un-published by the repository going private.
29. **One visibility per inbox, declared by the inbox itself** (`inbox/inbox.json`), read by the validator and never inferred from a directory name or a git remote. A row that does not match belongs in the sibling repository and is refused here. Filing a row under the wrong visibility is the one mistake that cannot be corrected afterwards; the remedy recorded in `inbox/README.md` treats it as a disclosure, not as a tidy-up.
30. **`workload.scope` is a vocabulary, not prose.** The base schema leaves it open; the composing schema narrows it to an enum per domain. What a task *did* is carried by its fingerprint and its registry entry, what *kind* of task it was by `scope`. Free text in `scope` is the one field on a metadata-only row that can carry a roadmap, and it is closed on public and private rows alike.
31. **`workload.fingerprint` is opaque and not derivable from the task text by anyone without private material.** Two producer classes, each namespaced in the value: `reg:` — an identifier assigned by the private task registry when the task is planned, stable across time and across arms; `ci:` — a keyed MAC over `(repository, pull request, head sha)` for workloads a CI producer observes rather than plans, stable across arms of one pull request and *not* across a key rotation, which is a fence. The classes are disjoint universes and the prefix makes an accidental join between them impossible rather than silent. A content hash of a short task description is rejected: published, it is an oracle that confirms a guess.
32. **The private task registry is the first thing `exeris-ai-execution-enterprise` holds**, and it exists before the first *planned* group, whatever that group's repository visibility — a group is declared before its arms run, and the registry is what declares it. It records, per task: the identifier, the description, the date planned, and any preregistered hypothesis with its falsification condition.

### G. Rules a schema cannot see

33. **The inbox validator is the first piece of tooling in the layer, and it exists before the first row lands.** `inbox/README.md` promises that a non-conforming row is "reported back to the producer"; without the validator that promise is false from the first row. It needs nothing beyond the standard library.
34. **The validator enforces, across files, what JSON Schema cannot express in one:** every row's `repository_state.visibility` equals the inbox's declared visibility; `repository_state` is identical within a `group_id`; `human_baseline` is byte-for-byte identical within a `group_id`; `arm` is unique within a `group_id`; every judgement record's `run_id` resolves to a run record in the same inbox. Until it runs, these four rules are *checkable, not checked*, and every document that mentions them says so in those words.
35. **The docs oracle's mutation suite runs as a suite and publishes its result** (`oracle-selftest.json` in SCB's form) before any row names `docs-guardrails` with `calibration.status: pass`. The eighth mutant — an empty or absent corpus reported as clean — is part of the suite from its first run.

### H. Explicitly deferred

36. **The sink contract's payload and version.** Direction is fixed (§A.2); the payload, the versioning and whether it ships in bundle 1.x or 2.0 are decided after CI-produced rows have shown what a run needs from the local dispatcher. It is an amendment to this ADR and a release of `exeris-agents`, reviewed against rule 8's reasoning as well as its letter.
37. **Retention and the privacy boundary for event payloads.** How long the artefact `execution.event_stream.ref` points at is kept, and where the line between metadata and content falls, are policy questions; they are written down before the first `enterprise-private` row and recorded by amendment. Until then the inbox conventions stand on their own and do not depend on the answer.
38. **When SCB enters as the second oracle** — tracked against SCB's Phase 1, not against this layer.
39. **Whether the documentation domain is representative enough to seed a router.** Held open on purpose: a negative answer is a result, and its consequence is a second domain, not a failed V0.

## Consequences

### ✅ Positive Outcomes

- **[+] Every row is interpretable on its own.** Model reference, repository state, oracle and its calibration state, accounting mode and fence travel on the row, so a row written today can be read in a year without the conversation that produced it.
- **[+] Fail-closed by construction.** The schema itself refuses a positive outcome from an uncalibrated oracle; the layer cannot report a success it has not earned, and every honest row today reads `UNKNOWN`.
- **[+] The review domain gets labels from a calibrated oracle and observation from a cheap one, and the two cannot be confused** — the table in §D.15 says what each verdict is admissible as, and the observational one never appears alone.
- **[+] The seam holds the bundle's property.** Twenty repositories vendor and digest-verify `exeris-agents`; nothing in this ADR puts a mutable dataset or an interpretation inside it.
- **[+] Private rows are captured, not dropped**, and the contract stays public — the split follows two precedents the ecosystem already lives with.
- **[+] Pairing is a declared design, not a post-hoc grouping** — the preregistration discipline the RFC asks for is a field, a registry and a validator rule rather than a sentence.

### ⚠️ Trade-offs

- **[-] Nothing this layer records today is a pass.** Until the docs mutation suite and the planted-defect self-test run as suites, every row is `UNKNOWN`. That is the price of calibration before measurement, and it is paid in public.
- **[-] Three roles in one person.** The founder authors the oracles, will author the router, and is the sole annotator. SCB answers this with an external neutrality audit; this layer has no equivalent, says so, and does not imply independence it lacks.
- **[-] A router trained on oracle outcomes selects for the oracle's blind spots.** On a docs oracle that checks structure and not quality, that is a machine for finding the cheapest way to produce structurally perfect, substantively empty documentation. Partial mitigations: SCB §7.5's change-cost idea, and a human-judged sample held out of the training signal entirely. This risk does not go away and is stated in every report the layer produces.
- **[-] Two more repositories** — `exeris-ai-execution` and `exeris-ai-execution-enterprise` — for one maintainer, before the first row.
- **[-] The calibration set is not the deployment distribution.** `review-planted` gives high-quality labels on a seeded, frozen corpus; `review-disposition` gives weak labels on real, drifting work. Transferring anything between them is an extrapolation, and the gap is itself the thing to measure.
- **[-] The `ci:` fingerprint class is not stable across a key rotation.** A rotation is a fence; the registry class exists so that planned tasks never depend on it.

### 📋 What is NOT in scope

- **The CI publication and capture step** — identity, credential, labels, the required check, the envelope's producer-side derivations. That is ADR-087.
- **The router's design**, its capability registry and its seed values. Nothing before V3 may contain them, and `reasoning: 7`-style seed values are claims under `claims-and-evidence.md` when they appear.
- **The System Construction Benchmark itself** — its contract, its Phase 0, its neutrality audit. It is a separate programme that this layer consumes at Phase 4.
- **The bridge's context-adapter role** — under ADR-025, later, by its own amendment.

### 🚫 Non-Goals

- **A router.** This ADR does not aim at one; it aims at a dataset that could justify one and is useful if it never does.
- **A judgement of documentation quality.** The docs oracle answers whether a corpus satisfies stated machine-verifiable properties, and that scope declaration survives here verbatim because the moment `TRUE_DONE` is read as "the work was good", every risk above becomes active at once.
- **Substituting for an external audit.** Naming the rater, holding out a human-judged sample and publishing instrument cost reduce the three-roles problem; they do not resolve it, and this ADR does not claim they do.
- **Capturing content.** Event streams, prompts and diffs are referenced, hashed and counted, never stored in the dataset.

### ⚠️ Risks and Assumptions

- **Assumes:** the L1 guardrail suite and the review routines keep emitting machine-readable verdicts in the bundle's `verdict` shape; `exeris-agents` accepts an optional, no-op sink in its dispatcher without a runtime; a CI runner exposes enough (turns, tool calls, an execution log that can be referenced by digest) for the CI producer to fill `execution` honestly — unverified until one real run, and tracked in ADR-087.
- **Reversed by:** rows that show the envelope cannot reconstruct a run well enough to characterise it — that is a V0 failure and the answer is a MAJOR schema change, not a footnote; a documentation domain that V1 shows is unrepresentative — the answer is a second domain; a planted-defect self-test that cannot be made to pass without leaking the corpus — the answer is a different review oracle, recorded by amendment, with §D.16's two rejections still standing.
- **Risk:** a producer fills a required field with a convenient value (a hash of the wrong thing, a `public` from a directory name, a cost from a price list). The validator catches the cross-file half; the producer-side half is caught only by the review of the producer's own derivations, which is why ADR-087 owns them and why this ADR names the field definitions precisely. The founder notices first, which is the problem.

## Cross-references

- [RFC-2026-09-08](../rfc/RFC-2026-09-08-ai-execution-layer.md) — the accepted exploration behind §A–§E; its option trail and its open questions are not repeated here.
- ADR-087 (CI publication and capture — `exeris-bot`) — the producer of `ci:`-class rows and the owner of every producer-side derivation named in §C.
- [ADR-025](https://github.com/exeris-systems/exeris-ai-bridge/blob/main/docs/adr/ADR-025-ai-agent-bridge.md) — bounds the bridge to bridging Exeris surfaces to agents; §A.3 follows from it.
- [ADR-020](ADR-020-open-core-documentation-mirror-policy.md) — the two-valued visibility taxonomy §F.28 maps onto.
- ADR-018 — the public-spec / private-decoder split §F.27 repeats.
- [ADR-085](ADR-085-documentation-architecture-and-repo-hygiene-standards.md) §I.30 (agents file nothing without a named human author), §J (the layering this layer observes and does not extend).
- `exeris-docs/standards/agents-md-schema.md` rule 8 — no fetch at agent runtime; the sink is reviewed vendored code.
- `exeris-ai-execution/schemas/run-record.schema.json`, `exeris-ai-execution/inbox/README.md` — the contract and the inbox convention this ADR makes binding; where this ADR and those files disagree on a field's meaning, the schema's field description is the home and this ADR is amended.
- `exeris-agents/bundle/schemas/verdict.base.schema.json` — the shape every reviewing role returns; `review-planted` reads `findings[].why` and `findings[].location` from it.
- System Construction Benchmark v1.3 (working material outside the repositories) — §0.1–§0.3, §1.3, §7.1, §7.5, §8, §9.5, §12.3 are cited above by number.

## Engineering Protocol

1. **Exists (2026-09-10):** `exeris-ai-execution` locally, with `schemas/run-record.schema.json`, `inbox/README.md`, `inbox/inbox.json` and the four validator rules as a specification. Not yet on GitHub; not yet under `caller-example/guardrails.yml`.
2. **Before the first row:** the repository on GitHub, public, with the guardrails caller; the inbox validator (stdlib only, the five rules of §G.34, `inbox.json` as the inbox's identity); `schemas/judgement-record.schema.json` beside the run record, sharing its `oracle` and `outcome` definitions by `$ref` rather than by copy; the load-bearing wording in `inbox/README.md` fixed to *appended, marked, never rewritten or deleted* so that the reason `group_id` was chosen over a pointer is true of the text it cites.
3. **Before any `calibration.status: pass`:** the docs mutation suite run as a suite with `oracle-selftest.json` published; the planted-defect self-test of §D.17 passing as a suite.
4. **Before the first planned group:** `exeris-ai-execution-enterprise`, private, holding the task registry and the `enterprise-private` inbox with its own `inbox.json`. Ordered *after* the first CI-produced rows have shown that the envelope reconstructs a run — planning pairs on an instrument nobody has checked is the thing V0 exists to prevent.
5. **Sink contract:** an amendment to this ADR and a MINOR or MAJOR release of `exeris-agents` (decided by whether a vendored script's runtime behaviour changes), after CI rows exist — §H.36.
6. **Stubs:** `docs/adr/ADR-086.link.md` in `exeris-agents`, `exeris-ai-bridge` and `exeris-ai-execution`; a *(private repo)* marker for `exeris-ai-execution-enterprise` in the registry's stubs table. Accepted ahead of the stubs under `adr-conventions.md` rule 5's `[L2]` gate, as rows 030, 072 and 085 are; tracked as `[DOC DEBT]`.
7. **Registry:** the reserved row 086 is pointed at this file and its status changed from `reserved` to `accepted (YYYY-MM-DD)` in the accepting pull request; the PR carries the `adr` label and `Refs: ADR-086`.
8. **Review-time assertions this ADR adds** (L2, until a gate exists): any artefact under `exeris-ai-execution` that names a model as appropriate for a workload → `[HARD BLOCK]` before V3; any change to `exeris-agents` that interprets events → `[HARD BLOCK]`; a row naming an oracle whose calibration status is not `pass` with a positive outcome → rejected by the schema, and a producer that works around it → `[HARD BLOCK]`.
