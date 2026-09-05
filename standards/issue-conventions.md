---
title: Issue Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-05
---

# Issue Conventions

Binding per ADR-085 §E.17a. Applies to every issue in every Exeris repository. Forms live in `exeris-systems/.github/ISSUE_TEMPLATE/`; blank issues are disabled.

## Hard rules

1. **Four forms, no blank issues.** `Bug` (contract violated), `Change request` (becomes a PR), `Performance finding` (numbers with evidence), `Documentation` (stale / missing / wrong / evidence / boundary / drift). Questions and RFC-shaped topics go to Discussions; security to the private advisory form. `[L1: ISSUE_TEMPLATE/config.yml blank_issues_enabled: false]`
2. **Title grammar = commit grammar.** `type(scope): summary`, ≤ 100 characters, so the issue title can become the PR title unchanged. The type comes from the list in `commit-conventions.md` rule 1 — a defect is `fix`, never `bug`. `[L2]`
3. **Labels come from the organisation taxonomy** (`labels.yml`, applied by `workflows/labels-sync.yml`): one `type:` label; the review-ladder labels (`hard-block`, `doc-debt`, `tck-debt`, `cross-repo`, `phase-gated`) mirror the tags reviews emit; `release:` labels feed the generated release notes. Repo-specific `area:` labels are allowed and are the only labels a repo may add. The sync is additive and never deletes, so those survive it. `[L1: scripts/labels_sync.py]`
4. **A bug names the contract it violates** — the Javadoc, subsystem page, TCK class or ADR. No contract → it is a Documentation issue (the contract is missing) or a Discussion (the behaviour was never promised). `[L3: form field required]`
5. **Numbers need evidence.** A Performance finding without a report path and figure state carries `needs-evidence`; a Bug without a reproducer carries `needs-reproducer`. Either goes stale after 14 days of silence and closes 7 days later. A comment inside that window removes the marker and keeps the issue open; after it closes, reopening is a person clicking reopen — the workflow cannot do it. `[L1: workflows/issue-hygiene.yml]`
6. **Review findings become issues, one each, by the PR author.** A `[DOC DEBT]` or `[TCK DEBT]` finding that the PR does not resolve is filed with the Documentation (or Change request) form before the PR merges, labelled `doc-debt` / `tck-debt`, and the PR body's `TCK obligation: debt #N` line references it. `docs-guardrails-review.md` requires each such finding to name where it is tracked; that it resolves to an open issue rather than a backlog note is what this rule adds. A merged PR with an unfiled debt finding is a review miss, reported in the monthly audit. `[L2: docs-guardrails-review output format]`
7. **Sweep and audit outputs become issues the same way.** Every `<!-- VERIFY(sweep-…) -->` marker and every QUESTION the founder answers with "later" becomes one Documentation issue with `Origin` filled in; the sweep report links them. An agent drafts the text, a human files it (`ai-provenance.md` rule 3). `[L2]`
8. **`Closes #N` closes; `Refs: ADR-NNN` relates.** A PR that resolves an issue carries `Closes #N` (or `Fixes #N`) in the body and the squash commit; a PR that only touches an issue links it in prose. The checker verifies the grammar of a trailer that is present, not that a resolving PR carries one — that half is review. `[L1: pr_body_check.py TRAILERS]` `[L2: the obligation]`
9. **Triage within a week.** New issues carry `triage`; removing it means a maintainer set the `type:` label, scope class and (for bugs) severity estimate. Issues older than 30 days with `triage` still on are listed by the monthly audit. `[L2: audit]`
10. **English.** `[L2]`

## Why this shape

Quarkus routes questions away from the tracker (`config.yml` → Stack Overflow / Discussions / Zulip) and lets a bot label by path and title; Spring treats the tracker as the design record; Micronaut has forms but no rules. The Exeris addition is rule 6: the review routines already produce a severity vocabulary, and without it a `[TCK DEBT]` finding has nowhere to land except the PR thread. Making the finding → issue step mandatory and labelled is what lets the monthly audit count debt instead of estimating it.

## Where this does not apply

`budgetHQ/` and `pbm/` keep their own internal issue conventions, as they keep their own ADR namespaces. The hygiene workflow closes only issues a maintainer marked as missing a named thing; nothing here ages out an issue for being old.

## Filter (before you submit)

- Does the title read as the eventual commit subject, with a real commit type?
- Bug: which document promised the behaviour you expected? Quote it.
- Performance: is every number copied from a report, with its fence, and is the report path in the issue?
- Documentation: did you name the symbol you checked the doc against?
- Is this actually a question? Then it is a Discussion.
