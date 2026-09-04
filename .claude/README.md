# `.claude/` — generated adapters and provider configuration

This directory is **not** where project rules are authored. Per
[`agents-md-schema.md`](../standards/agents-md-schema.md) rules 2 and 7, the canonical semantic
source is [`.agents/`](../.agents) and this directory adapts it for Claude Code.

- `skills/`, `agents/`, `commands/` — **generated** from `.agents/skills`, `.agents/agents` and
  `.agents/workflows`. Every file carries a do-not-edit marker naming its source. Edit the source.
- `scripts/` — reviewed shell code the workflows call. Provider-owned operational tooling.
- `settings.local.json` — provider-owned local configuration. Never semantic content.

There is no renderer yet, so the adapters are refreshed by hand when their source changes. That is
the one thing to remember: a change made here is lost the next time they are regenerated.
