---
name: exeris-docs-routing-planner
description: Router/Planner skill for exeris-docs. Produces primary agent, secondary handoffs, execution order, validation gates, and minimal next action for a docs task.
---

# Exeris Docs Routing Planner

## Purpose
Given a classified task (see `exeris-docs-task-classifier`), produce a minimal, risk-aware execution order across `exeris-docs-{router,architect,adr-registry-keeper,document-shape-classifier,implementer}`.

## Output Contract
1. `primary_agent`
2. `secondary_handoffs` (ordered list with reason)
3. `execution_plan` (3–5 steps)
4. `validation_gates` (must-pass list)
5. `minimal_next_action`

## Routing Patterns
- `DOCUMENT_SHAPE` → `exeris-docs-document-shape-classifier` primary; `adr-registry-keeper` if ADR is the chosen shape.
- `ADR_REGISTRY` → `exeris-docs-adr-registry-keeper` primary; `architect` if narrative impact.
- `NARRATIVE_INTEGRITY` → `exeris-docs-architect` primary; `implementer` for the actual edits.
- `LARGE_DOC_EDIT` → `exeris-docs-implementer` primary; `architect` mandatory for drift sweep post-edit.
- `TEMPLATE_UPDATE` → `exeris-docs-architect` primary (template shape is load-bearing); `document-shape-classifier` if shape semantics change.
- `DRIFT_SWEEP` → `exeris-docs-architect` primary; `implementer` for any corrections.
- `MULTI_DOMAIN` → start with `router` triage, list all dominant handoffs.

## Default Validation Gates
- Document shape decided (Research / RFC / ADR) when "draft a decision doc".
- ADR number reserved in `adr-index.md` BEFORE content lands.
- Filename matches `ADR-NNN-<lowercase-kebab-title>.md`.
- Visibility taxonomy correct (`public` / `enterprise-private`); no `public-staged`.
- License taxonomy correct when capability artefacts in scope.
- Drift-pattern sweep done after non-trivial HLA / whitepaper edit.
- Three-tier narrative respected.
- Cross-repo `ADR-NNN.link.md` stubs created when cross-repo.
- Execution-plan §6 reconciliation updated when new architectural correction surfaces.

## Completion Criteria
All five contract fields present and gates tied to the specific risk surface.
