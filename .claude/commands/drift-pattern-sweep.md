---
description: Sweep an edited file for the registered drift patterns in `.agents/policies/drift-patterns.md`. Use after any non-trivial HLA / whitepaper / large-doc edit.
argument-hint: edited file path (e.g. `high-level-architecture.md`) or PR diff
---

<!-- DO NOT EDIT. Generated from .agents/workflows/drift-pattern-sweep.md by the AGENTS.md adapter step
     (agents-md-schema.md rule 7). Edit the source, not this file. -->
Run the drift-pattern sweep on the target below.

Target: $ARGUMENTS

Steps:
1. Run the locator: `.agents/scripts/drift-sweep.sh $ARGUMENTS`
   (It holds the 10 greppable patterns and marks likely-correct negations with
   `⟵ (neg? verify)`. Exit 1 = candidates found → review required, NOT "broken".)
2. Adjudicate each candidate as real drift vs. a correct negation/mention. For
   canonical phrasing and the "why", read `.agents/policies/drift-patterns.md` (see to
   watch" (entries 1–10 match the script's `#N`). Prioritise the STRUCTURAL
   patterns (#1,#3,#4,#5,#7,#8) — they propagate downstream.
3. For every confirmed drift, grep the WHOLE doc and apply the same correction at
   every site — single-edit fixes leave inconsistencies.
4. Report: per-candidate verdict, single-edit consistency check, and a patch list.

The patterns and the prose live in one place each (`drift-sweep.sh` and
`.agents/policies/`) — don't restate them here; read them. For the full review procedure
use the `exeris-docs-drift-pattern-sweep-review` skill.
