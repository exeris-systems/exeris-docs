---
title: Comment Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-18
---

# Comment Conventions

Binding per ADR-085 §F.21f; §J.32 names the gate. One rule, in every language: **a comment carries the contract, not the
history.** `javadoc-conventions.md` rule 12 and `tsdoc-conventions.md` rule 12 are this rule
narrowed to the tags and the gate of one language, and where any of the three disagree this page is
the rule.

## Separation of concerns, for information

Three surfaces, three jobs. A fact belongs to exactly one of them, and putting it in two is how the
two come to disagree.

| Surface | Carries | Answers |
|:--|:--|:--|
| Code comment | the stable semantic reason | **why this code exists** |
| Commit / pull request | implementation history | **what changed, and how** |
| Issue / postmortem | incident history | **what happened, why it happened, and what it cost** |

A comment outlives the change that added it; a commit message does not, and is not meant to. That
asymmetry is the whole of this page.

## Hard rules

1. **A comment states the invariant, not its origin.** *"The ring is initialised by the transport
   owner thread, never by a persistence path"* is the contract and stays, however it was learned.
   *"This fixes the head-of-line blocking we hit in h1"* is history and goes. The anchored token
   list — "previously returned", "used to be", "fixed in 0.8.1", "formerly", "as of 0.12", PR, issue
   and bug numbers, "workaround for", "after the … refactor", "we hit" — is authored once, in
   `exeris-systems/.github` → `comment-history.json`.
   `[L1 (warning): Checkstyle over Java, ESLint over TypeScript, comment_history_check.py over the rest]` `[L2]`

2. **The test is time, and it is the one to apply when the list says nothing.** Read the comment
   with no access to the change that added it. What still says something is the contract; what only
   made sense beside that diff was never a comment. A sentence can pass every token check and fail
   this one. `[L2]`

3. **A comment that needs a story is a missing link.** Where an invariant deserves a *why* at
   length, the comment references the place that owns it — `@see ADR-NNN`, a `docs/subsystems/` page,
   a changelog entry — rather than retelling it. A paragraph of argument in a comment is an ADR
   nobody wrote. `[L2]`

4. **A correction replaces; it does not annotate.** Where a comment said something untrue, edit it
   to say the true thing and stop. "Corrected", "an earlier draft said", "this replaces" are notes
   about the author rather than about the subject, and the diff already records them. `[L2]`

5. **The gates warn; they do not fail.** Whether a sentence is archaeology or a statement about the
   present is a reviewer's call — *"the buffer is no longer valid after `close()`"* is a correct
   sentence about now. A build that stops on the difference decides it wrongly in one direction
   every time. `[L1 (warning)]`

6. **The token list is narrow by measurement, and authored once.** Each alternative is anchored to
   the verb or the number that makes it past-referential; "no longer" and a bare "previously" are
   deliberately absent, because a check that is wrong most of the time is one people learn to
   ignore. One file holds the list and every gate reads it or is asserted against it: a second copy
   drifts, and did — before `comment-history.json`, the Java and TypeScript regexes had drifted
   apart in both directions while `tsdoc-conventions.md` described them as identical.
   `[L1: comment_history_suite.py]`

## Where this does not apply, and what it costs

Not to the history surfaces themselves. A commit message, a pull-request body, an issue, a
changelog entry, a release note and an ADR's `## Amendments` section exist to carry history, and
rule 1 is what keeps them the place it goes rather than the place it is duplicated.

Not to a test that pins a behaviour. A case may name the behaviour it holds — that is the contract
it asserts — but it does not narrate when that behaviour broke, and it does not assert a count of
something mutable so that fixing the thing turns the suite red.

The cost is that "delete it" is never the instruction. A sentence removed from a comment carries
knowledge, and the rule is that it **moves** — to the commit, the changelog, an ADR or an issue.
A reviewer applying rule 1 without naming the destination has made the codebase poorer, which is
why rule 1's `[L2]` finding is written as a `[STYLE]` with the destination named.

## Filter

- Does every comment I added state something that will still be true in two years?
- Does any of them explain the diff rather than the code? That text belongs in the commit.
- Did I remove a sentence carrying knowledge without moving it anywhere?
- Did I annotate a correction instead of making it?
