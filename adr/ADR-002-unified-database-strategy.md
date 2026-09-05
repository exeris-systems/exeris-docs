---
title: "ADR-002: Unified Database Strategy (PostgreSQL 18)"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
slug: adr/ADR-002
---

# ADR-002: Unified Database Strategy (PostgreSQL 18)

> **Scope:** platform-recommended stack for new applications, not a kernel mandate. The Exeris kernel itself remains database-agnostic at the runtime layer (`PersistenceProvider` SPI); apps can override with their own persistence provider.

| Attribute       | Value                                                                                                                                                               |
|:----------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                                                                        |
| **Deciders**    | Arkadiusz Przychocki                                                                                                                                                |
| **Date**        | 2025-10-15                                                                                                                                                          |
| **Scope**       | platform (stack-level recommendation across all Exeris apps)                                                                                                        |
| **Owning Repo** | `exeris-docs`                                                                                                                                                       |
| **Compliance**  | [Strategic Pillar: No-Waste Compute](../../exeris-kernel/docs/whitepaper.md)                                                                                        |

## Context and Problem Statement
The "Polyglot Persistence" pattern (e.g., using Neo4j for Graph, Mongo for Docs, SQL for core) introduces massive operational complexity ("Integration Tax"), high licensing costs, and distributed transaction consistency issues.

To support **Hyper-Density** and keep the "Code Detachment" stack manageable for clients, we need to consolidate data models while maintaining high write throughput (>50k writes/sec — `unartifacted`: no write-path campaign exists in `exeris-benchmarks/docs/CLAIMS.md`).

## 🏁 The Decision
We standardize on **PostgreSQL 18** as the single engine for all primary data needs.

**Implementation Details:**
* **Relational:** Standard SQL for core business entities.
* **Documents:** `JSONB` column type for unstructured data (replacing Mongo).
* **Graph:** **SQL/PGQ** standard (read) + Recursive CTEs (write) for graph traversals (replacing Neo4j) — *the kernel Graph SPI is dual-engine and this bullet is the platform recommendation, not a kernel-wide replacement; see Amendments, 2026-09-04*.
* **Identity:** UUIDv7 for primary keys to ensure index locality and performance.
* **Security:** Mandatory usage of **Row Level Security (RLS)** for multi-tenancy enforcement.

## Positive Outcomes
* **Simplified Stack:** One database to manage, back up, and scale.
* **ACID Guarantees:** Strong consistency across relational, document, and graph data in a single transaction.
* **Cost Reduction:** Elimination of expensive specialized database licenses (e.g., Neo4j Enterprise).

## Trade-offs / Risks
* **No Specialized Time-Series:** For extremely high-frequency telemetry, Postgres might hit limits (mitigation: TimescaleDB extension if needed later).
* **Vertical Scaling Limits:** Scaling a single massive Postgres cluster is harder than sharding NoSQL (mitigation: Read Replicas and future sharding strategies).

## Amendments

- **2026-09-04 — The Graph bullet's "(replacing Neo4j)" describes the platform default, not the kernel.**
  The Decision's `**Graph:**` line reads "(replacing Neo4j)". The kernel Graph SPI is dual-engine: the same
  `MATCH` DSL transpiles to SQL:2023 PGQ on PostgreSQL 18 *or* to Cypher on Neo4j / Memgraph / FalkorDB
  (`exeris-kernel/docs/subsystems/graph.md:23` and `:133`), and Neo4j is a compiled dependency rather than a
  documentation aspiration — `exeris-kernel-community/pom.xml:162` pulls `org.neo4j.driver:neo4j-java-driver`
  at compile scope and `CommunityNeo4jClient` is a working Bolt client. Code outranks the record here, and
  the phrase is item 1 of the registered drift patterns (`.agents/policies/drift-patterns.md:31`), a Vale
  `existence` rule at **warning** level under `docs-style-guide.md` rule 10 — a lint hit, not a build
  failure. The decision itself is unchanged and remains correct in its own scope: this ADR states the
  platform-recommended stack, and says so twice already (its `> **Scope:**` note and `## Kernel
  relationship`). Read the bullet as scoped to that recommendation; the kernel neither mandates PostgreSQL
  nor drops Neo4j. No obligation changes. (PR #91)

## Engineering Protocol
Once this decision is ACCEPTED, it must be committed to the repository to maintain the Single Source of Truth.

## Kernel relationship

The kernel (`exeris-kernel`, `exeris-kernel-enterprise`) does **not** hard-depend on PostgreSQL. The persistence boundary is the `PersistenceProvider` SPI. ADR-002 is a platform-tier recommendation for the *default* stack used by new applications and reference implementations. Applications that need a different persistence backend can ship their own provider via `ServiceLoader` priority — that path is supported by the SPI and is not a deviation from this ADR.
