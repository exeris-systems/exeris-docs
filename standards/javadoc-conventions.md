---
title: Javadoc Conventions
type: reference
visibility: public
owning-repo: exeris-docs
status: active
last-verified: 2026-09-18
---

# Javadoc Conventions

Binding per ADR-085 §F. Applies to all Java sources (TypeScript: `tsdoc-conventions.md`, same rule numbers); the hard gates apply to the **frozen and published surfaces**: `exeris-kernel-spi`, `exeris-sdk-annotations`, and every module published to Maven Central. Everything else is checked on changed files only.

## Hard rules

1. **Every public type, constructor, method, enum constant and record component on a gated module has a doc comment.** `[L1: maven-javadoc-plugin failOnWarnings=true on gated modules — port the exeris-sdk block; Checkstyle JavadocType/JavadocMethod scope=public]`
   - **One exemption, taken per repository and never by default.** A repository whose published surface is fluent — a builder whose setters are `this.x = v; return this;` — may set the Javadoc gate's `trivial-accessors: exempt`, which drops this rule for mechanical members in **both** halves of the gate: Checkstyle skips those members, and javadoc runs `-Xdoclint:all,-missing`. It has to be both. A policy stated to one engine is not in force — with `exempt` in Checkstyle alone, doclint reports the identical accessor as `warning: no comment` under `failOnWarnings`, measured on a probe carrying one undocumented getter and one fluent setter as Checkstyle 2 errors → 0 against doclint 2 warnings → 2. The doclint half is coarse, because `missing` is the only group that reports an undocumented accessor and the same group carries the only checks above private visibility and on fields and enum constants; the ruleset buys those back (`JavadocVariable`, and a missing-doc scope following doclint's default visibility) so that `exempt` subtracts mechanical members and, on every shape measured, nothing else: 13 flagged sites → 10. One shape gains rather than keeps — a constant declared in a record body, which doclint's `missing` does not report and the Checkstyle module does. A gated module whose pom hardcodes `<doclint>` cannot receive the flag and keeps the strict policy; the gate warns rather than letting that pass for an exemption. The exemption is only available where something else carries the coverage and the repository says what: `exeris-sdk` has a completeness test requiring a comment on every public member except exactly that body shape. The point is to move the coverage, not to lose it, and a repository that cannot name its replacement does not qualify. `[L1: javadoc-gate input trivial-accessors, default documented; the gate writes the policy in force into its step summary, so a green run says which standard it ran]`
   - **What counts as mechanical is a body shape, enumerated.** `return <field>;` or `return this.<field>;` on a method with no parameters; `<field> = <param>;` or `this.<field> = <param>;` on a method with exactly one; either assignment followed by `return this;`. That is the set. Anything else keeps the rule: a method with no body, a constant return, a delegation, a computation, a setter that validates, a body carrying a comment. `[L1: scripts/javadoc_trivial_members.py in exeris-systems/.github, filtering MissingJavadocMethod findings and no other check; 23 cases in its suite, thirteen of them members that must NOT be exempted]`
   - **A line count cannot express it.** `MissingJavadocMethod.minLineCount` counts lines in a body and an abstract method has none, so zero sits under any threshold and every abstract and interface method qualifies. Measured on corpora stripped of doc comments, the state in which the released set is visible at all: on `exeris-kernel-spi` that predicate releases 689 of 938 public methods, **377 of them abstract contract methods** against 29 getters; 55 of 259 on `exeris-kernel-tck`; 393 of 447 on `exeris-sdk-source-model`, the one corpus where the released set resembles accessors. It releases the SPI surface a driver implementor reads and keeps the accessors the exemption exists for. The shape predicate releases 29, 11 and 205 on the same three, the last being 204 fluent setters and one getter.
   - The filter fails closed: a file it cannot read, a line past the end of one, a body it cannot parse, all keep the finding. A member is exempted by a rule that fired, never by a check that gave up. `[L2: whether an exempted method is genuinely trivial]`
