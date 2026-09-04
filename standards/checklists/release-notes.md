---
title: Release Notes Checklist
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-04
---

# Release Notes Checklist — before the tag

1. **Breaking.** Is the `### Breaking` section present, and does every line match a japicmp/revapi report line and name an ADR?
2. **Accepted changes.** Does `accepted-api-changes.json` carry a justification for each, not just a signature?
3. **Migration.** Non-empty `Breaking` → is there a `MIGRATION.md` section for this version, written for someone on the *previous* release (the v0.5.0-in-production case)?
4. **Stability.** Does the stability paragraph agree with `stability-matrix.md`, and is every label change a `Changed` entry?
5. **Modules.** Does every entry name its module and link a PR or ADR?
6. **Numbers.** Any figure in the notes → report path + state; nothing from the retraction register.
7. **Narrative vs list.** Do the hand-written notes tell the story and the CHANGELOG list the facts — without duplicating each other?
8. **Version.** `release(x.y.z):` commit, `-SNAPSHOT` bumped on `development/*`, Maven Central POM licence block present.
9. **Docs.** Do the docs the release changes have `last-verified` bumped, and does the site build from the release branch named in `sources.yml`?
10. **Consumers.** Did the ai-bridge, Elevated, and any repo pinning this version get a heads-up line in *Cross-repo impact*?
