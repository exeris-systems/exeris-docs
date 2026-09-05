---
title: "ADR-NNN: <Short Title>"
type: adr
visibility: public
owning-repo: exeris-<repo>
status: draft
last-verified: YYYY-MM-DD
slug: adr/ADR-NNN
---

# ADR-NNN: <Short Title — verb-led where possible, e.g. "Adopt X", "Standardize on Y", "Replace Z with W">

<!--
TEMPLATE USAGE NOTES — DELETE THIS BLOCK BEFORE COMMITTING.

1. Reserve the number FIRST in `exeris-docs/adr-index.md` (a separate PR), then write content here.
2. Filename pattern: `ADR-NNN-<lowercase-kebab-title>.md` — 3-digit zero-padded, then `-`, then the title in lowercase kebab-case (replace `&` with `and`; drop other punctuation). See `templates/README.md` §Conventions for the full slug rule.
3. Authoritative location depends on Scope (see ADR-020 §1):
   - platform → `exeris-docs/adr/`
   - per-repo → `<owning-repo>/docs/adr/`
   - cross-repo → owning repo's `docs/adr/`, plus `ADR-NNN.link.md` stubs in every consuming repo
   - enterprise-private → `<enterprise-repo>/docs/adr/`
4. Status flow: PROPOSED → ACCEPTED → (later: SUPERSEDED-BY-ADR-MMM | WITHDRAWN). Don't ship in DRAFT/PROPOSED for long — accept or withdraw within a fortnight of writing.
5. Keep "Decision" specific and enforceable. If you can't write a CI check or a review-time assertion against it, the decision is still in RFC territory — push it back.
6. Cross-references: link to other ADRs by number; subsystem docs by repo-relative path.
-->

| Attribute       | Value                                                                                          |
|:----------------|:-------------------------------------------------------------------------------------------------|
| **Status**      | **PROPOSED** \| **ACCEPTED** \| **SUPERSEDED by ADR-MMM** \| **WITHDRAWN**                       |
| **Deciders**    | <Author(s) — typically a single name; list everyone whose sign-off is load-bearing>              |
| **Date**        | YYYY-MM-DD <decision date, not write date>                                                       |
| **Scope**       | platform \| per-repo \| cross-repo \| enterprise-private \| <subsystem> (e.g. `kernel/runtime`)  |
| **Owning Repo** | `exeris-<repo>` <see ADR-020 §1 for the rule>                                                    |
| **Driven By**   | <RFC link / ADR-NNN it amends / external incident / strategic pillar>                            |
| **Compliance**  | `[<Strategic Pillar / Whitepaper section>](<relative-path-or-url>)`                                  |
| **Supersedes**  | <ADR-NNN if this replaces a prior decision; omit row otherwise>                                  |

## Context and Problem Statement

<2–4 paragraphs. State the situation, the forces in tension, and the cost of doing nothing. Avoid solutioning here.>

<End with one sentence that names the question this ADR answers.>

## 🏁 The Decision

**<One sentence. The decision in active voice. Bold.>**

<Optional 1–2 paragraphs of clarification — what this means concretely.>

**Concrete obligations:**

1. **<Obligation 1.>** <Description specific enough that a reviewer can detect violations.>
2. **<Obligation 2.>** <…>
3. **<Obligation 3.>** <…>

<Add as many as needed. Each obligation should be testable: "Does PR X violate this?" should have a yes/no answer, not a judgment call.>

## Consequences

### ✅ Positive Outcomes

- **[+] <Outcome 1.>** <One-sentence elaboration.>
- **[+] <Outcome 2.>** <…>

### ⚠️ Trade-offs

- **[-] <Cost 1.>** <Be honest. Trade-offs that are missing or hand-waved hurt the ADR's credibility.>
- **[-] <Cost 2.>** <…>

### 📋 What is NOT in scope

- <Adjacent decisions that might look like they belong here but don't. Naming them prevents scope creep at review time.>

### 🚫 Non-Goals

- <Outcomes this decision deliberately does not pursue, even though it could. Distinct from "not in scope": a non-goal is a road not taken on purpose (JEP 2 §Non-Goals).>

### ⚠️ Risks and Assumptions

- **Assumes:** <what must stay true for the decision to hold — a JDK feature staying in preview, a vendor limit, a measurement>
- **Reversed by:** <the evidence that would overturn this ADR. If nothing would, this is a preference, not a decision.>
- **Risk:** <what goes wrong if the assumption fails, and who notices first>

## Cross-references

- ADR-NNN (Title) — <one-line reason for the link>
- `<repo>/docs/<path>.md` — <what the linked doc covers>
- <External resource — RFC, JEP, CVE, vendor doc>

## Amendments

<Omit until the first amendment. Then, one dated entry per change, newest first. The original decision text above is not rewritten; superseded paragraphs are marked, not deleted. The registry status becomes `accepted (YYYY-MM-DD, upd. YYYY-MM-DD)`.>

- **YYYY-MM-DD — <title of amendment>.** <What changed, why, and which obligations it touches. Link the PR.>

## Engineering Protocol

<Once ACCEPTED, what enforcement exists? Examples:>

1. <CI guard / ArchUnit test / classpath gate that encodes this rule.>
2. <Documentation site update that needs to land alongside this ADR.>
3. <Migration task tracked separately if the codebase is not yet compliant.>

<If the decision is purely descriptive — codifies existing reality — say so explicitly: "Existing repos already comply; this ADR locks the discipline against future drift."  Otherwise, name the migration owner and target window.>
