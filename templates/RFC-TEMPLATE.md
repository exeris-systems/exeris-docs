---
title: "RFC-YYYY-MM-DD: <Short Title>"
type: rfc
visibility: public
owning-repo: exeris-<repo>
status: draft
last-verified: YYYY-MM-DD
---

# RFC-YYYY-MM-DD: <Short Title — describes the question, not the answer>

<!--
TEMPLATE USAGE NOTES — DELETE THIS BLOCK BEFORE COMMITTING.

1. RFCs are **exploration documents**. They precede ADRs. The output of an RFC is an ACCEPTED RFC (a recommended direction) which then becomes one or more ADRs that lock the decision in.
2. RFC IDs use a date prefix (YYYY-MM-DD) not sequential numbers. They're chronological exploration; sequential ADR numbers come AFTER acceptance.
3. RFCs MAY live outside this repo (an external system, an issue tracker, a discussion thread). When external, an ADR's "Driven By" field links to the RFC URL. Use this template either way — it's the structure that matters, not the host.
4. The Investigation section carries the evidence behind the option comparison. A falsifiable hypothesis that needs its own measurement campaign is a RESEARCH document instead (`RESEARCH-TEMPLATE.md`; filename `RESEARCH-YYYY-MM-DD-<kebab>.md`, branch-scoped on `research/<slug>` — see `templates/README.md`).
5. RFC status flow: DRAFT → IN-REVIEW → ACCEPTED → (one or more ADRs) | REJECTED | WITHDRAWN.
6. An RFC is too long if you can't read it in 15 minutes. If options analysis is sprawling, split into multiple RFCs.
7. Don't write an RFC for a decision the team has already informally made — go straight to ADR.
-->

| Field            | Value                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------|
| **Status**       | **DRAFT** \| **IN-REVIEW** \| **ACCEPTED** \| **REJECTED** \| **WITHDRAWN**                      |
| **Author(s)**    | <Name(s)>                                                                                        |
| **Date Opened**  | YYYY-MM-DD                                                                                       |
| **Date Closed**  | YYYY-MM-DD <set when status reaches ACCEPTED/REJECTED/WITHDRAWN>                                 |
| **Target ADR(s)**| <ADR-NNN expected to be authored once this RFC is accepted; "TBD" while in DRAFT>                |
| **Affected Repos**| <comma-separated list of repos this decision will touch>                                        |
| **Reviewers**    | <Optional — leave blank for solo-author projects>                                                |

## Question

<One paragraph. State the question the RFC is trying to answer. Examples:
"Should we standardize on PostgreSQL 18 across all Exeris applications?"
"How should the kernel propagate request context — ScopedValue, ThreadLocal, or per-request explicit parameter?"
"What's our Java version target for v1.0?"

A good RFC question is binary or has a small enumerable set of answers. "How do we improve performance?" is not an RFC question.>

## Context

<2–4 paragraphs. Why is this question being asked now? What changed? What's the cost of leaving it unanswered? Who's affected if the wrong answer is picked? Avoid recommending an answer here — that's §Recommendation.>

## Investigation

<This is where research lives. Subsections as needed:>

### Prior art

<What have other projects/companies/RFCs done in this space? Cite sources.>

### Constraints

<What hard constraints apply? Performance budgets, licensing, regulatory, vendor commitments, existing ADRs that bound the decision.>

### Data gathered

<Measurements, benchmarks, surveys, code archaeology, vendor experiments. Numbers belong here, not in §Recommendation.>

### Spike outcomes

<If a prototype was built to inform the decision, summarize what it proved or disproved. Link the prototype branch / commit if relevant.>

## Options Considered

### Option A: <Short name>

<1–2 paragraph description.>

**Pros:**
- <…>

**Cons:**
- <…>

**Cost:** <engineering cost / operator cost / vendor cost / migration cost — whatever's relevant>

### Option B: <Short name>

<…>

### Option C (do nothing): <What if we don't decide?>

<Always include the do-nothing option. If "do nothing" is acceptable, the RFC should probably be withdrawn.>

## Testing

<Required when the RFC proposes an SPI surface, a wire format, or a contract consumers will implement (JEP 2 §Testing). How will the recommended option be verified — which `Abstract*Tck`, which property tests, which benchmark scenario? What cannot be tested before implementation, and what is the fallback? Omit the section for decisions with no testable surface, and say so in §Recommendation.>

## Recommendation

**<One sentence stating the recommended option. Bold.>**

<2–4 paragraphs justifying the recommendation against the rejected options. Reference data from §Investigation. Be honest about residual uncertainty.>

### Why not the alternatives?

- **Option A** — <one-sentence reason to reject>
- **Option C** — <one-sentence reason to reject>

### Risks of the recommendation

- <Known risks of going this direction. The reviewer should not have to guess at downside.>

## Decision Record

<Filled in when status reaches ACCEPTED / REJECTED / WITHDRAWN.>

| Field            | Value                                                                  |
|:-----------------|:-----------------------------------------------------------------------|
| **Outcome**      | ACCEPTED \| REJECTED \| WITHDRAWN                                      |
| **Date**         | YYYY-MM-DD                                                             |
| **Resulting ADR(s)** | <ADR-NNN, ADR-MMM — created from this RFC; "none" if rejected>     |
| **Notes**        | <Optional — anything the reviewer wants future-them to know>           |

## Open questions / follow-ups

<Items that surfaced during the RFC but are out of scope for this decision. Each becomes a future RFC, ADR, or tracked task.>

- <Question 1 — owner / target>
- <Question 2 — owner / target>
