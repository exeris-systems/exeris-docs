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
  - `exeris-docs-adr-registry-discipline-review` (subsumes the visibility/license check)
  - `exeris-docs-drift-pattern-sweep-review`
  - `exeris-docs-three-tier-narrative-review`
- `scripts/` — deterministic gates that hold the *greppable* rules (see [`scripts/README.md`](scripts/README.md)):
  - `drift-sweep.sh`, `taxonomy-check.sh` — candidate locators (exit 1 = review required, not "broken")
  - `adr-filename-check.sh`, `check-consistency.sh` — true gates (exit 1 = real violation)

## When skill vs command vs agent vs script

One function should not be re-implemented across forms. The division of labour:

- **`scripts/`** — the *mechanical, regex-expressible* check. The one place a
  pattern/census is written down. Runs in CI / pre-commit unchanged.
- **skills** — the *judgement* procedure around a script: adjudicate candidates,
  read the canonical `CLAUDE.md` entry, decide a verdict. Model-invoked.
- **commands** (`/<name> $ARGUMENTS`) — a *thin entrypoint*: run the script on the
  argument, then point at the skill for the procedure. No restated doctrine.
- **agents** — *delegation* with their own context/tools; the router is a
  dispatcher that delegates classification/planning to the two routing skills.

## Doctrine — single source

Project doctrine is **not** duplicated under `.claude/`:

- **`/CLAUDE.md`** (repo root) — load-bearing facts, doc precedence, three-tier architecture summary, capability layer rules (ADR-023, ADR-024), Graph subsystem dual-engine, Bootstrap DAG canonical reference, ADR registry conventions, common drift patterns, editing discipline.
- **`adr-index.md`** — single ADR numbering namespace across the ecosystem.
- **`high-level-architecture.md`** — three-tier narrative, capability composition, SKU compositions, open-core split, Family-product framing.
- **`b2b-technical-whitepaper.md`** — buyer-facing summary + roadmap.
- **`templates/`** — `ADR-TEMPLATE.md`, `RFC-TEMPLATE.md`, `RESEARCH-TEMPLATE.md` + `README.md` (template usage rules).

The **prose** doctrine lives once in the sources above; the **greppable** rules
(drift patterns, taxonomy locators, ADR filename pattern) live once in
`scripts/`. When skills/commands/agents need policy context, they reference these
— they do not restate them.

`scripts/check-consistency.sh` enforces this: it fails if any file under
`.claude/{skills,commands,agents}` hard-codes rotting doctrine (cap census,
named census caps, TRL levels, the SKU split) that must live only in
`CLAUDE.md` / the ADRs. Run it after editing this directory — the toolkit guards
itself against the exact doc-drift it exists to catch.
