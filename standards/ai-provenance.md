---
title: AI Provenance and Contribution Policy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# AI Provenance and Contribution Policy

Binding per ADR-085 §I.30 and §K. Linked from every `CONTRIBUTING.md`.

Exeris is built with AI assistance as a matter of course: roughly nine in ten commits in the public repos carry a `Co-authored-by: Claude …` trailer, the review workflow is Claude-driven, and the founder treats verification (TCK, property tests, benchmarks) — not the author — as the oracle. This policy states the terms, in the open, rather than pretending otherwise or banning the trailer as some projects do.

## Hard rules

1. **Provenance is kept.** A commit produced with AI assistance carries `Co-authored-by: <model name> <noreply@anthropic.com>` (or the equivalent for another tool). Stripping it is a `[STYLE]` finding; adding it where no AI was involved is a lie, treat it the same. `[L2]`
2. **A named human is accountable for every line.** The PR author must be able to explain and defend any part of the change in review. "The agent produced it" is not an answer; it is the reason the question is being asked. `[L2]`
3. **Agents do not open PRs, file issues or post comments without a human author.** Automated review comments are fine; automated *contributions* are not. `[L1: claude.yml runs only on human-triggered events; Dependabot is the one exception]`
4. **Verification is stated, not assumed.** A PR's `Verification` section names the commands run after the last push; a green default build says nothing about tagged tests or lint (`exeris-kernel/CLAUDE.md` Operating Standard 3). `[L1: pr_body_check.py presence]` `[L2: substance]`
5. **AI-generated tests that assert nothing observable are rejected** — same rule as Quarkus's `AI_POLICY.md`, adopted verbatim in spirit: tests follow the repo's test philosophy (TCK-first, property tests where the contract allows), not volume. `[L2]`
6. **Signal-to-noise.** A PR description is what the author would have written unaided: what it does, what it costs, what it does not cover. Not a transcript. `[L2]`
7. **External contributors** sign off under the DCO (`Signed-off-by:`), certifying the right to submit under the module's licence (`LICENSE` / `LICENSE-COMMUNITY` in each repo). Organisation members are exempt from the trailer, not from the accountability rule. `[L1: DCO GitHub App]`

## What this is not

- Not a ban on AI tooling anywhere in the workflow.
- Not a CLA. Contributions are accepted under the module's published licence; the project does not ask for relicensing rights (RFC-2026-09-04 Q3).
- Not legal advice; the CONTRIBUTING wording and the copyright-holder line get a lawyer's pass after the company registration.
