#!/usr/bin/env bash
#
# drift-sweep.sh — candidate locator for the 10 recurring drift patterns.
#
# Single source of the *greppable* drift locators. The prose explanation of WHY
# each pattern is wrong lives once in ../../CLAUDE.md § "Common drift patterns to
# watch". This script does not restate that prose — it only surfaces candidate
# lines fast so a reviewer (the drift-pattern-sweep skill, or a human) can
# adjudicate drift vs. a correct negation/mention.
#
# IMPORTANT — why this is a *locator*, not an auto-fail gate:
#   grep cannot tell USE from MENTION. The canonical docs legitimately contain
#   every one of these tokens inside a negation ("there is no exeris-caps-quic-*",
#   "no cap @Requires exeris-spring-runtime", "TRL-5 component validation in Q4")
#   or while quoting the deprecated form to forbid it. So a token match is a
#   CANDIDATE, never a proven defect. Lines that look like a correct negation are
#   annotated "(neg? verify)" to speed adjudication.
#
# Usage:
#   scripts/drift-sweep.sh <file> [<file> ...]
#
# Class (prioritisation only, per CLAUDE.md): STRUCTURAL patterns (1,3,4,5,7,8)
# propagate downstream — review them first.
#
# Exit codes:
#   0 = no candidate lines found (clean)
#   1 = candidate lines found -> REVIEW REQUIRED (NOT "broken"; a human/model must
#       confirm each is drift vs. a correct negation/mention)
#   2 = usage error / no readable input

set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <file> [<file> ...]" >&2
  exit 2
fi

# Negation / mention cues — if a matched line contains one, it is likely the doc
# correctly stating the rule rather than committing the drift.
NEG_CUE="(\bno\b|\bnot\b|\bnever\b|n't|\bwithout\b|deprecated|\bexcludes?\b|forbid|prohibit|must not|cannot|there is no|do(es)? not|instead of|rather than|replaced?|legacy|wrong)"

# Pattern table: "ID|CLASS|LABEL|EREGEX"  (IDs match CLAUDE.md 1..10)
PATTERNS=(
  '1|STRUCTURAL|Postgres-only graph / replacing Neo4j (kernel is dual-engine)|replacing Neo4j|Postgres[- ]only|only graph engine|drop(ping|s)? Neo4j'
  '2|local|exeris-kernel-community framed as a sibling repo (it is a Maven module)|exeris-kernel-community'
  '3|STRUCTURAL|exeris-caps-quic-* / exeris-caps-io-uring-* (these caps do NOT exist)|exeris-caps-(quic|io[-_]uring)'
  '4|STRUCTURAL|SB-family / SKU claims Spring Runtime (SKUs are kernel-direct)|(SB[- ]family|Service Boundary|SKU)[^.]{0,80}Spring[ -]?Runtime'
  '5|STRUCTURAL|Cap @Requires exeris-spring-runtime (cap-tier Wall)|@?Requires[^.]{0,40}exeris-spring-runtime'
  '6|local|License taxonomy for caps — confirm three-valued|licens'
  '7|STRUCTURAL|Deprecated bootstrap framing Config -> Memory -> Exceptions|(Config|Memory|Exceptions)[[:space:]]*(->|=>|→|&gt;|&rarr;)[[:space:]]*(Memory|Exceptions|Security)'
  '8|STRUCTURAL|"Family products run on Spring Runtime" (only BudgetHQ does)|Family product[^.]{0,80}Spring[ -]?Runtime|Spring[ -]?Runtime[^.]{0,80}Family product'
  '9|local|Spring Runtime framed as part of the platform stack (independent Tier 1)|Spring[ -]?Runtime[^.]{0,60}(platform stack|part of the platform)|(platform stack|part of the platform)[^.]{0,60}Spring[ -]?Runtime'
  '10|local|TRL-5+ claimed (platform-aggregate is TRL-3; subsystem/roadmap TRL-5 is OK)|TRL[- ]?[5-9]'
)

candidates=0
files_ok=0

for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "WARN: cannot read '$f' — skipped" >&2
    continue
  fi
  files_ok=1
  for row in "${PATTERNS[@]}"; do
    id="${row%%|*}"; rest="${row#*|}"
    cls="${rest%%|*}"; rest="${rest#*|}"
    label="${rest%%|*}"; regex="${rest#*|}"
    matches="$(grep -nIE "$regex" -- "$f" 2>/dev/null || true)"
    [ -z "$matches" ] && continue
    echo "── [#$id $cls] $label"
    echo "   file: $f"
    while IFS= read -r line; do
      if printf '%s' "$line" | grep -qiE "$NEG_CUE"; then
        echo "   $line   ⟵ (neg? verify)"
      else
        echo "   $line"
      fi
      candidates=$((candidates + 1))
    done <<< "$matches"
  done
done

if [ "$files_ok" -eq 0 ]; then
  echo "no readable input files" >&2
  exit 2
fi

echo
if [ "$candidates" -gt 0 ]; then
  echo "drift-sweep: $candidates candidate line(s) — REVIEW REQUIRED"
  echo "Adjudicate each: real drift (fix every site) vs. correct negation/mention (lines marked 'neg? verify')."
  exit 1
fi
echo "drift-sweep: CLEAN (no candidate lines)"
exit 0
