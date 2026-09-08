# `.claude/` — generated adapters and provider configuration

This directory is **not** where project rules are authored. Per
[`agents-md-schema.md`](../standards/agents-md-schema.md) rules 2 and 7, the canonical semantic
source is [`.agents/`](../.agents) and this directory adapts it for Claude Code.

- `agents/` — **generated** from `.agents/agents/<name>/AGENT.md`. The canonical frontmatter is
  vendor-neutral (`capabilities`, `model` tiers); the Claude tool list and model id here are
  produced by the mapping in `exeris-systems/.github` → `agents/adapters/claude.yaml`.
- `skills/` — one symlink per skill into `.agents/skills/`, plus a **generated** directory per
  workflow (a workflow is a user-invoked skill on this runtime, with `disable-model-invocation`).
  Nothing here is a copy of a skill. A checkout without symlink support renders with
  `agents_render.py --skills-copy`, which the manifest records as a degradation.
- `settings.json` — **generated** `hooks` block wiring the L0 layer to
  `.agents/hooks/bin/hook.py`. The patterns live in `.agents/hooks/hooks.yaml`, not here.
- `settings.local.json` — provider-owned local configuration. Never semantic content.

Regenerate with `python3 <path-to>/.github/scripts/agents_render.py --root .`, and verify with
`--check`, which is what CI runs. A change made here is lost the next time they are regenerated.

## Auto-memory

Claude Code keeps this workspace's persistent memory under its own per-user directory
(`~/.claude/projects/<slug>/memory/` on the founder's workstation — a client path, not repository
content, which is why it is described here rather than in `AGENTS.md`). Use it for **process
feedback** and **user preferences**, never for project facts: those belong in `AGENTS.md`, in
`.agents/`, or in the canonical documents and records, all versioned and visible to every tool.
