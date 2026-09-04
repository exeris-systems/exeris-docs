---
title: Reference — the graph subsystem
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Reference — the graph subsystem

Authoritative source: `exeris-kernel/docs/subsystems/graph.md`, in the repository that owns the SPI.

What follows is the short form an agent needs before editing a document that touches this
subject. It does not restate the source and is not authority: when they disagree, the source wins
and this file is the defect.

The kernel Graph SPI is **dual-engine** per `exeris-kernel/docs/subsystems/graph.md`: a unified `MATCH` DSL transpiles to either SQL:2023 PGQ (on PostgreSQL 18) or Cypher (on Neo4j / Memgraph / FalkorDB). Both engine paths ship in Community. Enterprise tier adds a native PG wire-protocol driver (off-heap, no JDBC tax) plus a planned FFM Bolt v5 driver for Neo4j (TRL-4, not yet shipping).

**ADR-002** scopes itself explicitly as "platform-recommended stack for new applications, not a kernel mandate." When documenting or recommending, distinguish between (a) the platform default stack recommendation (Postgres + PGQ) and (b) the kernel's actual capability (dual-engine via SPI). Don't conflate them.

<!-- VERIFY(sweep-2026-09): the "TRL-4" label on the planned FFM Bolt v5 Neo4j driver is contradicted inside its own repo. exeris-kernel-enterprise/docs/subsystems/graph.md:8, :55 and :93 say "planned TRL-4"; exeris-kernel-enterprise/docs/ROADMAP.md:322 calls the same EPIC-E3 work a "TRL-3 skeleton with HELLO/RUN/PULL". Both sources are enterprise-private while this file is public, and exeris-kernel/docs/subsystems/graph.md — the doc this file names as precedence #1 — carries no Enterprise driver row at all (its Driver Roadmap table at :171-175 lists only PostgreSQL JDBC, Neo4j Bolt and Memgraph Bolt, all Community/TRL-3). Maintainer to pick one TRL value or drop the number. -->
