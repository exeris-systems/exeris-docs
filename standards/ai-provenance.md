---
title: AI Provenance and Contribution Policy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-19
---

# AI Provenance and Contribution Policy

Binding per ADR-085 §I.30, which is the whole of this file's mandate: the provenance trailer, human accountability, and the limit on what an agent may do unattended. Rule 7 restates §K.35's `Signed-off-by` requirement because it is the same trailer discipline — it does not settle what a repository asks a contributor to grant. Linked from every `CONTRIBUTING.md`.

Exeris is built with AI assistance as a matter of course: roughly nine in ten commits in the public repos carry a `Co-authored-by: Claude …` trailer, the review workflow is Claude-driven, and the maintainer treats verification (TCK, property tests, benchmarks) — not the author — as the oracle. This policy states the terms, in the open, rather than pretending otherwise or banning the trailer as some projects do.

## Hard rules

1. **Provenance is kept.** A commit produced with AI assistance carries `Co-authored-by: <model name> <noreply@anthropic.com>` (or the equivalent for another tool). Stripping it is a `[STYLE]` finding; adding it where no AI was involved is a lie, treat it the same. `[L2]`
2. **A named human is accountable for every line.** The PR author must be able to explain and defend any part of the change in review. "The agent produced it" is not an answer; it is the reason the question is being asked. The same accountability holds under the Code of Conduct: content produced with an assistant is the author's conduct under form (a) and the named owner's conduct under form (b) (ADR-085 §I.30(c)), and an assistant is never the party a report is about. `[L2]` *(gains form (b) 2026-09-19 — see the `## Amendments` section of ADR-085)*
3. **Agent-executed contributions are authored by the execution identity; the accountable human is named as owner, not as author** *(rewritten 2026-09-19 — see the `## Amendments` section of ADR-085)*. ADR-085 §I.30(b): a harness-run change is git-authored and pull-request-authored by the organisation's execution identity, `exeris-agent` (ADR-087 §A.1, the hands) — never a vendor identity, never a person's account used as a fallback (3d). It opens as a draft; a human marks it ready. Rule 2's accountability is unchanged in force and moves from the author field to the `Owner:` line (3b) — a pull-request body line, not a commit trailer (ADR-085 §D.15): the named owner must be able to explain and defend every part of the change in review exactly as a human author would under rules 1–2. Automated review comments remain fine; a contribution with no accountable human — author under rules 1–2, or owner under 3b — is not. The same split applies to issues: an agent drafts the text, a human files it. `[L1: claude.yml runs only on human-triggered events for automated comments, Dependabot the one exception; the owner line is gated in pr_body_check.py — owed, see 3b]`
3a. **`Exeris-Run:` grammar.** `Exeris-Run: <ULID>` — exactly one per commit, linking it to the run record (ADR-086 §C) that observed it. Written by the harness's `prepare-commit-msg` hook; never hand-written on a human-authored commit. `[L0: exeris-agent-harness prepare-commit-msg hook]`
3b. **`Owner:` grammar.** `Owner: @<login>` — exactly one, an organisation member. Required on every pull request whose author is `exeris-agent`; forbidden on every other. `[L1: pr_body_check.py — owed, checkable not checked until it lands (ADR-085 §J.31)]`
3c. **A `Bot` principal never establishes human review.** A review, a label or a readiness event whose sender is a `Bot` principal — any App the organisation installs — does not satisfy rule 2's or rule 3's accountability, whatever the event says. ADR-087 §B.8a–§B.8c and its amendments of 2026-09-17 (door and readiness senders) state the check; this rule only says that its result binds here too.
3d. **A harness never falls back to a human credential.** A run that cannot mint the execution identity's own token fails; it does not degrade to a person's account, a shared secret, or any other identity to get the commit made. A human opening the pull request that carries a batch of locally captured rows into the inbox is a sign-off on that batch, not a fallback credential for the runs it describes.
3e. **A provider trailer is adapter data, not the provenance trailer.** `Claude-Session:` and its equivalents from other vendor CLIs identify a vendor-side session; they are written by the adapter that launched the run, and this policy neither reads nor gates them. They do not replace `Exeris-Run:` (3a).
3f. **`CONTRIBUTING.md` names both forms.** The template `CONTRIBUTING.md` carries one sentence pointing at the two authorship forms of ADR-085 §I.30 and at `exeris-agent-harness/policy/README.md` for the execution identity's scope and permissions; it does not restate either.
4. **Verification is stated, not assumed.** A PR's `Verification` section names the commands run after the last push; a green default build says nothing about tagged tests or lint (`exeris-kernel/CLAUDE.md` Operating Standard 3). `[L1: pr_body_check.py presence]` `[L2: substance]`
5. **AI-generated tests that assert nothing observable are rejected** — same rule as Quarkus's `AI_POLICY.md`, adopted verbatim in spirit: tests follow the repo's test philosophy (TCK-first, property tests where the contract allows), not volume. `[L2]`
6. **Signal-to-noise.** A PR description is what the author would have written unaided: what it does, what it costs, what it does not cover. Not a transcript. `[L2]`
7. **External contributors** sign off under the DCO (`Signed-off-by:`), certifying the right to submit under the licence that repository publishes for the module (its `LICENSE`, and any per-tier licence file beside it). A sign-off certifies origin and grants nothing, so it neither replaces nor precludes a contributor licence agreement where a repository asks for one. Organisation members are exempt from the trailer, not from the accountability rule. `[L1: DCO GitHub App]`

## What this is not

- Not a ban on AI tooling anywhere in the workflow.
- Not the contributor-licensing regime. Whether a repository also asks for a contributor licence agreement, and what that agreement grants, is a commercial and IP decision: it is owned by the private business decision registry and stated in that repository's own `CONTRIBUTING.md`. This standard governs provenance and accountability; it does not set contribution terms. ADR-085 §K.35 read "No CLA" until that sentence was withdrawn on 2026-09-05 — see the `## Amendments` section of that ADR.
- Not legal advice; the CONTRIBUTING wording and the copyright-holder line get a lawyer's pass after the company registration.
