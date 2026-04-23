#!/bin/bash
# learnings-sync.sh — Distill local CC session data into committed learnings
# Runs bigpicture + plan-learnings locally, commits output to ai-agents-research
#
# Usage: ./scripts/learnings-sync.sh
#
# Output committed to:
#   ai-agents-research/docs/learnings/cc-bigpicture/latest.md
#   ai-agents-research/docs/learnings/cc-bigpicture/archive/YYYY-MM-DD.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEARCH_DIR="/workspaces/qte77/ai-agents-research"
OUTPUT_DIR="${RESEARCH_DIR}/docs/learnings/cc-bigpicture"
DATE=$(date +%Y-%m-%d)

if [[ ! -d "$RESEARCH_DIR/.git" ]]; then
  echo "Error: ai-agents-research not found at $RESEARCH_DIR" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}/archive"

echo "=== Distilling CC session data ==="

# Run bigpicture synthesis
echo "Running synthesizing-cc-bigpicture..."
claude -p "/cc-meta:synthesizing-cc-bigpicture --time-range 7d --output-path ${OUTPUT_DIR}/latest.md" \
  --max-turns 10 --output-format json > /dev/null 2>&1 || {
  echo "Warning: bigpicture synthesis failed, trying plan-learnings only" >&2
}

# Run plan-learnings distillation
echo "Running distilling-plan-learnings..."
claude -p "/cc-meta:distilling-plan-learnings --time-range 7d --output-path ${OUTPUT_DIR}/plan-learnings-latest.md" \
  --max-turns 10 --output-format json > /dev/null 2>&1 || {
  echo "Warning: plan-learnings distillation failed" >&2
}

# Archive dated copies
for f in latest.md plan-learnings-latest.md; do
  src="${OUTPUT_DIR}/${f}"
  if [[ -f "$src" && -s "$src" ]]; then
    base="${f%-latest.md}"
    [[ "$base" == "latest" ]] && base="bigpicture"
    cp "$src" "${OUTPUT_DIR}/archive/${base}-${DATE}.md"
    echo "Archived: ${base}-${DATE}.md"
  fi
done

# Commit to ai-agents-research
cd "$RESEARCH_DIR"
git add docs/learnings/cc-bigpicture/
if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "chore: learnings sync ${DATE} — bigpicture + plan distillation"
  git push origin HEAD
  echo "=== Committed and pushed to ai-agents-research ==="
fi
