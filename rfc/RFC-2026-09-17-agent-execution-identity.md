---
title: "RFC-2026-09-17: A provider-agnostic agent execution identity (`exeris-agent`) — the third App, the second producer, and what the record can honestly say about who acted"
type: rfc
visibility: public
owning-repo: exeris-docs
status: draft
---

# RFC-2026-09-17: A provider-agnostic agent execution identity (`exeris-agent`)

| Field             | Value |
|:------------------|:------|
| **Status**        | **DRAFT** (v2, re-based 2026-09-17 on ADR-086 and ADR-087 as accepted 2026-09-15 with their amendments through 2026-09-17) |
| **Author(s)**     | Arkadiusz Przychocki (options analysis assisted by Claude) |
| **Date Opened**   | 2026-09-17 |
| **Date Closed**   | — |
| **Target ADR(s)** | ADR-AGENT-ID (new; number to be reserved); amendments to **ADR-085 §I.30**, **ADR-087 §A.1/§A.3/§B.8-door/§C.14a/§D.20** and **ADR-086 §C/§F.31** (see companion draft) |
| **Affected Repos**| `exeris-docs` (`standards/ai-provenance.md`, `agents-md-schema.md`), `exeris-systems/.github` (`publish_verdict.py`, `pr_body_check.py`, rulesets), **new** `exeris-agent-harness`, `exeris-agents` (hook wiring only), `exeris-ai-execution` (the fields of ADR-086's 0.2.0 MINOR, one record kind, one fingerprint class), `exeris-ai-execution-enterprise` (task registry), every code repository (App installation + ruleset) |
| **Reviewers**     | — |

## Question

ADR-087 gave the organisation a provider-neutral *publisher* (`exeris-bot`, the voice) and a *row writer* (`exeris-inbox`, the pen). Neither can author code: the voice holds no `contents` scope by design, the pen writes only to two data repositories. So every commit an agent produces in an interactive session — the bulk of the work, as against the L2 reviews ADR-087 captures — still lands under the maintainer's GitHub identity, and the record ADR-086 keeps cannot tell a run the maintainer executed from one the maintainer steered from one an agent executed alone. ADR-086 §D.15 already says why that matters: `review-disposition` is observational because "the judge is the maintainer on the maintainer's own pull request"; the same person is also, on GitHub, the *author* of every pull request the agent wrote.

This RFC settles eight coupled questions (six of design, two — Q7, Q8 — that began as spikes and became decisions with a verification step): **(Q1)** name and placement, given `exeris-agents`, `exeris-ai-execution`, `exeris-ai-bridge` and now `exeris-bot`/`exeris-inbox`; **(Q2)** which GitHub principal carries the identity, inside ADR-087's rule that an App's permissions are one set for every repository it is installed on; **(Q3)** the accountability model — ADR-085 §I.30, ADR-087 §A.3 and §D.20 all say the human *author* is accountable and agents open nothing without one; **(Q4)** what the run record gains and what stays out of it, under ADR-086 §C.9's SemVer and §C.12's metadata-only rule; **(Q5)** whether the harness wraps vendor CLIs or runs its own loop; **(Q6)** how "what the agent may not do" is expressed — and two places in ADR-087 where the current door is open to an App principal.

Template deviation, stated up front: six questions in one RFC because they constrain each other and produce one ADR plus three amendment sets.

## Context

Facts the options must respect — cited to the accepted records, not to the earlier draft of this RFC:

- **ADR-087 §A.1**: two Apps, split by *what they may write*, because App permissions are one set per installation: `exeris-bot` (`pull-requests: write`, `issues: write`, no `contents`), `exeris-inbox` (`contents: write` on the two inbox repositories only). §A.2: keys are organisation secrets, tokens minted per job. **Alternatives rejected** there: a machine-user account with a PAT ("a non-expiring token on a phishable account, a second human seat, and automation that reads as a person"). This RFC does not reopen that rejection.
- **ADR-087 §A.3, §D.20, Non-Goals**: the bot is publisher, never reviewer; "ADR-085 §I.30's human accountability attaches to the pull request's author as it does today"; every bot-filed issue names its human. An App that *authors* pull requests changes what "author" means in those three sentences.
- **ADR-087 amendment 2026-09-17 (the door)**: a person greens the required check by applying `l2-human-reviewed`; the publication records who applied it and at which commit; "the label, which anyone can re-apply". The clause does not say the applier must be a human principal.
- **ADR-087 amendment 2026-09-16 (readiness)**: the review runs on `opened`, `reopened`, `ready_for_review` and a human-applied label; `issue_comment` was rejected as a trigger for permission reasons; "the bot never applies the request label, so it cannot trigger itself".
- **ADR-087 amendment 2026-09-15**: App-token events start workflow runs; the runner **refuses a non-human actor** (measured: a run triggered by `exeris-bot` failed in the produce job and the publication replaced a real verdict with "no verdict"). A pull request opened or pushed by an App principal therefore triggers a review that cannot run under that actor.
- **ADR-087 §C.14a**: for a pull request whose author is not an organisation member, the produce job restores `AGENTS.md`, `.agents/**` and every provider adapter from the merge base. An App principal is not a member.
- **ADR-086 §C.9–14, §C.12a**: `run-record.schema.json` is the contract; new optional field MINOR, new required field or enum change MAJOR; **metadata only** — prompts, file content and tool arguments never appear, `execution.event_stream` is a reference; `accounting.mode ∈ api | subscription | local`; model reference is `id + snapshot + harness + system-prompt hash`; later verdicts are **judgement records**, never edits. Amendment 2026-09-17: `model_snapshot` may be `unresolved:<model_id>`; a usage-ledger model with no turn is instrument, not agent.
- **ADR-086 §D.15**: admitted domains and oracles — `docs-sweep`, `docs-review-calibration`, `docs-review-live`, and "any construction domain → `scb`" whose calibration is not run, so every construction row is `UNKNOWN` today. Fail-closed is the rule, not a gap.
- **ADR-086 §F.31–32**: `workload.fingerprint` has exactly two classes — `reg:` (assigned by the private task registry when a task is planned) and `ci:` (SHA-256 over repository, PR number, head SHA — key dropped by ADR-087's 2026-09-17 amendment). The registry lives in `exeris-ai-execution-enterprise`, ordered after the first CI rows (Engineering Protocol 4).
- **ADR-086 §A.2**: `exeris-agents` gains a telemetry sink and no runtime; payload and version deferred (§H.36) until CI rows show what a run needs from the local dispatcher.
- **ADR-085 §I.29a / §J.31a** (2026-09-08): the agent layer is vendor-neutral at the instruction layer; L0 hooks act before a commit exists. §I.30 is unchanged since 2026-09-04. §G.26a: records carry no figures — RFCs are exempt.
- **Provider terms**: consumer subscriptions are usable only through the vendor's own client; a harness may launch `claude`/`codex`/`gemini` under one and may not extract or proxy their credentials. Organisation API keys have no such restriction. `accounting.mode` already names the split.
- **GitHub mechanics** (docs.github.com, 2026-09-17): required-review rules count approvals from *people with write or admin permissions*, Copilot's shown but not counted; an App holds no signing key, commits it creates through the API are GitHub-signed, local pushes under its token are not; installation tokens live one hour.
- **Working reality**: one maintainer, several parallel vendor-CLI sessions in one shell, all inheriting `gh auth` and `~/.gitconfig`; commits from the Cowork surface already carry a provider-specific `Claude-Session:` trailer that nothing consumes.

The cost of leaving this open is now specific: ADR-086's dataset has one producer (CI reviews), its construction domain has no rows, and the rows it could get from interactive work would name the maintainer as the actor on every one of them.

## Investigation

### Prior art

- **ADR-087 itself** is the nearest prior art and the shape to extend: one App per *write capability*, provenance in a footer that survives a provider swap, the human named in what automation files. The gap is that neither App may write code.
- **Skara / `quarkus-bot`**: project-owned bot identities, never vendor-owned; the naming lesson transfers, the hosted-service shape does not (ADR-087 already rejected it).
- **`github-actions[bot]`**: a non-person principal whose approvals never satisfy a required review and which cannot be a code owner — the boundary Q6 wants, obtained from the principal's *type*.
- **Git trailers as grammar** (ADR-085 §D.15): `Exeris-Run:` is the same mechanism as `Refs:` and `Claim:`.

### Constraints

- ADR-086 owns the record; this RFC may propose MINOR additions and a new record kind, never a second schema for the same thing.
- ADR-087 owns producer-side derivations and the publication path; a second producer follows its §C.14 rules or records no row.
- ADR-087 §A.1's principle: a capability boundary is drawn by *which App*, not by which repository an App is installed on.
- Metadata only (ADR-086 §C.12); fail-closed (§E.19); no `mode`-like field the model could declare.
- One maintainer; nothing in V0 needs a second human to operate.
- Developer tooling tier (ADR-025 precedent), Apache-2.0.

### Data gathered

| Fact | Value | Source |
|:--|:--|:--|
| Approvals that satisfy required reviews | people with write/admin; Copilot approvals shown, not counted | docs.github.com, *Approving a pull request with required reviews* |
| App commit signatures | API-created commits GitHub-signed; local pushes under App token unsigned; Apps hold no key | github.com/orgs/community/discussions/50055 |
| Runner behaviour under an App actor | produce job fails, publication reports "no verdict" | ADR-087 amendment 2026-09-15 |
| Instruction-file source for non-member PR authors | merge base, not head | ADR-087 §C.14a |
| Who may green the required check without a review | any principal that can apply `l2-human-reviewed`; type not checked | ADR-087 amendment 2026-09-17 |
| Fingerprint classes admitted | `reg:`, `ci:` | ADR-086 §F.31 |
| Accounting modes | `api`, `subscription`, `local` | ADR-086 §C.14 |
| Existing provider execution-id trailer | `Claude-Session: <url>` | commit history |

### Spike outcomes

S3 was executed against the checkout on 2026-09-17 and answered worse than the question assumed. The draft-then-ready flow does not fail to review — it **greens without a review**: `docs-review.yml` skips the produce job when the pull request's *author* login ends in `[bot]` (line 171) and reports skip kind `draft-or-bot` (line 481), and `publish_verdict.py` lists `draft-or-bot` beside `fork` in `ABOUT_THE_PULL_REQUEST`, the set of skips that are green on their own (line 53). A pull request's author is `exeris-agent[bot]` for its whole life; the ready click changes the state, not the author. So after the click: produce skipped, skip kind `draft-or-bot`, required check green, nothing read. The click works as provenance; the author test does not work as a gate. The finding is RFC-bound and is resolved in Q6 below by moving the test from the author to the sender and splitting the skip kind. What the same measurement could not close: a machine user — a `User` principal holding a token — is indistinguishable from a person by type; telling them apart needs a list of people the organisation does not keep, and the routine and the docstring now say so. Verified by `publish_verdict_suite.py` at 124 cases (117 before) plus a `principal_check.py` that reads the expressions the workflow ships; reverting each rule alone fails only its own cases.

S1 and S2 are re-cast as decisions with a verification step each (Q7, Q8): the design consequence of every possible outcome is fixed before the measurement, so the measurement closes a row rather than opening a question.

## Options Considered

### Q1 — Name and placement

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Identity and repo both `exeris-agent`** | Shortest | `exeris-agent` beside `exeris-agents` is a routing error waiting to happen; a repo named "agent" that holds no agent semantics |
| **B. Identity `exeris-agent`, repo `exeris-agent-harness`, bundle `exeris-agents` unchanged** | The actor name is what GitHub shows; the repo name says what the code does; the bundle keeps its name and its vendored-file property | One more sibling repository |
| **C. Inside `exeris-ai-execution`** | One repo fewer | Puts credential minting next to the dataset — the opposite of ADR-087 §A.1's split |
| **D. Inside `exeris-agents`** | The dispatcher is there | A credential-minting CLI in a tree vendored into every repository |
| **E. Inside `exeris-systems/.github`** (where `exeris-bot`'s steps live) | Same home as the other two Apps | `.github` is consumed at `@main` with no version (ADR-085 amendment 2026-09-08's reason for moving the bundle out); a launcher people run locally needs a pin |

`exeris-agent-runtime` dropped: "runtime" is the kernel's word.

### Q2 — GitHub principal

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Third App `exeris-agent` — the *hands*: `contents: write`, `pull-requests: write`, `metadata: read`; installed on code repositories, never on the inbox repositories** | Extends ADR-087 §A.1's taxonomy with its own rule (one App per write capability); no seat; one-hour tokens; not a member, so the review-type exclusion applies by construction and §C.14a *binds* — it is not yet implemented, and until it is the author skip keeps the App's pull requests away from the runner; a compromise can push a branch and open a PR and cannot merge over a ruleset, cannot write a row, cannot speak as the publisher | Local pushes unsigned; cannot mint tokens for external maintainers |
| **B. Machine user** | Signs locally | Rejected by ADR-087 for reasons that hold here unchanged |
| **C. Reuse `exeris-bot` with `contents: write` added** | No third App | Exactly the "single App carrying `contents: write` everywhere" ADR-087 §A.2 admits only if the ADR stops calling its scope minimal; the voice would become able to write code |
| **D. Fine-grained PAT on the maintainer's account** | Zero setup | The maintainer's identity in a costume |

### Q3 — Accountability

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Keep "author" in ADR-085 §I.30, ADR-087 §A.3/§D.20** | No amendment | The App is the author of what it executes; either the sentences become false or the App may not author |
| **B. Accountability = named `Owner:` on every App-authored PR, gated by `pr_body_check.py`; the sentences are amended to say *owner* where they say *author*** | Keeps the substance ("accountable for every line, able to defend it in review"); makes it a gate, not a request; ADR-087 §D.20's "every issue names its human" is the same rule already in force for issues | Three records amended; ADR-087 Non-Goals' "unchanged" sentence marked |
| **C. App-authored, no owner** | — | Nobody accountable; contradicts §K.35a's Covenant line |

### Q4 — What the record gains

| Option | Pros | Cons |
|:--|:--|:--|
| **A. A bespoke provenance artefact** (the earlier draft's in-toto Statement with `events[]`, `mode`, `human_interventions`) | Self-contained | A second owner of what ADR-086 §C.9 already owns; `events[]` with prompts is content under §C.12; `mode` is model-declarable |
| **B. Two MINOR optional fields on the run record + one new record kind + one fingerprint class, all in `exeris-ai-execution`:** `execution.principal {kind: app\|user, login}` (the authenticated GitHub identity the harness acted under); `execution.human_prompts` (count of `UserPromptSubmit`-class events after the first, harness-observed, a count not a text); a **provenance record** (`schemas/provenance-record.schema.json`, one per pull request, keyed to the run ids that touched it, written by the closed-PR workflow ADR-087 §C.16 already runs: per commit the SHA and whether a run record claims it; per review the principal type and state; per label the applier's principal type; `merged_by` type) from which the human/steered/agent/modified classes are **derived at analysis time**; and a `reg:`-only obligation for harness runs (Q4′) | One owner; no model claim anywhere; judgement records stay oracle-only; the classes ADR-086 §D.15 needs for the review domain fall out of the same file | Three schema PRs before the first harness row |
| **C. Put the principal in `agent.*`** | No new fields | ADR-087 §A.4 forbids it for the publisher and the reason holds: the principal is not the agent |

**Q4′ — fingerprint for interactive runs.** ADR-086 §F.31 admits `reg:` and `ci:`. An interactive run is neither observed by CI nor, today, planned in a registry. Options: require every `exeris-agent run` to carry `--task reg:<id>` (the registry becomes a precondition, which is what §F.32 wants anyway); or admit an `adhoc:` class that the validator refuses to join to anything. Recommendation: `reg:` required, `adhoc:` as an escape that carries the non-joinable marker — an unplanned run is capturable but never paired.

### Q5 — Harness mode

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Wrapper around vendor CLIs** | ToS-clean under subscriptions (`accounting.mode: subscription`); reuses vendor loops, sandboxes and hooks (`exeris-agents` dispatcher fires locally — the L0 layer ADR-085 §J.31a already defines, and the "do hooks fire" question ADR-087 EP4 leaves open for CI is answered *yes* for this producer) | Capture depth bounded by each vendor's hook surface; `capture_level` must say so |
| **B. Own loop over provider APIs** | Uniform capture; what V3+ eventually needs | Only under `api` mode; an agent framework for one maintainer; ADR-086 defers routing on purpose |
| **C. A now under an `exeris-agent run` contract that B implements later as an executor** | Identity and record contract are the same in both | Contract must not leak CLI shape |

### Q6 — Capability boundary, and two doors ADR-087 leaves open

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Instruction in `AGENTS.md`** | Zero infra | The mechanism that has failed; ADR-085 §I.29 forbids restating what CI enforces anyway |
| **B. Capability absence** — the App's permission set; every code repository under one ruleset (*require PR*, *no bypass actors — the maintainer included*, *required approvals* switched on the day a second maintainer exists and off until then), `CODEOWNERS` humans only; **the human-verification requirement for App-authored pull requests lives in the required check** (`publish_verdict.py`): a pull request whose author is a `Bot` principal is green only when an approving review or the `l2-human-reviewed` label exists from a `User` principal — a condition a ruleset cannot express because it depends on the author, and a required check can; **plus three closures**: (i) the door greens only from a `User` sender, never a `Bot`; (ii) the readiness label and the readiness events start a review only from a `User` — the rule ADR-087 states for `exeris-bot` by policy, now checked by type; (iii) **`draft-or-bot` splits in two, and the author test moves to the sender only once §C.14a is implemented**: `draft` stays a green skip (a draft cannot merge, so the state is stated, not inferred); `bot-authored` hands the colour to the standing verdict — red when there is none (`.github#62`, merged 2026-09-17); and the `[bot]` *author* test in the produce job stays until the merge-base restore of `AGENTS.md`, `.agents/**` and the provider adapters for non-member authors (ADR-087 §C.14a) exists — `docs-review.yml` says in so many words that the author test is what holds §C.14a's trigger closed, and an App is a non-member. In the same change that implements the restore, the author test goes and `bot-event` (a Bot *sender*) becomes the only bot-related skip; until then an execution-identity pull request is reviewed by a human through the door, never by L2, and produces no `docs-review-live` row — a stated gap, not a green one; **plus**: the harness opens pull requests as **drafts**, and only a human marks them ready | The agent identity is structurally unable to produce "a human verified this" in any of its three forms (approval, door label, readiness); no bypass exists to be used routinely; a solo maintainer's own human-authored pull requests pass on a clean verdict as today, and the second maintainer flips one ruleset switch, nothing else | The check, not the ruleset, carries the author-conditional rule — so `publish_verdict.py`'s mutation suite gains the cases (Bot author + no human event → red; Bot author + Bot approval → red; Bot author + User approval → green; User author + clean verdict → green) |

### Q7 — What the ruleset adds beyond the check, and what `pull-requests: write` leaks (formerly spike S1)

The human-verification rule for App-authored pull requests lives in the required check (Q6-B), so the question is no longer whether the model stands; it is what a ruleset adds as a second line, and which capabilities `pull-requests: write` hands the execution identity that the check must notice. Five facts to establish on a throwaway repository, each with its design consequence fixed in advance so the spike closes rather than opens:

| # | Fact to establish | Expected | If so | If not |
|:--|:--|:--|:--|:--|
| S1.a | An App's approving review counts toward *required approvals* | no (docs: people with write/admin; Copilot excluded by name) | the ruleset alone protects nothing; S1.b is mandatory | ruleset and check are two independent lines |
| S1.b | *Require review from Code Owners* is enforceable with required approvals at 0 | unknown | an App cannot appear in `CODEOWNERS` (users and teams only), so the rule is insensitive to S1.a — but it blocks a solo maintainer's own pull requests, so it switches on with the second maintainer | nothing lost; the check remains |
| S1.c | An App can **dismiss** a human's *changes requested* review | yes (dismiss-review API under `pull-requests: write`) | a capability leak: rulesets have no *restrict who can dismiss* (classic branch protection only) → the check is red on a `review_dismissed` timeline event whose actor is a `Bot`, and `exclude_pushers` keeps the dismisser from counting as a reviewer | nothing |
| S1.d | An App can merge once rules pass | yes (`contents` + `pull_requests` write) | consistent with the T7 step of the earlier analysis; `merged_by: app` in the provenance record; **the capability boundary is at approval, not at merge** — GitHub has no "write without merge" short of a bypass list, which Q6 rejects | the human clicks merge; acceptable, worse for cost-to-TRUE_DONE |
| S1.e | An App push after approval invalidates it (*approval of most recent reviewable push*) | yes | the agent cannot ride commits in behind a review; the one ruleset rule that is useful from day one because it needs no approval to exist | the check compares the approval's SHA with head, as ADR-087 §B.8 already does for the verdict |

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Ruleset as second line** — *required approvals*, *code owners*, *most recent push*, switched on with the second maintainer except S1.e, which is on from day one | GitHub-native, independent of the organisation's own code | unavailable solo; blind to S1.c |
| **B. Check as the line** — Q6-B as written, plus red on `review_dismissed` by a `Bot` | works solo; author-conditional; mutation-tested | it is code, not absence — a regression in `publish_verdict.py` is an open door |
| **C. The human opens the pull request, the App only pushes** (no `pull-requests: write`) | the App can neither approve, dismiss, label nor merge — pure absence | the pull request's author is the human again, and ADR-085 §I.30(b) loses its subject; one more click per task |
| **D. Two Apps for the hands** | — | opening a pull request *is* `pull-requests: write`; there is nothing to split |

### Q8 — Isolating the launched vendor CLI from the maintainer's credentials (formerly spike S2)

The threat is not a malicious agent; it is a model that finds a working credential and uses it. Environment overrides (`GH_TOKEN`, `GIT_CONFIG_GLOBAL`, `GH_CONFIG_DIR`) change what a CLI *uses by default*; they change nothing about what is *readable from disk* — `~/.config/gh/hosts.yml`, `~/.git-credentials`, the keychain, and above all `~/.ssh`, since an SSH remote bypasses the credential helper entirely. The integration section above said "vendor state untouched"; it did not say "maintainer state unreachable", and those are different properties.

| Option | Isolates | Pros | Cons |
|:--|:--|:--|:--|
| **A. Environment only, plus closures** — `url.https://github.com/.insteadOf git@github.com:` in the run's git config, `GIT_SSH_COMMAND=/bin/false`, isolated `GH_CONFIG_DIR` | the default paths | no infrastructure; every CLI; the vendor login untouched; an hour to ship | the maintainer's files stay readable — isolation by convention; SSH closed, files not |
| **B. A separate OS user** for runs, the vendor login done once under it | file permissions | the maintainer's files are physically unreadable; no `~/.ssh`; still local; build caches shareable by group | a second vendor login (same subscription, different `$HOME` — permitted); IDE-driven agents do not run as another user; per-machine setup |
| **C. A container per run** — worktree and App token mounted, nothing else; vendor login on a persistent volume | everything | strongest; the same shape as the capability principle; gives `execution.tool_surface` (ADR-086 §C.14a) a literal meaning; reproducible | JDK and Maven caches as volumes; vendor OAuth headless (once, device flow); IDEs outside it (VS Code devcontainers yes, Antigravity no) |
| **D. Vendor sandbox** — deny reads on credential paths through the L0 hooks `exeris-agents` already renders | paths, per vendor | no infrastructure; L0 exists | a tripwire, not a proof (ADR-085 §J.31a says so); per vendor; a shell bypasses it unless the vendor sandboxes the shell |
| **E. Remove long-lived credentials from the machine** — short-lived `gh` tokens, SSH on a hardware key with touch | the root cause | independent of the harness; protects against every other process too | a change to the maintainer's own workflow; hardware; the keychain only partly |

## Testing

The RFC proposes one surface that a consumer will implement against — the `agent/*` service — and
two checks that make claims about it falsifiable before V1 freezes it:

- **The surface golden.** `api/agent-surface.json` in `exeris-agent-harness` lists every method,
  its inputs and its outputs; the harness's own gate regenerates it from the implementation and is
  red on any difference, the way ADR-085 §F.21c's tool-surface golden is. A removed method or a
  newly required input is a MAJOR change and is refused without a version bump; an added optional
  input is MINOR. The CLI is the reference client, so the golden is checked against it, not against
  a plugin.
- **The isolation closures of Q8-A**, each a test that fails when its closure is removed: a push
  over an ssh remote fails inside the run environment; the credential helper answers for the
  organisation's host and no other; the shell's own credentials are absent from the run's
  environment; the clone's own configuration cannot override the run's hooks path or credential
  boundary; a commit made in the run's worktree carries exactly one `Exeris-Run:` trailer.
- **The record's own validator**, run by `flush` before an inbox pull request is opened, so a row
  the harness assembles is checked against `exeris-ai-execution`'s schema and cross-file rules by
  the same code the inbox runs, never by a copy.

What cannot be tested before implementation: whether a vendor's session log exposes enough for
`capture_level: full` on a given runtime, and the Q8 count of L0 denials on credential paths — both
are the harness's first readings, not its preconditions.

## Recommendation

**Q7: A and B together, C rejected on authorship, S1.e on from day one; the spike is one evening on a throwaway repository — five actions by the App (approve, dismiss, merge before and after a human approval, push after approval) against the five-rule ruleset. Q8: A and D for V0, stated honestly as convention plus tripwire, with a measurement that decides the next step: the count of L0 denials on credential paths over the first runs — zero after a reasonable number and C waits; more than zero and C is V1 for CLI-launched agents, because the "hmm, I probably can" has then been observed rather than assumed. B is the fallback if C proves too heavy for JVM builds. E is hygiene independent of everything here and is recommended regardless.**

**Q1: B. Q2: A — `exeris-agent` is the third App, the *hands*, on the same principle as the other two. Q3: B — *owner*, gated. Q4: B and Q4′ — two optional fields, a provenance record, `reg:` required with a non-joinable `adhoc:` escape; nothing stored that a model could declare. Q5: C. Q6: B — including the two `publish_verdict.py` closures, which are ADR-087 findings independent of this RFC and should land first.**

**One execution contract, N surfaces.** The HLA's design-time stripe already solves this shape once: `sdk-lsp` defines the protocol, and four surfaces — Studio, desktop, IntelliJ, VS Code — are clients of it (ecosystem map, *Four surfaces, one protocol*). The harness is built the same way from day one, because the same three populations that need it now — maintainers, platform users, marketplace creators — will reach it through the platform's own surfaces later: a CLI, the IDE plugins, and the hosted `exeris.eu` platform.

- **The contract** is a small JSON-RPC service, `exeris-agent serve` (stdio or local socket — the transport `vscode-jsonrpc` and LSP4J already speak), with a handful of methods: `agent/openRun` (task ref, repository, provider → worktree path, bound identity, run id), `agent/event` (hook-observed events in, counted, never stored as text), `agent/closeRun` (push, draft PR, run record), `agent/flush` (inbox batch), `agent/status`. Everything that binds identity, mints tokens, installs hooks and writes records lives behind these methods, once.
- **Surfaces are clients.** *V0:* the CLI, which is the first client of its own service. *V1:* `exeris-ide-vscode` and `exeris-ide-intellij` call the same methods — the "IDE trick" disappears, because the plugin does not wrap the IDE's agent, it asks the harness to open a run and reports what the IDE's agent runtime exposes; an IDE with no Exeris plugin (Antigravity, Cursor today) stays at `identity-only` through the worktree. *V2:* the hosted platform runs the same service server-side, with the organisation's BYO provider credentials and, once ADR-086's V4 conjunction is met, the router filling the slot a human fills today with `--provider` — the same "configuration point, not decision point" clause ADR-087 §B.12 gives the `runner:` input.
- **Not an LSP extension.** `agent/*` is its own service beside `sdk-lsp`, never a method added to the `exeris/*` canonical set: `sdk-lsp` depends on `sdk-model` alone and its scope is the entity model (SDK Wall); the plugins simply hold a second JSON-RPC channel. This keeps the platform review rule intact — any new `exeris/*` method is designed in `sdk-lsp` first — by not needing one.
- **Identity per organisation, contract shared.** The App manifest is published so that a platform customer or a marketplace creator instantiates their own execution identity on their own GitHub organisation (App names are global on GitHub, so it is `<org>`'s instance, not ours); the harness config declares which App login is the execution identity, and the provenance record classifies by declared principal, never by name. What Exeris ships is the manifest, the ruleset, the record shapes and the service — the same for the maintainer's repositories and for a creator's cap repository. A marketplace listing that later requires provenance on a cap release has a record to require.
- **Frozen before V1.** The `agent/*` surface is a gated TypeScript surface under ADR-085 §F.21c's rule: a tool-surface golden, a removed method or required input is MAJOR. The CLI is the reference client; the plugins do not get a second contract.

**Registering the App** (the same shape as ADR-087 Engineering Protocol 1, with two differences named):

- *Name* `exeris-agent`; *owner* the `exeris-systems` organisation; *installable* "only on this account" until the manifest is published for other organisations. No webhook (deactivate it), no callback URL, no user authorisation flow — the App never acts on a person's behalf; it acts as itself.
- *Repository permissions*: `contents: write`, `pull_requests: write`, `metadata: read` (implicit). Nothing else — in particular no `workflows` (a push touching `.github/workflows/**` is refused by GitHub without it, which is the behaviour wanted: the agent cannot change the gate it is judged by), no `administration`, no `members`, no `secrets`, no `checks`, no `issues` (issues are the voice's). *Organisation permissions*: none.
- *Installation*: every code repository; **never** `exeris-ai-execution` or its enterprise sibling — the hands do not hold the pen.
- *Key custody* — the first difference from the other two Apps: their keys are organisation secrets readable only by workflows (ADR-087 §A.2); this App's key must also be **on the maintainer's machine**, because the harness mints tokens locally. It lives in the harness's own directory — `~/.config/exeris-agent/` (0700) holding `config.toml` (client id, installation id, bot user id — none of them secret) and the private key **encrypted at rest** (`age`, passphrase or a local age key), decrypted in memory by `openRun` once per run and never written back; under Q8 option A this is what keeps the key unreadable to an agent running in the same account, where a bare `0600` file would be readable and the L0 deny only a tripwire. The whole directory joins the L0 deny list beside `~/.config/gh/**` and `~/.ssh/**`. The run sees a one-hour installation token, never the key. The organisation-secret copy has its repository access set to none until a CI surface needs to mint (V2).
- *Rotation baseline* — the second difference: ADR-087 records rotation as a dated line per App under its `## Amendments`; this App's line lives in the ADR that accepts this RFC, and the registration date is the baseline.
- *Identity strings for git*: `user.name = exeris-agent[bot]`, `user.email = <bot-user-id>+exeris-agent[bot]@users.noreply.github.com`, where the id is the App's *bot user* id (`gh api /users/exeris-agent%5Bbot%5D`), not the App id — the noreply form GitHub attributes to the App's avatar.
- *Ruleset* applied at the same time, so the App never exists on a repository without the rules that bound it.

What V0 concretely is:

```
exeris-agent-harness/                     developer tooling (ADR-025 precedent), Apache-2.0
├── identity/
│   ├── app-manifest.json                 exeris-agent: contents+pull_requests write, metadata read; no
│   │                                     administration/members/secrets/workflows; not on inbox repos;
│   │                                     published so another organisation can instantiate its own
│   ├── (ruleset lives in exeris-systems/.github, not here — shared enforcement per ADR-085
│   │    §C.11: require PR · no bypass actors, maintainer included · required approvals off (solo)
│   │    / on (second maintainer) · inbox repositories excluded; the harness references it)
│   └── review-policy.json                min_independent_approvals: 0 (solo) | 1 ·
│                                         independent_reviewer: member | committer | codeowner ·
│                                         exclude_pushers: true; any change writes an ADR-086
│                                         §E.20 fence — rows across it never sum
├── core/     the contract: `exeris-agent serve` — agent/openRun · event · closeRun · flush · status
│     openRun:  mint installation token (1 h) → credential helper; worktree per run with
│               worktree-scoped git identity (GIT_AUTHOR_*/GIT_COMMITTER_* = exeris-agent);
│               GH_CONFIG_DIR isolated, vendor config dir untouched (S2); hooks: exeris-agents
│               dispatcher (L0) + prepare-commit-msg adding `Exeris-Run: <ulid>`
│     event:    hook-observed events in; prompts counted, never read
│     closeRun: push branch, open a DRAFT pull request with `Owner: @<login>` and `Exeris-Run:`;
│               write one run record (ADR-086 §C, ADR-087 §C.14 derivations) with
│               execution.principal = {app, exeris-agent}, accounting.mode from the credential
│               class, oracle per domain (construction → scb, not-run → outcome UNKNOWN)
│     flush:    validate, then open the inbox pull request under the human's identity (sign-off)
├── cli/      `exeris-agent run --provider <claude|codex|gemini> --repo <r> --task reg:<id>`
│             — the first client of core/; launches the vendor CLI inside the run's worktree
├── adapters/<vendor>/                    launcher + hook/session-log mapping; nothing else in V0
├── api/agent-surface.json                the golden of the agent/* surface (ADR-085 §F.21c)
└── policy/README.md                      what the credential cannot do — pointing at the manifest and
                                          ruleset JSON, never restating them
```

Surface roadmap, gated on the contract golden, not on dates: V0 CLI → V1 IDE plugins (`exeris-ide-vscode` first, shared TypeScript; IntelliJ over LSP4J's JSON-RPC) → V2 hosted platform with organisation credentials. Nothing in V1 or V2 adds a method a V0 client would not understand.

**Integration with the runtimes in use today.** The harness changes nothing inside a vendor's client; it changes what the client finds when it looks at git and GitHub.

- *CLI-launched agents (Claude Code, Codex CLI, Gemini CLI):* `exeris-agent run` sets `GH_TOKEN` (which `gh` prefers over its stored login), `GIT_CONFIG_GLOBAL` → an agent-only config (`user.name`/`user.email` = the App's noreply identity; `credential.helper` returning `x-access-token:<installation token>` for `github.com/exeris-systems/*` only; `core.hooksPath` → the run's hook directory with `prepare-commit-msg`), and launches the CLI in a **worktree created for the run** with `extensions.worktreeConfig`, so the identity is bound to the tree, not to the shell. The vendor's own state — `~/.claude`, `~/.codex`, `~/.gemini`, where the subscription login lives — is untouched (S2). Vendor co-author trailers (`includeCoAuthoredBy` and equivalents) are switched off for the run: form (b) names the model in the run record, and `Co-authored-by: Claude` on an App-authored commit would mix ADR-085 §I.30's forms (a) and (b). L0 hooks fire from the checkout's rendered adapters (`.claude/settings.json` etc., from `.agents/hooks/hooks.yaml`) — the layer ADR-085 §J.31a already defines; the harness only exports the run id the dispatcher forwards to the sink. Capture reads the vendor's session log (Claude Code's per-session JSONL, Codex's session directory) for `model_id`, turns and tool counts; `model_snapshot` is `unresolved:<model_id>` where the log exposes none.
- *IDE-driven agents (Antigravity, Cursor):* there is no CLI to launch, so identity binds at the worktree — the harness creates it with the same worktree-scoped config and the person opens it in the IDE. Everything committed from that tree is the run's. Capture is `capture_level: identity-only` unless the IDE exposes a session log an adapter has actually read; ADR-085's amendment of 2026-09-08 measured `agy` ignoring repository profiles and exiting 0 on an unknown `--agent`, so no adapter assumes more than it has verified.
- *The author string is a claim; the pusher is the fact.* Nothing stops an agent running `git -c user.name=<the maintainer>` inside its worktree; the commit graph will carry the maintainer's name on a commit the App pushed. The provenance record classifies by the principal that pushed and by the run record that claims the commit, never by the `author` field, and a commit whose author string names a principal other than its pusher is `unattributed` at best — the rule is stated so that nobody later reads `author` as provenance. Q8 does not close this and is not meant to; Q7's S1.e keeps such a commit from riding in behind a review.
- *The worktree is the attribution boundary.* Anything committed inside a run's worktree is that run's, including a line the human types there: that is steering — counted where the runtime exposes prompt events, otherwise invisible, and `capture_level` says which. A modification that should count as *human* is made in the human's own checkout under the human's own identity. Stated so that "I fixed one line in the agent's tree" is neither silently an agent commit nor silently a human one; it is a run commit in a steered run.
- *Vendor-hosted agents* (Codex cloud, Claude Code on the web, Copilot's coding agent) push under vendor identities and are **not producers** under this RFC — they are exactly the `claude[bot]`-shaped identities the organisation declined to build on. Their pull requests are non-member PRs to the rulesets (ADR-087 §C.14a applies) and their rows, if any, are `ci:`-class from the CI producer. Admitting one is an amendment naming how its identity maps.
- *A model switch inside a session* (`/model` and equivalents) ends the run and starts a new one on the same `reg:` task, because `agent.model_id` is singular and names the model that took the turns (ADR-086, 2026-09-17). *Subagents on a different model* are the one thing this producer will see that the CI producer measured absent: the harness counts `SubagentStop` events and, where a subagent's model differs from the run's, the producer records no row and counts the case — ADR-086's withdrawn schema change is re-owed on measurement, not on anticipation.

**The model stays on the row.** Q4-B moves nothing about the model out of the record. `agent.model_id`, `model_snapshot`, `harness.{client,version}` and `system_prompt_sha256` are ADR-086 §C.13's required four, and the harness fills them under ADR-087 §C.14's derivations. The provenance record adds *who acted on GitHub* and joins to run records by `run_id`, so model and principal are one join apart, never one field. What the routing programme needs per row — model, task identity, outcome, cost, count of human steering — is on the run record; what it could not have before — whether a human also pushed, reviewed or merged — is on the provenance record. For an interactive run, `system_prompt_sha256` covers the task text the harness passed as the first prompt (the registry entry's description), the routine if any, and `AGENTS.md` as read — the second reason `reg:` is required: an unregistered task has no prompt text the harness can hash, and §C.14's hash half yields no row.

Trailers and PR grammar (ADR-085 §D.15, §E.16–17): `Exeris-Run: <ulid>` on every commit made in a harness session; `Owner: @login` (exactly one, an organisation member) on every pull request whose author is `exeris-agent[bot]`, forbidden on any other — `pr_body_check.py` gates both. Provider trailers (`Claude-Session:`) stay as adapter data and are copied into the record's `agent.harness` block, not replaced.

Row transport for a local producer: `exeris-inbox` is the only pen, its key is an organisation secret, and the hands are deliberately not installed on the inbox repositories. So a harness run leaves its row as a local artefact and `exeris-agent flush` opens the inbox pull request **under the maintainer's own identity** — not a fallback, a sign-off: the human vouches for a batch of rows exactly as ADR-087 §C.15 has a human merge them. The validator runs before the PR is opened, as §C.15 requires of every producer. Automating this through a workflow in the harness repository that lets `exeris-inbox` commit is the same "auto-merge by amendment" trigger ADR-087 §C.15 already reserves.

Derived classes (a query in `exeris-ai-execution` over run + provenance records, never a stored value): `PURE_HUMAN` — no run record claims any commit of the PR; `AGENT_EXECUTED` — every commit claimed by a run with `principal.kind = app` and `human_prompts = 0`; `HUMAN_STEERED` — `human_prompts > 0`; `…_HUMAN_MODIFIED` — a commit no run claims after the last claimed one, or `unattributed` when the record cannot say; and the review axis is two classes, never one: `OWNER_VERIFIED` — the approving review or door label comes from a `User` principal whose login equals the pull request's `Owner:`; `INDEPENDENTLY_REVIEWED` — it comes from a `User` principal who is not the owner. `unattributed` is a class, not a default to human. Reviewing a pull request one commissioned from an agent is verification by the commissioner — better than reviewing one's own code, since the reviewer did not write it, and still not independent — and the split is what keeps ADR-086 §D.15's SCB §0.3 caveat from becoming a mixed population the moment a second reviewer exists. "Independent" is not one thing, and the policy names which one. Four levels, each observable from the platform without a list of people, each strictly stronger than the last: **`member`** — a `User` who is not the owner and whose `author_association` is `MEMBER` or `OWNER`; **`committer`** — additionally holds write or maintain permission on the repository (the semantic GitHub's own *required approvals* uses, so the ruleset switch and the check agree at this level); **`codeowner`** — additionally listed in `CODEOWNERS` for a path the pull request touches (meaningful only once `CODEOWNERS` has more than one row); and, orthogonal to all three, **`exclude_pushers`** — nobody who pushed a `human_push` to the branch counts, so a co-author is not a reviewer. An automated reviewer — `exeris-bot`, the L2 routine's runner, any `Bot` — is none of these at any level. `review-policy.json` carries `min_independent_approvals` and `independent_reviewer: member | committer | codeowner` and `exclude_pushers`; the recommended setting on the day of a second maintainer is `1 / committer / true`, moving to `codeowner` when there are code owners to move to. `publish_verdict.py` enforces the policy for App-authored pull requests; a change to any of the three values writes a fence, and the derived class stays binary — the level in force is instrument state on the fence, not a suffix on the class. The residual the platform cannot see: a machine-user account added as a member is a `User` at every level; that is an organisation membership decision, the same class of decision as admitting a member who rubber-stamps, and no check on the pull request can make it.

Scope of the guarantee: enforced inside `exeris-systems` (App, rulesets, `publish_verdict.py`); declared for an external maintainer running the harness on a fork with their own credentials. Their pull request still lands under the organisation's ruleset, which enforces the only invariant that matters at merge.

### Why not the alternatives?

- **Q1-A/C/D/E** — a naming collision, or the wrong trust boundary, or a home with no version.
- **Q2-B/C/D** — rejected by ADR-087 already, would widen the voice, or is the maintainer's identity.
- **Q3-A/C** — the RFC becomes impossible, or nobody is accountable.
- **Q4-A/C** — a second record owner, content in a metadata-only row, a self-report; or the principal in a field ADR-087 §A.4 reserves for the model.
- **Q5-B first** — excludes the subscription case and builds a framework ADR-086 deferred.
- **Q6-A** — the status quo, and one ADR-085 §I.29 already forbids.

### Risks of the recommendation

- **Three schema changes and a record kind before the first harness row**, in a repository whose validator is still "a specification rather than a program" (ADR-086 EP1). Mitigation: identity first — the App, the rulesets and the two `publish_verdict.py` closures are valuable with no capture at all; capture follows ADR-086 EP2.
- **The construction domain's oracle is `scb` at `not-run`**, so every harness row on code is `UNKNOWN` indefinitely until SCB Phase 4. That is ADR-086's fail-closed working as intended, and the provenance record is useful without an outcome — the *who* question has an answer before the *whether* question does.
- **`human_prompts` is a count of a vendor's hook event**; a runtime that does not expose it yields a row with the field absent and `capture_level` saying so, never `0`.
- **Unsigned local pushes.** *Require signed commits* must stay off on the code ruleset; the authenticated fact is the pusher and the PR author, which is what the provenance record reads. Trigger for API-created commits or a signing arrangement: SCB or an auditor asks for per-commit *Verified*.
- **Draft-then-human-ready** makes every agent PR wait for one click; that click is the point.
- **A solo organisation cannot produce an independent review, and a bypass is not the answer.** There is no bypass actor, the maintainer included: a bypass exists to be used, and one used routinely is an override (ADR-087's own reasoning for the door). Instead the ruleset's *required approvals* is off in the solo phase and the human-verification rule for App-authored pull requests lives in the required check, so the maintainer's own pull requests pass on a clean verdict as today and every agent pull request still needs a `User` event. What the solo phase *cannot* fix is independence: every review of an agent pull request is `OWNER_VERIFIED`, and the derived classes keep it apart from `INDEPENDENTLY_REVIEWED` so the two are never summed. The mitigation is the switch, not the disclosure — `review-policy.json` flips to `min_independent_approvals: 1` on the day there is a second maintainer, and the fence it writes is what makes rows before and after comparable only within their own side.
- **Provider ToS drift** drops an adapter to `api` mode; the contract does not change.

### What can be measured before the harness exists

Not everything the RFC defers to measurement needs the harness to measure it, and the acceptance gate should say which is which.

- **Q7 needs no harness.** Registering the `exeris-agent` App is identity work that precedes the harness anyway; with its private key, an installation token is a JWT exchange and the five actions of the Q7 table are five `gh api` calls against a throwaway repository under the five-rule ruleset. One evening, no code beyond a token-minting script.
- **Q8's closures need no harness — they *are* the harness's first commit.** The isolation of option A is a shell script of a few dozen lines (`GIT_CONFIG_GLOBAL`, `GH_CONFIG_DIR`, `GH_TOKEN`, `insteadOf`, `GIT_SSH_COMMAND`, worktree with `extensions.worktreeConfig`) and is exactly what `agent/openRun` does; verifying it and writing `openRun` are the same act.
- **Q8's count needs runs, but a baseline is available now.** The L0 deny on `~/.config/gh/**` and `~/.ssh/**` is one `hooks.yaml` entry in `exeris-agents`, renderable into any repository today; counting its firings across the maintainer's *current* sessions for a week gives a baseline before the harness changes anything. The baseline is an underestimate by construction — today the agent runs as the maintainer and has no reason to go looking for a credential; under the harness its default identity is the App, and the moment something needs the maintainer's permission is the moment the incentive appears. It is still the number to compare the first harness runs against.
- **The number is reserved after Q7 and Q8's closures, not after Q8's count.** The count is the harness's first instrument reading, and gating the ADR on it would gate the instrument on its own output.

### What the harness measures that nothing else can

The CI producer of ADR-087 measures reviews. The harness is the first producer for the construction domain and, more importantly, the first that can produce ADR-086 §E.22's *paired runs on demand*: `exeris-agent run --task reg:<id> --provider <p>` for N providers on one registered task is a declared group by construction — `pairing.group_id` assigned when the task is registered, one arm per provider, `arms_planned` known before any arm runs. CI can pair only reviews of a pull request that already exists; the harness pairs *construction* of the same task, which is the population SCB needs and the one ADR-086 §H.39 holds open the documentation domain against.

Two disciplines from ADR-086 bind harder here than in CI, and the RFC states them so the harness is not built around a figure it cannot have:

- **Reported cost exists only on `api` rows; api-equivalent cost is a derived, fenced, calibrated quantity — never a field.** The maintainer's runs will mostly be `accounting.mode: subscription`, and the objection is fair: the tokens are the same tokens, only the billing differs, and the price lists are public. What §C.14 refuses is not the arithmetic; it is a *figure on the row* that looks like a measurement and is a claim about a price list — one that changes by date, by tier, by cache TTL (the runner's ledger shows cache-read tokens dominating, and cache pricing differs by TTL the ledger may not expose), by batch and by contract. Putting that beside `provider_reported_cost` in one column is the failure §C.14 exists to prevent. The resolution keeps both truths: the row carries tokens by class and no USD (unchanged); `exeris-ai-execution` gains **versioned price lists** (`price-lists/<vendor>/<effective-date>.json`, digest, source URL) as instrument state under §E.20 — a new list is a fence; V1 computes **`api_equivalent_cost`** from token classes × the list in force, always carrying `price_list_id`, never named `cost`, never summed with reported cost; and it is **calibrated before it is quoted** — paired arms of the same task, one `api`, one `subscription`, same model: the reported figure against the imputed one, the difference published, and only a list whose imputation matches reported cost within a stated tolerance carries `calibration: pass`. That is the same discipline §D.17 applies to an oracle, applied to a price list, and it answers the cache-TTL question empirically instead of by assumption. What remains true: a cost *claim* rests on `api` arms; a subscription arm supports an api-equivalent figure labelled as such. Proposed as an ADR-086 amendment beside the two fields.
- **The construction domain's outcome is `UNKNOWN` until SCB calibrates**, so every "the second model was not cheaper because CI failed and it took four more turns" is *observable* and not *labelled*. What can be recorded today without breaking §D.15: the L1 check-run conclusions on the run's pull request as `oracle` state on a row whose `oracle.id` is a **fifth, observational-only row in §D.15's table** — `construction-ci`: does the pull request's build and test gate pass at the run's result commit; calibration none; admissible as observation only, never a label, never summarised with `scb` rows. It is the construction analogue of `review-disposition`, with the same incentive caveat: a runner that touches nothing passes CI. Proposed as an ADR-086 amendment beside the two fields, not assumed.

The trajectory quantities a reader wants — turns, tool calls, tokens, wall time, human steering, commits, rework, first-pass gap, self-correction, regression — sort into five kinds, and the sorting is the point:

| Kind | Quantities | Where |
|:--|:--|:--|
| already on the row | turns, tool calls, permission denials, tokens by class, wall time, `tool_surface`, `verdict_route` | ADR-086 §C (measured 2026-09-15) |
| MINOR fields this RFC adds | `human_prompts`; `execution.principal`; **`execution.result_commits[]`** if `run-record.schema.json` does not already list the commits a run produced (the provenance record joins on it; check before the schema PR) | §C.9 MINOR |
| V1 derived, no new field | turns/wall/tool-calls-to-outcome per group, human steering rate, first-pass gap (first `Stop` vs last), self-correction count (failed tool call followed by a retry), rework (commits after a review event, from the provenance record), `api_equivalent_cost` (token classes × fenced price list, calibrated against `api` arms, labelled imputed) | `exeris-ai-execution` V1, descriptive only (§B.6) |
| needs a preregistered definition before it is queried | `semantic_change_cost`, `regression_rate` (a later pull request or issue that reverts or repairs what this run produced — a link from a run to a future incident, SCB §7.5's change-cost idea) | §E.25: hypothesis and falsification condition in the registry first |
| blocked on a calibrated oracle | `false_DONE_rate`, anything phrased as TRUE_DONE for construction | §E.19 fail-closed; `construction-ci` observes it, SCB labels it |

Two sentences of discipline that the harness repository carries verbatim: no artefact under it names a model as appropriate for a workload (ADR-086 §B.5 applies to a producer as it applies to the layer); and the harness is a producer — every quantity in the table's lower three rows is computed in `exeris-ai-execution`, never in the harness, so the seam of §A.2 holds for this producer as it holds for the bundle.

One addition worth its own line: **the human arm.** §E.23 wants the human baseline first, on every model row, and today nothing produces it reproducibly. `exeris-agent baseline --task reg:<id>` — a worktree under the *human's* identity, no model, no hooks beyond timing and the commit trailer — makes `human_baseline` a measured value with the same task fingerprint rather than a remembered one. *(ADR-086 §E.23 amended 2026-09-23: the human arm is declared only where a group asks whether delegating pays; `baseline` exists for that case.)* It costs one subcommand and closes the field the pairing discipline depends on.

## Decision Record

| Field                | Value |
|:---------------------|:------|
| **Outcome**          | — |
| **Date**             | — |
| **Resulting ADR(s)** | ADR-AGENT-ID (pending); amendments to ADR-085, ADR-086, ADR-087 (companion draft) |
| **Notes**            | v1 of this RFC (same date) proposed a bespoke provenance artefact and was written before ADR-086/087's acceptance was read; superseded by this text. **Decisions of 2026-09-17:** Q1-B, Q2-A, Q3-B ("behind the agent stands the person who commissioned the work"), Q4-B with the model-on-the-row clarification above, Q5-C (the same intent → route-by-difficulty → plan → implement → verify contract the future platform runs), Q6-B. **Surface architecture (2026-09-17):** one execution contract (`agent/*` JSON-RPC service), N surfaces — CLI now, IDE plugins and hosted `exeris.eu` later — mirroring `sdk-lsp`'s four-surfaces-one-protocol; built that way in V0 because maintainers, users and marketplace creators will all reach it through the platform's own surfaces. ADR-087 closures (i) and (ii) taken immediately, independent of this RFC; S3 closed as a finding (Q6 (iii)). **Q7: A + B** ("clean A" was the first instinct; the S1.c dismissal leak is what makes B necessary beside it). **Q8: A + D now, C on measurement, E regardless.** Gate for reserving the number: Q7 and Q8's closures; Q8's count is the harness's first reading, not a prerequisite. **Identity registered 2026-09-17** — App `exeris-agent` created and installed on the code repositories; private key stored as an organisation secret alongside `exeris-bot`/`exeris-inbox` (client id, not app id, as the JWT issuer); the RFC's custody rule applies as a narrowing, not a reversal: the secret's repository access is restricted to no repository until a CI surface needs to mint (V2), and the harness reads a local owner-only copy. Rotation baseline for this App: 2026-09-17. The ruleset is the next step and precedes the first `exeris-agent run`. **Measurement (2026-09-17):** the harness is the paired-run producer for the construction domain; cost claims only from `api` arms; `construction-ci` proposed as an observational-only oracle row; `exeris-agent baseline` for the human arm. |

## Open questions / follow-ups

- **Q7 verification (S1)** — throwaway repository under the five-rule ruleset; the App approves, dismisses a human's *changes requested*, merges before and after a human approval, pushes after approval. Five rows in the Q7 table filled in; `publish_verdict.py` gains the `review_dismissed`-by-`Bot` red and its mutation cases whatever the outcome of S1.c, because the API permits it today.
- **Q8 verification (S2)** — `exeris-agent run --provider claude` under option A's closures: `gh auth status` inside reports the App; `git push` over a `git@github.com:` remote fails; the vendor CLI finds its subscription login; the L0 deny on `~/.config/gh/**` and `~/.ssh/**` fires and is counted. The count over the first runs is the input to the C-vs-wait decision, recorded as a dated line in the harness's `policy/README.md`.
- **S3 — closed, see *Spike outcomes*; the false green is gone (`.github#62`).** Remaining, as one change: implement the §C.14a restore (checkout HEAD, then restore `AGENTS.md`, `.agents/**`, `.claude/**`, `.codex/**`, `.cursor/**`, `.gemini/**` from the merge base when `author_association` is not `OWNER`/`MEMBER`), drop the author test from the produce `if:` and from skip-kind, retire `bot-authored` — `bot-event` already names a Bot sender. Until then agent pull requests are door-reviewed only and yield no L2 row. Whether Dependabot-class pull requests, which today ride the `draft-or-bot` green, should instead wait for a human readiness click (one click, which for a solo maintainer is the merge click anyway) or keep a named green-skip list is decided in the same amendment — the recommendation is the click, because a list is a thing somebody adds an App to.
- **`publish_verdict.py` closures (i) and (ii)** — file as an ADR-087 amendment now, independent of this RFC: the door and the readiness trigger check the sender's principal type.
- **ADR-086 schema PRs** — `execution.principal`, `execution.human_prompts`, and `execution.result_commits[]` if absent (MINOR); `provenance-record.schema.json`; the `adhoc:` class and its non-joinable rule in the validator (§G.34 gains a sixth rule); the `construction-ci` observational row in §D.15 with its incentive caveat written beside it; versioned price lists as instrument state and `api_equivalent_cost` as a calibrated V1 derivation (§C.14 amendment — the row stays USD-free).
- **Credential baseline** — the L0 deny entry for credential paths rendered into one repository now; the count over a week of current sessions recorded before the first harness run.
- **Subagent model divergence** — first ten harness runs: count runs where a `SubagentStop` names a model other than `agent.model_id`. Zero → nothing owed; non-zero → ADR-086's withdrawn schema change (list or companion field) is re-owed, by amendment, with the count.
- **`exeris-agents` sink** (ADR-086 §H.36) — this producer needs one thing from the dispatcher: the prompt-event count with the run id from the environment. It is a datum for the deferred payload decision, not a decision.
- **Registry before harness capture** — ADR-086 EP4 orders `exeris-ai-execution-enterprise` after the first CI rows; `reg:`-required harness runs are gated on it. Identity is not.
- **External maintainers** — publish the App manifest for other organisations to instantiate, or keep "your credentials, our trailers". Not blocking.
- **Exeris Platform / marketplace** — the same three-App principle (voice, pen, hands) applies to Studio actions and marketplace publishing, and the `agent/*` service is the surface the platform's CLI, IDE plugins and hosted tier all call; the ADR says both are reused, not re-invented. Placement of `exeris-agent-harness` in the ecosystem map's layer diagram (beside `exeris-ai-bridge`, consumed by L7a/L7b) is an ecosystem-map edit that lands with the ADR.
- **Contract surface golden** — `api/agent-surface.json` exists before the first IDE client, and `caller_bundle_check`-style drift on it is red; the CLI is the reference client.
- **Retention / privacy** — `human_prompts` is a count; the boundary between metadata and content stays where ADR-086 §H.37 leaves it.