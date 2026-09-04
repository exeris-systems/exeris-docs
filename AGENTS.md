---
title: "exeris-docs: the central documentation hub for the Exeris Systems ecosystem"
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# exeris-docs: the central documentation hub for the Exeris Systems ecosystem

Guardrails for AI assistants (Claude Code, Copilot, Cursor) working inside `~/exeris-systems/exeris-docs/`. Human-facing repository description lives in [`README.md`](README.md); this file captures the constraints, conventions, and "what to do when" rules that an AI session must respect when editing the central documentation surface.

## Mission and scope

`exeris-docs` is the **central documentation hub** for the Exeris Systems ecosystem. It holds the ADR registry (single numbering namespace across ~20 sibling repositories), the platform-scope ADRs, the High-Level Architecture, the customer-facing whitepaper, the decision-document templates, the RFCs, and the documentation standards. Per-repo docs (subsystem docs, repo-specific ADRs, build notes) live next to the code they describe in the owning repository.

This is **not** a monorepo. The ecosystem is ~20 sibling repos under `~/exeris-systems/`; the top-level routing rules live in `~/exeris-systems/CLAUDE.md` — a workstation path, not a repository file, so it is deliberately not a link.

Open this repo for: looking up an ADR by number, drafting a new platform-scope ADR or template-driven document, reading the HLA or whitepaper, editing the central registries, or working on cross-cutting strategy documents. For any non-trivial implementation task, change in subsystem behaviour, or repo-specific tooling, `cd` into the owning sibling repository instead — that is where the actionable code-level guardrails live.

## Operating contract

**Documentation precedence.** When sources disagree, the higher wins and the lower is a doc-drift
task — never the reverse. In order: the canonical subsystem doc in the owning repository, then the
ADR registry and the ADR it points at, then [`high-level-architecture.md`](high-level-architecture.md)
for the ecosystem-wide structural narrative, then
[`b2b-technical-whitepaper.md`](b2b-technical-whitepaper.md) for the buyer-facing summary.

**Language.** English everywhere — source, comments, commit messages, PR titles, ADRs, this file.
Conversation with the founder happens in Polish; persisted artefacts are English.

**Scoped bans.** Absolute. The reasoning lives in
[`.agents/policies/`](.agents/policies), not here.

- Never cite the 2026-05-05 `e2e-shop-order-saga` run, in whole or in part. "Axon" never appears
  next to a number, and no figure may depend on the v1 unresolved-rate gap.
- Never assert a benchmark figure without its report path and figure state. A withdrawal is fenced
  with the Vale toggle, never edited away.
- Never edit an ADR's decision text in place.
- Never give a `budgetHQ/` or `pbm/` decision a number from this registry.

## Architecture and documentation entry points

[`adr-index.md`](adr-index.md) is the lookup for every decision in the ecosystem — number to owning
repo and link. Four ADRs gate everyday editing here and are worth opening before you touch the
documents they govern: [ADR-006](adr/ADR-006-spring-free-kernel-boundary.md) (the Spring-free kernel
boundary, "the Wall"), [ADR-020](adr/ADR-020-open-core-documentation-mirror-policy.md) (what may be
linked from a public file, and every *(content private)* marker),
[ADR-023](adr/ADR-023-capability-licensing-taxonomy.md) and
[ADR-024](adr/ADR-024-capability-composition-model.md) (the licence axis and the composition model),
and [ADR-085](adr/ADR-085-documentation-architecture-and-repo-hygiene-standards.md), which makes
[`standards/`](standards) binding.

## `.agents/` — the canonical semantic source

Detailed rules are authored once, under [`.agents/`](.agents), and nowhere else. This file is an
index and a safety boundary; it does not restate them.

| Path | What it holds |
|:--|:--|
| [`.agents/policies/`](.agents/policies) | What is permitted or forbidden: [ADR registry discipline](.agents/policies/adr-registry.md) (hard constraints), [editing the whitepaper and the HLA](.agents/policies/editing-large-documents.md) (strong defaults), [drift patterns](.agents/policies/drift-patterns.md) (a sweep checklist). |
| [`.agents/references/`](.agents/references) | The short form of facts owned elsewhere — the three-tier architecture, the capability layer, the graph subsystem, the bootstrap DAG. Each names its authoritative source and yields to it. |
| [`.agents/skills/`](.agents/skills) | Bounded capabilities: registry-discipline review, document-shape classification, drift sweep, routing, task classification, three-tier narrative review. |
| [`.agents/agents/`](.agents/agents) | Role profiles composed from those skills — router, architect, registry keeper, shape classifier, implementer. |
| [`.agents/workflows/`](.agents/workflows) | Ordered task sequences: ADR reservation check, drift-pattern sweep, three-tier narrative purity, visibility-taxonomy check. |
| [`.agents/manifest.yaml`](.agents/manifest.yaml) | The composition, and the version-pinned bundles this repository imports. It imports none. |

Instruction sources resolve broad to narrow — organisation bundle, repository, subtree, selected
workflow. A narrower file may restrict behaviour; it may never relax a higher-order rule. Accepted
ADRs and the standards outrank anything summarised here: where they disagree, this file is the
defect.

## Conventions

The binding standards live in [`standards/`](standards/) and are not restated here. When this file and a standard disagree, the standard wins and this file is the defect.

- [`standards/commit-conventions.md`](standards/commit-conventions.md)
- [`standards/pr-conventions.md`](standards/pr-conventions.md)
- [`standards/javadoc-conventions.md`](standards/javadoc-conventions.md)
- [`standards/docs-style-guide.md`](standards/docs-style-guide.md)
- [`standards/adr-conventions.md`](standards/adr-conventions.md)
- [`standards/ai-provenance.md`](standards/ai-provenance.md)

## Verification and reporting

Before opening a pull request, run the guardrail checks the standards name and report the numbers
rather than the impression: `frontmatter_check.py`, `registry_check.py`, `agents_file_check.py`,
Vale at error level, `commitlint`. Say what you did not verify as plainly as what you did.

Where the checkout cannot settle a question, leave a `VERIFY` comment at the sentence and report it
as doc debt rather than guessing. A record's decision text is amended, never edited in place, and
the amendment and its registry status cell move in the same pull request
([`adr-conventions.md`](standards/adr-conventions.md) rule 7). Numbers follow
[`claims-and-evidence.md`](standards/claims-and-evidence.md).

## Provider adapters

[`.claude/`](.claude) holds Claude Code adapters generated from `.agents/`, each carrying a
do-not-edit marker and its source path, plus provider-owned operational configuration. There is no
renderer yet, so they are refreshed by hand. `CLAUDE.md` is a pointer to this file.

## Auto-memory

Persistent memory for this workspace lives at `~/.claude/projects/-home-arkstack-exeris-systems-exeris-docs/memory/`. Use it for **process feedback** and **user preferences** — not for project facts. Project facts belong in this CLAUDE.md (versioned, visible to humans and other AI tools) or in the canonical docs / ADRs.
