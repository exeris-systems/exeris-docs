---
title: New SKU Repository Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-16
---

# New SKU Repository Checklist — 10 questions before publishing a Platform SKU or opening PR #1

Run before publishing an `exeris-sku-*` repository or marking its initial pull request ready for review. Aligned with [sku-conventions.md](../sku-conventions.md).

1. **Manifest presence & validity.** Is `composition.json` authored at the repository root and does it conform to the `CapManifest` schema — at the version `exeris-sdk-composition-spec` states, which this checklist does not restate — with a valid SHA-256 `contentBinding`?
2. **Composition assertion.** Does the test suite assert manifest consistency using `CompositionStampAssertion.assertConsistent(manifest)`?
3. **Kernel-Direct execution.** Does the application boot directly on the Exeris Kernel (`KernelBootstrap` + `CompositionConductor`) with zero Spring dependencies in the data plane or API surface?
4. **Driver-swap transparency.** Are capability requirements in `composition.json` bounded strictly to kernel SPIs, ensuring the manifest is byte-identical across Community and Enterprise drivers?
5. **Licensing & visibility.** Is the composition manifest licensed under the Exeris Commercial License (`commercial`)? Is the repository public (source-available) unless qualifying for the `bot-blocker` closed-source security exception?
6. **Measured JVM baseline.** Have default JVM settings been determined through workload profiling, recorded in `README.md` with a report path and a figure state, and baked into the default container entrypoint?
7. **Diagnostics endpoints.** Are `/health` (or `/actuator/health`) and `/actuator/allocations` endpoints implemented and covered by automated tests?
8. **Containerization.** Does the repository carry a production-grade multi-stage `Dockerfile` based on an official minimal Java 25 runtime?
9. **Hygiene files.** Are `pom.xml`, `composition.json`, `Dockerfile`, `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `README.md`, `CLAUDE.md`, and `AGENTS.md` committed at the root?
10. **CI workflows.** Are reusable workflows from `exeris-systems/.github` (`guardrails.yml`, `docs-lint.yml`, `commit-lint.yml`) configured under `.github/workflows/`?
