# Document Templates

Canonical templates for **decision documents** in the Exeris ecosystem. Three templates for three question shapes.

## Templates

| Template | File | Use when |
|:---|:---|:---|
| **ADR** | [`ADR-TEMPLATE.md`](ADR-TEMPLATE.md) | A decision is made. The document records what, why, and how it's enforced. |
| **RFC** | [`RFC-TEMPLATE.md`](RFC-TEMPLATE.md) | A multi-option strategic/policy question is open. The document enumerates options and recommends one. |
| **Research** | [`RESEARCH-TEMPLATE.md`](RESEARCH-TEMPLATE.md) | A falsifiable hypothesis needs measurement (JMH, JFR, profiling, prototypes). Lab-notebook shape; produces data and a falsifiable conclusion. |

All three live here at `exeris-docs/templates/` so they're available to every repo.

## Picking the right template

The three are not interchangeable. Pick by the *shape of the question*:

| | Research | RFC | ADR |
|:---|:---|:---|:---|
| **Question shape** | "Does X work as predicted?" | "Should we choose A, B, or C?" | "We've decided X." |
| **Measurable hypothesis?** | Yes — falsifiable | No — multiple options compared | N/A — already decided |
| **Output** | Data tables + conclusion | Recommendation + reasoning against alternatives | Concrete obligations + enforcement |
| **Drives** | Often → ADR, sometimes → feature | → ADR | (terminal) |

**Rule of thumb:** if you can write a measurable hypothesis ("X will reduce Y by Z% under workload W"), use Research. If your decision is "which option do we pick?", use RFC. If the decision has already been made and you just need to record it, go straight to ADR.

## Lifecycle

```
              ┌────────────────────────────────────────┐
              │  Question forms                         │
              └───┬────────────────────────────────┬────┘
                  │ measurable hypothesis           │ multi-option / strategic
                  ▼                                 ▼
           ┌─────────────┐                  ┌─────────────┐
           │  Research   │                  │ RFC (DRAFT) │
           │  (active)   │                  └──────┬──────┘
           └──────┬──────┘                         │ review / iteration
                  │ experiments + data             ▼
                  ▼                         ┌─────────────────┐
           ┌──────────────────┐             │  RFC (ACCEPTED) │
           │ Research.Decision│             └────────┬────────┘
           │ (concluded)      │                      │
           └──────┬───────────┘                      │
                  │                                  │
                  └──────────────┬───────────────────┘
                                 ▼
                          ┌─────────────┐
                          │  ADR(s)     │  ← Decision recorded, enforceable
                          └─────────────┘
```

A single Research effort or RFC may produce multiple ADRs.

**You may skip the upstream stage** when:
- The decision is descriptive (codifies existing reality), not prescriptive — go straight to ADR.
- The decision is a small per-repo convention with no cross-repo blast radius.
- You've already done the analysis informally and there's no losing alternative whose proponents will ask "why didn't we do X?" later.

**You should NOT skip the upstream stage** when:
- The decision needs measurable data to justify (use Research).
- The decision affects multiple repos and has clear losing alternatives (use RFC).
- The decision will be questioned later (use whichever upstream form fits — capture the reasoning).

## Where the documents live

- **ADR location** is governed by [ADR-020](../adr/ADR-020-open-core-documentation-mirror-policy.md): platform → `exeris-docs/adr/`; per-repo → `<repo>/docs/adr/`; cross-repo → owning repo with `.link.md` stubs in consumers; enterprise-private → `<enterprise-repo>/docs/adr/`.
- **RFC location** may be this repo, the relevant code repo, an issue tracker, or an external discussion thread. The accepted RFC's URL is referenced in the resulting ADR's `Driven By` field.
- **Research location** is the relevant code repo's `docs/research/` directory, on a `research/<slug>` branch — see the kernel's `docs/research/RESEARCH.md` framework doc for the established branch workflow. Research can happen in any repo where measurement-driven decisions arise.

## Conventions

- **Filenames.** Lowercase kebab-case for the title slug; the `ADR-NNN` / `RFC-YYYY-MM-DD` prefix keeps its original casing.
  - ADR: `ADR-NNN-<lowercase-kebab-title>.md` (3-digit zero-padded; e.g. `ADR-001-cloud-native-and-agnostic-infrastructure-strategy.md`).
  - ADR link stub: `ADR-NNN.link.md` in a consuming repo's `docs/adr/` (ADR-020 §2).
  - RFC: `RFC-YYYY-MM-DD-<lowercase-kebab-title>.md` (date prefix; same kebab title rule).
  - Research: `RESEARCH-YYYY-MM-DD-<lowercase-kebab-title>.md` in the owning repo's `docs/research/`, on a `research/<slug>` branch. `RESEARCH.md` — the framework doc — is the one filename the gate exempts.
  - **Title slug rules.** Replace `&` with `and`. Drop other punctuation (`+`, `:`, `(`, `)`, `,`, etc.). Collapse runs of whitespace/hyphens to a single `-`. The slug should be machine-grep-able and copy-paste-safe in URLs (no `%20`, no `%26`).
- **Numbering.** ADR numbers are reserved in [`../adr-index.md`](../adr-index.md) before content is written. RFC IDs are the date the RFC opens — no central registry. Research has no central registry — it's branch-scoped.
- **Status discipline.** ADRs in PROPOSED and RFCs in DRAFT should accept, reject, or withdraw within a couple of weeks. Research with `Status: active` for more than one milestone should conclude, park, or abandon.
- **Language.** All ADRs are in English — body content, section headings, header-table labels, YAML frontmatter values, everything. The canonical header-table labels are `Attribute` / `Value`. The same English-only rule applies to RFCs that drive ADRs, the index, and this README. Research lab-notebook content may be informal. Repo-local working notes (refactor archaeology, internal R&D) may be in any language but never enter the ADR namespace.

<!-- VERIFY(sweep-2026-09): the closing clause of the Language bullet lets repo-local working notes be written "in any language", while standards/docs-style-guide.md rule 11 (line 44) states "English." with no carve-out and scopes itself (line 12) to every file under docs/ in any repo — which includes <repo>/docs/refactor-notes/. adr/ADR-020-open-core-documentation-mirror-policy.md §4 (line 89) records "Polish-language working notes" in that exact directory as an existing, sanctioned reality. Maintainer to decide which wins and amend ADR-085 §B or this bullet. -->

## Cross-references

- [`../adr-index.md`](../adr-index.md) — central tech ADR registry.
- [ADR-020](../adr/ADR-020-open-core-documentation-mirror-policy.md) — where ADRs live across the open-core / enterprise repo split.
- `exeris-kernel/docs/research/RESEARCH.md` — kernel research framework (when, how, branch lifecycle, current portfolio).
