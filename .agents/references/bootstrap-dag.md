---
title: Reference — the bootstrap DAG
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Reference — the bootstrap DAG

Authoritative source: `exeris-kernel/docs/subsystems/bootstrap.md`, and `SubsystemOrchestrator` where the
two disagree — code outranks prose.

What follows is the short form an agent needs before editing a document that touches this
subject. It does not restate the source and is not authority: when they disagree, the source wins
and this file is the defect.

Per `exeris-kernel/docs/subsystems/bootstrap.md`:

```
FOUNDATION: Memory (sequential)
    ↓
SERVICES: Crypto & Persistence & Graph & Transport (dependency-safe rounds, on the booting thread)
    ↓
RUNTIME: Events & Flow & HTTP (dependency-safe rounds, on the booting thread)
    ↓
KERNEL READY
```

`Config` is resolved by `KernelBootstrap` via `ServiceLoader<ConfigProvider>` before the orchestrator runs and is **not** a Subsystem in the DAG. `Exceptions` is not a Subsystem layer. `Security` is an L1 Citadel concept (ADR-012), not a boot-DAG node. The deprecated `Config → Memory → Exceptions → {Security, Persistence} → {Graph, Transport} → {Events, Flow} → READY` framing should be replaced wherever it surfaces.

<!-- VERIFY(sweep-2026-09): the bootstrap DAG block above is quoted from exeris-kernel/docs/subsystems/bootstrap.md, and that file contradicts itself on the phase-start mechanism. Its "Holy Order" block (:213-215) and Diagram 1 (:66, :71) still read "SERVICES (parallel)" / "RUNTIME (parallel)", while its own ADR-066 passage (:340-355) records that the per-subsystem fork was removed and "a phase takes the sum of its subsystems' start times rather than the longest". SubsystemOrchestrator.java settles it — :691 "Each round runs on THIS thread, in order." — and the wording above follows the code. Cross-repo [DOC DEBT] against exeris-kernel; do not re-sync this block to bootstrap.md's Holy Order text until that file is fixed. -->

<!-- VERIFY(sweep-2026-09): exeris-spring-runtime/CLAUDE.md:83 carries the superseded form of the DAG corrected here — "SERVICES: Crypto & Persistence & Graph & Transport (parallel via StructuredTaskScope)" — contradicted by SubsystemOrchestrator.java:55-57 and :691 on both the default and preview kernel lines. That repo is outside this sweep's scope; cross-repo [DOC DEBT]. -->
