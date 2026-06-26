#!/usr/bin/env bash
#
# adr-filename-check.sh — deterministic gate for ADR filename pattern + number
# reservation order.
#
# Rules live once in ../../CLAUDE.md § "ADR registry conventions" and adr-index.md.
# This script enforces only the mechanical parts:
#   - filename matches ADR-NNN-<lowercase-kebab-title>.md (3-digit zero-padded)
#   - the ADR number already has a row in adr-index.md (reserve-number-first)
#
# Usage:
#   scripts/adr-filename-check.sh adr/ADR-024-capability-composition-model.md
#
# Exit codes: 0 = pass, 1 = violation, 2 = usage / index not found.

set -uo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <path-to-ADR-file>" >&2
  exit 2
fi

target="$1"
base="$(basename -- "$target")"

# Locate adr-index.md: prefer the repo root two levels up from this script,
# fall back to the current working directory.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
index=""
for cand in "$repo_root/adr-index.md" "./adr-index.md" "../adr-index.md"; do
  if [ -r "$cand" ]; then index="$cand"; break; fi
done

fail=0

# 1) Filename pattern. Lowercase kebab title, 3-digit number, .md extension.
if [[ "$base" =~ ^ADR-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
  echo "PASS  filename pattern: $base"
else
  echo "FAIL  filename pattern: '$base' does not match ADR-NNN-<lowercase-kebab-title>.md"
  echo "      (3-digit zero-padded number; lowercase kebab; '&' -> 'and'; drop other punctuation)"
  fail=1
fi

# 2) Number reservation. Extract NNN and confirm a row exists in the index.
num="$(printf '%s' "$base" | grep -oE '^ADR-[0-9]{3}' || true)"
if [ -z "$num" ]; then
  echo "SKIP  number reservation: cannot parse ADR number from filename"
elif [ -z "$index" ]; then
  echo "WARN  number reservation: adr-index.md not found (looked under repo root + cwd)"
elif grep -qE "(^|[^0-9])${num}([^0-9]|\$)" -- "$index"; then
  echo "PASS  number reservation: $num present in $index"
else
  echo "FAIL  number reservation: $num has NO row in $index — reserve the number FIRST"
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
fi
echo "RESULT: FAIL"
exit 1
