---
title: "RFC-2026-10-28: Which security verification does the kernel owe before 1.0, and who runs it?"
type: rfc
visibility: public
owning-repo: exeris-docs
status: draft
last-verified: 2026-10-28
---

# RFC-2026-10-28: Which security verification does the kernel owe before 1.0, and who runs it?

| Field             | Value |
|:------------------|:------|
| **Status**        | **DRAFT** |
| **Author(s)**     | Arkadiusz Przychocki (options analysis assisted by Claude) |
| **Date Opened**   | 2026-10-28 |
| **Date Closed**   | — |
| **Target ADR(s)** | TBD — one ADR in `exeris-kernel` for the security-verification bar of the 1.0 line, if accepted |
| **Affected Repos**| `exeris-kernel` (fuzzing, conformance and smuggling tests, the ASVS mapping, the penetration test), `exeris-systems/.github` (a security review part, prompt-injection hardening of the review runner), `exeris-ai-bridge` (an agentic-risk review of the MCP server), `exeris-docs` (this RFC) |
| **Reviewers**     | Single-author decision (Arkadiusz Przychocki) |

## Question

The kernel is approaching its first release candidate, and a production adopter gates migration on a
stable release. Automated scanning already runs on every pull request: SonarCloud, Snyk/Dependabot,
CodeQL, plus the org review routine. **What verification beyond that does the kernel owe before
`v1.0.0`, in which order, and which of it belongs in CI as a standing gate rather than a one-off?**
The candidates are coverage-guided fuzzing and protocol conformance suites, a requirement mapping
against OWASP ASVS 5.0, a security-focused review part in the org guardrails run on a stronger model,
a review of the agent infrastructure against the OWASP Agentic Skills Top 10, and an external
penetration test.

## Context

The 0.13 line exposed classes of defect that the current tooling does not reach:

- **Conformance defects in byte-level protocol handling.** Five were found and fixed one at a time:
  - the h2c upgrade preface;
  - request-body flow control;
  - inbound frame size;
  - HPACK refusal and wire-octet sizing;
  - HTTP/2 field validation per RFC 9113 §8.2.1, still open as exeris-kernel#769.

  None of them was flagged by a scanner, and each was found by reading the RFC against the code.
