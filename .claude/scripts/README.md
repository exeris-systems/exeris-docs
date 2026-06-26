# `.claude/scripts/` — single source of the *greppable* doctrine rules

These scripts hold the **mechanical, regex-expressible** half of the exeris-docs
guardrails. They are the one place the patterns are written down. Skills,
commands, and agents **call** these scripts — they do not restate the patterns
(see [`../README.md`](../README.md) § "Rules — single source").

The **prose** half of the doctrine (why each pattern is wrong, the cap census,
the SKU split, the three-tier narrative) lives once in
[`../../CLAUDE.md`](../../CLAUDE.md) and the ADRs it points at. Scripts locate;
prose explains; the skill/agent adjudicates.

## Scripts

| Script | Purpose | Exit 0 / 1 / 2 |
|---|---|---|
| `drift-sweep.sh <file>…` | Locate candidate lines for the 10 drift patterns (CLAUDE.md § Common drift patterns). | clean / candidates-found / usage |
| `taxonomy-check.sh <file>…` | Locate visibility (ADR-020) + license (ADR-023) candidate lines. | clean / candidates-found / usage |
| `adr-filename-check.sh <adr-file>` | Verify `ADR-NNN-<lowercase-kebab>.md` + number reserved in `adr-index.md`. | pass / fail / usage |
| `check-consistency.sh` | Anti-drift guard: fail if any `.claude/` file hard-codes doctrine that must live only in CLAUDE.md/scripts. | clean / violation / — |

## Locator, not auto-fail (drift-sweep + taxonomy-check)

`grep` cannot distinguish **use** from **mention**. The canonical docs legitimately
contain every forbidden token inside a *negation* — "there is **no**
`exeris-caps-quic-*` cap", "**no** cap `@Requires` exeris-spring-runtime", or
"Q4 2026 = TRL-5 component validation" (a correct roadmap statement). So:

- A token match is a **candidate**, never a proven defect.
- Lines that look like a correct negation are annotated `⟵ (neg? verify)`.
- Exit code `1` means **REVIEW REQUIRED**, *not* "broken". A human or the
  relevant review skill adjudicates each candidate: real drift → fix **every**
  site; correct negation/mention → leave it.

`adr-filename-check.sh` and `check-consistency.sh` are true gates (exit 1 = real
violation) because their rules are unconditional.

## Typical use

```bash
# after editing a large doc
.claude/scripts/drift-sweep.sh high-level-architecture.md b2b-technical-whitepaper.md
.claude/scripts/taxonomy-check.sh high-level-architecture.md

# before an ADR content file lands
.claude/scripts/adr-filename-check.sh adr/ADR-046-some-decision.md

# keep the toolkit itself single-source
.claude/scripts/check-consistency.sh
```

These are dependency-free POSIX-ish bash + `grep`; they run in CI or a
pre-commit hook unchanged.
