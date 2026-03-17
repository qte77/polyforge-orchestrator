#!/bin/bash
# Load environment: .env file, gh_pat, credential store
# Usage: source config/env-loader.sh

# Load .env if present (cc-workspace root or ~/.env)
for envfile in "$(dirname "${BASH_SOURCE[0]}")/../.env" "$HOME/.env"; do
  if [[ -f "$envfile" ]]; then
    set -a; source "$envfile"; set +a
    break
  fi
done

# Fallback: load GH_PAT from legacy location
if [[ -z "${GH_PAT:-}" && -f "$HOME/.gh_pat" ]]; then
  export GH_PAT=$(grep -oP '(?<=GH_PAT=).*' "$HOME/.gh_pat" 2>/dev/null || cat "$HOME/.gh_pat")
fi
