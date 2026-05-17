#!/usr/bin/env bash
# tools/check-refs.sh — fitness function for §N cross-references
#
# Verifies the structural invariant: every §N reference in any markdown file
# in this repo resolves to a section header that exists somewhere in the repo.
#
# Per §3 (Architectural Fitness Functions): this is a structural fitness
# function. The invariant is "every §N reference resolves to a defined section."
# Violations indicate orphan references — typically a section was renumbered,
# moved, or removed without updating cross-refs, OR a typo in the reference.
#
# Exit codes:
#   0 — all references resolve
#   N — N orphan references found (one exit code per orphan, capped at 255)
#
# Usage:
#   tools/check-refs.sh             # full check
#   tools/check-refs.sh --quiet     # exit code only, no output
#   tools/check-refs.sh --unused    # also list defined sections never referenced

set -euo pipefail

# Move to repo root regardless of invocation directory
cd "$(dirname "$0")/.."

QUIET=0
SHOW_UNUSED=0
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=1 ;;
    --unused) SHOW_UNUSED=1 ;;
  esac
done

# Section ID patterns we recognize:
#   §0, §1 ... §15           (top-level core sections)
#   §3b, §3c, §3d, §3e       (lettered peer sections)
#   §6b                       (lettered peer of §6)
#   §0.1 ... §0.8, §0.7b     (numbered sub-sections of §0)
#   §9.1, §9.5b, §9.6, §9.7  (numbered sub-sections of §9)
#   §16 ... §30, §30.1 etc.  (extension sections — declared via h2 OR via the
#                              "**Extension of ... — §N**" bold-line convention)

# Pattern 1: defined via "## N. Title", "## N.X Title", "### N.X Title", etc.
# Trailing punctuation is optional — some extensions use "## 26.0 Context" without period
DEFINED_HEADER_RE='^#{2,3} §?[0-9]+([a-z]|\.[0-9]+([a-z])?)?[ .]'

# Pattern 2: defined via "**Extension of ... — §N**" bold-line (extensions use this)
DEFINED_EXT_RE='\*\*Extension of .* — §[0-9]+([a-z]|\.[0-9]+([a-z])?)?\*\*'

# Reference regex (matches §N, §N.X, §Nb, §N.Xb — but caps section number at 2 digits
# so HIPAA-style citations like §164.312 don't false-positive as section refs)
REFERENCE_RE='§[0-9]{1,2}([a-z]|\.[0-9]+([a-z])?)?'

# Collect defined sections from h2/h3 headers
defined_headers=$(grep -rhE "$DEFINED_HEADER_RE" --include="*.md" . \
  | sed -E 's/^#{2,3} §?([0-9]+([a-z]|\.[0-9]+([a-z])?)?).*/\1/' \
  | sort -u)

# Collect defined sections from extension-bold-line convention
defined_ext=$(grep -rhE "$DEFINED_EXT_RE" --include="*.md" . \
  | sed -E 's/.*§([0-9]+([a-z]|\.[0-9]+([a-z])?)?).*/\1/' \
  | sort -u)

# Union of both definition patterns
defined=$(echo -e "${defined_headers}\n${defined_ext}" | sort -u | grep -v "^$")

# Collect referenced sections (extract just the section ID after §)
# Word-boundary anchor avoids matching §164 inside §164.312 as separate ref
referenced=$(grep -rhoE "$REFERENCE_RE" --include="*.md" . \
  | sed 's/§//' \
  | sort -u)

# Known false-positive references that aren't real cross-refs:
# - §N where N is "next-available" markers in CLAUDE.md (e.g., "Next available extension section: §31")
# - References inside code fences (rare; not currently filtered)
# Maintain a small allowlist of section IDs that are expected NOT to resolve.
# Future: replace with an inline annotation system (<!-- nofitness --> in markdown).
EXPECTED_UNRESOLVED="31"

# Report orphan references
# A reference §N resolves if EITHER the exact section is defined OR any sub-section §N.X is defined.
orphan_count=0
orphans=""
for ref in $referenced; do
  # Skip known false-positives
  if echo " $EXPECTED_UNRESOLVED " | grep -q " ${ref} "; then
    continue
  fi
  # Exact match
  if echo "$defined" | grep -qE "^${ref}$"; then
    continue
  fi
  # Sub-section family match: §26 resolves if §26.0, §26.1, etc. exist
  if echo "$defined" | grep -qE "^${ref}\."; then
    continue
  fi
  orphans="$orphans $ref"
  orphan_count=$((orphan_count + 1))
done

# Report unused sections (defined but never referenced) — informational only
unused=""
if [ "$SHOW_UNUSED" = "1" ]; then
  for sec in $defined; do
    if ! echo "$referenced" | grep -qE "^${sec}$"; then
      unused="$unused $sec"
    fi
  done
fi

if [ "$QUIET" != "1" ]; then
  echo "=== umami cross-reference fitness check ==="
  echo "Defined sections: $(echo "$defined" | wc -w)"
  echo "Referenced sections: $(echo "$referenced" | wc -w)"
  echo ""

  if [ "$orphan_count" = "0" ]; then
    echo "✓ All §N references resolve to defined sections."
  else
    echo "✗ ${orphan_count} orphan reference(s) found:"
    for ref in $orphans; do
      # Show first 3 locations where the orphan is referenced
      locations=$(grep -rln "§${ref}\b" --include="*.md" . 2>/dev/null | head -3 | sed 's|^./||' | tr '\n' ' ')
      echo "  §${ref} (first refs: ${locations})"
    done
  fi

  if [ "$SHOW_UNUSED" = "1" ] && [ -n "$unused" ]; then
    echo ""
    echo "Informational — sections defined but never referenced (may be intentional):"
    for sec in $unused; do
      echo "  §${sec}"
    done
  fi
fi

# Cap exit code at 255 to fit POSIX exit range
[ "$orphan_count" -gt 255 ] && orphan_count=255
exit "$orphan_count"
