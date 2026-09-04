---
title: "ADR-053: SKU Composition Manifest Format — JSON"
type: adr
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-05
slug: adr/ADR-053
---

# ADR-053: SKU Composition Manifest Format — JSON

| Attribute       | Value                                                                                                                |
|:----------------|:---------------------------------------------------------------------------------------------------------------------|
| **Status**      | **ACCEPTED**                                                                                                         |
| **Deciders**    | Arkadiusz Przychocki                                                                                                 |
| **Date**        | 2026-07-21                                                                                                           |
| **Scope**       | platform (binds the `exeris-sku-*` repository convention, the `exeris-tooling` canonical reader, and the `exeris-sdk-composition-spec` schema module) |
| **Owning Repo** | `exeris-docs`                                                                                                        |
| **Driven By**   | ADR-024 open follow-up 3 ("Composition manifest format specification — YAML / JSON / pkl decision plus the canonical reader implementation"); the 2026-07-21 gateway-caps implementation plan (P0.4), founder-approved same day |
| **Compliance**  | [HLA §3.3 SKU Compositions](../high-level-architecture.md), [HLA §4 Capability Composition Model](../high-level-architecture.md), [ADR-024 Capability Composition Model](ADR-024-capability-composition-model.md) |

## Context and Problem Statement

ADR-024 defines a Tier 3 SKU as a named, signed, version-pinned composition of Tier 2 capabilities, expressed in a manifest file — but deliberately left the file format open ("`composition.yaml` or equivalent, format TBD", open follow-up 3), delegating the choice to the SKU repository convention in coordination with `exeris-tooling`.

The first SKU track (`exeris-sku-api-gateway`, per the 2026-07-21 gateway-caps implementation plan) now needs the format fixed before the first SKU repository is scaffolded. The surrounding machinery has meanwhile converged on JSON: the tooling pipeline already emits a deterministic **`cap-manifest.json`** (ADR-024 obligation 7), its canonical read-schema (`CapManifest`) and the one content-binding implementation live in **`exeris-sdk-composition-spec`**, and the boot-time asserter (`exeris-sdk-composition-runtime`) parses JSON via the Jackson 3 stack already present on every relevant classpath. Choosing anything other than JSON for the authored SKU manifest would introduce a second parser dependency (SnakeYAML / `jackson-dataformat-yaml` / a pkl runtime) into the tooling and the SKU-boot path, a second canonicalisation story for signing, and a format seam between the authored manifest and the emitted one.


This ADR answers: **in what format does an `exeris-sku-*` repository author its composition manifest?**

## 🏁 The Decision

**The SKU composition manifest is a JSON document — canonically `composition.json` in the `exeris-sku-*` repository. JSON is the single canonical format for every composition-model artefact (authored `composition.json` and tooling-emitted `cap-manifest.json` alike); no YAML, pkl, or other format is ever canonical.**

Authoring-ergonomics front-ends (a YAML view, a Studio editor at the `exeris-platform` control plane) may be layered later, provided they emit and round-trip the canonical JSON — that is an authoring-surface concern, not a wire-format concern, and requires no change to this ADR.

**Concrete obligations:**

1. **`composition.json` is the authored manifest artefact.** Every `exeris-sku-*` repository carries its composition manifest as a JSON document named `composition.json`; the exact repository-relative path is fixed by the first SKU scaffold (`exeris-sku-api-gateway`) and becomes the convention.
2. **The schema lives in `exeris-sdk-composition-spec`.** The authored-manifest schema joins the `CapManifest` family in the spec module (ADR-024 obligation 8b), so the tooling emitter, the tooling validator/reader, and the SKU-boot asserter all consume one schema definition. No second schema copy anywhere.
3. **The canonical reader is owned by the `exeris-tooling` pipeline** (per ADR-024 §Composition), implemented against the spec module — never a per-SKU hand-rolled parser.
4. **Canonical serialization is deterministic.** The manifest's canonical form has a stable field order per the spec schema (and stable array ordering for the cap set), so signatures and the ADR-024 content binding are byte-stable across re-serialization. A manifest that round-trips to different bytes is a spec-module bug, not an accepted looseness.
5. **No parser-dependency creep.** Neither `exeris-tooling` nor `exeris-sdk-composition-*` gains a YAML/pkl/HOCON dependency on behalf of manifest handling. An authoring front-end that prefers another syntax owns its own conversion at the control plane and commits the resulting canonical JSON.

## Consequences

### ✅ Positive Outcomes

