---
title: Capability Author Guide
type: howto
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Capability Author Guide

**Scope:** platform · **Discharges:** [ADR-024](adr/ADR-024-capability-composition-model.md) open
follow-up 4 (cap-author documentation set)

How to build an `exeris-caps-*` repository that the build-time pipeline will validate and a SKU
will boot. Everything here is derived from the shipped implementation, not from intent — where the
implementation and an ADR disagree, this document follows the implementation and says so.

## Prerequisites

> **Read first:** [ADR-024](adr/ADR-024-capability-composition-model.md) (the contract),
> [ADR-023](adr/ADR-023-capability-licensing-taxonomy.md) (which licence your cap carries),
> [ADR-055](../exeris-tooling/docs/adr/ADR-055-cap-tier-wall-guard.md) (how the Wall is enforced).

- **JDK 25 LTS.** `exeris-sdk` and `exeris-tooling` both compile at `maven.compiler.release` 25, and
  `exeris-tooling`'s enforcer requires the JVM running Maven itself to be JDK 25 or newer — the
  codegen plugin loads into Maven's own JVM.
- **Maven 3.9 or newer** (`exeris-tooling`'s `requireMavenVersion` rule).
- **`exeris-sdk`, plus `exeris-tooling-bom`, `exeris-processor` and `exeris-codegen-maven-plugin`,
  installed into your local repository** — see "Build the tooling dependency without credentials"
  in §5. The published artefacts live on GitHub Packages, so building these from source is what
  keeps a cap build credential-free.

---

## 1. What a cap is

A cap is an ordinary Maven module that declares, on one class:

- what it **offers** other caps — `@Provides`
- what it **needs** from them — `@Requires`
- optionally, how it **starts and stops** — `@CapabilityLifecycle`

Nothing else makes it a cap. There is no registry to sign up to, no interface to implement on the
module class, and no runtime container. Composition is resolved **at build time**; by the time a
SKU runs, the graph has already been reduced to an ordered list.

**What a cap is not:**

- *Not a plugin discovered at runtime.* All four annotations are `@Retention(SOURCE)` — they are
  erased from bytecode. Nothing can read them after `javac`. The build-time pipeline is the only
  possible consumer.
- *Not a kernel subsystem.* Per ADR-024's 2026-07-21 amendment, the cap layer registers no
  `SubsystemProvider` and contributes no node to the kernel bootstrap DAG. The kernel is
  **cap-blind**: it has no manifest reader, no stamp check, and no capability type.
- *Not a host application.* A cap never chooses a web framework, a server, or a DI container.

---

## 2. Repository layout

```
exeris-caps-<name>/
├── pom.xml
├── LICENSE                     # per ADR-023 — Apache-2.0 or the Exeris Commercial License
├── README.md
└── src/
    ├── main/java/eu/exeris/caps/<name>/
    │   ├── <Name>Module.java        # the @CapabilityModule class
    │   ├── api/                     # visible to other caps
    │   └── internal/                # private — siblings may not reach in
    └── test/java/...
```

The package root **is** load-bearing, not convention-for-neatness. `CapTierWall` derives the set of
cap names this build owns from the segment after `eu.exeris.caps.`, and that set is what licenses
the build to read its *own* `internal` packages. A cap outside `eu.exeris.caps.*` owns no names, so
every `internal` reference it makes — including to itself — is classified as a sibling violation.

`internal` is matched as a **whole path segment**, so `internals` and `InternalCache` are not
flagged.

---

## 3. The module class

```java
package eu.exeris.caps.corspolicy;

import eu.exeris.caps.corspolicy.api.CorsPolicy;
import eu.exeris.sdk.annotation.capability.CapabilityModule;
import eu.exeris.sdk.annotation.capability.Provides;

@CapabilityModule
@Provides(service = CorsPolicy.class, version = "1.0.0")
public final class CorsPolicyModule {
}
```

That is the whole of the shipped reference cap: one `@Provides`, no `@Requires`, no lifecycle class.
`@Requires` syntax is in the attribute table below — declare one only when a service you actually
consume is provided by another cap, because an empty or speculative `@Requires` puts a false edge in
the composition DAG and changes the derived `initOrder` for every SKU that includes the cap.

**Attribute surface — the whole of it:**

| Annotation | Attributes | Notes |
|---|---|---|
| `@CapabilityModule` | *(none)* | Pure marker. Cap identity comes from the repo coordinate, not the annotation. |
| `@Provides` | `service`, `version` (default `""`) | Repeatable. `""` means unversioned. |
| `@Requires` | `service`, `versionRange` (default `""`), `optional` (default `false`) | Repeatable. `""` means any version. Maven-style ranges. |
| `@CapabilityLifecycle` | *(none)* | Pure marker, on the hooks class. At most one per cap. |

`service` is a `Class<?>` reference so your IDE and the compiler check it, but the processor never
loads the class — it records the name. `version` and `versionRange` are asymmetric on purpose: a
provider states one version, a consumer accepts a range.

**An unversioned provide is not the same as version `"0.0.0"`.** The content binding normalizes a
null version to the empty string — `service@`, distinct from `service@0.0.0`. The distinction is
load-bearing: the content binding hashes that exact string, so an implementation that emits
`service@null` computes a different SHA-256 and false-fails every deploy.

---

## 4. Lifecycle hooks

Only if your cap owns resources. Mark a class `@CapabilityLifecycle` and implement
`CapabilityLifecycleHooks` — it needs a **public no-arg constructor**, because the conductor
instantiates it reflectively from the manifest.

```java
public interface CapabilityLifecycleHooks {
    default void initialize() throws Exception {}
    default void ready() throws Exception {}
    default void drain(Duration remaining) throws Exception {}
    default void terminate() {}          // note: no throws clause
}
```

All four are no-ops by default — **implement the subset you need**.

| Phase | When | Your obligation |
|---|---|---|
| `initialize()` | After `KERNEL READY`, before the first request, in `initOrder` | Acquire what you own. Must be **idempotent** — the conductor may replay it. Do **not** call another cap's service here: it may not be initialized yet. |
| `ready()` | Only after *every* cap finished `initialize()` | The all-caps barrier. This is where cross-cap interaction is safe. |
| `drain(Duration)` | Orderly shutdown, reverse `initOrder` | Stop accepting work, finish in-flight, flush. You receive your **strictly-remaining slice** of a composition-wide budget (default 30s). |
| `terminate()` | Unconditionally, for every cap that entered `initialize()` | Release resources. Must be **re-entry-safe** and must not throw. |

**Four sharp edges, all of them real:**

1. **A throwing `initialize()` aborts boot.** The conductor unwinds the already-initialized prefix.
   A throwing `ready()` unwinds *everything*.
2. **Only `drain` is deadline-enforced.** A hanging `initialize()` hangs boot — there is no timeout
   on it. Do not do unbounded work there.
3. **The drain deadline is cooperative *and* enforced.** An overrun is interrupted and abandoned;
   once the budget is spent, remaining caps' drains are **skipped entirely**. If your drain neither
   blocks interruptibly nor checks the flag, it will delay shutdown past the budget.
4. **`terminate()` has no happens-before edge from a timed-out `drain()`.** The abandoned drain may
   still be running on another thread. Write `terminate()` defensively — this is why it cannot
   throw checked exceptions.

---

## 5. The build

### Dependencies

| Dependency | Scope | When |
|---|---|---|
| `eu.exeris:exeris-sdk-annotations` | compile | always — the four annotations |
| `eu.exeris:exeris-kernel-spi` | compile | whenever you touch a kernel SPI |
| `eu.exeris:exeris-sdk-composition-lifecycle` | compile | only with `@CapabilityLifecycle` |
| `org.junit.jupiter:junit-jupiter`, `org.assertj:assertj-core` | test | whenever the cap has tests of its own; also required by `-Dexeris.tests=true`, which makes the generator emit tests that import exactly these two |

`exeris-sdk-composition-lifecycle` is enforcer-proven to have **zero dependencies**, so taking it
adds exactly one jar.

### Plugin wiring — bind **both** goals

```xml
<plugin>
  <groupId>eu.exeris.tooling</groupId>
  <artifactId>exeris-codegen-maven-plugin</artifactId>
  <version><!-- see "Versions" below --></version>
  <executions>
    <execution>
      <goals>
        <goal>generate</goal>             <!-- generate-sources -->
        <goal>verify-capabilities</goal>  <!-- process-classes -->
      </goals>
    </execution>
  </executions>
</plugin>
```

`exeris-processor` must also be on the compiler's `annotationProcessorPaths`.

**Binding both is not optional, and the reason is not obvious.** At `generate-sources` the
`capability_*.json` on disk is by construction the *previous* build's output — the processor only
refreshes it during `compile`. A graph failure that hard-fails there deadlocks the build on its own
stale input: the `@Requires` edit that fixes the graph can never take effect, because the build dies
on the file it is about to replace.

`GenerateMojo` scans the project's build plugins for a bound `verify-capabilities` execution at
`process-classes` **or later**. When it finds one, a graph failure at `generate-sources` degrades to
a warning and the authoritative verdict comes from that gate, against metadata the processor emitted
*this* build. When it does not — or when you rebind the gate to an earlier phase, where it would
itself see stale input — `generate-sources` fails the build, deadlock included.

### First build: seed the metadata

**Never run `mvn clean compile` in one shot on a metadata-less tree.**

```bash
mvn compile -Dexeris.codegen.skip=true   # seed: processor writes exeris-metadata/
mvn compile                              # normal from here on
```

A run that loads zero entities refuses to prune a previously-generated tree (`allowEmpty` defaults
to `false`), because empty metadata is almost always a masked compile failure, and pruning on it
would silently wipe committed output.

### Versions

Track the released lines: **SDK 0.11.0** (2026-08-26), **kernel 0.11.0** (2026-08-12), **tooling
0.8.0** (2026-09-01). Pin all three to release tags rather than tracking `main` — in both your POM
and your CI checkout refs. Each repo's `main` already carries the next line (`0.12.0-SNAPSHOT` in
the SDK, `0.9.0-SNAPSHOT` in tooling), so a cap that pins a SNAPSHOT and checks out `main` resolves
a version nothing produces any more, without a single commit landing in the cap itself. An immutable
ref also stops an unrelated upstream commit from turning your build red.

