---
description: Sweep an edited file for the 10 common drift patterns from `CLAUDE.md`. Use after any non-trivial HLA / whitepaper / large-doc edit.
argument-hint: edited file path (e.g. `high-level-architecture.md`) or PR diff
---

Sweep this file for the 10 common drift patterns.

Patterns (per repo `CLAUDE.md` § Common drift patterns):
1. **"Postgres-only graph" / "replacing Neo4j"** — wrong. Kernel ships dual-engine. ADR-002 is platform recommendation; SPI is engine-agnostic.
2. **`exeris-kernel-community` listed as a sibling repository** — wrong. It's a Maven module inside `exeris-kernel/`.
3. **`exeris-caps-quic-h3` / `exeris-caps-io-uring-transport`** — these caps do NOT exist. Native-bypass is Tier 1 substrate (`exeris-kernel-enterprise`), not Tier 2.
4. **SB-family SKUs "use Spring Runtime"** — wrong. SB SKUs are kernel-direct via `@ExerisDomain` + `rest-emission` codegen. Spring Runtime has only two consumers: brownfield customer apps and BudgetHQ.
5. **Cap `@Requires: exeris-spring-runtime`** — wrong. Violates cap-tier Wall.
6. **Two-value license taxonomy for caps** — wrong. Three-value (`community` / `commercial` / `enterprise-private`) per ADR-023.
7. **Bootstrap DAG with `Config → Memory → Exceptions → {...}`** — deprecated. Replace with FOUNDATION / SERVICES / RUNTIME shape.
8. **"Family products run on Spring Runtime"** — wrong. Only BudgetHQ does (singular dogfooding).
9. **Spring Runtime described as part of "the platform stack"** — wrong. Independent Tier 1 product.
10. **TRL-5+ claimed for the platform-aggregate state** — currently TRL-3.

File / change:
$ARGUMENTS

Please:
1. For each pattern, run a targeted `grep -nE` and report hits.
2. If hits found, list line numbers and quote the offending text.
3. For each hit, propose the canonical-correct phrasing.
4. Single-edit changes leave inconsistencies — confirm the SAME correction is applied to every site, not just the one the PR happens to touch.
5. If the edit is to `high-level-architecture.md` or `b2b-technical-whitepaper.md`, the sweep is mandatory; if to a smaller doc, sweep at least the patterns plausibly in scope.

Don't trust a clean sweep without grepping. The patterns are subtle precisely because they're easy to re-introduce.