- **[+] One format across the composition surface.** Authored `composition.json` and emitted `cap-manifest.json` share a parser stack, a schema module, and a determinism story; the signing/content-binding path has a single canonical byte form.
- **[+] Zero new dependencies.** Jackson 3 is already on the tooling and SKU-boot classpaths; the SKU artefact's detachment footprint (ADR-024 obligation 6) stays minimal.
- **[+] Diff-able, signable, schema-checkable.** JSON Schema validation slots into the `exeris:verify-capabilities` gate and SKU CI without new tooling; review diffs on version pins are unambiguous.

### ⚠️ Trade-offs

- **[-] JSON is less pleasant to hand-author than YAML** — no comments, more punctuation. Accepted: SKU manifests are short (10–15 cap coordinates + pins + config overrides *— counted 2026-09-05, the seven manifests in HLA §3.3 run 7 to 16; see the amendment below*), change rarely, are mostly machine-maintained (version-pin bumps), and the Studio control plane is the intended long-term authoring surface. A `$comment`-style schema field can carry annotations if genuinely needed.
- **[-] Committing to a format before the first SKU exists risks discovering ergonomic gaps late.** Mitigated by obligation 1's scaffold clause: the *path and surrounding convention* are fixed by `exeris-sku-api-gateway`; only the *format* is locked here.

### 📋 What is NOT in scope

- **Manifest content and semantics** — the cap-coordinate set, version-pinning discipline, validation predicates, and stamp lifecycle are ADR-024's; this ADR fixes only the serialization format.
- **The signature algorithm** — still delegated to the `exeris-sku-*` repository convention per ADR-024 obligation 5.
- **Studio / control-plane authoring UX** — an `exeris-platform` concern (ADR-024 obligation 8c), layered on top of the canonical JSON.
- **`cap-manifest.json` itself** — already JSON and already governed by ADR-024 obligation 7 / the spec module; this ADR merely confirms format uniformity.

## Amendments

- **2026-09-05 — The "10–15 cap coordinates" figure is 7–16, and the Jackson claim was checked and
  stands.** Two statements on this record were verified against source. (PR #91)

  The Trade-offs bullet describes SKU manifests as "10–15 cap coordinates". Counted directly from the
  seven manifests in `high-level-architecture.md` §3.3 — the table this ADR's format governs, labelled
  there "full manifest" — the range is **7 to 16**: Bot Blocker 7, Edge Proxy 8, API Gateway 13,
  Headless CMS API 14, and IDP, PIM and OMS 16 each. The manifests remain short and the trade-off it
  supports is unaffected; only the range was wrong. The same sentence appears in
  `b2b-technical-whitepaper.md` §3.2, corrected in this pull request, and in the HLA, corrected
  earlier in it.

  The Context and "Zero new dependencies" claims about Jackson 3 **hold**. `exeris-sdk-composition-runtime`,
  the boot-time asserter this ADR names, imports `tools.jackson` exclusively — six imports, with
  `tools.jackson.core:jackson-databind` declared in its pom — and `tools.jackson.core` is a declared
  groupId in `exeris-tooling` as well, so "no new dependency" is accurate. One precision worth
  recording rather than leaving implied: neither classpath is uniformly Jackson 3. `exeris-tooling`
  carries 45 imports of the 2.x `com.fasterxml.jackson` namespace against 5 of the 3.x one, and the
  classes that emit and stamp the manifest — `CompositionStamp`, `OutputWriter`, `VerifyCapabilitiesMojo`
  and `CapabilityGraph` — import no Jackson at all. Read "already present on every relevant classpath"
  as availability, which is what the trade-off needs, not as a statement that the whole path runs on 3.x.

## Cross-references

- ADR-024 (Capability Composition Model) — parent contract; this ADR resolves the *format* half of its open follow-up 3 (the canonical-reader half lands with the tooling extension; signing stays delegated).
- ADR-023 (Capability Licensing Taxonomy) — the licence metadata a manifest row may carry is governed there.
- `exeris-sdk/exeris-sdk-composition-spec` — schema home (`CapManifest` family, canonical content-binding implementation).
- ADR-015 (Codegen Emission Strategy, `exeris-tooling`) — the pipeline that owns the canonical reader and the `exeris:verify-capabilities` gate.

## Engineering Protocol

This ADR is **prescriptive at acceptance** but has no enforcement surface until the first SKU repository exists:

1. The `exeris-sku-api-gateway` scaffold (gateway-caps plan Phase 5) ships `composition.json`, fixes its repository-relative path, and wires JSON-Schema validation of the manifest into SKU CI alongside `exeris:verify-capabilities`.
2. The authored-manifest schema addition to `exeris-sdk-composition-spec` lands with the same slice (coordinated with the ADR-024 obligation 8b module).
3. Until then, the obligation binding is review-time: any draft SKU material proposing a non-JSON canonical manifest is rejected citing this ADR.