A cap still *builds* tooling from source, because the published artefacts live on GitHub Packages
and resolving them reintroduces the credential this whole recipe exists to avoid. Pinning the ref
and building from source are separate decisions; do both.

### Build the tooling dependency without credentials

Building `exeris-tooling` whole drags in artefacts your cap has no use for, and the failure is
confusing because it names the kernel in a build that never mentions it. Scope the reactor instead:

```bash
# SDK: skip the semver gate — it resolves the previous release as its baseline, and no
# eu.exeris artefact is on Maven Central yet, so a clean runner has nothing to resolve.
(cd exeris-sdk && mvn -DskipTests -Djapicmp.skip=true install)

# Tooling: the two modules a cap consumes, plus the BOM, plus what they need.
(cd exeris-tooling && mvn -DskipTests install \
    -pl exeris-tooling-bom,exeris-processor,exeris-codegen-maven-plugin -am)
```

The `-pl` scoping is what keeps this **credential-free**. Kernel dependencies appear in exactly one
tooling module — `exeris-e2e-tests`, at test scope — and those artefacts live on GitHub Packages,
so building the full reactor demands a token. Nothing in the processor or plugin chain references
the kernel at all.

Three ways to get this wrong, all of them observed rather than imagined:

**`-DskipTests` alone does not work**, and the reason is worth internalising: Maven collects a
module's dependency graph whether or not its tests compile. The module has to be *out of the
reactor*, not merely quiet. Diagnosing that from the error message is hard — it surfaces as
`401 Unauthorized` on `exeris-kernel-spi` while building a repository that has no kernel dependency.

