---
title: "RFC-2026-09-18: The native executor — a self-hosted model, a context layer and a gated tool surface for `exeris-agent`, with no vendor in the loop"
type: rfc
visibility: public
owning-repo: exeris-docs
status: draft
---

# RFC-2026-09-18: The native executor — a self-hosted model, a context layer and a gated tool surface for `exeris-agent`

| Field             | Value |
|:------------------|:------|
| **Status**        | **DRAFT** (v1) |
| **Author(s)**     | Arkadiusz Przychocki (options analysis assisted by Claude) |
| **Date Opened**   | 2026-09-18 |
| **Date Closed**   | — |
| **Target ADR(s)** | ADR-NATIVE-EXECUTOR (new; number to be reserved after V0's first reading); amendments to **ADR-025** (a `context:*` family and one narrowly permitted local embedding call), **ADR-086 §C.13/§C.14** (`local` model reference and a fence rule for adapters); one BUS- entry (what the platform ships: an endpoint, never weights) |
| **Affected Repos**| `exeris-agent-harness` (executor, prompt render target, adaptation), `exeris-agents` (one adapter mapping, one hook-event mapping), `exeris-ai-bridge` (context adapter, ADR-025's deferred role), `exeris-ai-execution` (schema notes), `exeris-docs` (this RFC; a docset licence register), `exeris-business` (BUS- entry) |
| **Reviewers**     | — |

## Question

RFC-2026-09-17 Q5-C chose one execution contract (`agent/*`) with the vendor CLIs as the first executors and "B implements later as an executor" — an own loop over a model API — deferred to `api` mode. This RFC asks what that first native executor is, and settles it as **a locally served open-weight model under ADR-086's `accounting.mode: local`**, on the machine that exists today (one 16 GB GPU, 64 GB RAM). Six coupled questions: **(Q1)** which model class and licence the executor admits, and how the choice stays a *configuration* rather than the routing claim ADR-086 §B.5 forbids; **(Q2)** how repository knowledge and external documentation sets (JDK, TypeScript, Angular) reach the model — the context layer, its home, and its relationship to agent-file rule 8 (nothing fetched at runtime); **(Q3)** how the executor's tools are declared, gated per run and recorded; **(Q4)** how a per-repository system prompt is produced so that every executor, vendor or native, receives the same instructions and the same `system_prompt_sha256`; **(Q5)** what is adapted in the weights, on what data, trained where, and how an adapter enters the record; **(Q6)** what "independent of the provider" means as a test rather than a sentence.

Template deviation, stated up front: six questions in one RFC because they share one artefact — the executor — and produce one ADR plus two amendment sets. Q1 and Q5 are the two the reader most expects to find answered by a model name; neither is, on purpose.

## Context

RFC-2026-09-17 gave the harness an identity, a record and a contract, and left the executor slot filled by whatever CLI a subscription permits. That is the right V0 for provenance and the wrong V0 for three things the maintainer now wants: **control of the tool surface** (a vendor CLI exposes what its hook surface exposes; `capture_level` says how little), **control of the context** (a vendor CLI reads the repository its own way, and `.agents/references` reach it only as prose), and **independence from a vendor's model roster** (a `model_snapshot` that reads `unresolved:<id>` is the record admitting it does not know what ran). A native executor closes all three at once, because the harness then owns the loop, the tools, the prompt and the model reference.

What changed this week: Apache-2.0 open-weight models in the 9B–35B class now carry native function calling and 256K context, and two of them are mixture-of-experts models whose *active* parameters fit a consumer GPU while their total does not — which is exactly the shape a 16 GB card with 64 GB of system memory can exploit, and exactly the shape that needs measuring before anything is bought. The maintainer's own hardware note (2026-09-18) says the same thing in the other direction: nothing is purchased until ten to twenty real tasks have run through the harness and the telemetry says what is missing.

Two constraints from the accepted records bound this RFC harder than the hardware does. **ADR-086 §B.5**: no artefact under the layer names a model as appropriate for a workload, and a harness is a producer, so this RFC recommends a *candidate list and a measurement*, never a winner. **ADR-086 §C.12**: a run record is metadata only — prompts, file content and tool arguments never appear. A fine-tuning corpus is content by definition, so the training data of Q5 cannot come from the dataset ADR-086 keeps, whatever the temptation; it is a separate store with its own rules, and this RFC says which.

The cost of leaving this open is the cost RFC-2026-09-17 already named, one step further: the construction domain's rows would all name a vendor's model under a vendor's tool surface, and the routing question ADR-086 defers to V4 could never include the arm the maintainer most wants to compare against — the one with no vendor.

## Investigation

### Prior art

- **RFC-2026-09-17 Q5** is the immediate prior art: the contract is fixed, the executor is a slot. This RFC fills the slot without changing the contract — the acceptance test for Q6.
- **`exeris-agents` renderer** (`tools/agents_render.py`, `tools/adapters/<vendor>.yaml`): one canonical `.agents/` tree, N vendor adapters, each a mapping of capabilities → tool names, model tiers → model ids, canonical hook events → vendor events. A native executor is *one more adapter file*, not a second prompt compiler. Reference-first discipline (`~/exeris-systems/CLAUDE.md`) applies: the pattern exists; the gap is a porting gap.
- **`exeris-ai-bridge`** (ADR-025): read-only MCP server, zero-checkout for P2, filesystem reads sandboxed to pinned roots, `scripts/vendor-reference-data.mjs` vendoring released upstream artefacts with digest verification. ADR-025 already names the bridge as the future *context adapter* (RFC-2026-09-08 §Placement). The vendoring script is the exact mechanism a documentation set needs.
- **Agent-file schema rule 8** (`agents-md-schema.md`): no hidden or remote authority; imports are vendored, pinned and digest-verified; nothing is fetched at agent runtime. A context layer that queries the web at run time violates it; one that reads a vendored, pinned index does not.
- **Agent-file schema rule 11**: a profile declares `capabilities` (`read, search, edit, shell, web, subagents, mcp:<server>`) and a `model` tier, never a vendor's tool names or a model id. The tool surface of Q3 has its vocabulary already.
- **Agent-file schema rule 12**: hooks are L0, declared once in `hooks.yaml`, dispatched by the vendored dispatcher; a runtime that cannot block records a degradation. Every vendor adapter today carries degradations; a native executor can carry none.
- **cAST** (arXiv 2506.15655) and tree-sitter-based code graphs (arXiv 2603.27277): structural chunking of code by syntax tree outperforms fixed-size chunking for code RAG; hybrid BM25 + dense with a reranker is the settled default for mixed prose-and-code corpora.
- **Commission guidelines on GPAI (July 2025)**: a downstream modifier becomes a provider of the modified model only when the modification's training compute exceeds one third of the original's (≥ ⅓ × 10²³ FLOP for a non-systemic model); a LoRA adapter is orders of magnitude below that. What the guidelines do not relieve is the *platform's* stated position (current-state, Sep 2026): Exeris is a tool and runtime supplier, not an AI-system provider, and the BYO-key architecture is the documented affordance for that. Shipping weights would move the line; shipping an endpoint reference does not.

### Constraints

- ADR-086 owns the record: `agent.{provider, model_id, model_snapshot, harness, system_prompt_sha256}` are required, metadata only, fail-closed outcome; `accounting.mode: local` exists and means "the cost is hardware and wall time, and is not a provider figure".
- ADR-086 §B.5: the harness names no model as appropriate for a workload. A candidate list is configuration; a recommendation is routing.
- ADR-087 §C.14 / RFC-2026-09-17: the harness is a producer; every derived quantity is computed in `exeris-ai-execution`, never in the harness.
- ADR-025: the bridge is read-only, makes no model API calls, holds no keys, boots with zero checkout for P2. A new tool family is an ADR-025 amendment.
- Agent-file schema rules 8, 11, 12 as above; rule 9: no agent file weakens an ADR.
- Licence policy: Apache-2.0 / MIT weights only (the OpenRewrite rule, applied to models). Custom "community" licences with revenue gates are out, however permissive today.
- Hardware, as of 2026-09-18: RTX 4060 Ti 16 GB, Ryzen 5 5600, 64 GB DDR4, B550. Nothing is bought before V0's telemetry.
- One maintainer; V0 must run in one shell on one machine.

### Data gathered

Figures below are vendor or community numbers as published on the cited date; none is an Exeris measurement, and none may be quoted as one (style guide rule 9; RFCs are exempt from the report-path rule, not from saying whose number it is).

| Fact | Value | Source (2026-09-18) |
|:--|:--|:--|
| Qwen3.6-35B-A3B | 35B total / 3B active MoE, Apache-2.0, 262K native context, native tool use, thinking toggle, GGUF available (Apr 2026) | [huggingface.co/Qwen/Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) |
| Qwen3.6-27B / Qwen3.8-27B | dense, Apache-2.0, 256K (Apr / Aug 2026); Qwen3.8-2.4T-A95B under a custom revenue-gated licence — **out** | [codersera guide](https://codersera.com/blog/qwen-3-5-complete-guide-2026/) |
| Qwen3.5 family | 0.8B–397B, Apache-2.0, 256K (Feb 2026); 9B dense and 35B-A3B are the two sizes a 16 GB card is interested in | same |
| Gemma 4 family | E2B, E4B, 12B dense, **26B-A4B** (25.2B total / 3.8B active MoE), 31B dense; **Apache-2.0** since Gemma 4 (Apr 2026); 256K on 12B+; system role and native function calling; QAT checkpoints | [ai.google.dev/gemma/docs/core](https://ai.google.dev/gemma/docs/core), [Google Open Source blog](https://opensource.googleblog.com/2026/03/gemma-4-expanding-the-gemmaverse-with-apache-20.html), [HF model card](https://huggingface.co/google/gemma-4-26B-A4B-it) |
| Devstral Small 2 | 24B dense, Apache-2.0, 256K, 68.0 % SWE-bench Verified (vendor figure); Devstral 2 123B under a modified MIT | [mistral.ai](https://mistral.ai/news/devstral-2-vibe-cli/) |
| GLM-5.2 | 753B open-weight — not a local candidate on any consumer machine; an `api`-mode arm only | [datanorth.ai](https://datanorth.ai/news/zhipu-ai-releases-glm-5-2) |
| GGUF footprint, Qwen3.6-27B | 3-bit ≈ 15 GB, 4-bit ≈ 18 GB (Unsloth); Q4_K_M ≈ 16.8 GB (willitrunai) — **does not fit 16 GB with an agentic KV cache** | [unsloth.ai/docs/models/qwen3.6](https://unsloth.ai/docs/models/qwen3.6), [willitrunai](https://willitrunai.com/blog/qwen-3-6-vram-requirements) |
| GGUF footprint, Qwen3.6-35B-A3B | 3-bit ≈ 17 GB, 4-bit ≈ 21–23 GB — fits only with experts offloaded to system RAM (`--n-cpu-moe` / `--cpu-moe`); one guide reports ~5–10 tok/s under offload and advises against, another lists it as the 16 GB pick with `--cpu-moe` — **the disagreement is the V0 measurement** | same two, plus [InsiderLLM](https://insiderllm.com/guides/function-calling-local-llms/) |
| GGUF footprint, Gemma 4 26B-A4B | ≈ 15 GB at Q4 — fits, with little KV headroom; QAT int4 checkpoints exist | InsiderLLM, HF card |
| Fine-tuning VRAM (Unsloth, bf16 LoRA) | 4B ≈ 10 GB; **9B ≈ 22 GB; 27B ≈ 56 GB; 35B-A3B ≈ 74 GB**; QLoRA 4-bit explicitly *not recommended* on Qwen3.5-class weights (quantisation drift); MoE router layers frozen by default | [unsloth.ai/docs/models/qwen3.5/fine-tune](https://unsloth.ai/docs/models/qwen3.5/fine-tune) |
| llama.cpp tool calling | `--jinja` required; native handlers for Llama 3.x, Qwen 2.5, Hermes, Mistral Nemo, Functionary, Command R7B; generic fallback for others (more tokens); parallel tool calls off by default; extreme KV quantisation degrades tool calling; Gemma 4 routes tool output to `reasoning_content` unless `enable_thinking:false` | [llama.cpp function-calling.md](https://github.com/ggml-org/llama.cpp/blob/master/docs/function-calling.md), InsiderLLM |
| Embeddings / rerankers | Qwen3-Embedding 0.6B/4B/8B and Qwen3-Reranker, Apache-2.0, multilingual, code-aware | [qwen.ai/blog qwen3-embedding](https://qwen.ai/blog?id=qwen3-embedding) |
| GPAI modifier threshold | provider status for the *modified* model only above ⅓ of original training compute; obligations then attach to the modification only | [artificialintelligenceact.eu](https://artificialintelligenceact.eu/gpai-guidelines-overview/) |
| Run record today (`main`) | `execution.{turns, tool_calls, wall_time_ms, event_stream}`; `tool_surface`, `permission_denials`, `capture_level` are named by ADR-086 §C.14a / RFC-2026-09-17 but **not yet in `run-record.schema.json` on `main`** (33,366 B; the `alias` worktree carries a 35,750 B revision) | `exeris-ai-execution/schemas/run-record.schema.json`, 2026-09-18 |

Three things the table settles before any option is weighed. **Local training of anything above ~4B is not available on this machine**: bf16 LoRA on a 9B model needs 22 GB, and the 4-bit path Unsloth would otherwise offer is the one it advises against on this model class. **Local inference of the 27B dense class is marginal**: a 4-bit file alone is at or over the card, before a 32K KV cache. **The two MoE models are the only 25B+-class candidates that fit at all**, one directly (Gemma 4 26B-A4B at Q4) and one through expert offload (Qwen3.6-35B-A3B), and the throughput of the second under DDR4 offload is unknown until measured.

### Spike outcomes

None executed. The two spikes this RFC needs are cheap enough to be V0's first two days rather than a precondition: S1 — `llama-server` with each candidate, `--jinja`, one fixed agentic prompt with ten tool calls, recording VRAM, prefill and decode tok/s at 8K/32K/64K context; S2 — the `native.yaml` adapter rendered for one repository (`exeris-docs`) and `agents_render.py --check` green. Their outcomes are the first rows of V0's telemetry, not inputs to this text.

## Options Considered

### Q1 — Model class and licence, and how the choice is recorded

| Option | Pros | Cons |
|:--|:--|:--|
| **A. A candidate list of Apache-2.0/MIT weights in three shapes — dense ≤12B (Qwen3.5-9B, Gemma 4 12B), MoE 25–35B with 3–4B active (Gemma 4 26B-A4B, Qwen3.6-35B-A3B), dense 24–27B at 3-bit as a control (Devstral Small 2, Qwen3.6-27B) — every one a `--model` argument, none a default; the record carries `agent.provider: local`, `model_id` = the vendor's id, `model_snapshot` = the GGUF file's SHA-256 plus the server's version** | Exactly what ADR-086 §B.5 permits a producer to hold; the snapshot is a digest, so "which model" is never `unresolved:`; a licence rule the maintainer already applies to code | A list is maintenance; three shapes are three sets of `llama-server` flags |
| **B. One model, chosen now** | One flag set; one prompt tuned | A routing claim in a harness — the thing §B.5 forbids — and a bet placed before the telemetry that was supposed to inform the purchase |
| **C. Admit non-Apache "open" weights too** | Wider pool | The OpenRewrite lesson: a licence that is fine today and gated tomorrow, in a component the platform will later point customers at |
| **D. Do nothing — vendor CLIs only, `accounting.mode ∈ {api, subscription}`** | — | The arm with no vendor never exists; `capture_level` stays bounded by vendor hooks |

### Q2 — The context layer: what it indexes, where it lives, what it may call

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Context is prose in `.agents/references` and the model's own file reads** (status quo) | Zero infrastructure | A 256K window is not a retrieval strategy; rule 6 forbids copying ADRs into references; external documentation sets have no home at all |
| **B. A `context:*` family in `exeris-ai-bridge` (ADR-025 amendment) over vendored, digest-pinned indices: per-repository (code by syntax-tree chunk, ADRs/standards/`.agents` by section) and per-docset (JDK 25 Javadoc, TypeScript handbook, Angular docs — each a manifest entry with version, licence, source URL, digest, built by the existing `vendor-reference-data.mjs` pattern); V0 retrieval is lexical + structural (BM25 over chunks, symbol table over tree-sitter output — no model call); V1 adds dense vectors and a reranker through a **locally configured `/v1/embeddings` endpoint**, permitted by a narrow ADR-025 amendment (no generative call, no vendor SDK, no key, degrade to lexical when absent); every hit returns a citation (`repo@sha:path#Lx-Ly`, `ADR-NNN §n`, `docset@version:path`) and the executor is told to cite or not use it** | Both executors — the vendor CLIs over MCP and the native loop over the same tools — retrieve the same way, so a context change is one change; rule 8 holds by construction (index built offline by a human, pinned, verified); the bridge's zero-checkout rule holds (a docset is a package asset, a repository index is gated like `docs:*`); the docset manifest is the licence register the corpus needs anyway | One amendment; a query-time embedding call is a model call in spirit, and the amendment has to say why it is not the call ADR-025 forbids (it generates nothing, holds nothing, and leaves the process on a missing endpoint) |
| **C. Context layer inside the harness** | No amendment | A second retrieval path the vendor CLIs cannot see; the bridge's promised role (RFC-2026-09-08) never materialises |
| **D. A hosted vector database** | Scales | Remote authority at agent runtime — rule 8's exact prohibition; a network dependency in the executor whose reason to exist is having none |

### Q3 — The tool surface: declaration, gating, record

| Option | Pros | Cons |
|:--|:--|:--|
| **A. The vendor's tools, as exposed** | — | The surface the maintainer cannot control; the reason for this RFC |
| **B. A tool registry in the native executor keyed by rule 11's capability vocabulary — `read`, `search`, `edit`, `shell`, `web`, `subagents`, `mcp:<server>` — where every tool has a JSON Schema, arguments are validated before execution, and the per-run **tool manifest** is the intersection of (the profile's `capabilities`) ∩ (the run's scope from `openRun`) ∩ (the executor's policy: `web` off unless a docset is missing and a human says so, `shell` an allow-list of build and VCS commands with the scope rules of RFC-2026-09-17 in front, `edit` refused outside the worktree, Category-B paths refused); every call passes through the vendored L0 dispatcher as a seventh runtime (`tools/adapters/native.yaml`, full-fidelity: `pre-tool` blocks, `stop` gates, no `degradations`); the manifest's canonical hash is `execution.tool_surface`, refusals are `permission_denials` / `scope_denials`** | The surface is declared once (rule 11), narrowed per run, enforced in the loop *and* by L0, and recorded; a tool the model calls that is not in the manifest is a counted error returned to the model, never an exception; mutation-testable | The registry is code, and code regresses; the golden of §Testing is what holds it |
| **C. Prompt-level gating** ("do not use X") | Zero code | The mechanism agent-file rule 12 exists to replace; ADR-085 §I.29 forbids restating in prose what CI enforces |

### Q4 — The system prompt: one compilation, N executors

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Hand-written system prompt per repository in the harness** | Fast to start | A second place rules are authored — rule 2's exact violation |
| **B. The native executor is a render target of `agents_render.py`: `AGENTS.md` + the selected `AGENT.md` body (verbatim, as every adapter gets it) + composed policies by `bundle:` prefix + skill *descriptions* (bodies load on selection, per rule 4) + the tool manifest + a retrieval preamble; canonicalised by the renderer's documented method; `agent.system_prompt_sha256` is the same hash the CI producer computes for the same commit — and, because the native executor owns the whole prompt, a second hash of the *full* prompt as sent is kept beside it (`harness`-scoped, closing the "stated hole" ADR-086 §C.13 names for hosted clients)** | One compiler, one hash, one authority order (`bundle → repository → subtree → workflow`); a change to `.agents/` reaches every executor in the same commit; the swap test of Q6 becomes meaningful because the inputs are provably equal | The renderer gains a target that is not a vendor; `native.yaml` needs the capability and hook mappings written from a vocabulary that has been *read*, per `exeris-agents/README.md`'s own rule for adapters |

### Q5 — Adaptation: what, on what, where, and how it enters the record

| Option | Pros | Cons |
|:--|:--|:--|
| **A. Continued pre-training on the codebase** | "The model knows Exeris" | Knowledge that goes stale per commit, baked into weights; the context layer exists so this is never needed; compute this machine does not have |
| **B. A ladder, each rung gated on a measurement: A0 none (base + context + tools — the V0 arm); A1 prompt and skill changes, driven by `.agents/evals`; A2 supervised LoRA on *protocol and format* — the tool-call protocol of Q3, the decision schemas of rule 13 (triage, verdict, handoff), the commit and PR grammar (`Exeris-Run:`, `Owner:`, trailers), the RFC/ADR templates and the docs style guide — a small corpus, half synthetic from the schemas and templates, half captured; A3 preference tuning (DPO/KTO) from paired runs' outcomes — **only for a domain whose oracle is calibrated** (ADR-086 §D.15: documentation today, construction never until SCB Phase 4)** | Each rung is falsifiable against the rung below on the same paired tasks; A2's corpus is mostly derivable from artefacts the organisation already keeps, and its value (fewer malformed tool calls and schema violations) is the cheapest kind to measure; A3 inherits ADR-086's fail-closed rule instead of inventing a reward | A2 above ~4B trains on rented hardware, not this machine — stated plainly, not hidden |
| **C. Fine-tune first, measure later** | — | The discipline this programme already applies forbids it; without A0's rows nothing distinguishes an adapter that helped from a prompt that changed |

**Where the corpus lives, and what it is not.** A training corpus is *content* — prompts, file text, tool arguments, model output. ADR-086 §C.12 keeps every one of those out of a run record, and the inbox validator would be right to refuse them. So the corpus is a fourth artefact class beside run, judgement and provenance records: local, private, never in `exeris-ai-execution`, never in a public repository, keyed to `run_id` so that a training example can be traced to a row but a row never leads to text. Consent boundary: the organisation's own repositories, and docsets only where the licence permits derivative use in training (the docset manifest's licence field decides, per entry — CC-BY 4.0 handbooks are one answer, a vendor Javadoc under its own terms is another, and the register says which before an example is cut).

**How an adapter enters the record.** An adapter is instrument state. Loading one changes `agent.model_snapshot` to `<base-gguf-sha256>+<adapter-sha256>` and writes an `instrument.fence` (ADR-086 §E.20); rows on either side never sum. The adapter registry (`adapt/registry/<name>/<version>/`) carries base digest, corpus digest, recipe, training compute (so the GPAI threshold is a number, not an assumption), and the eval result that admitted it. An adapter with no eval row is not loadable — the same rule ADR-086 applies to an oracle without calibration.

### Q6 — Provider independence as a test

| Option | Pros | Cons |
|:--|:--|:--|
| **A. A sentence in the README** | — | Unverifiable; the failure mode is discovered the day a vendor changes a hook name |
| **B. Three checks: (i) the **swap test** — one registered task, one `.agents/` commit, ≥ 2 executors (a vendor CLI and the native loop) as arms of one `pairing.group_id`, with equal `system_prompt_sha256` asserted before either arm runs; (ii) a **lock-in lint** — no vendor tool name, model id or hook event outside `tools/adapters/` and `executors/vendor-cli/`, enforced like the existing adapter-drift gate; (iii) the **eval invariant** — `.agents/evals/scenarios.yaml` passes under the native executor with no change to the scenarios** | Independence becomes a green check that goes red on the day it stops being true; the native executor is the *witness* that the contract carries no vendor shape, which is what makes the vendor executors safe to keep | (i) needs the registry (`reg:`) ADR-086 EP4 orders after the first CI rows — until then the swap test runs on `adhoc:` fingerprints and is not paired, only compared by hand |

**Do nothing** (Option C across the board): the harness stays a wrapper, `capture_level` stays bounded by vendor hooks, the context layer stays prose, and every row of the construction domain names a vendor. Acceptable only if the maintainer's three stated wants are withdrawn; they are not.

## Testing

The RFC proposes two contracts consumers will implement — the tool registry's schemas and the `context:*` tool family — and one render target. What is verified, and how:

- **Tool-surface golden** — `executors/native/api/tool-surface.json` under ADR-085 §F.21c's rule: a removed tool or a widened argument schema is MAJOR; drift is red, as for `api/agent-surface.json`.
- **Tool-gate mutation suite** — the shape ADR-087 EP2 uses for `publish_verdict.py`: profile without `shell` + model calls `shell` → refused and counted; `edit` outside the worktree → refused; Category-B path → refused; `web` with no docset gap → refused; a tool call whose arguments fail its schema → error to the model, `tool_calls` incremented, nothing executed; a call the L0 dispatcher denies → the executor's own gate agrees (two lines, one answer). Each rule reverted alone fails only its own cases.
- **Adapter-fidelity check** — `agents_render.py --check` for `native.yaml`, and a test asserting the profile body reaches the model byte-identical to what `claude.yaml` renders, so the swap test's hash equality is a property, not a hope.
- **Retrieval evals** — a small, versioned query set per index (an ADR number, a symbol, a standard's rule) with expected citations; recall@k tracked as a descriptive figure, never a claim; a docset whose index fails its query set is not loaded.
- **The swap test** (Q6-B-i) — runnable on `adhoc:` fingerprints from V0's first week; paired from the day the registry exists.
- **What cannot be tested before implementation:** throughput under MoE offload on DDR4, and whether a 3–4B-active model holds the loop past three sequential tool calls without "eager" calls. Both are V0 telemetry; the fallback for the second is the dense ≤12B shape, which is on the list for that reason.

## Recommendation

**Q1-A, Q2-B, Q3-B, Q4-B, Q5-B, Q6-B: a native executor in `exeris-agent-harness` that runs an Apache-2.0 model behind an OpenAI-compatible local endpoint, reads context through a `context:*` family in `exeris-ai-bridge`, exposes a per-run tool manifest derived from `.agents/` and enforced by the loop and by L0, receives the same rendered prompt every vendor adapter receives, adapts weights only on a measured rung, and proves its independence with a swap test — V0 on the machine that exists, with the telemetry deciding the hardware.**

The design is one sentence from RFC-2026-09-17 applied once more: *the contract does not leak the executor's shape.* `agent/openRun` already binds identity, scope, worktree and hooks; the native executor is the first client of that service that is not a vendor CLI, and everything it adds — a tool registry, a retrieval family, a render target, an adapter registry — is placed where the ecosystem already has a home for that kind of thing. The renderer compiles the prompt because it compiles every other adapter's. The bridge serves context because ADR-025 said it would. `exeris-ai-execution` derives the numbers because a harness never does. Nothing in this RFC creates a second owner for anything.

What V0 concretely is:

```
exeris-agent-harness/                          (RFC-2026-09-17 layout, plus:)
├── executors/
│   ├── vendor-cli/<claude|codex|gemini>/      Q5-A wrappers — unchanged
│   └── native/                                THIS RFC
│       ├── loop.ts        turn loop over /v1/chat/completions: prompt → tool_calls → results;
│       │                  budgets (turns, tool calls, wall time, tokens); stop conditions;
│       │                  a model switch mid-run ends the run (ADR-086, 2026-09-17)
│       ├── endpoint/      one adapter per server: llama-server (V0), vLLM/SGLang (later,
│       │                  larger VRAM), any `api` provider (same loop, accounting.mode api)
│       ├── tools/         registry keyed by rule-11 capability: read · search · edit ·
│       │                  shell(allow-list) · context(mcp:exeris-ai-bridge) · git(scoped)
│       ├── gate/          per-run manifest = capabilities ∩ scope ∩ policy; schema validation;
│       │                  L0 dispatch on every call (native.yaml, no degradations)
│       └── api/tool-surface.json              golden (ADR-085 §F.21c)
├── models/
│   ├── candidates.yaml    id · licence · shape · gguf sha256 · server flags · context — a LIST
│   └── README.md          "this file names no model as appropriate for any workload" (ADR-086 §B.5)
├── adapt/                 V2+: corpus builder (local, private, content — never the inbox),
│   ├── recipes/           Unsloth LoRA recipes per shape; rented-GPU note for >4B
│   └── registry/          <name>/<version>/: base digest · corpus digest · compute · eval row
└── evals/
    ├── swap-test.yaml     one task, N executors, equal system_prompt_sha256 asserted first
    └── lockin-lint        no vendor name outside adapters/ and executors/vendor-cli/

exeris-agents/tools/adapters/native.yaml       capabilities → registry tool names;
                                               tiers → candidates.yaml entries; hooks → loop events

exeris-ai-bridge/src/tools/context/            context:* — search · cite · docsets · index_status
exeris-ai-bridge/data/docsets/<name>@<ver>/    vendored, digest-pinned (vendor-reference-data.mjs)
exeris-docs/standards/docset-license-registry.md   which docset, which licence, training: yes | no
```

The V0 endpoint is `llama-server --jinja` with the chat-template kwargs the candidate needs (`enable_thinking:false` for tool-heavy loops on the two families that route tool output through reasoning otherwise), KV cache unquantised (the tool-calling degradation under extreme KV quantisation is documented), and expert offload (`--n-cpu-moe`) as a per-candidate flag in `candidates.yaml`, never a default.

**The record.** `agent.provider: local`; `model_id` as the vendor writes it; `model_snapshot: sha256:<gguf>` (plus `+sha256:<adapter>` from V2); `harness.client: exeris-agent-native`, `harness.version` the harness's own; `system_prompt_sha256` computed by the renderer's canonicalisation, identical across executors for one commit; `accounting.mode: local`, `usage` from the server's token counts; `execution.tool_surface` the manifest hash, `permission_denials` and `scope_denials` from the gate — three fields ADR-086 §C.14a names and `main`'s schema does not yet carry, so V0's first rows will validate only against the `alias` revision or carry them in a producer-scoped extension until the MINOR lands. Nothing else is new on the row.

**The prompt.** Rendered, not written. The native adapter gets the profile body verbatim like every other; what differs by executor is the *tool block* (names from the registry) and the *retrieval preamble* (how to call `context-search` and how to cite). Both are in `native.yaml`, so the semantic source stays `.agents/` and rule 2 holds.

**The corpus.** Content, local, private, traceable by `run_id`, never in the inbox, never in a public repository, cut only from the organisation's own repositories and from docsets whose register entry says `training: yes`. The corpus for A2 is small by design: the schemas, templates and grammars the organisation already versions, plus captured tool-call transcripts from V0 runs that passed their gate.

### Why not the alternatives?

- **Q1-B** — a model name in a harness is routing wearing configuration's clothes, and a purchase decision made before the measurement that was to inform it.
- **Q1-C** — the OpenRewrite lesson, in weights.
- **Q2-A/C/D** — no home for docsets; a second retrieval path; remote authority at runtime.
- **Q3-C** — prose gating is what rule 12 replaced.
- **Q4-A** — a second prompt author is rule 2's violation and makes the swap test meaningless.
- **Q5-A/C** — stale knowledge in weights; an adapter with no baseline to beat.
- **Q6-A** — a claim nobody can falsify.

### Risks of the recommendation

- **The card.** Every 25B+-class candidate is at the edge of 16 GB; the MoE path through DDR4 offload may measure too slow for an interactive loop. Mitigation: the dense ≤12B shape is on the list as a first-class candidate, not a fallback, and V0's exit criterion is written on outcome and wall time, not on model class. If the telemetry says "16 GB is the only thing that blocks", that is the maintainer's own Etap 1 trigger — GPU only, no platform rebuild.
- **Local training is not what "local" promised.** Anything above ~4B trains on rented hardware (one large-VRAM GPU for hours, not days). Stated here so V2 is planned as a rental line, not discovered as one. The inference side stays local throughout.
- **Small-active-parameter models and long tool chains.** Community notes report eager tool invocation and difficulty past two or three sequential calls on small models. The gate makes the eager call a counted refusal rather than damage; whether the loop completes tasks is exactly what A0 measures, and what A2 is for.
- **A query-time embedding call inside the bridge.** Narrow as the amendment is, it is the first model call in a repository whose hard constraint 2 says "none". The amendment must name the three properties that keep it inside ADR-025's intent (generates nothing, holds no key, degrades to lexical) and the mutation case that proves the third. V0 needs none of this — lexical and structural retrieval is the baseline.
- **Docset licences.** A documentation set that may be *indexed and cited* may not be *trained on*; the register carries both answers per entry, and a docset with no entry is not vendored.
- **What the platform ships.** The stated intent is "target model for the platform". The recommendation reads that as *target executor* — the platform ships the harness, the render target, the context family and a candidate list; it ships **no weights** and no adapter. A customer or a marketplace creator points the executor at their own endpoint, exactly as they bring their own key today. That keeps the BYO-key affordance and the "optional AI dependency" of the IDP SKU intact; distributing weights would reopen the tool-supplier position and is a BUS- decision, not a harness default.
- **The registry is not there yet.** The swap test pairs only on `reg:` fingerprints; until `exeris-ai-execution-enterprise` exists, V0 compares `adhoc:` rows by hand and never sums them — the rule ADR-086 §F.31 already states.

### Phases and exit criteria

Gated on measurements, not dates.

| Phase | Ships | Exit criterion |
|:--|:--|:--|
| **V0** — the arm with no vendor | `executors/native/` loop, gate, registry; `native.yaml`; `candidates.yaml` with the three shapes; `context:*` **lexical + structural only** (no amendment beyond the family); run records under `local`; swap test on `adhoc:`; telemetry per run: VRAM, prefill/decode tok/s, context reached, turns, tool calls, denials, wall time, outcome; **10–20 tasks in the documentation domain**, because that is the one domain whose oracle is calibrated (ADR-086 §D.15) and the only place a local model's `TRUE_DONE` is a fact rather than `UNKNOWN` | at least one candidate completes the docs-domain scenario set with the same oracle result as a vendor arm on the same commit; hardware verdict written as a dated line (buy GPU / do not buy / rebuild) with the rows behind it |
| **V1** — context | dense retrieval + reranker through the local embedding endpoint (ADR-025 amendment); docsets vendored (JDK, TypeScript, Angular — register entries first); retrieval evals; `context:*` used by vendor CLIs over MCP as well | retrieval eval set green per index; swap test shows the vendor arm and the native arm citing the same sources for the same task |
| **V2** — adaptation A2 | corpus builder; LoRA recipe per shape (local ≤4B, rented above); adapter registry with fence; A/B as paired runs (base vs base+adapter, same task, same prompt hash) | adapter admitted only on a paired-run improvement in tool-call validity and schema conformance, with the corpus and compute digests recorded |
| **V3** — A3 and the platform | preference tuning on a calibrated-oracle domain; the hosted `exeris.eu` tier runs the same native executor against an organisation's BYO endpoint (RFC-2026-09-17 V2 surface) | gated on SCB calibration for any construction claim; on the swap test staying green across the surface change |

## Decision Record

| Field                | Value |
|:---------------------|:------|
| **Outcome**          | — |
| **Date**             | — |
| **Resulting ADR(s)** | ADR-NATIVE-EXECUTOR (pending); amendments to ADR-025, ADR-086; one BUS- entry |
| **Notes**            | Decisions of 2026-09-18: local first on existing hardware (RTX 4060 Ti 16 GB, 64 GB RAM), purchase decided by telemetry after 10–20 real tasks; Apache-2.0/MIT weights only; placement in `exeris-agent-harness` as the next executor under RFC-2026-09-17's contract. Number reserved after V0's first reading (S1, S2), not before. |

## Open questions / follow-ups

- **S1 / S2** (V0, first days) — candidate throughput table and the `native.yaml` render check; both recorded as dated lines in `models/README.md` and the harness changelog.
- **ADR-025 amendment** — `context:*` family (V0 needs the family; V1 needs the embedding clause); which persona each tool serves (P1 repository indices; P2 docsets); zero-checkout behaviour of an absent index.
- **ADR-086 MINORs** — land `tool_surface`, `permission_denials`, `capture_level` on `main` (they are on the `alias` worktree); add the `local` model-reference convention (`sha256:<gguf>[+sha256:<adapter>]`) and the adapter-fence rule to §C.13/§E.20; whether `accounting.usage` under `local` should carry prefill/decode split as two optional counters or stay as is.
- **`native.yaml`** — written only after the registry's vocabulary is fixed, per the adapter rule in `exeris-agents/README.md`; the hook-event mapping is the one place the native executor is *more* capable than the canonical events (it can block a stop unconditionally) — record it as the absence of degradations, not as a new event.
- **Docset licence register** — `exeris-docs/standards/docset-license-registry.md` on the `cap-license-registry.md` pattern: name, version, source, licence, `index: yes|no`, `train: yes|no`. JDK 25 API docs, TypeScript handbook, Angular docs are the first three entries; each needs its licence *read*, not assumed.
- **BUS- entry** — the platform ships an executor and a candidate list, never weights; a customer's adapter is theirs. Owner: maintainer; before V3.
- **Corpus retention** — local, private, `run_id`-keyed; deletion when a run's row is deleted; no public copy ever. Written into the harness's `policy/README.md` beside the credential rule.
- **Rented training** — which provider, which region (data stays in the EU for a corpus cut from private repositories), and whether the recipe runs unattended; decided at V2, recorded in `adapt/recipes/README.md`.
- **Subagents** — the native loop has no `subagents` capability in V0; whether it gains one, and how a sub-run is recorded (ADR-086's withdrawn schema change, re-owed on measurement per RFC-2026-09-17), is a V1 question with the same count as its trigger.
- **The IDE surfaces** — `exeris-ide-vscode` / `-intellij` call `agent/*`; whether they may *select* the native executor is a UI question the contract already answers (a `provider` argument to `openRun`), and nothing here changes.
