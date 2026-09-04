---
title: Agent-File Schema and Policy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Agent-File Schema and Policy

Binding target for ADR-085 §I. This file retains its historical path for stable
links; it governs `AGENTS.md`, `.agents/`, and provider adapters rather than
`CLAUDE.md` alone.

## Purpose and ownership

Every repository has one portable entry point and one canonical semantic
source. Provider-specific files make that source usable by a particular agent;
they do not become a second place to author project rules.

```text
AGENTS.md                         portable repository entry point
.agents/                          canonical semantic content
  policies/                       non-negotiable constraints
  skills/<name>/SKILL.md          reusable procedures and capabilities
  agents/                         role profiles composed from skills/policies
  workflows/                      repeatable task sequences
  references/                     deferred, authoritative context
  manifest.yaml                   composition and delivery metadata
.claude/, .github/, .codex/, ...  provider adapters
```

`AGENTS.md` and `.agents/` are both versioned repository content. The former is
the small file every compatible agent can discover; the latter is the source of
truth for the detailed semantics it points to.

## Hard rules

1. **`AGENTS.md` at repository root is required and is the canonical entry
   point.** It states the repository mission, the operating contract, the
   authoritative knowledge locations, and where policies, skills, profiles and
   workflows live. It is an index and a safety boundary, not an encyclopedia.
   Keep it at or below 8 KB; move detail to `.agents/` or `docs/`.
   `[L1: agent-file check]`
2. **`.agents/` is the canonical semantic source.** A repository that exposes
   reusable agent behaviour keeps it under `.agents/`; semantic rules MUST NOT
   be authored independently under `.claude/`, `.github/`, `.codex/`,
   `.cursor/`, or `.gemini/`. An exception requires an explicit,
   provider-specific capability that cannot be represented in the canonical
   model. `[L1: generated-adapter drift check once the renderer is adopted]`
3. **Policies, skills, profiles and workflows have distinct jobs.** A policy
   says what is permitted or forbidden; a skill says how to perform a bounded
   capability; a profile defines a role and composes skills/policies; a workflow
   defines the ordered lifecycle of a task. Do not encode one kind as another
   merely because a provider has only one native file type. `[L2]`
4. **Skills use the Agent Skills layout.** Every skill lives at
   `.agents/skills/<name>/SKILL.md`, with `name` and a precise `description` in
   YAML frontmatter. Optional `scripts/`, `references/`, and `assets/` are
   loaded only when that skill is selected. A skill description names both what
   it does and when it applies. `[L1: skill metadata and path check]`
5. **Profiles and workflows are declarative compositions.** They identify the
   skills, policies, references and default workflow they need; they do not
   copy their full bodies. The format is owned by the Exeris agent manifest,
   not by a provider. `[L1: manifest schema check]`
6. **References remain authoritative at their owning location.** A skill may
   link to an ADR, module document, contract or generated artifact, but must
   not copy it merely to make a prompt self-contained. Facts about code, CI,
   releases and architecture are verified against the owning source, not the
   agent file that links to it. `[L2]`
7. **Provider directories are adapters, not a lowest-common-denominator
   target.** A renderer may generate native Claude skills, GitHub agents and
   prompts, Codex/Gemini skills, or Cursor rules from `.agents/`. Generated
   files carry their source and a do-not-edit marker. Provider-local settings,
   MCP connection settings, secrets, permissions and GitHub Actions remain
   provider-owned operational configuration; they are not semantic adapters.
   `[L2; L1 for generated outputs after rollout]`
8. **No hidden or remote authority.** A manifest may import only an approved,
   version-pinned Exeris bundle. It must never fetch executable scripts,
   policies or instructions at agent runtime. Bundled scripts are reviewed code
   with explicit permissions; an agent must not execute them merely because a
   skill mentions them. `[L1: pinned-import and checksum check]`
9. **No agent file may weaken an ADR, a standard, a repository policy, or the
   user's explicit safety constraints.** When they disagree, the higher-order
   authority wins and the lower document is a `[DOC DEBT]` item. `[L2]`

## `AGENTS.md` schema

The exact prose and heading names are repository-owned. The file contains, in
this order, the following concerns:

1. mission and scope;
2. operating contract and non-negotiable safety boundaries;
3. architecture and documentation entry points;
4. `.agents/` discovery and the applicable policy/workflow contract;
5. verification and reporting expectations;
6. provider-adapter note, when one exists.

It links rather than reproduces detailed build commands, subsystem rules,
release mechanics and ADR text. Nested `AGENTS.md` files are permitted where a
subtree has materially different constraints; they add scope-specific rules and
must stay at or below 4 KB. They do not restate the parent file.

## Resolution and inheritance

Instruction sources resolve from broad to narrow:

```text
approved organisation bundle → repository → subtree → selected task workflow
```

The closest applicable `AGENTS.md` adds to its parent. A more specific file may
restrict behaviour but may not relax a higher-order rule. At execution time,
system and user instructions outrank repository material; accepted ADRs and
standards outrank agent-file summaries. `manifest.yaml` records bundle versions
and compositions, but never replaces this authority order.

## Adapter and distribution policy

The canonical source is portable; delivery may differ by audience.

- Repository contributors consume the repository's `.agents/` source and its
  locally generated adapters.
- Application developers may receive a versioned, read-only bundle through an
  npm package or MCP resources/prompts. It must declare its Exeris and manifest
  versions and may not claim to be current for a different dependency line.
- MCP resources and prompts distribute contextual guidance for a session; they
  do not replace installation of a native skill where a client requires one.
- A setup tool may materialise an explicitly selected bundle and its provider
  adapter. It must never overwrite user-authored files without a preview and
  confirmation.

## Migration from `CLAUDE.md`

Existing `CLAUDE.md` files are migration inputs, not the new source of truth.
Extract each rule once into `AGENTS.md`, a policy, a skill, a profile, a
workflow, a reference, or the owning source document. Preserve a thin
`CLAUDE.md` adapter only while a supported Claude client requires it; it points
to or is rendered from the canonical source. Do not mass-convert content with
search-and-replace: classify its meaning first.

## Filter

- Can a compatible agent discover the repository contract from `AGENTS.md`
  without loading all project knowledge?
- Does each detailed instruction have exactly one semantic owner under
  `.agents/` or in its authoritative documentation?
- Is a provider file an adapter or operational configuration, rather than an
  independently maintained rule set?
- Does a selected developer bundle disclose its version, scope and unavailable
  capabilities instead of silently assuming a full Exeris checkout?