- **A security control that never engaged.** Memory-pressure admission (PAQS shedding) could not
  leave `NORMAL` on a default Community boot (exeris-kernel#786, fixed in 0.13), while the subsystem
  pages described it as working. A scanner cannot see a control that is wired but never driven.
- **Review that confirms rather than attacks.** A documentation re-verification by four agents
  introduced false statements, among them the inverse of the code on `ScopedValue` inheritance. An
  adversarial audit then found them, because its brief was "assume this is wrong and find where".
  The same asymmetry applies to code review.

The cost of leaving the question open is that 1.0 freezes the stable SPI surfaces (ADR-065 A1). It
would also freeze, by default, whatever security behaviour ships with them, and give an adopter no
statement of which security requirements the kernel meets and which it leaves to the application.

## Investigation

### Prior art

- **OWASP ASVS 5.0.0** (May 2025, source in `github.com/OWASP/ASVS`, project site in
  `OWASP/www-project-application-security-verification-standard`). It has 17 chapters:
  - V1 Encoding and Sanitization; V2 Validation and Business Logic; V3 Web Frontend Security;
  - V4 API and Web Service; V5 File Handling; V6 Authentication; V7 Session Management; V8 Authorization;
  - V9 Self-contained Tokens; V10 OAuth and OIDC; V11 Cryptography; V12 Secure Communication;
  - V13 Configuration; V14 Data Protection; V15 Secure Coding and Architecture;
  - V16 Security Logging and Error Handling; V17 WebRTC.

  Requirements come in three verification levels. ASVS targets applications. A runtime kernel meets
  some requirements itself (tokens, cryptography, TLS, error handling) and makes others possible for
  the application on top (authorization decisions, data protection).
- **OWASP Code Review Guide** (v2, 2017). A methodology and checklist for manual review. It predates
  current agent-assisted review, but its per-topic checklists are usable as review prompts.
- **OWASP Agentic Skills Top 10** (incubator, version 1.0-2026, mapped to the CSA MAESTRO threat model).
  It covers the risks of AI agent skills and tooling. Here that means the review runner, the `.agents/`
  skills and hooks, and the MCP server in `exeris-ai-bridge`, not the kernel runtime.
- **Protocol conformance and fuzzing.**
  - `h2spec` is the de-facto conformance suite for HTTP/2 servers.
  - Jazzer brings coverage-guided fuzzing to the JVM as JUnit tests, and OSS-Fuzz uses it for Java projects.

### Constraints

- The 1.0 line is GA-only: JDK 25, no preview features. Tools must run on the default line.
- Solo maintainer: a gate that produces noise is worse than no gate, so new gates start advisory
  where their false-positive rate is unknown.
- No access to a dedicated security-model offering. A stronger general model with a security brief
  is the available option.
- Public-docs rule: the ASVS mapping and the penetration-test summary are published, so they name no
  private consumer.

### Data gathered

- The 0.13 issues and pull requests named above, as evidence of what the current tooling misses.
- An adversarial audit of a 1,780-line documentation diff found 26 findings across three parts. The
  confirm-style sweep that produced the diff had reported none.

## Options Considered

### Option A: Layered verification, cheapest high-yield first

1. **Conformance and fuzzing in CI** (exeris-kernel#789, #790, #791):
   - `h2spec` against the Community HTTP/2 server;
   - Jazzer targets for the HTTP/1.1 parser, HPACK, the HTTP/2 frame codec, the WebSocket frame decoder
     and the licence canonicaliser;
   - request-smuggling refusal tests across HTTP/1.1 and HTTP/2.
2. **ASVS 5.0 Level 2 mapping** (exeris-kernel#792). This is `docs/security-requirements.md`. It
   classifies each requirement in the chapters the kernel touches as verified (naming the test),
   delegated (saying what the application does) or not met (linking an issue).
3. **Security review part in the org guardrails** (exeris-systems/.github#139). It triggers on
   security-sensitive paths, runs on the strongest available model with an adversarial brief, and
   demands an exploit scenario and a code citation for every finding. It starts advisory.
4. **Agentic-risk hardening** of the review runner (exeris-systems/.github#140) and of the MCP server
   (exeris-ai-bridge#82): pull-request and repository content is treated as untrusted input to a model.
5. **External penetration test after `v1.0.0-RC1`** (exeris-kernel#793), against the reference
   deployment, with a published scope and summary.

**Pros:** each layer finds a different class of defect. The cheap automated layers come first, so the
paid test does not rediscover what tooling finds. The mapping gives the adopter a statement they can
check.

**Cons:** the most work of the options. The review part and the fuzzing add CI time. The mapping must
be kept current as the kernel changes.

**Cost:** roughly two to three weeks of maintainer time across the RC line, CI minutes for fuzzing,
model cost for the review part on matching PRs, and the external test's fee.

### Option B: External penetration test only

Commission a test before 1.0 and fix what it finds.

**Pros:** independent human expertise, and the least maintainer time up front.

**Cons:**
- a time-boxed test covers what the tester reaches, not parser edge cases at scale;
- it leaves no standing gate, so the next change can reintroduce what was fixed;
- it produces no requirement mapping;
- a paid tester rediscovers conformance defects that `h2spec` finds for free.

**Cost:** the fee, plus fix time.

### Option C: Stronger-model security review only

Add the guardrails security part and rely on it.

**Pros:** cheap to add, and it runs on every relevant change.

**Cons:** model review reads code and does not execute it. It does not explore input spaces the way a
fuzzer does, and it cannot see a control that is wired but never driven unless the reviewer happens to
trace it. It is also an unmeasured gate until its false-positive rate is known.

### Option D (do nothing): keep the current scanners

**Cons:** the 0.13 evidence shows the defects that matter here are outside what the scanners see, and
1.0 freezes whatever ships.

## Testing

The recommendation adds verification rather than a contract surface, so each part verifies itself:

- **Conformance:** `h2spec` runs with an allow-list. Every listed deviation carries a reason and an issue.
- **Fuzzing:** each Jazzer target has a seed corpus, a short PR pass and a longer scheduled pass. Every
  crash becomes a regression test.
- **Review part:** advisory for a stated number of pull requests, with each finding labelled as a true
  or false positive. Promotion to blocking needs that measured rate.
- **ASVS mapping:** checked by review like any document. Every "verified" row names a test that exists.

## Recommendation

**Option A, in the order listed, with the penetration test gated on the first four layers.**

The 0.13 evidence points at byte-level protocol handling and at controls that were never driven.
Fuzzing and conformance suites attack the first directly, and they keep attacking it on every change.
The ASVS mapping forces the second into view, because a requirement can only be marked "verified" by
naming the test that holds it, and #786 would have had no test to name. The review part covers what
neither executes: logic, authorization, and misuse of crypto or TLS APIs. Its adversarial brief is
what the documentation audit showed to work. The penetration test then checks the assembled system
with a human attacker, after the cheap layers have removed the findings tooling can produce.

### Why not the alternatives?

- **Option B:** it leaves no standing gate, and it spends a fee rediscovering what free tools find.
- **Option C:** review reads code but does not execute it; it complements fuzzing and cannot replace it.
- **Option D:** the defects that matter are outside the scanners' reach.

### Risks of the recommendation

- **Noise.** Fuzzing and the review part can be noisy. Mitigation: advisory first, an allow-list, and
  measured promotion.
- **Mapping drift.** The mapping can go stale. Mitigation: it is a subsystem-style page with a
  `last-verified` date, and a "verified" row names a test that CI runs.
- **Schedule.** The RC line may slip. Mitigation: the five items are independent, so the first three
  can run in parallel, and only the penetration test waits.

## Decision Record

| Field            | Value |
|:-----------------|:------|
| **Outcome**      | — |
| **Date**         | — |
| **Resulting ADR(s)** | — |
| **Notes**        | — |

## Open questions / follow-ups

- **Penetration-test scope and vendor:** decided when RC1 is tagged.
- **Enterprise coverage:** whether the security review part also runs on the Enterprise repository,
  and on which trigger.
- **Stream priority:** the Community engine assigns every stream `NORMAL` priority (exeris-kernel#787),
  which limits what admission can protect under load. This is a security-relevant design question for
  the 1.0 line, and is tracked there.
- **Code javadoc that contradicts the code** (exeris-kernel#784) and the HTTP header charset
  follow-ups (exeris-kernel#770, #771, #772): candidates for gaps the ASVS mapping will surface.
