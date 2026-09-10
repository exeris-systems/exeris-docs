---
title: "ADR-087: Establish exeris-bot as the CI Publication and Capture Step"
type: adr
visibility: public
owning-repo: exeris-docs
status: draft
slug: adr/ADR-087
---

# ADR-087: Establish exeris-bot as the CI Publication and Capture Step

| Attribute       | Value |
|:----------------|:------|
| **Status**      | **PROPOSED** |
| **Deciders**    | Arkadiusz Przychocki |
| **Date**        | 2026-09-10 |
| **Scope**       | platform / cross-repo (`exeris-systems/.github` owns the workflows; every repository that calls them adopts the contract; `exeris-agents` supplies the verdict shape; `exeris-ai-execution` consumes the rows) |
| **Owning Repo** | `exeris-docs` (the bot is an organisation-wide identity and contract; its code lives in `.github`, which carries the stub) |
| **Driven By**   | The provider coupling of `docs-review.yml` (ADR-085 §J.33's L2 review, one step, one provider's identity); the label taxonomy's severity vocabulary that nothing applies; ADR-086, which needs a producer for CI rows. The option comparison behind this ADR is internal working material and is not part of this repository. |
| **Compliance**  | [ADR-085](ADR-085-documentation-architecture-and-repo-hygiene-standards.md) §C.11 (shared enforcement lives in `.github`), §I.29–30 (no duplicated rules; no PR or issue without a named human), §J (enforcement layering); [ADR-086](ADR-086-bound-the-ai-execution-layer-to-observation-before-routing.md) §C (run record), §D.15 (review-domain rows), §F.31 (`ci:` fingerprints); [ADR-065](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-065-spi-compatibility-gate.md) (the compatibility report §D trusts) |

## Context and Problem Statement

The L2 review of ADR-085 §J.33 runs on pull requests through one reusable workflow, `docs-review.yml`, whose single step both *produces* the review with one provider's action and *publishes* it under that provider's GitHub identity — the App the action exchanges the workflow's OIDC token for, which is why every caller grants `id-token: write`. The routine the step follows is provider-neutral Markdown checked out from `.github`; the step around it is not. A provider swap rewrites the author of every past review, and the only way to make the step apply a label is to grant the one step that executes model-generated commands `pull-requests: write`.

Three further facts, observed in the checkout on 2026-09-09, make the shape wrong rather than merely inconvenient. `labels.yml` defines `hard-block`, `cross-repo`, `doc-debt`, `tck-debt` and `phase-gated` as "the severity vocabulary pr-review.md and docs-guardrails-review.md emit", and nothing applies them: a `[HARD BLOCK]` finding is a sentence in a comment and blocks no merge. The organisation routine ends in prose with bracketed tags while `exeris-docs`'s own routine ends in a fenced `verdict` JSON, so a repository that copies `caller-example/guardrails.yml` runs two L2 reviews with two output contracts. And every L2 run in CI is a candidate row for the layer ADR-086 bounds — the same domain, with the same oracle running beside it as L1 gates — and every one of them is discarded when the runner exits.

The reference bots do not answer this. Skara integrates on the author's behalf because OpenJDK forbids self-merge; `quarkus-bot` routes issues and pull requests to area maintainers. Both solve a scale problem this organisation does not have — one maintainer, a handful of external reviewers, no area owners — and both are hosted services with release cycles of their own. What transfers is narrower: one stable author for automated actions, with the human whose request it fulfils named in it; a structured artefact posted as a comment rather than a log; and the compatibility report, not a path glob, as the signal that a change obliges somebody else.

This ADR answers: **what does `exeris-bot` own in CI, under whose identity and credential does it act, what must it never emit, and when may it file work in another repository?**

## 🏁 The Decision

**`exeris-bot` is a GitHub App identity plus reusable workflow steps in `exeris-systems/.github` — a *publish* step that turns any runner's schema-valid `verdict` into a review comment, labels and a fail-closed required check under the organisation's own byline, and a *capture* step that emits one ADR-086 run record per L2 run; it files one merge-time, human-named, idempotent issue per downstream repository when a compatibility report says an upstream surface changed; it judges nothing, selects nothing, and routes nobody.**

