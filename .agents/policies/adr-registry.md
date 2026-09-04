---
title: Policy — ADR registry discipline
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Policy — ADR registry discipline

Hard constraints. A change here is a change to [ADR-020](../../adr/ADR-020-open-core-documentation-mirror-policy.md)
and to [`adr-conventions.md`](../../standards/adr-conventions.md), not to this file.

Single numbering namespace across the ecosystem. The full rules are in [`adr-index.md`](adr-index.md) and formalized in [`adr/ADR-020-open-core-documentation-mirror-policy.md`](adr/ADR-020-open-core-documentation-mirror-policy.md). Essentials any AI session must follow:

<!-- NOTE(sweep-2026-09): the gates these standards cite are not yet wired into this repository. .github/workflows/ holds only claude-code-review.yml and claude.yml, and no workflow references registry_check.py, frontmatter_check.py or claude_md_check.py; the scripts live in an untracked shared tree reached via the .guardrails symlink to ~/exeris-systems/.guardrails. Until a caller workflow lands, no rule may be dropped from this file on the grounds that "CI reports it instead" (agents-md-schema.md rule 5). -->

- **Reserve the number first.** A new ADR adds its row to `adr-index.md` (PR or commit) **before** the ADR-content file lands. Numbering is chronological by decision date with reserved gap-fillers for backdated decisions.
- **Filename pattern.** `ADR-NNN-<lowercase-kebab-title>.md` — 3-digit zero-padded, then `-`, then the title in lowercase kebab-case. Replace `&` with `and`; drop other punctuation. Examples: `ADR-023-capability-licensing-taxonomy.md`, `ADR-024-capability-composition-model.md`.
- **Authoritative location per scope.** Platform-scope ADRs → `exeris-docs/adr/`. Per-repo ADRs → `<owning-repo>/docs/adr/`. Cross-repo ADRs → owning repo's `docs/adr/` plus `ADR-NNN.link.md` stubs in every affected repo. Enterprise-private ADRs → `<enterprise-repo>/docs/adr/` (number publicly registered, content private).
- **Visibility taxonomy is two-valued** per ADR-020: `public` or `enterprise-private`. The legacy `public-staged` is deprecated.
- **License taxonomy is a separate axis** per ADR-023 — three values (`community` / `commercial` / `enterprise-private`) that apply to capability artefacts, not to ADR files. Don't conflate visibility with license.
- **Refactor-only docs are not ADRs.** They live in `<repo>/docs/refactor-notes/` (or in PR descriptions) and never get ADR numbers.
- **Out of scope for the registry.** `budgetHQ/`, `pbm/`, and similar portfolio products have internal namespaces and do not enter `adr-index.md`.

When asked to "draft an ADR," check the question shape first: if upstream measurement is missing, suggest a Research; if option-comparison is missing, suggest an RFC; if the decision is already informally made, go straight to ADR. The three template shapes live in [`templates/`](templates/) and are not interchangeable (see `templates/README.md`).

<!-- NOTE(sweep-2026-09): this numbered list is load-bearing for two standards. docs-style-guide.md rule 10 seeds Vale existence rules from it by section name ("Common drift patterns"), and claims-and-evidence.md rule 4 makes items 10-13 error-level Vale rules, citing them by number. Item numbering and the section heading are therefore frozen: renaming the section, renumbering an item, or relocating the block requires editing both standards in the same PR, and standards/ is exempt from this sweep. Note the trap this creates: items 10, 11 and 13 are the sentences that name the forbidden figures in order to forbid them, so the Exeris Vale package must exempt this file (the RetractedFigures off/on comments below are the local mitigation) or the file that defines the rules will be the first to fail them. The same applies to whitepaper §4.1's retraction box. -->
