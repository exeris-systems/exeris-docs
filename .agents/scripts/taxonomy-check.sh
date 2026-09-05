#!/usr/bin/env bash
#
# taxonomy-check.sh — candidate locator for visibility (ADR-020) and license
# (ADR-023) taxonomy discipline.
#
# The authoritative prose (which value means what, the cap census, the SKU
# source-visibility split) lives once in ../../.agents/references/capability-layer.md and
# § "ADR registry conventions", and in adr/ADR-020 / adr/ADR-023. This script only
# locates candidate lines — it does NOT restate the census.
#
# Like drift-sweep.sh this is a locator, not an auto-fail gate: a doc legitimately
# says "public-staged is deprecated — do not use it". Such mentions are annotated
# "(neg? verify)". A reviewer (the adr-registry-discipline-review skill, or a
# human) adjudicates.
#
# Usage:
#   scripts/taxonomy-check.sh <file> [<file> ...]
#
# Exit codes: 0 = clean, 1 = candidates -> REVIEW REQUIRED, 2 = usage error.

set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <file> [<file> ...]" >&2
  exit 2
fi

NEG_CUE="(\bno\b|\bnot\b|\bnever\b|n't|deprecated|do(es)? not|instead of|rather than|legacy|wrong|don't|avoid)"

# "ID|CLASS|LABEL|EREGEX"
PATTERNS=(
  'V1|visibility|public-staged (deprecated by ADR-020 — must be a negation/mention only)|public[- ]staged'
  'V2|visibility|Visibility context — confirm two-valued (public / enterprise-private)|visibilit'
  'L1|license|License context — confirm three-valued (community/commercial/enterprise-private)|licens'
  'X1|conflation|Possible visibility/license conflation on one line|(visibilit[a-z]*)[^.]{0,60}(licens)|(licens[a-z]*)[^.]{0,60}(visibilit)'
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
    echo "── [$id $cls] $label"
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
  echo "taxonomy-check: $candidates candidate line(s) — REVIEW REQUIRED"
  echo "Confirm: visibility two-valued, license three-valued, axes not conflated, no live public-staged."
  exit 1
fi
echo "taxonomy-check: CLEAN"
exit 0
