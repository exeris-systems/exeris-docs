---
title: Agent-File Schema and Policy
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-08
---

# Agent-File Schema and Policy

Binding target for ADR-085 §I. This file retains its historical path for stable
links; it governs `AGENTS.md`, `.agents/`, and provider adapters rather than
`CLAUDE.md` alone.

Version 2 (2026-09-08). Rules 1–9 are v1's and keep their numbers; 10–14 are new.
What changed and why is in [Migration](#migration).

## Purpose and ownership

Every repository has one portable entry point and one canonical semantic
source. Provider-specific files make that source usable by a particular agent;
they do not become a second place to author project rules.

```text
AGENTS.md                         portable repository entry point (≤ 8 KB)
<subtree>/AGENTS.md               scope-specific, restrict-only (≤ 4 KB)
CLAUDE.md                         rendered pointer — a client that cannot read AGENTS.md
.agents/                          canonical semantic content
  manifest.yaml                   composition, pinned imports, render map, degradations
  agents/<name>/AGENT.md          role profile: vendor-neutral frontmatter + system prompt
  agents/<name>/{checklists,rubrics,examples,references,evals}/   optional, referenced by path
  skills/<name>/SKILL.md          reusable procedures and capabilities
  workflows/<name>.md             user-invoked prompt; declares its steps and gates
  policies/*.md                   non-negotiable constraints
  references/*.md                 deferred, authoritative context
  schemas/*.schema.json           the decision handoffs (triage, verdict, handoff)
  hooks/hooks.yaml, hooks/bin/*   runtime enforcement, authored once
  evals/scenarios.yaml, evals/    runtime-independent behaviour tests
  scripts/*                       provider-agnostic checks the canonical files call
  vendor/<bundle>-<version>/      VENDORED, verified copy of an imported bundle — never edited
  hooks.json, rules/, plugins/    RENDERED adapters that a vendor claims inside .agents/
.claude/ .github/ .codex/ .cursor/ .gemini/    rendered adapters + provider-owned configuration
```

`AGENTS.md` and `.agents/` are both versioned repository content. The former is
the small file every compatible agent can discover; the latter is the source of
truth for the detailed semantics it points to.

Three paths inside `.agents/` are rendered output rather than source, because
one runtime discovers them there and the alternative is a second copy of the
same content: `.agents/hooks.json`, `.agents/rules/` and `.agents/plugins/`.
They carry the do-not-edit marker every other generated file carries, and rule 2
does not make them canonical merely because of where they sit.

## Hard rules

1. **`AGENTS.md` at repository root is required and is the canonical entry
   point.** It states the repository mission, the operating contract, the
   authoritative knowledge locations, and where policies, skills, profiles and
   workflows live. It is an index and a safety boundary, not an encyclopedia.
   Keep it at or below 8 KB; move detail to `.agents/` or `docs/`.
   `[L1: agent-file check]`
2. **`.agents/` is the canonical semantic source.** A repository that exposes
   reusable agent behaviour keeps it under `.agents/`; semantic rules MUST NOT
   be authored independently under `.claude/`, `.github/`, `.codex/`,
   `.cursor/`, or `.gemini/`, nor under the three rendered paths named above. An
   exception requires an explicit, provider-specific capability that cannot be
   represented in the canonical model, and is recorded in the manifest.
   `[L1: generated-adapter drift check]`
3. **Each kind of file has one job.** A policy says what is permitted or
   forbidden; a skill says how to perform a bounded capability; a profile
   defines a role and composes skills and policies; a workflow defines the
   ordered lifecycle of a task; a schema fixes the shape of a decision handed
   between them; a hook enforces at runtime what none of the others can. Do not
   encode one kind as another merely because a provider has only one native file
   type. `[L2]`
4. **Skills use the Agent Skills layout.** Every skill lives at
   `.agents/skills/<name>/SKILL.md`, with `name` and a precise `description` in
   YAML frontmatter. Optional `scripts/`, `references/`, and `assets/` are
   loaded only when that skill is selected. A skill description names both what
   it does and when it applies. `[L1: skill metadata and path check]`
5. **Profiles and workflows are declarative compositions.** They identify the
   skills, policies, references and default workflow they need; they do not
   copy their full bodies. The manifest and the filesystem must agree in both
   directions: every declared name exists, and every profile, skill and workflow
   on disk is declared. The format is owned by the Exeris agent manifest, not by
   a provider. `[L1: manifest schema check]`
6. **References remain authoritative at their owning location.** A reference
   names its source and yields to it; a skill may link to an ADR, module
   document, contract or generated artefact, but must not copy it merely to make
   a prompt self-contained. A reference that restates a *structure* — a module
   matrix, an event table, a dependency graph — is **generated** from that
   structure and carries a generated-file header (ADR-085 §F.21d); hand-written,
   it is the drift this rule exists to prevent. `[L2; L1 for generated
   references]`
7. **Provider directories are adapters, not a lowest-common-denominator
   target.** The renderer generates native Claude subagents and skills, GitHub
   Copilot agents and instructions, Codex agents, Gemini agents and commands,
   Antigravity rules and hooks, and Cursor rules from `.agents/`. Generated
   files carry their source and a do-not-edit marker. Provider-local settings,
   MCP connection settings, secrets, permissions and GitHub Actions remain
   provider-owned operational configuration; they are not semantic adapters and
   are listed under `provider-owned` in the manifest rather than matched by a
   regex. `[L1: generated outputs]`
8. **No hidden or remote authority.** A manifest may import only an approved,
   Exeris bundle pinned to a version and a commit, and recorded with a digest.
   An import is **vendored**: its content is committed under
   `.agents/vendor/<bundle>-<version>/` and verified byte-for-byte, so a
   `$ref` into it resolves on github.com, in CI without a network and in a
   fresh clone alike. Nothing is fetched at agent runtime — the network is used
   once, by a human, at the moment the version is chosen. A profile composes an
   imported policy or reference by the `bundle:<name>` prefix, so a reader can
   tell whose rule it is without knowing the layout. Bundled scripts are
   reviewed code with explicit permissions; an agent must not execute them
   merely because a skill mentions them, and must never edit the vendored copy
   in place. `[L1: pinned-import and checksum check]`
9. **No agent file may weaken an ADR, a standard, a repository policy, or the
   user's explicit safety constraints.** When they disagree, the higher-order
   authority wins and the lower document is a `[DOC DEBT]` item. `[L2]`
10. **Role profiles use the `AGENT.md` layout, mirroring skills.** Every profile
    lives at `.agents/agents/<name>/AGENT.md`, where `<name>` matches
    `^[a-z0-9]+(-[a-z0-9]+)*$`, is at most 64 characters, and equals the
    frontmatter `name`. A lowercase `agent.md` anywhere under `.agents/agents/`
    is forbidden: one runtime discovers `.agents/agents/<name>/agent.md`
    natively, which is the same path as the canonical file on a case-insensitive
    filesystem, and the ban keeps a single file from being both source and
    adapter. `AGENT.md` is an Exeris convention, not an ecosystem standard.
    `[L1: profile path and name check]`
11. **Canonical frontmatter is vendor-neutral, and must be safe to be read
    raw.** A profile declares `capabilities` (`read, search, edit, shell, web,
    subagents, mcp:<server>`), not a vendor's tool names, and `model` as a tier
    (`inherit | fast | balanced | strong`), not a model id. Vendor-specific keys
    live under `adapters: {<vendor>: {…}}` and are merged last by the renderer.
    A runtime that reads a canonical profile directly must find nothing it can
    mistake for a grant of tools. `[L1: frontmatter schema check]`
12. **Hooks are L0 and are authored once.** Runtime enforcement lives in
    `.agents/hooks/hooks.yaml` with its scripts under `.agents/hooks/bin/`, and
    is rendered to each vendor's hook file. A hook may deny an action a policy
    already forbids; it may never permit one a policy forbids, and it is never
    the place a rule is first stated. **L0 is a tripwire, not a proof** — a stop
    hook establishes that a command ran, never that it was the right command,
    and where a runtime cannot block a stop the hook degrades to a warning and
    the manifest records the degradation. `[L0; L1: hook render and
    degradation check]`
13. **A decision handed from one agent to another has a schema.** Triage
    results, review verdicts and handoffs conform to the JSON Schema files in
    `.agents/schemas/`; a profile that emits one names it in `output` and
    reproduces it as a fenced `json` block after its human-readable response.
    Validation happens in evals and in the CI review that posts a verdict — not
    on every interactive turn, where the cost is friction and the benefit is
    already taken. `[L1: schema validity; L2: conformance in review]`
14. **Behaviour is tested by evals, not by recollection.** A repository that
    ships profiles keeps `.agents/evals/scenarios.yaml` in a runtime-independent
    form — fixture, prompt, expected schema and field assertions — with
    deterministic graders first. A change to a profile, skill or policy that a
    scenario covers reruns that scenario before merge, and the pull request
    names the run. Evals run on demand and on a schedule, never on every pull
    request. `[L2; L3: pre-pr checklist]`

## `AGENTS.md` schema

The exact prose and heading names are repository-owned. The file contains, in
this order, the following concerns:

1. mission and scope;
2. operating contract and non-negotiable safety boundaries;
3. architecture and documentation entry points;
4. `.agents/` discovery and the applicable policy/workflow contract;
5. verification and reporting expectations;
6. provider-adapter note, when one exists.

It links rather than reproduces detailed build commands, subsystem rules,
release mechanics and ADR text.

**Nested files.** A subtree with materially different constraints carries its
own `AGENTS.md`. It adds scope-specific rules, may restrict but never relax, and
does not restate the parent. It stays at or below 4 KB, and its frontmatter adds
two keys to the ADR-085 §B.7 block: `paths:`, the globs the renderer uses to
scope the adapters it emits, and `enforced-by:`, the ArchUnit rules, Checkstyle
modules or CI checks that actually enforce what the file says. A nested file
that names no enforcement is a preference, and belongs in a policy instead.

**Portability.** An agent file is read on whatever machine checks the repository
out. A path under someone's home directory is true on one machine, and an
instruction built on one fails silently for everyone else — the grep finds
nothing and the reader concludes something from the silence. Name the
repository; leave a sibling checkout as a stated convenience.
`[L1: machine-path check, warning]`

## `AGENT.md` — the role profile

The body is the system prompt and is copied verbatim into every adapter.
Sections derived from `skills`, `policies`, `references`, `handoffs` and
`output` are appended under a marker, so the adapter check can still assert that
the authored part is byte-identical.

| Field | Req. | Canonical meaning |
|:--|:--|:--|
| `name` | yes | identifier; equals the directory name |
| `description` | yes | when to delegate — this is the routing text every runtime reads |
| `role` | yes | `router \| reviewer \| implementer \| evaluator \| specialist` |
| `mode` | yes | `read-only \| edit \| autonomous` — permission intent, mapped per vendor |
| `capabilities` | yes | `read, search, edit, shell, web, subagents, mcp:<server>` |
| `model` | no | `inherit \| fast \| balanced \| strong` (default `inherit`) |
| `skills` | no | names under `.agents/skills/` this role preloads or references |
| `policies`, `references` | no | composition by reference (rule 5) |
| `handoffs` | no | `[{agent, when, blocking}]` |
| `output` | no | path to the schema the response must conform to (rule 13) |
| `hooks` | no | agent-scoped hooks, in the canonical form of `hooks.yaml` |
| `evals` | no | directory of per-agent scenarios |
| `limits` | no | `{body_chars}`, to override a vendor cap deliberately |
| `adapters` | no | per-vendor overrides, any native key, verbatim; merged last |

There is no templating language. A profile that wants worked examples
references `examples/*.md` by path and the model reads them.

## Workflow header

A workflow is a Markdown prompt. Its frontmatter carries `name`, `description`
and `argument-hint` as before, and adds `steps` — the ordered agent and skill
handoffs, each optionally with a `when` guard, a `gate`, or an evaluator `loop`
— and `gates`. A gate is prefixed by what enforces it, so the reader can tell a
promise from a check: `hook:<id>` for an L0 hook, `ci:<job>` for a CI job,
`script:<file>` for a repository script, `test:<class>` for a test class. The
names in both keys are checked against the manifest and the filesystem; the
model reads them as guidance, and the gates they name are what actually
enforces.

No runtime in scope executes a workflow file: every one of them hands it to the
model as a prompt. A declarative graph here would be interpreted by the same
model it was meant to constrain, so determinism comes from the hooks and the CI
checks the header names, and from a script layer (`.agents/pipelines/`) when a
concrete pipeline pays for one. That directory is reserved and currently unused.

## Hooks — the L0 layer

`hooks/hooks.yaml` declares each hook with an `id`, a canonical `event`
(`pre-tool`, `post-tool`, `stop`, `session-start`), a canonical tool class
(`shell | edit | read`), a `match`, the script to `run`, and a `decision`
(`allow | deny | block-or-allow`). Scripts live in `hooks/bin/`, read the vendor
from `$EXERIS_HOOK_VENDOR`, and emit that vendor's decision shape through one
`normalize` helper. Session state lives in `.agents-state/`, which is
git-ignored.

Two shapes are worth naming because getting them backwards is the common
mistake. A hook that **denies** encodes an action no policy permits — an
irreversible or outward-facing operation with a named human in the loop. A hook
that **records and then gates** encodes an action a policy permits *with a
consequence*: it allows the action, writes what happened, and blocks the stop
until the consequence has been discharged. Denying what a policy allows produces
a hook that is switched off within a week, which is worse than no hook.

## Schemas

`.agents/schemas/` holds the decision handoffs and nothing else:
`triage-result.schema.json`, `verdict.schema.json`, `handoff.schema.json`. They
are JSON Schema, are the eval grader's input, and are what a CI review posts.
Adding a fourth schema means a new kind of decision exists, which is a change to
rule 3's list and to this file.

Where a bundle is imported, a repository's schema **narrows the bundle's base
rather than copying it**: an `allOf` of a relative `$ref` into
`.agents/vendor/…/schemas/<name>.base.schema.json` and the repository's own
enums. The shape belongs to the bundle; the vocabulary does not, because role
names carry a repository prefix (rule 10) and a task class means what its
repository decided. A `$ref` that is a URL is a rule-8 violation, not a style
choice: resolving one needs a fetch. `[L1: $ref targets exist and are local]`

## Naming and size caps

| Subject | Cap | Set by |
|:--|:--|:--|
| `<name>` for a profile, skill or workflow | `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤ 64 chars, equals frontmatter `name` | Agent Skills |
| root `AGENTS.md` | 8 KB | rule 1 |
| nested `AGENTS.md` | 4 KB | rule 1 |
| profile body | 30,000 characters | the tightest vendor agent-body cap |
| workflow body | 12,000 characters | the tightest vendor workflow cap |
| `SKILL.md` | < 500 lines, recommended | Agent Skills |

Names keep their repository prefix (`exeris-`, `exeris-docs-`). Several runtimes
merge agent and skill names across user, project and plugin scope, so an
unprefixed `architect` collides silently with whatever the user has installed.

## Resolution and inheritance

Instruction sources resolve from broad to narrow:

```text
approved organisation bundle → repository → subtree → selected task workflow
```

The closest applicable `AGENTS.md` adds to its parent. A more specific file may
restrict behaviour but may not relax a higher-order rule. At execution time,
system and user instructions outrank repository material; accepted ADRs and
standards outrank agent-file summaries. `manifest.yaml` records bundle versions
and compositions, but never replaces this authority order. Hooks sit outside
this order: they do not instruct, they enforce, and a hook that appears to state
a rule is a rule authored in the wrong place (rule 12).

## Adapter and distribution policy

The canonical source is portable; delivery may differ by audience.

- Repository contributors consume the repository's `.agents/` source and its
  generated adapters. One renderer, shared across repositories, produces every
  adapter; a repository that renders with its own script is a fork of the
  standard and will drift from it. The shared half lives in one bundle and
  reaches a repository two ways, which are not interchangeable: **semantics are
  vendored** (policies, base schemas, the hook dispatcher, the eval runner —
  committed, digest-verified, resolvable offline), and **tooling is checked out**
  at a pinned ref in CI (renderer, checker, vendor mappings), because copying
  executable tooling into every repository is the duplication a bundle exists to
  remove.
- Application developers may receive a versioned, read-only bundle through an
  npm package or MCP resources/prompts. It must declare its Exeris and manifest
  versions and may not claim to be current for a different dependency line.
- MCP resources and prompts distribute contextual guidance for a session; they
  do not replace installation of a native skill where a client requires one.
- A setup tool may materialise an explicitly selected bundle and its provider
  adapter. It must never overwrite user-authored files without a preview and
  confirmation.

Where a runtime cannot express something the canonical model states, the
manifest's `degradations` records what is lost for that vendor. An unrecorded
degradation is the failure mode this key exists to prevent: an operator who
believes a gate is running on a client that never had it.

## Migration

**From `CLAUDE.md`.** Existing `CLAUDE.md` files are migration inputs, not the
new source of truth. Extract each rule once into `AGENTS.md`, a policy, a skill,
a profile, a workflow, a reference, or the owning source document. Preserve a
thin `CLAUDE.md` adapter only while a supported Claude client requires it; it
points to or is rendered from the canonical source. Do not mass-convert content
with search-and-replace: classify its meaning first.

**From v1 of this schema.** Four things move, and none of them changes what a
rule means:

1. `agents/<name>.md` becomes `agents/<name>/AGENT.md` (rule 10).
2. A profile's `tools:` list becomes `capabilities:` plus, where a vendor needs
   its own list, `adapters.<vendor>.tools` (rule 11). A hand-authored adapter
   frontmatter is the case this replaces: it was the one place the "adapters are
   generated" rule was not true.
3. Workflows rendered to a Claude `commands/` file become skills with
   `disable-model-invocation: true`; the user-invoked `/name` behaviour is the
   same and one adapter kind disappears.
4. Skills stop being copied into provider directories. Five runtimes read
   `.agents/skills/` natively; Claude gets a directory symlink, and a repository
   that cannot use symlinks records the copy fallback as a degradation.

`hooks/`, `schemas/`, `evals/` and nested `AGENTS.md` are additive: a repository
without them is v2-conformant as long as it does not need them, and rules 12–14
bind once it has profiles that hand decisions to each other.

**How v2 binds.** `manifest.yaml`'s `version` is what opts a repository in. Rules
10–13 are reported as warnings against a repository still declaring `version: 1`,
and as errors once it declares `version: 2`. The checker ships to every repository
at once while the migrations land one at a time, so binding v2 before a repository
has migrated turns its CI red for work nobody has asked it to do — which is the
same reason the frontmatter validator has a ramp mode, and the same remedy.

## Filter

- Can a compatible agent discover the repository contract from `AGENTS.md`
  without loading all project knowledge?
- Does each detailed instruction have exactly one semantic owner under
  `.agents/` or in its authoritative documentation?
- Is a provider file an adapter or operational configuration, rather than an
  independently maintained rule set?
- Would this frontmatter be safe if a runtime read the canonical file directly,
  ignoring every key it does not know?
- Does every hook enforce a rule that is written down somewhere else?
- Does the manifest say what each vendor cannot do, rather than implying it can?
- Does a selected developer bundle disclose its version, scope and unavailable
  capabilities instead of silently assuming a full Exeris checkout?