**Subtracting instead of selecting moves the failure one hop.** `-pl '!exeris-e2e-tests'` fails at
`exeris-coverage-aggregate`, which declares the excluded module at `provided` scope to locate its
`jacoco.exec`. Removing a module from the build order does not remove it from a sibling's dependency
graph. A blacklist also rots silently: it breaks again the next time tooling gains a module.

**Naming the BOM is not optional.** `-am` traverses parent and dependency edges but *not*
`dependencyManagement` imports, and `exeris-tooling-bom` reaches the plugin only through
`exeris-tooling-parent`'s import block. Omit it and you install a plugin whose POM cannot be read
back — which resolves fine on a developer machine with a warm `~/.m2` and fails on a clean one.
`exeris-caps-cors-policy`'s first CI run died exactly there, on
`exeris-tooling-bom:pom:0.7.0-SNAPSHOT (absent) ... 401`.

That last one generalises past this recipe: **verify build instructions against a scratch
`-Dmaven.repo.local`, never against your own `~/.m2`.** Every local check of this step passed on a
warm repo while CI stayed red. A cap repo's CI always starts empty, and so should your test of it.

**JDK 25 LTS.** Do not compile a cap with `--enable-preview`: it re-pins your bytecode to one exact
JDK major and re-inherits the "may change next release" contract that the preview-clean baseline
(kernel ADR-066, SDK ADR-069) exists to escape.

