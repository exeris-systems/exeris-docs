---
name: exeris-docs-document-shape-classifier
description: Document shape classifier for exeris-docs. Use whenever a user asks to "draft an ADR / RFC / research note" — confirms Research / RFC / ADR / refactor-note is the right shape, and selects the right template.
---

# Exeris Docs Document Shape Classifier (skill)

## Purpose
Classify the question shape before opening a template. The three templates are NOT interchangeable; refactor-only changes are NOT decision docs at all.

**Single source.** Template shapes, filenames, and selection rules live once in
`templates/README.md` (and `CLAUDE.md` § "Decision-document templates"). This
skill applies the decision tree below and points at the right file — read
`templates/README.md` for the authoritative shape definitions.

## When to Use
- Any "draft an ADR" / "write an RFC" / "make a research note" request.
- Any time the user reaches for a template without naming which one.
- Any time an ADR draft surfaces but upstream measurement / option comparison is missing.

## Templates (summary — authoritative copy in `templates/README.md`)
- **Research** (`RESEARCH-TEMPLATE.md`) — falsifiable hypothesis, lab-notebook, JMH/JFR-driven. Branch-scoped, no registry.
- **RFC** (`RFC-TEMPLATE.md`) — multi-option strategic question. No registry.
- **ADR** (`ADR-TEMPLATE.md`) — decision already made. Enters the registry.

## Decision Procedure
1. **Is upstream measurement missing?** → Research first.
2. **Are there multiple legitimate options needing comparison?** → RFC.
3. **Is the decision already made (single decider, no future gating event)?** → ADR, accepted-on-merge.
4. **Is the decision genuinely deferred (multi-stakeholder, waiting for input)?** → ADR with `PROPOSED` status.
5. **Is it a refactor / rename / dep bump?** → NOT a decision doc. Lives in `<repo>/docs/refactor-notes/` or PR description.

## Output Contract
1. `recommended_shape` (`RESEARCH` | `RFC` | `ADR` | `NOT_A_DECISION_DOC`)
2. `template_path`
3. `rationale` (2-3 sentences citing the decision tree)
4. `next_steps` (reserve number / create branch / commit to PR description)

## Decision Logic
- **RESEARCH**: Question is empirical and unmeasured.
- **RFC**: Question is strategic with multiple options to compare.
- **ADR**: Decision already made; the doc records it.
- **NOT_A_DECISION_DOC**: Change is mechanical; no decision to record.

## Completion Criteria
- Shape chosen with citation to one of the 5 decision steps.
- Template path provided.
- Next concrete step provided.

## Non-Negotiable Rules
- Never draft an ADR on an unmeasured question — Research first.
- Never draft an ADR when option comparison hasn't happened — RFC first.
- Never draft an ADR for a refactor-only change.
- Never conflate the three templates; their shapes differ on purpose.
