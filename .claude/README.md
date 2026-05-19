# `.claude/` — Claude Code workspace for `exeris-docs`

This directory is loaded automatically when a Claude Code session opens inside
`~/exeris-systems/exeris-docs/`. It exists alongside the repo-root [`CLAUDE.md`](../CLAUDE.md)
and works as the operating context for AI assistants on the central documentation hub.

## Layout

- `agents/` — sub-agents Claude can launch via the `Agent` tool (or invoke directly):
  - `exeris-docs-router.md` — entrypoint triage
  - `exeris-docs-architect.md` — three-tier narrative integrity, drift-pattern sweep, doc precedence
  - `exeris-docs-adr-registry-keeper.md` — ADR numbering, filename, location, visibility taxonomy, license taxonomy, link stubs
  - `exeris-docs-document-shape-classifier.md` — Research vs RFC vs ADR question-shape decision
  - `exeris-docs-implementer.md` — large-doc editing discipline (HLA / whitepaper / execution plans)
- `commands/` — slash commands (`/<command-name>`):
  - `adr-reservation-check.md`, `drift-pattern-sweep.md`, `three-tier-narrative-purity.md`, `visibility-taxonomy-check.md`
- `skills/` — invocable skills (`/<skill-name>`):
  - `exeris-docs-task-classifier`, `exeris-docs-routing-planner`
  - `exeris-docs-document-shape-classifier`
  - `exeris-docs-adr-registry-discipline-review`
  - `exeris-docs-drift-pattern-sweep-review`
  - `exeris-docs-three-tier-narrative-review`

## Doctrine — single source

Project doctrine is **not** duplicated under `.claude/`:

- **`/CLAUDE.md`** (repo root) — load-bearing facts, doc precedence, three-tier architecture summary, capability layer rules (ADR-023, ADR-024), Graph subsystem dual-engine, Bootstrap DAG canonical reference, ADR registry conventions, common drift patterns, editing discipline.
- **`adr-index.md`** — single ADR numbering namespace across the ecosystem.
- **`high-level-architecture.md`** — three-tier narrative, capability composition, SKU compositions, open-core split, Family-product framing.
- **`b2b-technical-whitepaper.md`** — buyer-facing summary + roadmap.
- **`templates/`** — `ADR-TEMPLATE.md`, `RFC-TEMPLATE.md`, `RESEARCH-TEMPLATE.md` + `README.md` (template usage rules).

When skills/agents need policy context, they reference these — they do not restate them.
