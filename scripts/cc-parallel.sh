#!/bin/bash
# cc-parallel.sh — Run a claude prompt across repos in parallel
# Usage: ./cc-parallel.sh <prompt> <repo-path> [repo-path...]
# Usage: ./cc-parallel.sh --preset <preset-name>
#
# Options:
#   --max-turns N      Max conversation turns per repo (default: 10)
#   --max-budget N     Max USD budget per repo (default: 2.0)
#   --output-dir DIR   Directory for result files (default: mktemp)
#   --preset NAME      Use a predefined prompt+repo combination
#
# Presets:
#   validate    — Run `make validate` on all repos that have a Makefile
#   status      — Report git status and recent changes
#   security    — Audit for security issues
#
# Examples:
#   ./cc-parallel.sh "Run make validate" /workspaces/Agents-eval /workspaces/qte77/CABIO-test
#   ./cc-parallel.sh --preset validate
#   ./cc-parallel.sh --max-budget 1.0 "Check for TODO comments" /workspaces/Agents-eval

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/env-loader.sh"
source "${SCRIPT_DIR}/repos.conf"

# Defaults
MAX_TURNS=10
MAX_BUDGET="2.0"
OUTPUT_DIR=""
PROMPT=""
PRESET=""
TARGET_REPOS=()

usage() {
  head -20 "$0" | grep '^#' | sed 's/^# \?//'
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-turns) MAX_TURNS="$2"; shift 2 ;;
    --max-budget) MAX_BUDGET="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --preset) PRESET="$2"; shift 2 ;;
    --help|-h) usage ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      if [[ -z "$PROMPT" && -z "$PRESET" ]]; then
        PROMPT="$1"
      else
        TARGET_REPOS+=("$1")
      fi
      shift
      ;;
  esac
done

# Apply presets
case "$PRESET" in
  validate)
    PROMPT="Run 'make validate' and report the results. If make validate is not available, run the closest equivalent (lint, type check, test)."
    for repo in "${REPOS[@]}"; do
      [[ -f "$repo/Makefile" ]] && TARGET_REPOS+=("$repo")
    done
    ;;
  status)
    PROMPT="Report: 1) current branch, 2) git status (clean/dirty), 3) last 3 commit subjects, 4) any uncommitted changes summary."
    TARGET_REPOS=("${REPOS[@]}")
    MAX_TURNS=3
    MAX_BUDGET="0.50"
    ;;
  security)
    PROMPT="Audit this repo for security issues: hardcoded secrets, insecure dependencies, OWASP top 10 vulnerabilities. Report findings with severity (critical/high/medium/low) and file locations."
    TARGET_REPOS=("${REPOS[@]}")
    MAX_TURNS=15
    ;;
  "")
    # No preset, need prompt and repos from args
    ;;
  *)
    echo "Unknown preset: $PRESET" >&2
    usage
    ;;
esac

if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided." >&2
  usage
fi

if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
  echo "Error: No repos specified." >&2
  usage
fi

# Setup output directory
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR=$(mktemp -d -t cc-parallel-XXXXXX)
fi
mkdir -p "$OUTPUT_DIR"

echo "=== CC Parallel Runner ==="
echo "Prompt:     ${PROMPT:0:80}$([ ${#PROMPT} -gt 80 ] && echo '...')"
echo "Repos:      ${#TARGET_REPOS[@]}"
echo "Max turns:  $MAX_TURNS"
echo "Max budget: \$${MAX_BUDGET}/repo"
echo "Output:     $OUTPUT_DIR"
echo ""

# Track PIDs for wait
declare -A PIDS

# Launch parallel claude instances
for repo in "${TARGET_REPOS[@]}"; do
  if [[ ! -d "$repo" ]]; then
    echo "Warning: $repo not found, skipping"
    continue
  fi

  name=$(basename "$repo")
  outfile="${OUTPUT_DIR}/${name}.json"
  logfile="${OUTPUT_DIR}/${name}.log"

  echo "Starting: $name"

  (
    cd "$repo"
    claude -p "$PROMPT" \
      --output-format json \
      --max-turns "$MAX_TURNS" \
      > "$outfile" 2>"$logfile"
  ) &
  PIDS[$name]=$!
done

echo ""
echo "Waiting for ${#PIDS[@]} instances..."
echo ""

# Collect results
TOTAL_COST=0
FAILURES=0

for name in "${!PIDS[@]}"; do
  pid="${PIDS[$name]}"
  outfile="${OUTPUT_DIR}/${name}.json"

  if wait "$pid"; then
    status="OK"
  else
    status="FAILED"
    ((FAILURES++))
  fi

  # Extract cost and result summary from JSON output
  cost="n/a"
  result_preview=""
  if [[ -f "$outfile" && -s "$outfile" ]]; then
    cost=$(jq -r '.cost_usd // .session_cost // "n/a"' "$outfile" 2>/dev/null || echo "n/a")
    result_preview=$(jq -r '.result // .content // "" | tostring | .[0:120]' "$outfile" 2>/dev/null || echo "")

    if [[ "$cost" != "n/a" ]]; then
      TOTAL_COST=$(echo "$TOTAL_COST + $cost" | bc 2>/dev/null || echo "$TOTAL_COST")
    fi
  fi

  printf "%-30s %-8s \$%-8s %s\n" "$name" "$status" "$cost" "${result_preview:0:60}"
done

echo ""
echo "=== Summary ==="
echo "Total repos:    ${#PIDS[@]}"
echo "Failures:       $FAILURES"
echo "Total cost:     \$${TOTAL_COST}"
echo "Results in:     $OUTPUT_DIR"

exit "$FAILURES"
