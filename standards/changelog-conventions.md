---
title: Changelog and Release-Notes Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Changelog and Release-Notes Conventions

Binding per ADR-085 §H. Applies to every repo that publishes an artefact (Maven Central, npm, GitHub Packages, a container image).

## Hard rules

1. **`CHANGELOG.md` at repo root**, Keep-a-Changelog 1.1 shape: `## [x.y.z] — YYYY-MM-DD`, sections `Added / Changed / Deprecated / Removed / Fixed / Security`, plus a mandatory **`### Breaking`** section per release (write `None.` when empty). `[L1: markdownlint custom rule on CHANGELOG heading set]`
2. **`Breaking` agrees with the compatibility tool.** Every japicmp/revapi-reported incompatible change on a `stable` surface appears under `Breaking` with its ADR; a `Breaking` entry without a report line, or a report line without an entry, fails the release gate. `[L1: release-impact-check step; ADR-065]` For TypeScript packages the compatibility tool is the committed golden of `tsdoc-conventions.md` rule 7 (`api/<pkg>.api.md` or `api/tools.api.json`): a `-` line in its diff is a `Breaking` entry.
3. **Accepted incompatible changes are justified in a file next to the tool:** `accepted-api-changes.json` (Micronaut/Netty pattern) — one entry per change: `{ "signature", "since", "adr", "justification" }`. The tool's exclusion list reads from it; nothing is excluded ad hoc in the plugin config. `[L1: japicmp configuration]`
4. **Every entry names the module and links a PR or ADR.** Format: `- **module:** what changed — why it matters to a consumer (#PR, ADR-NNN)`. `[L2]`
5. **Stability declarations are restated per release**: which surfaces are `stable | preview | experimental`, pointing at `stability-matrix.md` for the kernel; a surface changing label is a `Changed` entry. `[L2]`
6. **Hand-written release notes** (`docs/release/vX.Y.Z-release-notes.md`, type `release-notes`) are for narrative; the CHANGELOG is the list. Neither duplicates the other; the notes link the CHANGELOG section. `[L2]`
7. **Auto-generated GitHub release notes** (label categories in `.github/release.yml`: `type: breaking | enhancement | bug | docs | dependency`) are a supplement fed by PR labels and the optional `Release note:` line; they never replace rule 1. `[L1: release workflow]`
8. **Migration guides** for any release with a non-empty `Breaking` section: `MIGRATION.md` gains a `## x.y → x.z` section before the tag. `[L1: release-impact-check step]`

## Filter (before the tag)

- Could an adopter on the previous release read the upgrade path from `Breaking` + `MIGRATION.md` alone (the Elevated case: v0.5.0 in production)?
- Does every `Breaking` line have an ADR?
- Does `accepted-api-changes.json` explain, not just list?
- Is the stability paragraph consistent with `stability-matrix.md`?
