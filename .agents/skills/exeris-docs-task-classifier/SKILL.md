---
name: exeris-docs-task-classifier
description: Router/Planner triage skill for exeris-docs. Classifies task type (document shape / ADR registry / narrative integrity / large-doc edit / drift sweep), scope, severity, and recommends primary agent.
---

# Exeris Docs Task Classifier

## Purpose
Classify incoming docs work before execution. Triage only — no implementation.

## Output Contract
1. `task_class` (`DOCUMENT_SHAPE` | `ADR_REGISTRY` | `NARRATIVE_INTEGRITY` | `LARGE_DOC_EDIT` | `TEMPLATE_UPDATE` | `DRIFT_SWEEP` | `MULTI_DOMAIN`)
2. `scope` (single-doc | cross-doc | cross-repo | template)
3. `severity` (low | medium | high | critical)
4. `primary_risk`
5. `recommended_primary_agent`

## Classification Heuristics
- `DOCUMENT_SHAPE`: "draft an ADR / RFC / Research" requests; uncertainty about which template.
- `ADR_REGISTRY`: ADR numbering / filename / location / visibility / license / link stubs.
- `NARRATIVE_INTEGRITY`: three-tier framing, doc precedence, drift patterns surfacing in framing.
- `LARGE_DOC_EDIT`: HLA / whitepaper / execution plans concrete edits.
- `TEMPLATE_UPDATE`: changes to `templates/ADR-TEMPLATE.md`, `RFC-TEMPLATE.md`, `RESEARCH-TEMPLATE.md`, `templates/README.md`.
- `DRIFT_SWEEP`: pattern sweep over an edited file.
- `MULTI_DOMAIN`: ≥2 first-order concerns.

## Guardrails
- Preserve doc precedence.
- Preserve three-tier narrative.
- Preserve ADR registry discipline.
- Preserve template-shape separation.
- If uncertain, emit `MULTI_DOMAIN` and state both.

## Completion Criteria
All five output fields present and justified in 1-2 bullets.
