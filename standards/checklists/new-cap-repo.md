---
title: New Capability Repository Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-12
---

# New Capability Repository Checklist — 10 questions before creating a repo or opening PR #1

Run before provisioning a new `exeris-caps-*` repository or marking its initial pull request ready for review. Aligned with [capability-conventions.md](../capability-conventions.md).

1. **Licensing entry.** Is the capability registered in `high-level-architecture.md` §3.2 and `cap-license-registry.md` with an agreed licence tier (`community`, `commercial`, or `enterprise-private`) and visibility?
2. **Naming and coordinates.** Does the repository name start with `exeris-caps-` and does `pom.xml` declare `groupId=eu.exeris.caps` and matching `artifactId`?
3. **The Wall (Boundary check).** Are public contracts strictly in `eu.exeris.caps.<name>.api` and internal details in `eu.exeris.caps.<name>.internal`? Are Spring, Netty, and Servlet APIs completely absent from bytecode dependencies?
4. **Module declaration.** Does the root package contain exactly one `@CapabilityModule` class declaring `@Provides` and only genuine, non-speculative `@Requires` edges?
5. **Lifecycle safety.** If `@CapabilityLifecycle` is implemented, does the hook class provide a public no-arg constructor, idempotent `initialize()`, and a non-throwing `terminate()`?
6. **Plugin configuration.** Does `pom.xml` bind `exeris-codegen-maven-plugin` goals `generate` and `verify-capabilities`, and include `exeris-processor` on the compiler processor path?
7. **Two-pass build.** Does the repository build cleanly on a fresh checkout via:
   ```bash
   mvn compile -Dexeris.codegen.skip=true && mvn verify
   ```
8. **Logging facade.** Does the code use `System.Logger` instead of introducing third-party logging engines?
9. **Hygiene files.** Are `pom.xml`, `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `README.md`, `CLAUDE.md`, and `AGENTS.md` committed at the root?
10. **CI workflows.** Are reusable workflows from `exeris-systems/.github` (`guardrails.yml`, `docs-lint.yml`, `commit-lint.yml`) wired under `.github/workflows/`?
