---
title: Exeris Standards — Index
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Exeris Standards

The standards that ADR-085 makes binding for every Exeris repository. One file per artefact kind. Repos **link** here from `CONTRIBUTING.md`; they never copy (ADR-020).

Each standard has the same shape: **hard rules** first, each tagged with the layer that enforces it — `[L1]` a CI gate (named), `[L2]` Claude review, `[L3]` an author checklist — then a short **filter** of questions to run before you push. If a rule has no `[L1]` tag, no machine checks it; that is deliberate, not an oversight.

| Standard | Governs | Gate config lives in |
|:--|:--|:--|
| [`commit-conventions.md`](commit-conventions.md) | commit subject, body, trailers | `exeris-systems/.github` → `commitlint.config.js` |
| [`pr-conventions.md`](pr-conventions.md) | PR title, required sections, labels | `exeris-systems/.github` → `PULL_REQUEST_TEMPLATE.md`, `scripts/pr_body_check.py` |
| [`issue-conventions.md`](issue-conventions.md) | issue forms, title grammar, labels, findings → issues | `exeris-systems/.github` → `ISSUE_TEMPLATE/`, `labels.yml`, `scripts/labels_sync.py`, `workflows/issue-hygiene.yml` |
| [`javadoc-conventions.md`](javadoc-conventions.md) | doc comments on Java API | per-repo `maven-javadoc-plugin`, `exeris-kernel-build-config/checkstyle.xml` |
| [`docs-style-guide.md`](docs-style-guide.md) | Markdown docs: frontmatter, types, terminology, voice | `exeris-systems/.github` → `scripts/frontmatter_check.py`, `vale/`, `.markdownlint.yaml` |
| [`readme-skeleton.md`](readme-skeleton.md) | repo README shape | `[L2]` only |
| [`adr-conventions.md`](adr-conventions.md) | ADR / RFC / RESEARCH files and the registry | `exeris-systems/.github` → `scripts/registry_check.py` |
| [`changelog-conventions.md`](changelog-conventions.md) | CHANGELOG, release notes, accepted API changes | per-repo japicmp / revapi |
| [`agents-md-schema.md`](agents-md-schema.md) | `AGENTS.md`, `.agents/`, provider adapters | `exeris-systems/.github` → `scripts/agents_file_check.py` |
| [`ai-provenance.md`](ai-provenance.md) | AI-assisted contributions | `[L2]` + DCO app |
| [`claims-and-evidence.md`](claims-and-evidence.md) | numbers in docs | `[L2]`; authority is `exeris-benchmarks/docs/CLAIMS.md` |
| [`checklists/`](checklists/) | `pre-pr`, `doc-page`, `adr`, `release-notes` | `[L3]` only |

## Changing a rule

1. Hard rules trace to an ADR-085 obligation (`§D.13` etc.). Changing a hard rule = amending ADR-085 (dated entry in its `## Amendments` section) **and** the gate config in the same PR.
2. Filter questions and examples can change by PR to this directory alone.
3. A rule that keeps getting worked around is a bug in the rule. Say so in the PR that removes it.

## Provenance

Written 2026-09-04 from the Phase 0 inventory (what the repos do today), the reference analysis of what OpenJDK, Spring, Quarkus, Micronaut and Netty do, the generator spike and the option comparison that chose between them. All of it is internal working material and is deliberately not part of the repository, so it is named descriptively rather than linked. Modelled on the arkstack voice checklist: few rules, testable, short.
