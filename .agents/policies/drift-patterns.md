---
title: Policy — drift patterns to sweep for
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Policy — drift patterns to sweep for

Heuristics: a checklist to run against an edited file, not a gate.

**The item numbering is load-bearing.** [`docs-style-guide.md`](../../standards/docs-style-guide.md) rule 10
seeds Vale existence rules from this list by section name, and
[`claims-and-evidence.md`](../../standards/claims-and-evidence.md) rule 4 makes items 10-13 error-level rules,
citing them by number. Renaming the section or renumbering an item requires editing both standards in the
same pull request.

Absolute in this repository. The reasoning sits in the rule levels above and is not repeated here.

- **Never cite the 2026-05-05 `e2e-shop-order-saga` run**, in whole or in part — C-10. Two rules follow from it: "Axon" never appears next to a number, and no figure may depend on the v1 unresolved-rate gap.
- **Never assert a benchmark figure without its report path and figure state** — C-12, gated by [`standards/claims-and-evidence.md`](../../standards/claims-and-evidence.md). A withdrawal is fenced with the Vale toggle, never edited away.
- **Never edit an ADR's decision text in place.** A change of substance is a dated entry under `## Amendments` — [`standards/adr-conventions.md`](../../standards/adr-conventions.md) rule 7.
- **Never give a `budgetHQ/` or `pbm/` decision a number from this registry** — A, "Out of scope for the registry".

## The patterns

These have been caught across multiple sessions — when editing whitepaper / HLA / ADRs, sweep for them:

1. **"Postgres-only graph" / "replacing Neo4j"** — wrong. Kernel ships dual-engine. ADR-002 is platform recommendation; the kernel SPI is engine-agnostic.
2. **`exeris-kernel-community` listed as a sibling repository** — wrong. It is a Maven module inside `exeris-kernel/`, not a sibling.
3. **`exeris-caps-quic-h3` / `exeris-caps-io-uring-transport`** — these caps do NOT exist. Native-bypass transport is Tier 1 substrate (`exeris-kernel-enterprise`), not Tier 2.
4. **SB-family SKUs "use Spring Runtime"** — wrong. SB SKUs are kernel-direct via `@ExerisDomain` + `rest-emission` codegen. Spring Runtime has only two consumers: brownfield customer apps and BudgetHQ.
5. **Cap `@Requires: exeris-spring-runtime`** — wrong. Violates cap-tier Wall. Caps depend only on kernel SPIs.
6. **Two-value license taxonomy for caps** — wrong. Three-value (`community` / `commercial` / `enterprise-private`) per ADR-023.
7. **Bootstrap DAG with `Config → Memory → Exceptions → {...}`** — deprecated. Replace with the canonical FOUNDATION / SERVICES / RUNTIME shape above.
8. **"Family products run on Spring Runtime"** — wrong. Only BudgetHQ runs on Spring Runtime (singular dogfooding case). All future Family products are pure-Exeris.
9. **Spring Runtime described as part of "the platform stack"** — wrong. Independent Tier 1 product.

<!-- vale Exeris.RetractedFigures = NO -->

10. **The 2026-05-05 `e2e-shop-order-saga` table — never cite it again.** The dev-laptop run of 2026-05-05 (459 MB / 752 MB / 1,312 MB RSS; 0% / 1.82% / 1.22% compensation-unresolved columns; the 3.4× / 4.7× density multipliers; the "structural signature of async event-sourced dispatch returning before the work is done" mechanism) is **retracted in full** — see whitepaper §4.1's retraction box and entry **#23** in `exeris-benchmarks/docs/CLAIMS.md`'s retraction register. Three independent grounds: the Quarkus arm never ran an Axon saga (`grep '@Saga' exeris-benchmarks/targets/quarkus-benchmark-app*/src` is empty — the orchestration was hand-rolled over Axon's command bus); the correctness columns tracked a harness defect (the k6 poller's terminal-state dictionary did not recognise `CANCELLED`, documented in `AxonOrderSagaProjection`); and `exeris-benchmarks/scenarios/e2e-shop-order-saga/CONTRACT-v2.md` §10 classes the v1 findings **superseded** and any mixed-population latency table **"invalid under v2, do not cite"**. Two standing rules follow: **"Axon" never appears next to a number**, and **no figure may depend on the v1 unresolved-rate gap.** No v2 comparative saga numbers exist yet. This is the one retraction in that register that reached distributed artefacts — site, both CVs, blog EN + PL, dev.to — so treat any surviving copy of it as live, not historical.
11. **Unsourced inflation magnitudes** — *"~60% CPU waste"*, *">160 GB of allocations on a 4 GB payload"*. Withdrawn from whitepaper §1 and HLA §3.1; no campaign in `exeris-benchmarks` supports either. The gated replacements are **−25.6% / −33.3% CPU per request** and the **~1/2.7 RSS ratio with its matched-heap qualifier (1.18–1.26×)**, from `results/reports/2026-07-21-entity-read-by-id-tuned-pg-triad-comparison-eligible.md`.
12. **Quoting a benchmark figure without its fence.** `exeris-benchmarks/docs/CLAIMS.md` is the citation authority and says *"consumers copy, never paraphrase"*; read its **retraction register** and **citation canon** before quoting. Heavy-contract throughput ratios are never quotable (they read the Postgres ceiling); use CPU/req. Footprint claims travel with the budget-matched-vs-heap-matched qualifier.
13. **TRL-5 or higher claimed for the platform-aggregate state** — currently TRL-3 (Validated Architectural Prototype). Subsystems are ahead (Crypto TRL-4). Per whitepaper §7 roadmap, Q3 2026 = TRL-4 integration-tested **for the Crypto subsystem**, the only one at that level; the rest of the kernel subsystem set is TRL-3; Q4 2026 = TRL-5 component validation + the RC SPI lock; H1 2027 = TRL-6 with Kernel 1.0 GA + Spring Runtime 1.0 GA shipped together. (2027+ horizons use half-year notation — never quarters; matches the arkstack.dev roadmap canon.)

<!-- vale Exeris.RetractedFigures = YES -->