2. **First sentence is a summary that stands alone**: third-person declarative, states the contract, does not repeat the name. `[L1: Checkstyle JavadocStyle checkFirstSentence]` `[L2]`
   - ✗ `Returns the segment.` on `segment()`
   - ✓ `Returns the backing memory as a read-only view whose lifetime is bound to this buffer's reference count.`
3. **Tags, in this order:** `@param` (every parameter) → `@return` (every non-void) → `@throws` (checked, and unchecked a caller would reasonably catch) → `@since` → `@see` → `@deprecated`. Every tag has a description. `[L1: Checkstyle AtclauseOrder, NonEmptyAtclauseDescription]`
4. **`@since` on every public element of a released module**, in `major.minor` form (`@since 0.12`, never `0.12.0`). `[L1: Checkstyle regexp — Spring's atSinceVersionConvention]`
5. **`@author` and `@version` are banned.** Git is the author record. `[L1: Checkstyle Regexp]`
6. **Contract tags (OpenJDK vocabulary, JDK-8008632):** `[L2]`
   - `@implSpec` — what a valid implementation **must** do; written for the implementer on the other side of The Wall.
   - `@apiNote` — guidance for callers: idioms, pitfalls, performance expectations that are part of the API's intent.
   - `@implNote` — facts about *this* implementation that may change (Community driver behaviour, current buffer sizes).
7. **Three contract lines on every SPI type that touches buffers, memory or threads**, as the last paragraph of the type comment, in this order and wording: `[L2]` `[L1 (planned): Checkstyle Regexp on `interface|class` under `spi/memory`, `spi/transport`, `spi/persistence`]`
   ```
   <p><b>Allocation:</b> zero-alloc on hot path | allocates (<what, when>)
   <p><b>Thread confinement:</b> owner thread | any thread | virtual-thread-safe
   <p><b>Ownership:</b> <who releases; retain/close semantics>
   ```
8. **Examples use `{@snippet}`**, never `<pre>{@code …}</pre>`; snippets longer than ~10 lines live in `snippet-files/` and are compiled by the module's tests. `[L1: doclint syntax on gated modules]` `[L2]`
9. **Failure modes name the code.** A method that can raise an `ExerisKernelException` documents the `EX-*` code(s) in `@throws`. `[L2]`
10. **Category B (generated) files carry the standard generated header and no hand-written Javadoc.** One header shape for every emitter, Java and TypeScript (ADR-085 §F.21d), produced by one helper that reads the real version:
    ```java
    /**
     * @generated by exeris-codegen-java <version> — DO NOT EDIT.
     * Source: <Domain>.java (@ExerisDomain <name>) · Regenerate: mvn exeris:generate
     */
    @Generated("eu.exeris.tooling.codegen")
    ```
    `[L1: pr-review Category-B check]` — the `generated` label exists in the organisation taxonomy but nothing applies it: there is no path-based labeler in `exeris-systems/.github`, and no emitter test asserts the header, because no shared helper produces it yet. Same position as `tsdoc-conventions.md` rule 10; ADR-085 §F.21d is what changes it.
