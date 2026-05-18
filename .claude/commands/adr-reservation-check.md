---
description: Verify a new / amended ADR follows the registry discipline — number reserved first, filename pattern correct, location matches scope, visibility taxonomy correct, link stubs in affected repos.
argument-hint: ADR PR / new ADR file / index update to audit
---

Audit this ADR change against registry discipline.

ADR registry rules (per repo `CLAUDE.md` + `adr/ADR-020-open-core-documentation-mirror-policy.md`):
- **Reserve the number first.** A new ADR adds its row to `adr-index.md` (or `business-adr-index.md` for BUS-NNN) BEFORE the ADR-content file lands.
- **Filename pattern**: `ADR-NNN-<lowercase-kebab-title>.md` — 3-digit zero-padded; replace `&` with `and`; drop other punctuation.
- **Authoritative location per scope**:
  - Platform-scope → `exeris-docs/adr/`
  - Per-repo → `<owning-repo>/docs/adr/`
  - Cross-repo → owning repo's `docs/adr/` PLUS `ADR-NNN.link.md` stubs in every affected repo
  - Enterprise-private → `<enterprise-repo>/docs/adr/` (number publicly registered, content private)
- **Visibility taxonomy**: two-valued — `public` or `enterprise-private`. `public-staged` deprecated.
- **License taxonomy** (separate axis, ADR-023): three-valued — `community` / `commercial` / `enterprise-private` — applies to capability artefacts, NOT to ADR files.
- **No refactor-only ADRs** — those live in `<repo>/docs/refactor-notes/` or PR descriptions.
- **No portfolio entries** — `budgetHQ/`, `pbm/` do NOT enter `adr-index.md`.

Change:
$ARGUMENTS

Please review:
1. Is the ADR number reserved in `adr-index.md` (or `business-adr-index.md`) BEFORE the content file is added?
2. Does the filename match `ADR-NNN-<lowercase-kebab-title>.md` exactly?
3. Does the file location match the scope (platform / per-repo / cross-repo / enterprise-private)?
4. For cross-repo: are `ADR-NNN.link.md` stubs in every affected repo?
5. Is the visibility taxonomy claim correct (`public` / `enterprise-private`)? No `public-staged` reintroduction?
6. If the ADR concerns capability artefacts: is the license taxonomy (`community` / `commercial` / `enterprise-private`) cited and not conflated with visibility?
7. Is this a real decision document, or should it be a refactor note / PR description?
8. Minimal correction if registry discipline is at risk.