---

## 6. The Wall

`exeris:verify-capabilities` scans **compiled bytecode** — not source — at `process-classes`, and
only when the module actually is a cap (non-empty `capability_*.json`).

**Forbidden:**

| Rule | Why |
|---|---|
| `org.springframework.*`, `io.netty.*`, `reactor.*`, `jakarta.servlet.*` | Host selection belongs to the SKU, not a cap |
| `eu.exeris.kernel.**.internal.**` | Only the SPI surface is callable |
| `eu.exeris.caps.<other>.**.internal.**` | Cross-cap access goes through `@Provides` |

A violation fails the build listing **every** offence at once, deterministically ordered:

```
Cap-tier Wall violated (ADR-024 predicate 4) — 2 forbidden reference(s):
  - eu.exeris.caps.audit.AuditModule -> org.springframework.stereotype.Component
      (host-runtime package (host selection belongs to the SKU, not a cap))
  - eu.exeris.caps.audit.AuditModule -> eu.exeris.caps.vault.internal.Secrets
      (sibling cap's internal package (cross-cap access goes through @Provides))
```

**Two things worth knowing.** The scan reads bytecode because a source scan is blind to a forbidden
type that arrives through a *dependency* change. And it unions five extraction sources — constant
pool, field descriptors, method descriptors, `Signature` attributes, annotation types — because a
constant-pool walk alone is unsound: `void configure(ApplicationContext ctx)` puts the type only in
the method descriptor.

**Not caught:** reflective reach-through (`Class.forName("org.springframework…")`) is invisible to
any static scan. String constants are deliberately not scanned — otherwise a cap would be flagged
for logging the word "springframework". The Wall is an import-boundary guard, not a sandbox.

`-Dexeris.wall.skip=true` exists and is deliberately loud. ADR-024 obligation 3 treats a shipped
cap with the guard disabled as a registry violation.

---

## 7. What you get

On success the pipeline emits `cap-manifest.json`:

```json
{
  "schemaVersion": 2,
  "stamp": {
    "validated": true,
    "compositionVersion": "0.0.0",
    "contentBinding": "sha256:83aae848…"
  },
  "modules": [ /* … */ ],
  "initOrder": [ "com.app.Vault", "com.app.Audit" ]
}
```

`initOrder` is a topological sort of the `@Requires` DAG. Ordering is **derived** — there is no
`@Order`, no priority integer, no alphabetical fallback. The SKU's generated bootstrap replays this
list *verbatim* after `KERNEL READY`; the conductor does no DAG re-resolution at boot.

The `contentBinding` is a SHA-256 over the canonical form of the resolved cap set. It makes the
stamp non-transferable — it attests "*this* composition is valid", not "some composition is valid".
It is a **correctness and operability assertion, not a security or licensing gate**; SKU licence
enforcement is contractual per ADR-023, never technical.

---

## 8. Known gaps — read before you file a bug