11. **Kernel Core, Community and tooling: rules 2–9 apply to changed files only.** No backfill mandate. `[L1: diff-aware javadoc-gate workflow]`
12. **Javadoc carries no history.** A doc comment states the contract as it is today. Documentation has places for history — `CHANGELOG`, release notes, an ADR's `## Amendments`, a retraction box, a refactor note — and a doc comment is not one of them. The only temporal tags are `@since` (when the element appeared) and `@deprecated` (since when, and what replaces it). "Previously returned null", "fixed in 0.8.1", "after the io_uring refactor", bug or PR numbers, "this used to…" all go; where they carry knowledge, they go to the release notes or an ADR. A comment that argues *why* the contract is shaped this way is a missing ADR link rather than a paragraph — `@see ADR-NNN` is right, the story is not. `[L1 (warning): Checkstyle RegexpSingleline]` `[L2]`
    - **The line is the invariant, not its origin.** *"The ring is initialised by the transport owner thread, never by a persistence path"* is the contract and stays, however it was learned. *"This fixes the head-of-line blocking we hit in h1 when the PostgreSQL path initialised the ring"* is history and goes; if that invariant deserves a *why*, it gets `@see ADR-NNN`, or the trade-off goes to `docs/subsystems/transport.md`.
    - **The gate warns, it does not fail.** Whether a sentence is archaeology or a statement about the present is a reviewer's call: *"the buffer is no longer valid after `close()`"* is a correct sentence about now.
    - **The regex is narrow by measurement.** Each token is anchored to the verb that makes it past-referential. On `exeris-kernel-spi` the unanchored list (`previously|used to|fixed in|no longer|historically`) fires **36** times, **21** of them on `no longer` alone and nearly all legitimate; anchored, it fires **twice**, both genuine — a narrated downstream incident and a before-and-after account of a lost compile-time guarantee. `no longer` and a bare `previously` are therefore not matched. The miss is deliberate: a check that is wrong twenty times out of twenty-one is a check people learn to ignore.
    - **A sweep that is unsure records a `VERIFY` and moves on.** Deciding whether a sentence is contract or archaeology is review work, not sweep work.

## Prose rules (Oracle doc-comment conventions, adopted verbatim)

- Write the description to be implementation-independent; state dependencies explicitly where they exist.
- Use `{@code}` for identifiers, keywords and literals; `{@link}` sparingly (not for `java.lang`).
- "If the doc comment merely repeats the API name in sentence form, it is not providing more information." Delete it and write the contract instead.
- Document *what* and *under which conditions*, not *how* — `how` belongs in `@implNote` or the subsystem doc.

## Example — `LoanedBuffer` (kernel SPI), before and after

The current type comment already states the zero-copy contract and the reference-count lifecycle — that part is good and stays. What it lacks is the three contract lines, `@implSpec` for implementers, and it uses `<pre>{@code}` for examples.

Add, at the end of the type comment:

```java
 * <p><b>Allocation:</b> zero-alloc on hot path — {@link #slice} and {@link #view}
 * allocate no heap objects beyond the returned handle; pooling is the allocator's concern.
 * <p><b>Thread confinement:</b> owner thread — a buffer is confined to the thread that
 * obtained it from the allocator; a {@link #retain()}'d reference may be handed to another
 * thread only through a transport or scheduler seam that documents the hand-off.
 * <p><b>Ownership:</b> the holder of the last reference releases via {@link #close()};
 * every {@code slice}/{@code view} increments the parent's count and must be closed.
 *
 * @implSpec Implementations must return the segment to the pool exactly once, on the
 *           transition from reference count 1 to 0, and must throw
 *           {@code IllegalStateException} ({@code EX-MEM-nnnn} — the code registered in
 *           {@code KernelErrorCodes}; placeholder here) on any operation after that.
 * @apiNote  Prefer {@code try-with-resources}; a missed {@code close()} is a silent leak
 *           that only {@code LeakDetectionMode.PARANOID} will report.
 * @since 0.9
```

Replace the usage block:

```java
 * {@snippet lang="java" :
 * try (LoanedBuffer buf = allocator.allocate(AllocationHint.MEDIUM)) {
 *     buf.segment().set(ValueLayout.JAVA_BYTE, 0, (byte) 0xFF);
 *     transport.send(buf);   // @highlight substring="transport.send" : transport calls buf.retain()
 * }
 * }
```

## Filter (before you push a gated module)

- Does the first sentence tell an implementer what they may assume, not what the method is called?
- Is there a failure mode, and does it name the `EX-*` code?
- If the type touches memory: are Allocation / Thread confinement / Ownership all three there?
- Is anything in the comment something the *implementation* does rather than the *contract* requires? Move it to `@implNote`.
- Did the module's tests compile the snippet?
- Is there a sentence about the past? Move it to release notes or an ADR and leave `@since`/`@deprecated`/`@see` behind.
