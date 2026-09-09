---
name: docs-pr-review
description: Full pull-request review for exeris-docs — scope, registry discipline, amendment discipline, drift, single-edit consistency, scoped bans and claims, ending in a verdict. This is the routine the CI review action runs; run it locally before opening a pull request to get the same answer earlier.
disable-model-invocation: true
---

<!-- DO NOT EDIT. Generated from .agents/workflows/docs-pr-review.md by agents_render.py
     (exeris-systems/exeris-agents; agents-md-schema.md rule 7). Edit the source. -->
Review the change below and return one verdict.

Change: $ARGUMENTS

Read `AGENTS.md` first — it is the entry point, and the rules live under `.agents/`. Read the
policies your diff actually touches rather than working from memory; each is the single owner of
its list, and a summary repeated here would go stale the next time an entry is added.

Steps:

1. **Triage.** Classify the change with the `exeris-docs-task-classifier` skill. The class decides
   which of the specialist steps below run at all; a docs-only typo fix does not need the architect.

2. **Run the mechanical checks and record what they said**, before reading the diff for meaning.
   `.agents/scripts/adr-filename-check.sh` on every changed `adr/ADR-*.md`,
   `.agents/scripts/drift-sweep.sh` on every changed large document,
   `.agents/scripts/taxonomy-check.sh` on the changed set,
   `.agents/scripts/check-consistency.sh` for the repository-wide invariants.
   Report each as pass, fail or not-run with its exit code. A check you did not run is `not-run`;
   it is never silence.

   `ci:docs`, `ci:commits` and `ci:pr-body` are gates too, and a `ci:` gate is **observed, not
   re-run** — `agents-md-schema.md`'s *Workflow header* owns that rule, because it owns what the
   prefix means. Here it is one command:
   `gh api repos/<repo>/commits/<sha>/check-runs --jq '.check_runs[] | "\(.name) \(.status) \(.conclusion)"'`.

   What `ci:docs` owns in this repository is the shared enforcement in `exeris-systems/.github` —
   `frontmatter_check.py`, `registry_check.py`, `lint_globs.py`, markdownlint and Vale. Where the
   pull-request body cites a number from one of them, say whose environment produced it rather
   than filing the script as a check you failed to perform.

3. **Specialist passes**, as the triage class requires. The registry keeper owns numbering,
   filename, location, visibility and licence; the architect owns three-tier framing, doc
   precedence and drift adjudication. Neither restates the other's rules.

4. **Evaluate.** Run `exeris-docs-evaluator` over the whole change: scope against the pull-request
   description, amendment discipline, single-edit consistency, scoped bans, claims. Its verdict is
   the one that is posted.

5. **Report.** Lead with blockers, then in-scope improvements, then non-blocking suggestions. Cite
   `file:line`. End with the verdict and, after it, the same content as a fenced `json` block
   conforming to `.agents/schemas/verdict.schema.json`.

The scoped bans in `AGENTS.md` and `.agents/policies/adr-registry.md` are absolute: a withdrawn
figure asserted rather than fenced, or a number without its report path and figure state, is
`BLOCKED` however small the diff is.