It is not a service. It has no repository of its own, no hosted process and no state beyond what a workflow run holds. Everything below is a step in `.github/workflows/*.yml`, checked out by callers at a pinned ref.

**Concrete obligations:**

### A. Identity and credential

1. **Two Apps, because a GitHub App's permissions are one set for every repository it is installed on** — there is no per-repository narrowing, so "write to the inbox and nowhere else" cannot be one App with a write scope. **`exeris-bot`** is the *voice*: installed organisation-wide with `pull-requests: write` and `issues: write` and nothing else (`metadata: read` is implicit; it holds no `contents` scope at all), and it is the author of every automated review comment, label change and issue the organisation's workflows produce. **`exeris-inbox`** is the *pen*: installed only on `exeris-ai-execution` and its enterprise sibling, with `contents: write` and `pull-requests: write` there, and it commits rows and opens the inbox pull requests of §C.15. A compromise of the first can talk; a compromise of the second can write to two data repositories; neither can push a line of code to the kernel.
2. **Both private keys are organisation secrets readable only by workflows in the organisation's repositories**; every job mints a short-lived installation token (`actions/create-github-app-token`) for the one App the step needs and holds it for that step alone. These are standing credentials, and `labels-sync.yml` refused one for a reason: there the alternative was free, because a repository token can sync its own labels. Here there is no free alternative — a repository token cannot act in another repository and cannot give the organisation a byline. The trade is recorded, not hidden: rotation is a dated line under `## Amendments` per App, and the compensating gain is §B.5. A single App carrying `contents: write` everywhere is the alternative, and it is admissible only if this ADR stops calling its scope minimal.
3. **Provenance survives a swap.** Every review comment carries a footer naming the runner — `provider`, model id, harness and version, the routine file and its SHA. The bot is the publisher; it is never described as the reviewer, and ADR-085 §I.30's human accountability attaches to the pull request's author as it does today.
4. **Names in envelopes.** In every run record the bot emits, `agent.provider`, `agent.model_id` and `agent.harness` name the runner; neither `exeris-bot` nor `exeris-inbox` appears in those fields. A row that names a publisher as the agent is the instrument mutant of Engineering Protocol 2.

### B. Publication

