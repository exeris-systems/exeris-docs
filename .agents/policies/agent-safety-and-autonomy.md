---
title: Policy — agent safety and autonomy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-08
---

# Policy — agent safety and autonomy

Hard constraints. This is the written rule that `.agents/hooks/hooks.yaml` enforces; the hook is a
tripwire, not the authority. Where the two disagree, this file is right and the hook is a defect.

## 1. Human in the loop

An agent never performs an irreversible or outward-facing action on its own initiative. Each of
these needs the founder to ask for it in the session it happens in; approval given once for one
action does not carry to the next.

- `git push --force` and `--force-with-lease`, to any ref.
- Any push to `main` or to a `development/*` branch.
- `git tag`, `gh release create`, and any publish or deploy.
- `gh pr merge`, and closing or merging anyone else's pull request.
- Deleting a branch, a worktree, or a remote ref.
- `git reset --hard` and `git clean -fd` over uncommitted work that the session did not create.
- Anything that sends repository content to a service outside `github.com/exeris-systems`.

Opening a pull request is not on this list, but ADR-085 §I.30 is: an agent does not open a pull
request or file an issue without a named human author, and the `Co-authored-by:` trailer records
the assistance rather than the authorship.

## 2. Minimal privilege

A role declares the narrowest `capabilities` that let it finish its job. Read-only roles —
`exeris-docs-architect`, `exeris-docs-document-shape-classifier`, `exeris-docs-evaluator` — stay
read-only, and a finding they could fix in one line is still handed back rather than applied. A
role that needs a capability it does not have escalates; it does not borrow one from another role.

## 3. Isolation for doc work

Documentation changes are made on a branch off `origin/main`, in a worktree when other repositories
in the workspace are on unrelated branches. A session that edits the shared checkout in place makes
the founder's other work part of its diff.

## 4. What an agent may never claim

- That a gate passed, when what it observed was that a command exited zero with the gate skipped.
- That a corpus-wide claim holds, when what it ran was a single-file grep.
- That a check ran, when it did not. "Not run" is a reportable result; silence is not.

Reporting is covered in `error-handling-and-fallback.md`; the reason it is a *safety* rule is that
every item above turns a missing check into a green light for a human who did not run it either.
