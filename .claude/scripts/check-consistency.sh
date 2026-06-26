#!/usr/bin/env bash
#
# check-consistency.sh — anti-drift guard for the .claude/ toolkit itself.
#
# Single-source invariant: doctrine that ROTS (the cap census, specific cap
# names, TRL levels, the SKU enumeration) must live ONLY in ../../CLAUDE.md and
# the ADRs. Skills / commands / agents must REFERENCE it, not restate it — so
# that when CLAUDE.md changes there is exactly one site to update.
#
# This is a TRUE gate (unlike drift-sweep/taxonomy-check, which are locators):
# its rules are unconditional. A hit is a real violation -> exit 1.
#
# It deliberately does NOT flag the mere *mention* of a drift-pattern name — a
# review skill must be allowed to say what it checks for. It targets only the
# rotting specifics (numbers, named census, TRL values).
#
# Scope: .claude/{skills,commands,agents} + .claude/README.md.
# Excluded: .claude/scripts/ (the allowed home of the greppable patterns) and
#           CLAUDE.md (the allowed home of the prose + census).
#
# Usage:  .claude/scripts/check-consistency.sh
# Exit:   0 = clean, 1 = violation(s).

set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="$(cd -- "$script_dir/.." && pwd)"

# Build the file list (skills, commands, agents, top-level README) — never scripts/.
mapfile -t FILES < <(
  find "$claude_dir/skills" "$claude_dir/commands" "$claude_dir/agents" \
       -type f -name '*.md' 2>/dev/null
  [ -f "$claude_dir/README.md" ] && echo "$claude_dir/README.md"
)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "check-consistency: no files to scan" >&2
  exit 0
fi

# "ID|LABEL|EREGEX" — each match is a restated rotting fact.
RULES=(
  'A|Hard-coded cap census magnitude (belongs only in CLAUDE.md / ADR-023)|\b([3-9]|[0-9]{2,})[[:space:]]+caps\b'
  'B|SKU split count e.g. 6/7 (belongs only in CLAUDE.md / ADR-023)|[0-9][[:space:]]*/[[:space:]]*7\b'
  'C|Named census cap (enumerate only in CLAUDE.md / ADR-023)|bot-fingerprinting|cors-policy|observability-bridge'
  'D|Hard-coded TRL level (rots; state only in CLAUDE.md / whitepaper)|TRL[- ]?[0-9]'
)

violations=0

for f in "${FILES[@]}"; do
  rel="${f#"$claude_dir"/}"
  for row in "${RULES[@]}"; do
    id="${row%%|*}"; rest="${row#*|}"
    label="${rest%%|*}"; regex="${rest#*|}"
    matches="$(grep -nIE "$regex" -- "$f" 2>/dev/null || true)"
    [ -z "$matches" ] && continue
    echo "── [$id] $label"
    echo "   .claude/$rel"
    while IFS= read -r line; do
      echo "   $line"
      violations=$((violations + 1))
    done <<< "$matches"
  done
done

echo
if [ "$violations" -gt 0 ]; then
  echo "check-consistency: $violations restated-doctrine violation(s) — FAIL"
  echo "Move the rotting fact back to CLAUDE.md / the ADR and reference it instead."
  exit 1
fi
echo "check-consistency: CLEAN (no restated rotting doctrine under .claude/)"
exit 0