5. **Produce and publish are two steps, and only the second writes.** `docs-review.yml` becomes a *produce* job — one per supported runner, selected by a `runner:` input the caller sets — that writes `verdict.json` to a path the step reads, followed by a *publish* job that posts, labels and gates. Because every write goes through an App's installation token, **no job's own `GITHUB_TOKEN` needs a write scope**: produce and publish alike run with `contents: read`, `pull-requests: read`, `issues: read` (the routine reads the debt issues of `issue-conventions.md` rule 6) and `id-token: write` where the runner's action needs it for its own token exchange. The one step that executes model-generated commands never held more; the caller's permission block does not change, and `caller_permissions_check.py` has nothing new to pass.
6. **The output contract is `verdict`, not a new schema.** The publish step consumes `verdict.base.schema.json` from the `exeris-agents` bundle, composed in `.github` the way `exeris-docs` composes it — `agent` narrowed to the organisation routine's role, `scope_class` to ADR-085 §E.16's vocabulary — plus **one optional field, `tag`**, carrying the bracketed severity the organisation routine emits *today*: `HARD BLOCK`, `CONTRACT`, `CATEGORY-B`, `CROSS-REPO`, `DOC DEBT`, `TCK DEBT`, `STYLE` — the seven that can be checked against `docs-guardrails-review.md` in git. The remaining vocabulary of `pr-review.md` (`CATEGORY-C`, `SYNC`, `PERFORMANCE`, `PHASE`, `HEURISTIC`) lives in the Claude Project document ADR-085 §J.33 still names, and joins the enum in the amendment that brings that document into git (Engineering Protocol 6) — an enum value nobody can check against a file in the repository is a value the routine may never emit. The field is added in the composed schema, never in the base. `docs-guardrails-review.md` gains the closing requirement `docs-pr-review.md` already has — the verdict as a file, and as a fenced `json` block in the posted text.
6a. **`.github` vendors the base it composes over.** The organisation repository carries no `.agents/` tree today, so a `$ref` to `../vendor/…` has nothing to resolve. It becomes a bundle consumer in the bundle's own sanctioned form: `agents_bundle.py vendor` into `.agents/vendor/exeris-agents-<version>/`, pinned and digest-verified like every other consumer's copy — a verified vendored copy is what `BUNDLE.md` defines a copy to be, not a fork. Two rules hold it honest: the vendored version equals the ref `docs-lint.yml` already checks the bundle's `tools/` out at, asserted by `.github`'s own `guardrails.yml` beside `caller_permissions_check.py`; and the publish step compares the caller's pin (`.agents/manifest.yaml`) with its own — a different MAJOR is red with the mismatch named, a different MINOR or PATCH validates against `.github`'s base, because the bundle's SemVer promises that a MINOR adds and never requires. Resolving the base from the caller's checkout instead was considered: it validates against the pin the routine ran under, but it makes the composed schema a fragment a script assembles rather than a file whose `$ref` resolves, and it makes every repository without a vendored bundle red on publication for a reason unrelated to its review.
7. **The label mapping is mechanical and lives in one file** (`.github/labels-from-verdict.json`): `decision: BLOCKED` → `hard-block`; a finding tagged `CROSS-REPO` → `cross-repo`; `DOC DEBT` → `doc-debt`; `TCK DEBT` → `tck-debt`. `PHASE` → `phase-gated` joins with the tag in §B.6's amendment. The mapping names only tags in the enum and only labels in `labels.yml`, and `.github`'s `guardrails.yml` asserts both. A `PASS` after a `BLOCKED` on the same pull request removes `hard-block`. Labels the mapping does not name are never touched.
8. **The publish step is the required check, and it is fail-closed.** It is green only when it parsed a schema-valid verdict with `decision ≠ BLOCKED` and no `checks_run[].result == not-run` for a gate the routine names as mandatory — or when the produce job was skipped by the deterministic path filter, which the log distinguishes from a crash. A verdict that is absent (runner crashed, timed out, cancelled by `concurrency`), invalid, `BLOCKED`, or resting on an unrun mandatory check is red. A label alone is never the gate: a rule that fails on `hard-block` present passes when the runner never ran.
9. **`not-run` is published, never swallowed.** Every `checks_run` entry with `result: not-run` appears verbatim in the comment; a verdict resting on an unrun check says so in the place a reader looks (`error-handling-and-fallback.md` rule 1).
10. **Where a runner cannot write a file** (today's `--allowedTools` allows no `Write`), the publish step parses the fenced block from the review the runner posted, as a stated fallback; the file is the contract, the fallback is the exception, and the ADR that removes the fallback is an amendment here.
11. **Two L2 reviews on one pull request publish under one identity and one contract.** A repository that runs its own routine and the organisation's gets two verdicts; both are posted, the stricter decides `hard-block`, and neither is suppressed. Whether the two should be one run with two roles is `agents-md-schema.md`'s question, not this ADR's.
12. **The runner seam is a configuration point, not a decision point.** `runner:` is set by a human in the caller. The bot records which runner ran and selects nothing; ADR-086 §B fixes when a selection may exist (V4, on its conjunction, after preregistration), and the word *router* does not appear in the bot's documentation until then.

### C. Capture

13. **One run record per L2 run, in the shape of `exeris-ai-execution/schemas/run-record.schema.json`**, assembled by the publish job from what CI already holds: the verdict; the check-run conclusions of the L1 gates as `oracle` state; `agent` from the runner's output (`model_id`, `model_snapshot`, `harness.client`, `harness.version`); `repository_state` from the checkout (`commit`, the bundle pin from `.agents/manifest.yaml`, `dirty: false`, `visibility` per §C.17); `accounting.mode` from the credential class; `execution` from the runner's execution log; `instrument` from the bot's own version and the fence in force. The bot adds nothing the schema does not name and interprets nothing — no aggregation, no comparison, no sentence about a model — per ADR-086 §A.2.
14. **Producer-side derivations are this ADR's, not the schema's** (ADR-086 §C.12–14 and §F.30–31 name the fields; this names how a CI producer fills them):
    - `agent.system_prompt_sha256` — SHA-256 over, in this order and each terminated by a newline: the prompt text the workflow passed to the runner; the routine file at the checked-out `.github` SHA; `AGENTS.md` **as the runner read it**. The hash records what happened, not what should have; which `AGENTS.md` the runner reads is §C.14a's rule. The harness's own prompt changes are covered by `harness.version`. A runner that does not expose enough to compute this yields **no row**, not a row with a convenient hash.
    - `agent.model_snapshot` — from the runner's execution log; absent there → no row.
    - `execution.event_stream` — the runner's execution log, uploaded as a *separate* workflow artefact (it contains content), referenced by artefact URL, SHA-256 and event count. Never copied into the row, never committed to an inbox.
    - `accounting` — `mode: subscription` under an OAuth credential, `api` under an API key; usage from the log; **the USD figure a runtime prints under a subscription is a price-list computation and is dropped** — the schema refuses it, and a producer that relabels it is working around the schema (ADR-086 Engineering Protocol 8).
    - `workload.fingerprint` — `ci:` class: a keyed MAC over `(repository, pull request number, head sha)` with the organisation secret `EXERIS_FINGERPRINT_KEY`; a key rotation writes a fence (ADR-086 §F.31).
    - `workload.scope` — from the pull request's *Scope class* (ADR-085 §E.16), mapped to the schema's pattern by a fixed table, not by convention: `runtime hot path` → `runtime-hot-path`, `runtime non-hot` → `runtime-non-hot`, `test-tooling` → `test-tooling`, `docs-only` → `docs-only`. The composed schema in `.github` narrows `workload.scope` to exactly these four for the review domains; a body whose scope class does not parse yields no row, which `pr_body_check.py` has already made red.
    - Any change to a derivation in this list changes what a row means and **writes a fence** (ADR-086 §E.20) before the first row under the new derivation lands.
14a. **The instruction files the runner reads come from the base branch, not the pull request's head**, whenever the pull request's author is not a member of the organisation. The produce job restores `AGENTS.md`, `.agents/**` and every provider adapter (`.claude/**`, `.codex/**`, `.cursor/**`, `.gemini/**`) from the merge base before the runner starts; a pull request from outside that touches those paths is reviewed by a human before any runner reads it. Today every pull request is the maintainer's and this costs nothing; the rule is written now because it matters exactly when the §E.26 trigger fires and there is no time left to write it. `agents-md-schema.md` rule 8 is the reasoning: instructions an agent follows are pinned and reviewed, and a head-branch `AGENTS.md` from a stranger is neither.
15. **Rows reach the inbox as pull requests, not as pushes.** The capture step commits rows to a branch of `exeris-ai-execution` (or the enterprise sibling, by §C.17) and opens one pull request per source repository per UTC day, titled in commit grammar and naming the humans whose pull requests produced the rows. The inbox validator of ADR-086 §G.33 is the required check on that pull request — which is what "reported back to the producer" means operationally — and it is fail-closed over the whole pull request: one invalid file is red for the batch. That is not how an invalid row stops good ones, because **the producer runs the same validator before it opens the pull request**, and a row that fails there never enters the batch: it is kept as a workflow artefact and an issue is filed in the *source* repository, keyed like §D.21 and naming the pull request's author, so that the defect is fixed at the producer (`error-handling-and-fallback.md` rule 4) rather than quarantined in the dataset. The inbox holds rows; quarantine is a producer-side state. Merge is human until the daily volume makes that a cost, at which point auto-merge on a green validator is decided by amendment, not by default.
16. **A review-domain run record is complete when the review ends, and its outcome is `UNKNOWN`** (ADR-086 §D.15, §C.12a). Everything the record needs — model reference, execution counts, the execution-log artefact's digest — exists at that moment and is written then. When the pull request closes, a `pull_request: closed` workflow appends a **judgement record** keyed by that `run_id`: `oracle: review-disposition`, the per-finding dispositions read from the pull request's history, `outcome: UNKNOWN` (the oracle is observational and uncalibrated, and the schema says so by construction). The run record is never touched, no artefact has to outlive the pull request, and a pull request that closes after the run record's `run_id` can no longer be resolved — the inbox pull request was never merged, say — yields a judgement the validator rejects, which is the producer's defect to fix, not a gap to hide.
17. **Visibility is recorded at capture time, fail-closed** (ADR-086 §F.28): the platform's visibility value is read in the same job; only `PUBLIC` maps to `public`, everything else — including `INTERNAL` — to `enterprise-private`, and the row is routed to the matching inbox.

### D. Cross-repo obligation

18. **On merge to the default branch of an upstream repository, if the compatibility gate reports a change on a listed surface, the bot files one issue per downstream repository.** The signal is the report ADR-065 already trusts — japicmp for Java, the api-extractor or tool-surface golden for TypeScript (ADR-085 §F.21c) — never a path glob, except where an upstream module produces no report in CI yet; there the path filter is the stated interim, and the map says so per row.
19. **The map is one static file** (`.github/downstream.json`): one row per upstream surface → the downstream repositories that must adopt it. The first rows are the chain that motivated this: `exeris-kernel` SPI → `exeris-sdk`, `exeris-spring-runtime`, `exeris-kernel-enterprise`; `exeris-sdk` annotations → `exeris-tooling`, `exeris-platform`. Adding a row is a pull request to `.github` with the `cross-repo` label.
20. **Every issue names its human.** The body opens with the merged pull request, its author and the person who merged it; the bot is the pen. ADR-085 §I.30 speaks of agents, and this workflow is deterministic — the rule's spirit is honoured anyway, because the first automated issue without a human name is how the rule erodes.
21. **Idempotent.** The issue is keyed `<upstream-repo>#<pr>/<downstream-repo>` in its body; a re-run of the merge workflow finds the key and files nothing. Labels: `cross-repo`, `triage`.
22. **It carries its own exit.** At the first quarterly audit after it is enabled, the issues it filed are counted by disposition. If they were closed without work, the map shrinks or the workflow is removed; the criterion is written here so that the decision is not left to taste.

### E. What the bot does not own

23. **No judgement.** The bot never reads a diff, never runs a model, never adds, removes or reorders a finding. A change that makes it do so is out of bounds.
24. **No interpretation.** No aggregation across rows, no comparison, no recommendation — ADR-086 §B.5 applies to the bot's comments and logs as it applies to the layer's reports.
25. **No routing of people.** No mentions, no area labels, no ageing of real work beyond what `issue-hygiene.yml` already does for `needs-reproducer` and `needs-evidence`.
26. **No commands.** `/integrate`-style command surfaces, triage by regex and stale-closing of pull requests are deferred until there is a second maintainer to route to. The trigger is written: an external pull-request stream that the maintainer cannot route by hand within a week. Not before.
27. **No rules.** The label mapping and the downstream map are the only two rule-shaped files the bot owns; both are checked by `.github`'s own `guardrails.yml`; neither restates anything a standard says (ADR-085 §I.29). A third such file is a review-time question, not a default.

## Consequences

### ✅ Positive Outcomes

- **[+] `hard-block` blocks.** For the first time a `[HARD BLOCK]` finding is a red required check, and a runner that never ran is red too.
- **[+] The organisation owns its review history.** A provider swap changes a footer, not a byline, and the label semantics do not move.
- **[+] The model-running step has read-only reach.** Publication moves to a step that runs no model, so `pull-requests: write` leaves the one step that executes generated commands.
- **[+] Every L2 run in CI becomes a row** — the cheapest, most regular source ADR-086's V0 has, in exactly its domain, with its oracle's state on the row, without touching the vendored bundle.
- **[+] CI becomes a paired-run machine.** A `runner:` matrix over the same pull request at the same SHA is a declared group with a real oracle for the cost of one workflow — the first paired collection ADR-086 §D.18 can plan.
- **[+] The SPI → SDK → Tooling chain leaves one person's head**, at the moment the obligation becomes real, keyed so it cannot double.

### ⚠️ Trade-offs

- **[-] A standing credential in a solo organisation.** Scoped, per-job minted, expiring and rotated by dated amendment — and still the largest new attack surface this ADR introduces. It is not described as small.
- **[-] Every pull request gets a bot comment.** It replaces one the provider's App already posts, and a `PASS` is one line; but it is a comment on every pull request in a solo repository, and the routines are held to brevity for that reason.
- **[-] Two verdicts on some pull requests** until `agents-md-schema.md` decides one routine or two. The bot makes either work; it does not decide.
- **[-] Two more rule-shaped files in `.github`** — the label mapping and the downstream map — with the standing pull toward a third.
- **[-] Inbox pull requests are toil** until §C.15's threshold is met, and the threshold is deliberately not pre-set.
- **[-] Rows whose runner cannot supply a snapshot or a hash are not captured at all.** That is the honest reading of ADR-086 §C.13, and it means some runners produce no rows until their actions expose what a row needs.

### ❌ Alternatives rejected

- **Keep the provider's identity** (leave publication inside the runner's action) — makes the provider the author of the organisation's review history and forces `pull-requests: write` onto the model-running step to get labels at all. Zero cost now; the byline cost is paid at the first swap.
- **A machine-user account with a fine-grained PAT** — a non-expiring token on a phishable account, a second human seat, and automation that reads as a person, which misleads on provenance.
- **Pull-request-body-only cross-repo obligation** (a `Cross-repo:` section checked by `pr_body_check.py`) — records the obligation where nobody looks for open work; nothing ages it, nothing counts it, the monthly audit cannot see it (`issue-conventions.md` rule 6).
- **Pull-request-time cross-repo issues** (the Quarkus shape) — routing to nobody, with an issue to close for every reworked pull request.
- **A hosted bot in the `quarkus-bot` shape** — a fifth thing to keep alive for one maintainer, solving a scale problem the organisation does not have.

