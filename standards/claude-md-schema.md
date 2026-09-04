---
title: CLAUDE.md Schema and Agent-File Policy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# CLAUDE.md Schema and Agent-File Policy

Binding per ADR-085 §I. One canonical agent-instruction file per repo; everything else points at it.

## Hard rules

1. **`CLAUDE.md` at repo root is canonical.** `AGENTS.md`, `.github/copilot-instructions.md`, `.cursorrules`, `.clinerules/`, `.github/agents/*.agent.md` either contain a single line pointing at `CLAUDE.md` (plus tool-specific glue that cannot live there) or do not exist. Two files stating the same rule is a `[DOC DEBT]` finding. `[L1: scripts/claude_md_check.py — flags any of those files over 20 lines]`
2. **Section order, headings verbatim:** `[L1: claude_md_check.py]`
   ```
   # <repo-name>: <one-line mission>
   ## What this repo is — load-bearing facts
   ## Documentation precedence
   ## Rule levels
   ### A) Hard constraints
   ### B) Strong defaults
   ### C) Heuristics
   ## Scoped bans
   ## Language
   ## Cross-repo ADRs to consult
   ## Conventions
   ## Auto-memory
   ```
   A repo may add sections **after** `## Conventions` (build commands, subsystem notes); it may not reorder or rename the ones above.
3. **`## Documentation precedence` is an ordered list** whose first entry is the repo's founding ADR (or the top-level routing file for `exeris-docs`), then cross-repo ADRs, then `~/exeris-systems/CLAUDE.md`, then this file, then `README.md`. The check verifies the list exists and that every ADR it names has a registry row. `[L1: claude_md_check.py + registry_check.py]`
4. **`## Language`** contains the sentence: *English everywhere — source, comments, commit messages, PR titles, ADRs, this file. Conversation with the founder happens in Polish; persisted artefacts are English.* `[L1: claude_md_check.py exact-match]`
5. **`## Conventions`** links the standards — `commit-conventions.md`, `pr-conventions.md`, `javadoc-conventions.md`, `docs-style-guide.md`, `adr-conventions.md`, `ai-provenance.md` — by relative path to `exeris-docs/standards/`, and states nothing those files already state. **Rules enforced by CI are not repeated in `CLAUDE.md`**; the agent gets the CI failure instead. `[L2]`
6. **Size:** a `CLAUDE.md` over 16 KB moves topical material to `docs/` and links it (the SDK's 34 KB is the first candidate); per-module `AGENTS.md` files (Micronaut pattern) are allowed only under that rule and are themselves ≤ 4 KB. `[L1: claude_md_check.py size warning]`
7. **Skills and routines** stay under `.claude/skills/` and `.claude/agents/`; `.github/skills`, `.github/prompts` are migrated or deleted. `[L2]`
8. **No rule in `CLAUDE.md` may weaken a standard or an ADR.** When they disagree, the ADR wins and `CLAUDE.md` is a `[DOC DEBT]` item. `[L2]`

## Why

The inventory found the same lineage of `CLAUDE.md` in seven repos with four section vocabularies, plus `copilot-instructions.md` in three (one of them 13.5 KB), `.cursorrules` in two, and a parallel `.github/{agents,prompts,skills}` tree in kernel-enterprise. Quarkus and Micronaut both converged on one canonical file plus pointers; Spring and Netty have none. The schema is the lineage that already exists (tooling / platform / ai-bridge form), fixed.

## Filter

- Is anything here a duplicate of a standards file or of a CI check? Link or delete.
- Does the precedence list tell the agent what to do when two sources disagree?
- Would a new agent session know which ADRs to open *before* editing?