| Gap | Effect | Status |
|---|---|---|
| `compositionVersion` is read from a property nothing sets | `CodegenPipeline` reads the `exeris.composition.version` system property and falls back to `CompositionStamp.UNVERSIONED` (`"0.0.0"`); nothing in the plugin or the parent POMs passes it, so a build that does not set it on the command line stamps `"0.0.0"` and the release-identity half of the stamp is inert. The asserter tolerates it by design. | untracked — no open `exeris-tooling` ROADMAP item |
| Manifest is emitted to a *source* root | It is not on the runtime classpath. Delivering it to a running SKU is a SKU-scaffold concern. | SKU scaffold, Phase 5 |
| No cross-service resolution | A legitimate cross-service `@Requires` hard-fails with "no `@CapabilityModule` provides it". `optional = true` is the documented workaround, and it misrepresents a hard requirement. | `exeris-tooling` T12/T17, 0.9.0 |
| No `composition.json` reader | The authored SKU manifest (ADR-053) has no canonical reader yet. | SKU scaffold, Phase 5 |
| No archetype | ADR-024 lists `mvn archetype:generate` for cap repos as planned scaffolding. It does not exist; this guide is the manual substitute. | open |
| Processor extraction gaps | `@Encrypted` and `@RowLevelSecurity` are not consumed by any generator. Declaring them has **no effect** today. | `exeris-tooling` C2 |

<!-- VERIFY(sweep-2026-09): the "Phase 5" label in the two rows above is the 2026-07-21
     gateway-caps implementation plan's Phase 5, the same phase ADR-053's Engineering Protocol and
     `exeris-tooling/ROADMAP.md` name. Deliberately left as written on 2026-09-05: the label is
     consistent across all three, and renaming it here alone would break that. What is genuinely
     open is whether that plan's phase numbering should be cited from a guide at all, or replaced
     by the ROADMAP item it corresponds to — a maintainer call, not a documentation defect. -->

That last row deserves emphasis: `-Aexeris.strict` audits attributes that are *extracted but
unconsumed*, so an attribute the processor never reads at all is invisible to it. Treat the gap
list as a lower bound.

---

## 9. Checklist

- [ ] Package root is `eu.exeris.caps.<name>`, with `api` / `internal` split
- [ ] Exactly one `@CapabilityModule` class
- [ ] Every `@Requires` resolves, or is explicitly `optional = true`
- [ ] `@CapabilityLifecycle` class has a public no-arg constructor; `initialize()` idempotent;
      `terminate()` re-entry-safe and non-throwing
- [ ] Both plugin goals bound; `exeris-processor` on `annotationProcessorPaths`
- [ ] Metadata seeded once with `-Dexeris.codegen.skip=true`
- [ ] No Spring / Netty / Reactor / Servlet import; no sibling `internal` reach
- [ ] JDK 25, no `--enable-preview`
- [ ] `LICENSE` matches the cap's ADR-023 row
- [ ] `cap-manifest.json` emitted with `validated: true` and a `sha256:` binding

---

## Where this does not apply

- **Tier 1 substrate.** Native-bypass transport — QUIC/HTTP/3, `io_uring`, IOCP — is a kernel driver
  implementation in `exeris-kernel` or `exeris-kernel-enterprise`, not a cap. There is no
  `exeris-caps-quic-*` or `exeris-caps-io-uring-*` repository, and nothing here describes how to
  build one ([HLA §3.2](high-level-architecture.md), "Note on transport implementations").
- **Host-runtime selection.** A cap never chooses a web framework, a server, or a DI container, and
  no cap `@Requires` `exeris-spring-runtime`. §6 fails the build on the import rather than on the
  intent.
- **SKU-side concerns.** Delivering `cap-manifest.json` to a running SKU, and authoring the SKU's
  own `composition.json` ([ADR-053](adr/ADR-053-sku-composition-manifest-format.md)), belong to the
  SKU scaffold — see §8.
- **Anything a static scan cannot see.** Reflective reach-through and string constants are outside
  the Wall by design (§6, "Not caught"). The Wall is an import-boundary guard, not a sandbox.