### 📋 What is NOT in scope

- **The routines' content** — `docs-guardrails-review.md`, `docs-pr-review.md` and their successors. The bot publishes what they emit; it does not say what they check.
- **The run record's shape** — ADR-086 §C. This ADR fills it; it does not define it.
- **The inbox validator** — ADR-086 §G. It is the required check on §C.15's pull requests; it is not the bot's.
- **One routine or two** — `agents-md-schema.md`.

### 🚫 Non-Goals

- **Replacing review.** The bot is transport from a verdict to its consequences. A human still reads the review, and ADR-085 §I.30's accountability is unchanged.
- **A router, or a step toward one.** The `runner:` seam is where one *could* attach at V4; designing the seam for that is deliberate, naming it that is forbidden.
- **Scale features** — triage, lifecycle, commands — for a contributor base that does not exist yet.
- **Completeness of capture.** A runner that cannot be captured honestly is not captured; the layer prefers a gap it can see to a row it cannot trust.

### ⚠️ Risks and Assumptions

- **Assumes:** the runner's action exposes an execution log with model id, snapshot, turns, tool calls and usage — *unverified until one real run*; the action honours the checkout's `.claude/settings.json` hooks, which decides whether the L0 dispatcher fires in CI at all (if it does, ADR-086's sink has a CI transport for free in the same artefact; if it does not, nothing here breaks, but the "one emitter" account of the sink is wrong and ADR-086 §H.36 must say which transport is real); a runner can be confined to writing one file at one path; `actions/create-github-app-token` remains available to organisation workflows.
- **Reversed by:** cross-repo issues closed without work for a quarter — §D.22 removes 3A; a provider whose action cannot be split into produce and publish — the fallback of §B.10 becomes the contract for that provider and the ADR says so by amendment; a compromise of the App key — rotation, a fence on every `ci:` row (the fingerprint key rotates with it), and a re-reading of §A.2's trade.
- **Risk:** the bot becomes the third home for rules — the pull will exist on every review that finds something CI could have caught. §E.27 is the answer every time, and `.github`'s own `guardrails.yml` checks the two files it may have. The founder notices first, which is the problem ADR-086 names too.

## Cross-references

- [ADR-086](ADR-086-bound-the-ai-execution-layer-to-observation-before-routing.md) — the layer this bot produces rows for; §C.13 (field definitions), §D.15 (closed-PR rule), §F.28 and §F.31 (visibility mapping, `ci:` fingerprints), §G.33 (the validator that gates §C.15).
- [ADR-085](ADR-085-documentation-architecture-and-repo-hygiene-standards.md) — §C.11 (`.github` as the home of shared enforcement), §E.16 (scope class), §I.29–30, §J.33 (amended by this ADR's Engineering Protocol 6).
- [ADR-065](https://github.com/exeris-systems/exeris-kernel/blob/main/docs/adr/ADR-065-spi-compatibility-gate.md) — the compatibility report §D.18 trusts.
- `exeris-agents/bundle/schemas/verdict.base.schema.json` — the output contract; `agents-md-schema.md` rule 13 (one verdict shape for every reviewing role).
- `exeris-agents/bundle/policies/agent-safety-and-autonomy.md` §1, `error-handling-and-fallback.md` rule 1 — the human-in-the-loop and honest-reporting rules §B.9 and §D.20 carry into CI.
- `exeris-systems/.github` — `docs-review.yml`, `labels.yml`, `labels-sync.yml` (the credential principle §A.2 departs from, and why), `caller_permissions_check.py` (every new permission propagates to `caller-example/*.yml` and is checked there).
- `exeris-docs/standards/issue-conventions.md` rule 6 — why a merged pull-request body is not a tracker.

## Engineering Protocol

1. **Register the two Apps** of §A.1 — `exeris-bot` organisation-wide, `exeris-inbox` on the two inbox repositories only; store both private keys as organisation secrets; add `EXERIS_FINGERPRINT_KEY`. Record the three dates under `## Amendments` as the rotation baseline. Registration needs organisation-admin rights and a browser; nothing before it needs a token — the composed schema, the label mapping, the routine amendment and the produce→publish split (items 2–3) land first, by pull request, and run under the provider's identity until the Apps exist.
2. **Split `docs-review.yml`** into produce and publish; add the composed verdict schema with `tag`, `labels-from-verdict.json`, and the publish step's mutation suite to `.github`'s own `guardrails.yml` beside `caller_permissions_check.py`: absent verdict → red; invalid verdict → red; `BLOCKED` → `hard-block` + red; `PASS` after `BLOCKED` → label removed + green; mandatory `not-run` → published + not green; deterministic skip → green, distinguishable; a row with `exeris-bot` in `agent.*` → refused; the same merge event twice → one issue. Update `caller-example/guardrails.yml` and its permission block; `caller_permissions_check.py` gates the rest.
3. **Amend `docs-guardrails-review.md`** with the verdict-file closing requirement, so both routines meet the bot at one shape.
4. **One real run before the capture step is enabled**, answering the two assumptions: does the action expose the execution log, and do the checkout's hooks fire. Record both answers in ADR-086 §H.36 by amendment.
5. **Enable capture** only after ADR-086 Engineering Protocol 2 (repository on GitHub, validator, `inbox.json`) — a row with nowhere valid to land is not captured.
6. **Amend ADR-085 §J.33**: the L2 routine text lives in `.github` (already true since `docs-review.yml`), and its execution and publication contract is this ADR. The "Claude Project document maintained outside the git repositories" sentence is marked, not deleted.
7. **Cross-repo (§D)** is enabled last, after the `[CROSS-REPO]` inventory of which upstream modules produce a compatibility report in CI, so that `downstream.json`'s first rows are report-gated and the path-filter interim is the exception.
8. **Stubs:** `docs/adr/ADR-087.link.md` in `.github`, `exeris-agents` and `exeris-ai-execution`; accepted ahead of the stubs under `adr-conventions.md` rule 5's `[L2]` gate, tracked as `[DOC DEBT]`.
9. **Registry:** reserve row 087 in `adr-index.md` *before* this file merges (rule 2); the accepting pull request points the row here, carries the `adr` label and `Refs: ADR-087`.
10. **Review-time assertions this ADR adds** (L2): a workflow that grants the produce job any write scope → `[HARD BLOCK]`; a bot-authored issue without a named human → `[HARD BLOCK]`; a row whose `agent.*` names the publisher → rejected by the mutation suite, and a producer that works around it → `[HARD BLOCK]`; any text under the bot's ownership that names a model as appropriate for a workload → `[HARD BLOCK]` before ADR-086's V3.
