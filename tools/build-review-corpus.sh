#!/usr/bin/env bash
# build-review-corpus.sh — dev tooling (not corpus; b1edit/Claude-shaped is fine here).
#
# Concatenates the full umami corpus into a single review/corpus.md with clear
# per-file delimiters, for feeding to the 4-frontier-model readability sweep
# (see /home/dennis/.claude/plans/nested-growing-beacon.md). Output is scratch:
# review/ is gitignored.
#
# Usage:  tools/build-review-corpus.sh
# Emits:  review/corpus.md  (+ a size report on stdout)
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root
OUT_DIR="review"
OUT="$OUT_DIR/corpus.md"
mkdir -p "$OUT_DIR"

# Explicit reading order so structure is legible to the reviewer:
# landing -> core (quality, runtime, process, agents) -> extensions -> recipes.
FILES=(
  umami.md
  core/umami-quality.md
  core/umami-runtime.md
  core/umami-process.md
  core/umami-agents.md
  ext/umami-web.md
  ext/umami-data.md
  ext/umami-iac.md
  ext/umami-mobile.md
  ext/cms/umami-cms.md
  ext/cms/umami-wordpress.md
  ext/cms/umami-drupal.md
  ext/umami-compliance.md
  ext/umami-scripting.md
  ext/umami-integration.md
  ext/umami-homelab.md
  ext/desktop/umami-desktop.md
  ext/desktop/umami-linux.md
  ext/desktop/umami-spa-wrapper.md
  ext/umami-agent-workflows.md
  recipes/README.md
  recipes/activity-stream.md
  recipes/closed-loop-pr-review.md
)

: > "$OUT"
{
  echo "# umami corpus — full concatenation for multi-model readability review"
  echo
  echo "This file is the complete umami corpus (landing + core companions + extensions + recipes),"
  echo "concatenated in reading order. Each source file is delimited by a \`===== FILE: =====\` banner."
  echo "Section numbers (\`§N\`) are stable cross-references that resolve across files."
  echo
} >> "$OUT"

for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "WARN: missing $f" >&2
    continue
  fi
  lines=$(wc -l < "$f" | tr -d ' ')
  {
    echo
    echo "===== FILE: $f ($lines lines) ====="
    echo
    cat "$f"
    echo
  } >> "$OUT"
done

bytes=$(wc -c < "$OUT" | tr -d ' ')
lines=$(wc -l < "$OUT" | tr -d ' ')
words=$(wc -w < "$OUT" | tr -d ' ')
approx_tokens=$(( bytes / 4 ))

echo "Wrote $OUT"
echo "  files:           ${#FILES[@]}"
echo "  bytes:           $bytes"
echo "  lines:           $lines"
echo "  words:           $words"
echo "  approx tokens:   ~$approx_tokens  (bytes/4 heuristic)"
