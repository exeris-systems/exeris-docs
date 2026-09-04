---
title: README Skeleton
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# README Skeleton

Binding per ADR-085 §B (shape) — enforced by review only. A README answers five questions in this order and then stops; everything else lives in `docs/`.

## Hard rules

1. **Same section order in every repo**, headings verbatim: `[L2]`
   1. `# <repo-name>` + one paragraph: what it is, in the ecosystem's own terms (tier, layer, what it never does).
   2. `## Where it sits` — the layer-map row (L0–L8 per `high-level-architecture.md`), what it depends on, what depends on it, which Wall edges it must not cross.
   3. `## Build & test` — the golden command and the one that runs a single module; JDK requirement; native prerequisites if any.
   4. `## Documentation` — links to `docs/` entry points and to `docs.exeris.eu/<repo>`; the documentation-precedence list (which doc wins when they disagree).
   5. `## Governing ADRs` — numbers with one line each; link the registry.
   6. `## Contributing` — one line linking `CONTRIBUTING.md`, which links the standards; licence sentence per module.
2. **No status badges that can go stale silently** (build badges are fine; "TRL-x" or "production-ready" are not). `[L2]`
3. **No numbers** unless they carry a report path (`claims-and-evidence.md`). `[L2]`
4. **Length:** under 120 lines. A README that needs more is a `docs/` page missing. `[L2]`
5. **README carries no frontmatter** (it renders on GitHub first); the site includes it via the root-file whitelist. `[L1: frontmatter_check.py exemption]`

## Filter

- Can a new engineer find the build command, the docs entry point and the governing ADRs in under a minute?
- Does "Where it sits" name the Wall edges this repo must not cross?
- Is anything here a duplicate of a `docs/` page? Link instead.
